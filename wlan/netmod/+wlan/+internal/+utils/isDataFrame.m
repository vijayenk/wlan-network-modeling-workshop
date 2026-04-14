function flag = isDataFrame(mpdu)
%isDataFrame Returns true if the given MPDU is a data frame
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   FLAG = isDataFrame(MPDU) returns true if the given MPDU is a data
%   frame.
%
%   FLAG is a logical indicating true if given MPDU is data frame and
%   indicating false otherwise.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU.

%   Copyright 2025 The MathWorks, Inc.

if isnumeric(mpdu)
    flag = (mpdu == wlan.internal.Constants.QoSData) || (mpdu == wlan.internal.Constants.QoSNull);
else
    flag = strcmp(mpdu.Header.FrameType,'QoS Data') || strcmp(mpdu.Header.FrameType,'QoS Null');
end
end