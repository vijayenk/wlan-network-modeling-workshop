function [y,scalingFactor] = hePreHEFieldMap(dataSymbol,numTones,cfgHE)
%hePreHEFieldMap Apply Cyclic Shift and Carrier Rotation 
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = hePreHEFieldMap(DATASYMBOL,NUMTONES,CFGHE) apply cyclic shift, and
%   carrier rotation on DATASYMBOL. DATASYMBOL is a frequency domain
%   samples of a given preamble field. NUMTONES is the number of carrier
%   tones in the given preamble field. CFGHE is the format configuration
%   object.
%
%   Y is the frequency-domain preamble signal. It is a complex matrix of
%   size Ns-by-Nt where Ns represents the number of frequency-domain
%   samples and Nt represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, 
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

chBW = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);

Nfft = size(dataSymbol,1);
Nsym = size(dataSymbol,2);

% For codegen
numTx = cfgHE.NumTransmitAntennas;
[gamma,punc] = wlan.internal.hePreHECarrierRotations(cfgHE);

if isa(cfgHE,'wlanHESUConfig') && cfgHE.PreHESpatialMapping % BeamChange = false (only applicable for HE-SU)
    y = processBeamChangeUnset(dataSymbol,gamma,numTx,cfgHE.NumSpaceTimeStreams, ...
        chBW,Nfft,Nsym,cfgHE.SpatialMapping,cfgHE.SpatialMappingMatrix);

    scalingFactor = Nfft/sqrt(cfgHE.NumSpaceTimeStreams*numTones);
elseif isa(cfgHE,'wlanHESUConfig') || isa(cfgHE,'wlanHEMUConfig') || isa(cfgHE,'wlanHETBConfig')% BeamChange = true
    y = processBeamChangeSet(dataSymbol,gamma,numTx,chBW,Nfft,cfgHE.PreHECyclicShifts);
    
    scalingFactor = Nfft/sqrt(cfgHE.NumTransmitAntennas*numTones);
    if isa(cfgHE,'wlanHETBConfig') % Power scaling for Pre-HE TB fields
        scalingFactor = scalingFactor*cfgHE.PreHEPowerScalingFactor;
    end
elseif cfgHE.PreHESpatialMapping % For HEz. BeamChange = false
    S = ruInfo(cfgHE);
    applyCSD = ~cfgHE.SecureHELTF;
    y = processBeamChangeUnset(dataSymbol,gamma,numTx,S.NumSpaceTimeStreamsPerRU, ...
        chBW,Nfft,Nsym,cfgHE.SpatialMapping,cfgHE.SpatialMappingMatrix,applyCSD);
    scalingFactor = Nfft/sqrt(S.NumSpaceTimeStreamsPerRU*numTones); % Scaling factor
else % For HEz. BeamChange = true
    y = processBeamChangeSet(dataSymbol,gamma,numTx,chBW,Nfft,cfgHE.PreHECyclicShifts);

    scalingFactor = Nfft/sqrt(cfgHE.NumTransmitAntennas*numTones); % Scaling factor
end

% Normalize for punctured subchannels as per IEEE P802.11ax/D7.0, Equation 27-5
puncNorm = sum(~punc)/numel(punc);
scalingFactor = scalingFactor/sqrt(puncNorm);

end

function y = processBeamChangeSet(symOFDM,carrierRotation,numTx,chBW,Nfft,cyclicShift)
    % Apply gamma rotation to all symbols, puncturing subchannels
    symRot = symOFDM .* carrierRotation;

    % Replicate over multiple antennas
    symMIMO = repmat(symRot,1,1,numTx);

    % Total number of standard defined cyclic shifts for eight transmit
    % antenna chains for the pre-HE portion of the packet. IEEE Std
    % 802.11-2016, Table 21-10.
    numCyclicShift = 8;

    % Cyclic shift addition for pre-HE modulated field
    csh = wlan.internal.getCyclicShiftSamples(chBW,numTx,numCyclicShift,cyclicShift);
    y = wlan.internal.cyclicShift(symMIMO,csh,Nfft);
end

function y = processBeamChangeUnset(symOFDM,carrierRotation,numTx,RUNumSTS,chBW,Nfft,Nsym,SpatialMappingType,SpatialMappingMatrix,varargin)
    applyCyclicShift = true;
    if nargin>9
        applyCyclicShift = varargin{1};
    end
    % Orthogonal mapping matrix
    % P matrices as per IEEE Std 802.11-2016, Section 21.3.8.3.5.
    Pheltf = wlan.internal.mappingMatrix(RUNumSTS);    
    Rheltf = repmat(Pheltf(1,:), RUNumSTS, 1);

    % Find which subcarriers in the pre-HE fields correspond to data and
    % pilots in the 4x HE-Data field.
    % Even if an 106 tone RU is used in the band (as can be for EXT-SU),
    % assume full band allocation so we have a full band spatial mapping
    % matrix to use with the preamble
    ruSize = wlan.internal.heFullBandRUSize(chBW);
    ruIndex = 1; % Full-band RU
    [kData,kPilot] = wlan.internal.heSubcarrierIndices(chBW,ruSize,ruIndex);
    kFFT = (1:Nfft).'-Nfft/2-1;
    pilotIndexLegacy = wlan.internal.intersectRUIndices(4*kFFT,kPilot);
    dataIndexLegacy = wlan.internal.intersectRUIndices(4*kFFT,kData);

    % Apply P and R matrix and replicate over numSTS
    sigMIMO = complex(zeros(Nfft,Nsym,RUNumSTS));
    for i = 1:Nsym
        % Apply P matrix to data carrying subcarriers (in HE-Data field)
        sigMIMO(dataIndexLegacy,i,:) = symOFDM(dataIndexLegacy,i) .* Pheltf(1:RUNumSTS,1).';
        % Apply R matrix to pilot carrying subcarriers (in HE-Data field)
        sigMIMO(pilotIndexLegacy,i,:) = symOFDM(pilotIndexLegacy,i) .* Rheltf(1:RUNumSTS,1).';
    end

    if applyCyclicShift
        % Get cyclic shift per space-time stream
        csh = wlan.internal.getCyclicShiftVal('VHT',RUNumSTS,chBW);

        % Cyclic shift addition per space-time stream
        lsigCycShift = wlan.internal.cyclicShift(sigMIMO,csh,Nfft);
    else
        lsigCycShift = sigMIMO;
    end

    % Spatial mapping, take every 4th subcarrier from 4x spatial mapping
    kActive = sort([kData; kPilot]);

    % Spatial mapping
    [activeIndexLegacy,activeIndexHE] = wlan.internal.intersectRUIndices(4*kFFT,kActive);
    if any(carrierRotation==0)
        % If preamble punctured then remove punctured subcarriers
        isNotPuncturedSubcarrier = carrierRotation~=0;
        [activeInd,~,activeIndexLegacy] = wlan.internal.intersectRUIndices(activeIndexLegacy,find(isNotPuncturedSubcarrier));
        activeIndexHE = activeIndexHE(activeInd);
    end
    y = complex(zeros(Nfft,Nsym,numTx)); 
    y(activeIndexLegacy,:,:) = wlan.internal.spatialMap(lsigCycShift(activeIndexLegacy,:,:),SpatialMappingType,numTx,SpatialMappingMatrix,activeIndexHE);
end
