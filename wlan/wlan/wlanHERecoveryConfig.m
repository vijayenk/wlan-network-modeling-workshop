classdef wlanHERecoveryConfig < comm.internal.ConfigBase
%wlanHERecoveryConfig Create a high efficiency (HE) recovery configuration object
%   CFGRX = wlanHERecoveryConfig creates a HE recovery configuration object
%   for HE SU, HE ER SU, and HE MU packet formats. This object contains the
%   recovered parameters after decoding the signaling fields of HE SU, HE
%   ER SU, and HE MU formats defined in IEEE Std 802.11ax-2021 standard.
%
%   CFGRX = wlanHERecoveryConfig (Name,Value) creates an HE recovery
%   object, CFGRX, with the specified property Name set to the specified
%   Value. You can specify additional name-value pair arguments in any
%   order as (Name1,Value1, ...,NameN,ValueN).
%
%   wlanHERecoveryConfig methods:
%
%   getPSDULength             - Number of coded bytes in the packet
%   packetFormat              - HE packet type
%   getSIGBLength             - HE-SIG-B field length information
%   interpretHESIGABits       - Parse and interpret decoded HE-SIG-A bits
%                               and returns an updated recovery object with
%                               the relevant HE-SIG-A fields set.
%   interpretHESIGBCommonBits - Parse and interpret decoded HE-SIG-B
%                               common field bits and return an updated
%                               recovery object with the relevant HE-SIG-B
%                               fields set.
%   interpretHESIGBUserBits   - Parse and interpret decoded HE-SIG-B
%                               user field bits and return an updated
%                               recovery object with the relevant HE-SIG-B
%                               fields set.
%
%   wlanHERecoveryConfig properties:
%
%   PacketFormat                 - HE packet format
%   ChannelBandwidth             - Channel bandwidth
%   LSIGLength                   - Indicate length value in L-SIG field
%   PreamblePuncturing           - Indicate HE MU preamble puncturing mode
%   SIGBCompression              - Indicate HE-SIG-B compression
%   SIGBMCS                      - Indicate MCS of HE-SIG-B field
%   SIGBDCM                      - Indicate DCM of HE-SIG-B field
%   NumSIGBSymbolsSignaled       - Number of HE-SIG-B symbols signaled in HE-SIG-A
%   STBC                         - Indicate space-time block coding
%   LDPCExtraSymbol              - Indicate extra OFDM symbol
%   PreFECPaddingFactor          - Indicate pre-FEC padding factor
%   PEDisambiguity               - Indicate PEDisambiguity
%   GuardInterval                - Indicate guard interval type
%   HELTFType                    - Indicate HE-LTF compression mode
%   NumHELTFSymbols              - Indicate number of HE-LTF symbols
%   UplinkIndication             - Indicate uplink transmission
%   BSSColor                     - Basic service set (BSS) color identifier 
%   SpatialReuse                 - Indicate spatial reuse
%   TXOPDuration                 - Duration information for TXOP protection
%   HighDoppler                  - Indicate high Doppler mode
%   MidamblePeriodicity          - Indicate midamble periodicity
%   AllocationIndex              - Indicate RU allocation index
%   LowerCenter26ToneRU          - Indicate user in lower center 26-tone RU
%   UpperCenter26ToneRU          - Indicate user in upper center 26-tone RU
%   NumUsersPerContentChannel    - Number of users per content channel
%   RUTotalSpaceTimeStreams      - Number of space time streams in an RU
%   RUSize                       - Indicate resource unit (RU) size
%   RUIndex                      - Indicate resource unit (RU) index
%   STAID                        - Indicate station identification
%   MCS                          - Indicate modulation and coding scheme
%   DCM                          - Dual coded modulation of HE-Data field
%   ChannelCoding                - Indicate channel coding type
%   Beamforming                  - Indicate beamforming
%   PreHESpatialMapping          - Spatial mapping of pre-HE-STF portion
%   NumSpaceTimeStreams          - Indicate number of space-time streams
%   SpaceTimeStreamStartingIndex - Starting space-time stream index

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

properties (Access = 'public')
    %PacketFormat Indicate the recovered HE packet type
    %   This property is set after (i) decoding the length value in the
    %   L-SIG field and (ii) decoding the HE-SIG-A field of an HE packet.
    %   The PacketFormat is specified as one of 'HE-SU' | 'HE-EXT-SU' |
    %   'HE-MU' | 'Unknown'. The default value of this property is
    %   'Unknown'.
    PacketFormat = 'Unknown';
    %ChannelBandwidth Channel bandwidth (MHz) of PPDU transmission
    %   Specify the channel bandwidth as one of 'CBW20' | 'CBW40' | 'CBW80'
    %   | 'CBW160' | 'Unknown'. The default value of this property is
    %   'Unknown', which indicates an unknown or undefined channel
    %   bandwidth.
    ChannelBandwidth = 'Unknown';
    %LSIGLength Indicate the length value of L-SIG field
    %   This property is set after decoding the length of the L-SIG packet.
    %   The LSIGLength is specified as scalar integer between 1 and 4095
    %   (inclusive). The default value of this property is -1, which
    %   indicates an unknown or undefined packet length.
    LSIGLength (1,1) {wlan.internal.mustBeValidLSIGLengthRange(LSIGLength)} = -1;
    %PreamblePuncturing Indicate the preamble puncturing pattern
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the location of a punctured 20MHz or 40MHz subchannel.
    %   This property is only applicable when ChannelBandwidth is 'CBW80'
    %   and 'CBW160' and SIGBCompression is false. The preamble puncturing
    %   is specified as one of 'None' | 'Mode-1' | 'Mode-2' | 'Mode-3' |
    %   'Mode-4 | 'Unknown'.
    %
    %   The preamble puncturing modes are:
    %      Mode-1:  Preamble puncturing in 80 MHz, when in the preamble
    %               only the secondary 20 MHz is punctured.
    %      Mode-2:  Preamble puncturing in 80 MHz, when in the preamble
    %               only one of the two 20 MHz subchannels in secondary 40
    %               MHz is punctured.
    %      Mode-3:  Preamble puncturing in 160 MHz, when in the primary 80
    %               MHz of the preamble only the secondary 20 MHz is
    %               punctured.
    %      Mode-4:  Preamble puncturing in 160 MHz, when in the primary 80
    %               MHz of the preamble only the primary 40 MHz is
    %               punctured.
    %
    %   The 'Mode-1' and 'Mode-2' are applicable for 'CBW80' and 'Mode-3'
    %   and 'Mode-4 are applicable for 'CBW160'. 'None' indicates there is
    %   no preamble puncturing in the recovered waveform. This property is
    %   applicable for HE MU packet. The default value of this property is
    %   'Unknown', which indicates an unknown or undefined preamble
    %   puncturing pattern.
    PreamblePuncturing = 'Unknown';
    %SIGBCompression Indicate HE-SIG-B compression of an HE-SIG-B field
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the HE-SIG-B compression of an HE-SIG-B field of HE MU
    %   packets. The value must be logical or double. The default is -1,
    %   which indicate an unknown or undefined state of SIGBCompression.
    SIGBCompression (1,1) double {wlan.internal.mustBeLogicalOrUnknown(SIGBCompression,'SIGBCompression')} = -1;
    %SIGBMCS Indicate the MCS of an HE-SIG-B field
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the modulation and coding scheme of the HE-SIG-B field as
    %   an integer scalar. The value must be an integer between 0 and 5,
    %   inclusive. This property is applicable for an HE MU packet. The
    %   default is -1, which indicates an unknown or undefined SIGBMCS
    %   value.
    SIGBMCS (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SIGBMCS,-1),mustBeLessThanOrEqual(SIGBMCS,5)} = -1;
    %SIGBDCM Indicate that HE-SIG-B field is modulated with DCM
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates whether HE-SIG-B field is modulated with dual carrier
    %   modulation (DCM). The value must be logical or double. DCM is only
    %   applicable for an HE MU packet when SIGBMCS is 0, 1, 3 or 4. The
    %   default is -1, which indicates an unknown or undefined SIGBDCM
    %   value.
    SIGBDCM (1,1) double {wlan.internal.mustBeLogicalOrUnknown(SIGBDCM,'SIGBDCM')} = -1;
    %NumSIGBSymbolsSignaled Number of HE-SIG-B symbols signaled in HE-SIG-A
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the number of symbols in HE-SIG-B field when
    %   SIGBCompression is set to false, as signaled in HE-SIG-A. This
    %   property is applicable for HE MU packets and is only visible when
    %   SIGBCompression property is set to false. The value must be an
    %   integer between 1 and 16 or -1. The value of 16 indicates there are
    %   16 or more HE-SIG-B symbols. The default is -1, which indicates
    %   an unknown or undefined number of HE-SIG-B symbols.
    NumSIGBSymbolsSignaled (1,1) {mustBeNumeric,mustBeMember(NumSIGBSymbolsSignaled,[-1,1:16])} = -1;
    %STBC Indicate space-time block coding
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates whether space-time block coding (STBC) is enabled in the
    %   data field transmission. STBC can only be applied for two
    %   space-time streams and when DCM is not used. The value must be
    %   logical or double. The default value of this property is -1, which
    %   indicates an unknown or undefined state of STBC.
    STBC (1,1) double {wlan.internal.mustBeLogicalOrUnknown(STBC,'STBC')} = -1;
    %LDPCExtraSymbol Indicate the presence of an extra OFDM symbol
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the presence of an extra OFDM symbol segment for LDPC
    %   coding. The value must be logical or double. The default value of
    %   this property is -1, which indicates an unknown or undefined number
    %   of LDPC extra symbols segments.
    LDPCExtraSymbol (1,1) double {wlan.internal.mustBeLogicalOrUnknown(LDPCExtraSymbol,'LDPCExtraSymbol')} = -1;
    %PreFECPaddingFactor Indicate the Pre-FEC padding factor
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the presence of pre-FEC padding factor in the recovered
    %   HE packet. PreFECPaddingFactor must be an integer scalar between 1
    %   and 4 inclusive. The default is -1, which indicates an unknown or
    %   undefined PreFECPaddingFactor value.
    PreFECPaddingFactor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(PreFECPaddingFactor,-1),mustBeLessThanOrEqual(PreFECPaddingFactor,4)} = -1;
    % PEDisambiguity Indicate the PE-Disambiguity in a HE packet
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the PE-Disambiguity in the recovered HE packet. The value
    %   must be logical or double. The default is -1, which indicates an
    %   unknown or undefined PEDisambiguity state.
    PEDisambiguity (1,1) double {wlan.internal.mustBeLogicalOrUnknown(PEDisambiguity,'PEDisambiguity')} = -1;
    %GuardInterval Indicate guard interval type of an HE packet
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the guard interval (cyclic prefix) length in microseconds
    %   of an HE packet. The allowed values are 0.8, 1.6 or 3.2. The
    %   default value of this property is -1, which indicates an unknown or
    %   undefined guard interval.
    GuardInterval {wlan.internal.heValidateGI(GuardInterval,[-1 0.8 1.6 3.2])} = -1;
    %HELTFType Indicate the HE-LTF compression mode of an HE PPDU
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the HE-LTF compression type of the recovered packet. The
    %   HE-LTF compression type should be one of 1, 2, or 4, corresponding
    %   to 1xHE-LTF, 2xHE-LTF and 4xHE-LTF modes respectively. The default
    %   is -1, which indicates an unknown or undefined HELTFType
    %   compression type.
    HELTFType (1,1) {mustBeNumeric,mustBeMember(HELTFType,[-1 1 2 4])} = -1;
    %NumHELTFSymbols Indicate the number of HE-LTF symbols
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the number of HE-LTF symbols as scalar integer between 1
    %   and 8, inclusive. The default is -1, which indicates an unknown or
    %   undefined number of HELTF symbol.
    NumHELTFSymbols (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(NumHELTFSymbols,-1),mustBeLessThanOrEqual(NumHELTFSymbols,8)} = -1;
    %UplinkIndication Uplink indication
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates that the PPDU is sent on an uplink transmission. The
    %   value must be logical or double. A value of false indicates a
    %   downlink transmission. The default is -1, which indicates an
    %   unknown or undefined transmission direction.
    UplinkIndication (1,1) double {wlan.internal.mustBeLogicalOrUnknown(UplinkIndication,'UplinkIndication')} = -1;
    %BSSColor Indicate basic service set (BSS) color identifier 
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default is -1, which
    %   indicates an unknown or undefined BSS color.
    BSSColor (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(BSSColor,-1),mustBeLessThanOrEqual(BSSColor,63)} = -1;
    %SpatialReuse Spatial reuse indication
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the SpatialReuse as an integer scalar between 0 and 15,
    %   inclusive. The default is -1, which indicates an unknown or
    %   undefined Spatial reuse value.
    SpatialReuse (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(SpatialReuse,-1),mustBeLessThanOrEqual(SpatialReuse,15)} = -1;
    %TXOPDuration Indicate the duration information for TXOP protection
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates TXOPDuration information signaled in HE-SIG-A field as an
    %   integer scalar between 0 and 127, inclusive. The decoded TXOP
    %   duration must be converted to microseconds as specified in IEEE Std
    %   802.11ax-2021, Tables 27-18 and 27-20. For more information see the
    %   documentation. The default is -1, which indicates an unknown or
    %   undefined duration for TXOP protection.
    TXOPDuration (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(TXOPDuration,-1),mustBeLessThanOrEqual(TXOPDuration,127)} = -1;
    %HighDoppler Indicate High Doppler mode
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates the high Doppler mode. The value must be logical or
    %   double. A value of true indicates high Doppler in HE-SIG-A. The
    %   default is -1, which indicates an unknown or undefined Doppler.
    HighDoppler (1,1) double {wlan.internal.mustBeLogicalOrUnknown(HighDoppler,'HighDoppler')} = -1;
    %MidamblePeriodicity Indicate midamble periodicity in number of OFDM symbols
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates HE-Data field midamble periodicity in OFDM symbols. The
    %   allowed values are 10 or 20 OFDM symbols. This property applies
    %   only when HighDoppler property is set to true. The default is -1,
    %   which indicates an unknown or undefined midamble periodicity in
    %   number of OFDM symbols.
    MidamblePeriodicity (1,1) {mustBeNumeric,mustBeMember(MidamblePeriodicity,[-1 10 20])} = -1;
    %AllocationIndex Indicate RU allocation index for each 20 MHz subchannel
    %   For a full band MU-MIMO reception, when SIGBCompression is true,
    %   the AllocationIndex is a scalar. This property is set after
    %   decoding the HE-SIG-A field and uses the channel bandwidth and
    %   number of users information to calculate the AllocationIndex. The
    %   AllocationIndex has following values:
    %      20 MHz:  AllocationIndex = 191 + NumUsers
    %      40 MHz:  AllocationIndex = 199 + NumUsers
    %      80 MHz:  AllocationIndex = 207 + NumUsers
    %      160 MHz: AllocationIndex = 215 + NumUsers
    %   When SIGBCompression is false the AllocationIndex is indicated for
    %   each 20MHz as scalar or a row vector. The AllocationIndex defines
    %   the number and sizes of RUs, and the number of users assigned to
    %   each RU. IEEE Std 802.11ax-2021, Table 27-26 defines the assignment
    %   index as an 8 bit index for each 20 MHz subchannel. The RU
    %   allocation for each assignment index can be viewed in the documentation. 
    %   The default is -1, which indicates an unknown or undefined RU
    %   allocation index.
    AllocationIndex {mustBeNumeric,mustBeInteger} = -1;
    %LowerCenter26ToneRU Indicate the presence of user in lower center 26-tone RU
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the presence of user in lower center 26-tone RU. The
    %   value must be logical or double. This property is applicable only
    %   when the channel bandwidth is 80 MHz or 160 MHz and a full
    %   bandwidth allocation is not used. This property is only visible
    %   when the RU allocation is appropriate. The default is -1, which
    %   indicates an unknown or undefined presence of user in lower center
    %   26-tone RU.
    LowerCenter26ToneRU (1,1) double {wlan.internal.mustBeLogicalOrUnknown(LowerCenter26ToneRU,'LowerCenter26ToneRU')} = -1
    %UpperCenter26ToneRU Indicate the presence of user in upper center 26-tone RU
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the presence of user in upper center 26-tone RU. The
    %   value must be logical or double. This property is applicable only
    %   when the channel bandwidth is 160 MHz and a full bandwidth
    %   allocation is not used. This property is only visible when the RU
    %   allocation is appropriate. The default is -1, which indicates an
    %   unknown or undefined presence of user in upper center 26-tone RU.
    UpperCenter26ToneRU (1,1) double {wlan.internal.mustBeLogicalOrUnknown(UpperCenter26ToneRU,'UpperCenter26ToneRU')} = -1;
    %NumUsersPerContentChannel Indicate the number of users per SIGB content channel
    %   This property is set after decoding the HE-SIG-A field for a full
    %   bandwidth MU-MIMO waveform and HE-SIG-B field for an OFDMA
    %   waveform. The recovered bits indicate the number of users in each
    %   SIGB content channel. This property is applicable for both full
    %   bandwidth MU-MIMO and OFDMA allocation. For full bandwidth MU-MIMO,
    %   the distribution of users on SIGB content channel is defined in
    %   IEEE Std 802.11ax-2021, Section 27.3.11.8. For OFDMA the distribution
    %   of number of users per content channel is determined from HE-SIG-B
    %   common field decoding. The default is -1, which indicates an
    %   unknown or undefined number of users.
    NumUsersPerContentChannel {mustBeNumeric,mustBeInteger} = -1;
    %RUTotalSpaceTimeStreams Indicate the total number of space time streams in the RU of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the total number of space time streams in an RU, as an
    %   integer scalar between 1 and 8, inclusive. The default is -1, which
    %   indicates an unknown or undefined number of total space time
    %   streams in an RU.
    RUTotalSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(RUTotalSpaceTimeStreams,[-1 1:8])} = -1;
    %RUSize Indicate the resource unit size for the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the resource unit size for the user of interest. The
    %   draft standard defines the RU size must be one of 26, 52, 106, 242,
    %   484, 996 and 1992 (2x996). The default is -1, which indicates an
    %   unknown or undefined resource unit size.
    RUSize (1,1) {mustBeNumeric, mustBeMember(RUSize,[-1 0 26 52 106 242 484 996 1992])} = -1;
    %RUIndex Indicate the resource unit index for the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the RU index as a positive integer. The RU index
    %   specifies the location of the RU within the channel. For example,
    %   in an 80 MHz transmission there are four possible 242 tone RUs, one
    %   in each 20 MHz subchannel. RU# 242-1 (size 242, index 1) is the RU
    %   occupying the lowest absolute frequency within the 80 MHz, and RU#
    %   242-4 (size 242, index 4) is the RU occupying the highest absolute
    %   frequency. The default value for this property is -1, which
    %   indicates an unknown or undefined resource unit index.
    RUIndex (1,1) {mustBeNumeric, mustBeInteger,mustBeGreaterThanOrEqual(RUIndex,-1),mustBeLessThanOrEqual(RUIndex,74)} = -1;
    %STAID Indicate the station identification number for the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the STAID of the user of interest. The STAID refer to the
    %   association identifier (AID) field as an integer between 0 and
    %   2047. The STAID is defined in IEEE Std 802.11ax-2021, Section
    %   26.11.1. The 11 LSBs of the AID field are used to address the STA.
    %   When STAID is set to 2046 the associated RU carries no data. The
    %   default value for this property is -1, which indicates an unknown
    %   or undefined station identification.
    STAID (1,1) {mustBeNumeric, mustBeInteger,mustBeGreaterThanOrEqual(STAID,-1),mustBeLessThanOrEqual(STAID,2047)} = -1;
    %MCS Indicate modulation and coding scheme for the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the modulation and coding scheme as an integer scalar.
    %   The MCS must be an integer between 0 and 11, inclusive. The
    %   default value for this property is -1, which indicates an unknown
    %   or undefined MCS value.
    MCS (1,1) {mustBeNumeric,mustBeInteger,mustBeGreaterThanOrEqual(MCS,-1),mustBeLessThanOrEqual(MCS,11)} = -1;
    %DCM Indicate dual coded modulation for HE-Data field for the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates that dual carrier modulation (DCM) is used for the
    %   HE-Data field for the user of interest. DCM can only be used with
    %   up to two space-time streams, and in a single-user RU. The value
    %   must be logical or double. The default value for this property is
    %   -1, which indicates an unknown or undefined DCM value.
    DCM (1,1) double {wlan.internal.mustBeLogicalOrUnknown(DCM,'DCM')} = -1;
    %ChannelCoding Indicate forward error correction coding type of the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the channel coding as one of 'BCC' or 'LDPC' to indicate
    %   binary convolution coding (BCC) or low-density-parity-check (LDPC)
    %   coding for the use of interest. The default value for this property
    %   is 'Unknown', which indicates an unknown or undefined channel
    %   coding type.
    ChannelCoding = 'Unknown';
    %Beamforming Indicate the use of beamforming steering matrix for the user of interest
    %   This property is set after decoding the HE-SIG-A field for HE SU
    %   waveform and HE-SIG-B field for HE MU waveform as logical scalar
    %   and indicates if a beamforming steering matrix is applied to the
    %   received waveform. The value must be logical or double. The default
    %   value for this property is -1, which indicates an unknown or
    %   undefined beamforming steering matrix.
    Beamforming (1,1) double {wlan.internal.mustBeLogicalOrUnknown(Beamforming,'Beamforming')} = -1;
    %PreHESpatialMapping Indicate the spatial mapping of pre-HE-STF portion
    %   This property is set after decoding the HE-SIG-A field and
    %   indicates if the pre-HE-STF portion of an HE SU waveform is
    %   spatially mapped the same way as the first symbol of the HE-LTF
    %   field on each tone. The value must be logical or double. The
    %   default value for this property is -1, which indicates an unknown
    %   or undefined PreHESpatialMapping value.
    PreHESpatialMapping (1,1) double {wlan.internal.mustBeLogicalOrUnknown(PreHESpatialMapping,'PreHESpatialMapping')} = -1;
    %NumSpaceTimeStreams Indicate the number of space-time streams for the user of interest
    %   This property is set after decoding the HE-SIG-A field for an HE SU
    %   waveform and HE-SIG-B field for an HE MU waveform. The decoded bits
    %   indicate the number of space-time streams for the user as an
    %   integer scalar between 1 and 8, inclusive. The default value for
    %   this property is -1, which indicates an unknown or undefined number
    %   of space time streams.
    NumSpaceTimeStreams (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(NumSpaceTimeStreams,[-1 1:8])} = -1;
    %SpaceTimeStreamStartingIndex Indicate the starting space time stream index for the user of interest
    %   This property is set after decoding the HE-SIG-B field and
    %   indicates the starting space-time stream index. When multiple users
    %   are transmitting in the same RU, in a MU-MIMO configuration, each
    %   user must transmit on different space-time streams. The
    %   StartingSpaceTimeStream and NumSpaceTimeStreams properties
    %   indicates different space time stream per user. The default value
    %   for this property is -1, which indicates an unknown or undefined
    %   starting space-time stream index.
    SpaceTimeStreamStartingIndex (1,1) {mustBeNumeric,mustBeInteger,mustBeMember(SpaceTimeStreamStartingIndex,[-1 1:8])} = -1;
end

properties(Constant,Hidden)
    PacketFormat_Values = {'HE-SU','HE-EXT-SU','HE-MU','Unknown'};
    ChannelBandwidth_Values = {'CBW20','CBW40','CBW80','CBW160','Unknown'};
    PreamblePuncturing_Values = {'Mode-1','Mode-2','Mode-3','Mode-4','None','Unknown'};
    ChannelCoding_Values = {'BCC','LDPC','Unknown'};
end
    
methods
    function obj = wlanHERecoveryConfig(varargin)
         if ~isempty(coder.target)
            packetFormat = 'Unknown';
            coder.varsize('packetFormat',[1 9],[0 1]); % Add variable-size support
            obj.PacketFormat = packetFormat; % Default

            channelBandwidth = 'Unknown';
            coder.varsize('channelBandwidth',[1 7],[0 1]); % Add variable-size support
            obj.ChannelBandwidth = channelBandwidth; % Default

            preamblePuncturing = 'Unknown';
            coder.varsize('preamblePuncturing',[1 7],[0 1]); % Add variable-size support
            obj.PreamblePuncturing = preamblePuncturing; % Default

            channelCoding = 'Unknown';
            coder.varsize('channelCoding',[1 7],[0 1]); % Add variable-size support
            obj.ChannelCoding = channelCoding; % Default

            numUsersPerContentChannel = -1;
            coder.varsize('numUsersPerContentChannel',[1 2],[0 1]); % Add variable-size support
            obj.NumUsersPerContentChannel = numUsersPerContentChannel; % Default

            allocationIndex = -1;
            coder.varsize('allocationIndex',[1 8],[0 1]); % Add variable-size support
            obj.AllocationIndex = allocationIndex; % Default
        end
        obj = setProperties(obj,varargin{:}); % Supperclass method for NV pair parsing
    end
    
    function obj = set.PacketFormat(obj,val)
        propName = 'PacketFormat';
        val = validateEnumProperties(obj,propName,val);
        obj.(propName) = val;
    end

    function obj = set.ChannelBandwidth(obj,val)
        propName = 'ChannelBandwidth';
        val = validateEnumProperties(obj,propName,val);
        obj.(propName) = val;
    end

    function obj = set.ChannelCoding(obj,val)
        propName = 'ChannelCoding';
        val = validateEnumProperties(obj,propName,val);
        obj.(propName) = val;
    end

    function obj = set.PreamblePuncturing(obj,val)
        propName = 'PreamblePuncturing';
        val = validateEnumProperties(obj,propName,val);
        obj.(propName) = val;
    end

    function obj = set.AllocationIndex(obj,val)
       propName = 'AllocationIndex';
       validateattributes(val,{'numeric'},{'nonempty','row','>=',-1,'<=',223});
       coder.internal.errorIf(~any(numel(val)==[1 2 4 8]),'wlan:wlanHERecoveryConfig:InvalidAllocationIndex');
       obj.(propName) = val;
    end
    
    function obj = set.NumUsersPerContentChannel(obj,val)
       propName = 'NumUsersPerContentChannel';
       validateattributes(val,{'numeric'},{'nonempty','row','>=',-1});
       coder.internal.errorIf(~any(numel(val)==[1 2]),'wlan:wlanHERecoveryConfig:InvalidNumUserPerContentChannel');
       obj.(propName) = val;
    end
    
    function [obj,failInterpretation] = interpretHESIGABits(obj,sigaBits)
    %interpretHESIGABits Interpret HE-SIG-A bits
    %   obj = interpretHESIGABits(obj,SIGABITS) parses and interprets
    %   decoded HE-SIG-A bits and returns an updated recovery object with
    %   the relevant HE-SIG-A fields set. The HE-SIG-A bit fields are
    %   defined in IEEE Std 802.11ax-2021, Table 27-18 and Table 27-20.
    %   When you use this syntax and the function cannot interpret the
    %   recovered HE-SIG-A bits due to an unexpected value, an exception is
    %   issued, and the function does not return an output.
    %
    %   SIGABITS is a column vector of size 52-by-1 of recovered HE-SIG-A
    %   information bits.
    %
    %   [...,FAILINTERPRETATION] = interpretHESIGABits(...) when you use
    %   this syntax and the function cannot interpret the recovered
    %   HE-SIG-A bits due to an unexpected value, the function returns the
    %   input obj with no change.
    %
    %   FAILINTERPRETATION is a logical scalar and represent the result of
    %   interpreting the recovered HE-SIG-A field bits. The function return
    %   this as true when it cannot interpret the received HE-SIG-A bits.
    %
    %   The PacketFormat property must not be 'Unknown'. This function
    %   supports only the HE SU, HE ER SU, and HE MU packet formats.
    %
    %   The following properties of the recovery object are updated for an
    %   HE MU packet after interpreting the HE-SIG-A bits.
    %
    %   * PreamblePuncturing
    %   * SIGBCompression
    %   * SIGBMCS
    %   * SIGBDCM
    %   * NumSIGBSymbolsSignaled
    %   * STBC
    %   * LDPCExtraSymbol
    %   * PreFECPaddingFactor
    %   * PEDisambiguity
    %   * GuardInterval
    %   * HELTFType
    %   * NumHELTFSymbols
    %   * UplinkIndication
    %   * BSSColor
    %   * SpatialReuse
    %   * TXOPDuration
    %   * HighDoppler
    %   * MidamblePeriodicity
    %   * AllocationIndex (Only when SIGBCompression is true)
    %   * NumUsersPerContentChannel
    %   * RUSize (Only when SIGBCompression is true)
    %   * RUIndex (Only when SIGBCompression is true)
    %
    %   The following properties of the recovery object are updated for an
    %   HE SU and HE ER SU packet after interpreting the HE-SIG-A bits.
    %
    %   * STBC
    %   * LDPCExtraSymbol
    %   * PreFECPaddingFactor
    %   * PEDisambiguity
    %   * GuardInterval
    %   * HELTFType
    %   * NumHELTFSymbols
    %   * UplinkIndication
    %   * BSSColor
    %   * SpatialReuse
    %   * TXOPDuration
    %   * HighDoppler
    %   * MidamblePeriodicity
    %   * RUSize
    %   * RUIndex
    %   * MCS
    %   * DCM
    %   * ChannelCoding
    %   * BeamForming
    %   * PreHESpatialMapping
    %   * NumSpaceTimeStreams

        nargoutchk(0,2);
        validateattributes(sigaBits,{'double','int8'},{'2d','binary','nrows',52,'ncols',1},mfilename,'HE-SIG-A bits');
        suppressError = nargout==2; % Validate the interpreted bit values
        failInterpretation = false;
        if strcmp(obj.PacketFormat,'HE-MU')
            inputObj = obj; % Copy of the input object
            [obj,failInterpretation] = wlan.internal.interpretHEMUSIGABits(sigaBits,obj,suppressError);
            if ~failInterpretation
                [~,failInterpretation] = validateLength(obj,suppressError);
                if failInterpretation
                    obj = inputObj; % Return the input object with no change
                end
            end
        elseif any(strcmp(obj.PacketFormat,{'HE-SU','HE-EXT-SU'}))
            if sigaBits(1)==1 % HE SU or HE ER SU
                inputObj = obj; % Copy of the input object
                [obj,failInterpretation] = wlan.internal.interpretHESUSIGABits(sigaBits,obj,suppressError);
                if ~failInterpretation
                    [~,failInterpretation] = validateLength(obj,suppressError);
                    if failInterpretation
                        obj = inputObj; % Return the input object with no change
                        return
                    end

                    failInterpretation = validateCodingRUArguments(obj,suppressError);
                    if failInterpretation
                        obj = inputObj; % Return the input object with no change
                    end
                end
            else % Invalid packet format
                if suppressError
                   failInterpretation = true;
                else
                   coder.internal.error('wlan:wlanHERecoveryConfig:InvalidPacketFormat');
                end
            end
        else % Unknown packet format
            coder.internal.error('wlan:wlanHERecoveryConfig:InvalidPacketFormat');
        end
    end

    function [obj,failInterpretation] = interpretHESIGBCommonBits(obj,sigbCommonBits,status)
    %interpretHESIGBCommonBits Interpret HE-SIG-B common field bits
    %   obj = interpretHESIGBCommonBits(obj,SIGBCOMMONBITS,STATUS) parses
    %   and interprets decoded HE-SIG-B common bits and returns an updated
    %   recovery object with the relevant HE-SIG-B fields set. The HE-SIG-B
    %   common bit fields are defined in IEEE Std 802.11ax-2021, Table
    %   27-20 and Table 27-24. Only HE MU packet format is supported. When
    %   you use this syntax and the function cannot interpret the recovered
    %   HE-SIG-B common field bits due to an unexpected value, an exception
    %   is issued, and the function does not return an output.
    %
    %   SIGBCOMMONBITS is an int8 matrix containing the recovered common
    %   field bits for each content channel of HE-SIG-B field. The size of
    %   the SIGBCOMMONBITS output depends on the channel bandwidth:
    %
    %   * For a channel bandwidth of 20 MHz the size of BITS is 18-by-1.
    %   * For a channel bandwidth of 40 MHz the size of BITS is 18-by-2.
    %   * For a channel bandwidth of 80 MHz the size of BITS is 27-by-2.
    %   * For a channel bandwidth of 160 MHz the size of BITS is 43-by-2.
    %
    %   STATUS is a character vector and represents the result of content
    %   channel decoding. The STATUS output is determined by the
    %   combination of cyclic redundancy check (CRC) per content channel
    %   and the number of HE-SIG-B symbols signaled in HE-SIG-A field. For
    %   more details see: wlanHESIGBCommonBitRecover documentation.
    %
    %   [...,FAILINTERPRETATION] = interpretHESIGBCommonBits(...) when you
    %   use this syntax and the function cannot interpret the recovered
    %   HE-SIG-B common field bits due to an unexpected value, the function
    %   returns the input obj with no change.
    %
    %   FAILINTERPRETATION is a logical scalar and represent the result of
    %   interpreting the recovered HE-SIG-B common field bits. The function
    %   return this as true when it cannot interpret the received HE-SIG-B
    %   common field bits.

        narginchk(3,3);
        nargoutchk(0,2);
        suppressError = nargout==2; % Validate the interpreted bit values

        % Validate channel bandwidth
        chanBW = wlan.internal.validateParam('CHANBW',obj.ChannelBandwidth,mfilename);
        cbw = wlan.internal.cbwStr2Num(chanBW);
        % The size of the SIGBCOMMONBITS depends on the channel bandwidth:
        switch cbw % Interpret input Status into failCRC
            case 20
                rows = 18;
                cols = 1;
            case 40
                rows = 18;
                cols = 2;
            case 80
                rows = 27;
                cols = 2;
            otherwise % 'CBW160'
                rows = 43;
                cols = 2;
        end
        validateattributes(sigbCommonBits,{'double','int8'},{'2d','binary','nrows',rows,'ncols',cols},mfilename,'HE-SIG-B common field bits');
        coder.internal.errorIf(~strcmp(obj.PacketFormat,'HE-MU'),'wlan:wlanHERecoveryConfig:InvalidPacketFormatHEMU');

        failInterpretation = validateHESIGB(obj,suppressError);
        if failInterpretation
            failInterpretation = true;
            return
        end

        sigbMCSTable = wlan.internal.heSIGBRateTable(obj.SIGBMCS,obj.SIGBDCM);
        commonInfo = wlan.internal.heSIGBCommonFieldInfo(cbw,sigbMCSTable.NDBPS);
        failCRC = coder.nullcopy(false(1,commonInfo.NumContentChannels));
        switch cbw % Interpret input Status into failCRC
            case 20
                if strcmp(status,'Success')
                    failCRC(1) = false;
                else
                    failCRC(1) = true;
                end
            otherwise % For BW > CBW20
                if strcmp(status,'Success')
                    failCRC = [false false];
                elseif any(strcmp(status,{'ContentChannel1CRCFail','UnknownNumUsersContentChannel1'}))
                    failCRC = [true false];
                elseif any(strcmp(status,{'ContentChannel2CRCFail','UnknownNumUsersContentChannel2'}))
                    failCRC = [false true];
                else % AllContentChannelCRCFail
                    failCRC = [true true];
                end
        end

        % If all content channel fails then do not process further
        if sum(all(failCRC,1))==numel(failCRC) % For codegen
            if suppressError % Return the input object with no change
                failInterpretation = true;
            end
            return
        end

        % Interpret HE-SIG-B common field bits
        [obj,failInterpretation] = wlan.internal.interpretHEMUSIGBCommonBits(sigbCommonBits,failCRC,obj,suppressError);
    end

    function [user,varargout] = interpretHESIGBUserBits(obj,sigbUserBits,failCRC)
    %interpretHESIGBUserBits Interpret HE-SIG-B user field bits
    %   USER = interpretHESIGBUserBits(obj,SIGBUSERBITS,FAILCRC) parses and
    %   interprets decoded HE-SIG-B user field bits and returns an updated
    %   recovery object with the relevant HE-SIG-B fields set. HE-SIG-B
    %   user bit fields are defined in IEEE Std 802.11ax-2021, Table 27-28
    %   and Table 27-29. Only HE MU packet format is supported. When you
    %   use this syntax and the function cannot interpret the recovered
    %   HE-SIG-B user field bits due to an unexpected value an exception is
    %   issued, and the function does not return an output.
    %
    %   The returned USER is a cell array of size 1-by-NumUsers. USER is
    %   the updated format configuration object after HE-SIG-B user field
    %   decoding, of type wlanHERecoveryConfig.
    %   The updated format configuration object USER is only returned for
    %   the users who pass the CRC.
    %
    %   SIGBUSERBITS is an int8 matrix of size 21-by-NumUsers, where
    %   NumUsers is the number of users in the transmission, containing the
    %   recovered user field bits for all users.
    %
    %   FAILCRC is a logical row vector of size 1-by-NumUsers representing
    %   the CRC result for each user.
    %
    %   [USER,FAILINTERPRETATION] = interpretHESIGBUserBits(...) parses and
    %   interprets decoded HE-SIG-B user field bits and returns an updated
    %   recovery object with the relevant HE-SIG-B fields set. When you use
    %   this syntax and the function cannot interpret the recovered
    %   HE-SIG-B user field bits for the user due to an unexpected value,
    %   the function does not return the respective USER object. 
    %
    %   FAILINTERPRETATION is a logical row vector of size 1-by-NumUsers,
    %   and represent the result of interpreting the recovered HE-SIG-B
    %   user field bits. Each element of FAILINTERPRETATION corresponds to
    %   a user and is true when the received HE-SIG-B user field bits
    %   cannot be interpreted.

        narginchk(3,3);
        nargoutchk(0,2);
        suppressError = nargout==2; % Validate the interpreted bit values

        % Validate PacketFormat ChannelBandwidth, SIGBCompression,
        % AllocationIndex, NumUserPerContentChannel
        coder.internal.errorIf(~strcmp(obj.PacketFormat,'HE-MU'),'wlan:wlanHERecoveryConfig:InvalidPacketFormatHEMU');
        wlan.internal.mustBeDefined(obj.SIGBCompression,'SIGBCompression');
        validateRUAllocation(obj);

        % Get the allocation index per content channel
        allocationIndex = obj.AllocationIndex;
        numUsersPerContentChannel = obj.NumUsersPerContentChannel;
        switch obj.ChannelBandwidth
            case 'CBW20'
                numContentChannels = 1;
            otherwise
                numContentChannels = 2;
        end
        invalidContentChannel = false(1,numContentChannels);
        coder.internal.errorIf(all(allocationIndex==-1),'wlan:shared:UndefinedProperty','AllocationIndex');
        coder.internal.errorIf(all(numUsersPerContentChannel==-1),'wlan:shared:UndefinedProperty','NumUsersPerContentChannel');

        if ~obj.SIGBCompression
            for i=1:numContentChannels
                % Check if there is an invalid user in NumUsersPerContentChannel
                invalidContentChannel(i) = numUsersPerContentChannel(i)==-1;
                allocationPerContentChannel = reshape(allocationIndex,numContentChannels,ceil(numel(allocationIndex)/2));
                invalidAllocationIndex = any(allocationPerContentChannel(i,:)==-1);
                coder.internal.errorIf(invalidAllocationIndex~=invalidContentChannel(i),'wlan:wlanHESIGBUserBitRecover:InvalidContentChannelLocation');
            end
        end

        % Validate sigbUserBits, failCRC against NumUsersPerContentChannel
        numUsers = sum(numUsersPerContentChannel(invalidContentChannel==0));
        validateattributes(sigbUserBits,{'double','int8'},{'2d','nrows',21,'ncols',numUsers},mfilename,'Input sigbUserBits');
        validateattributes(failCRC,{'logical'},{'ncols',numUsers},mfilename,'Input failCRC');

        [usersCfg,failInterpretation] = wlan.internal.interpretHEMUSIGBUserBits(sigbUserBits,invalidContentChannel,failCRC,obj,suppressError);

        % Dependent validation on all user
        if any(failInterpretation==0,2) % Do not process if all users fails independent property validation
            for u=1:numel(failInterpretation)
                if failInterpretation(u)==0
                    failInterpretation(u) = validateCodingRUArguments(usersCfg{u},suppressError);
                    if failInterpretation(u)==1
                        continue
                    end
                    failInterpretation(u) = validateDoppler(usersCfg{u},suppressError);
                end
            end
            if any(failInterpretation==0,2) % Do not process if all users fails validation
                numValidUsers = sum(failInterpretation==0,2); % Number of valid users
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
        varargout{1} = failInterpretation;
    end

    function s = getSIGBLength(obj)
    %getSIGBLength Returns information relevant to HE-SIG-B field length
    %    S = getSIGBLength(cfgRx) return a structure, S, containing the
    %    information related to HE-SIG-B field length. The output structure
    %    S has these fields:
    %
    %    NumSIGBCommonFieldSamples - Number of samples in HE-SIG-B common 
    %                                field
    %    NumSIGBSymbols            - Total number of symbols in the
    %                                HE-SIG-B field.
    %
    %    When SIGBCompression is true, the number of HE-SIG-B symbols is
    %    calculated using the coding parameters and number of users
    %    recovered in HE-SIG-A (NumUsersPerContentChannel, SIGBDCM and
    %    SIGBMCS).
    %
    %    When SIGBCompression is false and NumSIGBSymbolSignaled is less
    %    than 16 the number of HE-SIG-B symbols returned is that signaled in
    %    HE-SIG-A (NumSIGBSymbolSignaled).
    %
    %    When SIGBCompression is false and NumSIGBSymbolSignaled is 16 the
    %    number of HE-SIG-B symbols returned is calculated from the number
    %    of user fields recovered by decoding the HE-SIG-B common field
    %    (NumUsersPerContentChannel) and the coding parameters recovered
    %    from HE-SIG-A (SIGBDCM and SIGBMCS).

        % Get HE-SIG-B common field samples
        if (obj.SIGBDCM==-1) || (obj.SIGBMCS==-1) || (obj.SIGBCompression==-1) || ...
                strcmp(obj.PacketFormat,'Unknown') || strcmp(obj.ChannelBandwidth,'Unknown')
            % The object is in an uninitialized state the number of
            % HE-SIG-B common field and total number of HE-SIG-B symbols
            % are undefined.
            numSIGBCommonFieldSamples = -1;
            numHESIGBSymbols = -1;
        else
            if obj.SIGBCompression
                % No HE-SIG-B common field when SIGBCompression is true
                numSIGBCommonFieldSamples = 0;
            else
                numSIGBCommonFieldSamples = getNumSIGBCommonFieldSamples(obj.ChannelBandwidth,obj.SIGBMCS,obj.SIGBDCM);
            end
            numHESIGBSymbols = getNumSIGBSymbols(obj);
        end
        s = struct;
        s.NumSIGBCommonFieldSamples = numSIGBCommonFieldSamples;
        s.NumSIGBSymbols = numHESIGBSymbols;
    end

    function psduLength = getPSDULength(obj)
    %getPSDULength Returns the PSDU length in bytes for the recovered configuration
    %   Returns the PSDU length for an HE configuration. IEEE Std 802.11ax-2021, Section 27.4.3.

        validateCodingRUArguments(obj);
        s = validateConfig(obj);
        wlan.internal.mustBeDefined(obj.LDPCExtraSymbol,'LDPCExtraSymbol');
        nss = obj.NumSpaceTimeStreams;
        if obj.STBC
            nss = nss/2;
        end
        params = wlan.internal.heRecoverCodingParameters(s.NumDataSymbols,obj.PreFECPaddingFactor,obj.RUSize,obj.MCS, ...
            nss,obj.ChannelCoding,obj.STBC,obj.DCM,obj.LDPCExtraSymbol);
        psduLength = params.PSDULength;
    end

    function format = packetFormat(obj)
    %packetFormat Returns the HE packet type
    %   Returns the HE packet type as a character vector. Packet format is
    %   one of 'HE-SU', 'HE-EXT-SU', 'HE-MU', or 'Unknown'.

        format = obj.PacketFormat;
    end

    function varargout = validateConfig(obj,varargin)
    %validateConfig Validate the dependent properties of wlanHERecoveryConfig object
    %   validateConfig(obj) validates the dependent properties for the
    %   specified wlanHERecoveryConfig configuration object.
    % 
    %   For INTERNAL use only, subject to future changes
    %
    %   validateConfig(CFG,MODE) validates only the subset of dependent
    %   properties as specified by the MODE input. MODE must be one of:
    %       'HELTFGI'
    %       'HELTFGIHESU'
    %       'DataLocationLength'
    %       'Coding'
    %       'HESIGB'
    %       'RUAllocation'
    %       'HighDoppler'
    %       'Full'

        narginchk(1,2);
        nargoutchk(0,1);
        if (nargin==2)
            mode = varargin{1};
        else
            mode = 'Full';
        end

        switch mode
            case 'HELTFGI' % HELTF type and GuardInterval validation for HE SU, HE ER SU and HE MU
                validateHELTFGI(obj);
            case 'HELTFGIHESU' % HELTF type, GuardInterval, DCM and STBC validation for HE SU
                validateHELTFGIHESU(obj)
            case 'DataLocationLength' % wlanFieldIndices (HE-Data and HE-LTF)
                s = validateLength(obj);
            case 'Coding' % Coding and RU arrangements validation for HE SU, HE ER SU and HE MU
                validateCodingRUArguments(obj);
            case 'HESIGB' % HE-SIG-B validation for HE MU 
                validateHESIGB(obj);
            case 'RUAllocation'
                validateRUAllocation(obj)
            case 'HighDoppler'
                validateDoppler(obj);
            otherwise 
                % Validate MCS and length for HE SU, HE ER SU and HE MU
                s = validateLength(obj);
        end

        if nargout == 1
            varargout{1} = s;
        end
   end
end
   
methods (Access = private)
    function validateHELTFGI(obj)
    %validateHELTFGI Validate the HELTF type and GuardInterval of wlanHERecoveryConfig object
    %   Validated property-subset includes:
    %     HELTFType, GuardInterval
    
        coder.internal.errorIf(strcmp(obj.PacketFormat,'Unknown'),'wlan:wlanHERecoveryConfig:InvalidPacketFormat');
        wlan.internal.mustBeDefined(obj.HELTFType,'HELTFType'); % Check for undefined state
        wlan.internal.mustBeDefined(obj.GuardInterval,'GuardInterval'); % Check for undefined state;
        if strcmp(obj.PacketFormat,'HE-MU')
            % Validate GuardInterval and HELTFType 
            coder.internal.errorIf(obj.HELTFType==1,'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);     
        end
        coder.internal.errorIf((~(obj.HELTFType==2) && obj.GuardInterval==1.6),'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);
        coder.internal.errorIf((~(obj.HELTFType==4) && obj.GuardInterval==3.2),'wlan:shared:InvalidGILTF',feval('sprintf','%1.1f',obj.GuardInterval),'HELTFType',obj.HELTFType);   
    end
    
    function validateHELTFGIHESU(obj)
    %validateHELTFGIHESU Validate the HELTF type, GuardInterval, DCM and STBC for an HE-SU packet 
    %   Validated property-subset includes:
    %     HELTFType, GuardInterval, DCM, STBC
          
          % Check for undefined state
          wlan.internal.mustBeDefined(obj.STBC,'STBC');
          wlan.internal.mustBeDefined(obj.DCM,'DCM');
          wlan.internal.mustBeDefined(obj.HELTFType,'HELTFType');
          wlan.internal.mustBeDefined(obj.GuardInterval,'GuardInterval');
          coder.internal.errorIf((obj.DCM || obj.STBC) && (obj.GuardInterval==0.8 && obj.HELTFType==4), ...
              'wlan:he:SUInvalidGILTF4',feval('sprintf','%1.1f',obj.GuardInterval),obj.HELTFType);
    end
    
    function [s,failInterpretation] = validateLength(obj,varargin)
    %   validateLength Length properties of wlanHERecoveryConfig
    %   configuration object
    %
    %   [S,FAILINTERPRETATION] = validateLength(...,SUPPRESSERROR)
    %   controls the behaviour of the function when validating the
    %   dependent properties of obj. SUPPRESSERROR is logical. When
    %   SUPPRESSERROR is true, an invalid combination of the interpreted
    %   properties of the obj, sets FAILINTERPRETATION to true. When
    %   SUPPRESSERROR is false, an invalid combination of the interpreted
    %   properties of the obj results in an exception and the function does
    %   not return an output. The default is false.
    %
    %   Validated property-subset includes:   
    %     HELTFType, GuardInterval, SIGBMCS, SIGBDCM, SIGBCompression, 
    %     GuardInterval, PreFECPaddingFactor, NumHELTFSymbols, LSIGLength

        % Check for undefined state
        nargoutchk(0,2);
        suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
        if nargin>1
            suppressError = varargin{1};
        end
        failInterpretation = false;
        % Set output structure
        s = struct( ...
            'NumDataSymbols', -1, ...
            'RxTime', -1, ...% RxTime in us
            'TPE', -1);
        % Validate HELTFType and GuardInterval for HE-LTF
        validateHELTFGI(obj);

        if strcmp(obj.PacketFormat,'HE-MU')
            if suppressError
                failInterpretation = validateHESIGB(obj,suppressError);
                if failInterpretation
                    return
                end
            else
                validateHESIGB(obj);
            end
            sigbFieldInfo = getSIGBLength(obj);
            numHESIGBSymbols = sigbFieldInfo.NumSIGBSymbols;
        else
            numHESIGBSymbols = 0; % For codegen
            validateHELTFGIHESU(obj);
        end
        
        wlan.internal.mustBeDefined(obj.PreFECPaddingFactor,'PreFECPaddingFactor');
        trc = wlan.internal.heTimingRelatedConstants(obj.GuardInterval,obj.HELTFType,obj.PreFECPaddingFactor); % In microseconds
        
        wlan.internal.mustBeDefined(obj.NumHELTFSymbols,'NumHELTFSymbols');
        wlan.internal.mustBeDefined(obj.LSIGLength,'LSIGLength');
        wlan.internal.mustBeDefined(obj.HighDoppler,'HighDoppler');
        wlan.internal.mustBeDefined(obj.PEDisambiguity,'PEDisambiguity');
        NHELTF = obj.NumHELTFSymbols;
        switch obj.PacketFormat
            case 'HE-MU'
                NHESIGB = numHESIGBSymbols;
                m = 1; % Equation 27-11
                THE_PREAMBLE = trc.TRLSIG+trc.THESIGA+NHESIGB*trc.THESIGB+trc.THESTFNT+NHELTF*trc.THELTFSYM; % Equation 27-121
            case 'HE-SU'
                m = 2; % Equation 27-11
                THE_PREAMBLE = trc.TRLSIG+trc.THESIGA+trc.THESTFNT+NHELTF*trc.THELTFSYM; % Equation 27-121
            otherwise % 'HE-EXT-SU'
                m = 1; % Equation 27-11
                THE_PREAMBLE = trc.TRLSIG+trc.THESIGAR+trc.THESTFNT+NHELTF*trc.THELTFSYM; % Equation 27-121
        end
        
        Nma = 0;
        sf = 1e3; % Scaling factor to convert time in us into ns
        if obj.HighDoppler 
            wlan.internal.mustBeDefined(obj.MidamblePeriodicity,'MidamblePeriodicity');
            Tma = obj.MidamblePeriodicity*trc.TSYM + NHELTF*trc.THELTFSYM; % Equation 27-116
            Nma = max(0,floor((((obj.LSIGLength+m+3)/3)*4*sf-THE_PREAMBLE-(obj.PEDisambiguity+2)*trc.TSYM)/Tma)); % Equation 27-117
        end

        NSYM = floor(((((obj.LSIGLength+m+3)/3)*4*sf-THE_PREAMBLE-Nma*NHELTF*trc.THELTFSYM)/trc.TSYM))-obj.PEDisambiguity; % Equation 27-119
        TPE = floor(((((((obj.LSIGLength+m+3)/3)*4)*sf-THE_PREAMBLE)-(NSYM*trc.TSYM)-(Nma*NHELTF*trc.THELTFSYM)))/(4*sf))*4; % Equation 27-120
        trc.TPE = TPE*sf; % In nanoseconds

        RXTIME = ceil(20*sf+THE_PREAMBLE+NSYM*trc.TSYM+Nma*NHELTF*trc.THELTFSYM+trc.TPE); % Equation 27-132 (with no signal extension)

        if NSYM<0 % NSYM less than zero if LSIGLength or the interpreted HE-SIG-A bits are incorrect
            if suppressError
                failInterpretation = true;
            else
                coder.internal.error('wlan:shared:InvalidPktLength');
            end
        end

        % Set output structure
        s.NumDataSymbols = NSYM;
        s.RxTime = RXTIME/sf; % RxTime in us
        s.TPE = TPE;
    end
    
    function failInterpretation = validateCodingRUArguments(obj,varargin)
    %validateCodingRUArguments Coding and RU assignment properties of wlanHERecoveryConfig configuration object
    %   FAILINTERPRETATION = validateCodingRUArguments(obj) validates the
    %   dependent properties for the specified wlanHERecoveryConfig
    %   configuration object.
    %
    %   FAILINTERPRETATION = validateCodingRUArguments(...,SUPPRESSERROR)
    %   controls the behaviour of the function when validating the
    %   dependent properties of obj. SUPPRESSERROR is logical. When
    %   SUPPRESSERROR is true, an invalid combination of the interpreted
    %   properties of the obj, sets FAILINTERPRETATION to true. When
    %   SUPPRESSERROR is false, an invalid combination of the interpreted
    %   properties of the obj results in an exception and the function does
    %   not return an output. The default is false.
    %
    %   Validated property-subset includes:
    %     ChannelBandwidth, NumSpaceTimeStreams, STBC, MCS,
    %     ChannelCoding, RU Size, Upper106ToneRU

        % Check for undefined state
        nargoutchk(0,1);
        suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
        if nargin>1
            suppressError = varargin{1};
        end
        coder.internal.errorIf(strcmp(obj.PacketFormat,'Unknown'),'wlan:wlanHERecoveryConfig:InvalidPacketFormat');
        coder.internal.errorIf(strcmp(obj.ChannelCoding,'Unknown'),'wlan:shared:InvalidChannelCoding');
        wlan.internal.mustBeDefined(obj.STBC,'STBC');
        wlan.internal.mustBeDefined(obj.DCM,'DCM');
        wlan.internal.mustBeDefined(obj.MCS,'MCS');
        wlan.internal.mustBeDefined(obj.NumSpaceTimeStreams,'NumSpaceTimeStreams');
        
        % Validate RU sizes and channel bandwidth
        chanBW = wlan.internal.validateParam('CHANBW',obj.ChannelBandwidth,mfilename);
        wlan.internal.mustBeDefined(obj.RUSize,'RUSize');
        wlan.internal.mustBeDefined(obj.RUIndex,'RUIndex');
        ru = [obj.RUSize obj.RUIndex];
        rusize = wlan.internal.validateRUArgument(ru,wlan.internal.cbwStr2Num(chanBW));

        if strcmp(obj.PacketFormat,'HE-MU')
            % Validate MCS, DCM and STBC

            % For MU-MIMO transmission the total number of RU space time
            % streams must be equal to the sum of the number of space time
            % stream per users in an RU.
            wlan.internal.mustBeDefined(obj.RUTotalSpaceTimeStreams,'RUTotalSpaceTimeStreams'); % Check for undefined state
            MUMIMOFlag = obj.RUTotalSpaceTimeStreams~=obj.NumSpaceTimeStreams;

            failInterpretation =  wlan.internal.failInterpretationIf(obj.DCM && (MUMIMOFlag || ~any(obj.MCS == [0 1 3 4]) || obj.STBC || obj.NumSpaceTimeStreams>2), ...
                                                     'wlan:he:InvalidDCM',suppressError);
            if failInterpretation
                return
            end

            % Validate STBC and NumSpaceTimeStreams
            failInterpretation =  wlan.internal.failInterpretationIf(obj.STBC && (obj.NumSpaceTimeStreams~=2 || MUMIMOFlag),'wlan:he:MUNumSTSWithSTBC',suppressError);
            if failInterpretation
                return
            end
        else % HE SU and HE ER SU
            % Validate extended range
            if strcmp(obj.PacketFormat,'HE-EXT-SU')
                failInterpretation = wlan.internal.failInterpretationIf(~any(obj.RUSize==[106 242]),'wlan:wlanHERecoveryConfig:InvalidExtRangeRUSize',suppressError);
                if failInterpretation
                    return
                end
                % For extended range validate MCS range
                if rusize==106
                    % For extended range operation 106 only MCS0 is valid
                    failInterpretation = wlan.internal.failInterpretationIf(~obj.MCS==0,'wlan:he:InvalidExtRangeMCS106RU',suppressError);
                    if failInterpretation
                        return
                    end
                else
                    % For extended range operation 242 only MCS0,1,2 is valid
                    failInterpretation = wlan.internal.failInterpretationIf(~any(obj.MCS==[0 1 2]),'wlan:he:InvalidExtRangeMCS242RU',suppressError);
                    if failInterpretation
                        return
                    end
                end
            end

            % Validate STBC and NumSpaceTimeStreams
            failInterpretation = wlan.internal.failInterpretationIf((obj.STBC && obj.NumSpaceTimeStreams~=2),'wlan:he:InvalidNumSTSWithSTBC',suppressError);
            if failInterpretation
                return
            end
        end

        % Validate STBC and NumSpaceTimeStreams
        failInterpretation = wlan.internal.failInterpretationIf((obj.DCM && (~any(obj.MCS==[0 1 3 4]) || obj.STBC || obj.NumSpaceTimeStreams>2)),'wlan:he:InvalidDCM',suppressError);
        if failInterpretation
            return
        end

        if strcmp(obj.ChannelCoding,'BCC')
            % For extended range validate MCS range
            failInterpretation = wlan.internal.failInterpretationIf(rusize>242,'wlan:shared:InvalidBCCRUSize',suppressError);
            if failInterpretation
                return
            end

            failInterpretation = wlan.internal.failInterpretationIf(obj.NumSpaceTimeStreams>4,'wlan:shared:InvalidNSTS',suppressError);
            if failInterpretation
                return
            end

            failInterpretation = wlan.internal.failInterpretationIf(any(obj.MCS==[10 11]),'wlan:he:InvalidMCS',suppressError);
            if failInterpretation
                return
            end
        end
    end

    function failInterpretation = validateHESIGB(obj,varargin)
    %validateHESIGB Validate HE-SIG-B related properties of wlanHERecoveryConfig object
    %   FAILINTERPRETATION = validateHESIGB(obj) validates the dependent
    %   properties for the specified wlanHERecoveryConfig configuration
    %   object.
    %
    %   FAILINTERPRETATION = validateHESIGB(...,SUPPRESSERROR) controls the
    %   behaviour of the function when validating the dependent properties
    %   of obj. SUPPRESSERROR is logical. When SUPPRESSERROR is true, an
    %   invalid combination of the interpreted properties of the obj, sets
    %   FAILINTERPRETATION to true. When SUPPRESSERROR is false, an invalid
    %   combination of the interpreted properties of the obj results in an
    %   exception and the function does not return an output. The default
    %   is false.
    %
    %   Validated property-subset includes:
    %     SIGBDCM, SIGBMCS, NumSIGBSymbolsSignaled, SIGBCompression

        nargoutchk(0,1);
        % Check for undefined state
        suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
        if nargin>1
            suppressError = varargin{1};
        end
        wlan.internal.mustBeDefined(obj.SIGBMCS,'SIGBMCS');
        wlan.internal.mustBeDefined(obj.SIGBDCM,'SIGBDCM');
        wlan.internal.mustBeDefined(obj.SIGBCompression,'SIGBCompression');

        % Validate SIGBDCM against SIGBMCS (Table 27-19)
        failInterpretation = wlan.internal.failInterpretationIf((any(obj.SIGBMCS==[2 5]) && obj.SIGBDCM),'wlan:he:InvalidSIGBDCM',suppressError);
        if failInterpretation
            return
        end
    end 
    
    function validateRUAllocation(obj)
    %validateRUAllocation Validate RU allocation and number of user in an RU
    %   Validated property-subset includes:
    %     AllocationIndex, NumUsersPerContentChannel
              
        % Validate Channel Bandwidth
        chanBW = wlan.internal.validateParam('CHANBW',obj.ChannelBandwidth,mfilename);
        chbw = wlan.internal.cbwStr2Num(chanBW);
        % Validate the size of AllocationIndex
        N = ceil(chbw/20); % Row vector length of allocation index
        
        if strcmp(chanBW,'CBW20')
            numContentChannels = 1;
        else % CBW40/80/160
            numContentChannels = 2;
        end
        
        if obj.SIGBCompression
            validateattributes(obj.AllocationIndex,{'numeric'},{'real','row','finite','nrows',1},mfilename,'AllocationIndex');
        else
            validateattributes(obj.AllocationIndex,{'numeric'},{'real','row','finite','ncols',N},mfilename,'AllocationIndex');
        end
        
        % Validate NumUsersPerContentChannel
        validateattributes(obj.NumUsersPerContentChannel,{'numeric'},{'real','row','finite','ncols',numContentChannels},mfilename,'NumUsersPerContentChannel');
    end

    function failInterpretation = validateDoppler(obj,varargin)
    %validateDoppler Validate HighDoppler and Number of space time streams
    %   validateDoppler(obj) validates the dependent properties for the
    %   specified wlanHERecoveryConfig configuration object.
    %
    %   FAILINTERPRETATION = validateDoppler(...,SUPPRESSERROR) controls
    %   the behaviour of the function when validating the dependent
    %   properties of obj. SUPPRESSERROR is logical. When SUPPRESSERROR is
    %   true, an invalid combination of the interpreted properties of the
    %   obj, sets FAILINTERPRETATION to true. When SUPPRESSERROR is false,
    %   an invalid combination of the interpreted properties of the obj
    %   results in an exception and the function does not return an output.
    %   The default is false.
    %
    %   Validated property-subset includes:
    %     HighDoppler, NumSpaceTimeStreams

        nargoutchk(0,1);
        % Check for undefined state
        suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
        if nargin>1
            suppressError = varargin{1};
        end
        % Check for undefined state
        wlan.internal.mustBeDefined(obj.HighDoppler,'HighDoppler');
        if strcmp(obj.PacketFormat,'HE-MU')
            wlan.internal.mustBeDefined(obj.RUTotalSpaceTimeStreams,'RUTotalSpaceTimeStreams');
            failInterpretation = wlan.internal.failInterpretationIf((obj.HighDoppler && obj.RUTotalSpaceTimeStreams>4),'wlan:he:InvalidHighDoppler',suppressError);
        else
            failInterpretation = wlan.internal.failInterpretationIf((obj.HighDoppler && obj.NumSpaceTimeStreams>4),'wlan:he:InvalidHighDoppler',suppressError);
        end
    end
end
       
methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
    flag = false;
    if strcmp(prop,'MidamblePeriodicity')
        if obj.HighDoppler==0
            flag = true;
        end
    end  
    if any(strcmp(obj.PacketFormat,{'HE-SU','HE-EXT-SU'}))
        if any(strcmp(prop,{'SIGBCompression','SIGBMCS','SIGBDCM','AllocationIndex','NumUsersPerContentChannel','STAID','SpaceTimeStreamStartingIndex', ...
                'RUTotalSpaceTimeStreams','NumSIGBSymbolsSignaled','PreamblePuncturing','LowerCenter26ToneRU','UpperCenter26ToneRU'}))
            flag = true;
        end 
    elseif strcmp(obj.PacketFormat,'HE-MU')
        if strcmp(prop,'PreHESpatialMapping')
            flag = true;
        end
        if obj.SIGBCompression==1
            if any(strcmp(prop,{'LowerCenter26ToneRU','UpperCenter26ToneRU','NumSIGBSymbolsSignaled'})) 
                flag = true;
            end
        end
        if any(strcmp(obj.ChannelBandwidth,{'CBW20','CBW40'}))
            if any(strcmp(prop,{'LowerCenter26ToneRU','UpperCenter26ToneRU','PreamblePuncturing'}))
                flag = true;
            end
        end
        if strcmp(obj.ChannelBandwidth,'CBW80')
            if strcmp(prop,'UpperCenter26ToneRU')
                flag = true;
            end
        end
    end
    end
end

end

function numCommonFieldSamples = getNumSIGBCommonFieldSamples(chanBW,SIGBMCS,SIGBDCM)
%getNumSIGBCommonFieldSamples Get the maximum number of HE-SIG-B common field samples

    sigbMCSTable = wlan.internal.heSIGBRateTable(SIGBMCS,logical(SIGBDCM));
    chbw = wlan.internal.cbwStr2Num(chanBW);
    s = wlan.internal.heSIGBCommonFieldInfo(chbw,sigbMCSTable.NDBPS);
    numCommonFieldSamples = s.NumCommonFieldSamples;
end

function y = getNumSIGBSymbols(cfg)
%getNumSIGBSymbols Get number of HE-SIG-B symbols

numContentChannel = size(cfg.NumUsersPerContentChannel,2);
sigbMCSTable = wlan.internal.heSIGBRateTable(cfg.SIGBMCS,logical(cfg.SIGBDCM));

if cfg.SIGBCompression
    % Calculate the total number of HE-SIG-B Symbols from number of users
    % information recovered from HE-SIG-A field
    wlan.internal.mustBeDefined(cfg.NumUsersPerContentChannel,'NumUsersPerContentChannel');
    numCommonFieldBits = 0;
    y = wlan.internal.heNumSIGBSymbolsPerContentChannel(numContentChannel, ...
        cfg.NumUsersPerContentChannel,numCommonFieldBits,sigbMCSTable.NDBPS);

else
    if ~any(cfg.NumUsersPerContentChannel==-1) % Check for the unknown
    % Only calculate the number of HE-SIG-B Symbols, if all content channel pass the CRC check
        if cfg.NumSIGBSymbolsSignaled==16
            % A signaled value of 16 in HE-SIG-A field indicates, there
            % are 16 or more HE-SIG-B symbols in the packet. Calculate
            % the number of HE-SIG-B Symbols from the number of users
            % information recovered from HE-SIG-A field.
            chbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
            s = wlan.internal.heSIGBCommonFieldInfo(chbw,sigbMCSTable.NDBPS);
            y = wlan.internal.heNumSIGBSymbolsPerContentChannel(numContentChannel, ...
                cfg.NumUsersPerContentChannel,s.NumCommonFieldBits,sigbMCSTable.NDBPS);
        else % NumSIGBSymbolsSignaled<16
            y = cfg.NumSIGBSymbolsSignaled;
        end
    else
        % Content channel failure
        if cfg.NumSIGBSymbolsSignaled==16
            % A signaled value of 16 in HE-SIG-A field indicates, there
            % are 16 or more HE-SIG-B symbols in the packet. If any of
            % the content channel fails then the total number of users
            % indicated on all content channel cannot be determined. The
            % total number of user information is required to calculate the
            % number of HE-SIG-B symbols. Hence the number of HE-SIG-B
            % symbols is unknown.
            y = -1;
        else
            % A signaled value of less than 16, indicates the known number
            % of HE-SIG-B symbols in the packet, even if any of the content
            % channel fails the CRC.
            y = cfg.NumSIGBSymbolsSignaled;
        end
    end
end

end
