function mhz = cbwStr2Num(chanBW)
%cbwStr2Num Returns the channel bandwidth in MHz given a character vector
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   MHZ = cbwStr2Num(CHANBW) returns the channel bandwidth in MHz for a
%   given channel bandwidth character vector. The character vector must be
%   one of the following: 'CBW1', 'CBW2', 'CBW4', 'CBW5', 'CBW8', 'CBW10',
%   'CBW16', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

switch chanBW
    case 'CBW1'
        mhz = 1;
    case 'CBW2'
        mhz = 2;
    case 'CBW4'
        mhz = 4;
    case 'CBW8'
        mhz = 8;
    case 'CBW16'
        mhz = 16;
    case 'CBW5'
        mhz = 5;
    case 'CBW10'
        mhz = 10;
    case 'CBW20'
        mhz = 20;
    case 'CBW40'
        mhz = 40;
    case 'CBW80'
        mhz = 80;
    case 'CBW160'
        mhz = 160;
    otherwise % 'CBW320'
        assert(strcmp(chanBW,'CBW320'))
        mhz = 320;
end

end