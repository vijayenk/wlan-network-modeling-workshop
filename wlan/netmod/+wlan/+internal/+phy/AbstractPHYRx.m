classdef AbstractPHYRx < wlan.internal.phy.PHYRx
%AbstractPHYRx Create a handle object for abstract WLAN PHY receiver
%   WLANPHYRX = AbstractPHYRx creates a handle object for abstract WLAN PHY
%   receiver.
%
%   WLANPHYRX = AbstractPHYRx(Name, Value) creates a handle object for
%   abstract WLAN PHY receiver with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   AbstractPHYRx methods:
%
%   run         - Run the physical layer receive operations
%   setPHYMode  - Handle the PHY mode set request from the MAC layer
%
%   AbstractPHYRx properties:
%
%   NodeID                - Node ID of the receiving WLAN device
%   EDThreshold           - Energy detection threshold in dBm
%   RxGain                - Receiver gain in dB
%   BSSColor              - Basic service set (BSS) color identifier
%   OBSSPDThreshold       - OBSS PD threshold
%   DeviceID              - Identifier of device containing PHY
%   EventNotificationFcn  - Function handle to notify the node about event trigger
%   AbstractionType       - PHY abstraction type
%   NoiseFigure           - Noise figure in dB
%   SubcarrierSubsampling - Factor to subsample active subcarriers

%   Copyright 2022-2025 The MathWorks, Inc.

properties
    %AbstractionType PHY abstraction type
    %   Specify the PHY abstraction as either of the two strings,
    %   'abstract-phy-tgax-evaluation-methodology',
    %   'abstract-phy-tgax-mac-calibration'.
    AbstractionType = 'abstract-phy-tgax-evaluation-methodology';

    %SubcarrierSubsampling Factor to subsample active subcarriers. The
    %default is 1 (no subsampling)
    SubcarrierSubsampling = 1;
end

properties (Access = private)
    % Index of the subframes being processed for each user
    RxSubframeNumber;

    % Number of subframes for each user
    NumSubframes;

    % RU information
    RUInfo;

    % Store signal reception start time and used to determine if multiple
    % signals are part of an UL-OFDMA transmission
    SignalReceptionStartTime = -1;

    % Store reception start time of the frame (subframe or header/preamble)
    % to be abstracted in nanoseconds for each signal/user. This is used by
    % the interference buffer as the start time of the interference window
    % to consider when abstracting a frame.
    FrameReceptionStartTime = [];

    % Store packet end time
    PacketEndTime = -1;

    % Simulation time at the end of each subframe
    % (NumSubframes-by-NumUsers)
    SubframeEndTimes;

    % Total uplink signal power in dBm
    TotalULSignalPower = -Inf;

    % Vector of indices into the interference buffer containing UL-OFDMA
    % signals
    ULSignalBufferIndex = [];

    SOIChannel = struct('Cached',false,'PathFilters',0,'TimingOffset',0,'PathGains',0,'UserTxIndex',0);

    % Cache of OFDM info
    NonHTOFDMInfo;
    VHTPreambleOFDMInfo;
    HEPreambleOFDMInfo;
    VHTDataOFDMInfo;
    HESUDataOFDMInfo;
    HEMUDataOFDMInfo;
    NonHTOFDMInfoBandwidth;
    VHTOFDMInfoBandwidth;
    HESUOFDMInfoBandwidth;
    HEMUOFDMInfoBandwidth;
    HEOFDMInfoRUInfo;
    EHTPreambleOFDMInfo;
    EHTSUDataOFDMInfo;

    DefaultAbstractionSignal = struct("SourceID",0,"Config",[],"Field","Preamble","RxPower",0,"RUIndex",-1,"PathGains",0,"PathFilters",0);
    EmptyAbstractionSignal;

    % Logical indicating a pre-computed probability of packet segment
    % success can be used when processing each user
    UsePacketErrProbCache;

    % Pre-computed probability of packet segment success for each user
    PacketErrProbCache;

    % Frame to MAC buffered to be passed at a later simulation time
    FrameToMAC;

    % Simulation time in nanoseconds that an HE TB trigger request expires.
    % We expect an HE TB packet reception to start by this time.
    TriggerRequestExpiryTime = -Inf;

    % HESUConfig HE-SU configuration object
    HESUConfig;

    % HEMUConfig HE-MU configuration object
    HEMUConfig;

    % HETBConfig HE-TB configuration object
    HETBConfig;

    %EHTSUConfig EHT-SU configuration object
    EHTSUConfig;
end

properties (Dependent, Access = private)
    AbstractionTypeTGaxAppendix1
end

methods
    % Constructor
    function obj = AbstractPHYRx(varargin)
        % Perform one-time calculations, such as computing constants

        % Name-value pairs
        for idx = 1:2:numel(varargin)
            obj.(varargin{idx}) = varargin{idx+1};
        end

        % Create interference buffer which assumes any time overlap is
        % interference regardless of frequency
        obj.NumSubchannels = obj.ChannelBandwidth/20; % Maximum number of subchannels of current receiver
        obj.Interference = wnet.internal.interferenceBuffer(DisableValidation=true, ...
            CenterFrequency=obj.OperatingFrequency, Bandwidth=obj.ChannelBandwidth*1e6, SampleRate=obj.ChannelBandwidth*1e6, ...
            InterferenceModeling="non-overlapping-adjacent-channel", NumReceiveAntennas=obj.MaxReceiveAntennas, Abstraction=true);

        % Initialize the CCA per 20 MHz
        obj.DefaultIndicationToMAC.Per20Bitmap = false(obj.NumSubchannels,1); % Per20Bitmap is size obj.NumSubchannels-by-1
        obj.CurrentPer20Bitmap = false(obj.NumSubchannels,1);

        obj.UsePacketErrProbCache = false(1,obj.MaxMUUsers);
        obj.PacketErrProbCache = zeros(1,obj.MaxMUUsers);

        obj.HEMUConfig = wlanHEMUConfig(192);

        cbwstr = wlan.internal.utils.getChannelBandwidthStr(obj.ChannelBandwidth);
        obj.EHTSUConfig = wlanEHTMUConfig(cbwstr);
        if obj.ChannelBandwidth < 320
            obj.HETBConfig = wlanHETBConfig('ChannelBandwidth', cbwstr);
            obj.HESUConfig = wlanHESUConfig('ChannelBandwidth', cbwstr);
        end

        obj.EmptyAbstractionSignal = repmat(obj.DefaultAbstractionSignal,1,0);

        % Initialize as structure to allow 320 MHz
        obj.NonHTConfig = wlanNonHTConfig('ChannelBandwidth',cbwstr);

        % Default cache OFDM info
        obj.NonHTOFDMInfo = wlan.internal.vhtOFDMInfo('NonHT-Data','CBW20');
        obj.NonHTOFDMInfoBandwidth = 20;

        obj.VHTPreambleOFDMInfo = wlan.internal.vhtOFDMInfo('L-SIG','CBW20');
        obj.VHTDataOFDMInfo = wlan.internal.vhtOFDMInfo('VHT-Data','CBW20');
        obj.VHTOFDMInfoBandwidth = 20;

        obj.HEPreambleOFDMInfo = wlan.internal.heOFDMInfo('L-SIG','CBW20');
        obj.HESUDataOFDMInfo = wlan.internal.heOFDMInfo('HE-Data','CBW20');
        obj.HESUOFDMInfoBandwidth = 20;

        obj.HEMUDataOFDMInfo = wlan.internal.heOFDMInfo('HE-Data','CBW20');
        obj.HEMUOFDMInfoBandwidth = 20;
        obj.HEOFDMInfoRUInfo = [-1 -1];
        obj.HEMUDataOFDMInfo = [];
    end

    function val = get.AbstractionTypeTGaxAppendix1(obj)
        val = ~strcmp(obj.AbstractionType,'abstract-phy-tgax-mac-calibration');
    end

    function [nextInvokeTime, indicationToMAC, frameToMAC] = run(obj, currentTime, signal)
        %run physical layer receive operations for a WLAN node and returns the
        %next invoke time, indication to MAC, and decoded data bits along with
        %the decoded data length
        %
        %   [NEXTINVOKETIME, INDICATIONTOMAC, FRAMETOMAC] = run(OBJ,
        %   CURRENTTIME, SIGNAL) receives and processes the waveform
        %
        %   NEXTINVOKETIME is the next event simulation time in nanoseconds,
        %   when this method must be invoked again.
        %
        %   INDICATIONTOMAC is an output structure to be passed to MAC layer
        %   with the receiver indication. This output structure is valid only
        %   when its field MessageType is set to value other than
        %   wlan.internal.PHYPrimitives.UnknownIndication. See <a
        %   href="matlab:help('wlan.internal.utils.defaultIndicationToMAC')">wlan.internal.utils.defaultIndicationToMAC</a>.
        %
        %   FRAMETOMAC is an output structure to be passed to MAC layer. An
        %   empty value is returned when there is nothing to pass to MAC layer.
        %   See <a href="matlab:help('wlan.internal.utils.defaultMACFrame')">wlan.internal.utils.defaultMACFrame</a>.
        %
        %   CURRENTTIME is the current simulation time in nanoseconds.
        %
        %   SIGNAL is an input structure which contains the WLAN
        %   signal received from the channel. When empty no signal is assumed.
        %
        %   Structure 'SIGNAL' contains the following fields:
        %
        %   Data             - Depending on SIGNAL.Metadata.MACDataType, Data
        %                      can be complex IQ samples, MAC PPDU bits, or MAC
        %                      configuration structure.
        %   Type             - Type of the signal
        %   NodeID           - Node identifier of the source node
        %   NodePosition     - Position of the source node
        %   StartTime        - Frame start time in seconds
        %   Duration         - Duration of the signal in seconds
        %   Power	         - Signal power of the received signal
        %   SampleRate       - Sample rate of the received signal
        %   CenterFrequency  - Center frequency of the signal
        %   Bandwidth        - Bandwidth of the channel
        %   Metadata         - Structure holding metadata for the received
        %                      packet. See <a href="matlab:help('wlan.internal.utils.defaultMetadata')">wlan.internal.utils.defaultMetadata</a>.

        % Defaults to return
        indicationToMAC = obj.DefaultIndicationToMAC;
        frameToMAC = [];

        obj.LastRunTimeNS = currentTime; % nanoseconds

        signalReceived = ~isempty(signal);
        if signalReceived
            handleNewSignal(obj, signal);
        end

        % Reception of the decodable signal (or its part) is completed
        if currentTime >= obj.NextProcessingTime
            switch obj.SignalDecodeStage
                case obj.Preamble % Started receiving a waveform (end of legacy preamble and header)
                    indicationToMAC = processPreambleAndHeader(obj);
                case obj.Payload % Preamble and header successfully decoded (end of payload)
                    [indicationToMAC, frameToMAC] = processPayload(obj);
                case obj.Extension % End of extension/padding duration
                    [indicationToMAC, frameToMAC] = endOfPacket(obj);
                case obj.Cleanup
                    % Remove the processing waveform from stored buffer
                    % when duration is completed
                    obj.UsePacketErrProbCache = false(1, obj.MaxMUUsers);
                    obj.SignalDecodeStage = obj.WaitForWaveform;
                    obj.SOIChannel.Cached = false; % Clear channel cache
                    obj.NextProcessingTime = Inf;
                    obj.PPDUFiltered = false;
                    obj.RxBSSColor = 0;
                    obj.RxUplinkIndication = false;
                    obj.RxSTAID = [];
                    obj.UserIndex = obj.UserIndexSU; % By default assume single-user
                    resetSignal(obj);
            end
        end

        % Get the indication to MAC
        if obj.RxOn && (obj.SignalDecodeStage == obj.WaitForWaveform || signalReceived) && (indicationToMAC.MessageType == obj.UnknownIndication)
            indicationToMAC = getIndicationToMAC(obj);
        end

        nextInvokeTime = getNextInvokeTime(obj);
    end

    function setPHYMode(obj, phyMode)
        %setPHYMode Process the PHY mode set request from the MAC layer
        %
        %   setPHYMode(OBJ, PHYMODE) processes the PHY mode set request from the
        %   MAC layer.
        %
        %   PHYMODE is an input structure from MAC layer to configure the
        %   PHY. See <a href="matlab:help('wlan.internal.utils.defaultPHYMode')">wlan.internal.utils.defaultPHYMode</a>.

        obj.RxOn = phyMode.PHYRxOn;

        if ~obj.RxOn
            if obj.SignalDecodeStage ~= obj.WaitForWaveform
                % MAC turns off the EMLSR link during the SOI processing. PHY terminates
                % the current SOI processing, treat it as interference.
                obj.SignalDecodeStage = obj.Cleanup;
                obj.NextProcessingTime = obj.LastRunTimeNS;
                treatSOIAsInterference(obj);
                obj.DroppedPackets = obj.DroppedPackets + 1;
            end
        end

        % Set spatial reuse parameters
        obj.EnableSROperation = phyMode.EnableSROperation;
        if obj.EnableSROperation
            obj.BSSColor = phyMode.BSSColor;
            obj.OBSSPDThreshold = phyMode.OBSSPDThreshold;
        end
    end

    function subChanSignalPowerIndBm = getTotalSignalPower(obj)
        %get the subchannel power of the signal of interest and the
        %interference in dBm
        currentTimeInSeconds = round(obj.LastRunTimeNS*1e-9,9);
        interferencePowerPerSubchannel = receivedPacketPower(obj.Interference, currentTimeInSeconds, CenterFrequency=obj.OperatingFrequency, ...
            Bandwidth=obj.ChannelBandwidth*1e6, SubchannelBandwidth=20e6);
        soiPowerPerSubchannel = obj.RxSignalPower - round(pow2db(obj.NumSubchannels)); % Scaled by the number of subchannels
        subChanSignalPowerIndBm = wlan.internal.utils.addPowerdBm(soiPowerPerSubchannel, interferencePowerPerSubchannel);
    end

    function handleTrigRequest(obj, expiryTime)
        % Callback from MAC. Set time by which we expect an HE TB packet to
        % begin reception.
        obj.TriggerRequestExpiryTime = expiryTime; % nanoseconds
    end

    function indicationToMAC = setPPDUStartTime(obj, indicationToMAC)
        % Set PPDU start time in the indicationTOMAC
        indicationToMAC.PPDUInfo.StartTime = obj.Signal(1).StartTime; % In seconds
    end
end

methods (Access = private)
    function indicationToMAC = processPreambleAndHeader(obj)
        %processPreambleAndHeader Process both legacy preamble and header of the received signal

        % Initialize
        obj.PPDUFiltered = false;
        obj.UserIndex = obj.UserIndexSU; % By default assume single-user

        % As per Appendix 4 of IEEE 11-14-0571-12 treat whole preamble (and
        % header) as a standalone subframe based on the assumption of 3
        % bytes per 4 us (MCS0). Assume BCC coding. If UL-OFDMA, all
        % preambles same
        effectiveNumPreambleAndHeaderBytes = (3*(obj.Signal(1).Metadata.PreambleDuration + obj.Signal(1).Metadata.HeaderDuration)/1e3)/4;

        % Determine if preamble is decodable
        isInterference = interferencePresentSinceTime(obj,min(obj.FrameReceptionStartTime));
        if obj.AbstractionTypeTGaxAppendix1
            % PHY abstraction: TGax Appendix 1
            % Estimate SINR and probability of frame decode error
            [signalOfInterest,signalInterference] = getAbstractionSignals(obj, "preamble", 1:numel(obj.Signal));
            sinr = wlan.internal.phy.l2sm.estimateLinkQuality(signalOfInterest, signalInterference, obj.NoiseFigure, obj.SubcarrierSubsampling);
            per = wlan.internal.phy.l2sm.estimateLinkPerformance(sinr, effectiveNumPreambleAndHeaderBytes, wlan.internal.utils.getFrameFormatString(obj.NonHT, 'PHY'), 0, 'BCC');
            % Pick a random number and compare against the packet error
            % rate. If the packet error rate is 0.1, it means that 90
            % percent of packets get successfully decoded and 10 percent
            % are not decoded because of packet errors.
            randNum = rand(1);
            isDecodable = per<=randNum;
        else
            % PHY abstraction: MAC calibration
            % Packet not decodable if any interference present since last event
            isDecodable = ~isInterference;
        end

        % Fill indication to MAC
        indicationToMAC = obj.DefaultIndicationToMAC;
        indicationToMAC.Vector = obj.Signal(1).Metadata.Vector;
        indicationToMAC.Vector.RSSI = obj.RxSignalPower; % dBm

        if ~isDecodable
            % If the header cannot be decoded, set next invoke time as the
            % current time as the receiver now should compare the RX power
            % with the ED threshold to determine if CCA stays Busy or moves
            % to Idle state, Appendix 4 of IEEE 11-14-0571-12
            indicationToMAC = setRxErrorIndication(obj, indicationToMAC);
            indicationToMAC = setPerUserInfo(obj,indicationToMAC);
            obj.NextProcessingTime = obj.LastRunTimeNS;
            obj.SignalDecodeStage = obj.Cleanup;
            % No longer signal of interest - now interference
            treatSOIAsInterference(obj);

            % Increment the PHY decoding failures and Rx drop statistic
            obj.HeaderDecodeFailures = obj.HeaderDecodeFailures + 1;
            obj.DroppedPackets = obj.DroppedPackets + 1;
            return;
        end

        % Decode successful
        obj.RxFrameFormat = obj.Signal(1).Metadata.Vector.PPDUFormat;
        if obj.RxFrameFormat == obj.HE_MU
            % Valid MU PPDUs count
            obj.ReceivedMUPPDUs = obj.ReceivedMUPPDUs + 1;
        end

        if (signalReceivedDuringTriggerRequest(obj) && obj.RxFrameFormat ~= obj.HE_TB) || ...
                (~signalReceivedDuringTriggerRequest(obj) && obj.RxFrameFormat == obj.HE_TB)
            % If expecting HE TB PPDU but other format received, or not
            % expecting an HE TB PPDU, then filter the PPDU
            obj.PPDUFiltered = true;
            indicationToMAC = handleFilteredPPDU(obj,indicationToMAC);
            return;
        end

        % Filter frames based on BSSColor.
        obj.RxBSSColor = indicationToMAC.Vector.BSSColor;
        filterPPDUWhenBSSColorMismatches(obj);
        if obj.PPDUFiltered
            indicationToMAC = handleFilteredPPDU(obj,indicationToMAC);
            return;
        end

        % Filter frames based on Uplink/Downlink indication
        obj.RxUplinkIndication = indicationToMAC.Vector.UplinkIndication;
        filterPPDUWhenULorDLNotIntended(obj);
        if obj.PPDUFiltered
            indicationToMAC = handleFilteredPPDU(obj,indicationToMAC);
            return;
        end

        % Filter frames based on STAID (NodeID/AID)
        obj.RxSTAID = [obj.Signal(1).Metadata.Vector.PerUserInfo.StationID];
        stationIDMatchLogical = filterPPDUWhenSTAIDMismatches(obj);
        if obj.PPDUFiltered
            % If station ID does not match current node then do not
            % process data portion
            indicationToMAC = handleFilteredPPDU(obj,indicationToMAC);
            return;
        else
            % Multi user index obtained only for DLOFDMA frames. If DLOFDMA frames
            % are received by unintended AP/Mesh, pass the index of the RU for the
            % first user. Thus the frame is passed to MAC, which updates the NAV
            % accordingly. If received by a STA, get index of the RU to process as
            % intended for this user (assuming OFDMA - 1 RU per user).
            if ~isempty(stationIDMatchLogical) && obj.RxFrameFormat == obj.HE_MU
                obj.UserIndex = find(stationIDMatchLogical,1);
            end
        end

        if obj.RxFrameFormat == obj.HE_TB
            numUsersToDecode = numel(obj.Signal);
        else
            numUsersToDecode = 1;
        end
        % Set expected data length and get durations of subframes
        firstSubframeDuration = zeros(1,numUsersToDecode);
        obj.NumSubframes = zeros(1,numUsersToDecode);
        obj.RxSubframeNumber = ones(1,numUsersToDecode); % Initialize
        obj.SubframeEndTimes = Inf(obj.MaxSubframes,numUsersToDecode);
        for i = 1:numUsersToDecode
            obj.NumSubframes(i) = obj.Signal(i).Metadata.NumSubframes(obj.UserIndex);

            firstSubframeDuration(i) = obj.Signal(i).Metadata.PayloadInfo(obj.UserIndex,1).Duration;
            obj.SubframeEndTimes(1:obj.NumSubframes(i),i) = cumsum([obj.Signal(i).Metadata.PayloadInfo(obj.UserIndex,1:obj.NumSubframes(i)).Duration]) + ...
                obj.Signal(i).Metadata.MIMOPreambleDuration + obj.LastRunTimeNS;
        end
        % Packet end time includes any padding and packet or signal
        % extension which is included in PayloadDuration.
        % PayloadInfo.Duration only includes the duration of useful payload
        % (no padding).
        obj.PacketEndTime = obj.LastRunTimeNS + obj.Signal(1).Metadata.MIMOPreambleDuration + obj.Signal(1).Metadata.PayloadDuration;

        indicationToMAC = setPerUserInfo(obj,indicationToMAC);

        if obj.RxFrameFormat == obj.HE_MU
            % Get RU size and index for this user and set in RXVECTOR
            center26 = [obj.Signal(1).Metadata.Vector.LowerCenter26ToneRU obj.Signal(1).Metadata.Vector.UpperCenter26ToneRU];
            s = wlan.internal.heAllocationInfo(obj.Signal(1).Metadata.Vector.RUAllocation, center26);
            obj.RUInfo = [s.RUSizes' s.RUIndices'];
            indicationToMAC.Vector.RUAllocation = obj.RUInfo(obj.UserIndex,:);
        end

        % Next processing time is the MIMO preamble duration plus duration
        % of the first subframe
        nextRelProcessingTime = obj.Signal(1).Metadata.MIMOPreambleDuration + min(firstSubframeDuration);

        % Continue to decode payload with RXSTART indication.
        indicationToMAC.MessageType = obj.RxStartIndication;
        obj.moveToDecodingStage(obj.Payload,nextRelProcessingTime);
    end

    function [indicationToMAC, frameToMAC] = endOfPacket(obj)
        % Generate RXEND indication and prepare data to send to MAC

        % If multiple signals all formats will be the same
        if obj.RxFrameFormat~=obj.HE_TB
            % Process all signals together
            frameToMAC = createFrameToMAC(obj,1);
        else
            % Decoding HE TB
            % All user decode stages and timers will be the same for all
            % formats as only a single subframe supported if UL-OFDMA (ACK)
            frameToMAC = repmat(obj.DefaultFrameToMAC, 1, numel(obj.Signal));
            for u = 1:numel(obj.Signal)
                frameToMAC(u) = createFrameToMAC(obj,u);
            end
        end
        indicationToMAC = obj.DefaultIndicationToMAC;
        indicationToMAC = setRxEndIndication(obj, indicationToMAC);
        obj.NextProcessingTime = obj.LastRunTimeNS;
        obj.SignalDecodeStage = obj.Cleanup; % Finish payload decode - remove signal
    end

    function handleNewSignal(obj, signal)
        %handleNewSignal initiates the processing of a received signal or
        % ignores the signal (consider as interferer) based on the ED
        % threshold and CCA and RxOn states.

        assert(wlan.internal.utils.seconds2nanoseconds(signal.StartTime)==obj.LastRunTimeNS,'No propagation delay expected');

        % Apply receiver gain
        signal.Power = signal.Power + obj.RxGain; % dBm

        if ~obj.RxOn % Receiver antenna is switched on
            % Receiver antenna is switched off (Transmission is in progress)
            dropPacket(obj, signal);
            obj.ReceiveTriggersWhileTransmission = obj.ReceiveTriggersWhileTransmission + 1;
            return
        end

        if obj.PrimaryChannelCCAIdle
            handleNewSignalWhenCCAIdle(obj, signal);
        elseif obj.SignalDecodeStage == obj.Preamble
            handleNewSignalWhenPreambleProcessingStarted(obj, signal);
        else
            % Waveform is received when the node is already in receive state
            dropPacket(obj, signal);
            obj.ReceiveTriggersWhileReception = obj.ReceiveTriggersWhileReception + 1;
        end
    end

    function handleNewSignalWhenPreambleProcessingStarted(obj, signal)
        %handleNewSignalWhenPreambleProcessingStarted handles a new signal
        % when an existing preamble is being processed. This handles
        % potential UL-OFDMA signals.

        if isULOFDMASignal(obj, signal)
            % Existing signal of interest and new signal are both part of
            % an UL-OFDMA transmission. Treat as another signal of interest
            % so append to list, start interference measurement for another
            % signal, and accumulate signal power
            obj.Signal = [obj.Signal signal];
            obj.FrameReceptionStartTime = [obj.FrameReceptionStartTime obj.LastRunTimeNS];
            obj.RxSignalPower = wlan.internal.utils.addPowerdBm(obj.RxSignalPower, signal.Power);
        elseif isHETB(signal) && intendedForThisNode(obj,signal) && signal.StartTime <= obj.TriggerRequestExpiryTime
            % HE TB waveform arrived (and expected), but an interferer
            % (existing signal of interest) arrived before expected HE TB
            % packet. Add current signal of interest to interference buffer
            % and process HE TB as signal of interest.

            % Treat previous signal(s) of interest as a dropped packet
            for i = 1:numel(obj.Signal)
                dropPacket(obj, obj.Signal(i));
            end

            % Store new signal of interest
            obj.Signal = signal;
            obj.FrameReceptionStartTime = obj.LastRunTimeNS;
            obj.moveToDecodingStage(obj.Preamble,obj.Signal.Metadata.PreambleDuration+obj.Signal.Metadata.HeaderDuration);
            obj.RxSignalPower = signal.Power;
        else
            % Waveform is received when the node is already in receive
            % state

            if (signal.StartTime == obj.Signal(1).StartTime) && (signal.Power >= obj.EDThreshold) && ~isHETB(obj.Signal(1))
                % If an incoming signal arrives simultaneously with the
                % current SOI and its power is higher than the ED
                % threshold, it is considered to be a potential SOI
                % For HE-TB packets, if an SOI is already present, consider
                % any unexpected packet arriving simultaneously as
                % interference

                indicateStateTransition(obj, signal); % Indicate transition to reception state

                if  signal.Power > obj.RxSignalPower
                    % Previous packet(s) is not SOI anymore - now interference
                    treatSOIAsInterference(obj)
                    obj.DroppedPackets = obj.DroppedPackets + 1;

                    % Store the context of WLAN signal received with high
                    % power as it is assumed to be SOI
                    obj.RxSignalPower = signal.Power;

                    % Store the current received waveform
                    obj.Signal = signal;
                    obj.FrameReceptionStartTime = obj.LastRunTimeNS;

                    % Reset spatial reuse flag as new signal received - MAC
                    % will need to identify a new opportunity
                    obj.SROpportunityIdentified = false;

                    % Update the signal decode stage to process preamble
                    % and header Next processing time after preamble +
                    % header duration of newly locked SOI
                    obj.moveToDecodingStage(obj.Preamble,obj.Signal.Metadata.PreambleDuration+obj.Signal.Metadata.HeaderDuration);
                    return
                end
            end

            dropPacket(obj, signal);
            obj.ReceiveTriggersWhileReception = obj.ReceiveTriggersWhileReception + 1;
        end
    end

    function handleNewSignalWhenCCAIdle(obj, signal)
        %handleNewSignalWhenPreambleProcessingStarted handles a new signal
        % when the CCA is idle. A signal will be processed if the power is
        % above ED threshold, or if the culmination of low power UL-OFDMA
        % signals exceed the ED threshold

        if signal.Power >= obj.EDThreshold
            % Signal power exceeded ED threshold, store as signal of interest

            indicateStateTransition(obj, signal); % Indicate transition to reception state

            % Store the context of WLAN signal received with high power
            % as it is assumed to be SOI
            obj.RxSignalPower = signal.Power;

            % Store the received waveform
            obj.Signal = signal;
            obj.FrameReceptionStartTime = obj.LastRunTimeNS;
            % Reset spatial reuse flag as new signal received - MAC will
            % need to identify a new opportunity
            obj.SROpportunityIdentified = false;

            % Update the signal decode stage to process preamble and header
            % Next processing time after preamble + header duration
            obj.moveToDecodingStage(obj.Preamble,obj.Signal.Metadata.PreambleDuration+obj.Signal.Metadata.HeaderDuration);
            return
        end

        % Signal power of the current individual waveform is less than ED threshold
        obj.EnergyDetectionsBelowEDThreshold = obj.EnergyDetectionsBelowEDThreshold + 1;

        % If signal may be part of UL-OFDMA transmission then record it. It
        % failed ED by itself but combined with other UL-OFDMA signals may
        % exceed ED threshold.
        candidateHETB = isHETB(signal);
        candidateULCTS = isCTS(signal);
        isULOFDMACandidate = candidateHETB|candidateULCTS;
        if ~isULOFDMACandidate
            dropPacket(obj, signal);
            return
        end

        signalStartTime = wlan.internal.utils.seconds2nanoseconds(signal.StartTime);
        if signalStartTime~=obj.SignalReceptionStartTime
            % Not currently processing an UL-OFDMA waveform. If received
            % waveform is potentially UL-OFDMA then store as cumulation of
            % all waveforms may exceed ED threshold.

            % Store candidate UL-OFDMA signal information
            storeULOFDMASignal = true;
            obj.TotalULSignalPower = signal.Power;

            % Reset variables
            obj.SignalReceptionStartTime = signalStartTime;
            obj.ULSignalBufferIndex = [];

        elseif obj.TotalULSignalPower>-Inf
            % Previously captured a candidate UL-OFDMA signal at the same
            % time. If the current received waveform is likely in an OFDMA
            % transmission with reference, then store it and test for
            % combined CCA to exceed ED threshold.
            refBufferIdx = obj.ULSignalBufferIndex(1); % First candidate stored is used as reference
            refSignal = retrievePacket(obj.Interference,refBufferIdx);
            isULOFDMA = signal.Metadata.Vector.PerUserInfo(1).StationID == refSignal.Metadata.Vector.PerUserInfo(1).StationID && ... % Intended for same station
                ((candidateHETB && isHETB(refSignal)) || (candidateULCTS && isCTS(refSignal))) && ... % Same format and type suitable for UL-OFDMA
                signal.Metadata.HeaderDuration == refSignal.Metadata.HeaderDuration && ... % Same header duration
                signal.Metadata.PayloadDuration == refSignal.Metadata.PayloadDuration; % Same payload duration
            storeULOFDMASignal = isULOFDMA;
            if isULOFDMA
                % Store candidate UL-OFDMA signal information
                obj.TotalULSignalPower = wlan.internal.utils.addPowerdBm(obj.TotalULSignalPower, signal.Power);

                if obj.TotalULSignalPower >= obj.EDThreshold
                    % Accumulation of UL-OFDMA signals exceed ED
                    % threshold - can process

                    % Indicate transition to reception state
                    indicateStateTransition(obj, signal);
                    obj.RxSignalPower = obj.TotalULSignalPower; % In dBm

                    % Store the received waveform
                    obj.Signal = [retrievePacket(obj.Interference,obj.ULSignalBufferIndex).' signal];
                    obj.FrameReceptionStartTime = obj.LastRunTimeNS.*ones(1,numel(obj.Signal));
                    numULOFDMASignals = numel(obj.Signal);

                    % Remove signals from interference buffer as now signals of interest
                    for i = 1:numel(obj.ULSignalBufferIndex)
                        removePacket(obj.Interference, obj.ULSignalBufferIndex(i));
                    end

                    % Update the signal decode stage, signal processing flag, and set the reception timer to preamble + header duration
                    obj.SignalDecodeStage = obj.Preamble;
                    obj.NextProcessingTime = obj.Signal(1).Metadata.PreambleDuration+...
                        obj.Signal(1).Metadata.HeaderDuration+obj.LastRunTimeNS;

                    % Update statistics incremented when UL-OFDMA waveforms were counted as interference
                    obj.EnergyDetectionsBelowEDThreshold = obj.EnergyDetectionsBelowEDThreshold-numULOFDMASignals;
                    obj.DroppedPackets = obj.DroppedPackets-(numULOFDMASignals-1); % For current signal DroppedPackets not incremented

                    % Reset variables
                    obj.SignalReceptionStartTime = -1;
                    obj.ULSignalBufferIndex = [];
                    return
                end
            end
        end

        bufferIdx = dropPacket(obj, signal);
        if storeULOFDMASignal
            % Store interference buffer index of candidate UL-OFDMA waveform
            obj.ULSignalBufferIndex = [obj.ULSignalBufferIndex bufferIdx];
        end
    end

    function bufferIdx = dropPacket(obj, signal)
        % Add signal to the interference buffer list
        bufferIdx = addPacket(obj.Interference, signal);
        obj.DroppedPackets = obj.DroppedPackets + 1;
    end

    function [signalOfInterest,signalInterference] = getAbstractionSignals(obj,fieldOfInterest,soiIndex)
        % Return an array of structures containing signal parameters for
        % signal of interest and interferers

        % soiIndex is a vector only when all signals are the same, for
        % example MU-CTS. Therefore, the frame reception start time is the
        % same, so take the first.
        fieldStartTime = obj.FrameReceptionStartTime(soiIndex);
        fieldStartTime = fieldStartTime(1);

        % Get active interfering signals active between the start of the
        % current subframe processed for user of interest and the current
        % time.
        fieldStartTimeInSeconds = round(fieldStartTime*1e-9,9);
        currentTimeInSeconds = round(obj.LastRunTimeNS*1e-9,9);
        sigSet = packetList(obj.Interference,fieldStartTimeInSeconds,currentTimeInSeconds);

        % Fill signals of interest
        if numel(soiIndex)>1
            signalOfInterest = repmat(obj.DefaultAbstractionSignal,1,numel(soiIndex));
        else
            signalOfInterest = obj.DefaultAbstractionSignal;
        end
        for i = 1:numel(soiIndex)
            j = soiIndex(i);
            signalOfInterest(i).SourceID = obj.Signal(j).TransmitterID;
            cfg = signalToPHYConfig(obj,obj.Signal(j));
            signalOfInterest(i).Config = cfg;
            % l2sm functions expect the signal power in Watts therefore
            % convert dBm to Watts
            signalOfInterest(i).RxPower = db2pow(obj.Signal(j).Power-30);
            signalOfInterest(i).Field = fieldOfInterest;

            if i==1
                % If UL-OFDMA, all configs are the same so use first to
                % calculate channel etc and use for remainder

                signalOfInterest(i).RUIndex = obj.UserIndex;
                rxOFDMInfo = getOFDMInfo(obj,cfg,fieldOfInterest,obj.UserIndex);

                if ~obj.SOIChannel.Cached
                    % Concatenate all signal of interest channel structures as treat as a single channel
                    soiSigMetadata = [obj.Signal(soiIndex).Metadata];
                    sig = [soiSigMetadata.Channel];
                    if numel(sig)>1
                        % Combine channels from individual signals into a single channel
                        [pathGains,pathDelays,userTxIdx] = wlan.internal.phy.l2sm.createMUChannel(sig);
                    else
                        pathGains = sig.PathGains;
                        pathDelays = sig.PathDelays;
                        userTxIdx = {1:size(sig.PathGains,3)}; % All path gain antennas used
                    end

                    % Generate path filters if UL-MIMO (single channel) or no filters provided
                    if numel(sig)>1 || isempty(sig.PathFilters)
                        pathFilters = wireless.internal.L2SM.channelFilterCoefficients(pathDelays,rxOFDMInfo.SampleRate);
                    else
                        pathFilters = sig.PathFilters;
                    end

                    % Parameters used for perfect channel estimation
                    tOffset = channelDelay(pathGains,pathFilters);

                    % Store channel to be by subsequent portions of the packet
                    obj.SOIChannel.Cached = true;
                    obj.SOIChannel.PathGains = pathGains;
                    obj.SOIChannel.PathFilters = pathFilters;
                    obj.SOIChannel.UserTxIndex = userTxIdx;
                    obj.SOIChannel.TimingOffset = tOffset;
                else
                    % Get stored channel to be used by data portion
                    pathGains = obj.SOIChannel.PathGains;
                    if strcmp(fieldOfInterest,'data')
                        % If receiving OFDMA, the path gains are for
                        % the whole combined channel, therefore extract
                        % transmit antennas for signal of interest when
                        % processing data field
                        pathGains = pathGains(:,:,[obj.SOIChannel.UserTxIndex{soiIndex}],:);
                    end
                    pathFilters = obj.SOIChannel.PathFilters;
                    tOffset = obj.SOIChannel.TimingOffset;
                end
            end

            soiPathGainsActive = handlePathGainForActiveRxAnts(obj,pathGains);
            signalOfInterest(i).PathGains = soiPathGainsActive;
            signalOfInterest(i).PathFilters = pathFilters;
            signalOfInterest(i).TimingOffset = tOffset;
            signalOfInterest(i).OFDMConfig = rxOFDMInfo;
        end

        % Fill interfering signals
        if numel(sigSet)>1
            signalInterference = repmat(obj.DefaultAbstractionSignal,1,numel(sigSet));
        elseif numel(sigSet)==0
            signalInterference = obj.EmptyAbstractionSignal;
        else
            signalInterference = obj.DefaultAbstractionSignal;
        end
        possibleFields = ["preamble" "data"];
        for i = 1:numel(sigSet)
            signalInterference(i).SourceID = sigSet(i).TransmitterID;
            signalInterference(i).Config = signalToPHYConfig(obj,sigSet(i));
            signalInterference(i).RxPower = db2pow(sigSet(i).Power-30); % dBm to Watts
            % RUIndex is default -1 so that all RUs in an interferer affect
            % signal of interest
            % Channel abstraction
            sigSetPathGainsActive = handlePathGainForActiveRxAnts(obj,sigSet(i).Metadata.Channel.PathGains);
            signalInterference(i).PathGains = sigSetPathGainsActive;
            signalInterference(i).PathFilters = sigSet(i).Metadata.Channel.PathFilters;
            signalInterference(i).OFDMConfig = rxOFDMInfo;
            signalInterference(i).TimingOffset = tOffset;

            startTime = wlan.internal.utils.seconds2nanoseconds(sigSet(i).StartTime);
            % Get the start time of each section
            fieldStartTimes = [startTime; ...
                startTime+sigSet(i).Metadata.PreambleDuration+sigSet(i).Metadata.HeaderDuration];
            % Find the field which started before or on the current time
            % (as interference model assumed any signal active at this
            % current time applies to the segment of interest)
            fieldStarted = fieldStartTimes <= obj.LastRunTimeNS;
            idx = find(fieldStarted,1,'last');
            signalInterference(i).Field = possibleFields(idx);
        end
    end

    function rxOFDMInfo = getOFDMInfo(obj, config, field_soi, ruIdx_soi)
        % Returns an OFDM configuration structure. Cache structures for
        % speed when possible

        vector = obj.Signal(1).Metadata.Vector; % If multiple signals all will be same type and bandwidth (HE TB)
        if vector.PPDUFormat == obj.NonHT
            if obj.NonHTOFDMInfoBandwidth~=vector.ChannelBandwidth
                obj.NonHTOFDMInfoBandwidth = vector.ChannelBandwidth;
                % Use internal OFDM info as wlanNonHTOFDMInfo does not support 320 MHz. CBW320NONHTDUP.
                obj.NonHTOFDMInfo = wlan.internal.vhtOFDMInfo('L-SIG',wlan.internal.utils.getChannelBandwidthStr(vector.ChannelBandwidth));
            end
            rxOFDMInfo = obj.NonHTOFDMInfo;
        else
            if any(vector.PPDUFormat == [obj.HTMixed obj.VHT])
                if obj.VHTOFDMInfoBandwidth~=vector.ChannelBandwidth
                    obj.VHTOFDMInfoBandwidth = vector.ChannelBandwidth;
                    obj.VHTPreambleOFDMInfo = wlan.internal.vhtOFDMInfo('L-SIG',wlan.internal.utils.getChannelBandwidthStr(vector.ChannelBandwidth));
                    obj.VHTDataOFDMInfo = wlan.internal.vhtOFDMInfo('VHT-Data',wlan.internal.utils.getChannelBandwidthStr(vector.ChannelBandwidth));
                end
                if strcmp(field_soi,"preamble")
                    rxOFDMInfo = obj.VHTPreambleOFDMInfo;
                else
                    rxOFDMInfo = obj.VHTDataOFDMInfo;
                end
            elseif any(vector.PPDUFormat == [obj.HE_SU obj.HE_EXT_SU]) || (any(vector.PPDUFormat == [obj.HE_MU obj.HE_TB]) && strcmp(field_soi,"preamble"))
                if obj.HESUOFDMInfoBandwidth~=vector.ChannelBandwidth
                    obj.HESUOFDMInfoBandwidth = vector.ChannelBandwidth;
                    obj.HEPreambleOFDMInfo = wlan.internal.heOFDMInfo('L-SIG',wlan.internal.utils.getChannelBandwidthStr(vector.ChannelBandwidth));
                    if any(vector.PPDUFormat == [obj.HE_SU obj.HE_EXT_SU])
                        allocInfo = ruInfo(config);
                        ruSize = allocInfo.RUSizes;
                        ruIdx = allocInfo.RUIndices;
                        obj.HESUDataOFDMInfo = wlan.internal.heOFDMInfo('HE-Data',wlan.internal.utils.getChannelBandwidthStr(vector.ChannelBandwidth),3.2,ruSize,ruIdx);
                    end
                end
                if strcmp(field_soi,"preamble")
                    rxOFDMInfo = obj.HEPreambleOFDMInfo;
                else
                    rxOFDMInfo = obj.HESUDataOFDMInfo;
                end
            elseif vector.PPDUFormat == obj.HE_MU
                if obj.HEMUOFDMInfoBandwidth~=vector.ChannelBandwidth || any(obj.HEOFDMInfoRUInfo~=obj.RUInfo(ruIdx_soi,:))
                    obj.HEMUOFDMInfoBandwidth = vector.ChannelBandwidth;
                    obj.HEOFDMInfoRUInfo = obj.RUInfo(ruIdx_soi,:);
                    ruSize = obj.HEOFDMInfoRUInfo(1);
                    ruIdx = obj.HEOFDMInfoRUInfo(2);
                    obj.HEMUDataOFDMInfo = wlan.internal.heOFDMInfo('HE-Data',wlan.internal.utils.getChannelBandwidthStr(vector.ChannelBandwidth),3.2,ruSize,ruIdx);
                end
                rxOFDMInfo = obj.HEMUDataOFDMInfo;
            elseif vector.PPDUFormat == obj.HE_TB
                % HE TB data field - depending on bandwidth/RU index/size
                % the OFDM config can be very different so lots of cached
                % versions may be required.
                allocInfo = ruInfo(config);
                ruSize = allocInfo.RUSizes;
                ruIdx = allocInfo.RUIndices;
                rxOFDMInfo = wlan.internal.heOFDMInfo('HE-Data',config.ChannelBandwidth,3.2,ruSize,ruIdx);
            else % vector.PPDUFormat == obj.EHT_SU
                % Cached assuming fixed CBW, fixed guard interval, single
                % RU, single user
                if (isempty(obj.EHTPreambleOFDMInfo))
                    obj.EHTPreambleOFDMInfo = wlan.internal.ehtOFDMInfo('L-SIG',config.ChannelBandwidth);
                    allocInfo = ruInfo(config);
                    ruSize = allocInfo.RUSizes{1};
                    obj.EHTSUDataOFDMInfo = wlan.internal.ehtOFDMInfo('EHT-Data',config.ChannelBandwidth,3.2,ruSize);
                end
                if strcmp(field_soi,"preamble")
                    rxOFDMInfo = obj.EHTPreambleOFDMInfo;
                else
                    rxOFDMInfo = obj.EHTSUDataOFDMInfo;
                end
            end
        end
    end

    function cfg = signalToPHYConfig(obj,signal)
        % Return a PHY configuration object used for calculating SINR, set with signal metadata

        switch signal.Metadata.Vector.PPDUFormat
            case obj.HE_MU
                % For HE MU create a new object and configure
                if ~(isequal(signal.Metadata.Vector.RUAllocation,obj.HEMUConfig.AllocationIndex) && ...
                        signal.Metadata.Vector.UpperCenter26ToneRU==obj.HEMUConfig.LowerCenter26ToneRU && signal.Metadata.Vector.LowerCenter26ToneRU==obj.HEMUConfig.UpperCenter26ToneRU)
                    % If RU allocation has changed create new configuration object
                    obj.HEMUConfig = wlanHEMUConfig(signal.Metadata.Vector.RUAllocation, ...
                        "LowerCenter26ToneRU", signal.Metadata.Vector.LowerCenter26ToneRU, ...
                        "UpperCenter26ToneRU", signal.Metadata.Vector.UpperCenter26ToneRU);
                end

                if signal.Metadata.Vector.NumTransmitChains~=obj.HEMUConfig.NumTransmitAntennas
                    obj.HEMUConfig.NumTransmitAntennas = signal.Metadata.Vector.NumTransmitChains;
                end

                for iru = 1:numel(obj.HEMUConfig.RU)
                    % Assume OFDMA - one user per RU
                    if signal.Metadata.Vector.PerUserInfo(iru).NumSpaceTimeStreams~=obj.HEMUConfig.User{iru}.NumSpaceTimeStreams
                        obj.HEMUConfig.User{iru}.NumSpaceTimeStreams = signal.Metadata.Vector.PerUserInfo(iru).NumSpaceTimeStreams;
                    end
                    spatialMapping = signal.Metadata.Vector.PerUserInfo(iru).SpatialMapping;
                    if ~strcmp(obj.HEMUConfig.RU{iru}.SpatialMapping,spatialMapping)
                        obj.HEMUConfig.RU{iru}.SpatialMapping = spatialMapping;
                    end
                end

                cfg = obj.HEMUConfig;
            case obj.NonHT
                obj.NonHTConfig = setGeneralProperties(obj.NonHTConfig);
                cfg = obj.NonHTConfig;
            case obj.HTMixed
                obj.HTConfig = setGeneralProperties(obj.HTConfig);
                obj.HTConfig = setMIMOProperties(obj.HTConfig);
                cfg = obj.HTConfig;
            case obj.VHT
                obj.VHTConfig = setGeneralProperties(obj.VHTConfig);
                obj.VHTConfig = setMIMOProperties(obj.VHTConfig);
                cfg = obj.VHTConfig;
            case {obj.HE_SU,obj.HE_EXT_SU}
                obj.HESUConfig = setGeneralProperties(obj.HESUConfig);
                obj.HESUConfig = setMIMOProperties(obj.HESUConfig);
                cfg = obj.HESUConfig;
            case obj.HE_TB
                obj.HETBConfig = setGeneralProperties(obj.HETBConfig);
                obj.HETBConfig = setMIMOProperties(obj.HETBConfig);
                obj.HETBConfig.RUSize = signal.Metadata.Vector.RUAllocation(1);
                obj.HETBConfig.RUIndex = signal.Metadata.Vector.RUAllocation(2);
                obj.HETBConfig.NumHELTFSymbols = signal.Metadata.Vector.NumHELTFSymbols;
                cfg = obj.HETBConfig;
            case obj.EHT_SU
                v = signal.Metadata.Vector;
                u = v.PerUserInfo;
                obj.EHTSUConfig.User{1}.NumSpaceTimeStreams = u.NumSpaceTimeStreams;
                obj.EHTSUConfig.NumTransmitAntennas = v.NumTransmitChains;
                obj.EHTSUConfig.RU{1}.SpatialMapping = u.SpatialMapping;
                cfg = obj.EHTSUConfig;
        end

        function cfg = setGeneralProperties(cfg)
            % Set properties applicable to all configuration objects
            chanBW = wlan.internal.utils.getChannelBandwidthStr(signal.Metadata.Vector.ChannelBandwidth);
            if ~strcmp(cfg.ChannelBandwidth,chanBW)
                cfg.ChannelBandwidth = chanBW;
            end
            if signal.Metadata.Vector.NumTransmitChains~=cfg.NumTransmitAntennas
                cfg.NumTransmitAntennas = signal.Metadata.Vector.NumTransmitChains;
            end
        end

        function cfg = setMIMOProperties(cfg)
            % Set SU multiple antenna related properties
            if signal.Metadata.Vector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams~=cfg.NumSpaceTimeStreams
                cfg.NumSpaceTimeStreams = signal.Metadata.Vector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams;
            end
            sm = signal.Metadata.Vector.PerUserInfo(obj.UserIndexSU).SpatialMapping;
            if ~strcmp(cfg.SpatialMapping,sm)
                cfg.SpatialMapping = sm;
            end
        end
    end

    function isul = isULOFDMASignal(obj,signal)
        % Returns true if signal is part of an UL-OFDMA transmission
        % with the signal of interest

        jointTransmissionTimeLimit = 0.5*1e-6; % seconds
        isul = ...
            (abs(signal.StartTime-obj.Signal(1).StartTime) < jointTransmissionTimeLimit) && ... % Within transmission window
            ((isHETB(signal) && isHETB(obj.Signal(1))) || (isCTS(signal) && isCTS(obj.Signal(1)))) && ... % HE TB or CTS in response to MU-RTS
            (signal.Metadata.Vector.PerUserInfo(1).StationID == obj.Signal(1).Metadata.Vector.PerUserInfo(1).StationID) && ... % Destination IDs match
            (signal.Metadata.HeaderDuration == obj.Signal(1).Metadata.HeaderDuration) &&...
            (signal.Metadata.PayloadDuration == obj.Signal(1).Metadata.PayloadDuration); % Signal durations used in abstraction the same
    end

    function [allFramesComplete,nextSubframeEndTime] = processUserPayload(obj,u)

        if obj.LastRunTimeNS<obj.SubframeEndTimes(obj.RxSubframeNumber(u),u)
            % Subframe not complete at this time - wait for end of subframe before abstracting
            allFramesComplete = false;
            nextSubframeEndTime = obj.SubframeEndTimes(obj.RxSubframeNumber(u),u);
            return;
        end

        % Determine if subframe is decodable
        if obj.RxFrameFormat~=obj.HE_TB
            % Get abstraction signals for all active signals of interest (allows for MU-CTS)
            soiIndex = 1:numel(obj.Signal);
        else
            % Get abstraction signals for single user of interest
            soiIndex = u;
        end
        format = wlan.internal.utils.getFrameFormatString(obj.RxFrameFormat,'PHY');
        mcs = obj.Signal(u).Metadata.Vector.PerUserInfo(obj.UserIndex).MCS;
        channelCoding = getChannelCoding(obj);
        numBytes = obj.Signal(u).Metadata.PayloadInfo(obj.UserIndex, obj.RxSubframeNumber(u)).NumBits/8;

        % Determine if frame is decodable
        isInterference = interferencePresentSinceTime(obj,obj.FrameReceptionStartTime(u));

        if obj.AbstractionTypeTGaxAppendix1
            % PHY abstraction: TGax Appendix 1
            if obj.UsePacketErrProbCache(u) && ~isInterference
                % If possible use pre-computed and cached probability of subframe error
                per = obj.PacketErrProbCache(u);
            else
                % Estimate SINR and probability of frame decode error
                [signalOfInterest,signalInterference] = getAbstractionSignals(obj, "data", soiIndex);
                sinr = wlan.internal.phy.l2sm.estimateLinkQuality(signalOfInterest, signalInterference, obj.NoiseFigure, obj.SubcarrierSubsampling);
                per = wlan.internal.phy.l2sm.estimateLinkPerformance(sinr, numBytes, format, mcs, channelCoding);

                % If no interference, more subframes to decode, and the
                % number of payload bits is the same in the next subframe,
                % then use cached probability of error for next subframe
                obj.PacketErrProbCache(u) = per;
                obj.UsePacketErrProbCache(u) = ~isInterference && ...
                    (obj.RxSubframeNumber(u) < obj.NumSubframes(u)) && ...
                    (obj.Signal(u).Metadata.PayloadInfo(obj.UserIndex,obj.RxSubframeNumber(u)+1).NumBits == obj.Signal(u).Metadata.PayloadInfo(obj.UserIndex,obj.RxSubframeNumber(u)).NumBits);
            end
            % Pick a random number and compare against the packet error
            % rate. If the packet error rate is 0.1, it means that 90
            % percent of packets get successfully decoded and 10 percent
            % are not decoded because of packet errors.
            randNum = rand(1);
            isDecodable = per<=randNum;
        else
            % PHY abstraction: MAC calibration
            % Packet not decodable if any interference present since last event
            isDecodable = ~isInterference;
        end

        % Update signal payload data based on abstraction result
        updateSignalPayloadData(obj,u,isDecodable);

        % Process more subframes if there are any
        obj.RxSubframeNumber(u) = obj.RxSubframeNumber(u)+1;
        if obj.RxSubframeNumber(u) > obj.NumSubframes(u)
            % All subframes processed
            allFramesComplete = true;
            nextSubframeEndTime = Inf;
        else
            % Process next subframe
            allFramesComplete = false;
            nextSubframeEndTime = obj.SubframeEndTimes(obj.RxSubframeNumber(u),u);
        end

        % Finished subframe, start counting interference from now (for next subframe)
        obj.FrameReceptionStartTime(u) = obj.LastRunTimeNS;
    end

    function f = interferencePresentSinceTime(obj,startTime)       
        %interferencePresentSinceTime return true if interference was
        % present since the specified time
        startTimeInSeconds = round(startTime*1e-9,9); 
        currentTimeInSeconds = round(obj.LastRunTimeNS*1e-9,9); 
        f = ~isempty(packetList(obj.Interference, startTimeInSeconds, currentTimeInSeconds));
    end

    function updateSignalPayloadData(obj,ulUserIdx,isDecodable)
        dlUserIdx = obj.UserIndex;
        sfIdx = obj.RxSubframeNumber(ulUserIdx);

        % If payload is not decodable then force FCS failure in full or abstracted MAC
        if ~isDecodable && obj.NumSubframes(ulUserIdx)>0
            % Flip the CRC of current subframe/frame
            if obj.Signal(ulUserIdx).Metadata.MACDataType == obj.DataTypeMACFrameBits
                % Converting byte indexing to bit indexing for start and end indices
                assert(dlUserIdx==1,'OFDMA not supported')

                subframeIndex = obj.Signal(ulUserIdx).Metadata.SubframeIndices(dlUserIdx,sfIdx);
                startIndex = (subframeIndex-1) * 8 + 1;
                subframeLength = obj.Signal(ulUserIdx).Metadata.SubframeLengths(dlUserIdx,sfIdx);
                endIndex = (startIndex + subframeLength * 8) - 1;
                obj.Signal(ulUserIdx).Data(dlUserIdx).Data(endIndex - 1 : endIndex, 1) = ~obj.Signal(ulUserIdx).Data(dlUserIdx).Data(endIndex -1 : endIndex, 1);
            else % Abstracted MAC
                % Mark FCS fail for the MAC subframe
                obj.Signal(ulUserIdx).Data(dlUserIdx).MPDU(sfIdx).FCSPass = false;
                obj.Signal(ulUserIdx).Data(dlUserIdx).MPDU(sfIdx).DelimiterPass = false;
            end
        else
            if obj.Signal(ulUserIdx).Metadata.MACDataType == obj.DataTypeMACFrameStruct % Abstracted MAC
                % Mark FCS pass for the MAC subframe
                obj.Signal(ulUserIdx).Data(dlUserIdx).MPDU(sfIdx).FCSPass = true;
                obj.Signal(ulUserIdx).Data(dlUserIdx).MPDU(sfIdx).DelimiterPass = true;
            end
        end
    end

    function [indicationToMAC, frameToMAC] = processPayload(obj)
        % Defaults
        indicationToMAC = obj.DefaultIndicationToMAC;
        frameToMAC = [];

        if obj.PPDUFiltered
            % PPDU is filtered so send RXEND indication
            indicationToMAC = setRxEndIndication(obj, indicationToMAC);
            obj.SignalDecodeStage = obj.Cleanup; % Remove signal
            % When STAID does not match, or SR filters out packet, CCA is kept busy after RXEND signaled
            obj.NextProcessingTime = obj.NextReceptionEndTimeAfterRxEnd;
            obj.NextReceptionEndTimeAfterRxEnd = Inf; % Reset
            obj.DroppedPackets = obj.DroppedPackets + 1; % Drop this packet as it is filtered out, i.e., not intended for the receiver
            return;
        end

        % Indices of users to process active at this time (subframes still to decode)
        userInd = find(obj.RxSubframeNumber <= obj.NumSubframes);

        % Process all active users in reception
        numUsers = numel(obj.RxSubframeNumber);
        userPayloadComplete = true(1,numUsers);
        nextSubframeEndTime = Inf(1,numUsers);
        for u = userInd
            [userPayloadComplete(u),nextSubframeEndTime(u)] = processUserPayload(obj,u);
        end

        if all(userPayloadComplete)
            % If all subframes are processed for all users, or there are no
            % subframes, schedule RXEND event to MAC and remove signal.
            % The packet may include EOF padding or packet/signal
            % extension. Therefore, if required, wait this duration before
            % issuing RXEND to prevent transmitter contending before the
            % end of the packet.
            if obj.PacketEndTime>obj.LastRunTimeNS
                obj.NextProcessingTime = obj.PacketEndTime;
                obj.SignalDecodeStage = obj.Extension; % Wait for extension/padding duration
            else
                [indicationToMAC, frameToMAC] = endOfPacket(obj);
            end
        else
            % Get next active frame end time. This allows subframes for
            % some users to finish before others.
            obj.NextProcessingTime = min(nextSubframeEndTime(~userPayloadComplete));
            obj.SignalDecodeStage = obj.Payload; % Decode payload of next subframe
        end
    end

    function channelCoding = getChannelCoding(obj)
        % Assume default object channel coding
        if any(obj.RxFrameFormat==[obj.NonHT obj.HTMixed obj.VHT])
            channelCoding = "BCC";
        else
            channelCoding = "LDPC";
        end
    end

    function frameToMAC = createFrameToMAC(obj,ulUserIdx)
        % Returns a frame to pass to the MAC using decoded data (for user
        % ulUserIdx in UL-OFDMA)
        frameToMAC = obj.DefaultFrameToMAC;
        signal = obj.Signal(ulUserIdx);
        rxDataLength = signal.Metadata.Vector.PerUserInfo(obj.UserIndex).Length; % Bytes
        if signal.Metadata.MACDataType == obj.DataTypeMACFrameStruct % Abstracted MAC
            frameToMAC.MACFrame.MPDU = signal.Data(obj.UserIndex).MPDU;
        else % Full MAC
            frameToMAC.MACFrame.Data = signal.Data(obj.UserIndex).Data(1:rxDataLength * 8);
        end
        frameToMAC.MACFrame.PSDULength = rxDataLength;

        % Pass higherlayer metadata to MAC
        frameToMAC.PacketGenerationTime = signal.Metadata.PacketGenerationTime(obj.UserIndex,1:obj.NumSubframes(ulUserIdx));
        frameToMAC.SequenceNumbers = signal.Metadata.MPDUSequenceNumber(obj.UserIndex,1:obj.NumSubframes(ulUserIdx));
        frameToMAC.PacketID = signal.Metadata.PacketID(obj.UserIndex,1:obj.NumSubframes(ulUserIdx));

        % Update statistics
        obj.ReceivedPackets = obj.ReceivedPackets + 1;
        obj.ReceivedPayloadBytes = obj.ReceivedPayloadBytes + rxDataLength;
    end

    function moveToDecodingStage(obj, stage, nextRelativeTime)
        obj.SignalDecodeStage = stage;
        % Store the current time to capture interference before end of field
        obj.FrameReceptionStartTime(:) = obj.LastRunTimeNS; % nanoseconds
        obj.NextProcessingTime = obj.LastRunTimeNS + nextRelativeTime; % nanoseconds
    end

    function treatSOIAsInterference(obj)
        % Add signal(s) of interest to the interference buffer list and
        % reset signal of interest to default state
        for i = 1:numel(obj.Signal)
            addPacket(obj.Interference, obj.Signal(i));
        end
        resetSignal(obj); % Reset power stored etc
    end

    function resetSignal(obj)
        obj.RxSignalPower = -Inf; % dBm
        obj.FrameReceptionStartTime = [];
    end

    function indicationToMAC = setPerUserInfo(obj,indicationToMAC)
        % If multiple signals are received (UL-OFDMA), send an array of
        % PerUserInfo fields in the RXVECTOR corresponding to each signal
        % (user). For DL-OFDMA send per-user info for the user of interest
        % in RXVECTOR. Note obj.UserIndex = 1 for UL-OFDMA.
        isAIDApplicableForCurrentFormat = any(obj.Signal(1).Metadata.Vector.PPDUFormat == [obj.HE_MU, obj.EHT_SU, obj.EHT_MU]);
        for i = 1:numel(obj.Signal)
            indicationToMAC.Vector.PerUserInfo(i) = obj.Signal(i).Metadata.Vector.PerUserInfo(obj.UserIndex);
            if ~isAIDApplicableForCurrentFormat
                % If AID is not applicable, reuse the StationID field
                % present in vector to store the source node ID
                indicationToMAC.Vector.PerUserInfo(i).StationID = obj.Signal(i).TransmitterID;
            end
        end
    end

    function flag = signalReceivedDuringTriggerRequest(obj)
        % Returns true if receiving node is expecting an HE TB transmission
        % and received a signal; a signal reception started at the trigger
        % request expiry time set by the handleTrigRequest() callback. This
        % test is made at the end of the header.
        flag = obj.LastRunTimeNS-(obj.Signal(1).Metadata.PreambleDuration+obj.Signal(1).Metadata.HeaderDuration) <= obj.TriggerRequestExpiryTime;
    end

    function indicationToMAC = handleFilteredPPDU(obj,indicationToMAC)
        %handleFilteredPPDU Process actions post filtering of PPDU 
        
        % Set RXSTART then RXEND(Filtered) indications as per 802.11ax-2021
        % Figure 27-63 and Section 27.3.22.
        indicationToMAC.MessageType = obj.RxStartIndication;
        indicationToMAC = setPerUserInfo(obj,indicationToMAC);

        % Call again straight away with Payload decode stage so RXEND triggered
        obj.moveToDecodingStage(obj.Payload,0);

        % Simulate the channel busy time until the end of this
        % waveform using the duration after RXEND indication
        obj.NextReceptionEndTimeAfterRxEnd = obj.LastRunTimeNS + obj.Signal(1).Metadata.MIMOPreambleDuration + obj.Signal(1).Metadata.PayloadDuration;

        % No longer signal of interest - now interference
        treatSOIAsInterference(obj);
    end

    function f = intendedForThisNode(obj,signal)
        % Returns true if the signal StationID matches NodeID
        f = obj.NodeID == signal.Metadata.Vector.PerUserInfo(1).StationID;
    end

    function pgActiveRxAnts = handlePathGainForActiveRxAnts(obj, pgMaxRxAnts)
        % Process path gain to extract the number of active receive antennas
        if obj.NumReceiveAntennas < obj.MaxReceiveAntennas
            % pgMaxRxAnts contains the maximum possible number of receive
            % antennas therefore extract the active receive antennas for
            % modelling EMLSR scenario
            pgActiveRxAnts = pgMaxRxAnts(:,:,:,1:obj.NumReceiveAntennas);
        else
            % Otherwise always use the maximum possible number of receiver
            % antennas
            pgActiveRxAnts = pgMaxRxAnts;
        end
    end
end
end

function s = isHETB(sig)
    % Returns true if signals is HE TB
    s = sig.Metadata.Vector.PPDUFormat==wlan.internal.phy.PHYRx.HE_TB;
end

function s = isCTS(sig)
    % Returns true if signals is Non-HT carrying CTS
    s = sig.Metadata.MACDataType==wlan.internal.phy.PHYRx.DataTypeMACFrameStruct && ...
    (sig.Metadata.Vector.PPDUFormat==wlan.internal.phy.PHYRx.NonHT) && strcmp(sig.Data(1).MPDU.Header.FrameType,'CTS');
end
