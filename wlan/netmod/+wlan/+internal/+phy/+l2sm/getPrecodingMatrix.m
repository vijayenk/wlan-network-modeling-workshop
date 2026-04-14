function W = getPrecodingMatrix(sig,varargin)
%getPrecodingMatrix(SIG) return the precoding matrix
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   W = getPrecodingMatrix(SIG) returns the precoding matrix per subcarrier
%   W given the signal structure SIG. The precoding matrix is scaled such
%   that sum(abs(W).^2) = 1, as in a typical WLAN system, the power per
%   subcarrier is normalized so the total power of the transmission is 1 (0
%   dBW).
%
%   W is a Nst-by-Nsts-by-Ntx precoding matrix, where Nst is the number of
%   active subcarriers, Nsts is the number of space-time streams, and Ntx
%   is the number of transmit antennas.
%
%   SIG is a structure with the following fields:
%     Config      - Configuration object
%     Field       - 'data' or 'preamble'
%     OFDMConfig  - Structure with OFDM information
%     RUIndex     - RU index if an OFDMA configuration
%
%   OFDMConfig is a strcuture with the following fields:
%     FFTLength              - The FFT length
%     CPLength               - The cyclic prefix length
%     NumTones               - The number of active subcarriers
%     ActiveFrequencyIndices - Indices of active subcarriers relative to DC
%                              in the range [-NFFT/2, NFFT/2-1]
%     ActiveFFTIndices       - Indices of active subcarriers within the FFT
%                              in the range [1, NFFT]
%
%   W = getPrecodingMatrix(SIG,REF) returns a cell array containing the
%   precoding specified in SIG and FIELD but projected onto the OFDM
%   configuration specified in REF. REF is a structure with the same fields
%   as SIG. Each element of W contains the precoding matrix for an RU which
%   overlaps the reference OFDM subcarrier configuration.
%
%   W = getPrecodingMatrix(...,SSFACTOR) returns the precoding with
%   subcarriers subsampled SSFACTOR times.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

[parms,ref] = parseInputs(sig,varargin{:});
cfg = sig.Config;
cfgClass = class(cfg);

if strcmp(cfgClass,'wlanEHTMUConfig') && ~isEHTOFDMA(cfg)
    % If non-OFDMA EHT then no need to get OFDMA precoding matrix, use
    % simpler non-OFDMA approach
    sig.RUIndex = 1;
end

isOFDMA = strcmp(cfgClass,'wlanHEMUConfig') || (strcmp(cfgClass,'wlanEHTMUConfig') && isEHTOFDMA(cfg)); %#ok<*STISA> 
isDataField = strcmp(sig.Field,'data');

if isOFDMA && isDataField && sig.RUIndex==-1 
    % Extract the precoding from all RUs in an OFDMA configuration at
    % subcarriers specified by the reference configuration. Return a cell
    % array where each element corresponds to the overlapping subcarriers
    % from an RU. RUIndex = -1, signifies all RUs to be processed (no RU of
    % interest)
    W = getOFDMAPrecodingMatrix(sig,ref,parms.SubsampleFactor);
    return
end
    
% Get the cyclic shift applied per OFDM symbol and space-time stream or transmit antenna
[Wcs,ofdmInfo,activeSCInd] = getCyclicShiftMatrix(sig,ref,parms);

if isDataField && ~any(strcmp(cfgClass,{'wlanNonHTConfig','struct'})) % CBW320NONHTDUP
    % Apply gamma rotation per 20 MHz for formats other than HE
    if any(strcmp(cfgClass,{'wlanVHTConfig','wlanHTConfig'}))
        gamma = wlan.internal.vhtCarrierRotations(cfg.ChannelBandwidth);
        Wcs = Wcs.*gamma(ofdmInfo.ActiveFFTIndices,:,:);
    end

    % Spatial mapping only relevant for:
    % * Data field, as not supporting BeamChange=false
    % * Configurations which perform spatial mapping
    Wsm = getSpatialMappingMatrix(cfg,sig.RUIndex,ofdmInfo,activeSCInd);
    W = Wsm.*Wcs; % Nst-by-Nsts-by-Ntx
    
    if isMU(cfgClass)
        % wlanHEMUConfig or wlanEHTMUConfig
        % The transmit power is normalized by the number of space-time streams, RU size etc.
        allocInfo = ruInfo(cfg);
        ruScalingFactor = allocInfo.PowerBoostFactorPerRU(sig.RUIndex)/sqrt(allocInfo.NumSpaceTimeStreamsPerRU(sig.RUIndex));
        alpha = allocInfo.PowerBoostFactorPerRU(allocInfo.RUAssigned);
        ruSize = allocInfo.RUSizes(allocInfo.RUAssigned);
        if iscell(ruSize)
            % For wlanEHTMUConfig
            sumAlphaRUSize = 0;
            for i = 1:numel(ruSize)
                sumAlphaRUSize = sumAlphaRUSize+sum(alpha(i)*ruSize{i});
            end
            allScalingFactor = sqrt(sum(cell2mat(ruSize)))/sqrt(sumAlphaRUSize);
        else
            allScalingFactor = sqrt(sum(ruSize))/sqrt(sum(alpha.^2.*ruSize));
        end
        W = W*allScalingFactor*ruScalingFactor;
    else
        % The transmit power is normalized by the number of space-time
        % streams. To make things easier perform this normalization in the
        % precoder. The normalization by number of transmit antennas is
        % done as part of the spatial mapping matrix calculation.
        W = W/sqrt(cfg.NumSpaceTimeStreams);
    end
else
    if any(strcmp(cfgClass,{'wlanEHTMUConfig','wlanEHTTBConfig'}))
        [gamma,punc] = wlan.internal.ehtPreEHTCarrierRotations(cfg);
    else
        % Precoding includes per 20-MHz subchannel rotation
        % For all formats same pre-HE rotation applied
        [gamma,punc] = wlan.internal.hePreHECarrierRotations(cfg);
    end
    W = Wcs.*gamma(ofdmInfo.ActiveFFTIndices,:,:);

    % Normalize for punctured subchannels as per IEEE P802.11ax/D7.0, Equation 27-5
    puncNorm = sum(~punc)/numel(punc);
    W = W/sqrt(puncNorm);

    % The transmit power is normalized by the number of transmit antennas.
    % To make things easier perform this normalization in the precoder. For
    % other formats this is performed in spatial mapping - but there is no
    % spatial mapping for non-HT or preambles.
    W = W/sqrt(cfg.NumTransmitAntennas);
end

% Scale precoding matrix to reflect actual power per subcarrier
if isOFDMA && isDataField
    ruParams = ruInfo(cfg);
    ruSize = ruParams.RUSizes(ruParams.RUAssigned);
    if iscell(ruSize)
        % For wlanEHTMUConfig
        numTonesTotal = sum(cell2mat(ruSize));
    else
        numTonesTotal = sum(ruSize);
    end
else
    numTonesTotal = ofdmInfo.NumTones; % All returned subcarriers are active
end
if parms.DiffOFDMRef
    % If the subcarrier spacing is different between reference and signal
    % of interest then adjust the power per subcarrier from the signal of
    % interest. For example if there are 4x as many subcarriers in the
    % reference OFDM config, we expect the power on each to be 1/4 of the
    % power on 1 signal of interest subcarrier.
    scsDiff = wlan.internal.phy.l2sm.getOFDMInfo(ref.Config,ref.Field,ref.RUIndex).FFTLength/ofdmInfo.FFTLength;
    W = W/sqrt(scsDiff*numTonesTotal);
else
    W = W/sqrt(numTonesTotal);
end

if parms.UseRefConfig
    % If using a reference configuration return a cell array - this allows
    % for OFDMA precoding matrices for different RUs to be returned
    W = {W};
end

end

function [parms,ref] = parseInputs(sig,varargin)
    % Defaults
    ruIdx = -1;
    ruIdxRef = -1;
    ssFactor = 1;
    useRefCfg = false;
    
    cfg = sig.Config;
    field = sig.Field;
    sigClass = class(cfg);
    isMUFOI = isMU(sigClass);
    switch nargin
        case 1
            % getPrecodingMatrix(sig)
            ref = sig;
        case 2
            % getPrecodingMatrix(sig,ss)
            ref = sig;
            ssFactor = varargin{1}; % For test
        case 3
            % getPrecodingMatrix(sig,ref,ss)
            ref = varargin{1};
            useRefCfg = true;
            refClass = class(ref.Config);
            if isMU(refClass)
                ruIdxRef = ref.RUIndex;
            end
            ssFactor = varargin{2};
        otherwise
            assert(true,'Unexpected number of inputs')
    end

    sigClass = class(cfg);
    if isMUFOI
        ruIdx = sig.RUIndex;
    end
    
    % If field or waveform format for reference differ from reference then
    % project subcarriers onto appropriate reference subcarriers
    diffOFDMRef = useRefCfg && ...
        (~strcmp(field,ref.Field) || ...   % Fields are different
        ~strcmp(refClass,sigClass) || ...  % Configurations are different
        (strcmp(refClass,sigClass) && (strcmp(sigClass,'wlanHETBConfig') || strcmp(sigClass,'wlanEHTTBConfig'))) || ... 
        (strcmp(refClass,sigClass)) && isMUFOI && ((ruIdx~=ruIdxRef) || ~isequal(cfg.AllocationIndex,ref.Config.AllocationIndex))); % OFDMA allocations are different or RU indices are different

    parms = struct;
    parms.SubsampleFactor = ssFactor;
    parms.DiffOFDMRef = diffOFDMRef;
    parms.UseRefConfig = useRefCfg;
end

function [csd,ofdmInfoSig,activeSCInd] = getCyclicShiftMatrix(sig,ref,parms)
% CSD = getCyclicShiftMatrix returns a Nst-by-Nsts-by-1/Ntx matrix
% containing the cyclic shift applied to each subcarrier and space-time
% stream in the Data filed. Nst is the number of active subcarriers and
% Nsts is the number of space-time streams. If the cyclic shift applied to
% each transmitter is the same the size of third dimension returned is 1.

if parms.DiffOFDMRef
    % If the reference OFDM subcarrier indices differ from those of the
    % waveform configuration then set OFDM info such that the appropriate
    % subcarriers from the waveform configuration are selected
    ofdmInfoRef = ref.OFDMConfig;

    % Get OFDM info for OFDM config of field of interest if OFDM config not
    % provided or the OFDM config for the signal of interest is different
    % to the referece config
    ofdmInfoSig = wlan.internal.phy.l2sm.getOFDMInfo(sig.Config,sig.Field,sig.RUIndex);

    % Ratio of subcarrier spacing - ASSUME THE BANDWIDTH IS THE SAME
    r = ofdmInfoRef.FFTLength/ofdmInfoSig.FFTLength;
    
    % Find the closet subcarrier index of interferer which to each
    % subcarrier index of the reference OFDM configuration. closestSCDist
    % is the distance (in subcarriers), and activeSCInd contains the
    % indices the closest interfering subcarrier for each reference
    % subcarrier. These are the "active" subcarrier indices which are used
    % to extract the appropriate FFT indices and spatial mapping matrix
    % elements.
    [closestSCDist,activeSCInd] = min(abs(ofdmInfoSig.ActiveFrequencyIndices*r - ...
        ofdmInfoRef.ActiveFrequencyIndices'));
    
    % If the distance between the closest interference subcarrier and the
    % reference subcarrier is large then assume there is no active
    % overlapping interference subcarrier. Create an array of logical
    % indices, inactiveFFTLogInd, indicating inactive interfering
    % subcarriers.
    inactiveFFTLogInd = closestSCDist>r/2;
    
    % The above two processes result in the following:
    % Consider the interference configuration subcarrier spacing is 4x that
    % of the interference.
    %
    %       Interference:  x  x  x  A  x  x  x  B  x  x  x  C  x  x  x  D  x  x  x
    %          Reference:  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19
    %
    % The active subcarrier indices are the interference subcarrier indices
    % closest to each reference subcarrier. In the above example there are
    % four indices with values A, B, C, and D. Therefore:
    %
    %        activeSCInd:  1  1  1  1  1  2  2  2  2  3  3  3  4  4  4  4  4  4  4
    %
    % If active subcarriers are too far away they are deemed inactive:
    %
    %  inactiveFFTLogInd:  1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1
    %
    % This will result in the following precoding values being used at each
    % reference subcarrier (the inactive ones are set to 0):
    %
    %             result:  0  A  A  A  A  B  B  B  B  C  C  C  C  D  D  D  D  D  0
    
    % Update OFDM configuration of interference for subcarriers which will
    % be used for the reference configuration. Note inactive subcarriers
    % are included. Do not update ofdmInfoSig.NumTones as used for other
    % normalization.
    ofdmInfoSig.ActiveFFTIndices = ofdmInfoSig.ActiveFFTIndices(activeSCInd);
    ofdmInfoSig.ActiveFrequencyIndices = ofdmInfoSig.ActiveFFTIndices-(ofdmInfoSig.FFTLength/2+1);
else
    % Signal OFDM config same as reference
    ofdmInfoSig = ref.OFDMConfig;
    % All subcarriers to be used for reference
    activeSCInd = 1:ofdmInfoSig.NumTones;
    inactiveFFTLogInd = false(1,ofdmInfoSig.NumTones);
end

if parms.SubsampleFactor>1
    % Subsample the subcarriers. Do not update ofdmInfoSig.NumTones as used
    % for other normalization so required number in signal required.
    activeSCInd = activeSCInd(1:parms.SubsampleFactor:end);
    inactiveFFTLogInd = inactiveFFTLogInd(1:parms.SubsampleFactor:end);
    ofdmInfoSig.ActiveFFTIndices = ofdmInfoSig.ActiveFFTIndices(1:parms.SubsampleFactor:end);
    ofdmInfoSig.ActiveFrequencyIndices = ofdmInfoSig.ActiveFFTIndices-(ofdmInfoSig.FFTLength/2+1);
end

% Get the cyclic shift per space-time stream or transmit antenna depending
% on the format and field. For Non-HT format or preamble, the shift is per
% transmit antenna. Create a 'mock' channel estimate of the correct
% dimensions to apply the cyclic shift.
cfgSig = sig.Config;
cfgClass = class(cfgSig);
cbw = wlan.internal.cbwStr2Num(cfgSig.ChannelBandwidth);
isTxAntCSD = strcmp(sig.Field,'preamble') || any(strcmp(cfgClass,{'wlanNonHTConfig','struct'})); % CBW320NONHTDUP
if isTxAntCSD
    csh = wlan.internal.getCyclicShiftVal('OFDM',cfgSig.NumTransmitAntennas,cbw);
else
    switch cfgClass
        case {'wlanHEMUConfig','wlanEHTMUConfig'}
            allocInfo = ruInfo(cfgSig);
            numSTS = allocInfo.NumSpaceTimeStreamsPerRU(sig.RUIndex);
            csh = wlan.internal.getCyclicShiftVal('VHT',numSTS,cbw); % Same CSD for HE, VHT, and HT
        case {'wlanHETBConfig','wlanEHTTBConfig'}
            stsIdx = cfgSig.StartingSpaceTimeStream-1+(1:cfgSig.NumSpaceTimeStreams).';
            numSTSTotal = stsIdx(end);
            cshAll = wlan.internal.getCyclicShiftVal('VHT',numSTSTotal,cbw);
            csh = cshAll(stsIdx);
        otherwise % 'wlanHESUConfig','wlanVHTConfig','wlanHTConfig'
            csh = wlan.internal.getCyclicShiftVal('VHT',cfgSig.NumSpaceTimeStreams,cbw); % Same CSD for HE, VHT, and HT
    end
end

% Get cyclic shift per subcarrier each space-time stream/transmit antenna
csdTmp = exp(-1i*2*pi*csh.'.*ofdmInfoSig.ActiveFrequencyIndices/ofdmInfoSig.FFTLength);
if isTxAntCSD
    % CSD applied over second dimension so permute to third dimension to represent transmit antennas
    csd = permute(csdTmp,[1 3 2]);
else
    csd = csdTmp;
end

% If subcarriers are deemed to be inactive then zero them - this will "turn
% them off" in calculations using the precoding matrix
csd(inactiveFFTLogInd,:,:) = 0;

end

function Q = getSpatialMappingMatrix(cfg,ruIdx,ofdmInfo,activeSCInd)
%getSpatialMappingMatrix Returns spatial mapping matrix used.
%   Q = getSpatialMappingMatrix(CFG,RUIDX,OFDMINFO,ACTIVESCIND) returns the
%   spatial mapping matrix used for each occupied subcarrier in the data
%   portion.
%
%   Q is Nst-by-Nsts-by-Ntx where Nst is the number of occupied
%   subcarriers, Nsts is the number of space-time streams, and Ntx is the
%   number of transmit antennas.
%
%   CFG is a format configuration object.
%
%   RUIDX is the index of the RU of interest. This is used to extract an RU
%   if CFG is of type wlanHEMUConfig.
%
%   OFDMINFO is the OFDM info structure.
%
%   ACTIVESCIND is an array containing subcarrier indices to use within
%   active RU subcarriers - this allows for subsampling of the spatial
%   mapping matrix.

    if isMU(class(cfg))
        allocInfo = ruInfo(cfg);
        assert(ruIdx>0)
        numSTS = allocInfo.NumSpaceTimeStreamsPerRU(ruIdx);
        mappingType = cfg.RU{ruIdx}.SpatialMapping;
        mappingMatrix = cfg.RU{ruIdx}.SpatialMappingMatrix;
    else
        numSTS = sum(cfg.NumSpaceTimeStreams); % For VHT might be a vector
        mappingType = cfg.SpatialMapping;
        mappingMatrix = cfg.SpatialMappingMatrix;
    end
    numTx = cfg.NumTransmitAntennas;
    Nst = numel(ofdmInfo.ActiveFrequencyIndices); % ofdmInfo.NumTones is original size (not subsampled so use subsampled vector)
    
    if isenum(mappingType)
        switch mappingType
            case wlan.type.SpatialMapping.direct
                Q = repmat(permute(eye(numSTS,numTx),[3 1 2]),Nst,1,1);
            case wlan.type.SpatialMapping.hadamard
                Q = spatialMappingHadamard(numSTS,numTx,Nst);
            case wlan.type.SpatialMapping.fourier
                Q = spatialMappingFourier(numSTS,numTx,Nst);
            otherwise  % 'Custom'
                Q = spatialMappingCustom(mappingMatrix,numSTS,numTx,Nst,activeSCInd);
        end
    else
        switch mappingType
            case 'Direct'
                Q = repmat(permute(eye(numSTS,numTx),[3 1 2]),Nst,1,1);
            case 'Hadamard'
                Q = spatialMappingHadamard(numSTS,numTx,Nst);
            case 'Fourier'
                Q = spatialMappingFourier(numSTS,numTx,Nst);
            otherwise  % 'Custom'
                Q = spatialMappingCustom(mappingMatrix,numSTS,numTx,Nst,activeSCInd);
        end
    end
end

function Q = normalize(Q,numSTS)
% Normalize mapping matrix
    Q = Q * sqrt(numSTS)/norm(Q,'fro');
end

function W = getOFDMAPrecodingMatrix(sig,ref,subsampleFactor)
% Return a cell array of matrices as the configuration of interest is OFDMA
% and therefore, multiple RUs may contribute to the precoding matrix at
% reference subcarriers.

    cfg = sig.Config;

    % Get the precoding matrix for each RU at reference subcarriers and
    % find the number of overlapping subcarriers in each RU.
    allocInfo = ruInfo(cfg);
    assignedRUIndices = find(allocInfo.RUAssigned);
    numActiveRUs = numel(assignedRUIndices);
    Q = cell(1,numActiveRUs);
    activeSCPerRU = cell(1,numActiveRUs);
    numActiveSCPerRU = zeros(1,numActiveRUs);

    for iru = 1:numActiveRUs
        sig.RUIndex = assignedRUIndices(iru);
        Qtmp = wlan.internal.phy.l2sm.getPrecodingMatrix(sig,ref,subsampleFactor);
        Q(iru) = Qtmp;
        activeSCPerRUtmp = all(all(Qtmp{1}~=0,3),2);
        activeSCPerRU{iru} = activeSCPerRUtmp;
        numActiveSCPerRU(iru) = sum(activeSCPerRUtmp);
    end

    % Find which RUs contribute to the precoding at the reference location
    % as they have active subcarriers
    activeRU = numActiveSCPerRU>0;
    numActiveRUs = sum(activeRU);

    if numActiveRUs==0
        % Return an zeros precoding matrix the size of the reference (use 1
        % space-time stream) as no RUs active
        W = {zeros(size(Qtmp{1},1),1,cfg.NumTransmitAntennas)};
        return
    end
    
    activeRUInd = find(activeRU);
    lastActiveRUInd = activeRUInd(end);

    % Find any subcarriers which are not active in any of the precoding RUs
    % and therefore will have "0" precoding
    inactiveSC = true(size(Q{iru},1),1);
    for iru = 1:numActiveRUs
        idx = activeRUInd(iru); % Index of RU to use
        inactiveSC(activeSCPerRU{idx}) = false;
    end

    % Handle zero precoding subcarriers by appending or prepending to an active RUs
    inactiveSCInd = find(inactiveSC);
    prependToRUidx = zeros(1,numel(inactiveSCInd));
    appendToRUidx = zeros(1,numel(inactiveSCInd));
    for iia = 1:numel(inactiveSCInd)
        idx = find(inactiveSCInd(iia)<cumsum(numActiveSCPerRU),1,'first');
        if ~isempty(idx)
            % Treat zero subcarrier as part of next RU
            prependToRUidx(iia) = idx;
            numActiveSCPerRU(idx) = numActiveSCPerRU(idx)+1;
        else
            % If idx is empty it means 0 subcarriers occur after the last RU
            appendToRUidx(iia) = lastActiveRUInd;
        end
    end

    W = cell(1,numActiveRUs);
    for iru = 1:numActiveRUs
        % Extract active subcarriers from RU
        idx = activeRUInd(iru); % Index of RU to use
        if any(idx==prependToRUidx) || any(idx==appendToRUidx)
            % Prepend and append zeros subcarriers to RU and
            [~,Nsts,Ntx] = size(Q{idx});
            numZerosPrepend = sum(idx==prependToRUidx);
            numZerosAppend = sum(idx==appendToRUidx);
            W{iru} = [zeros(numZerosPrepend, Nsts, Ntx); Q{idx}(activeSCPerRU{idx},:,:); zeros(numZerosAppend, Nsts, Ntx)]; % Extract active subcarriers from it
        else
            W{iru} = Q{idx}(activeSCPerRU{idx},:,:);
        end
    end

end

function flag = isEHTOFDMA(cfg)
% Check if the cfg is an EHT and OFDMA configuration
    mode = compressionMode(cfg);
    flag = ~((any(mode==[1 2]) && cfg.UplinkIndication==0) || (any(mode==[0 1]) && cfg.UplinkIndication==1));
end

function Q = spatialMappingHadamard(numSTS,numTx,Nst)
    hQ = hadamard(8);
    normhQ = hQ(1:numSTS,1:numTx)/sqrt(numTx);
    Q = repmat(permute(normhQ,[3 1 2]),Nst,1,1);
end

function Q = spatialMappingFourier(numSTS,numTx,Nst)
    [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
    normQ = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx);
    Q = repmat(permute(normQ,[3 1 2]),Nst,1,1);
end

function Q = spatialMappingCustom(mappingMatrix,numSTS,numTx,Nst,activeSCInd)
    if ismatrix(mappingMatrix) && (size(mappingMatrix, 1) == numSTS) && (size(mappingMatrix, 2) == numTx)
        % MappingMatrix is Nsts-by-Ntx
        Q = repmat(permute(normalize(mappingMatrix(1:numSTS, 1:numTx),numSTS),[3 1 2]),Nst,1,1);
    else
        % MappingMatrix is Nst-by-Nsts-by-Ntx
        Q = mappingMatrix(activeSCInd,:,:); % Extract active subcarriers to use from the mapping matrix
        Qp = permute(Q,[2 3 1]);
        Qn = coder.nullcopy(complex(zeros(numSTS,numTx,Nst)));
        for i = 1:Nst
            Qn(:,:,i) = normalize(Qp(:,:,i),numSTS); % Normalize mapping matrix
        end
        Q = permute(Qn,[3 1 2]);
    end
end

function is = isMU(cfgClass)

    is = any(strcmp(cfgClass,{'wlanHEMUConfig','wlanEHTMUConfig'}));

end
