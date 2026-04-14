function [Y,trc] = nonhtPacketSamplesPerSymbol(cfg,numDataSym,osf)
%nonhtPacketSamplesPerSymbol Samples per symbol information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, TRC] = nonhtPacketSamplesPerSymbol(CFG,NUMDATASYM,OSF) returns a
%   structure containing information including the number of samples per
%   symbol in the packet, and a structure TRC containing the field timing
%   parameters.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>.
%
%   NUMDATASYM is the number of data symbols.
%
%   OSF is the oversampling factor.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sf = cbw*1e-3*osf; % Scaling factor to convert bandwidth and time in ns to samples
trc = nonhtTimingRelatedConstants(cbw);

% Create a vector of the samples per symbol
samplesPerSymbol = [trc.TLSTF trc.TLLTF trc.TLSIG ...
                    trc.TSYM*ones(1,numDataSym)]*sf;

% Create a vector of the CP per symbol
cpPerSymbol = [0 trc.TGI2 trc.TGI ...
               trc.TGI*ones(1,numDataSym)]*sf;

numPPDUSamples = sum(samplesPerSymbol);
Y = struct('NumSamplesPerSymbol', samplesPerSymbol, ...
           'CPPerSymbol', cpPerSymbol, ...
           'ExtensionPerSymbol', zeros(size(samplesPerSymbol)), ...
           'NumPacketSamples', numPPDUSamples);

end

function c = nonhtTimingRelatedConstants(CBW)
%nonhtTimingRelatedConstants Non-HT timing related constants

c = struct;

% Times in ns. IEEE 802.11-2016, Table 17-5. The time in us is converted
% to ns, this is to avoid inaccuracies in the calculations
if CBW<20
    s = 20/CBW; % Subcarrier spacing scales with bandwidth
else
    s = 1; % Subcarrier spacing constant for all other bandwidths
end
TDFT = 3200*s;
c.TDFT = TDFT;
TGI = TDFT/4;
TGI2 = TDFT/2;
c.TGI = TGI;
c.TGI2 = TGI2;
TSYM = TDFT+TGI;
c.TSYM = TSYM;
c.TLSTF = 10*TDFT/4;
c.TLLTF = 2*TDFT+TGI2;
c.TLSIG = TSYM;

end
