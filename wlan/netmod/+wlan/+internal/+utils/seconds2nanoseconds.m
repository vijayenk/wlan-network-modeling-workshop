function ns = seconds2nanoseconds(s)
%seconds2nanoseconds Convert given value from seconds to nanoseconds
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

ns = round(s*1e9); % Round to whole nanosecond
end
