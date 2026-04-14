function y = wlanConstellationMap(x, numBPSCS, phase, nameValueArgs)
%wlanConstellationMap Constellation mapping
%   Y = wlanConstellationMap(X,NUMBPSCS) maps the input bits (X) using the
%   number of coded bits per subcarrier per spatial stream (NUMBPSCS) to
%   one of the following modulations:
%     BPSK, QPSK, 16QAM, or 64QAM as per IEEE Std 802.11-2016 Section
%     17.3.5.8; 256QAM as per IEEE Std 802.11-2016 Section 21.3.10.9.1;
%     1024QAM as per Std 802.11ax-2021 Section 27.3.12.9 and 4096QAM as
%     per IEEE P802.11be/D5.0 Section 36.3.13.7.
%   Constellation mapping is performed column-wise.
%
%   Y is a complex vector, matrix or multidimensional array containing the
%   mapped symbols. Y has the same size of X except for the number of rows,
%   which is equal to the number of rows of X divided by NUMBPSCS.
%
%   X is a binary 'int8', 'single', or 'double' vector, matrix or
%   multidimensional array containing the input bits to map into symbols.
%   The number of rows of X must be an integer multiple of NUMBPSCS.
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1 (BPSK), 2 (QPSK), 4 (16QAM),
%   6 (64QAM), 8 (256QAM), 10 (1024QAM), or 12 (4096QAM). NUMBPSCS is equal
%   to log2(M), where M is the modulation order.
%
%   Y = wlanConstellationMap(...,PHASE) rotates the constellation points
%   counter-clockwise by the specified amount, PHASE, in radians. PHASE can
%   be a scalar, matrix or multidimensional array. PHASE and mapped symbols
%   must have compatible sizes. PHASE and mapped symbols have compatible
%   sizes if, for every dimension, the dimension sizes are either the same
%   or one of them is 1. For more information, see wlanConstellationMap
%   documentation.
%
%   Y = wlanConstellationMap(...,Name=Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'OutputDataType'    The output data type of Y. Can be
%                       either 'single' or 'double'. The
%                       default value is 'single' for 'single'
%                       X and 'double' for 'double' or 'int8' X.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

    arguments
        x {validateInput(x)};
        numBPSCS (1,1) {wlan.internal.validateBPSCS(numBPSCS)};
        phase = 0;
        nameValueArgs.OutputDataType;
    end

    % Validate input with numBPSCS
    coder.internal.errorIf(mod(size(x,1),numBPSCS)~=0,'wlan:wlanConstellationMap:xSizeBit');

    % Output Data Type
    if isfield(nameValueArgs,"OutputDataType")
        % Validation
        odt = validatestring(nameValueArgs.OutputDataType,{'double','single'},mfilename);
    else
        % If not specified, output data type depends on x
        if isa(x,'int8')
            odt = 'double';
        else
            odt = class(x);
        end
    end

    % Return an empty matrix if x is empty
    if isempty(x)
        y = zeros(size(x),odt);
        return;
    end

    % Separate out BPSK from other QAM modulations
    if numBPSCS==1
        % As per IEEE Std 802.11-2020 Section 17.3.5.8, Fig. 17-10
        constellation = cast([-1; 1],odt);
        yt = complex(constellation(x+1)); % Force to complex
    else
        % Get symbol mapping
        symMap = wlan.internal.symbolMap(numBPSCS);

        if ndims(x)>3
            % qam.modulate does not support inputs with more than 3 dimensions.
            % Reshape into a column
            yTmp = comm.internal.qam.modulate(x(:),2^numBPSCS,'custom',symMap,1,1,odt);
            inpSize = size(x);
            yt = reshape(yTmp,[inpSize(1)/numBPSCS inpSize(2:end)]);
        else
            yt = comm.internal.qam.modulate(x,2^numBPSCS,'custom',symMap,1,1,odt);
        end
    end

    % Constellation rotation
    if any(phase ~= 0,'all')
        wlan.internal.validatePhase(phase,size(yt),mfilename);
        y = complex(yt.*exp(1i*phase)); % Force complex so it is maintained for BPSK
    else
        y = yt;
    end
end

function validateInput(x)
    % Validate input
    validateattributes(x,{'int8','double','single'},{'binary'},mfilename,'Input bits');
end