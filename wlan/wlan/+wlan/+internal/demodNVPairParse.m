function nvp = demodNVPairParse(varargin)
%demodNVPairParse Parse optional name-value pairs for demodulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NVP = demodNVPairParse(IN) parses the cell array IN and returns a
%   structure containing name-value pair values.

%   Copyright 2018-2023 The MathWorks, Inc.

%#codegen

% Default
symOffset = 0.75;
osf = 1;
nvp = struct('SymOffset',symOffset,'OversamplingFactor',osf);

if nargin==0
    % Use default values.
    return
end

% Validate each P-V pair
symValFn = @(x)validateattributes(x,{'numeric'},{'scalar','>=',0,'<=',1},mfilename,'OFDM symbol offset');
osfValFn = @(x)validateattributes(x,{'numeric'},{'scalar','>=',1},mfilename,'Oversampling factor');
if isempty(coder.target) % Simulation path
    p = inputParser;
    % Set defaults for the optional arguments
    addParameter(p,'OFDMSymbolOffset',symOffset,symValFn);
    addParameter(p,'OversamplingFactor',osf,osfValFn);
    try
        parse(p,varargin{:}); % Parse inputs
    catch e
        throwAsCaller(e);
    end
    res = p.Results;
    symOffset = res.OFDMSymbolOffset;
    osf = res.OversamplingFactor;
else % Codegen path
    % Validate name of NV pair of first varargin element
    validateParamNameCG(varargin{1});
    if nargin==4
        % Validate name of NV pair of third varargin element
        validateParamNameCG(varargin{3});
    end

    pvPairs = struct('OFDMSymbolOffset',uint32(0),'OversamplingFactor',uint32(1));
    % Select parsing options
    popts = struct('PartialMatching',true);
    % Parse inputs
    pStruct = coder.internal.parseParameterInputs(pvPairs,popts,varargin{:});
    % Get values for the P-V pair or set defaults for the optional arguments
    symOffset = coder.internal.getParameterValue(pStruct.OFDMSymbolOffset,symOffset,varargin{:});
    symValFn(symOffset);
    osf = coder.internal.getParameterValue(pStruct.OversamplingFactor,osf,varargin{:});
    osfValFn(osf);
end

nvp = struct('SymOffset',symOffset,'OversamplingFactor',double(osf));

end

% Error if NV pair is Text or is not Constant
function validateParamNameCG(paramName)
    if ~coder.internal.isTextRow(paramName)
        % Error if NV pair not provided
        coder.internal.error('wlan:shared:InvalidDemodNV');
        return
    end
    if ~coder.internal.isConst(paramName)
        % Name-Value pair input must be a constant
        coder.internal.error('wlan:shared:NameValueMustBeConstant');
        return
    end
end
