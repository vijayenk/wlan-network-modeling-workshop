classdef edcaMAC < handle
%edcaMAC Create a WLAN EDCA MAC object
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = edcaMAC creates a WLAN EDCA MAC object, OBJ, for a node.
%
%   edcaMAC properties:
%
%   NodeID                      - Node identifier
%   NodeName                    - Name of the node
%   DeviceID                    - Identifier of device containing MAC
%   MACAddress                  - MAC address of device
%   IsAPDevice                  - Flag to indicate that device is an access
%                                 point (AP)
%   IsAssociatedSTA             - Flag to indicate that device is station
%                                 (STA) in basic service set (BSS)
%   IsEMLSRSTA                  - Flag to indicate that the STA link is
%                                 operating in EMLSR mode
%   IsMeshDevice                - Flag to indicate that device is a mesh STA
%   BSSID                       - BSS identifier
%   AID                         - Association identifier
%   PrimaryChannelIndex         - Position of primary 20 MHz channel
%   ChannelBandwidth            - Bandwidth of the channel
%   TransmissionFormat          - Physical layer frame format
%   NumTransmitAntennas         - Number of transmit antennas
%   MPDUAggregation             - Enable frame aggregation
%   MaxSubframes                - Maximum number of subframes that can be
%                                 aggregated
%   MaxQueueLength              - Maximum size of MAC transmission queue
%   RTSThreshold                - Threshold for frame length below which
%                                 RTS/MU-RTS is not transmitted
%   DisableRTS                  - Disable RTS transmission
%   DisableAck                  - Disable acknowledgments
%   CWMin                       - Minimum range of contention window for
%                                 four ACs
%   CWMax                       - Maximum range of contention window for
%                                 four ACs
%   AIFS                        - Arbitrary interframe slot values for
%                                 four ACs
%   TXOPLimit                   - Transmission Opportunity (TXOP) duration
%                                 limit for four ACs
%   BasicRates                  - Non-HT data rates supported in the BSS
%   Use6MbpsForControlFrames    - Force to transmit control frames at 6 Mbps
%   BeaconInterval              - Beacon interval in time units (TU)
%   InitialBeaconOffset         - Time offset specified for the first beacon
%                                 transmission in TU
%   ULOFDMAEnabled              - Flag indicating AP can trigger UL OFDMA
%                                 transmissions
%   BSSColor                    - Basic service set (BSS) color identifier
%   OBSSPDThreshold             - OBSS PD threshold
%   OperatingFrequency          - Frequency of operation
%   FrameAbstraction            - Enable MAC frame abstraction
%
%   edcaMAC methods:
%
%   run                     - Run MAC layer
%   enqueuePacket           - Push packet into MAC queue
%   isQueueFull             - Query status of MAC queue
%   statistics              - Get the statistics of MAC layer

%   Copyright 2022-2025 The MathWorks, Inc.

%% Initialized via constructor: General info
properties (SetAccess = private)
    %NodeID Node identifier
    %   NodeID is an integer to identify the node in the network. Set this
    %   property to a value same as <a
    %   href="matlab:help('wlanNode/ID')">ID</a> property of <a
    %   href="matlab:help('wlanNode')">wlanNode</a>. The default value is
    %   1.
    NodeID = 1;

    %NodeName Name of the node
    % NodeName is a string scalar representing the name of the node.
    NodeName = "";

    %DeviceID Identifier of device containing MAC
    %   Specify the device identifier containing MAC layer as an integer
    %   scalar starting from 1.
    DeviceID = 1;

    %MACAddress MAC address of device
    %   Specify MAC address of the device as a 12-element character vector
    %   or string scalar denoting a 6-octet hexadecimal value. The default
    %   value is '000000000000'.
    MACAddress = '000000000000';

    %IsAPDevice Flag to indicate that the device is an AP
    %   Set this flag to true to indicate that the device is an AP. The
    %   default value is false.
    IsAPDevice = false;

    %IsAssociatedSTA Flag to indicate that the device is a STA in a BSS
    %   Set this flag to true to indicate that the device is a STA in a
    %   BSS. The default value is false.
    IsAssociatedSTA = false;

    %IsMeshDevice Flag to indicate that the device is a mesh STA
    %   Specify this property as true to use 4-address header for
    %   transmitting data if required. The default value is false.
    IsMeshDevice = false;

    %IsEMLSRSTA Flag to indicate that the STA link is operating in EMLSR mode
    %   Set this flag to true to indicate that the link of a STA is operating
    %   in EMLSR mode. The default value is false.
    IsEMLSRSTA = false;
end

%% Initialized via constructor or a method of edcaMAC: Passed from node
properties (SetAccess = private)
    %PrimaryChannelIndex Position of primary 20 MHz channel
    %   Specify the position of the primary 20 MHz channel in the channel
    %   bandwidth as an integer in the range 1 when ChannelBandwidth is 20e6,
    %   [1, 2] when ChannelBandwidth is 40e6, [1, 4] when ChannelBandwidth is
    %   80e6, [1, 8] when ChannelBandwidth is 160e6 and [1, 16] when
    %   ChannelBandwidth is 320e6. Indexing starts from the lowest 20 MHz
    %   sub-channel. The default value is 1.
    PrimaryChannelIndex = 1;

    %ChannelBandwidth Bandwidth of the channel (in MHz)
    %   Specify channel bandwidth in MHz as 20, 40, 80, 160 or 320. The default
    %   value is 20.
    ChannelBandwidth = 20;

    %TransmissionFormat Physical layer frame format
    %   Specify the physical layer (PHY) frame format used for the data
    %   transmissions, as a constant integer value defined in
    %   wlan.internal.FrameFormats. Specify this value as one of the
    %   following constants from wlan.internal.FrameFormats: NonHT,
    %   HTMixed, VHT, HE_SU, HE_EXT_SU, HE_MU, or EHT_SU.
    TransmissionFormat = wlan.internal.FrameFormats.HE_SU;

    %NumTransmitAntennas Number of transmit antennas
    %   Specify the number of transmit antennas as an integer scalar in the
    %   range [1 8]. The default value is 1.
    NumTransmitAntennas = 1;

    %MPDUAggregation Enable frame aggregation
    %   Set this property to true to aggregate multiple MPDUs into an
    %   aggregated MPDU (A-MPDU) for transmission. The default value is
    %   true. This property is only applicable when TransmissionFormat is
    %   set to wlan.internal.FrameFormats.HTMixed.
    MPDUAggregation = true;

    %MaxSubframes Maximum number of A-MPDU subframes
    %   Specify maximum number of subframes that can be aggregated in a
    %   single A-MPDU as an integer scalar in the range [1 1024]. The
    %   default value is 64.
    MaxSubframes = 64;

    %MaxQueueLength Maximum size of a MAC transmission queue
    %   Specify the maximum number of MSDUs that can be stored in a queue
    %   for each destination and each AC as an integer scalar. The default
    %   value is 256.
    MaxQueueLength = 256;

    %RTSThreshold Threshold for frame length below which RTS is not
    %transmitted
    %   Specify the threshold value of frame length below which RTS/CTS
    %   protection is not used for single-user (SU) data transmission as an
    %   integer in the range [0 6500631]. The default value is 0. This
    %   property is applicable only when <a
    %   href="matlab:help('wlan.internal.mac.edcaMAC/DisableRTS')">DisableRTS</a>
    %   is set to false.
    RTSThreshold = 0;

    %DisableRTS Disable RTS transmission
    %   Set this property to true to disable the RTS/CTS exchange in the
    %   simulation. The default value is false.
    DisableRTS = false;

    %DisableAck Disable acknowledgments
    %   Set this property to true to disable acknowledgments (no
    %   acknowledgment in response to data frame). The default value is
    %   false.
    DisableAck = false;

    %CWMin Minimum range of contention window for four ACs
    %   Specify minimum size of contention window for Best Effort,
    %   Background, Video, and Voice traffic respectively as a vector of
    %   length four. Each element in the vector must be in the range [1
    %   1023]. The default value is [15 15 7 3].
    CWMin = [15 15 7 3];

    %CWMax Maximum range of contention window for four ACs
    %   Specify maximum size of contention window for Best Effort,
    %   Background, Video, and Voice traffic respectively as a vector of
    %   length four. Each element in the vector must be in the range [1
    %   1023]. The default value is [1023 1023 15 7].
    CWMax = [1023 1023 15 7];

    %AIFS Arbitrary interframe slot (AIFS) values for four ACs
    %   Specify arbitrary interframe space slots for Best Effort,
    %   Background, Video, and Voice traffic respectively as a vector of
    %   length four. Each element in the vector must be in the range [2 15].
    %   The default value is [3 7 2 2].
    AIFS = [3 7 2 2];

    %TXOPLimit Transmission Opportunity (TXOP) duration limit for four ACs,
    %in nanoseconds.
    %   Specify the TXOP limit values in nanoseconds, for Best Effort,
    %   Background, Video and Voice traffic respectively. This value must
    %   be a vector of four integers.If you specify any element in the
    %   vector as zero, the object disables multiple frame transmissions
    %   within a TXOP for the access category corresponding to that element.
    TXOPLimit = [0 0 0 0];

    %BasicRates Non-HT data rates supported in the BSS
    %   Specify Non-HT data rates supported in the BSS in Mbps as a vector
    %   which is subset of [6 9 12 18 24 36 48 54]. The default value is [6
    %   12 24]. This property is set to 6, if <a
    %   href="matlab:help('wlan.internal.mac.edcaMAC/Use6MbpsForControlFrames')">Use6MbpsForControlFrames</a>
    %   property is set to true.
    BasicRates = [6 12 24];

    %Use6MbpsForControlFrames Force to transmit control frames at 6 Mbps
    %   Set this property to true to indicate date rate of 6 Mbps should be
    %   used for control frames. The default value is false.
    Use6MbpsForControlFrames = false;

    %BeaconInterval Beacon interval in time units (TU)
    %   To enable beacon transmissions, specify beacon interval as a scalar
    %   integer in the range [1, 65535]. One TU is equal to 1024
    %   microseconds. The MAC internally sets the service set identifier
    %   (SSID) in a beacon frame to "WLAN". The default value is Inf.
    BeaconInterval = Inf;

    %InitialBeaconOffset Time offset specified for the first beacon
    %transmission in time units (TU)
    %   Specify a constant or random time offset before transmission of the
    %   first beacon, in TUs. One TU is equal to 1024 microseconds. Set
    %   this property as a nonnegative scalar integer or a nonnegative row
    %   vector of [MinTimeOffset, MaxTimeOffset], specifying a range for
    %   the time offset. If you specify this value as a scalar, the object
    %   assigns this value to the initial time offset. If you specify this
    %   value as a row vector, the object assigns a random numeric between
    %   MinTimeOffset and MaxTimeOffset (in microseconds) to the initial
    %   time offset. The valid values of scalar offset, MinTimeOffset, and
    %   MaxTimeOffset are the integers in the range [0, 65535]. The default
    %   value is [0, 100].
    InitialBeaconOffset = [0, 100];

    %ULOFDMAEnabled Flag indicating that the AP can trigger UL OFDMA
    %transmissions
    %   Set this property to true to enable the AP to trigger UL OFDMA data
    %   transmissions from the associated stations. The default value is
    %   false.
    ULOFDMAEnabled = false;

    %BSSColor Basic service set (BSS) color identifier
    %   Specify the BSS color identifier of a basic service set as an
    %   integer scalar in the range [0 63]. The default value is 0.
    BSSColor = 0;

    %OBSSPDThreshold OBSS PD threshold
    %   Specify OBSS PD Threshold in dBm as an integer in the range [-62
    %   -82]. The default value is -82.
    OBSSPDThreshold = -82;

    %OperatingFrequency Frequency of operation
    %   OperatingFrequency indicates the frequency in which the MAC layer
    %   is operating in Hz.
    OperatingFrequency = 2.412*1e9;

    %NumReceiveAntennas Number of receive antennas
    %   Specify the number of receive antennas as an integer scalar in the
    %   range [1 8]. The default value is 1.
    NumReceiveAntennas = 1;
    
    %FrameAbstraction Enable frame abstraction
    %   Specify this property as false to generate and decode full MAC
    %   frame, otherwise set true. The default value is true.
    FrameAbstraction = true;
end

%% Initialized via a method of edcaMAC: Passed during association to STA
properties (SetAccess=private)
    %BSSID BSS identifier
    %   Specify BSSID as the MAC address of the access point (AP). The
    %   default value is '000000000000'.
    BSSID = '000000000000';

    %AID Association identifier
    %   Specify this property as an integer in the range [1 2007]. This value
    %   is assigned by the AP to STA during association.
    AID = 0;
end

%% Initialized via constructor: Pluggable and non-pluggable objects
properties (SetAccess=private)
    %SharedMAC Shared MAC layer handle object
    %   Specify the shared MAC layer object of type wlan.internal.mac.SharedMAC,
    %   which is a handle object, corresponding to the device. If the device is
    %   a multi-link device (MLD), it contains sharedMAC object which handles
    %   shared functionality of all links. If the device is a non-MLD device,
    %   it contains sharedMAC object only corresponding to this device.
    SharedMAC;

    %SharedEDCAQueues Shared queue management handle object
    %   SharedEDCAQueues represents a WLAN MAC Queue management handle object
    %   maintained by shared MAC. These queues hold unicast data packets to be
    %   sent to MLD nodes.
    SharedEDCAQueues;

    %Scheduler Scheduler handle object
    %   Specify the scheduler handle object for a multi-user network to
    %   schedule destination stations. The default value is a round robin
    %   scheduler object.
    Scheduler;

    %RateControl Rate control handle object
    %   Specify the rate control handle object providing the interface for
    %   rateControl. This allows plugging in various rate control strategies
    %   such as - Fixed rate, ARF, Minstrel. The default value is a fixed rate
    %   control object.
    RateControl;

    %PowerControl Power control handle object
    %   Specify the power control handle object providing the interface for
    %   powerControl. This allows plugging in various power control strategies
    %   such as - Fixed power, MCS based power control, central carrier
    %   frequency based power control. The default value is a fixed power
    %   control object.
    PowerControl;

    %ULRateControl Uplink rate control handle object
    %   Specify the rate control handle object to determine uplink rate in
    %   multi-user transmissions. This object provides interface for
    %   rateControl. Only fixed rate is supported.
    ULRateControl;
end

%% Initialized via a method of edcaMAC: MLO-EMLSR info
properties (SetAccess=private)
    %MediumSyncDuration Duration value of medium sync delay timer in
    %nanoseconds
    %   MediumSyncDuration is a scalar that represents the duration value of
    %   medium sync delay timer in nanoseconds at an EMLSR STA. Medium sync
    %   delay timer is set to a value equal to current time plus
    %   MediumSyncDuration when a link switches back to listening after its CCA
    %   goes off for more than medium sync threshold.
    MediumSyncDuration = 0;

    %MediumSyncEDThreshold ED threshold to use during medium synchronization
    %recovery
    %   MediumSyncEDThreshold is an integer in the range [-72, -62] and
    %   represents the ED threshold that an EMLSR STA uses when its medium sync
    %   delay timer is running i.e., when it is performing medium
    %   synchronization recovery.
    MediumSyncEDThreshold = -72;

    %MediumSyncMaxTXOPs Maximum number of TXOPs during medium synchronization
    %recovery
    %   MediumSyncMaxTXOPs is an integer in the range [1, 15] or Inf and
    %   represents maximum number of TXOPs an EMLSR STA attempts to initiate
    %   when it has non-zero medium sync delay timer i.e., when it is
    %   performing medium synchronization recovery.
    MediumSyncMaxTXOPs = Inf;
end

%% Callback functions set from node
properties
    %PushPacketToQueueFcn Function handle to notify the node about an empty
    %slot in the packet buffer when full buffer traffic is configured
    %   Specify the function handle to notify the node about an empty slot in
    %   the packet buffer when full buffer traffic is configured.
    PushPacketToQueueFcn = [];

    %HandleReceivePacketFcn Function handle to receive/forward decoded
    %MSDUs
    %   Specify the function handle that handles the decoded MSDUs after
    %   MAC processing.
    HandleReceivePacketFcn = [];

    %HandleReceiveMeshPacketFcn Function handle to receive/forward decoded
    %MSDUs at mesh STA
    %   Specify the function handle that handles the decoded MSDUs at mesh
    %   STA after MAC processing.
    HandleReceiveMeshPacketFcn = [];

    %SetPHYModeFcn Function handle to notify the PHY receiver about PHY
    %mode change
    %   Specify the function handle to notify the PHY receiver about the change
    %   in PHY mode.
    SetPHYModeFcn = [];

    %ResetPHYCCAFcn Function handle to notify the PHY receiver about
    %CCARESET request
    %   Specify the function handle to notify the PHY receiver about the
    %   CCARESET request.
    ResetPHYCCAFcn = [];

    %SendTrigRequestFcn Function handle to notify the PHY receiver about
    %PHY-TRIGGER request
    %   Specify the function handle to notify the PHY receiver about
    %   PHY-TRIGGER request.
    SendTrigRequestFcn = [];

    %MSDTimerStartFcn Function handle to notify the PHY receiver about medium
    %sync delay (MSD) timer start at MAC
    %   Specify the function handle to notify the PHY receiver about MSD timer
    %   start.
    MSDTimerStartFcn = [];

    %MSDTimerResetFcn Function handle to notify the PHY receiver about medium
    %sync delay (MSD) timer reset at MAC
    %   Specify the function handle to notify the PHY receiver about MSD timer
    %   reset.
    MSDTimerResetFcn = [];

    %SetNumRxAntennasFcn Function handle to notify PHY receiver about number of
    %antennas to use for reception
    %   Specify the function handle to notify the PHY receiver about number of
    %   antennas to use for reception in EMLSR mode.
    SetNumRxAntennasFcn = [];

    %PerformPostManagementTxActionsCustomFcn Function handle to notify that a
    %management frame was transmitted
    %   Specify the function handle to get notified that management frame
    %   transmission finished (and about to receive a response a SIFS after
    %   this point if applicable).
    PerformPostManagementTxActionsCustomFcn = [];

    %ProcessManagementFramesCustomFcn Function handle to notify a management
    %frame reception
    %   Specify the function handle to get notified about management frame
    %   reception for performing custom operations.
    ProcessManagementFramesCustomFcn = [];

    %PerformPostManagementRxActionsCustomFcn Function handle to notify that a
    %management frame was received and its response transmission (if any) has finished
    %   Specify the function handle to get notified that management frame
    %   reception processing finished, which includes response transmission if
    %   applicable.
    PerformPostManagementRxActionsCustomFcn = [];

    %EventNotificationFcn Function handle to notify the node about event
    %trigger
    %   Specify the function handle to notify the node about event trigger.
    EventNotificationFcn = [];

    %TransmissionStartedFcn Function handles to invoke at TransmissionStarted
    %event trigger
    %   TransmissionStartedFcn is a cell array of function handles to invoke
    %   when TransmissionStarted event is triggered.
    TransmissionStartedFcn = cell(1, 0);

    %ReceptionEndedFcn Function handles to invoke at ReceptionEnded event
    %trigger
    %   ReceptionEndedFcn is a cell array of function handles to invoke
    %   when ReceptionEnded event is triggered.
    ReceptionEndedFcn = cell(1, 0);

    %ChangingStateFcn Function handles to invoke at ChangingState event trigger
    %   ChangingStateFcn is a cell array of function handles to invoke when
    %   ChangingState event is triggered.
    ChangingStateFcn = cell(1, 0);   
end

%% Hidden support
properties (Hidden)
    %MaxMUStations Maximum number of multi-user (MU) stations
    %    Specify the maximum number of stations that can be scheduled in a
    %    multi-user DL or UL OFDMA transmission as an integer scalar. This
    %    property must be set to a value greater than 1 only when
    %    TransmissionFormat is set to wlan.internal.FrameFormats.HE_MU or
    %    when ULOFDMAEnabled is set to true. Specify this property in the
    %    range [1 9] when ChannelBandwidth is 20 MHz, in the range [1 18]
    %    when ChannelBandwidth is 40 MHz, in the range [1 37] when
    %    ChannelBandwidth is 80 MHz, and in the range [1 74] when
    %    ChannelBandwidth is 160 MHz. The default value is 1.
    MaxMUStations = 1;

    %DLOFDMAFrameSequence Downlink OFDMA frame exchange sequence
    %   Specify the type of frame exchange sequence used in downlink
    %   multi-user transmissions as an integer scalar in the range [1 2].
    %   Value 1 represents DL MU PPDU + TRS control -> Uplink (UL) BA sequence
    %   Value 2 represents DL MU PPDU -> MU-BAR -> Uplink (UL) BA sequence
    %   The default value is 1.
    DLOFDMAFrameSequence = 1;

    %AllowEDCAParamsUpdate Allow updating EDCA parameters at STA from beacon
    %   Specify this property as true to let the STA adopt EDCA
    %   parameters received in the beacon frame from its AP. This is
    %   applicable for only STA mode.
    AllowEDCAParamsUpdate = false;

    %IncludeVector Flag indicating whether to include Tx/Rx vector in
    %MPDUDecoded, TransmissionStarted and ReceptionEnded events notification
    %data
    %   Specify this property as true to include Tx vector in notification data
    %   of TransmissionStarted event and Rx vector in notification data of
    %   ReceptionEnded and MPDUDecoded events. The default
    %   value is false.
    IncludeVector = false;

    %MSDUMaxLifetime Maximum amount of time to retain an MSDU in queue, after
    %which it is discarded
    %   MSDUMaxLifetime is a scalar that contains the maximum time allowed to
    %   retain an MSDU in nanoseconds, starting from its entry into MAC queue.
    %   After this time, MSDU will be discarded from MAC queue. This value is
    %   applicable for all access categories.
    MSDUMaxLifetime = 512000e3; % 500 TUs = 500 * 1024 microseconds
end

%% Standard defined timers
properties (Hidden)
    %TXNAVTimer The remaining simulation time (in nanoseconds), for which the
    %node holds control over the wireless medium
    TXNAVTimer = 0;

    %NonHTResponseTimeout Timeout for waiting on a Non-HT response frame
    NonHTResponseTimeout;

    %NAVTimer Time at which Network Allocation Vector(NAV) set due to frames
    %received from other BSS or cannot be classified as same or other BSS will
    %be elapsed
    %   NAVTimer is a scalar that indicates absolute simulation time at which
    %   the latest updated NAV value from frames received from other BSS or
    %   frames that cannot be classified as from same or other BSS will be
    %   elapsed.
    NAVTimer = 0;

    %IntraNAVTimer Time at which NAV set due to frames received from same BSS
    %will be elapsed
    %   IntraNAVTimer is a scalar that indicates absolute simulation time at
    %   which the latest updated NAV value from frames received from same BSS
    %   will be elapsed.
    IntraNAVTimer = 0;

    %RTSNAVResetTimer Timer for waiting on NAV timeout, the time after which
    %NAV set due to RTS must be reset if an RxStart is not received
    RTSNAVResetTimer = 0;

    %EIFSTimer Timer for waiting on EIFS
    EIFSTimer = 0;

    %MediumSyncDelayTimer Medium sync delay (MSD) timer set at an EMLSR link
    %when the CCA goes off for more than medium sync threshold
    %   If the value of this timer is greater than the current time (i.e., the
    %   timer is running), it indicates that a link is performing medium
    %   synchronization recovery. This property is applicable only in case of
    %   an EMLSR STA.
    MediumSyncDelayTimer = 0;
end

%% Internal timestamps/durations for MAC layer implementation
properties (Hidden)
    %SIFSTime Short interframe spacing duration in nanoseconds
    SIFSTime = 16e3;

    %LastRunTimeNS Timestamp (in nanoseconds) when the MAC is last invoked by
    %node. This gets updated every time the MAC runs.
    LastRunTimeNS = 0;

    %NextInvokeTime Next event invoke time in nanoseconds
    NextInvokeTime = 0;

    %BackoffInvokeTime Wait time (in nanoseconds) to invoke the backoff
    %algorithm.
    %   The initial value of this property is 0 and will be updated every
    %   time during entry to CONTEND_STATE.
    BackoffInvokeTime = 0;

    %StateEntryTimestamp Entry timestamp of either IDLE_STATE or
    %CONTEND_STATE in nanoseconds
    StateEntryTimestamp = 0;

    %ElapsedTime Time (in nanoseconds) elapsed since last run
    ElapsedTime = 0;

    %AccumulatedElapsedTime Accumulated elapsed time in contention
    %   AccumulatedElapsedTime is the context in CONTEND_STATE that
    %   stores the accumulated elapsed time in contention that is not a
    %   multiple of slot duration (9us).
    AccumulatedElapsedTime = zeros(1,4);

    %LinkTurnOffTimestamp Time at which an EMLSR link goes inactive
    %   An EMLSR link goes inactive in the following cases:
    %   * Due to transmission or reception on a different active EMLSR link
    %   * Due to transition delay if this is the active EMLSR link
    %   This property is applicable only in case of an EMLSR STA.
    LinkTurnOffTimestamp = 0;

    %AckOrCTSBasicRateDuration Ack frame transmission duration at MCS 0
    AckOrCTSBasicRateDuration;
end

%% State machine related properties
properties (Hidden)
    %MACState Current state of the MAC State machine
    %   MACState represents the current state of EDCA MAC state machine.
    %   1  - IDLE_STATE
    %   2  - CONTEND_STATE
    %   3  - TRANSMIT_STATE
    %   4  - RECEIVERESPONSE_STATE
    %   5  - RECEIVE_STATE
    %   6  - ERRORRECOVERY_STATE
    %   7  - NAVWAIT_STATE
    %   8  - EMLSRRECEIVE_STATE
    %   9  - INACTIVE_STATE
    %   10 - TRANSMITRESPONSE_STATE
    MACState;

    %MACSubstate Current sub-state of the MAC State machine
    %   MACSubstate represents the current sub-state in an EDCA MAC state.
    %   Current state is an umbrella of sub-states.
    %   1  - TRANSMIT_SUBSTATE
    %   2  - WAITINGFORSIFS_SUBSTATE
    %   These sub-states are applicable for SENDINGDATA_STATE and TRANSMITRESPONSE_STATE.
    MACSubstate;
end

%% Context and queue related properties
properties (Hidden)
    %Tx TxContext handle object
    %   Tx represents a MAC layer transmit parameters object to maintain
    %   context specific to transmit states (TRANSMIT/RECEIVERESPONSE_STATE)
    %   for a node. It is a handle object.
    Tx;

    %Rx RxContext handle object
    %   Rx represents a MAC layer receive parameters object to maintain context
    %   specific to RECEIVE_STATE for a node. It is a handle object.
    Rx;

    %LinkEDCAQueues Per-link queue management handle object
    %   LinkEDCAQueues represents a per-link WLAN MAC Queue management object
    %   maintained by EDCA MAC (edcaMAC). These queues hold broadcast data
    %   packets for MLD and non-MLD nodes and unicast data packets to be sent
    %   to non-MLD nodes.
    LinkEDCAQueues;
end

%% QoS related channel access properties
properties (Hidden)
    %QSRC QoS STA retry count maintained per AC
    %   QSRC is an array of size 4 x 1 where each element represents QoS
    %   STA retry counter for corresponding AC. It is used to increment and
    %   reset CW value for each AC.
    QSRC = zeros(4, 1);

    %CW Size of contention window(CW)
    %   CW is a vector of size 4 x 1 where each element represents size of
    %   contention window for corresponding AC.
    CW;

    %AIFSSlotCounter AIFS slot counter for CONTEND_STATE
    AIFSSlotCounter = zeros(1, 4);

    %BackoffCounter Backoff counter
    BackoffCounter = zeros(1, 4);

    %OwnerAC Access category that won contention
    OwnerAC = 0;

    %IsLastTXOPHolder Flag to indicate that the device is the last TXOP
    %holder
    %   IsLastTXOPHolder is a flag to indicate that the device is the last
    %   TXOP holder. It is set before CONTEND_STATE is triggered from
    %   the following states (TRANSMIT_STATE, RECEIVERESPONSE_STATE, 
    %   ERRORRECOVERY_STATE (if PIFS recovery)) by the TXOP holder.
    IsLastTXOPHolder = false;
end

%% BSS specific properties
properties (Hidden)
    %TXOPHolder TXOP holder address
    %   TXOPHolder is a character vector representing the address of TXOP
    %   holder. It is set when intra-NAV timer is set and reset when intra-NAV
    %   timer is reset or elapsed.
    TXOPHolder = '000000000000';

    %NonHTMCSIndicesForBasicRates Non-HT MCS indices corresponding to the data rates in
    %basic rates set
    NonHTMCSIndicesForBasicRates;
end

%% Full buffer related properties
properties (Hidden)
    %FullBufferTrafficEnabled Indicates whether full buffer traffic is enabled
    FullBufferTrafficEnabled = false;

    %FullBufferTrafficDestinationID List of destination IDs for which full
    %buffer traffic is enabled
    FullBufferTrafficDestinationID = 0;

    %FullBufferTrafficACIndex AC index for which full buffer traffic is enabled
    %for the destination node IDs specified in FullBufferTrafficDestinationID
    FullBufferTrafficACIndex = 1;
end

%% Context required at AP for downlink/uplink multi-user (MU) OFDMA transmission
properties(Hidden)
    %MaxMUUsers Maximum number of users in a multi-user(MU) transmission
    MaxMUUsers;

    %PrevDLTransmission Flag indicating that a DL transmission has occurred
    %previously. This flag is used to schedule alternate DL and UL MU
    %transmissions.
    PrevDLTransmission = false;

    %STAQueueInfo Queue information of the associated STAs
    %   STAQueueInfo is an array of size M-by-3. Elements in first column
    %   are associated STA IDs, in second column are access categories and
    %   in third column are queue sizes in bytes.
    STAQueueInfo = zeros(0, 3);

    %ULOFDMAScheduled Flag indicating that an UL OFDMA transmission is
    %scheduled by AP
    %   This property will be set to true when AP schedules an UL OFDMA
    %   transmission after winning contention, and reset at the end of
    %   the TXOP.
    ULOFDMAScheduled = false;

    %ULTBSysCfg TB system configuration object at AP for UL OFDMA transmission
    %   ULTBSysCfg is an object of type heTBSystemConfig. This is the config
    %   object maintained at AP for UL MU transmission. The UL HE TB frames
    %   might be in response to MU-BAR trigger frame or DL MU data with TRS
    %   control or Basic trigger frame.
    ULTBSysCfg = wlan.internal.mac.HETBSystemConfig(0);

    %ULMCS MCS assigned to each UL MU STA
    %   ULMCS is a vector where each element represents MCS assigned to an UL
    %   user by access point.
    ULMCS;

    %ULNumSTS Number of space time streams assigned to each UL MU STA
    %   ULNumSTS is a vector where each element represents number of space time
    %   streams assigned to an UL user by access point.
    ULNumSTS;

    %MultiSTABARate MCS index used to transmit Multi-STA BA frame
    %   MultiSTABARate is a scalar representing MCS index to use for
    %   transmitting a Multi-STA BA frame. The default value is 0.
    MultiSTABARate = 0;
end

%% Context required at STA to perform an UL OFDMA data transmission
properties(Hidden)
    %ULOFDMAEnabledAtAP Flag to indicate that the associated AP can trigger UL
    %OFDMA data transmissions
    % Set ULOFDMAEnabledAtAP to true at STA when its associated AP can send
    % Basic TF to solicit UL OFDMA data responses.
    ULOFDMAEnabledAtAP = false;
end

%% Spatial reuse related properties
properties (Hidden)
    %OBSSPDBuffer OBSS PD thresholds buffer
    %   OBSSPDBuffer is a vector that stores the OBSSPDThreshold values.
    %   Different OBSSPD values can be applied for different OBSS frames
    %   based on the type of receiving OBSS frame(Spatial reuse groups
    %   (SRG), Non-SRG or Parameterized spatial reuse (PSR)). This
    %   parameter is used in the calculation of tx power for parallel
    %   transmission when SR opportunity is identified. It will be reset
    %   again at the end of TXOP during SR operation. The initial value is
    %   an empty vector.
    OBSSPDBuffer = [];

    %RestrictSRTxPower Power restriction flag
    %   Set this property to true to indicate that the transmit power
    %   restriction is enabled during spatial reuse operation. This flag
    %   will be reset at the end of TXOP gained using spatial reuse. The
    %   initial value is false.
    RestrictSRTxPower = false;

    %UpdatedOBSSPDThreshold Updated OBSS PD threshold
    UpdatedOBSSPDThreshold = -82;

    %SROpportunityIdentified Spatial reuse opportunity identified
    %   SROpportunityIdentified is a flag indicating if a spatial reuse
    %   opportunity is identified. This flag is used to attempt transmission
    %   during identified SR opportunity by moving to contention.
    SROpportunityIdentified = false;
end

properties (Dependent, Hidden)
    %EnableSROperation Flag indicating spatial reuse(SR) operation is
    %enabled.
    EnableSROperation;
end

%% CCA and primary/secondary channel related properties
properties (Hidden)
    %CCAState PHY CCA state
    %   CCAState is a scalar or vector which represents PHY CCA state of
    %   primary and secondary channels. The elements in order represents the
    %   state of primary, secondary 20, secondary 40, secondary 80 and
    %   secondary 160. The number of secondary channels depends on the
    %   ChannelBandwidth property. Each element when set to true indicates that
    %   the corresponding channel is busy.
    CCAState;

    %CCAStatePer20 PHY CCA state of each 20 MHz subchannel
    %   CCAStatePer20 is a scalar or vector with number of elements equal to
    %   the number of 20 MHz subchannels. Each element when set to true
    %   indicates that the corresponding 20 MHz subchannel is busy.
    CCAStatePer20;

    %CCAIdleTimestamps Timestamp at which the primary and secondary channels
    %turned idle
    %  CCAIdleTimestamps is a scalar or vector. First element corresponds to
    %  primary 20 MHz and the following elements correspond to secondary 20,
    %  secondary 40, secondary 80 and secondary 160. The number of secondary
    %  channels depend on the ChannelBandwidth property. Each element
    %  represents the timestamp at which the corresponding channel has become
    %  idle.
    CCAIdleTimestamps;

    %LastCCAIdle2BusyDuration Duration of last CCA idle before turning busy
    %  LastCCAIdle2BusyDuration is a scalar or vector. First element
    %  corresponds to primary 20 MHz and the following elements correspond
    %  to secondary 20, secondary 40, secondary 80 and secondary 160. The
    %  number of secondary channels depend on the ChannelBandwidth
    %  property. Each element represents the last CCA idle duration before
    %  turning to CCA busy for the corresponding channel.
    LastCCAIdle2BusyDuration;

    %Initial20MHzIndices Indices of the first 20 MHz subchannels in primary and
    %secondary (20,40,80,160) channels
    %  Initial20MHzIndices is a scalar or vector which represents the index of
    %  first 20 MHz subchannel in primary 20, secondary 20, secondary 40,
    %  secondary 80 and secondary 160. The number of secondary channels depends
    %  on the ChannelBandwidth property.
    Initial20MHzIndices;

    %RequiredSecChannelIdleTime Time for which secondary channels must be idle
    %to consider them for transmission
    %   RequiredSecChannelIdleTime is a scalar which represents the time before
    %   the backoff counter expiry for which secondary 20/40/80/160 channels
    %   must be idle, so that they can be used for transmission. For 2.4GHz
    %   band, this value is DIFS and for 5 and 6 GHz bands, this value is PIFS.
    RequiredSecChannelIdleTime;

    %CandidateCentFreqOffset Candidate center frequency offset
    %   CandidateCentFreqOffset is a cell array representing offset from the
    %   operating center frequency for all possible bandwidths in the operating
    %   bandwidth. The elements in order represent the offset of center
    %   frequencies of 20, 40, 80, 160 and 320 MHz subchannels respectively
    %   from the operating center frequency.
    CandidateCentFreqOffset = {};

    %AvailableBandwidth Available channel bandwidth
    AvailableBandwidth;
end

%% Self-capabilities
properties (Hidden)
    %MaxSupportedStandard Max supported standard by the MAC
    %   Specify this property as an integer value in the range [0, 5]
    %   representing standards 802.11a, 802.11g, 802.11n, 802.11ac,
    %   802.11ax, 802.11be. This property takes the enumerated constant
    %   values from wlan.internal.Constants.Std80211XX.
    MaxSupportedStandard = wlan.internal.Constants.Std80211be;

    %DynamicBandwidthOperation Flag indicating whether bandwidth negotiation
    %using non-HT duplicate RTS/CTS is enabled or not
    %   DynamicBandwidthOperation is a scalar representing the capability to
    %   transmit CTS in a bandwidth less than or equal to the bandwidth
    %   signaled in a non-HT duplicate RTS when set to true. The default value
    %   is false.
    DynamicBandwidthOperation = false;

    %BABitmapLength Block-ack bitmap length
    BABitmapLength;
end

%% MLO specific properties
properties (Hidden)
    %IsAffiliatedWithMLD Flag indicating that the MAC is affiliated with a
    %multi-link device (MLD)
    IsAffiliatedWithMLD = false;

    %IsEMLSRLinkMarkedInactive Flag indicating whether the link is marked
    %inactive or not
    %   This property is set to true to indicate that the link must remain
    %   inactive due to frame exchange on active EMLSR link. When set to false,
    %   it indicates that the link must move out of INACTIVE_STATE. This
    %   property is applicable only in case of an EMLSR STA.
    IsEMLSRLinkMarkedInactive = false;

    %NumMediumSyncTXOPs Number of TXOPs initiated since the start of MSD timer
    %   This property is applicable only in case of an EMLSR STA.
    NumMediumSyncTXOPs = 0;

    %NumEMLSRListenAntennas Number of antennas to use for listening (CCA and
    %initial control frame (ICF) reception)
    %   This property is applicable only in case of an EMLSR STA.
    NumEMLSRListenAntennas = 1;
end

%% Beacon related properties
properties (Hidden)
    %TBTT Next target beacon transmission time (in nanoseconds)
    TBTT = 0;

    %TBTTAcquired Flag to check if Target Beacon Transmission Time (TBTT)
    %has reached
    TBTTAcquired = false;

    %BeaconFrameContext A structure containing context used for beacon
    %frame generation. This structure is populated the first time a beacon
    %frame is generated or if EDCA contention parameters are updated, and
    % is reused later to form the subsequent beacon frames.
    BeaconFrameContext = struct('ElementIDs', {zeros(0, 2)}, ... % Used in full MAC frame generation
        'InformationElements', {zeros(0, 1)}, ... % Used in full MAC frame generation
        'MACManagementConfigObject', wlanMACManagementConfig, ... % Used in full MAC frame generation
        'AbstractBeaconFrame', [], ... % Used in abstract MAC frame generation
        'NumPayloadBytes', 0); % Used in abstract MAC frame generation
end

%% Mesh related properties
properties (Hidden)
    %MeshNeighbors Mesh neighbors established for this mesh device
    %   This property is a cell array containing node IDs and device IDs of
    %   the neighbor mesh devices.
    MeshNeighbors = {};
end

%% PHY config objects and other PHY related properties
properties (Hidden)
    %NonHTConfig An object of type wlanNonHTConfig
    NonHTConfig;

    %HTConfig An object of type wlanHTConfig
    HTConfig;

    %VHTConfig An object of type wlanVHTConfig
    VHTConfig;

    %HESUConfig An object of type wlanHESUConfig
    HESUConfig;

    %EHTSUConfig An object of type wlanEHTMUConfig containing the transmit
    %parameters for a non-OFDMA single-user EHT MU format transmission
    %   This is used by the receiver to pass to wlanAMPDUDeaggregate function.
    %   In this function, only 'User' and 'EHTDUPMode' properties of the phy
    %   configuration object are used. As the simulation supports only
    %   single-user and no EHT DUP support, the object is created when MAC
    %   object is created.
    EHTSUConfig;

    %PHYMode PHY mode structure
    %   Output structure indicating the change in PHY mode
    PHYMode = wlan.internal.utils.defaultPHYMode;

    %PHYRxStartDelayEHT Maximum PHY Rx start delay of EHT PPDU in nanoseconds
    %   This value is used in calculation of timeout while an EMLSR STA is
    %   waiting for frame from AP after it has responded to ICF.
    PHYRxStartDelayEHT;
end

%% TxVector parameter
properties (Hidden)
    %TXOPDuration Transmission opportunity duration
    %   TXOPDuration is a scalar parameter representing transmission
    %   opportunity duration of an HE PPDU in the range [0, 8448] with the
    %   units as microseconds. This property is used to fill corresponding
    %   field in TXVECTOR for HE frames. This information in vector is used
    %   for NAV setting and protection of the TXOP. This value is set to -1
    %   when duration value is unspecified or unknown. The initial value is
    %   -1.
    TXOPDuration = -1;
end

%% Template properties: Frames and phy request/indication
properties (Hidden)
    %MACFrameTemplate Structure for MAC frame (abstracted MAC frame)
    MACFrameTemplate;

    %MPDUTemplate Default structure for data MPDU (abstracted MAC frame)
    MPDUTemplate
    
    % Default MPDU structures for different frame types (other than QoS Data)
    MPDUQoSNullTemplate
    MPDUBeaconTemplate
    MPDURTSTemplate
    MPDUCTSTemplate
    MPDUAckTemplate
    MPDUBlockAckTemplate
    MPDUCFEndTemplate
    MPDUMultiSTABlockAckTemplate
    MPDUMURTSTriggerTemplate
    MPDUMUBARTriggerTemplate
    MPDUBasicTriggerTemplate

    %BSRControlInfoTemplate Structure containing buffer status report (BSR)
    %information
    BSRControlInfoTemplate;

    %TRSControlInfoTemplate Structure containing triggered response scheduling (TRS)
    %information
    TRSControlInfoTemplate;

    %EmptyMACConfig A default object of type wlanMACFrameConfig
    EmptyMACConfig;

    %EmptyMACManagementConfig A default object of type wlanMACManagementConfig
    EmptyMACManagementConfig;

    %EmptyMACTriggerUserConfig A default object of type wlanMACTriggerUserConfig
    EmptyMACTriggerUserConfig;

    %EmptyRequestToPHY Structure for MAC requests to PHY
    EmptyRequestToPHY;
end

%% Template properties: Rate control
properties (Hidden)
    %RateControlTxContextTemplate Template structure for frame transmission
    %context information passed to rate control algorithm.
    RateControlTxContextTemplate;

    %RateControlTxStatusTemplate Template structure for frame transmission
    %status information passed to rate control algorithm.
    RateControlTxStatusTemplate;

    %DataFrameRateControlTxContext Structure for storing frame transmission information
    %passed to rate control algorithm.
    DataFrameRateControlTxContext;

    %ControlFrameRateControlTxContext Structure for storing frame transmission information
    %passed to rate control algorithm.
    ControlFrameRateControlTxContext;
end

%% Constant Properties
properties(Constant, Hidden)
    %NonHTMCSIndex6Mbps Non-HT MCS index representing 6 Mbps data rate
    NonHTMCSIndex6Mbps = 0;

    %SlotTime Slot time duration in nanoseconds
    SlotTime = 9e3;

    %PIFSTime PCF interframe spacing duration = SIFS Time + Slot Time in
    %nanoseconds
    PIFSTime = 25e3;

    %DIFSTime Distributed interframe spacing duration = SIFS Time + 2*Slot Time
    %in nanoseconds
    DIFSTime = 34e3;

    %MPDUOverhead Overhead for MPDU frames
    MPDUOverhead = 30;

    %MPDUMaxLength Maximum MPDU length in octets
    %   Maximum MPDU length that we can receive is:
    %   (MPDU header + FCS + Mesh control + Max MSDU length) = (32 + 4 + 18 + 2304)
    %   Refer table 9-25 in IEEE Std 802.11-2020.
    MPDUMaxLength = 2358;

    %AckOrCtsFrameLength Acknowledgment or CTS frame length
    %   Acknowledgment or CTS frame length (14 octets)
    AckOrCtsFrameLength = 14;

    %PHYRxStartDelayNonHT PHY Rx start delay of Non-HT PPDU in nanoseconds
    %   This value is used in calculation of timeout while waiting for
    %   response. The response frames for RTS, single-user data frames and
    %   MU-RTS are sent in Non-HT format. Hence, using the value corresponding
    %   to Non-HT PPDU.
    PHYRxStartDelayNonHT = 20e3;

    %PHYRxStartDelayHETB PHY Rx start delay of HE-TB PPDU in nanoseconds
    %   This value is used in calculation of timeout while waiting for HE-TB
    %   response. The response frames for multi-user data frames with TRS,
    %   MU-BAR and Basic trigger frames are sent in HE-TB format.
    PHYRxStartDelayHETB = 32e3;

    %OBSSPDThresholdMin Minimum value of OBSS PD threshold value in dBm.
    %   Specify OBSS PD Threshold in dBm as an integer in the range [-62
    %   -82]. The default value is -82.
    %   Reference: Table 26-11 of IEEE Std 802.11ax-2021
    OBSSPDThresholdMin = -82;

    %OBSSPDThresholdMax Maximum value of OBSS PD threshold value in dBm.
    %   Specify OBSS PD Threshold in dBm as an integer in the range [-62
    %   -82]. The default value is -62.
    %   Reference: Table 26-11 of IEEE Std 802.11ax-2021
    OBSSPDThresholdMax = -62;

    %MediumSyncThreshold Duration threshold on how long a link can switch off
    %CCA before invoking medium sync delay (MSD) timer
    MediumSyncThreshold = 72e3; % in nanoseconds

    %UserIndexSU User index for single user processing
    UserIndexSU = 1;   

    %BroadcastID Broadcast address
    BroadcastID = 65535;

    % MAC States
    IDLE_STATE = 1;
    CONTEND_STATE = 2;
    TRANSMIT_STATE = 3;
    RECEIVERESPONSE_STATE = 4;
    RECEIVE_STATE = 5;
    ERRORRECOVERY_STATE = 6;
    NAVWAIT_STATE = 7;
    EMLSRRECEIVE_STATE = 8;
    INACTIVE_STATE = 9;
    TRANSMITRESPONSE_STATE = 10;

    % MAC substates
    TRANSMIT_SUBSTATE = 1;
    WAITINGFORSIFS_SUBSTATE = 2;

    % Frame formats
    NonHT = wlan.internal.FrameFormats.NonHT;
    HTMixed = wlan.internal.FrameFormats.HTMixed;
    VHT = wlan.internal.FrameFormats.VHT;
    HE_SU = wlan.internal.FrameFormats.HE_SU;
    HE_EXT_SU = wlan.internal.FrameFormats.HE_EXT_SU;
    HE_MU = wlan.internal.FrameFormats.HE_MU;
    HE_TB = wlan.internal.FrameFormats.HE_TB;
    EHT_SU = wlan.internal.FrameFormats.EHT_SU;
    EHT_MU = wlan.internal.FrameFormats.EHT_MU;
    EHT_TB = wlan.internal.FrameFormats.EHT_TB;

    % PHY primitives
    CCAIndication = wlan.internal.PHYPrimitives.CCAIndication;
    RxStartIndication = wlan.internal.PHYPrimitives.RxStartIndication;
    RxEndIndication = wlan.internal.PHYPrimitives.RxEndIndication;
    RxErrorIndication = wlan.internal.PHYPrimitives.RxErrorIndication;
    TxStartRequest = wlan.internal.PHYPrimitives.TxStartRequest;
    UnknownIndication = wlan.internal.PHYPrimitives.UnknownIndication;

    % Standard types
    Std80211a = wlan.internal.Constants.Std80211a;
    Std80211g = wlan.internal.Constants.Std80211g;
    Std80211n = wlan.internal.Constants.Std80211n;
    Std80211ac = wlan.internal.Constants.Std80211ac;
    Std80211ax = wlan.internal.Constants.Std80211ax;
    Std80211be = wlan.internal.Constants.Std80211be;

    % Frame types supported in the simulation. These are used to assign
    % NextTxFrameType (next frame type to transmit) and LastTxFrameType
    % (last transmitted frame type) properties of TxContext. Control
    % response frame types are used to store the expected response type.
    UnknownFrameType = wlan.internal.Constants.UnknownFrameType;
    RTS = wlan.internal.Constants.RTS;
    CTS = wlan.internal.Constants.CTS;
    QoSData = wlan.internal.Constants.QoSData;
    ACK = wlan.internal.Constants.ACK;
    BlockAck = wlan.internal.Constants.BlockAck;
    MURTSTrigger = wlan.internal.Constants.MURTSTrigger;
    MUBARTrigger = wlan.internal.Constants.MUBARTrigger;
    BasicTrigger = wlan.internal.Constants.BasicTrigger;
    QoSNull = wlan.internal.Constants.QoSNull;
    MultiSTABlockAck = wlan.internal.Constants.MultiSTABlockAck;
    Beacon = wlan.internal.Constants.Beacon;
    CFEnd = wlan.internal.Constants.CFEnd;
    Management = wlan.internal.Constants.Management;
end

%% MAC statistics
properties (GetAccess = public, SetAccess = private, Description = 'Metrics')
    %Statistics Structure containing statistics captured at MAC layer
    Statistics = struct('TransmittedDataFrames', 0, ...         % Data frames transmitted
        'TransmittedPayloadBytes', 0, ...                       % MSDU bytes successfully transmitted
        'SuccessfulDataTransmissions', 0, ...                   % Successfully acknowledged data frames
        'RetransmittedDataFrames', 0, ...                       % Data frame retransmissions
        'TransmittedAMPDUs', 0, ...                             % AMPDU transmissions
        'TransmittedRTSFrames', 0, ...                          % RTS frames transmitted
        'TransmittedMURTSFrames', 0, ...                        % MU-RTS frames transmitted
        'TransmittedCTSFrames', 0, ...                          % CTS frames transmitted
        'TransmittedMUBARFrames', 0, ...                        % MU-BAR frames transmitted
        'TransmittedAckFrames', 0, ...                          % Ack frames transmitted
        'TransmittedBlockAckFrames', 0, ...                     % Block Ack frames transmitted
        'TransmittedCFEndFrames', 0, ...                        % CF-End frames transmitted
        'TransmittedBasicTriggerFrames', 0, ...                 % Basic trigger frames transmitted
        'TransmittedBeaconFrames', 0, ...                       % Beacon frames transmitted
        'ReceivedDataFrames', 0, ...                            % Data frames received, intended to this node
        'ReceivedPayloadBytes', 0, ...                          % MSDU bytes received
        'ReceivedAMPDUs', 0, ...                                % Received AMPDUs with at least one valid subframe
        'ReceivedRTSFrames', 0, ...                             % RTS frames received
        'ReceivedMURTSFrames', 0, ...                           % MU-RTS frames received
        'ReceivedCTSFrames', 0, ...                             % CTS frames received
        'ReceivedMUBARFrames', 0, ...                           % MU-BAR frames received
        'ReceivedAckFrames', 0, ...                             % Ack frames received
        'ReceivedBlockAckFrames', 0, ...                        % Block Ack frames received
        'ReceivedCFEndFrames', 0, ...                           % CF-End frames received
        'ReceivedBasicTriggerFrames', 0, ...                    % Basic trigger frames intended to this node
        'ReceivedFCSValidFrames', 0, ...                        % Received MPDUs with valid FCS
        'ReceivedFCSFails', 0, ...                              % MPDU FCS failures
        'ReceivedDelimiterCRCFails', 0, ...                     % Delimiter CRC failures in A-MPDU subframes
        'ReceivedBeaconFrames', 0);                             % Beacon frames received

    PerSTAStatistics = struct([]);
    PerSTAStatisticsTemplate = struct('TransmittedDataFrames', 0, ...
        'TransmittedPayloadBytes', 0, ...
        'RetransmittedDataFrames', 0, ...
        'AssociatedNodeID', 0);

    PerACPerSTAStatistics = struct([]);
    PerACPerSTAStatisticsTemplate = struct('TransmittedMSDUBytesPerAC', [0 0 0 0], ...
        'TransmittedUnicastDataFramesPerAC', [0 0 0 0], ...
        'RetransmittedDataFramesPerAC', [0 0 0 0], ...
        'AssociatedNodeID', 0);

    TransmittedUnicastDataFramesPerAC = zeros(1, 4);            % Unicast data frames per-AC
    TransmittedBroadcastDataFramesPerAC = zeros(1, 4);          % Broadcast data frames per-AC
    TransmittedMSDUBytesPerAC = zeros(1, 4);                    % MSDU bytes successfully transmitted per-AC
    SuccessfulDataTransmissionsPerAC = zeros(1, 4);             % Successfully acknowledged data frames per-AC
    RetransmittedDataFramesPerAC = zeros(1, 4);                 % Data frame retransmissions per-AC
    TransmittedAMPDUsPerAC = zeros(1, 4);                       % AMPDU transmissions per-AC
    ReceivedUnicastDataFramesPerAC = zeros(1, 4);               % Unicast data frames intended to this node per-AC
    ReceivedUnicastDataFramesToOthersPerAC = zeros(1, 4);       % Unicast data frames intended to other node per-AC
    ReceivedBroadcastDataFramesPerAC = zeros(1, 4);             % Broadcast data frames received per-AC
    ReceivedMSDUBytesPerAC = zeros(1, 4);                       % MSDU bytes received per-AC
    ReceivedAMPDUsPerAC = zeros(1, 4);                          % Received AMPDUs with at least one valid subframe per-AC
    ReceivedDuplicateDataFramesPerAC = zeros(1, 4);             % Duplicate data frames received
    SuccessfulRTSTransmissions = 0;                             % Successfully transmitted RTS frames
    SuccessfulMURTSTransmissions = 0;                           % Successfully transmitted MU-RTS frames
    TransmitQueueOverflowPerAC = zeros(1, 4);                   % Packet overflows from MAC queues
    ResponseFrameFCSFailures = 0;                               % Response frames with FCS failures
    AMPDUDecodeFailures = 0;                                    % A-MPDUs in which valid subframes are not detected
    InternalCollisionsPerAC = zeros(1, 4);                      % Internal collisions during contention
    PacketLossRatio = 0;                                        % Ratio of lost packets to total sent packets
    ReceivedBeaconFramesFromAssociatedAP = 0;                   % Total number of beacon frames received from associated AP (updated only for STA nodes)
    ReceivedBeaconFramesFromAP = 0;                             % Total number of beacon frames received from all AP devices (updated for all nodes)
    ReceivedBeaconFramesFromMesh = 0;                           % Total number of beacon frames received from all Mesh devices (updated for all nodes)
    TransmittedManagementFrames = 0;                            % Total number of management frame transmissions
    ReceivedManagementFrames = 0;                               % Total number of management frame receptions
    SuccessfulManagementTransmissions = 0;                      % Successfully acknowledged management frames
    RetransmittedManagementFrames = 0;                          % Management frame retransmissions
end

%% MAC events
properties(Hidden)
    % Following are properties for new events interface (Callback mechanism)

    %EventTemplate Template structure for event notification data
    EventTemplate;

    % Properties to hold structure templates of 'EventData' field in
    % notification data of corresponding event
    TransmissionStartedTemplate;
    ReceptionEndedTemplate;
    ChangingStateTemplate;

    %PPDUParametersTemplate Template sub-structure in 'EventData' field in
    %notification data of ReceptionEnded event
    PPDUParametersTemplate;

    % Properties to hold current event notification data
    TransmissionStarted;
    ReceptionEnded;

    % Following are properties for old events interface (MATLAB events
    % listeners mechanism)

    %HasListener Structure with event names as field names containing flags
    %indicating whether they have a listener
    HasListener = wlan.internal.utils.defaultEventList;

    %MPDUGenerated Structure containing data that is notified when MPDU(s)
    %are generated at MAC. This event is notified only in case of full MAC
    %frames. It is notified at once after all MPDU(s) in a MAC frame are
    %generated.
    %   DeviceID      - Scalar representing device identifier
    %   CurrentTime   - Scalar representing current simulation time in seconds
    %   MPDU          - Cell array of MPDU(s) where each element is a vector
    %                   containing MPDU bytes in decimal format
    %   Frequency     - Scalar representing center frequency of transmitting
    %                   PPDU in Hz
    MPDUGenerated

    %MPDUDecoded Structure containing data that is notified when: (a) A decode
    %failure is indicated by PHY or (b) Received MPDU(s) are decoded at MAC. In
    %second case, it is notified at once after all MPDU(s) in a MAC frame are
    %decoded.
    %   DeviceID      - Scalar representing device identifier
    %   CurrentTime   - Scalar representing current simulation time in seconds
    %   MPDU          - Cell array of MPDU(s) where each element is a vector
    %                   containing MPDU bytes in decimal format in case of full
    %                   MAC frames
    %                   Structure containing information of all MPDUs in a MAC
    %                   frame in case of abstract MAC frames
    %   FCSFail       - Flag indicating whether frame check sequence (FCS)
    %                   failed at MAC. In case of multiple MPDUs, it is a
    %                   vector with values for each MPDU
    %   PHYDecodeFail - Logical scalar representing a decode failure at PHY,
    %                   when set to true. When set to true, MPDU and FCSFail
    %                   fields are not applicable
    %   PPDUStartTime - Scalar representing PPDU start time in seconds
    %   Frequency     - Scalar representing center frequency of PPDU in Hz
    %   Bandwidth     - Scalar representing bandwidth of PPDU in Hz
    MPDUDecoded

    %TransmissionStatus Structure containing data that is notified about the
    %transmission status of an RTS/MU-RTS or a data frame. This event is
    %triggered for each user in the transmission.
    %   DeviceID           - Scalar representing device identifier
    %   CurrentTime        - Scalar representing current simulation time in seconds
    %   FrameType          - String representing frame type as one of "QoS Data",
    %                        "RTS", or "MU-RTS"
    %   ReceiverNodeID     - Scalar representing ID of the node to which
    %                        frame is transmitted
    %   MPDUSuccess        - Logical scalar when transmitted frame contains
    %                        an MPDU and vector when it contains an A-MPDU.
    %                        Each element represents transmission status as:
    %                          'true'  - Transmission success
    %                          'false' - Transmission failure
    %   MPDUDiscarded      - Logical scalar when transmitted frame contains
    %                        an MPDU and vector when it contains an A-MPDU.
    %                        Each element represents whether MPDU is discarded:
    %                          'true'  - MPDU discarded
    %                          'false' - MPDU not discarded
    %                        When FrameType is "RTS" or "MU-RTS",
    %                        MPDUDiscarded flag indicates the status of
    %                        discard of data packets from transmission
    %                        queues.
    %   TimeInQueue        - Scalar when transmitted frame contains an
    %                        MPDU and vector when it contains an A-MPDU.
    %                        Each element represents time in seconds spent
    %                        by packet in MAC queue. This is applicable for
    %                        MPDUs whose MPDUDiscarded flag is set to true.
    %   AccessCategory     - Scalar when transmitted frame contains an
    %                        MPDU and vector when it contains an A-MPDU.
    %                        Each element represents access category of the
    %                        MPDU, where 0, 1, 2 and 3 represents
    %                        Best-Effort, Background, Video and Voice
    %                        respectively. When FrameType is "RTS" or
    %                        "MU-RTS", it indicates the access category of
    %                        the corresponding "QoS Data".
    %   ResponseRSSI       - Scalar value indicating the signal strength of
    %                        the received response in the form of an Ack
    %                        frame, a Block Ack, or a CTS frame.
    TransmissionStatus

    %StateChangedTemplate Structure containing template of data that is notified when
    %idle/contention/sleep is completed
    %   DeviceID    - Scalar representing device identifier
    %   CurrentTime - Scalar representing current simulation time in seconds
    %   State       - State of device representing "Contention",
    %                 "Transmission", "Reception", "Idle", or "Sleep"
    %   Duration    - Scalar representing state duration
    %   Frequency   - Scalar representing center frequency of transmitted
    %                 waveform in Hz. Applicable only when State is "Transmission.
    %   Bandwidth   - Scalar representing bandwidth of transmitted waveform
    %                 in Hz. Applicable only when State is "Transmission".
    StateChangedTemplate;
end

% Public methods
methods
    % Constructor
    function obj = edcaMAC(varargin)
        % Initial MAC state
        obj.MACState = obj.IDLE_STATE;

        % Create object for rate control
        obj.RateControl = wlan.internal.mac.RateControlFixed;
        obj.ULRateControl = wlan.internal.mac.RateControlFixed;

        % Create object for power control
        obj.PowerControl = wlan.internal.mac.PowerControlFixed;

        % Create a scheduler object
        obj.Scheduler = wlan.internal.mac.SchedulerRoundRobin;

        % Create shared MAC object
        obj.SharedMAC = wlan.internal.mac.SharedMAC(obj.MaxQueueLength, obj.MaxSubframes);

        % Name-value pairs
        for idx = 1:2:numel(varargin)
            obj.(varargin{idx}) = varargin{idx+1};
        end

        % Sub channels: Pri20, sec20, sec40, sec80 and sec160 based on configured
        % bandwidth
        numSubchannels = log2(obj.ChannelBandwidth/10);
        obj.CCAState = zeros(1,numSubchannels);
        obj.CCAIdleTimestamps = zeros(1,numSubchannels);
        obj.LastCCAIdle2BusyDuration = zeros(1,numSubchannels);
        obj.Initial20MHzIndices = zeros(1,numSubchannels);
        obj.CCAStatePer20 = zeros(1,obj.ChannelBandwidth/20);
        % Assign default values for these properties
        setPrimaryChannelInfo(obj, obj.PrimaryChannelIndex);
        obj.CandidateCentFreqOffset = wlan.internal.utils.getChannelCenterFreqOffset(obj.ChannelBandwidth);

        % Disable beacon transmission from STA
        if ~(obj.IsAPDevice || obj.IsMeshDevice)
            obj.BeaconInterval = Inf;
        end

        if obj.MaxSubframes <= 64
            obj.BABitmapLength = 64;
        elseif obj.MaxSubframes <= 256 % obj.MaxSubframes > 64 && obj.MaxSubframes <= 256
            obj.BABitmapLength = 256;
        elseif obj.MaxSubframes <= 512 % obj.MaxSubframes > 256 && obj.MaxSubframes <= 512
            obj.BABitmapLength = 512;
        else % obj.MaxSubframes > 512
            obj.BABitmapLength = 1024;
        end

        % Maximum users in multi-user(MU) transmission.
        switch obj.ChannelBandwidth
            case 20
                obj.MaxMUUsers = 9;
            case 40
                obj.MaxMUUsers = 18;
            case 80
                obj.MaxMUUsers = 37;
            otherwise % 160 MHz
                obj.MaxMUUsers = 74;
        end

        % Calculate the Target Beacon Transmission Time for the first
        % beacon frame, based on the configured InitialBeaconOffset
        if isfinite(obj.BeaconInterval) && (obj.IsAPDevice || obj.IsMeshDevice)
            linkIdx = getLinkIndex(obj);
            obj.SharedMAC.LastTBTT(linkIdx) = obj.TBTT;
            if isscalar(obj.InitialBeaconOffset) % Constant initial TBTT
                obj.TBTT = obj.InitialBeaconOffset*1024e3;
            else % Random initial TBTT
                obj.TBTT = randi([obj.InitialBeaconOffset(1)*1024e3 obj.InitialBeaconOffset(2)*1024e3]);
            end
            obj.SharedMAC.NextTBTT(linkIdx) = obj.TBTT;
        end

        % Create transmission and reception context objects
        obj.Tx = wlan.internal.mac.TxContext(obj.MaxSubframes, obj.MaxMUUsers, obj.ChannelBandwidth);
        obj.Rx = wlan.internal.mac.RxContext(obj.BABitmapLength, obj.MaxMUUsers);

        % Create a WLAN MAC Queue management object
        obj.LinkEDCAQueues = wlan.internal.mac.QueueManager(obj.MaxQueueLength, obj.MaxSubframes, ...
            ShortRetryLimit=obj.SharedMAC.ShortRetryLimit, MSDUMaxLifetime=obj.MSDUMaxLifetime, DestinationNodeIDs=65535);

        % Initialize uplink OFDMA properties
        obj.ULMCS = zeros(obj.MaxMUUsers, 1);
        obj.ULNumSTS = zeros(obj.MaxMUUsers, 1);

        % Determine if this link is affiliated with an MLD
        obj.IsAffiliatedWithMLD = obj.SharedMAC.IsMLD;

        % Create default structures
        obj.MACFrameTemplate = wlan.internal.utils.defaultMACFrame; % Default MAC frame
        obj.MPDUTemplate = wlan.internal.utils.defaultMPDU; % Default MPDU (QoS Data)
        obj.MPDUQoSNullTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('QoS Null'), wlan.internal.utils.defaultMPDUFrameBody('QoS Null')); % Default MPDU (QoS Data)
        obj.MPDUBeaconTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('Beacon'), wlan.internal.utils.defaultMPDUFrameBody('Beacon'));
        obj.MPDURTSTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('RTS'), wlan.internal.utils.defaultMPDUFrameBody('RTS'));
        obj.MPDUCTSTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('CTS'), wlan.internal.utils.defaultMPDUFrameBody('CTS'));
        obj.MPDUAckTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('ACK'), wlan.internal.utils.defaultMPDUFrameBody('ACK'));
        obj.MPDUBlockAckTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('Block Ack'), wlan.internal.utils.defaultMPDUFrameBody('Block Ack'));
        obj.MPDUCFEndTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('CF-End'), wlan.internal.utils.defaultMPDUFrameBody('CF-End'));
        obj.MPDUMultiSTABlockAckTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('Multi-STA-BA'), wlan.internal.utils.defaultMPDUFrameBody('Multi-STA-BA'));
        obj.MPDUMURTSTriggerTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('Trigger'), wlan.internal.utils.defaultMPDUFrameBody('Trigger','MU-RTS'));
        obj.MPDUMUBARTriggerTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('Trigger'), wlan.internal.utils.defaultMPDUFrameBody('Trigger','MU-BAR'));
        obj.MPDUBasicTriggerTemplate = wlan.internal.utils.defaultMPDU(wlan.internal.utils.defaultMPDUHeader('Trigger'), wlan.internal.utils.defaultMPDUFrameBody('Trigger','Basic'));

        % Only the fields useful in simulation are added to the structure
        obj.BSRControlInfoTemplate = wlan.internal.utils.defaultBSRControlInfo;

        % Only the fields useful in simulation are added to the structure
        obj.TRSControlInfoTemplate = wlan.internal.utils.defaultTRSControlInfo;

        % Structure exchanged between MAC and PHY
        % Reuse the default structure template defined for PHY layer in wlan.internal.utils folder
        obj.EmptyRequestToPHY = wlan.internal.utils.defaultIndicationToMAC;

        obj.NonHTConfig = wlanNonHTConfig;
        obj.HTConfig = wlanHTConfig;
        obj.VHTConfig = wlanVHTConfig;
        obj.HESUConfig = wlanHESUConfig;
        obj.EHTSUConfig = wlanEHTMUConfig("CBW"+obj.ChannelBandwidth);

        % Initialize MAC parameters
        initMACParameters(obj);

        % Initialize event related structures
        obj.EventTemplate = wnet.internal.defaultEventTemplate;
        obj.EventTemplate.NodeName = obj.NodeName;
        obj.EventTemplate.NodeID = obj.NodeID;
        obj.EventTemplate.TechnologyType = wnet.TechnologyType.WLAN;

        obj.TransmissionStartedTemplate = struct('PDU', [], ... % Cell array of MPDUs (each element is decimal octet row vector) in full MAC
            'Length', 0, ... % Number of octets sent from MAC to PHY (PSDU length)
            'Duration', 0, 'TransmitPower', 0, ... % Transmission time in seconds, Transmit power in dBm
            'TransmitCenterFrequency', 0, 'TransmitBandwidth', 0, ... % Center frequency and bandwidth of current transmission in Hz
            'CenterFrequency', obj.OperatingFrequency, ... % Frequency of operation in Hz
            'Bandwidth', obj.ChannelBandwidth*1e6); % Bandwidth of operation in Hz
        obj.TransmissionStarted = obj.TransmissionStartedTemplate;

        obj.PPDUParametersTemplate = struct('Format', "Non-HT", 'MCS', 0, ...
            'Aggregation', false, 'NumSpaceTimeStreams', 0, 'TXOPDuration', 127, ...
            'BSSColor', 0);

        obj.ReceptionEndedTemplate = struct('PDU', [], ... % Cell array of MPDUs (each element is decimal octet row vector) in full MAC
            'Length', 0, ... % Number of octets sent from PHY to MAC (PSDU length)
            'Duration', 0, ... % Duration of current reception in seconds
            'ReceiveCenterFrequency', 0, 'ReceiveBandwidth', 0, ... % Center frequency and bandwidth of current reception in Hz
            'CenterFrequency', obj.OperatingFrequency, ... % Frequency of operation in Hz
            'Bandwidth', obj.ChannelBandwidth*1e6, ... % Bandwidth of operation in Hz
            'PHYDecodeStatus', 0, 'PDUDecodeStatus', [], ... % PHY decode status, MPDU (MAC) decode status
            'IsIntendedReception', false); % Reception is destined to us or not
        obj.ReceptionEnded = obj.ReceptionEndedTemplate;

        obj.ChangingStateTemplate = struct('PreviousState', "", ... % State from which MAC is exiting
            'NextState', "", ... % State into which MAC is entering
            'PreviousStateDuration', 0, ... % Time in seconds spent in state from which MAC is exiting
            'CenterFrequency', obj.OperatingFrequency, ... % Frequency of operation in Hz
            'Bandwidth', obj.ChannelBandwidth*1e6); % Bandwidth of operation in Hz

        obj.MPDUGenerated = struct('DeviceID', obj.DeviceID, ...
            'CurrentTime', 0, 'MPDU', [], 'Frequency', 0);
        obj.MPDUDecoded = struct('DeviceID', obj.DeviceID, ...
            'CurrentTime', 0, 'MPDU', [], 'FCSFail', false, ...
            'PHYDecodeFail', false, 'PPDUStartTime', 0, ...
            'Frequency', 0, 'Bandwidth', 0);
        obj.TransmissionStatus = struct('DeviceID', obj.DeviceID, ...
            'CurrentTime', 0, 'FrameType', "RTS", 'ReceiverNodeID', 0, ...
            'MPDUSuccess', false, 'MPDUDiscarded', false, ...
            'TimeInQueue', 0, 'AccessCategory', 0, 'ResponseRSSI', 0);
        
        obj.StateChangedTemplate = struct('DeviceID', obj.DeviceID, ...
            'CurrentTime', 0, 'State', "Contention", 'Duration', 0, ...
            'Frequency', 0, 'Bandwidth', 0);

        % Initialize rate control related structures
        obj.RateControlTxContextTemplate = struct('FrameType', "QoS Data", ...
            'ReceiverNodeID', 0, 'TransmissionFormat', 'HE-SU', ...
            'IsRetry', false, 'AvailableBandwidth', 20e6);
        obj.RateControlTxStatusTemplate = struct('IsMPDUSuccess', false, ...
            'IsMPDUDiscarded', false, 'CurrentTime', 0, 'ResponseRSSI', 0);

    end

    function initPreAssociationContext(obj)
        %initPreAssociationContext Initialize context that is used in
        %association

        setPrimaryChannelInfo(obj, obj.PrimaryChannelIndex);
        if obj.IsAPDevice
            bssID = obj.MACAddress;
            deviceType = "AP";
        else
            bssID = '000000000000'; % No association performed yet
            if obj.IsMeshDevice
                deviceType = "mesh";
            else
                deviceType = "STA";
            end
        end
        addConnection(obj, deviceType, obj.AID, obj.BSSColor, bssID, obj.BasicRates);
        setAssociationConfig(obj.RateControl, obj.BasicRates);
        setAssociationConfig(obj.ULRateControl, obj.BasicRates);
    end

    function [nextInvokeTime, macReqToPHY, frameToPHY] = run(obj, currentTime, phyIndication, frameFromPHY)
        %run Runs MAC Layer state machine
        %
        %   This function implements the following:
        %   1. EDCA (Enhanced Distribution Channel Access)
        %   2. Generation and parsing of MPDUs and A-MPDUs
        %   3. Transmission of PSDUs in NonHT/HT/HE/VHT based on
        %   configuration
        %
        %   [NEXTINVOKETIME, MACREQTOPHY, FRAMETOPHY] = run(OBJ,
        %   CURRENTTIME, PHYINDICATION, FRAMEFROMPHY) runs MAC Layer.
        %
        %   NEXTINVOKETIME is the time (in nanoseconds) after which the
        %   run function must be invoked again.
        %
        %   MACREQTOPHY is the transmission start request to PHY Layer.
        %
        %   FRAMETOPHY is the frame sent to PHY Layer.
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   CURRENTTIME is the simulation time in nanoseconds.
        %
        %   PHYINDICATION is indication from PHY Layer.
        %
        %   FRAMEFROMPHY is the frame received from PHY layer.

        % Initialize
        macReqToPHY = obj.EmptyRequestToPHY;
        frameToPHY = [];
        obj.ElapsedTime = currentTime - obj.LastRunTimeNS;
        obj.LastRunTimeNS = currentTime;

        % Check and update TBTT
        if isfinite(obj.BeaconInterval)
            checkAndUpdateTBTT(obj, currentTime);
        end

        % Handle the events as per the current state
        switch obj.MACState
            case obj.IDLE_STATE
                nextInvokeTime = handleEventsIDLE(obj, currentTime, phyIndication);

            case obj.CONTEND_STATE
                nextInvokeTime = handleEventsContend(obj, currentTime, phyIndication);

            case obj.TRANSMIT_STATE
                [macReqToPHY, frameToPHY, nextInvokeTime] = handleEventsTransmit(obj, currentTime);

            case obj.RECEIVERESPONSE_STATE
                nextInvokeTime = handleEventsReceiveResponse(obj, currentTime, phyIndication, frameFromPHY);

            case obj.RECEIVE_STATE
                nextInvokeTime = handleEventsReceive(obj, currentTime, phyIndication, frameFromPHY);

            case obj.ERRORRECOVERY_STATE
                nextInvokeTime = handleEventsErrorRecovery(obj, currentTime, phyIndication);

            case obj.NAVWAIT_STATE
                nextInvokeTime = handleEventsNAVWait(obj, currentTime, phyIndication);

            case obj.EMLSRRECEIVE_STATE
                nextInvokeTime = handleEventsEMLSRReceive(obj, currentTime, phyIndication, frameFromPHY);

            case obj.INACTIVE_STATE
                nextInvokeTime = handleEventsInactive(obj, currentTime, phyIndication);

            case obj.TRANSMITRESPONSE_STATE
                [macReqToPHY, frameToPHY, nextInvokeTime] = handleEventsTransmitResponse(obj, currentTime, phyIndication);
        end
    end

    function enqueuePacket(obj, mpdu)
        %enqueuePacket Enqueue packet into MAC queue
        %
        %   enqueuePacket(OBJ, MPDU) enqueues packet into MAC
        %   transmission queues.
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   PACKET is the MPDU to be enqueued. It is a structure of
        %   type wlan.internal.utils.defaultMPDU.

        % Get access category of the packet
        ac = wlan.internal.Constants.TID2AC(mpdu.Header.TID+1);

        % Expand queues if receiver entry is not present
        receiverID = mpdu.Metadata.ReceiverID;
        qIdx = find(receiverID == getDestinationIDs(obj.LinkEDCAQueues),1);
        if isempty(qIdx) % Queues are not yet created for given receiver
            linkIdx = getLinkIndex(obj);
            % Check if the given receiver is an MLD
            receiverIdxLogical = (receiverID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
            isMLDReceiver = obj.SharedMAC.RemoteSTAInfo(receiverIdxLogical).IsMLD;
            getQIndexAndExpandContext(obj.SharedMAC, receiverID, false, linkIdx, isMLDReceiver);
        end

        % Enqueue packet
        isSuccess = enqueue(obj.LinkEDCAQueues, receiverID, ac+1, mpdu);

        if ~isSuccess % Queue overflow
            % Update MAC queue overflow statistics
            obj.TransmitQueueOverflowPerAC(ac + 1) = obj.TransmitQueueOverflowPerAC(ac + 1) + 1;
        end
    end

    function isFull = isQueueFull(obj, receiverID, ac)
        %isQueueFull Return whether per-link queue is full or not
        %
        %   ISFULL = isQueueFull(OBJ, RECEIVERID, AC) returns status of the
        %   per-link queue for specified receiver ID and access category.
        %
        %   The function returns ISFULL as true when per-link queue for specified
        %   receiver ID and access category is full. Otherwise, it returns false.
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   RECEIVERID is the node ID of the receiver.
        %
        %   AC is the access category specified as an integer in the range
        %   [0, 3] representing Best Effort, Background, Video, and Voice
        %   traffic.

        isFull = true;
        acIndex = ac + 1;
        qIdx = find(receiverID == getDestinationIDs(obj.LinkEDCAQueues));

        if isempty(qIdx) % Queues are not yet created for given receiver
            linkIdx = getLinkIndex(obj);
            % Check if the given receiver is an MLD
            receiverIdxLogical = (receiverID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
            isMLDReceiver = obj.SharedMAC.RemoteSTAInfo(receiverIdxLogical).IsMLD;
            qIdx = getQIndexAndExpandContext(obj.SharedMAC, receiverID, false, linkIdx, isMLDReceiver);
        end

        % Check if MAC buffers are full
        if (obj.LinkEDCAQueues.TxQueueLengths(qIdx, acIndex) + obj.LinkEDCAQueues.RetryBufferLengths(qIdx, acIndex)) ...
                ~= obj.LinkEDCAQueues.MaxQueueLength
            isFull = false;
        end
    end

    function isFull = isManagementQueueFull(obj, receiverID)
        %isManagementQueueFull Return whether per-link queue of management
        %frames is full or not
        %
        %   ISFULL = isManagementQueueFull(OBJ, RECEIVERID) returns status
        %   of the per-link queue of management frames for specified
        %   receiver ID.
        %
        %   The function returns ISFULL as true when per-link queue for
        %   specified receiver ID is full. Otherwise, it returns false.
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   RECEIVERID is the node ID of the receiver.

        isFull = true;
        qIdx = find(receiverID == getDestinationIDs(obj.LinkEDCAQueues));

        if isempty(qIdx) % Queues are not yet created for given receiver
            linkIdx = getLinkIndex(obj);
            % Check if the given receiver is an MLD
            receiverIdxLogical = (receiverID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
            isMLDReceiver = obj.SharedMAC.RemoteSTAInfo(receiverIdxLogical).IsMLD;
            qIdx = getQIndexAndExpandContext(obj.SharedMAC, receiverID, false, linkIdx, isMLDReceiver);
        end

        % Check if MAC buffers are full
        numMgtFramesInRetryBuffer = numManagementFramesInRetryBuffer(obj.LinkEDCAQueues, qIdx);
        if (obj.LinkEDCAQueues.TxManagementQueueLengths(qIdx) + numMgtFramesInRetryBuffer) ~= obj.LinkEDCAQueues.MaxQueueLength
            isFull = false;
        end
    end

    function macStats = statistics(obj, varargin)
        %statistics Get the statistics captured in MAC layer

        macStats = obj.Statistics;
        macStats.TransmittedDataFrames = sum(obj.TransmittedUnicastDataFramesPerAC) + sum(obj.TransmittedBroadcastDataFramesPerAC) + sum(obj.RetransmittedDataFramesPerAC);
        macStats.TransmittedPayloadBytes = sum(obj.TransmittedMSDUBytesPerAC);
        macStats.SuccessfulDataTransmissions = sum(obj.SuccessfulDataTransmissionsPerAC);
        macStats.RetransmittedDataFrames = sum(obj.RetransmittedDataFramesPerAC);
        macStats.TransmittedAMPDUs = sum(obj.TransmittedAMPDUsPerAC);
        macStats.ReceivedDataFrames = sum(obj.ReceivedUnicastDataFramesPerAC) + sum(obj.ReceivedBroadcastDataFramesPerAC) + sum(obj.ReceivedUnicastDataFramesToOthersPerAC);
        macStats.ReceivedPayloadBytes = sum(obj.ReceivedMSDUBytesPerAC);
        macStats.ReceivedAMPDUs = sum(obj.ReceivedAMPDUsPerAC);
        macStats.ReceivedBeaconFrames = obj.ReceivedBeaconFramesFromAP + obj.ReceivedBeaconFramesFromMesh;
        if ~isempty(varargin) && strcmp(varargin{1}, 'all')
            macStats.AccessCategories = repmat(struct('TransmittedDataFrames', 0, ...
                'TransmittedPayloadBytes', 0, ...
                'SuccessfulDataTransmissions', 0, ...
                'RetransmittedDataFrames', 0, ...
                'ReceivedDataFrames', 0, ...
                'ReceivedPayloadBytes', 0), 1, 4);

            for acIdx = 1:4
                macStats.AccessCategories(acIdx).TransmittedDataFrames = obj.TransmittedUnicastDataFramesPerAC(acIdx) + obj.TransmittedBroadcastDataFramesPerAC(acIdx) + obj.RetransmittedDataFramesPerAC(acIdx);
                macStats.AccessCategories(acIdx).TransmittedPayloadBytes = obj.TransmittedMSDUBytesPerAC(acIdx);
                macStats.AccessCategories(acIdx).SuccessfulDataTransmissions = obj.SuccessfulDataTransmissionsPerAC(acIdx);
                macStats.AccessCategories(acIdx).RetransmittedDataFrames = obj.RetransmittedDataFramesPerAC(acIdx);
                macStats.AccessCategories(acIdx).ReceivedDataFrames = obj.ReceivedUnicastDataFramesPerAC(acIdx) + obj.ReceivedBroadcastDataFramesPerAC(acIdx) + obj.ReceivedUnicastDataFramesToOthersPerAC(acIdx);
                macStats.AccessCategories(acIdx).ReceivedPayloadBytes = obj.ReceivedMSDUBytesPerAC(acIdx);
            end
        end

        % Compute PacketLossRatio
        if (macStats.TransmittedDataFrames > 0)
            % Total number of transmitted MSDUs
            totalTx = macStats.TransmittedDataFrames;
            txSuccess = macStats.SuccessfulDataTransmissions;
            obj.PacketLossRatio = (totalTx - txSuccess)/totalTx;
        end
    end

    function perSTAStats = getPerSTAStatistics(obj)
        %getPerSTAStatistics Returns the per STA statistics captured in MAC layer and the
        %ID of the corresponding STA/AP node

        for staIdx = 1:numel(obj.PerSTAStatistics)
            obj.PerSTAStatistics(staIdx).TransmittedPayloadBytes = ...
                sum(obj.PerACPerSTAStatistics(staIdx).TransmittedMSDUBytesPerAC);

            obj.PerSTAStatistics(staIdx).TransmittedDataFrames = ...
                sum(obj.PerACPerSTAStatistics(staIdx).TransmittedUnicastDataFramesPerAC) + ...
                sum(obj.PerACPerSTAStatistics(staIdx).RetransmittedDataFramesPerAC);

            obj.PerSTAStatistics(staIdx).RetransmittedDataFrames = ...
                sum(obj.PerACPerSTAStatistics(staIdx).RetransmittedDataFramesPerAC);
        end
        perSTAStats = obj.PerSTAStatistics;
    end

    function addConnection(obj, deviceType, aid, bssColor, bssid, basicRates)
        %addConnection Add connection information at STA

        obj.BSSID = bssid;
        obj.BasicRates = basicRates;
        obj.BSSColor = bssColor;
        if strcmp(deviceType, 'STA') && ~strcmp(bssid, '000000000000') % Associated STA
            obj.IsAssociatedSTA = true;
        end
        obj.AID = aid;
        updateBasicRatesAndIndices(obj);
        updateBSSProperties(obj);
    end

    function updateContentionParams(obj, paramName, paramVal)
        %updateContentionParams Update CWMin, CWMax or AIFS parameters

        obj.(paramName) = paramVal;
    end

    function setPrimaryChannelInfo(obj, primaryChannelIdx)
        %setPrimaryChannelInfo Set primary channel index and initialize dependent
        %fields

        obj.PrimaryChannelIndex = primaryChannelIdx;
        numSubchannels = log2(obj.ChannelBandwidth/10);
        % Fill values corresponding to pri20
        obj.Initial20MHzIndices(1) =  obj.PrimaryChannelIndex;

        for idx = 2:numSubchannels % Iterate over sec20, sec40, sec80 and sec160
            % Number of 20 MHz subchannels in 20/40/80/160 subchannels
            subChannelScalingFactor = 2^(idx-2);
            % Get the primary 20/40/80/160 index respectively in each iteration
            primarySubchannelIdx = ceil(obj.PrimaryChannelIndex/subChannelScalingFactor);

            if rem(primarySubchannelIdx, 2) == 1 % Primary 20/40/80/160 index is odd
                % Secondary 20/40/80/160 is above primary 20/40/80/160
                secondarySubChannelIdx = primarySubchannelIdx + 1;
            else
                % Secondary 20/40/80/160 is below primary 20/40/80/160
                secondarySubChannelIdx = primarySubchannelIdx - 1;
            end

            % Assign the starting 20 MHz index of the secondary 20/40/80/160
            obj.Initial20MHzIndices(idx) = (secondarySubChannelIdx-1)*subChannelScalingFactor + 1;
        end
    end

    function idx = getLinkIndex(obj)
        % Return link index

        % In case of non-MLD, each device has a shared MAC and EDCA MAC. Shared MAC
        % holds the context of only corresponding EDCA MAC. Hence, set link index
        % as 1.
        idx = 1;
        if obj.IsAffiliatedWithMLD
            % In MLD, context in shared MAC is maintained for each link. Hence, set the
            % link index as DeviceID. DeviceID indicates ID of the specific link.
            idx = obj.DeviceID;
        end
    end

    function expandPerSTAStatistics(obj, associatedNodeID)
        %expandPerSTAStatistics Appends a structure to the PerSTAStatistics and
        %PerACPerSTAStatistics properties

        perSTAStatistics = obj.PerSTAStatisticsTemplate;
        perSTAStatistics.AssociatedNodeID = associatedNodeID;
        obj.PerSTAStatistics = [obj.PerSTAStatistics perSTAStatistics];

        perACPerSTAStatistics = obj.PerACPerSTAStatisticsTemplate;
        perACPerSTAStatistics.AssociatedNodeID = associatedNodeID;
        obj.PerACPerSTAStatistics = [obj.PerACPerSTAStatistics perACPerSTAStatistics];
    end

    function addMediumSyncDelayInfo(obj, mediumSyncDuration, mediumSyncEDThreshold, mediumSyncMaxTXOPs)
        %addMediumSyncDelayInfo Add medium sync delay information to MAC layer of
        %associated EMLSR STA

        obj.MediumSyncDuration = mediumSyncDuration;
        obj.MediumSyncEDThreshold = mediumSyncEDThreshold;
        obj.MediumSyncMaxTXOPs = mediumSyncMaxTXOPs;
    end

    function setFullBufferTrafficContext(obj, destID)
        %setFullBufferTrafficContext Set context for full buffer traffic

        obj.FullBufferTrafficEnabled = true;
        obj.FullBufferTrafficDestinationID = destID;
    end

    function turnOffLink(obj)
        %turnOffLink Set a flag to indicate transition to INACTIVE_STATE when other
        %link is active

        obj.IsEMLSRLinkMarkedInactive = true;
    end

    function turnOnLink(obj)
        %turnOnLink Set a flag to false to indicate that the link is no longer
        %inactive

        obj.IsEMLSRLinkMarkedInactive = false;
    end

    function sendCFEnd = isTXOPEnoughForCFEnd(obj, excludeIFS)
        % Check if CF-End frame can be transmitted within TXNAV

        sendCFEnd = false;
        [rate, frameLength] = controlFrameRateAndLen(obj, obj.CFEnd);
        txTime = calculateTxTime(obj, obj.NonHT, frameLength, rate, 1, 20); % numSTS = 1, cbw = 20;
        if excludeIFS
            requiredTime = txTime;
        else
            requiredTime = obj.SIFSTime + txTime;
        end
        if requiredTime > 0 && requiredTime <= obj.TXNAVTimer
            sendCFEnd = true;
        end
    end

    function isempty = isQueueEmpty(obj, acIndex)
        % Checks if the transmissions queue are empty. Providing a specific AC
        % index checks if the transmissions queues for that specific AC are empty.

        isempty = true;

        if nargin == 1 % Are all queues empty
            mappedACIndices = getMappedACs(obj);
            % Check link queues
            if any(obj.LinkEDCAQueues.RetryBufferLengths(:, mappedACIndices, 1), 'all') || ...          % Link Retry Queues
                    any(obj.LinkEDCAQueues.TxQueueLengths(:, mappedACIndices), 'all') || ...            % Link Tx Data Queues
                    (any(mappedACIndices == 4) && any(obj.LinkEDCAQueues.TxManagementQueueLengths)) % Link Tx Management Queues
                isempty = false;
            end
            % Check shared queues as well if node is MLD
            if isempty && obj.IsAffiliatedWithMLD
                totalFramesInRetryBuffer = sum(obj.SharedEDCAQueues.RetryBufferLengths, 3);
                numFramesWithTxInProgress = numPacketsWithTxInProgress(obj.SharedEDCAQueues);
                if any(obj.SharedEDCAQueues.TxQueueLengths(:, mappedACIndices), 'all') || ...                                        % Shared Tx Data Queues
                        (any(mappedACIndices == 4) && any(obj.SharedEDCAQueues.TxManagementQueueLengths)) || ...                     % Shared Tx Management Queues
                        any(totalFramesInRetryBuffer(:, mappedACIndices) - numFramesWithTxInProgress(:, mappedACIndices), 'all') % Shared Retry Queues
                    isempty = false;
                end
            end
        else % Is specific AC queue empty
            mappedACIndices = getMappedACs(obj);
            if any(acIndex == mappedACIndices)
                % Check link queues
                if any(obj.LinkEDCAQueues.RetryBufferLengths(:, acIndex, 1)) || ...                 % Link Retry Queues
                        any(obj.LinkEDCAQueues.TxQueueLengths(:, acIndex)) || ...                   % Link Tx Data Queues
                        ((acIndex == 4) && any(obj.LinkEDCAQueues.TxManagementQueueLengths))    % Link Tx Management Queues
                    isempty = false;
                end
                % Check shared queues as well if node is MLD
                if isempty && obj.IsAffiliatedWithMLD
                    totalFramesInRetryBuffer = sum(obj.SharedEDCAQueues.RetryBufferLengths, 3);
                    numFramesWithTxInProgress = numPacketsWithTxInProgress(obj.SharedEDCAQueues);
                    if any(obj.SharedEDCAQueues.TxQueueLengths(:, acIndex)) || ...                                % Shared Tx Data Queues
                            ((acIndex == 4) && any(obj.SharedEDCAQueues.TxManagementQueueLengths)) || ...         % Shared Tx Management Queues
                            any(totalFramesInRetryBuffer(:, acIndex) - numFramesWithTxInProgress(:, acIndex)) % Shared Retry Queues
                        isempty = false;
                    end
                end
            end
        end
    end

    function [isDuplicate, isMLD2MLDCommunication, srcIndex, cacheIndex] = isDuplicateMPDU(obj, rxMPDU, isPartOfAMPDU, acIndex)
        % Check if the input is a duplicate MPDU

        % Initialize
        isDuplicate = false;
        isMLD2MLDCommunication = false;
        cacheIndex = -1;
        rx = obj.Rx; % Handle object
        sharedMAC = obj.SharedMAC;
        srcID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2); % Get ID of the source node and index to access context
        isDataFrame = wlan.internal.utils.isDataFrame(rxMPDU);

        % Duplicate detection
        if obj.IsAffiliatedWithMLD
            srcIndex = find(srcID == [sharedMAC.RemoteSTAInfo(:).NodeID]);
            if sharedMAC.RemoteSTAInfo(srcIndex).IsMLD
                % Frame received at MLD from another MLD
                if isDataFrame
                    [lastRxSeqNum, cacheIndex] = getLastRxSeqNumMLDUnicast(obj, srcID, acIndex-1);
                else
                    [lastRxSeqNum, cacheIndex] = getLastRxSeqNumMLDUnicastManagement(obj, srcID);
                end
                if rxMPDU.Header.Retransmission && any(rxMPDU.Header.SequenceNumber == lastRxSeqNum)
                    isDuplicate = true;
                end
                isMLD2MLDCommunication = true;
            end
        end
        
        srcIndex = blockAckScoreboadIndex(obj, srcID);

        if ~isMLD2MLDCommunication
            if isPartOfAMPDU
                bitmap = rx.BlockAckBitmap(srcIndex, acIndex, 1:obj.BABitmapLength);
                ssn = rx.LastSSN(srcIndex, acIndex);
                rxBitmapIndex = rxMPDU.Header.SequenceNumber-ssn+1;
                isDuplicate = (rxBitmapIndex > 0) && (rxBitmapIndex <= numel(bitmap)) && bitmap(rxBitmapIndex) && (rxMPDU.Header.Retransmission);
            else
                if isDataFrame
                    % Reference: Section-10.3.2.14.3 in IEEE Std 802.11-2020
                    lastRxSeqNum = sharedMAC.RCUnicastDataNonMLD(srcIndex,acIndex);
                else
                    [lastRxSeqNum, cacheIndex] = getLastRxSeqNumNonMLDUnicastManagement(obj, srcID);
                end
                isDuplicate = rxMPDU.Header.Retransmission && (rxMPDU.Header.SequenceNumber == lastRxSeqNum);
            end
        end
    end

    function insertSequenceNumberIntoCache(obj, seqNum, isDataFrame, isMLDSrcToMLDReceiver, srcIndex, index)
        % Inserts given sequence number into relevant cache

        if isMLDSrcToMLDReceiver
            cacheIndex = index;
            if isDataFrame
                obj.SharedMAC.RCUnicastDataMLD{cacheIndex, 3} = seqNum;
            else
                obj.SharedMAC.RCUnicastManagementMLD{cacheIndex, 2} = seqNum;
            end
        else
            if isDataFrame
                acIndex = index;
                obj.SharedMAC.RCUnicastDataNonMLD(srcIndex, acIndex) = seqNum;
            else
                cacheIndex = index;
                obj.SharedMAC.RCUnicastManagementNonMLD{cacheIndex, 2} = seqNum;
            end
        end
    end
end

methods(Access = private)
    function initMACParameters(obj)
        %initMACParameters Initialize MAC layer parameters

        % Set Basic Rates
        updateBasicRatesAndIndices(obj);

        % CTS frame length (14 octets)
        ctsFrameLength = 14;

        cbw = 20; % Bandwidth for CTS transmission
        numSTS = 1; % Number of space time streams

        % CTS frame duration with basic rate
        obj.AckOrCTSBasicRateDuration = calculateTxTime(obj, obj.NonHT, ctsFrameLength, obj.NonHTMCSIndex6Mbps, numSTS, cbw);

        % Timeout for a Non-HT response. Refer section 10.3.2.11 in IEEE Std 802.11-2020
        obj.NonHTResponseTimeout = obj.SIFSTime + obj.SlotTime + obj.PHYRxStartDelayNonHT;

        % Initialize CW value to CWmin
        obj.CW = obj.CWMin;

        % Available channel bandwidth
        obj.AvailableBandwidth = obj.ChannelBandwidth;

        if ~obj.FrameAbstraction
            % MAC configuration for full MAC
            obj.EmptyMACConfig = wlanMACFrameConfig(DisableHexValidation=true);
            obj.EmptyMACTriggerUserConfig = wlanMACTriggerUserConfig;
            obj.EmptyMACManagementConfig = wlanMACManagementConfig;
        end

        % Reference: Table 36-70 of IEEE P802.11be/D5.0
        numSymEHTSIG = 32; % Maximum number of OFDM symbols in EHT SIG
        obj.PHYRxStartDelayEHT = round((32 + 4*numSymEHTSIG)*1e3); % nanoseconds

        % Reference: Section 11.15.9 of IEEE Std 802.11-2020, Section 10.23.2.5 of
        % IEEE Std 802.11-2020 and 2021
        linkIdx = getLinkIndex(obj);
        band = obj.SharedMAC.BandAndChannel(linkIdx, 1);
        % Get the time for which secondary channels must be idle to consider them
        % for transmission
        if band == 2.4
            obj.RequiredSecChannelIdleTime = obj.DIFSTime;
        else
            obj.RequiredSecChannelIdleTime = obj.PIFSTime;
        end
    end

    function updateBasicRatesAndIndices(obj)
        %updateBasicRatesAndIndices Update basic rates and basic rate indices

        if obj.Use6MbpsForControlFrames
            obj.BasicRates = 6;
        end
        dataRateSet = [6 9 12 18 24 36 48 54];
        obj.NonHTMCSIndicesForBasicRates = find(ismember(dataRateSet, obj.BasicRates))-1;
    end

    function checkAndUpdateTBTT(obj, currentTime)
        %checkAndUpdateTBTT Update the TBTT if current simulation time
        %exceeds TBTT

        if obj.TBTT <= currentTime
            linkIdx = getLinkIndex(obj);
            obj.SharedMAC.LastTBTT(linkIdx) = obj.TBTT;
            obj.TBTTAcquired = true;
            obj.TBTT = obj.TBTT + obj.BeaconInterval * 1024e3;
            obj.SharedMAC.NextTBTT(linkIdx) = obj.TBTT;
        end
    end

    function [lastSeqNum, cacheRowIdx] = getLastRxSeqNumMLDUnicast(obj, srcID, ac)
        % Return the last sequence number(s) received from given source node ID in
        % corresponding AC and index to access receiver cache

        lastSeqNum = -1;
        sharedMAC = obj.SharedMAC;
        knownSrcIDs = [sharedMAC.RCUnicastDataMLD{:, 1}];
        if any(srcID == knownSrcIDs)
            srcRowIndices = find(srcID == knownSrcIDs);
            knownACs = [sharedMAC.RCUnicastDataMLD{srcRowIndices, 2}];
            cacheRowIdx = srcRowIndices(ac == knownACs);
            if ~isempty(cacheRowIdx)
                % Cache exists for given source and AC. Get the last received seq num(s)
                % from cache
                lastSeqNum = sharedMAC.RCUnicastDataMLD{cacheRowIdx, 3};
            else
                % Add row in cache for the given source and AC and initialize the last
                % received seq num to -1
                [sharedMAC.RCUnicastDataMLD{end+1, :}] =  deal(srcID, ac, -1);
                cacheRowIdx = size(sharedMAC.RCUnicastDataMLD, 1);
            end
        else
            % Add row in cache for the given source and AC and initialize the last
            % received seq num to -1
            [sharedMAC.RCUnicastDataMLD{end+1, :}] =  deal(srcID, ac, -1);
            cacheRowIdx = size(sharedMAC.RCUnicastDataMLD, 1);
        end
    end

    function [lastSeqNum, cacheRowIdx] = getLastRxSeqNumMLDUnicastManagement(obj, srcID)
        % Return the last sequence number(s) received from given source node ID
        % and index to access receiver cache

        lastSeqNum = -1;
        knownSrcIDs = [obj.SharedMAC.RCUnicastManagementMLD{:, 1}];
        if any(srcID == knownSrcIDs)
            cacheRowIdx = find(srcID == knownSrcIDs);
            % Cache exists for given source and AC. Get the last received seq num(s)
            % from cache
            lastSeqNum = obj.SharedMAC.RCUnicastManagementMLD{cacheRowIdx, 2};
        else
            % Add row in cache for the given source and AC and initialize the last
            % received seq num to -1
            [obj.SharedMAC.RCUnicastManagementMLD{end+1, :}] =  deal(srcID, -1);
            cacheRowIdx = size(obj.SharedMAC.RCUnicastManagementMLD, 1);
        end
    end

    function [lastSeqNum, cacheRowIdx] = getLastRxSeqNumNonMLDUnicastManagement(obj, srcID)
        % Return the last sequence number(s) received from given source node ID
        % and index to access receiver cache

        lastSeqNum = -1;
        knownSrcIDs = [obj.SharedMAC.RCUnicastManagementNonMLD{:, 1}];
        if any(srcID == knownSrcIDs)
            cacheRowIdx = find(srcID == knownSrcIDs);
            % Cache exists for given source and AC. Get the last received seq num(s)
            % from cache
            lastSeqNum = obj.SharedMAC.RCUnicastManagementNonMLD{cacheRowIdx, 2};
        else
            % Add row in cache for the given source and AC and initialize the last
            % received seq num to -1
            [obj.SharedMAC.RCUnicastManagementNonMLD{end+1, :}] =  deal(srcID, -1);
            cacheRowIdx = size(obj.SharedMAC.RCUnicastManagementNonMLD, 1);
        end
    end

    function scoreboardIndex = blockAckScoreboadIndex(obj, sourceID)
        %blockAckScoreboadIndex Return the index to access block ack scoreboard
        %context corresponding to specified source ID

        rx = obj.Rx; % Handle object
        sharedMAC = obj.SharedMAC; % Handle object

        if any(sourceID == rx.BAScoreboardSourceIDs)
            scoreboardIndex = find(sourceID == rx.BAScoreboardSourceIDs);
        else
            rx.BAScoreboardSourceIDs(end+1) = sourceID;
            scoreboardIndex = numel(rx.BAScoreboardSourceIDs);

            isMLD2MLDCommunication = false;
            if obj.IsAffiliatedWithMLD
                srcIndexLogical = (sourceID == [sharedMAC.RemoteSTAInfo(:).NodeID]);
                if sharedMAC.RemoteSTAInfo(srcIndexLogical).IsMLD
                    isMLD2MLDCommunication = true;
                end
            end

            % Create reception context for the source
            if ~isMLD2MLDCommunication
                sharedMAC.RCUnicastDataNonMLD(end+1, :) = 0;
            end
            rx.BlockAckBitmap(end+1, :, :) = 0;
            rx.LastSSN(end+1, :) = -1;
        end
    end

    function setNAV(obj, rx, rxCfg)
        %setNAV Set Intra-NAV or NAV timer when frame not destined to this node is
        %received
        %
        %   setNAV(OBJ, RX, RXCFG) sets:
        %   1. Intra-BSS NAV timer when an frame from same BSS (intra-BSS) is
        %   received.
        %   2. NAV timer when a frame from other BSS (inter-BSS) or frame that
        %   cannot be classified as inter/intra is received.
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   RX is the MAC Rx context object of type wlan.internal.mac.RxContext.
        %
        %   RXCFG is the MAC configuration object of type
        %   wlanMACFrameConfig corresponding to the received frame, in case
        %   of full MAC frame. In case of abstracted MAC frame, it is a
        %   structure containing decoded MAC configuration parameters of
        %   the received frame.

        if strcmp(rxCfg.Header.FrameType, 'QoS Data')
            acIndex = wlan.internal.Constants.TID2AC(rxCfg.Header.TID+1) + 1;
            obj.ReceivedUnicastDataFramesToOthersPerAC(acIndex) = obj.ReceivedUnicastDataFramesToOthersPerAC(acIndex) + 1;
        end

        if wlan.internal.utils.isIntraBSSFrame(obj.BSSColor, obj.BSSID, rx.RxVector, obj.TXOPHolder, rxCfg)

            % Reference: Section 26.2.5 of IEEE Std 802.11ax-2021
            if strcmp(rxCfg.Header.FrameType, 'CF-End')
                obj.IntraNAVTimer = obj.LastRunTimeNS; % Reset to current MAC invoke time
                resetContextOnNAVExpiry(obj);
                % Update statistics
                obj.Statistics.ReceivedCFEndFrames = obj.Statistics.ReceivedCFEndFrames + 1;
            else
                intraNav = round(rxCfg.Header.Duration*1e3); % In nanoseconds
                % Update Intra NAV timer
                if obj.IntraNAVTimer < intraNav + obj.LastRunTimeNS
                    obj.IntraNAVTimer = intraNav + obj.LastRunTimeNS;
                    setTXOPHolderAddressOnIntraNAV(obj, rxCfg);

                    if strcmp(rxCfg.Header.FrameType, 'RTS') || (strcmp(rxCfg.Header.FrameType, 'Trigger') && strcmp(rxCfg.FrameBody.TriggerType, 'MU-RTS'))
                        setRTSNAVResetTimer(obj, rx, rxCfg);
                    end
                end
            end

        else % Received frame is inter-BSS or cannot be classified as inter or intra-BSS
            if strcmp(rxCfg.Header.FrameType, 'CF-End') % Inter BSS
                obj.NAVTimer = obj.LastRunTimeNS; % Reset to current MAC invoke time
                % Update statistics
                obj.Statistics.ReceivedCFEndFrames = obj.Statistics.ReceivedCFEndFrames + 1;
            else
                if (rx.RxVector.BSSColor ~= 0 && obj.BSSColor ~= 0)
                    updateNAV = false;

                    % By default set the 'updateNAV' flag to true for all the response frames
                    % or any frame with RSSI value greater than or equal to OBSS threshold
                    if strcmp(rxCfg.Header.FrameType, 'CTS') || strcmp(rxCfg.Header.FrameType, 'ACK') || ...
                            strcmp(rxCfg.Header.FrameType, 'Block Ack') || rx.RxVector.RSSI >= obj.UpdatedOBSSPDThreshold
                        updateNAV = true;
                    end

                    if strcmp(rxCfg.Header.FrameType, 'CTS')
                        % Time difference between RTS and CTS reception
                        diff = obj.LastRunTimeNS - rx.RTSRxTimestamp;

                        % Do not update the CTS NAV if all the following
                        % conditions are satisfied:
                        % 1. If previously received RTS signal is ignored
                        % following the rules defined in Section 26.10.2.2,
                        % IEEE Std 802.11-2021
                        % 2. CTS is received with in the PIFS time from
                        % previous RTS reception and the received CTS frame
                        % RSSI is less than the OBSS threshold.
                        if (diff < obj.PIFSTime) && rx.RTSRxTimestamp && ~rx.OBSSRTSNAVUpdated && ...
                                (rx.RxVector.RSSI < obj.UpdatedOBSSPDThreshold)
                            updateNAV = false;
                        end

                        % Reset RTS reception timestamp
                        rx.RTSRxTimestamp = 0;

                        % Reset the flag indicating NAV update due to OBSS RTS
                        rx.OBSSRTSNAVUpdated = false;
                    end
                else
                    updateNAV = true;
                end

                if updateNAV
                    % Update NAV timer due to frame received from inter-BSS or cannot be
                    % classified as received from inter or intra.
                    nav = round(rxCfg.Header.Duration*1e3); % In nanoseconds
                    if obj.NAVTimer < nav + obj.LastRunTimeNS
                        obj.NAVTimer = nav + obj.LastRunTimeNS;

                        if strcmp(rxCfg.Header.FrameType, 'RTS') || (strcmp(rxCfg.Header.FrameType, 'Trigger') && strcmp(rxCfg.FrameBody.TriggerType, 'MU-RTS'))
                            setRTSNAVResetTimer(obj, rx, rxCfg);
                            % Set the flag indicating NAV is updated due to an inter-BSS RTS/MU-RTS
                            % frame
                            rx.OBSSRTSNAVUpdated = updateNAV;
                        end
                        if obj.IsAffiliatedWithMLD
                            % Discard last SSN and temporary bitmap records at the end of current TXOP,
                            % if independent scoreboard context is maintained. Reference: Section
                            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever basic
                            % NAV is updated, which indicates TXOP change.
                            resetLastSSNForMLDTxRxPair(obj);
                        end
                    end
                end
            end
        end
    end

    function setTXOPHolderAddressOnIntraNAV(obj, rxCfg)
        % Store TXOP holder address when intra-NAV is set based on received frame

        prevTXOPHolder = obj.TXOPHolder;
        obj.TXOPHolder = rxCfg.Header.Address2;
        if strcmp(rxCfg.Header.FrameType, 'CTS') || strcmp(rxCfg.Header.FrameType, 'ACK') || ...
                strcmp(rxCfg.Header.FrameType, 'Block Ack')
            obj.TXOPHolder = rxCfg.Header.Address1;
        end
        if obj.IsAffiliatedWithMLD && ~strcmp(prevTXOPHolder, obj.TXOPHolder)
            % Discard last SSN and temporary bitmap records at the end of current TXOP,
            % if independent scoreboard context is maintained. Reference: Section
            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
            % holder address is cleared/updated, which indicates TXOP change.
            resetLastSSNForMLDTxRxPair(obj);
        end
    end

    function setRTSNAVResetTimer(obj, rx, rxCfg)
        % Set waiting for NAV reset flag to true to indicate that NAV should be
        % reset to zero when NAV timeout is expired after RTS/MU-RTS transmission.
        rx.WaitingForNAVReset = true;
        rx.RTSRxTimestamp = obj.LastRunTimeNS;
        % Set NAV reset timeout
        % Time after which NAV is allowed to reset. Refer section 10.3.2.4
        % in IEEE Std 802.11ax-2021
        %   In case of RTS NAV reset, CTS duration is calculated using data
        %   rate same as RTS.
        %   In case of MU-RTS NAV reset, CTS duration is calculated using
        %   6Mbps data rate.
        if strcmp(rxCfg.Header.FrameType, 'RTS')
            ctsDuration = calculateTxTime(obj, obj.NonHT, obj.AckOrCtsFrameLength, rx.RxVector.PerUserInfo.MCS, 1, 20); % For NAV reset due to RTS, calculate CTS duration with same rate as RTS
        else % 'MU-RTS'
            ctsDuration = obj.AckOrCTSBasicRateDuration;  % For NAV reset due to MU-RTS, calculate CTS duration with basic rate
        end
        navTimeout = 2*obj.SIFSTime + ctsDuration + obj.PHYRxStartDelayNonHT + 2*obj.SlotTime;
        obj.RTSNAVResetTimer = obj.LastRunTimeNS + navTimeout;
    end

    function setNAVFromRxVector(obj, rxVector)
        %setNAVFromRxVector Set Intra-NAV or NAV timer from TXOP_DURATION in
        %RxVector
        %
        %   setNAVFromRxVector(OBJ, RXVECTOR) sets Intra-NAV or NAV in following
        %   conditions:
        %   1. TXOP_DURATION in RxVector is not unspecified
        %   2. No frame with Duration field is received
        %   3. TXOP_DURATION is greater than current Intra-NAV or NAV
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   RXVECTOR is a structure representing Rx Vector of received PPDU.

        % Refer 'TXOP_DURATION' parameter in Table 36-1 of
        % IEEE P802.11be/D5.0
        if rxVector.PPDUFormat == obj.EHT_SU
            if rem(rxVector.TXOPDuration,2) == 0
                nav = round(((rxVector.TXOPDuration/2)*8)*1e3); % in nanoseconds
            else
                nav = round((512+((rxVector.TXOPDuration-1)/2)*128)*1e3); % in nanoseconds
            end
        else
            % Calculate NAV duration after decoding TXOP_DURATION value
            % obtained from RXVECTOR. This value (denoted by 7 bits,
            % B0-B7) is obtained after PHY decodes the TXOP subfield in
            % HE-SIG-A field. Refer 'TXOP_DURATION' parameter in
            % Table 27-1 of IEEE Std 802.11-2021
            if rxVector.TXOPDuration < 64 % B0 = 0
                nav = round((rxVector.TXOPDuration*8)*1e3); % in nanoseconds
            else % B0 = 1
                nav = round((512+(rxVector.TXOPDuration-64)*128)*1e3); % in nanoseconds
            end
        end
        if wlan.internal.utils.isIntraBSSFrame(obj.BSSColor, obj.BSSID, rxVector, obj.TXOPHolder)
            updatedIntraNAVTimer = obj.LastRunTimeNS + nav;
            % Do not update intra BSS NAV from TXOPDuration in RxVector at TXOP Holder.
            % Refer Section 26.2.4 in IEEE Std 802.11ax-2021
            if (obj.IntraNAVTimer < updatedIntraNAVTimer) && ~isTXOPHolder(obj)
                obj.IntraNAVTimer = updatedIntraNAVTimer;
            end
        else
            if (rxVector.BSSColor ~= 0 && obj.BSSColor ~= 0)
                updateNAV = false;
                if rxVector.RSSI >= obj.UpdatedOBSSPDThreshold
                    % Update NAV. NAV represents inter-NAV when SR
                    % operation is enabled and frame is received
                    % from other BSS.
                    updateNAV = true;
                end
            else
                updateNAV = true;
            end

            updatedNAVTimer = obj.LastRunTimeNS + nav;
            if updateNAV && (obj.NAVTimer < updatedNAVTimer)
                obj.NAVTimer = updatedNAVTimer;
                if obj.IsAffiliatedWithMLD
                    % Discard last SSN and temporary bitmap records at the end of current TXOP,
                    % if independent scoreboard context is maintained. Reference: Section
                    % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever basic
                    % NAV is updated, which indicates TXOP change.
                    resetLastSSNForMLDTxRxPair(obj);
                end
            end
        end
    end

    function flag = isTXOPHolder(obj)
        %isTXOPHolder Check if MAC is TXOP holder

        flag = (~strcmp(obj.TXOPHolder, '000000000000') && strcmp(obj.MACAddress, obj.TXOPHolder));
    end

    function checkForNAVReset(obj, currentTime)
        % Check whether NAV timeout is elapsed after RTS/MU-RTS
        % transmission

        if obj.Rx.WaitingForNAVReset && obj.RTSNAVResetTimer <= currentTime
            % After NAV timeout, the Intra-NAV and NAV timers set due to RTS/MU-RTS
            % frames are no longer valid and hence set as current time. This would mean
            % the timers have already elapsed.
            obj.IntraNAVTimer = currentTime;
            obj.NAVTimer = currentTime;
            obj.Rx.WaitingForNAVReset = false;
            resetContextOnNAVExpiry(obj);
        end
    end

    function isExpired = isNAVTimerExpired(obj, currentTime)
        % Check if NAV timers expired and clear TXOP holder address if
        % expired

        isExpired = false;
        checkForNAVReset(obj, currentTime);
        if (obj.IntraNAVTimer <= currentTime) && (obj.NAVTimer <= currentTime)
            isExpired = true;
        end
    end

    function resetContextOnNAVExpiry(obj)
        % Reset context on intra-BSS NAV expiry

        obj.TXOPHolder = '000000000000';
        if obj.IsAffiliatedWithMLD
            % Discard last SSN and temporary bitmap records at the end of current TXOP,
            % if independent scoreboard context is maintained. Reference: Section
            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
            % holder address is cleared/updated, which indicates TXOP change.
            resetLastSSNForMLDTxRxPair(obj);
        end
    end

    function isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime)
        % Check whether NAV timers are expired and reset context upon intra-NAV
        % timer expiry

        isNAVExpired = isNAVTimerExpired(obj, currentTime);
        if isNAVExpired && ~isTXOPHolder(obj)
            % Clear the TXOP holder address set when unintended frame
            % is received, i.e., current node is not TXOP holder. If
            % current node is TXOP holder, TXOP holder address is
            % cleared at the end of TXOP.
            resetContextOnNAVExpiry(obj);
        end
    end

    function resetLastSSNForMLDTxRxPair(obj)
        % Reset partial bitmap context maintained at MLD receiver for an MLD source

        rx = obj.Rx; % Handle object

        numSrcIDs = numel(rx.BAScoreboardSourceIDs);
        remoteSTAInfo = obj.SharedMAC.RemoteSTAInfo;
        for srcIdx = 1:numSrcIDs
            srcID = rx.BAScoreboardSourceIDs(srcIdx);
            if srcID ~= 0
                transmitterIdxLogical = (srcID == [remoteSTAInfo(:).NodeID]);
                isUnicastMLDTransmitter = remoteSTAInfo(transmitterIdxLogical).IsMLD;
                if obj.IsAffiliatedWithMLD && isUnicastMLDTransmitter
                    rx.BlockAckBitmap(srcIdx, :, :) = 0;
                    rx.LastSSN(srcIdx, :) = -1;
                end
            end
        end
    end

    function incrementQSRCAndCW(obj)
        %incrementQSRCAndCW Increments QSRC and CW for owner AC

        ownerACIdx = obj.OwnerAC + 1;
        obj.QSRC(ownerACIdx) = obj.QSRC(ownerACIdx) + 1;

        % Increment CW until QSRC reaches ShortRetryLimit
        % Reference: Section 10.23.2.2 of IEEE Std 802.11ax Draft 4.1.
        if obj.QSRC(ownerACIdx) < obj.SharedMAC.ShortRetryLimit
            % Increment CW
            obj.CW(ownerACIdx) = min(obj.CW(ownerACIdx)*2+1, obj.CWMax(ownerACIdx));
        else
            % Reset QSRC and CW
            resetQSRCAndCW(obj);
        end
    end

    function resetQSRCAndCW(obj)
        %resetQSRCAndCW Resets QSRC and CW for owner AC

        % Reference: Section 10.23.2.2 of IEEE Std 802.11ax Draft 4.1.
        ownerACIdx = obj.OwnerAC + 1;
        obj.QSRC(ownerACIdx) = 0;
        obj.CW(ownerACIdx) = obj.CWMin(ownerACIdx);
    end

    function rateInfo = checkAndSetHTMIMOMCS(obj, rateInfo)
        if obj.TransmissionFormat == obj.HTMixed
            % Interpret MCS value from NumSTS and given MCS value in HT format
            rateInfo.MCS = ((rateInfo.NumSpaceTimeStreams - 1) * 8) + rateInfo.MCS;
        end
    end

    function isTriggerSent = isTriggerFrameSent(obj)
        % Check whether AP device has sent a trigger frame. Supported trigger
        % frames in the simulation: HE MU PPDU with TRS Control, MU-BAR trigger
        % frame and Basic trigger frame.

        isTriggerSent = false;
        tx = obj.Tx;

        if obj.IsAPDevice
            isTriggerSent = any(tx.LastTxFrameType == [obj.MUBARTrigger obj.BasicTrigger]) || ...
                ((tx.LastTxFrameType == obj.QoSData) && (tx.TxFormat == obj.HE_MU && obj.DLOFDMAFrameSequence == 1));
        end
    end

    function acIndices = getMappedACs(obj)
        % Return the AC indices allowed in this link/device for transmission

        acIndices = 1:4; % By default, all ACs are allowed
        if obj.IsAffiliatedWithMLD
            % Get the ACs mapped to this specific link for transmission
            acIndices = obj.SharedMAC.Link2ACMap{obj.DeviceID} + 1;
        end
    end

    function APToEMLSRSTA = isAPToEMLSRSTATransmission(obj)
        % Return true if an AP MLD is transmitting to an EMLSR STA

        APToEMLSRSTA = false;
        if obj.IsAPDevice && obj.IsAffiliatedWithMLD % AP MLD
            stationID = obj.Tx.TxStationIDs(obj.UserIndexSU);
            remoteSTAInfo = obj.SharedMAC.RemoteSTAInfo;
            if ~(stationID == obj.BroadcastID) && ... % Unicast receiver
                    any(stationID == [remoteSTAInfo(:).NodeID])
                receiverIdxLogical = stationID == [remoteSTAInfo(:).NodeID];
                isUnicastMLDReceiver = remoteSTAInfo(receiverIdxLogical).IsMLD;
                % In case of an AP MLD, get whether the receiver STA MLD is operating in
                % EMLSR mode or STR mode.
                APToEMLSRSTA = isUnicastMLDReceiver && (remoteSTAInfo(receiverIdxLogical).EnhancedMLMode==1); % MLD mode 1 indicates EMLSR
            end
        end
    end

    function maxTxTime = calculateMaxDataTxTime(obj, dlTxSelected, excludeIFS)
        %calculateMaxDataTxTime Calculates the maximum time available for
        %data transmission
        %
        %   MAXTXTIME = calculateMaxDataTxTime(obj, DLTXSELECTED, EXCLUDEIFS)
        %   calculates the time available for a downlink or uplink data
        %   transmission, based on the remaining TXOP duration. It subtracts the
        %   time required for transmitting any protection frames, UL initiating
        %   frames (Basic TF), acknowledgement frames, along with applicable inter
        %   frame spaces.
        %
        %   MAXTXTIME is the maximum available data transmission time
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   DLTXSELECTED specifies whether downlink transmission is being
        %   attempted in the next FES.
        %
        %   EXCLUDEIFS is a logical scalar that indicates whether SIFS/PIFS must be
        %   excluded while determining if a new FES can be initiated. This argument
        %   is set to true when this function is called in these cases: internal
        %   collision, initial FES, non-initial FES at MLD (only when queue length
        %   is less than MSDU count decided in RECEIVERESPONSE_STATE) and
        %   available BW for transmission changed during PIFS recovery. In first
        %   three cases, SIFS is ignored and in the fourth case, PIFS is ignored.

        tx = obj.Tx;
        if obj.TXOPLimit(obj.OwnerAC+1) && obj.TXNAVTimer % If scheduler has been called to resolve internal collision, then TXNAV may not be initialized yet
            maxTxTime = obj.TXNAVTimer;

            if dlTxSelected
                calculateRTSTxTime = tx.ProtectNextFrame; % set in scheduleAndCalculateTxInfo (usual case), or in Wait For Rx (if tx fails from AP to EMLSR STA, have to send ICF in next FES)
                calculateAckTxTime = ~obj.DisableAck;
            else
                calculateRTSTxTime = tx.ProtectNextFrame; % set in scheduleAndCalculateULInfo
                calculateAckTxTime = true;
            end

            if tx.TxStationIDs(1) == obj.BroadcastID
                calculateRTSTxTime = false;
                calculateAckTxTime = false;
            end

            if calculateRTSTxTime
                if (~dlTxSelected) || (tx.TxFormat == obj.HE_MU) || ... % MU-RTS before UL or DL OFDMA
                        (dlTxSelected && isAPToEMLSRSTATransmission(obj)) % MU-RTS as ICF
                    frameType = obj.MURTSTrigger;
                else
                    frameType = obj.RTS;
                end
                [rate, frameLength] = controlFrameRateAndLen(obj, frameType); % MU-RTS or ICF (MU-RTS) is checked within this function
                rtsTxTime = calculateTxTime(obj, obj.NonHT, frameLength, rate, 1, 20); % numSTS = 1, cbw = 20;
                % MU-RTS in MU transmission or ICF frame to EMLSR STA
                if (frameType == obj.MURTSTrigger)
                    ctsTxTime = obj.AckOrCTSBasicRateDuration; % CTS uses 6 Mbps basic rate for MU-RTS.
                else % RTS
                    ctsTxTime = calculateTxTime(obj, obj.NonHT, obj.AckOrCtsFrameLength, rate, 1, 20); % numSTS = 1, cbw = 20;
                end
                % Subtract RTS and CTS transmission times
                maxTxTime = maxTxTime - rtsTxTime - ctsTxTime - 2*obj.SIFSTime; % RTS + SIFS + CTS + SIFS
            end

            % Subtract Ack transmission time
            if calculateAckTxTime
                ackTxTime = getAckDuration(obj, dlTxSelected);
                maxTxTime = maxTxTime - ackTxTime - obj.SIFSTime; % SIFS + Ack

                if dlTxSelected
                    if (tx.TxFormat == obj.HE_MU && obj.DLOFDMAFrameSequence == 2) && ~tx.NoAck
                        % If DL OFDMA frame exchange sequence includes MU-BAR, consider an
                        % additional SIFS and MU-BAR duration
                        [muBarRate, muBarLength] = controlFrameRateAndLen(obj, obj.MUBARTrigger);
                        mubarNumSTS = 1;
                        cbw = 20; % This value would not be used. Bandwidth will be determined internally based on allocation index
                        muBarDuration = calculateTxTime(obj, obj.NonHT, muBarLength, muBarRate, mubarNumSTS, cbw);
                        maxTxTime = maxTxTime - muBarDuration - obj.SIFSTime; % SIFS + MU-BAR
                    end
                end
            end


            if ~dlTxSelected
                % Subtract Basic TF duration
                [rate, basicTriggerLength] = controlFrameRateAndLen(obj, obj.BasicTrigger);
                basicTFTxTime = calculateTxTime(obj, obj.NonHT, basicTriggerLength, rate, 1, 20); % numSTS = 1, cbw = 20
                maxTxTime = maxTxTime - basicTFTxTime - obj.SIFSTime; % SIFS + BasicTF
            end

            if ~excludeIFS
                % Initial wait time before the next FES
                if tx.LastTxFail
                    maxTxTime = maxTxTime - obj.PIFSTime;
                else
                    maxTxTime = maxTxTime - obj.SIFSTime;
                end
            end

            % Maximum allowed PPDU duration is 5484000 nanoseconds,
            % according to standard. Take minimum of calculated time and
            % 5484000
            maxTxTime = min(maxTxTime, 5484000);
            maxTxTime = max(maxTxTime, 0);
        else
            maxTxTime = 5484000; % Maximum duration limit of a PPDU in nanoseconds
        end
    end

    function ackDuration = getAckDuration(obj, dlTxSelected)
        % Return acknowledgment duration

        if dlTxSelected
            tx = obj.Tx;
            txMCS = tx.TxMCS(1:tx.NumTxUsers);
            txNumSTS = tx.TxNumSTS(1:tx.NumTxUsers);
            txFormat = tx.TxFormat;
            txAggMPDU = tx.TxAggregatedMPDU;
            txBW = tx.TxBandwidth;
            if (txFormat == obj.HE_MU) % MU
                cbw = 20; % This value would not be used. Bandwidth will be determined internally based on allocation index
                respMCS = responseMCS(obj, txFormat, cbw, txAggMPDU, txMCS, txNumSTS);
                heTBFrameLengths = wlan.internal.mac.calculateHETBResponseLength(tx.NumTxUsers, obj.BABitmapLength);
                if obj.DLOFDMAFrameSequence == 1 % Frame exchange sequence (DL MU PPDU + TRS control -> UL BA sequence)
                    % Restricting response MCS greater than 3 to MCS index 3 as TRS
                    % Control field support uplink MCS in the range of [0 - 3].
                    respMCS(respMCS > 3) = 3;
                    % Restricting numSTS to 1 for HETB response trigger via TRS control
                    % as per table 26.5.2.3.4 of IEEE Std 802.11ax-2021
                    numSTS = ones(1, tx.NumTxUsers);
                    ackDuration = calculateTxTime(obj, obj.HE_TB, heTBFrameLengths, respMCS, numSTS, 'TRS');
                else
                    ackDuration = calculateTxTime(obj, obj.HE_TB, heTBFrameLengths, respMCS, txNumSTS, 'TriggerFrame');
                end
            else % SU
                % In the case where APEP Length is not calculated yet
                % (hence, MSDU count is zero), and we need to know the
                % maximum available transmission time, assume that next
                % frame is aggregated and calculate block ack tx time
                assumeBlockAck = false;
                if tx.TxMPDUCount(obj.UserIndexSU) == 0
                    assumeBlockAck = true;
                end

                if ((txAggMPDU) && (txFormat == obj.HTMixed)) || any(tx.TxMPDUCount(1:tx.NumTxUsers) > 1) || assumeBlockAck
                    % For aggregated frames acknowledgment is Block Ack
                    if obj.BABitmapLength == 64
                        baFrameLength = 32;
                    elseif obj.BABitmapLength == 256
                        baFrameLength = 56;
                    elseif obj.BABitmapLength == 512
                        baFrameLength = 88;
                    else % obj.BABitmapLength == 1024
                        baFrameLength = 152;
                    end
                    respMCS = responseMCS(obj, txFormat, txBW, txAggMPDU, txMCS, txNumSTS);
                    cbw = 20; % Response is transmitted in Non-HT 20 MHz
                    respNumSTS = 1; % Non-HT used to send Ack/Block Ack so single space-time stream
                    ackDuration = calculateTxTime(obj, obj.NonHT, baFrameLength, respMCS, respNumSTS, cbw);
                else % Non-aggregated MPDU
                    % For non-aggregated frames acknowledgment is Normal Ack
                    ackFrameLength = 14;
                    respMCS = responseMCS(obj, txFormat, txBW, tx.TxAggregatedMPDU, txMCS, txNumSTS);
                    cbw = 20; % Response is transmitted in Non-HT 20 MHz
                    respNumSTS = 1; % Non-HT used to send Ack/Block Ack so single space-time stream
                    ackDuration = calculateTxTime(obj, obj.NonHT, ackFrameLength, respMCS, respNumSTS, cbw);
                end
            end
        else
            % Calculate Multi STA BA duration
            multiSTABALength = controlFrameMPDULength(obj, 'Multi-STA-BA', [], obj.Tx.NumTxUsers, false);
            obj.MultiSTABARate = responseMCS(obj, obj.HE_TB, 20, true, obj.ULMCS, obj.ULNumSTS); % cbw = 20, agg = true
            ackDuration = calculateTxTime(obj, obj.NonHT, multiSTABALength, obj.MultiSTABARate, 1, 20); % numSTS = 1, cbw = 20
        end
    end

    function updateTxNAVTimer(obj)
        % Update Tx NAV timer

        if obj.TXNAVTimer > 0 % Update TXNAV Timer
            obj.TXNAVTimer = obj.TXNAVTimer - obj.ElapsedTime;
        end
    end

    function [continueTXOP, nextFrameType] = decideTXOPStatus(obj, isFailed, excludeIFS)
        %decideTXOPStatus Decide if the current TXOP should be continued or
        %terminated and return the frame type to be transmitted next
        %
        %   [CONTINUETXOP, NEXTFRAMETYPE] = decideTXOPStatus(OBJ, ISFAILED)
        %   decides if the current TXOP should be continued or terminated,
        %   immediately after the end of current FES. If a new frame
        %   exchange sequence can be completed within the remaining TXOP,
        %   it allows the TXOP to continue. It indicates the MAC to
        %   terminate TXOP in the following cases:
        %       *If initial frame in a TXOP failed
        %       *If any RTS frame within a TXOP failed
        %       *If remaining TXOP is not sufficient for the next FES
        %       *If a new frame exchange sequence cannot be scheduled
        %   It also indicates if CF-End frame needs to be transmitted as
        %   the next frame, if TXOP is decided to be terminated.
        %
        %   CONTINUETXOP is a flag indicating whether TXOP must be
        %   continued or terminated. If the flag indicates termination,
        %   NEXTFRAMETYPE specifies if CF-End frame must be sent to
        %   terminate TXOP.
        %
        %   NEXTFRAMETYPE is an enumerated value returned as one of the
        %   following constant values of edcaMAC object: RTS, QoSData,
        %   MURTSTrigger, BasicTrigger, CFEnd.
        %
        %   OBJ is an object of type edcaMAC.
        %
        %   ISFAILED specifies if the last frame transmission failed.
        %
        %   [CONTINUETXOP, NEXTFRAMETYPE] = decideTXOPStatus(OBJ, ISFAILED,
        %   EXCLUDEIFS) decides if the current TXOP should be continued or
        %   terminated, after SIFS gap or PIFS recovery. If available queue
        %   length in a link is less than required MSDU count,
        %   decideTXOPStatus is called once again to decide if TXOP should
        %   be continued or terminated. If available bandwidth for
        %   transmission reduced during PIFS recovery, decideTXOPStatus is
        %   called once again.
        %
        %   EXCLUDEIFS indicates whether SIFS/PIFS wait time must be considered
        %   while calculating if next FES can be completed within remaining TXOP.
        %   If this input is not provided, the function considers this value as
        %   false, which means SIFS/PIFS wait time is considered.

        continueTXOP = false;
        nextFrameType = obj.UnknownFrameType;
        obj.Tx.ContinueMFTXOP = false; % Default
        if obj.TXNAVTimer > 0 % TXOP is still remaining
            if isFailed
                if any(obj.Tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger])
                    % If RTS failed, always end the TXOP, for both initial
                    % or non-initial RTS within a TXOP. No need of CF-End
                    return;
                elseif obj.Tx.IsTXOPInitialFrame % Checking for termination after initial FES fails (QoS Data/Basic TF)
                    % End the TXOP if initial FES fails. Reference: Section
                    % 10.23.2.2 of IEEE Std.802.11 of IEEE Std 802.11-2020
                    sendCFEnd = isTXOPEnoughForCFEnd(obj, false);
                    if sendCFEnd
                        nextFrameType = obj.CFEnd;
                    end
                    return;
                end
            end

            if nargin == 2
                excludeIFS = false;
            end
            isInitialFES = false;
            nextFrameType = scheduleTransmission(obj, isInitialFES, excludeIFS);

            scheduleNextFES = true;
            if (nextFrameType == obj.UnknownFrameType) % No frame transmission is scheduled
                scheduleNextFES = false;
            end

            if scheduleNextFES
                obj.Tx.ContinueMFTXOP = true;
                continueTXOP = true;
            else
                sendCFEnd = isTXOPEnoughForCFEnd(obj, excludeIFS);
                if sendCFEnd
                    nextFrameType = obj.CFEnd;
                end
            end
        end
    end

    function resetContextAfterTXOPEnd(obj)
        % Reset transmission context after ending the current TXOP

        tx = obj.Tx; % obj.Tx is a handle object

        obj.TXNAVTimer = 0; % Reset TXNAV timer
        if strcmp(obj.TXOPHolder, obj.MACAddress)
            % Clear only if current device is still TXOP holder. TXOP holder may be
            % overwritten in current TXOP when intra BSS NAV is set. Do not clear in
            % such cases.
            obj.TXOPHolder = '000000000000';
        end
        obj.ULOFDMAScheduled = false;

        tx.TxStationIDs = 0;
        tx.OFDMAScheduleContext.AllocationIndex = 0;
        tx.OFDMAScheduleContext.UseLowerCenter26ToneRU = false;
        tx.OFDMAScheduleContext.UseUpperCenter26ToneRU = false;
        tx.ProtectNextFrame = false;
        tx.ContinueMFTXOP = false;
        tx.TXOPBandwidth = 0;
        tx.TxBandwidth = 0;
        tx.LastRTSBandwidth = 0;
        tx.FirstNonHTDupBandwidth = 0;
        tx.LastPPDUBandwidth = 0;
        tx.NextTxFrameType = obj.UnknownFrameType;
        tx.LastTxFrameType = obj.UnknownFrameType;

        % Reset power restriction flag and OBSSPD buffer at the end of
        % TXOP. Reference: Section 26.10.2.5 of IEEE Std 802.11ax-2021.
        obj.RestrictSRTxPower = false;
        obj.OBSSPDBuffer = [];

        if obj.IsAffiliatedWithMLD && obj.IsAPDevice
            % Context to be reset at AP MLD
            obj.SharedMAC.CurrentEMLSRTxSTA(obj.DeviceID) = 0;
            obj.SharedMAC.BroadcastTxInProgress(obj.DeviceID) = false;
        end

        resetSchedulerContext(obj.Scheduler);
        resetContextAfterCurrentFES(obj);
    end

    function resetContextAfterCurrentFES(obj)
        % Reset transmission context after the completion of the current
        % frame exchange sequence

        tx = obj.Tx; % obj.Tx is a handle object

        tx.LastTxFail = false;
        tx.IsTXOPInitialFrame = false;
        tx.BWSignaledInRTS = false;
    end

    function updateFreqDepProps(obj, frequency)
        % Update frequency related fields in event structure templates
        obj.TransmissionStartedTemplate.CenterFrequency = frequency;
        obj.TransmissionStarted.CenterFrequency = frequency;
        obj.ReceptionEndedTemplate.CenterFrequency = frequency;
        obj.ReceptionEnded.CenterFrequency = frequency;
        obj.ChangingStateTemplate.CenterFrequency = frequency;
    end

    function buffSize = getMaxBufferSize(obj, stationID)
        %getMaxBufferSize Return the maximum buffer size notified by the station

        buffSizeIndicesLogical = (stationID == obj.STAQueueInfo(:, 1));
        buffSize = max(obj.STAQueueInfo(buffSizeIndicesLogical, 3));
    end

    function rtsRequired = isRTSProtectionRequired(obj, continueTXOP, scheduleStations)
        %isRTSProtectionRequired Return flag to indicate RTS protection is needed for next FES

        tx = obj.Tx;
        if ~continueTXOP
            rtsRequired = ~obj.DisableRTS || isAPToEMLSRSTATransmission(obj);
        else
            % If scheduled destinations change, use RTS protection
            rtsRequired = scheduleStations && ~obj.DisableRTS;
            % If transmission from an AP to an EMLSR STA fails, AP has to send an ICF
            % before starting another transmission
            if tx.LastTxFail && isAPToEMLSRSTATransmission(obj)
                rtsRequired = true;
            end
        end
    end
end

methods(Access=protected)
    function stateChange(obj, newState)
        %stateChange Perform operations related to MAC state transition

        stateExit(obj, obj.MACState);
        stateEntry(obj, newState);
        obj.MACState = newState;
    end

    function stateEntry(obj, macState)
        %stateEntry Perform entry operations of MAC state

        switch macState            
            case obj.RECEIVE_STATE
                obj.NextInvokeTime = Inf; % Wait until further indications are received from PHY

            case obj.NAVWAIT_STATE
                maxNAVTimer = max(obj.NAVTimer, obj.IntraNAVTimer);
                if obj.Rx.WaitingForNAVReset
                    % In case of NAV set due to RTS/MU-RTS frames, wait for minimum of NAV
                    % timeout or maximum of NAV and Intra-NAV timers
                    obj.NextInvokeTime = min(obj.RTSNAVResetTimer, maxNAVTimer);
                else
                    % In case of NAV set due to frames other than RTS/MU-RTS frames, wait until
                    % maximum of NAV and Intra-NAV timers
                    obj.NextInvokeTime = maxNAVTimer;
                end

            case obj.CONTEND_STATE
                % Capture entry timestamp
                obj.StateEntryTimestamp = obj.LastRunTimeNS;
                % Initialize AIFS counters for all ACs
                obj.AIFSSlotCounter = obj.AIFS*obj.SlotTime;
                obj.BackoffInvokeTime = obj.LastRunTimeNS + obj.SIFSTime;
                obj.NextInvokeTime = obj.LastRunTimeNS + min(obj.AIFS)*obj.SlotTime;
                obj.AccumulatedElapsedTime = zeros(1,4);

            case obj.IDLE_STATE
                % Capture entry timestamp
                obj.StateEntryTimestamp = obj.LastRunTimeNS;
                obj.NextInvokeTime = obj.LastRunTimeNS;

            case obj.RECEIVERESPONSE_STATE
                tx = obj.Tx; % obj.Tx is a handle object
                % Capture entry timestamp
                obj.StateEntryTimestamp = obj.LastRunTimeNS;
                % Reset flag
                tx.IgnoreResponseTimeout = false;
                timeout = obj.NonHTResponseTimeout; % Timeout for Non-HT response
                if (tx.LastTxFrameType == obj.QoSData && (tx.TxFormat == obj.HE_MU && obj.DLOFDMAFrameSequence == 1)) || ...
                        ((tx.LastTxFrameType == obj.MUBARTrigger) || (tx.LastTxFrameType == obj.BasicTrigger)) % Expecting a HE-TB response
                    % Timeout for HE-TB response
                    timeout = obj.SIFSTime + obj.SlotTime + obj.PHYRxStartDelayHETB;
                end
                % Set timer for response timeout
                tx.WaitForResponseTimer = obj.LastRunTimeNS + timeout;

                if isTriggerFrameSent(obj)
                    % To turn on phy Rx after SIFS after transmitting a trigger frame, i.e.
                    % frame with TRS Control in sequence 1 or MU-BAR trigger frame in sequence
                    % 2, set the next invoke time.
                    obj.NextInvokeTime = obj.LastRunTimeNS + obj.SIFSTime;
                else
                    obj.NextInvokeTime = tx.WaitForResponseTimer;
                end
                tx.NumResponses = 0;

            case obj.ERRORRECOVERY_STATE
                if obj.Tx.DoPIFSRecovery
                    obj.NextInvokeTime = obj.LastRunTimeNS + obj.PIFSTime;
                else
                    obj.NextInvokeTime = obj.EIFSTimer;
                end

            case obj.INACTIVE_STATE
                % Capture entry timestamp
                obj.StateEntryTimestamp = obj.LastRunTimeNS;
                % Turn off the PHY receiver
                switchOffPHYRx(obj);
                % Capture the timestamp at which link is switching off CCA by turning off
                % phy receiver
                obj.LinkTurnOffTimestamp = obj.LastRunTimeNS;
                % Active EMLSR link moving to INACTIVE_STATE to handle transition delay
                if obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID)
                    % Switch back to number of listen antennas
                    obj.NumReceiveAntennas = obj.NumEMLSRListenAntennas;
                    if ~isempty(obj.SetNumRxAntennasFcn)
                        obj.SetNumRxAntennasFcn(obj.NumReceiveAntennas);
                    end
                    % Invoke after transition delay
                    obj.NextInvokeTime = obj.LastRunTimeNS + obj.SharedMAC.EMLTransitionDelay;
                else
                    obj.NextInvokeTime = Inf;
                end
                % Reset context
                obj.Rx.LastRxFrameTypeNeedingResponse = obj.UnknownFrameType;
                obj.Rx.ResponseFrame = [];

            case obj.EMLSRRECEIVE_STATE
                % Invoke after timeout to receive PHY-RxStart after responding to ICF.
                % Timeout = SIFS time + slot time + PHY Rx Start delay.
                obj.NextInvokeTime = obj.LastRunTimeNS + (obj.SIFSTime + obj.SlotTime + obj.PHYRxStartDelayEHT);
                obj.Rx.IgnoreReceiveTimeout = false; % Wait for receive timeout and reset this if any RxStart is received

            case obj.TRANSMIT_STATE
                % Stop PHY receiver
                switchOffPHYRx(obj);
                tx = obj.Tx;

                % Determine MAC sub-state
                if any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger]) && ... % Last frame is RTS/MU-RTS
                        any(tx.NextTxFrameType == [obj.QoSData obj.Management obj.BasicTrigger]) % Next frame is QoS Data or Basic trigger or a Management frame
                    % Wait for SIFS before transmitting next frame after
                    % RTS-CTS exchange
                    obj.MACSubstate = obj.WAITINGFORSIFS_SUBSTATE;
                    obj.NextInvokeTime = obj.LastRunTimeNS + obj.SIFSTime;
                elseif tx.DoPIFSRecovery % PIFS recovery completed before moving to TRANSMIT_STATE
                    % Transmit directly as PIFS recovery completed
                    obj.MACSubstate = obj.TRANSMIT_SUBSTATE;
                    obj.NextInvokeTime = obj.LastRunTimeNS;
                elseif tx.ContinueMFTXOP || (tx.NextTxFrameType == obj.CFEnd)
                    % Wait for SIFS to continue TXOP or end TXOP using
                    % CF-End frame
                    obj.MACSubstate = obj.WAITINGFORSIFS_SUBSTATE;
                    obj.NextInvokeTime = obj.LastRunTimeNS + obj.SIFSTime;
                else
                    obj.MACSubstate = obj.TRANSMIT_SUBSTATE;
                    obj.NextInvokeTime = obj.LastRunTimeNS;
                end

            case obj.TRANSMITRESPONSE_STATE
                obj.MACSubstate = obj.WAITINGFORSIFS_SUBSTATE;
                obj.NextInvokeTime = obj.LastRunTimeNS + obj.SIFSTime;
        end
    end

    function stateExit(obj, macState)
        %stateExit Perform exit operations of MAC state

        switch macState
            case obj.RECEIVE_STATE
                % Reset flag
                obj.SROpportunityIdentified = false;

            case obj.TRANSMITRESPONSE_STATE
                obj.Rx.IsBWSignalingTAPresent = false;

            case obj.CONTEND_STATE
                % Reset flag
                obj.IsLastTXOPHolder = false;
                % Trigger event to indicate contention completion
                if obj.HasListener.StateChanged
                    stateChanged = obj.StateChangedTemplate;
                    stateChanged.DeviceID = obj.DeviceID;
                    stateChanged.State = "Contention";
                    stateChanged.Duration = round((obj.LastRunTimeNS - obj.StateEntryTimestamp)/1e9, 9);
                    obj.EventNotificationFcn('StateChanged', stateChanged);
                end

            case obj.IDLE_STATE
                % Trigger event to indicate IDLE_STATE completion
                if obj.HasListener.StateChanged
                    stateChanged = obj.StateChangedTemplate;
                    stateChanged.DeviceID = obj.DeviceID;
                    stateChanged.State = "Idle";
                    stateChanged.Duration = round((obj.LastRunTimeNS - obj.StateEntryTimestamp)/1e9, 9);
                    obj.EventNotificationFcn('StateChanged', stateChanged);
                end

            case obj.TRANSMIT_STATE
                % Start PHY Receiver after transmission of a frame except in the following
                % cases.
                % 1. Data frame with TRS Control in DL OFDMA sequence 1
                % 2. MU-BAR trigger frame in DL OFDMA sequence 2
                % 3. Basic trigger frame sent
                % 4. Data frame with no response from EMLSR STA
                % The reason to keep the receiver off for 1, 2 and 3 cases
                % is to prevent decoding the non HE-TB frames while waiting
                % for TB frames. The reason for 4th case is data frame with
                % no ack is considered as end of frame exchange sequence.
                % And receiver must continue in off after frame exchange
                % sequence until transition delay.
                if (~obj.IsEMLSRSTA && ~isTriggerFrameSent(obj)) || ...
                        (obj.IsEMLSRSTA && ((obj.Tx.LastTxFrameType == obj.RTS) || (obj.Tx.LastTxFrameType == obj.QoSData && ~obj.Tx.NoAck)))
                    switchOnPHYRx(obj);
                end
                % Reset after sending data/null frame response to Basic trigger frame
                obj.Rx.LastRxFrameTypeNeedingResponse = obj.UnknownFrameType;

            case obj.RECEIVERESPONSE_STATE
                obj.Tx.ExpectedAckType = 0;

            case obj.EMLSRRECEIVE_STATE
                % Reset flag
                obj.SROpportunityIdentified = false;
                obj.Rx.IgnoreReceiveTimeout = true;

            case obj.INACTIVE_STATE
                obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) = false;
        end
    end

    function allocateBandwidthForTXOP(obj)
        %allocateBandwidthForTXOP Determines available bandwidth for the TXOP

        if obj.TBTTAcquired && (obj.OwnerAC == 3)
            obj.Tx.TXOPBandwidth = 20; % Transmit Beacon in 20 MHz
        else
            useLastCCAIdle2BusyDuration = false; % Set this to false to calculate the CCA idle duration from current time
            obj.Tx.TXOPBandwidth = totalBWBasedOnSecondaryChannelCCA(obj, useLastCCAIdle2BusyDuration);
        end
    end

    % Return number of address fields present in MAC header
    function numAddrFields = numAddressFieldsInHeader(obj, isGroupcast)

        if isGroupcast
            % Group addressed data frames have 3 address fields
            numAddrFields = 3;
        else
            if obj.IsMeshDevice % Mesh node
                % Individually addressed mesh data frames have 4 address fields
                numAddrFields = 4;
            else % Non-mesh node
                numAddrFields = 3;
            end
        end
    end

    function updateBSSProperties(obj)
        % Initialize the initial OBSS threshold value and update BSSColor
        % based on EnableSROperation
        if obj.EnableSROperation
            obj.UpdatedOBSSPDThreshold = obj.OBSSPDThreshold;
        else
            obj.UpdatedOBSSPDThreshold = -82;
        end
    end

    function numFrames = numTxFramesAvailable(obj, acIndex, staID, queueObj, retryBufferIdx)
        if nargin == 1
            % Return number of available Tx frames for all STAs (transmission queue +
            % retry buffer) for all mapped ACs

            % Shared queues
            mappedACIndices = getMappedACs(obj);
            totalNumFrames = obj.SharedEDCAQueues.TxQueueLengths(:, :) + ...                                        % Data queue
                sum(obj.SharedEDCAQueues.RetryBufferLengths, 3) - numPacketsWithTxInProgress(obj.SharedEDCAQueues); % Retry buffer
            numFrames = nnz(totalNumFrames(:, mappedACIndices));

            % Link queues
            numFrames = numFrames + nnz(obj.LinkEDCAQueues.TxQueueLengths(:, :) + ...
                obj.LinkEDCAQueues.RetryBufferLengths(:, :, 1));

        elseif nargin == 2
            % Return number of available Tx frames for all STAs (transmission queue +
            % retry buffer) for given AC

            % Shared queues
            numFramesWithTxInProgress = numPacketsWithTxInProgress(obj.SharedEDCAQueues);
            totalFramesInRetryBuffer = sum(obj.SharedEDCAQueues.RetryBufferLengths, 3);
            % Number of frames in retry buffer which are waiting for transmission
            numFramesInSharedQ = nnz(totalFramesInRetryBuffer(:, acIndex) - numFramesWithTxInProgress(:, acIndex));
            if ~numFramesInSharedQ % No frames in retry buffers
                numFramesInSharedQ = sum(obj.SharedEDCAQueues.TxQueueLengths(:, acIndex)); % Total number of frames for all STAs
            end

            % Link queues
            numFramesInLinkQ = sum([obj.LinkEDCAQueues.RetryBufferLengths(:, acIndex, 1)]);
            if ~numFramesInLinkQ % No frames in retry buffer
                numFramesInLinkQ = sum(obj.LinkEDCAQueues.TxQueueLengths(:, acIndex)); % Total number of frames for all STAs
            end

            numFrames = numFramesInSharedQ + numFramesInLinkQ;

        else % nargin >= 3
            % Return number of available Tx frames specific to a STA (retry buffer (or)
            % transmission queue with preference to retry buffer) for a given AC in the
            % specified queue

            staIdxLogical = (staID == getDestinationIDs(queueObj));

            if retryBufferIdx == 0
                numFrames = queueObj.TxQueueLengths(staIdxLogical, acIndex);
                if acIndex == 4
                    numFrames = numFrames + queueObj.TxManagementQueueLengths(staIdxLogical);
                end
            else
                numFrames = queueObj.RetryBufferLengths(staIdxLogical, acIndex, retryBufferIdx);
            end
        end
    end

    function [queueObj, isSharedQ] = getQueueObj(obj, stationID, acIdx)
        % Return the queue object to access for the given station ID and AC along
        % with queue index and flag indicating shared or link queues

        isSharedQ =  true;
        queueObj = findStationACQueue(obj.SharedEDCAQueues, stationID, acIdx);
        if isempty(queueObj)
            queueObj = findStationACQueue(obj.LinkEDCAQueues, stationID, acIdx); % Match if link queue is present for station ID and AC. If not, return empty
            isSharedQ =  false;
        end
    end

    function [discardedNodeIndices, discardedACIndices, discardedSeqNums, varargout] = discard(obj, isSharedQ, queueObj, varargin)
        %discard Discard MSDUs from queues due to lifetime expiry or retry limit
        %exhaust or transmission success
        %
        %   discard(OBJ, ISSHAREDQ, QUEUEOBJ) discards the MSDUs in all
        %   transmission queues and retry buffers, whose frame retry counter has
        %   reached ShortRetryLimit or MSDU lifetime has expired..
        %
        %   ISSHAREDQ is a logical scalar indicating whether the QUEUEOBJ is the
        %   shared queue or per-link queue.
        %
        %   QUEUEOBJ is a handle object of type wlan.internal.mac.QueueManager.
        %
        %   ISDISCARDED = discard(..., NODEIDLIST, ACLIST, RETRYBUFFERINDEXLIST)
        %   discards the MSDUs in the queues represented by NODEIDLIST, ACLIST and
        %   RETRYBUFFERINDEXLIST. MSDU is discarded if its frame retry counter has
        %   reached ShortRetryLimit or its lifetime has expired.
        %
        %   ISDISCARDED is a logical array where each element represents whether
        %   packet is discarded or not. Each two dimensional array corresponds to
        %   packets in retry buffers of a specific node. Each element indicates
        %   whether the packet in corresponding retry buffer is discarded or not.
        %
        %   NODEIDLIST is an array of IDs of nodes for which packets must be
        %   discarded.
        %
        %   ACLIST is an array of access category indices corresponding to the node
        %   IDs from which packets must be discarded.
        %
        %   RETRYBUFFERINDEXLIST is an array of retry buffer indices corresponding
        %   to nodes for which packets must be discarded.
        %
        %   ISDISCARDED = discard(..., NODEID, AC, RETRYBUFFERINDEX,
        %   DISCARDINDICES) discards the MSDUs at given indices in the given
        %   queues. Also discards the MSDUs whose frame retry counter has reached
        %   ShortRetryLimit or MSDU lifetime has expired.
        %
        %   DISCARDINDICES is an array containing the indices of packets to be
        %   discarded corresponding to node ID and AC.

        if ~isempty(varargin)
            [discardedNodeIndices, discardedACIndices, discardedSeqNums, varargout{1}] = discard(queueObj, obj.LastRunTimeNS, varargin{:});
        else
            [discardedNodeIndices, discardedACIndices, discardedSeqNums] = discard(queueObj, obj.LastRunTimeNS);
        end

        % If discardedNodeIndices has all zeros, it means no packets are discarded
        % for any node. Update transmission window only if discardedNodeIndices has
        % at least one non-zero value and packets are discarded from unicast
        % queues. Queues at index 1 are for broadcast.
        if any(discardedNodeIndices~=0) && any(discardedNodeIndices~=1)
            updateTxWindowStatusIfDiscarded(obj, queueObj, discardedNodeIndices, discardedACIndices, discardedSeqNums);
        end

        % Check if full buffer traffic is configured and fill the queue
        if obj.FullBufferTrafficEnabled && any(discardedNodeIndices~=0)
            checkFullBuffer(obj, isSharedQ, queueObj, discardedNodeIndices, discardedACIndices);
        end
    end

    function checkFullBuffer(obj, isSharedQ, queueObj, discardedNodeIndices, discardedACIndices)
        %checkFullBuffer Check if full buffer traffic is configured and fill the
        %queue

        for idx = 1:numel(discardedNodeIndices)
            if (discardedNodeIndices(idx) ~= 0) % Valid node index
                destNodeIDs = getDestinationIDs(queueObj);
                destNodeID = destNodeIDs(discardedNodeIndices(idx));
                if isSharedQ
                    mac = obj.SharedMAC;
                else
                    mac = obj;
                end
                destIdx = find(destNodeID == obj.FullBufferTrafficDestinationID);

                if ~isempty(destIdx) && (discardedACIndices(idx) == obj.FullBufferTrafficACIndex)
                    % Full buffer traffic is configured for the given destination and given AC.
                    % Currently, full buffer traffic can be configured only for AC0.
                    while ~isQueueFull(mac, destNodeID, discardedACIndices(idx)-1)
                        obj.PushPacketToQueueFcn(destIdx, discardedACIndices(idx));
                    end
                end
            end
        end
    end

    function updateTxWindowStatusIfDiscarded(obj, queueObj, discardedNodeIndices, discardedACIndices, discardedSeqNums)
        %updateTxWindowStatusIfDiscarded Updates status of sequence numbers in
        %transmission window corresponding to a receiver, AC pair

        destNodeIDs = getDestinationIDs(queueObj);
        for idx = 1:numel(discardedNodeIndices)
            if (discardedNodeIndices(idx) ~= 0) % Valid node index
                seqNums = discardedSeqNums(idx,:);
                if any(seqNums ~= -1) % Valid discarded sequence numbers are present. -1 indicates invalid value.
                    destNodeID = destNodeIDs(discardedNodeIndices(idx));
                    updateBATxWindowStatus(obj.SharedMAC, destNodeID, discardedACIndices(idx), seqNums(seqNums~=-1));
                end
            end
        end
    end

    function resetMSDTimer(obj)
        % Reset medium sync delay (MSD) timer of an EMLSR link

        % Reset to current MAC invoke time which means the MediumSyncDelayTimer is
        % no longer valid after this time.
        obj.MediumSyncDelayTimer = obj.LastRunTimeNS;
        % Reset the count of TXOPs that are initiated since the start of this timer
        obj.NumMediumSyncTXOPs = 0;
        if ~isempty(obj.MSDTimerResetFcn)
            obj.MSDTimerResetFcn();
        end
    end

    function switchOnPHYRx(obj)
        % Turn on PHY receiver
        obj.PHYMode.PHYRxOn = true;
        if ~isempty(obj.SetPHYModeFcn)
            obj.SetPHYModeFcn(obj.PHYMode);
        end
    end

    function switchOffPHYRx(obj)
        % Turn off PHY receiver
        obj.PHYMode.PHYRxOn = false;
        if ~isempty(obj.SetPHYModeFcn)
            obj.SetPHYModeFcn(obj.PHYMode);
        end
    end

    % Note that MPDUDecoded event will be removed in a future release. Use the
    % ReceptionEnded event instead. Register for the ReceptionEnded
    % notification by using the 'registerEventCallback' function of wlanNode.
    function notifyPHYFailInMPDUDecoded(obj, ppduInfo, cbw)
        % Notify about PHY decode failure in MPDUDecoded event
        mpduDecoded = obj.MPDUDecoded;
        mpduDecoded.PHYDecodeFail = true;
        mpduDecoded.DeviceID = obj.DeviceID;
        mpduDecoded.PPDUStartTime = ppduInfo.StartTime; % In seconds
        mpduDecoded.Frequency = ppduInfo.CenterFrequency; % In Hz
        mpduDecoded.Bandwidth = cbw; % In Hz
        obj.EventNotificationFcn('MPDUDecoded', mpduDecoded);
    end

    % Note that MPDUGenerated event will be removed in a future release. Use the
    % TransmissionStarted event instead. Register for the TransmissionStarted
    % notification by using the 'registerEventCallback' function of wlanNode.
    function notifyMPDUGenerated(obj, frame, frameBW)
        % Notify MPDUGenerated event

        mpduGenerated = obj.MPDUGenerated;
        % Convert to double to prevent arithmetic operations on unlike datatypes
        % inside binaryToDecimal method
        frameBits = double(frame);
        frameLen = numel(frameBits)/8;
        frameDec = zeros(frameLen,1);
        idx = 1;
        for i = 1:frameLen
            frameDec(i) = obj.binaryToDecimal(frameBits(idx:idx+7));
            idx = idx+8;
        end
        mpduGenerated.MPDU = {frameDec};
        mpduGenerated.DeviceID = obj.DeviceID;
        mpduGenerated.Frequency = wlan.internal.utils.getPacketCenterFrequency(obj.OperatingFrequency, ...
            obj.ChannelBandwidth, obj.PrimaryChannelIndex, frameBW, obj.CandidateCentFreqOffset);

        obj.EventNotificationFcn('MPDUGenerated', mpduGenerated);
    end
end

methods
    function value = get.EnableSROperation(obj)
        value = false;
        % Enable SR operation when BSSColor property is set to a non-zero value,
        % frame format is single user HE, and is not a mesh device
        if (obj.BSSColor ~= 0) && (obj.TransmissionFormat == obj.HE_SU || obj.TransmissionFormat == obj.HE_EXT_SU || obj.TransmissionFormat == obj.EHT_SU) && ~obj.IsMeshDevice
            value = true;
        end
    end

    function set.OperatingFrequency(obj, frequency)
        obj.OperatingFrequency = frequency;
        updateFreqDepProps(obj, frequency);
    end
end

methods(Static)
    function decimalVal = binaryToDecimal(binaryVal)
        % Convert binary to decimal

        decimalVal = 0;
        mul = 1;
        for idx = 1:numel(binaryVal)
            decimalVal = decimalVal + mul*binaryVal(idx);
            mul = mul*2;
        end
    end
end
end
