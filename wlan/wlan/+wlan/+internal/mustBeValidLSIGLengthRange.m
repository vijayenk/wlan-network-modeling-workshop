function mustBeValidLSIGLengthRange(val)
%mustBeValidLSIGLengthRange Validate LSIGLength
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2023 The MathWorks, Inc.

%#codegen
mustBeNumeric(val);
mustBeInteger(val);
coder.internal.errorIf((val<1 || val>4095) && ~(val==-1),'wlan:shared:InvalidLSIGRange');

end