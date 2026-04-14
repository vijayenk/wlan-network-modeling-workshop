function [trc,NSYM,TEHTPREAMBLE] = ehtTBTimingRelatedConstants(cfg)
%ehtTBTimingRelatedConstants Timing related constants and number of data
%symbols for an EHT TB PPDU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [TRC,NSYM,TEHTPREAMBLE] = ehtTBTimingRelatedConstants(CFG) returns a
%   structure (TRC) containing timing related constants, number of data
%   symbol (NSYM), and THEPREAMBLE for an EHT TB PPDU as per IEEE
%   802.11be/D2.0, Table 36-18 and Equation 36-97.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

sf = 1e3; % Scaling factor to convert time in us into ns
trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,cfg.PreFECPaddingFactor);

PEDisambiguity = cfg.PEDisambiguity;
LSIGLength = cfg.LSIGLength;
NEHTLTF = cfg.NumEHTLTFSymbols;
TEHTPREAMBLE = trc.TRLSIG+trc.TUSIG+trc.TEHTSTFT+NEHTLTF*trc.TEHTLTFSYM; % Equation 36-97
NSYM = floor((((LSIGLength+2+3)/3)*4*sf-TEHTPREAMBLE)/trc.TSYM)-PEDisambiguity; % Equation 36-93
TPE = floor((((((LSIGLength+2+3)/3)*4)*sf-TEHTPREAMBLE)-(NSYM*trc.TSYM))/(4*sf))*4; % Equation 36-92
trc.TPE = TPE*sf; % In nsec