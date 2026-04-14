function [N,M,NumEncBlks,NCC] = ehtSIGNumAllocationSubfields(cbw)
%ehtSIGNumAllocationSubfields Number of allocation subfields, N and M for OFDMA transmission
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [N,M,NumEncBlks,NCC] = ehtSIGNumAllocationSubfieldsParams(cbw) returns
%   the number of allocation field, encoding blocks, and number of content
%   channels for OFDMA transmission as defined in Table 36-39 and Figure
%   36-32, 36-33 of IEEE P802.11be/D4.0 respectively.
%
%   N and M are the number of allocation-1 and allocation-2 subfields.
%   NumEncBlks is the number of common encoding blocks. It is 1 for 20 MHz,
%   40 MHz, and 80 MHz. It is two 160 MHz and 320 MHz. See Figure 36-31 and
%   Figure 36-32 of IEEE P802.11be/D4.0. NCC is the number of content
%   channels, it is 1 for 20 MHz and 2 for all other bandwidths.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

switch cbw
    case 20
        N = 1;
        M = 0;
        NumEncBlks = 1;
        NCC = 1;
    case 40
        N = 1;
        M = 0;
        NumEncBlks = 1;
        NCC = 2;
    case 80
        N = 2;
        M = 0;
        NumEncBlks = 1;
        NCC = 2;
    case 160
        N = 2;
        M = 2;
        NumEncBlks = 2;
        NCC = 2;
    otherwise % 320 MHz
        N = 2;
        M = 6;
        NumEncBlks = 2;
        NCC = 2;
end

end