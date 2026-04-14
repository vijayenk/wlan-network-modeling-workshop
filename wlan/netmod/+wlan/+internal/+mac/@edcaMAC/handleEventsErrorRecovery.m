function nextInvokeTime = handleEventsErrorRecovery(obj, currentTime, phyIndication)
%handleEventsErrorRecovery Handle the operations in error recovery state
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTINVOKETIME = handleEventsErrorRecovery(OBJ, CURRENTTIME, PHYINDICATION)
%   performs actions in MAC layer error recovery (EIFS/PIFS) state.
%
%   NEXTINVOKETIME is the time in nanoseconds at which the run function
%   must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is the CCAState indicated by the physical layer.

%   Copyright 2022-2025 The MathWorks, Inc.

% Initialize
nextInvokeTime = Inf;
nextState = obj.ERRORRECOVERY_STATE;
tx = obj.Tx;

%% Handle active timers
if obj.Tx.DoPIFSRecovery
    updateTxNAVTimer(obj);
else
    % NAV timers might be running in the background while MAC is in EIFS state.
    % Hence check whether they should be reset, as some further transitions in
    % this state depend on NAV timers.
    checkForNAVReset(obj, currentTime);

    if obj.IsEMLSRLinkMarkedInactive
        % Some other link is active EMLSR link and shared MAC has instructed this
        % link to move to inactive state
        nextState = obj.INACTIVE_STATE;
        nextInvokeTime = moveToNextState(obj, nextState);
        return;
    end
end

%% Handle PHY indications
if phyIndication.MessageType == obj.CCAIndication
    nextState = handleCCA(obj, currentTime, phyIndication);
end

% Switch to next state
if nextState ~= obj.ERRORRECOVERY_STATE
    nextInvokeTime = moveToNextState(obj, nextState);
    return;
end

%% Handle wait times
if obj.NextInvokeTime <= currentTime % Error recovery period completed
    if obj.Tx.DoPIFSRecovery
        nextState = handlePostPIFSWait(obj);
    else
        nextState = handlePostEIFSWait(obj, currentTime);
    end
    % Switch to next state
    nextInvokeTime = moveToNextState(obj, nextState);
else % Error recovery period in progress
    nextInvokeTime = obj.NextInvokeTime;  
end

end

%% Supporting Functions

function nextState = handleCCA(obj, currentTime, phyIndication)
%handleCCA Handles CCA physical layer indication

    nextState = obj.ERRORRECOVERY_STATE;
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
    if obj.CCAState(1) % Primary 20 is busy
        if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) % Active EMLSR link
            nextState = obj.INACTIVE_STATE;
        else
            nextState = obj.RECEIVE_STATE;
        end
    end
end

function nextState = handlePostEIFSWait(obj, currentTime)
%handlePostEIFSWait Handles operations post completion of EIFS period

    isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
    if isNAVExpired
        % If both the NAV timers are elapsed, move to Contention state.    
        nextState = obj.CONTEND_STATE;
    else % One or both of the NAV and Intra-NAV timers are yet to elapse
        % Move to NAV wait state       
        nextState = obj.NAVWAIT_STATE;
    end
end

function nextState = handlePostPIFSWait(obj)
%handlePostPIFSWait Handles operations post completion of PIFS period

    tx = obj.Tx;
    if obj.AvailableBandwidth < tx.TxBandwidth
        % During PIFS recovery, a CCA indication is received such that the
        % bandwidth available for next transmission is reduced.
    
        % Check if next FES is possible. Do not account for PIFS wait time while
        % checking for next FES because PIFS is already elapsed.
        isFail = false;
        excludeIFS = true;
        [continueTXOP, tx.NextTxFrameType] = decideTXOPStatus(obj, isFail, excludeIFS);
    
        if continueTXOP || (tx.NextTxFrameType == obj.CFEnd) % Continue TXOP or end TXOP with CF-End
            nextState = obj.TRANSMIT_STATE;
    
        else % End the TXOP without CF-End
            nextState = obj.CONTEND_STATE;
            obj.IsLastTXOPHolder = true;
        end
    else
        nextState = obj.TRANSMIT_STATE;
    end
end

function nextInvokeTime = moveToNextState(obj, nextState)
%moveToNextState Perform state transition actions and set nextInvokeTime of
%new state      

    % If in PIFS recovery, reset TXOP context if moving to any of these states
    if obj.Tx.DoPIFSRecovery && ...
            any(nextState == [obj.RECEIVE_STATE obj.INACTIVE_STATE obj.CONTEND_STATE obj.NAVWAIT_STATE])
        resetContextAfterTXOPEnd(obj);
    end
    stateChange(obj, nextState);
    nextInvokeTime = obj.NextInvokeTime;

    obj.Tx.DoPIFSRecovery = false; % Reset PIFS recovery if running
end
