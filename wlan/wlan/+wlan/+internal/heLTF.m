function y = heLTF(cfgHE,varargin)
%heLTF HE Long Training Field (HE-LTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heLTF(CFGHE) generates the HE Long Training Field (HE-LTF)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain HE-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heLTF(CFGHE,OSF) generates the HE-LTF for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   % Example: Generate an HE-LTF field for a 80MHz, single user PPDU
%   % format.
%
%   cfgHE = wlanHESUConfig('ChannelBandwidth','CBW80');
%   y = wlan.internal.heLTF(cfgHE);
%   plot(abs(y));
%
%   See also wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

switch cfgHE.HELTFType
    % HE-LTF-Mode. IEEE Std 802.11ax-2021, Section 27.3.11.10, Equation 27-53.
    case 1
        N_HE_LTF_Mode = 4;
    case 2
        N_HE_LTF_Mode = 2;
    otherwise % 4
        N_HE_LTF_Mode = 1;
end

cbw = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);
numTx = cfgHE.NumTransmitAntennas;

allocationInfo = ruInfo(cfgHE); % RU allocation info
format = packetFormat(cfgHE);   % Packet type

if isa(cfgHE,'wlanHEMUConfig')
    RU = cfgHE.RU;
    powerBoostFactor = allocationInfo.PowerBoostFactorPerRU;
else % HE-SU, HE-EXT-SU, HE-TB
    % Get Q matrix
    Q = wlan.internal.heExtractRUFromSpatialMappingMatrix(cfgHE);

    RU = {struct('Size',allocationInfo.RUSizes,'Index',allocationInfo.RUIndices, ...
        'SpatialMapping',cfgHE.SpatialMapping,'SpatialMappingMatrix',Q)};

    powerBoostFactor = 1; % No additional power boost (alpha)
end

isHETB = false;
if isa(cfgHE,'wlanHESUConfig') || isa(cfgHE,'wlanHEMUConfig')
    % Number of HE-LTF symbols
    Nltf = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU(allocationInfo.RUAssigned)));
    stsStart = 1;
    maskWithOrthogonalCode = false;
else % HE-TB
    % Number of HE-LTF symbols
    Nltf = cfgHE.NumHELTFSymbols;
    stsStart = cfgHE.StartingSpaceTimeStream;
    % IEEE Std 802.11ax-2021, Equation 27-53
    maskWithOrthogonalCode = ~cfgHE.SingleStreamPilots;
    isHETB = true;
end

% Get HE-LTF sequence. IEEE Std 802.11ax-2021, Section 27.3.11.10
[HELTF,kHELTFSeq] = wlan.internal.heLTFSequence(cbw,cfgHE.HELTFType);

% Scaling for extended-range SU PPDU
if strcmp(format,'HE-EXT-SU')
    n_Scale = sqrt(2); 
else
    n_Scale = 1;
end

% Orthogonal mapping matrix
Pheltf = wlan.internal.mappingMatrix(Nltf);

Nfft = 256*cbw/20;
ofdmGrid = complex(zeros(Nfft,Nltf,numTx));
kRUPuncture = wlan.internal.hePuncturedRUSubcarrierIndices(cfgHE);
cardKr = coder.nullcopy(zeros(1,allocationInfo.NumRUs));
cardKHELTFr = coder.nullcopy(zeros(1,allocationInfo.NumRUs));
isFeedbackNDP = isHETB && cfgHE.FeedbackNDP;
for j = 1:allocationInfo.NumRUs
    if ~allocationInfo.RUAssigned(j)
        continue
    end
    % Get the index of the RU object containing the active RU properties
    jru = allocationInfo.RUNumbers(j);

    % Determine the number of STS in this RU, and the indices of the
    % space-time streams. The indices may not always start at 1 due to the
    % trigger-based format.
    numSTS = allocationInfo.NumSpaceTimeStreamsPerRU(j);
    stsIdx = stsStart-1+(1:numSTS).';

    % Extract the RU of interest from the full-bandwidth HE-LTF
    if isFeedbackNDP
        kRUFull = wlan.internal.heTBNDPSubcarrierIndices(cbw,cfgHE.RUToneSetIndex,cfgHE.FeedbackStatus);
    else
        kRUFull = wlan.internal.heRUSubcarrierIndices(cbw,allocationInfo.RUSizes(j),allocationInfo.RUIndices(j));
    end

    if ~isempty(kRUPuncture)
        [kRU,kRUInd] = setdiff(kRUFull,kRUPuncture); % Discard punctured subcarriers
    else
        kRU = kRUFull;
        kRUInd = (1:numel(kRU))';
    end
    seqIdx = wlan.internal.intersectRUIndices(kHELTFSeq,kRU);
    HELTFRU = HELTF(seqIdx);
    coder.varsize('HELTFRU',[],[1 1]); % For codegen

    if maskWithOrthogonalCode
        % Mask elements in the LTF sequence by an orthogonal code for UL MU-MIMO transmission. IEEE Std 802.11ax-2021, Equation 27-53
        P8by8 = wlan.internal.mappingMatrix(8);
        p_colums = mod((ceil(kRU/N_HE_LTF_Mode)-1),8)+1; % Calculate for 8x8 MIMO
        HELTFRU = HELTFRU .* P8by8(stsIdx,p_colums).';
    end

    % Calculate P and R matrices
    P = Pheltf(stsIdx,1:Nltf);
    R = repmat(Pheltf(1,1:Nltf),numSTS,1);
    ruGrid = coder.nullcopy(complex(zeros(numel(kRU),Nltf,numSTS)));

    % Indices of data and pilot subcarriers within the occupied RU
    kPilot = wlan.internal.hePilotSubcarrierIndices(cbw,allocationInfo.RUSizes(j));
    ruInd = wlan.internal.heOccupiedSubcarrierIndices(kRU,kPilot);

    for k = 1:Nltf
        if maskWithOrthogonalCode || isFeedbackNDP % IEEE Std 802.11ax-2021, Equation 27-55
            % For HE masked HE-LTF sequence mode or HE TB Feedback NDP both
            % data and pilots are multiplied by a P matrix.
            ruGrid(:,k,:) = HELTFRU .* P(:, k).';
        else
            % Single stream pilots
            ruGrid(ruInd.Data,k,:) = HELTFRU(ruInd.Data) .* P(:, k).';
            ruGrid(ruInd.Pilot,k,:) = HELTFRU(ruInd.Pilot) .* R(:, k).';
        end
    end

    % Cyclic shift
    ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,kRU,stsIdx);

    % Spatial mapping  
    txRUGrid = wlan.internal.spatialMap(ruGrid,RU{jru}.SpatialMapping,numTx,RU{jru}.SpatialMappingMatrix,kRUInd);

    % Calculate per RU scaling as per IEEE P802.11ax/D4.1, Section 27.3.9,
    % Equation 27-5.
    cardKr(j) = numel(kRU);
    cardKHELTFr(j) = cardKr(j)/N_HE_LTF_Mode;
    numSTSTotalRU = allocationInfo.NumSpaceTimeStreamsPerRU;
    if isHETB
        ruScalingFactor = 1/sqrt(numSTSTotalRU(j)*cardKHELTFr(j));
    else
        % Note we scale by sqrt(cardK)/sqrt(cardKHELTFr). This causes us to
        % normalize the power in the RU.
        ruScalingFactor = (powerBoostFactor(j)*sqrt(cardKr(j)))/sqrt(numSTSTotalRU(j)*cardKHELTFr(j));
    end

    % Map subcarriers to full FFT grid and scale
    ofdmGrid(kRU+Nfft/2+1,:,:) = txRUGrid*ruScalingFactor*n_Scale;
end

% Overall scaling factor
if isHETB
    allScalingFactor = Nfft;
else
    allScalingFactor = Nfft/sqrt(sum(powerBoostFactor(allocationInfo.RUAssigned).^2.*cardKr(allocationInfo.RUAssigned)));
end

switch cfgHE.GuardInterval
    case 0.8
        CPLenSamples = 0.8*cbw;
    case 1.6
        CPLenSamples = 1.6*cbw;
    otherwise % 3.2
        assert(cfgHE.GuardInterval==3.2)
        CPLenSamples = 3.2*cbw;
end
if cfgHE.HELTFType == 1
    % Transmitting 1/4 of 12.8us OFDM symbol
    y = wlan.internal.ofdmModulate(ofdmGrid(1:4:end,:,:),CPLenSamples,varargin{:}).*allScalingFactor/4; %/4 to account for NFFT/4 actual FFT size
elseif cfgHE.HELTFType == 2
    % Transmitting 1/2 of 12.8us OFDM symbol
    y = wlan.internal.ofdmModulate(ofdmGrid(1:2:end,:,:),CPLenSamples,varargin{:}).*allScalingFactor/2; %/2 to account for NFFT/2 actual FFT size
else % Sequence 4
    % Transmitting 12.8us OFDM symbol
    y = wlan.internal.ofdmModulate(ofdmGrid,CPLenSamples,varargin{:}).*allScalingFactor;
end

end
