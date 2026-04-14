function params = ehtSIGRateTable(mcs)
%ehtSIGBRateTable EHT-SIG rate dependent parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PARAMS = ehtSIGRateTable(MCS) returns a structure containing the
%   EHT-SIG rate dependent parameters according.
%
%   MCS is the EHT-SIG modulation and coding scheme and must be between 0,
%   1, 3 or 15 as defined in Table 36-88 of IEEE P802.11be/D3.0.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

NSD = 52; % Number of data tones in EHT-SIG
R = 1/2;
NSS = 1; % Only one spatial-stream used for transmission
switch mcs
    case 0
        NBPSCS = 1; % 'BPSK'
    case 1
        NBPSCS = 2; % 'QPSK'
    case 3
        NBPSCS = 4; % 16 QAM
    otherwise % 15
        assert(mcs==15)
        NBPSCS = 1; % 'BPSK-DCM'
        NSD = NSD/2;
end

NCBPS = NSD*NBPSCS*NSS;
NDBPS = floor(NCBPS*R); % As per IEEE 802.11-16/0620

params = struct( ...
    'Rate',      R, ...
    'NBPSCS',    NBPSCS, ...
    'NCBPS',     NCBPS, ...
    'NSD',       NSD, ...
    'NDBPS',     NDBPS, ...
    'NSS',       NSS);
end