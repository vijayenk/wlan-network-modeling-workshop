function mustBeValidPuncturedPattern(val)
%mustBeValidPuncturedPattern Validate PuncturedPattern
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

mustBeNumeric(val);
mustBeInteger(val);
mustBeNonempty(val);
mustBeMember(val,[-1 0 1]);
coder.internal.errorIf(~any(size(val,1)==[1 2 4]) || ~any(size(val,2)==[1 4]),'wlan:wlanEHTRecoveryConfig:InvalidPuncturedPattern');

end