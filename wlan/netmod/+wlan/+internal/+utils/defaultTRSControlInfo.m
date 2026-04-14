function trsControl = defaultTRSControlInfo()
%defaultTRSControlInfo Returns default structure for TRS control info
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   TRSCONTROL = defaultTRSControlInfo() returns default structure for TRS
%   control info which is included as AControl field in the MPDU header.

% Copyright 2025 The MathWorks, Inc.

    trsControl = struct('NumDataSymbols', 0, ...
                        'MCS', 0);
end