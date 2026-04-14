function s = nanoseconds2seconds(ns)
%nanoseconds2seconds Convert given value from nanoseconds to seconds
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

s = round(ns*1e-9,9); % Round to whole nanosecond
end