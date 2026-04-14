function isactive = heUpperCenter26ToneRUActive(allocationIndex)
%heUpperCenter26ToneRUActive Is the lower 26-tone RU active
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   ISACTIVE = heUpperCenter26ToneRUActive(ALLOCATIONINDEX) returns true if
%   the upper center 26-tone RU is active and false otherwise given the
%   allocation index.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

isactive = true;
if numel(allocationIndex)<8
    isactive = false;
else
    % Test the upper center 26-tone RU is valid for the allocation index
    s = wlan.internal.heAllocationInfo(allocationIndex);
    if any(s.RUSizes>996)
        % If a 2*996-tone RU, then center not applicable
        isactive = false;
    else
        rui = find(s.RUSizes==996);
        if ~isempty(rui) && any(s.RUIndices(rui)==2)
            % If 996 RU in upper half, then center not applicable
            isactive = false;
        end
    end
end
end