function mustBeDefined(val,propName)
%mustBeDefined Validate properties
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   mustBeDefined(VAL,PROPNAME) validates that VAL is not set to -1 or
%   'Unknown'. Otherwise, an error is thrown indicating which property
%   PROPNAME is undefined.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    if ischar(val) || isStringScalar(val)
        coder.internal.errorIf(strcmpi(val,'Unknown'),'wlan:shared:UndefinedCharProperty',propName);
    else
        coder.internal.errorIf(all(val==-1,'all'),'wlan:shared:UndefinedProperty',propName);
    end

end
