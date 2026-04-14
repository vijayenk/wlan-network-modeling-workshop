function responseFrame = processRxFrame(obj, rxFrame, frameIdx, frameMetadata)
%processRxFrame Processes received frame
%   RESPONSEFRAME = processRxFrame(OBJ, RXFRAME, FRAMEIDX, FRAMEMETADATA)
%   processes the received frame and generates response frame if required.
%
%   RESPONSEFRAME is the frame to be sent as response to received frame.
%
%   OBJ is an object of type edcaMAC.
%
%   RXFRAME is the received frame.
%
%   FRAMEIDX is the index of frames received from PHY layer. In case of UL
%   HE-TB reception, this value will be greater than 1.
%
%   FRAMEMETADATA contains metadata of PPDU received at PHY layer such as
%   start time and center frequency. It is structure with fields StartTime
%   and CenterFrequency.

%   Copyright 2023-2025 The MathWorks, Inc.

responseFrame = [];

rx = obj.Rx; % Handle object

% Update Length in Rx vector for HE format PSDUs. For all other formats,
% length will be obtained from Rx vector
if (rx.RxVector.PPDUFormat == obj.HE_SU) || (rx.RxVector.PPDUFormat == obj.HE_EXT_SU) || ...
        (rx.RxVector.PPDUFormat == obj.HE_MU) || (rx.RxVector.PPDUFormat == obj.HE_TB)
    rx.RxVector.PerUserInfo(frameIdx).Length = rxFrame.MACFrame(obj.UserIndexSU).PSDULength;
end

% Send updated SR parameters to PHYRx
if obj.EnableSROperation
    obj.PHYMode.PHYRxOn = true;
    obj.PHYMode.BSSColor = obj.BSSColor;
    obj.PHYMode.EnableSROperation = obj.EnableSROperation;
    obj.PHYMode.OBSSPDThreshold = obj.UpdatedOBSSPDThreshold;
    if ~isempty(obj.SetPHYModeFcn)
        obj.SetPHYModeFcn(obj.PHYMode);
    end
end

% Non-aggregated MPDU
if (rx.RxVector.AggregatedMPDU == 0) && (rx.RxVector.PPDUFormat < obj.VHT)

    if rx.RxVector.PerUserInfo(obj.UserIndexSU).Length > obj.MPDUMaxLength % Invalid subframe
        handleRxFailure(obj, false, frameIdx);
        if obj.HasListener.MPDUDecoded || ~isempty(obj.ReceptionEndedFcn)
            notifyMPDUEventNonAggFrame(obj, rxFrame, -1, frameMetadata); % -1 indicates failed decode status
        end
    else
        responseFrame = decodeNonAggFrame(obj, rxFrame, frameIdx, frameMetadata);
    end

else % Received frame is an aggregated MPDU
    responseFrame = decodeAggFrame(obj, rxFrame, frameIdx, frameMetadata);
end
end

function processBeacon(obj, rxMPDU)
%processBeacon Increment the receptions statistics for beacon frames

% Perform actions on beacon reception
performActionsOnBeaconRx(obj, rxMPDU);

% Store TXOP holder address
if ~strcmp(rxMPDU.Header.Address2, obj.TXOPHolder)
    obj.TXOPHolder = rxMPDU.Header.Address2;
    if obj.IsAffiliatedWithMLD
        % Discard last SSN and temporary bitmap records at the end of current TXOP,
        % if independent scoreboard context is maintained. Reference: Section
        % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
        % holder address is cleared/updated, which indicates TXOP change.
        resetLastSSNForMLDTxRxPair(obj);
    end
end

% Update statistics
if obj.IsAssociatedSTA && strcmp(rxMPDU.Header.Address2, obj.BSSID) % Beacon received from AP in same BSS
    obj.ReceivedBeaconFramesFromAssociatedAP = obj.ReceivedBeaconFramesFromAssociatedAP + 1;
end
if rxMPDU.FrameBody.IsMeshBeacon
    obj.ReceivedBeaconFramesFromMesh = obj.ReceivedBeaconFramesFromMesh + 1;
else % Beacon is sent from AP
    obj.ReceivedBeaconFramesFromAP = obj.ReceivedBeaconFramesFromAP + 1;
end
end

function responseFrame = decodeNonAggFrame(obj, rxFrame, frameIdx, frameMetadata)
%decodeNonAggFrame Decode non-aggregated frame and return response frame

    responseFrame = [];
    rx = obj.Rx; % Handle object
    isIntendedFrame = false;
    
    % Decode the received MPDU
    if obj.FrameAbstraction
        rxMPDU = rxFrame.MACFrame.MPDU;
        decodeStatus = (~rxFrame.MACFrame.MPDU.FCSPass)*-2; % Conversion from logical to double
    else % full MAC frame
        mpduBits = rxFrame.MACFrame(obj.UserIndexSU).Data;
        [rxMPDU, decodeStatus] = decodeMACFrameBits(obj, mpduBits, rx.RxVector.PPDUFormat);
        rxFrame.MACFrame.MPDU = rxMPDU;
    end

    if (decodeStatus == 0) % Decoding successful
        % If a frame with an MPDU is received, reset the MSD timer of EMLSR STA.
        % Reference: Section 35.3.16.8.2 of IEEE P802.11be/D5.0
        if obj.IsEMLSRSTA
            resetMSDTimer(obj);
        end

        % Convert transmitter address to non-bandwidth signaling before
        % using it
        if (rx.RxVector.PPDUFormat == obj.NonHT) && (obj.MaxSupportedStandard >= obj.Std80211ac)
            [rxMPDU.Header.Address2, rx.IsBWSignalingTAPresent] = wlan.internal.utils.nonBandwidthSignalingTA(rxMPDU.Header.Address2);
        end

        % Frame is intended to this node
        if isFrameAddressedToUs(obj, rxMPDU)

            % Initialize
            isIntendedFrame = true;

            if strcmp(rxMPDU.Header.FrameType, 'QoS Data') % QoS Data frame
                responseFrame = processQoSDataFromMPDU(obj, rxFrame, rxMPDU);
    
            elseif strcmp(rxMPDU.Header.FrameType, 'RTS') || ... % RTS frame
                    (strcmp(rxMPDU.Header.FrameType, 'Trigger') && strcmp(rxMPDU.FrameBody.TriggerType, 'MU-RTS')) % MU-RTS frame
                responseFrame = processRTS(obj, rxMPDU);

            elseif strcmp(rxMPDU.Header.FrameType, 'Trigger') && strcmp(rxMPDU.FrameBody.TriggerType, 'MU-BAR')
                responseFrame = processMUBARTrigger(obj, rxMPDU);

            elseif strcmp(rxMPDU.Header.FrameType, 'Trigger') && strcmp(rxMPDU.FrameBody.TriggerType, 'Basic')
                processBasicTrigger(obj, rxMPDU);

            elseif wlan.internal.utils.isManagementFrame(rxMPDU)
                responseFrame = processManagementFrames(obj, rxMPDU);

            elseif ~ismember(rxMPDU.Header.FrameType, ["CTS", "ACK", "Block Ack"]) % Received an unsupported MPDU
                handleRxFailure(obj, false, frameIdx);
            end
    
        elseif wlan.internal.utils.isGroupAddress(rxMPDU.Header.Address1) && any(strcmp(rxMPDU.Header.FrameType, {'Beacon','QoS Data'})) % Groupcast frame

            isIntendedFrame = true;
            if strcmp(rxMPDU.Header.FrameType, 'Beacon')
                % Handle beacon frame reception
                processBeacon(obj,rxMPDU);

            elseif strcmp(rxMPDU.Header.FrameType, 'QoS Data')
                % Handle groupcast data frame reception 
                processGroupcastDataFrame(obj, rxFrame, rxMPDU, 1);   
            end

        else % Received frame is intended to others or broadcast (CF-End)
            setNAV(obj, rx, rxMPDU);
        end

        % Update statistics for frames with valid FCS
        obj.Statistics.ReceivedFCSValidFrames = obj.Statistics.ReceivedFCSValidFrames + 1;
    
    else % FCS check failed
        handleRxFailure(obj, true, frameIdx);
    end

    % Update common Rx statistics
    updateCommonRxStats(obj, rxMPDU);

    % Event trigger (reception)
    if obj.HasListener.MPDUDecoded || ~isempty(obj.ReceptionEndedFcn)
        % Trigger MPDUDecoded event or ReceptionEnded event
        notifyMPDUEventNonAggFrame(obj, rxFrame, decodeStatus, frameMetadata, isIntendedFrame);
    end
end

function responseFrame = decodeAggFrame(obj, rxFrame, frameIdx, frameMetadata)
%decodeAggFrame Decode aggregated frame and return response frame

    rx = obj.Rx; % Handle object
    responseFrame = [];
    isIntendedFrame = false;
    
    if obj.FrameAbstraction
        % Number of subframes in the A-MPDU
        aggCount = numel(rxFrame.MACFrame.MPDU);
        delFails = ~([rxFrame.MACFrame.MPDU(:).DelimiterPass]);

    else % Full MAC
        % PSDU bits
        psdu = rxFrame.MACFrame(obj.UserIndexSU).Data;
        % Deaggregate A-MPDU
        % EHT-SU format A-MPDU
        if rx.RxVector.PPDUFormat == obj.EHT_SU
            [mpdusList, delFails] = wlanAMPDUDeaggregate(psdu, obj.EHTSUConfig, DataFormat='bits', DisableValidation=true, OutputDecimalOctets=true);
            % HE-SU format A-MPDU
        elseif rx.RxVector.PPDUFormat == obj.HE_SU
            [mpdusList, delFails] = wlanAMPDUDeaggregate(psdu, obj.HESUConfig, DataFormat='bits', DisableValidation=true, OutputDecimalOctets=true);
            % HE-EXT-SU format A-MPDU
        elseif rx.RxVector.PPDUFormat == obj.HE_EXT_SU
            obj.HESUConfig.ExtendedRange = true;
            [mpdusList, delFails] = wlanAMPDUDeaggregate(psdu, obj.HESUConfig, DataFormat='bits', DisableValidation=true, OutputDecimalOctets=true);
            % VHT format A-MPDU
        elseif rx.RxVector.PPDUFormat == obj.VHT
            [mpdusList, delFails] = wlanAMPDUDeaggregate(psdu, obj.VHTConfig, DataFormat='bits', DisableValidation=true, OutputDecimalOctets=true);
        else % HT-Mixed format A-MPDU
            obj.HTConfig.AggregatedMPDU = true;
            [mpdusList, delFails] = wlanAMPDUDeaggregate(psdu, obj.HTConfig, DataFormat='bits', DisableValidation=true, OutputDecimalOctets=true);
        end
        % Number of subframes in the A-MPDU
        aggCount = numel(mpdusList);
    end
    
    rxSeqNums = zeros(aggCount, 1);
    seqNumIdx = 0;
    tid = 1;
    subframeFailures = 0;
    baDestinationAddress = '000000000000';
    ackPolicy = 'No Ack'; % Default ack policy
    cacheIndex = -1;
    srcIndex = -1;
    isMLD2MLDCommunication = false;
    insertIntoUnicastMLDCache = false;
    mpduList = cell(1, aggCount);
    fcsPassList = false(aggCount, 1);
    decodeStatusList = zeros(1, aggCount);
    
    % Decode each subframe
    for i = 1:aggCount
        % Length of A-MPDU subframe
        if obj.FrameAbstraction
            mpduLength = rxFrame.MACFrame.MPDU(i).Metadata.MPDULength;
        else
            mpduOctets = mpdusList{i}';
            mpduLength = numel(mpduOctets);
        end
    
        % Invalid delimiter or length of the A-MPDU subframe exceeds
        % maximum MPDU length
        if delFails(i) || (mpduLength > obj.MPDUMaxLength)
            rxMPDU = obj.MPDUTemplate;
            decodeStatus = -1; % Indicates failure
            if delFails(i)
                obj.Statistics.ReceivedDelimiterCRCFails = obj.Statistics.ReceivedDelimiterCRCFails + 1;
            end
        else % Valid subframe
            if obj.FrameAbstraction
                rxMPDU = rxFrame.MACFrame.MPDU(i);
                decodeStatus = (~rxFrame.MACFrame.MPDU(i).FCSPass)*-2; % Conversion from logical to double
            else % full MAC frame
                mpduBits = [];
                if ~isempty(mpduOctets)
                    mpduBits = int2bit(mpduOctets, 8, false);
                end
                [rxMPDU, decodeStatus] = decodeMACFrameBits(obj, mpduBits, rx.RxVector.PPDUFormat);
            end
        end

        % Valid subframe
        if (decodeStatus==0) % Valid subframe
            if rx.RxVector.PPDUFormat == obj.HE_MU && rxMPDU.Header.AControlID == 0
                % Store the following from MPDUs decoded successfully and containing TRS
                % Control field and received in HE-MU PPDU
                rx.ResponseMCS = rxMPDU.Header.AControlInfo.MCS;
                rx.ULNumDataSymbols = rxMPDU.Header.AControlInfo.NumDataSymbols;
                rx.ULTriggerMethod = 'TRS';
                rx.ResponseNumSTS = 1; % NumSpaceTimeStreams must be 1, when trigger method is TRS
                rx.ResponseRU = rx.RxVector.RUAllocation;
            end
            % Update MAC frame reception counter
            obj.Statistics.ReceivedFCSValidFrames = obj.Statistics.ReceivedFCSValidFrames + 1;
            % Get index corresponding to current MPDU
            seqNums = rxFrame.SequenceNumbers(obj.UserIndexSU, :);
            mpduIdx = find(seqNums == rxMPDU.Header.SequenceNumber);
            tid = rxMPDU.Header.TID; % TID
    
            % Frame is intended to this node
            if isFrameAddressedToUs(obj, rxMPDU)
                isIntendedFrame = true;
    
                if strcmp(rxMPDU.Header.FrameType, 'QoS Data') % QoS Data frame
                    if ~(obj.IsAssociatedSTA && ~strcmp(rxMPDU.Header.Address2, obj.BSSID))
                        [isMLD2MLDCommunication, srcIndex, cacheIndex] = processQoSDataFromAMPDU(obj, rxFrame, rxMPDU, mpduIdx);

                        % Capture frame configuration to generate BA
                        seqNum = rxMPDU.Header.SequenceNumber;
                        baDestinationAddress = rxMPDU.Header.Address2;
                        ackPolicy = rxMPDU.Header.AckPolicy;

                        % Store the sequence numbers to generate Block Ack (BA)
                        seqNumIdx = seqNumIdx+1;
                        rxSeqNums(seqNumIdx) = seqNum;
                        insertIntoUnicastMLDCache = isMLD2MLDCommunication;
                    end

                elseif strcmp(rxMPDU.Header.FrameType, 'QoS Null') % Only received in HE TB PPDUs currently
                    processQoSNull(obj, rxMPDU);
                end
    
            elseif wlan.internal.utils.isGroupAddress(rxMPDU.Header.Address1) % Groupcast subframe
                isIntendedFrame = true;
                if strcmp(rxMPDU.Header.FrameType, 'QoS Data') % groupcast data frames
                    processGroupcastDataFrame(obj, rxFrame, rxMPDU, mpduIdx);
                end
    
            else % Received frame is not intended to this node
                setNAV(obj, rx, rxMPDU);
            end
    
        else % FCS check failed for A-MPDU subframe
            % Update MAC frame reception failure counter
            subframeFailures = subframeFailures + 1;
            if ~delFails(i)
                obj.Statistics.ReceivedFCSFails = obj.Statistics.ReceivedFCSFails + 1;
            end
        end
    
        % Store data to give in event trigger
        fcsPassList(i) =  (decodeStatus==0);
        if ~obj.FrameAbstraction
            mpduList{i} = mpduOctets; % macFrameOctets is column vector
        end
        decodeStatusList(i) = decodeStatus;
    end
    
    if aggCount == 0 % Delimiter not found
        % Update AMPDU decode failure counter
        obj.AMPDUDecodeFailures = obj.AMPDUDecodeFailures + 1;
    end
    
    % All the subframes are invalid
    if subframeFailures == aggCount
    
        % EIFS shall not be invoked if the RXVECTOR parameter TXOP_DURATION
        % of a received HE PPDU is not set to UNSPECIFIED. Value 127
        % signifies that TXOPDuration is UNSPECIFIED.
        %
        % Refer section 10.3.2.3.7 in IEEE Std 802.11-2021
        if rx.RxVector.TXOPDuration ~= 127 && ... % 127 indicates unspecified
                any(rx.RxVector.PPDUFormat == [obj.HE_SU, obj.HE_EXT_SU, obj.HE_MU, obj.HE_TB, obj.EHT_SU])
            % Set NAV with duration indicated by TXOP_DURATION parameter in RxVector
            % when no frame with Duration field is received. Reference: Section 26.2.4
            % of IEEE Std 802.11ax-2021
            setNAVFromRxVector(obj, rx.RxVector);

            % If a RXVECTOR with valid TXOP_DURATION (i.e., not UNSPECIFIED) is
            % received, reset the MSD timer of EMLSR STA. Reference: Section
            % 35.3.16.8.2 of IEEE P802.11be/D5.0
            if obj.IsEMLSRSTA
                resetMSDTimer(obj);
            end

            % Set flag to indicate if UL HE-TB transmissions failed
            if rx.RxVector.PPDUFormat == obj.HE_TB
                rx.ULFramesFail(frameIdx) = true;
            end
        else
            rx.RxErrorMACFailure(frameIdx) = true;
        end
    else % At least one subframe is valid
        acIndex = wlan.internal.Constants.TID2AC(tid+1) + 1; % AC starts at 0. Adding 1 to index.

        % Update aggregate frame reception statistics
        obj.ReceivedAMPDUsPerAC(acIndex) = obj.ReceivedAMPDUsPerAC(acIndex) + 1;

        % Send acknowledgment, if required
        if (seqNumIdx > 0)
            % Insert last received sequence number into cache
            if insertIntoUnicastMLDCache
                isDataFrame = true;
                insertSequenceNumberIntoCache(obj, rxSeqNums(1:seqNumIdx), isDataFrame, isMLD2MLDCommunication, srcIndex, cacheIndex);
            end

            % Send acknowledgment based on Ack policy
            if ismember(ackPolicy, ...
                    ["Normal Ack/Implicit Block Ack Request" "No explicit acknowledgment/PSMP Ack/HTP Ack"])
                if rx.RxVector.PPDUFormat == obj.HE_TB
                    % If the received frame is a HE TB data frame, process other HE TB data
                    % frames and generate response after all the frames are processed. Store
                    % the context required to generate response
                    updateBABitmap(obj, rxSeqNums(1:seqNumIdx), tid, srcIndex);
                    % Store the indices to access bitmap context for the stations to whom
                    % Multi-STA BA must be sent
                    rx.MultiSTABAContextSTAIndices(frameIdx) = srcIndex;
                    rx.MultiSTABAContextTIDs(frameIdx) = tid;
                    rx.ResponseStationID(frameIdx) = wlan.internal.utils.macAddress2NodeID(baDestinationAddress);

                else
                    % VHT single MPDU or HE (SU/EXT_SU) single MPDU, send Ack
                    % In case of HE MU PPDU, consider the single MPDU as untagged and
                    % send Block Ack frame. In case of HT-Mixed, always send
                    % Block Ack Reference: Section 26.4.4.4 in IEEE Std 802.11ax-2021
                    if (aggCount == 1) && ~any(rx.RxVector.PPDUFormat == [obj.HTMixed obj.HE_MU])
                        % Update rx context
                        rxVector = rx.RxVector;
                        rx.ResponseMCS = responseMCS(obj, rxVector.PPDUFormat, rxVector.ChannelBandwidth, rxVector.AggregatedMPDU, ...
                            rxVector.PerUserInfo(obj.UserIndexSU).MCS, rxVector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams);
                        rx.ResponseNumSTS = 1;
                        if ~isMLD2MLDCommunication
                            % Follow full-state operation for updating bitmap and SSN
                            updateBABitmap(obj, rxSeqNums(1), tid, srcIndex);
                        else
                            % Follow partial-state operation for updating bitmap and SSN
                            updateBABitmapPartial(obj, rxSeqNums(1), tid, srcIndex);
                        end
                        responseFrame = prepareAckFrame(obj, baDestinationAddress, rxMPDU.Header.Duration);
                    else
                        % Update rx context
                        if ~((rx.RxVector.PPDUFormat == obj.HE_MU) && strcmp(rx.ULTriggerMethod, 'TRS')) % Not an MU frame
                            rxVector = rx.RxVector;
                            rx.ResponseMCS = responseMCS(obj, rxVector.PPDUFormat, rxVector.ChannelBandwidth, rxVector.AggregatedMPDU, ...
                                rxVector.PerUserInfo(obj.UserIndexSU).MCS, rxVector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams);
                            rx.ResponseNumSTS = 1;
                        end
                        nodeID = wlan.internal.utils.macAddress2NodeID(baDestinationAddress);
                        rx.ResponseStationID = nodeID;
                        responseFrame = generateBA(obj, baDestinationAddress, rxSeqNums(1:seqNumIdx), tid, srcIndex, rxMPDU.Header.Duration, isMLD2MLDCommunication);
                    end
                end
                rx.LastRxFrameTypeNeedingResponse = obj.QoSData;
            else
                rx.IsIntendedNoAckFrame = true;
            end
        end

        % If a frame with an MPDU is received, reset the MSD timer of EMLSR STA.
        % Reference: Section 35.3.16.8.2 of IEEE P802.11be/D5.0
        if obj.IsEMLSRSTA
            resetMSDTimer(obj);
        end
    end
    rx.RxSeqNums = rxSeqNums(1:seqNumIdx);
    
    % Event trigger information (reception)

    % Trigger 'MPDUDecoded'. Note that MPDUDecoded event will be removed in a
    % future release. Use the ReceptionEnded event instead. Register for the
    % ReceptionEnded notification by using the 'registerEventCallback' function
    % of wlanNode.
    if obj.HasListener.MPDUDecoded
        mpduDecoded = obj.MPDUDecoded;
        if ~obj.FrameAbstraction
            mpduDecoded.MPDU = mpduList;
        else
            mpduDecoded.MPDU = rxFrame.MACFrame.MPDU;
        end
        mpduDecoded.FCSFail = ~fcsPassList; % Any failure type is notified as FCS failure in this event
        mpduDecoded.DeviceID = obj.DeviceID;
        mpduDecoded.PPDUStartTime = frameMetadata.StartTime; % In seconds
        mpduDecoded.Frequency = frameMetadata.CenterFrequency; % In Hz
        mpduDecoded.Bandwidth = rx.RxVector.ChannelBandwidth*1e6; % In Hz
        if obj.IncludeVector
            mpduDecoded.RxVector = rx.RxVector;
        end
    
        obj.EventNotificationFcn('MPDUDecoded', mpduDecoded);
    end

    % Fill information notified in ReceptionEnded event. This is not filled for
    % MPDUDecoded because it is notified per user. ReceptionEnded is notified
    % for all users at once.
    if ~isempty(obj.ReceptionEndedFcn)
        receptionEnded = obj.ReceptionEnded;
        if rx.RxVector.PPDUFormat ~= obj.HE_TB % Non-TB formats
            receptionEnded.PDUDecodeStatus = decodeStatusList; % Integer vector
            if ~obj.FrameAbstraction
                % macFramesList is row vector.
                receptionEnded.PDU = mpduList; % Cell array with vector of decimal octet elements
            end
            receptionEnded.IsIntendedReception = isIntendedFrame;
        else % HE-TB format
            receptionEnded.PDUDecodeStatus{end+1} = decodeStatusList; % Cell array with integer vector elements
            if ~obj.FrameAbstraction % Not supported currently
                % macFramesList is row vector.
                receptionEnded.PDU{end+1} = mpduList; % Cell array with each element as cell array with vector of decimal octet elements
            end
            receptionEnded.IsIntendedReception(end+1) = isIntendedFrame;
        end
        obj.ReceptionEnded = receptionEnded;
    end
end

function [isMLD2MLDCommunication, srcIndex, cacheIndex] = processQoSDataFromAMPDU(obj, rxFrame, rxMPDU, mpduIdx)
    rx = obj.Rx; % Handle object
    acIndex = wlan.internal.Constants.TID2AC(rxMPDU.Header.TID+1) + 1; % AC starts at 0. Adding 1 to index.
    srcID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2);

    % Duplicate detection
    isPartOfAMPDU = true;
    [isDuplicate, isMLD2MLDCommunication, srcIndex, cacheIndex] = isDuplicateMPDU(obj, rxMPDU, isPartOfAMPDU, acIndex);
    
    % Send data to App layer
    if ~isDuplicate && ~isempty(mpduIdx) % isempty check is added to handle the metadata mismatch in case of full PHY.
        sendDataToApp(obj, rxFrame, rxMPDU, mpduIdx);
    end
    
    % Store the BSR information
    if obj.FrameAbstraction && rxMPDU.Header.AControlID == 3
        updateQueueInfo(obj, srcID, rxMPDU.Header.AControlInfo);
    end
    
    % Store the duration field of HE-TB data frame to calculate duration field
    % of Multi-STA BA
    if rx.RxVector.PPDUFormat == obj.HE_TB
        rx.HETBDurationField = rxMPDU.Header.Duration;
    end

    % Store TXOP holder address
    if ~strcmp(obj.TXOPHolder, obj.MACAddress) && ~strcmp(rxMPDU.Header.Address2, obj.TXOPHolder)
        obj.TXOPHolder = rxMPDU.Header.Address2;
        if obj.IsAffiliatedWithMLD
            % Discard last SSN and temporary bitmap records at the end of current TXOP,
            % if independent scoreboard context is maintained. Reference: Section
            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
            % holder address is cleared/updated, which indicates TXOP change.
            resetLastSSNForMLDTxRxPair(obj);
        end
    end

    % Update statistics
    updateDataRxStats(obj, rxMPDU, acIndex, isDuplicate);
end

function responseFrame = processQoSDataFromMPDU(obj, rxFrame, rxMPDU)
% Process non-aggregated QoS Data frame

    rx = obj.Rx; % Handle object
    responseFrame = [];
    acIndex = wlan.internal.Constants.TID2AC(rxMPDU.Header.TID+1) + 1; % AC starts at 0, add 1 for indexing
    rxVector = rx.RxVector;

    % Process the frame if received from the same BSS or if receiver is a mesh
    % device

    % Duplicate detection
    isPartOfAMPDU = false;
    [isDuplicate, isMLD2MLDCommunication, srcIndex, cacheIndex] = isDuplicateMPDU(obj, rxMPDU, isPartOfAMPDU, acIndex);
    if ~isDuplicate
        index = cacheIndex;
        if ~isMLD2MLDCommunication
            index = acIndex;
        end
        isDataFrame = true;
        insertSequenceNumberIntoCache(obj,rxMPDU.Header.SequenceNumber,isDataFrame,isMLD2MLDCommunication,srcIndex,index);
    end

    % Send data to App layer
    if ~isDuplicate
        sendDataToApp(obj, rxFrame, rxMPDU, 1);
    end

    % Send Acknowledgment as response
    if strcmp(rxMPDU.Header.AckPolicy, 'Normal Ack/Implicit Block Ack Request')
        % Update rx context
        rx.ResponseMCS = responseMCS(obj, rxVector.PPDUFormat, rxVector.ChannelBandwidth, rxVector.AggregatedMPDU, ...
            rxVector.PerUserInfo(obj.UserIndexSU).MCS, rxVector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams);
        rx.ResponseNumSTS = 1;
        rx.LastRxFrameTypeNeedingResponse = obj.QoSData;
        responseFrame = prepareAckFrame(obj, rxMPDU.Header.Address2, rxMPDU.Header.Duration);
    else
        rx.IsIntendedNoAckFrame = true;
    end

    % Store TXOP holder address
    if ~strcmp(obj.TXOPHolder, obj.MACAddress) && ~strcmp(rxMPDU.Header.Address2, obj.TXOPHolder)
        obj.TXOPHolder = rxMPDU.Header.Address2;
        if obj.IsAffiliatedWithMLD
            % Discard last SSN and temporary bitmap records at the end of current TXOP,
            % if independent scoreboard context is maintained. Reference: Section
            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
            % holder address is cleared/updated, which indicates TXOP change.
            resetLastSSNForMLDTxRxPair(obj);
        end
    end

    % Update statistics
    updateDataRxStats(obj, rxMPDU, acIndex, isDuplicate);
end

function processQoSNull(obj, rxMPDU)
% Process QoS Null frame

    % Store the BSR information
    if obj.FrameAbstraction && rxMPDU.Header.AControlID == 3
        % Get ID of the source node and index to access
        % context
        srcID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2);
        updateQueueInfo(obj, srcID, rxMPDU.Header.AControlInfo);
    end
    % Ack policy of QoS Null frame is 'No Ack'
    obj.Rx.IsIntendedNoAckFrame = true;
end

function responseFrame = processManagementFrames(obj, rxMPDU)
% Process management frame

    responseFrame = [];
    obj.Rx.LastRxFrameTypeNeedingResponse = obj.Management;
    
    if ~isempty(obj.ProcessManagementFramesCustomFcn)
        responseFrame = obj.ProcessManagementFramesCustomFcn(obj, rxMPDU);
    end

    % Store TXOP holder address
    if ~strcmp(obj.TXOPHolder, obj.MACAddress) && ~strcmp(rxMPDU.Header.Address2, obj.TXOPHolder)
        obj.TXOPHolder = rxMPDU.Header.Address2;
        if obj.IsAffiliatedWithMLD
            % Discard last SSN and temporary bitmap records at the end of current TXOP,
            % if independent scoreboard context is maintained. Reference: Section
            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
            % holder address is cleared/updated, which indicates TXOP change.
            resetLastSSNForMLDTxRxPair(obj);
        end
    end
end

function responseFrame = processRTS(obj, rxMPDU)
% Process RTS / MU-RTS frame

    rx = obj.Rx; % Handle object
    isMURTS = strcmp(rxMPDU.Header.FrameType, 'Trigger');
    
    % Update context
    nodeID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2);
    rx.ResponseStationID = nodeID;
    rx.RTSReceivedFrom = rxMPDU.Header.Address2;
    if obj.IsEMLSRSTA
        % Capture the duration field of ICF. Later, use this value to suspend
        % transmissions in other links.
        rx.TriggerDurationField = rxMPDU.Header.Duration;
    end
    if isMURTS
        rx.ResponseMCS = 0; % CTS response to MU-RTS must be sent at 6 Mbps
        rx.ResponseNumSTS = 1;
        rx.CSRequired = rxMPDU.FrameBody.CSRequired; % Store CSRequired field. It will be always true for MU-RTS.
        rx.LastRxFrameTypeNeedingResponse = obj.MURTSTrigger;
    
        % Set IntraNAV when a Trigger frame is received. Refer to Section 26.2.4 of
        % IEEE Std 802.11ax-2021
        setIntraNAVFromIntendedTriggerFrame(obj, rxMPDU);
    else
        % Update rx context
        rxVector = rx.RxVector;
        rx.ResponseMCS = responseMCS(obj, rxVector.PPDUFormat, rxVector.ChannelBandwidth, rxVector.AggregatedMPDU, ...
            rxVector.PerUserInfo(obj.UserIndexSU).MCS, rxVector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams);
        rx.ResponseNumSTS = 1;
        rx.LastRxFrameTypeNeedingResponse = obj.RTS;
    end
    
    % Send CTS as response
    responseFrame = prepareCTSFrame(obj, rxMPDU.Header.Address2, rxMPDU.Header.Duration);
    
    % Update statistics
    if isMURTS
        obj.Statistics.ReceivedMURTSFrames = obj.Statistics.ReceivedMURTSFrames + 1;
    else
        obj.Statistics.ReceivedRTSFrames = obj.Statistics.ReceivedRTSFrames + 1;
    end
end

function responseFrame = processMUBARTrigger(obj, rxMPDU)
% Process MU-BAR trigger frame

    responseFrame = [];
    rx = obj.Rx; % Handle object

    % Update context
    staIdxLogical = (obj.AID == [rxMPDU.FrameBody.UserInfo(:).AID12]);
    rx.ResponseMCS = rxMPDU.FrameBody.UserInfo(staIdxLogical).MCS;
    rx.ResponseRU = [rxMPDU.FrameBody.UserInfo(staIdxLogical).RUSize rxMPDU.FrameBody.UserInfo(staIdxLogical).RUIndex];
    rx.ResponseNumSTS = rxMPDU.FrameBody.UserInfo(staIdxLogical).NumSpatialStreams;
    rx.ULLSIGLength = rxMPDU.FrameBody.LSIGLength;
    rx.ULNumHELTFSymbols = rxMPDU.FrameBody.NumHELTFSymbols;
    rx.ULTriggerMethod = 'TriggerFrame';
    srcID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2);
    rx.ResponseStationID = srcID;
    rx.LastRxFrameTypeNeedingResponse = obj.MUBARTrigger;

    % Set IntraNAV when a Trigger frame is received. Refer to Section 26.2.4 of
    % IEEE Std 802.11ax-2021
    setIntraNAVFromIntendedTriggerFrame(obj, rxMPDU);
    
    % Send Block Ack as response
    if ~isempty(rx.RxSeqNums)
        isMLD2MLDCommunication = false;
        if obj.IsAffiliatedWithMLD
            srcIndex = find(srcID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
            if obj.SharedMAC.RemoteSTAInfo(srcIndex).IsMLD
                isMLD2MLDCommunication = true;
            end
        end
        srcIndex = blockAckScoreboadIndex(obj, srcID);
        responseFrame = generateBA(obj, rxMPDU.Header.Address2, rx.RxSeqNums, rxMPDU.FrameBody.UserInfo(staIdxLogical).TID, srcIndex, rxMPDU.Header.Duration, isMLD2MLDCommunication);
    end
    
    % Update statistics
    obj.Statistics.ReceivedMUBARFrames = obj.Statistics.ReceivedMUBARFrames + 1;
end

function processBasicTrigger(obj, rxMPDU)
% Process basic trigger frame

    rx = obj.Rx; % Handle object
    
    % Update context
    % Fill required parameters and schedule an UL HE-TB frame
    staIdxLogical = (obj.AID == [rxMPDU.FrameBody.UserInfo(:).AID12]);
    rx.CSRequired = rxMPDU.FrameBody.CSRequired;
    % Though the following information is filled in macRxContext, it will be
    % accessed by sending trig response state to generate and transmit UL HE TB
    % PPDU
    rx.ResponseNumSTS = rxMPDU.FrameBody.UserInfo(staIdxLogical).NumSpatialStreams;
    rx.ResponseMCS = rxMPDU.FrameBody.UserInfo(staIdxLogical).MCS;
    rx.ResponseRU = [rxMPDU.FrameBody.UserInfo(staIdxLogical).RUSize rxMPDU.FrameBody.UserInfo(staIdxLogical).RUIndex];
    rx.ULTriggerMethod = "TriggerFrame";
    rx.ULLSIGLength = rxMPDU.FrameBody.LSIGLength;
    rx.ULNumHELTFSymbols = rxMPDU.FrameBody.NumHELTFSymbols;
    rx.ULPreferredAC = rxMPDU.FrameBody.UserInfo(staIdxLogical).PreferredAC;
    rx.ULTIDAggregationLimit = rxMPDU.FrameBody.UserInfo(staIdxLogical).TIDAggregationLimit;
    rx.TriggerDurationField = rxMPDU.Header.Duration;
    % Set IntraNAV when a Basic Trigger frame is received to avoid the STA from
    % moving into contention. Refer to Section 26.2.4 of IEEE Std 802.11ax-2021
    setIntraNAVFromIntendedTriggerFrame(obj, rxMPDU);

    % Respond with an UL HE TB Data frame after SIFS
    rx.LastRxFrameTypeNeedingResponse = obj.BasicTrigger;

    % Update statistics
    obj.Statistics.ReceivedBasicTriggerFrames = obj.Statistics.ReceivedBasicTriggerFrames + 1;
end

function processGroupcastDataFrame(obj, rxFrame, rxMPDU, msduIdx)
%processGroupcastDataFrame Process received groupcast data frame

    % Initialize
    acIndex = wlan.internal.Constants.TID2AC(rxMPDU.Header.TID+1) + 1; % AC starts at 0, add 1 for indexing
    srcID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2); % Get ID of the source node and index to access context

    % Duplicate detection
    isDuplicate = false;
    if obj.IsAffiliatedWithMLD % MLD
        if obj.IsAssociatedSTA && strcmp(rxMPDU.Header.Address3, obj.SharedMAC.MLDMACAddress)
            % Group addressed data frames with source address (Address3) as the non-AP
            % MLD MAC address must be filtered. Reference: Section 35.3.15.2 of IEEE
            % P802.11be/D5.0.
            isDuplicate = true;
        else
            % Find whether the source node ID is in the associated STAs list in case of
            % an AP. In case of STA, find whether the source node ID is associated AP.
            srcIdx = find(srcID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
            if ~isempty(srcIdx) && obj.SharedMAC.RemoteSTAInfo(srcIdx).IsMLD
                % Perform duplicate detection if the source node is an MLD. In other cases,
                % consider it non-duplicate.
                [lastRxSeqNum, cacheIdx] = getLastRxSeqNumMLDGroupcast(obj, srcID);
                if rxMPDU.Header.SequenceNumber == lastRxSeqNum
                    isDuplicate =  true;
                else
                    % Insert the new sequence number into cache
                    obj.SharedMAC.RCGroupcastDataMLD(cacheIdx, 2) = rxMPDU.Header.SequenceNumber;
                end
            end
        end
    end
    
    % Send data to App layer
    if ~isDuplicate && (rxMPDU.FrameBody.MSDU.PacketLength > 0)
        sendDataToApp(obj, rxFrame, rxMPDU, msduIdx);
    end

    % Store TXOP holder address
    if ~strcmp(obj.TXOPHolder, obj.MACAddress) && ~strcmp(rxMPDU.Header.Address2, obj.TXOPHolder)
        obj.TXOPHolder = rxMPDU.Header.Address2;
        if obj.IsAffiliatedWithMLD
            % Discard last SSN and temporary bitmap records at the end of current TXOP,
            % if independent scoreboard context is maintained. Reference: Section
            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
            % holder address is cleared/updated, which indicates TXOP change.
            resetLastSSNForMLDTxRxPair(obj);
        end
    end
    
    % Update statistics
    updateDataRxStats(obj, rxMPDU, acIndex, isDuplicate);
end

function setIntraNAVFromIntendedTriggerFrame(obj, rxMPDU)
%setIntraNAVFromIntendedTriggerFrame Set intra-NAV timer at STA when
%trigger frame is received

updatedIntraNAVTimer = obj.LastRunTimeNS + round(rxMPDU.Header.Duration*1e3);
if obj.IntraNAVTimer <= updatedIntraNAVTimer
    prevTXOPHolder = obj.TXOPHolder;
    obj.IntraNAVTimer = updatedIntraNAVTimer;
    obj.TXOPHolder = rxMPDU.Header.Address2;
    if obj.IsAffiliatedWithMLD && ~strcmp(prevTXOPHolder, obj.TXOPHolder)
        % Discard last SSN and temporary bitmap records at the end of current TXOP,
        % if independent scoreboard context is maintained. Reference: Section
        % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
        % holder address is cleared/updated, which indicates TXOP change.
        resetLastSSNForMLDTxRxPair(obj);
    end
end
end

function handleRxFailure(obj, fcsFail, frameIdx)
%handleRxFailure Handle received frame failure

    % Update statistics
    if fcsFail
        obj.Statistics.ReceivedFCSFails = obj.Statistics.ReceivedFCSFails + 1;
    end
    % Set a flag to indicate transition to ERRORRECOVERY_STATE, when there is no energy
    % in the channel
    obj.Rx.RxErrorMACFailure(frameIdx) = true;
end

function isIntendedForAppRx = handleReceiveNonMeshPacket(obj, rxMPDU)
%handleReceiveNonMeshPacket Handle reception of non-mesh packet

    isIntendedForAppRx = false;
    isGroupAddr = wlan.internal.utils.isGroupAddress(rxMPDU.Header.Address1);
    if isGroupAddr
        isFrameOriginatedFromSelf = strcmp(rxMPDU.Metadata.SourceAddress,obj.MACAddress);
        if ~isFrameOriginatedFromSelf
            isIntendedForAppRx = true;
        end
    else
        if strcmp(obj.MACAddress, rxMPDU.Metadata.DestinationAddress) % Data frame destined to us
            % Give packet to application layer if it is destined to this node
            isIntendedForAppRx = true;
        end
    end
end

function [lastSeqNum, cacheRowIdx] = getLastRxSeqNumMLDGroupcast(obj, srcID)
    % Return the last sequence number received from given source node ID and
    % index to access receiver cache

    lastSeqNum = -1;
    knownSrcIDs = obj.SharedMAC.RCGroupcastDataMLD(:, 1);
    if any(srcID == knownSrcIDs)
        % Cache exists for given source. Get the last received seq num from cache
        cacheRowIdx = find(srcID == knownSrcIDs);
        lastSeqNum = obj.SharedMAC.RCGroupcastDataMLD(cacheRowIdx, 2);
    else
        % Add row in cache for the given source and initialize the last received
        % seq num to -1
        obj.SharedMAC.RCGroupcastDataMLD(end+1, :) = [srcID, lastSeqNum];
        cacheRowIdx = size(obj.SharedMAC.RCGroupcastDataMLD, 1);
    end
end

function frameToPHY = generateBA(obj, destinationAddress, seqNums, tid, dstIdx, rxDuration, isMLD2MLDCommunication)
    % generateBA(...) generate BA frame.

    rx = obj.Rx; % Handle object
    
    % Update the BA bitmap context with the newly received sequence numbers
    if ~isMLD2MLDCommunication
        % Follow full-state operation for updating bitmap and SSN
        [updatedBitmap, ssn] = updateBABitmap(obj, seqNums, tid, dstIdx);
    else
        [updatedBitmap, ssn] = updateBABitmapPartial(obj, seqNums, tid, dstIdx);
    end
    % Convert the BA bitmap to hexadecimal format
    bitMapLen = numel(updatedBitmap)/8;
    baBitmapDec = zeros(bitMapLen,1);
    idx = 1;
    for i = 1:bitMapLen
        baBitmapDec(i) = obj.binaryToDecimal(updatedBitmap(idx:idx+7));
        idx = idx+8;
    end
    baBitmapDec = flip(baBitmapDec);
    bitmapHex = reshape(dec2hex(baBitmapDec, 2)', 1, []);

    % Create a default control response frame information structure
    % Calculate duration field
    if ((rx.RxVector.PPDUFormat == obj.HE_MU) && strcmp(rx.ULTriggerMethod, 'TRS')) || ...
            (rx.LastRxFrameTypeNeedingResponse == obj.MUBARTrigger)
        blockAckTxTime = calculateMUResponseTime(obj);

        % For MU-BAR or HE-MU frames with TRS, send Block Ack in HE-TB
        isPartOfHETBAMPDU = true;
        % Fill the TXOPDuration as the remaining duration in the TXOP. It is
        % set to value zero for Single TXOP as Block Ack is the last frame
        % transmission in the available TXOP.
        obj.TXOPDuration = max(rxDuration*1e3 - obj.SIFSTime - blockAckTxTime, 0);
    else
        isPartOfHETBAMPDU = false;
        if obj.BABitmapLength == 64
            responseLength = 32;
        elseif obj.BABitmapLength == 256
            responseLength = 56;
        elseif obj.BABitmapLength == 512
            responseLength = 88;
        else % obj.BABitmapLength == 1024
            responseLength = 152;
        end
        blockAckTxTime = calculateTxTime(obj, obj.NonHT, responseLength, rx.ResponseMCS, 1, 20); % numSTS = 1, cbw = 20
    end
    duration = max(rxDuration*1e3 - obj.SIFSTime - blockAckTxTime, 0); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
    % Convert to microseconds and round off to nanoseconds granularity
    duration = round(duration*1e-3, 3);

    % Fill MPDU fields
    mpdu = obj.MPDUBlockAckTemplate;
    mpdu.Header.Duration = duration;
    mpdu.Header.Address1 = destinationAddress;
    mpdu.Header.Address2 = obj.MACAddress;
    mpdu.FrameBody.BlockAckBitmap = bitmapHex;
    mpdu.FrameBody.TID = tid;
    mpdu.FrameBody.SequenceNumber = ssn;
    
    % Fill MPDU metadata
    mpduLength = controlFrameMPDULength(obj, mpdu.Header.FrameType);
    mpdu.Metadata.MPDULength = mpduLength;
    if isPartOfHETBAMPDU
        psduLength = mpduLength + 4; % MPDU Length + Delimiter (4)
    else
        psduLength = mpduLength; % MPDU Length
    end
    mpdu.Metadata.SubframeIndex = 1;
    mpdu.Metadata.SubframeLength = psduLength;

    % Create frame structure to be passed to PHY
    frameToPHY = obj.MACFrameTemplate;
    frameToPHY.MACFrame.MPDU = mpdu;
    frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
    frameToPHY.MACFrame.PSDULength = psduLength;

    % Update context
    rx.ResponseTxTime = blockAckTxTime;
    rx.ResponseLength = frameToPHY.MACFrame.PSDULength;

    % Update statistics
    obj.Statistics.TransmittedBlockAckFrames = obj.Statistics.TransmittedBlockAckFrames + 1;
end

function sendDataToApp(obj, rxFrame, rxMPDU, mpduIndex)
%sendDataToApp Fill the output packet to be given to the application

    rxMPDU = fillMSDUMetadata(rxMPDU, rxFrame, mpduIndex);
    
    if ~isempty(obj.HandleReceivePacketFcn)
        % Check if this packet is meant for App reception
        if obj.IsMeshDevice
            isIntendedForAppRx = obj.HandleReceiveMeshPacketFcn(rxMPDU, obj.MACAddress, obj.DeviceID);
        else % Non-mesh device
            isIntendedForAppRx = handleReceiveNonMeshPacket(obj, rxMPDU);
        end
    
        % Pass the decoded MSDUs to higher layer
        obj.HandleReceivePacketFcn(obj.DeviceID, rxMPDU, obj.IsMeshDevice, isIntendedForAppRx, rxFrame.PacketGenerationTime(obj.UserIndexSU, mpduIndex), obj.LastRunTimeNS);
    end
end

function rxMPDU = fillMSDUMetadata(rxMPDU, rxFrame, mpduIdx)
% Fill metadata in MSDU that is not carried in the actual MSDU (since MSDU is random bits)
    
    rxMPDU.FrameBody.MSDU.PacketID = rxFrame.PacketID(mpduIdx);
    rxMPDU.FrameBody.MSDU.PacketGenerationTime = rxFrame.PacketGenerationTime(mpduIdx);
    rxMPDU.FrameBody.MSDU.SourceNodeID = wlan.internal.utils.macAddress2NodeID(wlan.internal.utils.getSourceAddress(rxMPDU));
end

function [bitmap, ssn] = updateBABitmap(obj, rxSeqNums, tid, nodeIndex)
    % updateBABitmap(...) updates the BA bitmap context and returns the updated
    % BITMAP and starting sequence number (SSN) following full-state operation.
    %
    % Reference: Section-10.25.6.3 in IEEE Std 802.11-2021

    rx = obj.Rx; % Handle object

    % Maximum allowed sequence number
    maxSeqNum = 4096;
    % Half of the maximum sequence number
    maxSeqNumBy2 = 2048;
    % Bitmap size (64-bits/256-bits/512-bits/1024-bits)
    bitMapSize = obj.BABitmapLength;
    
    % Existing bitmap and SSN context of the TID
    acIndex = wlan.internal.Constants.TID2AC(tid+1) + 1; % AC starts at 0. Add 1 for indexing.
    bitmap(1:bitMapSize) = rx.BlockAckBitmap(nodeIndex, acIndex, 1:obj.BABitmapLength);
    ssn = rx.LastSSN(nodeIndex, acIndex);
    if ssn == -1 % Default initial value (invalid sequence number)
        ssn = 0; % Default initial value for window start as per std
    end
    
    % Take the offset of the sequence numbers with the starting sequence number
    seqNumsOffset = mod(rxSeqNums-ssn,maxSeqNum);
    % Ignore the duplicate frames, i.e., the sequence numbers which are greater
    % than or equal to maxSeqNumBy2
    seqNumsOffset(seqNumsOffset >= maxSeqNumBy2) = -1;
    % Maximum sequence offset which is not duplicate frame
    windowEnd = max(seqNumsOffset);
    
    if(windowEnd > bitMapSize-1) % Shift in bitmap
        % Check whether there will be overlap between the previous and the new
        % window
        isOverlapPossible =  2*bitMapSize-windowEnd-1 > 0;
        % Offset of next window start from ssn
        nextWindowStartOffset = mod((windowEnd-bitMapSize+1),maxSeqNum);
        % Next window starting sequence number
        nextWindowStart = mod(nextWindowStartOffset+ssn,maxSeqNum);
    
        if isOverlapPossible
            % startIndex is the starting index of the overlapped window
            startIndex = mod(nextWindowStart-ssn+1,maxSeqNum);
            % Copy the overlapped window to the new bitmap.
            overlapBitmap = bitmap(startIndex:end);
            bitmap = [overlapBitmap zeros(1,startIndex-1)];
    
        else
            % If there is no overlapping, then assign 0 to all the bits
            bitmap = zeros(1, bitMapSize);
        end
        % Update the new Starting Sequence number.
        ssn = nextWindowStart;
    end
    
    % Take the offset of the sequence numbers with the new starting sequence
    % number
    seqNumsOffset = mod(rxSeqNums-ssn,maxSeqNum);
    % Ignore the duplicate frames
    seqNumsOffset = seqNumsOffset(seqNumsOffset<bitMapSize);
    % Increment for array indexing
    seqNumsOffset = seqNumsOffset + 1;
    % Update the bitmap
    bitmap(seqNumsOffset) = 1;
    
    % Update the context of SSN and Bitmap
    rx.BlockAckBitmap(nodeIndex, acIndex, 1:obj.BABitmapLength) = bitmap;
    rx.LastSSN(nodeIndex, acIndex) = ssn;
end

function [bitmap, ssn] = updateBABitmapPartial(obj, rxSeqNums, tid, nodeIndex)
    % updateBABitmapPartial(...) updates the BA bitmap context and returns the
    % updated BITMAP and starting sequence number (SSN) following partial-state
    % operation. Reference for partial state operation: Section-10.25.6.4 in
    % IEEE Std 802.11-2021
    % 
    % This method is used currently only in multi link operation. If recipient
    % MLD maintains independent scoreboard context control at each affiliated
    % STA, then implement partial state operation and discard temporary bitmap
    % record at the end of current TXOP. Reference: Section 35.3.8 in IEEE
    % P802.11be/D5.0.

    rx = obj.Rx; % Handle object

    % Existing SSN context of the TID
    acIndex = wlan.internal.Constants.TID2AC(tid+1) + 1; % AC starts at 0. Add 1 for indexing.
    ssn = rx.LastSSN(nodeIndex, acIndex);

    if (ssn ~= -1) % Bitmap and last SSN record exists
        [bitmap, ssn] = updateBABitmap(obj, rxSeqNums, tid, nodeIndex);
    else
        % Maximum allowed sequence number
        maxSeqNum = 4096;
        % Initialize default bitmap with configured size
        bitMapSize = obj.BABitmapLength;
        bitmap = zeros(1, bitMapSize);

        % Assuming the received sequence numbers are sequential, consider the last
        % received sequence number as window end
        windowEnd = rxSeqNums(end);
        windowStart = mod(windowEnd-bitMapSize+1, maxSeqNum);
        % Take the offset of sequence numbers from window start to set the
        % positions corresponding to sequence numbers to 1 in bitmap
        seqNumsOffset = mod(rxSeqNums-windowStart,maxSeqNum);
        % Ignore the duplicate frames
        seqNumsOffset = seqNumsOffset(seqNumsOffset<bitMapSize);
        % Increment for array indexing
        seqNumsOffset = seqNumsOffset + 1;
        bitmap(seqNumsOffset) = 1;
        ssn = windowStart;

        % Update the context of SSN and Bitmap
        rx.BlockAckBitmap(nodeIndex, acIndex, 1:obj.BABitmapLength) = bitmap;
        rx.LastSSN(nodeIndex, acIndex) = ssn;
    end
end

function txTime = calculateMUResponseTime(obj)
    %calculateMUResponseTime Calculates response time for MU frames and MU-BAR
    %trigger frames

    rx = obj.Rx; % Handle object
    % HE-TB PHY configuration object
    cfgTB = obj.Tx.CfgTB;
    cfgTB.TriggerMethod = rx.ULTriggerMethod;
    cfgTB.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(rx.RxVector.ChannelBandwidth);
    cfgTB.RUSize = rx.ResponseRU(1);
    cfgTB.RUIndex = rx.ResponseRU(2);
    cfgTB.MCS = rx.ResponseMCS;
    numSTS = rx.ResponseNumSTS;
    if strcmp(rx.ULTriggerMethod, 'TRS')
        cfgTB.NumDataSymbols = rx.ULNumDataSymbols;
    else
        cfgTB.LSIGLength = rx.ULLSIGLength;
        cfgTB.NumHELTFSymbols = rx.ULNumHELTFSymbols;  
    end
    cfgTB.NumTransmitAntennas = numSTS; % Set as NumSTS for validation
    cfgTB.NumSpaceTimeStreams = numSTS;
    
    if strcmp(cfgTB.TriggerMethod, 'TRS')
        if cfgTB.RUSize < 484
            cfgTB.ChannelCoding = 'BCC';
        else
            cfgTB.ChannelCoding = 'LDPC';
            cfgTB.LDPCExtraSymbol = true;
        end
    else
        cfgTB.ChannelCoding = 'LDPC';
    end
    % Get PPDU info
    ppduInfo = validateConfig(cfgTB);
    obj.Tx.CfgTB = cfgTB;
    txTime = round(ppduInfo.TxTime*1e3);
end

function updateQueueInfo(obj, staID, bsrControl)
%updateQueueInfo Store/update the queue information of STA which is
%extracted from BSR Control field

    ac = bsrControl.ACIHigh;
    queueSize = bsrControl.QueueSizeHigh;
    staACPairs = obj.STAQueueInfo(:, 1:2);
    staACPairFoundLogical = (all([staID ac] == staACPairs, 2));
    
    sf = bsrControl.ScalingFactor;
    % Get the value represented by the scaling factor field as defined in Table
    % 9-24f of IEEE Std 802.11ax-2021.
    if sf == 0
        sfValue = 16;
    elseif sf == 1
        sfValue = 256;
    elseif sf == 2
        sfValue = 2048;
    else % sf == 3
        sfValue = 32768;
    end
    
    if queueSize ~= 255 % Valid queue size
        queueSize = queueSize*sfValue;
    
        if any(staACPairFoundLogical)
            % Update the information
            obj.STAQueueInfo(staACPairFoundLogical, 3) = queueSize;
        else
            % Store the information
            obj.STAQueueInfo = [obj.STAQueueInfo; staID ac queueSize];
        end
    end
    
    if bsrControl.QueueSizeAll == 0 && all(bsrControl.ACIBitmap)
        % If ACI Bitmap indicates that the status of all ACs is included in Queue
        % Size All subfield, and that status indicates 0, it means that there is no
        % data in any AC at the STA. So, store the queue size of any AC for this
        % STA as 0.
    
        rowIdxLogical = (obj.STAQueueInfo(:, 1) == staID);
        obj.STAQueueInfo(rowIdxLogical, 3) = 0;
    end
end

function flag = isFrameAddressedToUs(obj, rxMPDU)
    flag = false;
    if strcmp(rxMPDU.Header.Address1, obj.MACAddress)
        flag = true;
    elseif strcmp(rxMPDU.Header.FrameType, 'Trigger')
        % For trigger frames, AID should be checked
        associationIDs = [rxMPDU.FrameBody.UserInfo(:).AID12];
        flag = (obj.IsAssociatedSTA && ...                    % Process trigger frames only if we're operating in STA mode
                any(associationIDs == obj.AID) && ...         % Process trigger frames at STA only if there is a matching AID in trigger frame
                strcmp(rxMPDU.Header.Address2, obj.BSSID));   % Process trigger frames at STA only if it is sent by its AP
    end
end

function updateDataRxStats(obj, rxMPDU, acIndex, isDuplicate)
%updateDataRxStats Update counters for successfully received data frames

    % Number of received data bytes
    obj.ReceivedMSDUBytesPerAC(acIndex) = obj.ReceivedMSDUBytesPerAC(acIndex) + rxMPDU.FrameBody.MSDU.PacketLength;
    
    % Unicast/broadcast data frames
    if strcmp(rxMPDU.Header.Address1, 'FFFFFFFFFFFF')
        obj.ReceivedBroadcastDataFramesPerAC(acIndex) = obj.ReceivedBroadcastDataFramesPerAC(acIndex) + 1;
    else
        obj.ReceivedUnicastDataFramesPerAC(acIndex) = obj.ReceivedUnicastDataFramesPerAC(acIndex) + 1;
    end
    
    % Duplicate data frames
    if isDuplicate
        obj.ReceivedDuplicateDataFramesPerAC(acIndex) = obj.ReceivedDuplicateDataFramesPerAC(acIndex) + 1;
    end
end

function updateCommonRxStats(obj, rxMPDU)
    if wlan.internal.utils.isManagementFrame(rxMPDU)
        obj.ReceivedManagementFrames = obj.ReceivedManagementFrames + 1;
    end
end

function notifyMPDUEventNonAggFrame(obj, rxFrame, decodeStatus, frameMetadata, isIntendedFrame)
%notifyMPDUEventNonAggFrame Trigger 'MPDUDecoded' event along with
%notification data for a non-aggregated frame

    rx = obj.Rx; % Handle object
    if ~obj.FrameAbstraction
        mpduBits = rxFrame.MACFrame(obj.UserIndexSU).Data(1:(rx.RxVector.PerUserInfo(obj.UserIndexSU).Length*8));
        mpduLen = numel(mpduBits)/8;
        macFrame = zeros(mpduLen,1);
        idx = 1;
        for i = 1:mpduLen
            % Convert to double to prevent arithmetic operations on unlike datatypes
            % inside binaryToDecimal method
            macFrame(i) = obj.binaryToDecimal(double(mpduBits(idx:idx+7)));
            idx = idx+8;
        end
    end
    
    % Note that MPDUDecoded event will be removed in a future release. Use the
    % ReceptionEnded event instead. Register for the ReceptionEnded
    % notification by using the 'registerEventCallback' function of wlanNode.
    if obj.HasListener.MPDUDecoded
        mpduDecoded = obj.MPDUDecoded;
        if ~obj.FrameAbstraction
            mpduDecoded.MPDU = {macFrame};
        else
            mpduDecoded.MPDU = rxFrame.MACFrame.MPDU;
        end
        mpduDecoded.FCSFail = (decodeStatus~=0); % Any failure type is notified as FCS failure in this event
        mpduDecoded.DeviceID = obj.DeviceID;
        mpduDecoded.PPDUStartTime = frameMetadata.StartTime; % In seconds
        mpduDecoded.Frequency = frameMetadata.CenterFrequency; % In Hz
        mpduDecoded.Bandwidth = rx.RxVector.ChannelBandwidth*1e6; % In Hz
        if obj.IncludeVector
            mpduDecoded.RxVector = rx.RxVector;
        end
        obj.EventNotificationFcn('MPDUDecoded', mpduDecoded);
    end
    
    % Store information necessary to trigger ReceptionEnded event
    if ~isempty(obj.ReceptionEndedFcn)
        receptionEnded = obj.ReceptionEnded;
        receptionEnded.PDUDecodeStatus = decodeStatus; % Integer scalar
        if ~obj.FrameAbstraction
            receptionEnded.PDU = {macFrame}; % Cell array with vector of decimal octet elements
        end
    
        receptionEnded.IsIntendedReception = false;
        if nargin == 5 % isIntendedFrame
            receptionEnded.IsIntendedReception = isIntendedFrame;
        end
        obj.ReceptionEnded = receptionEnded;
    end
end
