function T = wurCyclicShift(dataRate,n)
%wurCyclicShift WUR pseudorandom cyclic shift
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   T = wurCyclicShift(dataRate,n) returns the value of pseudorandom cyclic
%   shift with cyclic shift index n for WUR Sync and Data fields.
%
%   T represents the value of pseudorandom cyclic shift in ns.
%
%   DATARATE specifies the transmission rate as character vector or string 
%   and must be 'LDR', or 'HDR'.
%
%   N represents the cyclic shift index.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

switch dataRate
    case 'LDR'
        % IEEE P802.11ba/D8.0, December 2020, Table 30-7
        TCSRSym = 0:-400:-2800; % in ns;
    otherwise
        % IEEE P802.11ba/D8.0, December 2020, Table 30-6
        TCSRSym = 0:-200:-1400; % in ns;
end

T = TCSRSym(n+1);

end
