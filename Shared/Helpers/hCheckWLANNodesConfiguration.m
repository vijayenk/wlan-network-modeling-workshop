%Copyright 2024-2025 The MathWorks, Inc
function hCheckWLANNodesConfiguration(wlanNodes)
%hCheckWLANNodesConfiguration Checks if WLAN node properties are configured
%correctly for all the input WLAN nodes
%
%   hCheckWLANNodesConfiguration(WLANNODES) checks if all the nodes have
%   the same values for MACFrameAbstraction and PHYAbstractionMethod
%   properties. It also checks if all the WLAN devices operating on the
%   same channel frequency have the same channel bandwidth. Additionally,
%   it ensures all the WLAN devices operating in the simulation are
%   configured with the same values of MPDUAggregationLimit,
%   NumTransmitAntennas, and NumSpaceTimeStreams.
%
%   WLANNODES is an array or cell array of objects of type <a href="matlab:help('wlanNode')">wlanNode</a>.

%   Copyright 2022-2024 The MathWorks, Inc.

% Convert cell array input
if iscell(wlanNodes)
    wlanNodes = [wlanNodes{:}];
end

numNodes = numel(wlanNodes);
devCfg = getDeviceConfig(wlanNodes);

devices = {};
links = {};
isEMLSRLink = {};
for nodeID = 1:numNodes
    if isa(devCfg{nodeID},"wlanDeviceConfig")
        devices{end+1} = devCfg{nodeID}; %#ok<*AGROW>
    else
        links{end+1} = devCfg{nodeID};
        isEMLSRLink{end+1} = repmat(strcmp(wlanNodes(nodeID).DeviceConfig.EnhancedMultilinkMode, "EMLSR"), ...
            1,numel(devCfg{nodeID}));
    end
end
devices = [devices{:}];
links = [links{:}];
isEMLSRLink = [isEMLSRLink{:}];
numDevices = numel(devices) + numel(links);

freqBWPairs = zeros(2,numDevices);
deviceCount = 1;
aciModeled = false;
cbwGreaterThan20MHz = false;
for nodeID = 1:numNodes
    if nodeID>1
        if wlanNodes(nodeID).MACFrameAbstraction ~= wlanNodes(1).MACFrameAbstraction
            error("hCheckWLANNodesConfiguration:MACFrameAbstractionMismatch","All nodes must have the same MACFrameAbstraction value.");
        end

        if ~strcmp(wlanNodes(nodeID).PHYAbstractionMethod,wlanNodes(1).PHYAbstractionMethod)
            error("hCheckWLANNodesConfiguration:PHYAbstractionMethodMismatch","All nodes must have the same PHYAbstractionMethod.");
        end
    end

    endIndex = numel([devCfg{nodeID}(:)])-1;
    aciModeled = aciModeled || any(~strcmp("co-channel",[devCfg{nodeID}(:).InterferenceModeling]));
    cbwGreaterThan20MHz = cbwGreaterThan20MHz || any([devCfg{nodeID}(:).ChannelBandwidth] > 20e6);
    freqBWPairs(1,deviceCount:deviceCount+endIndex) = [devCfg{nodeID}(:).ChannelFrequency];
    freqBWPairs(2,deviceCount:deviceCount+endIndex) = [devCfg{nodeID}(:).ChannelBandwidth];
    deviceCount = deviceCount+endIndex+1;
end

if aciModeled && cbwGreaterThan20MHz
    error("hCheckWLANNodesConfiguration:BandwidthACIIncompatible","If adjacent channel interference is modeled in any node, all nodes in the network must be configured with 20 MHz channel bandwidth.");
end

freqBWPairs = sortrows(freqBWPairs.',[1 2]);
uniqueFreqBWPairs = unique(freqBWPairs,'rows');

for freqID = 1:numel(uniqueFreqBWPairs(:,1))-1
    if uniqueFreqBWPairs(freqID,:) == uniqueFreqBWPairs(freqID+1,:)
        continue;
    else
        if uniqueFreqBWPairs(freqID,1) ~= uniqueFreqBWPairs(freqID+1,1) %Check for frequency mismatch
            continue; %Continue since there can be multiple frequencies
        elseif uniqueFreqBWPairs(freqID,2) ~= uniqueFreqBWPairs(freqID+1,2) % Check for bandwidth mismatch
            error("hCheckWLANNodesConfiguration:BandwidthMismatch","Nodes operating in the same channel frequency must have the same channel bandwidth.");
        end
    end
end

% Check MPDUAggregationLimit and NumTransmitAntennas
checkConfig({devices, links}, isEMLSRLink);
end

function devCfg = getDeviceConfig(node)
%getDeviceConfig Returns the object(s) holding MAC/PHY configuration
%
%   DEVCFG = getDeviceConfig(NODE) returns the objects that hold the
%   MAC/PHY configuration.
%
%   DEVCFG is a cell array of objects of type wlanDeviceConfig and/or
%   wlanLinkConfig, depending upon if the input is an array of non-MLD
%   and/or MLD nodes.
%
%   NODE is an object of type wlanNode.

    devCfg = cell(1, numel(node));
    for idx = 1:numel(node)
        if isa(node(idx).DeviceConfig, 'wlanMultilinkDeviceConfig')
            devCfg{idx} = node(idx).DeviceConfig.LinkConfig;
        else
            devCfg{idx} = node(idx).DeviceConfig;
        end
    end
end

function checkConfig(configInput, isEMLSRLink)
%checkConfig Checks the input object(s) holding MAC/PHY configuration
%
%   checkConfig(CONFIGINPUT, ISEMLSRLINK) checks if the input configuration
%   objects use the same MPDUAggregationLimit and NumTransmitAntennas.
%
%   CONFIGINPUT is a cell array with two elements. First element is an
%   array of wlanDeviceConfig objects in simulation. Second element is an
%   array of wlanLinkConfig objects in simulation.
%
%   ISEMLSRLINK is a flag indicating that the link is operating in EMLSR
%   mode. It is a logical array of size 1-by-N, where N is the number of
%   wlanLinkConfig objects in simulation.

devices = configInput{1};
links = configInput{2};
numDevices = numel(devices);
numLinks = numel(links);

% Get the first configuration object
if numDevices
    firstConfig = devices(1);
else
    firstConfig = links(1);
end

for configIdx = 1:numDevices+numLinks
    % Compare the other configuration objects with first one
    if configIdx>1
        isEMLSRConfig = false;
        if configIdx <= numDevices
            config = devices(configIdx);
        else
            linkIdx = configIdx-numDevices;
            config = links(linkIdx);
            isEMLSRConfig = isEMLSRLink(linkIdx);
        end

        if config.MPDUAggregationLimit ~= firstConfig.MPDUAggregationLimit
            if numDevices && numLinks % Both non-MLDs and MLDs are present in simulation
                error("hCheckWLANNodesConfiguration:MPDUAggregationLimitMismatchMixed","All non-MLDs and all links in MLDs must have the same value of MPDUAggregationLimit.");
            elseif ~numLinks % Only non-MLDs are present in simulation
                error("hCheckWLANNodesConfiguration:MPDUAggregationLimitMismatchNonMLD","All devices must have the same value of MPDUAggregationLimit.");
            else % Only MLDs are present in simulation
                error("hCheckWLANNodesConfiguration:MPDUAggregationLimitMismatchMLD","All links must have the same value of MPDUAggregationLimit.");
            end
        end

        if ~isEMLSRConfig % For EMLSR STAs, the check is done during associateStations call
            if config.NumTransmitAntennas ~= firstConfig.NumTransmitAntennas
                if numDevices && numLinks % Both non-MLDs and MLDs are present in simulation
                    error("hCheckWLANNodesConfiguration:NumTransmitAntennasMismatchMixed","All non-MLDs and all STR links in MLDs must have the same value of NumTransmitAntennas.");
                elseif ~numLinks % Only non-MLDs are present in simulation
                    error("hCheckWLANNodesConfiguration:NumTransmitAntennasMismatchNonMLD","All devices must have the same value of NumTransmitAntennas.");
                else % Only MLDs are present in simulation
                    error("hCheckWLANNodesConfiguration:NumTransmitAntennasMismatchMLD","All STR links must have the same value of NumTransmitAntennas.");
                end
            end
        end
    end
end
end
