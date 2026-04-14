function mustBeValidEHTNumUsersPerContentChannel(val)
%mustBeValidEHTNumUsersPerContentChannel Validate NumUsersPerContentChannel
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    mustBeNumeric(val);
    mustBeInteger(val);
    mustBeNonempty(val);
    coder.internal.errorIf(~any(val(:)==[-1 1:72],'all'),'wlan:wlanEHTRecoveryConfig:InvalidNumUserPerContentChannelRange');
    [M,N] = size(val);
    coder.internal.errorIf(~(any(M==[1 2 4]) && any(N==[1 2])),'wlan:wlanEHTRecoveryConfig:InvalidNumUserPerContentChannel');

end
