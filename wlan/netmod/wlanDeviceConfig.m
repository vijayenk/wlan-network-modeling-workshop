classdef wlanDeviceConfig < comm.internal.ConfigBase
%wlanDeviceConfig WLAN device configuration
%   DEVICECFG = wlanDeviceConfig() creates a default WLAN device
%   configuration object.
%
%   DEVICECFG = wlanDeviceConfig(Name=Value) creates a WLAN device
%   configuration object with the specified property Name set to the
%   specified Value. You can specify additional name-value arguments in any
%   order as (Name1=Value1, ..., NameN=ValueN).
%
%   wlanDeviceConfig properties:
%
%   Mode                        - Operating mode of the device
%   BandAndChannel              - Operating frequency band and channel number
%   PrimaryChannelIndex         - Index of primary 20 MHz channel
%   ChannelBandwidth            - Maximum bandwidth for transmission or reception in Hz
%   TransmissionFormat          - Physical layer (PHY) transmission format
%   MCS                         - Modulation and coding scheme
%   NumTransmitAntennas         - Number of transmit antennas
%   NumSpaceTimeStreams         - Number of space-time streams
%   AggregateHTMPDU             - Enable HT MPDUs aggregation
%   MPDUAggregationLimit        - Maximum number of MPDUs in an A-MPDU
%   TransmitQueueSize           - Size of a MAC transmission queue
%   ShortRetryLimit             - Maximum number of transmission attempts
%                                 for a frame
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
%   EnableUplinkOFDMA           - Enable access point (AP) to trigger
%                                 uplink (UL) OFDMA transmissions
%   MeshTTL                     - Mesh time-to-live
%   TransmitPower               - Transmission power in dBm
%   TransmitGain                - Transmission gain in dB
%   ReceiveGain                 - Receive gain in dB
%   NoiseFigure                 - Receiver noise figure in dB
%   BSSColor                    - Color of the BSS
%   OBSSPDThreshold             - Overlapping BSS (OBSS) Packet Detect (PD)
%                                 threshold in dBm
%   InterferenceModeling        - Type of interference modeling
%   MaxInterferenceOffset       - Maximum frequency offset for determining
%                                 the interfering signal
%
%   wlanDeviceConfig properties (read-only):
%
%   ChannelFrequency            - Channel center frequency in Hz

%   Copyright 2022-2025 The MathWorks, Inc.

    properties
        %Mode Operating mode of the device
        %   Specify the operating mode as "STA", "AP", or "mesh". The default
        %   is "STA".
        Mode = "STA";

        %BandAndChannel Operating frequency band and channel number
        %   Specify the band and channel as a vector of length two. The first value
        %   in the vector must be 2.4, 5, or 6 indicating the frequency band. The
        %   second value in the vector must be a channel number in the range [1,
        %   13] if the frequency band is 2.4, in the range [36, 177] if the
        %   frequency band is 5, in the range [1, 233] if the frequency band is 6.
        %   The object allows only a set of valid numbers from the above ranges
        %   based on the value of "ChannelBandwidth" property. The default value is
        %   [5, 36].
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
        %   To enable this property, set the "Mode" property to "AP" and
        %   "ChannelBandwidth" property to a value greater than 20e6. This value
        %   represents the primary channel of the basic service set (BSS) that the
        %   AP creates.
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
        %   When TransmissionFormat is set to "VHT", "HE-SU", or "HE-MU-OFDMA",
        %       * ChannelBandwidth accepts 20e6, 40e6, 80e6, and 160e6.
        %    When TransmissionFormat is set to "EHT-SU",
        %       * ChannelBandwidth accepts 20e6, 40e6, 80e6, 160e6, and 320e6.
        % 
        %   The default is 20e6.
        ChannelBandwidth (1, 1) {mustBeMember(ChannelBandwidth,[20e6, 40e6, 80e6, 160e6, 320e6])} = 20e6;

        %TransmissionFormat Physical layer transmission format
        %   Specify the physical layer (PHY) transmission format used for the
        %   unicast data frame transmissions as "Non-HT", "HT-Mixed", "VHT",
        %   "HE-SU", "HE-EXT-SU", "HE-MU-OFDMA", or "EHT-SU".
        %
        %   The "HE-MU-OFDMA" value indicates "HE-MU" format with
        %   DL OFDMA frame exchange sequence containing DL MU PPDU, DL
        %   MU-BAR, and UL MU BAs. The "HE-MU-OFDMA" format value is supported
        %   only when the Mode value is set to "AP" and MACModel in the
        %   corresponding wlanNode object is set to
        %   "full-mac-with-frame-abstraction".
        %
        %   The "EHT-SU" value indicates EHT MU PPDU format for a single user.
        %   The "EHT-SU" format value is allowed only when MACModel in the
        %   corresponding wlanNode object is set to
        %   "full-mac-with-frame-abstraction".
        %
        %	Data frames transmitted in response to trigger frames always use
        %   "HE-TB" format irrespective of this configuration.
        %
        %   Broadcast data frame transmissions always use "Non-HT" format
        %   irrespective of this configuration.
        %
        %   The default is "HE-SU".
        TransmissionFormat = "HE-SU";

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
        %   When TransmissionFormat is set to "HE-SU", or "HE-MU-OFDMA",
        %       * The maximum value is 11.
        %   When TransmissionFormat is set to "EHT-SU",
        %       * The maximum value is 13.
        %
        %   This is only applicable for unicast data frame transmissions. Broadcast
        %   data frames are always transmitted using MCS 0.
        %
        %   When the Mode property is set to "AP" and the EnableUplinkOFDMA property
        %   is set to true, AP also asks the associated stations to use this value
        %   for UL OFDMA transmissions.
        %
        %   The default is 0.
        MCS (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(MCS,0), mustBeLessThanOrEqual(MCS,13)} = 0;

        %NumTransmitAntennas Number of transmit antennas
        %   Specify the number of transmit antennas as an integer in the range [1,
        %   8]. The device uses the same number of antennas for reception. The
        %   default is 1.
        NumTransmitAntennas (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(NumTransmitAntennas,1), mustBeLessThanOrEqual(NumTransmitAntennas,8)} = 1;

        %NumSpaceTimeStreams Number of space-time streams
        %   Specify the number of space-time streams as an integer in the range [1,
        %   8]. This value must be less than or equal to NumTransmitAntennas.
        %   If this value is less than the NumTransmitAntennas value, the node uses
        %   fourier spatial mapping.
        %
        %   This is only applicable for unicast data frames. To transmit broadcast 
        %   data frames, the node uses the value 1. If you set the Mode property to 
        %   "AP" and enable UL OFDMA transmissions, the AP requests the associated 
        %   STAs to use this value for UL OFDMA transmissions. If you set the Mode 
        %   property to "STA" and enable UL OFDMA transmissions in the associated
        %   AP, the STA ignores this property and uses the value from the trigger
        %   frame for UL OFDMA transmissions.
        %   
        %   The default is 1.
        NumSpaceTimeStreams (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(NumSpaceTimeStreams,1), mustBeLessThanOrEqual(NumSpaceTimeStreams,8)} = 1;

        %AggregateHTMPDU Enable HT MPDUs aggregation
        %   Set this property to true to concatenate multiple HT MPDUs into an
        %   aggregated MPDU (A-MPDU) for transmission. The default is true.
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
        %   When TransmissionFormat is set to "HE-SU", "HE-EXT-SU", or
        %   "HE-MU-OFDMA",
        %       * The maximum value is 256
        %   When TransmissionFormat is set to "EHT-SU",
        %       * The maximum value is 1024
        %
        %   This property is not applicable when TransmissionFormat is set to
        %   "Non-HT" or when the TransmissionFormat is set to "HT-Mixed" with
        %   AggregateHTMPDU flag set to false. 
        % 
        %   The default is 64.
        MPDUAggregationLimit (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(MPDUAggregationLimit,1), mustBeLessThanOrEqual(MPDUAggregationLimit,1024)} = 64;

        %TransmitQueueSize Size of a MAC transmission queue
        %   Specify the size of the queue for buffering the frames (MSDUs)
        %   to be transmitted from the MAC layer as an integer scalar in
        %   the range [1, 2048]. The queue size specified here corresponds
        %   to the size of each per-destination and per-AC queue.
        %
        %   If the TransmissionFormat is "EHT-SU", the default is 
        %   1024. Otherwise, the default is 256.
        TransmitQueueSize (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(TransmitQueueSize,1), mustBeLessThanOrEqual(TransmitQueueSize,2048)} = 256;
        
        %ShortRetryLimit Maximum number of transmission attempts for a frame
        %   Specify the maximum number of transmission attempts for a frame as an
        %   integer in the range [1, 65535]. The default is 7.
        ShortRetryLimit (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(ShortRetryLimit,1), mustBeLessThanOrEqual(ShortRetryLimit,65535)} = 7;

        %RTSThreshold Threshold for frame length below which RTS is not
        %transmitted
        %   Specify the RTS threshold as an integer in the range [0,
        %   6500631]. If the size of a MAC frame exceeds RTS threshold,
        %   RTS/CTS protection mechanism is used. The default is 0.
        %   This property is applicable only when DisableRTS is set to 
        %   false and when TransmissionFormat is not set to "HE-MU-OFDMA".
        RTSThreshold (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(RTSThreshold, 0), mustBeLessThanOrEqual(RTSThreshold,6500631)} = 0;

        %DisableRTS Disable RTS transmission
        %   Set this property to true to disable the RTS/CTS or MU-RTS/CTS exchange
        %   in the simulation. The default is false.
        DisableRTS (1, 1) logical = false;

        %DisableAck Disable acknowledgments
        %   Set this property to true to disable acknowledgments (no acknowledgment
        %   in response to data frame). The default is false.
        DisableAck (1, 1) logical = false;

        %CWMin Minimum range of contention window for four ACs
        %   Specify minimum size of contention window for Best Effort, Background,
        %   Video, and Voice traffic respectively. This value must be a vector of
        %   four integers. Each element in the vector must be in the range [1,
        %   1023] and must be such that it can be expressed in the form of 2^X-1,
        %   where X is an integer. The default is [15 15 7 3].
        CWMin (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(CWMin,1), mustBeLessThanOrEqual(CWMin,1023), eCWMustBeInteger(CWMin,"CWMin")}  = [15 15 7 3];

        %CWMax Maximum range of contention window for four ACs
        %   Specify maximum size of contention window for Best Effort, Background,
        %   Video, and Voice traffic respectively. This value must be a vector of
        %   four integers. Each element in the vector must be in the range [1,
        %   1023] and must be such that it can be expressed in the form of 2^X-1,
        %   where X is an integer. The default is [1023 1023 15 7].
        CWMax (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(CWMax,1), mustBeLessThanOrEqual(CWMax,1023), eCWMustBeInteger(CWMax,"CWMax")} = [1023 1023 15 7];

        %AIFS Arbitrary interframe space (AIFS) values for four ACs
        %   Specify arbitrary interframe space values in units of slots for Best
        %   Effort, Background, Video, and Voice traffic respectively. This value
        %   must be a vector of four integers. If you set the Mode property to "STA"
        %   or "mesh", specify each element of this vector in the range [2, 15]. If
        %   you set the Mode property to "AP", specify each element of this vector
        %   in the range [1, 15]. The default is [3 7 2 2].
        AIFS (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(AIFS,1), mustBeLessThanOrEqual(AIFS,15)} = [3 7 2 2];

        %TXOPLimit Transmission Opportunity (TXOP) duration limit for
        %four access categories (ACs), in units of 32 microseconds.
        %
        %   Specify the TXOP limit values in units of 32 microseconds, for
        %   Best Effort, Background, Video and Voice traffic respectively.
        %   This value must be a vector of four integers. Each element in
        %   the vector must be in the range [0, 1023]. If you specify any
        %   element in the vector as zero, the object disables multiple
        %   frame transmissions within a TXOP for the access category
        %   corresponding to that element.
        %
        %   A non-zero value of this property is not allowed in the
        %   following cases:
        %       * If Mode is set to "mesh"
        %       * If TransmissionFormat is set to "Non-HT"
        %       * If TransmissionFormat is set to "HT-Mixed" with AggregateHTMPDU flag set to false.
        %
        %   The default is [0 0 0 0].
        TXOPLimit (1, 4) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(TXOPLimit,0), mustBeLessThanOrEqual(TXOPLimit,1023)} = [0 0 0 0];
       
        %RateControl Rate control algorithm
        %   Specify the rate control algorithm as "fixed", "auto-rate-fallback", an
        %   object of type wlanRateControlARF, or an object of a subclass of
        %   wlanRateControl. The default value is "fixed".
        %
        %   If you set this property as "fixed", the object uses the MCS and
        %   NumSpaceTimeStreams values from MCS and NumSpaceTimeStreams properties
        %   of the wlanDeviceConfig object, respectively. If you specify this
        %   property as "auto-rate-fallback", an object of type wlanRateControlARF
        %   is used with default properties. You can also specify a custom rate
        %   control algorithm by using the wlanRateControl object. MCS and
        %   NumSpaceTimeStreams values are retrieved from the custom rate control
        %   object. When you create the corresponding wlanNode object, a copy of
        %   the custom rate control object is created and used. Any changes made to
        %   the custom rate control object are not reflected. This property
        %   supports dynamic rate control for only single user transmissions. If
        %   TransmissionFormat is set as "HE-MU-OFDMA", this property must be set
        %   to "fixed".
        RateControl = "fixed";
        
        %BasicRates Non-HT data rates supported in the BSS
        %   Specify Non-HT data rates supported in the BSS in Mbps as a vector
        %   which is a subset of [6 9 12 18 24 36 48 54]. The default is [6 
        %   12 24]. 6, 12, and 24 are mandatory rates to be included in this
        %   property. To enable this property, set the Mode property to "AP". 
        %   The stations associated to the AP use the same basic rates as the AP.
        BasicRates {mustBeMember(BasicRates, [6 9 12 18 24 36 48 54])} = [6 12 24];

        %Use6MbpsForControlFrames Implement 6Mbps data rate for control
        %frames
        %   Set this property to true to use 6 Mbps date rate for control frames.
        %   Control frames are always transmitted in Non-HT format. The default
        %   value is false.
        Use6MbpsForControlFrames (1, 1) logical = false;

        %BeaconInterval Beacon interval in time units (TU)
        %   To enable beacon transmissions, specify beacon interval as a
        %   scalar integer in the range [1, 65535]. One TU is equal to
        %   1024 microseconds.
        %
        %   At the end of each beacon interval, the beacon frames contend
        %   for medium access by using the voice access category. The MAC
        %   internally sets the service set identifier (SSID) in a beacon
        %   frame to "WLAN". To differentiate beacons of different AP or
        %   Mesh devices in a packet analyzer tool such as Wireshark, use
        %   the MAC address of the AP or mesh device transmitting the
        %   beacon.
        %
        %   This property is applicable when Mode is set to "AP" or "mesh".
        %   The default is Inf.
        BeaconInterval (1,1) {mustBeNumeric, mustBeReal, validateBeaconInterval} = Inf;

        %InitialBeaconOffset Time offset specified for the first beacon
        %transmission in time units (TU)
        %   Specify a constant or random time offset before transmitting
        %   the first beacon, in TUs. One TU is equal to 1024 microseconds.
        %   Set this property as a nonnegative scalar integer or a
        %   nonnegative row vector of [MinTimeOffset, MaxTimeOffset],
        %   specifying a range for the time offset. If you specify this
        %   value as a scalar, the object assigns this value to the initial
        %   time offset. If you specify this value as a row vector, the
        %   object assigns a random numeric between MinTimeOffset and
        %   MaxTimeOffset (in microseconds) to the initial time offset. The
        %   valid values of scalar offset, MinTimeOffset, and MaxTimeOffset
        %   are the integers in the range [0, 65535]. This property is
        %   applicable when Mode is set to "AP" or "mesh", and BeaconInterval
        %   is set to a finite value. If you enable beacon transmission,
        %   the default value is [0, BeaconInterval]. Otherwise, the default
        %   value is not present.
        InitialBeaconOffset {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(InitialBeaconOffset,0), mustBeLessThanOrEqual(InitialBeaconOffset,65535)};

        %EnableUplinkOFDMA Enable AP to trigger UL OFDMA transmissions
        %   Set this property to true for an AP node to trigger UL OFDMA data
        %   transmissions from the associated stations. This property is applicable
        %   only when the Mode property is set to "AP" and the TransmissionFormat
        %   property is set to "HE-SU", or "HE-MU-OFDMA". The default is false.
        EnableUplinkOFDMA (1, 1) logical = false;

        %MeshTTL Mesh time-to-live
        %   Specify this property as an integer scalar in the range [1, 255]. This
        %   value represents the maximum number of hops that a packet can traverse
        %   in a mesh network to reach its destination before it is dropped. The
        %   default value is 31.
        %   This property is applicable only when Mode is set to "mesh".
        MeshTTL (1, 1) {mustBeNumericOrLogical, mustBeInteger, mustBeGreaterThanOrEqual(MeshTTL,1), mustBeLessThanOrEqual(MeshTTL,255)} = 31;

        %TransmitPower Transmit power in dBm
        %   Specify the transmit power of the node as a scalar in dBm. If you
        %   enable spatial reuse, the object might not use this value. In this
        %   case, the object selects the minimum value between this value and the
        %   adjusted transmit power as the transmit power. For more information
        %   about the adjusted transmit power, see section 26.10.2.4 in IEEE Std
        %   802.11ax-2021. The default is 10 dBm.
        TransmitPower (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 10;

        %TransmitGain Transmit gain in dB
        %   Specify the transmit gain of the node as a scalar in dB. The default
        %   is 0 dB.
        TransmitGain (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 0;

        %ReceiveGain Receive gain in dB
        %   Specify the receive gain of the node as a scalar in dB. The default
        %   is 0 dB.
        ReceiveGain (1,1) {mustBeNumeric, mustBeReal, mustBeFinite} = 0;

        %NoiseFigure Receiver noise figure in dB
        %   Specify the receiver noise figure as a non-negative scalar value in dB.
        %   The default is 7 dB.
        NoiseFigure (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNonnegative} = 7;

        %BSSColor Color of the BSS
        %   Specify the BSS color as an integer scalar in the range [0, 63]. To
        %   enable this property, set the Mode property to "AP".
        %   The station nodes associated to this AP are configured with the same
        %   BSS color as the AP. A non-zero value of this property enables
        %   spatial-reuse operation. The default value is 0.
        BSSColor (1,1) {mustBeNumericOrLogical, mustBeInteger, mustBeNonnegative, mustBeLessThanOrEqual(BSSColor,63)} = 0;

        %OBSSPDThreshold Overlapping basic service set (OBSS) packet detect
        %(PD) threshold in dBm
        %   Specify OBSS PD threshold in dBm as a scalar in the range [-82,-62].
        %   The default value is -82 dBm.
        %   If Mode is set to "AP",
        %     - This property is applicable when BSSColor is set to a non-zero
        %       value.
        %   If Mode is set to "STA",
        %     - This property is applicable when BSSColor of its associated AP
        %       is set to a non-zero value.
        %   If Mode is set to "mesh",
        %     - This property is not applicable
        OBSSPDThreshold (1,1) {mustBeNumeric, mustBeReal, mustBeGreaterThanOrEqual(OBSSPDThreshold,-82), mustBeLessThanOrEqual(OBSSPDThreshold, -62)} = -82;

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
        %   This property applies only when the InterferenceModeling is set to
        %   "non-overlapping-adjacent-channel". If you specify this property as
        %   Inf, the object considers all the signals that overlap in time,
        %   regardless of their frequency, to be interference. If you specify this
        %   value as a finite nonnegative scalar, the object considers all the
        %   signals overlapping in time with frequency in the range
        %   [f1-MaxInterferenceOffset, f2+MaxInterferenceOffset], as interference.
        %   f1 and f2 are the starting and ending frequencies of receiver operation
        %   respectively. The default value is 0.
        MaxInterferenceOffset (1,1) {mustBeNumeric, mustBeNonnegative} = 0;
    end

    properties(SetAccess=private)
        %ChannelFrequency Channel center frequency in Hz
        %   This property indicates the operating center frequency of the device
        %   corresponding to the configured value of the BandAndChannel property.
        %   This is a read-only property.
        ChannelFrequency;
    end

    properties(Hidden)
        %MaxMUStations Maximum number of DL or UL multiuser (MU) stations
        %    MaxMUStations is a scalar representing maximum number of
        %    DL or UL stations that can be scheduled in an MU
        %    transmission. Specify this property as an integer in the
        %    range [1, 9] when ChannelBandwidth is 20e6 Hz, in the range 
        %    [1, 18] when ChannelBandwidth is 40e6 Hz, in the range [1, 37] 
        %    when ChannelBandwidth is 80e6 Hz, and in the range [1, 74] 
        %    when ChannelBandwidth is 160e6 Hz. This property is applicable 
        %    only when Mode is set to "AP" and:
        %       1. TransmissionFormat is set to "HE-MU-OFDMA" (or)
        %       2. EnableUplinkOFDMA is set to true
        %    The default is 0. When the value is 0, the MaxMUStations is set
        %    to the highest value possible for the specified channel bandwidth
        %    value.
        MaxMUStations (1, 1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(MaxMUStations,0), mustBeLessThanOrEqual(MaxMUStations,74)} = 0;

        %DLOFDMAFrameSequence DL OFDMA frame exchange sequence
        %   Specify the type of frame exchange sequence used in DL MU transmissions
        %   as 1 or 2. The value 1 represents DL MU PPDU + TRS control -> UL BA
        %   sequence and value 2 represents DL MU PPDU -> MU-BAR -> UL BA sequence.
        %   This property is applicable only when Mode is set to "AP" and 
        %   TransmissionFormat is set to "HE-MU-OFDMA". The default 
        %   is 2.
        DLOFDMAFrameSequence (1, 1) {mustBeNumeric, mustBeInteger, mustBeGreaterThanOrEqual(DLOFDMAFrameSequence,1), mustBeLessThanOrEqual(DLOFDMAFrameSequence,2)} = 2;

        %IsMeshDevice Flag indicating mesh device
        IsMeshDevice = false;

        %IsAPDevice Flag indicating AP device
        IsAPDevice = false;
    end

    properties(Hidden, Dependent)
        %EDThreshold Energy detection threshold in dBm
        %   Specify the energy detection threshold as a scalar in dBm. The default
        %   is -82 dBm.
        EDThreshold
    end

    properties(Hidden, Constant)
        %PowerControl Power control
        %   A string value indicating the type of power control algorithm
        %   used.
        PowerControl = "FixedPower";
    end

    properties (Hidden, Constant)
        Mode_Values = ["STA", "AP", "mesh"];
        TransmissionFormat_Values = ["Non-HT", "HT-Mixed", "VHT", "HE-SU", "HE-EXT-SU", "HE-MU-OFDMA", "EHT-SU"];
        InterferenceModeling_Values = ["co-channel", "overlapping-adjacent-channel", "non-overlapping-adjacent-channel"];
        RateControl_Values = ["fixed", "auto-rate-fallback"];
    end

    methods (Access = protected)
        function flag = isInactiveProperty(obj, prop)
            flag = false;

            switch(prop)
                case "NumSpaceTimeStreams"
                    flag = strcmp(obj.TransmissionFormat, "Non-HT");
                case "AggregateHTMPDU"
                    flag = ~strcmp(obj.TransmissionFormat, "HT-Mixed");
                case "MPDUAggregationLimit"
                    flag = strcmp(obj.TransmissionFormat, "Non-HT") || (strcmp(obj.TransmissionFormat, "HT-Mixed") && ~obj.AggregateHTMPDU);
                case "RTSThreshold"
                    flag = obj.DisableRTS || strcmp(obj.TransmissionFormat, "HE-MU-OFDMA");
                case "BasicRates"
                    flag = ~strcmp(obj.Mode, "AP");
                case "PrimaryChannelIndex"
                    flag = ~(strcmp(obj.Mode, "AP") && obj.ChannelBandwidth ~= 20e6);
                case "BSSColor"
                    flag = ~strcmp(obj.Mode, "AP");
                case "EnableUplinkOFDMA"
                    flag = ~(strcmp(obj.Mode, "AP") && any(strcmp(obj.TransmissionFormat, ["HE-SU", "HE-MU-OFDMA"])));
                case "MeshTTL"
                    flag = ~strcmp(obj.Mode, "mesh");
                case "OBSSPDThreshold"
                    flag = strcmp(obj.Mode, "mesh") || (strcmp(obj.Mode, "AP") && obj.BSSColor==0);
                case "BeaconInterval"
                    flag = strcmp(obj.Mode, "STA") ;
                case "InitialBeaconOffset"
                    flag = strcmp(obj.Mode, "STA") || ~isfinite(obj.BeaconInterval);
                case "MaxInterferenceOffset"
                    flag = ~strcmp(obj.InterferenceModeling, "non-overlapping-adjacent-channel");
                case "TXOPLimit"
                    flag = (strcmp(obj.TransmissionFormat, "Non-HT") || (strcmp(obj.TransmissionFormat, "HT-Mixed") && ~obj.AggregateHTMPDU)) || strcmp(obj.Mode, "mesh");
            end
        end
    end

    methods
        function obj = wlanDeviceConfig(varargin)
            % Name-value pair check
            if mod(nargin,2) == 1
                error(message('wlan:ConfigBase:InvalidPVPairs'));
            end

            s = struct;
            % Name-value pairs
            for idx = 1:2:nargin-1
                obj.(varargin{idx}) = varargin{idx+1};
                s.(varargin{idx}) = varargin{idx+1};
            end

            % Search the presence of 'TransmitQueueSize' N-V pair
            % argument to assign default value for EHT-SU transmissions
            % in case the user does not configure
            if ~isfield(s, "TransmitQueueSize") && strcmp(obj.TransmissionFormat, "EHT-SU")
                obj.TransmitQueueSize = 1024;
            end

            % Search the presence of 'InitialBeaconOffset' N-V pair
            % argument to assign default value, if beacon transmission is
            % enabled and the user does not configure 'InitialBeaconOffset'
            if isfinite(obj.BeaconInterval) && ~isfield(s, "InitialBeaconOffset")
                obj.InitialBeaconOffset = [0 obj.BeaconInterval];
            end
        end

        function value = get.ChannelFrequency(obj)
            band = obj.BandAndChannel(1);
            channel = obj.BandAndChannel(2);
            value = wlanChannelFrequency(channel, band);
        end

        function threshold = get.EDThreshold(obj)
            threshold = -82 + round(10 * log10(obj.ChannelBandwidth / 20e6));
        end

        function obj = set.Mode(obj, value)
            value = validatestring(value, obj.Mode_Values, 'wlanDeviceConfig', 'Mode');
            obj.Mode = value;
        end

        function obj = set.TransmissionFormat(obj, value)
            value = validatestring(value, obj.TransmissionFormat_Values, 'wlanDeviceConfig', 'TransmissionFormat');
            obj.TransmissionFormat = value;
        end

        function obj = set.RateControl(obj, value)
             validateattributes(value, {'string','char','wlanRateControl'}, {}, 'wlanDeviceConfig', 'RateControl');
             if isstring(value) || ischar(value)
                 value = validatestring(value, obj.RateControl_Values, 'wlanDeviceConfig', 'RateControl');
             else % object
                 validateattributes(value, {'wlanRateControl'}, {'scalar'}, 'wlanDeviceConfig', 'RateControl');
             end
             obj.RateControl = value;
        end

        function obj = set.BasicRates(obj, value)
            obj.BasicRates = unique(value);
        end

        function obj = set.InterferenceModeling(obj, value)
            value = validatestring(value, obj.InterferenceModeling_Values, 'wlanDeviceConfig', 'InterferenceModeling');
            obj.InterferenceModeling = value;
        end

        function obj = validateConfig(obj)
            % Set mode flags
            obj.IsMeshDevice = strcmp(obj.Mode, "mesh");
            obj.IsAPDevice = strcmp(obj.Mode, "AP");

            band = obj.BandAndChannel(1);
            channelNum = obj.BandAndChannel(2);
            if ((band == 6) && ~any(strcmp(obj.TransmissionFormat, ["HE-SU", "HE-MU-OFDMA", "HE-EXT-SU", "EHT-SU"])))
                error(message('wlan:wlanDeviceConfig:InvalidBand6GHz'))
            end
            switch obj.TransmissionFormat
                case {"HE-EXT-SU" "Non-HT"}
                    if ((obj.ChannelBandwidth ~= 20e6))
                        error(message('wlan:shared:BandwidthMustBe20'))
                    end

                case "HT-Mixed"
                    if (all(obj.ChannelBandwidth ~= [20e6 40e6]))
                        error(message('wlan:shared:InvalidBandwidthHTMixed'))
                    end  

                case "VHT"
                    if ((band == 2.4))
                        error(message('wlan:shared:InvalidBandVHT'))
                    end
                    if ((obj.ChannelBandwidth == 320e6))
                        error(message( 'wlan:shared:InvalidChannelBandwidthVHT'))
                    end

                case {"HE-SU" "HE-MU-OFDMA"}
                    if ((obj.ChannelBandwidth == 320e6))
                        error(message('wlan:shared:InvalidChannelBandwidthHE'))
                    end

                case "EHT-SU"
                    if ((obj.ChannelBandwidth == 320e6) && (band ~= 6))
                        error(message('wlan:shared:InvalidBandFor320MHz'))
                    end
                    
            end
            if ((band == 2.4) && ~any(obj.ChannelBandwidth == [20e6, 40e6]))
                error(message('wlan:shared:InvalidBandwidth2GHz'))
            end
            wlan.internal.validation.channelNumAndBandwidth(band, channelNum, obj.ChannelBandwidth);

            % Limit NumTransmitAntennas based on defined per-antenna
            % cyclic shifts in the standard.
            % As all rate-adaptation algorithms do not adapt the number
            % of space-time streams, validate fixed number of
            % space-time streams for each format.
            if strcmp(obj.TransmissionFormat,"HT-Mixed")
                if ((obj.NumTransmitAntennas > 4))
                    error(message('wlan:shared:InvalidNumTxAntennasHTMixed'))
                end

                % No need to validate NumSpaceTimeStreams specifically
                % for HT-MF as NumSpaceTimeStreams>NumTransmitAntennas
                % is validated separately.

            else % Non-HT, VHT, HE, or EHT-SU
                switch obj.TransmissionFormat
                    case "HE-EXT-SU"
                        if ((obj.NumSpaceTimeStreams > 2))
                            error(message('wlan:shared:InvalidNumSTSHEEXTSU'))
                        end

                    case "Non-HT"
                        if ((obj.NumSpaceTimeStreams > 1))
                            error(message( 'wlan:shared:InvalidNumSTSNonHT'))
                        end

                    otherwise % VHT, HE-SU, HE-MU-OFDMA, or EHT-SU
                        % No need to validate NumSpaceTimeStreams
                        % specifically for VHT, HE-SU, HE-MU-OFDMA, or
                        % EHT-SU. NumTransmitAntennas > NumSpaceTimeStreams
                        % is validated separately.
                end
            end
            % Validate that the number of space-time streams is never more
            % than the number of transmit antennas
            if ((obj.NumSpaceTimeStreams > obj.NumTransmitAntennas))
                error(message('wlan:shared:InvalidNumSpaceTimeStreams'))
            end

            % Validate MCS and NumSTS on TransmissionFormat
            if strcmp(obj.RateControl, 'fixed')
                switch obj.TransmissionFormat
                    case {"HE-SU", "HE-MU-OFDMA"}
                        if ((obj.MCS > 11))
                            error(message('wlan:shared:UnsupportedMCSHE'))
                        end

                    case "HE-EXT-SU"
                        if ((obj.MCS > 2))
                            error(message('wlan:shared:UnsupportedMCS', 2, obj.TransmissionFormat))
                        end

                    case "VHT"
                        if ((obj.MCS > 9))
                            error(message('wlan:shared:UnsupportedMCS', 9, obj.TransmissionFormat))
                        end

                        switch obj.ChannelBandwidth
                            case 20e6
                                if ((obj.MCS == 9) && ~any(obj.NumSpaceTimeStreams == [3 6]))
                                    error(message('wlan:shared:UnsupportedMCS9VHT20'))
                                end

                            case 80e6
                                if ((obj.MCS == 6) && any(obj.NumSpaceTimeStreams == [3 7]))
                                    error(message('wlan:shared:UnsupportedMCS6VHT80'))
                                end
                                if ((obj.MCS == 9) && (obj.NumSpaceTimeStreams == 6))
                                    error(message('wlan:shared:UnsupportedMCS9NumSTSCBW', 6, 80))
                                end

                            case 160e6
                                if ((obj.MCS == 9) && (obj.NumSpaceTimeStreams == 3))
                                    error(message('wlan:shared:UnsupportedMCS9NumSTSCBW', 3, 160))
                                end
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
            else % Dynamic rate control
                if (strcmp(obj.TransmissionFormat, "HE-MU-OFDMA"))
                    error(message("wlan:wlanDeviceConfig:MURateControlUnsupported"))
                end
            end

            if ~obj.IsAPDevice || (~strcmp(obj.TransmissionFormat,"HE-MU-OFDMA") && ~obj.EnableUplinkOFDMA)
                % If OFDMA is not enabled in either DL or UL, a maximum of only 1 station
                % is allowed for scheduling
                obj.MaxMUStations = 1;
            else
                if ~obj.MaxMUStations
                    % Set MaxMUStations internally based on ChannelBandwidth
                    switch obj.ChannelBandwidth
                        case 20e6
                            obj.MaxMUStations = 9;
                        case 40e6
                            obj.MaxMUStations = 18;
                        case 80e6
                            obj.MaxMUStations = 37;
                        case 160e6
                            obj.MaxMUStations = 74;
                    end
                end
            end

            % HE-MU-OFDMA format is only allowed for AP
            if (strcmp(obj.TransmissionFormat,"HE-MU-OFDMA") && ~obj.IsAPDevice)
                error(message('wlan:wlanDeviceConfig:InvalidSTATransmissionFormat'))
            end
            % HE-MU-OFDMA format is not supported in combination with Spatial Reuse
            if (strcmp(obj.TransmissionFormat,"HE-MU-OFDMA") && obj.BSSColor)
                error(message('wlan:wlanDeviceConfig:OFDMAUnsupportedWithSR'))
            end
            % Check for any missing mandatory rates in BasicRates
            if (obj.IsAPDevice && ~all(ismember([6 12 24], obj.BasicRates)))
                error(message('wlan:wlanDeviceConfig:MandatoryRatesMissing'))
            end
            % AIFS value 1 is only allowed for AP
            if (~obj.IsAPDevice && any(obj.AIFS == 1))
                error(message('wlan:wlanDeviceConfig:InvalidAIFSForNonAP'))
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
            if (obj.MPDUAggregationLimit > 256) && any(strcmp(obj.TransmissionFormat, ["HE-SU", "HE-EXT-SU", "HE-MU-OFDMA"]))
                error(message('wlan:shared:InvalidAggregationLimitHE'))
            end
            % UL OFDMA is not supported in combination with Spatial Reuse
            if (obj.IsAPDevice && strcmp(obj.TransmissionFormat, "HE-SU") && obj.EnableUplinkOFDMA && obj.BSSColor)
                error(message('wlan:wlanDeviceConfig:OFDMAUnsupportedWithSR'))
            end
            if ~strcmp(obj.Mode, "STA") && isfinite(obj.BeaconInterval)
                % Validate initial beacon offset
                if (isempty(obj.InitialBeaconOffset) || numel(obj.InitialBeaconOffset) > 2)
                    error(message('wlan:wlanDeviceConfig:InvalidBeaconOffset'))
                end
                if numel(obj.InitialBeaconOffset) == 2
                    if (obj.InitialBeaconOffset(1) > obj.InitialBeaconOffset(2))
                        error(message('wlan:wlanDeviceConfig:InvalidBeaconOffsetRange'))
                    end
                end
            end
            % Multi-frame TXOP unsupported with Mesh
            if (strcmp(obj.Mode, "mesh") && any(obj.TXOPLimit))
                error(message('wlan:wlanDeviceConfig:MFTXOPUnsupportedWithMesh'))
            end
            % Multi-frame TXOP unsupported with NonHT or HT-Mixed with
            % AggregateHTMPDU set to false
            if ((strcmp(obj.TransmissionFormat, "Non-HT") || (strcmp(obj.TransmissionFormat, "HT-Mixed") && ~obj.AggregateHTMPDU)) && any(obj.TXOPLimit))
                error(message('wlan:shared:MFTXOPUnsupportedWithNonAggregation'))
            end

            % Validate PrimaryChannelIndex based on bandwidth
            if strcmp(obj.Mode, "AP") && obj.ChannelBandwidth ~= 20e6
                if (obj.PrimaryChannelIndex>(obj.ChannelBandwidth/20e6))
                    error(message("wlan:shared:InvalidPrimaryChannelIndex", obj.ChannelBandwidth/20e6, obj.ChannelBandwidth/1e6))
                end
            end
        end
    end
end

% Property validation functions

function validateBeaconInterval(value)
% Validate beacon interval
if isfinite(value)
    if ~(floor(value) == value) || (~(value>=1 && value<=65535))
        error(message('wlan:wlanDeviceConfig:InvalidBeaconInterval'));
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
