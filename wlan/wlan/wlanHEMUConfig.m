classdef wlanHEMUConfig < comm.internal.ConfigBase
%wlanHEMUConfig Create a multi-user high efficiency (HE) format configuration object
%   CFGHE = wlanHEMUConfig(AllocationIndex) creates a multi user (MU) high
%   efficiency (HE) format configuration object. This object contains the
%   transmit parameters for the HE-MU format of IEEE Std 802.11ax-2021.
%
%   AllocationIndex specifies the resource unit (RU) allocation. The
%   allocation defines the number and sizes of RUs, and the number of users
%   assigned to each RU. IEEE Std 802.11ax-2021, Table 27-26 defines the
%   assignment index as an 8-bit index for each 20 MHz subchannel. The RU
%   allocation for each assignment index can be viewed in the documentation.
%
%   AllocationIndex can be a vector of integers between 0 and 223
%   inclusive, a string array, a character vector, or a cell array of
%   character vectors.
%
%   When AllocationIndex is specified as a vector of integers, each element
%   corresponds to an 8 bit index in Table 27-24. The length of
%   AllocationIndex must be 1, 2, 4, or 8, defining the assignment for each
%   20 MHz subchannel in a 20 MHz, 40 MHz, 80 MHz or 160 MHz channel
%   bandwidth. For a full band allocation with a single RU, AllocationIndex
%   can be specified as a scalar between 192 and 223 inclusive.
%
%   AllocationIndex can also be specified using the corresponding 8-bit
%   binary vector per allocation as specified in Table 27-24. An 8 bit
%   binary sequence can be provided as a character vector or string. A
%   string vector or cell array of character vectors can be used to specify
%   an allocation per 20 MHz subchannel.
%
%   To configure an OFDMA transmission greater than 20 MHz, AllocationIndex
%   consists of an assignment index for each 20 MHz subchannel. For
%   example, to configure an 80 MHz OFDMA transmission, a numeric row
%   vector with 4 allocation indices, or a string array with 4 elements is
%   required. You can signal punctured 20 MHz or 40 MHz subchannels in an
%   80 MHz or 160 MHz transmission. To signal a punctured 20 MHz
%   subchannel, set the corresponding element of the AllocationIndex
%   property to 113. To signal a punctured 40 MHz subchannel, set the two
%   corresponding elements of the AllocationIndex property to 114. To
%   signal an empty HE-SIG-B user field in an HE-SIG-B content channel, set
%   the corresponding element of the AllocationIndex property to 114 or
%   115. This AllocationIndex is only valid when configured with other
%   appropriate 484 or 996-tone RU assignment indices for an 80 MHz or 160
%   MHz transmission.
%
%   To configure a full band MU-MIMO transmission with HE-SIG-B compression
%   the following values of AllocationIndex can be used:
%      20 MHz:  AllocationIndex = 191 + NumUsers
%      40 MHz:  AllocationIndex = 199 + NumUsers
%      80 MHz:  AllocationIndex = 207 + NumUsers
%      160 MHz: AllocationIndex = 215 + NumUsers
%   To configure a full bandwidth MU-MIMO transmission without HE-SIG-B
%   compression, specify an allocation index for each 20 MHz subchannel.
%   For a 20 MHz full-band MU-MIMO transmission, HE-SIG-B compression can
%   be enabled or disabled using the SIGBCompression property.
%
%   CFGHE = wlanHEMUConfig(...,'LowerCenter26ToneRU',true,'UpperCenter26ToneRU',true)
%   additionally allows the lower and/or upper frequency center 26-tone RUs
%   to be enabled for an 80 MHz or 160 MHz transmission which is not full
%   band. The lower center 26-tone RU can only be used when AllocationIndex
%   specifies an 80 MHz or 160 MHz transmission. The upper center 26-tone
%   RU can only be used when AllocationIndex signifies an 160 MHz
%   transmission. When not specified the center 26-tone RUs are not used.
%
%   The returned configuration object CFGHE is parameterized according to
%   the assignment index. The RU and User properties are configured as per
%   the assignment.
%
%   CFGHE = wlanHEMUConfig(...,Name,Value) creates an HE-MU object, CFGHE,
%   with the specified property Name set to the specified Value. You can
%   specify additional name-value pair arguments in any order as
%   (Name1,Value1, ...,NameN,ValueN). The ChannelBandwidth, RU, and User
%   properties are derived from the AllocationIndex and therefore cannot be
%   specified using name-value pairs.
%
%   wlanHEMUConfig methods:
%
%   getPSDULength            - Number of bytes to be coded in the packet
%   packetFormat             - Packet format
%   ruInfo                   - Resource unit allocation information
%   showAllocation           - Shows the RU allocation
%   transmitTime             - Time required to transmit a packet
%   getNumPostFECPaddingBits - Required number of post-FEC padding bits
%
%   wlanHEMUConfig properties:
%
%   AllocationIndex      - RU allocation index for each 20 MHz subchannel
%   ChannelBandwidth     - Channel bandwidth
%   LowerCenter26ToneRU  - Enable the lower center 26-tone RU
%   UpperCenter26ToneRU  - Enable the upper center 26-tone RU
%   RU                   - RU properties of each assignment index
%   User                 - User properties of each assignment index
%   PrimarySubchannel    - Primary 20 MHz subchannel index
%   NumTransmitAntennas  - Number of transmit antennas
%   PreHECyclicShifts    - Cyclic shift values for >8 transmit chains
%   STBC                 - Enable space-time block coding
%   GuardInterval        - Guard interval duration
%   HELTFType            - Indicate HE-LTF compression mode
%   SIGBCompression      - Enable HE-SIG-B compression
%   SIGBMCS              - Indicates the MCS of the HE-SIG-B field
%   SIGBDCM              - Indication if HE-SIG-B is modulated with DCM
%   UplinkIndication     - Indicate if the PPDU is sent on the uplink
%   BSSColor             - Basic service set (BSS) color identifier
%   SpatialReuse         - Spatial reuse indication
%   TXOPDuration         - Duration information for TXOP protection
%   HighDoppler          - High Doppler mode indication
%   MidamblePeriodicity  - Midamble periodicity in number of OFDM symbols
%

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

properties
    %RU Resource unit (RU) properties
    %   Set the transmission properties for each RU in the transmission.
    %   This property is a cell array of wlanHEMURU objects. Each element of
    %   the cell array contains properties to configure an RU. This
    %   property is configured when the object is created based on the
    %   defined AllocationIndex.
    RU;
    %User User properties
    %   Set the transmission properties for each User in the transmission.
    %   This property is a cell array of wlanHEMUUser objects. Each element
    %   of the cell array contains properties to configure a User. This
    %   property is configured when the object is created based on the
    %   defined AllocationIndex.
    User;
    %PrimarySubchannel Primary 20 MHz subchannel index
    %   Specify the subchannel index of the primary 20 MHz subchannel
    %   within the 80 or 160 MHz channel bandwidth. For 80 MHz the index
    %   must be between 1 and 4 inclusive. For 160 MHz the index must be
    %   between 1 and 8 inclusive. The location of the primary 20 MHz
    %   subchannel and the preamble puncturing pattern determine the
    %   bandwidth value signaled in the HE-SIG-A field as defined in IEEE
    %   Std 802.11ax-2021, Table 27-20. See the documentation for valid
    %   preamble puncturing patterns given the location of the primary 20
    %   MHz subchannel. This property only applies when the RU allocation 
    %   is OFDMA and channel bandwidth is 80 or 160 MHz. The default is 1.
    PrimarySubchannel (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(PrimarySubchannel,1), mustBeLessThanOrEqual(PrimarySubchannel,8)} = 1;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as a numeric, positive
    %   integer scalar. The default is 1.
    NumTransmitAntennas (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(NumTransmitAntennas,1)} = 1;
    %PreHECyclicShifts Cyclic shift values for >8 transmit chains
    %   Specify the cyclic shift values for the pre-HE portion of the
    %   waveform, in nanoseconds for >8 transmit antennas as a row vector
    %   of length L = NumTransmitAntennas-8. The cyclic shift values must
    %   be between -200 and 0 inclusive. The first 8 antennas use the
    %   cyclic shift values defined in Table 21-10 of IEEE Std 802.11-2020.
    %   The remaining antennas use the cyclic shift values defined in this
    %   property. If the length of this row vector is specified as a value
    %   greater than L the object only uses the first L, PreHECyclicShifts
    %   values. For example, if you specify the NumTransmitAntennas
    %   property as 16 and this property as a row vector of length N>L, the
    %   object only uses the first L = 16-8 = 8 entries. This property
    %   applies only when you set the NumTransmitAntennas property to a
    %   value greater than 8. The default value of this property is -75.
    PreHECyclicShifts {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(PreHECyclicShifts,-200), mustBeLessThanOrEqual(PreHECyclicShifts,0)} = -75;
    %STBC Enable space-time block coding
    %   Set this property to true to enable space-time block coding in the
    %   data field transmission. In an HE-MU configuration STBC is only
    %   valid when all user are configured with a two space-time streams,
    %   DCM is not used, and all RUs are in a single-user configuration.
    %   The default is false.
    STBC (1,1) logical = false;
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) length in Microseconds
    %   as one of 0.8, 1.6 or 3.2. The default is 3.2.
    GuardInterval {wlan.internal.heValidateGI(GuardInterval)} = 3.2;
    %HELTFType Indicate HE-LTF compression mode of HE PPDU
    %   Specify the HE-LTF compression type as 2 or 4, corresponding to
    %   2x HE-LTF and 4x HE-LTF modes respectively. The default is 4.
    HELTFType (1,1) {mustBeNumeric, mustBeMember(HELTFType,[2 4])} = 4;
    %SIGBCompression Enable HE-SIG-B compression
    %   Set this property to true to enable HE-SIG-B compression for a full
    %   bandwidth 20 MHz MU-MIMO transmission. This property applies only
    %   for a 20 MHz channel bandwidth, when the RU allocation index is
    %   between 192 and 199 (inclusive). The default is true.
    SIGBCompression (1,1) logical = true;
    %SIGBMCS Indicates the MCS of the HE-SIG-B field
    %   Specify the modulation and coding scheme of the HE-SIG-B field as
    %   an integer scalar. The value must be an integer between 0 and 5,
    %   inclusive. The default is 0.
    SIGBMCS (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(SIGBMCS,0), mustBeLessThanOrEqual(SIGBMCS,5)} = 0;
    %SIGBDCM Indication that HE-SIG-B is modulated with DCM
    %   Set this property to true to indicate that HE-SIG-B is modulated
    %   with dual carrier modulation (DCM). DCM is only valid when SIGBMCS
    %   is 0, 1, 3 or 4. The default is false.
    SIGBDCM (1,1) logical = false;
    %UplinkIndication Indicates if the PPDU is sent on an uplink transmission
    %   Set this property to true to indicate that the PPDU is sent on an
    %   uplink transmission. The default is false which indicates a
    %   downlink transmission.
    UplinkIndication (1,1) logical = false;
    %BSSColor Basic service set (BSS) color identifier
    %   Specify the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default is 0.
    BSSColor (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(BSSColor,0), mustBeLessThanOrEqual(BSSColor,63)} = 0;
    %SpatialReuse Spatial reuse indication
    %   Specify the SpatialReuse as an integer scalar between 0 and 15,
    %   inclusive. The default is 0.
    SpatialReuse (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(SpatialReuse,0), mustBeLessThanOrEqual(SpatialReuse,15)} = 0;
    %TXOPDuration Duration information for TXOP protection
    %   Specify the TXOPDuration signaled in HE-SIG-A as an integer scalar
    %   between 0 and 127, inclusive. The TXOP field in HE-SIG-A is set
    %   directly to TXOPDuration, therefore a duration in microseconds must
    %   be converted before being used as specified in Table 27-20 of IEEE
    %   Std 802.11ax-2021. For more information see the documentation
    TXOPDuration (1,1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(TXOPDuration,0), mustBeLessThanOrEqual(TXOPDuration,127)} = 127;
    %HighDoppler High Doppler mode indication
    %   Set this property to true to indicate high doppler in HE-SIG-A. The
    %   default is false.
    HighDoppler (1,1) logical = false;
    %MidamblePeriodicity Midamble periodicity in number of OFDM symbols
    %   Specify HE-Data field midamble periodicity as 10 or 20 OFDM
    %   symbols. This property applies only when HighDoppler property is
    %   set to true. The default is 10.
    MidamblePeriodicity (1,1) {mustBeNumeric, mustBeMember(MidamblePeriodicity,[10 20])} = 10;
end

properties(SetAccess = 'private')
    %ChannelBandwidth Channel bandwidth (MHz) of HE-MU PPDU
    %   The channel bandwidth, specified as one of 'CBW20' | 'CBW40' |
    %   'CBW80' | 'CBW160'. This property is set when the object is created
    %   based on the defined AllocationIndex.
    ChannelBandwidth = 'CBW20';
    %AllocationIndex RU allocation index for each 20 MHz subchannel
    %   Specify the RU allocation index when creating the object. Once the
    %   object is created, AllocationIndex is read only. The allocation
    %   index defines the number and sizes of RUs, and the number of users
    %   assigned to each RU. Table 27-26 of IEEE Std 802.11ax-2021 defines
    %   the assignment index as an 8 bit index for each 20 MHz subchannel.
    %   The RU allocation for each assignment index can be viewed in
    %   the documentation.
    %
    %   AllocationIndex can be a vector of integers between 0 and 223, a
    %   string array, a character vector, or a cell array of character
    %   vectors.
    %
    %   When AllocationIndex is specified as a vector of integers, each
    %   element corresponds to an 8 bit index in Table 27-24. The length of
    %   AllocationIndex must be 1, 2, 4, or 8, defining the assignment for
    %   each 20 MHz subchannel in an 20 MHz, 40 MHz, 80 MHz or 160 MHz
    %   channel bandwidth, or for a full band allocation with a single RU,
    %   a scalar between 192 and 223.
    %
    %   AllocationIndex can also be specified using the corresponding 8-bit
    %   binary vector per allocation as specified in Table 27-24. An 8 bit
    %   binary sequence can be provided as a character vector or string. A
    %   string vector or cell array of character vectors can be used to
    %   specify an allocation per 20 MHz subchannel.
    %
    %   To configure an OFDMA transmission greater than 20 MHz,
    %   AllocationIndex consists of an assignment index for each 20 MHz
    %   subchannel. For example, to configure an 80 MHz OFDMA transmission,
    %   a numeric row vector with 4 allocation indices, or a string array
    %   with 4 elements is required. The AllocationIndex 113 signals the
    %   corresponding 20 MHz subchannel is punctured, and is only valid for
    %   an 80 MHz or 160 MHz transmission. The AllocationIndex 114 or 115
    %   signals an empty HE-SIG-B user specific field in the corresponding
    %   HE-SIG-B content channel is only valid when configured with other
    %   appropriate 484 or 996-tone RU assignment indices for an 80 MHz or
    %   160 MHz transmission.
    %
    %   To configure a full band MU-MIMO transmission with HE-SIG-B
    %   compression the following values of AllocationIndex can be used:
    %      20 MHz:  AllocationIndex = 191 + NumUsers
    %      40 MHz:  AllocationIndex = 199 + NumUsers
    %      80 MHz:  AllocationIndex = 207 + NumUsers
    %      160 MHz: AllocationIndex = 215 + NumUsers
    %   To configure a full bandwidth MU-MIMO transmission without HE-SIG-B
    %   compression, specify an allocation index for each 20 MHz
    %   subchannel. For a 20 MHz full-band MU-MIMO transmission, HE-SIG-B
    %   compression can be enabled or disabled using the SIGBCompression
    %   property.
    AllocationIndex = 192;
    %LowerCenter26ToneRU Lower center 26-tone RU allocation signaling
    %   Set this property to true using name-value pairs when the object is
    %   created to enable the lower frequency center 26-tone RU. After the
    %   object is created this property is read only. This property can be
    %   set to true only when the channel bandwidth is 80 MHz or 160 MHz
    %   and a full bandwidth allocation is not used. This property applies
    %   only when the RU allocation is appropriate. The default is false.
    LowerCenter26ToneRU (1,1) logical = false;
    %UpperCenter26ToneRU Upper center 26-tone RU allocation signaling
    %   Set this property to true using name-value pairs when the object is
    %   created to enable the upper frequency center 26-tone RU. After the
    %   object is created this property is read only. This property can be
    %   set to true only when the channel bandwidth is 160 MHz and a full
    %   bandwidth allocation is not used. This property applies only when
    %   the RU allocation is appropriate. The default is false.
    UpperCenter26ToneRU (1,1) logical = false;
end

properties(Access=private)
  PrivateUserRUNumber = 1;
end

methods
    function obj = wlanHEMUConfig(allocationIndex,varargin)
    %wlanHEMUConfig Create an HE-MU format configuration

        narginchk(1,Inf);

        % Determine allocation index given input
        if isstring(allocationIndex) || ischar(allocationIndex) || iscell(allocationIndex)
            if ischar(allocationIndex)
                % Single character array
                coder.internal.errorIf(numel(allocationIndex)~=8,'wlan:wlanHEMUConfig:IncorrectAllocationChar')
                allocationIndexUse = bin2dec(allocationIndex);
            elseif iscell(allocationIndex)
                % Cell array of character vectors
                n = numel(allocationIndex);
                allocationIndexUse = zeros(1,n);
                for i = 1:numel(allocationIndex)
                   val = allocationIndex{i};
                   coder.internal.errorIf(~ischar(val) || numel(val)~=8,'wlan:wlanHEMUConfig:IncorrectAllocationChar')
                   allocationIndexUse(i) = bin2dec(val);
                end
                % String or string array
            elseif isstring(allocationIndex)
                for i = 1:numel(allocationIndex)
                    coder.internal.errorIf(numel(char(allocationIndex(i)))~=8,'wlan:wlanHEMUConfig:IncorrectAllocationChar')
                end
                allocationIndexUse = bin2dec(allocationIndex);
            end
        else
            % Numeric
            allocationIndexUse = allocationIndex;
            validateattributes(allocationIndexUse,{'numeric'},{'integer'})
        end
        validateattributes(allocationIndexUse,{'numeric'},{'>=',0,'<=',223});
        obj.AllocationIndex = allocationIndexUse;

        % Process name-value pairs
        if nargin>1
            coder.internal.errorIf((mod(nargin-1,2) ~= 0),'wlan:ConfigBase:InvalidPVPairs');
            for i = 1:2:nargin-1
                coder.internal.errorIf(any(strcmp(varargin{i},{'RU','User'})),'wlan:wlanHEMUConfig:InvalidNameValue');
                obj.(char(varargin{i})) = varargin{i+1};
            end
        end
        obj.AllocationIndex = allocationIndexUse;
        center26 = [obj.LowerCenter26ToneRU obj.UpperCenter26ToneRU];
        [obj.RU,obj.User,obj.PrivateUserRUNumber] = heRUAllocation(obj.AllocationIndex,center26);
        if any(center26)
            punctureMask = wlan.internal.subchannelPuncturingPattern(allocationIndexUse);
            if any(punctureMask)
                % LowerCenter26ToneRU cannot be allocated if the adjacent subchannel is punctured
                coder.internal.errorIf(any(punctureMask(2:3)) && obj.LowerCenter26ToneRU,'wlan:wlanHEMUConfig:InvalidLowerCenter26ToneRUAllocation');
                if numel(punctureMask)>4 % 160 MHz
                    % UpperCenter26ToneRU cannot be allocated if the adjacent subchannel is punctured
                    coder.internal.errorIf(any(punctureMask(6:7)) && obj.UpperCenter26ToneRU,'wlan:wlanHEMUConfig:InvalidUpperCenter26ToneRUAllocation');
                end
            end
        end

        % Set channel bandwidth based on allocation index
        allocInfo = obj.ruInfo();
        if isscalar(allocationIndexUse) && allocInfo.NumRUs==1
            % Allow for a single number, full-band allocation
            switch allocInfo.RUSizes(1)
                case 242
                    obj.ChannelBandwidth = 'CBW20';
                case 484
                    obj.ChannelBandwidth = 'CBW40';
                case 996
                    obj.ChannelBandwidth = 'CBW80';
                case 2*996
                    obj.ChannelBandwidth = 'CBW160';
            end
        else
            switch numel(allocationIndexUse)
                case 1
                    obj.ChannelBandwidth = 'CBW20';
                case 2
                    obj.ChannelBandwidth = 'CBW40';
                case 4
                    obj.ChannelBandwidth = 'CBW80';
                case 8
                    obj.ChannelBandwidth = 'CBW160';
            end
        end
    end

    function varargout = validateConfig(obj,varargin)
    %validateConfig Validate the dependent properties of wlanHEMUConfig object
    %   validateConfig(obj) validates the dependent properties for the
    %   specified wlanHEMUConfig configuration object.
    %
    %   For INTERNAL use only, subject to future changes
    %
    %   validateConfig(CFG, MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'DataLocationLength'
    %       'HESIGB'
    %       'HELTFGI'
    %       'Coding'
    %       'Full'

        narginchk(1,2);
        nargoutchk(0,1);
        if nargin>1
            mode = varargin{1};
        else
            mode = 'Full';
        end

        switch mode
            case 'HESIGB' % wlanFieldIndices (HE-SIG-B)
                validateRUUserSpatialStreams(obj);
                validateHESIGB(obj);
            case 'HELTFGI' % wlanFieldIndices (HE-LTF)
                validateHELTFGI(obj);
            case 'DataLocationLength' % wlanFieldIndices (HE-Data and HE-LTF)
                s = validateMCSLengthTxTime(obj);
            case 'Coding' % wlanHEDataBitRecover
                validateCoding(obj);
            case 'CyclicShift' 
                % Validate PreHECyclicShifts against NumTransmitAntennas
                validatePreHECyclicShifts(obj);
            otherwise % wlanWaveformGenerator
                % Full object validation

                % Validate preamble puncturing
                validatePreamblePuncturing(obj.AllocationIndex,obj.PrimarySubchannel);

                % Validate Spatial mapping properties and spatial mapping matrix
                validateSpatialMapping(obj)

                % Validate HELTFType and GuardInterval for HE-LTF
                validateHELTFGI(obj);

                % Validate number STS per user/RU
                validateRUUserSpatialStreams(obj);

                % Validate SIGBDCM against SIGBMCS, and the number of HE-SIG-B
                % symbols
                validateHESIGB(obj);

                % Validate PreHECyclicShifts against NumTransmitAntennas
                validatePreHECyclicShifts(obj);

                % Validate MCS and length
                s = validateMCSLengthTxTime(obj);
        end

        if nargout == 1
            varargout{1} = s;
        end
    end

    function s = ruInfo(obj)
    %ruInfo Returns information relevant to the resource unit
    %   S = ruInfo(cfgHE) returns a structure, S, containing the resource
    %   unit (RU) allocation information for the wlanHEMUConfig object,
    %   cfgHE. The output structure S has the following fields:
    %
    %   NumUsers                 - Total number of users
    %   NumRUs                   - Total number of RUs
    %   RUIndices                - Vector containing the index of each RU
    %   RUSizes                  - Vector containing the size of each RU
    %   NumUsersPerRU            - Vector containing the number of users
    %                              per RU
    %   NumSpaceTimeStreamsPerRU - Vector containing the total number of
    %                              space-time streams per RU
    %   PowerBoostFactorPerRU    - Vector containing the power boost factor
    %                              per RU
    %   RUNumbers                - Vector containing the index of the
    %                              corresponding cfgHE.RU object for
    %                              each active RU.   
    %   RUAssigned               - Indicate assigned RUs

        numRUs = numel(obj.RU);
        numUsers = numel(obj.User);
        ruActive = true(1,numRUs);
        for j = 1:numUsers
           if (obj.User{j}.APEPLength==0 || obj.User{j}.STAID==2046)
               % If APEP length is 0 or STAID is 2046 then RU is inactive
               ruNum = obj.User{j}.RUNumber;
               if ruNum<=numRUs
                   ruActive(ruNum) = false;
               end
           end
        end
        ruIndices = zeros(1,numRUs);
        ruSizes = zeros(1,numRUs);
        ruNumbers = zeros(1,numRUs);
        numSTS = zeros(1,numRUs);
        powerBoostFactor = zeros(1,numRUs);
        numUsersPerRU = zeros(1,numRUs);

        k = 1;
        for i = 1:numRUs
            for j = 1:numUsers
                ruShared = i==obj.PrivateUserRUNumber(j);
                if ruShared
                    numUsersPerRU(k) = numUsersPerRU(k)+1;
                    numSTS(k) = numSTS(k)+obj.User{j}.NumSpaceTimeStreams;
                end
            end
            ruIndices(k) = obj.RU{i}.Index;
            ruSizes(k) = obj.RU{i}.Size;
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

    function psduLength = getPSDULength(obj)
    %getPSDULength Returns PSDU length for the configuration
    %   Returns a row vector with the required PSDU length for each user.
    %   Ref: IEEE Std 802.11ax-2021, Section 27.4.3.

        validateSTAID(obj); % Validate STAID 2046
        psduLength = wlan.internal.hePLMETxTimePrimative(obj);
    end
    
    function n = getNumPostFECPaddingBits(obj)
    %getNumPostFECPaddingBits Required number of post-FEC padding bits
    %   Returns a vector with the required number of post-FEC padding bits
    %   for each user.
        [~,userCodingParams] = wlan.internal.heCodingParameters(obj);
        n = [userCodingParams.NPADPostFEC].*[userCodingParams.mSTBC];
    end

    function format = packetFormat(obj) %#ok<MANU>
    %packetFormat Returns the packet format
    %   Returns the packet format as a character vector.

        format = 'HE-MU';
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
        [~,t] = wlan.internal.hePLMETxTimePrimative(obj);
        t = t*1e-3; % convert nanoseconds to microseconds
        t = wlan.internal.convertTransmitTime(t,varargin{:});
    end

    function obj = set.RU(obj,value)
    % Validate RU property is a cell array of wlanHEMURU objects

        validateattributes(value,{'cell'},{'nonempty'},mfilename,'RU');

        numInp = numel(value);
        % Validate expected number of RU objects
        if coder.target('MATLAB') && numel(obj.RU)~=numInp && numel(obj.RU)~=0
            coder.internal.error('wlan:shared:InvalidRU',numel(obj.RU),'wlanHEMURU');
        end

        for i = 1:numInp
            coder.internal.errorIf(~isa(value{i},'wlanHEMURU'),'wlan:shared:InvalidRU',numInp,'wlanHEMURU');
        end
        obj.RU = value;
    end

    function obj = set.User(obj,value)
    % Validate User property is a cell array of wlanHEMUUser objects

        validateattributes(value,{'cell'},{'nonempty'},mfilename,'User');

        numInp = numel(value);
        % Validate expected number of User objects
        if coder.target('MATLAB') && numel(obj.User)~=numInp && numel(obj.User)~=0
            coder.internal.error('wlan:shared:InvalidUser',numel(obj.User),'wlanHEMUUser');
        end

        for i = 1:numInp
            coder.internal.errorIf(~isa(value{i},'wlanHEMUUser'),'wlan:shared:InvalidUser',numInp,'wlanHEMUUser');
        end
        obj.User = value;
    end
    
    function showAllocation(obj,varargin)
    %showAllocation Shows the RU allocation
    %   showAllocation(cfgHE) shows the RU allocation for an HE-MU format
    %
    %   showAllocation(cfgHE,AX) shows the allocation in the axes specified
    %   by AX instead of in the current axes. If AX is not specified,
    %   showAllocation plots the allocation in a new figure.

        wlan.internal.hePlotAllocation(obj,varargin{:});
    end
end

methods (Access = private)
   function validateHELTFGI(obj)
    %validateHELTFGI Validate the HELTF type and GuardInterval of wlanHEMUConfig object
    %   Validated property-subset includes:
    %     HELTFType, GuardInterval, DCM, STBC, HighDoppler

        % Validate GuardInterval and HELTFType
        coder.internal.errorIf(~(obj.HELTFType==2) && obj.GuardInterval==1.6,'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);
        coder.internal.errorIf(~(obj.HELTFType==4) && obj.GuardInterval==3.2,'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);

        % Validate HighDoppler
        S = obj.ruInfo;
        coder.internal.errorIf(obj.HighDoppler && any(S.NumSpaceTimeStreamsPerRU>4),'wlan:he:InvalidHighDoppler');
   end

   function validateHESIGB(obj)
    %validateHESIGB Validate HE-SIG-B related properties of wlanHEMUConfig object
    %   Validated property-subset includes:
    %     SIGBDCM, SIGBMCS

        % Validate SIGBDCM against SIGBMCS (Table 27-19)
        coder.internal.errorIf(any(obj.SIGBMCS==[2 5]) && obj.SIGBDCM,'wlan:he:InvalidSIGBDCM');
   end

    function validateSpatialMapping(obj)
        %validateSpatialMapping Validate the spatial mapping properties
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumTransmitAntennas, NumSpaceTimeStreams,
        %     SpatialMapping, SpatialMappingMatrix

        % Validate SpatialMappingMatrix, SpatialMapping and the number of
        % transmit antennas
        infoRUs = ruInfo(obj);
        for i = 1:infoRUs.NumRUs
            if ~infoRUs.RUAssigned(i)
                continue
            end
            % NumTx and Nsts: numTx cannot be less than sum(Nsts)
            coder.internal.errorIf(obj.NumTransmitAntennas < infoRUs.NumSpaceTimeStreamsPerRU(i),'wlan:he:NumSTSLargerThanNumTx',infoRUs.RUIndices(i),infoRUs.NumSpaceTimeStreamsPerRU(i),obj.NumTransmitAntennas);
            if strcmp(obj.RU{i}.SpatialMapping,'Custom')
                % Validate spatial mapping matrix
                wlan.internal.validateSpatialMappingMatrix(obj.RU{i}.SpatialMappingMatrix,obj.NumTransmitAntennas,infoRUs.NumSpaceTimeStreamsPerRU(i),infoRUs.RUSizes(i),i);
            else
                coder.internal.errorIf(strcmp(obj.RU{i}.SpatialMapping,'Direct') && infoRUs.NumSpaceTimeStreamsPerRU(i)~= obj.NumTransmitAntennas,'wlan:he:NumSTSNotEqualNumTxDirectMap',i,infoRUs.NumSpaceTimeStreamsPerRU(i),obj.NumTransmitAntennas);            
            end
        end
    end

    function s = validateMCSLength(obj)
    %   validateMCSLength Length properties for wlanHEMUConfig
    %   configuration object
    %   Validated property-subset includes:
    %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, GuardInterval, APEPLength

        % Validate coding related properties
        validateCoding(obj);

        [psduLength,txTime,commonCodingParams] = wlan.internal.hePLMETxTimePrimative(obj);
        sf = 1e3; % Scaling factor to convert time from ns to us
        % Set output structure
        s = struct( ...
            'NumDataSymbols', commonCodingParams.NSYM, ...
            'TxTime', txTime/sf, ... % TxTime in us
            'PSDULength', psduLength);
    end

    function s = validateMCSLengthTxTime(obj)
    %   validateMCSLengthTxTime Validate length properties and resultant
    %   transmit time for wlanHEMUConfig configuration object
    %   Validated property-subset includes:
    %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, GuardInterval, APEPLength

        s = validateMCSLength(obj);

        % Validate txTime (max 5.484ms for HE MU format)
        coder.internal.errorIf(s.TxTime>5484,'wlan:shared:InvalidPPDUDuration',round(s.TxTime),5484);
    end

    function validateCoding(obj)
    %   validateCoding Validate coding properties for wlanHEMUConfig 
    %   configuration object
    %   Validated property-subset includes:
    %     ChannelBandwidth, NumUsers, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, RU Size, STAID

        % Validate ChannelCoding, DCM and STBC, and the number of
        % space-time streams for all users

        infoRUs = ruInfo(obj);

        for userIdx = 1:numel(obj.User)
            if strcmp(obj.User{userIdx}.ChannelCoding,'BCC')
                coder.internal.errorIf(obj.RU{obj.User{userIdx}.RUNumber}.Size>242,'wlan:shared:InvalidBCCRUSize');
                coder.internal.errorIf(obj.User{userIdx}.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS');
                coder.internal.errorIf(any(obj.User{userIdx}.MCS==[10 11]),'wlan:he:InvalidMCS');
            end

            % Validate MCS, DCM and STBC
            coder.internal.errorIf(obj.User{userIdx}.DCM && (numel(obj.RU{obj.User{userIdx}.RUNumber}.UserNumbers)>1 || ~any(obj.User{userIdx}.MCS == [0 1 3 4]) || obj.STBC || obj.User{userIdx}.NumSpaceTimeStreams>2),'wlan:he:InvalidDCM');

            % Validate STBC and NumSpaceTimeStreams
            coder.internal.errorIf(obj.STBC && (obj.User{userIdx}.NumSpaceTimeStreams~=2 || any(infoRUs.NumUsersPerRU>1)),'wlan:he:MUNumSTSWithSTBC');
        end

        validateSTAID(obj);
    end
    
    function validateSTAID(obj)
    %   validateSTAID Validate at least one user is active
    %
    %   Validated property: STAID

        % Validate STAID is not 2046 for all users
        userActive = true(1,numel(obj.User)); % Vector indicating if a user object is active
        for userIdx = 1:numel(obj.User)
            if obj.User{userIdx}.STAID==2046
                % If STAID is 2046 in a MU-MIMO RU, then error
                coder.internal.errorIf(numel(obj.RU{obj.User{userIdx}.RUNumber}.UserNumbers)>1,'wlan:shared:InactiveUserInMU');

                % If STAID is 2046, then RU carries no data, and user is
                % inactive.
                userActive(userIdx) = false;
            end
        end

        % Make sure at least one of the users is active
        numActiveUsers = sum(userActive==true);
        coder.internal.errorIf(numActiveUsers==0,'wlan:shared:NoActiveUsers');
    end

    function validateRUUserSpatialStreams(obj)
    %   validateRUUserSpatialStreams Space-time streams per user per RU for
    %   wlanHEMUConfig configuration object
    %   Validated property-subset includes:
    %     NumSpaceTimeStreams, User, RU
        userIdx = 1;
        for i = 1:numel(obj.RU)
            numSTSPerUser = zeros(numel(obj.RU{i}.UserNumbers),1);
            for j = 1:numel(obj.RU{i}.UserNumbers)
                numSTSPerUser(j) = obj.User{userIdx}.NumSpaceTimeStreams;
                userIdx = userIdx+1;
            end
            % Validate, number of space time streams in a MU-MIMO RU
            validateNumSpaceTimeStreamsPerRU(numSTSPerUser,i);
        end
    end
    
    function validatePreHECyclicShifts(obj)
    %   validatePreHECyclicShifts Validate PreHECyclicShifts values against
    %   NumTransmitAntennas
    %   Validated property-subset includes:
    %     PreHECyclicShifts, NumTransmitAntennas

        numTx = obj.NumTransmitAntennas;
        csh = obj.PreHECyclicShifts;
        if numTx>8
            coder.internal.errorIf(~(numel(csh)>=numTx-8),'wlan:shared:InvalidCyclicShift','PreHECyclicShifts',numTx-8);
        end
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = false;
        if strcmp(prop,'LowerCenter26ToneRU')
            % Hide LowerCenter26ToneRU
            flag = ~wlan.internal.heLowerCenter26ToneRUActive(obj.AllocationIndex);
        elseif strcmp(prop,'UpperCenter26ToneRU')
            % Hide LowerCenter26ToneRU
            flag = ~wlan.internal.heUpperCenter26ToneRUActive(obj.AllocationIndex);
        elseif strcmp(prop,'MidamblePeriodicity')
            % Hide MidamblePeriodicity when HighDoppler is not set
            flag = obj.HighDoppler == 0;
        elseif strcmp(prop,'SIGBCompression')
            % Hide SIGBCompression for AllocationIndex >199
            if numel(obj.AllocationIndex)>1
                flag = true;
            else
                flag = ~(obj.AllocationIndex>=192 && obj.AllocationIndex<=199);
            end
        elseif strcmp(prop,'PreHECyclicShifts')
            % Hide PreHECyclicShifts when NumTransmitAntennas <=8
            flag = obj.NumTransmitAntennas<=8;
        elseif strcmp(prop,'PrimarySubchannel')
            % Hide PrimarySubchannel for 20/40 MHz or full allocation
            % for 80/160 MHz
            flag = any(strcmp(obj.ChannelBandwidth,{'CBW20','CBW40'})) || numel(obj.AllocationIndex)==1;
        end
    end
end

end

function [ru,user,userRUNumber] = heRUAllocation(allocationIndex,varargin)
    % Returns a cell array of RUs, Users and the user RU numbers given the
    % allocation
    s = wlan.internal.heAllocationInfo(allocationIndex,varargin{:});
    numRUs = s.NumRUs;
    numUsers = s.NumUsers;

    Usertmp = cell(1,numUsers);
    RUtmp = cell(1,numRUs);
    userIdx = 1;
    userRUNumber = zeros(1,numUsers);
    for i = 1:numRUs
        ruUserNumber = zeros(1,s.NumUsersPerRU(i));
        for j = 1:s.NumUsersPerRU(i)
            userRUNumber(userIdx) = i;
            ruUserNumber(j) = userIdx;
            userIdx = userIdx+1;
        end

        % Use round to deal with invalid combos which can give a
        % non-integer RUindices.
        RUtmp{i} = wlanHEMURU(s.RUSizes(i),round(s.RUIndices(i)),ruUserNumber);
    end

    for u = 1:numUsers
        Usertmp{u} = wlanHEMUUser(userRUNumber(u),'PostFECPaddingSeed',u);
    end

    user = Usertmp;
    ru = RUtmp;
end

function validateNumSpaceTimeStreamsPerRU(nsts,i)
    % Validate the number of space-time streams per user in a MU-MIMO
    % configuration according to IEEE Std 802.11ax-2021, Table 27-29

    % Validate the number of space-time streams specified per used, by
    % using the validation flag with heSpatialConfigurationBits.
    wlan.internal.heSpatialConfigurationBits(nsts,i);
end

function validatePreamblePuncturing(allocationIndex,primaryChIndex)
    % Validate AllocationIndex for preamble puncturing
    punctureMask = wlan.internal.subchannelPuncturingPattern(allocationIndex);

    if any(punctureMask) && numel(punctureMask)>=4 % Preamble puncturing is only applicable to 80 MHz or 160 MHz
        punctureFlag = any((find(punctureMask==1)==primaryChIndex));
        if numel(punctureMask)==4 % 80 MHz
            coder.internal.errorIf(primaryChIndex>4,'wlan:wlanHEMUConfig:InvalidPrimarySubchannel',4,80);
            coder.internal.errorIf(any(primaryChIndex==1:4 & ...
                [(punctureMask(2) && any(punctureMask(3:4))) (punctureMask(1) && any(punctureMask(3:4))), ...
                 (punctureMask(4) && any(punctureMask(1:2))) (punctureMask(3) && any(punctureMask(1:2)))] | ...
                [all(punctureMask(3:4)) all(punctureMask(3:4)) all(punctureMask(1:2)) all(punctureMask(1:2))]) || ...
                  punctureFlag,'wlan:wlanHEMUConfig:IncorrectPuncturing80MHz');
        else % 160 MHz
            coder.internal.errorIf(any(primaryChIndex==1:8 & ...
                [punctureMask(2) punctureMask(1) any(punctureMask(1:2)) any(punctureMask(1:2)) punctureMask(6) punctureMask(5) any(punctureMask(5:6)) any(punctureMask(5:6))] & ...
                [any(punctureMask(3:4)) any(punctureMask(3:4)) punctureMask(4) punctureMask(3) any(punctureMask(7:8)) any(punctureMask(7:8)) punctureMask(8) punctureMask(7)]) || punctureFlag, ...
                'wlan:wlanHEMUConfig:IncorrectPuncturing160MHz');
        end
    end
end

