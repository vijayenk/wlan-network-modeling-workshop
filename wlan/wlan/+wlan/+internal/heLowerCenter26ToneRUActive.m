function isactive = heLowerCenter26ToneRUActive(allocationIndex)
%heLowerCenter26ToneRUActive Is the lower 26-tone RU active
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   ISACTIVE = heLowerCenter26ToneRUActive(ALLOCATIONINDEX) returns true if
%   the lower center 26-tone RU is active and false otherwise given the
%   allocation index.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

isactive = true;
if numel(allocationIndex)<4
    isactive = false;
else
    % Test the lower center 26-tone RU is valid for the allocation index
    s = wlan.internal.heAllocationInfo(allocationIndex);
    if numel(allocationIndex)==4
        if any(s.RUSizes>484)
            % If any 996-tone RUs, then center not applicable
            isactive = false;
        end
    else % allocationIndex == 8
        if any(s.RUSizes>996) || (s.RUSizes(1)==996 && s.RUIndices(1)==1)
            % If a 2*996-tone RU, or 996 RU in lower half, then center not applicable
            isactive = false;
        end
    end
end
end