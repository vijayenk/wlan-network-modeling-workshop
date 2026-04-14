function y = dmgCE(cfgDMG)
%dmgCE DMG Channel Estimation Field (DMG-CE)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgCE(CFGDMG) generates the DMG Channel Estimation Field (CE)
%   time-domain signal for the DMG transmission format.
%
%   Y is the time-domain DMG CE signal. It is a complex matrix of size
%   Ns-by-1, where Ns represents the number of time-domain samples.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the S1G format.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% Generate CE field as per IEEE Std 802.11ad 2012 Sections 21.3.6.3
[Ga,Gb] =  wlanGolaySequence(128);
Gu512 = [-Gb; -Ga; Gb; -Ga];
Gv512 = [-Gb; Ga; -Gb; -Ga];

if strcmp(phyType(cfgDMG),'OFDM')
   y = rotate([Gv512; Gu512; -Gb]);
else % SC and Control PHY
   y = rotate([Gu512; Gv512; -Gb]);
end

end

% Rotate by pi/2 per sample
function y = rotate(x)
    % Equivalent to y = x.*exp(1i*pi*(0:size(x,1)-1).'/2);    
    y = x.*repmat(exp(1i*pi*(0:3).'/2),size(x,1)/4,1);
end