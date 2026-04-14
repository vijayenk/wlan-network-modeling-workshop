function y = dmgDerotate(x)
%dmgRotate DMG pi/2 de-rotation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgDerotate(X) applies pi/2 de-rotation column wise.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

y = x .* repmat(exp(-1i*pi*(0:3).'/2),size(x,1)/4,1);

end
