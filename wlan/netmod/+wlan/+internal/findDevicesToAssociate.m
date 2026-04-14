function [apDeviceIndices, staDeviceIndices, staPrimary20Indices, commonBandwidths] ...
    = findDevicesToAssociate(apNode, associatedSTAs, associationNVParams)
%findDevicesToAssociate Finds device IDs to associate at AP and STAs
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [APDEVICEINDICES, STADEVICEINDICES, STAPRIMARY20INDICES,
%   COMMONBANDWIDTHS] = findDevicesToAssociate(APNODE, ASSOCIATEDSTAS,
%   ASSOCIATIONNVPARAMS) finds the device/link indices at AP and given
%   stations on which association happens and returns them. Additionally,
%   it returns the index of primary 20 MHz subchannel at STA based on the
%   primary 20 MHz subchannel configured at AP, and the bandwidth to be
%   used for communication between AP and given STAs.
%
%   APDEVICEINDICES is the indices of device/links on which AP associates
%   to given stations. In case of association between non-MLD AP/non-MLD
%   STA or MLD AP/non-MLD STA, one element of APDEVICEINDICES corresponds
%   to a given STA, indicating association on one device/link. In case of
%   association between MLD AP/MLD STA, multiple elements of
%   APDEVICEINDICES corresponds to given STA, indicating association on
%   multiple links.
%
%   STADEVICEINDICES is the indices of device/links on which a given STA
%   associates to the AP. Size of this output argument is same as
%   APDEVICEINDICES.
%
%   STAPRIMARY20INDICES is the indices of primary 20 MHz subchannel at STA
%   based on the primary 20 MHz configured at AP device/link. Size of this
%   output argument is same as APDEVICEINDICES.
%
%   COMMONBANDWIDTHS is the bandwidths to use for communication between AP
%   device/link and STA device/link. Size of this output argument is same
%   as APDEVICEINDICES. Units are in Hz.
%
%   APNODE is the AP node.
%
%   ASSOCIATEDSTAS is the list of STAs to associate.
%
%   ASSOCIATIONNVPARAMS is a structure with fields BandAndChannel and
%   FullBufferTraffic.

%   Copyright 2024-2025 The MathWorks, Inc.

numSTA = numel(associatedSTAs);
numLinks = 1;
if apNode.IsMLDNode
    numLinks = numel(apNode.DeviceConfig.LinkConfig);
end
apDeviceIndices = zeros(1, 0);
staDeviceIndices = zeros(1, 0);
staPrimary20Indices = zeros(1, 0);
commonBandwidths = zeros(1, 0);
% Correspondig indices in output for each AP/STA pair
outputIdx = 0;

if isempty(associationNVParams.BandAndChannel)
    for staIdx = 1:numSTA
        staNode = associatedSTAs(staIdx);
        if ~staNode.IsMLDNode % MLD/non-MLD AP and non-MLD STA
            % STA must have only one device
            assert(isscalar(staNode.ReceiveFrequency))
            outputIdx = outputIdx(end) + 1; % Only one association

        else % MLD AP and MLD STA
            outputIdx = outputIdx(end)+1:outputIdx(end)+numLinks; % Multiple associations on all links
        end

        [staPrimary20Indices(outputIdx), apDeviceIndices(outputIdx), ...
            staDeviceIndices(outputIdx), commonBandwidths(outputIdx)] = primary20ForSTA(apNode, staNode);
    end
else
    % Name-value pair check
    bandAndChannel = associationNVParams.BandAndChannel;
    if apNode.IsMLDNode
        isSTAMLD = associatedSTAs(1).IsMLDNode;

        if isSTAMLD % MLD AP and MLD STA
            % Check whether all associated STAs are MLDs
            if ~all([associatedSTAs(:).IsMLDNode])
                error(message('wlan:wlanNode:ExpectedSameTypeSTAs'))
            end
            % Get the frequencies from provided bands and channels
            numBandsAndChannels = size(bandAndChannel, 1);
            frequencies = wlanChannelFrequency(bandAndChannel(:, 2), bandAndChannel(:, 1));
            % Check if the provided bands and channels are same as the ones configured
            % in AP
            if (numBandsAndChannels ~= numel(apNode.ReceiveFrequency)) || ~all(ismember(frequencies, apNode.ReceiveFrequency))
                error(message('wlan:wlanNode:MLDBSSConfigureInvalidBandAndChannel'))
            end
            apDeviceIdx = 1:numLinks;

        else % MLD AP and non-MLD STA
            % Check whether all associated STAs are non-MLDs
            if any([associatedSTAs(:).IsMLDNode])
                error(message('wlan:wlanNode:ExpectedSameTypeSTAs'))
            end
        end
    else % Non-MLD AP
        % Currently, association of only non-MLD STAs is allowed to non-MLD AP
        isSTAMLD = false;
    end

    if ~isSTAMLD % Non-MLD STA
        % Validate the frequency
        if numel(bandAndChannel) > 2
            error(message('wlan:wlanNode:BSSConfigureInvalidBandAndChannel'))
        end
        frequency = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));
        apDeviceIdx = find(apNode.ReceiveFrequency == frequency, 1);
        % Given frequency not found in AP configuration
        if isempty(apDeviceIdx)
            error(message('wlan:wlanNode:BSSConfigureChannelNotFound1', apNode.Name, mat2str(bandAndChannel(1)), bandAndChannel(2)))
        end
        if apNode.MAC(apDeviceIdx).IsMeshDevice
            error(message( 'wlan:wlanNode:BSSConfigureMeshConflict1', apNode.Name, mat2str(bandAndChannel(1)), bandAndChannel(2)))
        end
    end

    for staIdx = 1:numSTA
        staNode = associatedSTAs(staIdx);
        if isSTAMLD
            % Multiple associations between AP MLD and STA MLD
            outputIdx = outputIdx(end)+1:outputIdx(end)+numLinks;
        else
            outputIdx = outputIdx(end) + 1; % Only one association
        end
        [staPrimary20Indices(outputIdx), apDeviceIndices(outputIdx), ...
            staDeviceIndices(outputIdx), commonBandwidths(outputIdx)] = primary20ForSTA(apNode, staNode, apDeviceIdx);
    end
end
end

function [primary20IdxAtSTA, apDeviceIdx, staDeviceIdx, commonBandwidth] = primary20ForSTA(apNode, staNode, apDeviceIndices)
%primary20ForSTA Checks whether primary 20 MHz of any AP device is
%supported by STA
%
%   [PRIMARY20IDXATSTA, APDEVICEIDX, STADEVICEIDX, COMMONBANDWIDTH] =
%   primary20ForSTA(APNODE, STANODE) checks whether primary 20 MHz of any
%   AP device/link is supported by STA device/link. This signature is used
%   when BandAndChannel input is not provided in associateStations method.
%
%   PRIMARY20IDXATSTA is the the primary 20 MHz channel index at STA. If
%   STA is non-MLD, the value is a scalar, indicating one association. If
%   STA is MLD, the value is a vector indicating association on all links.
%
%   APDEVICEIDX is the index/indices of AP device/links. Size of this
%   argument is same as PRIMARY20IDXATSTA.
%
%   STADEVICEIDX is the index/indices of STA device/links. Size of this
%   argument is same as PRIMARY20IDXATSTA.
%
%   COMMONBANDWIDTH is the bandwidth to use for communication between AP
%   and STA device/link. Size of this argument is same as
%   PRIMARY20IDXATSTA. Units are in Hz.
%
%   [PRIMARY20IDXATSTA, APDEVICEIDX, STADEVICEIDX, COMMONBANDWIDTH] =
%   primary20ForSTA(APNODE, STANODE, APDEVICEINDICES) checks whether
%   primary 20 MHz of any of the devices/links specified by APDEVICEINDICES
%   in AP node is supported by STA. This signature is used when
%   BandAndChannel input is provided in associateStations method.

isMultilinkAP = false;
isMultibandAP = false;

if apNode.IsMLDNode
    apCfg = apNode.DeviceConfig.LinkConfig;
    isMultilinkAP = true;
else
    apCfg = apNode.DeviceConfig;
    isMultibandAP = numel(apCfg) > 1;
end

if staNode.IsMLDNode
    staCfg = staNode.DeviceConfig.LinkConfig;
    numSTADevices = numel(staCfg);
else
    staCfg = staNode.DeviceConfig;
    numSTADevices = 1;
end

% Initialize outputs
apDeviceIdx = zeros(numSTADevices, 1);
staDeviceIdx = zeros(numSTADevices, 1);
primary20IdxAtSTA = zeros(numSTADevices, 1);
commonBandwidth = zeros(numSTADevices, 1);
if nargin == 2
    numAPDevices = apNode.NumDevices;
    apDeviceIndices = 1:apNode.NumDevices;
else % nargin == 3
    numAPDevices = numel(apDeviceIndices);
end

% Get the starting operating frequency of AP devices/links
startFreqsAP = apNode.ReceiveFrequency-([apCfg(:).ChannelBandwidth]/2);
% Get the primary 20 MHz of all devices/links in AP
primaryChannelIndices = getPrimaryChannelIndex(apNode, apCfg);
startFreqsPrimary20MHzAP = startFreqsAP + (primaryChannelIndices-1)*20e6;

% Iterate over STA devices/links. In case of non-MLD STA, numSTADevices is
% 1 and in case of MLD STA, numSTADevices is number of links.
for staIdx = 1:numSTADevices
    % Get the starting frequency of STA device/link
    startFreqSTA = staNode.ReceiveFrequency(staIdx)-(staCfg(staIdx).ChannelBandwidth/2);
    % Get the starting frequencies of 20 MHz subchannels of STA
    num20MHzSubchannelsSTA = staCfg(staIdx).ChannelBandwidth/20e6;
    startFreq20MHzSubchannelSTA = startFreqSTA + ((1:num20MHzSubchannelsSTA)-1)*20e6;

    tempAPDeviceIdx = 0;

    for apIdx = 1:numAPDevices % Iterate over number of devices/links in AP node
        isAPDevice = true;
        if ~apNode.IsMLDNode
            isAPDevice = strcmp(apCfg(apDeviceIndices(apIdx)).Mode, "AP");
        end

        if isAPDevice
            % Check if the primary 20 MHz at AP is supported in STA's operating
            % frequency
            primary20Idx=find(startFreqsPrimary20MHzAP(apDeviceIndices(apIdx))==startFreq20MHzSubchannelSTA, 1);
            if ~isempty(primary20Idx)
                % Check if more than one AP device/link primary 20 coincides with STA's 20
                % MHz subchannels
                if isMultibandAP && tempAPDeviceIdx
                    error(message('wlan:wlanNode:PrimaryChannelConflict', apNode.Name, staNode.Name, 'AP device')) % STA non-MLD
                end
                if isMultilinkAP && ~staNode.IsMLDNode && tempAPDeviceIdx
                    error(message('wlan:wlanNode:PrimaryChannelConflict', apNode.Name, staNode.Name, 'AP link')) % STA non-MLD
                end
                if isMultilinkAP && staNode.IsMLDNode && tempAPDeviceIdx
                    error(message('wlan:wlanNode:PrimaryChannelConflict1MLD', apNode.Name, staNode.Name, ... % STA MLD
                    mat2str(staCfg(staIdx).BandAndChannel)))
                end

                % Store the AP device/link index on which the cuurent STA device/link is
                % associated
                apDeviceIdx(staIdx) = apDeviceIndices(apIdx);
                staDeviceIdx(staIdx) = staIdx;
                primary20IdxAtSTA(staIdx) = primary20Idx;
                % Store the AP device/link index in a temporary variable
                tempAPDeviceIdx = apDeviceIndices(apIdx);

                % Determine maximum bandwidth for communication between AP and STA
                if startFreqsAP(tempAPDeviceIdx) == startFreqSTA
                    commonBandwidth(staIdx) = min(staCfg(staIdx).ChannelBandwidth, apCfg(tempAPDeviceIdx).ChannelBandwidth);
                else
                    % Find the overlapping bandwidth between AP and STA
                    minEndFreq = min(startFreqsAP(tempAPDeviceIdx)+apCfg(tempAPDeviceIdx).ChannelBandwidth, ...
                        startFreqSTA+staCfg(staIdx).ChannelBandwidth);
                    maxStartFreq = max(startFreqsAP(tempAPDeviceIdx), startFreqSTA);
                    commonBandwidth(staIdx) = minEndFreq - maxStartFreq;
                end
            end
        end
    end

    % No AP device/link primary channel coincides with STA's 20 MHz subchannels
    if(~apDeviceIdx(staIdx))
        [possibleBandAndChannels, possibleBW] = getPossibleBandAndChannel(apNode, staCfg(staIdx), startFreqsAP, startFreqsPrimary20MHzAP, apDeviceIndices);
        serializedInput = cellfun(@mat2str, possibleBandAndChannels, 'UniformOutput', false);
        inputString = [serializedInput{:}];
        newString = replace(inputString, '][', '] or [');

        % Single device in AP node
        if ~isMultibandAP && ~isMultilinkAP
            error(message('wlan:wlanNode:NoPrimaryOverlapSinglebandAP', apNode.Name, staNode.Name, newString, mat2str(possibleBW)))
        end
        % Multiple devices/links in AP node
        bwString = mat2str(possibleBW);
        if numel(possibleBW) > 1
            bwString = replace(bwString, ' ', ' or ');
            bwString = erase(bwString, ["[", "]"]);
        end
        if nargin == 2
            if isMultibandAP
                error(message('wlan:wlanNode:NoPrimaryOverlap1NonMLDSTA', apNode.Name, staNode.Name, newString, bwString, 'AP device')) % STA non-MLD
            end
            if isMultilinkAP && ~staNode.IsMLDNode
                error(message('wlan:wlanNode:NoPrimaryOverlap1NonMLDSTA', apNode.Name, staNode.Name, newString, bwString, 'AP link')) % STA non-MLD
            end

        else % nargin == 3
            if isMultibandAP
                error(message('wlan:wlanNode:NoPrimaryOverlap2NonMLDSTA', apNode.Name, staNode.Name, newString, bwString, 'AP device')) % STA non-MLD
            end
            if isMultilinkAP && ~staNode.IsMLDNode
                error(message('wlan:wlanNode:NoPrimaryOverlap2NonMLDSTA', apNode.Name, staNode.Name, newString, bwString, 'AP link')) % STA non-MLD
            end
        end
        if isMultilinkAP && staNode.IsMLDNode
            error(message('wlan:wlanNode:NoPrimaryOverlap1MLDSTA', apNode.Name, staNode.Name, newString, bwString, ... % STA MLD
            mat2str(staCfg(staIdx).BandAndChannel)))
        end
    end

    if isMultilinkAP && staNode.IsMLDNode
        % One AP link's primary channel is supported by more than one STA link
        if staIdx > 1 && any(apDeviceIdx(staIdx) == apDeviceIdx(1:staIdx-1))
            error(message('wlan:wlanNode:PrimaryChannelConflict2MLD', apNode.Name, staNode.Name))
        end
    end
end
end

function [possibleBandAndChannels, possibleBW] = getPossibleBandAndChannel(apNode, staCfg, startingFreqAP, primary20MHzStartingFreq, apDeviceIndices)
% Suggest possible band and channel at STA when it does not support primary
% channel of any device/link in AP

possibleBandAndChannels = zeros(numel(apDeviceIndices), 2);
possibleBW = zeros(1, numel(apDeviceIndices));
staBandwidth = staCfg.ChannelBandwidth;
outputIdx = 0;

for idx = 1:numel(apDeviceIndices)
    apDevIdx = apDeviceIndices(idx);
    if apNode.IsMLDNode
        apCfg = apNode.DeviceConfig.LinkConfig(apDevIdx);
        isAPDevice = true;
    else
        apCfg = apNode.DeviceConfig(apDevIdx);
        isAPDevice = strcmp(apCfg.Mode,"AP");
    end
    if isAPDevice
        apBandwidth = apCfg.ChannelBandwidth;
        apBand = apCfg.BandAndChannel(1);
        apChannel = apCfg.BandAndChannel(2);
        outputIdx = outputIdx + 1;

        if staBandwidth == apBandwidth
            % Suggest the STA to be configured with same band and channel as AP
            possibleBandAndChannels(outputIdx, :) = apCfg.BandAndChannel;
            possibleBW(outputIdx) = staBandwidth;

        elseif staBandwidth < apBandwidth
            % When STA bandwidth is less than AP bandwidth, suggest the STA to be
            % configured either in primary 20, 40, 80 or 160 channel of AP. For
            % example, if STA bandwidth is 40 MHz and AP bandwidth is 80 MHz, suggest
            % STA to be configured in primary 40 MHz of AP.

            primary20Idx = getPrimaryChannelIndex(apNode, apCfg);
            if staBandwidth == 20e6
                % Suggest the STA band and channel to be same as primary 20 MHz channel of AP
                possibleCenterFreq = primary20MHzStartingFreq(apDevIdx) + staBandwidth/2;

            else % 40e6, 80e6 and 160e6
                % Primary 20, 40 and 80 MHz of AP and STA must match for STA to operate in
                % primary 40, 80 and 160 MHz of AP
                matchingPrimaryBW = staBandwidth/2;
                % Scaling factor is the number of 20 MHz blocks that make up above matching
                % primary BWs
                scalingFactor = matchingPrimaryBW/20e6;
                % Index of primary 20, 40 and 80 MHz in AP bandwidth
                primaryIdx = ceil(primary20Idx/scalingFactor);
                % Suggest the STA band and channel to be same as primary 40, 80 and 160 MHz
                % of AP
                if rem(primaryIdx,2) == 0 % Even primary 20, 40 or 80 MHz channel
                    possibleCenterFreq = startingFreqAP(apDevIdx) + (primaryIdx-1)*(staBandwidth/2);
                else
                    possibleCenterFreq = startingFreqAP(apDevIdx) + (primaryIdx)*(staBandwidth/2);
                end
            end

            % Get channel number from center frequency
            [~, possibleChannel] = wlan.internal.utils.getBandChannelFromCenterFreq(possibleCenterFreq);
            possibleBandAndChannels(outputIdx, :) = [apBand possibleChannel];
            possibleBW(outputIdx) = staBandwidth;

        else
            % Get the list of all valid channels in operating band of AP
            channelMap = wlan.internal.utils.getChannelMap(apBand);
            % Get the column indices corressponding to AP and STA bandwidths
            apChannelColumnIdx = log2(apBandwidth/10e6);
            staChannelColumnIdx = log2(staBandwidth/10e6);

            for rowIdx = 2:size(channelMap, 1)
                % In each row of the table, get channel numbers corresponding to operating
                % bandwidth of AP
                channelNums = channelMap{rowIdx, apChannelColumnIdx};
                if any(apChannel==channelNums)
                    % Get the possible channels for STA based on its operating bandwidth
                    bw = staBandwidth;
                    % If operating BW for STA is greater than allowed in the AP band, iterate
                    % until maximum BW allowed in AP operating band is reached.
                    while staChannelColumnIdx > size(channelMap, 2)
                        % Check for channels in next possible BW
                        bw = bw/2;
                        staChannelColumnIdx = staChannelColumnIdx-1;
                    end
                    possibleChannel = channelMap{rowIdx, staChannelColumnIdx};
                    % No possible channel for STA bandwidth
                    if possibleChannel == 0
                        reduceBW = true;
                        while(reduceBW)
                            % Check for channels in next possible BW
                            bw = bw/2;
                            staChannelColumnIdx = staChannelColumnIdx-1;
                            possibleChannel = channelMap{rowIdx, staChannelColumnIdx};
                            if all(possibleChannel ~= 0)
                                reduceBW = false;
                            end
                        end
                    end
                    break;
                end
            end
            possibleBandAndChannels(outputIdx, :) = [apBand possibleChannel(1)];
            possibleBW(outputIdx) = bw;
        end
    end
end
possibleBandAndChannels = possibleBandAndChannels(1:outputIdx, :);
possibleBandAndChannels = num2cell(possibleBandAndChannels, 2);
possibleBandAndChannels = possibleBandAndChannels';
possibleBW = possibleBW(1:outputIdx);
end
