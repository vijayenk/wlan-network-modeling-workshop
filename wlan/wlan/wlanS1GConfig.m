classdef wlanS1GConfig < comm.internal.ConfigBase
%wlanS1GConfig Create a sub 1 GHz (S1G) format configuration object
%   CFGS1G = wlanS1GConfig creates a sub 1 GHz format configuration object.
%   This object contains the transmit parameters for the S1G format of IEEE
%   802.11 standard.
%
%   CFGS1G = wlanS1GConfig(Name,Value) creates a S1G object, CFGS1G, with
%   the specified property Name set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanS1GConfig methods:
%
%   packetFormat - S1G packet format 
%   transmitTime - Time required to transmit a packet
%
%   wlanS1GConfig properties:
%
%   ChannelBandwidth      - Channel bandwidth 
%   Preamble              - Preamble type
%   NumUsers              - Number of users
%   UserPositions         - User positions
%   NumTransmitAntennas   - Number of transmit antennas 
%   NumSpaceTimeStreams   - Number of space-time streams 
%   SpatialMapping        - Spatial mapping scheme
%   SpatialMappingMatrix  - Spatial mapping matrix(ces)
%   Beamforming           - Enable beamforming in a long preamble packet
%   STBC                  - Enable space-time block coding
%   MCS                   - Modulation and coding schemes
%   ChannelCoding         - Channel coding
%   APEPLength            - APEP lengths
%   PSDULength            - Number of bytes to be coded in the packet 
%                           including the A-MPDU and any MAC padding
%   GuardInterval         - Guard interval type
%   GroupID               - Group identifier
%   PartialAID            - Partial association identifier 
%   UplinkIndication      - Enable uplink indication
%   Color                 - Access point color identifier
%   TravelingPilots       - Enable traveling pilots
%   ResponseIndication    - Response indication type
%   RecommendSmoothing    - Recommend smoothing for channel estimation

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen
    
properties (Access = public)
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW1', 'CBW2' (default),
    %   'CBW4', 'CBW8', or 'CBW16'.
    ChannelBandwidth = 'CBW2';
    %Preamble Preamble type
    %   Specify the preamble type as one of 'Short' (default), 'Long'. This
    %   property only applies when the ChannelBandwidth property is not
    %   'CBW1'.
    Preamble = 'Short';
    %NumUsers Number of users
    %   Specify the number of users as an integer scalar from 1 to 4. The
    %   default value is 1.
    NumUsers = 1;
    %UserPositions User positions
    %   Specify the user positions as an integer row vector with length
    %   equal to NumUsers and element values from 0 to 3, in a strictly
    %   increasing order. This property applies when NumUsers is greater
    %   than 1. The default value is [0 1].
    UserPositions = [0 1];
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as an integer scalar from 1
    %   to 4. The default value is 1.
    NumTransmitAntennas = 1;
    %NumSpaceTimeStreams Number of space-time streams per user
    %   Specify the number of space-time streams as integer scalar or row
    %   vector with length equal to NumUsers. For a scalar, it must be a
    %   value from 1 to 4. For a row vector, all elements must be values
    %   from 1 to 4. The sum of all elements in the vector must be no
    %   larger than 4. The default value is 1.
    NumSpaceTimeStreams = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' (default),
    %   'Hadamard', 'Fourier', or 'Custom'. The default applies when the
    %   sum of the elements in NumSpaceTimeStreams is equal to
    %   NumTransmitAntennas.
    SpatialMapping = 'Direct';
    %SpatialMappingMatrix Spatial mapping matrix
    %   Specify the spatial mapping matrix as a scalar, a matrix, or a 3D
    %   array. The values can be real or complex. This property applies
    %   when the SpatialMapping property is 'Custom'. When
    %   SpatialMappingMatrix is a Nsts_Total-by-Nt matrix, the spatial
    %   mapping matrix applies to all the subcarriers. Nsts_Total is the
    %   sum of the elements in the NumSpaceTimeStreams property and Nt is
    %   the NumTransmitAntennas property. Alternatively if
    %   SpatialMappingMatrix is an Nst-by-Nsts_Total-by-Nt array, each
    %   occupied subcarrier can have its own spatial mapping matrix. Nst is
    %   the number of occupied subcarriers determined by the
    %   ChannelBandwidth property. Specifically, Nst is 26 for 'CBW1', 56
    %   for 'CBW2', 114 for 'CBW4', 242 for 'CBW8' and 484 for 'CBW16'. In
    %   either 2D or 3D case, the spatial mapping matrix for each
    %   subcarrier is normalized. The default value for
    %   SpatialMappingMatrix is 1.
    SpatialMappingMatrix = 1;
    %Beamforming Enable beamforming in a long preamble packet
    %   Set this property to true when the specified SpatialMappingMatrix
    %   property is a beamforming steering matrix. This property applies
    %   for a long preamble (Preamble = 'Long') with NumUsers = 1 and
    %   the SpatialMapping = 'Custom'. The default value is true.
    Beamforming (1,1) logical = true;
    %STBC Enable space-time block coding
    %   Space-time block coding, specified as false (default) or true. Set
    %   this property to true to enable space-time block coding in the data
    %   field transmission. This property applies when NumUsers is 1.
    STBC (1,1) logical = false;
    %MCS Modulation and coding scheme per user
    %   Specify the modulation and coding scheme per user as an integer
    %   scalar or row vector with length equal to NumUsers. Elements
    %   must be integer values from 0 to 12. If specified as a scalar, the
    %   setting applies to all users. The default value is 0.
    MCS = 0;
end

properties (SetAccess = private)
    %ChannelCoding Forward error correction code type
    %   This is a read-only property. Only binary convolutional coding
    %   (BCC) is supported.
    ChannelCoding = 'BCC';
end

properties (Access = public)
    %APEPLength APEP length per user
    %   Specify the APEP length in bytes per user as an integer scalar or
    %   row vector with length equal to NumUsers. If specified as a scalar,
    %   the setting applies to all users. All element values must be
    %   integers from 0 to 65535. The default value is 256.
    APEPLength = 256;
end

properties (SetAccess = private, GetAccess = public)
    %PSDULength PSDU lengths
    %   The number of bytes carried in a packet, including the A-MPDU and
    %   any MAC padding. This property is read-only and is calculated
    %   internally based on other properties.
    PSDULength;
end

properties (Access = public) 
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) type for data field
    %   transmission as 'Long' (default) or 'Short'.
    GuardInterval = 'Long';
    %GroupID Group identifier
    %   Specify the group identifier as an integer scalar. The GroupID is
    %   signaled during a multi-user transmission, therefore this property
    %   applies for a long preamble (Preamble = 'Long') and when NumUsers
    %   is greater than 1. GroupID must be a value from 1 to 62. The
    %   default value is 1.
    GroupID = 1;
    %PartialAID Abbreviated indication of the intended PSDU recipient(s)
    %   Specify the partial association identifier of the intended
    %   recipient. For an uplink transmission (UplinkIndication = true),
    %   the partial identifier is the last nine bits of the BSSID and must
    %   be an integer scalar from 0 to 511. For a downlink transmission
    %   (UplinkIndication = false), the partial identifier combines the
    %   association ID and the BSSID of its serving AP and must be an
    %   integer scalar from 0 to 63. The default partial identifier is 37.
    PartialAID = 37;
    %UplinkIndication Enable uplink indication
    %   Set this property to true to enable uplink indication. This
    %   property only applies when ChannelBandwidth is not 'CBW1'. The
    %   default is false.
    UplinkIndication (1,1) logical = false;
    %Color Access point color identifier
    %   Specify the color number of an access point for a downlink
    %   transmission as a scalar integer from 0 to 7. This property only
    %   applies when ChannelBandwidth is not 'CBW1', NumUsers is 1, and
    %   UplinkIndication is false. The default is 0.
    Color = 0;
    %TravelingPilots Enable traveling pilots
    %   Set this property to true to enable traveling pilots. Traveling
    %   pilots allow a receiver to track a changing channel due to Doppler
    %   spread. The default is false.
    TravelingPilots (1,1) logical = false;
    %ResponseIndication Response indication type
    %   Specify the response expected to the packet transmitted as a one of
    %   'None' (default), 'NDP', 'Normal', or 'Long'.
    ResponseIndication = 'None';
    %RecommendSmoothing Recommend smoothing for channel estimation
    %   Set this property to true to indicate smoothing is recommended for
    %   channel estimation. The default is true.
    RecommendSmoothing (1,1) logical = true;  
end

properties(Constant, Hidden)
    ChannelBandwidth_Values = {'CBW1','CBW2','CBW4','CBW8','CBW16'};
    Preamble_Values = {'Short','Long'};
    SpatialMapping_Values = {'Direct','Hadamard','Fourier','Custom'}
    GuardInterval_Values = {'Short','Long'};
    ResponseIndication_Values = {'None','NDP','Normal','Long'};
    MaxNumUsers = 4; % Maximum number of users
    MaxNumSTS = 4;   % Maximum number of space-time streams
    MaxNumTx = 4;    % maximum number of transmit antennas
end

methods
  function obj = wlanS1GConfig(varargin)
    % For codegen set maximum dimensions to force varsize
    if ~isempty(coder.target)
        channelBandwidth = 'CBW2';
        coder.varsize('channelBandwidth',[1 5],[0 1]); % Add variable-size support
        obj.ChannelBandwidth = channelBandwidth; % Default

        preamble = 'Short';
        coder.varsize('preamble',[1 5],[0 1]); % Add variable-size support
        obj.Preamble = preamble; % Default

        spatialMapping = 'Direct';
        coder.varsize('spatialMapping',[1 8],[0 1]); % Add variable-size support
        obj.SpatialMapping = spatialMapping; % Default

        guardInterval = 'Long';
        coder.varsize('guardInterval',[1 5],[0 1]); % Add variable-size support
        obj.GuardInterval = guardInterval; % Default

        responseIndication = 'None';
        coder.varsize('responseIndication',[1 6],[0 1]); % Add variable-size support
        obj.ResponseIndication = responseIndication; % Default
    end
    obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
  end

  function obj = set.ChannelBandwidth(obj,val)
    propName = 'ChannelBandwidth';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end
  
  function obj = set.Preamble(obj,val)
    propName = 'Preamble';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.NumUsers(obj,val)
    propName = 'NumUsers';
    validateattributes(val, {'numeric'},{'real','integer','scalar','>=',1,'<=',obj.MaxNumUsers}, ...
        [class(obj) '.' propName],propName); 
    obj.(propName) = val;
  end

  function obj = set.UserPositions(obj,val)
    propName = 'UserPositions';
    validateattributes(val, {'numeric'},{'real','integer','row','>=',0,'<=',obj.MaxNumUsers-1,'increasing'}, ...
        [class(obj) '.' propName],propName);
    obj.(propName) = val;                
  end

  function obj = set.NumTransmitAntennas(obj,val)
    propName = 'NumTransmitAntennas';
    validateattributes(val, {'numeric'}, ...
        {'real','integer','scalar','>=',1,'<=',obj.MaxNumTx}, ...
        [class(obj) '.' propName],propName);
    obj.(propName) = val;
  end

  function obj = set.NumSpaceTimeStreams(obj,val)
    propName = 'NumSpaceTimeStreams';
    validateattributes(val, {'numeric'},{'real','integer','row','>=',1,'<=',obj.MaxNumSTS}, ...
        [class(obj) '.' propName],propName);
    coder.internal.errorIf(~isscalar(val)&& ...
        ((length(val)>obj.MaxNumUsers)||any(val>obj.MaxNumSTS)||sum(val)>obj.MaxNumSTS), ...
        'wlan:shared:InvalidMUSTS',obj.MaxNumUsers,obj.MaxNumSTS,obj.MaxNumSTS); 
    obj.(propName) = val;
  end

  function obj = set.SpatialMapping(obj,val)
    propName = 'SpatialMapping';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.SpatialMappingMatrix(obj,val)
    propName = 'SpatialMappingMatrix';
    validateattributes(val, {'double'}, {'3d','finite','nonempty'}, ...
        [class(obj) '.' propName],propName); 

    is3DFormat = (ndims(val)==3) || (iscolumn(val)&&~isscalar(val));
    numSTS = size(val,1+is3DFormat);
    numTx  = size(val,2+is3DFormat);

    [Nsd,Nsp] = wlan.internal.s1gSubcarriersPerSymbol('Data');
    Nst = Nsd+Nsp;
    errStr = sprintf('%u ',Nst'); % Convert to char array of elements with trailing space
    errStr = ['[' errStr(1:end-1) ']']; % Remove last trailing space
    coder.internal.errorIf( ...
        (is3DFormat&&~any(size(val,1)==Nst)) || (numSTS>obj.MaxNumSTS) || ...
        (numTx>obj.MaxNumTx) || (numSTS>numTx), ...
        'wlan:shared:InvalidSpatialMapMtxDim',errStr);
    obj.(propName) = val;
  end
  
  function obj = set.MCS(obj,val)
    propName = 'MCS';
    validateattributes(val, {'numeric'},{'real','integer','row','>=',0,'<=',12}, ...
      [class(obj) '.' propName], propName);
    coder.internal.errorIf(length(val)>obj.MaxNumUsers,'wlan:shared:InvalidMUMCS',obj.MaxNumUsers);
    obj.(propName) = val;
  end

  function obj = set.APEPLength(obj, val)
    propName = 'APEPLength';
    maxBytes = 65535; % Maximum number of bytes
    validateattributes(val,{'numeric'},{'real','integer','row','>=',0,'<=',maxBytes}, ...
      [class(obj) '.' propName],propName);
    coder.internal.errorIf(~isscalar(val) && ((length(val)>obj.MaxNumUsers)||any(val==0)), ...
      'wlan:shared:InvalidMUAPEPLen',obj.MaxNumUsers);
    obj.(propName) = val;
  end

  function obj = set.GuardInterval(obj,val)
    propName = 'GuardInterval';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.GroupID(obj,val)
    propName = 'GroupID';
    validateattributes(val,{'numeric'},{'real','scalar','integer','>=',1,'<=',62}, ...
        [class(obj) '.' propName],propName);
    obj.(propName) = val;
  end

  function obj = set.PartialAID(obj,val)
    propName = 'PartialAID';
    validateattributes(val, {'numeric'},{'real','scalar','integer','>=',0,'<=',511}, ...
        [class(obj) '.' propName],propName);
    obj.(propName) = val;
  end
  
  function obj = set.Color(obj,val)
    propName = 'Color';
    validateattributes(val,{'numeric'},{'real','scalar','integer','>=',0,'<=',7}, ...
        [class(obj) '.' propName],propName);
    obj.(propName) = val;
  end
  
  function obj = set.ResponseIndication(obj,val)
    propName = 'ResponseIndication';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end
  
  function PSDULen = get.PSDULength(obj)
    % Returns PSDU length in bytes for all users
    if isPSDULengthUndefined(obj,'warn')
        PSDULen = zeros(1,0);
    else
        PSDULen = plmeTXTIMEPrimitive(obj);
    end
  end

  function format = packetFormat(obj)
    %packetFormat Get S1G packet format
    %   Returns the S1G packet format as a character vector, based on the
    %   current configuration. Packet format is one of 'S1G-1M',
    %   'S1G-Short' or 'S1G-Long'.
    if strcmp(obj.ChannelBandwidth,'CBW1')
        format = 'S1G-1M';
    elseif strcmp(obj.Preamble,'Short')
        format = 'S1G-Short';
    else
        format = 'S1G-Long';
    end
  end

  function t = transmitTime(obj,varargin)
    %transmitTime Returns the time required to transmit a packet
    %   T = transmitTime(CFG) returns the time required to transmit a
    %   packet in seconds.
    %
    %   T = transmitTime(CFG,UNIT) returns the transmit time in the
    %   requested unit. UNIT must be 'seconds', 'milliseconds',
    %   'microseconds', or 'nanoseconds'.

    narginchk(1,2);
    validateForPSDULengthCalculation(obj,'error');

    s = privInfo(obj);

    % Validate PSDULength
    aPSDUMaxLength = 797159; % Max octets, aPSDUMaxLength, Table 24-37
    coder.internal.errorIf(any(s.PSDULength>aPSDUMaxLength), ...
        'wlan:shared:InvalidPSDULength',max(s.PSDULength),aPSDUMaxLength);

    % When aggregation is used the maximum number of data symbols which can
    % be signaled is 511. Check for this limit.
    coder.internal.errorIf(s.NumDataSymbols>511, ...
          'wlan:wlanS1GConfig:InvalidNumSym',s.NumDataSymbols);

    t = wlan.internal.convertTransmitTime(s.TxTime,varargin{:});
  end
  
  function varargout = validateConfig(obj, varargin)
    % validateConfig Validate the wlanS1GConfig object
    %   validateConfig(cfgS1G) validates the dependent properties for the
    %   specified wlanS1GConfig configuration object.
    % 
    %   For INTERNAL use only, subject to future changes:
    %
    %   validateConfig(cfgS1G, MODE) validates only the subset of dependent
    %   properties as specified by the MODe input. MODE must be one of:
    %       'MCS'
    %       'SMapping'
    %       'SMappingMCS'
    %       'SMappingMCS10'
    %       'SMappingMCSTPilots'
    %       'SpatialMCSTPilotsID'
    %       'SMappingMCSTPilotsID'
    
    nargoutchk(0,1);
    narginchk(1,2);
    
    if (nargin==2)
        mode = varargin{1};
    else
        mode = 'Full';
    end

    switch mode
        case 'MCS'                      % wlanFieldIndices
            s = validateMCSLengthTxTime(obj);
        case 'SMapping'                 % S1G-LTF (Short and 1MHz), S1G-DSTF, S1G-DLTF
            validateSpatialMapping(obj);
        case 'SMappingMCS'              % S1G-SIG-B
            validateSpatialMapping(obj);
            s = validateMCSLengthTxTime(obj);
        case 'SMappingMCS10'            % S1G-STF (Short and 1MHz)
            validateSpatialMapping(obj);
            validateMCS10(obj);
        case 'SMappingMCSTPilots'       % S1G-Data
            validateSpatialMapping(obj);
            validateTravelingPilots(obj);
            s = validateMCSLengthTxTime(obj);
        case 'SpatialMCSTPilotsID'      % S1G-SIG-A
            validateSpatial(obj);
            validateTravelingPilots(obj);
            validatePartialAID(obj);
            validateUserPos(obj);
            s = validateMCSLengthTxTime(obj);
        case 'SMappingMCSTPilotsID'     % S1G-SIG
            validateSpatialMapping(obj);
            validateTravelingPilots(obj);
            validatePartialAID(obj);
            s = validateMCSLengthTxTime(obj);
        otherwise   % 'Full' validation for waveform generation
            validateSpatialMapping(obj);
            validateTravelingPilots(obj);
            validatePartialAID(obj);
            validateUserPos(obj);
            s = validateMCSLengthTxTime(obj);
    end
    
    if nargout == 1
        varargout{1} = s;
    end
  end

end   

methods (Access = protected)
  function flag = isInactiveProperty(obj, prop)
    flag = false;
    if strcmp(prop,'Preamble')
        % Hide preamble as not applicable when 1M configuration
        flag = strcmp(packetFormat(obj),'S1G-1M');
    elseif strcmp(prop,'STBC')
        % Hide STBC for MU as implied false
        flag = obj.NumUsers>1;
    elseif any(strcmp(prop,{'PartialAID','UplinkIndication'}))
        % Hide PartialAid and UplinkIndication MU or 1M as not signaled
        flag = obj.NumUsers>1 || strcmp(packetFormat(obj),'S1G-1M');
    elseif any(strcmp(prop,{'Color'}))
        % Hide PartialAid and UplinkIndication MU or 1M as not signaled.
        % Only signaled in 2M SU downlink transmission
        flag = obj.NumUsers>1 || strcmp(packetFormat(obj),'S1G-1M') || obj.UplinkIndication==true;
    elseif any(strcmp(prop,{'UserPositions','GroupID'}))
        % Hide UserPosition and GroupID when SU transmission as only used
        % for MU signaling
        flag = obj.NumUsers==1;
    elseif strcmp(prop,'SpatialMappingMatrix')
        % Hide SpatialMappingMatrix unless "Custom" spatial mapping is used
        flag = ~strcmp(obj.SpatialMapping,'Custom');
    elseif strcmp(prop,'Beamforming')
        % Hide Beamforming unless long 2M single user with custom spatial
        % mapping
        flag = ~strcmp(packetFormat(obj),'S1G-Long') || (obj.NumUsers>1) || ~strcmp(obj.SpatialMapping,'Custom');
    elseif strcmp(prop,'RecommendSmoothing')
        % Hide RecommendSmoothing when long 2M long with 1 STS or
        % multi-user (when its always off)
        flag = obj.NumUsers>1 || (strcmp(packetFormat(obj),'S1G-Long') && sum(obj.NumSpaceTimeStreams)==1);
    end
  end
  
  function [flag,msg] = isUndefinedProperty(obj, prop)
      % Returns true and the associated message catalog entry if the
      % property value is undefined in the current state
      flag = false;
      msg = '';
      if strcmp(prop, 'PSDULength')
          [flag,msg] = isPSDULengthUndefined(obj,'no action');
      end
  end
  
end

methods (Access = private)
  function flag = isValidMCS10(obj)
    % isValidMCS10 returns true if wlanS1GConfig configuration object with 
    % MCS=10 is valid. It occurs when ChannelBandwidth is equal to 'CBW1', 
    % MCS is equal to 10, and NumSpaceTimeStreams is equal to 1. 
    
    flag = ~(any(obj.MCS==10) && (~strcmp(packetFormat(obj),'S1G-1M')||any(obj.NumSpaceTimeStreams>1)));
  end

  function flag = isValidMCS12(obj)
    % isValidMCS12 returns true if wlanS1GConfig configuration object with
    % MCS=12 is valid. It occurs except for when ChannelBandwidth is 'CBW2',
    % MCS is equal to 12, and NumSpaceTimeStreams is equal to 1, 2, or 4.
    % IEEE P802.11-REVme/D6.0, June 2024

    flag = ~(any(obj.MCS==12) && strcmp(obj.ChannelBandwidth,'CBW2') && any(obj.NumSpaceTimeStreams==[1,2,4]));
  end
    
  function s = privInfo(obj)
    %privInfo Returns information relevant to the object
    %   S = privInfo(cfgS1G) returns a structure, S, containing the
    %   relevant information for the wlanS1GConfig object, cfgS1G.
    %   The output structure S has the following fields:
    %
    %   NumDataSymbols - Number of OFDM symbols for the Data field
    %   NumPadBits     - Number of pad bits in the Data field
    %   NumPPDUSamples - Number of PPDU samples per transmit antennas
    %   TxTime         - The time in microseconds, required to
    %                    transmit the PPDU.
    %   PSDULength     - PSDU length calculated according to the
    %                    PLME-TXTIME.confirm primitive in Section 24.4.3
    %                    IEEE P802.11ah/D5.0.

    % Calculate number of OFDM symbols
    [psduLen,txTime,numDataSymbols,numPadBits] = plmeTXTIMEPrimitive(obj);
    
    % Calculate burst time in samples   
    sr = wlan.internal.cbwStr2Num(obj.ChannelBandwidth); % MHz
    numPPDUSamples = txTime*sr;

    s = struct(...
        'NumDataSymbols', numDataSymbols, ...
        'NumPadBits',     numPadBits, ...
        'NumPPDUSamples', numPPDUSamples, ...
        'TxTime',         txTime, ...
        'PSDULength',     psduLen); 
  end
  
  function validateSTSTx(obj)
    %   ValidateSTSTx Validate NumTransmitAntennas, NumSpaceTimeStreams
    %   properties for wlanS1GConfig configuration object
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams

    % NumTx and Nsts: numTx cannot be less than sum(Nsts)
    coder.internal.errorIf(obj.NumTransmitAntennas<sum(obj.NumSpaceTimeStreams), ...
        'wlan:shared:NumSTSLargerThanNumTx');
  end

  function validateSpatial(obj)
    %   validateSpatial Validate the spatial properties for wlanS1GConfig 
    %   configuration object
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams, SpatialMapping

    validateSTSTx(obj);

    coder.internal.errorIf(strcmp(obj.SpatialMapping, 'Direct') && ...
        (sum(obj.NumSpaceTimeStreams)~=obj.NumTransmitAntennas), ...
        'wlan:shared:NumSTSNotEqualNumTxDirectMap');            
  end        

  function validateSpatialMapping(obj)
    %   validateSpatialMapping Validate the spatial mapping properties for
    %   wlanS1GConfig configuration object    
    %   Validated property-subset includes:
    %     ChannelBandwidth, NumTransmitAntennas, NumSpaceTimeStreams, ..
    %     SpatialMapping, SpatialMappingMatrix

    validateSpatial(obj);

    if strcmp(obj.SpatialMapping, 'Custom')
        % Validate spatial mapping matrix
        SPMtx = obj.SpatialMappingMatrix;
        is3DFormat = (ndims(SPMtx)==3) || (iscolumn(SPMtx)&&~isscalar(SPMtx));
        numSTSTotal = size(SPMtx,1+is3DFormat);
        numTx  = size(SPMtx,2+is3DFormat);
        [Nsd,Nsp] = wlan.internal.s1gSubcarriersPerSymbol('Data',obj.ChannelBandwidth);
        Nst = Nsd+Nsp; % Total number of occupied subcarriers
        coder.internal.errorIf((is3DFormat && (size(SPMtx,1)~=Nst)) || ...  
            (numSTSTotal~=sum(obj.NumSpaceTimeStreams)) || (numTx~=obj.NumTransmitAntennas), ...
            'wlan:shared:MappingMtxNotMatchOtherProp', ...
            sum(obj.NumSpaceTimeStreams),obj.NumTransmitAntennas,Nst);
    end            
  end        
  
  function s = validateMCSLengthTxTime(obj)
    %   validateMCSLength Validate MCS and Length properties, and resultant
    %   TxTime for wlanS1GConfig configuration object.
    %   Validated property-subset includes:   
    %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, GuardInterval, APEPLength
    
    validateForPSDULengthCalculation(obj,'error');
    
    s = privInfo(obj);
    
    % Validate PSDULength
    aPSDUMaxLength = 797159; % Max octets, aPSDUMaxLength, Table 24-37
    coder.internal.errorIf(any(s.PSDULength>aPSDUMaxLength), ...
        'wlan:shared:InvalidPSDULength',max(s.PSDULength),aPSDUMaxLength);
    
    % Validate txTime
    aPPDUMaxTime = 27920; % Max microseconds, aPPDUMaxTime, Table 24-37
    coder.internal.errorIf(s.TxTime>aPPDUMaxTime, ...
        'wlan:shared:InvalidPPDUDuration',round(s.TxTime),aPPDUMaxTime);
    
    % When aggregation is used the maximum number of data symbols which can
    % be signaled is 511. Check for this limit.
    coder.internal.errorIf(s.NumDataSymbols>511, ...
        'wlan:wlanS1GConfig:InvalidNumSym',s.NumDataSymbols);
  end
    
  function validateMCS10(obj)
    %   validateMCS10 Validate S1G 1MHz MCS10 configuration for
    %   wlanS1GConfig configuration object
    %   Validated property-subset includes:
    %     ChannelBandwidth, MCS, NumSpaceTimeStreams
    
    coder.internal.errorIf(~isValidMCS10(obj), ...
        'wlan:wlanS1GConfig:InvalidMCS10'); 
  end
  
  function validateUserPos(obj)
    %   validateUserPos Validate UserPositions against NumUsers for
    %   wlanS1GConfig configuration object. 
    %   Validated property-subset includes:
    %       NumUsers, UserPositions

    coder.internal.errorIf(obj.NumUsers>1&&(length(obj.UserPositions)~=obj.NumUsers), ...
        'wlan:shared:InvalidUserPosNumUsers');
  end

  function validatePartialAID(obj)
    %   validatePartialAID Validate PartialAID in Short and Long preamble
    %   wlanS1GConfig configuration object
    %   Validated property-subset includes:
    %       PartialAID, NumUsers, UplinkIndication
        
    numUsers = obj.NumUsers;
    coder.internal.errorIf((~strcmp(packetFormat(obj),'S1G-1M')&&(numUsers==1)) && ...
        (obj.UplinkIndication==0)&&(obj.PartialAID>63), ...
        'wlan:wlanS1GConfig:InvalidPartialAID',obj.PartialAID);
  end
  
  function validateTravelingPilots(obj)
    %   validateTravelingPilots Validate traveling pilots against NumUsers 
    %   and NumSTS for wlanS1GConfig configuration object
    %   Validated property-subset includes:
    %       TravelingPilots, NumUsers, NumSpaceTimeStreams, STBC
    
    if (obj.TravelingPilots==true)
        coder.internal.errorIf(obj.NumUsers>1, ...
            'wlan:wlanS1GConfig:InvalidTravelingPilotsMultiUser');
        coder.internal.errorIf(((sum(obj.NumSpaceTimeStreams)>2) || ...
            ((sum(obj.NumSpaceTimeStreams)==2)&&(obj.STBC==false))), ...
            'wlan:wlanS1GConfig:InvalidTravelingPilotsNumSTS')
    end
  end
  
  % PSDU_LENGTH, TXTIME, NSYM and NPAD calculations in Section 24.4.3 IEEE
  % P802.11ah/D5.0
  %   PSDU_LENGTH is the length of the PSDU to transmit in octets
  %   TXTIME is the transmission time in microseconds
  %   NSYM is the number of OFDM data symbols
  %   NPAD is the number of padding bits
  function [PSDU_LENGTH,TXTIME,NSYM,NPAD] = plmeTXTIMEPrimitive(obj)
      
    % Set output structure
    numUsers = obj.NumUsers;         
    mcsTable = wlan.internal.getRateTable(obj);
    NDBPS = mcsTable.NDBPS;
    NES = mcsTable.NES;
    
    APEPLen = repmat(obj.APEPLength,1,numUsers/length(obj.APEPLength)); 
    
    % Calculate number of OFDM symbols
    if isscalar(APEPLen) && all(APEPLen==0) % NDP 
        NSYM = 0;
        PSDU_LENGTH = 0;
        NPAD = 0;
    else
        mSTBC = (numUsers==1)*(obj.STBC~=0)+1; 
        Nservice = 8; % Table 24-4
        Ntail = 6;    % Table 24-4

        % S1G SU/MU PPDU using BCC encoding
        NSYM = max(mSTBC*ceil((8*APEPLen+Nservice+Ntail*NES)./(mSTBC*NDBPS))); % 24-7
        PSDU_LENGTH = floor((NSYM*NDBPS-Nservice-Ntail*NES)/8); % 24-76/78
        NPAD = NSYM*NDBPS-(8*PSDU_LENGTH+Nservice+Ntail*NES); % Section 24.3.9.4.3.2
    end
    
    % Table 24-4 common to all bandwidths, in microseconds
    TSYML = 40;
    TSYMS = 36;
    TDSTF = 40;
    TLTF  = 40;
    TDLTF = 40;
    TSIGA = 80;
    TSIGB = 40;

    % Simplify the number of equations by calculating the length of the
    % data field given the GI and number of symbols
    if NSYM>0
        if strcmp(obj.GuardInterval,'Long')
            TDATA = NSYM*TSYML;
        else % 'Short'
            TDATA = TSYML+TSYMS*(NSYM-1);
        end
    else
        TDATA = 0; % NDP
    end
    
    % Calculate burst time
    NLTF = wlan.internal.numVHTLTFSymbols(sum(obj.NumSpaceTimeStreams));
    if strcmp(obj.ChannelBandwidth,'CBW1')
        % Table 24-4 for 1 MHz, in microseconds
        TSTF  = 160;
        TLTF1 = 160;
        TSIG  = 240;
        TXTIME = TSTF+TLTF1+TSIG+TLTF*(NLTF-1)+TDATA;
    else % {'CBW2','CBW4','CBW8','CBW16'}
        % Table 24-4 for >=2 MHz, in microseconds
        TSTF  = 80;
        TLTF1 = 80;
        TSIG  = 80;
        if strcmp(obj.Preamble,'Short')
            TXTIME = TSTF+TLTF1+TSIG+TLTF*(NLTF-1)+TDATA;
        else % 'Long'
            TXTIME = TSTF+TLTF1+TSIGA+TDSTF+TDLTF*NLTF+TSIGB+TDATA;
        end
    end
  end
 
  function [isUndefined,varargout] = isPSDULengthUndefined(obj,mode)
  % Returns 1 if the object is in a state in which PSDULength cannot be
  % calculated and therefore is undefined. Additionally returns the message
  % catalog ID and arguments for the error/warning. Mode determines whether
  % an error is thrown 'error', a warning is thrown 'warn' or nothing is
  % thrown 'no action' when validating properties relevant to calculate the
  % PSDULength.
    if isempty(coder.target)
        % Only return msg character vector when not generating code. We
        % cannot obtain message from the catalog in codegen, but this is
        % not a problem as it is only used for object disp() which is not
        % supported in codegen.
        [isvalid,msg] = validateForPSDULengthCalculation(obj,mode);
        varargout{1} = msg;
    else
        % Codegen case, only return if the PSDU is valid
        isvalid = validateForPSDULengthCalculation(obj,mode);
    end
    isUndefined = ~isvalid;
  end
  
  function [isValid,msg] = validateForPSDULengthCalculation(obj,mode)
  %validateForPSDULengthCalculation Validate properties relevant to
  % PSDULength calculation; returns true if PSDULength can be calculated.
  % The mode determines the action taken during validation:
  %   Mode is 'error': throw an error 
  %   Mode is 'warn': throw a warning
  %   Mode is 'no action': return the message catalog entry for the first 
  %                        invalid condition, or an empty if no invalid 
  %                        condition. 
    
    numUsers = obj.NumUsers;
    
    % Test if MU when mode is not S1G-LONG
    [isValid,msg] = wlan.internal.testErrorCondition(numUsers>1 && ~strcmp(packetFormat(obj),'S1G-Long'), ...
        mode,'wlan:wlanS1GConfig:InvalidModeForMU');  
    if ~isValid
        return;
    end
    
    % Test is the number of space-time streams is not defined for each user
    [isValid,msg] = wlan.internal.testErrorCondition((length(obj.NumSpaceTimeStreams) ~= obj.NumUsers), ...
        mode,'wlan:shared:InvalidSTSNumUsers');
    if ~isValid
        return;
    end
    
    % Test if an MCS is not defined for each user
    [isValid,msg] = wlan.internal.testErrorCondition((all(length(obj.MCS) ~= [1 numUsers])), ...
        mode,'wlan:shared:InvalidMCSNumUsers');
    if ~isValid
        return;
    end
    
    % Test if an APEPLength is not defined for each user
    [isValid,msg] = wlan.internal.testErrorCondition((all(length(obj.APEPLength) ~= [1 numUsers]) || ((numUsers > 1) && any(obj.APEPLength == 0))), ...
        mode,'wlan:shared:InvalidAPEPLenNumUsers');
    if ~isValid
        return;
    end
            
    % Test if the number of space-time streams is odd when STBC is used for SU
    [isValid,msg] = wlan.internal.testErrorCondition(((numUsers == 1) && obj.STBC && all(mod(obj.NumSpaceTimeStreams, 2) == 1)), ...
        mode,'wlan:shared:OddNumSTSWithSTBC');
    if ~isValid
        return;
    end
    
    % Test if MCS10 used when not 1MHz and 1 SS
    [isValid,msg] = wlan.internal.testErrorCondition(~isValidMCS10(obj), ...
        mode,'wlan:wlanS1GConfig:InvalidMCS10');
    if ~isValid
        return;
    end

    % Test if MCS12 used for 2MHz and 1/2/4 SS
    [isValid,msg] = wlan.internal.testErrorCondition(~isValidMCS12(obj), ...
        mode,'wlan:wlanS1GConfig:InvalidMCS12');
    if ~isValid
        return;
    end

    % Check Bandwidth/MCS/Nss valid combinations
    %   Reference: Tables 24-38:24-57, IEEE P802.11ah/D5.0
    invalidComb = ...
          [2, 9, 1; ... % [chanBW, MCS, numSS]
           2, 9, 2; ...
           2, 9, 4];
    chanBW = wlan.internal.cbwStr2Num(obj.ChannelBandwidth); % MHz
    vecMCS = repmat(obj.MCS,1,numUsers/length(obj.MCS));
    numSS  = obj.NumSpaceTimeStreams/(((numUsers==1)&&obj.STBC)+1);
    for u = 1:numUsers
        thisComb = [chanBW vecMCS(u) numSS(u)];
        [isValid,msg] = wlan.internal.testErrorCondition(any(all(thisComb==invalidComb,2)), ...
             mode,'wlan:shared:InvalidMCSCombination', ...
             ['''', obj.ChannelBandwidth, ''''], obj.NumSpaceTimeStreams(u), vecMCS(u), u);
        if ~isValid
            return;
        end
    end
  end
  
end

end

