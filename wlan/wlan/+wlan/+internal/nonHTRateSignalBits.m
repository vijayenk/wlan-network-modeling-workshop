function R = nonHTRateSignalBits(varargin)
%nonHTRateSignalBits Non-HT rate table
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   R = nonHTRateSignalBits() returns the bits representing each rate for a
%   non-HT transmission in the SIGNAL field. R is a an 4-by-8 matrix of
%   bits, were the rows are bits R1...R4 and each column is a rate, ordered
%   from low to high, i.e. 6 Mbps to 54 Mbps.
%
%   R = nonHTRateSignalBits(MCS) returns a column vector of length 4,
%   containing bits R1 to R4 for a given MCS within the range 0-7.
 
%   Copyright 2016 The MathWorks, Inc.

%#codegen

narginchk(0,1);
% R: 1 2 3 4 (bits)
r = [1 1 0 1; ... % 6 Mbps (MCS 0)
     1 1 1 1; ... % 9 Mbps (MCS 1)
     0 1 0 1; ... % 12 Mbps (MCS 2)
     0 1 1 1; ... % 18 Mbps (MCS 3)
     1 0 0 1; ... % 24 Mbps (MCS 4)
     1 0 1 1; ... % 36 Mbps (MCS 5)
     0 0 0 1; ... % 48 Mbps (MCS 6)
     0 0 1 1];    % 54 Mbps (MCS 7)

if nargin>0
    R = r(varargin{1}+1,:).'; % Lookup table with given MCS
else
    R = r.'; % Return entire table
end   
end