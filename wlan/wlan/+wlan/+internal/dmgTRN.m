function y = dmgTRN(cfgDMG)
%dmgTRN DMG TRN training field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgTRN(CFGDMG) generates the DMG training (TRN) field time-domain
%   waveform.
%
%   Y is the time-domain DMG training field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% If no training fields then return an empty
if ~wlan.internal.isBRPPacket(cfgDMG)
    y = complex(zeros(0,1),zeros(0,1));
    return
end

% IEEE 802.11ad Section 21.10.2.2.6/7
ce = wlan.internal.dmgCE(cfgDMG);
[Ga,Gb] = wlanGolaySequence(128);
trnSF = rotate([Ga; -Gb; Ga; Gb; Ga]); % TRN subfield
trnUnit = [ce; repmat(trnSF,4,1)];     % TRN unit
numTRNUNits = cfgDMG.TrainingLength/4;
y = repmat(trnUnit,numTRNUNits,1);
end

% Rotate by pi/2 per sample
function y = rotate(x)
    % Equivalent to y = x.*exp(1i*pi*(0:size(x,1)-1).'/2);    
    y = x.*repmat(exp(1i*pi*(0:3).'/2),size(x,1)/4,1);
end