function [Ga,Gb] = wlanGolaySequence(len)
%wlanGolaySequence Golay sequence
%
%   [GA,GB] = wlanGolaySequence(LEN) returns the Golay sequences GA and GB
%   for a specified sequence length LEN.
%
%   GA and GB are both a column vector of length LEN.
%
%   LEN is an integer specifying the length of the Golay sequence and must
%   be 32, 64 or 128.

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen

validateattributes(len,{'numeric'},{'scalar'},mfilename,'length');
coder.internal.errorIf(~any(len==[32 64 128]),'wlan:wlanGolaySequence:InvalidLength');

% IEEE Std 802.11ad-2012 Section 21.11
switch len
    case 128
        Ga = [1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 1 -1 -1 1 1 1 -1 -1 1 1 1 1 -1 1 -1 1 -1 1 1 -1, ...
              -1 -1 1 1 1 1 1 1 1 -1 1 -1 -1 1 1 -1 1 1 -1 -1 1 1 1 1 -1 1 -1 1 -1 1 1 -1, ...
              1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 1 -1 -1 1 1 1 -1 -1 1 1 1 1 -1 1 -1 1 -1 1 1 -1, ...
              1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 1 -1 -1 1 -1 -1 1 1 -1 -1 -1 -1 1 -1 1 -1 1 -1 -1 1].';

        Gb = [-1 -1 1 1 1 1 1 1 1 -1 1 -1 -1 1 1 -1 -1 -1  1 1 -1 -1 -1 -1 1 -1 1 -1 1 -1 -1 1, ...
              1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 1 -1 -1 1 -1 -1 1 1 -1 -1 -1 -1 1 -1 1 -1 1 -1 -1 1, ...
              1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 1 -1 -1 1 1 1 -1 -1 1 1 1 1 -1 1 -1 1 -1 1 1 -1, ...
              1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 1 -1 -1 1 -1 -1 1 1 -1 -1 -1 -1 1 -1 1 -1 1 -1 -1 1].';
    case 64
        Ga = [-1 -1 1 -1 1 -1 -1 -1 1 1 -1 1 1 -1 -1 -1 -1 -1 1 -1 1 -1 -1 -1 -1 -1 1 -1 -1 1 1 1 ...
              -1 -1 1 -1 1 -1 -1 -1 1 1 -1 1 1 -1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 -1 1 1 -1 -1 -1].';
          
        Gb = [1 1 -1 1 -1 1 1 1 -1 -1 1 -1 -1 1 1 1 1 1 -1 1 -1 1 1 1 1 1 -1 1 1 -1 -1 -1 ...
              -1 -1 1 -1 1 -1 -1 -1 1 1 -1 1 1 -1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 -1 1 1 -1 -1 -1].';
    otherwise % 32
        Ga = [1 1 1 1 1 -1 1 -1 -1 -1 1 1 1 -1 -1 1 1 1 -1 -1 1 -1 -1 1 -1 -1 -1 -1 1 -1 1 -1].';
        Gb = [-1 -1 -1 -1 -1 1 -1 1 1 1 -1 -1 -1 1 1 -1 1 1 -1 -1 1 -1 -1 1 -1 -1 -1 -1 1 -1 1 -1].';
end 
end
