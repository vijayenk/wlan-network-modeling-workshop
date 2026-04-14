function P = wurFrequentlyUsedParameters(dataRate)
%wurFrequentlyUsedParameters WUR Frequently used Parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   P = wurTxAntCyclicShift(dataRate) returns a structure containing the
%   frequently used parameters for WUR formats.
%
%   P is a structure containing the frequently used parameters for WUR
%   formats, specified in IEEE P802.11ba/D8.0, December 2020, Table 30-4.
%
%   DATARATE specifies the transmission rate as character vector or string
%   and must be 'LDR', or 'HDR'.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

P = struct;
switch dataRate
    case 'LDR'
        P.NSPDB = 4; % Number of MC-OOK symbols per information data bit
        P.NWURSync = 64; % Number of MC-OOK symbols in the WUR-Sync field
    otherwise % HDR
        P.NSPDB = 2;
        P.NWURSync = 32;
end

end