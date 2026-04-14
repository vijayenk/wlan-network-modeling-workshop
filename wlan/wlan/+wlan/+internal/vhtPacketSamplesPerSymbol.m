function [Y,trc] = vhtPacketSamplesPerSymbol(cfg,numDataSym,osf)
%vhtPacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, TRC] = vhtPacketSamplesPerSymbol(CFG,NUMDATASYM,OSF) returns a
%   structure containing information including the number of samples per
%   symbol in the packet, and a structure TRC containing the field timing
%   parameters.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>.
%
%   NUMDATASYM is the number of data symbols.
%
%   OSF is the oversampling factor.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples
trc = vhtTimingRelatedConstants(cfg.GuardInterval);

% For each format calculate the number of samples per symbol and CP in the
% preamble fields which are format dependent
numVHTLTFSym = wlan.internal.numVHTLTFSymbols(sum(cfg.NumSpaceTimeStreams));

% Create a vector of the samples per symbol
samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG ...
                    trc.TSYML trc.TSYML ... % VHT-SIG-A
                    trc.TVHTSTF ... % VHT-STF
                    trc.TVHTLTFSYM*ones(1,numVHTLTFSym) ... % VHT-LTF
                    trc.TVHTSIGB ... % VHT-SIG-B
                    trc.TSYM*ones(1,numDataSym)]*sf;

% Create a vector of the CP per symbol
cpPerSymbol = [0 trc.TGI2 trc.TGI ...
               trc.TGI trc.TGI... % VHT-SIG-A
               0 ... % VHT-STF
               trc.TGI*ones(1,numVHTLTFSym) ... % VHT-LTF
               trc.TGI ... % VHT-SIG-B
               trc.TGIData*ones(1,numDataSym)]*sf;

numPPDUSamples = sum(samplesPerSymbol);
Y = struct('NumSamplesPerSymbol', samplesPerSymbol, ...
           'CPPerSymbol', cpPerSymbol, ...
           'ExtensionPerSymbol', zeros(size(samplesPerSymbol)), ...
           'NumPacketSamples', numPPDUSamples);

end

function c = vhtTimingRelatedConstants(GI)
%vhtTimingRelatedConstants VHT timing related constants

c = struct;

% Times in ns. IEEE 802.11-2016, Table 21-5. The time in us is converted to
% ns, this is to avoid inaccuracies in calculations.
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
c.TVHTLTFSYM = TSYML;
switch GI
  case 'Short'
    c.TSYM = TSYMS;
    c.TGIData = TGIS;
  otherwise % 'Long'
    c.TSYM = TSYML;
    c.TGIData = TGI;
end
c.TLSTF = 10*TDFT/4;
c.TLLTF = 2*TDFT+TGI2;
c.TLSIG = TSYML;
c.TVHTSIGA = 2*TSYML;
c.TVHTSTF = TSYML;
c.TVHTLTF = TSYML;
c.TVHTSIGB = TSYML;

end
