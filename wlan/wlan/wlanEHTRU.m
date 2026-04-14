classdef wlanEHTRU < comm.internal.ConfigBase
%wlanEHTRU Creates the RU and User properties of the channel bandwidth
%   CFGRU = wlanEHTRU(SIZE,INDEX,USERNUMBERS) creates a resource unit (RU)
%   configuration object. This object contains properties to configure an
%   EHT RU, including the users associated with it. SIZE is an integer
%   specifying the RU size and must be one of 26, 52, 78, 106, 132, 242,
%   484, 726, 968, 996, 1480, 1992, 2476, 2988, or 3984. INDEX is an
%   integer between 1 and 148 specifying the RU index. USERNUMBERS is a
%   vector of integers specifying the 1-based index of the users
%   transmitted on this RU. This number is used to index the appropriate
%   User objects within wlanEHTMUConfig.
%
%   CFGRU = wlanEHTRU(...,Name,Value) creates an object, CFGRU, that holds
%   the properties for each RU and its respective users. The specified
%   property Name is set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanEHTRU objects are used to parameterize RUs within an EHT MU
%   transmission, and therefore are part of the wlanEHTMUConfig object.
%
%   wlanEHTRU properties:
%
%   PowerBoostFactor     - Power boost factor
%   SpatialMapping       - Spatial mapping scheme
%   SpatialMappingMatrix - Spatial mapping matrix(ces)
%   Beamforming          - Enable beamforming
%   Size                 - Resource unit size
%   Index                - Resource unit index
%   UserNumbers          - Indices of users transmitted on this RU
%

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

properties
    %PowerBoostFactor Power boost factor for each RU
    %   Specify the power boost factor of the RU in the range [0.5,2]. The
    %   default is 1.
    PowerBoostFactor (1,1) {mustBeNumeric,mustBeGreaterThanOrEqual(PowerBoostFactor,0.5),mustBeLessThanOrEqual(PowerBoostFactor,2)} = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'direct' | 'hadamard'|
    %   'fourier' | 'custom'. The default value of this property is
    %   'direct', which applies NumSpaceTimeStreams is equal to
    %   NumTransmitAntennas.
    SpatialMapping (1,1) wlan.type.SpatialMapping = wlan.type.SpatialMapping.direct;
    %SpatialMappingMatrix Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix(ces) as a real or complex, 2D
    %   matrix or 3D array. This property applies when you set the
    %   SpatialMapping property to 'Custom'. It can be of size
    %   NstsTotal-by-Nt, where NstsTotal is the sum of the elements in the
    %   NumSpaceTimeStreams property and Nt is the NumTransmitAntennas
    %   property. In this case, the spatial mapping matrix applies to all
    %   the subcarriers. Alternatively, it can be of size Nst-by-
    %   NstsTotal-Nt, where Nst is the number of occupied subcarriers
    %   determined by the RU size. Specifically, Nst is 26, 52, 78, 106,
    %   132, 242, 484, 726, 968, 996, 1480, 1992, 2476, 2988, or 3984. In
    %   this case, each occupied subcarrier can have its own spatial
    %   mapping matrix. In either 2D or 3D case, the spatial mapping matrix
    %   for each subcarrier is normalized. The default value of this
    %   property is 1.
    SpatialMappingMatrix {wlan.internal.ehtValidateSpatialMappingMatrix} = complex(1);
    %Beamforming Enable beamforming
    %   Set this property to false when the specified SpatialMappingMatrix
    %   property is not a beamforming steering matrix. This property
    %   applies when SpatialMapping property is set to 'Custom'. This
    %   property is only applicable for OFDMA, single user non-OFDMA, and
    %   NDP. The default value is true.
    Beamforming (1,1) logical = true;
end
properties (SetAccess=private)
    %Size Resource unit size
    % Specify the size of the RU. If this RU is an MRU, Size is a vector of
    % RU sizes which combines RUs to create the MRU. Otherwise, Size is a
    % scalar. Elements of size must be one of 26, 52, 106, 242, 484, 968,
    % 996, 1992 (2x996), and 3984 (4x996). The default value is 242.
    Size {mustBeNumeric,mustBeMember(Size,[0 26 52 106 242 484 968 996 1992 3984])} = 3984;
    %Index Resource unit index
    %   Specify the RU index as a non-zero integer. The RU index specifies
    %   the location of the RU within the channel. For example, in an 80
    %   MHz transmission there are four possible 242 tone RUs, one in each
    %   20 MHz subchannel. RU# 242-1 (size 242, index 1) is the RU
    %   occupying the lowest absolute frequency within the 80 MHz, and RU#
    %   242-4 (size 242, index 4) is the RU occupying the highest absolute
    %   frequency. If this RU is an MRU, Index is a vector of RU indices
    %   which combine to create the MRU.
    Index {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(Index,0),mustBeLessThanOrEqual(Index,148)} = 0;
    %UserNumbers Indices of users transmitting on this RU
    %   UserNumbers is the 1-based indices of the users which are 
    %   transmitted on this RU. This number is used to index the 
    %   appropriate User objects within wlanEHTMUConfig.
    UserNumbers = 1;
end

methods       
    function obj = wlanEHTRU(size,index,userNumbers,varargin)
        % For codegen set maximum dimensions to force varsize
        if ~isempty(coder.target)
            spatialMappingMatrix = complex(1);
            coder.varsize('spatialMappingMatrix',[4*996 8 8],[1 1 1]); % Add variable-size support
            obj.SpatialMappingMatrix = spatialMappingMatrix; % Default
        end
        obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
        obj.Size = size;
        obj.Index = index;
        obj.UserNumbers = userNumbers;
    end
end
   
methods (Access = protected)
    function flag = isInactiveProperty(obj,prop)
        flag = false;
        if strcmp(prop,'Beamforming')
            % Hide Beamforming unless single user with custom spatial mapping
            flag = ~isscalar(obj.UserNumbers) || (obj.SpatialMapping ~= wlan.type.SpatialMapping.custom);
        elseif strcmp(prop,'SpatialMappingMatrix')
            % Hide SpatialMappingMatrix when SpatialMapping is not Custom
            flag = obj.SpatialMapping ~= wlan.type.SpatialMapping.custom;
        end
    end
end
end
