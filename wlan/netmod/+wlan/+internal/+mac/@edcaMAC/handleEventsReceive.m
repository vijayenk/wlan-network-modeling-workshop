function nextInvokeTime = handleEventsReceive(obj, currentTime, phyIndication, frameFromPHY)
%handleEventsReceive Runs MAC layer state machine for receiving
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   This function performs the following operations:
%   1. Processes any received packet.
%   2. Constructs response frame for the received frame if it is
%   needed.
%   3. Updates the NAV (Network allocation vector) timer if
%   received frame is not destined for it and received frame
%   duration is greater than the current NAV duration.
%
%   NEXTINVOKETIME = handleEventsReceive(OBJ, CURRENTTIME, PHYINDICATION,
%   FRAMEFROMPHY) performs MAC layer receiving actions.
%
%   NEXTINVOKETIME is the time (in nanoseconds) at which the run function
%   must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is indication from PHY layer.
%
%   FRAMEFROMPHY is the frame received from PHY layer. In case of MU
%   transmissions it is the frame corresponding to this particular user.

%   Copyright 2022-2025 The MathWorks, Inc.

% Initialize
nextInvokeTime = Inf;
nextState = obj.RECEIVE_STATE;

% NAV timers might be running in the background while MAC is in
% RECEIVE_STATE Hence, check whether they should be reset as some further
% transitions in this state depend on NAV timers.
checkForNAVReset(obj, currentTime);

if obj.IsEMLSRLinkMarkedInactive
    % Some other link is active EMLSR link and shared MAC has instructed this
    % link to move to INACTIVE_STATE
    stateChange(obj, obj.INACTIVE_STATE);
    return;
end

%% Handle PHY Indications
if phyIndication.MessageType == obj.RxStartIndication
    nextInvokeTime = handleRxStart(obj, phyIndication, currentTime);
elseif (phyIndication.MessageType == obj.RxEndIndication) || (phyIndication.MessageType == obj.RxErrorIndication)
    nextState = handleRxEnd(obj, phyIndication, frameFromPHY, currentTime);
elseif phyIndication.MessageType == obj.CCAIndication
    nextState = handleCCA(obj, phyIndication, currentTime);
end

% Switch to next state
if nextState ~= obj.RECEIVE_STATE % Switching to one of ERRORRECOVERY_STATE, NAVWAIT_STATE, TRANSMITRESPONSE_STATE, CONTEND_STATE
    stateChange(obj, nextState);
    nextInvokeTime = obj.NextInvokeTime;
end
end

%% Supporting functions

function nextInvokeTime = handleRxStart(obj, phyIndication, currentTime)
%handleRxStart Handles Rx Start indication received from physical layer

    rx = obj.Rx;
    rx.RxVector = phyIndication.Vector;
    rxVector = rx.RxVector;
    ppduFormat = rxVector.PPDUFormat;
    nextInvokeTime = Inf;
    
    if (rx.WaitingForNAVReset) && ... % Indicates NAV is set due to RTS/MU-RTS
            (obj.LastRunTimeNS <= obj.RTSNAVResetTimer)
        % Do not reset NAV set due to RTS/MU-RTS if RxStart indication is received
        % within NAV timeout after RxEnd corresponding to RTS/MU-RTS. Reference:
        % Section 10.3.2.4 of IEEE Std 802.11ax-2021
        rx.WaitingForNAVReset = false;
    end
    
    if ppduFormat == obj.HE_SU || ppduFormat == obj.HE_EXT_SU || ppduFormat == obj.EHT_SU
        % Check for SR opportunity
        checkSROpportunity(obj, rxVector)
    end
    
    % Store the ID of EMLSR STA from which the reception is in progress
    if obj.IsAPDevice && obj.IsAffiliatedWithMLD % AP MLD
        if (rxVector.PPDUFormat == obj.HE_MU) || (rxVector.PPDUFormat == obj.EHT_SU)
            % STAID in RxVector carries AID for an HE-MU/EHT-MU frame
            srcID = getStationID(obj.SharedMAC, rxVector.PerUserInfo(obj.UserIndexSU).StationID);
        else
            % STAID in RxVector is unused in other cases. It carries
            % transmitter node ID in the simulation (custom-implementation).
            srcID = rxVector.PerUserInfo(obj.UserIndexSU).StationID;
        end
        srcIdxLogical = find([obj.SharedMAC.RemoteSTAInfo(:).NodeID] == srcID);
    
        if ~isempty(srcIdxLogical)
            % Check whether the reception is from associated EMLSR STA
            isEMLSRSrc = obj.SharedMAC.RemoteSTAInfo(srcIdxLogical).IsMLD && obj.SharedMAC.RemoteSTAInfo(srcIdxLogical).EnhancedMLMode;
            if isEMLSRSrc
                obj.SharedMAC.CurrentEMLSRRxSTA(obj.DeviceID) = srcID;
            end
        end
    end

    if obj.SROpportunityIdentified
        % Invoke immediately to get Rx End indication from PHY
        nextInvokeTime = currentTime;
    end
end

function nextState = handleRxEnd(obj, phyIndication, frameFromPHY, currentTime)
%handleRxEnd Handle Rx End (success or failure) received from physical layer

    % Initialize
    rx = obj.Rx;
    nextState = obj.RECEIVE_STATE;

    if phyIndication.MessageType == obj.RxErrorIndication
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
    else
        if ~isempty(frameFromPHY)
            nextState = handleRxEndWithFrame(obj, phyIndication, frameFromPHY, currentTime);
        else
            nextState = handleRxEndWithoutFrame(obj, phyIndication);
        end
    end
end

function nextState = handleCCA(obj, phyIndication, currentTime)
%handleCCA Handle CCA indication received from physical layer

    % Initialize
    rx = obj.Rx;
    nextState = obj.RECEIVE_STATE;

    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
    if ~obj.CCAState(1) % Primary 20 is idle
        if rx.RxErrorPHYFailure || rx.RxErrorMACFailure(obj.UserIndexSU)
            % If Rx-Error indication or error-ed frame is received, move to
            % ERRORRECOVERY_STATE (EIFS) after receiving CCA-Idle. Reference: Section
            % 10.3.2.3.7 of IEEE Std 802.11ax-2021
            rx.RxErrorPHYFailure = false; % Reset
            rx.RxErrorMACFailure(obj.UserIndexSU) = false;
            % Move to ERRORRECOVERY_STATE. EIFS time = SIFS time + Ack duration.
            % Ack duration is same as CTS duration for MCS (0), NSTS (1), CBW (20)
            obj.EIFSTimer = currentTime + obj.SIFSTime + obj.AckOrCTSBasicRateDuration;
            nextState = obj.ERRORRECOVERY_STATE;
        else
            isNAVExpired = checkNAVTimerAndResetContext(obj, currentTime);
            if isNAVExpired
                % If both the NAV timers are elapsed, move to
                % CONTEND_STATE.
                nextState = obj.CONTEND_STATE;
            else
                nextState = obj.NAVWAIT_STATE;
            end
        end
    end
end

function nextState = handleRxEndWithFrame(obj, phyIndication, frameFromPHY, currentTime)
%handleRxEndWithFrame Handle Rx End (without error) with frame

    % Initialize
    rx = obj.Rx;
    nextState = obj.RECEIVE_STATE;

    % Non-HT frames receive bandwidth signaling information via
    % RxVector received in RxEnd indication
    if rx.RxVector.PPDUFormat == obj.NonHT
        rx.RxVector.NonHTChannelBandwidth = phyIndication.Vector.NonHTChannelBandwidth;
        rx.RxVector.BandwidthOperation = phyIndication.Vector.BandwidthOperation;
    end
    
    % Process the received frame
    frameIdx = 1;
    rx.ResponseFrame = processRxFrame(obj, frameFromPHY, frameIdx, phyIndication.PPDUInfo);
    if ~isempty(obj.ReceptionEndedFcn)
        notifyReceptionEnded(obj, 0, phyIndication.PPDUInfo, rx.RxVector.ChannelBandwidth*1e6);
    end
    
    if obj.IsAPDevice && obj.IsAffiliatedWithMLD && obj.SharedMAC.CurrentEMLSRRxSTA(obj.DeviceID) && ...
            (rx.RxErrorMACFailure(obj.UserIndexSU) || isempty(rx.ResponseFrame))
        % If there is an expected reception from an EMLSR STA but decoding failed
        % at MAC or no response required, reset the EMLSR STA ID at AP to let the
        % AP send ICF frames to the EMLSR STA on other links.
        obj.SharedMAC.CurrentEMLSRRxSTA(obj.DeviceID) = 0;
    end

    if ~isempty(rx.ResponseFrame) || (rx.LastRxFrameTypeNeedingResponse == obj.BasicTrigger)
        % Received frame has solicited response
        nextState = obj.TRANSMITRESPONSE_STATE;
    
    elseif ~rx.RxErrorMACFailure(obj.UserIndexSU) && ... % Frame with FCS failure is received
           ~isNAVTimerExpired(obj, currentTime)
        % If either of the NAV timers have not elapsed, move to NAV Wait state. But
        % if FCS failed for received frame, do not move to NAV wait state though
        % NAV timers are waiting to elapse. Instead wait for CCA idle indication
        % and move to ERRORRECOVERY_STATE (EIFS) once channel turns idle.
        nextState = obj.NAVWAIT_STATE;
    end
end

function nextState = handleRxEndWithoutFrame(obj, phyIndication)
%handleRxEndWithoutFrame Handle Rx End (without error) without frame
    
    % Initialize
    rx = obj.Rx;
    nextState = obj.RECEIVE_STATE;

    % As there is no frame received, reset the EMLSR STA ID at AP to let the AP
    % send ICF frames to the EMLSR STA on other links.
    obj.SharedMAC.CurrentEMLSRRxSTA(obj.DeviceID) = 0;
    
    if ~obj.CCAState(1) && obj.SROpportunityIdentified
        % Channel is idle and spatial reuse opportunity is identified
        nextState = obj.CONTEND_STATE;
    
    else
        % Perform EIFS recovery when RxEndIndication with no frame is received,
        % except when TXOP duration in Rx vector is not set as unspecified.
        % References: Section 8.3.5.14.2 and 10.3.2.3.7 of IEEE Std 802.11-2020 and
        % Section 10.3.2.3.7 of IEEE Std 802.11ax-2021. RxEndIndication with no
        % frame falls under RxEnd with RxError not equal to NoError.
        if rx.RxVector.TXOPDuration ~= 127 && ... % 127 indicates unspecified
                any(rx.RxVector.PPDUFormat == [obj.HE_SU, obj.HE_EXT_SU, obj.HE_MU, obj.HE_TB, obj.EHT_SU])
            % Set NAV with duration indicated by TXOP_DURATION parameter in RxVector
            % when no frame with Duration field is received. Reference: Section 26.2.4
            % of IEEE Std 802.11ax-2021
            setNAVFromRxVector(obj, rx.RxVector);
        else
            % To perform EIFS recovery, set the RxErrorPHYFailure flag to true.
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
end