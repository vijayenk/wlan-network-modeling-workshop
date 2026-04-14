function NSDSHORT = heNSDShort(ruSize,DCM,varargin)
%heNSDShort NSD short as per P802.11ax/D4.1, Table 27-31
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NSDShort = heNSDShort(RUSIZE,DCM) returns NSDSHORT given the RU size
%   and whether DCM is used for the following standards - IEEE
%   P802.11ax/D4.1, Table 27-31 - IEEE P802.11be/D1.0, Table 36-46, Table
%   36-47.
%
%   NSDShort = heNSDShort(...,EHTDUPMode) returns NSDSHORT for EHT-DUP
%   mode

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

ehtDUPMode = false;
if nargin>2
   ehtDUPMode = varargin{1};
end

switch ruSize
    case 26
        if DCM
            NSDSHORT = 2;
        else
            NSDSHORT = 6;
        end
    case 52
        if DCM
            NSDSHORT = 6;
        else
            NSDSHORT = 12;
        end
    case 78 % 52+26
        if DCM
            NSDSHORT = 8;
        else
            NSDSHORT = 18;
        end
    case 106
        if DCM
            NSDSHORT = 12;
        else
            NSDSHORT = 24;
        end
    case 132 % 106+26
        if DCM
            NSDSHORT = 14;
        else
            NSDSHORT = 30;
        end
    case 242
        if DCM
            NSDSHORT = 30;
        else
            NSDSHORT = 60;
        end
    case 484
        if DCM
            NSDSHORT = 60;
        else
            NSDSHORT = 120;
        end
    case 726 % 484+242
        if DCM
            NSDSHORT = 90;
        else
            NSDSHORT = 180;
        end
    case {968 996}
        if ehtDUPMode
            NSDSHORT = 60;
        elseif DCM
            NSDSHORT = 120;
        else
            NSDSHORT = 240;
        end
    case 1480 % 996+484
        if DCM
            NSDSHORT = 180;
        else
            NSDSHORT = 360;
        end
    case 1722 % 996+484+242
        if DCM
            NSDSHORT = 210;
        else
            NSDSHORT = 420;
        end
    case 1992 % 2x996
        if ehtDUPMode
            NSDSHORT = 120;
        elseif DCM
            NSDSHORT = 246;
        else
            NSDSHORT = 492;
        end
    case 2476 % 2x996+484
        if DCM
            NSDSHORT = 306;
        else
            NSDSHORT = 612;
        end
    case 2988 % 3x996
        if DCM
            NSDSHORT = 366;
        else
            NSDSHORT = 732;
        end
    case 3472 % 3x996+484
        if DCM
            NSDSHORT = 426;
        else
            NSDSHORT = 852;
        end
    otherwise % 4*996
        assert(ruSize==3984);
        if ehtDUPMode
            NSDSHORT = 246;
        elseif DCM
            NSDSHORT = 492;
        else
            NSDSHORT = 984;
        end
end
end