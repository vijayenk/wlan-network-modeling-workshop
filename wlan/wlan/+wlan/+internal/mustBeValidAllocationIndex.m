function mustBeValidAllocationIndex(val)
%mustBeValidAllocationIndex Validate AllocationIndex
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    mustBeNumeric(val);
    mustBeInteger(val);
    mustBeNonempty(val);
    mustBeGreaterThan(val,-2);
    mustBeLessThan(val,304);

    [M,N] = size(val);
    if M==1
        coder.internal.errorIf(~(any(numel(val)==[1 2 4])),'wlan:wlanEHTRecoveryConfig:InvalidAllocationIndex');
    elseif M==2
        coder.internal.errorIf(~(any(M==[2 4]) && any(N==[8 16])),'wlan:wlanEHTRecoveryConfig:InvalidAllocationIndex');
    else
        coder.internal.errorIf(~(M==4 && N==16),'wlan:wlanEHTRecoveryConfig:InvalidAllocationIndex');
    end
    % Allocation index 31 and 56 to 63 (inclusive) as specified in Table 36-34 of IEEE P802.11be/D4.0 are not supported
    coder.internal.errorIf(any(val(:)==[31 56:63],'all'),'wlan:wlanEHTMUConfig:InvalidAllocation');

end
