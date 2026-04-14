function cbwStr = getChannelBandwidthStr(cbw)
%getChannelBandwidthStr Return channel bandwidth as a string from the given
%channel bandwidth value in numeric format
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

switch cbw
    case 20
        cbwStr = 'CBW20';
    case 40
        cbwStr = 'CBW40';
    case 80
        cbwStr = 'CBW80';
    case 160
        cbwStr = 'CBW160';
    case 320
        cbwStr = 'CBW320';
end
end