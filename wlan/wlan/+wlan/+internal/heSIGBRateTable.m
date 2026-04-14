function params = heSIGBRateTable(mcs,dcm)
%heSIGBRateTable HE-SIG-B rate dependent parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   PARAMS = heSIGBRateTable(MCS,DCM) returns a structure containing the
%   HE-SIG-B rate dependent parameters according.
%
%   MCS is the HE-SIG-B modulation and coding scheme and must be between 0
%   and 5.
%
%   DCM is a logical representing if dual carrier modulation is used.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

NSD = 52; % Number of data tones in HE-SIG-B
NSS = 1;  % Only one spatial-stream used for transmission
switch mcs
    case 0
        NBPSCS = 1; % 'BPSK'
        R   = 1/2;
    case 1
        NBPSCS = 2; % 'QPSK'
        R   = 1/2;
    case 2
        NBPSCS = 2; 
        R   = 3/4;
    case 3
        NBPSCS = 4; % '16QAM'
        R   = 1/2;
    case 4
        NBPSCS = 4; 
        R   = 3/4;
    otherwise % 5
        assert(mcs==5)
        NBPSCS = 6; % '64QAM'
        R   = 2/3;
end

if dcm
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