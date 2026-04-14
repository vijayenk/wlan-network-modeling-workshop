function x7x6 = dmgExtendedMCSScramblerBits(cfgDMG)
%dmgExtendedMCSScramblerBits Bits X6 and X7 of the scrambler initialization
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   X7X6 = dmgExtendedMCSScramblerBits(CFGDMG) returns the scrambler
%   initialization bits as 2-by-1 binary column vector.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

% IEEE 802.11-16, Section 20.6.3.1.1
params = wlan.internal.dmgExtendedMCSParameters(cfgDMG);
x7x6 = int8(int2bit(mod((params.BaseLength2-cfgDMG.PSDULength),4),2));

end