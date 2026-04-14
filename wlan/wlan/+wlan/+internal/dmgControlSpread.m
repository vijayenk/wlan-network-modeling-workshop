function y = dmgControlSpread(x)
%dmgControlSpread DMG control PHY spreading
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgControlSpread(X) spreads symbols X as per IEEE 802.11ad-2012
%   Section 21.4.3.3.5.
%
%   Y is the time-domain spread signal. It is a complex column vector of
%   length Ns, where Ns represents the number of time-domain samples.
%
%   X is the signal before spreading. It is a complex column vector of
%   length N, where N represents the number of time-domain samples.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

% IEEE 802.11ad-2012, Section 21.4.3.3.5
Ga = wlanGolaySequence(32);
% Spreading and pi/2 rotation
y = kron(x,Ga).*repmat(exp(1i*pi*(0:3).'/2),numel(x)*32/4,1);

end