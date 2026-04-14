function [Y,trc] = s1gPacketSamplesPerSymbol(cfg,numDataSym,osf)
%s1gPacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, TRC] = s1gPacketSamplesPerSymbol(CFG,NUMDATASYM,OSF) returns a
%   structure containing information including the number of samples per
%   symbol in the packet, and a structure TRC containing the field timing
%   parameters.
%
%   CFG is the format configuration object of type wlanS1GConfig.
%
%   NUMDATASYM is the number of data symbols.
%
%   OSF is the oversampling factor.

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples
trc = s1gTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval);

% For each format calculate the number of samples per symbol and CP in the
% preamble fields which are format dependent
numLTFSym = wlan.internal.numVHTLTFSymbols(sum(cfg.NumSpaceTimeStreams));

% Create a vector of the samples per symbol and CP samples per symbol for
% the preamble
if cbw == 1
    samplesPerSymbol = [trc.TSTF ...
                        trc.TLTF1Part1 trc.TLTF1Part2 trc.TLTF1Part3... % LTF1
                        trc.TSIGSYM*ones(1,6) ... % SIG
                        trc.TLTFSYM*ones(1,numLTFSym-1)]*sf;

    cpPerSymbol = [0 ....
                   trc.TGI2 trc.TGILTF trc.TGILTF ... % LTF1
                   trc.TGISIG*ones(1,6) ... % SIG
                   trc.TGILTF*ones(1,numLTFSym-1)]*sf;

elseif ~strcmp(packetFormat(cfg),'S1G-Long')
    samplesPerSymbol = [trc.TSTF ...
                        trc.TLTF1 ...
                        trc.TSYML trc.TSYML ... % SIG
                        trc.TLTFSYM*ones(1,numLTFSym-1)]*sf;

    cpPerSymbol = [0 ...
                   trc.TGILTF1 ...
                   trc.TGISIG trc.TGISIG ... % SIG
                   trc.TGILTF*ones(1,numLTFSym-1)]*sf;
else
    samplesPerSymbol = [trc.TSTF ...
                        trc.TLTF1 ...
                        trc.TSYML trc.TSYML ... % SIG A
                        trc.TDSTF ...
                        trc.TLTFSYM*ones(1,numLTFSym) ...
                        trc.TSIGB]*sf;

    cpPerSymbol = [0 ...
                   trc.TGILTF1 ....
                   trc.TGISIGA trc.TGISIGA ...
                   0 ...
                   trc.TGILTF*ones(1,numLTFSym) ...
                   trc.TGISIGB]*sf;
end

% Add data symbols if not an NDP
if numDataSym>0
    samplesPerSymbol = [samplesPerSymbol trc.TSYML*sf trc.TSYM*ones(1,numDataSym-1)*sf];
    cpPerSymbol = [cpPerSymbol trc.TGI*sf trc.TGIData*ones(1,numDataSym-1)*sf];
end

numPPDUSamples = sum(samplesPerSymbol);
Y = struct('NumSamplesPerSymbol', round(samplesPerSymbol), ...
           'CPPerSymbol', round(cpPerSymbol), ...
           'ExtensionPerSymbol', zeros(size(samplesPerSymbol)), ...
           'NumPacketSamples', round(numPPDUSamples));

end

function c = s1gTimingRelatedConstants(chanBW,GI)
%s1gTimingRelatedConstants S1G timing related constants

c = struct;

% Times in ns. IEEE P802.11ah/D5.0, Table 24-4. The time in us is converted
% to ns, this is to avoid inaccuracies in the calculations.
TDFT = 32000;
c.TDFT = TDFT;
TGIS = 4000;
TGI = 8000;
TGI2 = 16000;
c.TGIS = TGIS;
c.TGI = TGI;
c.TGI2 = TGI2;
TSYMS = TDFT+TGIS;
TSYML = TDFT+TGI;
c.TSYMS = TSYMS;
c.TSYML = TSYML;
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
c.TLTF = TSYML;
c.TLTFSYM = TSYML;
c.TGILTF = TGI;
switch chanBW
  case 'CBW1'
    c.TSTF = 4*TSYML;
    c.TDSTF = 0;
    c.TLTF1 = 4*TDFT+2*TGI+TGI2;
    c.TLTF1Part1 = 2*TDFT+TGI2;
    c.TLTF1Part2 = TDFT+TGI;
    c.TLTF1Part3 = TDFT+TGI;
    c.TGILTF1 = TGI2;
    c.TDLTF = 0;
    c.TGIDLTF = 0;
    c.TSIG = 6*TSYML;
    c.TSIGSYM = TSYML;
    c.TGISIG = TGI;
    c.TSIGA = 0;
    c.TGISIGA = 0;
    c.TSIGB = 0;
    c.TGISIGB = 0;
  otherwise
    c.TSTF = 2*TSYML;
    c.TDSTF = TSYML;
    c.TLTF1 = 2*TDFT+TGI2;
    c.TLTF1Part1 = 0; % Used for CBW1 windowing
    c.TLTF1Part2 = 0; % Used for CBW1 windowing
    c.TLTF1Part3 = 0; % Used for CBW1 windowing
    c.TGILTF1 = TGI2;
    c.TDLTF = TSYML;
    c.TGIDLTF = TGI;
    c.TSIG = 2*TSYML;
    c.TSIGSYM = TSYML;
    c.TGISIG = TGI;
    c.TSIGA = 2*TSYML;
    c.TGISIGA = TGI;
    c.TSIGB = TSYML;
    c.TGISIGB = TGI;
end

end
