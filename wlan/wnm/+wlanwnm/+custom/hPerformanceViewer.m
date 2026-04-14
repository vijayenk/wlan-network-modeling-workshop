classdef hPerformanceViewer < handle
    %hPerformanceViewer Performance metrics viewer (throughput, latency, and
    %packet loss ratio)
    %
    %   hPerformanceViewer(NODES,SIMULATIONTIME) plots the packet loss
    %   ratio, throughput, and average application packet latency for the
    %   specified WLAN nodes.
    %
    %   NODES is a normal array or a cell array of objects of type wlanNode.
    %
    %   SIMULATIONTIME is a finite positive scalar indicating the simulation
    %   time in seconds.
    %
    %   hPerformanceViewer methods:
    %
    %   plotNetworkStats        - Plots the performance metrics (throughput,
    %                             average packet latency, and packet loss ratio)
    %   throughput              - Returns transmission throughput of all the nodes
    %   averageReceiveLatency   - Returns average receive latency of all the nodes
    %   packetLossRatio         - Returns packet loss ratio of all the nodes

    %   Copyright 2025 The MathWorks, Inc.

    properties (SetAccess=private)
        %WLANNodes List of WLAN nodes for visualization
        WLANNodes = wlanNode.empty()

        %AveragePacketLatency This property specifies the average latency computed
        %at each node in seconds. The first column represents node ID, second
        %column represents the average latency value, third column represents the
        %node type, and the fourth column represents the device type.
        AveragePacketLatency

        %Throughput This property specifies the throughput computed at each node in
        %seconds. The first column represents node ID, second column represents the
        %throughput value, third column represents the node type, and the fourth
        %column represents the device type.
        Throughput

        %PacketLossRatio This property specifies the packet loss ratio computed at
        %each node in seconds. The first column represents node ID, second column
        %represents the PLR value, third column represents the node type, and the
        %fourth column represents the device type.
        PacketLossRatio

        %PacketLatencyAll This property specifies the latency value of all the
        %received packet in seconds.
        PacketLatencyAll
    end

    properties (Access=private)
        %pPacketLatency This property specifies the latency computed at each node
        %in seconds. The first column represents node ID, second column represents
        %the latency values of the received packets, third column represents the
        %node type, and the fourth column represents the device type.
        pPacketLatency

        %pNumPackets This property specifies the number of application packets
        %received at each node. The first column represents node ID, second column
        %represents the number of packets received, third column represents the
        %node type, and the fourth column represents the device type.
        pNumPackets

        %pSimulationTime Simulation time in seconds
        pSimulationTime = 0

        %pNodeTypeList This property is a vector specifying the node IDs and the
        %type of the nodes. The first column represents the node ID, the second
        %column represents the node type, and the third column represents the
        %device type. This property is used for identifying the nodes and devices
        %for reference.
        pNodeTypeList

        %pNodes This property is a cell array containing all the nodes added in the
        %same order as the node IDs stored in pNodeTypeList.
        pNodes
    end

    %% For wirelessNetworkModeler app
    properties (Hidden)
        %PerformanceViewer Figure handle for the plotting the performance metrics
        PerformanceViewer

        %PerformanceViewerDisabled Flag to specify whether the PerformanceViewer UI Figure
        %has been disabled
        PerformanceViewerDisabled = false;

        %NetworkSimulator Wireless network simulator object used in the simulation
        % Can be set through N-V pair in the constructor. If not set, will be
        % obtained by calling wirelessNetworkSimulator.getInstance().
        NetworkSimulator wirelessNetworkSimulator {mustBeScalarOrEmpty}
    end

    %% Constructor
    methods
        function obj = hPerformanceViewer(nodes,simulationTime,varargin)

            % Validate the simulation time
            validateattributes(simulationTime,{'numeric'},{'nonempty','scalar','positive','finite'},mfilename,"simulationTime");

            % Return if no nodes are available
            if isempty(nodes)
                return;
            end

            % Validate the nodes
            if iscell(nodes)
                for idx = 1:numel(nodes)
                    validateattributes(nodes{idx},"wlanNode",{'scalar'},mfilename,"nodes");
                end
            else
                validateattributes(nodes(1),"wlanNode",{'scalar'},mfilename,"nodes");
                nodes = num2cell(nodes);
            end

            % Use weak-references for cross-linking handle objects
            objWeakRef = matlab.lang.WeakReference(obj);

            % Name-value pair check
            coder.internal.errorIf(mod(nargin,2)==1,"MATLAB:system:invalidPVPairs")

            % Store the NV pair information
            for idx = 1:2:nargin-2
                obj.(varargin{idx}) = varargin{idx+1};
            end

            % Use default wirelessNetworkSimulator if not provided
            if isempty(obj.NetworkSimulator)
                obj.NetworkSimulator = wirelessNetworkSimulator.getInstance;
            end

            % Store the nodes
            numWLANNodes = 0;
            numNodes = numel(nodes);
            for idx = 1:numNodes
                numWLANNodes = numWLANNodes+1;
                obj.WLANNodes(numWLANNodes) = nodes{idx};
                addlistener(nodes{idx},"AppDataReceived",@(srcNode,eventData) objWeakRef.Handle.calculatePacketLatency(srcNode,eventData));
            end

            % Initialize the throughput and latency
            obj.pNodeTypeList = zeros(numNodes,3);
            for idx = 1:numWLANNodes
                obj.pNodeTypeList(idx,1) = obj.WLANNodes(idx).ID;
                obj.pNodeTypeList(idx,2:3) = 1;
                obj.pNodes{idx} = obj.WLANNodes(idx);
            end

            numDevices = size(obj.pNodeTypeList,1);
            obj.PacketLatencyAll = cell(numDevices,2);
            obj.PacketLatencyAll(:,1) = num2cell(obj.pNodeTypeList(:,1));
            obj.pPacketLatency = [obj.pNodeTypeList(:,1) zeros(numDevices,1) obj.pNodeTypeList(:,2) zeros(numDevices,1)];
            [obj.AveragePacketLatency, obj.Throughput, obj.PacketLossRatio, obj.pNumPackets] = deal(obj.pPacketLatency);

            % Schedule action to perform at the end of simulation
            obj.pSimulationTime = simulationTime;
            if numel(obj.WLANNodes)>0
                schedulePostSimulationAction(obj.NetworkSimulator, @(varargin) objWeakRef.Handle.calculateStats(num2cell(obj.WLANNodes)), []);
            end
        end

        function plotNetworkStats(obj)
            %plotNetworkStats Plots the performance metrics (throughput, average
            %receive latency, and packet loss ratio)
            %
            %   plotNetworkStats(OBJ) plots throughput (in Mbps), average packet
            %   latency (in seconds), and packet loss ratio at each node.
            %
            %   OBJ is an object of type hPerformanceViewer.

            % Calculate and plot the graph for WLAN Nodes
            if numel(obj.WLANNodes)>0
                [nodeNames,plr,throughput,latency] = getMetrics(obj,num2cell(obj.WLANNodes));
                % Pass custom figure handle. It is empty unless provided by wirelessNetworkModeler app
                figHandle = plotBarGraph(obj,nodeNames,plr,throughput,latency,"Mbps",[0 ones(1,numel(obj.WLANNodes))],"Node Name",obj.PerformanceViewer);
                figHandle.Tag = "WLAN Performance";
                sgtitle("Performance of WLAN Nodes");
                obj.PerformanceViewer = figHandle;
            end
        end

        function tput = throughput(obj, nodeID, varargin)
            %throughput Returns transmission throughput of given nodes.
            %
            %   TPUT = throughput(OBJ, NODEID) returns transmission throughput for the
            %   given node, NODEID.
            %
            %   TPUT is a vector of size 1-by-N where N is the number of values in the
            %   NODEID.
            %
            %   OBJ is an object of type hPerformanceViewer.
            %
            %   NODEID is a scalar or a vector of integers indicating valid node
            %   identifier(s).
            %
            %   TPUT = throughput(..., LinkID=Value) returns transmission throughput
            %   for the specified link, in the given node, NODEID. LinkID indicates a
            %   valid link identifier in an MLD node specified by NODEID. If NODEID is
            %   a vector of values, the LinkID must be a vector of the same size,
            %   indicating valid link identifiers for the corresponding NODEID values.
            %   This is applicable when the specified node ID corresponds to a WLAN
            %   MLD node.

            tput = calculateMetrics(obj,"Throughput",nodeID,varargin);
        end

        function plr = packetLossRatio(obj, nodeID, varargin)
            %packetLossRatio Returns packet loss ratio of given nodes.
            %
            %   PLR = packetLossRatio(OBJ, NODEID) returns packet loss ratio for the
            %   given node, NODEID.
            %
            %   PLR is a vector of size 1-by-N where N is the number of values in the
            %   NODEID.
            %
            %   OBJ is an object of type hPerformanceViewer.
            %
            %   NODEID is a scalar or a vector of integers indicating valid node
            %   identifier(s).
            %
            %   PLR = packetLossRatio(..., LinkID=Value) returns packet loss ratio for
            %   the specified link, in the given node, NODEID. LinkID indicates a valid
            %   link identifier in an MLD node specified by NODEID. If NODEID is a
            %   vector of values, the LinkID must be a vector of the same size,
            %   indicating valid link identifiers for the corresponding NODEID values.
            %   This is applicable when the specified node ID corresponds to a WLAN
            %   MLD node.

            plr = calculateMetrics(obj,"PLR",nodeID,varargin);
        end

        function avgLatency = averageReceiveLatency(obj, nodeID)
            %averageReceiveLatency Returns average receive application latency of given
            %nodes.
            %
            %   AVGLATENCY = averageReceiveLatency(OBJ, NODEID) returns average
            %   application receive latency for the given node, NODEID.
            %
            %   AVGLATENCY is a vector or cell array of size 1-by-N where N is the
            %   number of values in the NODEID.
            %
            %   OBJ is an object of type hPerformanceViewer.
            %
            %   NODEID is a scalar or a vector of integers indicating valid node
            %   identifier(s).

            latencyMetric = "Average";
            avgLatency = calculateMetrics(obj,"Latency",nodeID,[],latencyMetric);
        end
    end

    %% For wirelessNetworkModeler app
    methods (Hidden)
        function networkStats = exportWLANNetworkStats(obj, nodes)
            %exportNetworkStats Returns the performance metrics (throughput, average
            %receive latency, and packet loss ratio) as a structure
            %
            %   exportNetworkStats(OBJ) returns throughput (in Mbps), average packet
            %   latency (in seconds), and packet loss ratio at each WLAN node, as a
            %   structure.
            %
            %   NETWORKSTATS is a structure with the following fields:
            %       NodeName                 - Name of the node
            %       MACTransmitThroughput    - Transmisison throughput of the node in Mbps
            %       MACPacketLossRatio       - MAC packet loss ratio of the node
            %       AverageAppPacketLatency  - Average application packet latency of the
            %                                  node in seconds
            %
            %   OBJ is an object of type hPerformanceViewer.
            %
            %   NODES is a normal array or a cell array of objects of type wlanNode.

            % Initialize
            networkStats = struct('NodeName',[], 'MACTransmitThroughput',[], 'MACPacketLossRatio',[], 'AverageAppPacketLatency',[]);
            % Return if no nodes are available
            if isempty(nodes)
                return;
            end

            % Validate the nodes
            if iscell(nodes)
                for idx = 1:numel(nodes)
                    validateattributes(nodes{idx},"wlanNode",{'scalar'},mfilename,"nodes");
                end
                nodes = cell2mat(nodes);
            else
                validateattributes(nodes(1),"wlanNode",{'scalar'},mfilename,"nodes");
            end

            % Calculate network stats for given WLAN Nodes
            if numel(obj.WLANNodes)>0
                networkStats = repmat(networkStats, 1, numel(nodes));
                nodeIDs = [nodes.ID]; % Node IDs of given nodes
                allWLANNodeIDs = [obj.WLANNodes.ID]; % Node IDs of all WLAN nodes
                [~, inputNodeLocations] = ismember(nodeIDs,allWLANNodeIDs);
                wlanNodes = obj.WLANNodes(inputNodeLocations);
                [nodeNames,plr,throughput,latency] = getMetrics(obj,num2cell(wlanNodes));

                % Populate output structure
                for nodeIdx = 1:numel(wlanNodes)
                    networkStats(nodeIdx).NodeName = nodeNames(nodeIdx);
                    networkStats(nodeIdx).MACTransmitThroughput = throughput(nodeIdx);
                    networkStats(nodeIdx).MACPacketLossRatio = plr(nodeIdx);
                    networkStats(nodeIdx).AverageAppPacketLatency = latency(nodeIdx);
                end
            end
        end
    end

    %% Standard Based Methods
    methods (Access=private)
        function calculatePacketLatency(obj,srcNode,eventData)
            %calculatePacketLatency Calculate average packet latency

            notificationData = eventData.Data;
            % Find the node index in the stored aggregate packet latency
            nodeIdx = find(srcNode.ID==obj.pNodeTypeList(:,1));

            latencyVal = notificationData.CurrentTime-notificationData.PacketGenerationTime;

            % Store the list of packet latencies of each packet
            packetLatencyList = obj.PacketLatencyAll{nodeIdx,2};
            packetLatencyList = [packetLatencyList latencyVal];
            obj.PacketLatencyAll{nodeIdx,2} = packetLatencyList;

            % Aggregate the packet latency
            obj.pPacketLatency(nodeIdx,2) = obj.pPacketLatency(nodeIdx,2)+latencyVal;

            % Increment the number of App packets received
            obj.pNumPackets(nodeIdx,2) = obj.pNumPackets(nodeIdx,2)+1;

            % Calculate the average packet latency
            obj.AveragePacketLatency(nodeIdx,2) = obj.pPacketLatency(nodeIdx,2)/obj.pNumPackets(nodeIdx,2);
        end

        function calculateStats(obj,nodes)
            %calculateStats Calculate all the statistics of the nodes added to the
            %performance viewer at the end of simulation

            % Initialize
            numNodes = numel(nodes);

            % Calculate the performance of all the nodes
            for idx = 1:numNodes
                % Get the index at the packet latency for the node
                nodeIdx = find(nodes{idx}.ID==obj.pNodeTypeList(:,1));

                % Get the node name and statistics of the node
                statsNode = statistics(nodes{idx});
                statsDevice = statsNode;

                % Get the device types of the node
                deviceList = obj.pNodeTypeList(nodeIdx,3);
                numDevices = numel(deviceList);

                % Initialize the metrics
                packetLossRatio = zeros(1,numDevices);
                throughput = zeros(1,numDevices);
                latency = zeros(1,numDevices);
                count = 1;

                % Calculate the metric based on the node and device type
                for packetTypeIdx = 1:numel(deviceList)
                    deviceType = deviceList(packetTypeIdx);
                    if deviceType==1
                        techName = "WLAN";
                    end
                    packetLossRatio(count) = calculatePerformanceMetric(obj,"PLR",techName,statsDevice,obj.pSimulationTime,nodeIdx(packetTypeIdx));
                    throughput(count) = calculatePerformanceMetric(obj,"Throughput",techName,statsDevice,obj.pSimulationTime,nodeIdx(packetTypeIdx));
                    latency(count) = calculatePerformanceMetric(obj,"Latency",techName,statsDevice,obj.pSimulationTime,nodeIdx(packetTypeIdx),"Average");

                    count = count+1;
                end

                % Store the PLR and throughput at the respective node indices
                obj.PacketLossRatio(nodeIdx,2) = packetLossRatio;
                obj.Throughput(nodeIdx,2) = throughput;
                obj.AveragePacketLatency(nodeIdx,2) = latency;
            end
        end

        function metricVal = calculateMetrics(obj,metricName,nodeID,linkIDNameValue,latencyMetric)
            %calculateMetrics Calculate the performance metrics for the specfied
            %performance metric and node ID

            % Validate the inputs
            narginchk(2,5)

            % Initialize
            metricVal = zeros(1,numel(nodeID));
            if nargin~=5
                latencyMetric = "Average";
            end

            % For loop for all the nodes specified
            for idx = 1:numel(nodeID)

                % Get the ID of the node
                idVal = nodeID(idx);

                % Find the index of the node in the performance viewer object
                nodeIdx = find(idVal==obj.pNodeTypeList(:,1));

                % Get the type of the node
                type = [obj.pNodeTypeList(nodeIdx,2)];
                if numel(type)>1
                    type = 5;
                end

                if isempty(type)
                    error(['Node with ID=' num2str(idVal) ' not found in the list of nodes added to this object.']);
                end

                % Get the statistics of the node specified
                switch type
                    case 1 % WLAN node
                        nodeIdxWLAN = find(idVal == [obj.WLANNodes(:).ID]);
                        statsNode = statistics(obj.WLANNodes(nodeIdxWLAN),"all");
                end

                % Calculate the performance metric for the node specified based on the
                % retreived statistics
                switch type
                    case 1
                        % Calculate link level performance metric
                        if nargin>3 && ~isempty(linkIDNameValue)
                            assert((nargin-3==1) && strcmpi(linkIDNameValue{1},"LinkID"), 'Invalid N/V pair');
                            linkID = linkIDNameValue{2};
                            assert((numel(linkID)==numel(nodeID)), 'Number of elements in LinkID must be the same as the number of elements in NodeID');
                            if ~isa(obj.WLANNodes(nodeIdxWLAN).DeviceConfig, "wlanMultilinkDeviceConfig") || numel(obj.WLANNodes(nodeIdxWLAN).DeviceConfig.LinkConfig) < linkID(idx)
                                error('Specified node ID must belong to an MLD node and the link ID must be less than or equal to number of links in the MLD');
                            end
                            if strcmp(metricName,"Throughput")
                                metricVal(idx) = ((statsNode.MAC(1).Link(linkID(idx)).TransmittedPayloadBytes)*8*1e-6)/obj.pSimulationTime;
                            else % PLR
                                metricVal(idx) = ((statsNode.MAC(1).Link(linkID(idx)).RetransmittedDataFrames)/statsNode.MAC(1).Link(linkID(idx)).TransmittedDataFrames);
                            end
                        else % Calculate node level performance metric
                            metricVal(idx) = calculatePerformanceMetric(obj,metricName,"WLAN",statsNode,obj.pSimulationTime,nodeIdx,latencyMetric);
                        end
                end
            end
        end

        function metricVal = calculatePerformanceMetric(obj,metricName,techName,stats,simulationTime,nodeIdx,latencyMetric)
            %calculatePerformanceMetric Calculate and return the metric value for
            %specified performance metric and technology

            node = obj.pNodes{nodeIdx};
            if strcmp(metricName,"PLR")
                metricVal = calculatePLR(obj,techName,stats);
            elseif strcmp(metricName,"Throughput")
                metricVal = calculateThroughput(obj,techName,stats,simulationTime);
            else
                if strcmp(latencyMetric,"Average")
                    metricVal = [obj.AveragePacketLatency(nodeIdx,2)];
                else
                    latencyVal = obj.PacketLatencyAll{nodeIdx,2};
                    if ~isempty(latencyVal)
                        if strcmp(latencyMetric,"P99")
                            metricVal = prctile(latencyVal,99);
                        elseif strcmp(latencyMetric,"P95")
                            metricVal = prctile(latencyVal,95);
                        end
                    else
                        metricVal = 0;
                    end
                end
            end
        end

        function packetLossRatio = calculatePLR(~,techName,stats)
            %calculatePLR Calculate the packet loss ratio based on the technology

            switch techName
                case "WLAN"
                    packetLossRatio = sum(([stats.MAC.RetransmittedDataFrames])/[stats.MAC.TransmittedDataFrames]);
            end
        end

        function throughput = calculateThroughput(~,techName,stats,simulationTime)
            %calculateThroughput Calculate the throughput based on the technology

            switch techName
                case "WLAN"
                    throughput = (sum([stats.MAC.TransmittedPayloadBytes])*8*1e-6)/simulationTime;
            end
        end
    end

    %% Figure Based Methods
    methods (Access=private)
        function [nodeNames,packetLossRatio,throughput,averageAppPacketLatency] = getMetrics(obj,nodes)
            %getMetrics Retreive the performance metrics for the nodes added to the
            %performance viewer for the plot

            % Initialize
            numNodes = numel(nodes);
            packetLossRatio = zeros(1,numNodes);
            throughput = zeros(1,numNodes);
            averageAppPacketLatency = zeros(1,numNodes);
            count = 1;
            nodeNames = "";

            % Get the performance of all the nodes
            for idx = 1:numNodes
                % Get the index at the packet latency for the node
                nodeIdx = find(nodes{idx}.ID==obj.pNodeTypeList(:,1));
                nodeNames(idx) = nodes{idx}.Name;

                deviceList = obj.pNodeTypeList(nodeIdx,3);
                for packetTypeIdx = 1:numel(deviceList)
                    % Retrieve the peformance metrics for the specified nodes
                    averageAppPacketLatency(count) = obj.AveragePacketLatency(nodeIdx(packetTypeIdx),2);
                    packetLossRatio(count) = obj.PacketLossRatio(nodeIdx(packetTypeIdx),2);
                    throughput(count) = obj.Throughput(nodeIdx(packetTypeIdx),2);
                    count = count+1;
                end
            end
        end

        function figHandle = plotBarGraph(obj,nodeNames,plr,throughput,latency,throughputUnits,numDevices,xlabelVal,customFigureHandle)
            %plotBarGraph Plots the bar graph

            % Create figure
            if isempty(customFigureHandle) % Empty figure handle (From Command line Use)
                figHandle = figure(Visible="off");
            else % Custom figure handle (From wirelessNetworkModeler app)
                figHandle = customFigureHandle;
            end

            % To ensure wirelessNetworkModeler app has control over visisbility without
            % affecting existing hPerformanceViewer operation, show the figure
            % only if it has not been hidden by the app.
            if ~obj.PerformanceViewerDisabled
                figHandle.Visible = "on";
            end

            matlab.graphics.internal.themes.figureUseDesktopTheme(figHandle);
            numNodes = numel(nodeNames);
            if numNodes>15
                xTickAngleVal = 90;
            else
                xTickAngleVal = 20;
            end

            % Calculate how the bars need to be grouped. Same node device bars will be
            % spaced nearer
            xValue = zeros(sum(numDevices),1);
            xValueCount = 0;
            for idx = 2:numel(numDevices)
                xValue(xValueCount+1:xValueCount+numDevices(idx),:) = (1:numDevices(idx))+sum(numDevices(1:idx-1));
                xValueCount = xValueCount+numDevices(idx);
                numDevices(idx) = numDevices(idx)+0.5;
            end

            % Plot the throughput
            s1 = subplot(3,1,1);
            bar(s1,xValue,throughput,"BarWidth",0.95);
            title("Throughput at Each Node");
            xlabel(xlabelVal);
            xticks(xValue)
            xtickangle(xTickAngleVal);
            xticklabels(nodeNames);
            ylabel('Throughput ('+ string(throughputUnits) + ')');

            % Plot the Packet Loss Ratio
            s2 = subplot(3,1,2);
            bar(s2,xValue,plr,"BarWidth",0.95);
            title("Packet Loss at Each Node");
            xlabel(xlabelVal);
            xticks(xValue)
            xtickangle(xTickAngleVal);
            xticklabels(nodeNames);
            ylabel("Packet Loss Ratio");

            % Plot the Average Application Packet Latency
            s3 = subplot(3,1,3);
            bar(s3,xValue,latency,"BarWidth",0.95);
            title("Average Packet Latency at Each Node");
            xlabel(xlabelVal);
            xticks(xValue)
            xtickangle(xTickAngleVal);
            xticklabels(nodeNames);
            ylabel("Latency (s)");
        end
    end
end
