function ruIndex = ehtMaxNumRUs(cbw,ruSize)
%ehtMaxNumRUs Maximum RU index per channel bandwidth
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   RUINDEX = ehtMaxNumRUs(CBW,RUSIZE) returns the maximum RU index for the
%   given RU size and channel bandwidth.
%
%   CBW is the channel bandwidth and must be 20, 40, 80, 160, or 320.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 968 (MCS-14, EHT DUP mode), 996, 2*996, or 4*996

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% IEEE P802.11be/D5.0, Table 36-5/6/7. Maximum number of RUs for each channel bandwidth

switch cbw
    case 20
        ruIndex = wlan.internal.heMaxNumRUs(cbw,ruSize);
    case 40
        ruIndex = wlan.internal.heMaxNumRUs(cbw,ruSize);
    case 80
        % Table 36-5 of D5.0
        switch ruSize
            case {26,52,106,242,484}
                ruIndex = wlan.internal.heMaxNumRUs(cbw,ruSize);
            otherwise % 996 or 968
                assert(any(ruSize==[968 996]));
                ruIndex = 1;
        end
    case 160 % 160
        % Table 36-6 of D5.0
        ruIndex = wlan.internal.heMaxNumRUs(cbw,ruSize);
    otherwise % 320
        assert(cbw==320);
        % Table 36-7 of D5.0
        switch ruSize
            case 26
                ruIndex = 148;
            case 52
                ruIndex = 64;
            case 106
                ruIndex = 32;
            case 242
                ruIndex = 16;
            case 484
                ruIndex = 8;
            case 996
                ruIndex = 4;
            case 1992
                ruIndex = 2;
            otherwise % 4*996
                assert(ruSize==4*996);
                ruIndex = 1;
        end
end
