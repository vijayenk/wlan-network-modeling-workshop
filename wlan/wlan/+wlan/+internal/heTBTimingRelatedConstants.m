function [trc,NSYM,NMA] = heTBTimingRelatedConstants(cfg)
%heTBTimingRelatedConstants Timing related constants and number of data
%symbols for an HE TB PPDU and HE TB feedback NDP
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [TRC,NSYM,NMA] = heTBTimingRelatedConstants(CFG) returns a structure
%   (TRC) containing timing related constants, number of data symbol (NSYM)
%   and number of midamble periods (NMA) in HE TB PPDU as per IEEE
%   Std 802.11ax-2021, Table 27-12.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.

%   Copyright 2019-2022 The MathWorks, Inc.

%#codegen

sf = 1e3; % Scaling factor to convert time in us into ns
trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,cfg.PreFECPaddingFactor);
if cfg.FeedbackNDP % HE TB feedback NDP
    trc.TPE = 0; % No PE field in HE TB feedback NDP
    NSYM = 0; % No HE-Data field in HE TB feedback NDP
    NMA = 0; % No HighDoppler in HE TB feedback NDP
    return
end

if strcmp(cfg.TriggerMethod,'TriggerFrame')
    [NMA,THEPREAMBLE] = wlan.internal.numHETBMidamblePeriods(trc,cfg);
    NHELTF = cfg.NumHELTFSymbols;
    PEDisambiguity = cfg.PEDisambiguity;
    LSIGLength = cfg.LSIGLength;
    m = 2; % For HE TB
    NSYM = floor((((LSIGLength+m+3)/3)*4*sf-THEPREAMBLE-NMA*NHELTF*trc.THELTFSYM)/trc.TSYM)-PEDisambiguity; % Equation 27-115
    TPE = floor((((((LSIGLength+m+3)/3)*4)*sf-THEPREAMBLE)-(NSYM*trc.TSYM)-(NMA*NHELTF*trc.THELTFSYM))/(4*sf))*4; % Equation 27-114
    trc.TPE = TPE*sf; % In nsec
else
    trc.TPE = cfg.DefaultPEDuration*sf; % In nsec
    NSYM = cfg.NumDataSymbols;
    NMA = 0; % No HighDoppler in TRS
end
end