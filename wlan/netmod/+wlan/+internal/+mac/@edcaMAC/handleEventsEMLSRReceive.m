function nextInvokeTime = handleEventsEMLSRReceive(obj, currentTime, phyIndication, frameFromPHY)
%handleEventsEMLSRReceive Runs MAC layer state machine for receiving
%frames at EMLSR station after responding to initial control frame (ICF)
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   This function performs the following operations:
%   1. Waits for RxStart after responding to ICF.
%   2. Processes any received packet.
%   3. Constructs response frame for the received frame if it is
%   needed.
%
%   NEXTINVOKETIME = handleEventsEMLSRReceive(OBJ, CURRENTTIME,
%   PHYINDICATION, FRAMEFROMPHY) performs MAC layer receiving actions at
%   EMLSR STA after responding to ICF.
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
%   FRAMEFROMPHY is the frame received from PHY layer.

%   Copyright 2024-2025 The MathWorks, Inc.

% Initialize
rx = obj.Rx;
nextInvokeTime = Inf;
nextState = obj. EMLSRRECEIVE_STATE;

%% Handle PHY Indications
if phyIndication.MessageType == obj.RxStartIndication
    handleRxStart(obj, phyIndication);
elseif (phyIndication.MessageType == obj.RxErrorIndication) || (phyIndication.MessageType == obj.RxEndIndication)
    [nextState, nextInvokeTime] = handleRxEnd(obj, phyIndication, frameFromPHY, currentTime);
elseif phyIndication.MessageType == obj.CCAIndication
    nextState = handleCCA(obj, phyIndication, currentTime);
end

% Switch to next state
if nextState ~= obj. EMLSRRECEIVE_STATE % Switching to one of INACTIVE_STATE, TRANSMITRESPONSE_STATE
    stateChange(obj, nextState);
    nextInvokeTime = obj.NextInvokeTime;
    return;
end

%% Handle Wait Timers
if ~rx.IgnoreReceiveTimeout % Response timeout elapsed without receiving RxStart request
    if (obj.NextInvokeTime <= currentTime)
        % If response timeout elapsed and no RxStart indication is received, move
        % to INACTIVE_STATE to wait for transition delay.
        stateChange(obj, obj.INACTIVE_STATE);
    end
    nextInvokeTime = obj.NextInvokeTime;
end

end

%% Supporting functions
function handleRxStart(obj, phyIndication)
%handleRxStart Handles Rx Start indication received from physical layer

    % Initialize
    rx = obj.Rx;
    rx.IgnoreReceiveTimeout = true; % Reset because RxStart is received
    rx.RxVector = phyIndication.Vector;
    rxVector = rx.RxVector;
    ppduFormat = rxVector.PPDUFormat;
    
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
end

function [nextState, nextInvokeTime] = handleRxEnd(obj, phyIndication, frameFromPHY, currentTime)
%handleRxEnd Handle RxEnd (with or without error) received from physical layer

    % Initialize
    rx = obj.Rx;
    nextInvokeTime = Inf;
    nextState = obj. EMLSRRECEIVE_STATE;
    
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
    
    elseif phyIndication.MessageType == obj.RxEndIndication  % RxEnd indication from PHY
        if ~isempty(frameFromPHY)
            [nextInvokeTime, nextState] = handleRxEndWithFrame(obj, phyIndication, frameFromPHY, currentTime);
        else
            handleRxEndWithoutFrame(obj, phyIndication);
        end
    end
end

function nextState = handleCCA(obj, phyIndication, currentTime)
%handleCCA Handle CCA indication received from physical layer

% Initialize
rx = obj.Rx;
nextState = obj. EMLSRRECEIVE_STATE;

if rx.IgnoreReceiveTimeout % RxStart received
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
    if ~obj.CCAState(1) % Primary 20 is idle

        if rx.RxErrorPHYFailure || any(rx.RxErrorMACFailure)
            % If Rx-Error indication or error-ed frame is received, start EIFS recovery
            % timer after receiving CCA-Idle. Reference: Section 10.3.2.3.7 of IEEE Std
            % 802.11ax-2021
            % EIFS time = SIFS time + Ack duration. Ack duration is same as CTS
            % duration for MCS (0), NSTS (1), CBW (20).
            obj.EIFSTimer = currentTime + obj.SIFSTime + obj.AckOrCTSBasicRateDuration;
            rx.RxErrorPHYFailure = false;
            rx.RxErrorMACFailure(1:end) = false;
        end

        % Move to INACTIVE_STATE after receiving CCA idle to handle transition
        % delay time in the following cases:
        %   1. No PPDU detected with RxEnd
        %   2. Error-ed frame
        %   3. Invalid frame is received. Reference for the list of valid
        %      frames: Section 35.3.17 of IEEE P802.11be/D5.0
        nextState = obj.INACTIVE_STATE;
    end

else % RxStart not received
    prevPrimaryStatus = obj.CCAState(1);
    updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);

    if prevPrimaryStatus && ~obj.CCAState(1) % Primary 20 became idle
        if rx.RxErrorPHYFailure
            % If Rx-Error indication is received, start EIFS recovery timer after
            % receiving CCA-Idle. Reference: Section 10.3.2.3.7 of IEEE Std
            % 802.11ax-2021
            % EIFS time = SIFS time + Ack duration. Ack duration is same as CTS
            % duration for MCS (0), NSTS (1), CBW (20).
            obj.EIFSTimer = currentTime + obj.SIFSTime + obj.AckOrCTSBasicRateDuration;
            rx.RxErrorPHYFailure = false;
        end
    end
end
end

function [nextInvokeTime, nextState] = handleRxEndWithFrame(obj, phyIndication, frameFromPHY, currentTime)
%handleRxEndWithFrame Handle Rx End (without error) with frame

    % Initialize
    rx = obj.Rx;
    nextInvokeTime = Inf;
    nextState = obj. EMLSRRECEIVE_STATE;

    rx.ResponseStationID = 0;
    frameIdx = 1;
    rx.ResponseFrame = processRxFrame(obj, frameFromPHY, frameIdx, phyIndication.PPDUInfo);
    
    if ~isempty(rx.ResponseFrame)
        % Move to RECEIVERESPONSE_STATE to wait for SIFS time to transmit
        % response
        nextState = obj.TRANSMITRESPONSE_STATE;
    
    elseif rx.IsIntendedNoAckFrame % Valid frame requiring no response
        % After receiving a frame from AP that does not require acknowledgment,
        % wait for the next PHY-RxStart during a timeout interval. Reference:
        % Section 35.3.17 of IEEE P802.11be/D5.0
        rx.IgnoreReceiveTimeout = false; % Set to false to restart timeout and wait for RxStart
        obj.NextInvokeTime = currentTime + (obj.SIFSTime + obj.SlotTime + obj.PHYRxStartDelayEHT);
        rx.IsIntendedNoAckFrame = false; % Reset
        nextInvokeTime = obj.NextInvokeTime;
    end

    % Notify Reception Ended event
    if ~isempty(obj.ReceptionEndedFcn)
        notifyReceptionEnded(obj, 0, phyIndication.PPDUInfo, rx.RxVector.ChannelBandwidth*1e6);
    end
end

function handleRxEndWithoutFrame(obj, phyIndication)
%handleRxEndWithoutFrame Handle Rx End (without error) without frame

    % Initialize
    rx = obj.Rx;
    
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
