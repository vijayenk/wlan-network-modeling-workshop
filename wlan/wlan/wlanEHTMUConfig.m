classdef wlanEHTMUConfig < comm.internal.ConfigBase
%wlanEHTMUConfig Creates a multi-user Extremely High Throughput (EHT) format configuration object
%   wlanEHTMUConfig object creates both OFDMA and non-OFDMA PPDU types of
%   EHT MU packet format.
%
%   # OFDMA:
%   CFG = wlanEHTMUConfig(AllocationIndex) creates an OFDMA multi-user (MU)
%   extremely high throughput (EHT) format configuration object. This
%   object contains the transmit parameters for an OFDMA EHT MU format of
%   IEEE P802.11be/D5.0.
%
%   AllocationIndex specifies the resource unit (RU) allocation. The
%   allocation defines the number and sizes of RUs and MRUs, and the number
%   of users assigned to each RU and MRU. IEEE P802.11be/D5.0, Table 36-34
%   defines the assignment index for each 20 MHz subchannel.
%
%   AllocationIndex is a vector of integers between 0 and 303 inclusive,
%   excluding validate and disregard indices as defined in Table 36-34 of
%   IEEE P802.11be/D5.0. The length of AllocationIndex must be 1, 2, 4, 8,
%   or 16 defining the assignment for each 20 MHz subchannel in a 20 MHz,
%   40 MHz, 80 MHz, 160 MHz, or 320 MHz channel bandwidth.
%
%   To configure an OFDMA transmission greater than 20 MHz, AllocationIndex
%   must consist of an assignment index for each 20 MHz subchannel. For
%   example, to configure an 80 MHz OFDMA transmission, a numeric row
%   vector with 4 allocation indices is required. You can also signal
%   punctured 20 MHz subchannels in an 80 MHz, 160 MHz, or 320 MHz
%   transmission. To signal a punctured 20 MHz subchannel, set the
%   corresponding element of the AllocationIndex property to 26.
%
%   When the specified AllocationIndex is a 1-by-N vector, for 160 MHz and
%   320 MHz we fill the EHT-SIG content channels with different allocation
%   information per 80 MHz frequency subblock, see the documentation. Where
%   N is the number of 20 MHz subchannels and is 8 for 160 MHz and 16 for
%   320 MHz.
%
%   You can specify the AllocationIndex per 80 MHz frequency subblock as an
%   M-by-N matrix, for 160 MHz and 320 MHz. Where M is the number of 80 MHz
%   frequency subblocks and is 2 for 160 MHz and 4 for 320 MHz. When
%   AllocationIndex is an M-by-N matrix, the 80 MHz frequency subblock (M)
%   AllocationIndex must be equal for all 80 MHz frequency subblocks,
%   see the documentation.
%
%   # Non-OFDMA:
%   CFG = wlanEHTMUConfig(ChannelBandwidth) creates a multi-user (MU)
%   extremely high throughput (EHT) format configuration object. This
%   object contains the transmit parameters for a non-OFDMA single-user EHT
%   MU format transmission.
%
%   ChannelBandwidth is a character vector or string specifying the channel
%   bandwidth and must be 'CBW20' 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%
%   CFG = wlanEHTMUConfig(ChannelBandwidth,...,'NumUsers',X) creates a
%   configuration object for a non-OFDMA EHT MU packet with X number of
%   users. X must be a scalar between 1 and 8 inclusive. When not
%   specified, NumUsers is 1. Once the object is created this property is
%   read only.
%
%   CFG = wlanEHTMUConfig(ChannelBandwidth,...,'PuncturedChannelFieldValue',Y)
%   creates a configuration object for a non-OFDMA EHT MU packet with the
%   puncturing pattern as defined in Table 36-30 of IEEE P802.11be/D5.0. Y
%   must be a scalar between 0 and 24 inclusive. When not specified,
%   PuncturedChannelFieldValue is set to zero, which indicates no
%   puncturing. Once the object is created this property is read only.
%
%   CFG = wlanEHTMUConfig(ChannelBandwidth,...,'EHTDUPMode',true) creates a
%   configuration object for an EHT DUP (MCS-14) single-user, 80 MHz, 160
%   MHz, or 320 MHz transmission. When not specified EHTDUPMode is
%   disabled. Once the object is created this property is read only.
%
%   CFG = wlanEHTMUConfig(...,Name,Value) creates an EHT MU object, CFG,
%   with the specified property Name set to the specified Value. You can
%   specify additional name-value pair arguments in any order as
%   (Name1,Value1, ...,NameN,ValueN).
%
%   wlanEHTMUConfig methods:
%
%   psduLength            - Number of bytes to be coded in the packet
%   packetFormat          - EHT MU packet format
%   ruInfo                - Resource unit allocation information
%   numPostFECPaddingBits - Required number of post-FEC padding bits
%   transmitTime          - Returns the time required to transmit a packet
%   showAllocation        - Shows the RU and MRU allocation
%
%   wlanEHTMUConfig properties:
%
%   AllocationIndex            - RU allocation for each 20 MHz subchannel
%   ChannelBandwidth           - Channel bandwidth
%   NumUsers                   - Number of users in non-OFDMA configuration
%   PuncturedChannelFieldValue - Puncturing pattern value for non-OFDMA
%   PuncturingPattern          - Punctured subchannels for non-OFDMA
%   EHTDUPMode                 - Enable EHT DUP mode
%   RU                         - RU properties
%   User                       - User properties
%   NumTransmitAntennas        - Number of transmit antennas
%   PreEHTCyclicShifts         - Cyclic shift values for >8 transmit chains
%   PreEHTPhaseRotation        - Pre-EHT phase rotation coefficients for 320 MHz
%   GuardInterval              - Guard interval duration
%   EHTLTFType                 - Indicates EHT-LTF compression mode
%   NumExtraEHTLTFSymbols      - Number of extra EHT-LTF symbols
%   EHTSIGMCS                  - Indicates the MCS of the EHT-SIG field
%   UplinkIndication           - Indicates if the PPDU is sent on the uplink
%   BSSColor                   - Basic service set (BSS) color identifier
%   SpatialReuse               - Spatial reuse indication
%   TXOPDuration               - Duration information for TXOP protection
%   Channelization             - Channelization for 320 MHz

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

properties
    %RU Resource unit (RU or MRU) properties
    %   Set the transmission properties for each RU and MRU in the
    %   transmission. This property is a cell array of wlanEHTRU objects. Each 
    %   element of the cell array contains properties to configure an RU or
    %   an MRU. This property is configured when the object is created
    %   based on the defined AllocationIndex for OFDMA or ChannelBandwidth
    %   and PuncturedChannelFieldValue for non-OFDMA configuration.
    RU;
    %User User properties
    %   Set the transmission properties for each User in the transmission.
    %   This property is a cell array of wlanEHTUser objects. Each element
    %   of the cell array contains properties to configure a User. This
    %   property is configured when the object is created based on the
    %   defined AllocationIndex for OFDMA or NumUsers for non-OFDMA
    %   configuration.
    User;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a numeric, positive
    %   integer scalar. The default value is 1.
    NumTransmitAntennas (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumTransmitAntennas,1)} = 1;
    %PreEHTCyclicShifts Cyclic shift values for >8 transmit chains
    %   Specify the cyclic shift values for the pre-EHT portion of the
    %   waveform, in nanoseconds for >8 transmit antennas as a row vector
    %   of length L = NumTransmitAntennas-8. The cyclic shift values must
    %   be between -200 and 0 inclusive. The first 8 antennas use the
    %   cyclic shift values defined in Table 21-10 of IEEE Std 802.11-2020.
    %   The remaining antennas use the cyclic shift values defined in this
    %   property. If the length of this row vector is specified as a value
    %   greater than L the object only uses the first L, PreEHTCyclicShifts
    %   values. For example, if you specify the NumTransmitAntennas
    %   property as 16 and this property as a row vector of length N>L, the
    %   object only uses the first L = 16-8 = 8 entries. This property
    %   applies only when you set the NumTransmitAntennas property to a
    %   value greater than 8. The default value is -75.
    PreEHTCyclicShifts {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreEHTCyclicShifts,-200),mustBeLessThanOrEqual(PreEHTCyclicShifts,0)} = -75;
    %PreEHTPhaseRotation Pre-EHT phase rotation coefficients for 320 MHz
    %   Specifies the phase rotation coefficients for the pre-EHT portion
    %   of the waveform as a row vector of size 1-by-16. Each element of
    %   the vector corresponds to a complex multiplier applied to the
    %   respective subcarriers in a 20 MHz subchannel, ordered by
    %   increasing frequency, as defined in Equation 36-13 of IEEE
    %   P802.11be/D5.0. This property only applies when ChannelBandwidth is
    %   CBW320. The default value is [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1
    %   1].
    PreEHTPhaseRotation (1,16) {mustBeNumeric,mustBeFinite,mustBeNonzero} = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1];
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) length in microseconds
    %   as one of 0.8, 1.6 or 3.2. The default value is 3.2.
    GuardInterval {wlan.internal.heValidateGI(GuardInterval)} = 3.2;
    %EHTLTFType Indicates EHT-LTF compression mode of EHT PPDU
    %   Specify the EHT-LTF compression type as 2 or 4, corresponding to 2x
    %   EHT-LTF and 4x EHT-LTF modes respectively. The default value is 4.
    EHTLTFType (1,1) {mustBeNumeric,mustBeMember(EHTLTFType,[2 4])} = 4;
    %NumExtraEHTLTFSymbols Extra EHT-LTF symbols
    %   Specify the number of extra EHT-LTF symbols over the initial number
    %   of EHT-LTF symbols determined by the maximum of the number of
    %   spatial streams in a resource unit as a numeric, positive integer
    %   scalar between 0 and 7 inclusive. The sum of number of extra
    %   EHT-LTF symbol and the initial number of EHT-LTF symbols must not be
    %   greater than 8. The default value is 0.
    NumExtraEHTLTFSymbols (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumExtraEHTLTFSymbols,0),mustBeLessThanOrEqual(NumExtraEHTLTFSymbols,7)} = 0;
    %EHTSIGMCS Indicates the MCS of the EHT-SIG field
    %   Specify the modulation and coding scheme of the EHT-SIG field as 0,
    %   1, 3, or 15, corresponding to EHT-SIG field value 0, 1, 2, or 3 as
    %   defined in Table 36-88 of IEEE P802.11be/D5.0. The default value is
    %   0.
    EHTSIGMCS (1,1) {mustBeNumeric,mustBeMember(EHTSIGMCS,[0 1 3 15])} = 0;
    %UplinkIndication Indicates if the PPDU is sent on an uplink transmission
    %   Set this property to true to indicate that the PPDU is sent on an
    %   uplink transmission. UplinkIndication must be false for OFDMA
    %   configurations. The default is false which indicates a downlink
    %   transmission.
    UplinkIndication (1,1) logical = false;
    %BSSColor Basic service set (BSS) color identifier
    %   Specify the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default value is 0.
    BSSColor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(BSSColor,0),mustBeLessThanOrEqual(BSSColor,63)} = 0;
    %SpatialReuse Spatial reuse indication
    %   Specify the SpatialReuse as an integer scalar between 0 and 15,
    %   inclusive. The default is 0.
    SpatialReuse (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse,0),mustBeLessThanOrEqual(SpatialReuse,15)} = 0;
    %TXOPDuration Duration information for TXOP protection
    %   Specify the TXOPDuration signaled in U-SIG in microseconds as
    %   integer scalar between 0 and 8448, inclusive as specified in Table
    %   36-1 of IEEE P802.11be/D5.0. For more information see the documentation.
    %   Use empty ([]) to specify no NAV duration and the TXOP field in
    %   U-SIG is set to 127. The default is [].
    TXOPDuration {wlan.internal.ehtValidateTXOPDuration(TXOPDuration)} = [];
    %Channelization Channelization for 320 MHz
    %   Specify the channelization for 320 MHz channel bandwidth as 1 or 2,
    %   corresponding to '320MHz-1' and '320MHz-2' in Section 36.3.24.2 of
    %   IEEE P802.11be/D5.0. This property only applies when
    %   ChannelBandwidth is CBW320. The default value is 1.
    Channelization (1,1) {mustBeNumeric,mustBeMember(Channelization,[1 2])} = 1;
end

properties(SetAccess = 'private')
    %ChannelBandwidth Channel bandwidth (MHz) of EHT MU PPDU
    %   The channel bandwidth, specified as one of 'CBW20' | 'CBW40' |
    %   'CBW80' | 'CBW160' | 'CBW320'. For OFDMA this property is set when
    %   the object is created based on the defined AllocationIndex. For
    %   non-OFDMA this property is set once the object is created based on
    %   the defined ChannelBandwidth. Once the object is created this
    %   property is read only.
    ChannelBandwidth = 'CBW320';
    %AllocationIndex RU allocation index per 80 MHz frequency subblock per 20 MHz subchannel
    %   Specify the RU allocation index when creating the object. Once the
    %   object is created, AllocationIndex is read only. The allocation
    %   index defines the number and sizes of RUs, and the number of users
    %   assigned to each RU, see the documentation. Table 36-34 of
    %   IEEE P802.11be/D5.0 defines the assignment index for each 20 MHz
    %   subchannel.
    %
    %   For 20 MHz, 40 MHz, or 80 MHz, AllocationIndex is a 1-by-N vector.
    %   For 160 MHz and 320 MHz, AllocationIndex is an M-by-N matrix
    %   representing the signaled allocation in EHT-SIG content channels
    %   per 80 MHz frequency subblock. Where M is the number of 80 MHz
    %   subblocks and is 2 for 160 MHz and 4 for 320 MHz.
    AllocationIndex = 0;
    %PuncturingPattern Indicates punctured subchannels for non-OFDMA
    %   Indicates inactive 20 MHz or 40 MHz subchannels as a logical vector
    %   for the given PuncturedChannelFieldValue property. For 80 MHz and
    %   160 MHz the number of elements are equal to the number of 20 MHz
    %   subchannels. A true value indicates an inactive (punctured) 20 MHz
    %   subchannel in a 80 MHz and 160 MHz bandwidth. For 320 MHz the
    %   number of elements are equal to the number of 40 MHz subchannels.
    %   In this case a true value indicates an inactive (punctured) 40 MHz
    %   subchannel. Subchannels are ordered from lowest to highest absolute
    %   frequency. This property applies only when ChannelBandwidth is
    %   'CBW80', 'CBW160', or 'CBW320'. Once the object is created this
    %   property is read only.
    PuncturingPattern logical = false;
    %PuncturedChannelFieldValue Puncturing pattern value for non-OFDMA
    %   Set this property to a scalar between 0 and 24 (inclusive) using
    %   name-value pairs. This property indicates puncturing pattern value
    %   for a non-OFDMA configuration as defined in Table 36-30 of IEEE
    %   P802.11be/D5.0. This property applies only to a non-OFDMA
    %   configuration. After the object is created this property is read
    %   only. The default is 0.
    PuncturedChannelFieldValue (1,1) double = 0;
    %NumUsers Number of users in non-OFDMA configuration
    %   Set this property to a scalar number between 1 and 8 (inclusive)
    %   using name-value pairs. This property sets the number of users only
    %   in non-OFDMA configuration. Once the object is created this
    %   property is read only. The default is 1.
    NumUsers (1,1) double = 1;
    %EHTDUPMode Enable EHT DUP mode
    %   Set this property to true using name-value pairs when the object is
    %   created to enable EHT DUP mode. After the object is created this
    %   property is read only. This property applies only to a non-OFDMA
    %   configuration when the channel bandwidth is 80 MHz, 160 MHz, or 320
    %   MHz. For EHT DUP mode the user must be configured with MCS 14 and 1
    %   space-time stream. The default is false.
    EHTDUPMode (1,1) logical = false;
end

properties(SetAccess = 'private',Hidden)
    pPrivateUserRUNumber = 1;
    pIsOFDMA = true;
    pAllocInfo = struct('NumUsers',0,'NumRUs',0,'RUIndices',zeros(0,1),'RUSizes',zeros(0,1),'NumUsersPerRU',zeros(0,1), ...
            'PuncturingPattern',zeros(0,1),'NumUsersPerSubchannel',zeros(0,1),'RUSubchannelAllocation',zeros(0,1),'UsersSignaledPerSubchannel',zeros(0,1), ...
            'AllocationIndexPerSegment',zeros(0,1),'ChannelBandwidth',0,'IsSameEHTSignalling',false);
end

methods
    function obj = wlanEHTMUConfig(x,varargin)
        %wlanEHTMUConfig Create an EHT MU format configuration object

        narginchk(1,Inf);
        % Differentiate between allocation index and channel bandwidth. If
        % the input is character vector or string than the configuration is
        % for non-OFDMA.
        if (isstring(x) || ischar(x)) % MU-MIMO (non-OFDMA)
            % wlanEHTMUConfig('CBW',N,V,...)
            chanBW = validatestring(x,{'CBW20','CBW40','CBW80','CBW160','CBW320'},'ChannelBandwidth'); % Validate Channel Bandwidth
            coder.varsize('chanBW',[1 6],[0 1]); % Make channel bandwidth varsize
            if nargin>1
                coder.internal.errorIf((mod(nargin-1,2)~=0),'wlan:ConfigBase:InvalidPVPairs');
                for i = 1:2:nargin-1
                    coder.internal.errorIf(any(strcmp(varargin{i},{'RU','User'})),'wlan:wlanEHTMUConfig:InvalidNameValueNonOFDMA');
                    obj.(char(varargin{i})) = varargin{i+1};
                end
            end

            % Map channel bandwidth and number of users to allocation index
            obj.pIsOFDMA = false; % Set flag for non-OFDMA transmission
            [obj.RU,obj.User,obj.pPrivateUserRUNumber,obj.pAllocInfo] = ehtRUAllocation(chanBW,obj.NumUsers,obj.PuncturedChannelFieldValue,obj.EHTDUPMode);
            obj.PuncturingPattern = obj.pAllocInfo.PuncturingPattern; % Set puncturing pattern
            obj.ChannelBandwidth = chanBW;
        else % OFDMA
            % wlanEHTMUConfig(allocationIndex,N,V,...)
            validateattributes(x,{'numeric','integer'},{'nonempty','nonnan','finite'},mfilename,'AllocationIndex');
            allocationIndex = x;
            if nargin>1
                coder.internal.errorIf((mod(nargin-1,2)~=0),'wlan:ConfigBase:InvalidPVPairs');
                for i = 1:2:nargin-1
                    coder.internal.errorIf(any(strcmp(varargin{i},{'RU','User','ChannelBandwidth','AllocationIndex'})),'wlan:wlanEHTMUConfig:InvalidNameValueOFDMA');
                    obj.(char(varargin{i})) = varargin{i+1};
                end
            end
            [obj.RU,obj.User,obj.pPrivateUserRUNumber,obj.pAllocInfo] = ehtRUAllocation(allocationIndex);
            
            obj.AllocationIndex = obj.pAllocInfo.AllocationIndexPerSegment;
            obj.PuncturingPattern = obj.pAllocInfo.PuncturingPattern; % Set puncturing pattern
            obj.ChannelBandwidth = obj.pAllocInfo.ChannelBandwidth;
        end
    end

    function obj = set.RU(obj,value)
        % Validate RU property is a cell array of wlanEHTRU objects

        validateattributes(value,{'cell'},{'nonempty'},mfilename,'RU');
        numInp = numel(value);
        % Validate expected number of RU objects
        if coder.target('MATLAB') && numel(obj.RU)~=numInp && numel(obj.RU)~=0
            coder.internal.error('wlan:shared:InvalidRU',numel(obj.RU),'wlanEHTRU');
        end

        for i = 1:numInp
            coder.internal.errorIf(~isa(value{i},'wlanEHTRU'),'wlan:shared:InvalidRU',numInp,'wlanEHTRU');
        end
        obj.RU = value;
    end

    function obj = set.User(obj,value)
        % Validate User property is a cell array of wlanEHTUser objects

        validateattributes(value,{'cell'},{'nonempty'},mfilename,'User');

        numInp = numel(value);
        % Validate expected number of User objects
        if coder.target('MATLAB') && numel(obj.User)~=numInp && numel(obj.User)~=0
            coder.internal.error('wlan:shared:InvalidUser',numel(obj.User),'wlanEHTUser');
        end

        for i = 1:numInp
            coder.internal.errorIf(~isa(value{i},'wlanEHTUser'),'wlan:shared:InvalidUser',numInp,'wlanEHTUser');
        end
        obj.User = value;
    end

    function s = ruInfo(obj)
        %ruInfo Returns information relevant to the resource unit
        %   S = ruInfo(cfg) returns a structure, S, containing the resource
        %   unit (RU) allocation information for the wlanEHTMUConfig object, cfg.
        %   The output structure S has the following fields:
        %
        %   NumUsers                 - Number of users
        %   NumRUs                   - Number of RUs
        %   RUIndices                - Index of the RU or MRU
        %   RUSizes                  - Size of the RU or MRU
        %   NumUsersPerRU            - Number of users per RU
        %   NumSpaceTimeStreamsPerRU - Total number of space-time streams
        %   PowerBoostFactorPerRU    - Power boost factor
        %   RUNumbers                - RU number
        %   RUAssigned               - Indicate assigned RUs
        %
        %   RUIndices and RUSizes are a cell array where each element is the
        %   index or size of an RU/MRU. For an MRU the cell array element is a
        %   vector containing RU indices and sizes which form an MRU.

        numRUs = numel(obj.RU);
        numUsers = numel(obj.User);
        ruActive = true(1,numRUs);
        for j = 1:numUsers
            if obj.User{j}.STAID==2046
                % If STAID is 2046 then RU is inactive
                ruNum = obj.User{j}.RUNumber;
                if ruNum<=numRUs
                    ruActive(ruNum) = false;
                end
            end
        end

        ruIndices = coder.nullcopy(cell(1,numRUs)); % For codegen
        ruSizes = coder.nullcopy(cell(1,numRUs)); % For codegen
        ruNumbers = zeros(1,numRUs);
        numSTS = zeros(1,numRUs);
        powerBoostFactor = zeros(1,numRUs);
        numUsersPerRU = zeros(1,numRUs);

        k = 1;
        for i = 1:numRUs
            for j = 1:numUsers
                ruShared = i==obj.pPrivateUserRUNumber(j);
                if ruShared
                    numUsersPerRU(k) = numUsersPerRU(k)+1;
                    numSTS(k) = numSTS(k)+obj.User{j}.NumSpaceTimeStreams;
                end
            end
            ruIndices{k} = obj.RU{i}.Index;
            ruSizes{k} = obj.RU{i}.Size;
            ruNumbers(k) = i;
            powerBoostFactor(k) = obj.RU{i}.PowerBoostFactor;
            k = k+1;
        end

        s = struct;
        s.NumUsers = numUsers;
        s.NumRUs = numRUs;
        s.RUIndices = ruIndices;
        s.RUSizes = ruSizes;
        s.NumUsersPerRU = numUsersPerRU;
        s.NumSpaceTimeStreamsPerRU = numSTS;
        s.PowerBoostFactorPerRU = powerBoostFactor;
        s.RUNumbers = ruNumbers;
        s.RUAssigned = ruActive;
    end

    function n = numPostFECPaddingBits(obj)
        %numPostFECPaddingBits Required number of post-FEC padding bits
        %   Returns a vector with the required number of post-FEC padding
        %   bits for each user.

        [~,userCodingParams] = wlan.internal.ehtCodingParameters(obj);
        n = [userCodingParams.NPADPostFEC];
    end

    function psduLength = psduLength(obj)
        %psduLength Returns PSDU length for the configuration
        %   Returns the PSDU length for an EHT MU configuration as defined in
        %   Section 36.4.3 of IEEE P802.11be/D5.0.

        validateSTAID(obj); % Validate STAID 2046
        psduLength = wlan.internal.ehtPLMETxTimePrimative(obj);
    end
    
    function format = packetFormat(obj) %#ok<MANU>
        %packetFormat Returns the packet format
        %   Returns the packet format as a character vector, based on the
        %   current configuration.

        format = 'EHT-MU';
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
        validateSTAID(obj); % Validate STAID 2046
        [~,t] = wlan.internal.ehtPLMETxTimePrimative(obj);
        t = t*1e-3; % Convert nanoseconds to microseconds
        t = wlan.internal.convertTransmitTime(t,varargin{:});
    end
    
    function showAllocation(obj,varargin)
        %showAllocation Shows the RU and MRU allocation
        %   showAllocation(cfg) shows the RU and MRU allocation for an EHT MU
        %   packet format.
        %
        %   showAllocation(cfg,AX) shows the allocation in the axes specified
        %   by AX instead of in the current axes. If AX is not specified,
        %   showAllocation plots the allocation in a new figure.

        wlan.internal.hePlotAllocation(obj,varargin{:});
    end
    
    function [mode,isNDP] = compressionMode(obj)
        %compressionMode Returns compression mode as defined in IEEE P802.11be/D5.0, Table 36-29

        mode = 0; % DL OFDMA
        isNDP = false; % Not an NDP
        if ~obj.pIsOFDMA
            if isscalar(obj.User)
                mode = 1; % SU or NDP
                isNDP = obj.User{1}.APEPLength==0;
            else
                mode = 2; % DL MU-MIMO
            end
        end
    end
    
    function varargout = validateConfig(obj,varargin)
        %validateConfig Validate the dependent properties of wlanEHTMUConfig object
        %   validateConfig(obj) validates the dependent properties for the
        %   specified wlanEHTMUConfig configuration object.
        %
        %   For INTERNAL use only, subject to future changes
        %
        %   validateConfig(CFG,MODE) validates only the subset of dependent
        %   properties as specified by the MODE input. MODE must be one of:
        %       'EHTLTFGI'
        %       'DataLocationLength'
        %       'Coding'
        %       'CyclicShift'
        %       'EHTSIGMCSNDP'
        %       'ExtraEHTLTFSymbols'
        %       'EHTDUPMode'
        %       'EHTMCS15'
        %       'Full'

        narginchk(1,2);
        nargoutchk(0,1);
        if (nargin==2)
            mode = varargin{1};
        else
            mode = 'Full';
        end

        switch mode
            case 'EHTLTFGI'
                % Validate the EHT-LTF type and GuardInterval
                validateEHTLTFGI(obj);
            case 'DataLocationLength'
                % Validate and get Length properties of EHT MU packet
                s = validateMCSLength(obj);
            case 'Coding'
                % Validate coding parameters
                validateCoding(obj);
            case 'CyclicShift'
                % Validate PreEHTCyclicShifts against NumTransmitAntennas
                validatePreEHTCyclicShifts(obj);
            case 'EHTSIGMCSNDP'
                % Validate EHT-SIG MCS for NDP packet
                validateEHTSIGMCSNDP(obj);
            case 'ExtraEHTLTFSymbols'
                % Validate NumExtraEHTLTFSymbols
                validateNumExtraEHTLTFSymbols(obj);
            case 'EHTDUPMode'
                % Validate EHT DUP mode
                validateEHTDUPMode(obj);
            case 'EHTMCS15'
                % Validate MCS-15
                validateMCS15(obj);
            case 'NumEHTSIGSymbols'
                % Validate the number of EHT-SIG symbols
                validateNumEHTSIGSymbols(obj);
            otherwise % wlanWaveformGenerator
                % Full object validation

                % Compression mode validation for uplink transmission
                validateCompressionMode(obj);

                % Validate EHT-SIG MCS for NDP packet
                validateEHTSIGMCSNDP(obj);

                % Validate Spatial mapping properties and spatial mapping matrix
                validateSpatialMapping(obj)

                % Validate PreEHTCyclicShifts against NumTransmitAntennas
                validatePreEHTCyclicShifts(obj);

                % Validate number STS per user/RU
                validateRUUserSpatialStreams(obj);

                % Validate NumExtraEHTLTFSymbols
                validateNumExtraEHTLTFSymbols(obj);

                % Validate EHT DUP mode
                validateEHTDUPMode(obj);

                % Validate MCS-15
                validateMCS15(obj);

                % Validate MCS and length
                s = validateMCSLength(obj);
        end

        if nargout == 1
            varargout{1} = s;
        end
    end
  end

  methods (Access = private)
    function validateCoding(obj)
        %validateCoding Coding properties for wlanEHTMUConfig configuration object
        %
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumSpaceTimeStreams, MCS, ChannelCoding, RU
        %     Size, STAID

        % Validate ChannelCoding and the number of space-time streams for all users
        for userIdx = 1:numel(obj.User)
            if obj.User{userIdx}.ChannelCoding==wlan.type.ChannelCoding.bcc
                coder.internal.errorIf(sum(obj.RU{obj.User{userIdx}.RUNumber}.Size)>242,'wlan:shared:InvalidBCCRUSize');
                coder.internal.errorIf(obj.User{userIdx}.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS');
                coder.internal.errorIf(any(obj.User{userIdx}.MCS==[10 11 12 13]),'wlan:eht:InvalidBCCMCS');
            end
        end

        validateSTAID(obj);
    end

    function validateSTAID(obj)
        %validateSTAID Validate STAID and APEPLength
        %   Validate at least one user is active for OFDMA. For non-OFDMA STAID
        %   for the user must not be 2046. The APEPLength for non-OFDMA must
        %   not be zero for any user if the number of users are greater than 1
        %
        %   Validated property-subset includes:
        %     STAID, APEPLength

        % Validate STAID is not 2046 for all users
        userActive = true(1,numel(obj.User)); % Vector indicating if a user object is active
        if obj.pIsOFDMA
            for userIdx = 1:numel(obj.User)
                if obj.User{userIdx}.STAID==2046
                    % If STAID is 2046, then RU carries no data, and user is inactive
                    userActive(userIdx) = false;
                end
                % APEPLength should not be zero for OFDMA users
                coder.internal.errorIf(obj.User{userIdx}.APEPLength==0,'wlan:wlanEHTMUConfig:InvalidAPEPLength');
            end
            % Make sure at least one of the users is active
            numActiveUsers = nnz(userActive==true);
            coder.internal.errorIf(numActiveUsers==0,'wlan:shared:NoActiveUsers');
        else
            % If STAID is 2046 in a MU-MIMO RU, then error
            for userIdx = 1:numel(obj.User)
                coder.internal.errorIf(obj.User{userIdx}.STAID==2046,'wlan:shared:InactiveUserInMU');
                if obj.User{userIdx}.APEPLength==0
                    userActive(userIdx) = false;
                end
            end
            % APEPLength of any user must not be zero in MU-MIMO
            coder.internal.errorIf(~isscalar(userActive) && ~all(userActive),'wlan:wlanEHTMUConfig:InvalidAPEPLengthMUMIMO');
        end
    end
    
    function s = validateMCSLength(obj)
        %validateMCSLength Length properties for wlanEHTMUConfig configuration object
        %
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, MCS,
        %     ChannelCoding, GuardInterval, APEPLength

        % Validate EHTLTFType and GuardInterval for EHT-LTF
        validateEHTLTFGI(obj);

        % Validate coding related properties
        validateCoding(obj);

        % Validate number of EHT-SIG symbols
        validateNumEHTSIGSymbols(obj);

        [psduLength,txTime,commonCodingParams,~,trc] = wlan.internal.ehtPLMETxTimePrimative(obj);

        sf = 1e3; % Scaling factor to convert time from ns to us
        % Set output structure
        s = struct( ...
            'NumDataSymbols',commonCodingParams.NSYM, ...
            'TxTime',txTime/sf, ...% TxTime in us
            'PSDULength',psduLength, ...
            'TPE', trc.TPE/1000);

        % Validate txTime (max 5.484ms for EHT format)
        coder.internal.errorIf(s.TxTime>5484,'wlan:shared:InvalidPPDUDuration',round(s.TxTime),5484);
    end

    function validateSpatialMapping(obj)
        %validateSpatialMapping Validate the spatial mapping properties
        %
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumTransmitAntennas, NumSpaceTimeStreams,
        %     SpatialMapping, SpatialMappingMatrix

        % Validate SpatialMappingMatrix, SpatialMapping and the number of transmit antennas
        infoRUs = ruInfo(obj);
        ruSizes = infoRUs.RUSizes;
        for i = 1:infoRUs.NumRUs
            if ~infoRUs.RUAssigned(i)
                continue
            end
            % NumTx and Nsts: numTx cannot be less than sum(Nsts)
            coder.internal.errorIf(obj.NumTransmitAntennas < infoRUs.NumSpaceTimeStreamsPerRU(i),'wlan:he:NumSTSLargerThanNumTx',infoRUs.RUNumbers(i),infoRUs.NumSpaceTimeStreamsPerRU(i),obj.NumTransmitAntennas);
            if obj.RU{i}.SpatialMapping==wlan.type.SpatialMapping.custom
                % Validate spatial mapping matrix
                wlan.internal.validateSpatialMappingMatrix(obj.RU{i}.SpatialMappingMatrix,obj.NumTransmitAntennas,infoRUs.NumSpaceTimeStreamsPerRU(i),sum(ruSizes{i}),i);
            else
                 coder.internal.errorIf(obj.RU{i}.SpatialMapping==wlan.type.SpatialMapping.direct && infoRUs.NumSpaceTimeStreamsPerRU(i)~= obj.NumTransmitAntennas,'wlan:he:NumSTSNotEqualNumTxDirectMap',i,infoRUs.NumSpaceTimeStreamsPerRU(i),obj.NumTransmitAntennas);
            end
        end
    end
    
    function validateEHTLTFGI(obj)
        %validateEHTLTFGI Validate EHT-LTF type and GuardInterval. Table 36-44 of IEEE P802.11be/D5.0
        %
        %   Validated property-subset includes:
        %     EHTLTFType, GuardInterval

        [~,isNDP] = compressionMode(obj);
        coder.internal.errorIf(obj.EHTLTFType==4 && obj.GuardInterval==0.8 && isNDP,'wlan:eht:InvalidGILTFNDP',feval('sprintf','%1.1f',obj.GuardInterval),obj.EHTLTFType);
        coder.internal.errorIf(obj.EHTLTFType~=2 && obj.GuardInterval==1.6,'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'EHTLTFType',obj.EHTLTFType);
        coder.internal.errorIf(obj.EHTLTFType~=4 && obj.GuardInterval==3.2,'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'EHTLTFType',obj.EHTLTFType);
    end
    
    function validatePreEHTCyclicShifts(obj)
        %validatePreEHTCyclicShifts Validate PreEHTCyclicShifts values against NumTransmitAntennas
        %
        %   Validated property-subset includes:
        %     PreEHTCyclicShifts, NumTransmitAntennas

        numTx = obj.NumTransmitAntennas;
        csh = obj.PreEHTCyclicShifts;
        coder.internal.errorIf(~(numel(csh)>=numTx-8),'wlan:shared:InvalidCyclicShift','PreEHTCyclicShifts',numTx-8);
    end

    function validateEHTSIGMCSNDP(obj)
        %validateEHTSIGMCSNDP Validate EHT-SIG MCS for NDP packet
        %
        %   Validated property-subset includes:
        %     EHTSIGMCS

        [~,isNDP] = compressionMode(obj);
        coder.internal.errorIf(isNDP && ~obj.EHTSIGMCS==0,'wlan:wlanEHTMUConfig:InvalidEHTSIGMCS');
    end

    function validateCompressionMode(obj)
        %validateCompressionMode Validate combination of uplink and compression mode
        %
        %   Validated property-subset includes:
        %     UplinkIndication

        mode = compressionMode(obj);
        coder.internal.errorIf(obj.UplinkIndication && any(mode==[0 2]),'wlan:eht:InvalidCompressionMode');
    end

    function validateNumExtraEHTLTFSymbols(obj)
        %validateNumExtraEHTLTFSymbols Validate extra number of EHT-LTF symbols
        %
        %   Validated property-subset includes:
        %     NumExtraEHTLTFSymbols

        wlan.internal.validateNumExtraEHTLTFSymbols(obj)
    end

    function validateRUUserSpatialStreams(obj)
        %validateRUUserSpatialStreams Space-time streams per user per RU for the configuration object
        %
        %   Validated property-subset includes:
        %     NumSpaceTimeStreams, User, RU

        userIdx = 1;
        for i = 1:numel(obj.RU)
            numUsers = numel(obj.RU{i}.UserNumbers);
            if numUsers>1
                numSTSPerUser = zeros(numUsers,1);
                for j = 1:numUsers
                    numSTSPerUser(j) = obj.User{userIdx}.NumSpaceTimeStreams;
                    userIdx = userIdx+1;
                end
                % Validate, number of space-time streams in a MU-MIMO RU
                wlan.internal.ehtSpatialConfigurationBits(numSTSPerUser,i);
            else
                userIdx = userIdx+1;
            end
        end
    end

    function validateEHTDUPMode(obj)
        %validateEHTDUPMode Validate EHT DUP mode
        %
        %   Validated property-subset includes:
        %     NumSpaceTimeStreams, EHT-MCS 14

        if obj.pIsOFDMA
            coder.internal.errorIf(obj.EHTDUPMode,'wlan:eht:InvalidDUPMode');
            for u = 1:numel(obj.User)
                coder.internal.errorIf(obj.User{u}.MCS==14,'wlan:eht:InvalidDUPMode');
            end
        else % non-OFDMA
            coder.internal.errorIf(obj.EHTDUPMode && obj.User{1}.NumSpaceTimeStreams>1, 'wlan:eht:InvalidDUPMode');
            coder.internal.errorIf(obj.EHTDUPMode && obj.User{1}.MCS~=14,'wlan:eht:InvalidDUPMode');
            coder.internal.errorIf(~obj.EHTDUPMode && obj.User{1}.MCS==14,'wlan:wlanEHTMUConfig:InvalidEHTDUPMode');
        end
    end

    function validateMCS15(obj)
        %validateMCS15 Validate EHT-MCS 15
        %
        %   Validated property-subset includes:
        %     NumSpaceTimeStreams

        for u = 1:numel(obj.User)
            coder.internal.errorIf(obj.User{u}.MCS==15 && obj.User{u}.NumSpaceTimeStreams>1,'wlan:eht:InvalidMCS15NSTS');
        end
    end

    function validateNumEHTSIGSymbols(obj)
        %validateNumEHTSIGSymbols Validate the number of EHT-SIG symbols

        ehtSIGInfo = wlan.internal.ehtSIGCodingInfo(obj);
        coder.internal.errorIf(ehtSIGInfo.NumSIGSymbols>32,'wlan:wlanEHTMUConfig:InvalidNumEHTSIGSymbols');
    end
  end

  methods (Access = protected)
      function flag = isInactiveProperty(obj,prop)
          if strcmp(prop,'PreEHTCyclicShifts')
              % Hide PreEHTCyclicShifts when NumTransmitAntennas <=8
              flag = obj.NumTransmitAntennas<=8;
          elseif any(strcmp(prop,{'PuncturingPattern','PuncturedChannelFieldValue','EHTDUPMode'}))
              % Hide PuncturingPattern, PuncturedChannelFieldValue, and
              % EHTDUPMode for OFDMA when ChannelBandwidth is CBW20 or
              % CBW40
              flag = obj.pIsOFDMA || any(strcmp(obj.ChannelBandwidth,{'CBW20','CBW40'}));
          elseif any(strcmp(prop,'AllocationIndex'))
              % Hide AllocationIndex for non-OFDMA format
              flag = ~obj.pIsOFDMA;
          elseif any(strcmp(prop,{'PreEHTPhaseRotation','Channelization'}))
              % Hide PreEHTPhaseRotation and Channelization for bandwidths other than 320 MHz
              flag = ~strcmp(obj.ChannelBandwidth,'CBW320');
          elseif any(strcmp(prop,'NumUsers'))
              % Hide NumUsers for OFDMA
              flag = obj.pIsOFDMA;
          else
              flag = false;
          end
      end
  end
end

function [ru,user,userRUNumber,allocParams] = ehtRUAllocation(varargin)
%Returns a cell array of RUs, Users, user RU number, puncturing pattern and allocation info

    allocParams = wlan.internal.ehtAllocationInfo(varargin{:});
    numRUs = allocParams.NumRUs; % Only single RU configuration is supported
    numUsers = allocParams.NumUsers; % Only single user configuration is supported

    Usertmp = cell(1,numUsers);
    RUtmp = cell(1,numRUs);
    userIdx = 1;
    userRUNumber = zeros(1,numUsers);
    for i = 1:numRUs
        ruUserNumber = zeros(1,allocParams.NumUsersPerRU(i));
        for j = 1:allocParams.NumUsersPerRU(i)
            userRUNumber(userIdx) = i;
            ruUserNumber(j) = userIdx;
            userIdx = userIdx+1;
        end
        RUtmp{i} = wlanEHTRU(allocParams.RUSizes{i},allocParams.RUIndices{i},ruUserNumber);
    end

    for u = 1:numUsers
        Usertmp{u} = wlanEHTUser(userRUNumber(u),'PostFECPaddingSeed',u,'STAID',u-1);
    end

    if nargin>2 && varargin{4}
        Usertmp{1}.MCS = 14; % Set the MCS to 14 for EHT DUP mode
    end

    user = Usertmp;
    ru = RUtmp;
end
