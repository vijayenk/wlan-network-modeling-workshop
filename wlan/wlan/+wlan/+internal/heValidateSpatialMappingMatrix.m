function heValidateSpatialMappingMatrix(spatialMappingMatrix)
%heValidateSpatialMappingMatrix Validate Spatial Mapping Matrix
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SPATIALMAPPINGMATRIX can be of size Nsts-by-Nt, where Nsts is the
%   number of space time streams and Nt is the number of transmit antennas.
%   Alternatively, it can be of size Nst-by-Nsts-Nt, where Nst is the
%   number of occupied subcarriers determined by the ChannelBandwidth
%   property. Specifically, Nst is 242 for 'CBW20', 484 for 'CBW40', 996
%   for 'CBW80' and 1992 for 'CBW160'.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

% Independent validation of spatialMappingMatrix property sizes.
validateattributes(spatialMappingMatrix,{'double'},{'3d','nonempty','nonnan','finite'},mfilename,'SpatialMappingMatrix'); 
is3DFormat = (ndims(spatialMappingMatrix)==3)||(iscolumn(spatialMappingMatrix)&&~isscalar(spatialMappingMatrix));
numSTS = size(spatialMappingMatrix,1+is3DFormat);
numTx  = size(spatialMappingMatrix,2+is3DFormat);
nst = [26 52 106 242 484 996 1992]; % RU size in subcarriers
errStr = sprintf('%u ',nst); % Convert to char array of elements with trailing space
errStr = ['[' errStr(1:end-1) ']']; % Remove last trailing space 
coder.internal.errorIf((is3DFormat&&~any(size(spatialMappingMatrix,1)==nst))||(numSTS>8)||(numSTS>numTx), ...
    'wlan:shared:InvalidSpatialMapMtxDim',errStr);

end