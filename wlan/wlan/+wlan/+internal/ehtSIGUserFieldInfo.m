function u = ehtSIGUserFieldInfo
%ehtSIGUserFieldInfo EHT-SIG user field info
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   U = ehtSIGUserFieldInfo returns the EHT-SIG user field information. The
%   output structure U has the following fields:
%
%   NumCRCBits           - Number of CRC bits
%   NumTailBits          - Number of tail bits
%   NumUserFieldBits     - Number of bits in a single user field
%   NumUserFieldPairBits - Number of bits in a pair of user field

%   Copyright 2023 The MathWorks, Inc.

%#codegen

u = struct( ...
    'NumCRCBits', 4, ...
    'NumTailBits', 6, ...
    'NumUserFieldBits', 22, ...
    'NumUserFieldPairBits', 22*2+6+4); % NumUserFieldBits*2+NumTailBits+NumCRCBits
end