function Nma = numMidamblePeriods(cfg,varargin)
%numMidamblePeriods Number of midamble periods in HE PPDU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NMA = numMidamblePeriods(CFG) returns the number of midamble periods in
%   an HE PPDU.
%
%   NMA = numMidamblePeriods(...,NSYM) uses the NSYM input to calculate the
%   midamble period, where NSYM is the number of data symbols in HE packet.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.

%   Copyright 2018-2022 The MathWorks, Inc.

%#codegen

if nargin == 1
    commonCodingParams = wlan.internal.heCodingParameters(cfg);
    Nsym = commonCodingParams.NSYM;
else
    Nsym = varargin{1};
end

if isa(cfg,'wlanHETBConfig')
    [~,~,Nma] = wlan.internal.heTBTimingRelatedConstants(cfg);
else
    Mma = cfg.MidamblePeriodicity;

    if (cfg.HighDoppler) && ~(Nsym<=Mma+1)
        Nma = max(0,ceil((Nsym-1)/Mma)-1); % IEEE Std 802.11ax-2021, Equation 27-117
    else
        Nma = 0; % No midamble
    end
end