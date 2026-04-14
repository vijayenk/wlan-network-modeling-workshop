function nextFrameType = scheduleNonTriggerTransmission(obj, isInitialFES, excludeIFS)
%scheduleNonTriggerTransmission Schedules stations and returns the next frame
%to be transmitted (RTS/MU-RTS/QoS Data/Initial control frame)
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTFRAMETYPE = scheduleNonTriggerTransmission(OBJ, true) schedules
%   destination stations for first frame exchange sequence (FES) or during
%   an internal collision.
%
%   NEXTFRAMETYPE = scheduleNonTriggerTransmission(OBJ, ISINITIALFES,
%   EXCLUDEIFS) is used for a non-initial FES in a multi-frame TXOP to
%   schedule stations if required.
%
%   NEXTFRAMETYPE is an enumerated value returned as one of the following
%   constant values of edcaMAC object: RTS, QoSData, MURTSTrigger.
%
%   OBJ is an object of type edcaMAC.
%
%   ISINITIALFES is a logical scalar. If specified as false, MAC checks if
%   a non-initial frame exchange sequence can start within the remaining
%   TXOP duration.
%
%   EXCLUDEIFS is a logical scalar that indicates whether SIFS/PIFS must be
%   excluded while determining if a new FES can be initiated. If this input
%   is not provided, the function considers a default value of true.

%   Copyright 2025 The MathWorks, Inc.

nextFrameType = obj.UnknownFrameType;
tx = obj.Tx; % obj.Tx is a handle object
if nargin == 2
    excludeIFS = true;
end

scheduleStations = isSTASchedulingRequired(obj, isInitialFES);
isScheduled = scheduleAndCalculateTxInfo(obj, scheduleStations, ~isInitialFES, excludeIFS);
if ~isScheduled
    return;
else
    % Peek into the queue to check whether the packet is a data or management frame

    % Get the queue object to dequeue packet for first user. As multi-user
    % transmission is only supported for non-MLD, the packets for subsequent
    % users must also be dequeued from same (per-link) queues.
    queueObj = getQueueObj(obj, tx.TxStationIDs(obj.UserIndexSU), tx.TxACs(obj.UserIndexSU));
    txFrame = peek(queueObj, tx.TxStationIDs, tx.TxACs, tx.TxMPDUCount, tx.NumTxUsers);
    isDataFrame = wlan.internal.utils.isDataFrame(txFrame(obj.UserIndexSU).MPDUs(1));
end

apToEMLSRSTA = isAPToEMLSRSTATransmission(obj); % AP MLD to EMLSR STA MLD
isBroadcast = tx.TxStationIDs(obj.UserIndexSU) == obj.BroadcastID;

if obj.IsAPDevice && obj.IsAffiliatedWithMLD % AP MLD
    isScheduled = checkConflictWithEMLSRSTAs(obj, apToEMLSRSTA, tx.TxStationIDs(obj.UserIndexSU));
    if ~isScheduled % Abort transmission
        return;
    end
    % Update the ID of the EMLSR STA to which AP will transmit the next frame.
    if apToEMLSRSTA
        obj.SharedMAC.CurrentEMLSRTxSTA(obj.DeviceID) = tx.TxStationIDs(obj.UserIndexSU);
    end
    if isBroadcast
        obj.SharedMAC.BroadcastTxInProgress(obj.DeviceID) = true;
    end
end

if isBroadcast
    % No acknowledgment for broadcast frames
    tx.NoAck = true;
    if isDataFrame
        nextFrameType = obj.QoSData;
    else
        nextFrameType = obj.Management;
    end

else % Unicast frame
    % Ack policy for this frame transmission
    tx.NoAck = obj.DisableAck;

    % Transmit ICF for first FES, failure of previous tx (ProtectNextFrame
    % true), scheduled stations change within TXOP (ProtectNextFrame true)
    if apToEMLSRSTA && tx.ProtectNextFrame
        % If receiver is a STA MLD operating in EMLSR mode, send an initial control
        % frame (ICF). MU-RTS is sent as ICF.
        nextFrameType = obj.MURTSTrigger;
    else
        % If medium sync delay timer is running and EMLSR STA has initiated a TXOP,
        % check whether the number of TXOPs since the start of MSD timer has not
        % reached maximum number of TXOPs. If no, then send an RTS frame as the
        % first frame of the obtained TXOP. Reference: Section 35.3.16.8.2 of
        % IEEE P802.11be/D5.0
        msdTimerInProgress = (obj.IsEMLSRSTA) && (obj.MediumSyncDelayTimer > obj.LastRunTimeNS);
        if msdTimerInProgress && isInitialFES
            if obj.NumMediumSyncTXOPs == obj.MediumSyncMaxTXOPs
                return;
            else
                obj.NumMediumSyncTXOPs = obj.NumMediumSyncTXOPs + 1;
            end
        end

        % Send RTS based on these conditions:
        %   1. At non-EMLSR STAs, RTS is sent only if all the
        %      following conditions are true
        %         a. DisableRTS is false
        %         b. PSDU length > RTS Threshold for Single User, or DL OFDMA is enabled
        %         c. In a Multi-frame TXOP, if attempting the initial frame transmission or if
        %            protection is deemed necessary for a non-initial frame transmission
        %      ProtectNextFrame is set to true in cases (a) and (c).
        %   2. At EMLSR STAs, RTS is sent only if all the
        %      following conditions are true
        %         a. Medium Sync delay timer is running, or
        %            RTS tx is decided based on DisableRTS, RTSThreshold and TransmissionFormat
        %         b. In a Multi-frame TXOP, if attempting the initial frame transmission or if
        %            protection is deemed necessary for a non-initial frame
        %            transmission. ProtectNextFrame is set to true in this case.
        sendRTS = (tx.TxPSDULength(1) > obj.RTSThreshold || (tx.TxFormat == obj.HE_MU)) && (tx.ProtectNextFrame);
        sendRTSFromEMLSRSTA = msdTimerInProgress && isInitialFES;
        sendRTS = sendRTS || sendRTSFromEMLSRSTA;
        if sendRTS
            if tx.TxFormat == obj.HE_MU
                nextFrameType = obj.MURTSTrigger;
            else
                nextFrameType = obj.RTS;
            end
        else
            if isDataFrame
                nextFrameType = obj.QoSData;
            else
                nextFrameType = obj.Management;
            end
        end
    end
end
end

function scheduleSTAs = isSTASchedulingRequired(obj, isInitialFES)
% Decide whether it is necessary to schedule stations for upcoming
% transmission. In a TXOP, schedule only for the first FES, or if there are
% no more frames belonging to the primary AC and destined to previously
% scheduled station.

scheduleSTAs = false;
tx = obj.Tx;

if isInitialFES
    % Schedule stations for initial frame exchange sequence
    scheduleSTAs = true;
else
    for userIdx = 1:tx.NumTxUsers
        % Get queue object, index to access queue and retry buffer index
        queueObj = getQueueObj(obj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
        if ~isempty(queueObj)
            [~, retryBufferIdx] = getAvailableRetryBuffer(queueObj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
            queueLength = numTxFramesAvailable(obj, tx.TxACs(userIdx), tx.TxStationIDs(userIdx), queueObj, retryBufferIdx);
        else
            queueLength = 0;
        end

        if queueLength == 0 % If no more frames for a previously scheduled AC and destination
            scheduleSTAs = true;
            break;
        end
    end
end
end

function continueTx = checkConflictWithEMLSRSTAs(obj, isEMLSRReceiver, txStationID)
% Return whether to proceed with transmission after checking for conflicts
% with active transmissions or receptions with EMLSR STAs

continueTx = true;

linkIDs = 1:obj.SharedMAC.NumLinks;
linkIdxLogical = ~(obj.DeviceID == linkIDs);
isBroadcast = txStationID == obj.BroadcastID;
if isEMLSRReceiver && any(txStationID == obj.SharedMAC.CurrentEMLSRTxSTA(linkIdxLogical))
    % Do not transmit to the same EMLSR STA on two different links at a time.
    % Reference: Section 35.3.17 of IEEE P802.11be/D5.0
    continueTx = false;
    return;
end

if isEMLSRReceiver && any(txStationID == obj.SharedMAC.CurrentEMLSRRxSTA(linkIdxLogical))
    % Do not send ICF to the EMLSR STA on this link, if AP MLD is receiving
    % from the same EMLSR STA on any of the other links.
    continueTx = false;
    return;
end

% Check whether any broadcast is happening on other links
isAnyBroadcastInProgress = any(obj.SharedMAC.BroadcastTxInProgress(linkIdxLogical));
if isAnyBroadcastInProgress && (isEMLSRReceiver || ...
        (any([obj.SharedMAC.RemoteSTAInfo(:).EnhancedMLMode]) && isBroadcast))
    % If broadcast data transmission in any other link is in progress, do not
    % transmit:
    %   1. ICF to any other EMLSR STA and
    %   2. Broadcast data if there is any EMLSR STA associated
    continueTx = false;
    return;
end

if isBroadcast && (any(obj.SharedMAC.CurrentEMLSRTxSTA(linkIdxLogical)) || any(obj.SharedMAC.CurrentEMLSRRxSTA(linkIdxLogical)))
    % Do not transmit broadcast data while transmitting to/receiving from an
    % EMLSR STA in other links
    continueTx = false;
    return;
end
end