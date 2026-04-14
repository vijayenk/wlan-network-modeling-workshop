function N = numHTELTFSymbols(numESS)
%numHTELTFSymbols Number of HT-ELTF symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   N = numHTELTFSymbols(NUMESS) returns the number of HT-ELTF symbols
%   required for the specified number of extension streams as per IEEE
%   802.11-2016 Table 19-14.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

NhteltfTable = [0 1 2 4];
N = NhteltfTable(numESS+1);

end