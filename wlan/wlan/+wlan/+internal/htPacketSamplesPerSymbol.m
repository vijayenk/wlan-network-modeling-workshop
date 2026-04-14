function [Y,trc] = htPacketSamplesPerSymbol(cfg,numDataSym,osf)
%htPacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, TRC] = htPacketSamplesPerSymbol(CFG,NUMDATASYM,OSF) returns a
%   structure containing information including the number of samples per
%   symbol in the packet, and a structure TRC containing the field timing
%   parameters.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>.
%
%   NUMDATASYM is the number of data symbols.
%
%   OSF is the oversampling factor.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples
trc = htTimingRelatedConstants(cfg.GuardInterval);

if wlan.internal.inESSMode(cfg)
    numESS = cfg.NumExtensionStreams;
else
    numESS = 0;
end
[~,~,numHTLTFSym,numELTFSym] = wlan.internal.vhtltfSequence(cfg.ChannelBandwidth,cfg.NumSpaceTimeStreams,numESS);

% Create a vector of the samples per symbol
samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG ...
                    trc.TSYML trc.TSYML ... % HT-SIG
                    trc.THTSTF trc.THTLTFSYM*ones(1,numHTLTFSym+numELTFSym) ...
                    trc.TSYM*ones(1,numDataSym)]*sf;

% Create a vector of the CP per symbol
cpPerSymbol = [0 trc.TGI2 trc.TGI ...
               trc.TGI trc.TGI... % HT-SIG
               0 trc.TGI*ones(1,numHTLTFSym+numELTFSym) ...
               trc.TGIData*ones(1,numDataSym)]*sf;

numPPDUSamples = sum(samplesPerSymbol);
Y = struct('NumSamplesPerSymbol', samplesPerSymbol, ...
           'CPPerSymbol', cpPerSymbol, ...
           'ExtensionPerSymbol', zeros(size(samplesPerSymbol)), ...
           'NumPacketSamples', numPPDUSamples);

end

function c = htTimingRelatedConstants(GI)
%htTimingRelatedConstants HT timing related constants

c = struct;

% Times in ns. IEEE 802.11-2016, Table 19-6. The time in us is converted
% to ns, this is to avoid inaccuracies in the calculations
TDFT = 3200;
c.TDFT = TDFT;
TGIS = 400;
TGI = 800;
TGI2 = 1600;
c.TGIS = TGIS;
c.TGI = TGI;
c.TGI2 = TGI2;
TSYMS = TDFT+TGIS;
TSYML = TDFT+TGI;
c.TSYMS = TSYMS;
c.TSYML = TSYML;
c.THTLTFSYM = TSYML;
switch GI
  case 'Short'
    c.TSYM = TSYMS;
    c.TGIData = TGIS;
  otherwise % 'Long'
    c.TSYM = TSYML;
    c.TGIData = TGI;
end
c.TGIHTLTF = TGI;
c.TLSTF = 10*TDFT/4;
c.TLLTF = 2*TDFT+TGI2;
c.TLSIG = TSYML;
c.THTSIG = 2*TSYML;
c.THTSTF = TSYML;
c.THTLTF1 = TSYML;
c.THTLTFS = TSYML;
c.THTLTF = TSYML;

end
