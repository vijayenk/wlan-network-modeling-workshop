classdef wlanHEMURU < comm.internal.ConfigBase
%wlanHEMURU Creates the RU and User properties of each assignment index
%   CFGRU = wlanHEMURU(SIZE,INDEX,USERNUMBERS) creates a resource unit (RU)
%   configuration object. This object contains properties to configure an
%   HE RU, including the users associated with it. SIZE is an integer
%   specifying the RU size and must be one of 26, 52, 106, 242, 484, 996,
%   or 2*996. INDEX is an integer between 0 and 74 specifying the RU index.
%   USERNUMBERS is a vector of integers specifying the 1-based index of the
%   users transmitted on this RU. This number is used to index the
%   appropriate User objects within wlanHEMUConfig.
%
%   CFGRU = wlanHEMURU(...,Name,Value) creates an object that holds the
%   properties for each RU and the respective users, CFGRU, with the
%   specified property Name set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanHEMURU objects are used to parameterize users within an HE-MU
%   transmission, and therefore are part of the wlanHEMUConfig object.
%
%   wlanHEMURU properties: 
%
%   PowerBoostFactor     - Power boost factor
%   SpatialMapping       - Spatial mapping scheme  
%   SpatialMappingMatrix - Spatial mapping matrix(ces)
%   Beamforming          - Enable beamforming
%   Size                 - Resource unit size 
%   Index                - Resource unit index
%   UserNumbers          - Indices of users transmitted on this RU

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

properties
    %PowerBoostFactor Power boost factor for each RU
    %   Specify the power boost factor of the RU in the range [0.5,2]. The
    %   default is 1.
    PowerBoostFactor (1,1) {mustBeNumeric, mustBeGreaterThanOrEqual(PowerBoostFactor,0.5), mustBeLessThanOrEqual(PowerBoostFactor,2)} = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' | 'Hadamard'|
    %   'Fourier' | 'Custom'. The default value of this property is
    %   'Direct', which applies NumSpaceTimeStreams is equal to
    %   NumTransmitAntennas.
    SpatialMapping = 'Direct';
    %SpatialMappingMatrix Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix(ces) as a real or complex, 2D
    %   matrix or 3D array. This property applies when you set the
    %   SpatialMapping property to 'Custom'. It can be of size
    %   NstsTotal-by-Nt, where NstsTotal is the sum of the elements in the
    %   NumSpaceTimeStreams property and Nt is the NumTransmitAntennas
    %   property. In this case, the spatial mapping matrix applies to all
    %   the subcarriers. Alternatively, it can be of size Nst-by-
    %   NstsTotal-Nt, where Nst is the number of occupied subcarriers
    %   determined by the RU size. Specifically, Nst is 26, 52, 106, 242,
    %   484, 996 and 2x996. In this case, each occupied subcarrier can have
    %   its own spatial mapping matrix. In either 2D or 3D case, the
    %   spatial mapping matrix for each subcarrier is normalized. The
    %   default value of this property is 1.
    SpatialMappingMatrix {wlan.internal.heValidateSpatialMappingMatrix} = complex(1);
    %Beamforming Enable beamforming
    %   Set this property to true when the specified SpatialMappingMatrix
    %   property is a beamforming steering matrix. This property applies
    %   only when SpatialMapping property is set to 'Custom'. The default
    %   value is true.    
    Beamforming (1,1) logical = true;
end
properties (SetAccess=private)
    %Size Resource unit size
    %   Specify the size of the RU. The draft standard defines the RU size
    %   must be one of 26, 52, 106, 242, 484, 996 and 1992 (2x996). The
    %   default value for this property is 242.
    Size (1,1) {mustBeNumeric, mustBeMember(Size,[0 26 52 106 242 484 996 1992])} = 242;
    %Index Resource unit index
    %   Specify the RU index as a non-zero integer. The RU index specifies
    %   the location of the RU within the channel. For example, in an 80
    %   MHz transmission there are four possible 242 tone RUs, one in each
    %   20 MHz subchannel. RU# 242-1 (size 242, index 1) is the RU
    %   occupying the lowest absolute frequency within the 80 MHz, and RU#
    %   242-4 (size 242, index 4) is the RU occupying the highest absolute
    %   frequency. The default value for this property is 1.
    Index (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(Index,0), mustBeLessThanOrEqual(Index,74)} = 0;
    %UserNumbers Indices of users transmitting on this RU
    %   UserNumbers is the 1-based indices of the users which are 
    %   transmitted on this RU. This number is used to index the 
    %   appropriate User objects within wlanHEMUConfig.
    UserNumbers = 1;
end

properties(Constant, Hidden)
    SpatialMapping_Values = {'Direct','Hadamard','Fourier','Custom'};
end

methods       
    function obj = wlanHEMURU(size,index,userNumbers,varargin)
        % For codegen set maximum dimensions to force varsize
        if ~isempty(coder.target)
            spatialMapping = 'Direct';
            coder.varsize('spatialMapping',[1 8],[0 1]); % Add variable-size support
            obj.SpatialMapping = spatialMapping; % Default
            spatialMappingMatrix = complex(1);
            coder.varsize('spatialMappingMatrix',[2*996 8 8],[1 1 1]); % Add variable-size support
            obj.SpatialMappingMatrix = spatialMappingMatrix; % Default
        end
        obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
        obj.Size = size;
        obj.Index = index;
        obj.UserNumbers = userNumbers;
    end

    function obj = set.SpatialMapping(obj,val)
        val = validateEnumProperties(obj,'SpatialMapping',val);
        obj.SpatialMapping = val;
    end 
end
   
methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = false;
        if strcmp(prop,'Beamforming')
            % Hide Beamforming unless single user with custom spatial
            % mapping
            flag = (numel(obj.UserNumbers)>1) || ~strcmp(obj.SpatialMapping,'Custom');
        elseif strcmp(prop,'SpatialMappingMatrix')
            % Hide SpatialMappingMatrix when SpatialMapping is not Custom
            flag = ~strcmp(obj.SpatialMapping,'Custom');
        end
      end
    end
end
