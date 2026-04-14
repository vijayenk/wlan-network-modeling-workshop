classdef wlanVHTConfig < comm.internal.ConfigBase
%wlanVHTConfig Create a very high throughput (VHT) format configuration object
%   CFGVHT  = wlanVHTConfig creates a very high throughput format
%   configuration object. This object contains the transmit parameters for
%   the VHT format of IEEE 802.11 standard.
%
%   CFGVHT = wlanVHTConfig(Name,Value) creates a VHT object, CFGVHT, with
%   the specified property Name set to the specified value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanVHTConfig methods:
%
%   packetFormat - VHT packet format
%   transmitTime - Time required to transmit a packet
%
%   wlanVHTConfig properties:
%
%   ChannelBandwidth     - Channel bandwidth 
%   NumUsers             - Number of users
%   UserPositions        - User positions
%   NumTransmitAntennas  - Number of transmit antennas
%   PreVHTCyclicShifts   - Cyclic shift values for >8 transmit chains
%   NumSpaceTimeStreams  - Number of space-time streams 
%   SpatialMapping       - Spatial mapping scheme
%   SpatialMappingMatrix - Spatial mapping matrix(ces)
%   Beamforming          - Enable beamforming
%   STBC                 - Enable space-time block coding
%   MCS                  - Modulation and coding schemes
%   ChannelCoding        - Channel coding
%   APEPLength           - APEP lengths
%   PSDULength           - Number of bytes to be coded in the packet 
%                          including the A-MPDU and any MAC padding
%   GuardInterval        - Guard interval type
%   GroupID              - Group identifier
%   PartialAID           - Partial association identifier 

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen
    
properties (Access = 'public')
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80'
    %   | 'CBW160'. The default value of this property is 'CBW80'.
    ChannelBandwidth = 'CBW80';
    %NumUsers Number of users
    %   Specify the number of users as an integer scalar between 1 and 4,
    %   inclusive. The default value of this property is 1.
    NumUsers = 1;
    %UserPositions User positions
    %   Specify the user positions as an integer row vector with length
    %   equal to NumUsers and elements between 0 and 3, inclusive, in a
    %   strictly increasing order. This property applies when you set the
    %   NumUsers property to 2, 3 or 4. The default value of this property
    %   is [0 1].
    UserPositions = [0 1];
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a numeric, positive
    %   integer scalar. The default is 1.
    NumTransmitAntennas = 1;
    %PreVHTCyclicShifts Cyclic shift values for >8 transmit chains
    %   Specify the cyclic shift values for the pre-VHT portion of the
    %   waveform, in nanoseconds for >8 transmit antennas as a row vector
    %   of length L = NumTransmitAntennas-8. The cyclic shift values must
    %   be between -200 and 0 inclusive. The first 8 antennas use the
    %   cyclic shift values defined in Table 21-10 of IEEE Std 802.11-2016.
    %   The remaining antennas use the cyclic shift values defined in this
    %   property. If the length of this row vector is specified as a value
    %   greater than L the object only uses the first L, PreVHTCyclicShifts
    %   values. For example, if you specify the NumTransmitAntennas
    %   property as 16 and this property as a row vector of length N>L, the
    %   object only uses the first L = 16-8 = 8 entries. This property
    %   applies only when you set the NumTransmitAntennas property to a
    %   value greater than 8. The default value of this property is -75.
    PreVHTCyclicShifts {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(PreVHTCyclicShifts,-200), mustBeLessThanOrEqual(PreVHTCyclicShifts,0)} = -75;
    %NumSpaceTimeStreams Number of space-time streams per user
    %   Specify the number of space-time streams as integer scalar or row
    %   vector with length equal to NumUsers. For a scalar, it must be
    %   between 1 and 8, inclusive. For a row vector, all elements must be
    %   between 1 and 4, inclusive, and sum to no larger than 8. The
    %   default value of this property is 1.
    NumSpaceTimeStreams = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' | 'Hadamard'
    %   | 'Fourier' | 'Custom'. The default value of this property is
    %   'Direct', which applies when the sum of the elements in
    %   NumSpaceTimeStreams is equal to NumTransmitAntennas.
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
    %   determined by the ChannelBandwidth property. Specifically, Nst is
    %   56 for 'CBW20', 114 for 'CBW40', 242 for 'CBW80' and 484 for
    %   'CBW160'. In this case, each occupied subcarrier can have its own
    %   spatial mapping matrix. In either 2D or 3D case, the spatial
    %   mapping matrix for each subcarrier is normalized. The default value
    %   of this property is 1.
    SpatialMappingMatrix = 1;
    %Beamforming Enable beamforming
    %   Set this property to true when the specified SpatialMappingMatrix
    %   property is a beamforming steering matrix(ces). This property
    %   applies when you set the NumUsers property to 1 and the
    %   SpatialMapping property to 'Custom'. The default value of this
    %   property is true.
    Beamforming (1,1) logical = true;
    %STBC Enable space-time block coding
    %   Set this property to true to enable space-time block coding in the
    %   data field transmission. This property applies when you set the
    %   NumUsers property to 1. The default value of this property is
    %   false.
    STBC (1,1) logical = false;
    %MCS Modulation and coding scheme per user 
    %   Specify the modulation and coding scheme per user as an integer
    %   scalar or row vector with length equal to NumUsers. Its elements
    %   must be integers between 0 and 9, inclusive. A scalar value applies
    %   to all users. The default value of this property is 0.
    MCS = 0;
    %ChannelCoding Forward error correction coding type
    %   Specify the channel coding as one of 'BCC' or 'LDPC' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding. The default is 'BCC'. For single-user, or all users in a
    %   multi-user transmission, a character vector or string scalar
    %   defines the channel coding type. For a multi-user transmission a
    %   cell array or string vector defines the different channel coding
    %   types.
    ChannelCoding = 'BCC';
end

properties (SetAccess = 'public')  
    %APEPLength APEP length per user
    %   Specify the APEP length in bytes per user as an integer scalar or
    %   row vector with length equal to NumUsers. A scalar value applies to
    %   all users. All elements must be integers between 1 and 1048575,
    %   inclusive. In addition, this property can be 0 when the NumUsers
    %   property is 1, which implies a VHT non-data-packet (NDP). The
    %   default value of this property is 1024.
    APEPLength = 1024;
end

properties (SetAccess = private, GetAccess = public)
    %PSDULength PSDU lengths
    %   The number of bytes carried in a packet, including the A-MPDU and
    %   any MAC padding. This property is read-only and is calculated
    %   internally based on other properties.
    PSDULength;
end

properties (Access = 'public') 
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) type for data field
    %   transmission as one of 'Long' | 'Short'. The default value of this
    %   property is 'Long'.
    GuardInterval = 'Long';
    %GroupID Group identifier
    %   Specify the group identifier as an integer scalar. It must be 0 or
    %   63 when the NumUsers property is 1 and must be between 1 and 62
    %   inclusive when the NumUsers property is 2, 3 or 4. The default
    %   value of this property is 63.
    GroupID = 63;
    %PartialAID Partial association identifier 
    %   Specify the partial association identifier of the intended
    %   recipient as an integer scalar between 0 and 511, inclusive. This
    %   property applies when you set the NumUsers property to 1. For an
    %   uplink transmission, it is the last nine bits of the BSSID. For a
    %   downlink transmission, it combines the association ID and the BSSID
    %   of its serving AP. The default value of this property is 275.
    PartialAID = 275;
end

properties(Constant, Hidden)
    ChannelBandwidth_Values  = {'CBW20','CBW40','CBW80','CBW160'};
    SpatialMapping_Values    = {'Direct','Hadamard','Fourier','Custom'};
    GuardInterval_Values     = {'Short','Long'};
    ChannelCoding_Values     = {'BCC','LDPC'};
end

methods
  function obj = wlanVHTConfig(varargin)
    % For codegen set maximum dimensions to force varsize
    if ~isempty(coder.target)
        channelBandwidth = 'CBW80';
        coder.varsize('channelBandwidth',[1 6],[0 1]); % Add variable-size support
        obj.ChannelBandwidth = channelBandwidth; % Default

        spatialMapping = 'Direct';
        coder.varsize('spatialMapping',[1 8],[0 1]); % Add variable-size support
        obj.SpatialMapping = spatialMapping; % Default

        guardInterval = 'Long';
        coder.varsize('guardInterval',[1 5],[0 1]); % Add variable-size support
        obj.GuardInterval = guardInterval; % Default
    end
    obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
  end

  function obj = set.ChannelBandwidth(obj,val)
    propName = 'ChannelBandwidth';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.NumUsers(obj, val)
    propName = 'NumUsers';
    validateattributes(val, {'numeric'}, {'real','integer','scalar','>=',1,'<=',4}, [class(obj) '.' propName], propName); 
    obj.(propName)= val;
  end

  function obj = set.UserPositions(obj, val)
    propName = 'UserPositions';
    validateattributes(val, {'numeric'}, {'real','integer','row','>=',0,'<=',3,'increasing'}, [class(obj) '.' propName], propName);
    obj.(propName) = val;                
  end

  function obj = set.NumTransmitAntennas(obj, val)
    propName = 'NumTransmitAntennas';
    validateattributes(val, {'numeric'}, {'real','integer','scalar','>=',1}, [class(obj) '.' propName], propName);
    obj.(propName) = val;
  end

  function obj = set.NumSpaceTimeStreams(obj, val)
    propName = 'NumSpaceTimeStreams';
    validateattributes(val, {'numeric'}, {'real','integer','row','>=',1,'<=',8}, [class(obj) '.' propName], propName);
    coder.internal.errorIf(~isscalar(val) && ((length(val) > 4) || any(val > 4) || sum(val) > 8), 'wlan:shared:InvalidMUSTS', 4, 4, 8); 
    obj.(propName) = val;
  end

  function obj = set.SpatialMapping(obj, val)
    propName = 'SpatialMapping';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.SpatialMappingMatrix(obj, val)
    propName = 'SpatialMappingMatrix';
    validateattributes(val, {'double'}, {'3d','finite','nonempty'}, [class(obj) '.' propName], propName); 

    is3DFormat = (ndims(val) == 3) || (iscolumn(val) && ~isscalar(val));
    numSTS = size(val, 1+is3DFormat);
    numTx  = size(val, 2+is3DFormat);
    numST = [56 114 242 484]; % Total number of occupied subcarriers
    errStr = sprintf('%u ', numST); % Convert to char array of elements with trailing space
    errStr = ['[' errStr(1:end-1) ']']; % Remove last trailing space
    coder.internal.errorIf((is3DFormat && ~any(size(val, 1) == numST)) || (numSTS > 8) || (numSTS > numTx), ...
        'wlan:shared:InvalidSpatialMapMtxDim', errStr);

    obj.(propName) = val;
  end
  
  function obj = set.MCS(obj, val)
    propName = 'MCS';
    validateattributes(val, {'numeric'}, {'real','integer','row','>=',0,'<=',9}, [class(obj) '.' propName], propName);

    coder.internal.errorIf(length(val) > 4, 'wlan:shared:InvalidMUMCS', 4);

    obj.(propName) = val;
  end
  
  function obj = set.ChannelCoding(obj, val)
    propName = 'ChannelCoding';
    
    if iscell(val)
        % Cell array
        coder.internal.errorIf((length(val) > 4) || isempty(val), 'wlan:wlanVHTConfig:InvalidChCoding');
        valProp = coder.nullcopy(cell(size(val)));
        for u = 1:length(val)
            coder.internal.errorIf(isstring(val{u}), 'wlan:ConfigBase:InvalidEnumValue', 'ChannelCoding', '''BCC'' and ''LDPC''');
            valProp{u} = validateEnumProperties(obj, propName, val{u});
        end
        obj.(propName) = valProp;
    elseif isstring(val) && numel(val)>1
        % String vector
        coder.internal.errorIf((length(val) > 4) || isempty(val), 'wlan:wlanVHTConfig:InvalidChCoding');
        valChar = convertStringsToChars(val);
        for u = 1:length(val)
            valChar{u} = validateEnumProperties(obj, propName, valChar{u});
        end
        obj.(propName) = valChar;
    else 
        % Character vector or string scalar
        valChar = validateEnumProperties(obj, propName, val);
        obj.(propName) = '';
        obj.(propName) = valChar;
    end
  end

  function obj = set.APEPLength(obj, val)
    propName = 'APEPLength';
    maxBytes = 1048575; % Maximum number of bytes
    validateattributes(val, {'numeric'}, {'real','integer','row','>=',0,'<=',maxBytes}, [class(obj) '.' propName], propName);

    coder.internal.errorIf(~isscalar(val) && ((length(val) > 4) || any(val == 0)), 'wlan:shared:InvalidMUAPEPLen', 4);

    obj.(propName) = val;
  end

  function obj = set.GuardInterval(obj, val)
    propName = 'GuardInterval';
    val = validateEnumProperties(obj, propName, val);
    obj.(propName) = val;
  end

  function obj = set.GroupID(obj, val)
    propName = 'GroupID';
    validateattributes(val, {'numeric'}, {'real','scalar','integer','>=',0,'<=',63}, [class(obj) '.' propName], propName);
    obj.(propName) = val;
  end

  function obj = set.PartialAID(obj, val)
    propName = 'PartialAID';
    validateattributes(val, {'numeric'}, {'real','scalar','integer','>=',0,'<=',511}, [class(obj) '.' propName], propName);
    obj.(propName) = val;
  end

  function PSDULen = get.PSDULength(obj)
    % Returns PSDU length in bytes for all users
    if isPSDULengthUndefined(obj,'warn')
        PSDULen = zeros(1,0);
    else
        s = privInfo(obj);
        PSDULen = s.PSDULength;
    end
  end

  function format = packetFormat(obj) %#ok<MANU>
      %packetFormat Returns the packet format
      %   Returns the packet format as a character vector
      format = 'VHT';
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
    t = wlan.internal.convertTransmitTime(s.TxTime,varargin{:});
  end

  function varargout = validateConfig(obj, varargin)
    % validateConfig Validate the wlanVHTConfig object
    %   validateConfig(CFGVHT) validates the dependent properties for the
    %   specified wlanVHTConfig configuration object.
    % 
    %   For INTERNAL use only, subject to future changes:
    %
    %   validateConfig(CFGVHT, MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'SpatialMCSGID'
    %       'SMapping'
    %       'MCS'
    %       'MCSSTSTx'
    %       'SMappingMCS'

    narginchk(1,2);
    nargoutchk(0,1);
    if (nargin==2)
        mode = varargin{1};
    else
        mode = 'Full';
    end

    switch mode
        case 'SpatialMCSGID'    % VHT-SIG-A
            validateSpatial(obj);
            s = validateMCSLengthTxTime(obj);
            validateGIDAndUserPos(obj);
            
        case 'SMapping'     % VHT-STF, VHT-LTF
            validateSpatialMapping(obj);
            
        case 'MCS'          % wlanVHTDataRecover
            s = validateMCSLengthTxTime(obj);
            
        case 'MCSSTSTx'     % L-SIG
            validateSTSTx(obj);
            s = validateMCSLengthTxTime(obj);
            
        case 'SMappingMCS'  % VHT-SIG-B, VHT-Data
            validateSpatialMapping(obj);
            s = validateMCSLengthTxTime(obj);
            
        case 'CyclicShift'
            % Validate PreVHTCyclicShifts values against NumTransmitAntennas
            validatePreVHTCyclicShifts(obj);
            
        otherwise           % wlanWaveformGenerator
            % Full object validation
            validateSpatialMapping(obj);
            validatePreVHTCyclicShifts(obj);
            s = validateMCSLengthTxTime(obj);
            validateGIDAndUserPos(obj);
    end

    if nargout == 1
        varargout{1} = s;
    end                        
  end

end   

methods (Access = protected)
  function flag = isInactiveProperty(obj, prop)
    flag = false;
    if any(strcmp(prop, {'STBC', 'PartialAID'}))
        flag = (obj.NumUsers > 1);
    elseif strcmp(prop, 'UserPositions')
        flag = (obj.NumUsers == 1);
    elseif strcmp(prop, 'SpatialMappingMatrix')
        flag = ~strcmp(obj.SpatialMapping, 'Custom');
    elseif strcmp(prop, 'Beamforming')
        flag = (obj.NumUsers > 1) || ~strcmp(obj.SpatialMapping, 'Custom');
    elseif strcmp(prop, 'PreVHTCyclicShifts')
        flag = obj.NumTransmitAntennas<=8;
    end
  end
  
  function [flag,msg] = isUndefinedProperty(obj, prop)
      % Returns true and the associated message catalog entry if the
      % property value is undefined in the current state
      flag = false;
      msg = '';
      if strcmp(prop, 'PSDULength')
          [flag,msg] = isPSDULengthUndefined(obj,'no action'); % Do not throw error or warning
      end
  end
    
end

methods (Access = private)
  function s = privInfo(obj)
    %privInfo Returns information relevant to the object
    %   S = privInfo(cfgVHT) returns a structure, S, containing the
    %   relevant information for the wlanVHTConfig object, cfgVHT.
    %   The output structure S has the following fields:
    %
    %   NumDataSymbols   - Number of OFDM symbols for the Data field
    %   NumPadBits       - Number of pad bits in the Data field
    %   NumPPDUSamples   - Number of PPDU samples per transmit antennas
    %   TxTime           - The time in microseconds, required to
    %                      transmit the PPDU.
    %   PSDULength       - The number of bytes carried in a packet,
    %                      including the A-MPDU and any MAC padding.
    %   ExtraLDPCSymbol  - An indication of an extra OFDM symbol added due
    %                      to LDPC encoding.

    numUsers = obj.NumUsers;
    APEPLen  = repmat(obj.APEPLength, 1, numUsers/length(obj.APEPLength));            
    mcsTable = wlan.internal.getRateTable(obj);
    numDBPS  = mcsTable.NDBPS;
    numES    = mcsTable.NES;
    rate     = mcsTable.Rate;
    mSTBC = (numUsers == 1)*(obj.STBC ~= 0) + 1;
    
    LDPCSymbol = 0;
    numDataBCCsymbols = 0;
    
    % Calculate number of OFDM symbols
    if isscalar(obj.APEPLength) && (obj.APEPLength(1) == 0) % NDP 
        numDataSymbols = 0;
        numPadBits = 0;
        PSDULen = 0;
    else
        % Get ChannelCoding property to a cell
        channelCoding = getChannelCoding(obj);
        
        userCodingIndex = zeros(1,numUsers); 
        for u=1:numUsers
            userCodingIndex(u) = strcmp(channelCoding{u}, 'BCC');
        end
        userCodingVector = 1:numUsers;
        indBCC  = userCodingVector(userCodingIndex == 1);
        indLDPC = userCodingVector(userCodingIndex == 0);
        
        PSDULen    = zeros(1,numUsers);
        numPadBits = zeros(1,numUsers);
        
        numSymbolsLDPC = zeros(1,numUsers);
        numDataSymbols = 0;
        numTailBits    = 6; % For BCC encoding
        
        if ~isempty(indBCC)
            numDataSymbols = max(mSTBC*ceil((8*APEPLen(indBCC) + 16 + numTailBits*numES(indBCC))./(mSTBC.*numDBPS(indBCC))));
            PSDULen(indBCC) = floor((numDataSymbols*numDBPS(indBCC) - 16 - numTailBits*numES(indBCC))./8);
            numPadBits(indBCC) = numDataSymbols*numDBPS(indBCC) - (8*PSDULen(indBCC) + 16 + numTailBits*numES(indBCC));
            numDataBCCsymbols = numDataSymbols;
        end

        if ~isempty(indLDPC)
            % LDPC encoding parameters as defined in IEEE Std 802.11-2012,
            % IEEE Std 802.11ac-2013
            numSymbolsLDPC(indLDPC) = mSTBC * ceil((8*APEPLen(indLDPC) + 16)./(mSTBC * numDBPS(indLDPC))); % Eq 22-64
            numSymMaxInit = max([numDataSymbols,numSymbolsLDPC(indLDPC)]);                                 % Eq 22-65-MU, Eq 22-62-SU
            PSDULen(indLDPC) = floor((numSymMaxInit * numDBPS(indLDPC) - 16)./8);                          % Eq 22-114 
            numPadBits(indLDPC) = numSymMaxInit.*numDBPS(indLDPC) - 8*PSDULen(indLDPC) - 16;               % Eq 22-57, Eq 22-58
            numSymbol = zeros(1, size(indLDPC,2));

            for u = 1:size(indLDPC,2)
                numPLD = numSymMaxInit*numDBPS(indLDPC(u));
                cfg = wlan.internal.getLDPCparameters(numDBPS(indLDPC(u)), rate(indLDPC(u)), mSTBC, numPLD); 
                numSymbol(u) = cfg.NumSymbol; % Eq 22-67
            end
            
            if max(numSymbol)>numSymMaxInit
                numDataSymbols = max(numSymbol);
                LDPCSymbol = 1;
            else 
                numDataSymbols = max(numSymMaxInit);
            end
        end
  
        % Update BCC length and padded bits for BCC
        if ~isempty(indBCC)  && (numDataSymbols ~= numDataBCCsymbols)
            % Recalculate PSDU length Eq: 22-114
            PSDULen(indBCC) = floor((numDataSymbols.*numDBPS(indBCC) - 16 - numTailBits*numES(indBCC))./8);
            numPadBits(indBCC) = numDataSymbols.*numDBPS(indBCC) - (8*PSDULen(indBCC) + 16 + numTailBits*numES(indBCC));
        end
    end
    
    % Calculate burst time
    numPreambSym = 4 + 1 + 2 + 1 + wlan.internal.numVHTLTFSymbols(sum(obj.NumSpaceTimeStreams)) + 1;            
    FFTLen = 64 * wlan.internal.cbwStr2Num(obj.ChannelBandwidth)/20;
    if strcmp(obj.GuardInterval, 'Short')
        txTime = 4*numPreambSym + 4*ceil(numDataSymbols*3.6/4);
        numPPDUSamples = numPreambSym*FFTLen*5/4 + numDataSymbols*FFTLen*9/8;
    else
        txTime = 4*numPreambSym + 4*numDataSymbols;
        numPPDUSamples = (numPreambSym + numDataSymbols)*FFTLen*5/4;
    end 
    
    % Set output structure
    s = struct(...
        'NumDataSymbols',  numDataSymbols, ... % Eq 22-67
        'NumPadBits',      numPadBits, ...
        'NumPPDUSamples',  numPPDUSamples, ...
        'TxTime',          txTime, ...
        'PSDULength',      PSDULen, ...
        'ExtraLDPCSymbol', LDPCSymbol);  
  end

  function validateSTSTx(obj)
    %   ValidateSTSTx Validate NumTransmitAntennas, NumSpaceTimeStreams
    %   properties for wlanVHTConfig object

    % NumTx and Nsts: numTx cannot be less than sum(Nsts)
    coder.internal.errorIf(obj.NumTransmitAntennas < sum(obj.NumSpaceTimeStreams), 'wlan:shared:NumSTSLargerThanNumTx');
  end

  function validateSpatial(obj)
    %   validateSpatial Validate the spatial properties for the 
    %   wlanVHTConfig object
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams, SpatialMapping

    validateSTSTx(obj);

    coder.internal.errorIf(strcmp(obj.SpatialMapping, 'Direct') && (sum(obj.NumSpaceTimeStreams) ~= obj.NumTransmitAntennas), 'wlan:shared:NumSTSNotEqualNumTxDirectMap');            
  end        
  
  function validateSpatialMapping(obj)
    %   validateSpatialMapping Validate the spatial mapping properties for
    %   the wlanVHTConfig object    
    %   Validated property-subset includes:
    %     ChannelBandwidth, NumTransmitAntennas, NumSpaceTimeStreams, ..
    %     SpatialMapping, SpatialMappingMatrix

    validateSpatial(obj);

    if strcmp(obj.SpatialMapping, 'Custom')
        % Validate spatial mapping matrix
        SPMtx = obj.SpatialMappingMatrix;
        is3DFormat  = (ndims(SPMtx) == 3) || (iscolumn(SPMtx) && ~isscalar(SPMtx));
        numSTSTotal = size(SPMtx, 1+is3DFormat);
        numTx       = size(SPMtx, 2+is3DFormat);
        switch obj.ChannelBandwidth
          case 'CBW20'
            numST = 56;
          case 'CBW40'
            numST = 114;
          case 'CBW80'
            numST = 242;
          otherwise
            numST = 484;
        end
        coder.internal.errorIf((is3DFormat && (size(SPMtx, 1) ~= numST)) || (numSTSTotal ~= sum(obj.NumSpaceTimeStreams))  || (numTx ~= obj.NumTransmitAntennas), ...
            'wlan:shared:MappingMtxNotMatchOtherProp', sum(obj.NumSpaceTimeStreams), obj.NumTransmitAntennas, numST);
    end            
  end 
  
  function s = validateMCSLengthTxTime(obj)
    %ValidateMCSLength Validate MCS and Length properties and resultant
    %   TxTime for wlanVHTConfig configuration object
    %   Validated property-subset includes:   
    %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, GuardInterval, APEPLength

    % Validate properties for PSDULength calculation
    validateForPSDULengthCalculation(obj,'error');
    
    % Validate PSDULength for TxTime (max 5.484ms for VHT format)
    s = privInfo(obj);
    coder.internal.errorIf(s.TxTime>5484, 'wlan:shared:InvalidPPDUDuration', round(s.TxTime), 5484);
    
  end
   
  function validateGIDAndUserPos(obj)
    %   validateGIDAndUserPos Validate UserPositions and GroupID against
    %   NumUsers for wlanVHTConfig object.    
    %   Validated property-subset includes:
    %       NumUsers, UserPositions, GroupID

    coder.internal.errorIf((obj.NumUsers > 1) && (length(obj.UserPositions) ~= obj.NumUsers), 'wlan:shared:InvalidUserPosNumUsers');

    coder.internal.errorIf(xor((obj.NumUsers == 1), any(obj.GroupID == [0 63])), 'wlan:wlanVHTConfig:InvalidGIDNumUsers');
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
  
  function [isValid,msg] = validateForPSDULengthCalculation(obj, mode)
  %validateForPSDULengthCalculation Validate properties relevant to
  % PSDULength calculation; returns true if PSDULength can be calculated.
  % The mode determines the action taken during validation:
  %   Mode is 'error': throw an error 
  %   Mode is 'warn': throw a warning
  %   Mode is 'no action': return the message catalog entry for the first 
  %                        invalid condition, or an empty if no invalid 
  %                        condition. 
    
    numUsers = obj.NumUsers;

    % Test if channel coding as a cell array or string vector is not specified for each user
    [isValid,msg] = wlan.internal.testErrorCondition((iscell(obj.ChannelCoding) && (length(obj.ChannelCoding) ~= obj.NumUsers) && ~isscalar(obj.ChannelCoding)), ...
        mode, 'wlan:wlanVHTConfig:InvalidChCoding');  
    if ~isValid
        return;
    end
    
    % Test is the number of space-time streams is not defined for each user
    [isValid,msg] = wlan.internal.testErrorCondition((length(obj.NumSpaceTimeStreams) ~= obj.NumUsers), ...
        mode, 'wlan:shared:InvalidSTSNumUsers');
    if ~isValid
        return;
    end
        
    % Test if the number of space-time streams is odd when STBC is used for SU
    [isValid,msg] = wlan.internal.testErrorCondition(((numUsers == 1) && obj.STBC && all(mod(obj.NumSpaceTimeStreams, 2) == 1)), ...
        mode, 'wlan:shared:OddNumSTSWithSTBC');
    if ~isValid
        return;
    end
    
    % Test if an MCS is not defined for each user
    [isValid,msg] = wlan.internal.testErrorCondition((all(length(obj.MCS) ~= [1 numUsers])), ...
        mode, 'wlan:shared:InvalidMCSNumUsers');
    if ~isValid
        return;
    end
    
    % Test if an APEPLength is not defined for each user
    [isValid,msg] = wlan.internal.testErrorCondition((all(length(obj.APEPLength) ~= [1 numUsers]) || ((numUsers > 1) && any(obj.APEPLength == 0))), ...
        mode, 'wlan:shared:InvalidAPEPLenNumUsers');
    if ~isValid
        return;
    end
    
    % Test Bandwidth/MCS/Nss valid combinations
    %   Reference: Tables 22-30:22-56, IEEE Std 802.11ac-2013
    invalidComb = ...
          [20,  9, 1; ... % [chanBW, MCS, numSS]
           20,  9, 2; ...
           20,  9, 4; ...
           20,  9, 5; ...
           20,  9, 7; ...
           20,  9, 8; ...
           80,  6, 3; ...
           80,  6, 7; ...
           80,  9, 6; ...
           160, 9, 3];           
    chanBW = wlan.internal.cbwStr2Num(obj.ChannelBandwidth); 
    vecMCS = repmat(obj.MCS, 1, numUsers/length(obj.MCS));
    numSS  = obj.NumSpaceTimeStreams / (((numUsers == 1) && obj.STBC) + 1);
    for u = 1:numUsers
        thisComb = [chanBW, vecMCS(u), numSS(u)];
        [isValid,msg] = wlan.internal.testErrorCondition(any(all(thisComb==invalidComb, 2)), mode, ...
            'wlan:shared:InvalidMCSCombination', ['''', char(obj.ChannelBandwidth), ''''], obj.NumSpaceTimeStreams(u), vecMCS(u), u);
        if ~isValid
            return;
        end
    end
    
  end
  
  function validatePreVHTCyclicShifts(obj)
    %   validatePreVHTCyclicShifts Validate PreVHTCyclicShifts values against
    %   NumTransmitAntennas
    %   Validated property-subset includes:
    %       PreVHTCyclicShifts, NumTransmitAntennas

    numTx = obj.NumTransmitAntennas;
    csh = obj.PreVHTCyclicShifts;
    if numTx>8
        coder.internal.errorIf(~(numel(csh)>=numTx-8),'wlan:shared:InvalidCyclicShift','PreVHTCyclicShifts',numTx-8);
    end
  end

end

methods (Access = public)
function channelCoding = getChannelCoding(obj)
    % Initialize to max number of users
    coder.varsize('channelCoding',[1,4]); 
    if ischar(obj.ChannelCoding)
        % Repeat scalar channel coding for all users as cell array
        channelCoding = repmat({obj.ChannelCoding},1,obj.NumUsers);
    elseif isscalar(obj.ChannelCoding) && iscell(obj.ChannelCoding)
        % Repeat scalar cell array channel coding for all users
        channelCoding = repmat(obj.ChannelCoding,1,obj.NumUsers);
    else
        % Cell array specified for all users
        channelCoding  = obj.ChannelCoding;
    end
end
end

end

