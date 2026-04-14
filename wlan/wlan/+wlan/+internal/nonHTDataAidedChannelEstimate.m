function chanEst = nonHTDataAidedChannelEstimate(demodLTF,demodData,chanEstData,noiseVarEst,cfg)
%nonHTDataAidedChannelEstimate Non-HT Data-aided MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST =
%   nonHTDataAidedChannelEstimate(DEMODLTF,DEMODDATA,CHANESTDATA,NOISEEST,CFG)
%   returns channel estimate using the data subcarriers in the data field.
%
%   DEMODLTF is a complex Nst-by-Nsymltf-by-Nr array containing the
%   demodulated L-LTF symbols. Nsymltf is the number of demodulated L-LTF
%   symbols.
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
%   CFG is a format configuration object of type wlanNonHTConfig.
%
%   Copyright 2025 The MathWorks, Inc.

% Equalize the data symbols for all STSs using L-LTF channel estimation
if noiseVarEst == 0
    alg = "ZF";
else
    alg = "MMSE";
end
eqDataSym = wlan.internal.equalize(demodData,chanEstData,alg,noiseVarEst);

% Reconstruct transmitted data symbols
inputType = class(demodLTF);
mcsTable = wlan.internal.getRateTable(cfg);
NBPSCS = mcsTable.NBPSCS;
demappedDataSym = wlanConstellationDemap(eqDataSym,noiseVarEst,NBPSCS,'hard',OutputDataType=inputType);
mappedDataSym = wlanConstellationMap(demappedDataSym,NBPSCS,OutputDataType=inputType);

% Include L-LTF symbols when updating channel estimation and cast them as the
% data type of demodulated L-LTF
txLTFSym = reconstructLLTFSyms(cfg,inputType);
mappedSym = [txLTFSym mappedDataSym]; % Nsc-by-Nsym-by-Nt

% Concatenate the demodulated LTF and data symbols
demodLTFData = [demodLTF demodData];
% Perform data-aided channel estimation
chanEst = wlan.internal.dataAidedChannelEstimate(chanEstData,demodLTFData,mappedSym,1);
end

function txLTFSyms = reconstructLLTFSyms(cfg,dataType)
% Reconstruct L-LTF symbols

[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
LLTF = cast([lltfLower; lltfUpper],dataType);

% Replicate L-LTF sequence for each 20MHz subchannel
[~,numSubchannels] = wlan.internal.cbw2nfft(cfg.ChannelBandwidth);
sym = repmat(LLTF,numSubchannels,1);

% Replicate over multiple antennas
info = wlan.internal.vhtOFDMInfo("L-LTF",cfg.ChannelBandwidth);
symData = sym(info.DataIndices,:,:);
txLTFSyms = [symData symData]; % Two OFDM symbols
end