function y = heSTF(cfgHE,varargin)
%heSTF HE Short Training Field (HE-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSTF(CFGHE) generates the HE Short Training Field (HE-STF)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain HE-STF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heSTF(CFGHE,OSF) generates the HE-STF for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   % Example: Generate an HE-STF field for a 20 MHz, single user PPDU
%   % format.
%
%     cfgHE = wlanHESUConfig();
%     y = wlan.internal.heSTF(cfgHE);
%     plot(abs(y));
%
%   See also wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);
allocationInfo = ruInfo(cfgHE);
numTx = cfgHE.NumTransmitAntennas;
formatType = packetFormat(cfgHE);

switch class(cfgHE)
    case 'wlanHETBConfig'
        if cfgHE.FeedbackNDP % HE TB feedback NDP
           [HESSequence,HESIndex] = heTBFeedbackNDPSTFSequence(cbw,cfgHE.RUToneSetIndex);
        else 
           [HESSequence,HESIndex] = wlan.internal.heTBSTFSequence(cbw);
        end
        numSamples = 8*cbw; % Number of samples for THE-STF-T as defined in IEEE Std 802.11ax-2021, Table 27-12
    otherwise % HE MU, HE SU
        [HESSequence,HESIndex] = wlan.internal.heSTFSequence(cbw);
        numSamples = 4*cbw; % Number of samples for THE-STF-T as defined in IEEE Std 802.11ax-2021, Table 27-12
end
if nargin>1
    osf = varargin{1};
    numSamples = numSamples*osf;
end

startSpaceTimeStream = 1;
if isa(cfgHE,'wlanHEMUConfig')
    RU = cfgHE.RU;
else % Single user or trigger-based
    % Get Q matrix
    Q = wlan.internal.heExtractRUFromSpatialMappingMatrix(cfgHE);
    
    RU = {struct('Size',allocationInfo.RUSizes,'Index',allocationInfo.RUIndices, ...
        'SpatialMapping',cfgHE.SpatialMapping,'SpatialMappingMatrix',Q)};
    if isa(cfgHE,'wlanHETBConfig') % HE TB
        startSpaceTimeStream = cfgHE.StartingSpaceTimeStream;
    end
end

% OFDM parameters
Nfft = 256*cbw/20;
CPLen = 0;
if strcmp(formatType,'HE-EXT-SU')
    n_Scale = sqrt(2); 
else
    n_Scale = 1;
end

kRUPuncture = wlan.internal.hePuncturedRUSubcarrierIndices(cfgHE);
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

    % Extract the RU of interest from the full-bandwidth HE-LTF
    kRUFull = wlan.internal.heRUSubcarrierIndices(cbw,RU{iru}.Size,RU{iru}.Index);
    if ~isempty(kRUPuncture)
        [kRU,kRUInd] = setdiff(kRUFull,kRUPuncture); % Discard punctured subcarriers
    else
        kRU = kRUFull;
        kRUInd = (1:numel(kRU))';
    end
    [ruIdx,seqIdx] = wlan.internal.intersectRUIndices(kRU,HESIndex);
    ruGrid = complex(zeros(numel(kRU),1,ruNumSTS)); % NST(per RU)-by-NSYM-by-NSTS

    % The same sequence is used on all space-time streams
    ruGrid(ruIdx,:,:) = repmat(HESSequence(seqIdx),1,1,ruNumSTS);

    % Cyclic shift
    if isa(cfgHE,'wlanHEMUConfig') || isa(cfgHE,'wlanHESUConfig') || isa(cfgHE,'wlanHETBConfig')
        ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,kRU,stsIdx);
    else % For HEz
        if ~cfgHE.SecureHELTF
            ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,kRU,stsIdx);
        end
    end
    
    % Spatial mapping
    txRUGrid = wlan.internal.spatialMap(ruGrid,RU{iru}.SpatialMapping,numTx,RU{iru}.SpatialMappingMatrix,kRUInd);

    numKru(i) = numel(kRU);
    numKhestf(i) = numel(ruIdx);

    % Calculate per RU scaling. IEEE Std 802.11ax-2021, Equations 27-38, 27-39
    BetarRU = sqrt(numKru(i)./numKhestf(i));
    if strcmp(formatType,'HE-TB')
        ruScalingFactor = 1/sqrt(numKhestf(1)*allocationInfo.NumSpaceTimeStreamsPerRU(1));
    else % All other formats except HE-Trigger
        ruScalingFactor = (allocationInfo.PowerBoostFactorPerRU(i)*BetarRU)/sqrt(allocationInfo.NumSpaceTimeStreamsPerRU(i));
    end

    % Map subcarriers to full FFT grid and scale
    ruFFTInd = kRU+Nfft/2+1;
    ofdmGrid(ruFFTInd,:,:) = txRUGrid*ruScalingFactor;
end

% Common scaling. IEEE Std 802.11ax-2021, Equations 27-38, 27-39
if strcmp(formatType,'HE-TB')
    BetarCommon = 1;
else
    BetarCommon = n_Scale/sqrt(sum(allocationInfo.PowerBoostFactorPerRU(allocationInfo.RUAssigned).^2.*numKru(allocationInfo.RUAssigned)));
end

% OFDM modulate, scale, and extract required periodicity
ofdmModulated = wlan.internal.ofdmModulate(ofdmGrid,CPLen,varargin{:});
y = ofdmModulated(1:numSamples,:)*Nfft*BetarCommon;

end

function [HESSequence,HESIndex] = heTBFeedbackNDPSTFSequence(cbw,ruTonSetIndex)
%heTBFeedbackNDPSTFSequence Returns the subcarrier indices and HE-STF
%sequence of an HE TB feedback NDP

M = wlan.internal.heSTFMSequence; % M sequence of HE-STF field
switch cbw
    case 20
        [HESSequence,HESIndex] = wlan.internal.heTBSTFSequence(cbw);
    case 40
        if ruTonSetIndex <=18 % IEEE Std 802.11ax-2021, Equation 27-31
            HESSequence = [M; -1; -M]*(1+1i)/sqrt(2);
            HESSequence(1) = 0; % Set HES -248 = 0;
            HESIndex = (-248:8:-8).';
        else % RUToneSetIndex >18
            HESSequence = [M; -1; M]*(1+1i)/sqrt(2);
            HESSequence(end) = 0; % Set HES +248 = 0;
            HESIndex = (8:8:248).';
        end
    case 80
        if ruTonSetIndex <=18 % IEEE Std 802.11ax-2021, Equation 27-33
            HESIndex = (-504:8:-264).';
            HESSequence = [M; -1; M]*(1+1i)/sqrt(2);
            HESSequence(1) = 0; % Set HES -504 = 0;
        elseif ruTonSetIndex <=36
            HESIndex = (-248:8:-8).';
            HESSequence = [-M; -1; M]*(1+1i)/sqrt(2);
        elseif ruTonSetIndex <=54
            HESIndex = (8:8:248).';
            HESSequence = [-M; 1; M]*(1+1i)/sqrt(2);
        else % RUToneSetIndex <=72
            HESIndex = (264:8:504).';
            HESSequence = [-M; 1; -M]*(1+1i)/sqrt(2);
            HESSequence(end) = 0; % Set HES +504 = 0;
        end
    otherwise % 160 MHz
        if ruTonSetIndex <=18 % IEEE Std 802.11ax-2021, Equation 27-35
            HESSequence = [M; -1; M]*(1+1i)/sqrt(2);
            HESSequence(1) = 0; % Set HES -1016 = 0;
            HESIndex = (-1016:8:-776).';
        elseif ruTonSetIndex <=36
            HESSequence = [-M; -1; M]*(1+1i)/sqrt(2);
            HESIndex = (-760:8:-520).';
        elseif ruTonSetIndex <=54
            HESSequence = [-M; 1; M]*(1+1i)/sqrt(2);
            HESIndex = (-504:8:-264).';
        elseif ruTonSetIndex <=72
            HESSequence = [-M; 1; -M]*(1+1i)/sqrt(2);
            HESSequence(end) = 0; % Set HES -8 = 0;
            HESIndex = (-248:8:-8).';
        elseif ruTonSetIndex <=90
            HESSequence = [-M; 1; -M]*(1+1i)/sqrt(2);
            HESSequence(1) = 0; % Set HES +8 = 0;
            HESIndex = (8:8:248).';
        elseif ruTonSetIndex <=108
            HESSequence = [M; 1; -M]*(1+1i)/sqrt(2);
            HESIndex = (264:8:504).';
        elseif ruTonSetIndex <=126
            HESSequence = [-M; 1; M]*(1+1i)/sqrt(2);
            HESIndex = (520:8:760).';
        else % RUToneSetIndex <=144
            HESSequence = [-M; 1; -M]*(1+1i)/sqrt(2);
            HESSequence(end) = 0; % Set HES +1016 = 0;
            HESIndex = (776:8:1016).';
        end
end
end
