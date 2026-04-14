function p = heRUToneAllocationConstants(in)
%heRUToneAllocationConstants OFDMA tone allocation constants
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   P = heRUToneAllocationConstants(RUSIZE) returns a structure with the
%   following fields:
%     NSD - Number of data carrying subcarriers in an RU
%     NSP - Number of pilot carrying subcarriers in an RU
%     NST - Total number of subcarriers in an RU
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 78,
%   106, 132, 242, 484, 726, 968, 996, 1480, 1722, 1992, 2476, 2988, 3472,
%   or 3984.
%
%   P = heRUToneAllocationConstants(CFG) returns the tone allocation
%   constants for each RU. Each field in P is a 1-by-NumRUs vector.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

% IEEE Std 802.11ax-2021, Table 27-14 - Tone allocation related constants
% for RUs in an OFDMA HE PPDU
% IEEE P802.11be/D2.0, Table 36-19, Table 36-20, Table 36-21 - Subcarrier
% allocation related constants

if nargin>0
    if isnumeric(in)
        % RU size
        ruSize = in;
        numRUSizes = size(ruSize,2);
    else
        % Config object
        allocation = in;
        allocationInfo = ruInfo(allocation);
        ruSize = allocationInfo.RUSizes;
        numRUSizes = size(ruSize,2);
    end
else
    numRUSizes = 17; % All RUs
    ruSize = [26 52 78 106 132 242 484 726 968 996 1480 1722 1992 2476 2988 3472 3984];
end

if numRUSizes==1
    % Optimized for single RU
    switch ruSize
        case 26
            p = struct;
            p.NSD = 24;
            p.NSP = 2;
            p.NST = 26;
        case 52
            p = struct;
            p.NSD = 48;
            p.NSP = 4;
            p.NST = 52;
        case 78 % 26+52
            p = struct;
            p.NSD = 72;
            p.NSP = 6;
            p.NST = 78;
        case 106
            p = struct;
            p.NSD = 102;
            p.NSP = 4;
            p.NST = 106;
        case 132 % 106+26
            p = struct;
            p.NSD = 126;
            p.NSP = 6;
            p.NST = 132;
        case 242
            p = struct;
            p.NSD = 234;
            p.NSP = 8;
            p.NST = 242;
        case 484
            p = struct;
            p.NSD = 468;
            p.NSP = 16;
            p.NST = 484;
        case 726 % 242+484
            p = struct;
            p.NSD = 702;
            p.NSP = 24;
            p.NST = 726;
        case 968 % MCS-14 (2x484)
            p = struct;
            p.NSD = 936;
            p.NSP = 32;
            p.NST = 968;
        case 996
            p = struct;
            p.NSD = 980;
            p.NSP = 16;
            p.NST = 996;
        case 1480 % 996+484
            p = struct;
            p.NSD = 1448;
            p.NSP = 32;
            p.NST = 1480;
        case 1722 % 996+484+242
            p = struct;
            p.NSD = 1682;
            p.NSP = 40;
            p.NST = 1722;
        case 1992
            p = struct;
            p.NSD = 1960;
            p.NSP = 32;
            p.NST = 1992;
        case 2476 % 2x996+484
            p = struct;
            p.NSD = 2428;
            p.NSP = 48;
            p.NST = 2476;
        case 2988 % 3x996
            p = struct;
            p.NSD = 2940;
            p.NSP = 48;
            p.NST = 2988;
        case 3472 % 3x996+484
            p = struct;
            p.NSD = 3408;
            p.NSP = 64;
            p.NST = 3472;
        otherwise % 996x4 320 MHz
            assert(ruSize(1)==3984)
            p = struct;
            p.NSD = 3920;
            p.NSP = 64;
            p.NST = 3984;
    end
else
    NSD = coder.nullcopy(zeros(1,numRUSizes));
    NSP = coder.nullcopy(zeros(1,numRUSizes));
    NST = coder.nullcopy(zeros(1,numRUSizes));
    for i = 1:numRUSizes
        switch ruSize(i)
            case 26
                NSD(i) = 24;
                NSP(i) = 2;
                NST(i) = 26;
            case 52
                NSD(i) = 48;
                NSP(i) = 4;
                NST(i) = 52;
            case 78 % 26+52
                NSD(i) = 72;
                NSP(i) = 6;
                NST(i) = 78;
            case 106
                NSD(i) = 102;
                NSP(i) = 4;
                NST(i) = 106;
            case 132 % 106+26
                NSD(i) = 126;
                NSP(i) = 6;
                NST(i) = 132;
            case 242
                NSD(i) = 234;
                NSP(i) = 8;
                NST(i) = 242;
            case 484
                NSD(i) = 468;
                NSP(i) = 16;
                NST(i) = 484;
            case 726 % 242+484
                NSD(i) = 702;
                NSP(i) = 24;
                NST(i) = 726;
            case 968 % MCS-14 (2x484)
                NSD(i) = 936;
                NSP(i) = 32;
                NST(i) = 968;
            case 996
                NSD(i) = 980;
                NSP(i) = 16;
                NST(i) = 996;
            case 1480
                NSD(i) = 1448;
                NSP(i) = 32;
                NST(i) = 1480;
            case 1722 % 996+484+242
                NSD(i) = 1682;
                NSP(i) = 40;
                NST(i) = 1722;
            case 1992
                NSD(i) = 1960;
                NSP(i) = 32;
                NST(i) = 1992;
            case 2476 % 2x996+484
                NSD(i) = 2428;
                NSP(i) = 48;
                NST(i) = 2476;
            case 2988 % 3x996
                NSD(i) = 2940;
                NSP(i) = 48;
                NST(i) = 2988;
            case 3472 % 3x996+484
                NSD(i) = 3408;
                NSP(i) = 64;
                NST(i) = 3472;
            otherwise % 996x4 320 MHz
                assert(ruSize(i)==3984)
                NSD(i) = 3920;
                NSP(i) = 64;
                NST(i) = 3984;
        end
    end
    % Create structure output
    p = struct;
    p.NSD = NSD;
    p.NSP = NSP;
    p.NST = NST;
end

end