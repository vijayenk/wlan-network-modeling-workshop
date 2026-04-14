function y = wlanConstellationDemap(x, noiseVar, numBPSCS, demapType, phase, nameValueArgs) 
%wlanConstellationDemap Constellation demapping
%   Y = wlanConstellationDemap(X,NOISEVAR,NUMBPSCS) demaps the received
%   input symbols (X) using the soft-decision approximate LLR method for
%   the specified number of coded bits per subcarrier per spatial stream
%   (NUMBPSCS). The received symbols must have been generated with one of
%   the following modulations:
%     BPSK, QPSK, 16QAM, or 64QAM as per IEEE 802.11-2012 Section 18.3.5.8;
%     256QAM as per IEEE 802.11ac-2012 Section 22.3.10.9.1; 1024QAM and
%     4096QAM as per IEEE P802.11be/D1.5 Section 36.3.13.7.
%   Constellation demapping is performed column-wise.
%
%   Y is a matrix or multidimensional array containing the demapped symbols
%   of same data type as X. Y has the same size as X except for the number
%   of rows that will be equal to the number of rows of X multiplied by
%   NUMBPSCS.
%
%   X is single or double precision vector, matrix or multidimensional
%   array containing the received symbols.
%
%   NOISEVAR is a single or double nonnegative scalar representing the
%   noise variance estimate. When the demapping type is optionally set to
%   'hard', the noise variance estimate is not required and therefore is
%   ignored.
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1 (BPSK), 2 (QPSK), 4 (16QAM),
%   6 (64QAM), 8 (256QAM), 10 (1024QAM), or 12 (4096QAM). NUMBPSCS is equal
%   to log2(M), where M is the modulation order.
%
%   Y = wlanConstellationDemap(...,DEMAPTYPE) allows the demapping type to
%   be specified. DEMAPTYPE is a character vector or string scalar. It can
%   be 'hard' for hard-decision demapping or 'soft' for the soft-decision
%   approximate LLR method. Default DEMAPTYPE is 'soft'.
%
%   Y = wlanConstellationDemap(...,PHASE) derotates the symbols clockwise
%   before demapping by the specified amount in radians. PHASE can be a
%   scalar, matrix or multidimensional array. PHASE and mapped symbols must
%   have compatible sizes. PHASE and mapped symbols have compatible sizes
%   if, for every dimension, the dimension sizes are either the same or one
%   of them is 1. For more information, see wlanConstellationDemap
%   documentation.
%
%   Y = wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,DEMAPTYPE,PHASE) allows
%   the demapping type and the phase rotation to be specified.
%
%   Y = wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,PHASE,DEMAPTYPE) allows
%   the phase rotation to be specified before the demapping type.
%
%   Y = wlanConstellationDemap(...,Name=Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'OutputDataType'    The output data type of Y. Must be one
%                       of 'single', 'double', or 'int8'. The
%                       default value matches the data type of
%                       X.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

    arguments 
        x {mustBeFloat, mustBeFinite};
        noiseVar (1,1) {validateNoiseVar(noiseVar)};
        numBPSCS (1,1) {wlan.internal.validateBPSCS(numBPSCS)};
        demapType {validateDemap(demapType,x)} = 'soft';
        phase {validatePhase(demapType,phase,x)} = 0;
        nameValueArgs.OutputDataType;
    end

    % Check the supplied order of demapType and phase inputs
    demapTypeInput = 'soft'; % default
    if isnumeric(demapType)
        if isnumeric(phase)
            % Only a phase supplied, use default demapType
            phaseInput = demapType;
        else
            % phase supplied before demapType
            phaseInput = demapType;
            demapTypeInput = phase;
        end
    else
        % demapType supplied before phase
        phaseInput = phase;
        demapTypeInput = demapType;
    end

    % Validate demapType and OutputDataType pairing to prevent an invalid
    % 'soft' demapping and 'int8' output data type condition
    coder.internal.errorIf(isfield(nameValueArgs,'OutputDataType') && ...
        strcmpi(demapTypeInput,'soft') && strcmpi(nameValueArgs.OutputDataType,'int8'), ...
        'wlan:wlanConstellationMap:InvalidCombination');

    % Output Data Type
    if isfield(nameValueArgs,"OutputDataType")
        % Validation
        odt = validatestring(nameValueArgs.OutputDataType,{'double','single','int8'},mfilename);
    else
        odt = class(x);
    end

    % Return an empty matrix if x is empty
    if isempty(x)
        y = zeros(size(x),odt);
        return; 
    end

    % Convert 'hard' and 'soft' demapType inputs into qam.demodulate
    % demapping types of 'bit' and 'approxllr' respectively
    if strcmpi(demapTypeInput,'soft')
        qamDemodType = 'approxllr';
    else
        qamDemodType = 'bit';
        % Ignore noiseVar for 'hard' demodulation
        noiseVar = cast(0,'like',noiseVar);
    end

    % Clip noiseVar to allowable value to avoid divide by zero warnings
    minNoiseVar = cast(1e-10,'like',noiseVar);
    if noiseVar < minNoiseVar
        noiseVar = minNoiseVar;
    end

    % Derotate phase
    x = x .* exp(-1i*phaseInput);

    % Separate out BPSK from other QAM modulations
    if numBPSCS==1
        if strcmp(qamDemodType,'approxllr')
            % For constellation [-1, 1] as per Fig. 17-10 Section 17.3.5.8, 802.11-2020
            approxLLR = -4*real(cast(x,odt)); % = abs(1 - inp).^2 - abs(-1 - inp).^2
            noiseVar =  cast(noiseVar,odt);
            % Scalar noiseVar applies to entire input
            y = approxLLR / noiseVar;
        else % BPSK hard demodulation
            y = zeros(size(x),odt);
            y(real(x)>0) = 1;
        end
    else
        % Get symbol mapping
        symMap = wlan.internal.symbolMap(numBPSCS);

        if ndims(x)>3
            % qam.demodulate does not support inputs with more than 3 dimensions.
            % Reshape into a column
            yTmp = comm.internal.qam.demodulate(x(:),2^numBPSCS,'custom',symMap,1,qamDemodType,noiseVar,false,odt);
            inpSize = size(x);
            yTmp = reshape(yTmp,[inpSize(1)*numBPSCS inpSize(2:end)]);
        else
            yTmp = comm.internal.qam.demodulate(x,2^numBPSCS,'custom',symMap,1,qamDemodType,noiseVar,false,odt);
        end

        % For codegen support of soft demapping, cast y to odt
        y = cast(yTmp,odt);

    end
end

function validateNoiseVar(noiseVar)
    % Validate noiseVar
    mustBeFloat(noiseVar);
    mustBeFinite(noiseVar);
    mustBeGreaterThanOrEqual(noiseVar,0);
end

function validateDemap(a,x)
    if isnumeric(a)
        % wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,PHASE,...)
        wlan.internal.validatePhase(a,size(x),mfilename);
    else
        % wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,DEMAPTYPE,...)
        coder.internal.errorIf(~(ischar(a) || (isstring(a) && isscalar(a))) || ...
            (~any(strcmpi(a,{'soft','hard'}))),'wlan:wlanConstellationMap:InvalidDemapType');
    end
end

function validatePhase(a,b,x)
    if isnumeric(a) && isnumeric(b)
        % wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,PHASE)
        coder.internal.errorIf(any(b ~= 0),'wlan:wlanConstellationMap:InvalidDemapType');
    elseif isnumeric(a) && ~isnumeric(b)
        % wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,PHASE,DEMAPTYPE)
        coder.internal.errorIf(~(ischar(b) || (isstring(b) && isscalar(b))) || ...
            (~any(strcmpi(b,{'soft','hard'}))),'wlan:wlanConstellationMap:InvalidDemapType');
    elseif any(b ~= 0)
        % wlanConstellationDemap(X,NOISEVAR,NUMBPSCS,DEMAPTYPE,PHASE)
        wlan.internal.validatePhase(b,size(x),mfilename);
    end
end

