function ldpcParams = getLDPCBitRecoveryParams(caller,nvPairs)
%getLDPCBitRecoveryParams Parses NameValue arguments and constructs an info struct for LDPC decoding
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2024-2025 The MathWorks, Inc.

%#codegen
    arguments
        caller {mustBeTextScalar} = '';
        nvPairs.LDPCDecodingMethod {mustBeTextScalar} = 'norm-min-sum';
        nvPairs.MinSumScalingFactor (1,1) double {mustBePositive,mustBeLessThanOrEqual(nvPairs.MinSumScalingFactor,1)} = 0.75;
        nvPairs.MinSumOffset (1,1) double {mustBeFinite,mustBeNonnegative} = 0.5;
        nvPairs.MaximumLDPCIterationCount (1,1) double {mustBeInteger,mustBePositive} = 12;
        nvPairs.EarlyTermination (1,1) logical = true;
    end

    ldpcDecMeth = validatestring(nvPairs.LDPCDecodingMethod,{'bp','layered-bp','norm-min-sum','offset-min-sum'},caller,'LDPCDecodingMethod');

    switch ldpcDecMeth
      case 'norm-min-sum'
        alphaBeta = nvPairs.MinSumScalingFactor;
      case 'offset-min-sum'
        alphaBeta = nvPairs.MinSumOffset;
      otherwise
        assert(matches(ldpcDecMeth,{'bp','layered-bp'}),'LDPCDeocdingMethod must be "bp" or "layered-bp".')
        % For 'bp' and 'layered-bp' alphaBeta is unused by LDPC dec
        % algorithm
        alphaBeta = 1;
    end

    if nvPairs.EarlyTermination
        term = 'early';
    else
        term = 'max';
    end

    ldpcParams = struct('LDPCDecodingMethod',ldpcDecMeth,'alphaBeta',alphaBeta, ...
                        'MaximumLDPCIterationCount',nvPairs.MaximumLDPCIterationCount,'Termination',term);

end
