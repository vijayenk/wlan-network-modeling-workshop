function chanEst = htDataAidedChannelEstimate(demodLTF,demodData,chanEstData,noiseVarEst,cfg)
%htDataAidedChannelEstimate HT Data-aided MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST =
%   htDataAidedChannelEstimate(DEMODLTF,DEMODDATA,CHANESTDATA,NOISEEST,CFG)
%   returns channel estimate using the data subcarriers in the data field.
%
%   DEMODLTF is a complex Nst-by-Nsymltf-by-Nr array containing the
%   demodulated concatenated HT-LTF. Nsymltf is the number of demodulated
%   HT-LTF symbols.
%
%   DEMODDATA is a Nsc-by-Nsym-by-Nr array of real or complex demodulated
%   data symbols, where Nsc is the number of data subcarriers, Nsym is the
%   number of data symbols, and Nr is the number of receive antennas.
%
%   CHANESTDATA is a Nsc-by-Nsts-by-Nr array of real or complex channel
%   estimation of data subcarriers, where Nsts is the number of space-time
%   streams, i.e., excluding the number of extension streams for spatial
%   expansion cases.
%
%   NOISEVAREST is a nonnegative real scalar value.
%
%   CFG is a format configuration object of type wlanHTConfig.
%
%   Copyright 2025 The MathWorks, Inc.

% Equalize the data symbols for all STSs using HT-LTF channel estimation
if noiseVarEst == 0
    alg = "ZF";
else
    alg = "MMSE";
end
numSTS   = cfg.NumSpaceTimeStreams;
mcsTable = wlan.internal.getRateTable(cfg);
numSS    = mcsTable.Nss;
NBPSCS   = mcsTable.NBPSCS;
isSTBC   = numSS < numSTS;
if isSTBC
    eqDataSym = wlan.internal.stbcCombine(demodData,chanEstData,numSS,alg,noiseVarEst);
else
    eqDataSym = wlan.internal.equalize(demodData,chanEstData,alg,noiseVarEst);
end

% Reconstruct transmitted data symbols
inputType = class(demodLTF);
demappedDataSym = wlanConstellationDemap(eqDataSym,noiseVarEst,NBPSCS,'hard',OutputDataType=inputType); % eqDataSym is size Nsc-by-Nsym-by-Nsts
mappedDataSym = wlanConstellationMap(demappedDataSym,NBPSCS,OutputDataType=inputType);
if isSTBC
    % STBC Encode to map Nss to Nsts
    mappedDataSym = wlan.internal.stbcEncode(mappedDataSym,numSTS); % Nsc-by-Nsym-by-Nsts
end

% Reconstruct the HT-LTF symbols excluding the extended LTF symbols for
% spatial expansion configurations
% Include LTF symbols when updating channel estimation and cast them as the
% data type of demodulated LTF
[txLTFSym,Ndltf] = reconstructHTLTFSyms(cfg,inputType); % txLTFSym is size Nsc-by-Ndltf-by-Nsts
mappedSym = [txLTFSym mappedDataSym];

% Extract first Nltf symbols as Extending-LTF symbols only exist in the extension streams
% Concatenate the demodulated LTF and data symbols
demodLTFData = [demodLTF(:,1:Ndltf,:) demodData];
% Perform data-aided channel estimation
chanEst = wlan.internal.dataAidedChannelEstimate(chanEstData,demodLTFData,mappedSym,1:numSTS);
end

function [txLTFSyms,Ndltf]  = reconstructHTLTFSyms(cfg,dataType)
% Reconstruct the HT-LTF symbols excluding the extended-LTF symbols

chanBW = cfg.ChannelBandwidth;
numSTS = cfg.NumSpaceTimeStreams;

% Get OFDM parameters
ofdm = wlan.internal.vhtOFDMInfo('HT-LTF',chanBW,1);
dataIdx = ofdm.ActiveFFTIndices(ofdm.DataIndices);

% HT training fields are subset of VHT
[HTLTF,Phtltf,Ndltf] = wlan.internal.vhtltfSequence(chanBW,numSTS);

% Generate HT-LTF
txLTFSyms = coder.nullcopy(zeros(numel(dataIdx),Ndltf,numSTS,'like',cast(1i,dataType)));
Pd = Phtltf(1:numSTS,1:Ndltf);
numSC = length(dataIdx);
for i = 1:Ndltf
    txLTFSyms(:,i,:) = repmat(HTLTF(dataIdx),1,numSTS).*repmat(Pd(:,i).',numSC,1);
end
end