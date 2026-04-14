function ruSize = heFullBandRUSize(cbw)
%heFullBandRUSize RU size for a full bandwidth allocation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   RUSIZE = heFullBandRUSize(CBW) returns the RU size for a full band
%   allocation.
%
%   CBW is the channel bandwidth and must be a scalar numeric or character
%   array.
%     CBW can be 20, 40, 80, 160, or 320.
%     CBW can be 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

if ischar(cbw)
    switch cbw
        case 'CBW20'
            ruSize = 242;
        case 'CBW40'
            ruSize = 484;
        case 'CBW80'
            ruSize = 996;
        case 'CBW160'
            ruSize = 2*996;
        otherwise % CBW320
            ruSize = 4*996; % IEEE 802.11-20/1262r15, Section 2.2.4.3
    end
else
    switch cbw
        case 20
            ruSize = 242;
        case 40
            ruSize = 484;
        case 80
            ruSize = 996;
        case 160
            ruSize = 2*996;
        otherwise % CBW320
            ruSize = 4*996; % IEEE 802.11-20/1262r15, Section 2.2.4.3
    end
end
end