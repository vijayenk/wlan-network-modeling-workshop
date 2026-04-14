function nextInvokeTime = handleEventsInactive(obj, currentTime, phyIndication)
%handleEventsInactive Handle the operations in INACTIVE_STATE
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTINVOKETIME = handleEventsInactive(OBJ, CURRENTTIME, PHYINDICATION)
%   performs actions in MAC layer INACTIVE_STATE. This state handles:
%       - An inactive EMLSR link. A link stays inactive for the duration of
%         frame exchange sequence followed by transition delay. It is indicated
%         by an active EMLSR link to move out of INACTIVE_STATE.
%       - An active EMLSR link waiting for transition delay
%
%   NEXTINVOKETIME is the time in nanoseconds at which the run function
%   must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is the CCAState indicated by the physical layer.

%   Copyright 2024-2025 The MathWorks, Inc.

nextInvokeTime = Inf;
nextState = obj.INACTIVE_STATE;
rx = obj.Rx;

%% Handle active timers

% NAV timers might be running in the background while MAC is in inactive
% state. Hence, check whether they should be reset as some further
% transitions in this state depend on NAV timers.
checkForNAVReset(obj, currentTime);

%% Control PHY Rx On/Off
if obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID)
    % Active EMLSR link waiting for transition delay

    if obj.NextInvokeTime <= currentTime % EMLSR transition delay elapsed
        if ~obj.PHYMode.PHYRxOn % PHY is not yet turned on
            % After transition delay after the end of frame exchange sequences, turn on
            % the other links to switch back to listening. Reference: Section 35.3.17
            % of IEEE P802.11be/D5.0
            turnOnOtherLinks(obj.SharedMAC, obj.DeviceID);
            % Turn on the PHY Rx of this link
            nextInvokeTime = turnOnPHYAndSetMSDTimer(obj, currentTime);
            return;
        end
    else
        nextInvokeTime = obj.NextInvokeTime;
        return;
    end
else % Inactive EMLSR link

    if obj.IsEMLSRLinkMarkedInactive % Turn off and stay inactive

        if obj.PHYMode.PHYRxOn % Turn off the PHY Rx if it is on
            % Capture entry timestamp when link turns inactive again
            obj.StateEntryTimestamp = currentTime;
            % Turn off the PHY receiver
            switchOffPHYRx(obj);
            % Capture the timestamp at which link is switching off CCA by turning off
            % phy receiver
            obj.LinkTurnOffTimestamp = currentTime;
        end

        % Stay in INACTIVE_STATE if the other EMLSR link is still active
        return;

        % If the link is no longer inactive, check if PHY receiver is on
    elseif ~obj.PHYMode.PHYRxOn
        % Turn on the PHY Rx of this link
        nextInvokeTime = turnOnPHYAndSetMSDTimer(obj, currentTime);
        return;
    end
end

%% Handle PHY indications
if phyIndication.MessageType == obj.CCAIndication
    nextState = handleCCA(obj, currentTime, phyIndication);
end

% Switch to next state
if nextState ~= obj.INACTIVE_STATE
    nextInvokeTime = moveToNextState(obj, nextState);
    return;
end

%% Handle wait times
% Transition to next state after processing indications if any
nextState = checkRemainingWaitTime(obj, currentTime);

% Switch to next state
if nextState ~= obj.INACTIVE_STATE
    nextInvokeTime = moveToNextState(obj, nextState);
    return;
end
end

%% Supporting functions

function nextState = handleCCA(obj, currentTime, phyIndication)
%handleCCA

    rx = obj.Rx;
    nextState = obj.INACTIVE_STATE;
    prevPrimaryStatus = obj.CCAState(1);
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);

    if prevPrimaryStatus && ~obj.CCAState(1) % Primary 20 became idle
        % If CCA is busy when the link moved to INACTIVE_STATE, check whether any
        % RxError indication or errored frame is received in previous state.
        if rx.RxErrorPHYFailure || any(rx.RxErrorMACFailure)
            % If Rx-Error indication or errored frame is received, start EIFS recovery
            % timer after receiving CCA-Idle. Reference: Section 10.3.2.3.7 of IEEE Std
            % 802.11ax-2021
            % EIFS time = SIFS time + Ack duration. Ack duration is same as CTS
            % duration for MCS (0), NSTS (1), CBW (20).
            obj.EIFSTimer = currentTime + obj.SIFSTime + obj.AckOrCTSBasicRateDuration;
            nextState = obj.ERRORRECOVERY_STATE;
            rx.RxErrorPHYFailure = false; % Reset
            rx.RxErrorMACFailure(1:end) = false;
        end
    end

    if obj.CCAState(1) % Primary 20 is busy
        % Move to RECEIVE_STATE
        nextState = obj.RECEIVE_STATE;
    end
end

function nextState = checkRemainingWaitTime(obj, currentTime)
%checkRemainingWaitTime Check remaining wait time and return next state

    nextState = obj.INACTIVE_STATE;
    isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
    if obj.EIFSTimer > currentTime % EIFS wait remaining (can happen in case of zero transition delay)
        nextState = obj.ERRORRECOVERY_STATE;
    elseif ~isNAVExpired % NAV wait remaining
        nextState = obj.NAVWAIT_STATE;
    elseif ~obj.CCAState(1) % Wait times elapsed and CCA state is Idle
        if isQueueEmpty(obj)
            nextState = obj.IDLE_STATE;
        else
            nextState = obj.CONTEND_STATE;
        end
    end
end

function nextInvokeTime = moveToNextState(obj, nextState)
%moveToNextState Perform state transition actions and set nextInvokeTime of
%new state      

    stateChange(obj, nextState);
    nextInvokeTime = obj.NextInvokeTime;
end

function nextInvokeTime = turnOnPHYAndSetMSDTimer(obj, currentTime)
    % Turns on PHY receiver and sets medium sync delay (MSD) timer (if
    % required)

    % Turn on PHY Rx
    switchOnPHYRx(obj);

    % As the link is switching back to performing CCA, set the medium sync
    % delay (MSD) timer if the duration for which CCA is lost is longer than
    % MediumSyncThreshold. Reference: Section 35.3.16.8.1 of IEEE P802.11be/D5.0
    if (currentTime - obj.LinkTurnOffTimestamp > obj.MediumSyncThreshold) && obj.MediumSyncDelayTimer <= currentTime
        % If the medium sync delay (MSD) timer is expired, restart it to its
        % initial value
        obj.MediumSyncDelayTimer = currentTime + obj.MediumSyncDuration;

        % Notify phy receiver that medium sync delay timer has started running
        if ~isempty(obj.MSDTimerStartFcn) && obj.MediumSyncDelayTimer > currentTime
            obj.MSDTimerStartFcn(obj.MediumSyncEDThreshold);
        end
    end

    % As receiver is turned on, invoke immediately to process CCABusy/CCAIdle
    % indications
    nextInvokeTime = currentTime;

    % Trigger event to indicate INACTIVE_STATE completion (i.e., when PHY Rx is turned on)
    if obj.HasListener.StateChanged
        stateChanged = obj.StateChangedTemplate;
        stateChanged.DeviceID = obj.DeviceID;
        stateChanged.State = "Sleep";
        stateChanged.Duration = round((currentTime - obj.StateEntryTimestamp)/1e9, 9);
        obj.EventNotificationFcn('StateChanged', stateChanged);
    end
end
