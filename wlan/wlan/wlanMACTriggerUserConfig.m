classdef wlanMACTriggerUserConfig < comm.internal.ConfigBase
%wlanMACTriggerUserConfig Create configuration object for User Info field
%of a MAC trigger frame.
%   CONFIG = wlanMACTriggerUserConfig creates an object to configure the
%   User Info field of a WLAN MAC trigger frame.
%
%   CONFIG = wlanMACTriggerUserConfig(Name=Value) creates an object,
%   CONFIG, to configure User Info field of a WLAN MAC trigger frame with
%   the specified property Name set to the specified Value. You can specify
%   additional name-value arguments in any order as (Name1=Value1, ...,
%   NameN=ValueN).
%
%   wlanMACTriggerUserConfig properties:
%   TriggerType              - Type of trigger frame
%   AID12                    - Identifier for User Info field
%   RUAllocationRegion       - Indicate RU allocation region in 80+80 MHz
%                              or 160 MHz channel
%   RUSize                   - Resource unit (RU) size
%   RUIndex                  - Resource unit index
%   ChannelCoding            - Forward error correction (FEC) coding type
%   MCS                      - Modulation and coding scheme (MCS)
%   DCM                      - Dual carrier modulation (DCM)
%   StartingSpatialStream    - Starting spatial stream
%   NumSpatialStreams        - Number of spatial streams
%   NumRARU                  - Number of contiguous random access RUs
%                              (RA-RUs) allocated
%   MoreRARU                 - Indicate RA-RUs in subsequent trigger frames
%   UseMaxTransmitPower      - Transmit response at maximum power for the
%                              assigned MCS
%   TargetRSSI               - Expected receive signal power
%   MPDUMUSpacingFactor      - Factor by which minimum MPDU start spacing
%                              is multiplied
%   TIDAggregationLimit      - Maximum number of TIDs that can be
%                              aggregated by a station
%   PreferredAC              - Lowest access category (AC) recommended for
%                              aggregation
%   TID                      - Traffic identifier (TID)
%   StartingSequenceNum      - Starting MSDU/A-MSDU sequence number

%   Copyright 2020-2025 The MathWorks, Inc.

%#codegen

properties
    %TriggerType Type of Trigger frame
    %   Specify the frame type as one of 'Basic' | 'MU-RTS' | 'MU-BAR'. The
    %   default value is 'Basic'.
    TriggerType = 'Basic';

    %AID12 Identifier for User Info field
    %   Specify the AID12 value as an integer in the interval [0, 2007],
    %   2045, or 2046. This property indicates the station's association ID
    %   (AID) value if the value is a number between 1 and 2007, inclusive.
    %   A value of 0 indicates that this User Info field allocates
    %   contiguous RA-RUs for associated stations. A value of 2045
    %   indicates that this User Info field allocates one or more
    %   contiguous RA-RUs for the unassociated stations. A value of 2046
    %   indicates that this User Info field identifies an unallocated RU.
    %   The default value is 1.
    AID12 (1, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeValidAID(AID12)} = 1;

    %RUAllocationRegion Indicate RU allocation region in 80+80 MHz or
    %160 MHz channel
    %   Specify the RU allocation region as 'primary 80MHz' or 'secondary
    %   80MHz'. This property applies only when RUSize is not 1992 and when
    %   you set the ChannelBandwidth property in wlanMACTriggerConfig to
    %   'CBW80+80 or CBW160'. The default value is 'primary 80MHz'.
    RUAllocationRegion = 'primary 80MHz';

    %RUSize Resource unit size
    %   Specify the size of the RU as one of these values 26, 52, 106, 242,
    %   484, 996 and 1992 (2x996). The default value of this property is
    %   242.
    RUSize (1, 1) {mustBeNumeric, mustBeInteger, mustBeMember(RUSize,[26 52 106 242 484 996 1992])} = 242;

    %RUIndex Resource unit index
    %   Specify the RU index as an integer in the range [1, 37]. The RU
    %   index specifies the location of the RU within the channel. For
    %   example, in an 80 MHz transmission there are four possible 242 tone
    %   RUs, one in each 20 MHz subchannel. RU# 242-1 (size 242, index 1)
    %   is the RU occupying the lowest absolute frequency within the 80
    %   MHz, and RU# 242-4 (size 242, index 4) is the RU occupying the
    %   highest absolute frequency. For a 160 MHz transmission, this RU
    %   index value corresponds to the 80 MHz segment indicated by
    %   RUAllocationRegion. Refer to table 9-29c of IEEE Std 802.11ax-2021.
    %   The default value is 1.
    RUIndex (1, 1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(RUIndex,1), mustBeLessThanOrEqual(RUIndex,37)} = 1;

    %ChannelCoding FEC coding type of HE TB PPDU response
    %   Specify the FEC coding type as one of 'BCC' | 'LDPC'. The default
    %   value is 'LDPC'.
    ChannelCoding = 'LDPC';

    %MCS Modulation and coding scheme in HE TB PPDU response
    %   Specify the MCS as an integer in the range [0, 11]. When you set
    %   the DCM property to true, only MCS values 0,1,3, and 4 are allowed.
    %   The default value is 0.
    MCS (1, 1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(MCS,11)} = 0;

    %DCM Dual carrier modulation in HE TB PPDU response
    %   Set this property to true to indicate that the HE TB PPDU response
    %   uses dual carrier modulation. For frame generation, this property
    %   must be set to false when you set STBC to true in the
    %   wlanMACTriggerConfig. The default value is false.
    DCM (1, 1) logical = false;

    %StartingSpatialStream Starting spatial stream
    %   Specify the starting spatial stream as an integer in the range [1,
    %   8]. This property applies only when AID12 is any value other than 0
    %   or 2045. The default value is 1.
    StartingSpatialStream (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBePositive, mustBeLessThanOrEqual(StartingSpatialStream,8)} = 1;

    %NumSpatialStreams Number of spatial streams
    %   Specify the number of spatial streams as an integer in the range
    %   [1,8]. This property applies only when AID12 is any value other
    %   than 0 or 2045. The default value is 1.
    NumSpatialStreams (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBePositive, mustBeLessThanOrEqual(NumSpatialStreams,8)} = 1;

    %NumRARU Number of contiguous RA-RUs allocated
    %   Specify the number of contiguous RA-RUs allocated as an integer in
    %   the range [1, 32]. This property applies only when AID12 is either
    %   0 or 2045. The default value is 1.
    NumRARU (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBePositive, mustBeLessThanOrEqual(NumRARU,32)} = 1;

    %MoreRARU Indicate RA-RUs in subsequent trigger frames
    %   Set this property to true to indicate more RA-RU allocations in
    %   subsequent trigger frames. This property applies only when you set
    %   the MoreTF property to true in the wlanMACTriggerConfig and AID12
    %   to either 0 or 2045. The default value is false.
    MoreRARU (1, 1) logical = false;

    %UseMaxTransmitPower Transmit response at maximum power for the
    %assigned MCS
    %   Set this property to true to indicate the receiving station to
    %   transmit the response HE TB PPDU at its maximum transmit power for
    %   the assigned HE MCS value. The default value is true.
    UseMaxTransmitPower (1, 1) logical = true;

    %TargetRSSI Expected receive signal power
    %   Specify the expected receive signal power as an integer in the
    %   range [-110, -20], in dBm. This property indicates expected receive
    %   signal power, measured at the AP's antenna connector and averaged
    %   over the antennas, for the HE portion of the HE TB PPDU transmitted
    %   on the assigned RU. This property applies only when
    %   UseMaxTransmitPower is set to false and refers to the UL Target
    %   Receive Power subfield in trigger frame. The default value is -110.
    TargetRSSI (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBeLessThanOrEqual(TargetRSSI,-20), mustBeGreaterThanOrEqual(TargetRSSI,-110)} = -110;

    %MPDUMUSpacingFactor Factor by which minimum MPDU start spacing is
    %multiplied
    %   Specify the value to multiply with minimum MPDU start spacing as an
    %   integer in the range [0, 3]. This property applies only when you
    %   set the TriggerType property to 'Basic'. The default value is 0.
    MPDUMUSpacingFactor (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBeNonnegative, mustBeLessThanOrEqual(MPDUMUSpacingFactor,3)} = 0;

    %TIDAggregationLimit Maximum number of TIDs that can be aggregated
    %by a station
    %   Specify the maximum number of TIDs that can be aggregated as an
    %   integer in the range [0, 7]. This property applies only when you
    %   set the TriggerType property to 'Basic'. The default value of this
    %   property is 0.
    TIDAggregationLimit (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBeNonnegative, mustBeLessThanOrEqual(TIDAggregationLimit,7)} = 0;

    %PreferredAC Lowest AC recommended for aggregation
    %   Specify the lowest AC recommended for aggregation of MPDUs in the
    %   A-MPDU contained in the HE TB PPDU response as an integer in the
    %   range [0, 3]. This property applies only when you set the
    %   TriggerType property to 'Basic'. The default value of this property
    %   is 0.
    PreferredAC (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBeNonnegative, mustBeLessThanOrEqual(PreferredAC,3)} = 0;

    %TID Traffic identifier
    %   Set the traffic identifier as an integer in the range [0, 7]. This property
    %   applies only when you set the TriggerType property to 'MU-BAR'. The
    %   default value is 0.
    TID (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBeNonnegative, mustBeLessThanOrEqual(TID,7)} = 0;

    %StartingSequenceNum Starting MSDU/A-MSDU sequence number
    %   Specify the starting sequence number as an integer in the range [0,
    %   4095]. This property applies only when TriggerType property is set
    %   to 'MU-BAR'. The default value is 0.
    StartingSequenceNum (1, 1) {mustBeNumeric, mustBeInteger, ...
        mustBeNonnegative, mustBeLessThanOrEqual(StartingSequenceNum,4095)} = 0;
end

properties (Hidden)
    %UserInfoVariant Specify the variant of the user info field
    %   Specify the variant of the User Info field in the Trigger frame. When
    %   'TriggerType' is specified as 'MU-RTS', acceptable values are 'HE',
    %   'EHT', and 'Special'. Otherwise, acceptable value is 'HE'. The
    %   default is 'HE'.
    UserInfoVariant = 'HE';

    %PS160 Specify the value of PS160 bit
    %   Specify the value of the PS160 bit in the EHT variant user info field.
    %   This property indicates the channel bandwidth in which the CTS response
    %   to MU-RTS is solicited. A value of 0 indicates primary 20, 40, 80 or
    %   160 MHz. A value of 1 indicates 320 MHz. This property is applicable
    %   when you set the UserInfoVariant to 'EHT', and 'TriggerType' is specified
    %   as 'MU-RTS'. The default is 0.
    PS160 = 0;

    %ULBandwidthExtension Specify the value of uplink bandwidth extension
    %subfield
    %   Specify the value of uplink bandwidth extension subfield in special
    %   user info field, as an integer in the range [0,3]. This property is
    %   applicable when you set the UserInfoVariant to 'Special' and
    %   'TriggerType' is specified as 'MU-RTS'. The default is 0.
    ULBandwidthExtension (1, 1) {mustBeMember(ULBandwidthExtension,[0, 1, 2, 3])} = 0;
end

properties (Hidden, Constant)
    TriggerType_Values = {'Basic', 'MU-BAR', 'MU-RTS'}
    RUAllocationRegion_Values = {'primary 80MHz', 'secondary 80MHz'}
    ChannelCoding_Values = {'BCC', 'LDPC'}
end

methods(Access = protected)
    function flag = isInactiveProperty(obj, prop)
        % Present in all trigger variants
        switch prop
            case {'TriggerType', 'AID12', 'RUSize', 'RUIndex'}
                flag = false;
            case 'RUAllocationRegion'
                flag = strcmp(obj.TriggerType, 'MU-RTS') || (obj.RUSize == 1992);
            case {'ChannelCoding', 'MCS', 'DCM', 'UseMaxTransmitPower', 'TargetRSSI'}
                flag = strcmp(obj.TriggerType, 'MU-RTS') || (obj.AID12 == 2046);
                if ~flag && strcmp(prop, 'TargetRSSI')
                    flag = obj.UseMaxTransmitPower;
                end
                % Not applicable for MU-RTS trigger variant and for other variants
                % when AID is 0 or 2045
            case {'StartingSpatialStream', 'NumSpatialStreams'}
                flag = (strcmp(obj.TriggerType, 'MU-RTS')) || any(obj.AID12 == [0, 2045, 2046]);
                % Not applicable for MU-RTS trigger variant and for other variants
                % applicable when AID is not 0 or 2045
            case {'NumRARU', 'MoreRARU'}
                flag = (strcmp(obj.TriggerType, 'MU-RTS')) || ~any(obj.AID12 == [0, 2045]);
                % Applicable only for MU-BAR
            case {'MPDUMUSpacingFactor', 'TIDAggregationLimit', 'PreferredAC'}
                flag = ~strcmp(obj.TriggerType, 'Basic') || (obj.AID12 == 2046);
            otherwise % {'TID', 'StartingSequenceNum'}
                flag = ~strcmp(obj.TriggerType, 'MU-BAR') || (obj.AID12 == 2046);
                % Applicable only for Basic trigger
        end
    end
end

methods
    function obj = wlanMACTriggerUserConfig(varargin)
        obj@comm.internal.ConfigBase('TriggerType', 'Basic', ...
            'RUAllocationRegion', 'primary 80MHz', ...
            'ChannelCoding', 'LDPC', ...
            varargin{:});
    end

    function obj = set.TriggerType(obj, value)
        value = validatestring(value, obj.TriggerType_Values, 'wlanMACTriggerUserConfig', 'TriggerType');
        obj.TriggerType = '';
        obj.TriggerType = value;
    end

    function obj = set.RUAllocationRegion(obj, value)
        value = validatestring(value, obj.RUAllocationRegion_Values, 'wlanMACTriggerUserConfig', 'RUAllocationRegion');
        obj.RUAllocationRegion = '';
        obj.RUAllocationRegion = value;
    end

    function obj = set.ChannelCoding(obj, value)
        value = validatestring(value, obj.ChannelCoding_Values, 'wlanMACTriggerUserConfig', 'ChannelCoding');
        obj.ChannelCoding = '';
        obj.ChannelCoding = value;
    end

    function validateConfig(obj)
        % validateConfig Validate the wlanMACTriggerUserConfig object
        %
        %   validateConfig(OBJ) validates the dependent properties for the
        %   specified wlanMACTriggerUserConfig configuration object.

        %   For INTERNAL use only, subject to future changes.

        if ~strcmp(obj.TriggerType, 'MU-RTS')
            % Refer to section 27.3.7 of IEEE Std 802.11ax-2021
            coder.internal.errorIf(((obj.AID12 ~= 2046) && obj.DCM && ~any(obj.MCS == [0, 1, 3, 4])), 'wlan:wlanMACTriggerUserConfig:InvalidULMCS', obj.MCS);

            if ~any(obj.AID12 == [0, 2045, 2046])
                % Validate StartingSpatialStream and NumSpatialStreams
                numSTS = obj.StartingSpatialStream+obj.NumSpatialStreams-1;
                coder.internal.errorIf(numSTS > 8, 'wlan:wlanMACTriggerUserConfig:InvalidStartingSpatialStream');
            end
        end

        % Random access RU
        isRARUUserInfo = any(obj.AID12 == [0, 2045]);
        % AID12 values 0 and 2045 are only applicable for Basic, BQRP and
        % BSRP frames. Refer to section 26.5.4.1 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(isRARUUserInfo && any(strcmp(obj.TriggerType, {'MU-RTS', 'MU-BAR'})), 'wlan:wlanMACTriggerUserConfig:InvalidAIDTriggerType');
        % Refer to section 26.5.2.3.3 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(isRARUUserInfo && (obj.NumSpatialStreams ~= 1), 'wlan:wlanMACTriggerUserConfig:InvalidRARUNumSpatialStreams');
        % Refer to section 26.5.2.3.3 of IEEE Std 802.11ax-2021
        coder.internal.errorIf(isRARUUserInfo && (obj.StartingSpatialStream ~= 1), 'wlan:wlanMACTriggerUserConfig:InvalidRARUStartingSpatialStream');
        % RU allocation code values 61-69 are applicable for MU-RTS, which
        % correspond to RU sizes 242, 484, 996, 1992, 3984. Refer to section
        % 9.3.1.22.5 of IEEE Std 802.11ax-2021, and IEEE P802.11be/D5.0.
        coder.internal.errorIf(strcmp(obj.TriggerType, 'MU-RTS') && any(obj.RUSize == [26 52 106]), ...
            'wlan:wlanMACTriggerUserConfig:InvalidMURTSRUSize',obj.RUSize);
    end
end

end

function mustBeValidAID(AID)
    %mustBeValidAID Validate AID12
    coder.internal.errorIf((AID > 2046) || ((AID > 2007) && (AID < 2045)),'wlan:wlanMACTriggerUserConfig:InvalidAID12');
end

