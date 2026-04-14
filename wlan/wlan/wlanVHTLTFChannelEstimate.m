function [est,varargout] = wlanVHTLTFChannelEstimate(rxSym,cfgVHT,varargin)
% wlanVHTLTFChannelEstimate Channel estimation using the VHT-LTF
%   EST = wlanVHTLTFChannelEstimate(RXSYM,CFGVHT) returns the estimated
%   channel between all space-time streams and receive antennas using the
%   Very High Throughput Long Training Field (VHT-LTF). The channel
%   estimate includes the effect of the applied spatial mapping matrix and
%   cyclic shifts at the transmitter.
%
%   EST is a single or double complex Nst-by-Nsts-by-Nr array
%   characterizing the estimated channel for the data and pilot
%   subcarriers, where Nst is the number of occupied subcarriers, Nsts is
%   the total number of space-time streams, and Nr is the number of receive
%   antennas.
%
%   RXSYM is a complex Nst-by-Nsym-by-Nr array containing demodulated
%   VHT-LTF OFDM symbols. Nsym is the number of demodulated VHT-LTF
%   symbols.
%
%   CFGVHT is a packet format configuration object of type wlanVHTConfig.
%
%   EST = wlanVHTLTFChannelEstimate(RXSYM,CHANBW,NUMSTS) returns the
%   estimated channel for the specified channel bandwidth, CHANBW, and the
%   number of space-time streams, NUMSTS. Both CHANBW and NUMSTS have the
%   same attributes as the corresponding ChannelBandwidth and
%   NumSpaceTimeStreams properties of the wlanVHTConfig format
%   configuration object.
%
%   EST = wlanVHTLTFChannelEstimate(...,SPAN) performs frequency smoothing
%   by using a moving average filter across adjacent subcarriers to reduce
%   the noise on the channel estimate. The span of the filter in
%   subcarriers, SPAN, must be odd. If adjacent subcarriers are highly
%   correlated frequency smoothing will result in significant noise
%   reduction, however in a highly frequency selective channel smoothing
%   may degrade the quality of the channel estimate.
%
%   [...,CHANESTSSPILOTS] = wlanVHTLTFChannelEstimate(...) additionally
%   returns an Nsp-by-Nsym-by-Nr array characterizing the estimated channel
%   for pilot subcarrier locations for each symbol, assuming one space-time
%   stream at the transmitter. Nsp is the number of pilot subcarriers.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(2,4);

if ischar(cfgVHT) || isstring(cfgVHT)
    % wlanVHTLTFChannelEstimate(RXSYM,CHANBW,NUMSTS,...) syntax
    narginchk(3,4);

    wlan.internal.validateParam('CHANBW',cfgVHT,mfilename);
    chanBW = cfgVHT;

    numSTSVec = varargin{1};
    wlan.internal.validateParam('NUMSTS',numSTSVec,mfilename);

    if nargin == 4
        span = varargin{2};
        enableFreqSmoothing = true;
    else
        enableFreqSmoothing = false;
    end
else
    % wlanVHTLTFChannelEstimate(RXSYM,CFGVHT,...) syntax
    narginchk(2,3);

    % cfgVHT validation
    validateattributes(cfgVHT,{'wlanVHTConfig'},{'scalar'}, mfilename,'VHT format configuration object');
    % Dependent validation not needed for necessary fields (CHANBW, numSTS)
    chanBW = cfgVHT.ChannelBandwidth;
    numSTSVec = cfgVHT.NumSpaceTimeStreams;

    if nargin == 3
        enableFreqSmoothing = true;
        span = varargin{1};
    else
        enableFreqSmoothing = false;
    end
end

% Validate symbol type
validateattributes(rxSym,{'single','double'},{'3d'},mfilename,'VHT-LTF OFDM symbol(s)');

numSC = size(rxSym,1);
numRxAnts = size(rxSym,3);
numSTSTotal = sum(numSTSVec);

% Get OFDM configuration
ofdm = wlan.internal.vhtOFDMInfo('VHT-LTF',chanBW);

% Return an empty if empty symbols
if isempty(rxSym)
    est = zeros(numSC,numSTSTotal,numRxAnts,'like',rxSym);
    if nargout>1
        numLTFSym = wlan.internal.numVHTLTFSymbols(numSTSTotal);
        if numSC==0
            varargout{1} = zeros(numSC,numLTFSym,numRxAnts,'like',rxSym);
        else % numRxAnts = 0
            varargout{1} = zeros(numel(ofdm.PilotIndices),numLTFSym,numRxAnts,'like',rxSym);
        end
    end
    return;
end

% Verify number of subcarriers to estimate
coder.internal.errorIf(numSC~=ofdm.NumTones,'wlan:wlanChannelEstimate:IncorrectNumSC',ofdm.NumTones,numSC);

% Get cyclic shifts applied at transmitter
csh = wlan.internal.getCyclicShiftVal('VHT',numSTSTotal,ofdm.NumSubchannels*20);

if numSTSTotal==1
    % Perform channel estimation for all subcarriers
    [est,seqLTF,PvhtLTF,numLTFSym] = wlan.internal.vhtltfEstimate(rxSym,chanBW,numSTSTotal,ofdm.ActiveFFTIndices);
else
    % Perform channel estimation for data carrying subcarriers as we
    % must interpolate the pilots
    [estData,seqLTF,PvhtLTF,numLTFSym] = wlan.internal.vhtltfEstimate(rxSym(ofdm.DataIndices,:,:),chanBW,numSTSTotal,ofdm.ActiveFFTIndices(ofdm.DataIndices));

    % Undo cyclic shift for each STS before averaging and interpolation
    estData = wlan.internal.cyclicShiftChannelEstimate(estData,-csh,ofdm.FFTLength,ofdm.ActiveFrequencyIndices(ofdm.DataIndices));

    % Estimate pilot subcarriers
    estPilots = pilotInterpolation(estData,ofdm.FFTLength,ofdm.ActiveFFTIndices(ofdm.DataIndices),ofdm.ActiveFFTIndices(ofdm.PilotIndices));

    % Combine data and pilots into one container
    est = coder.nullcopy(complex(zeros(ofdm.NumTones,numSTSTotal,numRxAnts,'like',rxSym)));
    est(ofdm.DataIndices,:,:) = estData;
    est(ofdm.PilotIndices,:,:) = estPilots;
end

% Perform frequency smoothing
if enableFreqSmoothing
    % Smooth segments between DC gaps
    switch chanBW
      case 'CBW20'
        numGroups = 1;
      case 'CBW40'
        numGroups = 2;
      case 'CBW80'
        numGroups = 2;
      otherwise % 'CBW160'
        numGroups = 4;
    end
    groupSize = size(est,1)/numGroups;
    for i = 1:numGroups
        idx = (1:groupSize)+(i-1)*groupSize;
        est(idx,:,:) = wlan.internal.frequencySmoothing(est(idx,:,:),span);
    end
end

% Re-apply cyclic shift after averaging and interpolation
if numSTSTotal>1
    est = wlan.internal.cyclicShiftChannelEstimate(est,csh,ofdm.FFTLength,ofdm.ActiveFrequencyIndices);
end

% Channel estimate for single stream pilots
if nargout>1
    % IEEE Std 802.11-2020, Equation 21-41
    RvhtLTF = PvhtLTF(1,1:numLTFSym);
    varargout{1} = rxSym(ofdm.PilotIndices,:,:)./(seqLTF(ofdm.ActiveFFTIndices(ofdm.PilotIndices),:).*RvhtLTF);
end
end

%--------------------------------------------------------------------------
function estPilots = pilotInterpolation(estData,Nfft,dataIndices,pilotIndices)
% Interpolate over the pilot locations

    numSTS = size(estData,2);
    numRxAnts = size(estData,3);

    % Construct full FFT size to allow us to interpolate over DC nulls
    est = complex(ones(Nfft,numSTS,numRxAnts),ones(Nfft,numSTS,numRxAnts));
    est(dataIndices,:,:) = estData;

    % Interpolate over missing parts of the waveform in magnitude and
    % phase (as opposed to real and imaginary)
    magPart = interp1(dataIndices,abs(est(dataIndices,:,:)),1:Nfft);
    phasePart = interp1(dataIndices,unwrap(angle(est(dataIndices,:,:))),1:Nfft);
    [realPart,imagPart] = pol2cart(phasePart,magPart);
    estInterp = complex(realPart,imagPart);
    if isrow(estInterp)
        est = estInterp(:,:,1).';
    else
        est = estInterp;
    end

    % Extract pilots
    estPilots = est(pilotIndices,:,:);

end

