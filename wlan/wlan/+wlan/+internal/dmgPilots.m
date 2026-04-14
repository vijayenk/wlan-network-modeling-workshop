function y = dmgPilots(NSYM,z)
%dmgPilots DMG pilot sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgPilots(NSYM,Z) returns DMG pilots. Null subcarriers are not
%   included therefore PILOTS is sized 16-by-Nsym, where Nsym is the number
%   of symbols within the field.
%
%   NSYM is a scalar specifying the number of symbols.
%
%   Z is a scalar specifying the number of symbols preceding the current
%   field, and is given in the standard as an addition in the pilot
%   polarity sequence subscript, e.g. the 1 in p_{n+1} in IEEE 802.11-2012
%   Eqn 18-22.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% IEEE 802.11ad-2012 Section 21.5.3.2.5
P = [-1; 1; -1; 1; 1; -1; -1; -1; -1 ;-1; 1; 1; 1; -1; 1; 1];
p = double(wlanScramble(zeros(NSYM+z,1,'int8'),ones(7,1,'int8')).');
polaritySeq = (2*p(1+z:end)-1);
y = polaritySeq .* P;

end
