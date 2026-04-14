function flag = isManagementFrame(mpdu)
%isManagementFrame Returns true if the given MPDU is a management frame
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   FLAG = isManagementFrame(MPDU) returns true if the given MPDU is a
%   management frame.
%
%   FLAG is a logical indicating true if given MPDU is management frame and
%   indicating false otherwise.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU.

%   Copyright 2025 The MathWorks, Inc.

flag = ~wlan.internal.utils.isDataFrame(mpdu) && ~wlan.internal.utils.isControlFrame(mpdu);
end