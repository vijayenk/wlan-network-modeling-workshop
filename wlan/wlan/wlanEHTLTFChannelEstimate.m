function [est,varargout] = wlanEHTLTFChannelEstimate(rxSym,cfgEHT,varargin)
%wlanEHTLTFChannelEstimate Channel estimation using the EHT-LTF
%   EST = wlanEHTLTFChannelEstimate(RXSYM,CFGEHT) returns the estimated
%   channel between all space-time streams and receive antennas using the
%   EHT-LTF of an EHT MU packet. The channel estimate includes the effect
%   of the applied spatial mapping matrix and cyclic shifts at the
%   transmitter. If EHT-LTF compression is used, linear interpolation is
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
%   concatenated EHT-LTF. Nsym is the number of demodulated EHT-LTF symbols.
%
%   CFGEHT is a format configuration object of type wlanEHTMUConfig,
%   wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   EST = wlanEHTLTFChannelEstimate(RXSYM,CFGEHT,RUNUMBER) returns the
%   channel estimate for the resource unit (RU) of interest, RUNUMBER.
%
%   #  For an EHT MU OFDMA PPDU type, RUNUMBER is required.
%   #  For a EHT MU non-OFDMA PPDU type, RUNUMBER is not required.
%   #  For an EHT TB PPDU type RUNUMBER is not required.
%   #  For wlanEHTRecoveryConfig, RUNUMBER is not required.
%
%   [...,CHANESTSSPILOTS] = wlanEHTLTFChannelEstimate(...) additionally
%   returns an Nsp-by-Nsym-by-Nr array characterizing the estimated channel
%   for pilot subcarrier locations for each symbol, assuming one space-time
%   stream at the transmitter. Nsp is the number of pilot subcarriers.
%
%   [EST,CHANESTSSPILOTS] = wlanEHTLTFChannelEstimate(...,NAME,VALUE)
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
validateattributes(rxSym,{'single','double'},{'3d','finite','nonempty'},mfilename,'demodulated EHT-LTF OFDM symbol(s)');
validateattributes(cfgEHT,{'wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{'scalar'},mfilename,'format configuration object');

isEHTTB = isa(cfgEHT,'wlanEHTTBConfig');
isEHTRecovery = isa(cfgEHT,'wlanEHTRecoveryConfig');

mode = compressionMode(cfgEHT);
if isEHTRecovery
    % Validate the channel bandwidth, RU Size, RU index, GuardInterval, EHTLTFType, NumEHTLTFSymbols, NumSpaceTimeStreams, and RUTotalSpaceTimeStreams
    wlan.internal.mustBeDefined(cfgEHT.ChannelBandwidth,'ChannelBandwidth');
    wlan.internal.mustBeDefined(cfgEHT.RUSize,'RUSize');
    wlan.internal.mustBeDefined(cfgEHT.RUIndex,'RUIndex');
    wlan.internal.mustBeDefined(cfgEHT.GuardInterval,'GuardInterval');
    wlan.internal.mustBeDefined(cfgEHT.EHTLTFType,'EHTLTFType');
    wlan.internal.mustBeDefined(cfgEHT.NumEHTLTFSymbols,'NumEHTLTFSymbols');
    wlan.internal.mustBeDefined(cfgEHT.RUTotalSpaceTimeStreams,'RUTotalSpaceTimeStreams');
    wlan.internal.mustBeDefined(cfgEHT.NumSpaceTimeStreams,'NumSpaceTimeStreams');
    wlan.internal.mustBeDefined(mode,'CompressionMode');
    if nargin>2 && isnumeric(varargin{1}) % wlanEHTLTFChannelEstimate(rxSym,cfgEHT,ruNumber,N-V)
        recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{2:end});
    else % wlanEHTLTFChannelEstimate(rxSym,cfgEHT) or wlanEHTLTFChannelEstimate(rxSym,cfgEHT,N-V)
        recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{:});
    end
    ruSize = cfgEHT.RUSize;
    ruIndex = cfgEHT.RUIndex;
    minNumSym = cfgEHT.NumEHTLTFSymbols;
    if any(mode==[0 2]) % MU-MIMO, OFDMA
        numSTSRU = cfgEHT.RUTotalSpaceTimeStreams;
    else % EHT SU
        numSTSRU = cfgEHT.NumSpaceTimeStreams;
    end
else
    if (mode==0 && isEHTTB) || (any(mode==[1 2]) && cfgEHT.UplinkIndication==0) || (any(mode==[0 1]) && cfgEHT.UplinkIndication==1)  % Single user: DL(EHT MU) or UL(EHT TB and EHT MU)
        if nargin>2 && isnumeric(varargin{1}) % wlanEHTLTFChannelEstimate(rxSym,cfgEHT,ruNumber,N-V)
            recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{2:end});
        else % wlanEHTLTFChannelEstimate(rxSym,cfgEHT) or wlanEHTLTFChannelEstimate(rxSym,cfgEHT,N-V)
            recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{:});
        end
        ruNumber = 1;
        numExtraEHTLTFSymbols = cfgEHT.NumExtraEHTLTFSymbols;
    else % OFDMA
        if nargin>2 && isnumeric(varargin{1}) % wlanEHTLTFChannelEstimate(rxSym,cfgEHT,ruNumber,N-V)
            validateattributes(varargin{1},{'double'},{'positive','integer','scalar'},mfilename,'RU number');
            wlan.internal.validateRUNumber(varargin{1},numel(cfgEHT.RU));
            ruNumber = varargin{1};
            recParams = wlan.internal.parseOptionalInputsChannelEstimate(mfilename,varargin{2:end});
        else % wlanEHTLTFChannelEstimate(rxSym,cfgEHT) or wlanEHTLTFChannelEstimate(rxSym,cfgEHT,N-V)
            coder.internal.error('wlan:shared:ExpectedRUNumberEHT');
        end
        numExtraEHTLTFSymbols = cfgEHT.NumExtraEHTLTFSymbols;
    end
    % Get allocation info
    allocInfo = ruInfo(cfgEHT);
    ruSize = allocInfo.RUSizes{ruNumber};
    ruIndex = allocInfo.RUIndices{ruNumber};
    numSTSRU = allocInfo.NumSpaceTimeStreamsPerRU(ruNumber); % Number of STSs in the specified RU
    if isEHTTB
        % NumEHTLTFSymbols is same across all RUs. NumEHTLTFSymbols is
        % calculated using the maximum number of STSs across all RUs in
        % an uplink transmission.
        minNumSym = cfgEHT.NumEHTLTFSymbols+numExtraEHTLTFSymbols;
    else
        numSTSMax = max(allocInfo.NumSpaceTimeStreamsPerRU); % Maximum number of STSs of all RUs
        minNumSym = wlan.internal.numVHTLTFSymbols(numSTSMax)+numExtraEHTLTFSymbols;
    end
end

% Get channel bandwidth
chanBW = cfgEHT.ChannelBandwidth;
cbw = wlan.internal.cbwStr2Num(chanBW);

% Validate the number of EHT-LTF subcarriers and OFDM symbols in rxSym
[numSC,numSym,numRx] = size(rxSym);
ofdmInfo = wlan.internal.ehtOFDMInfo('EHT-LTF',chanBW,cfgEHT.GuardInterval,ruSize,ruIndex);
coder.internal.errorIf(numSC~=ofdmInfo.NumTones,'wlan:wlanChannelEstimate:IncorrectNumSC',ofdmInfo.NumTones,numSC);
coder.internal.errorIf(numSym<minNumSym,'wlan:eht:InvalidNumLTF',numSym,minNumSym);
% Extract the required EHT-LTF OFDM symbols from rxSym
numSym = min(numSym,minNumSym);
rxLTFSym = rxSym(:,1:numSym,:);

% Get the EHT-LTF sequence
[seqEHTLTF,kEHTLTF] = wlan.internal.ehtLTFSequence(cbw,cfgEHT.EHTLTFType);

% Extract the RU of interest from the full-band EHT-LTF
kRU = ofdmInfo.ActiveFrequencyIndices;

% isPunctured variable is set when the middle 20/40 MHz subblock is
% punctured. This flag is used to manage the interpolation of compressed
% channel estimates for 1xEHT-LTF and 2xEHT-LTF types. In this scenario,
% interpolation of the compressed subcarriers is performed over a single
% RU.
if any(diff(kRU)>26) && any(cfgEHT.EHTLTFType==[1 2])
    isPunctured = true;
else
    isPunctured = false;
end

[~,ruIdx] = intersect(kEHTLTF,kRU);
seqEHTLTFRU = seqEHTLTF(ruIdx);

switch cfgEHT.EHTLTFType
    % EHT-LTF-Mode. IEEE P802.11be/D2.0, Section 36.3.12.10
    case 1
        N_EHT_LTF_Mode = 4;
    case 2
        N_EHT_LTF_Mode = 2;
    otherwise % 4
        N_EHT_LTF_Mode = 1;
end

% Get the FFT length and the subcarrier indices within the FFT
nfft = ofdmInfo.FFTLength;
kAct = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize,ruIndex)+nfft/2+1;

% ruStartIndex stores the boundaries of each RU, with a leading zero to
% represent the starting index of the first RU. Each value marks the
% starting index of a RU in the overall allocation.
ruStartOffset = [0 cumsum(ruSize)];
nsd = 1; % For codegen
nsdStartOffset = 1; % For codegen
if isPunctured
    p = wlan.internal.heRUToneAllocationConstants(ruSize);
    nsd = p.NSD; % Number of data subcarriers in an RU
    % nsdStartIndex stores the boundaries of each nsd, with a leading zero
    % to represent the starting index of the first nsd in the overall
    % allocation. Each value marks the starting index of a nsd in the
    % overall allocation.
    nsdStartOffset = [0 cumsum(nsd)];
end
est = coder.nullcopy(zeros(sum(ruSize),numSTSRU,numRx,'like',rxSym));

if numSTSRU==1
    % Single STS
    estChan = wlan.internal.mimoChannelEstimate(rxLTFSym,seqEHTLTFRU,numSTSRU);

    % Interpolate if EHT-LTF compression is used
    if N_EHT_LTF_Mode>1 && isPunctured
        for i=1:numel(ruSize) % Interpolate over a single RU
            indexRU = ruStartOffset(i)+(1:ruSize(i)); % Active RU indices
            est(indexRU,:,:) = wlan.internal.heInterpolateChannelEstimate(estChan(indexRU,:),nfft,N_EHT_LTF_Mode,kAct(indexRU));
        end
    else
        est = wlan.internal.heInterpolateChannelEstimate(estChan,nfft,N_EHT_LTF_Mode,kAct);
    end
else
    if cfgEHT.EHTLTFType==1
        kMIMO = kRU;
        mimoInd = (1:numSC).'; % For codegen
        estMIMO = wlan.internal.mimoChannelEstimate(rxLTFSym,seqEHTLTFRU,numSTSRU);
    else
        % Only perform channel estimate for data subcarriers as pilots are single-stream
        mimoInd = ofdmInfo.DataIndices;
        kMIMO = kRU(mimoInd);
        estMIMO = wlan.internal.mimoChannelEstimate(rxLTFSym(ofdmInfo.DataIndices,:,:),seqEHTLTFRU(mimoInd),numSTSRU);
    end

    % Undo cyclic shift for each STS before averaging and interpolation
    csh = wlan.internal.getCyclicShiftVal('VHT',numSTSRU,cbw);
    estMIMO = wlan.internal.cyclicShiftChannelEstimate(estMIMO,-csh,nfft,kMIMO);

    % Interpolate over pilot locations and compressed subcarriers
    if isPunctured
        for i=1:numel(ruSize) % Interpolate over a single RU
            ruMappingInd = wlan.internal.ehtOccupiedSubcarrierIndices(cbw,ruSize(i),ruIndex(i));
            kRUIndices = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize(i),ruIndex(i))+nfft/2+1;
            indexRU = ruStartOffset(i)+(1:ruSize(i)); % Active RU indices
            if cfgEHT.EHTLTFType==1
                est(indexRU,:,:) = wlan.internal.heInterpolateChannelEstimate(estMIMO(indexRU,:,:),nfft,N_EHT_LTF_Mode,kRUIndices,1:ruSize(i));
            else
                est(indexRU,:,:) = wlan.internal.heInterpolateChannelEstimate(estMIMO((1:nsd(i))+nsdStartOffset(i),:,:),nfft,N_EHT_LTF_Mode,kRUIndices,ruMappingInd.Data);
            end
        end
    else
        est = wlan.internal.heInterpolateChannelEstimate(estMIMO,nfft,N_EHT_LTF_Mode,kAct,mimoInd);
    end

    % Re-apply cyclic shift after interpolation
    est = wlan.internal.cyclicShiftChannelEstimate(est,csh,nfft,kRU);
end

% Channel estimate for pilots
if nargout>1
    if cfgEHT.EHTLTFType==1
        % Create single stream from MIMO pilot estimates by summing all
        % space-time streams for EHT TB
        varargout{1} = sum(est(ofdmInfo.PilotIndices,:,:),2);
    else
        % Channel estimate for single-stream pilots
        % Generate the P-matrix for the maximum number of STSs as the first row
        % of P-matrix used to generate the B-matrix below is same for all
        % numbers of STSs
        Pehtltf = wlan.internal.mappingMatrix(8);
        % Derive B mapping matrix from P mapping matrix
        % E.Prahia etc, Next Generation Wireless LANs 802.11n and 802.11ac, Page 198, Equation 7.26 and 7.27
        Behtltf = Pehtltf(1,1:numSym);
        % Estimate the channel at pilot subcarriers accounting for polarity
        refPilots = seqEHTLTFRU(ofdmInfo.PilotIndices).*Behtltf;
        varargout{1} = rxLTFSym(ofdmInfo.PilotIndices,:,:)./refPilots;
    end
end

% Perform frequency smoothing for est
est = wlan.internal.heLTFFrequencySmoothing(est,kRU,recParams.FrequencySmoothingSpan);
end
