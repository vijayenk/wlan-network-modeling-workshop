function nextInvokeTime = handleEventsReceiveResponse(obj, currentTime, phyIndication, frameFromPHY)
%handleEventsReceiveResponse Runs MAC Layer state machine for receiving
%response frames
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   This function performs the following operations:
%   1. Waits for response frames of data, RTS/MU-RTS and MU-BAR, response(s)
%      to Basic trigger frame
%   2. If it doesn't receive any frame within timeout duration,
%      try to retransmit that particular data or RTS/MU-RTS frame again.
%   3. Prepares response for the received frame(s) if needed.
%   4. Handles actions to be performed after response timeout.
%   5. Discards packet from retransmission buffer, if maximum
%      retransmission limit is reached.
%   6. Moves to ERRORRECOVERY_STATE, if it receives an error frame.
%   7. Moves to RECEIVE_STATE, if it receives any frame other than
%      ACK/CTS/BA.
%
%   NEXTINVOKETIME = handleEventsReceiveResponse(OBJ, CURRENTTIME,
%   PHYINDICATION, FRAMEFROMPHY) performs MAC Layer RECEIVERESPONSE_STATE
%   actions.
%
%   NEXTINVOKETIME is the time (in nanoseconds) at which the run function
%   must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is the indication received from PHY Layer.
%
%   FRAMEFROMPHY is the frame received from PHY layer.

%   Copyright 2022-2025 The MathWorks, Inc.

% Initialization
nextInvokeTime = Inf;

%% Handle active timers
updateTxNAVTimer(obj);

%% Handle PHY Indications
phyIndicationType = phyIndication.MessageType;
nextState = obj.RECEIVERESPONSE_STATE;
if phyIndicationType == obj.RxStartIndication
    nextState = handleRxStart(obj, phyIndication);
elseif (phyIndicationType == obj.RxErrorIndication || phyIndicationType == obj.RxEndIndication)
    nextState = handleRxEnd(obj, currentTime, phyIndication, frameFromPHY);
elseif phyIndicationType == obj.CCAIndication
    nextState = handleCCA(obj, currentTime, phyIndication);
end

% Switch to next state
if nextState ~= obj.RECEIVERESPONSE_STATE
    nextInvokeTime = moveToNextState(obj, nextState);
    return;
end

%% Handle Wait Times
if (obj.Tx.WaitForResponseTimer <= currentTime) && ~obj.Tx.IgnoreResponseTimeout % Response Wait Elapsed
    nextState = handlePostResponseWait(obj, currentTime);
    % Switch to next state
    nextInvokeTime = moveToNextState(obj, nextState);
elseif isTriggerFrameSent(obj) && (obj.StateEntryTimestamp + obj.SIFSTime <= currentTime) && ... % SIFS Time elapsed after sending trigger frames
        ~obj.Tx.IgnoreResponseTimeout % Response Timeout is not elapsed or RxStart is not received yet
    nextInvokeTime = handlePostSIFSWait(obj);
else
    if obj.NextInvokeTime > currentTime
        nextInvokeTime = obj.NextInvokeTime;
    end
end

end

%% Supporting Functions

function nextState = handleRxStart(obj, phyIndication)
%handleRxStart Handles RxStart physical layer indication
%
%   NEXTSTATE = handleRxStart(OBJ, PHYINDICATION) handles RxStart PHY
%   indication and sets the corresponding receiving context and MAC context
%   for a node.
%
%   NEXTSTATE defines the state MAC must move to after processing RxStart.
%
%   OBJ is an object of type edcaMAC.
%
%   PHYINDICATION is the indication received from PHY layer.

    % Initialize
    nextState = obj.RECEIVERESPONSE_STATE;
    tx = obj.Tx; % obj.Tx is a handle object
    rx = obj.Rx; % obj.Rx is a handle object
    tx.IgnoreResponseTimeout = true;
    rx.RxVector = phyIndication.Vector;
    
    if obj.Tx.LastTxFrameType == obj.BasicTrigger
        if rx.RxVector.PPDUFormat ~= obj.HE_TB
            % If the received frame format is other than HE-TB, then consider the Basic
            % TF transmission as failed and increment QSRC and CW. Reference: Section
            % 10.23.2.2 of IEEE Std 802.11ax-2021.
            incrementQSRCAndCW(obj);

            % Move to RECEIVE_STATE to process the non TB frame
            nextState = obj.RECEIVE_STATE;
        end
    end

    % Common for any indication
    if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
        nextState = updateNextStateEMLSR(obj, nextState);
    end
end

function nextState = handleCCA(obj, currentTime, phyIndication)
%handleRxStart Handles CCA physical layer indication
%
%   NEXTSTATE = handleCCA(OBJ, CURRENTTIME, PHYINDICATION) handles CCA.
%
%   NEXTSTATE defines the state MAC must move to after processing RxEnd or RxError.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is the indication received from PHY layer.

    % Initialize
    nextState = obj.RECEIVERESPONSE_STATE;
    rx = obj.Rx; % obj.Rx is a handle object
    tx = obj.Tx; % obj.Tx is a handle object

    % Get CCA state of primary channel before receiving CCAIndication
    prevState = obj.CCAState(1);
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
    
    if ~obj.CCAState(1) % Primary 20 is idle
        if ~prevState % Primary 20 was idle previously
            return;
        end

        % Get the number of stations from which responses are expected
        numRxUsers = tx.NumTxUsers;
        % In some cases, actual number of responses for data frames received might
        % be less than expected. Get the actual number of responses in these cases.
        % NumResponses is captured only for data frames and hence zero for
        % RTS/MU-RTS frames.
        if (tx.NumResponses < tx.NumTxUsers) && (tx.NumResponses ~= 0)
            numRxUsers = tx.NumResponses;
        end

        % 1. MU-RTS transmission is considered successful if CTS is received from any
        % of the addressed stations. Refer section 26.2.6.2 of IEEE Std
        % 802.11ax-2021. Assuming the same for MU-BAR transmission. Hence, move to
        % ERRORRECOVERY_STATE only if response frames from all the received users are
        % errored. However, if multi-frame TXOP is enabled, PIFS recovery can be
        % performed instead of EIFS for failure of a non-initial frame. Refer
        % section 10.23.2.2 of IEEE Std 802.11-2020.
        %
        % 2. Basic TF is considered successful if data is received from any of the
        % addressed stations.
        if all(rx.RxErrorMACFailure(1:numRxUsers))
            if tx.LastTxFrameType == obj.BasicTrigger
                % Increment QSRC and CW. Reference: Section 10.23.2.2 of IEEE Std
                % 802.11ax-2021
                incrementQSRCAndCW(obj);
            end
            
            rx.RxErrorMACFailure(1:end) = false; % Reset

            tx.LastTxFail = true;
            [continueTXOP, tx.NextTxFrameType] = decideTXOPStatus(obj, tx.LastTxFail);
            if continueTXOP % Transmit more frames
                % Perform PIFS recovery if last transmission fails
                obj.Tx.DoPIFSRecovery = true;
                nextState = obj.ERRORRECOVERY_STATE;
                resetContextAfterCurrentFES(obj);
            else % End TXOP
                % Move to ERRORRECOVERY_STATE. EIFS time = SIFS time + Ack duration. Ack duration is
                % same as CTS duration for MCS (0), NSTS (1), CBW (20)
                obj.EIFSTimer = currentTime + obj.SIFSTime + obj.AckOrCTSBasicRateDuration;
                nextState = obj.ERRORRECOVERY_STATE;
            end

        elseif rx.RxErrorPHYFailure
            if tx.LastTxFrameType ~= obj.BasicTrigger
                % Do not modify CW when a STA has sent an HE TB frame. Reference: Section
                % 10.23.2.2 of IEEE Std 802.11ax-2021
                if ~(tx.LastTxFrameType == obj.QoSData && tx.TxFormat == obj.HE_TB)
                    % Increment QSRC and CW. Reference: Section 10.23.2.2 of IEEE Std
                    % 802.11ax-2021
                    incrementQSRCAndCW(obj);
                    % Increment frame retry count of MSDUs that are not part of BA agreement,
                    % if transmission of the MSDUs or associated RTS fails. Reference: Section
                    % 10.23.2.12.1 of IEEE Std 802.11-2020
                    % No MSDUs are dequeued when uplink OFDMA transmission is scheduled by AP
                    % (i.e., ULOFDMAScheduled is set to true).
                    if ~tx.TxAggregatedMPDU && ~obj.ULOFDMAScheduled
                        % Get the queue object which contains packets whose frame retry count must
                        % be incremented.
                        queueObj = getQueueObj(obj, tx.TxStationIDs(obj.UserIndexSU), tx.TxACs(obj.UserIndexSU));
                        incrementFrameRetryCount(queueObj, tx.TxStationIDs(obj.UserIndexSU), ...
                            tx.TxACs(obj.UserIndexSU), tx.NumTxUsers, RetryBufferIndex=tx.RetryBufferIndices(obj.UserIndexSU), ...
                            MPDUCount=tx.TxMPDUCount(obj.UserIndexSU));
                    end
                end

                for idx = 1:tx.NumTxUsers
                    handleResponseFailure(obj, idx);
                end
            else
                % Increment QSRC and CW. Reference: Section 10.23.2.2 of IEEE Std
                % 802.11ax-2021
                incrementQSRCAndCW(obj);
            end

            tx.LastTxFail = true;
            [continueTXOP, tx.NextTxFrameType] = decideTXOPStatus(obj, tx.LastTxFail);

            % The EIFS/PIFS period shall begin after CCA Idle post receiving an erroneous
            % frame. Reference: Section 10.3.2.3.7 and Section 10.23.2.8 of IEEE Std
            % 802.11-2020.
            if continueTXOP % Transmit more frames
                % Perform PIFS recovery if last transmission fails
                obj.Tx.DoPIFSRecovery = true;
                nextState = obj.ERRORRECOVERY_STATE;
                resetContextAfterCurrentFES(obj);
            else % End TXOP
                % EIFS time = SIFS time + Ack duration. Ack duration is same as CTS
                % duration for MCS (0), NSTS (1), CBW (20). Start EIFS timer.
                obj.EIFSTimer = currentTime + obj.SIFSTime + obj.AckOrCTSBasicRateDuration;
                nextState = obj.ERRORRECOVERY_STATE;
            end

            rx.RxErrorPHYFailure = false; % Reset

        elseif any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger]) && ... % Last frame is RTS/MU-RTS
                any(tx.NextTxFrameType == [obj.QoSData obj.Management obj.BasicTrigger]) % Next frame is QoS Data or Management or Basic trigger
            nextState = obj.TRANSMIT_STATE;

        else
            if tx.IgnoreResponseTimeout
                % Response timeout is ignored if RxStart indication is received or response
                % timeout is already handled. If response timeout is ignored, move to
                % appropriate state on receiving CCA Idle. Else, wait until response
                % timeout is elapsed.

                [continueTXOP, tx.NextTxFrameType] = decideTXOPStatus(obj, tx.LastTxFail);
                if continueTXOP % Transmit more frames
                    if tx.LastTxFail
                        % Perform PIFS recovery if last transmission fails
                        obj.Tx.DoPIFSRecovery = true;
                        nextState = obj.ERRORRECOVERY_STATE;
                    else
                        % Move to sending data to transmit more frames
                        % after SIFS
                        nextState = obj.TRANSMIT_STATE;
                    end
                    resetContextAfterCurrentFES(obj);

                else % End TXOP
                    if (tx.NextTxFrameType == obj.CFEnd) % End TXOP with CF-End
                        nextState = obj.TRANSMIT_STATE;
                    else % End the TXOP without CF-End
                        % If NAV is remaining, go into NAV wait irrespective of whether or not MAC
                        % is TXOP holder. An example where MAC despite being TXOP holder goes into
                        % NAV wait - AP (TXOP holder) has sent Basic TF and STAs sent HE-TB data,
                        % which got corrupted and received by AP. Since AP got a corrupted frame,
                        % it has set NAV from RxVector. Since the frame is corrupted, it cannot be
                        % classified as inter/intra BSS and hence AP has set its basic NAV (as per
                        % Section 26.2.4 of IEEE Std 802.11ax-2021).
                        isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
                        if ~isNAVExpired
                            nextState = obj.NAVWAIT_STATE;
                        else
                            nextState = obj.CONTEND_STATE;
                            obj.IsLastTXOPHolder = true;
                        end
                    end
                end
            end
        end
    end

    % Common for any indication
    if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
        nextState = updateNextStateEMLSR(obj, nextState);
    end
end

function nextState = handleRxEnd(obj, currentTime, phyIndication, frameFromPHY)
%handleRxStart Handles RxEnd and RxError physical layer indications
%
%   NEXTSTATE = handleRxEnd(OBJ, CURRENTTIME, PHYINDICATION, FRAMEFROMPHY)
%   handles RxEnd and RxError and sets the corresponding receiving context
%   and MAC context for a node.
%
%   NEXTSTATE defines the state MAC must move to after processing RxEnd or RxError.
%
%   OBJ is an object of type edcaMAC.
%
%   PHYINDICATION is the indication received from PHY layer.
%
%   FRAMEFROMPHY is the frame received from PHY layer.

    % Initialize
    nextState = obj.RECEIVERESPONSE_STATE;
    rx = obj.Rx;
    
    if phyIndication.MessageType == obj.RxErrorIndication
        rx.RxVector = phyIndication.Vector;
        rx.RxErrorPHYFailure = true;
        % Trigger event to indicate PHY decode failure
        cbwInHz = phyIndication.Vector.ChannelBandwidth*1e6;
    
        % Note that MPDUDecoded event will be removed in a future release. Use the
        % ReceptionEnded event instead. Register for the ReceptionEnded
        % notification by using the 'registerEventCallback' function of wlanNode.
        if obj.HasListener.MPDUDecoded
            notifyPHYFailInMPDUDecoded(obj, phyIndication.PPDUInfo, cbwInHz);
        end
    
        if ~isempty(obj.ReceptionEndedFcn)
            notifyReceptionEnded(obj, 1, phyIndication.PPDUInfo, cbwInHz);
        end
    
    else % RxEnd
        if rx.RxVector.PPDUFormat == obj.NonHT
            rx.RxVector.NonHTChannelBandwidth = phyIndication.Vector.NonHTChannelBandwidth;
        end

        if ~isempty(frameFromPHY)
            nextState = handleRxEndWithResponse(obj, currentTime, phyIndication, frameFromPHY);
        else
            nextState = handleRxEndWithoutResponse(obj, currentTime, phyIndication);
        end
    end

    % Common for any indication
    if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
        nextState = updateNextStateEMLSR(obj, nextState);
    end
end

function nextState = handleRxEndWithResponse(obj, currentTime, phyIndication, frameFromPHY)
%handleRxEndWithResponse Handles RxEnd indication when a response is
%received

    % Initialize
    nextState = obj.RECEIVERESPONSE_STATE;
    rx = obj.Rx; % obj.Rx is a handle object
    tx = obj.Tx; % obj.Tx is a handle object

    if tx.LastTxFrameType ~= obj.BasicTrigger
        % Maintain a map corresponding to stations in TxStationIDs. Each
        % element of this map represents whether response is received from
        % station in TxStationIDs.
        isResponseReceived = false(obj.Tx.NumTxUsers, 1);

        % Update LastTxFail as a logical array to hold failure context
        % for each user
        obj.Tx.LastTxFail = false(obj.Tx.NumTxUsers, 1); % Updated in processResponse
        for frameIdx = 1:numel(frameFromPHY)
            [nextState, ~, isResponseReceived] = processResponse(obj, frameFromPHY(frameIdx), frameIdx, phyIndication.PPDUInfo, isResponseReceived);
        end

        if ~isempty(obj.ReceptionEndedFcn)
            notifyReceptionEnded(obj, 0, phyIndication.PPDUInfo, obj.Rx.RxVector.ChannelBandwidth*1e6);
        end

        % Transmission is considered a failure only if frames from all
        % intended stations failed. Convert LastTxFail back to a
        % scalar.
        obj.Tx.LastTxFail = all(obj.Tx.LastTxFail);

        % Check for stations from which responses are missing and handle
        % them
        handleMissingResponses(obj, isResponseReceived);

        % Store number of responses received for data frame(s)
        if any(obj.Tx.LastTxFrameType == [obj.QoSData obj.MUBARTrigger])
            obj.Tx.NumResponses = numel(frameFromPHY);
        end

    else % Basic Trigger
        rx.ResponseStationID = zeros(obj.MaxMUUsers, 1);

        numFrames = numel(frameFromPHY);
        rx.ULFramesFail = false(numFrames, 1); % Updated in processRxFrame
        for frameIdx = 1:numFrames
            processRxFrame(obj, frameFromPHY(frameIdx), frameIdx, phyIndication.PPDUInfo);
        end
        tx.LastTxFail = all(rx.ULFramesFail); % Only if frames from all intended stations failed, we can consider it as transmission failure

        if ~isempty(obj.ReceptionEndedFcn)
            notifyReceptionEnded(obj, 0, phyIndication.PPDUInfo, obj.Rx.RxVector.ChannelBandwidth*1e6);
        end

        if tx.LastTxFail
            % NAVTimer is set from Rxvector when all the subframes in all HE-TB PPDUs
            % failed. Basic TF transmission is failure and increment QSRC and CW.
            % Reference: Section 10.23.2.2 of IEEE Std 802.11ax-2021
            incrementQSRCAndCW(obj);
        end

        isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
        if ~tx.LastTxFail && ~isNAVExpired
            % NAVTimer is set from Rxvector when all the subframes in at least one
            % HE-TB PPDU failed. NAV need not be set if at least one QoS Null or QoS
            % Data is received (which implies a frame with Duration field is received,
            % Reference: Section 26.2.4 of IEEE Std 802.11ax-2021). So, reset NAV
            % timers.
            % AP receives only intended HE-TB frames. If at least one PPDU is
            % successfully decoded, it implies AP is in sync with the medium. Hence,
            % resetting NAV completely.
            obj.IntraNAVTimer = currentTime;
            obj.NAVTimer = currentTime;
            rx.IsIntendedNoAckFrame = false; % Reset
        end

        tx.NumResponses = numel(frameFromPHY);

        % Number of users to which Multi-STA BA must be generated
        numSTAsToBeAcked = nnz(rx.ResponseStationID);

        % No need to send Multi-STA BA if all HE TB PPDUs have failed (FCS failure)
        % or all HE TB PPDUs contain QoS Null, or Ack policy is set to NoAck.
        % At the end of this frame exchange sequence, either end the UL
        % sequence (Zero TXNAV), or continue the UL sequence if sufficient
        % TXNAV is available
        if numSTAsToBeAcked > 0
            rx.ResponseFrame = prepareMultiSTABA(obj, numSTAsToBeAcked);
            % Move to next substate to wait for SIFS time to
            % transmit response
            nextState = obj.TRANSMITRESPONSE_STATE;
        end

        % Reset the context maintained for UL transmission
        rx.MultiSTABAContextSTAIndices = zeros(obj.MaxMUUsers, 1);
        rx.MultiSTABAContextTIDs = zeros(obj.MaxMUUsers, 1);
    end
end

function nextState = handleRxEndWithoutResponse(obj, currentTime, phyIndication)
%handleRxEndWithoutResponse Handles RxEnd indication when a response is
%not received

    % Initialize
    nextState = obj.RECEIVERESPONSE_STATE;
    rx = obj.Rx; % obj.Rx is a handle object
    tx = obj.Tx; % obj.Tx is a handle object
    
    if obj.Rx.RxVector.TXOPDuration ~= 127 && ... % 127 indicates unspecified
            any(obj.Rx.RxVector.PPDUFormat == [obj.HE_SU, obj.HE_EXT_SU, obj.HE_MU, obj.HE_TB, obj.EHT_SU])
        if tx.LastTxFrameType ~= obj.BasicTrigger
            % No EIFS recovery required but transmission is still considered as
            % failure. So, failure actions are performed in handledMissingResponses as
            % necessary.
            isResponseReceived = false(obj.Tx.NumTxUsers, 1);
            handleMissingResponses(obj, isResponseReceived);
        else
            % No EIFS recovery required but increment QSRC and CW
            incrementQSRCAndCW(obj);
        end
    
        % Set NAV with duration indicated by TXOP_DURATION parameter in RxVector
        % when no frame with Duration field is received. Reference: Section 26.2.4
        % of IEEE Std 802.11ax-2021
        setNAVFromRxVector(obj, rx.RxVector);
        isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
        if ~isNAVExpired
            nextState = obj.NAVWAIT_STATE;
        else
            % Store context to decide if TXOP can be continued
            obj.Tx.LastTxFail = true;
        end
    else
        % Perform EIFS recovery when:
        % 1. RxEndIndication with no frame is received, except when TXOP duration
        % in Rx vector is not set as unspecified. References: Section 8.3.5.14.2
        % and 10.3.2.3.7 of IEEE Std 802.11-2020 and Section 10.3.2.3.7 of IEEE Std
        % 802.11ax-2021. RxEndIndication with no frame falls under RxEnd with
        % RxError not equal to NoError.
        %
        % 2. PPDU is filtered at PHY and not sent to MAC because it is not an HE TB
        % PPDU or an HE TB PPDU not intended to this node, consider that the Basic
        % TF transmission failed and increment QSRC and CW. Reference: Section
        % 10.23.2.2 of IEEE Std 802.11ax-2021. Additionally, perform EIFS recovery
        % when RxEndIndication with no frame is received, except when TXOP duration
        % in Rx vector is not set as unspecified. References: Section 8.3.5.14.2
        % and 10.3.2.3.7 of IEEE Std 802.11-2020 and Section 10.3.2.3.7 of IEEE Std
        % 802.11ax-2021. RxEndIndication with no frame falls under RxEnd with
        % RxError not equal to NoError.
    
        % To perform EIFS recovery and other transmission failure actions after CCA
        % Idle is received, set RxErrorPHYFailure flag to true.
        rx.RxErrorPHYFailure = true;
    end
    
    % Trigger event to indicate PHY decode failure
    cbwInHz = rx.RxVector.ChannelBandwidth*1e6;
    
    % Note that MPDUDecoded event will be removed in a future release. Use the
    % ReceptionEnded event instead. Register for the ReceptionEnded
    % notification by using the 'registerEventCallback' function of wlanNode.
    if obj.HasListener.MPDUDecoded
        notifyPHYFailInMPDUDecoded(obj, phyIndication.PPDUInfo, cbwInHz);
    end
    
    if ~isempty(obj.ReceptionEndedFcn)
        notifyReceptionEnded(obj, 1, phyIndication.PPDUInfo, cbwInHz);
    end
end

function nextInvokeTime = handlePostSIFSWait(obj)
%handlePostSIFSWait Handles actions after SIFS wait is elapsed

    % Turn on PHY receiver SIFS after:
    %    1. sending a trigger frame, i.e. frame with TRS Control in
    %       sequence 1 or MU-BAR trigger frame in sequence 2
    %    2. The reception of HE-TB PPDUs is expected to happen SIFS after sending a
    %       Basic TF. The non HE-TB PPDUs received within this SIFS must not be
    %       treated as signal of interest, as we are waiting for HE-TB. To facilitate
    %       this, PHY receiver is kept off during the SIFS time. Turn on the PHY
    %       receiver after SIFS.
    switchOnPHYRx(obj);
    obj.NextInvokeTime = obj.Tx.WaitForResponseTimer;
    nextInvokeTime = obj.NextInvokeTime;
end

function nextState = handlePostResponseWait(obj, currentTime)
%handlePostResponseWait Handles actions after response wait is elapsed
%
%   NEXTSTATE = handlePostResponseWait(OBJ, CURRENTTIME) increments the retry
%   counter and updates corresponding rx context, tx context and rate
%   context. OBJ is an object of type edcaMAC.
%
%   NEXTSTATE is the current MAC state. The current MAC state might be a
%   value other than edcaMAC.RECEIVERESPONSE_STATE due to transition based
%   on CCA state after timeout.
%
%   CURRENTTIME is the simulation time in nanoseconds.

    % Initialize
    nextState = obj.RECEIVERESPONSE_STATE;
    tx = obj.Tx; % obj.Tx is a handle object
    
    if ~tx.IgnoreResponseTimeout
        if tx.LastTxFrameType ~= obj.BasicTrigger
            % If the STA has responded with HE TB data frame, do not modify the CW
            % and QSRC.
            if ~(tx.LastTxFrameType == obj.QoSData && tx.TxFormat == obj.HE_TB)
                % Increment frame retry count of MSDUs that are not part of BA
                % agreement, if transmission of the MSDUs or associated RTS fails.
                % Reference: Section 10.23.2.12.1 of IEEE Std 802.11-2020
                % No MSDUs are dequeued when uplink OFDMA transmission is scheduled by AP
                % (i.e., ULOFDMAScheduled is set to true).
                if ~tx.TxAggregatedMPDU && ~obj.ULOFDMAScheduled
                    % Get the queue object which contains packets whose frame retry count must
                    % be incremented.
                    queueObj = getQueueObj(obj, tx.TxStationIDs(obj.UserIndexSU), tx.TxACs(obj.UserIndexSU));
                    incrementFrameRetryCount(queueObj, tx.TxStationIDs(obj.UserIndexSU), ...
                        tx.TxACs(obj.UserIndexSU), tx.NumTxUsers, RetryBufferIndex=tx.RetryBufferIndices(obj.UserIndexSU), ...
                        MPDUCount=tx.TxMPDUCount(obj.UserIndexSU));
                end

                % Increment QSRC and CW. Reference: Section 10.23.2.2 of IEEE Std
                % 802.11ax-2021
                incrementQSRCAndCW(obj);
            end

            for userIdx = 1:tx.NumTxUsers
                % Response failure
                handleResponseFailure(obj, userIdx);
            end
        else
            % Increment QSRC and CW. Reference: Section 10.23.2.2 of IEEE Std
            % 802.11ax-2021
            incrementQSRCAndCW(obj);
        end
        
        tx.IgnoreResponseTimeout = true; % Reset
        
        if ~obj.CCAState(1) % Primary 20 is idle
            tx.LastTxFail = true;
            [continueTXOP, tx.NextTxFrameType] = decideTXOPStatus(obj, tx.LastTxFail);
            if continueTXOP % Transmit more frames
                % Perform PIFS recovery if last transmission fails
                obj.Tx.DoPIFSRecovery = true;
                nextState = obj.ERRORRECOVERY_STATE;
                resetContextAfterCurrentFES(obj);
    
            else % End the TXOP
                if (tx.NextTxFrameType == obj.CFEnd) % End TXOP with CF-End
                    nextState = obj.TRANSMIT_STATE;
                else
                    % MAC has not received any response within the response timeout period. If
                    % MAC is the TXOP holder (all cases except STA waiting for Multi-STA BA),
                    % it would not have set it's NAV (NAV can only be set if RxEnd has been
                    % received with/without a response). So it will go into CONTENTION_STATE.
                    % If MAC is not the TXOP holder (STA waiting for Multi-STA BA), it would
                    % have set its intra BSS NAV anyway when it received the Basic TF. Thus it
                    % would go into NAVWAIT_STATE.
                    isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
                    if ~isNAVExpired
                        nextState = obj.NAVWAIT_STATE;
                    else
                        nextState = obj.CONTEND_STATE;
                        obj.IsLastTXOPHolder = true;
                    end
                end
            end
        else
            % If channel is busy after response timeout, move to
            % RECEIVE_STATE state and further process the frame or
            % indications.
            nextState = obj.RECEIVE_STATE;
        end
    end

    if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
        nextState = updateNextStateEMLSR(obj, nextState);
    end
end

function nextInvokeTime = moveToNextState(obj, nextState)
%moveToNextState Perform state transition actions and set nextInvokeTime of
%new state
    
    % From this state, TXOP must end if MAC needs to move to any of the
    % following states
    if any(nextState == [obj.RECEIVE_STATE obj.NAVWAIT_STATE obj.INACTIVE_STATE obj.CONTEND_STATE]) || ... % TXOP End states
            (nextState == obj.ERRORRECOVERY_STATE && ~obj.Tx.DoPIFSRecovery) || ... % EIFS recovery 
            (nextState == obj.TRANSMITRESPONSE_STATE && obj.Tx.LastTxFrameType ~= obj.BasicTrigger) % STA responding to an unexpected frame is considered as TXOP end
        % Reset Tx flags
        resetContextAfterTXOPEnd(obj);
        stateChange(obj, nextState);
    % TXOP continues when MAC needs to move to any of the following states
    elseif any(nextState == [obj.TRANSMIT_STATE obj.TRANSMITRESPONSE_STATE]) || ...
            (nextState == obj.ERRORRECOVERY_STATE && obj.Tx.DoPIFSRecovery) % PIFS recovery
        stateChange(obj, nextState);
    end
    nextInvokeTime = obj.NextInvokeTime;
end

function handleResponseFailure(obj, userIdx)
%handleResponseFailure Performs the operations required when expected
%response is not received
%   handleResponseFailure(OBJ) performs the operations required when
%   expected response is not received and updates corresponding tx context
%   and rate context. OBJ is an object of type edcaMAC.

    tx = obj.Tx;
    
    if (tx.LastTxFrameType == obj.QoSData)
        isSuccess = false(tx.TxMPDUCount(userIdx), 1);
    else % Recently transmitted frame is RTS/MURTSTrigger/MUBARTrigger/Management frame
        isSuccess = false;
    end
    
    % Update transmission status to the rate control algorithm
    updateTxStatus(obj, userIdx, isSuccess);
    
    notifyTxStatusEvent(obj);
end

function handleMissingResponses(obj, isResponseReceived)
%handleMissingResponses Increment/reset retry counters based on responses
%received

    tx = obj.Tx;
    % Updating QSRC, CW, frame retry count is not applicable when STA responds
    % with HE-TB data.
    if ~(tx.LastTxFrameType == obj.QoSData && tx.TxFormat == obj.HE_TB)
        % Increment frame retry count of MSDUs that are not part of BA agreement,
        % if transmission of the MSDUs or associated RTS fails.
        % Reference: Section 10.23.2.12.1 of IEEE Std 802.11-2020
        % No MSDUs are dequeued when uplink OFDMA transmission is scheduled by AP
        % (i.e., ULOFDMAScheduled is set to true).
        if ~tx.TxAggregatedMPDU && ~obj.ULOFDMAScheduled && ~isResponseReceived(obj.UserIndexSU)
            % Get the queue object which contains packets whose frame retry count must
            % be incremented.
            queueObj = getQueueObj(obj, obj.Tx.TxStationIDs(obj.UserIndexSU), obj.Tx.TxACs(obj.UserIndexSU));
            incrementFrameRetryCount(queueObj, obj.Tx.TxStationIDs(obj.UserIndexSU), ...
                obj.Tx.TxACs(obj.UserIndexSU), obj.Tx.NumTxUsers, RetryBufferIndex=obj.Tx.RetryBufferIndices(obj.UserIndexSU), ...
                MPDUCount=obj.Tx.TxMPDUCount(obj.UserIndexSU));
        end
    
        if (any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger]) || (tx.LastTxFrameType == obj.QoSData && tx.TxFormat ~= obj.HE_MU)) && ... % Frames that do not solicit HE TB PPDU
                ~isResponseReceived(obj.UserIndexSU)
            % Increment QSRC and CW
            % Reference: Section 10.23.2.2 of IEEE Std 802.11ax-2021
            incrementQSRCAndCW(obj);
        end
    
        if ((tx.LastTxFrameType == obj.QoSData) && (tx.TxFormat == obj.HE_MU)) || (tx.LastTxFrameType == obj.MUBARTrigger) % Frames that solicit HE TB PPDU
            % Reference: Section 10.23.2.2 of IEEE Std 802.11ax-2021
            if any(isResponseReceived(1:obj.Tx.NumTxUsers)) % At least one response is received
                % Reset QSRC and CW
                resetQSRCAndCW(obj);
            else % No response is received
                % Increment QSRC and CW
                incrementQSRCAndCW(obj);
            end
        end
    end
    
    % If there are any stations from which response frame is not received,
    % handle them
    for userIdx = 1:obj.Tx.NumTxUsers
        if ~isResponseReceived(userIdx)
            handleResponseFailure(obj, userIdx);
        end
    end
end

function [nextState, isFail, updatedIsResponseReceived] = processResponse(obj, frameFromPHY, frameIdx, frameMetadata, isResponseReceived)
%processResponse Decodes and processes the response frame.
%   [MACSTATE, ISFAIL, UPDATEDISRESPONSERECEIVED] = processResponse(OBJ,
%   FRAMEFROMPHY, FRAMEIDX, ISRESPONSERECEIVED) decodes and processes
%   response frame and updates corresponding context specific to receiving
%   state, MAC context and rate context.
%
%   MACSTATE is the current MAC state. The current MAC state might be a
%   value other than edcaMAC.RECEIVERESPONSE_STATE due to transition while
%   processing frame from PHY.
%
%   ISFAIL returns 1 to indicate transmission failure, 0 to indicate
%   transmission success, and -1 to indicate no status. A vector indicates
%   the status for multiple subframes in an A-MPDU.
%
%   UPDATEDISRESPONSERECEIVED is the updated value of input
%   ISRESPONSERECEIVED, after processing the current frame.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMEFROMPHY is the received response frame.
%
%   FRAMEIDX is the index of frame in multi-user reception. In case of
%   single user, it has a value of 1.
%
%   ISRESPONSERECEIVED is a logical array. Each element represents whether
%   response is received from corresponding station in TxStationIDs.

    rx = obj.Rx; % obj.Rx is a handle object
    tx = obj.Tx; % obj.Tx is a handle object
    nextState = obj.RECEIVERESPONSE_STATE;
    isFail = 1;
    isIntendedFrame = false;
    
    % In the process response module, we expect:
    %   * Non-aggregated response frames - CTS, Ack, Block-Ack and Multi-STA BA
    %   * Aggregated response frames - HE TB BAs
    % In this module, we will not receive HE-TB data frames as the unintended
    % HE-TB frames are filtered at PHY. Hence, process the aggregated frames
    % other than HE-TB.
    if rx.RxVector.AggregatedMPDU && rx.RxVector.PPDUFormat ~= obj.HE_TB
        % Consider this as the responses from all intended stations are missing
        isResponseReceived(1:tx.NumTxUsers) = false;
        % Transmission is considered as failed for all intended stations
        obj.Tx.LastTxFail(1:tx.NumTxUsers) = true;
        updatedIsResponseReceived = isResponseReceived;
    
        frameIdx = 1;
        rx.ResponseFrame = processRxFrame(obj, frameFromPHY, frameIdx, frameMetadata);
        if isempty(rx.ResponseFrame)
            % Move to RECEIVE_STATE either to wait for further indication from PHY
            nextState = obj.RECEIVE_STATE;
        else % Received a frame that solicits response
            nextState = obj.TRANSMITRESPONSE_STATE;
        end
    
        if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
            nextState = updateNextStateEMLSR(obj, nextState);
        end
        return;
    end
    
    % Decode the received MPDU
    rxMPDU = obj.MPDUTemplate;
    if obj.FrameAbstraction
        fcsPass = frameFromPHY.MACFrame.MPDU.FCSPass;
        if fcsPass
            rxMPDU = frameFromPHY.MACFrame.MPDU;
        end
        decodeStatus = ~fcsPass*-2; % Conversion from logical to double
    else % full MAC frame
        mpduBits = frameFromPHY.MACFrame(obj.UserIndexSU).Data;
        [rxMPDU, decodeStatus] = decodeMACFrameBits(obj, mpduBits, rx.RxVector.PPDUFormat);
        frameFromPHY.MACFrame.MPDU = rxMPDU;
    end

    % Find the index at which sender of the current frame is present in
    % TxStationIDs. As some control response frames does not have Transmitter
    % Address (TA), using the value in 'StationID' field in vector.
    if ~obj.IsMeshDevice && ((rx.RxVector.PPDUFormat == obj.HE_MU) || (rx.RxVector.PPDUFormat == obj.EHT_SU))
        % STAID in RxVector carries AID for an uplink HE-MU/EHT-MU frame
        staNodeID = getStationID(obj.SharedMAC, rx.RxVector.PerUserInfo(frameIdx).StationID);
        staIdx = find(staNodeID == obj.Tx.TxStationIDs, 1);
    else
        % STAID in RxVector is unused in other cases. It carries
        % transmitter node ID in the simulation (custom-implementation).
        staIdx = find(rx.RxVector.PerUserInfo(frameIdx).StationID == obj.Tx.TxStationIDs, 1);
    end
    if ~isempty(staIdx)
        % If staIdx is empty, it means an unintended frame and either NAV will
        % be set or MAC moves to Rx state to process the frame.
    
        acIdx = tx.TxACs(staIdx);
        queueObj = getQueueObj(obj, tx.TxStationIDs(staIdx), tx.TxACs(staIdx));
    end
    
    if (decodeStatus==0) % Decoding Successful
        % Update MAC Rx success
        obj.Statistics.ReceivedFCSValidFrames = obj.Statistics.ReceivedFCSValidFrames + 1;
    
        % Convert extracted TID from Block Ack frame to AC
        if strcmp(rxMPDU.Header.FrameType, 'Block Ack')
            acIdx = wlan.internal.Constants.TID2AC(rxMPDU.FrameBody.TID+1) + 1; % Add 1 for indexing
        end
    
        % If a frame with an MPDU is received, reset the MSD timer of EMLSR STA.
        % Reference: Section 35.3.16.8.2 of IEEE P802.11be/D5.0
        if obj.IsEMLSRSTA
            resetMSDTimer(obj);
        end
    
        % Frame is intended to this node
        if strcmp(rxMPDU.Header.Address1, obj.MACAddress)
            isIntendedFrame = true;
            % If two signals are received at same time at full PHY receiver, in
            % some scenarios, signal of interest (SOI) might be one signal (s1)
            % but extracted PHY payload might be of other signal (s2). 'staIdx'
            % is determined from metadata of SOI (s1). But, s1 might not be the
            % intended response and therefore 'staIdx' is empty. And s2 might
            % be intended response. Hence, overwrite 'staIdx', if s2 is
            % intended to us.
            if isempty(staIdx)
                % The above scenario can occur only when waiting for response
                % from single-user. Because multi-user is not yet supported in
                % full PHY. Hence, set to 'UserIndexSU'.
                staIdx = obj.UserIndexSU;
                acIdx = tx.TxACs(staIdx);
                queueObj = getQueueObj(obj, tx.TxStationIDs(staIdx), acIdx);
            end
    
            % If received frame is CTS and node sent RTS
            if strcmp(rxMPDU.Header.FrameType, 'CTS') && any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger])

                % Update MAC response frame reception counter
                obj.Statistics.ReceivedCTSFrames = obj.Statistics.ReceivedCTSFrames + 1;
                if tx.LastTxFrameType == obj.RTS
                    obj.SuccessfulRTSTransmissions = obj.SuccessfulRTSTransmissions + 1;
                else
                    obj.SuccessfulMURTSTransmissions = obj.SuccessfulMURTSTransmissions + 1;
                end

                discardPacketsDueToBWMismatch = false; % If CTS response is received, packets are not discarded by default
                if obj.ULOFDMAScheduled
                    % The node must send a basic TF after a successful MU-RTS/CTS exchange, if
                    % UL OFDMA is scheduled. Set the corresponding flag.
                    tx.NextTxFrameType = obj.BasicTrigger;
                else
                    % Set next frame type
                    isDataFrame = wlan.internal.utils.isDataFrame(tx.TxFrame(obj.UserIndexSU).MPDUs(1));
                    if isDataFrame
                        tx.NextTxFrameType = obj.QoSData;
                    else
                        tx.NextTxFrameType = obj.Management;
                    end
                    if (tx.LastTxFrameType == obj.RTS) % CTS response to RTS
                        % NonHTChannelBandwidth parameter in RxVector of CTS is valid only when BW
                        % signaling information is sent in RTS
                        if tx.BWSignaledInRTS && rx.RxVector.NonHTChannelBandwidth ~= 0
                            if ~obj.DynamicBandwidthOperation && ... % Only static operation is supported
                                    (tx.LastRTSBandwidth ~= rx.RxVector.NonHTChannelBandwidth)
                                tx.NextTxFrameType = obj.UnknownFrameType;
                                % Consider RTS transmission failure and terminate TXOP after CCA indication
                                % indicates idle primary 20 MHz
                                tx.LastTxFail(1:tx.NumTxUsers) = true;
                                % As data is not sent after RTS/CTS exchange, discard must be called to
                                % reset RetryBufferTxInProgress in QueueManager. However, transmission
                                % status to rate control algorithm must indicate transmission successful.
                                discardPacketsDueToBWMismatch = true;
                            end
                        end
                    end
                end

                % Return the transmission status
                isFail = 0;
    
                for idx = 1:tx.NumTxUsers
                    % Update transmission status to the rate control algorithm
                    updateTxStatus(obj, idx, ~isFail, discardPacketsDueToBWMismatch);
    
                    % Trigger 'TransmissionStatus' event
                    notifyTxStatusEvent(obj);
                end
    
                % If at least one CTS is received, consider the RTS/MU-RTS
                % transmission is successful.
                isResponseReceived(1:tx.NumTxUsers) = true;
    
                % Received frame is Ack
            elseif strcmp(rxMPDU.Header.FrameType, 'ACK')
    
                % Update MAC response frame reception counter
                obj.Statistics.ReceivedAckFrames = obj.Statistics.ReceivedAckFrames + 1;
                staIdxLogical = ([obj.PerACPerSTAStatistics.AssociatedNodeID] == tx.TxStationIDs(staIdx));
    
                if tx.ExpectedAckType == obj.ACK %  Expected response is Ack frame
                    if wlan.internal.utils.isDataFrame(tx.LastTxFrameType)
                        ackedMSDULengths = getMSDULengthsInRetryBuffer(queueObj, tx.TxStationIDs(staIdx), acIdx, tx.RetryBufferIndices(staIdx));
                        % Update MAC data tx counters
                        obj.TransmittedMSDUBytesPerAC(acIdx) = obj.TransmittedMSDUBytesPerAC(acIdx) + ackedMSDULengths(1);
                        obj.PerACPerSTAStatistics(staIdxLogical).TransmittedMSDUBytesPerAC(acIdx) = obj.PerACPerSTAStatistics(staIdxLogical).TransmittedMSDUBytesPerAC(acIdx) + ackedMSDULengths(1);
                        obj.SuccessfulDataTransmissionsPerAC(acIdx) = obj.SuccessfulDataTransmissionsPerAC(acIdx) + 1;
                    elseif wlan.internal.utils.isManagementFrame(tx.LastTxFrameType)
                        obj.SuccessfulManagementTransmissions = obj.SuccessfulManagementTransmissions + 1; % Assume no aggregation for management frames
                    end
    
                    % Discard the pending unacknowledged MSDU.
                    discardIndices = 1;
    
                    % Return the transmission status
                    isFail = 0;
    
                    % Update transmission status to the rate control algorithm
                    discardPacketsDueToBWMismatch = false;
                    updateTxStatus(obj, staIdx, ~isFail, discardPacketsDueToBWMismatch, discardIndices);
    
                    % Trigger 'TransmissionStatus' event
                    notifyTxStatusEvent(obj);
    
                    % Reset QSRC and CW
                    % Reference: Section 10.23.2.2 of IEEE Std 802.11ax-2021
                    resetQSRCAndCW(obj);
    
                    % Ack frame is received while waiting for response from single
                    % user. If Ack frame is received, consider the SU data frame
                    % transmission as successful.
                    isResponseReceived(1:tx.NumTxUsers) = true;
    
                    % If there's no RTS/CTS exchange in TXOP and there's at least one non-HT
                    % duplicate frame exchange, capture the bandwidth of initial frame in first
                    % non-HT duplicate frame exchange.
                    if ~tx.LastRTSBandwidth && ... % No RTS/CTS exchange in TXOP
                            ~tx.FirstNonHTDupBandwidth && ... % No previous NonHT Dup bandwidth saved in TXOP
                            rx.RxVector.ChannelBandwidth > 20 % Non-HT Dup frame exchange present
                        % If there's no RTS/CTS, initial frame in non-HT dup frame exchange is data
                        % frame. As Ack frame is received in same BW as data frame, saving ack
                        % frame bandwidth as the bandwidth of initial frame.
                        tx.FirstNonHTDupBandwidth = rx.RxVector.ChannelBandwidth;
                    end

                else % Expected response is not Ack frame
                    isResponseReceived(staIdx) = false;
                    % Transmission is considered as failed
                    obj.Tx.LastTxFail(staIdx) = true;
                end
    
                % Received frame is Block Ack
            elseif strcmp(rxMPDU.Header.FrameType, 'Block Ack')
    
                % Increment statistics
                obj.Statistics.ReceivedBlockAckFrames = obj.Statistics.ReceivedBlockAckFrames + 1;
    
                if  tx.ExpectedAckType == obj.BlockAck % Expected response is Block Ack frame
                    if rx.RxVector.PPDUFormat ~= obj.HE_TB % BA frame received in response to SU transmission
                        % Reset QSRC and CW
                        % Reference: Section 10.23.2.2 of IEEE Std 802.11ax-2021
                        resetQSRCAndCW(obj);
                    end
    
                    isFail = processBlockAck(obj, rxMPDU.FrameBody.BlockAckBitmap, rxMPDU.FrameBody.SequenceNumber, staIdx, acIdx);
    
                    % Set the element corresponding to station from which Block Ack
                    % frame is received.
                    isResponseReceived(staIdx) = true;
    
                    % If there's no RTS/CTS exchange in TXOP and there's at least one non-HT
                    % duplicate frame exchange, capture the bandwidth of initial frame in first
                    % non-HT duplicate frame exchange.
                    if ~tx.LastRTSBandwidth && ... % No RTS/CTS exchange in TXOP
                            ~tx.FirstNonHTDupBandwidth && ...  % No previous NonHT Dup bandwidth saved in TXOP
                            (rx.RxVector.PPDUFormat == obj.NonHT && rx.RxVector.ChannelBandwidth > 20)% Non-HT Dup frame exchange present     
                        % If there's no RTS/CTS, initial frame in non-HT dup frame exchange is data
                        % frame. As BA frame is received in same BW as data frame, saving ack frame
                        % bandwidth as the bandwidth of initial frame.
                        tx.FirstNonHTDupBandwidth = rx.RxVector.ChannelBandwidth;
                    end
    
                else % Expected response is not Block Ack frame
                    isResponseReceived(staIdx) = false;
                    % Transmission is considered as failed
                    obj.Tx.LastTxFail(staIdx) = true;
                end

            else % Received frame is not a response frame
                % Consider this as the responses from all intended stations are
                % missing
                isResponseReceived(1:tx.NumTxUsers) = false;
                % Transmission is considered as failed for all intended stations
                obj.Tx.LastTxFail(1:tx.NumTxUsers) = true;
                updatedIsResponseReceived = isResponseReceived;
    
                frameIdx = 1;
                rx.ResponseFrame = processRxFrame(obj, frameFromPHY, frameIdx, frameMetadata);
                if isempty(rx.ResponseFrame)
                    % Move to RECEIVE_STATE either to wait for further indication from PHY
                    nextState = obj.RECEIVE_STATE;
                else % Received a frame that solicits response
                    nextState = obj.TRANSMITRESPONSE_STATE;
                end
    
                if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
                    nextState = updateNextStateEMLSR(obj, nextState);
                end
                return;
            end
    
        elseif strcmp(rxMPDU.Header.Address1, 'FFFFFFFFFFFF') && strcmp(rxMPDU.Header.FrameType, 'Multi-STA-BA') && ...
                obj.IsAssociatedSTA && any(obj.AID == [rxMPDU.FrameBody.UserInfo(:).AID]) && strcmp(rxMPDU.Header.Address2, obj.BSSID)
            % Multi-STA BA frame is broadcasted. Process the frame at STA if it is sent
            % by associated AP and has BA information addressed to this STA.
    
            isIntendedFrame = true;
    
            % Update statistics
            obj.Statistics.ReceivedBlockAckFrames = obj.Statistics.ReceivedBlockAckFrames + 1;
    
            % Find the index of per AID TID info field corresponding to this
            % station
            nodeIdx = (obj.AID == [rxMPDU.FrameBody.UserInfo(:).AID]);

            acIndex = wlan.internal.Constants.TID2AC(rxMPDU.FrameBody.UserInfo(nodeIdx).TID+1) + 1; % Add 1 for indexing
            bitmap = rxMPDU.FrameBody.UserInfo(nodeIdx).BlockAckBitmap;
            ssn = rxMPDU.FrameBody.UserInfo(nodeIdx).SequenceNumber;

            staIdx = obj.UserIndexSU; % station transmits to only AP, hence use UserIndexSU
            isFail = processBlockAck(obj, bitmap, ssn, staIdx, acIndex);
            isResponseReceived(1:tx.NumTxUsers) = true;

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
    
        else % Received frame is destined to others
            % Consider this as the responses from all intended stations are missing
            isResponseReceived(1:tx.NumTxUsers) = false;
            % Transmission is considered as failed for all intended stations
            obj.Tx.LastTxFail(1:tx.NumTxUsers) = true;
    
            % Set network allocation vector(NAV)
            setNAV(obj, rx, rxMPDU);
            isNAVExpired = checkNAVTimerAndResetContext(obj, obj.LastRunTimeNS);
            if ~isNAVExpired
                % Move to NAV wait state
                nextState = obj.NAVWAIT_STATE;
    
                if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
                    nextState = updateNextStateEMLSR(obj, nextState);
                end
            else
                % Store context to decide if TXOP can be continued
                tx.LastTxFail = true;
            end
        end
    
    else % Failed to decode the received frame
        % Update response error counters
        obj.ResponseFrameFCSFailures = obj.ResponseFrameFCSFailures + 1;
        obj.Statistics.ReceivedFCSFails = obj.Statistics.ReceivedFCSFails + 1;
        % Set a flag to indicate transition to ERRORRECOVERY_STATE, when there is no energy
        % in the channel
        if any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger]) % Sent an RTS/MU-RTS frame
            % When MU-RTS is sent, one CTS frame is sent to MAC though more than one
            % CTS frames are received at PHY. And if FCS fails for response frame,
            % consider it as failure of frames received from all scheduled users. In
            % case of RTS, the NumTxUsers and hence number of received frames is equal
            % to 1.
            rx.RxErrorMACFailure(1:tx.NumTxUsers) = true;
        else % Sent frames other than RTS/MU-RTS
            % Response is expected from each scheduled user. Hence, set the flag
            % corresponding to received frame indicating it is error-ed.
            rx.RxErrorMACFailure(frameIdx) = true;
        end
    
        % Store FES failure context for each user
        if ~isempty(staIdx)
            obj.Tx.LastTxFail(staIdx) = true;
        else
            % If staIdx is empty, it means an unintended frame and either NAV will
            % be set or MAC moves to Rx state to process the frame. Transmission
            % is considered failed for all users
            obj.Tx.LastTxFail(1:tx.NumTxUsers) = true;
        end
    end
    
    updatedIsResponseReceived = isResponseReceived;
    
    if obj.HasListener.MPDUDecoded || ~isempty(obj.ReceptionEndedFcn)
        if ~obj.FrameAbstraction
            mpduBits = frameFromPHY.MACFrame(obj.UserIndexSU).Data;
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
    end
    
    % Trigger 'MPDUDecoded'. Note that MPDUDecoded event will be removed in a
    % future release. Use the ReceptionEnded event instead. Register for the
    % ReceptionEnded notification by using the 'registerEventCallback' function
    % of wlanNode.
    if obj.HasListener.MPDUDecoded
        mpduDecoded = obj.MPDUDecoded;
        if ~obj.FrameAbstraction
            mpduDecoded.MPDU = {macFrame};
        else
            mpduDecoded.MPDU = frameFromPHY.MACFrame(obj.UserIndexSU).MPDU;
        end
        mpduDecoded.FCSFail = (decodeStatus~=0); % Any failure type is notified as FCS failure in this event
        mpduDecoded.DeviceID = obj.DeviceID;
        mpduDecoded.PPDUStartTime = frameMetadata.StartTime; % In seconds
        mpduDecoded.Frequency = frameMetadata.CenterFrequency; % In Hz
        mpduDecoded.Bandwidth = rx.RxVector.ChannelBandwidth*1e6; % In Hz
        if obj.IncludeVector
            mpduDecoded.RxVector = rx.RxVector;
            % Give only per user fields corresponding to the user from which frame
            % is decoded
            mpduDecoded.RxVector.PerUserInfo = rx.RxVector.PerUserInfo(frameIdx);
        end
    
        obj.EventNotificationFcn('MPDUDecoded', mpduDecoded);
    end
    
    % Fill information necessary to trigger ReceptionEnded event
    if ~isempty(obj.ReceptionEndedFcn)
        receptionEnded = obj.ReceptionEnded;
        if rx.RxVector.PPDUFormat ~= obj.HE_TB % Non-TB formats
            receptionEnded.PDUDecodeStatus = decodeStatus; % Integer vector
            if ~obj.FrameAbstraction
                receptionEnded.PDU = {macFrame}; % Cell array with vector of decimal octet elements
            end
            receptionEnded.IsIntendedReception = isIntendedFrame;
        else % HE-TB format
            receptionEnded.PDUDecodeStatus{end+1} = decodeStatus; % Cell array with integer vector elements
            if ~obj.FrameAbstraction % Not supported currently
                receptionEnded.PDU{end+1} = {macFrame}; % Cell array with each element as cell array with vector of decimal octet elements
            end
            receptionEnded.IsIntendedReception(end+1) = isIntendedFrame;
        end
        obj.ReceptionEnded = receptionEnded;
    end
end

function updateTxStatus(obj, userIdx, isSuccess, discardPacketsDueToBWMismatch, discardIndices)
%updateTxStatus Update transmission status to the rate control algorithm
%   updateTxStatus(OBJ, USERIDX, ISSUCCESS) discards packets from queues
%   and updates the transmission status to the configured rate control
%   algorithm. In case of RTS/MU-RTS, packets are checked for discard only
%   if transmission fails.
%
%   USERIDX is the index of user in multi-user transmission. In case of
%   single user transmission, it has a value of 1.
%
%   ISSUCCESS is a flag indicating whether the transmission is success.
%
%   updateTxStatus(OBJ, USERIDX, ISSUCCESS, DISCARDPACKETSDUETOBWMISMATCH)
%   discards packets at given indices from queues irrespective of
%   transmission status and updates the transmission status to the
%   configured rate control algorithm. This signature is used only for RTS
%   frame.
%
%   DISCARDPACKETSDUETOBWMISMATCH is a logical scalar indicating to check
%   whether packets can be discarded. This is currently specified as true
%   when CTS is received in a bandwidth not equal to RTS.
%
%   updateTxStatus(OBJ, USERIDX, ISSUCCESS, false, DISCARDINDICES) discards
%   packets at given indices from queues and updates the transmission
%   status to the configured rate control algorithm.
%
%   DISCARDINDICES is the index of successful packets in the queues, which
%   must be discarded along with any other packets due to retry limit
%   exhaust or lifetime expiry.
    
    tx = obj.Tx; % Handle object
    rx = obj.Rx; % Handle object
    
    % Update transmission status to rate control algorithm
    acIdx = tx.TxACs(userIdx);
    numMPDUs = numel(isSuccess);
    discardPackets = false;
    isDiscarded = false;
    timeInQueue = 0;
    [queueObj, isSharedQ] = getQueueObj(obj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
    if nargin <= 4
        discardIndices = [];
        if nargin == 3
            discardPacketsDueToBWMismatch = false;
        end
    end
    
    if any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger]) % RTS/MU-RTS transmission status
        ac = acIdx - 1;
        if tx.LastTxFrameType == obj.RTS
            frameType = "RTS";
        else
            frameType = "MU-RTS";
        end

        if (~isSuccess && ~obj.ULOFDMAScheduled) || ... % RTS failure for data transmission from the device
                discardPacketsDueToBWMismatch
            % Discard any packets due to lifetime expiry
            discardPackets = true;
        end
    
    elseif wlan.internal.utils.isManagementFrame(tx.LastTxFrameType)
        frame = tx.TxFrame(userIdx);
        frameType = frame.MPDUs(1).Header.FrameType;
        ac = repmat(acIdx - 1, numMPDUs, 1);
    
        % Discard due to life time expiry/retry counter exhaust/tx success
        discardPackets = true;
        if ~any(isSuccess) % No subframes are successful
            discardIndices = [];
        end
    
    else % QoS Data transmission status (tx.LastTxFrameType == obj.QoSData || tx.LastTxFrameType == obj.MUBARTrigger)
        frameType = "QoS Data";
        ac = repmat(acIdx - 1, numMPDUs, 1);

        % Discard due to life time expiry/retry counter exhaust/tx success
        discardPackets = true;
        if ~any(isSuccess) % No subframes are successful
            discardIndices = [];
        end
    end

    % Discard packets and calculate time spent by packets in queue
    if discardPackets
        [~, ~, ~, isDiscarded] = discard(obj, isSharedQ, queueObj, tx.TxStationIDs(userIdx), acIdx, tx.RetryBufferIndices(userIdx), discardIndices);
        if any(isDiscarded)
            frame = tx.TxFrame(userIdx);
            numPackets = numel(frame.MPDUs);
            isDiscarded = isDiscarded(1:numPackets); % Discard status of MSDUs in current tx
            timeInQueue = zeros(numPackets, 1);
            for idx = numPackets:-1:1
                macEntryTimes(idx) = frame.MPDUs(idx).Metadata.MACEntryTime;
            end
            timeInQueue(isDiscarded) = round(round(obj.LastRunTimeNS/1e9, 9) - macEntryTimes(isDiscarded), 9);
        end
    end

    % Update transmission status (for event)
    txStatus = obj.TransmissionStatus;
    txStatus.CurrentTime = round(obj.LastRunTimeNS/1e9, 9); % In seconds
    txStatus.DeviceID = obj.DeviceID;
    txStatus.FrameType = frameType;
    txStatus.ReceiverNodeID = tx.TxStationIDs(userIdx);
    txStatus.MPDUSuccess = isSuccess;
    txStatus.MPDUDiscarded = isDiscarded;
    txStatus.TimeInQueue = timeInQueue;
    txStatus.AccessCategory = ac;
    txStatus.ResponseRSSI = rx.RxVector.RSSI;
    obj.TransmissionStatus = txStatus;
    
    % Update transmission status for RTS, MU-RTS and QoS Data frames
    rateControlTxStatus = obj.RateControlTxStatusTemplate;
    rateControlTxStatus.IsMPDUSuccess = isSuccess;
    rateControlTxStatus.IsMPDUDiscarded = isDiscarded;
    rateControlTxStatus.CurrentTime = txStatus.CurrentTime;
    rateControlTxStatus.ResponseRSSI = txStatus.ResponseRSSI;
    
    if any(tx.LastTxFrameType == [obj.RTS obj.MURTSTrigger]) % RTS/MU-RTS frame transmission status
	    if ~isempty(obj.ControlFrameRateControlTxContext)
    	    processTransmissionStatus(obj.RateControl, obj.ControlFrameRateControlTxContext, rateControlTxStatus);
		    obj.ControlFrameRateControlTxContext = []; % Reset context
	    end
    elseif tx.LastTxFrameType == obj.QoSData % Data frame transmission status
	    if ~isempty(obj.DataFrameRateControlTxContext)
    	    processTransmissionStatus(obj.RateControl, obj.DataFrameRateControlTxContext, rateControlTxStatus);
		    obj.DataFrameRateControlTxContext = []; % Reset context
	    end
    elseif tx.LastTxFrameType == obj.MUBARTrigger  % MU-BAR frame transmission status
	    if ~isempty(obj.ControlFrameRateControlTxContext)
    	    % Update transmissions status for MU-BAR frame to rate control
    	    rateControlTxStatus.IsMPDUDiscarded = false;
    	    processTransmissionStatus(obj.RateControl, obj.ControlFrameRateControlTxContext, rateControlTxStatus);
		    obj.ControlFrameRateControlTxContext = []; % Reset context
	    end
    elseif wlan.internal.utils.isManagementFrame(tx.LastTxFrameType)
        % No action. No rate control for management frames for now
    end
end

function nextState = updateNextStateEMLSR(obj, nextState)
% Determine the next state for EMLSR STA

    % TXOP is continued in these cases:
    %   1. Next state is SENDINGDATA_STATE or WAITFORRESPONSE_STATE
    %   2. PIFS recovery has to be started
    % If TXOP is not continued, go to INACTIVE_STATE to handle EMLSR Transition Delay.
    continueTXOP = any(nextState == [obj.TRANSMIT_STATE obj.RECEIVERESPONSE_STATE]) || (nextState == obj.ERRORRECOVERY_STATE && obj.Tx.DoPIFSRecovery);
    if ~continueTXOP
        nextState = obj.INACTIVE_STATE;
    end
end

function seqNums = extractSeqNumsFromBitmap(baBitmap, ssn)
%extractSeqNumsFromBitmap Returns acknowledged sequence numbers using bitmap
%and starting sequence number.

    % Convert hexadecimal bitmap to binary bitmap
    bitmapDec = hex2dec((reshape(baBitmap, 2, [])'));
    bitmapDec(1:end) = bitmapDec(end:-1:1);
    bitmapDecSize = numel(bitmapDec);
    bitmapBits = zeros(8*bitmapDecSize,1);
    idx = 1;
    for i = 1:bitmapDecSize
        bitmapBits(idx:8*i) = bitget(bitmapDec(i), 1:8)';
        idx = idx+8;
    end
    
    % Return the successfully acknowledged sequence numbers
    seqNums = rem(ssn+find(bitmapBits)-1, 4096);
end

function notifyTxStatusEvent(obj)
%notifyTxStatusEvent Trigger 'TransmissionStatus' event
%   notifyTxStatusEvent(OBJ) triggers 'TransmissionStatus' event.
%
%   OBJ is an object of type edcaMAC.

    if obj.HasListener.TransmissionStatus
        obj.EventNotificationFcn('TransmissionStatus', obj.TransmissionStatus);
    end
end

function frameToPHY = prepareMultiSTABA(obj, numSTAsToBeAcked)
%prepareMultiSTABA Prepare and return the Multi-STA Block Ack frame

    rx = obj.Rx; % Handle object
    
    % Calculate duration field
    multiSTABALength = controlFrameMPDULength(obj, 'Multi-STA-BA', [], numSTAsToBeAcked, false);
    cbw = 20;
    numSTS = 1;
    rx.ResponseTxTime = calculateTxTime(obj, obj.NonHT, multiSTABALength, obj.MultiSTABARate, numSTS, cbw); % Time required to transmit Multi-STA BA
    durationField = round(rx.HETBDurationField*1e3) - obj.SIFSTime - rx.ResponseTxTime;
    % Convert duration field to microseconds and round off to nanoseconds granularity
    durationField = max(round(durationField*1e-3, 3), 0); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020

    % Prepare context to fill MPDU frame body fields
    staIndices = find(rx.ResponseStationID > 0); % Indices corresponding to above STAs
    stasToBeAcked = rx.ResponseStationID(staIndices); % STA IDs to be acked
    staContextIndicesToBeAcked = rx.MultiSTABAContextSTAIndices(staIndices); % Corresponding BA context indices
    tidsToBeAcked = rx.MultiSTABAContextTIDs(staIndices); % Corresponding TIDs

    frameToPHY = generateMultiSTABA(obj, durationField, numSTAsToBeAcked, stasToBeAcked, staContextIndicesToBeAcked, tidsToBeAcked, multiSTABALength);

    % Update context
    rx.ResponseLength = multiSTABALength;
    rx.ResponseMCS = obj.MultiSTABARate;
    rx.ResponseNumSTS = 1;
end

function frameToPHY = generateMultiSTABA(obj, durationField, numSTAsToBeAcked, stasToBeAcked, staContextIndicesToBeAcked, tidsToBeAcked, multiSTABALength)
%generateMultiSTABA Generate Multi-STA BA frame

    rx = obj.Rx; % Handle object
    
    % Fill MPDU header fields
    mpdu = obj.MPDUMultiSTABlockAckTemplate;
    mpdu.Header.Duration = durationField;
    mpdu.Header.Address1 = 'FFFFFFFFFFFF';
    mpdu.Header.Address2 = obj.MACAddress;

    % Fill MPDU frame body fields
    for staIdx = 1:numSTAsToBeAcked
        % Get the bitmap corresponding to the STA
        staContextIndex = staContextIndicesToBeAcked(staIdx);
        acIndex = wlan.internal.Constants.TID2AC(tidsToBeAcked(staIdx)+1) + 1; % AC starts at 0. Add 1 for indexing.
        tempBitmap = rx.BlockAckBitmap(staContextIndex, acIndex, 1:obj.BABitmapLength);

        % Convert the BA bitmap to hexadecimal format
        bitMapLen = numel(tempBitmap)/8;
        baBitmapDec = zeros(bitMapLen,1);
        idx = 1;
        for i = 1:bitMapLen
            baBitmapDec(i) = obj.binaryToDecimal(tempBitmap(idx:idx+7));
            idx = idx+8;
        end
        baBitmapDec = flip(baBitmapDec);

        % We currently assume that the A-MPDU in HE TB PPDU contains only untagged
        % MPDUs. Hence, supporting only 'Block ack context' in Multi-STA BlockAck
        % frame. The Ack Type field for 'Block ack context' is set to 0. Hence not
        % including Ack Type field in Multi-STA BA.
        % References: Section 26.4.4.5 and 26.4.2 of IEEE Std 802.11ax-2021
        mpdu.FrameBody.UserInfo(staIdx).AID = getAID(obj.SharedMAC, stasToBeAcked(staIdx));
        mpdu.FrameBody.UserInfo(staIdx).TID = tidsToBeAcked(staIdx);
        mpdu.FrameBody.UserInfo(staIdx).SequenceNumber = rx.LastSSN(staContextIndex, acIndex);
        mpdu.FrameBody.UserInfo(staIdx).BlockAckBitmap = reshape(dec2hex(baBitmapDec, 2)', 1, []);
    end

    % Fill MPDU metadata
    mpdu.Metadata.MPDULength = multiSTABALength;
    mpdu.Metadata.SubframeIndex = 1;
    mpdu.Metadata.SubframeLength = multiSTABALength;

    % Create frame structure to be passed to PHY
    frameToPHY = obj.MACFrameTemplate;
    frameToPHY.MACFrame.MPDU = mpdu;
    frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
    frameToPHY.MACFrame.PSDULength = multiSTABALength;

    % Update statistics
    obj.Statistics.TransmittedBlockAckFrames = obj.Statistics.TransmittedBlockAckFrames + 1;
end

function isFail = processBlockAck(obj, bitmap, ssn, staIdx, acIdx)
%processBlockAck Update the sequence number context based on acknowledged
%sequence numbers and starting sequence number

    tx = obj.Tx;
    staIdxLogical = ([obj.PerACPerSTAStatistics.AssociatedNodeID] == tx.TxStationIDs(staIdx));
    queueObj = getQueueObj(obj, tx.TxStationIDs(staIdx), acIdx);
    
    % Get sequence numbers of the frames that are acknowledged in BA bitmap
    baSeqNums = extractSeqNumsFromBitmap(bitmap, ssn);
    
    % Get sequence numbers of the AMPDU subframes transmitted
    txFrame = tx.TxFrame(staIdx);
    txMPDUCount = tx.TxMPDUCount(staIdx);
    txSeqNums = zeros(1,txMPDUCount);
    for idx = 1:txMPDUCount
        txSeqNums(idx) = [txFrame.MPDUs(idx).Header.SequenceNumber];
    end
    % Acknowledged sequence numbers
    ackedIndices = ismember(txSeqNums, baSeqNums);
    ackedSeqNums = txSeqNums(ackedIndices);
    % Sequence numbers that are not acknowledged in this BA
    seqNumsToBeAcked = txSeqNums(~ackedIndices);
    
    obj.SuccessfulDataTransmissionsPerAC(acIdx) = obj.SuccessfulDataTransmissionsPerAC(acIdx) + numel(ackedSeqNums);
    
    % Indices of acknowledged MSDUs in MAC retry buffer
    discardIndices = find(ackedIndices);
    msduLengths = getMSDULengthsInRetryBuffer(queueObj, tx.TxStationIDs(staIdx), acIdx, tx.RetryBufferIndices(staIdx));
    ackedMSDULengths = sum(msduLengths(discardIndices));
    
    % Update data tx bytes
    obj.TransmittedMSDUBytesPerAC(acIdx) = ...
        obj.TransmittedMSDUBytesPerAC(acIdx) + ackedMSDULengths;
    obj.PerACPerSTAStatistics(staIdxLogical).TransmittedMSDUBytesPerAC(acIdx) =...
        obj.PerACPerSTAStatistics(staIdxLogical).TransmittedMSDUBytesPerAC(acIdx) ...
        + ackedMSDULengths;
    
    blockAckReceivedForMUBAR = (tx.LastTxFrameType == obj.MUBARTrigger); % BA is in response to MU-BAR frame
    
    discardPacketsDueToBWMismatch = false;
    % All the subframes are acknowledged
    if(isempty(seqNumsToBeAcked))
        if blockAckReceivedForMUBAR % BA is in response to MU-BAR frame
            isSuccess = true;
        else % BA is in response to A-MPDU frame
            isSuccess = true(txMPDUCount, 1); % Transmission status of each subframe
        end
        updateTxStatus(obj, staIdx, isSuccess, discardPacketsDueToBWMismatch, discardIndices);
        notifyTxStatusEvent(obj);
    
        % Return the transmission status
        isFail = false;
    
    else % Some or all subframes of the A-MPDU are not acknowledged
        if blockAckReceivedForMUBAR % BA is in response to MU-BAR frame
            isSuccess = true;
        else % BA is in response to A-MPDU frame
            isSuccess = ackedIndices; % Transmission status of each subframe
        end
        % Update transmission status to the rate control algorithm
        updateTxStatus(obj, staIdx, isSuccess, discardPacketsDueToBWMismatch, discardIndices);
        % Trigger 'TxStatusEvent'
        notifyTxStatusEvent(obj);
    
        % Return the transmission status
        isFail = ~ackedIndices;
    end
end