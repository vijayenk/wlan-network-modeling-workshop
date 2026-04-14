function us = seconds2microseconds(s)
%seconds2microseconds Convert given value from seconds to microseconds
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

us = round(s*1e6,3); % Round to whole nanosecond
end