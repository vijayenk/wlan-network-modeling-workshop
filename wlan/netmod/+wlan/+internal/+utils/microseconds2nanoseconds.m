function ns = microseconds2nanoseconds(us)
%microseconds2nanoseconds Convert given value from seconds to nanoseconds
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

ns = round(us*1e3); % Round to whole nanosecond
end