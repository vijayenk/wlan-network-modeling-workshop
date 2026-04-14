function osf = parseOSF(varargin)
%parseOSF OversamplingFactor name-value pair parsing
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   OSF = parseOSF(VARARGIN) returns the oversampling factor given
%   name-value pairs in VARARGIN.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

% Default
osf = 1;
if nargin==0
    return
end

if isempty(coder.target) % Simulation path    
    if mod(nargin,2) ~= 0
        % Check for number of arguments as error message using FAV in wlan.internal.parseOSFML gives incorrect position
        error(message('wlan:shared:InvalidNVPairs'));
    end
    osf = wlan.internal.parseOSFML(varargin{:}); 
else % Codegen path
    nvNames = {'OversamplingFactor'};
    pStruct = coder.internal.parseParameterInputs(nvNames,[],varargin{:});
    % Get values for the P-V pair or set defaults for the optional arguments
    osf = coder.internal.getParameterValue(pStruct.OversamplingFactor,osf,varargin{:});
    validateattributes(osf,{'numeric'},{'real','finite','scalar','>=',1},mfilename,'OversamplingFactor')
end
osf = double(osf); % Force to double for processing
end