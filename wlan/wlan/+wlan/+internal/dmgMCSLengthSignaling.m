function [baseMCS,length,extMCSInd] = dmgMCSLengthSignaling(cfgDMG)
%dmgMCSLengthSignaling Signaled elements for SC MCS Length
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BASEMCS,LENGTH,EXTMCSIND] = dmgMCSLengthSignaling(CFGDMG) return the
%   DMG header field elements related to MCS and length. BASEMCS is the
%   base MCS, LENGTH is the length field value, and EXTMCSIND is the
%   extended SC MCS indication.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

if wlan.internal.isDMGExtendedMCS(cfgDMG.MCS)
    % Calculate base MCS and length
    params = wlan.internal.dmgExtendedMCSParameters(cfgDMG);
    baseMCS = wlan.internal.mcsstr2num(params.BaseMCS);
    length = params.BaseLength1-floor((params.BaseLength2-cfgDMG.PSDULength)/4); % IEEE 802.11-2016, Table 20-17
    extMCSInd = 1; % Extended MCS indication
else
    % Signal base MCS and length
    if ischar(cfgDMG.MCS)
        baseMCS = wlan.internal.mcsstr2num(cfgDMG.MCS);
    else
        baseMCS = cfgDMG.MCS;
    end
    length = cfgDMG.PSDULength;
    extMCSInd = 0;
end

end