function N = numVHTLTFSymbols(numSTS)
%numVHTLTFSymbols Number of VHT-LTF symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   N = numVHTLTFSymbols(NUMSTS) returns the number of VHT-LTF symbols
%   required for the specified number of space-time streams as per IEEE
%   802.11-2016 Table 21-13.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

NvhtltfTable = [1 2 4 4 6 6 8 8];
N = NvhtltfTable(numSTS);
end