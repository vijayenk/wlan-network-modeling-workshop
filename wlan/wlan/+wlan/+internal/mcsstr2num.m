function y = mcsstr2num(s,cls)
%mcsstr2num Convert two element MCS character vector to numeric
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = mcsstr2num(S) converts the two-element character vector S to a
%   uint8 numeric scalar Y.
%
%   Y = mcsstr2num(S,CLS) converts the two element character vector S to a
%   numeric scalar of the type specified by CLS.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

if nargin == 1
    cls = 'uint8';
end
ZERO = cast('0',cls);
TEN = cast(10,cls);
y = cast(s(end),cls) - ZERO;
if length(s) > 1
    y = y + TEN*(cast(s(1),cls) - ZERO);
end
end