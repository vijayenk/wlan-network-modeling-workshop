function params = parseOptionalInputs(caller,varargin)
%parseOptionalInputs Optional parameter parsing and validation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CALLER is the name of the top level function from which
%   PARSEOPTIONALINPUTS is called.
%
%   The optional inputs are those passed by the user in the top level
%   function. These combinations of optional inputs are allowed.
%       1) mod(length(varargin),2)==0 --> N-V pair
%       2) mod(length(varargin),2)==1 --> None
%
%   The values accepted for the N-V pair inputs are listed below:
%   OFDMSymbolOffset          - OFDM symbol sampling offset
%   EqualizationMethod        - Equalization method
%   PilotPhaseTracking        - Pilot phase tracking
%   PilotAmplitudeTracking    - Pilot amplitude tracking
%   LDPCDecodingMethod        - LDPC decoding method
%   MinSumScalingFactor       - Scaling factor for LDPC decoding method 'norm-min-sum'
%   MinSumOffset              - Offset for LDPC decoding method 'offset-min-sum'
%   MaximumLDPCIterationCount - Maximum number of decoding iterations
%   Termination               - Early termination of LDPC decoding
%   SuppressWarnings          - Warning(s) suppression

%   Copyright 2019-2025 The MathWorks, Inc.

%#codegen

% Set defaults for the optional inputs
    defaultParams = struct( ...
        'EarlyTermination',true, ...
        'OFDMSymbolOffset',0.75,...
        'EqualizationMethod','MMSE',...
        'PilotPhaseTracking','PreEQ',...
        'PilotAmplitudeTracking','None',...
        'LDPCDecodingMethod','bp',...
        'MinSumScalingFactor',0.75,...
        'MinSumOffset',0.5,...
        'MaximumLDPCIterationCount',12,...
        'Termination','early',...
        'alphaBeta',1,...
        'SuppressWarnings',false);

    if strcmp(caller,'wlanEHTDataBitRecover')
        defaultParams.LDPCDecodingMethod = 'norm-min-sum';
    end

    if isempty(varargin)
        params = createStruct(defaultParams);
    else
        errorFlag = mod(length(varargin),2)==1; % Only N-V pair allowed
        coder.internal.errorIf(errorFlag,'wlan:shared:InvalidNumOptionalInputs');

        params = parseNVPair(caller,defaultParams,varargin{:});
    end

    % Combine MinSumScalingFactor and MinSumOffset into the single parameter
    % alphaBeta. This refers to either of these two, according to the LDPC
    % decoding algorithm used. If one of 'bp' or 'layered-bp' is used, the
    % value of alphaBeta is unused but still needed.
    switch params.LDPCDecodingMethod
      case 'bp'
        params.alphaBeta = 1; % Unused
      case 'layered-bp'
        params.alphaBeta = 1; % Unused
      case 'norm-min-sum'
        params.alphaBeta = params.MinSumScalingFactor;
      otherwise % "offset-min-sum"
        params.alphaBeta = params.MinSumOffset;
    end
end

function params = parseNVPair(caller,defaultParams,varargin)
%parseNVPair Validate and parse the N-V pair inputs

% Define the function handles for the validation
    OFDMSymbolOffsetValFcn = @(x) validateattributes(x,{'double'},{'real','scalar','>=',0,'<=',1},caller,'''OFDMSymbolOffset'' value');
    minSumScalingFactorValFcn = @(x) validateattributes(x,{'double'},{'real','scalar','>',0,'<=',1},caller,'''MinSumScalingFactor'' value');
    minSumOffsetValFcn = @(x) validateattributes(x,{'double'},{'real','scalar','finite','>=',0},caller,'''MinSumOffset'' value');
    maximumLDPCIterationCountValFcn = @(x) validateattributes(x,{'double'},{'real','integer','scalar','finite','>',0},caller,'''MaximumLDPCIterationCount'' value');
    earlyTerminationValFcn = @(x) validateattributes(x,{'logical','numeric'},{'real','scalar','nonnan'},caller,'''EarlyTermination'' value');
    suppressWarningsValFcn = @(x) validateattributes(x,{'logical','numeric'},{'real','scalar','nonnan'},caller,'''SuppressWarnings'' value');

    % Validate inputs
    if coder.target("MATLAB") % Simulation path
        p = inputParser;
        p.CaseSensitive = false;
        p.PartialMatching = true;

        % Add N-V pair into the parser and validate the numeric/logical ones
        addParameter(p,'EarlyTermination',defaultParams.EarlyTermination,earlyTerminationValFcn);
        addParameter(p,'OFDMSymbolOffset',defaultParams.OFDMSymbolOffset,OFDMSymbolOffsetValFcn);
        addParameter(p,'EqualizationMethod',defaultParams.EqualizationMethod);
        addParameter(p,'PilotPhaseTracking',defaultParams.PilotPhaseTracking);
        addParameter(p,'PilotAmplitudeTracking',defaultParams.PilotAmplitudeTracking);
        addParameter(p,'LDPCDecodingMethod',defaultParams.LDPCDecodingMethod);
        addParameter(p,'MinSumScalingFactor',defaultParams.MinSumScalingFactor,minSumScalingFactorValFcn);
        addParameter(p,'MinSumOffset',defaultParams.MinSumOffset,minSumOffsetValFcn);
        addParameter(p,'MaximumLDPCIterationCount',defaultParams.MaximumLDPCIterationCount,maximumLDPCIterationCountValFcn);
        addParameter(p,'SuppressWarnings',defaultParams.SuppressWarnings,suppressWarningsValFcn);
        parse(p,varargin{:}); % Parse inputs
        params = createStruct(p.Results);
    else % Codegen path
        nvPairs = struct('OFDMSymbolOffset',uint32(0),...
                         'EqualizationMethod','MMSE',...
                         'PilotPhaseTracking','PreEQ',...
                         'PilotAmplitudeTracking','None',...
                         'LDPCDecodingMethod','bp',...
                         'MinSumScalingFactor',uint32(0),...
                         'MinSumOffset',uint32(0),...
                         'MaximumLDPCIterationCount',uint32(0),...
                         'EarlyTermination',true,...
                         'Termination','early',...
                         'alphaBeta',uint32(0),...
                         'SuppressWarnings',false);

        % Select parsing options
        popts = struct('PartialMatching',true,...
                       'CaseSensitivity',false);

        % Parse inputs
        pStruct = coder.internal.parseParameterInputs(nvPairs,popts,varargin{:});

        % Get values for the N-V pair or set defaults for the optional arguments
        params = struct;
        params.OFDMSymbolOffset = coder.internal.getParameterValue(pStruct.OFDMSymbolOffset,defaultParams.OFDMSymbolOffset,varargin{:});
        params.EqualizationMethod = char(coder.internal.getParameterValue(pStruct.EqualizationMethod,defaultParams.EqualizationMethod,varargin{:}));
        params.PilotPhaseTracking = char(coder.internal.getParameterValue(pStruct.PilotPhaseTracking,defaultParams.PilotPhaseTracking,varargin{:}));
        params.PilotAmplitudeTracking = coder.internal.getParameterValue(pStruct.PilotAmplitudeTracking,defaultParams.PilotAmplitudeTracking,varargin{:});
        params.LDPCDecodingMethod = coder.internal.getParameterValue(pStruct.LDPCDecodingMethod,defaultParams.LDPCDecodingMethod,varargin{:});
        params.MinSumScalingFactor = coder.internal.getParameterValue(pStruct.MinSumScalingFactor,defaultParams.MinSumScalingFactor,varargin{:});
        params.MinSumOffset = coder.internal.getParameterValue(pStruct.MinSumOffset,defaultParams.MinSumOffset,varargin{:});
        params.MaximumLDPCIterationCount = coder.internal.getParameterValue(pStruct.MaximumLDPCIterationCount,defaultParams.MaximumLDPCIterationCount,varargin{:});
        earlyTermination = coder.internal.getParameterValue(pStruct.EarlyTermination,defaultParams.EarlyTermination,varargin{:});
        if earlyTermination
            termination = 'early';
        else
            termination = 'max';
        end
        params.Termination = coder.internal.getParameterValue(pStruct.Termination,termination);
        params.alphaBeta = coder.internal.getParameterValue(pStruct.alphaBeta,defaultParams.alphaBeta,varargin{:});
        params.SuppressWarnings = coder.internal.getParameterValue(pStruct.SuppressWarnings,defaultParams.SuppressWarnings,varargin{:});

        % Validate the numeric/logical N-V pair values
        OFDMSymbolOffsetValFcn(params.OFDMSymbolOffset);
        minSumScalingFactorValFcn(params.MinSumScalingFactor);
        minSumOffsetValFcn(params.MinSumOffset);
        maximumLDPCIterationCountValFcn(params.MaximumLDPCIterationCount);
        earlyTerminationValFcn(earlyTermination);
        suppressWarningsValFcn(params.SuppressWarnings);
    end

    % Validate the rest of the N-V pairs (strings)
    params.EqualizationMethod = validatestring(params.EqualizationMethod,{'ZF','MMSE'},caller,'EqualizationMethod');
    params.PilotPhaseTracking = validatestring(params.PilotPhaseTracking,{'PreEQ','None'},caller,'PilotPhaseTracking');
    params.PilotAmplitudeTracking = validatestring(params.PilotAmplitudeTracking,{'PreEQ','None'},caller,'PilotAmplitudeTracking');
    params.LDPCDecodingMethod = validatestring(params.LDPCDecodingMethod,{'bp','layered-bp','norm-min-sum','offset-min-sum'},caller,'LDPCDecodingMethod');

end

function s = createStruct(params)
%createStruct Create a structure from the fields of input structure params
%without an EarlyTermination field

    fieldNames = fieldnames(params);
    % Remove EarlyTermination field from the list of input structure fields
    idx = ~strcmp(fieldNames,'EarlyTermination');
    for i=1:length(fieldNames)
        if idx(i)
            f = fieldNames{i};
            s.(f) = params.(f);
        end
    end
    % Map N-V pair 'EarlyTermination' in WLAN recover functions to
    % 'Termination' input in ldpcDecode function from comms
    if params.EarlyTermination
        s.Termination = 'early';
    else
        s.Termination = 'max';
    end
end
