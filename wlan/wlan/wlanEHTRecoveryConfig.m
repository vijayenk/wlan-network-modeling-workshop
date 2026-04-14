classdef wlanEHTRecoveryConfig < comm.internal.ConfigBase
%wlanEHTRecoveryConfig Create an extremely high throughput (EHT) recovery configuration object
%
%   CFGRX = wlanEHTRecoveryConfig creates an EHT recovery configuration
%   object for EHT MU packet formats. This object contains the parameters
%   recovered by decoding the signaling fields of EHT MU formats, as
%   defined in the IEEE P802.11be/D5.0 standard.
%
%   CFGRX = wlanEHTRecoveryConfig (Name,Value) creates an EHT recovery
%   object, CFGRX, with the specified property Name set to the specified
%   Value. You can specify additional name-value pair arguments in any
%   order as (Name1,Value1, ...,NameN,ValueN).
%
%   wlanEHTRecoveryConfig methods:
%
%   psduLength                - Number of coded bytes in the packet.
%   packetFormat              - EHT packet type.
%   interpretUSIGBits         - Parse and interpret decoded U-SIG bits,
%                               returning an updated recovery object with
%                               the relevant U-SIG fields set.
%   interpretEHTSIGCommonBits - Parse and interpret decoded EHT-SIG common
%                               field bits, returning an updated recovery
%                               object with the relevant EHT-SIG fields
%                               set.
%   interpretEHTSIGUserBits   - Parse and interpret decoded EHT-SIG user
%                               field bits, returning an updated recovery
%                               object with the relevant EHT-SIG fields
%                               set.
%
%   wlanEHTRecoveryConfig properties:
%
%   ChannelBandwidth             - Channel bandwidth
%   LSIGLength                   - Indicate length value in L-SIG field
%   CompressionMode              - Indicate PPDU type and compression mode
%   EHTSIGMCS                    - Indicate MCS of EHT-SIG field
%   NumEHTSIGSymbolsSignaled     - Number of EHT-SIG symbols signaled in U-SIG field
%   LDPCExtraSymbol              - Indicate extra OFDM symbol
%   PreFECPaddingFactor          - Indicate pre-FEC padding factor
%   PEDisambiguity               - Indicate PEDisambiguity
%   GuardInterval                - Indicate guard interval type
%   EHTLTFType                   - Indicate EHT-LTF type
%   NumEHTLTFSymbols             - Indicate number of EHT-LTF symbols
%   UplinkIndication             - Indicate uplink transmission
%   BSSColor                     - Indicate Basic Service Set (BSS) color identifier
%   SpatialReuse                 - Indicate spatial reuse
%   TXOPDuration                 - Indicate duration information for TXOP protection
%   AllocationIndex              - Indicate RU allocation index
%   NumNonOFDMAUsers             - Number of users in non-OFDMA transmission
%   NumUsersPerContentChannel    - Number of users per content channel
%   RUTotalSpaceTimeStreams      - Number of space time streams in an RU
%   RUSize                       - Indicate resource unit (RU) size
%   RUIndex                      - Indicate resource unit (RU) index
%   PuncturedPattern             - Indicate puncturing pattern for OFDMA
%   PuncturedChannelFieldValue   - Indicate puncturing pattern value for non-OFDMA
%   STAID                        - Indicate station identification
%   MCS                          - Indicate modulation and coding scheme
%   ChannelCoding                - Indicate channel coding type
%   Beamforming                  - Indicate beamforming
%   NumSpaceTimeStreams          - Indicate number of space-time streams
%   SpaceTimeStreamStartingIndex - Starting space-time stream index
%   Channelization               - Indicate channelization for 320 MHz
%   PPDUType                     - Indicate the recovered EHT PPDU type
%   EHTDUPMode                   - Indicate EHT DUP mode

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    properties (Access='public')
        %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
        %   Specify the channel bandwidth as one of 'CBW20', 'CBW40', 'CBW80',
        %   'CBW160', 'CBW320', or 'unknown'. The default value of this
        %   property is 'unknown', which indicates an unknown or undefined
        %   channel bandwidth.
        ChannelBandwidth (1,:) = 'unknown';
        %LSIGLength Indicate the length value of L-SIG field
        %   This property is set after decoding the length of the L-SIG packet.
        %   The LSIGLength is specified as a scalar integer between 1 and 4095
        %   (inclusive). The default value of this property is -1, which
        %   indicates an unknown or undefined packet length.
        LSIGLength (1,1) {wlan.internal.mustBeValidLSIGLengthRange(LSIGLength)} = -1;
        %CompressionMode Indicate PPDU type and compression mode
        %   This property is set after decoding the U-SIG field and indicates
        %   the PPDU type and compression mode as defined in Table 36-29 of
        %   IEEE P802.11be/D5.0. The value must be 0, 1, 2, 3, or -1. The
        %   default is -1, which indicates an unknown or undefined compression
        %   mode.
        CompressionMode (1,1) {mustBeMember(CompressionMode,[-1 0 1 2 3])} = -1;
        %EHTSIGMCS Indicate the MCS of an EHT-SIG field
        %   This property is set after decoding the U-SIG field and indicates
        %   the modulation and coding scheme of the EHT-SIG field as an integer
        %   scalar. The value must be 0, 1, 3, 15, or -1. The values 0, 1, 3,
        %   and 15 correspond respectively to the EHT-SIG field values 0, 1, 2,
        %   and 3 as defined in Table 36-1 of IEEE P802.11be/D5.0. The default
        %   is -1, which indicates an unknown or undefined EHTSIGMCS value.
        EHTSIGMCS (1,1) {mustBeNumeric,mustBeMember(EHTSIGMCS,[-1 0 1 3 15])} = -1;
        %NumEHTSIGSymbolsSignaled Number of EHT-SIG symbols signaled in U-SIG
        %   This property is set after decoding the U-SIG field and indicates
        %   the number of symbols in the EHT-SIG field. The value must be an
        %   integer between 1 and 32 or -1. The default is -1, which indicates
        %   an unknown or undefined number of EHT-SIG symbols.
        NumEHTSIGSymbolsSignaled (1,1) {mustBeNumeric,mustBeMember(NumEHTSIGSymbolsSignaled,[-1,1:32])} = -1;
        %LDPCExtraSymbol Indicate the presence of an extra OFDM symbol
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the presence of an extra OFDM symbol segment for LDPC coding. The
        %   value must be logical or double. The default value of this property
        %   is -1, which indicates an unknown or undefined number of LDPC extra
        %   symbol segment.
        LDPCExtraSymbol (1,1) double {wlan.internal.mustBeLogicalOrUnknown(LDPCExtraSymbol,'LDPCExtraSymbol')} = -1;
        %PreFECPaddingFactor Indicate the Pre-FEC padding factor
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the pre-FEC padding factor in the recovered EHT packet.
        %   PreFECPaddingFactor must be an integer scalar between 1 and 4
        %   inclusive or -1. The default is -1, which indicates an unknown or
        %   undefined PreFECPaddingFactor value.
        PreFECPaddingFactor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreFECPaddingFactor,-1),mustBeLessThanOrEqual(PreFECPaddingFactor,4)} = -1;
        % PEDisambiguity Indicate the PE-Disambiguity in an EHT MU packet
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the PE-Disambiguity in the recovered EHT packet. The value must be
        %   logical or double. The default is -1, which indicates an unknown or
        %   undefined PEDisambiguity state.
        PEDisambiguity (1,1) double {wlan.internal.mustBeLogicalOrUnknown(PEDisambiguity,'PEDisambiguity')} = -1;
        %GuardInterval Indicate guard interval type of an EHT packet
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the guard interval (cyclic prefix) length in microseconds of an EHT
        %   packet. The allowed values are 0.8, 1.6, 3.2, or -1. The default
        %   value of this property is -1, which indicates an unknown or
        %   undefined guard interval.
        GuardInterval {wlan.internal.heValidateGI(GuardInterval,[-1 0.8 1.6 3.2])} = -1;
        %EHTLTFType Indicate the EHT-LTF type of an EHT PPDU
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the EHT-LTF type of the recovered packet. The EHT-LTF type must be
        %   one of 2, 4, or -1. The values of 2 and 4 correspond to the
        %   2xEHT-LTF and 4xEHT-LTF modes, respectively. The default is -1,
        %   which indicates an unknown or undefined EHT-LTF type.
        EHTLTFType (1,1) {mustBeNumeric,mustBeMember(EHTLTFType,[-1 2 4])} = -1;
        %NumEHTLTFSymbols Indicate the number of EHT-LTF symbols
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the number of EHT-LTF symbols as a scalar integer between 1 and 8,
        %   inclusive, or -1. The default is -1, which indicates an unknown or
        %   undefined number of EHT-LTF symbol.
        NumEHTLTFSymbols (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(NumEHTLTFSymbols,[-1 1:8])} = -1;
        %UplinkIndication Uplink indication
        %   This property is set after decoding the U-SIG field and indicates
        %   that the PPDU is sent on an uplink transmission. The value must be
        %   logical or double. A value of false indicates a downlink
        %   transmission. The default is -1, which indicates an unknown or
        %   undefined transmission direction.
        UplinkIndication (1,1) double {wlan.internal.mustBeLogicalOrUnknown(UplinkIndication,'UplinkIndication')} = -1;
        %BSSColor Indicate basic service set (BSS) color identifier
        %   This property is set after decoding the U-SIG field and indicates
        %   the BSS color number of a basic service set as an integer scalar
        %   between 0 and 63, inclusive, or -1. The default is -1, which
        %   indicates an unknown or undefined BSS color.
        BSSColor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(BSSColor,-1),mustBeLessThanOrEqual(BSSColor,63)} = -1;
        %SpatialReuse Spatial reuse indication
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the SpatialReuse mode as an integer scalar between 0 and 15,
        %   inclusive, or -1. The default is -1, which indicates an unknown or
        %   undefined SpatialReuse mode.
        SpatialReuse (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse,-1),mustBeLessThanOrEqual(SpatialReuse,15)} = -1;
        %TXOPDuration Indicate the duration information for TXOP protection
        %   This property is set after decoding the U-SIG field and indicates
        %   TXOPDuration information in U-SIG field as an integer scalar
        %   between 0 and 8448, inclusive, or -1 as specified in Table 36-1 of
        %   IEEE P802.11be/D5.0. For more information see the the documentation.
        %   The default is -1, which indicates an unknown or unspecified
        %   duration for TXOP protection.
        TXOPDuration (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(TXOPDuration,-1),mustBeLessThanOrEqual(TXOPDuration,8448)} = -1;
        %AllocationIndex Indicate RU allocation index for each 20 MHz subchannel
        %   This property is set after decoding the EHT-SIG field. Each element
        %   of AllocationIndex represents a 20 MHz subchannel and defines the
        %   size and number of RUs, and the number of users assigned to each
        %   RU. AllocationIndex is a scalar, a row vector, or a matrix. IEEE
        %   P802.11be/D5.0, Table 36-34 defines the AllocationIndex for each 20
        %   MHz subchannel. The RU allocation for each AllocationIndex can be
        %   viewed in the documentation. This property applies only to an OFDMA
        %   configuration. The default is -1, which indicates an unknown or
        %   undefined RU allocation index.
        AllocationIndex {wlan.internal.mustBeValidAllocationIndex(AllocationIndex)} = -1;
        %NumNonOFDMAUsers Number of users in non-OFDMA transmission
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the number of non-OFDMA users. The default is -1, which indicates
        %   an unknown or undefined number of non-OFDMA users.
        NumNonOFDMAUsers (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(NumNonOFDMAUsers,[-1 1:8])} = -1;
        %NumUsersPerContentChannel Indicate the number of users per EHT-SIG content channel
        %   This property is set after decoding the EHT-SIG field. The
        %   recovered bits indicate the number of users in each EHT-SIG content
        %   channel. This property applies to OFDMA and non-OFDMA
        %   configurations. For non-OFDMA transmission the size of
        %   NumUsersPerContentChannel is 1-by-C, where C is the number of
        %   content channels. For OFDMA transmissions the size of
        %   NumUsersPerContentChannel is L-by-C, where L is the number of 80
        %   MHz subblocks. The distribution of users on EHT-SIG content
        %   channels is defined in Section 36.3.12.8.5 of IEEE P802.11be/D5.0.
        %   The default is -1, which indicates an unknown or undefined number
        %   of users.
        NumUsersPerContentChannel {wlan.internal.mustBeValidEHTNumUsersPerContentChannel(NumUsersPerContentChannel)} = -1;
        %RUTotalSpaceTimeStreams Indicate the total number of space time streams in the RU of interest
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the total number of space time streams in an RU, as an integer
        %   scalar between 1 and 8, inclusive, or -1. The default is -1, which
        %   indicates an unknown or undefined number of total space time
        %   streams in an RU.
        RUTotalSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(RUTotalSpaceTimeStreams,[-1 1:8])} = -1;
        %RUSize Indicate the resource unit size for the user of interest
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the resource unit size for the user of interest as a scalar, or a
        %   column vector for an MRU. The RU size must be one of 26, 52, 106,
        %   242, 484, 968, 996, 1992 (2x996), 3984 (4x996), or -1. The default
        %   is -1, which indicates an unknown or undefined resource unit size.
        RUSize (1,:) {mustBeNumeric,mustBeMember(RUSize,[-1 26 52 106 242 484 968 996 1992 3984])} = -1;
        %RUIndex Indicate the resource unit index for the user of interest
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the RU index. The RU index is a scalar, or a column vector for an
        %   MRU. The RU index specifies the location of the RU within the
        %   channel. For example, in an 80 MHz transmission there are four
        %   possible 242 tone RUs, one in each 20 MHz subchannel. RU# 242-1
        %   (size 242, index 1) is the RU occupying the lowest absolute
        %   frequency within the 80 MHz, and RU# 242-4 (size 242, index 4) is
        %   the RU occupying the highest absolute frequency. The default value
        %   for this property is -1, which indicates an unknown or undefined
        %   resource unit index.
        RUIndex {mustBeNumeric,mustBeInteger,mustBeMember(RUIndex,[-1 1:148])} = -1;
        %PuncturedPattern Indicate puncturing pattern for OFDMA
        %   This property is set after decoding the U-SIG field and indicates
        %   which 20 MHz subchannel is punctured in the 80 MHz frequency
        %   subblock for CBW80, CBW160, and CBW320, as defined in Table 36-28
        %   of IEEE P802.11be/D5.0. PuncturedPattern is L-by-4, where L is the
        %   number of 80 MHz subblocks. L is 1, 2, and 4 for CBW80, CBW160, and
        %   CBW320, respectively. A value of 0 indicates that the corresponding
        %   20 MHz channel is punctured, and a value of 1 is used otherwise.
        %   This property applies only to a OFDMA configuration. The default
        %   value is -1, which indicates an unknown or undefined puncturing
        %   pattern.
        PuncturedPattern {wlan.internal.mustBeValidPuncturedPattern(PuncturedPattern)} = -1;
        %PuncturedChannelFieldValue Indicate puncturing pattern value for non-OFDMA
        %   This property indicates the puncturing pattern value for a
        %   non-OFDMA configuration as a scalar between 0 and 24 (inclusive),
        %   as defined in Table 36-30 of IEEE P802.11be/D5.0. This property is
        %   set after decoding the U-SIG field and applies only to a non-OFDMA
        %   configuration. The default value is -1, which indicates an unknown
        %   or undefined state of punctured channel field value.
        PuncturedChannelFieldValue {mustBeNumeric,mustBeInteger,mustBeMember(PuncturedChannelFieldValue,-1:24)} = -1;
        %STAID Indicate the station identification number for the user of interest
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the STAID of the user of interest. The STAID is defined in IEEE
        %   P802.11be/D5.0, Section 36.3.12.8.5. The 11 LSBs of the AID field
        %   are used to address the STA. When STAID is set to 2046 the
        %   associated RU carries no data. The default value for this property
        %   is -1, which indicates an unknown or undefined station
        %   identification.
        STAID (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(STAID,-1:2047)} = -1;
        %MCS Indicate modulation and coding scheme for the user of interest
        %   This property is set after decoding the EHT-SIG field and
        %   indicates the modulation and coding scheme as an integer scalar.
        %   The MCS must be an integer between 0 and 15, inclusive. The
        %   default value for this property is -1, which indicates an unknown
        %   or undefined MCS value.
        MCS (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(MCS,-1:15)} = -1;
        %ChannelCoding Indicate forward error correction coding type of the user of interest
        %   This property is set after decoding the EHT-SIG field and
        %   indicates the channel coding as one of 'bcc' or 'ldpc' to indicate
        %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
        %   coding for the use of interest. The default value for this property
        %   is 'unknown', which indicates an unknown or undefined channel
        %   coding type.
        ChannelCoding (1,1) wlan.type.RecoveredChannelCoding = wlan.type.RecoveredChannelCoding.unknown;
        %Beamforming Indicate beamforming
        %   This property is set after decoding the EHT-SIG field and indicates
        %   beamforming for OFDMA and sounding NDP transmission. The default
        %   value for this property is -1, which indicates an unknown or
        %   undefined beamforming value.
        Beamforming (1,1) double {wlan.internal.mustBeLogicalOrUnknown(Beamforming,'Beamforming')} = -1;
        %NumSpaceTimeStreams Indicate the number of space-time streams for the user of interest
        %   This property is set after decoding the EHT-SIG field. The decoded
        %   bits indicate the number of space-time streams for the user as an
        %   integer scalar between 1 and 8, inclusive. The default value for
        %   this property is -1, which indicates an unknown or undefined number
        %   of space-time streams.
        NumSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(NumSpaceTimeStreams,[-1 1:8])} = -1;
        %SpaceTimeStreamStartingIndex Indicate the starting space time stream index for the user of interest
        %   This property is set after decoding the EHT-SIG field and indicates
        %   the starting space-time stream index as an integer scalar between 1
        %   and 8, inclusive. When multiple users are transmitting in the same
        %   RU, in a MU-MIMO configuration, each user must transmit on
        %   different space-time streams. The SpaceTimeStreamStartingIndex and
        %   NumSpaceTimeStreams properties indicate that each user has a
        %   different space-time stream. The default value for this property is
        %   -1, which indicates an unknown or undefined starting space-time
        %   stream index.
        SpaceTimeStreamStartingIndex (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(SpaceTimeStreamStartingIndex,[-1 1:8])} = -1;
        %Channelization Indicate channelization for 320 MHz
        %   This property is set after decoding the U-SIG field and indicates
        %   the channelization for 320 MHz channel bandwidth as 1 or 2,
        %   corresponding to '320MHz-1' and '320MHz-2' in Section 36.3.24.2 of
        %   IEEE P802.11be/D5.0. This property applies only when the channel
        %   bandwidth is 320 MHz. The default value is -1, which indicates an
        %   unknown or undefined channelization for 320 MHz.
        Channelization (1,1) {mustBeMember(Channelization,[-1 1 2])} = -1;
    end

    properties (Dependent, SetAccess = 'private', GetAccess = 'public')
        %PPDUType Indicate the recovered EHT PPDU type
        %   This property is set after decoding the U-SIG field and indicates
        %   the recovered EHT PPDU type as one of 'su', 'dl_mumimo',
        %   'dl_ofdma', 'ndp', or 'unknown'. This property is read-only and
        %   'unknown' indicates an unknown or undefined EHT PPDU Type.
        PPDUType wlan.type.EHTPPDUType;
        %EHTDUPMode Indicate EHT DUP mode
        %   This property is set after decoding the U-SIG field and indicates
        %   if EHT DUP mode is used. The value is a logical or a double. A
        %   logical true indicates EHT DUP mode is used. This property is
        %   read-only and applies only to a non-OFDMA configuration when the
        %   channel bandwidth is 80 MHz, 160 MHz, or 320 MHz. A value of -1
        %   indicates an unknown or undefined EHT DUP mode.
        EHTDUPMode double;
    end

    properties (Access='public',Hidden)
        %UsersSignaledInSingleSubblock Indicates, if the OFDMA users are signaled in a single 80 MHz subblock
        %   This property is set after decoding the EHT-SIG common field using
        %   the number of EHT-SIG field symbols. It indicates if the users are
        %   signaled in a single 80 MHz subblock. This property is applicable
        %   only for 160/320 MHz, and when the RU size of the resource unit is
        %   less than 242-tone RU. True means that the users are signaled in a
        %   single 80 MHz subblock, hence there is no repetition of users
        %   information across other 80 MHz subblocks. A value of -1 indicates
        %   an unknown or undefined state.
        UsersSignaledInSingleSubblock (1,1) double = -1;
    end

    properties(Constant,Hidden)
        ChannelBandwidth_Values = {'CBW20','CBW40','CBW80','CBW160','CBW320','unknown'};
    end

    methods
        function obj = wlanEHTRecoveryConfig(varargin)
            if ~isempty(coder.target)
                % Add variable size support in code generation
                defaultValVect = -1;
                coder.varsize("defaultValVect",[1 148],[0 1])
                obj.RUSize = defaultValVect;
                obj.RUIndex = defaultValVect;

                defaultValMatrix = -1;
                coder.varsize("defaultValMatrix",[4 16],[1 1])
                obj.AllocationIndex = defaultValMatrix;
            end

            obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
        end

        function obj = set.ChannelBandwidth(obj,val)
            propName = 'ChannelBandwidth';
            val = validateEnumProperties(obj,propName,val);
            obj.(propName) = val;
        end

        function val = get.PPDUType(obj)
        % Returns EHT PPDU type of an EHT MU packet
            if isnumeric(obj.ChannelBandwidth) || obj.CompressionMode==-1
                val = wlan.type.EHTPPDUType.unknown;
            else
                if obj.CompressionMode==1
                    if obj.NumEHTSIGSymbolsSignaled==1 && obj.EHTSIGMCS==0
                        val = wlan.type.EHTPPDUType.ndp;
                    elseif (obj.NumEHTSIGSymbolsSignaled==1 && any(obj.EHTSIGMCS==[1 3])) || (obj.NumEHTSIGSymbolsSignaled==2 && obj.EHTSIGMCS==0) || (obj.NumEHTSIGSymbolsSignaled==4 && obj.EHTSIGMCS==15) % EHT SU
                        val = wlan.type.EHTPPDUType.su;
                    else
                        val = wlan.type.EHTPPDUType.unknown;
                    end
                elseif obj.CompressionMode==2
                    val = wlan.type.EHTPPDUType.dl_mumimo;
                else % CompressionMode==0
                    val = wlan.type.EHTPPDUType.dl_ofdma;
                end
            end
        end

        function val = get.EHTDUPMode(obj)
        %Returns an EHT DUP mode support
            if obj.MCS~=14 && obj.PPDUType~=wlan.type.EHTPPDUType.unknown
                val = 0;
            elseif obj.MCS==14 && obj.PPDUType==wlan.type.EHTPPDUType.su
                val = 1;
            else
                val = -1;
            end
        end

        function psduLen = psduLength(obj)
        %psduLength Returns the PSDU length in bytes for the recovered configuration. IEEE Std 802.11ax-2021, Section 27.4.3.

            if obj.PPDUType==wlan.type.EHTPPDUType.ndp
                psduLen = 0;
            else
                validateCodingRUArguments(obj);
                s = validateConfig(obj);
                nsymCalc = s.NumDataSymbols;
                wlan.internal.mustBeDefined(obj.LDPCExtraSymbol,'LDPCExtraSymbol');
                mcs = obj.MCS;
                if any(mcs==[14 15])
                    dcm = true;
                else
                    dcm = false;
                end
                params = wlan.internal.heRecoverCodingParameters(nsymCalc,obj.PreFECPaddingFactor,sum(obj.RUSize),mcs,obj.NumSpaceTimeStreams, ...
                                                                 obj.ChannelCoding,false,dcm,obj.LDPCExtraSymbol,obj.EHTDUPMode);
                psduLen = params.PSDULength;
            end
        end

        function format = packetFormat(obj) %#ok<MANU>
        %packetFormat Returns the EHT packet type
        %   Returns the EHT packet type as a character vector

            format = 'EHT-MU';
        end

        function [mode,isNDP] = compressionMode(obj)
        %compressionMode Returns compression mode and NDP information as defined in IEEE P802.11be/D5.0, Table 36-29

            mode = obj.CompressionMode;
            isNDP = obj.PPDUType==wlan.type.EHTPPDUType.ndp;
        end

        function [obj,failInterpretation] = interpretUSIGBits(obj,usigBits,failCRC)
        %interpretUSIGBits Interpret U-SIG bits
        %   obj = interpretUSIGBits(obj,USIGBITS,FAILCRC) parses and interprets
        %   decoded U-SIG bits and returns an updated recovery object with the
        %   relevant U-SIG field set. The U-SIG bit fields are defined in IEEE
        %   P802.11be/D5.0, Table 36-28. When you use this syntax and the
        %   function cannot interpret the recovered U-SIG bits due to an
        %   unexpected value, an exception is issued, and the function does not
        %   return an output.
        %
        %   USIGBITS is a matrix of size 52-by-L, consisting of recovered U-SIG
        %   information bits. Where L is the number of 80 MHz subblocks:
        %   - L is 1 for 20 MHz, 40 MHz and 80 MHz
        %   - L is 2 for 160 MHz
        %   - L is 4 for 320 MHz
        %
        %   FAILCRC is a row vector of length L.
        %
        %   [...,FAILINTERPRETATION] = interpretUSIGBits(...) when you use
        %   this syntax and the function cannot interpret the recovered
        %   U-SIG bits due to an unexpected value, the function returns the
        %   input obj with no change.
        %
        %   FAILINTERPRETATION is a logical scalar that represents the result
        %   of interpreting the recovered U-SIG field bits. The function
        %   returns this as true when it cannot interpret the received U-SIG
        %   bits.
        %
        %   For a non-OFDMA EHT MU packet (which includes EHT SU, MU-MIMO, and
        %   NDP PPDU types), the following properties are updated after
        %   interpreting the U-SIG bits.
        %
        %   * ChannelBandwidth
        %   * CompressionMode
        %   * EHTSIGMCS
        %   * NumEHTSIGSymbolsSignaled
        %   * UplinkIndication
        %   * BSSColor
        %   * TXOPDuration
        %   * RUSize
        %   * RUIndex
        %   * PuncturedChannelFieldValue
        %   * Channelization
        %   * PPDUType

            wlan.internal.mustBeDefined(obj.ChannelBandwidth,'ChannelBandwidth');
            numcols = max(1,wlan.internal.cbwStr2Num(obj.ChannelBandwidth)/80);
            validateattributes(usigBits,{'double','int8'},{'2d','binary','nrows',52,'ncols',numcols},mfilename,'U-SIG bits');
            validateattributes(failCRC,{'double','logical'},{'2d','nrows',1,'ncols',numcols},mfilename,'Fail CRC');
            suppressError = nargout==2; % Validate the interpreted bit values
            inputObj = obj; % Copy of the input object
            [obj,failInterpretation] = wlan.internal.interpretUSIGBits(usigBits,failCRC,obj,suppressError);
            if failInterpretation
                obj = inputObj; % Return the input object with no change
            end
        end

        function [obj,failInterpretation] = interpretEHTSIGCommonBits(obj,bits,failCRC)
        %interpretEHTSIGCommonBits Interpret EHT-SIG common field bits
        %   obj = interpretEHTSIGCommonBits(obj,BITS,FAILCRC) parses and
        %   interprets decoded EHT-SIG common bits and returns an updated
        %   recovery object with the relevant EHT-SIG fields set. When you use
        %   this syntax and the function cannot interpret the recovered EHT-SIG
        %   common field bits due to an unexpected value, an exception is
        %   issued, and the function does not return an output.
        %
        %   BITS is a binary matrix containing the recovered common field bits
        %   for each content channel of the EHT-SIG field.
        %
        %   # For non-OFDMA
        %       The EHT-SIG common bit fields are defined in Table 36-36 of
        %       IEEE P802.11be/D5.0 for EHT SU and MU-MIMO, and Table 36-37 for
        %       NDP. The size of the BITS input depends on the PPDU type:
        %
        %       * For EHT SU the size is 20-by-1
        %       * For NDP the size is 16-by-1
        %       * For MU-MIMO the size is 20-by-C
        %
        %   # For OFDMA
        %       The EHT-SIG common bit fields are defined in Table 36-33 of
        %       IEEE P802.11be/D5.0. The size of the BITS input depends on the
        %       channel bandwidth:
        %
        %       * For CBW20 and CBW40 the size is 36-by-C
        %       * For CBW80 the size is 45-by-C
        %       * For CBW160 the size is 73-by-C-by-L
        %       * For CBW320 the size is 109-by-C-by-L
        %
        %   Where C is the number of content channels. It is 1 for 20 MHz and 2
        %   for all other bandwidths. L is the number of 80 MHz subblocks:
        %       * L is 1 for 20 MHz, 40 MHz and 80 MHz
        %       * L is 2 for 160 MHz
        %       * L is 4 for 320 MHz
        %
        %   FAILCRC represents the result of the CRC for each common encoding
        %   block and content channel. True represents a CRC failure. FAILCRC
        %   is an array of size X-by-C-by-L. Where X is the number of EHT-SIG
        %   common encoding blocks. X is 1 for non-OFDMA configurations. For
        %   OFDMA configurations X is 1 for 20 MHz, 40 MHz, and 80 MHz, and 2
        %   for all other bandwidths. See Figure 36-31 and Figure 36-32 of IEEE
        %   P802.11be/D5.0.
        %
        %   [...,FAILINTERPRETATION] = interpretEHTSIGCommonBits(...) when you
        %   use this syntax and the function cannot interpret the recovered
        %   EHT-SIG common field bits due to an unexpected value, the function
        %   returns the input obj with no change.
        %
        %   FAILINTERPRETATION is a logical scalar that represents the result
        %   of interpreting the recovered EHT-SIG field bits. The function
        %   returns this as true when it cannot interpret the received EHT-SIG
        %   bits.
        %
        %  For a non-OFDMA EHT MU packet, the function updates different
        %  properties of the recovery object depending on the PPDU type. If the
        %  PPDU type is EHT SU or MU-MIMO, the following properties are
        %  updated:
        %
        %   * SpatialReuse
        %   * GuardInterval
        %   * EHTLTFType
        %   * NumEHTLTFSymbols
        %   * LDPCExtraSymbol
        %   * PreFECPaddingFactor
        %   * PEDisambiguity
        %   * NumNonOFDMAUsers
        %   * NumUsersPerContentChannel
        %
        %   If the PPDU type is sounding NDP, the following properties are
        %   updated:
        %
        %   * SpatialReuse
        %   * GuardInterval
        %   * EHTLTFType
        %   * NumEHTLTFSymbols
        %   * RUTotalSpaceTimeStreams
        %   * NumSpaceTimeStreams
        %   * Beamforming
        %
        %   If the PPDU type is OFDMA, the following properties are updated:
        %
        %   * SpatialReuse
        %   * GuardInterval
        %   * EHTLTFType
        %   * NumEHTLTFSymbols
        %   * LDPCExtraSymbol
        %   * PreFECPaddingFactor
        %   * PEDisambiguity
        %   * NumUsersPerContentChannel
        %   * AllocationIndex

            suppressError = nargout==2; % Validate the interpreted bit values
                                        % Validate channel bandwidth
            wlan.internal.mustBeDefined(obj.ChannelBandwidth,'ChannelBandwidth');
            wlan.internal.mustBeDefined(obj.PPDUType,'PPDUType');
            cbw = wlan.internal.cbwStr2Num(obj.ChannelBandwidth);
            validateCompression(obj);

            % The size of the EHTSIGBITS depends on the PPDUType and channel bandwidth
            switch obj.PPDUType
              case wlan.type.EHTPPDUType.su
                dimBits = [20,1];
                dimFailCRC = [1,1]; % X-by-C
              case wlan.type.EHTPPDUType.ndp
                dimBits = [16,1];
                dimFailCRC = [1,1]; % X-by-C
              case wlan.type.EHTPPDUType.dl_mumimo
                if cbw==20
                    dimBits = [20,1];
                    dimFailCRC = [1,1]; % X-by-C
                else
                    dimBits = [20,2];
                    dimFailCRC = [1,2]; % X-by-C
                end
              otherwise % OFDMA
                switch cbw
                  case 20
                    dimBits = [36,1]; % 36-by-C
                    dimFailCRC = [1,1]; % X-by-C
                  case 40
                    dimBits = [36,2]; % 36-by-C
                    dimFailCRC = [1,2]; % X-by-C
                  case 80
                    dimBits = [45,2]; % 45-by-C
                    dimFailCRC = [1,2]; % X-by-C
                  case 160
                    dimBits = [73,2,2]; % 73-by-C-by-L
                    dimFailCRC = [2,2,2]; % X-by-C-by-L
                  otherwise % 320 MHz
                    dimBits = [109,2,4]; % 109-by-C-by-L
                    dimFailCRC = [2,2,4]; % X-by-C-by-L
                end
            end
            validateattributes(bits,{'double','int8'},{'3d','binary','size',dimBits},mfilename,'EHT-SIG field bits');
            validateattributes(failCRC,{'double','logical'},{'3d','binary','size',dimFailCRC},mfilename,'failCRC');

            % Interpret EHT-SIG common field bits
            [obj,failInterpretation] = wlan.internal.interpretEHTSIGCommonBits(bits,failCRC,obj,suppressError);
        end

        function [user,failInterpretation] = interpretEHTSIGUserBits(obj,bits,failCRC)
        %interpretEHTSIGUserBits Interpret EHT-SIG user field bits
        %   USER = interpretEHTSIGUserBits(obj,BITS,FAILCRC) parses and
        %   interprets decoded EHT-SIG user field bits. The returned USER is a
        %   cell array of size 1-by-NumUsers. USER is the updated format
        %   configuration object after EHT-SIG user field decoding, of type
        %   wlanEHTRecoveryConfig. When you use this syntax and the
        %   function cannot interpret the recovered EHT-SIG user field bits
        %   due to an unexpected value, an exception is issued and the function
        %   does not return.
        %
        %   BITS is a binary matrix of size 22-by-NumUsers, where NumUsers is
        %   the number of users in the transmission, containing the recovered
        %   user field bits for all users.
        %
        %   FAILCRC is a logical row vector of length NumUsers representing the
        %   CRC result for each user. It is true if the user fails the CRC. It
        %   is a logical row vector of size 1-by-NumUsers.
        %
        %   [...,FAILINTERPRETATION] = interpretEHTSIGUserBits(...) when you
        %   use this syntax and the function cannot interpret the recovered
        %   EHT-SIG user field bits due to an unexpected value, the function
        %   does not return the respective USER object.
        %
        %   FAILINTERPRETATION is a logical row vector of size 1-by-NumUsers,
        %   and represent the result of interpreting the recovered EHT-SIG
        %   user field bits. Each element of FAILINTERPRETATION corresponds to
        %   a user and is true when the received EHT-SIG user field bits
        %   cannot be interpreted.
        %
        %   The following properties of the recovery object are updated for a
        %   non-MU-MIMO allocation:
        %
        %   * STAID
        %   * MCS
        %   * NumSpaceTimeStreams
        %   * Beamforming
        %   * ChannelCoding
        %
        %   The following properties of the recovery object are updated for a
        %   MU-MIMO allocation:
        %
        %   * STAID
        %   * MCS
        %   * ChannelCoding
        %   * NumSpaceTimeStreams

            suppressError = nargout==2; % Validate the interpreted bit values
                                        % Validate channel bandwidth
            wlan.internal.mustBeDefined(obj.ChannelBandwidth,'ChannelBandwidth');
            wlan.internal.mustBeDefined(obj.PPDUType,'PPDUType');
            validateCompression(obj);

            coder.varsize("failInterpretation",[1 Inf],[1 1])
            failInterpretation = validateEHTLTFGI(obj,suppressError);
            if failInterpretation
                user = {}; % No user configuration object is returned
                return
            end

            % Validate inputs based on the users signaled under content channels
            wlan.internal.mustBeDefined(obj.NumUsersPerContentChannel,'NumUsersPerContentChannel');
            isOFDMA = obj.PPDUType==wlan.type.EHTPPDUType.dl_ofdma;
            if isOFDMA
                if any(obj.NumUsersPerContentChannel==-1,'all')
                    failInterpretation = true; % If there is a content channel failure
                    user = {}; % No user configuration object is returned
                    return
                end
                allocInfo = wlan.internal.ehtAllocationParams(obj.AllocationIndex);
                if allocInfo.IsSameEHTSignalling && sum(obj.NumUsersPerContentChannel,'all')~=width(bits)
                    % For 160/320 MHz same users are signaled in all 80 MHz
                    % subblocks, hence there are same users bits in all 80 MHz
                    % subblocks. In this case the input BITS contains the
                    % recovered users bits in a single 80 MHz subblock. The
                    % total number of users are the users signaled in a single
                    % 80 MHz subblock.
                    numUsers = sum(obj.NumUsersPerContentChannel(1,:)); % Number of users in a single 80 MHz subblock
                else
                    % For 160/320 MHz, if the users are signaled in their
                    % respective subblocks, then the total number of users is
                    % the sum of users across all 80 MHz subblocks.
                    numUsers = sum(obj.NumUsersPerContentChannel,'all');
                end
            else % non-OFDMA
                wlan.internal.mustBeDefined(obj.NumNonOFDMAUsers,'NumNonOFDMAUsers');
                % Need to index into NumUsersPerContentChannel, otherwise
                % error checking in generated code gets confused
                coder.internal.assert(isvector(obj.NumUsersPerContentChannel), ...
                                      'wlan:codegen:NotAVector','NumUsersPerContentChannel');
                numUsersPerCC = obj.NumUsersPerContentChannel(1,:);
                numUsers = sum(numUsersPerCC(numUsersPerCC~=-1));
            end
            validateattributes(bits,{'double','int8'},{'2d','binary','nrows',22,'ncols',numUsers},mfilename,'EHT-SIG field bits');
            validateattributes(failCRC,{'double','logical'},{'2d','binary','nrows',1,'ncols',numUsers},mfilename,'failCRC');

            % Interpret EHT-SIG user field bits
            [usersCfg,failInterpretation] = wlan.internal.interpretEHTSIGUserBits(bits,failCRC,obj,suppressError);

            % Dependent validation on all users
            if ~all(failInterpretation,2) % Do not process if all users fails independent property validation
                for u=1:numel(failInterpretation)
                    if failInterpretation(u)==0
                        failInterpretation(u) = validateCodingRUArguments(usersCfg{u},suppressError);
                        if failInterpretation(u)==1
                            continue
                        end
                        if obj.EHTDUPMode
                            failInterpretation(u) = validateEHTDUPMode(usersCfg{u},suppressError);
                            continue
                        end
                        if obj.MCS==15
                            failInterpretation(u) = validateMCS15(usersCfg{u},suppressError);
                            continue
                        end
                    end
                end
                if ~all(failInterpretation,2) % Do not process if all users fails validation
                    numValidUsers = nnz(failInterpretation==0); % Number of valid users
                    user = repmat({obj},[1 numValidUsers(1)]);
                    if numValidUsers>0
                        idx = 1;
                        for u=1:numel(failInterpretation)
                            if failInterpretation(u)==0
                                user{idx} = usersCfg{u};
                                idx = idx+1;
                            end
                        end
                    end
                else % All users fail validation check
                    user = {};
                end
            else % All users fail validation check
                user = {};
            end
        end

        function s = ruInfo(obj)
        %ruInfo Returns RU allocation information
        %   S = ruInfo(CFG) returns a structure, S, containing the resource
        %   unit (RU) allocation information for the wlanEHTRecoveryConfig
        %   object, CFG. The output structure S has these fields:
        %
        %   NumUsers                  - Number of users
        %   NumRUs                    - Number of RUs
        %   RUIndices                 - Index of the RU/MRU
        %   RUSizes                   - Size of the RU/MRU
        %   NumUsersPerRU             - Number of users per RU
        %   NumSpaceTimeStreamsPerRU  - Total number of space-time streams
        %   PowerBoostFactorPerRU     - Power boost factor (1)
        %   RUNumbers                 - RU number (1)

            s = struct;
            s.NumUsers = -1;
            s.NumRUs = -1;
            s.RUIndices = {-1};
            s.RUSizes = {-1};
            s.NumUsersPerRU = -1;
            s.NumSpaceTimeStreamsPerRU = -1;
            s.PowerBoostFactorPerRU = -1;
            s.RUNumbers = -1;
            if obj.PPDUType~=wlan.type.EHTPPDUType.unknown && obj.RUTotalSpaceTimeStreams~=-1
                if (any(obj.PPDUType==[wlan.type.EHTPPDUType.ndp wlan.type.EHTPPDUType.su]) || obj.EHTDUPMode==1) && obj.PuncturedChannelFieldValue~=-1 % NDP, EHT SU, or EHT DUP mode
                    allocInfo = wlan.internal.ehtAllocationInfo(obj.ChannelBandwidth,1,obj.PuncturedChannelFieldValue,obj.EHTDUPMode==1);
                    s.NumUsers = 1;
                    s.NumUsersPerRU = 1;
                    numRUs = 1;
                    ruNumbers = 1;
                elseif obj.PPDUType==wlan.type.EHTPPDUType.dl_mumimo && obj.NumNonOFDMAUsers~=-1 && obj.PuncturedChannelFieldValue~=-1 % MU-MIMO
                    allocInfo = wlan.internal.ehtAllocationInfo(obj.ChannelBandwidth,1,obj.PuncturedChannelFieldValue,false);
                    s.NumUsers = obj.NumNonOFDMAUsers;
                    s.NumUsersPerRU = obj.NumNonOFDMAUsers;
                    numRUs = 1;
                    ruNumbers = 1;
                elseif obj.PPDUType==wlan.type.EHTPPDUType.dl_ofdma && ~any(obj.AllocationIndex==-1,'all') % OFDMA
                    allocInfo = wlan.internal.ehtAllocationParams(obj.AllocationIndex);
                    s.NumUsers = allocInfo.NumUsers;
                    s.NumUsersPerRU = allocInfo.NumUsersPerRU;
                    numRUs = allocInfo.NumRUs;
                    ruNumbers = 1:numRUs;
                else % Undefined or unknown state
                    return;
                end
                s.NumSpaceTimeStreamsPerRU = obj.RUTotalSpaceTimeStreams;
                s.RUIndices = allocInfo.RUIndices;
                s.RUSizes = allocInfo.RUSizes;
                s.PowerBoostFactorPerRU = 1;
                s.NumRUs = numRUs;
                s.RUNumbers = ruNumbers;
            end
        end

        function varargout = validateConfig(obj,varargin)
        %validateConfig Validate the dependent properties of wlanEHTRecoveryConfig object
        %   validateConfig(obj) validates the dependent properties for the
        %   specified wlanEHTRecoveryConfig configuration object.
        %
        %   For INTERNAL use only, subject to future changes
        %
        %   S = validateConfig(CFG,MODE) validates only the subset of dependent
        %   properties as specified by the MODE input and returns structure
        %   array S:
        %
        %    - NumDataSymbols - Number of EHT-Data symbols
        %    - RxTime         - RxTime in microseconds
        %    - TPE            - Packet extension field duration in microseconds
        %
        %   MODE must be one of:
        %       'EHTLTFGI'
        %       'Coding'
        %       'EHTDUPMode'
        %       'EHTMCS15'
        %       'DataLocationLength'
        %       'Full'
        %
        %   The structure, S is only defined or initialized when MODE is set to
        %   'DataLocationLength' or 'Full'.
        %
        %   [...,FAILINTERPRETATION] = validateConfig(...,SUPPRESSERROR)
        %   controls the behaviour of the function when validating the
        %   dependent properties of obj. SUPPRESSERROR is logical. When
        %   SUPPRESSERROR is true, an invalid combination of the interpreted
        %   properties of the obj, sets FAILINTERPRETATION to true. When
        %   SUPPRESSERROR is false, an invalid combination of the interpreted
        %   properties of the obj results in an exception. The default is
        %   false;

            narginchk(1,3);
            nargoutchk(0,2);
            suppressError = false; % Control the validation
            if nargin==2 % validateConfig(obj,SUPPRESSERROR) or validateConfig(obj,MODE)
                if islogical(varargin{1}) % validateConfig(obj,SUPPRESSERROR)
                    suppressError = varargin{1};
                    mode = 'Full';
                else % validateConfig(obj,MODE)
                    mode = varargin{1};
                end
            elseif nargin==3 % validateConfig(obj,MODE,SUPPRESSERROR)
                if ischar(varargin{1}) && islogical(varargin{2})
                    mode = varargin{1};
                    suppressError = varargin{2};
                else
                    coder.internal.error('wlan:wlanEHTRecoveryConfig:IncorrectValidationSyntax');
                end
            else
                mode = 'Full';
            end

            s = struct('NumDataSymbols', -1, ...
                       'RxTime', -1, ...
                       'TPE', -1);
            failInterpretation = false;
            varargout{1} = s;

            switch mode
              case 'EHTSIG'
                % Validate fields required for compression mode
                validateCompression(obj);
              case 'EHTLTFGI'
                % Validate the EHT-LTF type and GuardInterval
                failInterpretation = validateEHTLTFGI(obj,suppressError);
              case 'Coding'
                % Validate coding parameters
                failInterpretation = validateCodingRUArguments(obj,suppressError);
              case 'EHTDUPMode'
                % Validate EHT DUP mode
                failInterpretation = validateEHTDUPMode(obj,suppressError);
              case 'EHTMCS15'
                % Validate MCS-15
                failInterpretation = validateMCS15(obj,suppressError);
              case 'DataLocationLength' % wlanFieldIndices (EHT-Data and EHT-LTF)
                                        % Validate MCS and LSIGLength
                [s,failInterpretation] = validateLength(obj,suppressError);
              otherwise
                % Validate EHTLTFType and GuardInterval for EHT-LTF
                failInterpretation = validateEHTLTFGI(obj,suppressError);
                if failInterpretation
                    varargout{2} = failInterpretation;
                    return;
                end

                % Validate MCS and LSIGLength
                [s,failInterpretation] = validateLength(obj,suppressError);
                if failInterpretation
                    varargout{2} = failInterpretation;
                    return;
                end
            end
            varargout{1} = s;
            varargout{2} = failInterpretation;
        end
    end

    methods (Access = private)
        function validateCompression(obj)
        %validateCompression Validate field required for compression mode
        %
        %   Validated property-subset includes:
        %     CompressionMode, EHTSIGMCS, NumEHTSIGSymbolsSignaled

            wlan.internal.mustBeDefined(obj.CompressionMode,'CompressionMode'); % Check for undefined state
            wlan.internal.mustBeDefined(obj.EHTSIGMCS,'EHTSIGMCS'); % Check for undefined state
            wlan.internal.mustBeDefined(obj.NumEHTSIGSymbolsSignaled,'NumEHTSIGSymbolsSignaled'); % Check for undefined state
        end

        function failInterpretation = validateEHTLTFGI(obj,varargin)
        %validateEHTLTFGI Validate the EHT-LTF type and GuardInterval
        %   FAILINTERPRETATION = validateEHTLTFGI(obj) validates the dependent
        %   properties for the specified wlanEHTRecoveryConfig configuration
        %   object.
        %
        %   FAILINTERPRETATION = validateEHTLTFGI(...,SUPPRESSERROR) controls
        %   the behaviour of the function when validating the dependent
        %   properties of obj. SUPPRESSERROR is logical. When SUPPRESSERROR is
        %   true, an invalid combination of the interpreted properties of the
        %   obj, sets FAILINTERPRETATION to true. When SUPPRESSERROR is false,
        %   an invalid combination of the interpreted properties of the obj
        %   results in an exception.
        %
        %   Validated property-subset includes:
        %     EHTLTFType, GuardInterval

            suppressError = false; % Control the validation
            if nargin>1
                suppressError = varargin{1};
            end
            failInterpretation = false;

            % Check for undefined state
            validateConfig(obj,'EHTSIG');
            wlan.internal.mustBeDefined(obj.EHTLTFType,'EHTLTFType'); % Check for undefined state
            wlan.internal.mustBeDefined(obj.GuardInterval,'GuardInterval'); % Check for undefined state
            invalidCombination = obj.PPDUType==wlan.type.EHTPPDUType.ndp && (obj.EHTLTFType==4 && obj.GuardInterval==0.8);
            if suppressError && invalidCombination
                failInterpretation = true;
                return;
            else
                coder.internal.errorIf(invalidCombination,'wlan:eht:InvalidGILTFNDP',sprintf('%1.1f',obj.GuardInterval),obj.EHTLTFType);
            end

            invalidCombination = (obj.EHTLTFType~=2 && obj.GuardInterval==1.6) || (obj.EHTLTFType~=4 && obj.GuardInterval==3.2);
            if suppressError && invalidCombination
                failInterpretation = true;
                return;
            else
                coder.internal.errorIf(invalidCombination,'wlan:shared:InvalidGILTF',sprintf('%1.1f',obj.GuardInterval),'EHTLTFType',obj.EHTLTFType);
            end
        end

        function failInterpretation = validateCodingRUArguments(obj,varargin)
        %validateCodingRUArguments Coding and RU assignment properties of wlanEHTRecoveryConfig configuration object
        %   FAILINTERPRETATION = validateCodingRUArguments(obj) validates the
        %   dependent properties for the specified wlanEHTRecoveryConfig
        %   configuration object.
        %
        %   FAILINTERPRETATION = validateCodingRUArguments(...,SUPPRESSERROR)
        %   controls the behaviour of the function when validating the
        %   dependent properties of obj. SUPPRESSERROR is logical. When
        %   SUPPRESSERROR is true, an invalid combination of the interpreted
        %   properties of the obj, sets FAILINTERPRETATION to true. When
        %   SUPPRESSERROR is false, an invalid combination of the interpreted
        %   properties of the obj results in an exception. The default is
        %   false.
        %
        %   Validated property-subset includes:
        %     ChannelBandwidth, NumSpaceTimeStreams, MCS,
        %     ChannelCoding, RU Size, RU Index

        % Check for undefined state
            suppressError = false; % Control the validation of the interpreted bits
            if nargin>1
                suppressError = varargin{1};
            end
            failInterpretation = false;
            coder.internal.errorIf(obj.ChannelCoding==wlan.type.RecoveredChannelCoding.unknown,'wlan:shared:InvalidChannelCoding');
            wlan.internal.mustBeDefined(obj.MCS,'MCS');
            wlan.internal.mustBeDefined(obj.NumSpaceTimeStreams,'NumSpaceTimeStreams');

            % Validate RU sizes and channel bandwidth
            chanBW = wlan.internal.validateParam('EHTCHANBW',obj.ChannelBandwidth,mfilename);
            wlan.internal.mustBeDefined(obj.RUSize,'RUSize');
            wlan.internal.mustBeDefined(obj.RUIndex,'RUIndex');
            rusize = wlan.internal.validateEHTRUArgument(obj.RUSize,obj.RUIndex,wlan.internal.cbwStr2Num(chanBW));

            if obj.ChannelCoding==wlan.type.RecoveredChannelCoding.bcc
                failInterpretation = wlan.internal.failInterpretationIf(rusize>242,'wlan:shared:InvalidBCCRUSize',suppressError);
                if failInterpretation
                    return
                end

                failInterpretation = wlan.internal.failInterpretationIf(obj.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS',suppressError);
                if failInterpretation
                    return
                end

                failInterpretation = wlan.internal.failInterpretationIf(any(obj.MCS==[10 11 12 13]),'wlan:eht:InvalidBCCMCS',suppressError);
                if failInterpretation
                    return
                end
            end
        end

        function failInterpretation = validateEHTDUPMode(obj,varargin)
        %validateEHTDUPMode Validate EHT DUP mode
        %   FAILINTERPRETATION = validateEHTDUPMode(obj) validates the
        %   dependent properties for the specified wlanEHTRecoveryConfig
        %   configuration object.
        %
        %   FAILINTERPRETATION = validateEHTDUPMode(...,SUPPRESSERROR) controls
        %   the behaviour of the function when validating the dependent
        %   properties of obj. SUPPRESSERROR is logical. When SUPPRESSERROR is
        %   true, an invalid combination of the interpreted properties of the
        %   obj, sets FAILINTERPRETATION to true. When SUPPRESSERROR is false,
        %   an invalid combination of the interpreted properties of the obj
        %   results in an exception. The default is false.
        %
        %   Validated property-subset includes:
        %     NumSpaceTimeStreams, EHT-MCS 14

            suppressError = false; % Control the validation of the interpreted EHT-SIG bits
            if nargin>1
                suppressError = varargin{1};
            end

            % Check for undefined state
            wlan.internal.mustBeDefined(obj.NumSpaceTimeStreams,'NumSpaceTimeStreams');
            wlan.internal.mustBeDefined(obj.MCS,'MCS');
            wlan.internal.mustBeDefined(obj.EHTDUPMode,'EHTDUPMode');

            failInterpretation = wlan.internal.failInterpretationIf(obj.EHTDUPMode && obj.NumSpaceTimeStreams>1,'wlan:eht:InvalidDUPMode',suppressError);
            if failInterpretation
                return
            end
        end

        function failInterpretation = validateMCS15(obj,varargin)
        %validateMCS15 Validate EHT-MCS 15
        %   FAILINTERPRETATION = validateMCS15(obj) validates the dependent
        %   properties for the specified wlanEHTRecoveryConfig configuration
        %   object.
        %
        %   FAILINTERPRETATION = validateMCS15(...,SUPPRESSERROR) controls
        %   the behaviour of the function when validating the dependent
        %   properties of obj. SUPPRESSERROR is logical. When SUPPRESSERROR is
        %   true, an invalid combination of the interpreted properties of the
        %   obj, sets FAILINTERPRETATION to true. When SUPPRESSERROR is false,
        %   an invalid combination of the interpreted properties of the obj
        %   results in an exception. The default is false.
        %
        %   Validated property-subset includes:
        %     NumSpaceTimeStreams, MCS

            suppressError = false; % Control the validation of the interpreted U-SIG bits
            if nargin>1
                suppressError = varargin{1};
            end
            % Check for undefined state
            wlan.internal.mustBeDefined(obj.NumSpaceTimeStreams,'NumSpaceTimeStreams');
            wlan.internal.mustBeDefined(obj.MCS,'MCS');
            failInterpretation = wlan.internal.failInterpretationIf(obj.MCS==15 && obj.NumSpaceTimeStreams>1,'wlan:eht:InvalidMCS15NSTS',suppressError);
            if failInterpretation
                return
            end
        end

        function [s,failInterpretation] = validateLength(obj,varargin)
        %ValidateLength Length properties of wlanEHTRecoveryConfig configuration object
        %
        %   [S,FAILINTERPRETATION] = validateLength(...,SUPPRESSERROR) controls
        %   the behaviour of the function when validating the dependent
        %   properties of obj. SUPPRESSERROR is logical. When SUPPRESSERROR is
        %   true, an invalid combination of the interpreted properties of the
        %   obj, sets FAILINTERPRETATION to true. When SUPPRESSERROR is false,
        %   an invalid combination of the interpreted properties of the obj
        %   results in an exception. The default is false.
        %
        %   Validated property-subset includes:
        %     EHTLTFType, GuardInterval, EHTSIGMCS, CompressionMode,
        %     GuardInterval, PreFECPaddingFactor, NumEHTLTFSymbols, LSIGLength

        % Check for undefined state
            suppressError = false; % Control the validation of the interpreted values
            if nargin>1
                suppressError = varargin{1};
            end
            % Set output structure
            s = struct( ...
                'NumDataSymbols', -1, ...
                'RxTime', -1, ...% RxTime in us
                'TPE', -1);

            % Validate Channel bandwidth
            chanBW = wlan.internal.validateParam('EHTCHANBW',obj.ChannelBandwidth,mfilename);
            wlan.internal.mustBeDefined(obj.NumEHTLTFSymbols,'NumEHTLTFSymbols');
            wlan.internal.mustBeDefined(obj.LSIGLength,'LSIGLength');
            wlan.internal.mustBeDefined(obj.NumEHTSIGSymbolsSignaled,'NumEHTSIGSymbolsSignaled');
            NEHTLTF = obj.NumEHTLTFSymbols;
            NEHTSIG = obj.NumEHTSIGSymbolsSignaled;
            sf = 1e3; % Scaling factor to convert time in us into ns
            if obj.PPDUType==wlan.type.EHTPPDUType.ndp % Table 36-37 of IEEE P802.11be/D5.0
                trc = wlan.internal.ehtTimingRelatedConstants(chanBW,obj.GuardInterval,obj.EHTLTFType,4,0,0); % In microseconds (Set default for PreFECPaddingFactor, nominalPacketPadding, and Number of data symbols)
                TEHT_PREAMBLE = trc.TRLSIG+trc.TUSIG+NEHTSIG*trc.TEHTSIG+trc.TEHTSTFNT+NEHTLTF*trc.TEHTLTFSYM; % Equation 36-97 of IEEE P802.11be/D5.0
                NSYM = 0; % Section 36.3.18 of IEEE P802.11be/D5.0
                TPE = trc.TPE/sf; % TPE in us
            else % Table 36-33 and Table 36-36 of IEEE P802.11be/D5.0
                wlan.internal.mustBeDefined(obj.PreFECPaddingFactor,'PreFECPaddingFactor');
                wlan.internal.mustBeDefined(obj.PEDisambiguity,'PEDisambiguity');
                trc = wlan.internal.ehtTimingRelatedConstants(chanBW,obj.GuardInterval,obj.EHTLTFType,obj.PreFECPaddingFactor); % In microseconds
                TEHT_PREAMBLE = trc.TRLSIG+trc.TUSIG+NEHTSIG*trc.TEHTSIG+trc.TEHTSTFNT+NEHTLTF*trc.TEHTLTFSYM; % Equation 36-97 of IEEE P802.11be/D5.0
                NSYM = floor(((((obj.LSIGLength+3)/3)*4*sf-TEHT_PREAMBLE)/trc.TSYM))-obj.PEDisambiguity; % Equation 36-95 of IEEE P802.11be/D5.0
                TPE = floor(((((((obj.LSIGLength+3)/3)*4)*sf-TEHT_PREAMBLE)-(NSYM*trc.TSYM)))/(4*sf))*4; % Equation 36-96 of IEEE P802.11be/D5.0
                trc.TPE = TPE*sf; % In nanoseconds
            end

            RXTIME = ceil(20*sf+TEHT_PREAMBLE+NSYM*trc.TSYM+trc.TPE); % Equation 36-109 of IEEE P802.11be/D5.0 (with no signal extension)

            % NSYM less than zero if LSIGLength or the interpreted U-SIG bits are incorrect
            failInterpretation = wlan.internal.failInterpretationIf(NSYM<0,'wlan:shared:InvalidPktLength',suppressError);
            if failInterpretation
                return
            end

            % Set output structure
            s.NumDataSymbols = NSYM;
            s.RxTime = RXTIME/sf; % RxTime in us
            s.TPE = TPE;
        end

    end

    methods (Access = protected)
        function flag = isInactiveProperty(obj,prop)
            if strcmp(prop,'LDPCExtraSymbol') || strcmp(prop,'PreFECPaddingFactor') || strcmp(prop,'PEDisambiguity') || strcmp(prop,'NumUsersPerContentChannel') || strcmp(prop,'EHTDUPMode') ...
                    || strcmp(prop,'STAID') || strcmp(prop,'MCS') || strcmp(prop,'ChannelCoding')
                flag = obj.PPDUType==wlan.type.EHTPPDUType.ndp;
            elseif strcmp(prop,'Beamforming')
                flag = obj.PPDUType==wlan.type.EHTPPDUType.dl_mumimo;
            elseif strcmp(prop,'Channelization')
                flag = any(strcmp(obj.ChannelBandwidth,{'CBW20','CBW40','CBW80','CBW160'}));
            elseif strcmp(prop,'PuncturedChannelFieldValue')
                flag = obj.EHTDUPMode==1 || obj.PPDUType==wlan.type.EHTPPDUType.dl_ofdma;
            elseif strcmp(prop,'PuncturedPattern')
                flag =  ~any(obj.PPDUType==[wlan.type.EHTPPDUType.dl_ofdma wlan.type.EHTPPDUType.unknown]) || any(strcmp(obj.ChannelBandwidth,{'CBW20','CBW40'}));
            elseif strcmp(prop,'AllocationIndex')
                flag = ~any(obj.PPDUType==[wlan.type.EHTPPDUType.dl_ofdma wlan.type.EHTPPDUType.unknown]);
            elseif strcmp(prop,'NumNonOFDMAUsers')
                flag = obj.PPDUType==wlan.type.EHTPPDUType.ndp || obj.PPDUType==wlan.type.EHTPPDUType.dl_ofdma;
            else
                flag = false;
            end
        end
    end
end
