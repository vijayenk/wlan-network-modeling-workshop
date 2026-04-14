function [NBPSCS,R,constellationIndex] = getMCSTable(mcs)
%getMCSTable MCS dependent parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [NBPSCS,R,constellationIndex] = getMCSTable(MCS) returns NBPSCS, the
%   number of coded bits per subcarrier per spatial stream and R, the
%   coding rate, and constellationIndex according to Table 36-71 and Table
%   9-417u of IEEE P802.11be/D7.0.
%
%   MCS is the modulation and coding scheme and must be between 0 and 15.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

switch mcs
    case 0
        NBPSCS = 1; % 'BPSK'
        R = 1/2;
        constellationIndex = 0; % Table 9-417u. IEEE P802.11be/D7.0
    case 1
        NBPSCS = 2; % 'QPSK'
        R = 1/2;
        constellationIndex = 1;
    case 2
        NBPSCS = 2;
        R = 3/4;
        constellationIndex = 1;
    case 3
        NBPSCS = 4; % '16QAM'
        R = 1/2;
        constellationIndex = 2;
    case 4
        NBPSCS = 4;
        R = 3/4;
        constellationIndex = 2;
    case 5
        NBPSCS = 6; % '64QAM'
        R = 2/3;
        constellationIndex = 3;
    case 6
        NBPSCS = 6;
        R = 3/4;
        constellationIndex = 3;
    case 7
        NBPSCS = 6;
        R = 5/6;
        constellationIndex = 3;
    case 8
        NBPSCS = 8; % 256QAM
        R = 3/4;
        constellationIndex = 4;
    case 9
        NBPSCS = 8;
        R = 5/6;
        constellationIndex = 4;
    case 10
        NBPSCS = 10; % 1024QAM
        R = 3/4;
        constellationIndex = 5;
    case 11
        NBPSCS = 10;
        R = 5/6;
        constellationIndex = 5;
    case 12
        NBPSCS = 12;
        R = 3/4;
        constellationIndex = 6;
    case 13
        NBPSCS = 12;
        R = 5/6;
        constellationIndex = 6;
    case {14 15} % MCS 14 & 15
        NBPSCS = 1; % 'BPSK'
        R = 1/2;
        constellationIndex = 0;
    case 17 % UHR
        NBPSCS = 2; % 'QPSK'
        R = 2/3;
        constellationIndex = 1;
    case 19 % UHR
        NBPSCS = 4; % '16QAM'
        R = 2/3;
        constellationIndex = 2;
    case 20 % UHR
        NBPSCS = 4; % '16QAM'
        R = 5/6;
        constellationIndex = 2;
    otherwise % MCS 23 for UHR
        assert(mcs==23)
        NBPSCS = 8; % 256QAM
        R = 2/3;
        constellationIndex = 4;
end
end