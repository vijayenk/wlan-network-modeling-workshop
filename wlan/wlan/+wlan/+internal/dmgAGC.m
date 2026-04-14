function y = dmgAGC(cfgDMG)
%dmgAGC DMG beam refinement AGC field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgAGC(CFGDMG) generates the DMG beam refinement AGC field
%   time-domain waveform.
%
%   Y is the time-domain DMG beam refinement AGC field signal. It is a
%   complex column vector of length Ns, where Ns represents the number of
%   time-domain samples.
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

% IEEE 802.11ad-2012 Section 21.10.2.2.5
[Ga,Gb] = wlanGolaySequence(64);
if strcmp(phyType(cfgDMG),'Control')
    sf = rotate(repmat(Gb,5,1)); % subfield
else % SC/OFDM
    sf = rotate(repmat(Ga,5,1)); % subfield
end

N = cfgDMG.TrainingLength/4;
y = repmat(sf,4*N,1); % 4*N repetitions of the sequence

end

% Rotate by pi/2 per sample
function y = rotate(x)
    % Equivalent to y = x.*exp(1i*pi*(0:size(x,1)-1).'/2);    
    y = x.*repmat(exp(1i*pi*(0:3).'/2),size(x,1)/4,1);
end