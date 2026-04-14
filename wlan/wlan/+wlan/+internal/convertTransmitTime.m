function t = convertTransmitTime(t,unit)
%convertTransmitTime Converts the transmit time in microseconds to the desired unit
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   TU = convertTransmitTime(TS) returns TU, the transmit time in seconds
%   given TS, the transmit time in microseconds.
%
%   TU = convertTransmitTime(TS,UNIT) returns the transmit time in the
%   desired UNIT. UNIT is 'seconds', 'microseconds', 'milliseconds', or
%   'nanoseconds'.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

if nargin>1
    unit = validatestring(unit,{'seconds','microseconds','milliseconds','nanoseconds'},'convertTransmitTime','unit');
    switch unit
        case 'seconds'
            t = t*1e-6;
        case 'milliseconds'
            t = t*1e-3;
        case 'nanoseconds'
            t = t*1e3;
    end
else
    % Default seconds
    t = t*1e-6;
end
end
