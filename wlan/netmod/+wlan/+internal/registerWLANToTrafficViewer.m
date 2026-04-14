function registerWLANToTrafficViewer(viewerObj,node)
%registerWLANToTrafficViewer Register WLAN node to wireless traffic viewer
%object
%
%   registerWLANToTrafficViewer(VIEWEROBJ,NODE) registers the WLAN node,
%   NODE, to the traffic viewer object, VIEWEROBJ, to view the traffic
%   information in the viewer.
%
%   VIEWEROBJ specifies the viewer object to which the traffic information
%   of the node is to be viewed. Specify this as a scalar object of type
%   wirelessStateViewer.
%
%   NODE is the WLAN node whose traffic information is to be viewed.
%   Specify this as a scalar object of type wlanNode.
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

% Copyright 2024-2025 The MathWorks, Inc.

% Add listeners to the WLAN node events: TransmissionStarted,
% ReceptionEnded events to view the transmission, reception success,
% reception failure, reception others state.
deviceFrequencies = node.ReceiveFrequency;
callbackFcn = @(eventData) txRxTrafficViewerTranslator(viewerObj,eventData,deviceFrequencies);
registerEventCallback(node,"TransmissionStarted",callbackFcn);
registerEventCallback(node,"ReceptionEnded",callbackFcn);

% Add listeners to the WLAN node StateChanged event to view the contention
% state and sleep state.
callbackFcn = @(node,eventData) stateChangedTrafficViewerTranslator(viewerObj,eventData,node);
addlistener(node,"StateChanged",callbackFcn);
end

function txRxTrafficViewerTranslator(trafficViewerObj,eventData,deviceFrequencies)
%txRxTrafficViewerTranslator Calculates the information necessary for live
%state transition of WLAN node for transmission and reception states and
%adds the traffic information to the traffic viewer object
%
%   txRxTrafficViewerTranslator(TRAFFICVIEWEROBJ,EVENTDATA,DEVICEFREQUENCIES)
%   calculates the necessary traffic information based on the event data,
%   EVENTDATA, and operating center frequencies of the WLAN devices in the
%   node, DEVICEFREQUENCIES, to display on the traffic viewer,
%   TRAFFICVIEWEROBJ.
%
%   TRAFFICVIEWEROBJ specifies the viewer object to which the traffic
%   information of the node is to be viewed. This as a scalar object of
%   type wirelessTrafficViewer.
%
%   EVENTDATA is the event information passed from the node to callbacks.
%
%   DEVICEFREQUENCIES is the list of operating center frequencies in the
%   WLAN device.

    notificationData = eventData.EventData;
    eventName = eventData.EventName;
    trafficInfo = trafficViewerObj.TrafficInfoStruct;

    % Initialize the state of node, the channel frequency and bandwidth of communication
    state = [];
    centerFrequency = [];
    channelBandwidth = [];

    % Get the device index in the node to identify the device in the node
    deviceIdx = find(notificationData.CenterFrequency==deviceFrequencies);
    

    % Update information based on the received information
    if eventName=="TransmissionStarted"
        % TransmissionStarted event is triggered whenever a packet is transmitted
        % from the node. State for the viewer is set accordingly.
        state = trafficViewerObj.Transmission_State;

        % Get the duration of the packet transmitted
        duration = notificationData.Duration;

        % PacketTransmissionStarted event is triggered at the beginning of
        % transmission. Hence the start time is the current time.
        startTime = eventData.Timestamp;

        % Get the frequency and bandwidth of packet transmitted
        centerFrequency = notificationData.TransmitCenterFrequency/1e6;
        channelBandwidth = notificationData.TransmitBandwidth/1e6;
    elseif eventName=="ReceptionEnded"
        % ReceptionEnded event is triggered whenever a packet is received in the
        % node. Get the status of the received state. State for the viewer is set
        % accordingly.

        % Packet decoding has failed at PHY hence reception failure
        if notificationData.PHYDecodeStatus~=0 % Non-zero value indicates failure
            state = trafficViewerObj.ReceptionFailure_State;
        else
            % Packet decoding successful at PHY. Get packet decoding of the PDUs
            pduDecodeStatus = notificationData.PDUDecodeStatus;

            % Multi-user reception
            if iscell(pduDecodeStatus)
                pduDecodeStatus = [notificationData.PDUDecodeStatus{:}];
            end

            % All the PDUs failed decoding hence reception failure
            if all(pduDecodeStatus~=0) % Non-zero value indicates failure
                state = trafficViewerObj.ReceptionFailure_State;
            else % Some or all the PDUs decoded successfully
                if notificationData.IsIntendedReception
                    state = trafficViewerObj.ReceptionSuccess_State;
                else
                    state = trafficViewerObj.ReceptionOthers_State;
                end
            end
        end
        % Get the duration of the packet received
        duration = notificationData.Duration;
    
        % PacketReceptionEnded event is triggered at the end of a packet reception.
        % Hence the start time is calculated as current time - duration of the
        % packet received.
        startTime = eventData.Timestamp-duration;
    
        % Get the frequency and bandwidth of packet received
        centerFrequency = notificationData.ReceiveCenterFrequency/1e6;
        channelBandwidth = notificationData.ReceiveBandwidth/1e6;
    end

    if ~isempty(state)
        % Create the traffic information
        trafficInfo.DeviceID = deviceIdx;
        trafficInfo.StartTime = startTime;
        trafficInfo.Duration = duration;
        trafficInfo.State = state;
        trafficInfo.CenterFrequency = centerFrequency;
        trafficInfo.ChannelBandwidth = channelBandwidth;

        % Add the traffic information
        addTrafficInfo(trafficViewerObj,eventData.NodeID,trafficInfo,false);
    end
end

function stateChangedTrafficViewerTranslator(trafficViewerObj,eventData,node)
%stateChangedTrafficViewerTranslator Calculates the information necessary
%for live state transition of WLAN node based on the StateChanged event for
%sleep and contention states and adds the traffic information to the
%traffic viewer object
%
%   stateChangedTrafficViewerTranslator(TRAFFICVIEWEROBJ,EVENTDATA,NODE)
%   calculates the necessary traffic information based on the node, NODE
%   and event data, EVENTDATA, to display on the traffic viewer,
%   TRAFFICVIEWEROBJ.
%
%   TRAFFICVIEWEROBJ specifies the viewer object to which the traffic
%   information of the node is to be viewed. This as a scalar object of
%   type wirelessTrafficViewer.
%
%   EVENTDATA is the event information returned from the listener attached
%   to the node.
%
%   NODE is the WLAN node whose traffic information is to be viewed. This
%   as a scalar object of type wlanNode.

notificationData = eventData.Data;
trafficInfo = trafficViewerObj.TrafficInfoStruct;

% Get the device index in the node to identify the device in the node
deviceIdx = notificationData.DeviceID;

% Initialize the channel frequency and bandwidth of communication
centerFrequency = [];
channelBandwidth = [];

% Update information based on the received information

% Get the state of the node
nodeState = notificationData.State;

% Get the current time of the event
currentTime = notificationData.CurrentTime;

% Update information based on the state of the node
if strcmp(nodeState,"Contention")
    state = trafficViewerObj.Contention_State;

    % Get the duration of contention state
    duration = notificationData.Duration;

    % Contention event is triggered at the end of contention. Hence the start
    % time is calculated as current time - duration.
    startTime = currentTime-duration;
elseif strcmp(nodeState, "Sleep")
    state = trafficViewerObj.Sleep_State;

    % Get the duration of sleep state
    duration = notificationData.Duration;

    % Event is triggered at the end of sleep. Hence the start time is
    % calculated as current time - duration.
    startTime = currentTime-duration;
else
    return;
end

if ~isempty(state)
    % Create the traffic information
    trafficInfo.DeviceID = deviceIdx;
    trafficInfo.StartTime = startTime;
    trafficInfo.Duration = duration;
    trafficInfo.State = state;
    trafficInfo.CenterFrequency = centerFrequency;
    trafficInfo.ChannelBandwidth = channelBandwidth;

    % Add the traffic information
    addTrafficInfo(trafficViewerObj,node.ID,trafficInfo,false);
end
end

% LocalWords:  VIEWEROBJ MPDUDecoded TRAFFICVIEWEROBJ EVENTDATA DEVICEFREQUENCIES PHY
