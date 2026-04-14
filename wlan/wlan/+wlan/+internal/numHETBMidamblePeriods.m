function [NMA,THEPREAMBLE] = numHETBMidamblePeriods(trc,cfg)
%numHETBMidamblePeriods Number of midamble periods and preamble time in HE TB PPDU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [NMA,THEPREAMBLE] = NUMHETBMIDAMBLEPERIODS(TRC,CFG) returns the number
%   of midamble periods (NMA) and preamble time (THEPREAMBLE) in
%   nanoseconds for an HE TB PPDU. The preamble time (THEPREAMBLE) is
%   defined in Std 802.11ax-2021, Equation 27-121.
%
%   TRC is a structure containing timing related constants as per IEEE
%   Std 802.11ax-2021, Table 27-12.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.

%   Copyright 2019-2022 The MathWorks, Inc.

%#codegen

NHELTF = cfg.NumHELTFSymbols;
LSIGLength = cfg.LSIGLength;
PEDisambiguity = cfg.PEDisambiguity;
THEPREAMBLE = trc.TRLSIG+trc.THESIGA+trc.THESTFT+NHELTF*trc.THELTFSYM;
NMA = 0;
m = 2; % For HE TB, m = 2. IEEE Std 802.11ax-2021, Section 27.3.13
sf = 1e3; % Scaling factor to convert time in us into ns
if cfg.HighDoppler
    Tma = cfg.MidamblePeriodicity*trc.TSYM+NHELTF*trc.THELTFSYM; % Equation 27-116
    NMA = max(0,floor((((LSIGLength+m+3)/3)*4*sf-THEPREAMBLE-(PEDisambiguity+2)*trc.TSYM)/Tma)); % Equation 27-117
end
end