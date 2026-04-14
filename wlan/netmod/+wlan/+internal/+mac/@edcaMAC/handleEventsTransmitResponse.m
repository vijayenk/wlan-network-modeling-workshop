function [macReqToPHY, frameToPHY, nextInvokeTime] = handleEventsTransmitResponse(obj, currentTime, phyIndication)
%handleEventsTransmitResponse Runs MAC layer state machine for handling
%response transmission
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   This function performs the following operations:
%   1. Models SIFS wait time between a frame and its response
%   2. Transmits response frame to PHY
%
%   [MACREQTOPHY, FRAMETOPHY, NEXTINVOKETIME] =
%   handleEventsTransmitResponse(OBJ, CURRENTTIME, PHYINDICATION) performs
%   MAC layer response transmission actions.
%
%   MACREQTOPHY is the transmission request to PHY layer.
%
%   FRAMETOPHY is the response frame to PHY layer.
%
%   NEXTINVOKETIME is the time (in nanoseconds) at which the run function
%   must be invoked again.
%
%   OBJ is an object of type edcaMAC.
%
%   CURRENTTIME is the simulation time in nanoseconds.
%
%   PHYINDICATION is indication from PHY layer.

%   Copyright 2025 The MathWorks, Inc.

macReqToPHY = obj.EmptyRequestToPHY;
frameToPHY = [];
nextInvokeTime = Inf;
rx = obj.Rx; % Handle object

% NAV timers might be running in the background. Hence, check whether they
% should be reset as some further transitions in this state depend on NAV
% timers.
checkForNAVReset(obj, currentTime);

if obj.IsEMLSRLinkMarkedInactive
    % Some other link is active EMLSR link and shared MAC has instructed this
    % link to move to INACTIVE_STATE
    stateChange(obj, obj.INACTIVE_STATE);
    return;
end

switch obj.MACSubstate
    case obj.WAITINGFORSIFS_SUBSTATE % SIFS time waiting to transmit response
        % Handle CCA indication from PHY
        if phyIndication.MessageType == obj.CCAIndication
            updateCCAStateAndAvailableBW(obj, phyIndication, currentTime);
        end

        % Turn off receiver. Do not turn off if the node is responding to Basic TF
        % or MU-RTS TF because channel sensing might be required.
        if ~(any(rx.LastRxFrameTypeNeedingResponse==[obj.BasicTrigger obj.MURTSTrigger obj.MUBARTrigger]) && rx.CSRequired)
            switchOffPHYRx(obj);
        end

        % SIFS elapsed after receiving the frame soliciting response
        if obj.NextInvokeTime <= currentTime
            bwOperationType = 'Absent';
            % By default, assign the same bandwidth received in the
            % RxVector in the response frame's TxVector.
            respBandwidth = rx.RxVector.ChannelBandwidth;
            sendResponse = true;

            switch rx.LastRxFrameTypeNeedingResponse
                case obj.RTS
                    [sendResponse, respBandwidth, bwOperationType, navBusy, secChannelBusy] = performNAVAndBWSigChecks(obj, currentTime);
                    if sendResponse
                        prevTXOPHolder = obj.TXOPHolder;
                        obj.TXOPHolder = rx.ResponseFrame.MACFrame.MPDU.Header.Address1;
                        obj.Statistics.TransmittedCTSFrames = obj.Statistics.TransmittedCTSFrames + 1;
                        if obj.IsAffiliatedWithMLD && ~strcmp(prevTXOPHolder, obj.TXOPHolder)
                            % Discard last SSN and temporary bitmap records at the end of current TXOP,
                            % if independent scoreboard context is maintained. Reference: Section
                            % 35.3.8 of IEEE P802.11be/D5.0. Our implementation discards whenever TXOP
                            % holder address is cleared/updated, which indicates TXOP change.
                            resetLastSSNForMLDTxRxPair(obj);
                        end
                    else
                        if navBusy % NAV indicates channel is busy
                            % Move to NAVWAIT_STATE
                            stateChange(obj, obj.NAVWAIT_STATE);
                        end
                        if secChannelBusy % Any of the secondary channels are busy
                            nextState = performPostRxFrameHandlingActions(obj, currentTime);
                            stateChange(obj, nextState);
                        end
                    end

                case {obj.BasicTrigger, obj.MURTSTrigger}
                    sendResponse = performCSIfRequired(obj, currentTime);

                    if sendResponse
                        if (rx.LastRxFrameTypeNeedingResponse == obj.BasicTrigger)
                            % Move to TRANSMITRESPONSE_STATE to send HE TB
                            % data frame in following cases: 1. when
                            % carrier sensing is not required 2. when
                            % carrier sensing is required and channel is
                            % idle
                            obj.Tx.NextTxFrameType = scheduleTransmission(obj);
                            stateChange(obj, obj.TRANSMIT_STATE);
                            nextInvokeTime = obj.NextInvokeTime;
                            return;
                        else % rx.LastRxFrameTypeNeedingResponse == obj.MURTSTrigger
                            obj.Statistics.TransmittedCTSFrames = obj.Statistics.TransmittedCTSFrames + 1;
                        end
                    else
                        % Do not respond with CTS or HE TB PPDU when CSRequired field is set to
                        % true and virtual CS mechanism determined the channel as busy. During
                        % virtual CS, consider only basic NAV. Refer to Section 26.5.2.5 of IEEE
                        % Std 802.11ax-2021
                        if obj.CCAState(1) % Physical CS indicated busy
                            % Do nothing and wait for PHY Rx indication
                            stateChange(obj, obj.RECEIVE_STATE);
                        else % Virtual CS indicated busy
                            % Move to NAVWAIT_STATE
                            stateChange(obj, obj.NAVWAIT_STATE);
                        end
                    end
            end

            if ~sendResponse
                rx.ResponseFrame = [];
                rx.LastRxFrameTypeNeedingResponse = obj.UnknownFrameType;
                resetEMLSRRxContext(obj);
                switchOnPHYRx(obj);
                % As the receiver is turned on, invoke the node at current
                % time to receive CCA state indications from PHY.
                nextInvokeTime = currentTime;
            else
                % Overwrite the response bandwidth information with BW of the current
                % device. Need this when MAC has to rely on BW information in rxVector to
                % respond to a Non-HT packet with no bandwidth signaling TA and BW in
                % rxVector is higher than receiver BW.
                respBandwidth = min(respBandwidth,obj.ChannelBandwidth);

                % Send TxStart request and response frame
                macReqToPHY = generateRespTxStart(obj, respBandwidth, bwOperationType);
                frameToPHY = rx.ResponseFrame;

                obj.MACSubstate = obj.TRANSMIT_SUBSTATE;
                obj.NextInvokeTime = currentTime + rx.ResponseTxTime;
                nextInvokeTime = obj.NextInvokeTime;

                if strcmp(obj.TXOPHolder, obj.MACAddress)
                    % Capture bandwidth of the PPDU transmitted by TXOP holder
                    obj.Tx.LastPPDUBandwidth = rx.RxVector.ChannelBandwidth;
                end

                if obj.IsEMLSRSTA
                    nextInvokeTime = turnEMLSRLinkActive(obj, currentTime);
                end

                notifyEvents(obj, frameToPHY, macReqToPHY);
            end
        else
            nextInvokeTime = obj.NextInvokeTime;
        end

    case obj.TRANSMIT_SUBSTATE % Response frame transmission
        if obj.NextInvokeTime <= currentTime % Response frame transmission time is completed
            % Start PHY receiver
            switchOnPHYRx(obj);

            if obj.IsEMLSRSTA && obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID)
                stateChange(obj, obj.EMLSRRECEIVE_STATE);
                % As PHY receiver is turned on, invoke at current time to
                % get any indication
                nextInvokeTime = currentTime;
            else
                nextState = performPostRxFrameHandlingActions(obj, currentTime);
                stateChange(obj, nextState);
                nextInvokeTime = obj.NextInvokeTime;
                if obj.CCAState(1) % Primary 20 busy
                    % Invoke immediately to get further indication from PHY
                    nextInvokeTime = currentTime;
                end
            end

            rx.ResponseFrame = []; % Reset after transmission
            rx.LastRxFrameTypeNeedingResponse = obj.UnknownFrameType; % Reset
        else
            nextInvokeTime = obj.NextInvokeTime;
        end
end
end

function [sendResponse, respBandwidth, bwOperationType, navBusy, secChannelBusy] = performNAVAndBWSigChecks(obj, currentTime)

rx = obj.Rx; % Handle object
navBusy = false;
secChannelBusy = false;
bwOperationType = 'Absent';
respBandwidth = rx.RxVector.ChannelBandwidth;

% Send CTS response if NAV indicates idle. Refer Section 10.3.2.9 of IEEE
% Std 802.11-2020.
sendResponse = checkNAV(obj, currentTime);

if sendResponse % NAV indicates idle
    if (obj.MaxSupportedStandard >= obj.Std80211ac) && rx.IsBWSignalingTAPresent && ...
            rx.RxVector.NonHTChannelBandwidth ~= 0 && ~strcmp(rx.RxVector.BandwidthOperation, 'Absent')
        useLastCCAIdle2BusyDuration = true; % Set this to true to use the last CCA idle duration before turning busy
        respBandwidth = totalBWBasedOnSecondaryChannelCCA(obj, useLastCCAIdle2BusyDuration);
        bwOperationType = rx.RxVector.BandwidthOperation;
        if strcmp(rx.RxVector.BandwidthOperation,'Static')
            % Send CTS response only if CCA is idle for all secondary channels
            % indicated in NonHTChannelBandwidth, if bandwidth signaling TA is present
            % in received RTS frame with BandwidthOperation (DYN_BANDWIDTH_IN_NONHT)
            % parameter of RxVector indicates Static.
            if respBandwidth >= rx.RxVector.NonHTChannelBandwidth
                respBandwidth = rx.RxVector.NonHTChannelBandwidth;
            else % Secondary channels indicated in NonHTChannelBandwidth are not idle
                sendResponse = false;
                secChannelBusy = true;
            end
        else % 'Dynamic'
            % If BandwidthOperation parameter indicates Dynamic, send
            % CTS in any channel width less than or equal to RTS frame's RxVector
            % parameter 'NonHTChannelBandwidth'. Refer Section 10.3.2.9.
            respBandwidth = min(respBandwidth, rx.RxVector.NonHTChannelBandwidth);
        end
    end
else
    navBusy = true;
end
end

function sendResponse = checkNAV(obj, currentTime)
% Check NAV before responding with CTS frame to RTS

sendResponse = true;

% If NAV timer is still running, send response only if the sender of RTS is
% the TXOP owner
if (obj.IntraNAVTimer > currentTime) && ~strcmp(obj.TXOPHolder, '000000000000') ...
        && ~strcmp(obj.Rx.RTSReceivedFrom, obj.TXOPHolder)
    % Do not respond with CTS frame if NAV is not elapsed and NAV is not set by
    % TXOP owner. Reference: Section 10.3.2.9 of IEEE Std 802.11-2020.
    sendResponse = false;
end
end

function nextState = performPostRxFrameHandlingActions(obj, currentTime)
%performPostRxFrameHandlingActions Perform necessary operations after
%finishing the received frame processing and sending any required
%response (if any).

% Reset EMLSR Rx context
resetEMLSRRxContext(obj);

nextState = [];
if (obj.Rx.LastRxFrameTypeNeedingResponse == obj.Management) && ~isempty(obj.PerformPostManagementRxActionsCustomFcn)
    nextState = obj.PerformPostManagementRxActionsCustomFcn(obj);
end

if isempty(nextState)
    if ~isNAVTimerExpired(obj, currentTime)
        % If there are pending NAV timers, move to NAV wait state
        nextState = obj.NAVWAIT_STATE;

    elseif ~obj.CCAState(1) % Primary 20 is idle
        if strcmp(obj.TXOPHolder, obj.MACAddress)
            % If TXOP holder, check if TXOP can still be continued
            [continueTXOP, obj.Tx.NextTxFrameType] = decideTXOPStatus(obj, false);
            if continueTXOP || (obj.Tx.NextTxFrameType == obj.CFEnd) % Continue TXOP or end TXOP with CF-End
                nextState = obj.TRANSMIT_STATE;
                resetContextAfterCurrentFES(obj);
            else % End the TXOP without CF-End
                nextState = obj.CONTEND_STATE;
                obj.IsLastTXOPHolder = true;
                resetContextAfterTXOPEnd(obj);
            end
        else
            % If both the NAV timers are elapsed and channel is idle, move to
            % CONTEND_STATE.
            nextState = obj.CONTEND_STATE;
        end

    else
        if strcmp(obj.TXOPHolder, obj.MACAddress)
            resetContextAfterTXOPEnd(obj);
        end
        % As the channel is still busy, wait for further indication from PHY
        nextState = obj.RECEIVE_STATE;
    end
end

obj.Rx.LastRxFrameTypeNeedingResponse = obj.UnknownFrameType;
end

function resetEMLSRRxContext(obj)
%resetEMLSRRxContext Reset context related to receptions from EMLSR STA

if obj.IsAPDevice && obj.IsAffiliatedWithMLD && obj.SharedMAC.CurrentEMLSRRxSTA(obj.DeviceID)
    % Reset the EMLSR STA ID stored at affiliated AP to let the AP MLD send ICF
    % frames to the EMLSR STA on other links.
    obj.SharedMAC.CurrentEMLSRRxSTA(obj.DeviceID) = 0;
end
end

function sendResponse = performCSIfRequired(obj, currentTime)
    %performCSIfRequired Perform channel sensing if required for MU-RTS frame
    %and basic trigger frame

    if ~obj.Rx.CSRequired
        % Send response without checking indications from physical and virtual CS
        sendResponse = true;

    else
        if (obj.Rx.LastRxFrameTypeNeedingResponse == obj.BasicTrigger)
            fc = obj.OperatingFrequency;
            startingFreq = fc-(obj.ChannelBandwidth*1e6/2);

            % Get bandwidth indicated in UL BW subfield. This is not explicitly stored
            % currently. It is same as bandwidth in which Basic TF is sent.
            cbw = obj.Rx.RxVector.ChannelBandwidth;
            % Get the sub-carrier indices as per standard corresponding to allocated RU
            k = wlan.internal.heRUSubcarrierIndices(cbw, obj.Rx.ResponseRU(1), obj.Rx.ResponseRU(2));
            % Get the indices to calculate baseband frequency range
            Nfft = 256*cbw/20;
            carrierSpacingInHz = cbw*1e6/Nfft;
            kRU = (k+Nfft/2+1).';
            bbFreqRange = [kRU(1) kRU(end)]*carrierSpacingInHz;

            % Get the starting frequency corresponding to bandwidth indicated in UL BW
            % field
            factor = cbw/20;
            % Assuming RU allocation is in the primary 20/40/80/160 channel, get the
            % primary 20/40/80/160 channel index
            primaryChannelIdx = ceil(obj.PrimaryChannelIndex/factor);
            % Get the starting 20 MHz index in the primary 20/40/80/160 channel
            starting20MHzIdx = (primaryChannelIdx-1)*factor + 1;
            primaryStartingFreq = startingFreq + (starting20MHzIdx-1)*20e6;

            % Get the frequency range of resource unit
            freqRange = bbFreqRange + primaryStartingFreq;

            % Find the starting and ending frequencies of each 20 MHz subchannel
            num20MHzChannels = obj.ChannelBandwidth/20;
            starting20MHzFreq = zeros(num20MHzChannels,1);
            for channelIdx = 1:num20MHzChannels
                starting20MHzFreq(channelIdx) = startingFreq + (channelIdx-1)*20e6;
            end
            ending20MHzFreq = starting20MHzFreq + 20e6;

            % Find the starting and ending 20 MHz subchannel indices corresponding to
            % RU allocation
            start20MHzIdx = find(starting20MHzFreq<=freqRange(1), 1);
            end20MHzIdx = find(freqRange(2)<=ending20MHzFreq, 1);

            % Send response if:
            %  * Physical CS indicated that the 20 MHz channels containing RU allocation
            %    are idle
            %  * Virtual CS indicates idle (Zero NAV timer)
            % Reference: Section 26.5.2.5 of IEEE Std 802.11ax-2021
            phyCS = all(~obj.CCAStatePer20(start20MHzIdx:end20MHzIdx));
            virtualCS = obj.NAVTimer <= currentTime;
            sendResponse = phyCS && virtualCS;

        else % MU-RTS frame
            % Reference: Section 26.5.2.5 of IEEE Std 802.11ax-2021. Check if the CCA
            % state of all 20 MHz subchannels which correspond to the UL RU allocation
            % for this STA are idle. For MU-RTS, currently CTS is expected in whole
            % bandwidth and bandwidth of AP and STA is the same. Hence, check CCA state
            % of all 20 MHz subchannels in the bandwidth. MUAllNodesSameBWSupported.
            sendResponse = (obj.NAVTimer <= currentTime && all(~obj.CCAStatePer20));
        end
    end

    obj.Rx.CSRequired = false; % Reset
end

function macReqToPHY = generateRespTxStart(obj, respBandwidth, bwOperationType)
%generateRespTxStart Generate Tx_Start request to transmit response frame

rx = obj.Rx; % Handle object
if rx.RxVector.PPDUFormat == obj.HE_MU && strcmp(rx.ULTriggerMethod, 'TRS')
    % Response solicited by an HE-MU frame with TRS control field
    macReqToPHY = generateTxStartRequest(obj, ...
        double(obj.HE_TB), respBandwidth, ...
        rx.ResponseMCS, rx.ResponseNumSTS, ...
        rx.ResponseLength, rx.ResponseStationID, ...
        rx.ULTriggerMethod, rx.ULNumDataSymbols);
elseif rx.LastRxFrameTypeNeedingResponse == obj.MUBARTrigger
    % Response solicited by an MU-BAR trigger frame
    macReqToPHY = generateTxStartRequest(obj, ...
        double(obj.HE_TB), respBandwidth, ...
        rx.ResponseMCS, rx.ResponseNumSTS, ...
        rx.ResponseLength, rx.ResponseStationID, ...
        rx.ULTriggerMethod, rx.ULLSIGLength);
else
    % All other response frames
    macReqToPHY = generateTxStartRequest(obj, ...
        double(obj.NonHT), respBandwidth, ...
        rx.ResponseMCS, rx.ResponseNumSTS, ...
        rx.ResponseLength, rx.ResponseStationID, bwOperationType);
end
end

function nextInvokeTime = turnEMLSRLinkActive(obj, currentTime)

nextInvokeTime = obj.NextInvokeTime;
% Suspend transmit and receive capabilities on links other than the one on
% which STA MLD has responded to ICF. Reference: Section 35.3.17 of
% IEEE P802.11be/D5.0
if (obj.Rx.LastRxFrameTypeNeedingResponse == obj.MURTSTrigger) && ~obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID)
    turnOffOtherLinks(obj.SharedMAC, obj.DeviceID);
    % Switch to use aggregated antennas of all EMLSR links for reception.
    % NumTransmitAntennas holds the aggregated value.
    obj.NumReceiveAntennas = obj.NumTransmitAntennas;
    if ~isempty(obj.SetNumRxAntennasFcn)
        obj.SetNumRxAntennasFcn(obj.NumReceiveAntennas);
    end
    nextInvokeTime = currentTime; % To capture turn off time in other links
    obj.SharedMAC.ActiveEMLSRLink(obj.DeviceID) = true;
end
end

function notifyEvents(obj, frameToPHY,  macReqToPHY)

% Trigger 'MPDUGenerated'. Note that MPDUGenerated event will be removed in
% a future release. Use the TransmissionStarted event instead. Register for
% the TransmissionStarted notification by using the 'registerEventCallback'
% function of wlanNode.
if obj.HasListener.MPDUGenerated && ~obj.FrameAbstraction
    notifyMPDUGenerated(obj, frameToPHY.MACFrame(obj.UserIndexSU).Data, macReqToPHY.Vector.ChannelBandwidth);
end

if ~isempty(obj.TransmissionStartedFcn)
    notifyTransmissionStarted(obj, obj.Rx.ResponseLength, obj.Rx.ResponseTxTime, macReqToPHY.Vector);
end
end
