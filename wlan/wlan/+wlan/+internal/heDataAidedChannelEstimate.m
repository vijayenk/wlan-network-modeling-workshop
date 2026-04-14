function chanEst = heDataAidedChannelEstimate(demodLTF,demodData,chanEstData,noiseVarEst,cfg,userIdx)
%heDataAidedChannelEstimate HE Data-aided MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST =
%   heDataAidedChannelEstimate(DEMODLTF,DEMODDATA,CHANESTDATA,NOISEEST,CFG,USERIDX)
%   returns channel estimate using the data subcarriers in the data field.
%
%   DEMODLTF is a complex Nst-by-Nsymltf-by-Nr array containing the
%   demodulated concatenated HE-LTF. Nsymltf is the number of demodulated
%   HE-LTF symbols.
%
%   DEMODDATA is a Nsc-by-Nsym-by-Nr array of real or complex demodulated
%   data symbols, where Nsc is the number of data subcarriers, Nsym is the
%   number of data symbols, and Nr is the number of receive antennas.
%
%   CHANESTDATA is a Nsc-by-Nsts-by-Nr array of real or complex channel
%   estimation of data subcarriers, where Nsts is the number of space-time
%   streams.
%
%   NOISEEST is a nonnegative real scalar value.
%
%   CFG is a format configuration object of type wlanHESUConfig,
%   wlanHEMUConfig, wlanHETBConfig, or wlanHERecoveryConfig.
%
%   EST = heDataAidedChannelEstimate(...,USERINDEX) returns channel
%   estimate using the data subcarriers in the data field for specified
%   user indices.
%
%   Copyright 2025 The MathWorks, Inc.

isRecoveryConfig = isa(cfg,"wlanHERecoveryConfig");
isHEMUConfig = isa(cfg,"wlanHEMUConfig");
if isRecoveryConfig
    allocInfo = []; % Not matter for HE recovery cases as information should be within objects
    ruSize = cfg.RUSize;
    NBPSCS = wlan.internal.getMCSTable(cfg.MCS);
else
    allocInfo = ruInfo(cfg);
    if isHEMUConfig
        ruSize = allocInfo.RUSizes(cfg.User{userIdx}.RUNumber);
        NBPSCS = wlan.internal.getMCSTable(cfg.User{userIdx}.MCS);
    else
        % HE-SU, HE-EXE-SU or HE-TB
        ruSize = allocInfo.RUSizes;
        NBPSCS = wlan.internal.getMCSTable(cfg.MCS);
    end
end
ruConst = wlan.internal.heRUToneAllocationConstants(ruSize);
nSCValidation = ruConst.NSD;

% Validate the number of data subcarriers further
nSCLTF = size(demodLTF, 1);
if nSCLTF ~= nSCValidation
    [~,numSubchannels] = wlan.internal.cbw2nfft(cfg.ChannelBandwidth);
    coder.internal.error('wlan:shared:InvalidLTFSym1D','HE',nSCLTF,nSCValidation,20*numSubchannels);
end

% Equalize the data symbols for all STSs using HE-LTF channel estimation
if noiseVarEst == 0
    alg = "ZF";
else
    alg = "MMSE";
end

isSTBC = cfg.STBC && mod(size(chanEstData,2),2)==0; % HE-Data STBC combining
if isSTBC
    numSTS = size(chanEstData,2); % Number of spatial-time streams
    nSS = numSTS/2; % Number of spatial streams
    eqDataSym = wlan.internal.stbcCombine(demodData,chanEstData,nSS,alg,noiseVarEst);
    stsIdx = 1:cfg.NumSpaceTimeStreams;
else
    eqSymAllSTSs = wlan.internal.equalize(demodData,chanEstData,alg,noiseVarEst);
    % Extract data symbols corresponding to STS indices belonging to the user
    stsIdx = wlan.internal.getSTSIndices(cfg,userIdx);
    eqDataSym = eqSymAllSTSs(:,:,stsIdx);
end

% Reconstruct transmitted data symbols
inputType = class(demodLTF);
demappedDataSym = wlanConstellationDemap(eqDataSym,noiseVarEst,NBPSCS,'hard',OutputDataType=inputType);
mappedDataSym = wlanConstellationMap(demappedDataSym,NBPSCS,OutputDataType=inputType);
if isSTBC
    % STBC Encode to map Nss to Nsts
    mappedDataSym = wlan.internal.stbcEncode(mappedDataSym,numSTS); 
end

% Include LTF symbols when updating channel estimation and cast them as the data type of demodulated LTF
txLTFSym = reconstructHELTFSyms(cfg,allocInfo,userIdx,stsIdx,inputType);
mappedSym = [txLTFSym mappedDataSym];

% Concatenate the demodulated LTF and data symbols
demodLTFData = [demodLTF demodData];
% Perform data-aided channel estimation
chanEst = wlan.internal.dataAidedChannelEstimate(chanEstData,demodLTFData,mappedSym,stsIdx);
end

function txLTFSyms = reconstructHELTFSyms(cfg,allocInfo,userIdx,stsIdx,dataType)
% Reconstruct the HE-LTF symbols for the current user of interest

isRecoveryConfig = isa(cfg, "wlanHERecoveryConfig");
if isRecoveryConfig
    Nltf = cfg.NumHELTFSymbols;
    ltfType = cfg.HELTFType;
    ruSize = cfg.RUSize;
    ruIndices = cfg.RUIndex;
elseif isa(cfg, "wlanHEMUConfig")
    Nltf = wlan.internal.numVHTLTFSymbols(max(allocInfo.NumSpaceTimeStreamsPerRU));
    ltfType = cfg.HELTFType;
    ruNumber = cfg.User{userIdx}.RUNumber;
    ruSize = allocInfo.RUSizes(ruNumber);
    ruIndices = allocInfo.RUIndices(ruNumber);
else
    % HE-SU, HE-EXT-SU or HE-TB
    if isa(cfg, "wlanHETBConfig")
        Nltf = cfg.NumHELTFSymbols;
    else
        Nltf = wlan.internal.numVHTLTFSymbols(cfg.NumSpaceTimeStreams);
    end
    ltfType = cfg.HELTFType;
    ruSize = allocInfo.RUSizes;
    ruIndices = allocInfo.RUIndices;
end

% Get HE-LTF sequence
cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
[ruInd,kRUFull] = wlan.internal.heOccupiedSubcarrierIndices(cbw,ruSize,ruIndices);
[HELTF,kHELTFSeq] = wlan.internal.heLTFSequence(cbw,ltfType);
if isRecoveryConfig
    kRU = kRUFull;
else % Discard punctured subcarriers for non-HERecovery configurations
    kRUPuncture = wlan.internal.hePuncturedRUSubcarrierIndices(cfg);
    kRU = setdiff(kRUFull,kRUPuncture);
end
seqIdx = wlan.internal.intersectRUIndices(kHELTFSeq,kRU);
HELTFRU = HELTF(seqIdx);
% Orthogonal mapping matrix
Pheltf = wlan.internal.mappingMatrix(Nltf);
numSTS = numel(stsIdx);
P = Pheltf(stsIdx,1:Nltf);

% Initialize
txLTFSyms = coder.nullcopy(zeros(numel(ruInd.Data),Nltf,numSTS,'like',cast(1i,dataType)));
for k = 1:Nltf
    txLTFSyms(:,k,:) = HELTFRU(ruInd.Data).*P(:, k).';
end

% Scaling for extended-range SU PPDU
if strcmp(packetFormat(cfg),'HE-EXT-SU')
    txLTFSyms = txLTFSyms*sqrt(2); 
end
end