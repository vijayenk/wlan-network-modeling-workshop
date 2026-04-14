function macFrame = defaultMACFrame()
%defaultMACFrame Returns default structure for a MAC frame
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   MACFRAME = defaultMACFrame() returns default structure for a MAC
%   frame.

%   Copyright 2025 The MathWorks, Inc.

    macFrame = struct(...
                    'MACFrame', wlan.internal.utils.defaultMACFrameSU, ...
                    'PacketID', 0, ...
                    'PacketGenerationTime', 0, ...
                    'SequenceNumbers', 0);
end