function y = ehtSTF(cfgEHT,varargin)
%ehtSTF EHT Short Training Field (EHT-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtSTF(CFGHE) generates the EHT Short Training Field (EHT-STF)
%   time-domain signal for the EHT transmission format.
%
%   Y is the time-domain EHT-STF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or 
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   Y = ehtSTF(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

osf = 1;
if nargin>1
    osf = varargin{1};
end

cbw = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
allocationInfo = ruInfo(cfgEHT);
numTx = cfgEHT.NumTransmitAntennas;
isEHTTB = strcmp(packetFormat(cfgEHT),'EHT-TB');
startSpaceTimeStream = 1;

if isEHTTB
    % Get Q matrix
    Q = wlan.internal.ehtExtractRUFromSpatialMappingMatrix(cfgEHT);

    RU = {struct('Size',allocationInfo.RUSizes,'Index',allocationInfo.RUIndices, ...
        'SpatialMapping',cfgEHT.SpatialMapping,'SpatialMappingMatrix',Q)};
    startSpaceTimeStream = cfgEHT.StartingSpaceTimeStream;
    [HESSequence,HESIndex] = wlan.internal.heTBSTFSequence(cbw);
    numSamples = 8*cbw*osf; % Number of samples for TEHT-STF-T as defined in IEEE P802.11be/D2.0, Table 36-18
else
    RU = cfgEHT.RU;
    [HESSequence,HESIndex] = wlan.internal.heSTFSequence(cbw);
    numSamples = 4*cbw*osf; % Number of samples for TEHT-STF-NT as defined in IEEE P802.11be/D2.0, Table 36-18
end

% OFDM parameters
Nfft = 256*osf*cbw/20;
cpLen = 0;
numKru = zeros(1,allocationInfo.NumRUs);
numKhestf = zeros(1,allocationInfo.NumRUs);
ofdmGrid = complex(zeros(Nfft,1,numTx));
for i = 1:allocationInfo.NumRUs
    if ~allocationInfo.RUAssigned(i)
        continue
    end
    % Get the index of the RU object containing the active RU properties
    iru = allocationInfo.RUNumbers(i);

    % Determine the number of STS in this RU, and the indices of the
    % space-time streams. The indices may not always start at 1 due to the
    % trigger-based format.
    ruNumSTS = allocationInfo.NumSpaceTimeStreamsPerRU(i);
    stsIdx = startSpaceTimeStream-1+(1:ruNumSTS).';

    % Extract the RU of interest from the full-bandwidth EHT-STF
    kRU = wlan.internal.ehtRUSubcarrierIndices(cbw,RU{iru}.Size,RU{iru}.Index);

    [ruIdx,seqIdx] = wlan.internal.intersectRUIndices(kRU,HESIndex);

    ruGrid = complex(zeros(numel(kRU),1,ruNumSTS)); % NST(per RU)-by-NSYM-by-NSTS

    % The same sequence is used on all space-time streams
    ruGrid(ruIdx,:,:) = repmat(HESSequence(seqIdx),1,1,ruNumSTS);

    % Cyclic shift
    ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,kRU,stsIdx);

    % Spatial mapping
    txRUGrid = wlan.internal.spatialMap(ruGrid,RU{iru}.SpatialMapping,numTx,RU{iru}.SpatialMappingMatrix);

    numKru(i) = numel(kRU);
    numKhestf(i) = numel(ruIdx);

    % Calculate per RU scaling. IEEE P802.11be/D2.0, Equations 36-35
    if isEHTTB
        ruScalingFactor = 1/sqrt(numKhestf(1)*allocationInfo.NumSpaceTimeStreamsPerRU(1));
    else
        BetarRU = sqrt(numKru(i)./numKhestf(i));
        ruScalingFactor = (allocationInfo.PowerBoostFactorPerRU(i)*BetarRU)/sqrt(allocationInfo.NumSpaceTimeStreamsPerRU(i));
    end

    % Map subcarriers to full FFT grid and scale
    ruFFTInd = kRU+Nfft/2+1;
    ofdmGrid(ruFFTInd,:,:) = txRUGrid*ruScalingFactor;
end

% Common scaling
if isEHTTB
    BetarCommon = 1;
else
    BetarCommon = 1/sqrt(sum(allocationInfo.PowerBoostFactorPerRU(allocationInfo.RUAssigned).^2.*numKru(allocationInfo.RUAssigned)));
end

% OFDM modulate, scale, and extract required periodicity
ofdmModulated = wlan.internal.ofdmModulate(ofdmGrid,cpLen);
y = ofdmModulated(1:numSamples,:)*Nfft*BetarCommon;

end
