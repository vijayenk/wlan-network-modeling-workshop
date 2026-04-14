classdef wlanMACFrameConfig < comm.internal.ConfigBase
%wlanMACFrameConfig Create a MAC frame configuration object
%   CONFIG = wlanMACFrameConfig creates a WLAN MAC frame configuration
%   object.
%
%   CONFIG = wlanMACFrameConfig(Name=Value) creates a WLAN MAC frame
%   configuration object, CONFIG, with the specified property Name set to
%   the specified Value. You can specify additional name-value arguments in
%   any order as (Name1=Value1, ...,NameN=ValueN).
%
%   wlanMACFrameConfig properties:
%
%   FrameType                      - Type of MAC frame
%   FrameFormat                    - Format of MAC frame
%   ToDS                           - Frame destined to distribution system (DS)
%   FromDS                         - Frame exiting DS
%   Retransmission                 - Frame is being retransmitted
%   PowerManagement                - Power management mode
%   MoreData                       - More data indication
%   ProtectedFrame                 - Protected frame indication
%   HTControlPresent               - HTControl field included in the frame
%   Duration                       - Estimated time (in microseconds) to
%                                    transmit the pending frames after this
%                                    frame
%   Address1                       - Receiver address
%   Address2                       - Transmitter address
%   Address3                       - Basic service set identifier, destination
%                                    address, or source address
%   Address4                       - Source address or basic service set
%                                    identifier
%   SequenceNumber                 - Frame sequence number
%   TID                            - Traffic identifier
%   AckPolicy                      - Acknowledgment policy
%   HTControl                      - HT Control field of MAC header
%   MSDUAggregation                - Form A-MSDUs using MSDU aggregation
%   MPDUAggregation                - Form A-MPDU using MPDU Aggregation
%   AMSDUDestinationAddress        - Destination address (DA) or mesh DA
%                                    for all A-MSDU subframes
%   AMSDUSourceAddress             - Source address (SA) or mesh SA for all
%                                    A-MSDU subframes
%   MinimumMPDUStartSpacing        - Minimum spacing between the start of
%                                    MPDUs in an A-MPDU
%   BlockAckBitmap                 - Block Ack Bitmap
%   MinTriggerProcessTime          - Minimum time required for processing
%                                    trigger frame
%   EOSP                           - End of current service period indication
%   IsMeshFrame                    - Frame sent by mesh station in mesh
%                                    basic service set (BSS)
%   SleepMode                      - Peer-specific mesh power management mode
%   ReceiverServicePeriodInitiated - Mesh peer service period initiation
%                                    indication
%   MeshTTL                        - Mesh time to live (TTL) value
%   MeshSequenceNumber             - Mesh sequence number
%   AddressExtensionMode           - Additional addresses included in Mesh
%                                    Control field
%   Address5                       - Destination address
%   Address6                       - Source address
%   ManagementConfig               - Management frame-body configuration object
%   TriggerConfig                  - Trigger frame-body configuration object
%
%   wlanMACFrameConfig read-only properties:
%
%   TriggerType                    - Type of trigger frame
%   HasMeshControl                 - Mesh Control field included in frame body
%   Decoded                        - Decoded MPDU configuration indication

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

properties
    %FrameType Type of the MAC frame
    %   Specify the frame type as "RTS", "CTS", "ACK", "Block Ack",
    %   "CF-End", "Trigger", "Data", "Null", "QoS Data", "QoS Null", or
    %   "Beacon". The default value is "Beacon".
    FrameType = 'Beacon'

    %FrameFormat Format of the MAC frame
    %   Specify the frame format as "Non-HT", "HT-Mixed", "VHT", "HE-SU",
    %   "HE-EXT-SU", or "EHT-SU". This property is applicable when
    %   FrameType is set to 'QoS Data' or 'QoS Null'. VHT, HE-SU,
    %   HE-EXT-SU, and EHT-SU formats are applicable only for 'QoS Data'
    %   frame type. This property applies only for frame generation and
    %   does not apply in the decoded configuration. The default value is
    %   'Non-HT'.
    FrameFormat = 'Non-HT'

    %ToDS The frame is destined to the DS
    %   Set this property to true to indicate that the frame is directed
    %   from a non-AP station to the distributed system. The default value
    %   is false.
    ToDS (1, 1) logical = false

    %FromDS The frame is exiting the DS
    %   Set this property to true to indicate that the frame is directed
    %   from the distributed system to a non-AP station. The default value
    %   is true.
    FromDS (1, 1) logical = true

    %Retransmission The frame is being retransmitted
    %   Set this property to true to indicate that the frame is a
    %   retransmission. The default value is false.
    Retransmission (1, 1) logical = false

    %PowerManagement Power management mode
    %   Set this property to true to indicate that the sender is in power
    %   saving mode. The default value is false.
    PowerManagement (1, 1) logical = false

    %MoreData More data indication
    %   Set this property to true to indicate that the sender has more
    %   frames to send. The default value is false.
    MoreData (1, 1) logical = false

    %ProtectedFrame Protected frame indication
    %   The frame is protected with a cryptographic encapsulation
    %   algorithm. This property does not apply for frame generation. The
    %   default value is false.
    ProtectedFrame (1, 1) logical = false

    %HTControlPresent HTControl field included in the frame
    %   Set this property to true to indicate that the HTControl field is
    %   included in the MAC header. The default value is false.
    HTControlPresent (1, 1) logical = false

    %Duration Estimated time (in microseconds) to transmit the pending
    %frames after this frame
    %   Specify the duration in microseconds as an integer in the range of
    %   [0-32767]. The default value is 0.
    Duration (1,1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(Duration,32767)} = 0

    %Address1 Receiver address
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. The default value is
    %   'FFFFFFFFFFFF' (broadcast address).
    Address1 = 'FFFFFFFFFFFF'

    %Address2 Transmitter address
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. The default value is
    %   '00123456789B'.
    Address2 = '00123456789B'

    %Address3 Basic Service Set Identifier (or) Destination Address (or)
    %Source Address
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. This address
    %   represents BSSID (Basic Service Set Identifier) when both ToDS and
    %   FromDS are 0, represents SA (Source Address) when ToDS is 0 and
    %   FromDS is 1 and represents DA (Destination Address) when ToDS is 1
    %   and FromDS is 0. The default value is '00123456789B'.
    Address3 = '00123456789B'

    %Address4 Source Address (or) Basic Service Set Identifier
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. To enable this
    %   property:
    %       1. Set the FrameType property to 'QoS Data' or 'QoS Null' and
    %          both ToDS and FromDS properties to 1.
    %       2. Set the IsMeshFrame property to true, the FrameType property
    %          to 'QoS Data', ToDS to 0 and FromDS to 1 and the
    %          AddressExtensionModeProperty to 1. When you enable MSDU or
    %          MPDU aggregation, specify this property as an N-by-12
    %          character array or an N-by-1 string array, where N is the
    %          number of MSDUs to be aggregated. If you specify a
    %          12-element character vector or string scalar, all MSDUs have
    %          the same address.
    %   The default value is '00123456789B'.
    Address4

    %SequenceNumber Frame sequence number
    %   Specify the sequence number as an integer in the range of [0 -
    %   4095]. When an A-MPDU is generated, the specified sequence number
    %   corresponds to the first MPDU and is incremented for the subsequent
    %   MPDUs. For a Block Ack frame, this represents the starting sequence
    %   number. The default value is 0.
    SequenceNumber (1,1) {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(SequenceNumber,4095)} = 0

    %TID Traffic identifier representing the user-priority
    %   Specify TID as an integer in the range of [0-7]. The default value
    %   is 0.
    TID (1,1) {mustBeNumeric, mustBeMember(TID,[0,1,2,3,4,5,6,7])} = 0

    %AckPolicy Acknowledgment policy
    %   Specify the ack policy as one of 'Normal Ack/Implicit Block Ack
    %   Request' | 'No Ack' | 'No explicit acknowledgment/PSMP Ack/HTP Ack'
    %   | 'Block Ack'. The default value is 'No Ack'.
    AckPolicy = 'No Ack'

    %HTControl HT Control field of the MAC header
    %   Specify the HTControl as an 8-element character vector or string
    %   scalar denoting a 4-octet hexadecimal value. The leftmost byte in
    %   the value must contain the most significant byte. The default value
    %   is '00000000'.
    HTControl = '00000000'

    %MSDUAggregation Form A-MSDUs using MSDU aggregation
    %   Set this property to true to indicate that the output MAC frame
    %   should contain A-MSDU(s) instead of MSDU(s). This property applies
    %   only when FrameType is set to 'QoS Data'. The default value is
    %   false.
    MSDUAggregation (1, 1) logical = false

    %MPDUAggregation Form A-MPDU using MPDU aggregation
    %   Set this property to true to generate an A-MPDU as the output
    %   frame. This property applies only when FrameType is set to 'QoS
    %   Data' and FrameFormat is set to 'HT-Mixed'. When FrameType is set
    %   to 'QoS Data' and FrameFormat is set to 'VHT','HE-SU','HE-EXT-SU',
    %   or 'EHT-SU', A-MPDU is generated as the output frame regardless of
    %   this property's value. This property applies only for frame
    %   generation and does not apply in the decoded configuration. The
    %   default value is false.
    MPDUAggregation (1, 1) logical = false

    %AMSDUDestinationAddress Destination address (DA) or mesh DA of all
    %A-MSDU subframes
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. When MSDUAggregation
    %   is enabled, specify this property as an N-by-12 character array or
    %   an N-by-1 string array, where N is the number of MSDUs to be
    %   aggregated. If you specify a 12-element character vector or string
    %   scalar, all MSDUs have the same address. The default value is
    %   '00123456789A'.
    AMSDUDestinationAddress

    %AMSDUSourceAddress Source address (SA) or mesh SA of all A-MSDU
    %subframes
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. When MSDUAggregation
    %   is enabled, specify this property as an N-by-12 character array or
    %   an N-by-1 string array, where N is the number of MSDUs to be
    %   aggregated. If you specify a 12-element character vector or string
    %   scalar, all MSDUs have the same address. The default value is
    %   '00123456789B'.
    AMSDUSourceAddress

    %MinimumMPDUStartSpacing Minimum spacing between the start of MPDUs in
    %an A-MPDU
    %   Specify the minimum MPDU start spacing as an integer in the range
    %   of [0 - 7]. This value is an enumeration of time values in
    %   microseconds. Refer Table-9.163 in the Std IEEE 802.11-2016. This
    %   property applies only for frame generation and does not apply in
    %   the decoded configuration. The default value is 0.
    MinimumMPDUStartSpacing (1,1) {mustBeNumeric, mustBeMember(MinimumMPDUStartSpacing,[0,1,2,3,4,5,6,7])} = 0

    %BlockAckBitmap Block Ack Bitmap
    %   Specify this property as a character vector or string scalar
    %   containing 16, 64, 128, or 256 elements, denoting an 8, 32, 64, or
    %   128 octet hexadecimal values, respectively. Bit-0 in the least
    %   significant octet corresponds to the MPDU with the starting
    %   sequence number.
    BlockAckBitmap = 'FFFFFFFFFFFFFFFF'

    %MinTriggerProcessTime Minimum time required to process trigger frame
    %   Specify minimum trigger processing time in microseconds as 0, 8, or 16.
    %   This property applies only for frame generation and does not apply in
    %   the decoded configuration. The default value is 0.
    MinTriggerProcessTime (1,1) {mustBeNumeric, mustBeMember(MinTriggerProcessTime,[0 8 16])} = 0

    %EOSP End of current service period indication
    %   Set this property to true to indicate the end of the current
    %   service period. The default value is false.
    EOSP (1, 1) logical = false

    %IsMeshFrame Frame sent by mesh station in mesh BSS
    %   Set this property to true to indicate that the frame is sent by a
    %   mesh station in a mesh BSS. To enable this property, set the
    %   FrameType property to 'QoS Data' or 'QoS Null'. The default value
    %   is false.
    IsMeshFrame (1, 1) logical = false

    %SleepMode Peer-specific mesh power management mode
    %   Specify the peer-specific mesh power management mode of the mesh
    %   station as 'Deep' or 'Light'. To enable this property, set the
    %   PowerManagement property to true and the IsMeshFrame property to
    %   true. The default value is 'Light'.
    SleepMode = 'Light'

    %ReceiverServicePeriodInitiated Mesh peer service period initiation indication
    %   Set this property to true to initiate the mesh peer service period,
    %   of which the receiver of this frame is the owner. Refer to Table
    %   14-32 in the Std IEEE 802.11-2016. To enable this property, set the
    %   IsMeshFrame property to true. The default value is false.
    ReceiverServicePeriodInitiated (1, 1) logical = false

    %MeshTTL Mesh time to live (TTL) value
    %   Specify the mesh TTL value, i.e., remaining number of hops to
    %   forward the MSDU as an integer in the range [0, 255]. To enable
    %   this property, set the IsMeshFrame property to true and the
    %   FrameType property to 'QoS Data'. When you enable MSDU or MPDU
    %   aggregation, specify this property as a vector containing values
    %   for all MSDUs. If you specify this property as a scalar, the object
    %   uses the same value for all MSDUs. The default value is 31.
    MeshTTL {mustBeNumeric, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(MeshTTL,255)} = 31

    %MeshSequenceNumber Mesh sequence number
    %   Specify the sequence number assigned by the source mesh station to
    %   an MSDU as an integer in the range [0, 2^32-1]. To enable this
    %   property, set the IsMeshFrame property to true and the FrameType
    %   property to 'QoS Data'. When you enable MSDU or MPDU aggregation,
    %   specify this property as a vector containing values for all MSDUs.
    %   If you specify this property as a scalar, the specified sequence
    %   number corresponds to the first MSDU and the object increments this
    %   value for the subsequent MSDUs. The default value is 0.
    MeshSequenceNumber = 0

    %AddressExtensionMode Additional addresses included in Mesh Control field
    %   Specify the number of address fields included in Mesh Control field
    %   as an integer in the range [0, 2]. To enable this property, set the
    %   IsMeshFrame property to true and the FrameType property to 'QoS
    %   Data'. The default value is 0.
    AddressExtensionMode {mustBeNumeric, mustBeMember(AddressExtensionMode,[0, 1, 2])} = 0

    %Address5 Destination address
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. To enable this
    %   property, set the IsMeshFrame property to true, the FrameType
    %   property to 'QoS Data', the ToDS and FromDS properties to true and
    %   the AddressExtensionMode property to 2. When you enable MSDU or
    %   MPDU aggregation, specify this property as an N-by-12 character
    %   array or an N-by-1 string array, where N is the number of MSDUs to
    %   be aggregated. If you specify a 12-element character vector or
    %   string scalar, all MSDUs have the same address. The default value
    %   is '00123456789A'.
    Address5

    %Address6 Source address
    %   Specify the address as a 12-element character vector or string
    %   scalar denoting a six-octet hexadecimal value. To enable this
    %   property, set the IsMeshFrame property to true, the FrameType
    %   property to 'QoS Data', the ToDS and FromDS properties to true and
    %   the AddressExtensionMode property to 2. When you enable MSDU or
    %   MPDU aggregation, specify this property as an N-by-12 character
    %   array or an N-by-1 string array, where N is the number of MSDUs to
    %   be aggregated. If you specify a 12-element character vector or
    %   string scalar, all MSDUs have the same address. The default value
    %   is '00123456789B'.
    Address6

    %ManagementConfig Management frame-body configuration object
    %   Specify this property as a configuration object of type wlanMACManagementConfig.
    %   This configuration applies only for management frames. It
    %   specifies the fields and information elements (IEs) present in the
    %   management frame specified in 'FrameType' property. The default
    %   value is an object of type wlanMACManagementConfig with all
    %   properties set to their default values.
    ManagementConfig (1,1) {mustBeA(ManagementConfig, "wlanMACManagementConfig")} = wlanMACManagementConfig

    %TriggerConfig Trigger frame-body configuration object
    %   Specify this property as a configuration object of type wlanMACTriggerConfig.
    %   This configuration applies only when 'FrameType' is set to
    %   'Trigger'. It specifies the common info and user info fields
    %   present in the trigger frame. The default value is an object of
    %   type wlanMACTriggerConfig with all properties set to their default
    %   values.
    TriggerConfig (1,1) {mustBeA(TriggerConfig, "wlanMACTriggerConfig")} = wlanMACTriggerConfig
end

properties(SetAccess = private, GetAccess = public)
    %TriggerType Type of trigger frame
    %   This property indicates the type of the trigger frame configured in
    %   the 'TriggerConfig' property. This is a read-only property.
    TriggerType = 'Basic'

    %HasMeshControl Mesh Control field included in frame body
    %   This property indicates if the frame body includes a Mesh Control
    %   field, returned as a logical 1 or 0. This is a read-only property.
    HasMeshControl = false

    %Decoded Decoded MPDU configuration indication
    %   Indicates if this configuration holds decoded MPDU properties. When
    %   the wlanMPDUDecode function creates this object as an output of the
    %   MPDU decoding process, this property is true. Otherwise, this
    %   property is false. This is a read-only property.
    Decoded = false
end

properties(Hidden)
    %DecodeFailed MPDU decoder failed to decode the frame
    %   This is a hidden property used by wlanMPDUDecode function to
    %   disable the display of all the properties.
    DecodeFailed = false

    %DisableHexValidation Disable validation for hex inputs in property set methods
    %  Specify this property as a logical scalar. When true, validation
    %  is not performed for hexadecimal char/string inputs in the property
    %  set methods and these values are expected to be valid values.
    DisableHexValidation = false;

    %NumPadBytesICF Specify the number of padding bytes for Initial Control
    %Frame (ICF)
    %   Specify the number of padding bytes for MU-RTS Initial Control Frame
    %   (ICF), in an EMLSR frame exchange. If specified as -1, the number of
    %   padding bytes are calculated using MinTriggerProcessTime. The
    %   default value is -1.
    NumPadBytesICF = -1;
end

properties (Hidden, Constant)
    FrameType_Values = {'RTS', 'CTS', 'ACK', 'Block Ack', 'CF-End', 'Trigger', 'Data', 'Null', 'QoS Data', 'QoS Null', 'Beacon'}
    FrameFormat_Values = {'Non-HT', 'HT-Mixed', 'VHT', 'HE-SU', 'HE-EXT-SU', 'EHT-SU'}
    AckPolicy_Values = {'Normal Ack/Implicit Block Ack Request', 'No Ack', 'No explicit acknowledgment/PSMP Ack/HTP Ack', 'Block Ack'}
    SleepMode_Values = {'Light', 'Deep'}
end

methods(Access = private)
    function value = conditionalValidateHex(obj, value, length, propertyName)
        if ~obj.DisableHexValidation
            % validate format
            validateattributes(value, {'char', 'string'}, {}, 'wlanMACFrameConfig', propertyName);
            if isa(value, 'char')
                validateattributes(value, {'char'}, {'row'}, 'wlanMACFrameConfig', propertyName);
            else % string
                validateattributes(value, {'string'}, {'scalar'}, 'wlanMACFrameConfig', propertyName);
            end

            value = upper(char(value));

            % Validate hex-digits
            wnet.internal.validateHexOctets(value, propertyName, length);
        else
            value = upper(char(value));
        end
    end
end

methods(Hidden)
    function obj = isDecodedConfig(obj, value)
        obj.Decoded = value;
        obj.TriggerConfig.Decoded = value;
    end

    function obj = decodedMeshControl(obj, value)
        obj.HasMeshControl = value;
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = true;

        if obj.DecodeFailed
            % Disable the display of all the properties if MPDU decoder failed to
            % decode the frame.
            return;
        end

        switch(prop)
            case {'FrameType', 'PowerManagement', 'MoreData', 'Duration', 'Address1', 'Decoded'}
                % Applicable for all frame types
                flag = false;
            case 'ProtectedFrame'
                flag = ~obj.Decoded;
            case 'Address2'
                % Not applicable for CTS and ACK frames
                flag = strcmp(obj.FrameType, 'CTS') || strcmp(obj.FrameType, 'ACK');
            case {'ToDS', 'FromDS', 'Retransmission', 'Address3'}
                % Not applicable for control frames
                flag = strcmp(obj.getType, 'Control');
            case 'Address4'
                % Applicable when both ToDS and FromDS are true in 'QoS Data' or
                % 'QoS Null' frames. Applicable in Mesh Control field when ToDS is
                % 0, FromDS is 1 and AddressExtensionMode is 1
                flag = ~((strcmp(obj.FrameType, 'QoS Data') || strcmp(obj.FrameType, 'QoS Null')) && obj.ToDS && obj.FromDS) && ...
                    ~(obj.HasMeshControl && ~obj.ToDS && obj.FromDS && (obj.AddressExtensionMode == 1));
            case 'SequenceNumber'
                % Not applicable for control frames except BA frame
                flag = strcmp(obj.getType, 'Control') && ~strcmp(obj.FrameType, 'Block Ack');
            case 'BlockAckBitmap'
                flag = ~strcmp(obj.FrameType, 'Block Ack');
            case 'TID'
                % Applicable for 'QoS Data', 'QoS Null', and 'Block Ack'
                flag = ~any(strcmp(obj.FrameType, {'QoS Data', 'QoS Null', 'Block Ack'}));
            case {'FrameFormat', 'AckPolicy', 'HTControlPresent', 'HTControl', 'EOSP'}
                % FrameFormat, AckPolicy and EOSP are only applicable for 'QoS Data' and 'QoS Null' frames
                flag = ~(strcmp(obj.FrameType, 'QoS Data') || strcmp(obj.FrameType, 'QoS Null'));
                if ~flag && strcmp(prop, 'FrameFormat')
                    % FrameFormat is a generation parameter and not part of
                    % information decoded from MPDU
                    flag = obj.Decoded;
                end
                % HTControlPresent is applicable only when FrameFormat is applicable
                if ~flag && (strcmp(prop, 'HTControlPresent') || strcmp(prop, 'HTControl'))
                    % HTControlPresent flag is not applicable for Non-HT format frames
                    flag = strcmp(obj.FrameFormat, 'Non-HT');
                    % HTControl field is applicable only when HTControlPresent is applicable
                    if ~flag && strcmp(prop, 'HTControl')
                        % HTControl field is applicable when HTControlPresent flag is set
                        flag = ~obj.HTControlPresent;
                    end
                end
            case {'MSDUAggregation', 'AMSDUDestinationAddress', 'AMSDUSourceAddress'}
                % MSDUAggregation is applicable for only 'QoS Data' frames
                flag = ~strcmp(obj.FrameType, 'QoS Data');
                % AMSDUDestinationAddress and AMSDUSourceAddress are applicable only
                % when MSDUAggregation flag is set
                if ~flag && (strcmp(prop, 'AMSDUDestinationAddress') || strcmp(prop, 'AMSDUSourceAddress'))
                    flag = ~obj.MSDUAggregation || obj.ProtectedFrame;
                end
            case {'MPDUAggregation', 'MinimumMPDUStartSpacing'}
                isQoS = strcmp(obj.FrameType, 'QoS Data');
                isHT = strcmp(obj.FrameFormat, 'HT-Mixed');
                isNonHT = strcmp(obj.FrameFormat, 'Non-HT');

                % MPDUAggregation and MinimumMPDUStartSpacing are generation
                % parameters and not part of information decoded from MPDU
                flag = obj.Decoded;

                if ~flag && strcmp(prop, 'MPDUAggregation')
                    % MPDUAggregation is applicable for only HT format 'QoS Data'
                    % frame
                    flag = ~(isQoS && isHT);
                elseif ~flag && strcmp(prop, 'MinimumMPDUStartSpacing')
                    flag = isNonHT || ~isQoS || (isHT && ~obj.MPDUAggregation);
                end
            case 'ManagementConfig'
                % Applicable for only 'Beacon' frame
                flag = ~strcmp(obj.FrameType, 'Beacon');
            case {'TriggerConfig', 'TriggerType', 'MinTriggerProcessTime'}
                % Applicable for only 'Trigger' frame
                flag = ~strcmp(obj.FrameType, 'Trigger');
                if ~flag && strcmp(prop, 'MinTriggerProcessTime')
                    flag = obj.Decoded;
                end
            case {'IsMeshFrame', 'HasMeshControl', 'SleepMode', ...
                    'ReceiverServicePeriodInitiated', 'MeshTTL', 'MeshSequenceNumber', ...
                    'AddressExtensionMode', 'Address5', 'Address6'}
                flag = ~(strcmp(obj.FrameType, 'QoS Data') || strcmp(obj.FrameType, 'QoS Null'));
                if ~flag && any(strcmp(prop, {'HasMeshControl', 'SleepMode', 'ReceiverServicePeriodInitiated'}))
                    % Applicable for 'QoS Data' and 'QoS Null' frames sent by mesh
                    % station in mesh BSS
                    flag = ~obj.IsMeshFrame;
                    if ~flag && strcmp(prop, 'SleepMode')
                        % Applicable only when PowerManagement property is set to true
                        flag = ~obj.PowerManagement;
                    end
                end
                if ~flag && any(strcmp(prop, {'MeshTTL', 'MeshSequenceNumber', 'AddressExtensionMode', ...
                        'Address5', 'Address6'}))
                    % Applicable only when HasMeshControl property is true
                    flag = ~obj.HasMeshControl;
                    if ~flag && (strcmp(prop, 'Address5') || strcmp(prop, 'Address6'))
                        % Applicable only when AddressExtensionMode property is set to true
                        flag = ~(obj.AddressExtensionMode == 2);
                    end
                end
        end
    end
end

methods(Hidden)
    function type = getType(obj)
        if strcmp(obj.FrameType, 'Beacon')
            type = 'Management';
        elseif any(strcmp(obj.FrameType, {'RTS', 'CTS', 'ACK', 'Block Ack', 'CF-End', 'Trigger'}))
            type = 'Control';
        else % 'Data', 'Null', 'QoS Data', 'QoS Null'
            type = 'Data';
        end
    end

    function subtype = getSubtype(obj)
        subtype = obj.FrameType;
    end

    function amsduPresent = getAMSDUPresent(obj)
        amsduPresent = obj.MSDUAggregation && strcmp(obj.FrameType, 'QoS Data');
    end
end

methods
    function obj = wlanMACFrameConfig(varargin)
        % Properties expected to have variable sizes. Use coder.varsize for codegen
        meshTTLInitValue = 31;
        coder.varsize('meshTTLInitValue');

        meshSeqNumInitValue = 0;
        coder.varsize('meshSeqNumInitValue');

        % Max MAC frame size is 6500631 octets. Max MAC subframe (MPDU) size is
        % 11454 (max MPDU length) + 4 (MPDU delimiter) + 2 (padding) = 11460
        % octets. Max number of subframes = ceil(6500631/11460) = 568. Consider
        % that each MPDU consists of an A-MSDU. This will give maximum A-MSDU
        % length = 11454 - minimum MAC header (30) = 11424 octets. Assuming
        % MSDU length as 1 byte, minimum length of each A-MSDU subframe is
        % A-MSDU subframe header (14 octets) + MSDU length (1 octet) + padding
        % (1 octet) = 16 octets. Therefore we can aggregate a maximum of
        % 11424/16 = 714 MSDUs.
        % Maximum number of MSDUs in a MAC frame = 568 * 714 = 405552
        maxMSDUs = 405552;
        daInitValue = '00123456789A';
        coder.varsize('daInitValue', [maxMSDUs 12], [1 0]);

        saInitValue = '00123456789B';
        coder.varsize('saInitValue', [maxMSDUs 12], [1 0]);

        % Setting default value here as codegen doesn't support object as an
        % initial value for a property.
        obj@comm.internal.ConfigBase( ...
            'FrameType', 'Beacon', ...
            'FrameFormat', 'Non-HT', ...
            'AckPolicy', 'No Ack', ...
            'BlockAckBitmap', 'FFFFFFFFFFFFFFFF', ...
            'Address4', saInitValue, ...
            'MeshTTL', meshTTLInitValue, ...
            'MeshSequenceNumber', meshSeqNumInitValue, ...
            'AMSDUDestinationAddress', daInitValue, ...
            'AMSDUSourceAddress', saInitValue, ...
            'Address5', daInitValue, ...
            'Address6', saInitValue, ...
            'SleepMode', 'Light', ...
            'ManagementConfig', wlanMACManagementConfig,  ...
            'TriggerConfig', wlanMACTriggerConfig, ...
            varargin{:});
    end

    function obj = set.FrameType(obj, value)
        value = validatestring(value, obj.FrameType_Values, 'wlanMACFrameConfig', 'FrameType');
        obj.FrameType = value;
    end

    function obj = set.FrameFormat(obj, value)
        value = validatestring(value, obj.FrameFormat_Values, 'wlanMACFrameConfig', 'FrameFormat');
        obj.FrameFormat = value;
    end

    function obj = set.Address1(obj, value)
        value = obj.conditionalValidateHex(value, 12, 'Address1');
        obj.Address1 = value;
    end

    function obj = set.Address2(obj, value)
        value = obj.conditionalValidateHex(value, 12, 'Address2');
        obj.Address2 = value;
    end

    function obj = set.Address3(obj, value)
        value = obj.conditionalValidateHex(value, 12, 'Address3');
        obj.Address3 = value;
    end

    function obj = set.Address4(obj, value)
        numRows = size(value, 1);
        addressInChar = repmat('0', numRows, 12);
        for rowIdx = 1:numRows
            addressInChar(rowIdx, :) = obj.conditionalValidateHex(value(rowIdx, :), 12, 'Address4');
        end
        obj.Address4 = addressInChar;
    end

    function obj = set.AckPolicy(obj, value)
        value = validatestring(value, obj.AckPolicy_Values, 'wlanMACFrameConfig', 'AckPolicy');
        obj.AckPolicy = value;
    end

    function obj = set.HTControl(obj, value)
        value = obj.conditionalValidateHex(value, 8, 'HTControl');
        obj.HTControl = value;
    end

    function obj = set.AMSDUDestinationAddress(obj, value)
        numRows = size(value, 1);
        addressInChar = repmat('0', numRows, 12);
        for rowIdx = 1:numRows
            addressInChar(rowIdx, :) = obj.conditionalValidateHex(value(rowIdx, :), 12, 'AMSDUDestinationAddress');
        end
        obj.AMSDUDestinationAddress = addressInChar;
    end

    function obj = set.AMSDUSourceAddress(obj, value)
        numRows = size(value, 1);
        addressInChar = repmat('0', numRows, 12);
        for rowIdx = 1:numRows
            addressInChar(rowIdx, :) = obj.conditionalValidateHex(value(rowIdx, :), 12, 'AMSDUSourceAddress');
        end
        obj.AMSDUSourceAddress = addressInChar;
    end

    function obj = set.BlockAckBitmap(obj, value)
        value = obj.conditionalValidateHex(value, [], 'BlockAckBitmap');
        coder.internal.errorIf(~any(numel(value) == [16 64 128 256]), 'wlan:wlanMACFrameConfig:InvalidBABitmapSize');
        obj.BlockAckBitmap = value;
    end

    function obj = set.SleepMode(obj, value)
        value = validatestring(value, obj.SleepMode_Values, 'wlanMACFrameConfig', 'SleepMode');
        obj.SleepMode = value;
    end

    function obj = set.MeshSequenceNumber(obj, value)
        coder.internal.errorIf(~isnumeric(value) || ~all(floor(value)==value, 'all') || ...
            ~(all(value>=0, 'all') && all(value<=intmax('uint32'), 'all')), 'wlan:wlanMACFrameConfig:InvalidMeshSequenceNumber');
        obj.MeshSequenceNumber = uint32(value);
    end

    function obj = set.Address5(obj, value)
        numRows = size(value, 1);
        addressInChar = repmat('0', numRows, 12);
        for rowIdx = 1:numRows
            addressInChar(rowIdx, :) = obj.conditionalValidateHex(value(rowIdx, :), 12, 'Address5');
        end
        obj.Address5 = addressInChar;
    end

    function obj = set.Address6(obj, value)
        numRows = size(value, 1);
        addressInChar = repmat('0', numRows, 12);
        for rowIdx = 1:numRows
            addressInChar(rowIdx, :) = obj.conditionalValidateHex(value(rowIdx, :), 12, 'Address6');
        end
        obj.Address6 = addressInChar;
    end

    function variant = get.TriggerType(obj)
        variant = obj.TriggerConfig.TriggerType;
    end

    function value = get.HasMeshControl(obj)
        % HasMeshControl is dependent on IsMeshFrame and FrameType properties
        % in generation
        if ~obj.Decoded
            % Mesh control field is present in 'QoS Data' frames sent by mesh station.
            value = obj.IsMeshFrame && strcmp(obj.FrameType, 'QoS Data');
        else
            % HasMeshControl is decoded from frame in decoding
            value = obj.HasMeshControl;
        end
    end
end
end
