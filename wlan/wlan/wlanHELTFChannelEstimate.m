function [est,varargout] = wlanHELTFChannelEstimate(rxSym,cfgHE,varargin)
%wlanHELTFChannelEstimate Channel estimation using the HE-LTF
%   EST = wlanHELTFChannelEstimate(RXSYM,CFGHE) returns the estimated
%   channel between all space-time streams and receive antennas using the
%   HE-LTF of an HE single user, extended range single user, multi-user
%   (MU) or trigger-based packet. The channel estimate includes the effect
%   of the applied spatial mapping matrix and cyclic shifts at the
%   transmitter. If HE-LTF compression is used, linear interpolation is
%   performed to create a channel estimate for all subcarriers.
%
%   EST is an array characterizing the estimated channel for the data and
%   pilot subcarriers. EST is a complex Nst-by-Nsts-by-Nr array
%   characterizing the estimated channel for the data and pilot
%   subcarriers, where Nst is the number of occupied subcarriers, Nsts is
%   the total number of space-time streams, and Nr is the number of receive
%   antennas.
%
%   RXSYM is a complex Nst-by-Nsym-by-Nr array containing the demodulated
%   concatenated HE-LTF. Nsym is the number of demodulated HE-LTF symbols.
%
%   CFGHE is a format configuration object of type wlanHESUConfig,
%   wlanHEMUConfig, wlanHETBConfig, or wlanHERecoveryConfig. When
%   wlanHEMUConfig is provided an additional resource unit (RU) number
%   argument is required as described below.
%
%   EST = wlanHELTFChannelEstimate(RXSYM,CFGMU,RUNUMBER) returns the
%   channel estimate for the RU of interest for a MU configuration.
%
%   [...,CHANESTSSPILOTS] = wlanHELTFChannelEstimate(...) additionally
%   returns an Nsp-by-Nsym-by-Nr array characterizing the estimated channel
%   for pilot subcarrier locations for each symbol, assuming one space-time
%   stream at the transmitter. Nsp is the number of pilot subcarriers.
%
%   [EST,CHANESTSSPILOTS] = wlanHELTFChannelEstimate(...,NAME,VALUE)
%   specifies one name-value argument.
%
%   'FrequencySmoothingSpan'    Perform frequency smoothing for EST by
%                               using a moving average filter across
%                               adjacent subcarriers to reduce the noise on
%                               the channel estimate. To enable the
%                               frequency smoothing, set this property to
%                               an odd number greater than 1. If adjacent
%                               subcarriers are highly correlated frequency
%                               smoothing will result in significant noise
%                               reduction, however in a highly frequency-
%                               selective channel smoothing may degrade the
%                               quality of the channel estimate. The
%                               default is 1, indicating that the frequency
%                               smoothing does not occur.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

narginchk(2,5)

% Input self-validation
validateattributes(rxSym,{'single','double'},{'3d','finite','nonempty'},mfilename,'demodulated HE-LTF OFDM symbol(s)');
validateattributes(cfgHE,{'wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig'},{'scalar'},mfilename,'format configuration object');

ruNumber = 1; % Default ruNumber to be 1
isHEMU = isa(cfgHE,'wlanHEMUConfig');
if isHEMU
    if nargin>2 && isnumeric(varargin{1}) % wlanHELTFChannelEstimate(rxSym,cfgHE,ruNumber,N-V)
        recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{2:end});
        validateattributes(varargin{1},{'double'},{'positive','integer','scalar'},mfilename,'RU number');
        ruNumber = varargin{1};
    else
        coder.internal.error('wlan:shared:ExpectedRUNumberHE');
    end
else
    if nargin>2 && isnumeric(varargin{1}) % wlanHELTFChannelEstimate(rxSym,cfgHE,ruNumber,N-V)
        recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{2:end});
    else % wlanHELTFChannelEstimate(rxSym,cfgHE) or wlanHELTFChannelEstimate(rxSym,cfgHE,N-V)
        recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{:});
    end
end

% Get allocation info
if isa(cfgHE,'wlanHERecoveryConfig')
    % Validate the channel bandwidth, packetFormat, RU Size, RU index, HELTFType, and NumHELTFSymbols
    wlan.internal.validateParam('CHANBW',cfgHE.ChannelBandwidth,mfilename);
    coder.internal.errorIf(~any(strcmp(cfgHE.PacketFormat,{'HE-SU','HE-EXT-SU','HE-MU','HE-TB'})),'wlan:wlanHERecoveryConfig:InvalidPacketFormat');
    wlan.internal.mustBeDefined(cfgHE.PacketFormat,'PacketFormat');
    wlan.internal.mustBeDefined(cfgHE.RUSize,'RUSize');
    wlan.internal.mustBeDefined(cfgHE.RUIndex,'RUIndex');
    wlan.internal.mustBeDefined(cfgHE.HELTFType,'HELTFType');
    wlan.internal.mustBeDefined(cfgHE.NumHELTFSymbols,'NumHELTFSymbols');

    ruSizeRU = cfgHE.RUSize;
    ruIndexRU = cfgHE.RUIndex;
    pktFormat = cfgHE.PacketFormat;
    minNumSym = cfgHE.NumHELTFSymbols;
    if strcmp(pktFormat,'HE-MU')
        % Validate RUTotalSpaceTimeStreams
        wlan.internal.mustBeDefined(cfgHE.RUTotalSpaceTimeStreams,'RUTotalSpaceTimeStreams');
        numSTSRU = cfgHE.RUTotalSpaceTimeStreams;
    else % SU, EXT SU
        % Validate NumSpaceTimeStreams
        wlan.internal.mustBeDefined(cfgHE.NumSpaceTimeStreams,'NumSpaceTimeStreams');
        numSTSRU = cfgHE.NumSpaceTimeStreams;
    end
else
    allocInfo = ruInfo(cfgHE);
    wlan.internal.validateRUNumber(ruNumber,allocInfo.NumRUs);
    pktFormat = packetFormat(cfgHE);
    ruSizeRU = allocInfo.RUSizes(ruNumber);
    ruIndexRU = allocInfo.RUIndices(ruNumber);
    numSTSRU = allocInfo.NumSpaceTimeStreamsPerRU(ruNumber); % Number of STSs in the specified RU
    if isa(cfgHE,'wlanHETBConfig')
        % NumHELTFSymbols is same across all RUs. NumHELTFSymbols is
        % calculated using the maximum number of STSs across all RUs in an
        % uplink transmission.
        minNumSym = cfgHE.NumHELTFSymbols;
    else
        numSTSMax = max(allocInfo.NumSpaceTimeStreamsPerRU); % Maximum number of STSs of all RUs
        minNumSym = wlan.internal.numVHTLTFSymbols(numSTSMax);
    end
end

% Get channel bandwidth
chanBW = cfgHE.ChannelBandwidth;
cbw = wlan.internal.cbwStr2Num(chanBW);

% Validate the number of HE-LTF subcarriers and OFDM symbols in rxSym
[numSC,numSym,~] = size(rxSym);
ofdmInfo = wlan.internal.heOFDMInfo('HE-LTF',chanBW,3.2,ruSizeRU,ruIndexRU);
coder.internal.errorIf(numSC~=ofdmInfo.NumTones,'wlan:wlanChannelEstimate:IncorrectNumSC',ofdmInfo.NumTones,numSC);
coder.internal.errorIf(numSym<minNumSym,'wlan:he:InvalidNumLTF',numSym,minNumSym);
% Extract the required HE-LTF OFDM symobls from rxSym
numSym = min(numSym,minNumSym);
rxLTFSym = rxSym(:,1:numSym,:);

% Get the HE-LTF sequence
[seqHELTF,kHELTF] = wlan.internal.heLTFSequence(cbw,cfgHE.HELTFType);

% Extract the RU of interest from the full-band HE-LTF
kRU = ofdmInfo.ActiveFrequencyIndices;
[~,ruIdx] = intersect(kHELTF,kRU);
seqHELTFRU = seqHELTF(ruIdx);

switch cfgHE.HELTFType
    % IEEE Std 802.11ax-2021, Equation 27-53
    case 1
        N_HE_LTF_Mode = 4; % Undefined
    case 2
        N_HE_LTF_Mode = 2;
    otherwise % 4
        N_HE_LTF_Mode = 1;
end

% HE masked HE-LTF sequence mode of HE-TB format
isHELTFMasked = isa(cfgHE,'wlanHETBConfig') && ~cfgHE.SingleStreamPilots;

% Get the FFT length and the subcarrier indices within the FFT
nfft = ofdmInfo.FFTLength;
kAct = wlan.internal.heRUSubcarrierIndices(cbw,ruSizeRU,ruIndexRU)+nfft/2+1;

if numSTSRU==1
    % Single STS
    est = wlan.internal.mimoChannelEstimate(rxLTFSym,seqHELTFRU,numSTSRU);

    % Remove orthogonal sequence across subcarriers if HE-LTF is masked
    if isHELTFMasked
        est = removeOrthogonalSequence(est,numSTSRU,kRU,N_HE_LTF_Mode);
    end

    % Interpolate if HE-LTF compression is used
    if N_HE_LTF_Mode>1
        est = wlan.internal.heInterpolateChannelEstimate(est,nfft,N_HE_LTF_Mode,kAct);
    end
else
    if isHELTFMasked
        % All subcarriers for MIMO estimates
        kMIMO = kRU;
        mimoInd = (1:numSC).'; % For codegen
        estMIMO = wlan.internal.mimoChannelEstimate(rxLTFSym,seqHELTFRU,numSTSRU);
        estMIMO = removeOrthogonalSequence(estMIMO,numSTSRU,kRU,N_HE_LTF_Mode);
    else
        % Only perform channel estimate for data subcarriers as pilots are single-stream
        mimoInd = ofdmInfo.DataIndices;
        kMIMO = kRU(mimoInd);
        estMIMO = wlan.internal.mimoChannelEstimate(rxLTFSym(ofdmInfo.DataIndices,:,:),seqHELTFRU(mimoInd),numSTSRU);
    end

    % Undo cyclic shift for each STS before averaging and interpolation
    csh = wlan.internal.getCyclicShiftVal('VHT',numSTSRU,cbw);
    estMIMO = wlan.internal.cyclicShiftChannelEstimate(estMIMO,-csh,nfft,kMIMO);

    % Interpolate over pilot locations and compressed subcarriers
    est = wlan.internal.heInterpolateChannelEstimate(estMIMO,nfft,N_HE_LTF_Mode,kAct,mimoInd);

    % Re-apply cyclic shift after interpolation
    est = wlan.internal.cyclicShiftChannelEstimate(est,csh,nfft,kRU);
end

% IEEE Std 802.11ax-2021, Equation 27-58 and 27-59
% For HE ER SU, the HE-LTF field is scaled by sqrt(2), therefore need to
% descale for the channel estimation
if strcmp(pktFormat,'HE-EXT-SU')
    eta = 1/sqrt(2);
else
    eta = 1;
end
est = est*eta; % Descale for HE-EXT-SU

% Channel estimate for pilots
if nargout>1
    if isHELTFMasked
        % Create single stream from MIMO pilot estimates by summing all space-time streams
        varargout{1} = sum(est(ofdmInfo.PilotIndices,:,:),2);
    else
        % Channel estimate for single-stream pilots
        % Generate the P-matrix for the maximum number of STSs as the first
        % row of P-matrix used to generate the B-matrix below is same for
        % all numbers of STSs
        Pheltf = wlan.internal.mappingMatrix(8);
        % Derive B mapping matrix from P mapping matrix
        % E.Prahia etc, Next Generation Wireless LANs 802.11n and 802.11ac, Page 198, Equation 7.26 and 7.27
        Bheltf = Pheltf(1,1:numSym);

        % Estimate the channel at pilot subcarriers accounting for polarity
        % For 1xHE-LTF, pilot indices contain subcarriers that are not
        % being used therefore reference pilots contains zeros for those
        % unused subcarriers. Correspondingly, single stream pilot channel
        % estimates will contain NaNs for those unused pilot subcarriers.
        refPilots = seqHELTFRU(ofdmInfo.PilotIndices).*Bheltf;
        chanEstSSPilots = rxLTFSym(ofdmInfo.PilotIndices,:,:)./refPilots;

        % Descale for HE_EXT_SU
        varargout{1} = chanEstSSPilots*eta;
    end
end

% Perform frequency smoothing for est
est = wlan.internal.heLTFFrequencySmoothing(est,kRU,recParams.FrequencySmoothingSpan);
end

function estData = removeOrthogonalSequence(estData,numSTSRU,k,N_HE_LTF_Mode)
    %Remove the orthogonal sequence across subcarriers
    % IEEE Std 802.11ax-2021, Equation 27-53
    M = 0; % Assume space-time streams of all users in channel estimate
    m = 1:numSTSRU;
    Pheltf = wlan.internal.mappingMatrix(8);
    seq = Pheltf(M+m,mod(ceil(k/N_HE_LTF_Mode)-1,8)+1).';
    estData = estData./seq;
end

