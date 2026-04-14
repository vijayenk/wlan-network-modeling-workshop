function y = dmgScramblerInitializationBits(cfgDMG) 
%dmgScramblerInitializationBits DMG scrambler initialization bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgScramblerInitializationBits(CFGDMG) return the scrambler
%   initialization bits as 7-by-1 binary column vector. The scrambler
%   initialization bits B7-B1 are mapped to X7-X1 as specified in IEEE Std
%   802.11ad-2012, Section 21.3.9.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

if strcmp(phyType(cfgDMG),'Control')
    if isscalar(cfgDMG.ScramblerInitialization)
        y = [1; 1; 1; int8(int2bit(cfgDMG.ScramblerInitialization(1),4))];
    else
        y = [1; 1; 1; int8(cfgDMG.ScramblerInitialization(1:4))];
    end
elseif wlan.internal.isDMGExtendedMCS(cfgDMG.MCS)
    % IEEE 802.11-16, Section 20.6.3.1.1
    x7x6 = wlan.internal.dmgExtendedMCSScramblerBits(cfgDMG);
    if isscalar(cfgDMG.ScramblerInitialization)
        y = [x7x6; int8(int2bit(cfgDMG.ScramblerInitialization(1),5))];
    else
        y = [x7x6; int8(cfgDMG.ScramblerInitialization(1:5))];
    end
else
    if isscalar(cfgDMG.ScramblerInitialization)
        y = int8(int2bit(cfgDMG.ScramblerInitialization(1),7));
    else
        y = int8(cfgDMG.ScramblerInitialization);
    end
end
end