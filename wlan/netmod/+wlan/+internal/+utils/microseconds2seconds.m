function s = microseconds2seconds(us)
%microseconds2seconds Convert given value from microseconds to seconds
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

s = round(us*1e-6,9); % Round to whole nanosecond
end