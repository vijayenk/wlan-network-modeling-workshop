function osf = parseOSFML(options)
%parseOSFML Parse optional name-value pairs for oversampling
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   osf = parseOSFML(IN) parses the cell array IN to determine
%   the optional oversampling factor as a name-value pair.

%   Copyright 2021 The MathWorks, Inc.

arguments
    options.OversamplingFactor (1,1) {mustBeNumeric, mustBeFinite, mustBeGreaterThanOrEqual(options.OversamplingFactor,1)} = 1
end

osf = options.OversamplingFactor;

end