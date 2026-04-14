function chanEst = vhtDataAidedChannelEstimate(demodLTF,demodData,chanEstData,noiseVarEst,cfg,userIdx)
%vhtDataAidedChannelEstimate VHT Data-aided MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST =
%   vhtDataAidedChannelEstimate(DEMODLTF,DEMODDATA,CHANESTDATA,NOISEEST,CFG,USERIDX)
%   returns channel estimate using the data subcarriers in the data field.
%
%   DEMODLTF is a complex Nst-by-Nsymltf-by-Nr array containing the
%   demodulated concatenated VHT-LTF. Nsymltf is the number of demodulated
%   VHT-LTF symbols.
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
%   CFG is a format configuration object of type wlanVHTConfig.
%
%   EST = vhtDataAidedChannelEstimate(...,USERINDEX) returns channel
%   estimate using the data subcarriers in the data field for specified
%   user indices.
%
%   Copyright 2025 The MathWorks, Inc.

% Equalize the data symbols for all STSs using VHT-LTF channel estimation
if noiseVarEst == 0
    alg = "ZF";
else
    alg = "MMSE";
end
mcsTable = wlan.internal.getRateTable(cfg);
if isscalar(mcsTable.NBPSCS)
	% VHT-SU with NumSpaceTimeStreams is a scalar, or VHT-SU with
	% NumSpaceTimeStreams is a vector (for the recovery use case)
    NBPSCS = mcsTable.NBPSCS;
else
    % VHT-MU
    NBPSCS = mcsTable.NBPSCS(userIdx);
end

if cfg.STBC % Only SU
    numSS = mcsTable.Nss; % Number of spatial streams
    eqDataSym = wlan.internal.stbcCombine(demodData,chanEstData,numSS,alg,noiseVarEst);
    numSTS = cfg.NumSpaceTimeStreams;
    stsIdx = 1:numSTS;
else % Both SU and MU
    eqSymAllSTSs = wlan.internal.equalize(demodData,chanEstData,alg,noiseVarEst);
    stsIdx = wlan.internal.getSTSIndices(cfg,userIdx);
    eqDataSym = eqSymAllSTSs(:,:,stsIdx);
end

% Reconstruct transmitted data symbols
inputType = class(demodLTF);
demappedDataSym = wlanConstellationDemap(eqDataSym,noiseVarEst,NBPSCS,'hard',OutputDataType=inputType);
mappedDataSym = wlanConstellationMap(demappedDataSym,NBPSCS,OutputDataType=inputType);
if cfg.STBC
    % STBC Encode to map Nss to Nsts
    mappedDataSym = wlan.internal.stbcEncode(mappedDataSym,numSTS); 
end

% Include LTF symbols when updating channel estimation and cast them as the
% data type of demodulated LTF
txLTFSymAllSTSs = reconstructVHTLTFSyms(cfg,stsIdx,inputType);

% Extract LTF symbols corresponding to STS indices belonging to the user
txLTFSym = txLTFSymAllSTSs;
mappedSym = [txLTFSym mappedDataSym];

% Concatenate the demodulated LTF and data symbols
demodLTFData = [demodLTF demodData];
% Perform data-aided channel estimation
chanEst = wlan.internal.dataAidedChannelEstimate(chanEstData,demodLTFData,mappedSym,stsIdx);
end

function txLTFSyms = reconstructVHTLTFSyms(cfg,stsIdx,dataType)
% Reconstruct the VHT-LTF symbols for the current user of interest

chanBW = cfg.ChannelBandwidth;
numSTSTotal = sum(cfg.NumSpaceTimeStreams);

% Get OFDM parameters, user VHT-LTF and ignore CP length
cfgOFDM = wlan.internal.vhtOFDMInfo('VHT-LTF',chanBW,1);

% Get VHT-LTF sequences
[VHTLTF,Pvhtltf,Nltf] = wlan.internal.vhtltfSequence(chanBW,numSTSTotal);

% P and R matrices as per IEEE Std 802.11ac-2013 Sec. 22.3.8.3.5
P = Pvhtltf(stsIdx,1:Nltf);

% Define VHT-LTF and output variable sizes
numDataSC = numel(cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices));
txLTFSyms = coder.nullcopy(zeros(numDataSC,Nltf,numel(stsIdx),'like',cast(1i,dataType)));

% Generate and modulate each VHT-LTF symbol
% Map data subcarriers and apply P mapping matrices
for i = 1:Nltf
    txLTFSyms(:,i,:) = VHTLTF(cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices)).*P(:, i).';
end
end