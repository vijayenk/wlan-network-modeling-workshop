function flag = isControlFrame(mpdu)
%isControlFrame Returns true if the given MPDU is a control frame
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   FLAG = isControlFrame(MPDU) returns true if the given MPDU is a control
%   frame.
%
%   FLAG is a logical indicating true if given MPDU is control frame and
%   indicating false otherwise.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU.

%   Copyright 2025 The MathWorks, Inc.

if isnumeric(mpdu)
    flag = any(mpdu == [wlan.internal.Constants.RTS ...
                        wlan.internal.Constants.CTS ...
                        wlan.internal.Constants.ACK ...
                        wlan.internal.Constants.BlockAck ...
                        wlan.internal.Constants.MultiSTABlockAck ...
                        wlan.internal.Constants.MURTSTrigger ...
                        wlan.internal.Constants.MUBARTrigger ...
                        wlan.internal.Constants.BasicTrigger ...
                        wlan.internal.Constants.CFEnd]);
else
    flag = any(strcmp(mpdu.Header.FrameType, ["RTS" "CTS" "ACK" "Block Ack" "Multi-STA-BA" "Trigger" "CF-End"]));
end
end