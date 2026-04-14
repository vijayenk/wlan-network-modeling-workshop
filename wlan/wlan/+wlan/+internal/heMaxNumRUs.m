function numRU = heMaxNumRUs(chanBW,ruSize)
%heMaxNumRUs Maximum number of RUs per channel bandwidth
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NUMRU = heMaxNumRUs(CHANBW,RUSIZE) returns the maximum number of RUs.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, or 160.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 2*996.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

% IEEE P802.11ax/D4.1 Table 27-6. Maximum number of RUs for each channel
% bandwidth

switch chanBW
    case 20
        switch ruSize
            case 26
                numRU = 9;
            case 52
                numRU = 4;
            case 106
                numRU = 2;
            otherwise % 242
                assert(ruSize==242)
                numRU = 1;
        end
    case 40
        switch ruSize
            case 26
                numRU = 18;
            case 52
                numRU = 8;
            case 106
                numRU = 4;
            case 242
                numRU = 2;
            otherwise % 484
                assert(ruSize==484)
                numRU = 1;
        end
    case 80
        switch ruSize
            case 26
                numRU = 37;
            case 52
                numRU = 16;
            case 106
                numRU = 8;
            case 242
                numRU = 4;
            case 484
                numRU = 2;
            otherwise % 996
                assert(ruSize==996)
                numRU = 1;
        end
    otherwise % 160
        assert(chanBW==160);
        switch ruSize
            case 26
                numRU = 74;
            case 52
                numRU = 32;
            case 106
                numRU = 16;
            case 242
                numRU = 8;
            case 484
                numRU = 4;
            case 996
                numRU = 2;
            otherwise % 2*996
                assert(ruSize==2*996);
                numRU = 1;
        end
end

end