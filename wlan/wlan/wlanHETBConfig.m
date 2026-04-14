classdef wlanHETBConfig < comm.internal.ConfigBase
%wlanHETBConfig Create a high efficiency (HE) trigger-based (TB) format configuration object
%   CFG = wlanHETBConfig creates an uplink HE TB format configuration
%   object. This object contains the transmit parameters for the HE TB
%   format of the IEEE Std 802.11ax-2021 standard.
%
%   CFG = wlanHETBConfig(Name,Value) creates an HE TB object, CFG, with the
%   specified property Name set to the specified Value. You can specify
%   additional name-value pair arguments in any order as (Name1,Value1,
%   ...,NameN,ValueN).
%
%   wlanHETBConfig methods:
%  
%   getPSDULength               - Number of bytes to be coded in the packet
%   packetFormat                - HE TB packet format
%   ruInfo                      - Resource unit (RU) allocation information
%   showAllocation              - Shows the RU allocation
%   transmitTime                - Time required to transmit a packet
%   getNumPostFECPaddingBits    - Required number of post-FEC padding bits
%   getTRSConfiguration         - Return TRS configuration object
%   getNDPFeedbackConfiguration - Return HE TB feedback null data packet
%                                 (NDP) configuration object
%
%   wlanHETBConfig properties:
%
%   FeedbackNDP             - HE TB feedback NDP indication
%   TriggerMethod           - Method used to trigger an HE TB PPDU
%   ChannelBandwidth        - Channel bandwidth (MHz) of PPDU transmission
%   RUSize                  - RU size
%   RUIndex                 - RU index
%   RUToneSetIndex          - RU tone set used for HE TB feedback NDP
%   FeedbackStatus          - Modulated tones in an RU tone set
%   PreHEPowerScalingFactor - Power scaling factor for pre-HE TB field 
%   NumTransmitAntennas     - Number of transmit antennas
%   PreHECyclicShifts       - Cyclic shift values for >8 transmit chains
%   NumSpaceTimeStreams     - Number of space-time streams
%   StartingSpaceTimeStream - Starting space-time stream index
%   SpatialMapping          - Spatial mapping scheme
%   SpatialMappingMatrix    - Spatial mapping matrix
%   STBC                    - Enable space-time block coding
%   MCS                     - Modulation and coding scheme
%   DCM                     - Enable dual carrier modulation for HE data
%   ChannelCoding           - Forward error correction (FEC) coding type
%   PreFECPaddingFactor     - The pre-FEC padding factor for an HE TB PPDU
%   LDPCExtraSymbol         - LDPC extra OFDM symbol indication
%   PEDisambiguity          - The PE-Disambiguity for an HE TB PPDU
%   LSIGLength              - L-SIG length of an HE TB PPDU
%   NumDataSymbols          - Number of HE data OFDM symbols in TRS method
%   DefaultPEDuration       - Packet extension duration in microseconds
%   GuardInterval           - Guard interval type
%   HELTFType               - HE-LTF compression type
%   NumHELTFSymbols         - Number of HE-LTF symbols in the PPDU
%   SingleStreamPilots      - Indicate HE-LTF single-stream pilots
%   BSSColor                - Basic service set (BSS) color identifier
%   SpatialReuse1           - Spatial reuse-1 indication
%   SpatialReuse2           - Spatial reuse-2 indication
%   SpatialReuse3           - Spatial reuse-3 indication
%   SpatialReuse4           - Spatial reuse-4 indication
%   TXOPDuration            - Duration information for TXOP protection
%   HighDoppler             - High Doppler mode indication
%   MidamblePeriodicity     - Midamble periodicity in number of OFDM symbols
%   HESIGAReservedBits      - Reserved bits in HE-SIG-A field
%   PostFECPaddingSource    - Post-FEC padding bits source
%   PostFECPaddingSeed      - Initial random post-FEC padding bits seed
%   PostFECPaddingBits      - Post-FEC padding bits

%   Copyright 2019-2025 The MathWorks, Inc.

%#codegen

properties (Access = 'public')
    %FeedbackNDP HE TB feedback NDP indication
    %   Set this property to true to generate an HE TB feedback NDP
    %   waveform. The default is false.
    FeedbackNDP (1,1) logical = false;
    %TriggerMethod Method used to trigger an HE TB PPDU
    %   Indicate the method used to trigger an HE TB PPDU transmission.
    %   Specify this property as 'TriggerFrame' or 'TRS'. This property is
    %   applicable when FeedbackNDP is set to false. The default is
    %   'TriggerFrame'.
    TriggerMethod = 'TriggerFrame';
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80'
    %   | 'CBW160'. The default is 'CBW20'.
    ChannelBandwidth = 'CBW20';
    %RUSize Resource unit size
    %   Specify the size of the RU as one of these values 26, 52, 106, 242,
    %   484, 996 and 1992 (2x996). This property is applicable when
    %   FeedbackNDP is set to false. The is 242.
    RUSize (1,1) {mustBeInteger,mustBeMember(RUSize,[26 52 106 242 484 996 1992])} = 242;
    %RUIndex Resource unit index
    %   Specify the RU index as a nonzero integer. The RU index specifies
    %   the location of the RU within the channel. For example, in an 80
    %   MHz transmission there are four possible 242 tone RUs, one in each
    %   20 MHz subchannel. RU# 242-1 (size 242, index 1) is the RU
    %   occupying the lowest absolute frequency within the 80 MHz, and RU#
    %   242-4 (size 242, index 4) is the RU occupying the highest absolute
    %   frequency. This property is applicable when FeedbackNDP is set to
    %   false. The default is 1.
    RUIndex (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(RUIndex,1),mustBeLessThanOrEqual(RUIndex,74)} = 1;
    %RUToneSetIndex RU tone set used for HE TB feedback NDP
    %   Specify the RUToneSetIndex as a positive integer between 1 and 144,
    %   inclusive, as defined in IEEE Std 802.11ax-2021, Table 27-32.
    %   RUToneSetIndex is bandwidth dependent and must be in the range:
    %       - [1,18] for 20 MHz
    %       - [1,36] for 40 MHz
    %       - [1,72] for 80 MHz
    %       - [1,144] for 160 MHz
    %   RUToneSetIndex defines the small allocation tone sets (subcarrier)
    %   in HE-LTF for transmitting HE TB feedback NDP by a STA. This
    %   property is applicable when FeedbackNDP is set to true. The default
    %   is 1.
    RUToneSetIndex (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(RUToneSetIndex,1),mustBeLessThanOrEqual(RUToneSetIndex,144)} = 1;
    %FeedbackStatus Modulated tones in an RU tone set
    %   Specify the modulated tones in the RU tone set for a given
    %   RUToneSetIndex as logical scalar. The HE-LTF subcarrier mapping for
    %   an HE TB feedback NDP depends on RUToneSetIndex and FeedbackStatus
    %   as defined in IEEE Std 802.11ax-2021, Table 27-32. The
    %   FeedbackStatus indicates the resource status of a STA, as defined
    %   in IEEE Std 802.11ax-2021, Table 26-3. This property is applicable
    %   when FeedbackNDP is set to true. The default is true.
    FeedbackStatus (1,1) logical = true;
    %   PreHEPowerScalingFactor Power scaling factor for pre-HE fields
    %   Specify the power scaling factor for the pre-HE TB fields in the
    %   range [1/sqrt(2),1]. The default is 1.
    PreHEPowerScalingFactor (1,1) {mustBeNumeric,wlan.internal.validatePreEHTPowerScalingFactor(PreHEPowerScalingFactor)} = 1;
    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as positive integer. The
    %   default is 1.
    NumTransmitAntennas (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumTransmitAntennas,1)} = 1;
    %PreHECyclicShifts Cyclic shift values for >8 transmit chains
    %   Specify the cyclic shift values for the pre-HE portion of the
    %   waveform, in nanoseconds, for more than 8 transmit antennas as a
    %   row vector of length L = NumTransmitAntennas-8. The cyclic shift
    %   values must be between -200 and 0 inclusive. The first 8 antennas
    %   use the cyclic shift values defined in Table 21-10 of IEEE Std
    %   802.11-2020. The remaining antennas use the cyclic shift values
    %   defined in this property. If the length of this row vector is
    %   specified as a value greater than L the object only uses the first
    %   L PreHECyclicShifts values. For example, if you specify the
    %   NumTransmitAntennas property as 16 and this property as a row
    %   vector of length N>L, the object only uses the first L = 16-8 = 8
    %   entries. This property applies only when you set the
    %   NumTransmitAntennas property to a value greater than 8. The default
    %   is -75.
    PreHECyclicShifts {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreHECyclicShifts,-200),mustBeLessThanOrEqual(PreHECyclicShifts,0)} = -75;
    %NumSpaceTimeStreams Number of space-time streams
    %   Specify the number of space-time streams as integer between 1 and
    %   8, inclusive. The default is 1.
    NumSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1),mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;
    %StartingSpaceTimeStream Starting space-time stream index
    %   Specify the starting space-time stream index as 1-based index. When
    %   multiple users are transmitting in the same RU, in an MU-MIMO
    %   configuration, each user must transmit on different space-time
    %   streams. The StartingSpaceTimeStream and NumSpaceTimeStreams
    %   properties must be set to ensure each user transmits on a distinct
    %   space-time stream. When FeedbackNDP is true,
    %   StartingSpaceTimeStream must be 1 or 2. For more information see
    %   the wlanHETBConfig documentation. The default is 1.
    StartingSpaceTimeStream (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(StartingSpaceTimeStream,1),mustBeLessThanOrEqual(StartingSpaceTimeStream,8)} = 1;
    %SpatialMapping Spatial mapping scheme
    %   Specify the spatial mapping scheme as one of 'Direct' | 'Hadamard'
    %   | 'Fourier' | 'Custom'. The default is 'Direct', which applies when
    %   NumSpaceTimeStreams is equal to NumTransmitAntennas.
    SpatialMapping = 'Direct';
    %SpatialMappingMatrix Spatial mapping matrix(ces)
    %   Specify the spatial mapping matrix as a real or complex, 2D matrix
    %   or 3D array. This property applies when you set the SpatialMapping
    %   property to 'Custom'. It can be of size Nsts-by-Nt, where Nsts is
    %   the NumSpaceTimeStreams property and Nt is the NumTransmitAntennas
    %   property. In this case, the spatial mapping matrix applies to all
    %   the subcarriers. Alternatively, it can be of size Nst-by-Nsts-Nt,
    %   where Nst is the number of occupied subcarriers determined by the
    %   RUSize property. Specifically, Nst is one of 0 26 52 106 242 484
    %   996 or 1992 when FeedbackNDP is set to false. Nst is 242 when
    %   FeedbackNDP is set to true. In this case, each occupied subcarrier
    %   can have its own spatial mapping matrix. In either the 2D or 3D
    %   case, the object normalizes the spatial mapping matrix for each
    %   subcarrier. The default is 1.
    SpatialMappingMatrix {wlan.internal.heValidateSpatialMappingMatrix} = 1;
    %STBC Enable space-time block coding
    %   Set this property to true to enable space-time block coding in the
    %   data field transmission. STBC can only be applied for two
    %   space-time streams. This property is applicable when FeedbackNDP is
    %   set to false. The default is false.
    STBC (1,1) logical = false;
    %MCS Modulation and coding scheme per user
    %   Specify the modulation and coding scheme as an integer scalar
    %   between 0 and 11, inclusive. This property is applicable when
    %   FeedbackNDP is set to false. The default is 0.
    MCS (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(MCS,0),mustBeLessThanOrEqual(MCS,11)} = 0;
    %DCM Enable dual carrier modulation for HE data
    %   To indicate that the HE-Data field uses dual carrier modulation
    %   (DCM), set this property to true. This property is applicable when
    %   FeedbackNDP is set to false. The default is false.
    DCM (1,1) logical = false;
    %ChannelCoding Forward error correction (FEC) coding type
    %   Specify the channel coding as one of 'BCC' or 'LDPC' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding. This property is applicable when FeedbackNDP is set to
    %   false. The default is 'LDPC'.
    ChannelCoding = 'LDPC';
    %PreFECPaddingFactor Specify the pre-FEC padding factor for an HE TB PPDU
    %   Specify the pre-FEC padding factor for an HE TB PPDU as 1,2,3 or 4.
    %   This property is applicable when FeedbackNDP is set to false. The
    %   default is 4.
    PreFECPaddingFactor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreFECPaddingFactor,1),mustBeLessThanOrEqual(PreFECPaddingFactor,4)} = 4;
    %LDPCExtraSymbol LDPC extra OFDM symbol indication
    %   To indicate the presence of an extra OFDM symbol for LDPC encoding,
    %   set this property to true. This property is only applicable when
    %   ChannelCoding is LDPC and FeedbackNDP is set to false. The default
    %   is false.
    LDPCExtraSymbol (1,1) logical = false;
    % PEDisambiguity PE-Disambiguity for an HE TB PPDU
    %   To indicate the PE-Disambiguity for an HE TB PPDU, set this
    %   property to true. This property is applicable when FeedbackNDP is
    %   set to false. The default is false.
    PEDisambiguity (1,1) logical = 0;
    %LSIGLength L-SIG length of an HE TB PPDU
    %   Specify the L-SIG length for an HE TB PPDU as an integer scalar
    %   between 1 and 4093 (inclusive). The value of L-SIG length must
    %   satisfy, mod(LSIGLength,3)=1. This property applies only when
    %   TriggerMethod is TriggerFrame and FeedbackNDP is set to false. The
    %   default is 142.
    LSIGLength (1,1) {wlan.internal.mustBeValidLSIGLength(LSIGLength,'HE TB')} = 142;
    %NumDataSymbols Number of HE data OFDM symbols in TRS method
    %   Specify the number of allocated OFDM symbols in the HE data field
    %   of the HE TB PPDU as a scalar integer. This property applies only
    %   when TriggerMethod is TRS and FeedbackNDP is set to false. The
    %   default is 10.
    NumDataSymbols (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumDataSymbols,1)} = 10;
    %DefaultPEDuration Packet extension duration in microseconds
    %   Specify Packet extension duration as 0, 4, 8, 12 or 16. This
    %   property applies only when the TriggerMethod property is set to TRS
    %   and FeedbackNDP is set to false. The default is 0.
    DefaultPEDuration (1,1) {mustBeNumeric,mustBeMember(DefaultPEDuration,[0 4 8 12 16])} = 0;
    %GuardInterval Guard interval type
    %   Specify the guard interval (cyclic prefix) length in microseconds
    %   as one of 1.6 or 3.2. The default is 3.2.
    GuardInterval (1,1) {mustBeMember(GuardInterval,[1.6,3.2])} = 3.2;
    %HELTFType HE-LTF compression type
    %   Specify the HE-LTF compression type as one of 1, 2, or 4,
    %   corresponding to 1xHE-LTF, 2xHE-LTF and 4xHE-LTF type
    %   respectively. The default is 4.
    HELTFType (1,1) {mustBeNumeric,mustBeMember(HELTFType,[1 2 4])} = 4;
    %NumHELTFSymbols Number of HE-LTF symbols in the PPDU
    %   Specify the number of HE-LTF symbols in an HE TB PPDU as one of 1,
    %   2, 4, 6, or 8. The default is 1.
    NumHELTFSymbols (1,1) {mustBeNumeric,mustBeMember(NumHELTFSymbols,[1 2 4 6 8])} = 1;
    %SingleStreamPilots Indicate HE-LTF single-stream pilots
    %   To indicate that the HE-LTF field uses single-stream pilots, set
    %   this property to true. This property is applicable when FeedbackNDP
    %   is set to false. SingleStreamPilots must be false for 1xHE-LTF. The
    %   default is true.
    SingleStreamPilots (1,1) logical = true;
    %BSSColor Basic service set (BSS) color identifier
    %   Specify the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default is 0.
    BSSColor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(BSSColor,0),mustBeLessThanOrEqual(BSSColor,63)} = 0;
    %SpatialReuse1 Spatial reuse-1 indication
    %   Specify spatial reuse-1 in HE-SIG-A as an integer scalar between 0
    %   and 15, inclusive. The default is 15.
    SpatialReuse1 (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse1,0),mustBeLessThanOrEqual(SpatialReuse1,15)} = 15;
    %SpatialReuse2 Spatial reuse-2 indication
    %   Specify spatial reuse-2 in HE-SIG-A as an integer scalar between 0
    %   and 15, inclusive. The default is 15.
    SpatialReuse2 (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse2,0),mustBeLessThanOrEqual(SpatialReuse2,15)} = 15;
    %SpatialReuse3 Spatial reuse-3 indication
    %   Specify spatial reuse-3 in HE-SIG-A as an integer scalar between 0
    %   and 15, inclusive. The default is 15.
    SpatialReuse3 (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse3,0),mustBeLessThanOrEqual(SpatialReuse3,15)} = 15;
    %SpatialReuse4 Spatial reuse-4 indication
    %   Specify spatial reuse-4 in HE-SIG-A as an integer scalar between 0
    %   and 15, inclusive. The default is 15.
    SpatialReuse4 (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse4,0),mustBeLessThanOrEqual(SpatialReuse4,15)} = 15;
    %TXOPDuration Duration information for TXOP protection
    %   Specify the TXOPDuration signaled in HE-SIG-A as an integer scalar
    %   between 0 and 127, inclusive. The TXOP field in HE-SIG-A is set
    %   directly to TXOPDuration, therefore a duration in microseconds must
    %   be converted before being used as specified in Table 27-21 of 
    %   IEEE Std 802.11ax-2021. For more information see the wlanHETBConfig documentation.
    TXOPDuration (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(TXOPDuration,0),mustBeLessThanOrEqual(TXOPDuration,127)} = 127;
    %HighDoppler High Doppler mode indication
    %   To indicate high doppler in HE-SIG-A field, set this property to
    %   true. This property is applicable when FeedbackNDP is set to false.
    %   The default is false.
    HighDoppler (1,1) logical = false;
    %MidamblePeriodicity Midamble periodicity in number of OFDM symbols
    %   Specify HE-Data field midamble periodicity as 10 or 20 OFDM
    %   symbols. This property applies only when the HighDoppler property
    %   is set to true and FeedbackNDP is set to false. The default is 10.
    MidamblePeriodicity (1,1) {mustBeInteger,mustBeMember(MidamblePeriodicity,[10 20])} = 10;
    %HESIGAReservedBits Reserved bits in HE-SIG-A field
    %   Specify the reserved field bits in HE-SIG-A2 as a binary column
    %   vector of length 9. The default is a column vector of ones.
    HESIGAReservedBits (9,1) {mustBeNumeric,mustBeInteger} = ones(9,1);
    %PostFECPaddingSource Post-FEC padding bit source
    %   Specify the source of post-FEC padding bits for the waveform
    %   generator as 'mt19937ar with seed', 'Global stream', or
    %   'User-defined'. To use the mt19937ar random number generator
    %   algorithm with a seed to generate normally distributed random bits,
    %   set this property to 'mt19937ar with seed'. The mt19937ar algorithm
    %   uses the seed specified by the value of the PostFECPaddingSeed
    %   property. To use the current global random number stream to
    %   generate normally distributed random bits, set this property to
    %   'Global stream'. To use bits specified in the PostFECPaddingBits
    %   property, set this property to 'User-defined'. This property is
    %   applicable when FeedbackNDP is set to false. The default is
    %   'mt19937ar with seed'.
    PostFECPaddingSource = 'mt19937ar with seed';
    %PostFECPaddingSeed Initial random post-FEC padding bits seed
    %   Specify the initial seed of the mt19937ar random number generator
    %   algorithm as a nonnegative integer. This property applies when you
    %   set the PostFECPaddingSource property to 'mt19937ar with seed' and
    %   FeedbackNDP is set to false. The default is 73.
    PostFECPaddingSeed (1,1) {mustBeNumeric,mustBeInteger, mustBeNonnegative} = 73;
    %PostFECPaddingBits Post-FEC padding bits
    %   Specify post-FEC padding bits as an int8, double, or single typed
    %   binary column vector. For C code generation this property must be
    %   int8 typed. The waveform generator loops the vector if the number
    %   of bits required exceeds the length of the vector provided. The
    %   number of bits the waveform generator uses from the vector is given
    %   by the getNumPostFECPaddingBits object function. This property is 
    %   applicable when FeedbackNDP is set to false. The default is 0.
    PostFECPaddingBits (:,1) {wlan.internal.validateBits(PostFECPaddingBits,'PostFECPaddingBits')} = int8(0);
end

properties(Constant, Hidden)
    TriggerMethod_Values = {'TriggerFrame','TRS'};
    ChannelBandwidth_Values = {'CBW20','CBW40','CBW80','CBW160'};
    SpatialMapping_Values = {'Direct','Hadamard','Fourier','Custom'};
    ChannelCoding_Values = {'BCC','LDPC'};
    PostFECPaddingSource_Values = {'mt19937ar with seed','Global stream','User-defined'};
end

methods
    function obj = wlanHETBConfig(varargin)
        if ~isempty(coder.target)
            % For codegen set maximum dimensions to force varsize
            triggerMethod = 'TriggerFrame';
            coder.varsize('triggerMethod',[1 12],[0 1]); % Add variable-size support
            obj.TriggerMethod = triggerMethod; % Default

            channelBandwidth = 'CBW20';
            coder.varsize('channelBandwidth',[1 6],[0 1]); % Add variable-size support
            obj.ChannelBandwidth = channelBandwidth; % Default

            channelCoding = 'LDPC';
            coder.varsize('channelCoding',[1 4],[0 1]); % Add variable-size support
            obj.ChannelCoding = channelCoding; % Default

            spatialMapping = 'Direct';
            coder.varsize('spatialMapping',[1 8],[0 1]); % Add variable-size support
            obj.SpatialMapping = spatialMapping; % Default

            postFECPaddingSource = 'mt19937ar with seed';
            coder.varsize('postFECPaddingSource',[1 19],[0 1]); % Add variable-size support
            obj.PostFECPaddingSource = postFECPaddingSource; % Default

            postFECPaddingBits = int8(0);
            coder.varsize('postFECPaddingBits',[1920*10*8 1],[1 0]); % Add variable-size support (NCBPS = NSD*NBPSCS*NSS)
            obj.PostFECPaddingBits = postFECPaddingBits; % Default
        end
        obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
    end

    function obj = set.TriggerMethod(obj,val)
        val = validateEnumProperties(obj,'TriggerMethod',val);
        obj.TriggerMethod = val;
    end

    function obj = set.ChannelBandwidth(obj,val)
        val = validateEnumProperties(obj,'ChannelBandwidth',val);
        obj.ChannelBandwidth = val;
    end

    function obj = set.SpatialMapping(obj,val)
        val = validateEnumProperties(obj,'SpatialMapping',val);
        obj.SpatialMapping = val;
    end

    function obj = set.ChannelCoding(obj,val)
        val = validateEnumProperties(obj,'ChannelCoding',val);
        obj.ChannelCoding = val;
    end
    
    function obj = set.PostFECPaddingSource(obj,val)
        val = validateEnumProperties(obj,'PostFECPaddingSource',val);
        obj.PostFECPaddingSource = val;
    end
    

    function psduLength = getPSDULength(obj)
    %getPSDULength Returns PSDU length for the given configuration
    %   Returns the PSDU length for an HE TB PPDU. For more information,
    %   see Section 27.4.3, IEEE Std 802.11ax-2021.

        psduLength = wlan.internal.hePLMETxTimePrimative(obj);
    end
    
    function n = getNumPostFECPaddingBits(obj)
    %getNumPostFECPaddingBits Required number of post-FEC padding bits
    %   Returns the required number of post-FEC padding bits.
        [~,userCodingParams] = wlan.internal.heCodingParameters(obj);
        n = userCodingParams.NPADPostFEC*userCodingParams.mSTBC;
    end

    function format = packetFormat(obj) %#ok<MANU>
    %packetFormat Returns the packet format
    %   Returns the packet format as a character vector.

        format = 'HE-TB';
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
        [~,t] = wlan.internal.hePLMETxTimePrimative(obj);
        t = t*1e-3; % Scale from nanoseconds to microseconds
        t = wlan.internal.convertTransmitTime(t,varargin{:});
    end

    function s = ruInfo(obj)
    %ruInfo Returns RU allocation information
    %   S = ruInfo(CFG) returns a structure, S, containing the resource
    %   unit (RU) allocation information for the wlanHETBConfig object,
    %   CFG. The output structure S has these fields:
    %
    %   NumUsers                  - Number of users (1)
    %   NumRUs                    - Number of RUs (1)
    %   RUIndices                 - Index of the RU
    %   RUSizes                   - Size of each RU
    %   NumUsersPerRU             - Number of users per RU (1)
    %   NumSpaceTimeStreamsPerRU  - Total number of space-time streams
    %   PowerBoostFactorPerRU     - Power boost factor (1)
    %   RUNumbers                 - RU number (1)
    %   RUAssigned                - Indicate assigned RU (true)

        if obj.FeedbackNDP
            ruSize = 242; % Fix RU Size for all channel bandwidths
            cbw = wlan.internal.cbwStr2Num(obj.ChannelBandwidth);
            validateRUToneSetIndex(cbw,obj.RUToneSetIndex)
            ruIndex = wlan.internal.heTBNDPSubchannelIndex(cbw,obj.RUToneSetIndex);
        else
            ruIndex = obj.RUIndex;
            ruSize = obj.RUSize;
        end

        s = struct;
        s.NumUsers = 1;
        s.NumRUs = 1;
        s.RUIndices = ruIndex;
        s.RUSizes = ruSize;
        s.NumUsersPerRU = 1;
        s.NumSpaceTimeStreamsPerRU = obj.NumSpaceTimeStreams;
        s.PowerBoostFactorPerRU = 1;
        s.RUNumbers = 1;
        s.RUAssigned = true;
    end

    function showAllocation(obj,varargin)
    %showAllocation Shows the RU allocation
    %   showAllocation(cfg) shows the RU allocation for an HE TB format
    %   configuration object
    %
    %   showAllocation(cfg,AX) shows the allocation in the axes specified
    %   by AX instead of in the current axes. If AX is not
    %   specified, showAllocation plots the allocation in a new figure.

        wlan.internal.validateRUArgument([obj.RUSize obj.RUIndex],wlan.internal.cbwStr2Num(obj.ChannelBandwidth));
        wlan.internal.hePlotAllocation(obj,varargin{:});
    end

    function obj = getTRSConfiguration(obj)
    %getTRSConfiguration Returns a TRS configuration object
    %   This method takes the current configuration and returns an object
    %   with properties set to those required for an HE TB response to TRS.
    %   The other properties are unchanged.

        obj.TriggerMethod = 'TRS';
        if strcmp(obj.ChannelBandwidth,'CBW20')
            obj.ChannelCoding = 'BCC';
        else
            if strcmp(obj.ChannelCoding,'LDPC')
                obj.LDPCExtraSymbol = 1;
            end
        end
        obj.HighDoppler = false;
        obj.NumHELTFSymbols = 1;
        obj.StartingSpaceTimeStream = 1;
        obj.SingleStreamPilots = true;
        obj.STBC = false;
        obj.NumSpaceTimeStreams = 1;
        obj.PreFECPaddingFactor = 4;
        obj.SpatialReuse1 = 15;
        obj.SpatialReuse2 = 15;
        obj.SpatialReuse3 = 15;
        obj.SpatialReuse4 = 15;
        obj.HESIGAReservedBits = ones(9,1);
    end
    
    function obj = getNDPFeedbackConfiguration(obj)
    %getNDPFeedbackConfiguration Returns HE TB feedback NDP configuration object
    %   This method takes the current configuration and returns an object
    %   with properties set to those required for an HE TB feedback NDP.
    %   The other properties are unchanged.

        obj.FeedbackNDP = true;
        obj.StartingSpaceTimeStream = 1;
        obj.NumSpaceTimeStreams = 1;
        obj.GuardInterval = 3.2;
        obj.HELTFType = 4;
        obj.NumHELTFSymbols = 2;
        obj.SpatialReuse1 = 0;
        obj.SpatialReuse2 = 0;
        obj.SpatialReuse3 = 0;
        obj.SpatialReuse4 = 0;
        obj.HESIGAReservedBits = ones(9,1);
    end

    function varargout = validateConfig(obj,varargin)
    %validateConfig Validate the dependent properties of wlanHETBConfig object 
    %   validateConfig(CFG) validates the dependent properties for the
    %   specified wlanHETBConfig configuration object.
    %
    %   For INTERNAL use only, subject to future changes.
    %
    %   validateConfig(CFG,MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'DataLocationLength'
    %       'HELTFGI'
    %       'HELTF'
    %       'Coding'
    %       'TRS'
    %       'CyclicShift'
    %       'Full'

        narginchk(1,2);
        nargoutchk(0,1);

        if (nargin==2)
            mode = varargin{1};
        else
            mode = 'Full';
        end

        switch mode
            case 'DataLocationLength' % wlanFieldIndices (HE-LTF)
                % Validate MCS and length
                s = validateMCSLengthTxTime(obj);
            case 'HELTFGI' % wlanFieldIndices (HE-LTF)
                % Validate GuardInterval and HELTFType
                validateHELTFGI(obj);
            case 'HELTF'
                % Validate NumHELTFSymbols and HighDoppler
                validateSpatial(obj);
            case 'Coding' % wlanHEDataBitRecover
                % Validate channel coding
                validateCoding(obj);
            case 'TRS'
                % Validate properties when TriggerMethod is TRS
                validateTRS(obj);
            case 'CyclicShift'
                % Validate PreHECyclicShifts against NumTransmitAntennas
                validatePreHECyclicShifts(obj);
            otherwise % wlanWaveformGenerator
                % Full object validation

                % Validate properties when TriggerMethod is TRS
                if ~obj.FeedbackNDP && strcmp(obj.TriggerMethod,'TRS')
                    validateTRS(obj)
                end

                % Validate GuardInterval and HELTFType
                if ~obj.FeedbackNDP
                    validateHELTFGI(obj);
                end

                % Validate Spatial mapping properties and spatial mapping matrix
                validateSpatialMapping(obj)

                % Validate PreHECyclicShifts against NumTransmitAntennas
                validatePreHECyclicShifts(obj);

                % Validate RUSize, RUIndex and ChannelBandwidth
                wlan.internal.validateRUArgument([obj.RUSize obj.RUIndex],wlan.internal.cbwStr2Num(obj.ChannelBandwidth));

                % Validate LSIGLength when TriggerMethod is TriggerFrame
                if ~obj.FeedbackNDP && strcmp(obj.TriggerMethod,'TriggerFrame')
                    validateLSIGLength(obj);
                end

                s = validateMCSLengthTxTime(obj);
        end

        if nargout == 1
            varargout{1} = s;
        end
    end
end

methods (Access = private)
    function s = validateMCSLength(obj)
    %validateMCSLength Validate the length properties of wlanHETBConfig object
    %   Validated property-subset includes: 
    %     ChannelBandwidth, NumSpaceTimeStreams, STBC, MCS, ChannelCoding,
    %     GuardInterval, RUSize and properties for HE TB feedback NDP

        [psduLength,txTime] = wlan.internal.hePLMETxTimePrimative(obj);
        if obj.FeedbackNDP % HE TB feedback NDP
            validateFeedbackNDP(obj) % Validate properties of HE TB feedback NDP
            lsigLength = wlan.internal.heLSIGLengthCalculation(obj,txTime);
            NSYM = 0; % No data field in HE TB feedback NDP
            TPE = 0; % No PE field in HE TB feedback NDP
        else
            validateCoding(obj); % Validate coding related properties
            if strcmp(obj.TriggerMethod,'TriggerFrame') % TriggerFrame
                [trc,NSYM] = wlan.internal.heTBTimingRelatedConstants(obj);
                TPE = trc.TPE;
                lsigLength = obj.LSIGLength;
                % NSYM must be even when STBC is enabled
                coder.internal.errorIf(obj.STBC && mod(NSYM,2)~=0,'wlan:wlanHETBConfig:InvalidNSYMSTBC');
            else % TRS
                NSYM = obj.NumDataSymbols;
                TPE = obj.DefaultPEDuration;
                lsigLength = wlan.internal.heLSIGLengthCalculation(obj,txTime);
                coder.internal.errorIf(psduLength(1)==0,'wlan:wlanHETBConfig:InvalidTRSPSDULength');
            end
        end

        % Set output structure
        s = struct( ...
            'TxTime',         txTime/1000, ...
            'LSIGLength',     lsigLength, ...
            'PSDULength',     psduLength, ...
            'NumDataSymbols', NSYM, ...
            'TPE',            TPE);
    end

    function s = validateMCSLengthTxTime(obj)
    %validateMCSLengthTxTime Validate the length properties and resultant
    %   transmit time of wlanHETBConfig object.
    %   Validated property-subset includes: 
    %     ChannelBandwidth, NumSpaceTimeStreams, STBC, MCS, ChannelCoding,
    %     GuardInterval, RUSize and properties for HE TB feedback NDP

        s = validateMCSLength(obj);

        % Validate for TXTIME (max 5.484ms for HE format)
        coder.internal.errorIf(s.TxTime>5484,'wlan:he:InvalidPPDUDuration',round(s.TxTime),5484);
    end

    function validateHELTFGI(obj)
    %validateHELTFGI Validate GuardInterval and HELTFType
    %   Validated property-subset includes:
    %     HELTFType, SingleStreamPilots, HighDoppler, GuardInterval,
    %     NumHELTFSymbols,NumSpaceTimeStreams
          % Valid HELTFType modes are:
          %   1 x HELTFType and 1.6 GI is allowed for Non-OFDMA MU-MIMO, IEEE Std 802.11ax-2021, Table 27-31
          %   2 x HELTFType and 1.6 GI
          %   4 x HELTFType and 3.2 GI

        if strcmp(obj.TriggerMethod,'TRS')
            validateTRSDopplerHELTF(obj);
        end

        coder.internal.errorIf(obj.HighDoppler && obj.NumSpaceTimeStreams>4,'wlan:he:InvalidHighDoppler');
        coder.internal.errorIf(obj.HighDoppler && obj.NumHELTFSymbols>4,'wlan:wlanHETBConfig:InvalidHELTFSymbols');
        coder.internal.errorIf(any(obj.HELTFType==[1 2]) && obj.GuardInterval~=1.6,'wlan:shared:InvalidGILTF',sprintf('%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);
        coder.internal.errorIf(obj.HELTFType==4 && obj.GuardInterval~=3.2,'wlan:shared:InvalidGILTF',sprintf('%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);

        % Validate: 1 x HELTF must not use single stream pilots
        coder.internal.errorIf(obj.HELTFType==1 && obj.SingleStreamPilots==true,'wlan:wlanHETBConfig:InvalidTBSSPilotsHELTFType');

    end

    function validateTRSDopplerHELTF(obj)
    %validateTRSDopplerHELTF Validate when TriggerMethod is TRS
    %   Validated property-subset includes:
    %     HighDoppler, NumHELTFSymbols, STBC, NumSpaceTimeStreams, SingleStreamPilots

        coder.internal.errorIf(obj.HighDoppler==1,'wlan:wlanHETBConfig:InvalidTRSHighDoppler');
        coder.internal.errorIf(obj.NumHELTFSymbols>1,'wlan:wlanHETBConfig:InvalidTRSNumHELTFSymbols');
        coder.internal.errorIf(obj.STBC,'wlan:wlanHETBConfig:InvalidTRSSTBC');
        coder.internal.errorIf(obj.NumSpaceTimeStreams>1,'wlan:wlanHETBConfig:InvalidTRSNumSpaceTimeStreams');
        coder.internal.errorIf(~obj.SingleStreamPilots,'wlan:wlanHETBConfig:InvalidTRSSingleStreamPilots');
    end

    function validateCoding(obj)
    %validateCoding Coding properties for wlanHETBConfig configuration object
    %   Validated property-subset includes:
    %     NumSpaceTimeStreams, STBC, DCM, MCS, ChannelCoding, RUSize,
    %     PreFECPaddingFactor, LDPCExtraSymbol

        if strcmp(obj.TriggerMethod,'TRS')
            % For TRS, LDPC is not allowed for RUSize<484
            coder.internal.errorIf((strcmp(obj.ChannelCoding,'LDPC') && obj.RUSize<484),'wlan:wlanHETBConfig:InvalidTRSRUSizeCoding');
            coder.internal.errorIf(obj.PreFECPaddingFactor~=4,'wlan:wlanHETBConfig:InvalidTRSPreFECPaddingFactor');
            coder.internal.errorIf((strcmp(obj.ChannelCoding,'LDPC') && obj.LDPCExtraSymbol==0),'wlan:wlanHETBConfig:InvalidTRSLDPCExtraSymbol');
        end

        % Validate MCS, DCM and STBC
        coder.internal.errorIf(obj.DCM && (~any(obj.MCS==[0 1 3 4]) || obj.STBC || obj.NumSpaceTimeStreams>2),'wlan:he:InvalidDCM');

        % Validate STBC and NumSpaceTimeStreams
        coder.internal.errorIf(obj.STBC && obj.NumSpaceTimeStreams~=2,'wlan:he:InvalidNumSTSWithSTBC');

        % Validate BCC coding
        if strcmp(obj.ChannelCoding,'BCC')
            coder.internal.errorIf(obj.RUSize>242,'wlan:shared:InvalidBCCRUSize');
            coder.internal.errorIf(any(obj.MCS==[10 11]),'wlan:he:InvalidMCS');
            coder.internal.errorIf(obj.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS');
        end
        
    end

    function validateTRS(obj)
    %validateTRS Validate properties for TriggerMethod, TRS
    %   Validated property-subset includes:
    %     StartingSpaceTimeStream, SpatialReuse1, SpatialReuse2,
    %     SpatialReuse3, SpatialReuse4, HESIGAReservedBits

        % IEEE Std 802.11ax-2021, Section 26.5.2.3.4
        coder.internal.errorIf(obj.StartingSpaceTimeStream>1,'wlan:wlanHETBConfig:InvalidTRSStartingSpaceTimeStream');
        coder.internal.errorIf(obj.SpatialReuse1~=15,'wlan:wlanHETBConfig:InvalidTRSSpatialReuse1');
        coder.internal.errorIf(obj.SpatialReuse2~=15,'wlan:wlanHETBConfig:InvalidTRSSpatialReuse2');
        coder.internal.errorIf(obj.SpatialReuse3~=15,'wlan:wlanHETBConfig:InvalidTRSSpatialReuse3');
        coder.internal.errorIf(obj.SpatialReuse4~=15,'wlan:wlanHETBConfig:InvalidTRSSpatialReuse4');
        coder.internal.errorIf(any(obj.HESIGAReservedBits~=1),'wlan:wlanHETBConfig:InvalidTRSHESIGAReservedBits');
    end

    function validatePreHECyclicShifts(obj)
    %validatePreHECyclicShifts Validate PreHECyclicShifts values against NumTransmitAntennas
    %   Validated property-subset includes:
    %     PreHECyclicShifts, NumTransmitAntennas

        numTx = obj.NumTransmitAntennas;
        csh = obj.PreHECyclicShifts;
        if numTx>8
            coder.internal.errorIf(~(numel(csh) >= numTx-8),'wlan:shared:InvalidCyclicShift','PreHECyclicShifts',numTx-8);
        end
    end

    function validateLSIGLength(obj)
    %validateLSIGLength Validate LSIGLength value
    %   Validated property-subset includes:
    %     LSIGLength

        [trc,NSYMInit] = wlan.internal.heTBTimingRelatedConstants(obj);
        [~,THEPREAMBLE] = wlan.internal.numHETBMidamblePeriods(trc,obj);
        sf = 1e3; % Scaling factor to convert time in us into ns
        if NSYMInit<1
            if obj.PEDisambiguity
                numSYM = 2;
            else
                numSYM = 1;
            end
            minTXTIME = 20*sf+THEPREAMBLE+trc.TSYM*numSYM; % Minimum TXTIME without TPE + time for one data field symbol
            length = wlan.internal.heLSIGLengthCalculation(obj,minTXTIME); % Length of the packet with one data field symbol
            % The value of LSIGLength without packet extension must be
            % greater than or equal to the length of the preamble field
            % plus one data symbol.
            coder.internal.error('wlan:shared:InvalidLSIGLength',length);
        end
    end

    function validateSpatialMapping(obj)
    %validateSpatialMapping Validate the spatial mapping properties
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams, SpatialMapping,
    %     SpatialMappingMatrix, RUSize

        validateSpatial(obj);

        if strcmp(obj.SpatialMapping,'Custom')
            wlan.internal.validateSpatialMappingMatrix(obj.SpatialMappingMatrix,obj.NumTransmitAntennas,obj.NumSpaceTimeStreams,obj.RUSize);
        end
    end

    function validateSTSTx(obj)
    %ValidateSTSTx Validate the spatial properties of wlanHETBConfig object
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams

        % NumTx and Nsts: numTx cannot be less than Nsts
        coder.internal.errorIf(obj.NumTransmitAntennas < obj.NumSpaceTimeStreams,'wlan:he:NumSTSLargerThanNumTx',1,obj.NumSpaceTimeStreams,obj.NumTransmitAntennas);
    end

    function validateSpatial(obj)
    %validateSpatial Validate the spatial properties of wlanHETBConfig object
    %   Validated property-subset includes:
    %     NumTransmitAntennas, NumSpaceTimeStreams, SpatialMapping,
    %     StartingSpaceTimeStream, NumHELTFSymbols

        coder.internal.errorIf(strcmp(obj.SpatialMapping,'Direct') && (obj.NumSpaceTimeStreams ~= obj.NumTransmitAntennas),'wlan:he:NumSTSNotEqualNumTxDirectMap',1,obj.NumSpaceTimeStreams,obj.NumTransmitAntennas);
        if ~obj.FeedbackNDP
            % No need to validate NumSpaceTimeStreams, StartingSpaceTimeStream and NumHELTFSymbols for HE TB feedback NDP as the values are fixed
            validateSTSTx(obj);

            % Validate StartingSpaceTimeStream and NumSpaceTimeStreams
            numSTS = obj.StartingSpaceTimeStream+obj.NumSpaceTimeStreams-1;
            coder.internal.errorIf(numSTS>8,'wlan:wlanHETBConfig:InvalidStartingSpaceTimeStream');

            % Validate StartingSpaceTimeStream and NumHELTFSymbols
            Nltf = wlan.internal.numVHTLTFSymbols(numSTS);
            coder.internal.errorIf(obj.NumHELTFSymbols<Nltf,'wlan:shared:InvalidNumLTFSymbols','NumHELTFSymbols',Nltf,obj.StartingSpaceTimeStream,obj.NumSpaceTimeStreams);
        end
    end

    function validateFeedbackNDP(obj)
    %validateFeedbackNDP Validate HE TB feedback NDP properties of wlanHETBConfig object
    %   Validated property-subset includes:
    %     RUToneSetIndex, NumSpaceTimeStreams, NumHELTFSymbols, StartingSpaceTimeStream, HELTFType,
    %     GuradInterval, SpatialReuse1, SpatialReuse2, SpatialReuse3, SpatialReuse4

        cbw = wlan.internal.cbwStr2Num(obj.ChannelBandwidth);
        validateRUToneSetIndex(cbw,obj.RUToneSetIndex);
        coder.internal.errorIf(obj.NumSpaceTimeStreams~=1,'wlan:wlanHETBConfig:InvalidNDPNumSpaceTimeStreams');
        coder.internal.errorIf(obj.NumHELTFSymbols~=2,'wlan:wlanHETBConfig:InvalidNDPNumHELTFSymbols');
        coder.internal.errorIf(obj.StartingSpaceTimeStream>2,'wlan:wlanHETBConfig:InvalidNDPStartingSpaceTimeStream');
        coder.internal.errorIf(obj.HELTFType~=4,'wlan:wlanHETBConfig:InvalidNDPHELTFType');
        coder.internal.errorIf(obj.GuardInterval~=3.2,'wlan:wlanHETBConfig:InvalidNDPGuardInterval');
        coder.internal.errorIf(obj.SpatialReuse1~=0,'wlan:wlanHETBConfig:InvalidNDPSpatialReuse1');
        coder.internal.errorIf(obj.SpatialReuse2~=0,'wlan:wlanHETBConfig:InvalidNDPSpatialReuse2');
        coder.internal.errorIf(obj.SpatialReuse3~=0,'wlan:wlanHETBConfig:InvalidNDPSpatialReuse3');
        coder.internal.errorIf(obj.SpatialReuse4~=0,'wlan:wlanHETBConfig:InvalidNDPSpatialReuse4');
    end
end

methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = false;
        switch prop
            case 'DCM'
                % Hide DCM unless MCS is 0,1,3, or 4
                flag = ~(any(obj.MCS == [0 1 3 4])) || obj.FeedbackNDP;
            case 'LDPCExtraSymbol'
                % Hide LDPCExtraSymbol when ChannelCoding is BCC
                flag = ~strcmp(obj.ChannelCoding,'LDPC') || obj.FeedbackNDP;
            case 'SpatialMappingMatrix'
                % Hide SpatialMappingMatrix when SpatialMapping is not Custom
                flag = ~strcmp(obj.SpatialMapping,'Custom');
            case {'DefaultPEDuration','NumDataSymbols'}
                % Hide DefaultPEDuration and NumDataSymbols when TriggerMethod is TriggerFrame
                flag = ~strcmp(obj.TriggerMethod,'TRS') || obj.FeedbackNDP;
            case {'LSIGLength','PEDisambiguity'}
                % Hide LSIGLength, PEDisambiguity when TriggerMethod is TRS
                flag = ~strcmp(obj.TriggerMethod,'TriggerFrame') || obj.FeedbackNDP;
            case 'PreHECyclicShifts'
                % Hide PreHECyclicShifts when NumTransmitAntennas <=8
                flag = obj.NumTransmitAntennas<=8;
            case 'MidamblePeriodicity'
                % Hide MidamblePeriodicity for TRS or when HighDoppler is false
                flag = obj.HighDoppler==0 || strcmp(obj.TriggerMethod,'TRS') || obj.FeedbackNDP;
            case 'PostFECPaddingSeed'
                flag = ~strcmp(obj.PostFECPaddingSource,'mt19937ar with seed') || obj.FeedbackNDP;
            case 'PostFECPaddingBits'
                flag = ~strcmp(obj.PostFECPaddingSource,'User-defined');
            case {'TriggerMethod','RUSize','RUIndex','STBC','MCS','ChannelCoding','PreFECPaddingFactor','SingleStreamPilots','HighDoppler','PostFECPaddingSource'}
                flag = obj.FeedbackNDP;
            case {'RUToneSetIndex','FeedbackStatus'}
                flag = ~obj.FeedbackNDP;
        end
    end
end

end

function validateRUToneSetIndex(cbw,ruToneSetIndex)
%validateRUToneSetIndex Validate RUToneSetIndex and ChannelBandwidth combinations
    if any(cbw==[20 40 80])
        idx = [18 36 72];
        ruVal = idx(cbw==[20 40 80]);
        coder.internal.errorIf(ruToneSetIndex>ruVal(1),'wlan:wlanHETBConfig:InvalidRUToneSetIndex',ruVal(1),cbw);
    end
end
