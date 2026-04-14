function p = wurSymbolParameters(dataRate)
%wurSymbolParameters WUR symbol parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   p = wurSymbolParameters(dataRate) returns a structure containing
%   the number of MC-OOK symbols per information data bit and the number of
%   MC-OOK symbols in the WUR-SYNC field. See IEEE P802.11ba/D8.0,
%   December 2020, Table 30-4.
%
%   DATARATE specifies the transmission rate, and it is a character vector
%   or string scalar equal to 'LDR', or 'HDR'.
%   Set DATARATE to 'LDR', indicating the support for the low data rate (62.5 kb/s).
%   Set DATARATE to 'HDR', indicating the support for the high data rate (250 kb/s).
%
%   See also wlanWURConfig.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

p = struct;
switch dataRate
    case 'LDR'% Low data rate
        p.NSPDB = 4; % Number of MC-OOK symbols per information data bit
        p.NWURSync = 64; % Number of MC-OOK symbols in the WUR-Sync field
    otherwise % High data rate
        p.NSPDB = 2;
        p.NWURSync = 32;
end

end