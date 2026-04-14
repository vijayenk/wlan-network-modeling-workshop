function nextInvokeTime = handleEventsContend(obj, currentTime, phyIndication)
%handleEventsContend Handle the operations in CONTEND_STATE
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTINVOKETIME = handleEventsContend(OBJ, CURRENTTIME, ...
%   PHYINDICATION) performs actions in MAC layer CONTEND_STATE.
%
%   NEXTINVOKETIME is the simulation time in nanoseconds at which the run
%   function must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the current simulation time in nanoseconds.
%
%   PHYINDICATION is the CCAState indicated by the physical layer.

%   Copyright 2022-2025 The MathWorks, Inc.

nextInvokeTime = Inf;

if obj.IsEMLSRLinkMarkedInactive
    % Some other link is active EMLSR link and shared MAC has instructed this
    % link to move to INACTIVE_STATE
    stateChange(obj, obj.INACTIVE_STATE);
    return;
end

ccaBusy = false;
if phyIndication.MessageType == obj.CCAIndication
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
    if obj.CCAState(1) % Primary 20 is busy
        % Move to RECEIVE_STATE
        stateChange(obj, obj.RECEIVE_STATE);
        % In the RECEIVE_STATE, wait for further indication from the physical
        % layer receiver
        nextInvokeTime = obj.NextInvokeTime;
        ccaBusy = true;
    end
end   

% Wait for SIFS time before invoking backoff algorithm
if obj.BackoffInvokeTime > 0
    if obj.BackoffInvokeTime > currentTime
        % Update the nextInvokeTime as BackOffInvokeTime is not yet reached
        nextInvokeTime = obj.BackoffInvokeTime;
    end
end

if obj.BackoffInvokeTime <= currentTime
    % Invoke backoff algorithm if SIFS time has elapsed
    backoffAlgorithm(obj, currentTime, ccaBusy);
    nextInvokeTime = obj.NextInvokeTime;
end

if ccaBusy % Wait indefinitely for further indication from PHY
    nextInvokeTime = Inf;
end
end

function backoffAlgorithm(obj, currentTime, ccaBusy)
    %backoffAlgorithm Performs contention for each QoS access category (AC),
    %and beacon based on Enhanced Distributed Channel Access (EDCA).
    %
    %   backoffAlgorithm(OBJ, CURRENTTIME, CCABUSY) performs contention for
    %   each QoS access category, and beacon.
    %
    %   OBJ is an object of type edcaMAC.
    %
    %   CURRENTTIME is the current simulation time in nanoseconds.
    %
    %   CCABUSY is a flag indicating whether primary 20 MHz is busy.

    txopAC = -1; % Initialize txop AC

    if obj.BackoffInvokeTime > 0
        % Update the excess elapsed time after the backoff invoke timer
        elapsedTime = currentTime - obj.BackoffInvokeTime;
        obj.BackoffInvokeTime = 0;
    else
        elapsedTime = obj.ElapsedTime;
    end
    nextInvokeTimeAC = zeros(1, 4);
    elapsedTimeAC = repmat(elapsedTime, 1, 4);

    % For each access category
    for acIndex = [2 1 3 4]
        nextInvokeTimeAC(acIndex) = 0;

        if (obj.AIFSSlotCounter(acIndex) ~= 0)
            % Decrement AIFS counter
            if (obj.AIFSSlotCounter(acIndex) > elapsedTimeAC(acIndex))
                obj.AIFSSlotCounter(acIndex) = obj.AIFSSlotCounter(acIndex) - elapsedTimeAC(acIndex);
                nextInvokeTimeAC(acIndex) = obj.AIFSSlotCounter(acIndex);
                elapsedTimeAC(acIndex) = 0;
            else
                elapsedTimeAC(acIndex) = elapsedTimeAC(acIndex) - obj.AIFSSlotCounter(acIndex);
                obj.AIFSSlotCounter(acIndex) = 0;
            end

            if (obj.AIFSSlotCounter(acIndex) == 0) && (obj.BackoffCounter(acIndex) == 0)
                if (obj.IsLastTXOPHolder) || ~isQueueEmpty(obj, acIndex)
                    % Backoff must be invoked at last TXOP holder
                    % regardless of queue length. And backoff must be
                    % invoked if queue length is non-zero. Select a random
                    % backoff between 0 and cw. But in case of node which
                    % is not last TXOP holder and queue length is 0 after
                    % AIFS, backoff may or may not be invoked. Reference:
                    % Section 10.23.2.2 of IEEE Std 802.11-2020. Choosing
                    % not to invoke backoff because this case does not also
                    % fall under mandatory rules of DCF to invoke backoff
                    % when queue length is 0 in Section 10.3.4.3 of IEEE
                    % Std 802.11-2020.
                    obj.BackoffCounter(acIndex) = randi([0, obj.CW(acIndex)])*obj.SlotTime;
                end
            end
        end

        % AIFS slot counter is 0
        if (obj.AIFSSlotCounter(acIndex) == 0)
            if (obj.BackoffCounter(acIndex) ~= 0)
                if (obj.BackoffCounter(acIndex) > elapsedTimeAC(acIndex))
                    % Decrement backoff counter
                    elapsedTimeAC(acIndex) = elapsedTimeAC(acIndex) + obj.AccumulatedElapsedTime(acIndex);
                    slotUnits = floor(elapsedTimeAC(acIndex)/obj.SlotTime);
                    obj.BackoffCounter(acIndex) = obj.BackoffCounter(acIndex) - slotUnits*obj.SlotTime;
                    obj.AccumulatedElapsedTime(acIndex) = mod(elapsedTimeAC(acIndex), 9000);
                    nextInvokeTimeAC(acIndex) = obj.BackoffCounter(acIndex)-obj.AccumulatedElapsedTime(acIndex);
                else
                    obj.BackoffCounter(acIndex) = 0;
                end
            end

            if (obj.BackoffCounter(acIndex) == 0)
                % Discard any packets whose lifetime expired from both shared and link
                % queues
                isSharedQ = true;
                if ~isQueueEmpty(obj)
                    if obj.IsAffiliatedWithMLD
                        discard(obj, isSharedQ, obj.SharedEDCAQueues);
                    end
                    discard(obj, ~isSharedQ, obj.LinkEDCAQueues);
                end

                if obj.TBTTAcquired && ~ccaBusy
                    % Beacon needs to be transmitted in Voice AC, IEEE Std
                    % 802.11-2020, Section 10.2.3.2
                    if acIndex == 4             
                        txopAC = acIndex - 1; % Update the txop AC
                        obj.OwnerAC = txopAC; % Assign owner AC
                    else
                        continue; % Suspend pending transmissions till beacon is transmitted, IEEE Std 802.11-2020, Section 11.1.3.2, NOTE-1
                    end
                
                elseif ~ccaBusy && ~isQueueEmpty(obj, acIndex) % Data/management frames are queued for transmission
                    % High priority AC won the channel in the same time slot.
                    % i.e. an internal collision occurred
                    % Reference: Section 10.23.2.2 in IEEE Std 802.11-2020
                    if txopAC ~= -1 && ~isQueueEmpty(obj, txopAC+1)
                        % Report an internal collision when lower priority AC has data for
                        % transmission. Refer Section - 10.23.2.4 in IEEE Std 802.11-2020
                        handleInternalCollision(obj, txopAC);
                    end
                    % Update the txop AC
                    txopAC = acIndex - 1;
                    % Assign owner AC
                    obj.OwnerAC = txopAC;

                elseif obj.ULOFDMAEnabled && any(obj.STAQueueInfo(:, 3)) && ~ccaBusy
                    % Consider the AC has won contention even though the
                    % transmission queues are empty, when UL OFDMA is
                    % enabled and the AP has information that the queues at
                    % STA are not empty. Update the txop AC and assign
                    % owner AC.
                    txopAC = acIndex - 1;
                    obj.OwnerAC = txopAC;
                end
            end
        end
    end

    % Channel contention completed and no QoS AC has frames to transmit
    if (txopAC == -1) && ~ccaBusy && ~any([obj.AIFSSlotCounter obj.BackoffCounter])
        % Move to IDLE_STATE
        stateChange(obj, obj.IDLE_STATE);

    elseif (txopAC ~= -1) % One of the ACs got channel access
        stateChange(obj, obj.TRANSMIT_STATE);

        if obj.IsEMLSRSTA
            % Set the flag corresponding to this link indicating that the link is
            % active
            obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) = true;
            % Suspend transmit and receive capabilities on links other than the one on
            % which TXOP is initiated. Reference: Section 35.3.17 of IEEE P802.11be/D5.0
            turnOffOtherLinks(obj.SharedMAC, obj.DeviceID);
            % Switch to use aggregated antennas of all EMLSR links for reception.
            % NumTransmitAntennas holds the aggregated value.
            obj.NumReceiveAntennas = obj.NumTransmitAntennas;
            if ~isempty(obj.SetNumRxAntennasFcn)
                obj.SetNumRxAntennasFcn(obj.NumReceiveAntennas);
            end
        end

    elseif nnz(nextInvokeTimeAC) % Contention still in progress
        obj.NextInvokeTime = currentTime + min(nextInvokeTimeAC(nextInvokeTimeAC ~= 0));
    end
end

function handleInternalCollision(obj, lowPriorityAC)
    %handleInternalCollision Handles internal collision of a lower priority AC
    %with a higher priority AC

    % Increment QSRC and CW
    % Reference: Section 10.23.2.2 of IEEE Std 802.11ax-2021
    incrementQSRCAndCW(obj);

    % Allocate bandwidth available for the MSDUs that suffered internal
    % collision
    allocateBandwidthForTXOP(obj);
    % Run scheduler to get MSDUs that suffered internal collision
    scheduleStations = true;
    continueTXOP = false;
    scheduleAndCalculateTxInfo(obj, scheduleStations, continueTXOP);

    for userIdx = 1:numel(obj.Tx.NumTxUsers)
        % Check whether the scheduled AC is the lowest priority AC that
        % suffered internal collision
        if obj.Tx.TxACs(userIdx) == lowPriorityAC + 1
            queueObj = getQueueObj(obj, obj.Tx.TxStationIDs(userIdx),obj.Tx.TxACs(userIdx));

            numUsers = 1;
            % Increment frame retry counters of MSDUs which suffered internal
            % collision.
            % Reference: Section 10.23.2.12.1 of IEEE Std 802.11-2020
            incrementFrameRetryCount(queueObj, obj.Tx.TxStationIDs(userIdx), obj.Tx.TxACs(userIdx), ...
                numUsers, MPDUCount=obj.Tx.TxMPDUCount(userIdx));
        end
    end
    % Update internal collision statistics
    obj.InternalCollisionsPerAC(lowPriorityAC+1) = obj.InternalCollisionsPerAC(lowPriorityAC+1) + 1;
end
