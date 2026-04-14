function validateSpatialMappingMatrix(spatialMappingMatrix,numTx,numSTSRU,numST,varargin)
%validateSpatialMappingMatrix Validate spatial mapping matrix
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   validateSpatialMappingMatrix(spatialMappingMatrix,numTx,numSTSRU,numST)
%   validates the spatialMappingMatrix against the number of transmit
%   antennas, number of space-time streams per RU and the number of
%   space-time streams per user.
%
%   validateSpatialMappingMatrix(...,numRU) validates the
%   spatialMappingMatrix and display the RU number.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

ruNum = 1;
if nargin>4
    ruNum = varargin{1};
end

SPMtx = spatialMappingMatrix;
% Validate spatial mapping matrix
is3DFormat = (ndims(SPMtx) == 3) || (iscolumn(SPMtx) && ~isscalar(SPMtx));
numSTSTotal = size(SPMtx,1+is3DFormat);
numTxRef = size(SPMtx,2+is3DFormat);
coder.internal.errorIf((is3DFormat && (size(SPMtx,1)~=numST(1))) || (numSTSTotal~=numSTSRU) || (numTxRef~=numTx), ...
    'wlan:shared:MappingMtxNotMatchOtherPropEHT',numSTSRU,numTx,numST(1),ruNum); % For codegen

end