function y = dmgSTF(cfgDMG)
%dmgSTF DMG Short Training Field (DMG-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgSTF(CFGDMG) generates the DMG Short Training Field (STF)
%   time-domain signal for the DMG transmission format.
%
%   Y is the time-domain DMG STF signal. It is a complex matrix of size
%   Ns-by-1, where Ns represents the number of time-domain samples.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the S1G format.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% Generate STF
[Ga,Gb] = wlanGolaySequence(128);
if strcmp(phyType(cfgDMG),'Control')
   % DMG Control PHY: IEEE Std 802.11ad 2012, Section 21.4.3.1.2
   y = rotate([repmat(Gb,48,1); -Gb; -Ga]); 
else
   % DMG SC and OFDM PHY: IEEE Std 802.11ad 2012, Section 21.3.6.2
   y = rotate([repmat(Ga,16,1); -Ga]);  
end

end

% Rotate by pi/2 per sample
function y = rotate(x)
    % Equivalent to y = x.*exp(1i*pi*(0:size(x,1)-1).'/2);    
    y = x.*repmat(exp(1i*pi*(0:3).'/2),size(x,1)/4,1);
end