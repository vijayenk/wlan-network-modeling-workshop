function chanEst = ehtDataAidedChannelEstimate(demodLTF,demodData,chanEstData,noiseVarEst,cfg,userIdx)
%ehtDataAidedChannelEstimate EHT Data-aided MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST =
%   ehtDataAidedChannelEstimate(DEMODLTF,DEMODDATA,CHANESTDATA,NOISEEST,CFG,USERIDX)
%   returns channel estimate using the data subcarriers in the data field.
%
%   DEMODLTF is a complex Nst-by-Nsymltf-by-Nr array containing the
%   demodulated EHT-LTF symbols. Nsymltf is the number of demodulated
%   EHT-LTF symbols.
%
%   DEMODDATA is a Nsc-by-Nsymdata-by-Nr array of complex demodulated data
%   symbols, where Nsc is the number of data subcarriers, Nsymdata is the
%   number of data symbols, and Nr is the number of receive antennas.
%
%   CHANESTDATA is a Nsc-by-Nsts-by-Nr array of real or complex channel
%   estimation of data subcarriers, where Nsts is the number of space-time
%   streams.
%
%   NOISEEST is a nonnegative real scalar value.
%
%   CFG is a format configuration object of type wlanEHTMUConfig,
%   wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   EST = ehtDataAidedChannelEstimate(...,USERINDEX) returns channel
%   estimate using the data subcarriers in the data field for specified
%   user indices.
%
%   Copyright 2025 The MathWorks, Inc.

isRecoveryConfig = isa(cfg,"wlanEHTRecoveryConfig");
allocInfo = ruInfo(cfg);
if isRecoveryConfig
    ruSize = cfg.RUSize;
    ruConst = wlan.internal.heRUToneAllocationConstants(sum(ruSize));
    NBPSCS = wlan.internal.getMCSTable(cfg.MCS);
else
    isEHTMU = strcmp(packetFormat(cfg),'EHT-MU');
    if isEHTMU
        ruConst = wlan.internal.heRUToneAllocationConstants(sum(allocInfo.RUSizes{cfg.User{userIdx}.RUNumber}));
        NBPSCS = wlan.internal.getMCSTable(cfg.User{userIdx}.MCS);
    else
        % EHT-TB
        ruConst = wlan.internal.heRUToneAllocationConstants(sum(allocInfo.RUSizes{1}));
        NBPSCS = wlan.internal.getMCSTable(cfg.MCS);
    end
end
nSCValidation = ruConst.NSD;

% Validate the number of data subcarriers further
nSCLTF = size(demodLTF, 1);
if nSCLTF ~= nSCValidation
    [~,numSubchannels] = wlan.internal.cbw2nfft(cfg.ChannelBandwidth);
    coder.internal.error('wlan:shared:InvalidLTFSym1D','EHT',nSCLTF,nSCValidation,20*numSubchannels);
end

% Equalize the data symbols for all STSs using EHT-LTF channel estimation
if noiseVarEst == 0
    alg = "ZF";
else
    alg = "MMSE";
end
eqSymAllSTSs = wlan.internal.equalize(demodData,chanEstData,alg,noiseVarEst);

% Extract data symbols corresponding to STS indices belonging to the user
stsIdx = wlan.internal.getSTSIndices(cfg,userIdx);
eqDataSym = eqSymAllSTSs(:,:,stsIdx);

% Reconstruct transmitted data symbols
inputType = class(demodLTF);
demappedDataSym = wlanConstellationDemap(eqDataSym,noiseVarEst,NBPSCS,'hard',OutputDataType=inputType);
mappedDataSym = wlanConstellationMap(demappedDataSym,NBPSCS,OutputDataType=inputType);

% Include LTF symbols when updating channel estimation and cast them as the data type of demodulated LTF
txLTFSym = reconstructEHTLTFSyms(cfg,allocInfo,userIdx,stsIdx,inputType);
mappedSym = [txLTFSym mappedDataSym];

% Concatenate the demodulated LTF and data symbols
demodLTFData = [demodLTF demodData];
% Perform data-aided channel estimation
chanEst = wlan.internal.dataAidedChannelEstimate(chanEstData,demodLTFData,mappedSym,stsIdx);
end

function txLTFSyms = reconstructEHTLTFSyms(cfg,allocInfo,userIdx,stsIdx,dataType)
% Reconstruct the EHT-LTF symbols for the current user of interest

if isa(cfg,"wlanEHTRecoveryConfig")
    Nltf = cfg.NumEHTLTFSymbols;
    ltfType = cfg.EHTLTFType;
    ruSize = cfg.RUSize;
    ruIndices = cfg.RUIndex;
elseif strcmp(packetFormat(cfg),'EHT-MU')
    Nltf = wlan.internal.numVHTLTFSymbols(max(allocInfo.NumSpaceTimeStreamsPerRU))+cfg.NumExtraEHTLTFSymbols;
    ltfType = cfg.EHTLTFType;
    ruNumber = cfg.User{userIdx}.RUNumber;
    ruSize = allocInfo.RUSizes{ruNumber};
    ruIndices = allocInfo.RUIndices{ruNumber};
else
    % EHT-TB
    Nltf = cfg.NumEHTLTFSymbols;
    ltfType = cfg.EHTLTFType;
    ruNumber = allocInfo.RUNumbers(1);
    ruSize = allocInfo.RUSizes{ruNumber};
    ruIndices = allocInfo.RUIndices{ruNumber};
end

% Get EHT-LTF sequence
cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
[ruInd,kRU] = wlan.internal.ehtOccupiedSubcarrierIndices(cbw,ruSize,ruIndices);
[EHTLTF,kEHTLTFSeq] = wlan.internal.ehtLTFSequence(cbw,ltfType);
seqIdx = wlan.internal.intersectRUIndices(kEHTLTFSeq,kRU);
EHTLTFRU = EHTLTF(seqIdx);
% Orthogonal mapping matrix
Pehtltf = wlan.internal.mappingMatrix(Nltf);
P = Pehtltf(stsIdx,1:Nltf);
% Initialize
numSTS = numel(stsIdx);
txLTFSyms = coder.nullcopy(zeros(numel(ruInd.Data),Nltf,numSTS,'like',cast(1i,dataType)));
for k = 1:Nltf
    txLTFSyms(:,k,:) = EHTLTFRU(ruInd.Data).*P(:, k).';
end
end
