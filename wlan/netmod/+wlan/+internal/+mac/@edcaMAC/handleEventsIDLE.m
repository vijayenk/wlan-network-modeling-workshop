function nextInvokeTime = handleEventsIDLE(obj, currentTime, phyIndication)
%handleEventsIDLE Handle the operations in IDLE_STATE
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTINVOKETIME = handleEventsIDLE(OBJ, CURRENTTIME, PHYINDICATION)
%   performs actions in MAC layer IDLE_STATE.
%
%   NEXTINVOKETIME is the time in nanoseconds at which the run function
%   must be invoked again.
%
%   OBJ is an object of type edcaMAC.
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

if phyIndication.MessageType == obj.CCAIndication
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
end
if obj.CCAState(1) % Primary 20 is busy
    % Move to RECEIVE_STATE
    stateChange(obj, obj.RECEIVE_STATE);
    % In the RECEIVE_STATE, wait for further indication from the physical
    % layer receiver
    nextInvokeTime = obj.NextInvokeTime;

    % Check if packets waiting in queues for transmission or a beacon has to be
    % sent or uplink OFDMA enabled
elseif ~isQueueEmpty(obj) || obj.TBTTAcquired || obj.ULOFDMAEnabled
    % Move to CONTEND_STATE
    stateChange(obj, obj.CONTEND_STATE);
    nextInvokeTime = obj.NextInvokeTime;

elseif obj.TBTT && isfinite(obj.BeaconInterval)
    % If beacon transmission is enabled, but no data traffic is queued for
    % transmission, set next invoke time to TBTT
    nextInvokeTime = obj.TBTT;
end
end
