function validatePhase(phase, sizeMappedSymbols, fileName)
% validatePhase(PHASE, SIZEMAPPEDSYMBOLS, FILENAME) validates the optional
% input phase and checks that the mapped symbols and the phase have
% compatible sizes to apply implicit expansion. For every dimension, the
% dimension sizes of the mapped symbols and the phase are either the same
% or one of them is 1.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
% PHASE is a scalar, vector, matrix or multidimensional array specifying
% the phase rotation to apply to mapped symbols in radians.
%
% SIZEMAPPEDSYMBOLS is a row vector with the size of the dimensions of the
% mapped symbols.
%
% FILENAME is a character vector specifying the name of the function that 
% calls validatePhase. 

%   Copyright 2017 The MathWorks, Inc.

%#codegen

validateattributes(phase, {'double'}, {'real'}, fileName, 'Phase rotation');

sizePhase = size(phase);
M = min(numel(sizePhase),numel(sizeMappedSymbols)); % Number of dimensions to compare
sharedNonScalarDims = (sizePhase(1:M)>1) & (sizeMappedSymbols(1:M)>1); % True for shared non-scalar dimensions 
coder.internal.errorIf(~all(sizePhase(sharedNonScalarDims)==sizeMappedSymbols(sharedNonScalarDims)), ...
    'wlan:wlanConstellationMap:InvalidPhase');
end