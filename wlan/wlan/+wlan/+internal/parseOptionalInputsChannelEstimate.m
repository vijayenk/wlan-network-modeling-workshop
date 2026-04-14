function params = parseOptionalInputsChannelEstimate(caller,varargin)
%parseOptionalInputsChannelEstimate Optional parameter parsing and validation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CALLER is the name of the top level function from which
%   parseOptionalInputsTrackPilotError is called.
%
%   The optional inputs are those passed by the user in the top level
%   function. These combinations of optional inputs are allowed.
%       1) mod(length(varargin),2)==0 --> N-V pair
%       2) mod(length(varargin),2)==1 --> None
%
%   The values accepted for the N-V pair input are listed below:
%   FrequencySmoothingSpan  - Positive and odd number

%   Copyright 2022 The MathWorks, Inc.

%#codegen

defaultParams = struct('FrequencySmoothingSpan',1);
if isempty(varargin)
    % No need for parsing and validation
    params = defaultParams;
else
    params = parseNVPair(caller,defaultParams,varargin{:});
end

end

function params = parseNVPair(caller,defaultParams,varargin)
%parseNVPair Validate and parse the N-V pair inputs

freSmoothingSpanValFn = @(x)validateattributes(x,{'numeric'},{'>=',1,'odd','scalar'},caller,'''FrequencySmoothingSpan'' value');
% Validate inputs
if isempty(coder.target) % Simulation path
    p = inputParser;
    p.CaseSensitive = false;
    p.PartialMatching = true;
    % Name-Value pair
    addParameter(p,'FrequencySmoothingSpan',defaultParams.FrequencySmoothingSpan,freSmoothingSpanValFn);
    parse(p,varargin{:}); % Parse inputs
    params = p.Results;
else % Codegen path
    nvPairs = {'FrequencySmoothingSpan'};
    % Select parsing options
    popts = struct('PartialMatching',true,'CaseSensitivity',false);
    % Parse inputs
    pStruct = coder.internal.parseParameterInputs(nvPairs,popts,varargin{:});
    params = coder.internal.vararginToStruct(pStruct,defaultParams,varargin{:});
    % Validate values
    freSmoothingSpanValFn(params.FrequencySmoothingSpan);
end
end