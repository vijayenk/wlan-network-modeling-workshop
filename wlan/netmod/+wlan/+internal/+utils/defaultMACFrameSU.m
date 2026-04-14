function macFrameSU = defaultMACFrameSU()
%defaultMACFrameSU Returns a default structure for an SU MAC frame
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   MACFRAME = defaultMACFrameSU() returns a default structure
%   for a single-user MAC frame.

% Copyright 2025 The MathWorks, Inc.

    macFrameSU = struct(...
                    'Data', [], ...
                    'MPDU', wlan.internal.utils.defaultMPDU, ...
                    'PSDULength', 0);
end