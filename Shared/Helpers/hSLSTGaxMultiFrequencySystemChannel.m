%Copyright 2024-2025 The MathWorks, Inc
classdef hSLSTGaxMultiFrequencySystemChannel < handle
%hSLSTGaxMultiFrequencySystemChannel Create a system channel object
%
% CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES) returns a system
% channel object for an array of wlanNode objects, NODES. This assumes all
% nodes can transmit and receive and channels between the nodes are
% reciprocal.
%
% CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES,PROTLINKCHAN) uses the
% prototype channel for a link PROTLINKCHAN to create channels between all
% nodes. PROTLINKCHAN is a wlanTGaxChannel, wlanTGacChannel or
% wlanTGnChannel object.
%
% CHAN =
% hSLSTGaxMultiFrequencySystemChannel(...,ShadowFadingStandardDeviation=val)
% sets the shadow fading standard deviation in dB. The default is 0 dB (no
% shadow fading).
%
% CHAN = hSLSTGaxMultiFrequencySystemChannel(...,PathLossModel=model)
% sets the path loss model to 'free-space', 'residential', or 'enterprise'.
% The default is 'free-space').
%
%   hSLSTGaxMultiFrequencySystemChannel properties:
%
%   Channels   - Array of system channels; one channel per frequency.
%   ChannelFcn - Function handle to channel for all nodes and links in
%                the simulation
%
%   hSLSTGaxMultiFrequencySystemChannel methods:
%
%   getChannel - Returns the channel object for a signal and receiver
%   getLink    - Returns the link structure for a signal and receiver

%   Copyright 2022-2024 The MathWorks, Inc.

    properties
        %Channels Array of system channels; one channel per frequency
        %   The class of Channels depends on PHYAbstractionMethod specified
        %   in NODES:
        %    "none" - array of hSLSTGaxSystemChannel objects
        %    otherwise - array of hSLSTGaxAbtractSystemChannel objects
        Channels;
        %ChannelFcn Function handle to channel for all nodes and links in
        %the simulation
        ChannelFcn;
    end

    properties (Access=private)
        UseFullPHY = false;
    end

    methods
        function obj = hSLSTGaxMultiFrequencySystemChannel(nodes,varargin)
            % CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES) returns a
            % system channel object for an array of wlanNode objects, NODES.
            % This assumes all nodes can transmit and receive and channels
            % between the nodes are reciprocal.
            %
            % CHAN = hSLSTGaxMultiFrequencySystemChannel(NODES,PROTLINKCHAN)
            % uses the prototype channel for a link PROTLINKCHAN to create
            % channels between all nodes.
            %
            % CHAN =
            % hSLSTGaxMultiFrequencySystemChannel(...,ShadowFadingStandardDeviation=val)
            % sets the shadow fading standard deviation in dB. The default
            % is 0 dB (no shadow fading).

            % Set the base channel properties - this is used for all links Note
            % the number of transmit and receive antennas, and channel
            % bandwidth are sets from the node configuration.
            prototypeChannel = wlanTGaxChannel(...
                'DelayProfile','Model-D',...
                'TransmitReceiveDistance',15,...
                'ChannelFiltering',false,...
                'OutputDataType','single', ...
                'EnvironmentalSpeed',0); % 0.0890
            nvpairStart = 1;
            if nargin>1
                if isa(varargin{1}, 'wlan.internal.ChannelBase')
                    prototypeChannel = varargin{1};
                    nvpairStart = 2;
                end
            end
            numNodes = numel(nodes);
            % Select type of channel model depending on PHY abstraction
            % used
            obj.UseFullPHY = nodes(1).PHYAbstractionMethod == "none";

            % Create vectors of parameters for all devices in all nodes
            freqAllDevices = [];                 % Center frequency
            bwAllDevices = [];                   % Channel bandwidth (Hz)
            interferenceModelingAllDevices = []; % Interference modeling
            nodeNumAllDevices = [];              % Node number (1, 2, ..., numNodes)
            nodeIDsAllDevices = [];              % Node identifiers
            deviceINumAllDevices = [];           % Number of device in each nodes (1, ..., numDevices)
            numAntsAllDevices = [];              % Number of antennas
            for n = 1:numNodes
                assert((nodes(n).PHYAbstractionMethod=="none") == obj.UseFullPHY,'All nodes must be configured to use the same PHY abstraction method')
                devCfg = getDeviceConfig(nodes(n));
                for d = 1:numel(devCfg)
                    freqAllDevices = [freqAllDevices wlanChannelFrequency(devCfg(d).BandAndChannel(2),devCfg(d).BandAndChannel(1))]; %#ok<*AGROW>
                    bwAllDevices = [bwAllDevices devCfg(d).ChannelBandwidth];
                    nodeNumAllDevices = [nodeNumAllDevices n];
                    nodeIDsAllDevices = [nodeIDsAllDevices nodes(n).ID];
                    numAntsAllDevices = [numAntsAllDevices devCfg(d).NumTransmitAntennas];
                    deviceINumAllDevices = [deviceINumAllDevices d];
                    if isa(devCfg(d),'wlanLinkConfig')
                        % Only co-channel modeling is supported
                        interferenceModelingAllDevices = [interferenceModelingAllDevices "co-channel"];
                    else
                        interferenceModelingAllDevices = [interferenceModelingAllDevices devCfg(d).InterferenceModeling];
                    end
                end
            end

            % Get all combinations of devices, i.e. all possible links.
            % Each row contains two indices, one for each device making up
            % a channel.
            linkDeviceInd = nchoosek(1:numel(freqAllDevices),2);

            % Remove combinations of devices which are on the same node
            isSameNode = (nodeNumAllDevices(linkDeviceInd(:,1))==nodeNumAllDevices(linkDeviceInd(:,2)))';
            linkDeviceInd = linkDeviceInd(~isSameNode,:);

            % Get the channel bandwidth of all devices, for all combinations
            bwCombinations = bwAllDevices(linkDeviceInd);

            % Get the frequencies of all devices combinations
            freqCombinations = freqAllDevices(linkDeviceInd);

            % Calculate the start and end frequencies of the channels
            % required for each device, for all combinations
            rxStartFreq = freqCombinations-bwCombinations/2;
            rxEndFreq = freqCombinations+bwCombinations/2;

            % Get device interference modeling, for all combinations
            % All devices must use the same interference modeling
            if numel(unique(interferenceModelingAllDevices))>1
                error('All devices must use the same interference mode')
            end

            % Determine which links to model. For each pair of devices
            % generate a packet from the first device to the second to
            % determine where there is a frequency overlap and it should be
            % modeled (this can be co-channel, overlapping, or adjacent).
            packet = wirelessnetwork.internal.wirelessPacket;
            packet.Type = 1; % WLAN
            packet.Abstraction = true; % Set to avoid validation
            packet.Metadata.OversamplingFactor = 1.125; % Set to avoid validation
            modelChannel = false(height(linkDeviceInd),1);
            for i = 1:height(linkDeviceInd)
                packet.CenterFrequency = freqCombinations(i,1);
                packet.Bandwidth = bwCombinations(i,1);
                rxNodeNum = nodeNumAllDevices(linkDeviceInd(i,2));
                deviceNum = deviceINumAllDevices(linkDeviceInd(i,2));
                modelChannel(i) = wlan.internal.sls.isFrequencyOverlapping(nodes(rxNodeNum),packet,deviceNum);
            end

            linkDeviceIndToModel = linkDeviceInd(modelChannel,:); % Device index for each channel
            linkNodeIDs = nodeIDsAllDevices(linkDeviceIndToModel);

            % The combined span of the bandwidth of two devices is used to
            % model the channel between them. Therefore set the channel
            % bandwidth to this total span.
            channelStartFreq = min(rxStartFreq(modelChannel,:),[],2);
            channelStopFreq = max(rxEndFreq(modelChannel,:),[],2);
            overallChannelBandwidth = channelStopFreq-channelStartFreq;

            % Calculate the center frequencies of each channel, given the
            % span of the required bandwidth.
            centerFrequencies = (channelStartFreq+channelStopFreq)./2;

            % Get the index of the available channel bandwidth which the
            % overall channel bandwidth will fit in. If it exceeds the
            % maximum channel bandwidth string, then use the largest. Note
            % max() returns the first element in a row if the values are
            % the same - which is what we need.
            availableBWs = [20 40 80 160 320 Inf]*1e6;
            availableCBWs = ["CBW20" "CBW40" "CBW80" "CBW160" "CBW320" "CBW320"];
            [~,bwIndex] = max(availableBWs>=overallChannelBandwidth,[],2);
            channelBandwidths = availableCBWs(bwIndex);

            % Combine channels with the same center frequencies
            uniqueCenterFrequencies = unique(centerFrequencies);
            numChannels = numel(uniqueCenterFrequencies);

            % Create a channel manager for each unique channel center
            % frequency
            if obj.UseFullPHY
                obj.Channels = hSLSTGaxSystemChannel.empty(1,0);
            else
                obj.Channels = hSLSTGaxAbstractSystemChannel.empty(1,0);
            end
            for i = 1:numChannels
                % Create a channel between all devices operating within the
                % same channel. This includes adjacent/overlapping channels
                % if enabled.

                % Set the bandwidth and frequency of the channel. For the
                % channel, get the maximum bandwidth of all links using
                % that channel.
                isFreq = centerFrequencies==uniqueCenterFrequencies(i);
                [maxBW,maxBWIdx] = max(overallChannelBandwidth(isFreq));
                linkCBWsWithinThisChannel = channelBandwidths(isFreq);
                prototypeChannel.SampleRate = maxBW; % Used to create the path filters used in abstract PHY
                prototypeChannel.ChannelBandwidth = linkCBWsWithinThisChannel(maxBWIdx);
                prototypeChannel.CarrierFrequency = uniqueCenterFrequencies(i);

                % Get the node IDs of the pairs of nodes in this channel.
                linkNodeIDsThisChannel = linkNodeIDs(isFreq,:);

                % Create numAntennasChannel, which contiains the number of
                % antennas for each device used in this channel.
                devicesInChannel = unique(linkDeviceIndToModel(isFreq,:));
                numAntennasChannel = numAntsAllDevices(devicesInChannel);

                if obj.UseFullPHY
                     obj.Channels(i) = hSLSTGaxSystemChannel(prototypeChannel,numAntennasChannel,'ChannelIndicesLUT',linkNodeIDsThisChannel,varargin{nvpairStart:end});
                else
                    obj.Channels(i) = hSLSTGaxAbstractSystemChannel(prototypeChannel,numAntennasChannel,'ChannelIndicesLUT',linkNodeIDsThisChannel,varargin{nvpairStart:end});
                end
            end

            % Function handle to return impaired signal
            obj.ChannelFcn = @(rxInfo,signal)impairSignal(obj,signal,rxInfo);
        end
    end

    methods
        function channel = getChannel(obj,sig,rxInfo)
            % Returns the system channel object for a link between
            % signal SIG and receiver info RXINFO 

            % Get all channels between the transmitter and receiver - there
            % may be multiple devices connected between a transmitter and
            % receiver node, and therefore multiple channels.
            candidateIndices = [];
            for i = 1:numel(obj.Channels)
                if any([obj.Channels(i).Links.Node1]==sig.TransmitterID & [obj.Channels(i).Links.Node2]==rxInfo.ID | ...
                    [obj.Channels(i).Links.Node2]==sig.TransmitterID & [obj.Channels(i).Links.Node1]==rxInfo.ID)
                    candidateIndices = [candidateIndices i];
                end
            end

            if isempty(candidateIndices)
                error('hSLSTGaxSystemChannelBase:NoChannelExists','Channel does not exist between node #%d and #%d.',sig.TransmitterID,rxInfo.ID)
            end

            % Select the channel with the closest center frequency to the
            % signal as the desired channel
            candidateChannels = [obj.Channels(candidateIndices)];
            [~,idx] = min(abs(sig.CenterFrequency-[candidateChannels.CenterFrequency]));
            channel = candidateChannels(idx);
        end

        function link = getLink(obj,sig,rxInfo)
            % Returns the link structure between signal SIG the receiver
            % info RXINFO

            % Get system channel
            channel = getChannel(obj,sig,rxInfo);

            % Extract channel information
            link = getLink(channel,sig.TransmitterID,rxInfo.ID);
        end
    end

    methods (Access=private)
        function [sig,varargout] = impairSignal(obj,sig,rxInfo)
            %impairSignal Apply path loss, log-normal shadow fading, and
            %frequency selective fading to the packet and update relevant
            %fields of the output data.

            % Get system channel between devices
            channel = getChannel(obj,sig,rxInfo);

            % Model path loss
            sig = pathLoss(obj,channel,sig,rxInfo);

            % Model shadow fading
            sig = shadowFading(obj,channel,sig,rxInfo);

            % Model frequency-selective fading
            if obj.UseFullPHY
               nargs = nargout;
               [sig,varargout{1:nargs-1}] = applyChannelToSignalStructure(channel,sig,rxInfo);
            else
                sig.Metadata.Channel = getChannelStatistics(channel,sig,rxInfo);
            end
        end

        function sig = pathLoss(obj, channel, sig, rxInfo)
            %pathLoss Apply path loss to the packet and update relevant fields
            %of the output data.

            pl = getPathLoss(channel,sig,rxInfo); % dB

            % Apply path loss on the power of the packet
            sig.Power = sig.Power - pl;

            if obj.UseFullPHY
                % Scale signal by path loss
                sig.Data = sig.Data*db2mag(-pl);
            end
        end

        function sig = shadowFading(obj, channel, sig, rxInfo)
            %shadowFading Apply log-normal shadow fading to the packet and
            %update relevant fields of the output data.

            txIdx = sig.TransmitterID;
            rxIdx = rxInfo.ID;
            l = getShadowFading(channel,txIdx,rxIdx); % dB
            % Apply shadow fading to the power of the packet
            sig.Power = sig.Power + l; % power in dBm

            if obj.UseFullPHY
                % Scale signal by shadow fading
                sig.Data = sig.Data*db2mag(l);
            end
        end
    end
end

function devCfg = getDeviceConfig(node)
    %getDeviceConfig Returns the object holding MAC/PHY configuration
    %
    %   DEVCFG = getDeviceConfig(NODE) returns the object that holds the
    %   MAC/PHY configuration.
    %
    %   DEVCFG is an object of type wlanDeviceConfig if the input is a non-MLD
    %   node and it is an object of type wlanLinkConfig if the input is an MLD
    %   node.
    %
    %   NODE is an object of type wlanNode.

    if isa(node.DeviceConfig, "wlanMultilinkDeviceConfig")
        devCfg = node.DeviceConfig.LinkConfig;
        if strcmp(node.DeviceConfig.Mode, "STA") && isprop(node.DeviceConfig,'EnhancedMultilinkMode') && strcmp(node.DeviceConfig.EnhancedMultilinkMode, "EMLSR")
            % EMLSR case. For each device link set the number of antennas
            % to the sum for all devices. This will generate a channel for
            % each link (band) using the maximum number of antennas
            % possible. When we send data though the channel we will only
            % use the number of antennas appropriate at that time.
            totalNumAntennas = sum([devCfg.NumTransmitAntennas]);
            for i = 1:numel(devCfg)
                devCfg(i).NumTransmitAntennas = totalNumAntennas;
            end
        end
    else
        devCfg = node.DeviceConfig;
    end
end