function est = wlanHTLTFChannelEstimate(rxSym,cfgHT,varargin)
% wlanHTLTFChannelEstimate Channel estimation using the HT-LTF
%   EST = wlanHTLTFChannelEstimate(RXSYM,CFGHT) returns the estimated
%   channel between all space-time, extension streams and receive antennas
%   using the High Throughput Long Training Field (HT-LTF). The channel
%   estimate includes the effect of the applied spatial mapping matrix and
%   cyclic shifts at the transmitter.
%
%   EST is a complex Nst-by-(Nsts+Ness)-by-Nr array containing the
%   estimated channel at data and pilot subcarriers, where Nst is the
%   number of subcarriers, Nsts is the number of space-time streams, Ness
%   is the number of extension streams and Nr is the number of receive
%   antennas.
%
%   RXSYM is a complex Nst-by-Nsym-by-Nr array containing demodulated
%   HT-LTF OFDM symbols. Nsym is the number of demodulated HT-LTF OFDM
%   symbols.
%
%   CFGHT is a packet format configuration object of type wlanHTConfig.
%
%   EST = wlanHTLTFChannelEstimate(...,SPAN) performs frequency smoothing
%   by using a moving average filter across adjacent subcarriers to reduce
%   the noise on the channel estimate. The span of the filter in
%   subcarriers, SPAN, must be odd. If adjacent subcarriers are highly
%   correlated frequency smoothing will result in significant noise
%   reduction, however in a highly frequency selective channel smoothing
%   may degrade the quality of the channel estimate.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate number of arguments
narginchk(2,3);

if nargin > 2
    span = varargin{1};
    enableFreqSmoothing = true;
else
    % Default no frequency smoothing
    enableFreqSmoothing = false;
end

% Validate the packet format configuration object is a valid type
validateattributes(cfgHT,{'wlanHTConfig'},{'scalar'},mfilename, ...
                   'packet format configuration object');
validateConfig(cfgHT, 'EssSTS');

% Validate symbol type
validateattributes(rxSym,{'single','double'},{'3d'}, ...
                   'wlanHTLTFChannelEstimate','HT-LTF OFDM symbol(s)');

cbw = cfgHT.ChannelBandwidth;
numSC = size(rxSym,1);
numRxAnts = size(rxSym,3);
numSTS = cfgHT.NumSpaceTimeStreams;
if wlan.internal.inESSMode(cfgHT)
    numESS = cfgHT.NumExtensionStreams;
else
    numESS = 0;
end

% Return an empty if empty symbols
if isempty(rxSym)
    est = zeros(numSC,numSTS+numESS,numRxAnts,'like',rxSym);
    return;
end

% Perform channel estimation for all subcarriers
ofdm = wlan.internal.vhtOFDMInfo('HT-LTF',cbw); % Get OFDM configuration
chanBWInMHz = ofdm.NumSubchannels*20;
% Verify number of subcarriers to estimate
coder.internal.errorIf(numSC~=ofdm.NumTones, ...
                       'wlan:wlanChannelEstimate:IncorrectNumSC',ofdm.NumTones,numSC);
est = wlan.internal.htltfEstimate(rxSym,cbw,numSTS,numESS,ofdm.ActiveFFTIndices);

% Perform frequency smoothing
if enableFreqSmoothing
    % Undo cyclic shift for each STS+ESS before averaging
    csh = wlan.internal.getCyclicShiftVal('VHT',numSTS,chanBWInMHz);
    est(:,1:numSTS,:) = wlan.internal.cyclicShiftChannelEstimate(est(:,1:numSTS,:), ...
                                                                 -csh,ofdm.FFTLength,ofdm.ActiveFrequencyIndices);
    cshEss = wlan.internal.getCyclicShiftVal('VHT',numESS,chanBWInMHz);
    if numESS>1
        est(:,numSTS+(1:numESS),:) = ...
            wlan.internal.cyclicShiftChannelEstimate(est(:,numSTS+(1:numESS),:),-cshEss, ...
                                                     ofdm.FFTLength,ofdm.ActiveFrequencyIndices);
    end
    % Smooth segments between DC gaps
    switch cbw
      case 'CBW20'
        numGroups = 1;
      otherwise % 'CBW40'
        numGroups = 2;
    end
    groupSize = size(est,1)/numGroups;
    for i = 1:numGroups
        idx = (1:groupSize)+(i-1)*groupSize;
        est(idx,:,:) = wlan.internal.frequencySmoothing(est(idx,:,:),span);
    end

    % Re-apply cyclic shift after averaging and interpolation
    est(:,1:numSTS,:) = wlan.internal.cyclicShiftChannelEstimate(est(:,1:numSTS,:), ...
                                                                 csh,ofdm.FFTLength,ofdm.ActiveFrequencyIndices);
    if numESS>1
        est(:,numSTS+(1:numESS),:) = wlan.internal.cyclicShiftChannelEstimate(est(:, ...
                                                                                  numSTS+(1:numESS),:),cshEss,ofdm.FFTLength,ofdm.ActiveFrequencyIndices);
    end
end

end

