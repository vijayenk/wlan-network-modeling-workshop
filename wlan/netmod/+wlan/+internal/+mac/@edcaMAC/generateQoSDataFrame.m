function frameToPHY = generateQoSDataFrame(obj, frameTxTime)
%generateQoSDataFrame Generate a QoS Data frame to be sent to PHY
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   FRAMETOPHY = generateQoSDataFrame(OBJ, FRAMETXTIME) generates QoS Data
%   frame to be sent to physical layer and updates the relevant
%   transmission context and statistics.
%
%   FRAMETOPHY is the structure containing either an abstract or a full MAC
%   frame and metadata.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMETXTIME is the frame transmission time in nanoseconds.

%   Copyright 2022-2025 The MathWorks, Inc.

tx = obj.Tx;
frameToPHY = obj.MACFrameTemplate;

% Generate PSDUs for each user separately and multi-user padding in case of
% MU format
for userIdx = 1:tx.NumTxUsers
    % Generate single user data frame
    frameToPHY = generateDataFramePerUser(obj, frameTxTime, frameToPHY, userIdx);
end

end

% Return the data PSDU for the specified user
function frameToPHY = generateDataFramePerUser(obj, frameTxTime, frameToPHY, userIdx)
    % Initialize
    tx = obj.Tx; % obj.Tx is a handle object
    mpduList = tx.TxFrame(userIdx).MPDUs;
    numMPDUs = numel(mpduList);
    receiverID = mpduList(1).Metadata.ReceiverID;
    acIndex = wlan.internal.Constants.TID2AC(mpduList(1).Header.TID+1)+1;
    frameFormat = tx.TxFormat;
    mpduAggregation = tx.TxAggregatedMPDU;
    queueObj = getQueueObj(obj, receiverID, acIndex);
    retryBufferIdx = tx.RetryBufferIndices(userIdx);
    retry = isRetransmission(queueObj, receiverID, acIndex, retryBufferIdx); % Check if data frames in current transmissions are re-transmission

    % Calculate duration field
    [durationField, respMCS] = calculateDurationField(obj, frameTxTime, frameFormat, mpduAggregation, numMPDUs, userIdx);
    
    % Generate data frame per user
    frameToPHY = generateDataFrame(obj, frameToPHY, userIdx, retry, durationField, frameFormat, mpduAggregation, respMCS);
    
    % Update context
    if ~tx.NoAck
        fillExpectedAckType(obj, frameFormat, mpduAggregation, numMPDUs);
    end
    if any(frameFormat == [obj.HE_MU, obj.HE_SU, obj.HE_EXT_SU, obj.HE_TB, obj.EHT_SU])
        obj.TXOPDuration = durationField;
    end
    tx.StartingSequenceNums(userIdx) = frameToPHY.MACFrame(userIdx).MPDU(1).Header.SequenceNumber;

    % Update data transmission statistics
    updateDataTxStatistics(obj, receiverID, userIdx, acIndex, numMPDUs, queueObj, retryBufferIdx, retry);
end

% Generate and return a MAC data frame per user
function frameToPHY = generateDataFrame(obj, frameToPHY, userIdx, retry, durationField, txFormat, mpduAggregation, respMCS)

    % Initialization
    tx = obj.Tx;
    mpdus = tx.TxFrame(userIdx).MPDUs;
    frameToPHY.MACFrame(userIdx).MPDU = mpdus;
    numMPDUs = numel(mpdus);
    msduBytesList = cell(numMPDUs, 1);
    mpduBytesList = cell(1, numMPDUs);
    retryList = repmat(retry, 1, numMPDUs);
    frameFormat = wlan.internal.utils.getFrameFormatString(txFormat, 'MAC');
    subframeStartIndex = 1;
    isFourAddressFrame = (tx.NumAddressFields(userIdx) == 4); % Four address frame in case of individually addressed mesh data frames
    if ~isempty(obj.TransmissionStartedFcn)
        obj.TransmissionStarted = obj.TransmissionStartedTemplate;
    end

    % Update MPDU header/framebody fields
    for idx = 1:numMPDUs
        % Frame Control and Address Fields
        mpdus(idx) = setToDSAndFromDS(obj, mpdus(idx), mpdus(idx).Metadata.ReceiverID);
        mpdus(idx).Header.Duration = durationField;
        mpdus(idx).Header.Retransmission = retryList(idx);
        mpdus(idx).Header.Address2 = obj.MACAddress; % Transmitter address (TA)
        if isFourAddressFrame % Individually addressed mesh data frames
            % Address extension is not required when final destination
            % address (Address5) is same as mesh destination address (Address3)
            if strcmp(mpdus(idx).Header.Address3, mpdus(idx).Metadata.DestinationAddress)
                mpdus(idx).FrameBody.MeshControl.AddressExtensionMode = 0;
            else
                mpdus(idx).FrameBody.MeshControl.AddressExtensionMode = 2;
                mpdus(idx).FrameBody.MeshControl.Address5 = mpdus(idx).Metadata.DestinationAddress; % DA
                mpdus(idx).FrameBody.MeshControl.Address6 = mpdus(idx).Metadata.SourceAddress; % SA
            end
        else
            isGroupAddr = wlan.internal.utils.isGroupAddress(mpdus(idx).Header.Address1);
            if isGroupAddr && obj.IsMeshDevice % Group addressed mesh data frames
                % Current implementation supports SA same as mesh SA for
                % group addressed frames. Hence address extension mode is 0.
                mpdus(idx).FrameBody.MeshControl.AddressExtensionMode = 0;
            else % Non-mesh data frames
                if obj.IsAssociatedSTA % Frame sent by STA
                    mpdus(idx).Header.Address3 = mpdus(idx).Metadata.DestinationAddress; % DA
                elseif obj.IsAPDevice % Frame sent by an AP
                    mpdus(idx).Header.Address3 = mpdus(idx).Metadata.SourceAddress; % SA
                else % Frame sent by a node
                    mpdus(idx).Header.Address3 = '00123456789B'; % Default Address3 in wlanMACFrameConfig object
                end
            end
        end
    
        % QoS Control and HT Control
        if tx.NoAck
            mpdus(idx).Header.AckPolicy = 'No Ack';
        else
            if (tx.TxFormat == obj.HE_MU)
                switch obj.DLOFDMAFrameSequence
                    case 1 % Acknowledgment requested by TRS control subfield in the DL MU PPDU
                        % Using 'HTP Ack' ack policy according to Draft 4.1. It
                        % was reworded to 'HETP Ack' in IEEE Std 802.11ax-2021
                        % but since wlanMACFrameConfig uses 'HTP Ack' as per
                        % Draft 4.1, following the same here.
                        mpdus(idx).Header.AckPolicy = 'No explicit acknowledgment/PSMP Ack/HTP Ack';
    
                        % AControl
                        mpdus(idx).Header.AControlID = 0; % Indicates TRS Control
                        aControlInfo = obj.TRSControlInfoTemplate;
                        aControlInfo.NumDataSymbols = tx.NumDataSymbols(userIdx);
                        aControlInfo.MCS = respMCS(userIdx);
                        mpdus(idx).Header.AControlInfo = aControlInfo;
                    case 2
                        mpdus(idx).Header.AckPolicy = 'Block Ack';
                end
            else
                mpdus(idx).Header.AckPolicy = 'Normal Ack/Implicit Block Ack Request';
            end
        end
        if obj.IsAssociatedSTA && obj.ULOFDMAEnabledAtAP
            % Fill BSR Control information in uplink frames from STA, when UL OFDMA is
            % enabled at AP. When UL OFDMA is enabled at AP, it is informed to STA
            % during association.

            % BSR Control Info is present in each MPDU header. But not maintaining it
            % per MPDU for simplicity. Also, same information would be present in all
            % MPDUs.
            mpdus(idx).Header.AControlID = 3; % Identifier representing that BSR control info is present in AControlInfo
            mpdus(idx).Header.AControlInfo = getBSRControlInfo(obj);
        end
    
        % Fill MPDU metadata
        mpdus(idx).Metadata.MPDULength = tx.TxMPDULengths(idx, userIdx);
        mpdus(idx).Metadata.SubframeIndex = subframeStartIndex;
        mpdus(idx).Metadata.SubframeLength = tx.TxMPDULengths(idx, userIdx) + 4*mpduAggregation; % Add MPDU delimiter length of 4 bytes if aggregation enabled;
        subframeStartIndex = subframeStartIndex + tx.TxSubframeLengths(idx, userIdx);

        % Generate MPDU bytes (for full MAC frame)
        if ~obj.FrameAbstraction
            % Carry information from MPDU struct to MAC frame config object and
            % fill remaining information of MAC frame config object here
            cfgMAC = obj.EmptyMACConfig;
            cfgMAC = wlan.internal.utils.mpduStruct2Cfg(mpdus(idx), cfgMAC);
            cfgMAC.MPDUAggregation = mpduAggregation;
            cfgMAC.FrameFormat = frameFormat;
            if strcmp(frameFormat, 'HE-MU')
                % HE-MU format is not supported by MAC frame generator. So to generate
                % a HE-MU frame, individual HE-SU frames are generated first and then
                % adjusted for MU padding
                cfgMAC.FrameFormat = 'HE-SU';
            end
            if obj.IsMeshDevice
                cfgMAC.IsMeshFrame = true;
            end
    
            % Prepare MSDUs for frame generation
            msduLength = mpdus(idx).FrameBody.MSDU.PacketLength;
            data = mpdus(idx).FrameBody.MSDU.Packet;
            % Convert to column vector
            if size(data, 1) == 1
                msduBytesList{idx} = double(data(1:msduLength))';
            else
                msduBytesList{idx} = double(data(1:msduLength));
            end
    
            % Generate non-aggregated MAC frame
            if ~mpduAggregation
                [mpduBytesList{idx}, dataFrameBits] = wlan.internal.macGenerateMPDU(msduBytesList{idx}, cfgMAC);
    
            else % Generate A-MPDU
                cfgMAC.MinimumMPDUStartSpacing = 0;
                mpduBytesList{idx} = wlan.internal.macGenerateMPDU(msduBytesList{idx}, cfgMAC);
            end
        end
    end
    
    % Update frame structure to be passed to PHY
    frameToPHY.MACFrame(userIdx).MPDU = mpdus;
    frameToPHY.MACFrame(userIdx).PSDULength = tx.TxFrameLength(userIdx);
    if ~obj.FrameAbstraction
        if mpduAggregation % Generate AMPDU if aggregation enabled
            [~, ~, dataFrameBits] = aggregateMPDUs(obj, cfgMAC, mpduBytesList, userIdx, txFormat, tx.TxMCS(userIdx), tx.TxNumSTS(userIdx));
        end
        frameToPHY.MACFrame(userIdx).Data = dataFrameBits; % MAC frame bits
    end
    for idx = 1:numMPDUs
        frameToPHY.PacketGenerationTime(userIdx, idx) = mpdus(idx).FrameBody.MSDU.PacketGenerationTime;
        frameToPHY.PacketID(userIdx, idx) = mpdus(idx).FrameBody.MSDU.PacketID;
        frameToPHY.SequenceNumbers(userIdx, idx) = mpdus(idx).Header.SequenceNumber;
    end

    % Event(s) handling
    if ~obj.FrameAbstraction
        if obj.HasListener.MPDUGenerated
            % Trigger 'MPDUGenerated'. Note that MPDUGenerated event will be removed in
            % a future release. Use the TransmissionStarted event instead. Register for
            % the TransmissionStarted notification by using the 'registerEventCallback'
            % function of wlanNode.
            mpduGenerated = obj.MPDUGenerated;
            mpduGenerated.MPDU = mpduBytesList;
            mpduGenerated.DeviceID = obj.DeviceID;
            mpduGenerated.Frequency = wlan.internal.utils.getPacketCenterFrequency(obj.OperatingFrequency, ...
                obj.ChannelBandwidth, obj.PrimaryChannelIndex, obj.Tx.TxBandwidth, obj.CandidateCentFreqOffset);
    
            obj.EventNotificationFcn('MPDUGenerated', mpduGenerated);
        end
        if ~isempty(obj.TransmissionStartedFcn)
            % Information to include TransmissionStarted event
            % MPDUs are filled only for full MAC frames. In case of abstract MAC
            % frames, this field is empty ([]).
            obj.TransmissionStarted.PDU = mpduBytesList;
        end
    end
end

% Store the expected acknowledgment type
function fillExpectedAckType(obj, frameFormat, mpduAgg, numMPDU)
    tx = obj.Tx; % obj.Tx is a handle object

    if frameFormat == obj.HE_MU % HE-MU frames
        tx.ExpectedAckType = obj.BlockAck;
    elseif frameFormat == obj.HE_TB % HE-TB frames
        tx.ExpectedAckType = obj.MultiSTABlockAck;
    else % Frames other than HE-MU and HE-TB frames
        if mpduAgg && ((frameFormat == obj.HTMixed) || (numMPDU > 1))
            tx.ExpectedAckType = obj.BlockAck;
        else
            tx.ExpectedAckType = obj.ACK;
        end
    end
end

% Generate A-MPDU
function [dataFrameDec, frameLength, dataFrameBits] = aggregateMPDUs(obj, cfgMAC, mpduList, userIdx, txFormat, mcs, numSTS)
    tx = obj.Tx; % obj.Tx is a handle object
    cbwStr = wlan.internal.utils.getChannelBandwidthStr(tx.TxBandwidth); % Channel bandwidth
    % Prepare the A-MPDU
    if strcmp(cfgMAC.FrameFormat, 'HT-Mixed')
        tx.CfgHT.AggregatedMPDU = true;
        tx.CfgHT.MCS = mcs;
        tx.CfgHT.ChannelBandwidth = cbwStr;
        tx.CfgHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgHT.NumSpaceTimeStreams = numSTS;
        [dataFrameDec, frameLength, dataFrameBits] = wlan.internal.macGenerateAMPDU(mpduList, cfgMAC, tx.CfgHT);
    
    elseif strcmp(cfgMAC.FrameFormat, 'VHT')
        tx.CfgVHT.MCS = mcs;
        tx.CfgVHT.ChannelBandwidth = cbwStr;
        tx.CfgVHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgVHT.NumSpaceTimeStreams = numSTS;
        [dataFrameDec, frameLength, dataFrameBits] = wlan.internal.macGenerateAMPDU(mpduList, cfgMAC, tx.CfgVHT);
    
    elseif strcmp(cfgMAC.FrameFormat, 'HE-SU') || strcmp(cfgMAC.FrameFormat, 'HE-EXT-SU')
        tx.CfgHE.MCS = mcs;
        tx.CfgHE.ChannelBandwidth = cbwStr;
        tx.CfgHE.ExtendedRange = (txFormat == obj.HE_EXT_SU);
        tx.CfgHE.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgHE.NumSpaceTimeStreams = numSTS;
        [dataFrameDec, frameLength, dataFrameBits] = wlan.internal.macGenerateAMPDU(mpduList, cfgMAC, tx.CfgHE);
    
    else % EHT-SU
        tx.CfgEHT.User{userIdx}.MCS = mcs;
        tx.CfgEHT.User{userIdx}.NumSpaceTimeStreams = numSTS;
        tx.CfgEHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        [dataFrameDec, frameLength, dataFrameBits] = wlan.internal.macGenerateAMPDU(mpduList, cfgMAC, tx.CfgEHT);
    end

    % Information to include TransmissionStarted event
    if ~isempty(obj.TransmissionStartedFcn)
        % MPDUs are filled only for full MAC frames. In case of abstract MAC
        % frames, this field is empty ([]).
        % PDU bytes in TransmissionStarted event is row vector
        obj.TransmissionStarted.PDU = cellfun(@(x) double(x(:)), mpduList, 'UniformOutput', false);
    end
end

function updateDataTxStatistics(obj, receiverID, userIdx, acIndex, numMPDUs, queueObj, retryBufferIdx, retry)
    tx = obj.Tx;
    isBroadcast = (receiverID == obj.BroadcastID);

    % Update statistics
    if isBroadcast % Broadcast destination
        % Update statistics
        obj.TransmittedBroadcastDataFramesPerAC(acIndex) = obj.TransmittedBroadcastDataFramesPerAC(acIndex) + numMPDUs;
    else % Valid unicast destination
        % Update statistics
        staIdxLogical = (tx.TxStationIDs(userIdx) == [obj.PerACPerSTAStatistics.AssociatedNodeID]);
    end
    
    if tx.NoAck % QoS Data frames not soliciting response
        txMSDULengths = getMSDULengthsInRetryBuffer(queueObj, receiverID, acIndex, retryBufferIdx);
        obj.TransmittedMSDUBytesPerAC(acIndex) = obj.TransmittedMSDUBytesPerAC(acIndex) + sum(txMSDULengths(1:numMPDUs));
        if ~isBroadcast
            obj.PerACPerSTAStatistics(staIdxLogical).TransmittedMSDUBytesPerAC(acIndex) = obj.PerACPerSTAStatistics(staIdxLogical).TransmittedMSDUBytesPerAC(acIndex) + sum(txMSDULengths(1:numMPDUs));
        end
    end
    
    % Update statistics
    if ~retry
        if ~isBroadcast % Unique unicast data transmission count
            obj.TransmittedUnicastDataFramesPerAC(acIndex) = obj.TransmittedUnicastDataFramesPerAC(acIndex) + numMPDUs;
            obj.PerACPerSTAStatistics(staIdxLogical).TransmittedUnicastDataFramesPerAC(acIndex) = obj.PerACPerSTAStatistics(staIdxLogical).TransmittedUnicastDataFramesPerAC(acIndex) + numMPDUs;
        end
    else % Retransmission
        obj.RetransmittedDataFramesPerAC(acIndex) = obj.RetransmittedDataFramesPerAC(acIndex) + numMPDUs;
        obj.PerACPerSTAStatistics(staIdxLogical).RetransmittedDataFramesPerAC(acIndex) = obj.PerACPerSTAStatistics(staIdxLogical).RetransmittedDataFramesPerAC(acIndex) + numMPDUs;
    end
    % AMPDU transmission count
    if tx.TxAggregatedMPDU
        obj.TransmittedAMPDUsPerAC(acIndex) = obj.TransmittedAMPDUsPerAC(acIndex) + 1;
    end
end

function [durationField, respMCS] = calculateDurationField(obj, frameTxTime, frameFormat, mpduAggregation, numMPDUs, userIdx)
    % Initialize
    tx = obj.Tx;

    % Response frame duration
    if frameFormat == obj.HE_MU
        txMCS = tx.TxMCS(1:tx.NumTxUsers);
        numSTS = tx.TxNumSTS(1:tx.NumTxUsers);
        % For MU, this value would not be used. Bandwidth will be determined
        % internally based on allocation index.
        cbw = 20;
        respMCS = responseMCS(obj, frameFormat, cbw, mpduAggregation, txMCS, numSTS);
        if obj.DLOFDMAFrameSequence == 1 % Frame exchange sequence (DL MU PPDU + TRS control -> UL BA sequence)
            % Restricting response MCS greater than 3 to MCS index 3 as TRS Control
            % field support uplink MCS in the range of [0 - 3].
            respMCS(respMCS > 3) = 3;
            % Restricting numSTS to 1 for HETB response trigger via TRS control
            % as per table 26.5.2.3.4  of IEEE Std 802.11ax-2021
            numSTS = ones(1, tx.NumTxUsers);
            heTBFrameLengths = wlan.internal.mac.calculateHETBResponseLength(tx.NumTxUsers, obj.BABitmapLength);
            responseDuration = calculateTxTime(obj, obj.HE_TB, heTBFrameLengths, respMCS, numSTS, 'TRS');
        else
            [muBarRate, muBarLength] = controlFrameRateAndLen(obj, obj.MUBARTrigger);
            mubarNumSTS = 1;
            muBarDuration = calculateTxTime(obj, obj.NonHT, muBarLength, muBarRate, mubarNumSTS, cbw);
            heTBFrameLengths = wlan.internal.mac.calculateHETBResponseLength(tx.NumTxUsers, obj.BABitmapLength);
            responseDuration = calculateTxTime(obj, obj.HE_TB, heTBFrameLengths, respMCS, numSTS, 'TriggerFrame');
        end
    elseif frameFormat ~= obj.HE_TB % Response duration calculation for frames other than HE-TB
        if mpduAggregation && ((frameFormat == obj.HTMixed) || (numMPDUs > 1))      
            % Block Ack length = 22 (Header + BA Control + FCS) + 2 (Starting
            % Sequence Control) + BABitmapLength/8
            if obj.BABitmapLength == 64
                responseFrameLength = 32;
            elseif obj.BABitmapLength == 256
                responseFrameLength = 56;
            elseif obj.BABitmapLength == 512
                responseFrameLength = 88;
            else % obj.BABitmapLength == 1024
                responseFrameLength = 152;
            end
        else
            responseFrameLength = 14; % Ack or CTS length
        end
        respMCS = responseMCS(obj, frameFormat, tx.TxBandwidth, mpduAggregation, ...
            tx.TxMCS(userIdx), tx.TxNumSTS(userIdx));
        cbw = 20; % Response is transmitted in Non-HT 20 MHz
        respNumSTS = 1; % Non-HT used for response so a single space-time stream
        % Estimated time (in nanoseconds) to transmit normal/block acknowledgment
        responseDuration = calculateTxTime(obj, obj.NonHT, responseFrameLength, ...
            respMCS, respNumSTS, cbw);
    end
    
    % Calculate duration field
    if frameFormat == obj.HE_TB % Acknowledgment for frames sent in HE TB
        durationField = round(obj.Rx.TriggerDurationField*1e3) - obj.SIFSTime - frameTxTime;
        respMCS = 0; % This value would not be used. Only to preserve syntax
    else
        % Acknowledgment not required
        if tx.NoAck
            durationField = adjustDurationForMFTXOP(obj, frameTxTime, 0);
        else
            if (frameFormat == obj.HE_MU) && (obj.DLOFDMAFrameSequence == 2)
                durationField = adjustDurationForMFTXOP(obj, frameTxTime, 2*obj.SIFSTime + muBarDuration + responseDuration);
            else
                durationField = adjustDurationForMFTXOP(obj, frameTxTime, responseDuration + obj.SIFSTime);
            end
        end
    end
    % Convert durationField to microseconds to align with units of 'Duration' field in MAC frame
    durationField = round(durationField*1e-3, 3);
    durationField = max(durationField, 0); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
    % Round up to next integer microsecond, if calculated duration includes a
    % fractional microsecond. Reference: Section 9.2.5.1 of IEEE Std
    % 802.11-2020
    durationField = ceil(durationField);
end

function updatedDuration = adjustDurationForMFTXOP(obj, frameTxTime, duration)
%adjustDurationForMFTXOP Return updated duration for multiple protection

    if obj.TXNAVTimer == 0 % Zero TXOP limit
        updatedDuration = duration;
    else
        if frameTxTime + duration <= obj.TXNAVTimer
            updatedDuration = obj.TXNAVTimer - frameTxTime; % In nanoseconds
        else
            % If data transmission exceeds TXOP limit ( Reference:
            % Section 10.23.2.9 of IEEE Std. 802.11ax-2021, The TXOP
            % holder may exceed the TXOP limit only if it does not
            % transmit more than one Data or Management frame in the
            % TXOP, for the following situation: Initial transmission of
            % an MSDU under a block ack agreement, where the MSDU is not
            % in an A-MPDU consisting of more than one MPDU and the
            % MSDU is not in an A-MSDU."), fill duration accordingly
            updatedDuration = duration;
        end
    end
end