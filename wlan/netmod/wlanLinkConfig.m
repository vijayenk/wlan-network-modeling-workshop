classdef wlanLinkConfig < comm.internal.ConfigBase
%wlanLinkConfig Per-link configuration of WLAN multilink device (MLD)
%   LINKCFG = wlanLinkConfig() creates a default per-link configuration
%   object of a WLAN MLD.
%
%   LINKCFG = wlanLinkConfig(Name=Value) creates one or more per-link
%   configuration objects of a WLAN MLD with the specified property Name
%   set to the specified Value. You can specify additional name-value
%   arguments in any order as (Name1=Value1,...,NameN=ValueN). The number
%   of rows in "BandAndChannel" property specifies the number of link
%   configuration objects created. Specify "BandAndChannel" property as an
%   N-by-2 matrix, where N is the number of link configuration objects and
%   N>=1. Each row must contain two numeric values representing the
%   operating frequency band and channel number of the link. The output,
%   LINKCFG, is an object or an array of objects of the type
%   wlanLinkConfig. You can set the "BandAndChannel" property for multiple
%   links simultaneously by specifying it as N-V argument while creating
%   the object(s). After creating the link configuration objects, you can
%   only set the "BandAndChannel" property for one link configuration
%   object at a time.
%
%   wlanLinkConfig properties:
%
%   BandAndChannel              - Operating frequency band and channel number
%   PrimaryChannelIndex         - Index of primary 20 MHz channel
%   ChannelBandwidth            - Maximum bandwidth for transmission or reception in Hz
%   TransmissionFormat          - Physical layer (PHY) transmission format
%   MCS                         - Modulation and coding scheme
%   NumTransmitAntennas         - Number of transmit antennas
%   NumSpaceTimeStreams         - Number of space-time streams
%   AggregateHTMPDU             - Enable HT MPDUs aggregation
%   MPDUAggregationLimit        - Maximum number of MPDUs in an A-MPDU
%   RTSThreshold                - Threshold for frame length below which
%                                 RTS is not transmitted
%   DisableRTS                  - Disable RTS transmission
%   DisableAck                  - Disable acknowledgments
%   CWMin                       - Minimum range of contention window for
%                                 each access category (AC)
%   CWMax                       - Maximum range of contention window for
%                                 each AC
%   AIFS                        - Arbitrary interframe space (AIFS) value
%                                 for each AC
%   TXOPLimit                   - Transmission opportunity (TXOP) duration 
%                                 limit for each AC in units of 32 microseconds
%   RateControl                 - Rate control algorithm
%   BasicRates                  - Non-HT data rates supported in the basic
%                                 service set (BSS)
%   Use6MbpsForControlFrames    - Implement 6 Mbps data rate for control
%                                 frames
%   BeaconInterval              - Beacon interval in time units (TU)
%   InitialBeaconOffset         - Time offset specified for the first beacon
%                                 transmission in TU
%   TransmitPower               - Transmission power in dBm
%   TransmitGain                - Transmission gain in dB
%   ReceiveGain                 - Receive gain in dB
%   NoiseFigure                 - Receiver noise figure in dB
%   InterferenceModeling        - Type of interference modeling
%   MaxInterferenceOffset       - Maximum frequency offset for determining
%                                 the interfering signal
%
%   wlanLinkConfig properties (read-only):
%
%   ChannelFrequency            - Channel center frequency in Hz

%   Copyright 2023-2025 The MathWorks, Inc.

properties
    %BandAndChannel Operating frequency band and channel number
    %   Specify the band and channel as a vector of length two. The first
    %   value in the vector must be 2.4, 5, or 6 indicating the frequency
    %   band. The second value in the vector must be a channel number in
    %   the range [1, 13] if the frequency band is 2.4, in the range [36, 177]
    %   if the frequency band is 5, in the range [1, 233] if the frequency band
    %   is 6. The object allows only a set of valid numbers from the above
    %   ranges based on the value of "ChannelBandwidth" property.The default
    %   value is [5, 36].
    BandAndChannel {mustBeNumeric, mustBeRow, wlan.internal.validation.bandAndChannel(BandAndChannel,'BandAndChannel')} = [5, 36];

    %PrimaryChannelIndex Index of primary 20 MHz channel
    %   Specify the index of the primary 20 MHz channel in the channel
    %   bandwidth as an integer in the range [1, MaxPrimaryChannelIndex].
    %
    %   When ChannelBandwidth is set to 40e6,
    %       * MaxPrimaryChannelIndex is 2.
    %   When ChannelBandwidth is set to 80e6,
    %       * MaxPrimaryChannelIndex is 4.
    %   When ChannelBandwidth is set to 160e6,
    %       * MaxPrimaryChannelIndex is 8.
    %   When ChannelBandwidth is set to 320e6,
    %       * MaxPrimaryChannelIndex is 16.
    %
    %   To enable this property, set the "Mode" property of corresponding
    %   wlanMultilinkDeviceConfig object to "AP" and "ChannelBandwidth"
    %   property to a value greater than 20e6. This value represents the
    %   primary channel of the basic service set (BSS) that the AP creates.
    %
    %   Indexing starts from the lowest 20 MHz sub-channel. The default value
    %   is 1.
    PrimaryChannelIndex (1,1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(PrimaryChannelIndex,1), mustBeLessThanOrEqual(PrimaryChannelIndex,16)} = 1;

    %ChannelBandwidth Maximum bandwidth for transmission or reception in Hz
    %   Specify the maximum bandwidth for transmission or reception as 20e6,
    %   40e6, 80e6, 160e6, or 320e6. Units are in Hz.
    %
    %   When TransmissionFormat is set to "Non-HT" or "HE-EXT-SU",
    %       * ChannelBandwidth accepts only 20e6.
    %   When TransmissionFormat is set to "HT-Mixed",
    %       * ChannelBandwidth accepts 20e6 and 40e6.
    %   When TransmissionFormat is set to "VHT", or "HE-SU",
    %       * ChannelBandwidth accepts 20e6, 40e6, 80e6, and 160e6.
    %    When TransmissionFormat is set to "EHT-SU",
    %       * ChannelBandwidth accepts 20e6, 40e6, 80e6, 160e6, and 320e6.
    %
    %   The default value is 20e6.
    ChannelBandwidth (1, 1) {mustBeMember(ChannelBandwidth,[20e6, 40e6, 80e6, 160e6, 320e6])} = 20e6;

    %TransmissionFormat Physical layer transmission format
    %   Specify the physical layer (PHY) transmission format used for the
    %   unicast data frame transmissions as "Non-HT", "HT-Mixed", "VHT",
    %   "HE-SU", "HE-EXT-SU", or "EHT-SU".
    %
    %   The "EHT-SU" value indicates EHT MU PPDU format for a single user.
    %   The "EHT-SU" format value is allowed only when MACModel in the
    %   corresponding wlanNode object is set to
    %   "full-mac-with-frame-abstraction".
    %
    %   Broadcast data frame transmissions always use "Non-HT" format
    %   irrespective of this configuration.
    %
    %   The default value is "EHT-SU".
    TransmissionFormat = "EHT-SU";

    %MCS Modulation and coding scheme
    %   Specify the modulation and coding scheme as an integer in the range
    %   [0, 13].
    %
    %   When TransmissionFormat is set to "Non-HT",
    %       * The maximum value is 7.
    %   When TransmissionFormat is set to "HT-Mixed",
    %       * The maximum value is 7. The given MCS value
    %         from the range [0, 7] is mapped to [0, 31] based on the
    %         NumSpaceTimeStreams, using the calculation
    %         MCS+((NumSpaceTimeStreams-1)*8).
    %   When TransmissionFormat is set to "VHT",
    %       * The maximum value is 9.
    %       * For 20e6 Hz ChannelBandwidth,
    %           - MCS value 9 is only allowed when NumSpaceTimeStreams
    %             is set to 3 or 6
    %       * For 80e6 Hz,
    %           - MCS value 6 is not allowed when NumSpaceTimeStreams
    %             is set to 3 or 7
    %           - MCS value 9 is not allowed when NumSpaceTimeStreams
    %             is set to 6
    %       * For 160e6 Hz,
    %           - MCS value 9 is not allowed when NumSpaceTimeStreams
    %             is set to 3
    %   When TransmissionFormat is set to "HE-EXT-SU",
    %       * The maximum value is 2.
    %   When TransmissionFormat is set to "HE-SU",
    %       * The maximum value is 11.
    %   When TransmissionFormat is set to "EHT-SU",
    %       * The maximum value is 13.
    %
    %   This is only applicable for unicast data frame transmissions. Broadcast
    %   data frames are always transmitted using MCS 0.
    %
    %   The default value is 0.
    MCS (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(MCS,0), mustBeLessThanOrEqual(MCS,13)} = 0;

    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as an integer in the range [1,
    %   8]. The link uses the same number of antennas for reception.
    %
    %   If you set the EnhancedMultilinkMode property of the corresponding
    %   wlanMultilinkDeviceConfig object to "EMLSR", the link also uses this
    %   value as the number of antennas to listen for initial control frame
    %   (ICF). When the link is active, it aggregates the NumTransmitAntennas
    %   values of all links in wlanMultilinkDeviceConfig object and uses it for
    %   transmission and reception. The aggregated value must be less than or
    %   equal to 8. An EMLSR link at STA is said to be active when it:
    %   * Initiates a frame exchange sequence with an AP MLD (or)
    %   * Responds to ICF to continue the frame exchange sequence initiated by
    %     AP MLD
    %
    %   The default value is 1.
    NumTransmitAntennas (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(NumTransmitAntennas,1), mustBeLessThanOrEqual(NumTransmitAntennas,8)} = 1;

    %NumSpaceTimeStreams Number of space-time streams
    %   Specify the number of space-time streams as an integer in the range [1,
    %   8]. This value must be less than or equal to NumTransmitAntennas.
    %   If this value is less than the NumTransmitAntennas value, the node uses
    %   fourier spatial mapping.
    %
    %   This is only applicable for unicast data frames. To transmit broadcast
    %   data frames, the node uses the value 1.
    %
    %   If you set the EnhancedMultilinkMode property of corresponding
    %   wlanMultilinkDeviceConfig object to "EMLSR", the link uses the
    %   following value as the number of space time streams to transmit a data
    %   frame, when it is active:
    %     * Sum of NumSpaceTimeStreams values of all links in
    %       wlanMultilinkDeviceConfig object
    %
    %   The default value is 1.
    NumSpaceTimeStreams (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1), mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;

    %AggregateHTMPDU Enable HT MPDUs aggregation
    %   Set this property to true to concatenate multiple HT MPDUs into an
    %   aggregated MPDU (A-MPDU) for transmission. The default value is true.
    %   This property is only applicable when TransmissionFormat is set to
    %   "HT-Mixed".
    AggregateHTMPDU (1, 1) logical = true;

    %MPDUAggregationLimit Maximum number of MPDUs in an A-MPDU
    %   Specify the maximum number of MPDUs that can be aggregated in a single
    %   A-MPDU as an integer scalar in the range [1, 1024].
    %
    %   When TransmissionFormat is set to "HT-Mixed" and
    %   AggregateHTMPDU is set to true
    %       * The maximum value is 64
    %   When TransmissionFormat is set to "VHT",
    %       * The maximum value is 64
    %   When TransmissionFormat is set to "HE-SU", or "HE-EXT-SU",
    %       * The maximum value is 256
    %   When TransmissionFormat is set to "EHT-SU",
    %       * The maximum value is 1024
    %
    %   This property is not applicable when TransmissionFormat is set to
    %   "Non-HT" or when the TransmissionFormat is set to "HT-Mixed" with
    %   AggregateHTMPDU flag set to false.
    %
    %   The default value is 64.
    MPDUAggregationLimit (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(MPDUAggregationLimit,1), mustBeLessThanOrEqual(MPDUAggregationLimit,1024)} = 64;

    %RTSThreshold Threshold for frame length below which RTS is not transmitted
    %   Specify the RTS threshold as an integer in the range [0,
    %   6500631]. If the size of a MAC frame exceeds RTS threshold,
    %   RTS/CTS protection mechanism is used. The default value is 0.
    %   This property is applicable only when DisableRTS is set to
    %   false.
    RTSThreshold (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(RTSThreshold, 0), mustBeLessThanOrEqual(RTSThreshold,6500631)} = 0;

    %DisableRTS Disable RTS transmission
    %   Set this property to true to disable the RTS/CTS exchange in the
    %   simulation.
    %
    %   This property is not applicable for MU-RTS initial control
    %   frame (ICF) transmissions from an AP to an Enhanced Multilink Single
    %   Radio (EMLSR) STA.
    %
    %   The default value is false.
    DisableRTS (1, 1) logical = false;

    %DisableAck Disable acknowledgments
    %   Set this property to true to disable acknowledgments (no acknowledgment
    %   in response to data frame). The default value is false.
    DisableAck (1, 1) logical = false;

    %CWMin Minimum range of contention window for four ACs
    %   Specify minimum size of contention window in units of slots for Best
    %   Effort, Background, Video, and Voice traffic respectively. This value
    %   must be a vector of four integers. Each element in the vector must be
    %   in the range [1, 1023] and must be such that it can be expressed in the
    %   form of 2^X-1, where X is an integer. The default value is [15 15 7 3].
    CWMin (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(CWMin,1), mustBeLessThanOrEqual(CWMin,1023), eCWMustBeInteger(CWMin,"CWMin")}  = [15 15 7 3];

    %CWMax Maximum range of contention window for four ACs
    %   Specify maximum size of contention window in units of slots for Best
    %   Effort, Background, Video, and Voice traffic respectively. This value
    %   must be a vector of four integers. Each element in the vector must be
    %   in the range [1, 1023] and must be such that it can be expressed in the
    %   form of 2^X-1, where X is an integer. The default value is [1023 1023
    %   15 7].
    CWMax (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(CWMax,1), mustBeLessThanOrEqual(CWMax,1023), eCWMustBeInteger(CWMax,"CWMax")} = [1023 1023 15 7];

    %AIFS Arbitrary interframe space (AIFS) values for four ACs
    %   Specify arbitrary interframe space values in units of slots for Best
    %   Effort, Background, Video, and Voice traffic respectively. This value
    %   must be a vector of four integers. If you set the Mode property
    %   of the corresponding wlanMultilinkDeviceConfig object to "STA", specify
    %   each element of this vector in the range [2, 15]. If you set the Mode
    %   property to "AP", specify each element of this vector in the range [1,
    %   15]. The default value is [3 7 2 2].
    AIFS (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(AIFS,1), mustBeLessThanOrEqual(AIFS,15)} = [3 7 2 2];

    %TXOPLimit Transmission Opportunity (TXOP) duration limit for four
    %access categories (ACs), in units of 32 microseconds.
    %
    %   Specify the TXOP limit values in units of 32 microseconds, for
    %   Best Effort, Background, Video and Voice traffic respectively.
    %   This value must be a vector of four integers. Each element in the
    %   vector must be in the range [0, 1023]. If you specify any element in
    %   the vector as zero, the object disables multiple frame transmissions
    %   within a TXOP for the access category corresponding to that element.
    %
    %   A non-zero value of this property is not allowed in the
    %   following cases:
    %       * If TransmissionFormat is set to "Non-HT"
    %       * If TransmissionFormat is set to "HT-Mixed" with AggregateHTMPDU flag set to false.
    %
    %   The default value is [0 0 0 0].
    TXOPLimit (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(TXOPLimit,0), mustBeLessThanOrEqual(TXOPLimit,1023)} = [0 0 0 0];
    
    %RateControl Rate control algorithm
    %   Specify the rate control algorithm as "fixed", "auto-rate-fallback", an
    %   object of type wlanRateControlARF, or an object of a subclass of
    %   wlanRateControl. The default value is "fixed".
    %
    %   If you set this property as "fixed", the object uses the MCS and
    %   NumSpaceTimeStreams values from MCS and NumSpaceTimeStreams properties
    %   of the wlanLinkConfig object, respectively. If you specify this
    %   property as "auto-rate-fallback", an object of type wlanRateControlARF
    %   is used with default properties. You can also specify a custom rate
    %   control algorithm by using the wlanRateControl object. MCS and
    %   NumSpaceTimeStreams values are retrieved from the custom rate control
    %   object. When you create the corresponding wlanNode object, a copy of
    %   the custom rate control object is created and used. Any changes made to
    %   the custom rate control object are not reflected. This property
    %   supports dynamic rate control for only single user transmissions.
    RateControl = "fixed";

    %BasicRates Non-HT data rates supported in the BSS
    %   Specify Non-HT data rates supported in the BSS in Mbps as a vector
    %   which is a subset of [6 9 12 18 24 36 48 54]. The default value is [6
    %   12 24]. 6, 12, and 24 are mandatory rates to be included in this
    %   property. To enable this property, set the Mode property
    %   of the corresponding wlanMultilinkDeviceConfig object to "AP". The STAs
    %   associated to the AP use the same basic rates as the AP.
    BasicRates {mustBeMember(BasicRates, [6 9 12 18 24 36 48 54])} = [6 12 24];

    %Use6MbpsForControlFrames Implement 6Mbps data rate for control
    %frames
    %   Set this property to true to use 6 Mbps date rate for control frames.
    %   Control frames are always transmitted in Non-HT format. The default
    %   value is false.
    Use6MbpsForControlFrames (1, 1) logical = false;

    %BeaconInterval Beacon interval in time units (TU)
    %   To enable beacon transmissions, specify beacon interval as a scalar
    %   integer in the range [1, 254]. One TU is equal to 1024 microseconds.
    %
    %   At the end of each beacon interval, the beacon frames contend for
    %   medium access by using the voice access category. The MAC
    %   internally sets the service set identifier (SSID) in a beacon frame
    %   to "WLAN". To differentiate beacons of different APs in a packet
    %   analyzer tool such as Wireshark, use the MAC address of the AP
    %   transmitting the beacon.
    %
    %   This property is applicable when the Mode property of the corresponding
    %   wlanMultilinkDeviceConfig object is set to "AP". The default value is Inf.
    BeaconInterval (1,1) {mustBeNumeric, mustBeReal, validateBeaconInterval} = Inf;

    %InitialBeaconOffset Time offset specified for the first beacon
    %transmission in time units (TU)
    %   Specify a constant or random time offset before transmitting the
    %   first beacon, in TUs. One TU is equal to 1024 microseconds. Set
    %   this property as a nonnegative scalar integer or a nonnegative row
    %   vector of [MinTimeOffset, MaxTimeOffset], specifying a range for
    %   the time offset. If you specify this value as a scalar, the object
    %   assigns this value to the initial time offset. If you specify this
    %   value as a row vector, the object assigns a random numeric between
    %   MinTimeOffset and MaxTimeOffset (in microseconds) to the initial
    %   time offset. The valid values of scalar offset, MinTimeOffset, and
    %   MaxTimeOffset are the integers in the range [0, 254]. This
    %   property is applicable when the Mode property of the corresponding
    %   wlanMultilinkDeviceConfig object is set to "AP" and, BeaconInterval
    %   is set to a finite value. If you enable beacon transmission, the
    %   default value is [0, BeaconInterval]. Otherwise, the default value
    %   is not present.
    InitialBeaconOffset {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(InitialBeaconOffset,0), mustBeLessThanOrEqual(InitialBeaconOffset,254)};

    %TransmitPower Transmit power in dBm
    %   Specify the transmit power of the node as a scalar in dBm. The default
    %   value is 10 dBm.
    TransmitPower (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 10;

    %TransmitGain Transmit gain in dB
    %   Specify the transmit gain of the node as a scalar in dB. The default
    %   value is 0 dB.
    TransmitGain (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 0;

    %ReceiveGain Receive gain in dB
    %   Specify the receive gain of the node as a scalar in dB. The default
    %   value is 0 dB.
    ReceiveGain (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 0;

    %NoiseFigure Receiver noise figure in dB
    %   Specify the receiver noise figure as a non-negative scalar value in dB.
    %   The default value is 7 dB.
    NoiseFigure (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNonnegative} = 7;

    %InterferenceModeling Type of interference modeling
    %   Specify the type of interference modeling as "co-channel",
    %   "overlapping-adjacent-channel", or
    %   "non-overlapping-adjacent-channel".
    %
    %   If you set this property to "co-channel", the object considers:
    %     * Signals with the same center frequency and bandwidth as the
    %       receiver to be signal of interest (SOI) and interference
    %
    %   If you set this property to "overlapping-adjacent-channel", in addition
    %   to signals that satisfy the condition described under "co-channel", the
    %   object considers:
    %     * Signals whose one of the 20 MHz subchannels aligns with the primary
    %       20 MHz of the receiver as SOI.
    %     * Signals overlapping in frequency with the frequency range of the
    %       receiver operation, to be interference.
    %
    %   If you set this property to "non-overlapping-adjacent-channel", in
    %   addition to signals that satisfy the conditions described under
    %   "co-channel" and "overlapping-adjacent-channel", the object considers:
    %     * Signals overlapping with frequency in the range
    %       [f1-MaxInterferenceOffset, f2+MaxInterferenceOffset], to be
    %       interference. f1 and f2 are the starting and ending frequencies of
    %       receiver operation respectively.
    %
    %   The default value is "co-channel".
    InterferenceModeling = "co-channel";

    %MaxInterferenceOffset Maximum frequency offset for determining the
    %interfering signal
    %   Specify the maximum interference offset as a nonnegative scalar. Units
    %   are in Hz. This property specifies the offset between the edge of the
    %   receiver operating frequency and the edge of the interfering signal.
    %   This property applies only when you set the InterferenceModeling
    %   property to "non-overlapping-adjacent-channel". If you specify this
    %   property as Inf, the object considers all the signals that overlap in
    %   time, regardless of their frequency, to be interference. If you specify
    %   this value as a finite nonnegative scalar, the object considers all the
    %   signals overlapping in time with frequency in the range
    %   [f1-MaxInterferenceOffset, f2+MaxInterferenceOffset], as interference.
    %   f1 and f2 are the starting and ending frequencies of receiver operation
    %   respectively. The default value is 0.
    MaxInterferenceOffset (1,1) {mustBeNumeric, mustBeNonnegative} = 0;
end

properties(SetAccess=private)
    %ChannelFrequency Channel center frequency in Hz
    %   This property indicates the operating center frequency of the link
    %   corresponding to the configured value of the BandAndChannel property.
    %   This is a read-only property.
    ChannelFrequency;
end

properties(Hidden)
    %MappedTIDs List of TIDs mapped to this link
    %   Specify the TID values which can be transmitted on this link as a
    %   scalar or vector, where each element is in the range [0-7]. By default,
    %   all the TIDs are mapped to a link. Hence, the default value is 0:7.
    MappedTIDs (1, :) {mustBeNumericOrLogical, mustBeInteger, mustBeMember(MappedTIDs, 0:7)} = 0:7;
end

properties(Hidden, Dependent)
    %EDThreshold Energy detection threshold in dBm
    %   Specify the energy detection threshold as a scalar in dBm. The default
    %   value is -82 dBm.
    EDThreshold

    %MappedACs List of ACs corresponding to the TIDs that are mapped to this
    %link
    %   This property indicates the AC values corresponding to the TIDs which
    %   can be transmitted on this link. By default, all the TIDs are mapped to
    %   a link.
    MappedACs;
end

properties(Hidden, Constant)
    %PowerControl Power control
    %   A string value indicating the type of power control algorithm
    %   used.
    PowerControl = "FixedPower";

    %TID2AC Mapping from TID (values 0 to 7) to AC (values 0 to 3)
    %   Access Category corresponding to each TID, where TID+1 is the index
    TID2AC = [0 1 1 0 2 2 3 3]; % AC 0=BE, 1=BK, 2=Video, 3=Voice
end

properties (Hidden, Constant)
    TransmissionFormat_Values = ["Non-HT", "HT-Mixed", "VHT", "HE-SU", "HE-EXT-SU", "EHT-SU"];
    RateControl_Values = ["fixed", "auto-rate-fallback"];
    InterferenceModeling_Values = ["co-channel", "overlapping-adjacent-channel", "non-overlapping-adjacent-channel"];
end

methods (Access = protected)
    function flag = isInactiveProperty(obj, prop)
        flag = false;

        switch(prop)
            case "NumSpaceTimeStreams"
                flag = strcmp(obj.TransmissionFormat, "Non-HT");
            case "AggregateHTMPDU"
                flag = ~strcmp(obj.TransmissionFormat, "HT-Mixed");
            case {"MPDUAggregationLimit", "TXOPLimit"}
                flag = strcmp(obj.TransmissionFormat, "Non-HT") || (strcmp(obj.TransmissionFormat, "HT-Mixed") && ~obj.AggregateHTMPDU);
            case "RTSThreshold"
                flag = obj.DisableRTS;
            case "InitialBeaconOffset"
                flag = ~isfinite(obj.BeaconInterval);
            case "PrimaryChannelIndex"
                flag = obj.ChannelBandwidth == 20e6;
            case "MaxInterferenceOffset"
                    flag = ~strcmp(obj.InterferenceModeling, "non-overlapping-adjacent-channel");
        end
    end
end

methods
    function obj = wlanLinkConfig(varargin)
        % Name-value pair check
        if (mod(nargin,2) == 1)
            error(message('wlan:ConfigBase:InvalidPVPairs'))
        end

        numLinks = 1;
        if nargin > 0
            s = struct;
            % Identify the number of link config objects user intends to create based
            % on BandAndChannel value
            for idx = 1:2:nargin-1
                name = varargin{idx};
                value = varargin{idx+1};
                % Search the presence of 'BandAndChannel' N-V pair argument
                if strcmp(name, "BandAndChannel")
                    bandsAndChannels = value;
                    validateattributes(bandsAndChannels,{'numeric'},{'nonempty','ncols',2},'wlanLinkConfig','BandAndChannel');
                    numLinks = size(bandsAndChannels, 1);
                end

                % Set 'BeaconInterval'
                if strcmp(name, "BeaconInterval")
                    obj.(name) = value;
                end
                s.(name) = value;
            end

            % Search the presence of 'InitialBeaconOffset' N-V pair
            % argument to assign default value, if beacon transmission is
            % enabled and the user does not configure 'InitialBeaconOffset'
            if isfinite(obj.BeaconInterval) && ~isfield(s, "InitialBeaconOffset")
                obj.InitialBeaconOffset = [0 obj.BeaconInterval];
            end

            obj = repmat(obj, 1, numLinks);

            % Set the configuration as per the N-V pairs
            for idx = 1:2:nargin-1
                name = varargin{idx};
                value = varargin{idx+1};
                switch (name)
                    case 'BandAndChannel'
                        for linkIdx = 1:numLinks
                            obj(linkIdx).BandAndChannel = bandsAndChannels(linkIdx, :);
                        end
                    case 'RateControl'
                        isRateControlObj = isa(value,"wlanRateControl");
                        for linkIdx = 1:numLinks
                            % Configure the rate control algorithm at MAC for DL transmissions from the device
                            if isRateControlObj
                                % If value is a handle class, assign a copy of handle class
                                obj(linkIdx).RateControl = copy(value);
                            else
                                obj(linkIdx).RateControl = value;
                            end
                        end
                    otherwise
                        % Make all objects identical by setting same value for all the configurable
                        % properties, except band and channel
                        [obj.(char(name))] = deal(value);
                end
            end
        end
    end

    function obj = set.TransmissionFormat(obj, value)
        value = validatestring(value, obj.TransmissionFormat_Values, 'wlanLinkConfig', 'TransmissionFormat');
        obj.TransmissionFormat = value;
    end

    function value = get.ChannelFrequency(obj)
        band = obj.BandAndChannel(1);
        channel = obj.BandAndChannel(2);
        value = wlanChannelFrequency(channel, band);
    end

    function threshold = get.EDThreshold(obj)
        threshold = -82 + round(10 * log10(obj.ChannelBandwidth / 20e6));
    end

    function acs = get.MappedACs(obj)
        acs = unique(obj.TID2AC(obj.MappedTIDs+1));
    end

    function obj = set.RateControl(obj, value)
        validateattributes(value, {'string','char','wlanRateControl'},{},'wlanLinkConfig','RateControl');
        if isstring(value) || ischar(value)
            value = validatestring(value, obj.RateControl_Values, 'wlanLinkConfig', 'RateControl');
        else % object
            validateattributes(value,{'wlanRateControl'},{'scalar'},'wlanLinkConfig','RateControl');
        end
        obj.RateControl = value;
    end

    function obj = set.BasicRates(obj, value)
        obj.BasicRates = unique(value);
    end

    function obj = set.InterferenceModeling(obj, value)
        value = validatestring(value, obj.InterferenceModeling_Values, 'wlanLinkConfig', 'InterferenceModeling');
        obj.InterferenceModeling = value;
    end

    function obj = validateConfig(obj)
        band = obj.BandAndChannel(1);
        channelNum = obj.BandAndChannel(2);
        if (band == 6) && ~any(strcmp(obj.TransmissionFormat, ["HE-SU", "HE-EXT-SU", "EHT-SU"]))
            error(message('wlan:wlanLinkConfig:InvalidBand6GHz'))
        end
        switch obj.TransmissionFormat
            case {"HE-EXT-SU" "Non-HT"}
                if (obj.ChannelBandwidth ~= 20e6)
                    error(message('wlan:shared:BandwidthMustBe20'))
                end

            case "HT-Mixed"
                if all(obj.ChannelBandwidth ~= [20e6 40e6])
                    error(message('wlan:shared:InvalidBandwidthHTMixed'))
                end

            case "VHT"
                if (band == 2.4)
                    error(message('wlan:shared:InvalidBandVHT'))
                end
                if (obj.ChannelBandwidth == 320e6)
                    error(message('wlan:shared:InvalidChannelBandwidthVHT'))
                end

            case {"HE-SU"}
                if (obj.ChannelBandwidth == 320e6)
                    error(message('wlan:shared:InvalidChannelBandwidthHE'))
                end

            case "EHT-SU"
                if (obj.ChannelBandwidth == 320e6) && (band ~= 6)
                    error(message('wlan:shared:InvalidBandFor320MHz'))
                end

        end
        if (band == 2.4) && ~any(obj.ChannelBandwidth == [20e6, 40e6])
            error(message('wlan:shared:InvalidBandwidth2GHz'))
        end
        wlan.internal.validation.channelNumAndBandwidth(band, channelNum, obj.ChannelBandwidth);

        % Validate MCS on TransmissionFormat
        if strcmp(obj.RateControl, 'fixed')
            switch obj.TransmissionFormat
                case "HE-SU"
                    if (obj.MCS > 11)
                        error(message('wlan:shared:UnsupportedMCSHE'))
                    end

                case "HE-EXT-SU"
                    if (obj.MCS > 2)
                        error(message('wlan:shared:UnsupportedMCS', 2, obj.TransmissionFormat))
                    end

                case "VHT"
                    if (obj.MCS > 9)
                        error(message('wlan:shared:UnsupportedMCS', 9, obj.TransmissionFormat))
                    end
                    
                case "HT-Mixed"
                    if ((obj.MCS > 7))
                        error(message('wlan:shared:UnsupportedMCSHTMixed'))
                    end

                case "Non-HT"
                    if ((obj.MCS > 7))
                        error(message('wlan:shared:UnsupportedMCS', 7, obj.TransmissionFormat))
                    end
            end
        end

        % Check CWMin <= CWMax
        if (~all(obj.CWMin <= obj.CWMax))
            error(message('wlan:shared:InvalidCWValues'))
        end
        % Validate aggregation limit for HT-Mixed and VHT formats
        if ((obj.MPDUAggregationLimit > 64) && any(strcmp(obj.TransmissionFormat, ["HT-Mixed", "VHT"])))
            error(message('wlan:shared:InvalidAggregationLimit'))
        end
        % Validate aggregation limit for HE format
        if ((obj.MPDUAggregationLimit > 256) && any(strcmp(obj.TransmissionFormat, ["HE-SU", "HE-EXT-SU"])))
            error(message('wlan:shared:InvalidAggregationLimitHE'))
        end
        % Multi-frame TXOP unsupported with NonHT or HT-Mixed with
        % AggregateHTMPDU set to false
        if (strcmp(obj.TransmissionFormat, "Non-HT") || (strcmp(obj.TransmissionFormat, "HT-Mixed") && ~obj.AggregateHTMPDU)) && any(obj.TXOPLimit)
            error(message('wlan:shared:MFTXOPUnsupportedWithNonAggregation'))
        end
    end

    function validateNumSTS(obj, numSTS, numTxAntennas, isEMLSRLink)
        % Validates number of space time streams and transmit antennas based on
        % transmission format, MCS and CBW

        % Limit NumTransmitAntennas based on defined per-antenna
        % cyclic shifts in the standard.
        % As all rate-adaptation algorithms do not adapt the number of space-time
        % streams, validate fixed number of space-time streams for each format.
        if strcmp(obj.TransmissionFormat,"HT-Mixed")
            if (numTxAntennas > 4 && ~isEMLSRLink)
                error(message('wlan:shared:InvalidNumTxAntennasHTMixed'))
            end
            if (numTxAntennas > 4 && isEMLSRLink)
                error(message('wlan:wlanLinkConfig:InvalidEMLSRNumTxAntennasHTMixed'))
            end

            % No need to validate NumSpaceTimeStreams specifically for HT-MF as
            % NumSpaceTimeStreams>NumTransmitAntennas is validated separately.

        else % Non-HT, VHT, HE, or EHT-SU
            switch obj.TransmissionFormat
                case "HE-EXT-SU"
                    if (numSTS > 2 && ~isEMLSRLink)
                        error(message('wlan:shared:InvalidNumSTSHEEXTSU'))
                    end
                    if (numSTS > 2 && isEMLSRLink)
                        error(message('wlan:wlanLinkConfig:InvalidEMLSRNumSTSHEEXTSU'))
                    end

                case "Non-HT"
                    if (numSTS > 1 && ~isEMLSRLink)
                        error(message('wlan:shared:InvalidNumSTSNonHT'))
                    end
                    if (numSTS > 1 && isEMLSRLink)
                        error(message('wlan:wlanLinkConfig:InvalidEMLSRTxFormat'))
                    end

                otherwise % VHT, HE-SU, or EHT-SU
                    % No need to validate NumSpaceTimeStreams specifically for VHT, HE-SU, or
                    % EHT-SU. NumTransmitAntennas > NumSpaceTimeStreams is validated
                    % separately.
            end
        end
        % Validate that the number of space-time streams is never more
        % than the number of transmit antennas
        if (numSTS > numTxAntennas && ~isEMLSRLink)
            error(message('wlan:shared:InvalidNumSpaceTimeStreams'))
        end
        if (numSTS > numTxAntennas && isEMLSRLink)
            error(message('wlan:wlanLinkConfig:InvalidEMLSRNumSpaceTimeStreams'))
        end

        % Validate MCS and NumSTS on TransmissionFormat
        if strcmp(obj.RateControl, 'fixed') && strcmp(obj.TransmissionFormat, "VHT")
            switch obj.ChannelBandwidth
                case 20e6
                    if ((obj.MCS == 9) && ~any(numSTS == [3 6]) && ~isEMLSRLink)
                        error(message('wlan:shared:UnsupportedMCS9VHT20'))
                    end
                    if ((obj.MCS == 9) && ~any(numSTS == [3 6]) && isEMLSRLink)
                        error(message('wlan:wlanLinkConfig:UnsupportedEMLSRMCS9VHT20'))
                    end

                case 80e6
                    if ((obj.MCS == 6) && any(numSTS == [3 7]) && ~isEMLSRLink)
                        error(message('wlan:shared:UnsupportedMCS6VHT80'))
                    end
                    if ((obj.MCS == 6) && any(numSTS == [3 7]) && isEMLSRLink)
                        error(message('wlan:wlanLinkConfig:UnsupportedEMLSRMCS6VHT80'))
                    end
                    if ((obj.MCS == 9) && (numSTS == 6) && ~isEMLSRLink)
                        error(message('wlan:shared:UnsupportedMCS9NumSTSCBW', 6, 80))
                    end
                    if ((obj.MCS == 9) && (numSTS == 6) && isEMLSRLink)
                        error(message('wlan:wlanLinkConfig:UnsupportedEMLSRMCS9NumSTSCBW', 6, 80))
                    end

                case 160e6
                    if ((obj.MCS == 9) && (numSTS == 3) && ~isEMLSRLink)
                        error(message('wlan:shared:UnsupportedMCS9NumSTSCBW', 3, 160))
                    end
                    if ((obj.MCS == 9) && (numSTS == 3) && isEMLSRLink)
                        error(message('wlan:wlanLinkConfig:UnsupportedEMLSRMCS9NumSTSCBW', 3, 160))
                    end
            end
        end
    end
end
end

% Property validation functions

function validateBeaconInterval(value)
% Validate beacon interval
if isfinite(value)
    if ~(floor(value) == value) || (~(value>=1 && value<=254))
        error(message('wlan:wlanLinkConfig:InvalidBeaconInterval'));
    end
end
end

function eCWMustBeInteger(cw, prop)
% Validate that CW value can be represented in 2^X-1 where X is an integer
    eCW = log2(cw+1);
    eCWInteger = uint16(eCW);
    nonComplyingCWValues = cw(eCW ~= eCWInteger);
    if ~isempty(nonComplyingCWValues)
        error(message('wlan:shared:ECWNotAnInteger', prop, mat2str(nonComplyingCWValues)));
    end
end
