function [macReqToPHY, frameToPHY, nextInvokeTime] = handleEventsTransmit(obj, currentTime)
%handleEventsTransmit Runs MAC Layer state machine for transmitting data
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   This function performs the following operations:
%   1. Sends transmission vector to physical Layer along with any frame
%   2. Generate and send the data frame to PHY
%   3. Generate and send RTS Frame, if Frame length is '>' RTSThreshold
%   value, in case of single-user (SU) frames.
%   4. Generate and send MU-RTS frame, if DisableRTS flag is set to false in
%   case of multi-user (MU) frames.
%   5. Generate and send MU-BAR frame, if required according to OFDMA frame
%   exchange sequence.
%   6. Generate and send Beacon frame
%   7. Generate and send CF-End frame
%   8. Generate and send Basic trigger frame
%
%   [MACREQTOPHY, FRAMETOPHY, NEXTINVOKETIME] =
%   handleEventsTransmit(OBJ, CURRENTTIME) performs MAC Layer transmitting
%   Data Actions.
%
%   MACREQTOPHY is the transmission request to PHY Layer.
%
%   FRAMETOPHY is the frame to PHY Layer.
%
%   NEXTINVOKETIME is the simulation time (in nanoseconds) at which the
%   run function must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time (in nanoseconds).

%   Copyright 2022-2025 The MathWorks, Inc.

% Initialize
macReqToPHY = obj.EmptyRequestToPHY;
frameToPHY = [];
tx = obj.Tx;

updateTxNAVTimer(obj); % Update Tx NAV timer

switch obj.MACSubstate
    case obj.TRANSMIT_SUBSTATE
        if tx.FrameTxTime == 0 % No frame transmission is in progress
            if (tx.NextTxFrameType == obj.UnknownFrameType) % Next frame is not yet known
                initContextToStartTXOP(obj, currentTime);
                tx.NextTxFrameType = scheduleTransmission(obj, true); % isInitialFES = true
            else % Next frame is known
                % Check whether there are still required number of packets in
                % the queue. Reschedule, if not present.
                tx.NextTxFrameType = rescheduleTransmissionIfNeeded(obj);
            end
            
            if (tx.NextTxFrameType == obj.UnknownFrameType) % No transmission is scheduled
                if (obj.IntraNAVTimer > currentTime || obj.NAVTimer > currentTime)
                    stateChange(obj, obj.NAVWAIT_STATE);
                else
                    stateChange(obj, obj.IDLE_STATE);
                end
                resetContextAfterTXOPEnd(obj);
            else
                [frameToPHY, macReqToPHY, frameTxTime] = prepareFrameForTransmission(obj);
                % Calculate next invoke time
                obj.NextInvokeTime = currentTime + frameTxTime;
                tx.FrameTxTime = frameTxTime;
            end

        else % Frame transmission is in progress
            if obj.NextInvokeTime <= currentTime  % Transmission completed
                tx.LastTxFrameType = tx.NextTxFrameType;
                performPostTxActionsHandling(obj);
                moveToNextState(obj, currentTime);
                if obj.MACState ~= obj.TRANSMIT_STATE
                    % As the receiver is turned on in case of state change,
                    % invoke immediately to get CCA indication, if any.
                    nextInvokeTime = currentTime;
                    return;
                end
            end
        end

    case obj.WAITINGFORSIFS_SUBSTATE
        % This state handles SIFS:
        % 1. Between frame exchange sequences (FES)
        % 2. Before CF-End
        % 3. After RTS/CTS exchange
        % 4. Between HE MU data frame and MU-BAR

        if obj.NextInvokeTime <= currentTime % SIFS elapsed
            obj.MACSubstate = obj.TRANSMIT_SUBSTATE;
        end
end

nextInvokeTime = obj.NextInvokeTime;
end

function initContextToStartTXOP(obj, currentTime)
%initContextToStartTXOP Initialize context to start TXOP such as TXNAV
%timer, TXOP bandwidth, TXOP holder etc

initTXNAVTimer(obj, currentTime);
allocateBandwidthForTXOP(obj);
% Store the TXOP holder at transmitter as well to prevent intra BSS NAV
% update upon reception failure. Refer Section 26.2.4 in IEEE Std
% 802.11ax-2021
obj.TXOPHolder = obj.MACAddress;
end

function initTXNAVTimer(obj, currentTime)
% Initialize TXNAV timer

obj.Tx.IsTXOPInitialFrame = true;
if obj.TXOPLimit(obj.OwnerAC+1) > 0 % Initialize TXNAV for non zero TXOP Limit
    obj.TXNAVTimer = obj.TXOPLimit(obj.OwnerAC+1); % In nanoseconds

    % If a beacon transmission is scheduled within the TXOP
    % limit, reduce the available TXOP duration to the next target
    % beacon transmission time (TBTT). This prevents initiating any
    % data frame exchange at the TBTT.
    if isfinite(obj.BeaconInterval)
        linkIdx = getLinkIndex(obj);
        nextTBTT = obj.SharedMAC.NextTBTT(linkIdx);
        reducedTXNAV = nextTBTT-currentTime;
        if reducedTXNAV < obj.TXOPLimit(obj.OwnerAC+1)
            obj.TXNAVTimer = reducedTXNAV;
        end
    end
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareFrameForTransmission(obj)
% Prepare the frame to transmit and corresponding TxStart request

tx = obj.Tx;

switch tx.NextTxFrameType
    case obj.Beacon
        [frameToPHY, macReqToPHY, frameTxTime] = prepareBeaconFrame(obj);

    case obj.CFEnd
        [frameToPHY, macReqToPHY, frameTxTime] = prepareCFEndFrame(obj);

    case obj.RTS
        dequeuePackets(obj);
        [frameToPHY, macReqToPHY, frameTxTime] = prepareRTSFrame(obj);

    case obj.MURTSTrigger
        if obj.ULOFDMAScheduled
            [frameToPHY, macReqToPHY, frameTxTime] = prepareMURTSForULSequence(obj);
        else
            dequeuePackets(obj);
            if isAPToEMLSRSTATransmission(obj)
                [frameToPHY, macReqToPHY, frameTxTime] = prepareICF(obj);
            else
                [frameToPHY, macReqToPHY, frameTxTime] = prepareMURTSForDLSequence(obj);
            end
        end

    case obj.QoSData
        if ~any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger])
            dequeuePackets(obj);
        end
        [frameToPHY, macReqToPHY, frameTxTime] = prepareQoSDataFrame(obj);

    case obj.QoSNull
        [frameToPHY, macReqToPHY, frameTxTime] = prepareQoSNullFrame(obj);

    case obj.MUBARTrigger
        [frameToPHY, macReqToPHY, frameTxTime] = prepareMUBARTrigger(obj);

    case obj.BasicTrigger
        [frameToPHY, macReqToPHY, frameTxTime] = prepareBasicTrigger(obj);

    otherwise % Management frames
        if ~any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger])
            dequeuePackets(obj);
        end
        [frameToPHY, macReqToPHY, frameTxTime] = prepareManagementFrame(obj);
end

setBandwidthContext(obj, macReqToPHY.Vector);

% Notify TransmissionStarted event
if ~isempty(obj.TransmissionStartedFcn)
    psduLength = [frameToPHY.MACFrame(:).PSDULength];
    if any(tx.NextTxFrameType == [obj.QoSData obj.QoSNull])
        % For data frames, APEP length and PSDU length can be different.
        % frameToPHY.PSDULength contains APEP length. Overwrite with PSDU length.
        psduLength = tx.TxPSDULength(1:tx.NumTxUsers);
    end
    notifyTransmissionStarted(obj, psduLength, frameTxTime, macReqToPHY.Vector);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareBeaconFrame(obj)
% Prepare and return the beacon frame, TX_START request and the frame
% transmission time.

tx = obj.Tx;

cbw = 20; % Bandwidth for beacon transmission
mcs = obj.NonHTMCSIndex6Mbps; % Use 6 Mbps for beacon transmission
numSTS = 1; % Number of spatial streams for beacon transmission
txFormat = obj.NonHT;

% Generate a beacon frame
[frameToPHY, frameLength] = generateBeaconFrame(obj);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

% Calculate frame duration
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, cbw);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareCFEndFrame(obj)
% Prepare and return the CF-End frame, TX_START request and the frame
% transmission time.

% Set bandwidth to transmit CF-End frame as maximum bandwidth allowed by
% rules in Section 10.23.2.8 of IEEE Std 802.11. Reference: Section
% 10.6.6.6 of IEEE Std 802.11-2020
continueTXOP = true;
cbw = getBandwidthForTx(obj, continueTXOP);
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.CFEnd);
numSTS = 1; % Number of spatial streams for control frame transmission
txFormat = obj.NonHT;

frameToPHY = generateCFEnd(obj);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, obj.Tx.TxStationIDs);

% Calculate frame duration. Control frame duration is calculated over 20
% MHz bandwidth because it is duplicated on other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareRTSFrame(obj)
% Prepare and return the RTS frame, TX_START request and the frame
% transmission time.

tx = obj.Tx;

cbw = tx.TxBandwidth; % Bandwidth for control frame transmission
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.RTS);
numSTS = 1; % Number of spatial streams for control frame transmission
txFormat = obj.NonHT;

useBWSig = false; % Flag indicating if bandwidth signaling needs to be used
bwOperationType = 'Absent'; % Bandwidth operation type
% Determine if bandwidth signaling needs to be used
if (cbw > 20)
    receiverIdx = (tx.TxFrame(obj.UserIndexSU).MPDUs(1).Metadata.ReceiverID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
    if (obj.SharedMAC.RemoteSTAInfo(receiverIdx).MaxSupportedStandard >= obj.Std80211ac)
        useBWSig = true;
        bwOperationType = 'Static';
    end
end

% Calculate frame duration. Control frame duration is calculated over 20
% MHz bandwidth because it is duplicated on other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

frameToPHY = generateRTS(obj, mcs, frameLength, frameTxTime, useBWSig);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs, bwOperationType);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareMURTSForULSequence(obj)
% Prepare and return the MU-RTS TF to initiate an uplink OFDMA frame
% sequence, TX_START request and the frame transmission time.

tx = obj.Tx;
useBWSig = false; % Reference: NOTE-3 in Section 26.2.6.3 of IEEE Std 802.11ax-2021
isULSeq = true;
isICF = false;
cbw = tx.TxBandwidth; % Bandwidth for control frame transmission
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.MURTSTrigger);
numSTS = 1; % Number of spatial streams for control frame transmission
txFormat = obj.NonHT;

% Calculate frame duration. Control frame duration is calculated over 20
% MHz bandwidth because it is duplicated on other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

frameToPHY = generateMURTS(obj, frameLength, frameTxTime, useBWSig, isULSeq, isICF);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareICF(obj)
% Prepare and return an initial control frame (MU-RTS frame) to initiate
% frame exchange sequence with EMLSR STA, TX_START request and the frame
% transmission time

tx = obj.Tx;
useBWSig = false; % Reference: NOTE-3 in Section 26.2.6.3 of IEEE Std 802.11ax-2021
isULSeq = false;
isICF = true;
cbw = tx.TxBandwidth; % Bandwidth for control frame transmission
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.MURTSTrigger);
numSTS = 1; % Number of spatial streams for control frame transmission
txFormat = obj.NonHT;

% Calculate frame duration. Control frame duration is calculated over 20
% MHz bandwidth because it is duplicated on other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

frameToPHY = generateMURTS(obj, frameLength, frameTxTime, useBWSig, isULSeq, isICF);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareMURTSForDLSequence(obj)
% Prepare and return the MU-RTS TF to initiate a downlink OFDMA frame
% sequence, TX_START request and the frame transmission time.

tx = obj.Tx;
useBWSig = false; % Reference: NOTE-3 in Section 26.2.6.3 of IEEE Std 802.11ax-2021
isULSeq = false;
isICF = false;
cbw = tx.TxBandwidth; % Bandwidth for control frame transmission
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.MURTSTrigger);
numSTS = 1; % Number of spatial streams for control frame transmission
txFormat = obj.NonHT;

% Calculate frame duration. Control frame duration is calculated over 20
% MHz bandwidth because it is duplicated on other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

frameToPHY = generateMURTS(obj, frameLength, frameTxTime, useBWSig, isULSeq, isICF);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareQoSDataFrame(obj)
% Prepare and return the QoS data frame, TX_START request and the frame
% transmission time.

tx = obj.Tx;

cbw = tx.TxBandwidth;
mcs = tx.TxMCS(1:tx.NumTxUsers);
numSTS = tx.TxNumSTS(1:tx.NumTxUsers);
txFormat = tx.TxFormat;
frameLength = tx.TxFrameLength(1:tx.NumTxUsers);

% Calculate frame duration
if (txFormat ~= obj.HE_TB)
    frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, cbw);
else
    ppduInfo = validateConfig(tx.CfgTB);
    % calculateTxTime method calculates transmission times of response frames
    % (BA) expected in UL HE TB PPDUs at access point. Here, calculate the
    % transmission time of data frames sent in HE TB PPDUs at stations.
    frameTxTime = round(ppduInfo.TxTime*1e3);
end

% Generate a QoS Data frame
frameToPHY = generateQoSDataFrame(obj, frameTxTime);

% Prepare Tx Request to PHY Layer
if (txFormat ~= obj.HE_TB)
    macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);
else
    % Prepare Tx Request to PHY Layer
    macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs, ...
        'TriggerFrame', obj.Rx.ULLSIGLength);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareQoSNullFrame(obj)
% Prepare and return the QoS null frame, TX_START request and the frame
% transmission time.

tx = obj.Tx;
cbw = tx.TxBandwidth;
mcs = tx.TxMCS(obj.UserIndexSU);
numSTS = tx.TxNumSTS(obj.UserIndexSU);
txFormat = obj.HE_TB;
% Calculate MPDU length and subframe length
isQoSNull = true;
mpduAgg = true;
[tx.TxFrameLength, tx.TxMPDULengths, tx.TxSubframeLengths] = calculateAPEPLength(obj, isQoSNull, txFormat, mpduAgg);
frameLength = tx.TxFrameLength(obj.UserIndexSU);

% Calculate frame duration
ppduInfo = validateConfig(tx.CfgTB);
% calculateTxTime method calculates transmission time to send BA frame in
% UL HE TB PPDUs at access point. Here, calculate the transmission time to
% send data frames in HE TB PPDUs at stations.
frameTxTime = round(ppduInfo.TxTime*1e3);

% Generate a QoS Null frame
frameToPHY = generateQoSNullFrame(obj, frameTxTime);

% Prepare Tx Request to PHY Layer
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs, ...
    'TriggerFrame', obj.Rx.ULLSIGLength);
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareManagementFrame(obj)
% Prepare and return the data frame, TX_START request and the frame
% transmission time.

tx = obj.Tx;
mmpdu = tx.TxFrame(obj.UserIndexSU).MPDUs(1);


cbw = 20;
mcs = 0;
numSTS = 1;
txFormat = obj.NonHT;


cbw = tx.TxBandwidth;
mcs = tx.TxMCS(1);
numSTS = tx.TxNumSTS(1);
txFormat = tx.TxFormat;
frameLength = mmpdu.Metadata.MPDULength;

frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, cbw);

% Generate management frame
frameToPHY = generateManagementFrame(obj, mmpdu, frameTxTime);

frameLength = frameToPHY.MACFrame.MPDU.Metadata.MPDULength;

% Prepare Tx Request to PHY Layer
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareMUBARTrigger(obj)
% Prepare and return the MU-BAR trigger frame, TX_START request and the
% frame transmission time.

tx = obj.Tx;

cbw = tx.TxBandwidth; % Bandwidth for control frame transmission
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.MUBARTrigger);
numSTS = 1; % Number of spatial streams for control frame transmission
txFormat = obj.NonHT;

% Calculate frame duration. Control frame duration is calculated over 20
% MHz bandwidth because it is duplicated on other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

frameToPHY = generateMUBAR(obj, frameTxTime);

% Prepare Tx Request to PHY Layer (1 space-time stream and no spatial mapping)
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function [frameToPHY, macReqToPHY, frameTxTime] = prepareBasicTrigger(obj)
% Prepare and return the Basic TF, TX_START request and the frame
% transmission time.

tx = obj.Tx;

cbw = tx.TxBandwidth; % Bandwidth for control frame transmission
[mcs, frameLength] = controlFrameRateAndLen(obj, obj.BasicTrigger);
numSTS = 1; % Number of spatial streams for basic trigger frame transmission
txFormat = obj.NonHT;

% Calculate time taken to transmit Basic Trigger frame. Control frame
% duration is calculated over 20 MHz bandwidth because it is duplicated on
% other 20 subchannels.
frameTxTime = calculateTxTime(obj, txFormat, frameLength, mcs, numSTS, 20);

frameToPHY = generateBasicTrigger(obj, frameTxTime);

% Prepare Tx Request to PHY Layer
macReqToPHY = generateTxStartRequest(obj, txFormat, cbw, mcs, numSTS, frameLength, tx.TxStationIDs);

% Trigger 'MPDUGenerated'
if ~obj.FrameAbstraction && obj.HasListener.MPDUGenerated
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, cbw);
end
end

function frameToPHY = generateCFEnd(obj)
%generateCFEnd Return the CF-End frame to be sent to PHY

% Fill MPDU fields
mpdu = obj.MPDUCFEndTemplate;
mpdu.Header.Duration = 0;
mpdu.Header.Address1 = 'FFFFFFFFFFFF';
mpdu.Header.Address2 = obj.BSSID;

% Fill MPDU metadata
mpduLength = controlFrameMPDULength(obj, mpdu.Header.FrameType);
mpdu.Metadata.MPDULength = mpduLength;
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = mpduLength;

% Create frame structure to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC
frameToPHY.MACFrame.PSDULength = mpduLength;
end

function frameToPHY = generateRTS(obj, mcs, rtsLength, rtsTxTime, useBWSig)
% Generate an RTS frame

% Fill MPDU fields
mpdu = obj.MPDURTSTemplate;
isMURTS = false;
isULSeq = false;
% Calculate time required for transmission of the RTS frame
mpdu.Header.Duration = calculateRTSDurationField(obj, isMURTS, isULSeq, rtsTxTime, mcs); % Calculate duration
mpdu.Header.Address1 = obj.Tx.TxFrame(obj.UserIndexSU).MPDUs(1).Header.Address1;
if useBWSig
    mpdu.Header.Address2 = wlan.internal.utils.bandwidthSignalingTA(obj.MACAddress);
else
    mpdu.Header.Address2 = obj.MACAddress;
end

% Fill MPDU metadata
mpdu.Metadata.MPDULength = rtsLength;
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = rtsLength;

% Create frame structure to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
frameToPHY.MACFrame.PSDULength = rtsLength;

% Update statistics
obj.Statistics.TransmittedRTSFrames = obj.Statistics.TransmittedRTSFrames + 1;
end

function frameToPHY = generateMURTS(obj, murtsLength, murtsTxTime, useBWSig, isULSeq, isICF)
% Generate an MU-RTS frame to initiate a DL OFDMA frame sequence

% Fill MPDU fields
mpdu = obj.MPDUMURTSTriggerTemplate;
tx = obj.Tx;
isMURTS = true;
mpdu.Header.Duration = calculateRTSDurationField(obj, isMURTS, isULSeq, murtsTxTime); % Calculate duration
mpdu.Header.Address1 = 'FFFFFFFFFFFF';
if useBWSig
    mpdu.Header.Address2 = wlan.internal.utils.bandwidthSignalingTA(obj.MACAddress);
else
    mpdu.Header.Address2 = obj.MACAddress;
end
mpdu.FrameBody.ChannelBandwidth = tx.TxBandwidth;
mpdu.FrameBody.CSRequired = 1; % CSRequired field shall always be true for MU-RTS (Section 26.5.2.5 of IEEE Std 802.11ax-2021)
for userIdx = 1:tx.NumTxUsers
    mpdu.FrameBody.UserInfo(userIdx).AID12 = getAID(obj.SharedMAC, tx.TxStationIDs(userIdx));
end
if mpdu.FrameBody.ChannelBandwidth == 320
    mpdu.FrameBody.CommonInfoVariant = 'EHT';
    mpdu.FrameBody.HEorEHTP160 = 0;
    mpdu.FrameBody.SpecialUserInfoPresent = true;
    for userIdx = 1:tx.NumTxUsers
        mpdu.FrameBody.UserInfo(userIdx).UserInfoVariant = 'EHT';
        mpdu.FrameBody.UserInfo(userIdx).PS160 = 1;
    end
end
if isICF
    % Get the padding bytes to use in MU-RTS frame
    numPadBytes = 0;
    for userIdx = 1:obj.Tx.NumTxUsers
        staIdxLogical = (obj.Tx.TxStationIDs(userIdx) == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
        numPadBytesForSTA = obj.SharedMAC.RemoteSTAInfo(staIdxLogical).NumEMLPadBytes;
        % AP ensures that the padding duration of MU-RTS frame (ICF) is greater
        % than or equal to the maximum for all the STAs with which frame exchanges
        % are initiated. Reference: Section 35.3.17 of IEEE P802.11be/D5.0
        numPadBytes = max(numPadBytes, numPadBytesForSTA);
    end
    mpdu.FrameBody.NumPadBytesICF = numPadBytes;
end

% Fill MPDU metadata
mpdu.Metadata.MPDULength = murtsLength;
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = murtsLength;

% Create frame structure to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
frameToPHY.MACFrame.PSDULength = murtsLength;

% Update statistics
obj.Statistics.TransmittedMURTSFrames = obj.Statistics.TransmittedMURTSFrames + 1;
end

function frameToPHY = generateMUBAR(obj, muBarTxTime)
% Generate an MU-BAR frame

% Determine MCS for response to be filled in trigger frame and calculate duration field
tx = obj.Tx;
txMCS = tx.TxMCS(1:tx.NumTxUsers);
txNumSTS = tx.TxNumSTS(1:tx.NumTxUsers);
cbw = 20; % This value would not be used for response MCS calculation. It is determined internally based on allocation index
respMCS = responseMCS(obj, tx.TxFormat, cbw, tx.TxAggregatedMPDU, txMCS, txNumSTS);
duration = calculateMUBARDurationField(obj, muBarTxTime, respMCS, txNumSTS);

% Fill MPDU fields
mpdu = obj.MPDUMUBARTriggerTemplate;
mpdu.Header.Duration = duration;
mpdu.Header.Address1 = 'FFFFFFFFFFFF';
mpdu.Header.Address2 = obj.MACAddress;
mpdu.FrameBody.ChannelBandwidth = tx.TxBandwidth;
mpdu.FrameBody.LSIGLength = tx.LSIGLength;
mpdu.FrameBody.NumHELTFSymbols = tx.NumHELTFSymbols;
if tx.LSIGLength <= 418
    % Reset CSRequired field when LSIGLength is less than or equal to 418,
    % according to section 26.5.2.5 of IEEE Std 802.11ax-2021
    mpdu.FrameBody.CSRequired = 0;
end
for userIdx = 1:tx.NumTxUsers
    mpdu.FrameBody.UserInfo(userIdx).AID12 = getAID(obj.SharedMAC, tx.TxStationIDs(userIdx));
    mpdu.FrameBody.UserInfo(userIdx).MCS = respMCS(userIdx);
    mpdu.FrameBody.UserInfo(userIdx).NumSpatialStreams = tx.TxNumSTS(userIdx);
    mpdu.FrameBody.UserInfo(userIdx).TID = wlan.internal.Constants.AC2TID(tx.TxACs(userIdx));
    mpdu.FrameBody.UserInfo(userIdx).StartingSequenceNum = tx.StartingSequenceNums(userIdx);
    mpdu.FrameBody.UserInfo(userIdx).RUSize = tx.CfgHEMU.RU{userIdx}.Size;
    mpdu.FrameBody.UserInfo(userIdx).RUIndex = tx.CfgHEMU.RU{userIdx}.Index;
end

% Fill MPDU metadata
isICF = false;
mpduLength = controlFrameMPDULength(obj, mpdu.Header.FrameType, mpdu.FrameBody.TriggerType, tx.NumTxUsers, isICF);
mpdu.Metadata.MPDULength = mpduLength;
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = mpduLength;

% Create frame struture to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
frameToPHY.MACFrame.PSDULength = mpduLength;

% Update statistics
obj.Statistics.TransmittedMUBARFrames = obj.Statistics.TransmittedMUBARFrames + 1;
end

function frameToPHY = generateBasicTrigger(obj, basicTriggerTxTime)
% Generate a Basic trigger frame

tx = obj.Tx;

% Fill MPDU header fields
mpdu = obj.MPDUBasicTriggerTemplate;
mpdu.Header.Duration = calculateBasicTriggerDurationField(obj, basicTriggerTxTime);
if tx.NumTxUsers == 1
    mpdu.Header.Address1 = wlan.internal.utils.nodeID2MACAddress(tx.TxStationIDs(1));
else
    mpdu.Header.Address1 = 'FFFFFFFFFFFF'; % Use broadcast if NumUsers > 1. Refer to Section 9.3.1.22.1 of IEEE Std 802.11ax-2021.
end
mpdu.Header.Address2 = obj.MACAddress;

% Fill MPDU frame body fields
mpdu.FrameBody.ChannelBandwidth = tx.TxBandwidth;
mpdu.FrameBody.LSIGLength = tx.LSIGLength;
if tx.LSIGLength <= 76
    mpdu.FrameBody.CSRequired = 0; % Reset CSRequired field if LSIGLength <= 76 (section 26.5.2.5 of IEEE Std 802.11ax-2021)
end
mpdu.FrameBody.NumHELTFSymbols = tx.NumHELTFSymbols;
preferredAC = getPreferredACForULTransmission(obj);
for userIdx = 1:tx.NumTxUsers
    mpdu.FrameBody.UserInfo(userIdx).AID12 = getAID(obj.SharedMAC, tx.TxStationIDs(userIdx));
    mpdu.FrameBody.UserInfo(userIdx).RUSize = obj.ULTBSysCfg.RU{userIdx}.Size;
    mpdu.FrameBody.UserInfo(userIdx).RUIndex = obj.ULTBSysCfg.RU{userIdx}.Index;
    mpdu.FrameBody.UserInfo(userIdx).MCS = obj.ULMCS(userIdx);
    mpdu.FrameBody.UserInfo(userIdx).NumSpatialStreams = obj.ULNumSTS(userIdx);
    mpdu.FrameBody.UserInfo(userIdx).PreferredAC = preferredAC(userIdx);

    % Note that TIDAggregationLimit is always 1. As per Section 26.5.2.2.4 of
    % IEEE Std 802.11ax-2021, this can be 0 if CS Required is false (optional),
    % or the solicited HE-TB PPDU is the last PPDU of the TXOP (mandatory).
    % Since immediate acknowledgement is supported, HE-TB PPDUs solicit it,
    % when enabled. If ack is disabled at STA, the AP is unaware of it while
    % sending trigger frame, so it cannot force a TIDAggregationLimit of 0.
    mpdu.FrameBody.UserInfo(userIdx).TIDAggregationLimit = 1;
end

% Fill MPDU metadata
isICF = false;
mpduLength = controlFrameMPDULength(obj, mpdu.Header.FrameType, mpdu.FrameBody.TriggerType, tx.NumTxUsers, isICF);
mpdu.Metadata.MPDULength = mpduLength;
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = mpduLength;

% Create frame structure to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
frameToPHY.MACFrame.PSDULength = mpduLength;

% Update statistics
obj.Statistics.TransmittedBasicTriggerFrames = obj.Statistics.TransmittedBasicTriggerFrames + 1;
end

function setBandwidthContext(obj, txVector)
% Set required bandwidth context when transmitting a frame

tx = obj.Tx;

switch tx.NextTxFrameType
    case {obj.RTS obj.MURTSTrigger}
        if ~strcmp(txVector.BandwidthOperation, 'Absent')
            tx.BWSignaledInRTS = true;
        end

        % Capture bandwidth of the RTS/MU-RTS transmitted in non-HT or non-HT duplicate
        % PPDU. If TXOP is protected by RTS/CTS, bandwidth of a PPDU is determined
        % based on the last RTS frame. If TXOP is protected by MU-RTS/CTS, where RU
        % allocation of all receivers are equal to the channel bandwidth in UL BW
        % subfield of MU-RTS, bandwidth of a PPDU is determined based on the last
        % MU-RTS frame. Reference: Section 10.23.2.8 of IEEE Std 802.11ax-2021.
        tx.LastRTSBandwidth = txVector.ChannelBandwidth;
        tx.LastPPDUBandwidth = txVector.ChannelBandwidth;

    case obj.QoSData
        if (txVector.PPDUFormat == obj.NonHT) && (txVector.ChannelBandwidth > 20) && ~tx.FirstNonHTDupBandwidth
            % Store the bandwidth of first Non-HT duplicate frame in TXOP
            tx.FirstNonHTDupBandwidth = txVector.ChannelBandwidth;
        end
        % Store BW used to transmit PPDU
        tx.LastPPDUBandwidth = txVector.ChannelBandwidth;

    case obj.MUBARTrigger
        % Capture the bandwidth of initial frame in first non-HT duplicate frame
        % exchange.
        if txVector.ChannelBandwidth > 20 && ... % Non-HT Dup frame exchange present
                ~tx.FirstNonHTDupBandwidth % No previous NonHT Dup bandwidth saved in TXOP
            % If there's no MU-RTS/CTS, initial frame in non-HT dup frame exchange is
            % MU-data frame. As MU-BAR frame is transmitted in same BW as data frame,
            % saving MU-BAR frame bandwidth as the bandwidth of initial frame.
            tx.FirstNonHTDupBandwidth = txVector.ChannelBandwidth;
        end
        tx.LastPPDUBandwidth = txVector.ChannelBandwidth;

    case obj.BasicTrigger
        % Capture the bandwidth of initial frame in first non-HT duplicate frame
        % exchange.
        if txVector.ChannelBandwidth > 20 && ... % Non-HT Dup frame exchange present
                ~tx.FirstNonHTDupBandwidth % No previous NonHT Dup bandwidth saved in TXOP
            tx.FirstNonHTDupBandwidth = txVector.ChannelBandwidth;
        end
        % Capture bandwidth of last PPDU
        tx.LastPPDUBandwidth = txVector.ChannelBandwidth;

    otherwise % Management frames
        % Capture the bandwidth of initial frame in first non-HT duplicate frame
        % exchange.
        if txVector.ChannelBandwidth > 20 && ... % Non-HT Dup frame exchange present
                ~tx.FirstNonHTDupBandwidth % No previous NonHT Dup bandwidth saved in TXOP
            tx.FirstNonHTDupBandwidth = txVector.ChannelBandwidth;
        end
        % Store BW used to transmit PPDU
        tx.LastPPDUBandwidth = txVector.ChannelBandwidth;
end
end

function dequeuePackets(obj)
% Dequeues packets for transmission

tx = obj.Tx;
% Get the queue object to dequeue packet for first user. As multi-user
% transmission is only supported for non-MLD, the packets for subsequent
% users must also be dequeued from same (per-link) queues.
queueObj = getQueueObj(obj, tx.TxStationIDs(obj.UserIndexSU), tx.TxACs(obj.UserIndexSU));

% Dequeue packets for transmission and store the indices of retry buffers
% in which dequeued packets are present
[tx.TxFrame, tx.RetryBufferIndices] = dequeue(queueObj, tx.TxStationIDs, tx.TxACs, tx.TxMPDUCount, tx.NumTxUsers);

isBroadcast = (tx.TxStationIDs(obj.UserIndexSU) == obj.BroadcastID);
isUnicastMLDReceiver = false;
remoteSTAInfo = obj.SharedMAC.RemoteSTAInfo;
if ~(isBroadcast) && ... % Unicast receiver
        any(tx.TxStationIDs(obj.UserIndexSU) == [remoteSTAInfo(:).NodeID])
    receiverIdxLogical = tx.TxStationIDs(obj.UserIndexSU) == [remoteSTAInfo(:).NodeID];
    isUnicastMLDReceiver = remoteSTAInfo(receiverIdxLogical).IsMLD;
end
if isUnicastMLDReceiver || ... % Unicast MLD packet
        (obj.IsAffiliatedWithMLD && tx.TxFrame(obj.UserIndexSU).MPDUs(1).Metadata.ReceiverID == obj.BroadcastID) % Broadcast MLD packet
    tx.TxFrame = updateAddressFields(obj, tx.TxFrame);
end

isManagementFrame = wlan.internal.utils.isManagementFrame(tx.TxFrame(obj.UserIndexSU).MPDUs(1));

if isManagementFrame
    tx.TxFrameLength = tx.TxFrame(obj.UserIndexSU).MPDUs(1).Metadata.MPDULength;
    tx.TxMPDULengths(obj.UserIndexSU) = tx.TxFrameLength;
    tx.TxSubframeLengths(obj.UserIndexSU) = tx.TxFrameLength;
    tx.TxPSDULength = tx.TxFrameLength;
else % Data frame
    % Calculate APEP length and MPDU length(s)
    [tx.TxFrameLength, tx.TxMPDULengths, tx.TxSubframeLengths] = calculateAPEPLength(obj, false, tx.TxFormat, tx.TxAggregatedMPDU);
    if (tx.TxFormat ~= obj.HE_TB)
        tx.TxPSDULength = calculatePSDULength(obj, tx.TxFormat, tx.TxFrameLength);
    else
        tx.TxPSDULength = tx.CfgTB.getPSDULength;
    end
end
end

function txFrame = updateAddressFields(obj, txFrame)
    % Update address fields of the frame with the link addresses

    for idx = 1:numel(txFrame)
        for mpduIdx = 1:numel(txFrame(idx).MPDUs)
            mpdu = txFrame(idx).MPDUs(mpduIdx);
            srcAddress = mpdu.Metadata.SourceAddress;
            srcID = wlan.internal.utils.macAddress2NodeID(srcAddress);
            updateSrcAddress = true;
            if obj.IsAPDevice && (srcID ~= 0) && (srcID ~= obj.NodeID)
                % Packet originated at a different source and is being forwarded by AP. Do
                % not update source MAC address in this case
                updateSrcAddress = false;
            end
            if updateSrcAddress
                mpdu.Metadata.SourceAddress = obj.MACAddress;
            end
            if obj.IsAPDevice
                receiverID = mpdu.Metadata.ReceiverID;
                if receiverID == 65535
                    % Receiver address and destination address are filled before enqueuing the
                    % packet into queue.
                    if ~updateSrcAddress
                        % AP is forwarding a broadcast packet originated at STA. Modify Source
                        % Address as MLD MAC address of the STA. Reference: Section 35.3.15.1 of
                        % IEEE P802.11be/D5.0. Generate MLD MAC address by passing second
                        % input argument (device ID) as 0.
                        staMLDMACAddr = wlan.internal.utils.nodeID2MACAddress([srcID 0]);
                        mpdu.Metadata.SourceAddress = staMLDMACAddr;
                    end
                else
                    mpdu.Header.Address1 = getMACAddress(obj.SharedMAC, receiverID, obj.DeviceID);
                    mpdu.Metadata.DestinationAddress = mpdu.Header.Address1;
                end
            elseif obj.IsAssociatedSTA
                mpdu.Header.Address1 = obj.BSSID;
                apNodeID = wlan.internal.utils.macAddress2NodeID(obj.BSSID);
                destID = wlan.internal.utils.macAddress2NodeID(mpdu.Metadata.DestinationAddress);
                if destID == apNodeID
                    mpdu.Metadata.DestinationAddress = mpdu.Header.Address1;
                end
            end
            txFrame(idx).MPDUs(mpduIdx) = mpdu;
        end
    end
end

function moveToNextState(obj, currentTime)
% Moves to next state based on the transmitted frame

tx = obj.Tx;
resetContextAfterFrameTx(obj);
updateCommonTxStats(obj);

switch tx.LastTxFrameType
    case obj.Beacon
        stateChange(obj, obj.CONTEND_STATE);

        % Set/reset context
        obj.IsLastTXOPHolder = true;
        obj.TBTTAcquired = false;
        resetContextAfterTXOPEnd(obj);

        % Statistics increment
        obj.Statistics.TransmittedBeaconFrames = obj.Statistics.TransmittedBeaconFrames + 1;

    case obj.CFEnd
        if obj.IsEMLSRSTA
            % Wait for EMLSR transition delay in INACTIVE_STATE and switch to
            % listening operation in all links.
            stateChange(obj, obj.INACTIVE_STATE);
        else
            % Move immediately to CONTEND_STATE
            stateChange(obj, obj.CONTEND_STATE);
            obj.IsLastTXOPHolder = true;
        end

        % Reset context
        resetContextAfterTXOPEnd(obj);

        % Statistics increment
        obj.Statistics.TransmittedCFEndFrames = obj.Statistics.TransmittedCFEndFrames + 1;

    case {obj.RTS, obj.MURTSTrigger}
        % State change to RECEIVERESPONSE_STATE if the transmitted frame
        % requires a response
        stateChange(obj, obj.RECEIVERESPONSE_STATE);


    case {obj.MUBARTrigger, obj.BasicTrigger}
        % State change to RECEIVERESPONSE_STATE if the transmitted frame
        % requires a response
        stateChange(obj, obj.RECEIVERESPONSE_STATE);

        % Send to phy Rx, the time after which HE TB PPDUs are expected
        % after sending an MU-BAR trigger frame.
        obj.SendTrigRequestFcn(currentTime + obj.SIFSTime);

    case obj.QoSNull
        isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
        if obj.CCAState(1) % Last known primary 20 MHz state is busy
            stateChange(obj, obj.RECEIVE_STATE);

        elseif ~isNAVExpired
            stateChange(obj, obj.NAVWAIT_STATE);

        else
            % If both the NAV timers are elapsed and channel is idle, move to
            % CONTEND_STATE
            stateChange(obj, obj.CONTEND_STATE);
        end

    otherwise % {obj.QoSData, obj.Management}
        if tx.NoAck
            for userIdx = 1:tx.NumTxUsers
                if any(tx.LastTxFrameType, [obj.QoSData, obj.Management])
                    % Discard packets from MAC queue
                    [queueObj, isSharedQ] = getQueueObj(obj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
                    discardIndices = 1:tx.TxMPDUCount(userIdx);
                    discard(obj, isSharedQ, queueObj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx), tx.RetryBufferIndices(userIdx), discardIndices);
                end

                % Statistics increment
                if tx.LastTxFrameType == obj.QoSData
                    obj.SuccessfulDataTransmissionsPerAC(tx.TxACs(userIdx)) = obj.SuccessfulDataTransmissionsPerAC(tx.TxACs(userIdx)) + tx.TxMPDUCount(userIdx);
                else % Management frames
                    obj.SuccessfulManagementTransmissions = obj.SuccessfulManagementTransmissions + tx.TxMPDUCount(userIdx);
                end
            end

            if (tx.TxFormat == obj.HE_TB) % Sent a data frame in HE-TB format
                isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
                if obj.CCAState(1) % Last known primary 20 MHz state is busy
                    stateChange(obj, obj.RECEIVE_STATE);

                elseif ~isNAVExpired
                    stateChange(obj, obj.NAVWAIT_STATE);

                else
                    % If both the NAV timers are elapsed and channel is idle, move to
                    % CONTEND_STATE
                    stateChange(obj, obj.CONTEND_STATE);
                end

            else
                % Reset QSRC and CW
                resetQSRCAndCW(obj);

                % Check if TXOP can be continued
                [continueTXOP, tx.NextTxFrameType] = decideTXOPStatus(obj, false);

                if continueTXOP || (tx.NextTxFrameType == obj.CFEnd) % Continue TXOP or end TXOP with CF-End
                    % Send next frame after waiting for SIFS
                    obj.NextInvokeTime = currentTime + obj.SIFSTime;
                    obj.MACSubstate = obj.WAITINGFORSIFS_SUBSTATE;
                    resetContextAfterCurrentFES(obj);

                else % End the TXOP without CF-End
                    if obj.IsEMLSRSTA
                        % Wait for EMLSR transition delay in INACTIVE_STATE and switch to
                        % listening operation in all links.
                        stateChange(obj, obj.INACTIVE_STATE);
                    else
                        % Move immediately to CONTEND_STATE
                        stateChange(obj, obj.CONTEND_STATE);
                        obj.IsLastTXOPHolder = true;
                    end
                    resetContextAfterTXOPEnd(obj);
                end
            end
        else % Ack Required
            if (tx.TxFormat == obj.HE_MU) && (obj.DLOFDMAFrameSequence == 2)
                % Send MU-BAR trigger after waiting for SIFS
                obj.NextInvokeTime = currentTime + obj.SIFSTime;
                obj.MACSubstate = obj.WAITINGFORSIFS_SUBSTATE;
                tx.NextTxFrameType = obj.MUBARTrigger;

            else
                % State change to RECEIVERESPONSE_STATE if the transmitted
                % frame requires a response
                stateChange(obj, obj.RECEIVERESPONSE_STATE);

                if (tx.TxFormat == obj.HE_MU) && (obj.DLOFDMAFrameSequence == 1)
                    % Send to phy Rx, the time after which HE TB PPDUs are expected after
                    % sending a frame with TRS Control field.
                    obj.SendTrigRequestFcn(currentTime + obj.SIFSTime);
                end
            end
        end
end
end

function resetContextAfterFrameTx(obj)
%resetContextAfterFrameTx Reset context after frame transmission

tx = obj.Tx;
tx.NextTxFrameType = obj.UnknownFrameType;
tx.FrameTxTime = 0;
end

function nextFrameType = rescheduleTransmissionIfNeeded(obj)
%rescheduleTransmissionIfNeeded Perform scheduling actions once again if
%needed
% Check if scheduled number of packets are still present in the queue
% before starting a new frame exchange sequence. This is required in case
% of MLD because other link might transmit the packets scheduled for
% transmission by this link.

tx = obj.Tx;
% By default, some transmission is scheduled. Reschedule only if necessary.
nextFrameType = tx.NextTxFrameType;
reschedule = false;

newFESStart = ((any(nextFrameType == [obj.RTS obj.MURTSTrigger])) || ...
    (any(nextFrameType == [obj.QoSData obj.Management]) && ~any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger])));
if obj.IsAffiliatedWithMLD && newFESStart
    % In case of MLD nodes, the packets scheduled for transmission in this
    % link may be scheduled by other link too. This is not known until the
    % other link dequeues packets and transmits frame. So, check for queue
    % length and attempt to schedule again if required when starting a new
    % frame exchange sequence i.e.,:
    % 1. Before transmitting RTS/MU-RTS, if enabled
    % 2. Before transmitting QoS Data, without RTS/MU-RTS frame
    % Get queue object, index to access queue and retry buffer index
    queueObj = getQueueObj(obj, tx.TxStationIDs(obj.UserIndexSU), tx.TxACs(obj.UserIndexSU));
    if ~isempty(queueObj)
        [~, retryBufferIdx] = getAvailableRetryBuffer(queueObj, tx.TxStationIDs(obj.UserIndexSU), tx.TxACs(obj.UserIndexSU));
        queueLength = numTxFramesAvailable(obj, tx.TxACs(obj.UserIndexSU), tx.TxStationIDs(obj.UserIndexSU), queueObj, retryBufferIdx);
    else
        queueLength = 0;
    end
    % If another link transmitted packets since this link last scheduled,
    % queue length will be less than the stored MSDU count.
    if (queueLength < tx.TxMPDUCount(obj.UserIndexSU))
        reschedule = true;
    end
end

if reschedule && tx.ContinueMFTXOP % Rescheduling is needed only in multi-frame TXOP in MLO currently
    % Check if next FES is possible. Do not account for SIFS/PIFS wait
    % time while checking for next FES because SIFS/PIFS is already
    % elapsed.
    isFail = false;
    excludeIFS = true;
    [~, nextFrameType] = decideTXOPStatus(obj, isFail, excludeIFS);
end
end

function duration = calculateRTSDurationField(obj, isMURTS, isULSequence, rtsTxTime, rate)
% Calculate duration field for RTS or MU-RTS trigger frame for DL transmission

tx = obj.Tx;

if isMURTS
    ctsDuration = obj.AckOrCTSBasicRateDuration; % CTS uses 6 Mbps basic rate for MU-RTS
else % RTS
    ctsDuration = calculateTxTime(obj, obj.NonHT, obj.AckOrCtsFrameLength, rate, 1, 20);  % CTS response is sent with same data rate as RTS
end

if isULSequence
    % Calculate Basic Trigger frame duration
    [basicTFMCS, basicTFLength] = controlFrameRateAndLen(obj, obj.BasicTrigger);
    basicTFNumSTS = 1;
    basicTFDuration = calculateTxTime(obj, obj.NonHT, basicTFLength, basicTFMCS, basicTFNumSTS, 20);

    % Solicited HE-TB PPDU duration
    ppduInfo = validateConfig(obj.ULTBSysCfg);
    ulDataDuration = round(ppduInfo.TxTime*1e3);

    % Calculate Multi STA BA duration
    multiSTABADuration = getAckDuration(obj, false);

    % Duration to be filled in MU-RTS
    duration = obj.SIFSTime + ctsDuration + obj.SIFSTime + basicTFDuration + ...
        obj.SIFSTime + ulDataDuration + obj.SIFSTime + multiSTABADuration;

else % DL sequence
    ackDuration = getAckDuration(obj, true);
    isDataFrame = wlan.internal.utils.isDataFrame(tx.TxFrame(obj.UserIndexSU).MPDUs(1));
    if isDataFrame
        cbw = tx.TxBandwidth;
        dataFrameMCS = tx.TxMCS(1:tx.NumTxUsers);
        dataFrameNumSTS = tx.TxNumSTS(1:tx.NumTxUsers);
        dataFrameLength = tx.TxFrameLength(1:tx.NumTxUsers);
        dataFrameDuration = calculateTxTime(obj, tx.TxFormat, dataFrameLength, dataFrameMCS, dataFrameNumSTS, cbw);
        % Duration to be filled in RTS/MU-RTS
        duration = 3*obj.SIFSTime + ctsDuration + ackDuration + dataFrameDuration;
    else
        cbw = 20;
        mgtFrameMCS = 0;
        mgtFrameNumSTS = 1;
        mgtFrameLength = tx.TxPSDULength(1:tx.NumTxUsers);
        mgtFrameDuration = calculateTxTime(obj, obj.NonHT, mgtFrameLength, mgtFrameMCS, mgtFrameNumSTS, cbw);
        % Duration to be filled in RTS/MU-RTS
        duration = 3*obj.SIFSTime + ctsDuration + ackDuration + mgtFrameDuration;
    end

    if tx.NoAck
        % If acknowledgments are disabled, subtract the acknowledgment duration
        % and a SIFS
        duration = duration - ackDuration - obj.SIFSTime;
    end

    if (tx.TxFormat == obj.HE_MU && obj.DLOFDMAFrameSequence == 2) && ~tx.NoAck
        % If DL OFDMA frame exchange sequence includes MU-BAR, consider an
        % additional SIFS and MU-BAR duration in the duration field
        [muBarRate, muBarLength] = controlFrameRateAndLen(obj, obj.MUBARTrigger);
        mubarNumSTS = 1;
        cbw = 20; % This value would not be used. Bandwidth will be determined internally based on allocation index
        muBarDuration = calculateTxTime(obj, obj.NonHT, muBarLength, muBarRate, mubarNumSTS, cbw);
        duration = duration + obj.SIFSTime + muBarDuration;
    end
end

% If data transmission exceeds TXOP limit (Reference: Section 10.23.2.9
% of IEEE Std. 802.11ax-2021, The TXOP holder may exceed the TXOP limit
% only if it does not transmit more than one Data or Management frame
% in the TXOP, for the following situation: Initial transmission of an
% MSDU under a block ack agreement, where the MSDU is not in an A-MPDU
% consisting of more than one MPDU and the MSDU is not in an A-MSDU."),
% fill duration accordingly
if obj.TXNAVTimer % Multi frame TXOP enabled
    if (duration+rtsTxTime) <= obj.TXNAVTimer % FES does not exceed the TXOP limit
        duration = obj.TXNAVTimer - rtsTxTime; % In nanoseconds
    end
end

% Convert duration field to microseconds and round off to nanoseconds granularity
duration = round(duration*1e-3, 3);

% Round up to next integer microsecond
% (If beacon transmissions are enabled, TBTTs are set at nanoseconds
% granularity, which may lead to fractional value of duration)
if obj.TBTT
    duration = ceil(duration);
end
end

function duration = calculateMUBARDurationField(obj, muBarTxTime, respMCS, txNumSTS)
% Calculate duration field for MU BAR trigger frame

if obj.TXNAVTimer % Multi frame TXOP enabled
    duration = obj.TXNAVTimer - muBarTxTime; % In nanoseconds
else
    heTBFrameLengths = wlan.internal.mac.calculateHETBResponseLength(obj.Tx.NumTxUsers, obj.BABitmapLength);
    ackDuration = calculateTxTime(obj, obj.HE_TB, heTBFrameLengths, respMCS, txNumSTS, 'TriggerFrame');
    duration = obj.SIFSTime + ackDuration; % In nanoseconds
end

% Calculate Duration field of the MU-BAR frame in microseconds
duration = round(duration*1e-3, 3);

% Round up to next integer microsecond
% (If beacon transmissions are enabled, TBTTs are set at nanoseconds
% granularity, which may lead to fractional value of duration)
if obj.TBTT
    duration = ceil(duration);
end
end

function duration = calculateBasicTriggerDurationField(obj, basicTriggerTxTime)
% Calculate duration field for Basic trigger frame

tx = obj.Tx;
% Solicited HE TB PPDU duration
ppduInfo = validateConfig(obj.ULTBSysCfg);
ulDataDuration = round(ppduInfo.TxTime*1e3);

% Calculate Multi STA BA duration
multiSTABALength = controlFrameMPDULength(obj, 'Multi-STA-BA', [], tx.NumTxUsers, false);
obj.MultiSTABARate = responseMCS(obj, obj.HE_TB, 20, true, obj.ULMCS, obj.ULNumSTS); % mpduAgg = true
multiSTABADuration = calculateTxTime(obj, obj.NonHT, multiSTABALength, obj.MultiSTABARate, 1, 20);

% Calculate Duration field of the Basic trigger frame in nanoseconds
if obj.TXNAVTimer % Multi frame TXOP enabled
    duration = obj.TXNAVTimer - basicTriggerTxTime;
else
    duration = obj.SIFSTime + ulDataDuration + obj.SIFSTime + multiSTABADuration;
end

% Convert duration field to microseconds and round off to nanoseconds granularity
duration = round(duration*1e-3, 3);

% Round up to next integer microsecond
% (If beacon transmissions are enabled, TBTTs are set at nanoseconds
% granularity, which may lead to fractional value of duration)
if obj.TBTT
    duration = ceil(duration);
end

end

function preferredAC = getPreferredACForULTransmission(obj)
tx = obj.Tx;
% Form PreferredAC field. This subfield indicates the lowest AC that is
% recommended for aggregation of MPDUs in the A-MPDU contained in the HE TB
% PPDU sent as a response to the Trigger frame
preferredAC = ones(tx.NumTxUsers, 1)*obj.OwnerAC;
for idx = 1:tx.NumTxUsers
    % Find the entries of the scheduled STA in the queue information
    staIndicesLogical = (tx.TxStationIDs(idx) == obj.STAQueueInfo(:, 1));
    if any(staIndicesLogical)
        % If queue information is present for a scheduled STA, get the ACs for
        % which information is available.
        availableACs = obj.STAQueueInfo(staIndicesLogical, 2);
        % Set the PreferredAC as the AC with highest data. If more than one AC has
        % highest data, select the first entry.
        preferredAC(idx) = availableACs(find(obj.STAQueueInfo(staIndicesLogical, 3) == max(obj.STAQueueInfo(staIndicesLogical, 3)), 1));
    end
end
end

function performPostTxActionsHandling(obj)
% Handle actions after the transmission

    if (obj.Tx.LastTxFrameType == obj.Management) && ~isempty(obj.PerformPostManagementTxActionsCustomFcn)
        obj.PerformPostManagementTxActionsCustomFcn(obj, obj.Tx.TxFrame(1).MPDUs(1));
    end
end

function updateCommonTxStats(obj)
% Update common transmission stats

if wlan.internal.utils.isManagementFrame(obj.Tx.LastTxFrameType)
    obj.TransmittedManagementFrames = obj.TransmittedManagementFrames + 1;
end
end