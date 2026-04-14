classdef (Abstract) PHYRx < handle
%PHYRx Define WLAN physical layer Receiver interface class
%   The class acts as a base class for all the physical layer types. It
%   defines the interface to physical layer at Receiving side. It
%   declares the properties and methods to be used by higher layers to
%   interact with the physical layer.

%   Copyright 2022-2025 The MathWorks, Inc.

% Public, tunable properties
properties
    %NodeID Node identifier of the receiving WLAN node
    %   Specify the node ID as a scalar integer value greater than 0.
    %   The default value is 1.
    NodeID = 1;

    %EDThreshold Energy detection threshold in dBm
    %   Specify the ED threshold as a scalar negative value. It is used
    %   as a threshold for the received signal power in order to start
    %   decoding the signal and indicate CCABUSY to MAC layer. The
    %   default value is -82 dBm.
    EDThreshold = -82;

    %RxGain receiver gain in dB
    %   Specify the receiver gain as a scalar double value. It is used in
    %   applying the receiver gain on the power of the received WLAN
    %   signal. The default value is 0 dB.
    RxGain = 0;

    %NoiseFigure Noise figure in dB
    %   Specify the receiver noise figure as a non-negative scalar value in dB.
    %   The default value is 7 dB.
    NoiseFigure = 7;

    %BSSColor Basic service set (BSS) color identifier
    %   Specify the BSS color number of a basic service set as an integer
    %   scalar between 0 to 63, inclusive. The default is 0. This property
    %   is applicable when EnableSROperation is set to true.
    BSSColor = 0;

    %OBSSPDThreshold OBSS PD threshold
    %   Specify OBSS PD Threshold in dBm as a scalar in the range [-62 -82].
    %   The default value is -82.
    OBSSPDThreshold = -82;

    %DeviceID Identifier of device containing PHY
    %   Specify the device identifier containing PHY layer as an integer
    %   scalar starting from 1.
    DeviceID = 1;

    %EventNotificationFcn Function handle to notify the node about event
    %trigger
    %   Specify the function handle to notify the node about event trigger.
    EventNotificationFcn = [];
end

% PHY receiver configuration objects
properties (Access = protected)
    % NonHTConfig Non-HT configuration object
    NonHTConfig;

    % HTConfig HT configuration object
    HTConfig;

    % VHTConfig VHT configuration object
    VHTConfig;

    % OFDMA user index
    UserIndex = 1;

    % NumSubchannels number of 20 MHz subchannels of PHY receiver
    NumSubchannels = 1;
end

properties (Constant, Hidden, Access = protected)
    % Maximum number of users in a Rx MU-PPDU.
    MaxMUUsers = 74;

    %UserIndexSU User index for single user processing. Index '1' will be
    %used in case of single user and downlink multi-user reception. Indices
    %greater than '1' will be used in case of downlink multi-user
    %transmission and uplink multi-user reception.
    UserIndexSU = 1;
end

properties (Constant)
    % Shared stages of receiver state machine
    WaitForWaveform = 0;
    Preamble = 1;
    Header = 2;
    Payload = 3;
    Extension = 4;
    Cleanup = 5;
end

properties (Hidden)
    % Received waveform
    Signal;

    % SignalDecodeStage Decoding stage of the WLAN waveform reception
    % 0 - Waveform processing not started
    % 1 - Process the end of preamble
    % 2 - Process the end of SIG field
    % 3 - Process the end of actively received payload / MPDU in an AMPDU
    % 4 - End of padding/extension period if present - send RXEND indication
    % 5 - End of waveform duration and so signal has to be removed
    SignalDecodeStage;

    % Interference manager object
    Interference;

    %MaxReceiveAntennas Total number of receive antennas
    MaxReceiveAntennas = 1;
end

% Information specific to a WLAN signal currently being decoded
properties (Access = protected)
    %RxDataLength Received data length in bytes
    RxDataLength = 0;

    %RxFrameFormat WLAN frame format of the signal being decoded
    RxFrameFormat;

    %PrimaryChannelCCAIdle CCA idle flag of primary channel. This will be
    %set to true when primary channel is idle, i.e. No energy detected in
    %the primary channel
    PrimaryChannelCCAIdle = true;

    %NextProcessingTime Time (in nanoseconds) at which preamble and
    %header or payload of a WLAN waveform is to be decoded. When preamble &
    %header is being received, it contains the time till end of that
    %preamble. While receiving a subframe / payload, it contains the
    %corresponding end time.
    NextProcessingTime = Inf;

    %NextReceptionEndTimeAfterRxEnd Time for receiving remaining waveform
    %(in nanoseconds). Occurs after an RXEND indication has been
    %triggered.
    NextReceptionEndTimeAfterRxEnd = Inf;

    %PPDUFiltered Boolean value, used to indicate that during the
    %reception of the PPDU, the PPDU was dropped/filtered out on some
    %condition
    PPDUFiltered = false;

    %RxSignalPower Stores the signal power of the waveform being decoded in
    %dBm
    RxSignalPower = -Inf;
end

properties (Hidden)
    % Flag to indicate whether receiver antenna is on
    RxOn = true;

    % Structure of Rx-Vector
    RxVector;

    % Structure holding indication to MAC
    DefaultIndicationToMAC;

    % Structure holding the MAC frame and its metadata
    DefaultFrameToMAC;

    % Structure from MAC to configure the PHY Rx mode.
    PHYMode = wlan.internal.utils.defaultPHYMode;

    % LastRunTimeNS Timestamp (in nanoseconds) when the PHY receiver is last
    % invoked by the node. This gets updated every time the PHY runs.
    LastRunTimeNS = 0;

    % Maximum number of subframes that can be present in an A-MPDU
    MaxSubframes = 64;

    % Frequency of operation in Hz
    OperatingFrequency = 5.18e9;

    % Channel bandwidth
    ChannelBandwidth = 20;

    %ChannelBandwidthStr Channel bandwidth in string format
    ChannelBandwidthStr = 'CBW20';

    %IsSTA Flag to indicate that the device is a STA
    IsSTA = false;

    %IsAP Flag to indicate that the device is a AP
    IsAP = false;

    %AID Association identifier
    %   Specify the property as a scalar or vector of integers between 0 to
    %   2006, 2045, or 2046. 0 indicates contiguous RA-RUs for associated
    %   stations. 2045 indicates contiguous RA-RUs for unassociated stations.
    %   2046 indicates unallocated RU. This value is assigned by the AP to
    %   STA during association. For AP, it is a vector of integers
    %   corresponding to AID of each associated STA. For STA, it is a scalar
    %   corresponding to associated AP.
    AID;

    %HasListener Structure with event names as field names containing flags
    %indicating whether they have a listener
    HasListener = wlan.internal.utils.defaultEventList;
end

% Properties related to spatial reuse and PPDU filtering operations
properties (Hidden)
    %RxBSSColor BSS color decoded from the received waveform
    RxBSSColor = 0;

    %RxUplinkIndication Uplink indication decoded from the received waveform
    RxUplinkIndication = false;

    %RxSTAID Station ID decoded from the received waveform
    RxSTAID;

    % TXOPDuration is the duration information for TXOP protection. This
    % parameter represents the TXOP field value in the HE-SIG-A field. It
    % is an integer scalar between 0 and 127, inclusive. This value is
    % obtained by converting the duration in microseconds to map with the
    % [0, 127] range as specified in Table 27-18 of IEEE Std 802.11ax-2021.
    TXOPDuration = 127;

    % Set to true by the MAC to indicate an opportunity. When received
    % frame is decoded as Inter-BSS frame and the signal power is less than
    % OBSSPDThreshold.
    SROpportunityIdentified = false;

    % Spatial reuse flag
    EnableSROperation = false;
end

% MLO - EMLSR properties
properties (Hidden)
    % Flag indicating ED Threshold specified during medium synchronization
    % recovery must be used
    UseMSDEDThreshold = false;

    % MediumSyncEDThreshold ED threshold value to use during medium
    % synchronization recovery. Reference for below default is Section
    % 35.3.16.8.2 of IEEE P802.11be/D5.0
    MediumSyncEDThreshold = -72;

    % Number of antennas to use for reception in EMLSR mode
    NumReceiveAntennas = 1;
end

% Properties used for modeling dynamic bandwidth channel access (DBCA)
properties (Hidden)
    % Center frequncy of primary channel in Hz
    PrimaryChannelFrequency = 5.180*1e9; % Default same as default OperatingFrequency in RxInterface

    % Index of primary channel within channel map
    PrimaryChannelIndex = 1;

    % Current Per20Bitmap state of receiver
    CurrentPer20Bitmap = false;
end

% PHY receiver statistics
properties (GetAccess = public, SetAccess = protected)
    %EnergyDetectionsBelowEDThreshold Number of PHY energy detections less than
    %ED threshold
    EnergyDetectionsBelowEDThreshold = 0;

    %ReceiveTriggersWhileReception Number of PHY Rx triggers while
    %previous Rx is in progress
    ReceiveTriggersWhileReception = 0;

    %ReceiveTriggersWhileTransmission Number of PHY Rx triggers while Tx is in
    %progress
    ReceiveTriggersWhileTransmission = 0;

    %PreambleDecodeFailures Total number of preamble failures
    PreambleDecodeFailures = 0;

    %HeaderDecodeFailures Number of PHY header decode failures
    HeaderDecodeFailures = 0;

    %ReceivedPackets Number of packets received
    ReceivedPackets = 0;

    %ReceivedPayloadBytes Number of bytes received to PHY
    ReceivedPayloadBytes = 0;

    %DroppedPackets Number of packets dropped
    DroppedPackets = 0;

    %PhyNumInterFrames Number of inter-BSS frames
    PhyNumInterFrames = 0;

    %PhyNumIntraFrames Number of intra-BSS frames
    PhyNumIntraFrames = 0;

    %MUPPDUsDestinedToOthers Total number of multi-user PPDU destined to
    %others
    MUPPDUsDestinedToOthers = 0;

    %ReceivedMUPPDUs Total number of multi-user PPDUs received
    ReceivedMUPPDUs = 0;
end

% Interference statistics
properties (GetAccess = public, SetAccess = protected)
    %TotalSignalCollisions Number of signals which experienced collision
    %from other signals
    TotalSignalCollisions = 0

    %CollisionsWithOnlyNonWLANSignal Number of signals which experienced
    %collision in time domain with only non-WLAN signals
    CollisionsWithOnlyNonWLANSignal = 0

    %CollisionsWithOnlyWLANSignal Number of signals which experienced
    %collision in time domain with only WLAN signals
    CollisionsWithOnlyWLANSignal = 0

    %CollisionsWithBoth Number of signals which experienced
    %collision in time domain with both WLAN and non-WLAN signals
    CollisionsWithBoth = 0

    %CoChannelInterferenceCount Number of signals which experienced
    %co-channel interference
    CoChannelCollisionsCount = 0

    %PreambleCollisionsWithNonWLAN Number of signals which experienced
    %collisions at preamble only with non WLAN signals
    PreambleCollisionsWithNonWLAN = 0;

    %HeaderCollisionsWithNonWLAN Number of signals which experienced
    %collisions at header only with non WLAN signals
    HeaderCollisionsWithNonWLAN = 0;

    %PayloadCollisionsWithNonWLAN Number of signals which experienced
    %collisions at payload only with non WLAN signals
    PayloadCollisionsWithNonWLAN = 0;

    %PreambleAndHeaderCollisionsWithNonWLAN Number of signals which
    %experienced collisions at both preamble and header with non WLAN
    %signals
    PreambleAndHeaderCollisionsWithNonWLAN = 0;

    %HeaderAndPayloadCollisionsWithNonWLAN Number of signals which
    %experienced collisions at both header and payload with non WLAN
    %signals
    HeaderAndPayloadCollisionsWithNonWLAN = 0;

    %PreambleAndPayloadCollisionsWithNonWLAN Number of signals which
    %experienced collisions at both preamble and payload with non WLAN
    %signals
    PreambleAndPayloadCollisionsWithNonWLAN = 0;

    %PreambleHeaderAndPayloadCollisionsWithNonWLAN Number of signals which
    %experienced collisions at preamble, header and payload with non WLAN
    %signals
    PreambleHeaderAndPayloadCollisionsWithNonWLAN = 0;
end

% Constant Properties
properties(Constant, Hidden)
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

    % Packet is empty
    PacketTypeEmpty = wlan.internal.Constants.PacketTypeEmpty;

    % Packet contains IQ samples as data (Full MAC + Full PHY)
    DataTypeIQData = wlan.internal.Constants.DataTypeIQData;

    % Packet contains MAC frame bits as data (Full MAC + ABS PHY)
    DataTypeMACFrameBits = wlan.internal.Constants.DataTypeMACFrameBits;

    % Packet contains MAC configuration structure as data (ABS MAC + ABS PHY)
    DataTypeMACFrameStruct = wlan.internal.Constants.DataTypeMACFrameStruct;

    % PHY primitives
    CCAIndication = wlan.internal.PHYPrimitives.CCAIndication;
    RxStartIndication = wlan.internal.PHYPrimitives.RxStartIndication;
    RxEndIndication = wlan.internal.PHYPrimitives.RxEndIndication;
    RxErrorIndication = wlan.internal.PHYPrimitives.RxErrorIndication;
    TxStartRequest = wlan.internal.PHYPrimitives.TxStartRequest;
    UnknownIndication = wlan.internal.PHYPrimitives.UnknownIndication;
end

% PHY receiver events
properties (SetAccess = protected)
    StateChangedTemplate; % Structure tracking state change for statistics
end

methods
    % Constructor
    function obj = PHYRx
    % Perform one-time calculations, such as computing constants

        obj.SignalDecodeStage = obj.WaitForWaveform;

        % Initialize the structures frame to MAC, Rx vector, metadata, and
        % signal to default values
        obj.DefaultFrameToMAC = wlan.internal.utils.defaultMACFrame;
        obj.RxVector = wlan.internal.utils.defaultTxVector;
        obj.DefaultIndicationToMAC = wlan.internal.utils.defaultIndicationToMAC;

        obj.Signal = wirelessPacket;

        % Type field is added to the wireless packet to allow for deprecation. The
        % Type field will be removed from wireless packet in the future releases
        % and it is suggested to use the TechnologyType field of the wireless
        % packet to fill the type of technology using the constants in
        % wnet.TechnologyType.
        obj.Signal.Type = obj.Signal.TechnologyType;
        obj.Signal.Metadata = wlan.internal.utils.defaultMetadata(obj.RxVector);

        % Initialize PHY configuration objects common to both abstract and full PHY
        obj.VHTConfig = wlanVHTConfig();
        obj.HTConfig = wlanHTConfig();

        % Initialize to default structures
        obj.StateChangedTemplate = struct('DeviceID', obj.DeviceID, ...
            'CurrentTime', 0, 'State', "Reception", 'Duration', 0, ...
            'Frequency', 0, 'Bandwidth', 0);
    end

    % Set ED Threshold
    function set.EDThreshold(obj, value)
        obj.EDThreshold = value;
    end

    % Reset CCA
    function indicationToMAC = resetPHYCCA(obj)
    %resetPHYCCA Reset the PHY CCA indication

        obj.SROpportunityIdentified = true; % MAC has identified a SR opportunity
        indicationToMAC = getIndicationToMAC(obj);
    end

    function phyRxStats = statistics(obj)
    %statistics Return PHY receiver statistics
    
        phyRxStats = struct;
        phyRxMetrics = obj.getMetricsList();
        for statIdx = 1:numel(phyRxMetrics)
            phyRxStats.(phyRxMetrics{statIdx}) = obj.(phyRxMetrics{statIdx});
        end
    end

    function addConnection(obj, deviceType, aid, bssColor)
    %addConnection Add connection information of associated device

        if strcmp(deviceType, "STA")
            obj.AID = aid;
            obj.BSSColor = bssColor;
        elseif strcmp(deviceType, "AP")
            if isempty(obj.AID) % AP device/link with one associated STA
                obj.AID = aid;
            elseif any(aid ~= obj.AID) % Add new AIDs for multiple associated STAs
                obj.AID = [obj.AID aid];
            end
        end
    end

    function msdTimerStart(obj, msdOFDMEDThreshold)
        %msdTimerStart Handle actions at medium sync delay (MSD) timer start

        obj.UseMSDEDThreshold = true;
        obj.MediumSyncEDThreshold = msdOFDMEDThreshold;
    end

    function msdTimerReset(obj)
        %msdTimerReset Handle actions at MSD timer reset

        obj.UseMSDEDThreshold = false;
    end

    function updateNumActiveRxAntennas(obj, numAntennas)
        % Callback from MAC. Update the number of active receive antennas
        % for modeling EMLSR scenarios

        obj.NumReceiveAntennas = numAntennas;
    end

    function setPrimaryChannelInfo(obj, primaryChannelIndex, primaryChannelFrequency)
        %setPrimaryChannelInfo Add primary channel index and primary
        %channel frequency information to phyRx

        obj.PrimaryChannelIndex = primaryChannelIndex;
        obj.PrimaryChannelFrequency = primaryChannelFrequency; % In Hz
    end
end

methods (Static)
    function availableMetrics = getMetricsList()
    %getMetricsList Return the available metrics at PHY receiver
    %
    %   AVAILABLEMETRICS is a cell array containing all the available
    %   metrics at the PHY receiver

    availableMetrics  = {'ReceivedPackets', 'ReceivedPayloadBytes', 'DroppedPackets'};
    end
end

methods (Access = protected)
    function nextInvokeTime = getNextInvokeTime(obj)
    %getNextInvokeTime Return next invoke time

        nextInvokeTime = Inf;
        currentTimeInSeconds = round(obj.LastRunTimeNS*1e-9,9);
        timeUntiNextInterferenceEvent = bufferChangeTime(obj.Interference, currentTimeInSeconds);
        nextInterferenceEventTime = round(timeUntiNextInterferenceEvent*1e9) + obj.LastRunTimeNS; % whole nanosecond

        if nextInterferenceEventTime ~= Inf && obj.SignalDecodeStage ~= obj.WaitForWaveform
            nextInvokeTime = min(obj.NextProcessingTime, nextInterferenceEventTime);  % whole nanosecond
        elseif nextInterferenceEventTime ~= Inf
            nextInvokeTime = nextInterferenceEventTime;
        elseif obj.SignalDecodeStage ~= obj.WaitForWaveform
            nextInvokeTime = obj.NextProcessingTime; % whole nanosecond
        end
    end

    function indicateStateTransition(obj, wlanSignal)
    %indicateStateTransition Indicate transition to reception state with waveform duration

        % Total duration of the waveform
        ppduDuration = wlanSignal.Duration;

        % Trigger event to indicate signal reception
        if obj.HasListener.StateChanged
            stateChanged = obj.StateChangedTemplate;
            stateChanged.DeviceID = obj.DeviceID;
            stateChanged.State = "Reception";
            stateChanged.Duration = ppduDuration; % seconds
            obj.EventNotificationFcn('StateChanged', stateChanged);
        end
    end

    function filterPPDUWhenBSSColorMismatches(obj)
        %filterPPDUWhenBSSColorMismatches Checks if PPDU can be filtered based
        %on BSSColor

        % BSSColor based filtering. Applicable for HE_SU, HE_EXT_SU, HE_MU, HE_TB,
        % EHT_SU, EHT_MU formats
        if any(obj.RxFrameFormat==[obj.HE_SU obj.HE_EXT_SU obj.HE_MU obj.HE_TB obj.EHT_SU obj.EHT_MU])
            % Filter PPDU if the spatial reuse feature is enabled and the received PPDU
            % can be ignored. Reference: IEEE 802.11ax-2021 Figure 27.63 - PHY receive
            % state machine.
            if obj.BSSColor == 0 || obj.RxBSSColor == 0
                return;
            end

            % Update PHY Rx statistics
            if obj.BSSColor ~= obj.RxBSSColor
                obj.PhyNumInterFrames = obj.PhyNumInterFrames + 1;
                obj.PPDUFiltered = true;
            else % Frame is intra-BSS
                obj.PhyNumIntraFrames = obj.PhyNumIntraFrames + 1;
            end
        end
    end

    function filterPPDUWhenULorDLNotIntended(obj)
        %filterPPDUWhenULorDLNotIntended Checks if PPDU can be filtered based
        %on UplinkIndication.

        % DL/UL indication based filtering. Applicable for EHT_SU, and
        % EHT_MU formats. Refer PHY Receive state machine, Figure 27-63 of
        % IEEE Std 802.11ax-2021 and Figure 36-80 of IEEE P802.11be/D5.0.
        if any(obj.RxFrameFormat == [obj.EHT_SU obj.EHT_MU])
            if obj.RxUplinkIndication % Received an uplink frame
                if obj.IsSTA % Receiver is a STA
                    obj.PPDUFiltered = true;
                end
            else % Downlink frame
                if obj.IsAP % Receiver is an AP (Do not filter for mesh)
                    obj.PPDUFiltered = true;
                end
            end
        end
    end

    function stationIDMatchLogical = filterPPDUWhenSTAIDMismatches(obj)
        %filterPPDUWhenSTAIDMismatches Checks if PPDU can be filtered based
        %on STAID.
        %
        %   STATIONIDMATCHLOGICAL = filterPPDUWhenSTAIDMismatches(OBJ) checks whether
        %   PPDU can be filtered based on STAID check. If PPDU is not filtered, the
        %   function returns a logical scalar or vector (for MU frames),
        %   STATIONIDMATCHLOGICAL, specifying if the PHY's stored AID/NodeID,
        %   matches against the received PPDU's STAID. If PPDU is filtered,
        %   STATIONIDMATCHLOGICAL is empty.

        stationIDMatchLogical = [];
        % STAID based filtering. Applicable for HE_MU, EHT_SU, EHT_MU formats.
        % Additionally, HE_TB is allowed since STAID information is unavailable in
        % abstract PHY signals. NodeID is used for filtering in this case.
        if any(obj.RxFrameFormat == [obj.HE_MU obj.HE_TB obj.EHT_SU obj.EHT_MU])
            % If UL OFDMA, check if recovered station IDs match node ID
            if obj.RxFrameFormat == obj.HE_TB
                filterID = obj.NodeID;
            else % Use AID for HE_MU, EHT_SU, EHT_MU formats, otherwise NodeID
                if ~isempty(obj.AID) % Associated AP/STA
                    % In downlink PPDUs, AID of STA is matched against station ID to
                    % know if packet is intended for the STA. In uplink PPDUs, AID of all
                    % associated STAs is matched against station ID to know if packet is
                    % intended for the AP.
                    filterID = obj.AID;
                else % Unassociated/Mesh (AID unavailable)
                    filterID = obj.NodeID;
                end
            end

            % If a downlink HEMU frame is received by an AP, both filterID and RxSTAID
            % will be vectors. AP stores AID of its associated STAs, so filterID (AID
            % in this case) will be a vector. Similarly, for transmitted HEMU frames,
            % RxSTAID field will contain AIDs of all receiving STAs. Since ismember
            % call adds performance overhead, using ismember call only for this corner
            % case.
            if obj.IsAP && (obj.RxFrameFormat == obj.HE_MU || obj.RxFrameFormat == obj.EHT_MU)
                stationIDMatchLogical = ismember(filterID, obj.RxSTAID);
            else
                stationIDMatchLogical = (filterID == obj.RxSTAID);
            end
            obj.PPDUFiltered = ~any(stationIDMatchLogical);
        end
    end

    function indicationToMAC = getIndicationToMAC(obj)
    %getIndicationToMAC Return indication to MAC

        indicationToMAC = obj.DefaultIndicationToMAC;
        subChannelSignalPowerIndBm = getTotalSignalPower(obj);

        % If there is no signal being processed and there are active
        % interference (and non-WLAN waveform), or if MAC has identified a
        % spatial reuse opportunity then perform ED
        if (obj.SignalDecodeStage==obj.WaitForWaveform && any(subChannelSignalPowerIndBm>-Inf)) || obj.SROpportunityIdentified
            offsetEDThreshold = 20; % By default ED threshold for non-WLAN waveform is 20 dB (100 in linear) higher than WLAN waveform
            if obj.UseMSDEDThreshold
                % Reference: Section 35.3.16.8.2 of IEEE P802.11be/D5.0
                % Calculate offset (in dB) of MSD ED threshold from ED threshold. Scaling
                % based on BW cancels out (MSD ED Threshold + scaling - (-82 + scaling))
                offsetEDThreshold = obj.MediumSyncEDThreshold + 82;
            end
            energyThreshold = obj.EDThreshold + offsetEDThreshold;
        else
            % Otherwise always use the PD threshold
            energyThreshold = obj.EDThreshold;
        end

        % ED threshold for each 20 MHz subchannel
        subChannelEDThreshold = energyThreshold - 3 * log2(obj.NumSubchannels); % ED threshold is scaled down 3 dB if doubling the number of subchannels

        % Generate per20bitmap using the current power measure
        per20BitmapMeasure = subChannelSignalPowerIndBm >= subChannelEDThreshold;
        isCCAStatusChanged = ~all(per20BitmapMeasure == obj.CurrentPer20Bitmap);
        if isCCAStatusChanged
            if  any((obj.CurrentPer20Bitmap - per20BitmapMeasure) == 1) && ...
                    ((obj.SignalDecodeStage == obj.Preamble) || (obj.SignalDecodeStage == obj.Header))
                % Power of any subchannel has dropped below ED threshold
                % during the preamble or header processing - indicating
                % carrier lost, give RX-ERROR indication to MAC and perform
                % CCA-ED at current time during clean-up stage, see PHY
                % receive state machine, Figure 19-27, IEEE Std 802.11-2024
                indicationToMAC = handleInvalidPreamble(obj, indicationToMAC);

                % Not updating the per20MHz power measure info for now -
                % the updates will be at the next call along with the CCA
                % indication
                return
            else
                % Issue CCA indication as the CCA status has changed
                indicationToMAC.MessageType = obj.CCAIndication;

                % Update the current per20Bitmap if the CCA state per 20
                % MHz has changed
                obj.CurrentPer20Bitmap = per20BitmapMeasure;
                indicationToMAC.Per20Bitmap = per20BitmapMeasure;
            end
        end

        % Handle primary channel
        primChanSignalPowerIndBm = subChannelSignalPowerIndBm(obj.PrimaryChannelIndex);
        if obj.PrimaryChannelCCAIdle
            % If the total signal power is greater than or equal to
            % ED threshold, indicate CCA Busy to MAC
            if (primChanSignalPowerIndBm >= subChannelEDThreshold)
                obj.PrimaryChannelCCAIdle = false;
            end
        else
            if (primChanSignalPowerIndBm < subChannelEDThreshold)
                if obj.SignalDecodeStage == obj.Payload && ~obj.SROpportunityIdentified
                    % This is a special case - carrier lost happens in the
                    % middle of payload and SR opportunity not spotted,
                    % phyRx tries best to recover the payload therefore
                    % continue processing (NOT issue any Indication for
                    % now, instead issuing RxEndIndication at the end of
                    % payload)
                    indicationToMAC.MessageType = obj.UnknownIndication;
                    return
                end

                if obj.SignalDecodeStage == obj.Payload && obj.SROpportunityIdentified
                    % MAC is requesting CCARESET primitive and the current
                    % power is below ED threshold during payload stage

                    % Issue CCA indication immediately
                    obj.NextProcessingTime = obj.LastRunTimeNS;

                    % For HE-TB frames, there is no STA_ID field in the
                    % TxVector. At PHY, we use this information to filter
                    % unintended packets. The StationID in TxVector is
                    % populated with NodeID (source ID), and the same is
                    % used for filtering at PHY.
                    indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;
                end

                % If the primary channel is less than ED threshold now,
                % indicate CCA idle to MAC - this is for the special case
                % of handling the carrier lost happening in the middle of
                % payload as above
                indicationToMAC.MessageType = obj.CCAIndication;

                % Reset the SROpportunityIdentified to false and this will
                % be set to true when MAC identifies a SR opportunity
                % calling resetCCA
                obj.SROpportunityIdentified = false;

                % Low power in primary channel - set CCA state to idle 
                % Page 657 of IEEE Std 802.11ax-2021, Second Paragrah: PHY
                % shall maintain CCA-Busy primitive for the prediction of
                % RXTIME..., 'unless it receives a PHY-CCA.request
                % primitive before the end of PPDU during SR operation as
                % described in 26.10'
                obj.PrimaryChannelCCAIdle = true;
            end
        end
    end

    function indicationToMAC = handleCarrierLost(obj, indicationToMAC)
        %handleCarrierLost handle the carrier lost primitive during the payload stage
        % Set carrierlost in RxEndStatus and issue RxEndIndication(RxEndStatus) at the end of PSDU as in Figure 27-63, IEEE Std 802.11ax-2021
        indicationToMAC = setRxEndIndication(obj, indicationToMAC);
        % Reuse StationID field present in vector to store the source node ID
        indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;
        % Remove signal and reset
        obj.SignalDecodeStage = obj.Cleanup;
        % Drop the packet
        obj.DroppedPackets = obj.DroppedPackets + 1;
    end

    function indicationToMAC = setRxErrorIndication(obj, indicationToMAC)
        %Set the MessageType and PPDUStartTime fields in indication to MAC to
        %RxErrorIndication and SOI start time respectively
        indicationToMAC.MessageType = obj.RxErrorIndication;
        % Pass PPDU start time to MAC in RxError indication
        indicationToMAC = setPPDUStartTime(obj, indicationToMAC);
        % Pass center frequency of the received waveform to MAC in RxError
        % indication
        indicationToMAC.PPDUInfo.CenterFrequency = obj.Signal.CenterFrequency; % In Hz
    end

    function indicationToMAC = setRxEndIndication(obj, indicationToMAC)
        %Set the MessageType and PPDUStartTime fields in indication to MAC to
        %RxEndIndication and SOI start time respectively
        indicationToMAC.MessageType = obj.RxEndIndication;
        % Pass PPDU start time to MAC in RxEnd indication
        indicationToMAC = setPPDUStartTime(obj, indicationToMAC);
        % Pass center frequency of the received waveform to MAC in RxEnd
        % indication
        indicationToMAC.PPDUInfo.CenterFrequency = obj.Signal.CenterFrequency; % In Hz
    end

    function indicationToMAC = handleInvalidPreamble(obj,indicationToMAC)
        %handleInvalidPreamble handle the event of preamble is invalid during the preamble or header stage
        if (obj.SignalDecodeStage == obj.Preamble) || (obj.SignalDecodeStage == obj.Header)
            % Issue RxError as RxStartIndication is not issued yet
            indicationToMAC = setRxErrorIndication(obj,indicationToMAC);
        else
            % When the sample rate changes during the payload stage, we
            % need to re-synchronize the preamble portion. As a result, the
            % preamble may become invalid - issue RxEndIndication since
            % RxStartIndication has already been sent
            indicationToMAC = setRxEndIndication(obj,indicationToMAC);
        end
        % Reuse StationID field present in vector to store the source node ID
        indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;
        % Update the decoded failure statistic
        if obj.SignalDecodeStage == obj.Preamble
            obj.PreambleDecodeFailures = obj.PreambleDecodeFailures + 1;
        else % Header stage
            obj.HeaderDecodeFailures = obj.HeaderDecodeFailures + 1;
        end
        % Drop the packet
        obj.DroppedPackets = obj.DroppedPackets + 1;
        % Remove signal and reset
        obj.SignalDecodeStage = obj.Cleanup;
        obj.NextProcessingTime = obj.LastRunTimeNS;
    end
end

methods (Abstract)
    %run physical layer receive operations for a WLAN node and returns the
    %next invoke time, indication to MAC, and frame to MAC
    %
    %   [NEXTINVOKETIME, INDICATIONTOMAC, FRAMETOMAC] = run(OBJ,
    %   CURRENTTIME, SIGNAL) receives and processes the waveform
    %
    %   NEXTINVOKETIME is the next event simulation time, in nanoseconds,
    %   when this method must be invoked again.
    %
    %   INDICATIONTOMAC is an output structure to be passed to MAC layer
    %   with the Rx indication (CCA/RxStart/RxEnd/RxErr). This
    %   output structure is valid only when its field MessageType is set to
    %   value other than wlan.internal.PHYPrimitives.UnknownIndication.
    %
    %   FRAMETOMAC is an output structure to be passed to MAC layer. An
    %   empty value is returned when there is nothing to pass to MAC layer.
    %
    %   CURRENTTIME is the current simulation time in nanoseconds.
    %
    %   SIGNAL is an input structure which contains the signal received.
    %   When not valid an empty matrix/signal is expected.
    [nextInvokeTime, indicationToMAC, frameToMAC] = run(obj, currentTime, signal)

    %get the total power of the signal of interest and the interference in
    %dBm
    totalSignalPowerIndBm = getTotalSignalPower(obj)

    %set the PPDU start time in the indication to MAC
    indicationToMAC = setPPDUStartTime(obj, indicationToMAC)
end
end
