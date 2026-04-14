function Y = wurPacketSamplesPerSymbol(cfg,numDataSym,numPaddingBits,osf)
%wurPacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = wurPacketSamplesPerSymbol(CFG,NUMDATASYM,NUMPADDINGBITS,OSF)
%   returns a structure containing information including the number of
%   samples per symbol in the packet.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>.
%
%   NUMDATASYM is the number of data symbols for active subchannels.
%
%   NUMPADDINGBITS is the number of padding bits for active subchannels.
%
%   OSF is the oversampling factor.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples

activeSubchannelIndex = getActiveSubchannelIndex(cfg);
samplesPerSymbolWUR = coder.nullcopy(cell(1,cfg.NumUsers));
cpPerSymbolWUR = coder.nullcopy(cell(1,cfg.NumUsers));
samplesPerSymbol = coder.nullcopy(cell(1,cfg.NumUsers));
cpPerSymbol = coder.nullcopy(cell(1,cfg.NumUsers));

preamParams = wlan.internal.wurTimingRelatedConstants('HDR');
syncParams = wlan.internal.wurFrequentlyUsedParameters('HDR');

% Create a vector of the samples per WUR preamble field
samplesPerSymbolPreamble = [preamParams.TLSTF preamParams.TLLTF preamParams.TLSIG ...
    preamParams.TBPSKMark1 preamParams.TBPSKMark2]*sf; % WUR BPSK Mark 1 and Mark 2 fields

% Create a vector of the CP per symbol per WUR preamble field
cpPerSymbolPreamble = [0 preamParams.TGI2 preamParams.TGILegacyPreamble ...
    preamParams.TGILegacyPreamble preamParams.TGILegacyPreamble]*sf; % WUR BPSK Mark 1 and Mark 2 fields

for i=1:cfg.NumUsers
    subCh = activeSubchannelIndex(i);
    t = wlan.internal.wurTimingRelatedConstants(cfg.Subchannel{subCh}.DataRate);
    p = wlan.internal.wurFrequentlyUsedParameters(cfg.Subchannel{subCh}.DataRate);

    % For each format calculate the number of samples per symbol and CP in the
    % WUR-Sync and WUR-Data fields which are data rate dependent

    % Create a vector of the samples per WUR-Sync and WUR-Data fields
    samplesPerSymbolWUR{i} = [t.TSYNC*ones(1,p.NWURSync) ... % WUR-Sync
        t.TSym*ones(1,numDataSym(i)) ... % WUR-Data
        t.TSymHDR*ones(1,numPaddingBits(i)*syncParams.NSPDB)]*sf; % Padding

    % Create a vector of the samples per WUR packet
    samplesPerSymbol{i} = [samplesPerSymbolPreamble samplesPerSymbolWUR{i}];

    % Create a vector of the CP per symbol per WUR-Sync and WUR-Data fields
    cpPerSymbolWUR{i} = [t.GISync*ones(1,p.NWURSync) ... % WUR-Sync
        t.TGIWUR*ones(1,numDataSym(i)) ... % WUR-Data
        t.TGIDataHDR*ones(1,numPaddingBits(i)*syncParams.NSPDB)]*sf; % Padding

    % Create a vector of the CP per symbol per WUR packet
    cpPerSymbol{i} = [cpPerSymbolPreamble cpPerSymbolWUR{i}];
end

numWURSamples = sum(samplesPerSymbolWUR{1}); % Same per subchannel
numPacketSamples = sum(samplesPerSymbolPreamble)+numWURSamples;

Y = struct('NumSamplesPerSymbolPreamble', samplesPerSymbolPreamble, ...
           'NumSamplesPerSymbolWUR', samplesPerSymbolWUR, ...
           'NumSamplesPerSymbol', samplesPerSymbol, ...
           'CPPerSymbolPreamble', cpPerSymbolPreamble, ...
           'CPPerSymbolWUR', cpPerSymbolWUR, ...
           'CPPerSymbol', cpPerSymbol, ...
           'NumPacketSamples', numPacketSamples, ...
           'NumWURSamples', numWURSamples);

end