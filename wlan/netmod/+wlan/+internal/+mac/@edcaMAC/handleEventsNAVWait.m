function nextInvokeTime = handleEventsNAVWait(obj, currentTime, phyIndication)
%handleEventsNAVWait Handle the operations while waiting for NAV to elapse
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTINVOKETIME = handleEventsNAVWait(OBJ, CURRENTTIME, PHYINDICATION)
%   performs actions in MAC layer NAV wait state.
%
%   NEXTINVOKETIME is the simulation time in nanoseconds at which the run
%   function must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is the CCAState indicated by the physical layer.

%   Copyright 2023-2025 The MathWorks, Inc.

% Initialization
nextInvokeTime = Inf;
nextState = obj.NAVWAIT_STATE;

%% Handle active timers

% After NAV timeout, the Intra-NAV and NAV timers set due to RTS/MU-RTS
% frames are no longer valid. So, check if they should be reset.
checkForNAVReset(obj, currentTime);
if obj.IsEMLSRLinkMarkedInactive
    % Some other link is active EMLSR link and shared MAC has instructed this
    % link to move to inactive state
    nextState = obj.INACTIVE_STATE;
    nextInvokeTime = moveToNextState(obj, nextState);
    return;
end

%% Handle PHY indications
if phyIndication.MessageType == obj.CCAIndication
    nextState = handleCCA(obj, currentTime, phyIndication);
end

% Switch to next state
if nextState ~= obj.NAVWAIT_STATE
    nextInvokeTime = moveToNextState(obj, nextState);
    return;
end

%% Handle wait times
isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
if isNAVExpired
    if ~obj.CCAState(1) % Primary 20 is idle
        nextState = obj.CONTEND_STATE;
    else
        nextState = obj.RECEIVE_STATE;
    end
    nextInvokeTime = moveToNextState(obj, nextState);
else
    nextInvokeTime = checkRemainingNAVWaitTime(obj, currentTime);
end

end

%% Supporting functions

function nextState = handleCCA(obj, currentTime, phyIndication)
%handleCCA

    nextState = obj.NAVWAIT_STATE;
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
    if obj.CCAState(1) % Primary 20 is busy
        % Move to Receiving state to process further indications from PHY
        nextState = obj.RECEIVE_STATE;
    else
        % If both NAV timers are elapsed, move to Contention state.
        isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
        if isNAVExpired
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

function nextInvokeTime = checkRemainingNAVWaitTime(obj, currentTime)
%checkRemainingNAVWaitTime

    maxNAVTimer = max(obj.NAVTimer, obj.IntraNAVTimer);
    if obj.Rx.WaitingForNAVReset
        minWaitTime = min(obj.RTSNAVResetTimer, maxNAVTimer);
        maxWaitTime = max(obj.RTSNAVResetTimer, maxNAVTimer);
        if minWaitTime > currentTime % Wait time not elapsed
            obj.NextInvokeTime = minWaitTime;
        elseif maxWaitTime > currentTime % Wait time not elapsed
            obj.NextInvokeTime = maxWaitTime;
        else % Wait time elapsed
            obj.NextInvokeTime = Inf;
        end
    else
        if maxNAVTimer > currentTime % Wait time not elapsed
            obj.NextInvokeTime = maxNAVTimer;
        else % Wait time elapsed
            obj.NextInvokeTime = Inf;
        end
    end
    nextInvokeTime = obj.NextInvokeTime;
end
