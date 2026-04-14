function bsrControl = defaultBSRControlInfo()
%defaultBSRControlInfo Returns default structure for BSR control info
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   BSRCONTROL = defaultBSRControlInfo() returns default structure for BSR
%   control info which is included as AControl field in the MPDU header.

% Copyright 2025 The MathWorks, Inc.

    bsrControl = struct('ACIBitmap', 0, ...
                        'ACIHigh', 0, ...
                        'ScalingFactor', 0, ...
                        'QueueSizeHigh', 0, ...
                        'QueueSizeAll', 0);
end