function nvpairs = parseOptionalInputsTrackPilotError(nvpairs)
%parseOptionalInputsTrackPilotError Optional parameter parsing and validation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    arguments
        nvpairs.TrackPhase (1,1) logical = true
        nvpairs.TrackAmplitude (1,1) logical = false
    end
end
