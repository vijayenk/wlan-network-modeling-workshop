function alg = determineEqualizerAlgorithm(noiseEst)
%determineEqualizerAlgorithm Choose ZF or MMSE equalization algorithm
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    if noiseEst == 0
        alg = "ZF";
    else
        alg = "MMSE";
    end
end
