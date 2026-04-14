classdef FullPHYRx < wlan.internal.phy.PHYRx
%FullPHYRx Create an object for WLAN PHY receiver
%   WLANPHYRX = wlan.internal.phy.FullPHYRx creates a WLAN PHY Receiver
%   handle object for PHY decoding.
%
%   WLANPHYRX = wlan.internal.phy.FullPHYRx(Name, Value) creates a WLAN PHY
%   Receiver handle object with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   FullPHYRx methods:
%
%   run         - Run the physical layer receive operations
%   setPHYMode  - Handle the PHY mode set request from the MAC layer
%
%   FullPHYRx properties:
%
%   NodeID              - Node identifier of the receiving WLAN node
%   NumberOfNodes       - Number of nodes from which signal might come
%   EDThreshold         - Energy detection threshold in dBm
%   RxGain              - Receiver gain in dB

%   Copyright 2022-2025 The MathWorks, Inc.

properties(Access = private)
    % HE/EHT recovery configuration object
    HERecoveryConfig = wlanHERecoveryConfig;
    EHTRecoveryConfig = wlanEHTRecoveryConfig;

    % Cache the default EHT recovery configuration object, this is used for
    % resetting the default configuration after processing the packet
    RecoveryConfigCache;

    % Pre-HE/EHT channel estimate
    ChannelEstimatePreEHT;

    % L-LTF, HT-LTF, VHT-LTF, HE-LTF, EHT-LTF Channel estimates
    ChannelEstimate;

    % Pilot estimation
    PilotEstimate;

    % Non-HT channel estimation calculated using L-LTF
    ChannelEstimateNonHT = complex(zeros(52,1), 0);

    % Noise variance calculated using L-LTF
    NoiseVarianceNonHT = 0;

    % Noise variance of the received frame calculated based on frame format
    NoiseVariance = 0;

    % Demodulated L-LTF
    RecoveredLLTF = complex(zeros(52,2), 0);

    % Baseband sample rate of the received signal
    SampleRate;

    % Current processing offset of the received waveform
    PacketOffset = 0;

    % Frequency offset correction in Hz to apply to waveform
    FrequencyOffsetCorrection = 0;

    % Linear gain to scale waveform using L-STF field
    LSTFAGCGain = 1;

    % Linear gain to scale waveform using X-STF field
    MIMOSTFAGCGain = 1;

    % Extra tolerated delay for extracting the waveform. Allows for delay
    % due to resampling, or channel filtering, and any small error in
    % packet offset detection
    ToleratedDelay = 1750; % nanoseconds

    % Buffer storing the received PPDU with added interference before
    % synchronization
    RxPPDUWithInterference = [];

    % HE demodulated data symbols
    HEDemodSym;

    % HE RU mapping index
    HERUMappingInd;

    % MCS of the received PPDU
    MCS;

    % Number of space time streams
    NumSTS;

    % Start and end indices of the payload
    PayloadIndices;

    % Cell array of FIR decimator to resample the waveform to baseband
    DownSamplingFilter = [];

    % Matrix of downsampling factor and number of receive antennas of FIR decimator
    % First row  - downsampling factor
    % Second row - current number of receive antennas 
    DownSamplingFactorandNumRxAntennas = zeros(2, 0);

    % Waveform combining rate of the received signal per preamble, header, and payload decoding stage
    ResultantSampleRate;

    % Structure array of field indices after header is successfully recovered
    FieldIndices = [];

    % Common signaling field indices for Non-HT, HT, VHT, HE, and EHT
    % format. This includes 16 us following L-LTF for format detection:
    % Non-HT:  L-STF, L-LTF, L-SIG (4 µs), Non-HT Data (part, 12 µs) 
    % HT:      L-STF, L-LTF, L-SIG (4 µs), HT-SIG (8 µs), HT-STF (4 µs)
    % VHT:     L-STF, L-LTF, L-SIG (4 µs), VHT-SIG-A (8 µs), VHT-STF (4 µs)
    % HE:      L-STF, L-LTF, L-SIG (4 µs), RL-SIG (4 µs), HE-SIG-A (8 µs)
    % EHT/UHR: L-STF, L-LTF, L-SIG (4 µs), RL-SIG (4 µs), U-SIG (8 µs)
    SignalingFieldIndices;

    % Current operating channel bandwidth of receiver for processing the current received packet in Hz
    CurrentChannelBandwidth = 0;

    % Receiver operating frequency for processing the current received packet in Hz
    CurrentOperatingFrequency = 0;
end

% Statistics related to ACI modeling
properties (GetAccess = public)
    % Statistics related to ACI modeling, such as number of packets of frequency overlapping and non-overlapping
    ACIStats;
end

methods
    % Constructor
    function obj = FullPHYRx(varargin)
        % Perform one-time calculations, such as computing constants

        % Name-value pairs
        for idx = 1:2:numel(varargin)
            obj.(varargin{idx}) = varargin{idx+1};
        end

        % Cache the default EHT recovery configuration object
        obj.RecoveryConfigCache = obj.EHTRecoveryConfig;

        obj.ChannelBandwidthStr = wlan.internal.utils.getChannelBandwidthStr(obj.ChannelBandwidth);
        if obj.ChannelBandwidth<320
            obj.VHTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            obj.HERecoveryConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            if obj.ChannelBandwidth<80
                obj.HTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            end
        end
        obj.NonHTConfig = wlanNonHTConfig('ChannelBandwidth', obj.ChannelBandwidthStr);
        obj.EHTRecoveryConfig.ChannelBandwidth = obj.ChannelBandwidthStr;

        % Initialize parameters related to BW
        obj.NumSubchannels = obj.ChannelBandwidth/20; % Maximum number of subchannels of current receiver
        obj.DefaultIndicationToMAC.Per20Bitmap = false(obj.NumSubchannels, 1); % Per20Bitmap is size obj.NumSubchannels-by-1
        obj.CurrentPer20Bitmap = false(obj.NumSubchannels, 1);

        % Current channel bandwidth is set to the receiver bandwidth by default
        obj.CurrentChannelBandwidth = obj.ChannelBandwidth;

        % Baseband sample rate
        obj.SampleRate = obj.ChannelBandwidth*1e6;

        % Combining sample rate per decoding stage of waveform
        % 1 - Preamble
        % 2 - Header
        % 3 - Payload
        obj.ResultantSampleRate = zeros(3, 1);

        % Create interference buffer which assumes any time overlap is
        % interference regardless of frequency
        obj.Interference = wnet.internal.interferenceBuffer(CenterFrequency=obj.OperatingFrequency, Bandwidth=obj.ChannelBandwidth*1e6, SampleRate=obj.SampleRate, DisableValidation=true, ...
            InterferenceModeling="non-overlapping-adjacent-channel", ResultantWaveformDataType="single", NumReceiveAntennas=obj.MaxReceiveAntennas);

        obj.MCS = zeros(obj.MaxMUUsers, 1);
        obj.RxDataLength = zeros(obj.MaxMUUsers, 1);

        % Initialize the statistics related to ACI
        obj.ACIStats = struct('numFreqOverlappingPackets', 0, 'numFreqNonOverlappingPackets', 0);

        % Get common field indices
        obj.SignalingFieldIndices = obj.getSignalingIndices(obj.ChannelBandwidthStr);
    end

    function [nextInvokeTime, indicationToMAC, frameToMAC] = run(obj, currentTime, signal)
    %run physical layer receive operations for a WLAN node and returns the
    %next invoke time, indication to MAC, and decoded data bits along with
    %the decoded data length
    %
    %   [NEXTINVOKETIME, INDICATIONTOMAC, FRAMETOMAC] = run(OBJ,
    %   ELAPSEDTIME, SIGNAL) receives and processes the waveform
    %
    %   NEXTINVOKETIME is the next event time, when this method must be
    %   invoked again.
    %
    %   INDICATIONTOMAC is an output structure to be passed to MAC layer
    %   with the Rx indication (CCA/RxStart/RxEnd/RxErr). This output
    %   structure is valid only when its field MessageType is set to value
    %   other than wlan.internal.PHYPrimitives.UnknownIndication.
    %
    %   FRAMETOMAC is an output structure to be passed to MAC layer. An
    %   empty value is returned when there is nothing to pass to MAC layer.
    %
    %   ELAPSEDTIME is the time elapsed since the previous call to this.
    %
    %   SIGNAL is an input structure which contains the signal received
    %   from the channel. It is a structure created using
    %   <ahref="matlab:help('wirelessPacket')">wirelessPacket</a>.
    %   This is a valid signal when the property Type is set to non-zero
    %   value.
    %
    %   Structure 'METADATA' is a property of SIGNAL. See <a
    %   href="matlab:help('wlan.internal.utils.defaultMetadata')">wlan.internal.utils.defaultMetadata</a>.
    %
    %   Structure 'VECTOR' contains the following fields:
    %
    %   PPDUFormat          - PPDUFormat is the physical layer (PHY) frame
    %                         format, specified as a constant of type
    %                         wlan.internal.FrameFormats class
    %   ChannelBandwidth    - Bandwidth of the channel
    %   AggregatedMPDU      - Logical flag that represents whether the
    %                         MPDU aggregation is enabled or not
    %   NumTransmitChains   - Number of transmit antennas
    %   TriggerMethod       - Trigger method used to solicit HE_TB PPDU
    %   LSIGLength          - LSIG length of HE_TB PPDU
    %   NumHELTFSymbols     - Number of HE-LTF symbols in HE_TB PPDU
    %   LowerCenter26ToneRU - Flag indicating lower center 26 tone RU is
    %                         allocated
    %   UpperCenter26ToneRU - Flag indicating upper center 26 tone RU is
    %                         allocated
    %   RSSI                - Receive signal strength
    %   PerUserInfo         - Scalar or array of structures based on
    %                         number of users. It is structure with
    %                         following fields:
    %     MCS                   - Modulation coding scheme index
    %     Length                - Length of the received PSDU
    %     NumSpaceTimeStreams   - Number of space time streams
    %     StationID             - Scalar representing source node ID
    %     TxPower               - Power in dBm used for signal transmission

        narginchk(2,3);

        frameToMAC = [];
        indicationToMAC = obj.DefaultIndicationToMAC;

        obj.LastRunTimeNS = currentTime; % nanoseconds

        signalReceived = ~isempty(signal);
        if signalReceived
            handleNewSignal(obj, signal);
        end

        % Reception of the decodable signal (or its part) is completed
        if obj.NextProcessingTime <= currentTime
            switch(obj.SignalDecodeStage)
                case obj.Preamble % Started receiving a waveform (endPreamble)
                    indicationToMAC = processPreamble(obj);

                case obj.Header % Preamble successfully decoded (endHeader)
                    indicationToMAC = processHeader(obj);

                case obj.Payload % Header successfully decoded (end of payload)
                    [indicationToMAC, frameToMAC] = processPayload(obj);

                case obj.Cleanup
                    % Remove the processing waveform from stored
                    % buffer when its duration is completed
                    obj.SignalDecodeStage = obj.WaitForWaveform;
                    obj.NextProcessingTime = Inf;
                    obj.RxSignalPower = -Inf; % dBm
                    obj.PPDUFiltered = false;
                    obj.RxBSSColor = 0;
                    obj.RxUplinkIndication = false;
                    obj.RxSTAID = [];
                    obj.Signal = [];

                    % Reset receiver configuration related to BW to default
                    resetConfigurationtoDefault(obj);
            end
        end

        % Get the indication to MAC
        if obj.RxOn && (obj.SignalDecodeStage == obj.WaitForWaveform || signalReceived) && (indicationToMAC.MessageType == obj.UnknownIndication)
            indicationToMAC = getIndicationToMAC(obj);
        end

        nextInvokeTime = getNextInvokeTime(obj);
    end

    function setPHYMode(obj, phyMode)
        %setPHYMode Handle the PHY mode set request from the MAC layer
        %
        %   setPHYMode(OBJ, PHYMODE) handles the PHY mode set request from
        %   the MAC layer.
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
        %get the total power of the signal of interest and the interference
        %in dBm
        subChanSignalPowerIndBm = receivedPacketPower(obj.Interference, wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS), ...
            CenterFrequency=obj.OperatingFrequency, Bandwidth=obj.ChannelBandwidth*1e6, ...
            SubchannelBandwidth=20e6, ReceiveAntennaIndex=1:obj.NumReceiveAntennas);
    end

    function indicationToMAC = setPPDUStartTime(obj, indicationToMAC)
        % Set PPDU start time in the indicationTOMAC
        indicationToMAC.PPDUInfo.StartTime = wlan.internal.utils.nanoseconds2seconds(obj.Signal.StartTime);
    end
end

methods (Access = private)
    function indicationToMAC = processPreamble(obj)
    %processPreamble decodes the preamble part of the waveform
        indicationToMAC = obj.DefaultIndicationToMAC;
        % Copying Metadata.Vector because MAC uses BW from metadata to pass in
        % MPDUDecoded event, if preamble decoding fails
        indicationToMAC.Vector = obj.Signal.Metadata.Vector;

        % Get signal + interference. Include samples in L-SIG to allow for
        % for slight offset in symbol timing estimation. These samples may
        % not be fully interfered, but this will be included in the header
        % decode stage.
        extraDuration = 4e3 + obj.ToleratedDelay; % nanoseconds (4us L-SIG + a tolerated delay)
        extraDuration = min(extraDuration, obj.Signal.Duration - obj.Signal.Metadata.PreambleDuration); % Only take extra samples if waveform allows

        startTime = wlan.internal.utils.nanoseconds2seconds(obj.Signal.StartTime);
        endTime = wlan.internal.utils.nanoseconds2seconds(obj.Signal.StartTime + obj.Signal.Metadata.PreambleDuration + extraDuration);

        % Combine the waveform in the interference buffer, down sampling to baseband
        wavCombined = getBBWaveform(obj, startTime, endTime);

        % Add thermal noise to the waveform
        preambleBB = applyThermalNoise(obj, wavCombined);

        % Decode PHY preamble
        isValidPreamble = decodePreamble(obj, preambleBB);
        if isValidPreamble
            % If preamble is successfully decoded, give
            % RX-START indication to MAC and schedule a header
            % decoding event
            obj.SignalDecodeStage = obj.Header;
            obj.NextProcessingTime = obj.Signal.Metadata.HeaderDuration + obj.LastRunTimeNS;
        else
            % If preamble decoding is failed, give RX-ERROR indication to
            % MAC and perform CCA-ED at current time during clean-up stage
            indicationToMAC = handleInvalidPreamble(obj, indicationToMAC);
        end

        % Store impaired preamble for processing header
        preambleStartIndex = 1;
        preambleEndIndex = wlan.internal.utils.nanoseconds2seconds(obj.Signal.Metadata.PreambleDuration)*obj.SampleRate;
        obj.RxPPDUWithInterference = preambleBB(preambleStartIndex:preambleEndIndex,:);
    end

    function indicationToMAC = processHeader(obj)
    %processHeader decodes the header part of the waveform

        indicationToMAC = obj.DefaultIndicationToMAC;
        indicationToMAC.Vector = obj.Signal.Metadata.Vector;
        % Update the packet RSSI
        indicationToMAC.Vector.RSSI = obj.Signal.Power;

        % Get the resultant signal. Include three symbols after L-LTF to
        % allow for format detection. Notes these samples may not be fully
        % interfered, but this will be included in the header decode stage
        % To consider: schedule head decode at least 3 OFDM symbols after preamble
        minNumSIGSymbols = 3;
        minFormatDetectDuration = minNumSIGSymbols*8*1e3; % 8 nanoseconds per symbol
        extraDuration = max(minFormatDetectDuration - obj.Signal.Metadata.HeaderDuration,0) + obj.ToleratedDelay; % Extra duration for format detect and tolerated delay
        extraDuration = min(extraDuration, obj.Signal.Duration - (obj.Signal.Metadata.PreambleDuration + obj.Signal.Metadata.HeaderDuration)); % Only take extra samples if waveform allows
        startTime = wlan.internal.utils.nanoseconds2seconds(obj.Signal.StartTime);
        endTime = startTime + wlan.internal.utils.nanoseconds2seconds(obj.Signal.Metadata.PreambleDuration + obj.Signal.Metadata.HeaderDuration + extraDuration);

        % Combine the waveform in the interference buffer, down sampling to baseband and add thermal noise
        [wavCombined, isResultantRateSameAsPreamble] = getBBWaveform(obj, startTime, endTime);

        samplesPerNanosec = obj.SampleRate*1e-9; % Number of samples per nanosecond
        headerStartIdx = obj.Signal.Metadata.PreambleDuration * samplesPerNanosec + 1;
        headerEndIdx = headerStartIdx + obj.Signal.Metadata.HeaderDuration * samplesPerNanosec;
        if isResultantRateSameAsPreamble
            extraDurEndIdx = headerEndIdx + round(extraDuration * samplesPerNanosec) - 1; % Until the end of extra duration
            % Add noise to the combined waveform of header fields
            rxHeaderBB = applyThermalNoise(obj, wavCombined(headerStartIdx:extraDurEndIdx,:));
            rxSyncHeader = synchronizeWaveform(obj, [obj.RxPPDUWithInterference; rxHeaderBB]);
            % Store impaired preamble and header for processing payload
            obj.RxPPDUWithInterference = [obj.RxPPDUWithInterference; rxHeaderBB(1:obj.Signal.Metadata.HeaderDuration*samplesPerNanosec, :)];
        else
            % Header is resampled at a higher rate than the preamble stage
            [indicationToMAC, rxSyncHeader] = handleCombinedWaveformWhenSRChanges(obj, wavCombined, indicationToMAC);
            if indicationToMAC.MessageType == obj.RxErrorIndication
                % Issue RxError indication for invalid preamble and move to
                % CCA-CS stage
                return
            else
                % Overwrite the impaired waveform up to the end of header
                obj.RxPPDUWithInterference = rxSyncHeader(1:headerEndIdx, :);
            end
        end

        % Recover format and PHY header    
        isValidFormat = detectFormat(obj, rxSyncHeader);
        if isValidFormat
            [isValidHeader, isLSIGFailed] = handleSIGFields(obj, rxSyncHeader);
        else % Unsupported formats
            isValidHeader = false;
            isLSIGFailed = false;
        end

        if isValidHeader
            % If preamble is successfully decoded, give RX-DATA indication
            % to MAC and schedule a payload recovery event
            indicationToMAC.MessageType = obj.RxStartIndication;

            if (obj.RxFrameFormat == obj.NonHT)
                % Non-HT frames are always non aggregated
                aggregatedMPDU = false;
                % Reuse StationID field present in vector to store the source node ID
                indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;
            elseif (obj.RxFrameFormat == obj.HTMixed)
                % HT frames may be aggregated
                aggregatedMPDU = obj.HTConfig.AggregatedMPDU;
                % Reuse StationID field present in vector to store the source node ID
                indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;
            elseif any(obj.RxFrameFormat == [obj.VHT obj.HE_SU obj.HE_EXT_SU]) % VHT/HE
                % VHT/HE frames are always aggregated
                aggregatedMPDU = true;
                % Reuse StationID field present in vector to store the source node ID
                indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;

                % Filter frames based on BSSColor. Note that uplink indication based filtering and
                % STAID based filtering are not applicable for these HE_SU and HE_EXT_SU.
                filterPPDUWhenBSSColorMismatches(obj);
            else % EHT
                % EHT frames are always aggregated
                aggregatedMPDU = true;

                % Filter frames based on Uplink/Downlink indication. Note that BSSColoring
                % based filtering has already taken place after U-SIG decoding.
                obj.RxUplinkIndication = obj.EHTRecoveryConfig.UplinkIndication;
                filterPPDUWhenULorDLNotIntended(obj);

                % Filter frames based on STAID (NodeID/AID)
                obj.RxSTAID = obj.EHTRecoveryConfig.STAID;
                if ~obj.PPDUFiltered
                    filterPPDUWhenSTAIDMismatches(obj);
                    if ~obj.PPDUFiltered
                        indicationToMAC.Vector.PerUserInfo.StationID = obj.RxSTAID; % Return the STAID instead of TransmitterID for EHT
                    end
                end
                indicationToMAC.Vector.Channelization320MHz = obj.EHTRecoveryConfig.Channelization;
            end
            indicationToMAC.Vector.AggregatedMPDU = aggregatedMPDU;
            indicationToMAC.Vector.PPDUFormat = obj.RxFrameFormat;
            indicationToMAC.Vector.BSSColor = obj.RxBSSColor;
            indicationToMAC.Vector.PerUserInfo.NumSpaceTimeStreams = obj.NumSTS;
            userIdx = obj.UserIndexSU;
            indicationToMAC.Vector.PerUserInfo.Length = obj.RxDataLength(userIdx);
            indicationToMAC.Vector.PerUserInfo.MCS = obj.MCS(userIdx);
            indicationToMAC.Vector.TXOPDuration = obj.TXOPDuration;

            % Header process finished and move to the payload stage
            % processing
            obj.SignalDecodeStage = obj.Payload;
            if obj.PPDUFiltered
                % Filtered out (No match BSS color or No intended STA-ID),
                % First issue RxStartIndication then issue RxEndIndication
                % immediately. Reference: IEEE 802.11ax-2021 Figure 27-63
                % and IEEE 802.11be D6.0 Figure 36-80  - PHY receive state
                % machine
                obj.NextProcessingTime = obj.LastRunTimeNS;
                % Drop this packet as it is filtered out, i.e., not
                % intended for the receiver
                obj.DroppedPackets = obj.DroppedPackets + 1;
            else
                % Next invoke time is the end of payload
                mimoPreamAndPayloadDuration = obj.Signal.Duration - (obj.Signal.Metadata.PreambleDuration + obj.Signal.Metadata.HeaderDuration);
                obj.NextProcessingTime = obj.LastRunTimeNS + mimoPreamAndPayloadDuration;
            end
        else
            % If header decoding is failed, give RX-ERROR indication to MAC
            obj.SignalDecodeStage = obj.Cleanup;
            indicationToMAC = setRxErrorIndication(obj, indicationToMAC);
            if isLSIGFailed
                % The PPDU duration is not known if L-SIG check fails,
                % therefore set the reception timer to the current time and
                % perform CCA-ED during clean-up stage
                obj.NextProcessingTime = obj.LastRunTimeNS;
            else
                % L-SIG check passes but CRC check fails. The PPDU duration
                % is known after L-SIG check passes, therefore set the
                % reception timer to the end of PPDU
                mimoPreamAndPayloadDuration = obj.Signal.Duration - (obj.Signal.Metadata.PreambleDuration + obj.Signal.Metadata.HeaderDuration);
                obj.NextProcessingTime = obj.LastRunTimeNS + mimoPreamAndPayloadDuration;
            end
            % Reuse StationID field present in vector to store the source node ID
            indicationToMAC.Vector.PerUserInfo.StationID = obj.Signal.TransmitterID;
            % Update PHY Rx statistics
            obj.HeaderDecodeFailures = obj.HeaderDecodeFailures + 1;
            obj.DroppedPackets = obj.DroppedPackets + 1;
        end
    end

    function [indicationToMAC, frameToMAC] = processPayload(obj)
    %processPayload processes the MIMO preamble and decodes the payload
    %part of the waveform

        indicationToMAC = obj.DefaultIndicationToMAC;
        frameToMAC = [];
        if obj.PPDUFiltered
            indicationToMAC = setRxEndIndication(obj, indicationToMAC);
        else
            % Extract indices of x-STF and x-LTF fields in Rx waveform
            % MIMO preamble is only present for formats other than Non-HT
            samplesPerNanosec = obj.SampleRate*1e-9; % Number of samples per nanosecond
            isReceivedPacketNonHT = obj.RxFrameFormat == obj.NonHT;
            if ~isReceivedPacketNonHT
                stfStartIndex = (obj.Signal.Metadata.PreambleDuration + obj.Signal.Metadata.HeaderDuration) * samplesPerNanosec + 1;
                ltfEndIndex = stfStartIndex + obj.Signal.Metadata.MIMOPreambleDuration*samplesPerNanosec - 1;
                if obj.RxFrameFormat == obj.HTMixed
                    stfIndices = obj.FieldIndices.HTSTF;
                    ltfIndices = obj.FieldIndices.HTLTF;
                elseif obj.RxFrameFormat == obj.VHT
                    % For VHT, MIMO preamble ends at the end of VHT-SIG-B
                    stfIndices = obj.FieldIndices.VHTSTF;
                    vhtltfIndices = obj.FieldIndices.VHTLTF;
                    sigbIndices = obj.FieldIndices.VHTSIGB;
                    ltfIndices(1) = vhtltfIndices(1);
                    ltfIndices(2) = sigbIndices(2);
                elseif any(obj.RxFrameFormat == [obj.HE_SU obj.HE_EXT_SU])
                    stfIndices = obj.FieldIndices.HESTF;
                    ltfIndices = obj.FieldIndices.HELTF;
                else % EHT
                    stfIndices = obj.FieldIndices.EHTSTF;
                    ltfIndices = obj.FieldIndices.EHTLTF;
                end

                % Carrier lost during the reception of the PPDU, if the
                % expected STF/LTF indices do not match with actual STF/LTF
                % indices in waveform
                if (stfIndices(1) ~= stfStartIndex) || (ltfIndices(2) ~= ltfEndIndex)
                    indicationToMAC = handleCarrierLost(obj, indicationToMAC);
                    return
                end
            end

            % Extract indices of data in Rx waveform
            dataStartIndex = (obj.Signal.Metadata.PreambleDuration + obj.Signal.Metadata.HeaderDuration + obj.Signal.Metadata.MIMOPreambleDuration) * samplesPerNanosec + 1;
            dataEndIndex = dataStartIndex + obj.Signal.Metadata.PayloadDuration*samplesPerNanosec - 1;

            % Extract data field indices in Rx waveform
            if isReceivedPacketNonHT
                dataIndices = obj.FieldIndices.NonHTData;
            elseif obj.RxFrameFormat == obj.HTMixed
                dataIndices = obj.FieldIndices.HTData;
            elseif obj.RxFrameFormat == obj.VHT
                dataIndices = obj.FieldIndices.VHTData;
            elseif any(obj.RxFrameFormat == [obj.HE_SU obj.HE_EXT_SU])
                dataIndices = obj.FieldIndices.HEData;
            else % EHT
                dataIndices = obj.FieldIndices.EHTData;
            end

            % Carrier lost during the reception of the PPDU, if the
            % returned data indices are empty (note that NDP is not
            % expected therefore the data indices should not be empty) or
            % the expected data indices do not match with actual data
            % indices in waveform
            if isempty(dataIndices) || (dataIndices(1) ~= dataStartIndex) || (dataIndices(2) ~= dataEndIndex)
                indicationToMAC = handleCarrierLost(obj, indicationToMAC);
                return
            end

            % Combine the waveform in the interference buffer, down sampling to baseband and add thermal noise
            startTime = wlan.internal.utils.nanoseconds2seconds(obj.Signal.StartTime);
            endTime = startTime + wlan.internal.utils.nanoseconds2seconds(obj.Signal.Duration + obj.ToleratedDelay);

            [wavCombined, isResultantRateSameAsHeader] = getBBWaveform(obj, startTime, endTime);

            if isResultantRateSameAsHeader
                % Add thermal noise to the MIMO preamble and payload only
                % and synchronize as the sample rate is same for all
                % decoding stages
                if isReceivedPacketNonHT
                    % For Non-HT packets, there is no beamformed preamble,
                    % therefore payloadBB only contains the data field
                    payloadBB = wavCombined(dataStartIndex:end,:);
                else
                    % For other packets, beamformed preamble is present,
                    % therefore payloadBB contains MIMO preamble (x-STF and
                    % x-LTF) and data field
                    payloadBB = wavCombined(stfStartIndex:end,:);
                end
                payloadBB = applyThermalNoise(obj, payloadBB);
                rxPPDU = synchronizeWaveform(obj, [obj.RxPPDUWithInterference; payloadBB]);
            else
                % Decode PHY preamble and redo the synchronization as the
                % sample rate of payload has changed
                [indicationToMAC, rxPPDU] = handleCombinedWaveformWhenSRChanges(obj, wavCombined, indicationToMAC);
                if indicationToMAC.MessageType == obj.RxEndIndication
                    % Issue RxEndIndication indication and move to CCA-CS stage
                    return
                elseif isReceivedPacketNonHT && (obj.ResultantSampleRate(obj.Payload) ~= obj.ResultantSampleRate(obj.Header))
                    % Overwrite the L-LTF channel estimation and the noise variance for Non-HT packets as the sample rate has changed
                    obj.ChannelEstimate = obj.ChannelEstimateNonHT;
                    obj.NoiseVariance = obj.NoiseVarianceNonHT;
                end
            end

            % Carrier lost if there are not enough samples to finish
            % decoding process
            if notEnoughSamplesToProcessField(obj, dataIndices(2), rxPPDU)
                indicationToMAC = handleCarrierLost(obj, indicationToMAC);
                return
            end

            if ~isReceivedPacketNonHT
                % Apply HT/VHT/HE-STF AGC gain on the remaining of the combining waveform
                rxSTF = rxPPDU(obj.PacketOffset + double(stfIndices(1):stfIndices(2)), :);
                obj.MIMOSTFAGCGain = 1./(sqrt(mean(rxSTF(:).*conj(rxSTF(:)))));
                rxPPDU(obj.PacketOffset + double(stfIndices(1)):end,:) = rxPPDU(obj.PacketOffset + double(stfIndices(1)):end,:).*obj.MIMOSTFAGCGain;

                % MIMO channel estimation
                if obj.RxFrameFormat == obj.HTMixed
                    htltfDemod = wlanHTLTFDemodulate(rxPPDU(obj.PacketOffset + double(ltfIndices(1):ltfIndices(2)), :), obj.HTConfig);
                    obj.ChannelEstimate = wlanHTLTFChannelEstimate(htltfDemod, obj.HTConfig);
                elseif obj.RxFrameFormat == obj.VHT
                    ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-LTF', obj.VHTConfig.ChannelBandwidth, obj.VHTConfig.GuardInterval);
                    vhtltfDemod = wlan.internal.ofdmDemodulate(rxPPDU(obj.PacketOffset + double(vhtltfIndices(1):vhtltfIndices(2)), :), ofdmInfo, 0.75);
                    [obj.ChannelEstimate, obj.PilotEstimate] = wlanVHTLTFChannelEstimate(vhtltfDemod, obj.VHTConfig);
                elseif any(obj.RxFrameFormat == [obj.HE_SU obj.HE_EXT_SU])
                    ofdmInfo = wlan.internal.heOFDMInfo('HE-LTF', obj.HERecoveryConfig.ChannelBandwidth, obj.HERecoveryConfig.GuardInterval, obj.HERecoveryConfig.RUSize, obj.HERecoveryConfig.RUIndex);
                    heltfDemod = wlan.internal.ehtLTFDemodulate(rxPPDU(obj.PacketOffset + double(ltfIndices(1):ltfIndices(2)), :), obj.HERecoveryConfig.HELTFType, 0.75, ofdmInfo);
                    [obj.ChannelEstimate, obj.PilotEstimate] = wlanHELTFChannelEstimate(heltfDemod, obj.HERecoveryConfig);
                else % EHT
                    ofdmInfo = wlan.internal.ehtOFDMInfo('EHT-LTF', obj.EHTRecoveryConfig.ChannelBandwidth, obj.EHTRecoveryConfig.GuardInterval, obj.EHTRecoveryConfig.RUSize, obj.EHTRecoveryConfig.RUIndex);
                    ehtltfDemod = wlan.internal.ehtLTFDemodulate(rxPPDU(obj.PacketOffset + double(ltfIndices(1):ltfIndices(2)), :), obj.EHTRecoveryConfig.EHTLTFType, 0.75, ofdmInfo);
                    [obj.ChannelEstimate, obj.PilotEstimate] = wlanEHTLTFChannelEstimate(ehtltfDemod, obj.EHTRecoveryConfig);
                end
            end

            % Recover PSDU from waveform
            obj.PayloadIndices = dataIndices;
            [psdu, indicationToMAC] = recoverPayload(obj, rxPPDU, indicationToMAC);
            frameToMAC = obj.DefaultFrameToMAC;
            frameToMAC.MACFrame(obj.UserIndexSU).Data = psdu(:, 1);
            frameToMAC.MACFrame(obj.UserIndexSU).PSDULength = obj.RxDataLength(obj.UserIndexSU);
            metadata = obj.Signal.Metadata;
            numSubframes = metadata.NumSubframes(obj.UserIndexSU);
            % QoS Data frames contain application packet. Since full MAC/PHY does not
            % encode actual app packet information, MAC receiver cannot decode the
            % following app packet information. Hence this information is passed in
            % metadata.
            frameToMAC.PacketGenerationTime = metadata.PacketGenerationTime(obj.UserIndexSU,1:numSubframes);
            frameToMAC.PacketID = metadata.PacketID(obj.UserIndexSU,1:numSubframes);
            % To access a particular subframe's metadata information (packet ID, packet
            % generation time) above, MAC needs to know the exact subframe number in
            % the decoded MAC frame which is not possible because of potential subframe
            % reception failures. Hence MPDU sequence number is passed in metadata to
            % allow MAC in finding the exact subframe index by mapping the decoded
            % subframe's sequence number with the following list.
            frameToMAC.SequenceNumbers = metadata.MPDUSequenceNumber(obj.UserIndexSU,1:numSubframes);

            % Give RX-END indication, PSDU to MAC and
            % schedule a remove interference event
            indicationToMAC = setRxEndIndication(obj, indicationToMAC);
            obj.ReceivedPackets = obj.ReceivedPackets +1;
            obj.ReceivedPayloadBytes = obj.ReceivedPayloadBytes + obj.RxDataLength(obj.UserIndexSU);
        end
        obj.SignalDecodeStage = obj.Cleanup; % Remove signal
        obj.NextProcessingTime = obj.LastRunTimeNS; % Reset
    end

    function handleNewSignal(obj, signal)
    %handleNewSignal Considers the WLAN frame above the ED threshold for
    %processing when the PrimaryChannelCCAIdle and RxOn are true. Updates
    %the new entry of valid WLAN signal in a buffer along with transmitting
    %node ID, received signal power in dBm, its reception absolute (in
    %simulation time stamp) start and end times, sample rate, signal type,
    %channel bandwidth, and center frequency. Ignores the WLAN frame below
    %ED threshold and non-WLAN frame.

        assert(wlan.internal.utils.seconds2nanoseconds(signal.StartTime)==obj.LastRunTimeNS,'No propagation delay expected');

        % Apply Rx Gain
        scale = 10.^(obj.RxGain/20);
        signal.Data = signal.Data * scale;

        % Add receiver gain to signal power
        signal.Power = signal.Power + obj.RxGain;

        isSignalDecodable = false;
        isSignalNonOverlapping = false;
        isSignalFreqOverlapping = isFrequencyOverlappingWithReceiverBandwidth(obj, signal);

        if obj.RxOn
            if obj.PrimaryChannelCCAIdle || (~isempty(obj.Signal) && obj.Signal.TechnologyType == wnet.TechnologyType.WLAN && obj.Signal.StartTime == obj.LastRunTimeNS)
                % If CCA idle or currently processing a signal which starts at the same time as this signal
                if signal.Power >= obj.EDThreshold
                    isSignalDecodable = initiateReception(obj, signal);
                    isSignalNonOverlapping = ~(isSignalDecodable || isSignalFreqOverlapping);
                else
                    % Signal power of the current individual waveform is
                    % less than ED threshold
                    obj.EnergyDetectionsBelowEDThreshold = obj.EnergyDetectionsBelowEDThreshold + 1;
                end
            else
                % Waveform is received when the node is already in
                % receive state
                obj.ReceiveTriggersWhileReception = obj.ReceiveTriggersWhileReception + 1;
            end
        else
            % Receiver antenna is switched off (Transmission is in progress)
            obj.ReceiveTriggersWhileTransmission = obj.ReceiveTriggersWhileTransmission + 1;
        end

        if ~(isSignalDecodable || isSignalNonOverlapping)
            % Update PHY Rx statistics
            obj.DroppedPackets = obj.DroppedPackets + 1; % Dropped packets do not include the WLAN signal of not frequency overlapping
        end

        % Update ACI related statistics
        getACIStats(obj, isSignalFreqOverlapping);

        % Add packet to the interference buffer
        addPacket(obj.Interference, signal);
    end

    function isSignalDecodable = initiateReception(obj, signal)
    %initiateReception Initiate the reception of new signal

        % Signal is only decodable if the received signal is WLAN and any subchannel of received signal aligns with the receiver primary channel
        isSignalDecodable = (signal.TechnologyType == wnet.TechnologyType.WLAN) && isAnySubChannelFrequencyMatchingPrimary(obj, signal);

        if isSignalDecodable
            % Indicate transition to reception state
            indicateStateTransition(obj, signal);

            if (signal.Power > obj.RxSignalPower)
                % Change the SOI units to make it inline with units of dependent operations
                signal.Bandwidth = signal.Bandwidth*1e-6;
                signal.StartTime = wlan.internal.utils.seconds2nanoseconds(signal.StartTime);
                signal.Duration = wlan.internal.utils.seconds2nanoseconds(signal.Duration);

                % Store the context of WLAN signal received with high power as it is
                % assumed to be SOI
                obj.RxSignalPower = signal.Power;

                % Initialize spatial reuse flag
                obj.SROpportunityIdentified = false;

                % Store the information of received waveform except for actual IQ samples
                obj.Signal = rmfield(signal,"Data");

                % Update the signal decode stage and signal processing flag
                obj.SignalDecodeStage = obj.Preamble;

                % Set the reception timer to preamble duration
                obj.NextProcessingTime = obj.Signal.Metadata.PreambleDuration + obj.LastRunTimeNS; % in nanoseconds

                % Configure the operating frequency, BW, and baseband sample rate of receiver for processing the current SOI
                configureReceiverForProcessingCurrentSOI(obj);
            end
        end
    end
end

% Static helper methods for waveform decode
methods (Static, Access = private)
    function decimalVal = binaryToDecimal(binaryVal)
    %binaryToDecimal Convert binary to decimal

        decimalVal = 0;
        mul = 1;
        for idx = 1:numel(binaryVal)
            decimalVal = decimalVal + mul*binaryVal(idx);
            mul = mul*2;
        end
    end

    function ind = getSignalingIndices(chanBW)
    %getSignalingIndices Get signaling field indices (L-STF to U-SIG) of
    %packets

        % Assume we only know about the channel bandwidth and return the
        % pre-EHT field indices
        trc = wlan.internal.ehtTimingRelatedConstants(chanBW, 3.2, 4, 4); % Use defaults

        cbw = wlan.internal.cbwStr2Num(chanBW);
        sf = cbw*1e-3; % Scaling factor to convert bandwidth and time in ns to samples

        % L-STF
        nFieldSamples = trc.TLSTF*sf;
        indLSTF = [1 nFieldSamples];
        numCumSamples = nFieldSamples;

        % L-LTF
        nFieldSamples = trc.TLLTF*sf;
        indLLTF = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;

        % L-SIG
        nFieldSamples = trc.TLSIG*sf;
        indLSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;

        % RL-SIG
        nFieldSamples = trc.TRLSIG*sf;
        indRLSIG = [numCumSamples+1 numCumSamples+nFieldSamples];
        numCumSamples = numCumSamples+nFieldSamples;

        % U-SIG
        nFieldSamples = trc.TUSIG*sf;
        indUSIG = [numCumSamples+1 numCumSamples+nFieldSamples];

        % Return indices for all fields above
        ind = struct( ...
                'LSTF', uint32(indLSTF), ...
                'LLTF', uint32(indLLTF), ...
                'LSIG', uint32(indLSIG), ...
                'RLSIG', uint32(indRLSIG), ...
                'USIG', uint32(indUSIG));
    end
end

% Waveform decode methods
methods (Access = private)
    function getLLTFChanEstAndNoiseVar(obj, rxPPDU)
    %getLLTFChanEstAndNoiseVar Calculates the LLTF channel estimation and
    %noise variance

        ind = obj.SignalingFieldIndices;
        % Get the L-LTF field from rxPPDU.
        rxLLTF = rxPPDU(obj.PacketOffset + double(ind.LLTF(1):ind.LLTF(2)), :);
        % Demodulate L-LTF
        obj.RecoveredLLTF = wlanLLTFDemodulate(rxLLTF, obj.ChannelBandwidthStr);
        % Calculate Non-HT channel estimation
        obj.ChannelEstimateNonHT = wlanLLTFChannelEstimate(obj.RecoveredLLTF, obj.ChannelBandwidthStr);
        % Calculate Non-HT Noise variance
        obj.NoiseVarianceNonHT = wlanLLTFNoiseEstimate(obj.RecoveredLLTF);
    end

    function [flagIsHeaderValid, flagIsLSIGFailed] = handleSIGFields(obj, rxPPDU)
    %handleSIGFields Handles signaling fields of all supported formats
        switch obj.RxFrameFormat
            case obj.HTMixed
                maxBWForCurrentFrameFormat = 40; % MHz
            case {obj.VHT obj.HE_SU obj.HE_EXT_SU}
                maxBWForCurrentFrameFormat = 160;
            otherwise
                % Non-HT and EHT
                maxBWForCurrentFrameFormat = 320;
        end

        if obj.Signal.Bandwidth > maxBWForCurrentFrameFormat
            % This protects the case of incorrect format detection for
            % the SOI. In this case, the bandwidth of SOI could exceed
            % the maximum supported of detected format. Treat this as
            % an invalid header and L-SIG decoding error.
            flagIsHeaderValid = false;
            flagIsLSIGFailed = true;
        else
            [flagIsHeaderFailed, flagIsLSIGFailed] = recoverSIGFields(obj, rxPPDU);
            flagIsHeaderValid = ~flagIsHeaderFailed;
        end
    end

    function [failHeaderCheck, failLSIGCheck] = recoverSIGFields(obj, rxPPDU)
    %recoverSIGFields Recovers SIG fields (L-SIG, RL-SIG, HT-SIG, VHT-SIG-A, HE-SIG-A, U-SIG, EHT-SIG) of the Rx PPDU

        failHeaderCheck = true; % Header check fails by default
        isHE = any(obj.RxFrameFormat == [obj.HE_SU, obj.HE_EXT_SU]);

        if obj.RxFrameFormat == obj.EHT_MU || isHE
            % Process L-SIG and RL-SIG
            rxLLTF = rxPPDU(obj.PacketOffset + double(obj.SignalingFieldIndices.LLTF(1):obj.SignalingFieldIndices.LLTF(2)), :);

            % Demodulated L-LTF symbols include tone rotation for each 20 MHz subblock. The L-LTF channel estimates (with tone
            % rotation) are used to equalize and decode the pre-EHT-LTF fields.
            ofdmInfo = wlan.internal.ehtOFDMInfo('L-LTF', obj.EHTRecoveryConfig.ChannelBandwidth);
            % Add extra L-SIG tones onto NumTones so we scale at receiver
            % the same for L-SIG field
            ofdmInfo.NumTones = ofdmInfo.NumTones + 4*ofdmInfo.NumSubchannels;
            lltfDemod = wlan.internal.demodulateLLTF(rxLLTF, ofdmInfo, 0.75);
            lltfChanEst = wlanLLTFChannelEstimate(lltfDemod,obj.EHTRecoveryConfig.ChannelBandwidth);

            % L-SIG and RL-SIG Decoding
            rxLSIG = rxPPDU(obj.PacketOffset + double(obj.SignalingFieldIndices.LSIG(1):obj.SignalingFieldIndices.RLSIG(2)), :);

            % OFDM demodulate
            ofdmInfo = wlan.internal.ehtOFDMInfo('L-SIG', obj.EHTRecoveryConfig.ChannelBandwidth);
            ehtlsigDemod = wlan.internal.ofdmDemodulate(rxLSIG, ofdmInfo, 0.75);

            % Phase tracking
            ehtlsigDemod = wlanEHTTrackPilotError(ehtlsigDemod, lltfChanEst, obj.EHTRecoveryConfig, 'L-SIG');
            % Estimate channel on extra 4 subcarriers per subchannel and create full channel estimate
            preEHTInfo = wlan.internal.ehtOFDMInfo('L-SIG', obj.EHTRecoveryConfig.ChannelBandwidth);
            obj.ChannelEstimatePreEHT = wlanPreEHTChannelEstimate(ehtlsigDemod, lltfChanEst, obj.EHTRecoveryConfig.ChannelBandwidth);

            % Average L-SIG and RL-SIG before equalization
            ehtlsigDemod = mean(ehtlsigDemod,2);

            % Equalize data carrying subcarriers, merging 20 MHz subchannels
            [symMerge, chanMerge] = wlan.internal.mergeSubchannels(ehtlsigDemod(preEHTInfo.DataIndices,:,:), obj.ChannelEstimatePreEHT(preEHTInfo.DataIndices,:,:), preEHTInfo.NumSubchannels);

            % Equalize
            [eqLSIGSym, csi] = wlan.internal.equalize(symMerge, chanMerge,'MMSE', obj.NoiseVarianceNonHT);

            % Decode L-SIG field
            [~, failLSIGCheck, lsigInfo] = wlanLSIGBitRecover(eqLSIGSym, obj.NoiseVarianceNonHT, csi);
            if failLSIGCheck
                return;
            end

            if isHE % Get the length information from the recovered L-SIG bits and update the L-SIG length property of the recovery configuration object
                obj.HERecoveryConfig.LSIGLength = lsigInfo.Length;
            else % EHT-SU
                obj.EHTRecoveryConfig.LSIGLength = lsigInfo.Length;
            end
        else
            rxSIG = rxPPDU(obj.PacketOffset+(obj.SignalingFieldIndices.LSIG(1):obj.SignalingFieldIndices.LSIG(2)), :);
            [lsigBits, failLSIGCheck, lsigInfo] = wlan.internal.legacyLSIGRecover(rxSIG, obj.ChannelEstimateNonHT, obj.NoiseVarianceNonHT, obj.ChannelBandwidthStr);
            if failLSIGCheck % LSIG bits fail the parity check
                return
            end
            % Get L-SIG field from Rx PPDU
            PSDULength = wlan.internal.phy.FullPHYRx.binaryToDecimal(lsigInfo.Length.');
            % Check for invalid parameters
            failLSIGCheck = PSDULength == 0;
            if failLSIGCheck % Unexpected field value
                return
            end
        end

        % Recover and interpret SIG field parameters
        if obj.RxFrameFormat == obj.NonHT
            % Update PHY configuration fields, if L-SIG is successfully decoded
            obj.NonHTConfig.MCS = lsigInfo.MCS(1);
            obj.MCS(obj.UserIndexSU) = lsigInfo.MCS(1);
            obj.NonHTConfig.PSDULength = lsigInfo.Length(1);
            obj.RxDataLength(obj.UserIndexSU) = lsigInfo.Length(1);
            obj.NumSTS = 1;

            % Return Non-HT channel estimation and noise variance
            obj.ChannelEstimate = obj.ChannelEstimateNonHT;
            obj.NoiseVariance = obj.NoiseVarianceNonHT;

            % Update field indices
            obj.FieldIndices = wlanFieldIndices(obj.NonHTConfig);
        elseif obj.RxFrameFormat == obj.HTMixed
            % Recover and interpret HT-SIG field parameters
            startIdx = obj.SignalingFieldIndices.RLSIG(1); % Start of HT-SIG field
            endIdx = obj.SignalingFieldIndices.RLSIG(2) + 80*obj.CurrentChannelBandwidth/20; % End of HT-SIG field = RLSIG(2) + Number of samples in a 4us symbol
            htSIGIdx = [startIdx endIdx];
            % Get HT-SIG field from Rx PPDU
            if notEnoughSamplesToProcessField(obj, htSIGIdx(2), rxPPDU)
                return
            end

            % Decode HT-SIG
            [htsigBits, sigCRCFail] = wlanHTSIGRecover(rxPPDU(obj.PacketOffset+double(htSIGIdx(1):htSIGIdx(2)), :), obj.ChannelEstimateNonHT, obj.NoiseVarianceNonHT, obj.HTConfig.ChannelBandwidth);

            if sigCRCFail
                return
            end

            % Recover HT PHY parameters using HT SIG bits
            htsigBits = double(reshape(htsigBits, 24, 2)');
            if logical(htsigBits(1,8))
                obj.HTConfig.ChannelBandwidth = 'CBW40';
            end
            mcs = obj.binaryToDecimal(htsigBits(1,1:7));
            if mcs > 31
                return
            end
            obj.HTConfig.MCS = mcs;
            obj.HTConfig.PSDULength = obj.binaryToDecimal(htsigBits(1,9:24));
            obj.HTConfig.RecommendSmoothing = logical(htsigBits(2, 1));
            obj.HTConfig.AggregatedMPDU = logical(htsigBits(2, 4));
            Nss = floor(mcs/8)+1;
            obj.HTConfig.NumSpaceTimeStreams = Nss;
            obj.HTConfig.NumTransmitAntennas = Nss;
            obj.RxDataLength(obj.UserIndexSU) = obj.HTConfig.PSDULength;
            obj.MCS(obj.UserIndexSU) = obj.HTConfig.MCS;
            obj.NumSTS(obj.UserIndexSU) = obj.HTConfig.NumSpaceTimeStreams;

            % Update field indices
            obj.FieldIndices = wlanFieldIndices(obj.HTConfig);
        elseif obj.RxFrameFormat == obj.VHT
            indSIGA = wlanFieldIndices(obj.VHTConfig,'VHT-SIG-A');
            vhtSIGAIdx = [indSIGA(1) indSIGA(2)];

            % Get VHT-SIG-A field from Rx PPDU
            if notEnoughSamplesToProcessField(obj, vhtSIGAIdx(2), rxPPDU)
                return
            end

            % Decode VHT-SIG-A
            [recVHTSIGA, sigaCRCFail] = wlanVHTSIGARecover(rxPPDU(obj.PacketOffset+double(vhtSIGAIdx(1):vhtSIGAIdx(2)), :), obj.ChannelEstimateNonHT, obj.NoiseVarianceNonHT, obj.VHTConfig.ChannelBandwidth);
            if sigaCRCFail
                return
            end

            % Retrieve packet parameters based on decoded L-SIG and VHT-SIG-A
            % Bandwidth information is set within vhtConfigRecover
            [obj.VHTConfig, ~, ~, ~, failInterp] = wlan.internal.vhtConfigRecover(lsigBits, recVHTSIGA, SuppressError=true);

            % Decoded bandwidth can not exceed the maximum supported BW of receiver configuration
            isValidBW = wlan.internal.cbwStr2Num(obj.VHTConfig.ChannelBandwidth) <= obj.ChannelBandwidth;

            if failInterp || ~isValidBW || obj.VHTConfig.NumUsers ~= 1
                % Cannot interpret the received bits.
                return
            end

            obj.RxDataLength(obj.UserIndexSU) = obj.VHTConfig.PSDULength(1);
            obj.MCS(obj.UserIndexSU) = obj.VHTConfig.MCS(1);
            obj.NumSTS(obj.UserIndexSU) = obj.VHTConfig.NumSpaceTimeStreams(1);

            % Update field indices
            obj.FieldIndices = wlanFieldIndices(obj.VHTConfig);
        elseif isHE % HE-SU or HE-EXT-SU
            heSIGAIdx = wlanFieldIndices(obj.HERecoveryConfig,'HE-SIG-A');

            % Recover and decode HE-SIG-A field
            if notEnoughSamplesToProcessField(obj, heSIGAIdx(2), rxPPDU)
                return
            end

            preheInfo = wlan.internal.heOFDMInfo('HE-SIG-A', obj.HERecoveryConfig.ChannelBandwidth);
            [rxSIGABits, sigaCRCFail] = wlan.internal.heSIGARecover(rxPPDU(obj.PacketOffset+double(heSIGAIdx(1):heSIGAIdx(2)),:), obj.ChannelEstimatePreEHT, obj.NoiseVarianceNonHT, preheInfo, obj.HERecoveryConfig);

            % HE-SIG-A: check CRC
            if sigaCRCFail
                return
            end
            % Recover HE configuration from HE-SIG-A bits
            % Bandwidth information is set within vhtConfigRecover
            [obj.HERecoveryConfig, failInterpretation] = interpretHESIGABits(obj.HERecoveryConfig, rxSIGABits);

            % Decoded bandwidth can not exceed the maximum supported BW of receiver configuration
            isValidBW = wlan.internal.cbwStr2Num(obj.HERecoveryConfig.ChannelBandwidth) <= obj.ChannelBandwidth;

            % Do not process unsupported transmission parameters
            if failInterpretation || obj.HERecoveryConfig.HighDoppler==1 || ~isValidBW
                return;
            end

            % End of HE-SIG-A decoding
            obj.MCS(obj.UserIndexSU) = obj.HERecoveryConfig.MCS;
            obj.RxDataLength(obj.UserIndexSU) = getPSDULength(obj.HERecoveryConfig);
            obj.NumSTS = obj.HERecoveryConfig.NumSpaceTimeStreams;
            obj.RxBSSColor = obj.HERecoveryConfig.BSSColor;
            obj.TXOPDuration = obj.HERecoveryConfig.TXOPDuration;

            % Update field indices
            obj.FieldIndices = wlanFieldIndices(obj.HERecoveryConfig);
        else % EHT-SU
            usigIndex = wlanFieldIndices(obj.EHTRecoveryConfig,'U-SIG');

            % Recover and decode U-SIG field
            if notEnoughSamplesToProcessField(obj, usigIndex(2), rxPPDU)
                return
            end

            preEHTInfo = wlan.internal.ehtOFDMInfo('U-SIG', obj.EHTRecoveryConfig.ChannelBandwidth);
            [usigBits, failCRC] = wlan.internal.ehtUSIGRecover(rxPPDU(obj.PacketOffset+double(usigIndex(1):usigIndex(2)), :), obj.ChannelEstimatePreEHT, obj.NoiseVarianceNonHT, preEHTInfo, obj.EHTRecoveryConfig);
            if all(failCRC) % If every 80 MHz subblock fails then stop processing
                return
            end

            [obj.EHTRecoveryConfig, failInterpretation] = interpretUSIGBits(obj.EHTRecoveryConfig, usigBits, failCRC);

            % Do not process unsupported EHT transmission formats, unsupported bandwidth or incorrectly decoded bandwidth (signaling field is corrupted)
            if failInterpretation
                return
            end

            if obj.EHTRecoveryConfig.PPDUType==wlan.type.EHTPPDUType.su
                obj.RxFrameFormat = wlan.internal.FrameFormats.EHT_SU; % Reset EHT packet format after U-SIG recovery
            else
                obj.RxFrameFormat = -1; % Other EHT PPDU formats are not supported
                return
            end

            % Set the relevant field after U-SIG recovery
            obj.RxBSSColor = obj.EHTRecoveryConfig.BSSColor;
            obj.TXOPDuration = obj.EHTRecoveryConfig.TXOPDuration;

            % Set the flag 'PPDUFiltered' to true if the spatial reuse
            % feature is enabled and the received PPDU can be ignored.
            % The EHT_SIG field is not processed. Reference: Figure
            % 36-80, IEEE P802.11be/D5.0 - PHY receive state machine
            filterPPDUWhenBSSColorMismatches(obj);
            if ~obj.PPDUFiltered
                % Process EHT-SIG common field
                sigIndex = wlanFieldIndices(obj.EHTRecoveryConfig, 'EHT-SIG'); % Get EHT-SIG field symbols

                % Recover and decode EHT-SIG field
                if notEnoughSamplesToProcessField(obj, sigIndex(2), rxPPDU)
                    return
                end

                [ehtsigCommonBits, failCRC, csi, eqSIGSymComb] = wlan.internal.ehtSIGCommonRecover(rxPPDU(obj.PacketOffset+double(sigIndex(1):sigIndex(2)), :), obj.ChannelEstimatePreEHT, obj.NoiseVarianceNonHT, preEHTInfo, obj.EHTRecoveryConfig);
                if all(failCRC,'all') % If CRC fails for all encoding blocks
                    return
                end

                [obj.EHTRecoveryConfig, failInterpretation] = interpretEHTSIGCommonBits(obj.EHTRecoveryConfig, ehtsigCommonBits, failCRC);
                if failInterpretation
                    return
                end

                % Process EHT-SIG user field
                [userBits, failCRC] = wlanEHTSIGUserBitRecover(eqSIGSymComb, obj.NoiseVarianceNonHT, obj.EHTRecoveryConfig, csi);
                if all(failCRC) % Discard the packet if all users fail the CRC
                    return
                end

                [userConfig, failInterpretation] = interpretEHTSIGUserBits(obj.EHTRecoveryConfig, userBits, failCRC);
                % Do not process unsupported transmission parameters
                if failInterpretation
                    return
                end
                obj.EHTRecoveryConfig = userConfig{1};

                % End of EHT-SIG field decoding
                obj.MCS(obj.UserIndexSU) = obj.EHTRecoveryConfig.MCS;
                obj.RxDataLength(obj.UserIndexSU) = psduLength(obj.EHTRecoveryConfig);
                obj.NumSTS = obj.EHTRecoveryConfig.NumSpaceTimeStreams;

                % Update field indices
                obj.FieldIndices = wlanFieldIndices(obj.EHTRecoveryConfig); % The index for EHT-Data field is same for all users
            end
        end
        failHeaderCheck = false; % Decode header successfully
    end

    function [detected, rxPPDU] = packetDetectionAndFreqCorrection(obj, rxPPDU)
    %packetDetectionAndFreqCorrection Detects the packet and
    %performs frequency correction on the given waveform.

        detected = true;
        % Identify packet offset and determine coarse packet offset
        startOffset = wlanPacketDetect(rxPPDU, obj.ChannelBandwidthStr);
        ind = obj.SignalingFieldIndices;

        % No packet is detected or packet detection is likely incorrect
        if isempty(startOffset) || (startOffset+double(ind.LSIG(2))>size(rxPPDU,1))
            detected = false;
        else
            obj.PacketOffset = startOffset(1);
            % Extract L-STF and perform coarse frequency offset
            % correction
            lstf = rxPPDU((obj.PacketOffset + double(ind.LSTF(1):ind.LSTF(2))), :);
            cfo = wlanCoarseCFOEstimate(lstf, obj.ChannelBandwidthStr);
            rxPPDU = frequencyOffset(rxPPDU, obj.SampleRate, -cfo);

            % Extract Non-HT fields and perform symbol timing
            % synchronization
            nonHTFields = rxPPDU(obj.PacketOffset + double(ind.LSTF(1):ind.LSIG(2)), :);
            startOffset = wlanSymbolTimingEstimate(nonHTFields, obj.ChannelBandwidthStr);
            obj.PacketOffset = obj.PacketOffset + startOffset(1);
            % Catch any extreme packet offsets to prevent indexing errors
            obj.PacketOffset = max(obj.PacketOffset, -(double(ind.LLTF(1))-1));

            % No packet is detected if the minimum packet length is
            % less than 5 OFDM symbols or the packet is detected
            % outwith the range of the expected delays from the channel
            if (obj.PacketOffset + double(ind.LSIG(2))) > size(rxPPDU,1) || obj.PacketOffset > wlan.internal.utils.nanoseconds2microseconds(obj.ToleratedDelay)*obj.ChannelBandwidth
                detected = false;
                obj.FrequencyOffsetCorrection = -cfo; % Set frequency offset for frequency corrector
            else
                % Extract L-LTF and perform fine frequency offset correction
                lltf = rxPPDU(obj.PacketOffset + double(ind.LLTF(1):ind.LLTF(2)), :);
                ffo = wlanFineCFOEstimate(lltf, obj.ChannelBandwidthStr);
                rxPPDU = frequencyOffset(rxPPDU, obj.SampleRate, -ffo);
                obj.FrequencyOffsetCorrection = -ffo-cfo; % Set frequency offset for frequency corrector
            end

            % Scale the waveform based on L-STF power (AGC)
            gain = 1./(sqrt(mean(lstf(:).*conj(lstf(:)))));
            rxPPDU = rxPPDU.*gain;
            obj.LSTFAGCGain = gain;
        end
    end

    function [data, indicationToMAC] = recoverPayload(obj, rxPPDU, indicationToMAC)
    %recoverPayload Recovers the payload from the received PPDU
        % Extract data field from PPDU
        receivedData = rxPPDU(obj.PacketOffset + double(obj.PayloadIndices(1):obj.PayloadIndices(2)), :);
        pilotTrackingParams = struct('CalculateCPE', false, 'CalculateAE', false, 'TrackPhase', true, 'TrackAmplitude', false);

        if (obj.RxFrameFormat == obj.NonHT)
            s = validateConfig(obj.NonHTConfig);
            numOFDMSym = s.NumDataSymbols;
            ofdmInfo = wlan.internal.vhtOFDMInfo('NonHT-Data', obj.ChannelBandwidthStr);
            minInputLen = numOFDMSym * (ofdmInfo.FFTLength + ofdmInfo.CPLength);
            demod = wlan.internal.legacyOFDMDemodulate(receivedData(1:minInputLen,:), ofdmInfo, 0.75, 1); % Use default value of OFDM symbol offset

            % Offset by 1 to account for L-SIG pilot symbol
            z = 1;
            refPilots = wlan.internal.nonHTPilots(numOFDMSym, z, obj.ChannelBandwidthStr);
            demod = wlan.internal.trackPilotErrorCore(demod, obj.ChannelEstimate(ofdmInfo.PilotIndices,:,:), refPilots, ofdmInfo, pilotTrackingParams);

            % Merge subchannel channel estimates and demodulated symbols
            % together for the repeated subcarriers for data carrying
            % subcarriers
            [ofdmDataOutOne20MHz, chanEstDataOne20MHz] = wlan.internal.mergeSubchannels(demod(ofdmInfo.DataIndices,:,:), obj.ChannelEstimate(ofdmInfo.DataIndices,:,:), ofdmInfo.NumSubchannels);
            [eqDataSym, csiData] = wlan.internal.equalize(ofdmDataOutOne20MHz, chanEstDataOne20MHz, 'MMSE', obj.NoiseVariance);
            [data, scramInit, serviceBits] = wlanNonHTDataBitRecover(eqDataSym, obj.NoiseVariance, csiData, obj.NonHTConfig);

            % Interpret the state of scrambler and update parameters related to bandwidth signaling
            centerFreqIndex1 = 0; % 80+80 MHz channelization is not supported
            [interpretedChanBW, interpretedBWOperation] = wlanInterpretScramblerState(scramInit, centerFreqIndex1, serviceBits);
            if interpretedBWOperation
                obj.NonHTConfig.BandwidthOperation = 'Dynamic';
            else
                obj.NonHTConfig.BandwidthOperation = 'Static';
            end
            % Return the interpreted Non-HT DUP parameter in the
            % rxVector PHY would try to interpret at best as the
            % validity of these parameters is determined by the MAC
            if strcmpi(interpretedChanBW, 'Unknown')
                indicationToMAC.Vector.NonHTChannelBandwidth = 0;
            else
                indicationToMAC.Vector.NonHTChannelBandwidth = wlan.internal.cbwStr2Num(interpretedChanBW);
            end
            indicationToMAC.Vector.BandwidthOperation = obj.NonHTConfig.BandwidthOperation;
            indicationToMAC.Vector.ScramblerInitialValue = scramInit; % Place holder for MU-RTS, potentially needs to transform the scram state to initial value when supporting OFDMA in the future
        elseif (obj.RxFrameFormat == obj.HTMixed)
            % Recover information bits
            obj.NoiseVariance = wlan.internal.htNoiseEstimate(receivedData, obj.ChannelEstimate, obj.HTConfig);
            data = wlanHTDataRecover(receivedData, obj.ChannelEstimate, obj.NoiseVariance, obj.HTConfig, LDPCDecodingMethod='norm-min-sum', EarlyTermination=true);
        elseif (obj.RxFrameFormat == obj.VHT)
            ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-Data', obj.VHTConfig.ChannelBandwidth, obj.VHTConfig.GuardInterval);
            sym = wlan.internal.ofdmDemodulate(receivedData, ofdmInfo, 0.75);

            % Phase tracking using channel estimate for SSPilots
            pilotEstTrack = mean(obj.PilotEstimate,2);
            trackedSym = wlan.internal.vhtTrackPilotError(sym, pilotEstTrack, obj.VHTConfig.ChannelBandwidth, 'VHT-Data', pilotTrackingParams);

            % Noise estimate and equalization
            obj.NoiseVariance = vhtNoiseEstimate(trackedSym(ofdmInfo.PilotIndices,:,:), obj.PilotEstimate, obj.VHTConfig);
            [eqSym,csi] = wlan.internal.vhtEqualize(trackedSym, obj.ChannelEstimate, obj.NoiseVariance, obj.VHTConfig, 'VHT-Data', 1); % Equalization and STBC combining

            % Recover information bits
            ldpcParams = wlan.internal.getLDPCBitRecoveryParams('EarlyTermination', true);
            cfgInfo = validateConfig(obj.VHTConfig, 'MCS');
            data = wlan.internal.vhtDataBitRecover(eqSym(ofdmInfo.DataIndices, 1:cfgInfo.NumDataSymbols, :), obj.NoiseVariance, csi(ofdmInfo.DataIndices,:), obj.VHTConfig, ldpcParams, 1);
        elseif any(obj.RxFrameFormat == [obj.HE_SU, obj.HE_EXT_SU]) % HE-SU or HE-EXT-SU
            % User configuration
            userCfg = obj.HERecoveryConfig;

            % Data demodulate
            ofdmInfo = wlan.internal.heOFDMInfo('HE-Data', userCfg.ChannelBandwidth, userCfg.GuardInterval, userCfg.RUSize, userCfg.RUIndex);
            demodSym = wlan.internal.ofdmDemodulate(receivedData, ofdmInfo, 0.75);

            % Phase tracking using channel estimate for SSPilots
            pilotEstTrack = mean(obj.PilotEstimate,2);
            demodSym = wlanHETrackPilotError(demodSym, pilotEstTrack, userCfg, 'HE-Data');

            % Estimate noise power in HE fields
            heInfo = wlan.internal.heOFDMInfo('HE-Data', userCfg.ChannelBandwidth, userCfg.GuardInterval, userCfg.RUSize, userCfg.RUIndex);
            demodPilotSym = demodSym(heInfo.PilotIndices, :, :);
            obj.NoiseVariance = wlanHEDataNoiseEstimate(demodPilotSym, obj.PilotEstimate, userCfg);
            obj.MCS(obj.UserIndexSU) = userCfg.MCS;

            % Equalization and STBC combining
            if userCfg.STBC
                % Only SU, get num of SS from size of channel estimate
                nss = size(obj.ChannelEstimate,2)/2;
                [eqSym,csi] = wlan.internal.stbcCombine(demodSym,obj.ChannelEstimate,nss,'MMSE',obj.NoiseVariance);
            else
                % Equalize
                [eqSym,csi] = wlan.internal.equalize(demodSym,obj.ChannelEstimate,'MMSE',obj.NoiseVariance);
            end

            updatedheInfo = wlan.internal.heOFDMInfo('HE-Data', userCfg.ChannelBandwidth, userCfg.GuardInterval, userCfg.RUSize, userCfg.RUIndex);

            data = wlanHEDataBitRecover(eqSym(updatedheInfo.DataIndices, :, :), obj.NoiseVariance, csi(updatedheInfo.DataIndices, :, :), userCfg, LDPCDecodingMethod='norm-min-sum', EarlyTermination=true);
            obj.RxDataLength(obj.UserIndexSU) = numel(data)/8;
        else % EHT SU
            userCfg = obj.EHTRecoveryConfig;

            % Data demodulate
            ofdmInfo = wlan.internal.ehtOFDMInfo('EHT-Data', userCfg.ChannelBandwidth, userCfg.GuardInterval, userCfg.RUSize, userCfg.RUIndex);
            demodSym = wlan.internal.ofdmDemodulate(receivedData, ofdmInfo, 0.75);

            % Phase tracking using channel estimate for SSPilots
            pilotEstTrack = mean(obj.PilotEstimate,2);
            demodSym = wlanEHTTrackPilotError(demodSym, pilotEstTrack, userCfg, 'EHT-Data');

            % Estimate noise power in HE fields
            ehtInfo = wlan.internal.ehtOFDMInfo('EHT-Data', userCfg.ChannelBandwidth, userCfg.GuardInterval, userCfg.RUSize, userCfg.RUIndex);

            demodPilotSym = demodSym(ehtInfo.PilotIndices, :, :);
            obj.NoiseVariance = wlanEHTDataNoiseEstimate(demodPilotSym, obj.PilotEstimate, userCfg);
            obj.MCS(obj.UserIndexSU) = userCfg.MCS;

            % Equalization
            [eqSym, csi] = wlan.internal.equalize(demodSym,obj.ChannelEstimate,'MMSE',obj.NoiseVariance);

            % Data field recovery
            data = wlanEHTDataBitRecover(eqSym(ehtInfo.DataIndices, :, :), obj.NoiseVariance, csi(ehtInfo.DataIndices, :, :), userCfg, EarlyTermination=true);
            obj.RxDataLength(obj.UserIndexSU) = numel(data)/8;
        end
    end

    function [isValidPreamble, rxPPDU] = decodePreamble(obj, rxPPDU)
        %decodePreamble Decodes preamble of the received PPDU
        [isValidPreamble, rx] = obj.packetDetectionAndFreqCorrection(rxPPDU);
        if isValidPreamble
            rxPPDU = rx;
            % Calculate channel estimation and noise variance
            obj.getLLTFChanEstAndNoiseVar(rxPPDU);
        end
    end

    function isValidFormat = detectFormat(obj, rxPPDU)
        % Get the format of the receive packet Synthetically
        fmtDetInd = obj.PacketOffset+double(obj.SignalingFieldIndices.LSIG(1):obj.SignalingFieldIndices.USIG(2)); % Format detection using 16 us following L-LTF
        fmtDetectBuffer = zeros(obj.SignalingFieldIndices.LLTF(2),size(rxPPDU,2));
        missingIndices = fmtDetInd>size(rxPPDU,1); % Small packet in waveform may not have enough samples for HE detection
        fmtDetectBuffer(~missingIndices,:) = rxPPDU(fmtDetInd(~missingIndices),:); % Use the indices available in the buffer
        formatString = wlanFormatDetect(fmtDetectBuffer, obj.ChannelEstimateNonHT, obj.NoiseVarianceNonHT, obj.ChannelBandwidthStr, SuppressWarnings=true);
        % Return the frame format
        frameFormat = wlan.internal.utils.getFrameFormatConstant(formatString);
        % Set the packet type for HE
        switch frameFormat
            case {wlan.internal.FrameFormats.HE_SU, wlan.internal.FrameFormats.HE_EXT_SU}
                obj.HERecoveryConfig.PacketFormat = formatString;
            case {wlan.internal.FrameFormats.HE_TB  wlan.internal.FrameFormats.HE_MU wlan.internal.FrameFormats.EHT_TB}
                frameFormat = -1;
        end
        % Check if the frame format is unsupported like HT_GF, HE_TB, HE_MU, EHT TB.
        isValidFormat = frameFormat ~= -1;
        % Set the frame format
        obj.RxFrameFormat = frameFormat;
    end

    function wavOut = synchronizeWaveform(obj,wavIn)
        %synchronizeWaveform apply frequency offset correction and AGC
        %scaling to entire waveform
        wavOut = frequencyOffset(wavIn, obj.SampleRate, obj.FrequencyOffsetCorrection) * obj.LSTFAGCGain;
    end

    function waveformOut = applyThermalNoise(obj,waveformIn)
        %applyThermalNoise Calculate and apply thermal noise to the waveform

        % Apply thermal noise to the received waveform
        thermalNoiseInWatts = wnet.internal.calculateThermalNoise(obj.SampleRate,obj.NoiseFigure);
        waveformOut = wnet.internal.applyThermalNoise(waveformIn,thermalNoiseInWatts);
    end

    function wavOut = resampleWaveformToBB(obj,wavIn,sr)
        %resampleWaveformToBB resample the upsampled waveform to baseband
        downSamplingFactor = sr/obj.SampleRate; % Downsampling factor
        downSamplingFactorandNumRxAntennas = [downSamplingFactor; obj.NumReceiveAntennas];
        % Need to create new resampler when the number of received antennas
        % changes in EMLSR scenarios, because FIRRateConverter does not
        % support var-size channel inputs
        if ~any(all(downSamplingFactorandNumRxAntennas == obj.DownSamplingFactorandNumRxAntennas))
            % Create the new downsampler if downsampling factor is not matched to the cached
            createNewResampler(obj, downSamplingFactorandNumRxAntennas);
        end
        % Select resampler
        resamplerToUse = all(downSamplingFactorandNumRxAntennas == obj.DownSamplingFactorandNumRxAntennas);
        wavOut = obj.DownSamplingFilter{resamplerToUse}(wavIn);
        reset(obj.DownSamplingFilter{resamplerToUse});
    end

   function createNewResampler(obj,dsFactorandNumRxAntennas)
        %createNewResampler create the sampler to downsample the waveform to baseband
        aStop = 40; % Stopband attenuation
        dsFactor = dsFactorandNumRxAntennas(1);
        [L,M] = rat(1/dsFactor);
        % Average ratio approximated based on the analysis between
        % half-polyphase length of designed downsampling filter and
        % downsampling factor.
        switch obj.SampleRate
            case {20e6, 40e6}
                averageRatio = 24.2879;
            case 80e6
                averageRatio = 48.2987;
            case 160e6
                averageRatio = 95.9674;
            otherwise % 320 MHz
                averageRatio = 191.4564;
        end
        if dsFactor == floor(dsFactor)
            % Special case of downsampling factor is integer
            pPredict = ceil(averageRatio); % pPredict is 25 for 20 and 40 MHz, 49 for 80 MHz, 96 for 160 MHz, and 192 for 320 MHz.
        else
            pPredict = round(dsFactor*averageRatio);
        end

        % Create a new downsampling filter and add it to the pool of downsampling filters
        f = designMultirateFIR(L,M,pPredict,aStop,SystemObject=true);
        obj.DownSamplingFilter = [obj.DownSamplingFilter {f}];
        % Update the pool of downsampling factor and number of receive antennas
        obj.DownSamplingFactorandNumRxAntennas = [obj.DownSamplingFactorandNumRxAntennas dsFactorandNumRxAntennas];
   end

    function [wavCombined, isSRSameUpToCurrentStage] = getBBWaveform(obj,tStart,tEnd)
        %getBBWaveform combine the waveform and resample if it is required
        %and return true if the combining rate is same from preamble up to
        %the current decoding stage
        [wavCombined, ~, srCombined] = resultantWaveform(obj.Interference, tStart, tEnd, ...
            CenterFrequency=obj.CurrentOperatingFrequency, Bandwidth=obj.CurrentChannelBandwidth*1e6, ReceiveAntennaIndex=1:obj.NumReceiveAntennas);

        % Resample signal + interference to baseband if the combining sample rate is higher than baseband sample rate
        if srCombined ~= obj.SampleRate
            wavCombined = resampleWaveformToBB(obj, wavCombined, srCombined);
        end

        % Update the combing sample rate of current decoding stage
        obj.ResultantSampleRate(obj.SignalDecodeStage) = srCombined;
        % Check if the combining sample rate is same from the preamble to the current decoding stage
        isSRSameUpToCurrentStage =  max(obj.ResultantSampleRate(1:obj.SignalDecodeStage)) == min(obj.ResultantSampleRate(1:obj.SignalDecodeStage));
    end

    function flag = isFrequencyOverlappingWithReceiverBandwidth(obj,signal)
        % isFrequencyOverlappingWithReceiverBandwidth returns true if the
        % frequency of signal is overlapping with that of receiver
        % configuration of the whole operating bandwidth
        rxStartFreq = signal.CenterFrequency - signal.Bandwidth/2;
        rxEndFreq = signal.CenterFrequency + signal.Bandwidth/2;
        nodeStartFreq = obj.OperatingFrequency - obj.ChannelBandwidth*1e6/2;
        nodeEndFreq = obj.OperatingFrequency + obj.ChannelBandwidth*1e6/2;
        flag = min(rxEndFreq, nodeEndFreq) - max(rxStartFreq, nodeStartFreq) > 0;
    end

    function flag = isAnySubChannelFrequencyMatchingPrimary(obj,signal)
        % isAnySubChannelFrequencyMatchingPrimary returns true if any
        % subchannel of received signal is aligning with the configuration
        % of the receiver primary channel
        rxStartFreq = signal.CenterFrequency - signal.Bandwidth/2;
        rxEndFreq = signal.CenterFrequency + signal.Bandwidth/2;
        rxSubChannelFreq = rxStartFreq:20e6:rxEndFreq;
        primaryStartFreq = obj.PrimaryChannelFrequency - 10e6;
        primaryEndFreq = obj.PrimaryChannelFrequency + 10e6;
        flag = any(primaryStartFreq==rxSubChannelFreq) && any(primaryEndFreq==rxSubChannelFreq);
    end

    function getACIStats(obj,flagFreqOvelapping)
        %getACIStats get the statistics related to ACI
        if flagFreqOvelapping
            obj.ACIStats.numFreqOverlappingPackets = obj.ACIStats.numFreqOverlappingPackets + 1;
        else
            obj.ACIStats.numFreqNonOverlappingPackets = obj.ACIStats.numFreqNonOverlappingPackets + 1;
        end
    end

    function flag = notEnoughSamplesToProcessField(obj,lastIndex,rxPPDU)
        %notEnoughSamplesToProcessField returns true if there are not
        % enough samples in the waveform to process the field given the
        % last index
        flag = (obj.PacketOffset+double(lastIndex)) > size(rxPPDU,1);
    end

    function [indicationToMAC,rxSync] = handleCombinedWaveformWhenSRChanges(obj,waveformAfterCombining,indicationToMAC)
        %handleCombinedWaveformWhenSRChanges handles combined waveform when
        %the combining sample rate of current decoding stage has changed
        % Add noise to the combined waveform
        waveformAfterCombining = applyThermalNoise(obj, waveformAfterCombining);
        % Synchronize the waveform as the sample rate changes
        [isValidPreamble,rxSync] = decodePreamble(obj, waveformAfterCombining);
        if ~isValidPreamble
            % Handle the case when the the preamble is not valid after
            % re-synchronization
            indicationToMAC = handleInvalidPreamble(obj, indicationToMAC);
        end
    end

    function configureReceiverForProcessingCurrentSOI(obj)
        %configureReceiverForProcessingCurrentSOI configures the current
        %operating frequency, current channel bandwidth, baseband sample
        %rate and generating the signaling field indices for process SOI
        if obj.Signal.Bandwidth < obj.ChannelBandwidth
            % If the bandwidth of SOI is less than the receiver
            % configuration, process the packet at the baseband sample
            % rate of BW of received packet
            obj.CurrentOperatingFrequency = obj.Signal.CenterFrequency; % Use the center frequency of SOI to process
            obj.CurrentChannelBandwidth = obj.Signal.Bandwidth;
            obj.ChannelBandwidthStr = wlan.internal.utils.getChannelBandwidthStr(obj.CurrentChannelBandwidth);
            obj.SampleRate = obj.CurrentChannelBandwidth * 1e6;

            % Initiate the chanBW for all support formats
            obj.NonHTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            if obj.CurrentChannelBandwidth < 80
                obj.HTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            end
            obj.VHTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            obj.HERecoveryConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            obj.EHTRecoveryConfig.ChannelBandwidth = obj.ChannelBandwidthStr;

            % Regenerate the signaling field indices as the bandwidth has changed
            obj.SignalingFieldIndices = obj.getSignalingIndices(obj.ChannelBandwidthStr);

            % We should not scale the ED threshold as it should always be
            % the ED of configured receiver bandwidth
        else
            % Otherwise always process the packet at the baseband sample
            % rate of receiver BW. Use the center frequency of receiver to
            % process SOI.
            obj.CurrentOperatingFrequency = obj.OperatingFrequency;
        end
    end

    function resetConfigurationtoDefault(obj)
        %resetConfigurationtoDefault reset the receiver configuration to
        %default
        obj.CurrentOperatingFrequency = obj.OperatingFrequency;
        obj.CurrentChannelBandwidth = obj.ChannelBandwidth;
        obj.ChannelBandwidthStr = wlan.internal.utils.getChannelBandwidthStr(obj.ChannelBandwidth);
        obj.SampleRate = obj.ChannelBandwidth * 1e6;

        % Set the channel bandwidth to the current processing
        % bandwidth of receiver. This is to allow the
        % processing of signaling fields using the correct
        % indices of packet bandwidth.
        if obj.ChannelBandwidth < 320
            obj.VHTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            obj.HERecoveryConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            if obj.ChannelBandwidth < 80
                obj.HTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
            end
        end
        obj.NonHTConfig.ChannelBandwidth = obj.ChannelBandwidthStr;

        % Always reset EHTRecoveryConfig to default after the current
        % packet processing
        obj.EHTRecoveryConfig = obj.RecoveryConfigCache;
        obj.EHTRecoveryConfig.ChannelBandwidth = obj.ChannelBandwidthStr;
        obj.SignalingFieldIndices = obj.getSignalingIndices(obj.ChannelBandwidthStr);
    end
end
end

function nest = vhtNoiseEstimate(trackedDemodPilotSym,chanEstPilots,cfgVHT)
%vhtNoiseEstimate VHT noise estimate
    % Get reference pilots, from Eqn 22-95, IEEE Std 802.11ac-2013
    % Offset by 4 to allow for L-SIG, VHT-SIG-A, VHT-SIG-B pilot symbols
    numOFDMSym = size(trackedDemodPilotSym,2);
    n = (0:numOFDMSym-1).';
    z = 4;
    % Set the number of space time streams to 1 since the pilots are same across all spatial streams
    refPilots = wlan.internal.vhtPilots(n,z,cfgVHT.ChannelBandwidth,1);

    % Estimate received pilots
    chanEstPilotsAvg = mean(chanEstPilots,2); % Average single-stream pilot estimates over symbols (2nd dimension)
    estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilotsAvg,refPilots);

    % Estimate noise
    pilotError = estRxPilots-trackedDemodPilotSym;
    nest = mean(real(pilotError(:).*conj(pilotError(:))));
end