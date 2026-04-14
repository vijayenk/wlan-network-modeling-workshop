function y = ehtLTF(cfgEHT,varargin)
%ehtLTF EHT Long Training Field (EHT-LTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtLTF(CFGEHT) generates the EHT Long Training Field (EHT-LTF)
%   time-domain signal for the EHT transmission format.
%
%   Y is the time-domain EHT-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or 
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   Y = ehtLTF(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

osf = 1;
if nargin>1
    osf = varargin{1};
end

switch cfgEHT.EHTLTFType
    % EHT-LTF-Mode. IEEE P802.11be/D2.0, Section 36.3.12.10
    case 1
        N_EHT_LTF_Mode = 4;
    case 2
        N_EHT_LTF_Mode = 2;
    otherwise % 4
        N_EHT_LTF_Mode = 1;
end

cbw = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
numTx = cfgEHT.NumTransmitAntennas;

allocationInfo = ruInfo(cfgEHT); % RU allocation info
isEHTTB = strcmp(packetFormat(cfgEHT),'EHT-TB');

if isEHTTB
    % Get Q matrix
    Q = wlan.internal.ehtExtractRUFromSpatialMappingMatrix(cfgEHT);
    RU = {struct('Size',allocationInfo.RUSizes,'Index',allocationInfo.RUIndices, ...
        'SpatialMapping',cfgEHT.SpatialMapping,'SpatialMappingMatrix',Q)};
    powerBoostFactor = 1; % No additional power boost (alpha)
    % Number of HE-LTF symbols
    Nltf = cfgEHT.NumEHTLTFSymbols;
    stsStart = cfgEHT.StartingSpaceTimeStream;
else % EHT MU
    RU = cfgEHT.RU;
    powerBoostFactor = allocationInfo.PowerBoostFactorPerRU;
    % Number of EHT-LTF symbols including the extra EHT-LTF symbols
    Nltf = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU((allocationInfo.RUAssigned))))+cfgEHT.NumExtraEHTLTFSymbols;
    stsStart = 1;
end

% Get EHT-LTF sequence
[EHTLTF,kEHTLTFSeq] = wlan.internal.ehtLTFSequence(cbw,cfgEHT.EHTLTFType);

% Orthogonal mapping matrix
Pheltf = wlan.internal.mappingMatrix(Nltf);

Nfft = 256*osf*cbw/20;
ofdmGrid = complex(zeros(Nfft,Nltf,numTx));
cardKr = coder.nullcopy(zeros(1,allocationInfo.NumRUs));
cardKEHTLTFr = coder.nullcopy(zeros(1,allocationInfo.NumRUs));

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

    % Extract the RU of interest from the full-bandwidth EHT-LTF
    [ruInd,kRU] = wlan.internal.ehtOccupiedSubcarrierIndices(cbw,RU{jru}.Size,RU{jru}.Index);

    seqIdx = wlan.internal.intersectRUIndices(kEHTLTFSeq,kRU);
    EHTLTFRU = EHTLTF(seqIdx);

    % Calculate P and R matrices
    P = Pheltf(stsIdx,1:Nltf);
    R = repmat(Pheltf(1,1:Nltf),numSTS,1);
    ruGrid = coder.nullcopy(complex(zeros(numel(kRU),Nltf,numSTS)));

    for k = 1:Nltf
        if cfgEHT.EHTLTFType==1 % Table 36-44 of IEEE P802.11be/D2.0
            ruGrid(:,k,:) = EHTLTFRU.*P(:, k).'; % Single stream pilots are not used for 1×EHT-LTF
        else % Single stream pilots only applicable to EHT-LTF type 2 and 4
            ruGrid(ruInd.Data,k,:) = EHTLTFRU(ruInd.Data).*P(:, k).';
            ruGrid(ruInd.Pilot,k,:) = EHTLTFRU(ruInd.Pilot).*R(:, k).';
        end
    end

    % Cyclic shift
    ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,kRU,stsIdx);

    % Spatial mapping  
    txRUGrid = wlan.internal.spatialMap(ruGrid,RU{jru}.SpatialMapping,numTx,RU{jru}.SpatialMappingMatrix);

    % Calculate per RU scaling as per IEEE Std 802.11ax-2021, Section 27.3.10, Equation 27-5.
    cardKr(j) = numel(kRU);
    cardKEHTLTFr(j) = cardKr(j)/N_EHT_LTF_Mode;
    numSTSTotalRU = allocationInfo.NumSpaceTimeStreamsPerRU;

    if isEHTTB
        ruScalingFactor = 1/sqrt(numSTSTotalRU(j)*cardKEHTLTFr(j));
    else
        % Note we scale by sqrt(cardK)/sqrt(cardKEHTLTFr). Normalize the power in the RU.
        ruScalingFactor = (powerBoostFactor(j)*sqrt(cardKr(j)))/sqrt(numSTSTotalRU(j)*cardKEHTLTFr(j));
    end

    % Map subcarriers to full FFT grid and scale
    ofdmGrid(kRU+Nfft/2+1,:,:) = txRUGrid*ruScalingFactor;
end

% Overall scaling factor
if isEHTTB
    allScalingFactor = Nfft;
else
    allScalingFactor = Nfft/sqrt(sum(powerBoostFactor(allocationInfo.RUAssigned).^2.*cardKr(allocationInfo.RUAssigned)));
end

switch cfgEHT.GuardInterval
    case 0.8
        CPLenSamples = 0.8*cbw*osf;
    case 1.6
        CPLenSamples = 1.6*cbw*osf;
    otherwise % 3.2
        assert(cfgEHT.GuardInterval==3.2)
        CPLenSamples = 3.2*cbw*osf;
end
if cfgEHT.EHTLTFType == 1
    % Transmitting 1/4 of 12.8us OFDM symbol
    y = wlan.internal.ofdmModulate(ofdmGrid(1:4:end,:,:),CPLenSamples).*allScalingFactor/4; %/4 to account for NFFT/4 actual FFT size
elseif cfgEHT.EHTLTFType == 2
    % Transmitting 1/2 of 12.8us OFDM symbol
    y = wlan.internal.ofdmModulate(ofdmGrid(1:2:end,:,:),CPLenSamples).*allScalingFactor/2; %/2 to account for NFFT/2 actual FFT size
else % Sequence 4
    % Transmitting 12.8us OFDM symbol
    y = wlan.internal.ofdmModulate(ofdmGrid,CPLenSamples).*allScalingFactor;
end

end
