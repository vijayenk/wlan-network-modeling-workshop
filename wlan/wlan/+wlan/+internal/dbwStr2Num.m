function mhz = dbwStr2Num(DBW)
%dbwStr2Num Returns the distribution channel bandwidth (DBW) in MHz given a character vector
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   MHZ = dbwStr2Num(DBW) returns the channel bandwidth in MHz for a
%   given distribution channel bandwidth character vector. The character
%   vector must be one of the following: 'DBW20', 'DBW40', or 'DBW80'.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

switch DBW
    case 'DBW20'
        mhz = 20;
    case 'DBW40'
        mhz = 40;
    otherwise % 'CBW80'
        assert(strcmp(DBW,'DBW80'))
        mhz = 80;
end

end