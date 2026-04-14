function ehtValidateSpatialMappingMatrix(spatialMappingMatrix)
%ehtValidateSpatialMappingMatrix Validate Spatial Mapping Matrix
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SPATIALMAPPINGMATRIX can be of size Nsts-by-Nt, where Nsts is the
%   number of space time streams and Nt is the number of transmit antennas.
%   Alternatively, it can be of size Nst-by-Nsts-Nt, where Nst is the
%   number of occupied subcarriers determined by the ChannelBandwidth
%   property. Nst must be 26, 52, 78, 106, 132, 242, 484, 726, 968, 996,
%   1480, 1992, 2476, 2988, or 3984.
%
%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Independent validation of spatialMappingMatrix property sizes.
validateattributes(spatialMappingMatrix,{'double'},{'3d','nonempty','nonnan','finite'},mfilename,'SpatialMappingMatrix');
is3DFormat = (ndims(spatialMappingMatrix)==3)||(iscolumn(spatialMappingMatrix)&&~isscalar(spatialMappingMatrix));
numSTS = size(spatialMappingMatrix,1+is3DFormat);
numTx  = size(spatialMappingMatrix,2+is3DFormat);
nst = [26 52 78 106 132 242 484 726 968 996 1480 1992 2476 2988 3984]; % RU size in subcarriers
errStr = sprintf('%u ',nst); % Convert to char array of elements with trailing space
errStr = ['[' errStr(1:end-1) ']']; % Remove last trailing space
coder.internal.errorIf((is3DFormat&&~any(size(spatialMappingMatrix,1)==nst))||(numSTS>8)||(numSTS>numTx), ...
    'wlan:shared:InvalidSpatialMapMtxDim',errStr);

end