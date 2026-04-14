function mustBeLogicalOrUnknown(val,propName)
%mustBeLogicalOrUnknown Validate properties
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

mustBeNumericOrLogical(val);
coder.internal.errorIf(~any(val==[-1 0 1]),'wlan:shared:InvalidLogicalUnknown',propName);

end