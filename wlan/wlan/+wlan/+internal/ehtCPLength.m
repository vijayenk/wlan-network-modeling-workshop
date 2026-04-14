function cpLength = ehtCPLength(numSubchannels,guardInterval)
%ehtCPLength EHT cyclic prefix length
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CPLENGTH = ehtCPLength(NUMSUBCHANNELS,GUARDINTERVAL) returns the cyclic
%   prefix length in number of samples for the given NUMSUBCHANNELS and
%   GUARDINTERVAL.
%
%   NUMSUBCHANNELS is the number of 20 MHz subchannels and is 1, 2, 4, 8,
%   or 16 for CBW20, CBW40, CBW80, CBW160, and CBW320 respectively.
%
%   GUARDINTERVAL is the cyclic prefix length in microseconds and is 0.8,
%   1.6, or 3.2.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

switch guardInterval
    case 0.8
        cpLength = 16*numSubchannels;
    case 1.6
        cpLength = 32*numSubchannels;
    otherwise % 3.2
        assert(guardInterval==3.2)
        cpLength = 64*numSubchannels;
end

end