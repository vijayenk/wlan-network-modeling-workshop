function us = nanoseconds2microseconds(ns)
%nanoseconds2microseconds Convert given value from nanoseconds to microseconds
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

us = round(ns*1e-3,3); % Round to whole nanosecond
end