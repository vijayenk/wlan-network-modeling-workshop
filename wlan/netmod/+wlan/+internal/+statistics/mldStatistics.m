function mldStats = mldStatistics(linkStats)
%mldStatistics Returns multi-link device (MLD) statistics given per link
%statistics
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   MLDSTATS = mldStatistics(LINKSTATS) adds each link level stat and
%   returns MLD level statistics.
%
%   MLDSTATS is a structure with fields same as input structure and values
%   obtained by adding corresponding field values of each element in the
%   input structure array.
%
%   LINKSTATS is a statistics structure array where each element
%   corresponds to a link.

% Copyright 2025 The MathWorks, Inc.

mldStats = struct;
statNames = fieldnames(linkStats(1));

for statIdx = 1:numel(statNames)
    if ~strcmp(statNames{statIdx}, "AccessCategories")
        % Add all corresponding link statistics values
        totalStatValue = 0;
        for linkIdx = 1:numel(linkStats)
            totalStatValue = totalStatValue + linkStats(linkIdx).(statNames{statIdx});
        end
        mldStats.(statNames{statIdx}) = totalStatValue;
    else % Per AC statistics
        % Get names of per AC statistics
        perACStatNames = fieldnames(linkStats(1).(statNames{statIdx}));
        for acIdx = 1:4
            for perACStatIdx = 1:numel(perACStatNames)
                % Add per AC statistics of all links
                totalStatValue = 0;
                for linkIdx = 1:numel(linkStats)
                    totalStatValue = totalStatValue + ...
                        linkStats(linkIdx).(statNames{statIdx})(acIdx).(perACStatNames{perACStatIdx});
                end
                mldStats.(statNames{statIdx})(acIdx).(perACStatNames{perACStatIdx}) = totalStatValue;
            end
        end
    end
end
end