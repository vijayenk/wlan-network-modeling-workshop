function multipleOperatingFreq(node)
%multipleOperatingFreq Performs validations when node supports multiple
%operating frequencies
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   multipleOperatingFreq(NODE) performs the following validations when the
%   node supports operation in multiple frequencies via multiband or
%   multilink capability:
%       1. All the operating frequencies within the node are unique
%       2. There is no self-interference between any two links in an MLD
%       node
%
%   NODE is an object of type wlanNode.

%   Copyright 2025 The MathWorks, Inc.

if ~node.DisableValidation
    % Validate multi-band combination
    if ~node.IsMLDNode && (numel(node.DeviceConfig) > 1)
        % Multiple devices are not supported for a STA node
        if ismember("STA", [node.DeviceConfig(:).Mode])
            error(message('wlan:wlanNode:UnsupportedMultiDeviceCombo'));
        end
        % Two devices in the same node cannot operate in the same frequency
        for idx = 1:numel(node.DeviceConfig)-1
            bandAndChannels = [node.DeviceConfig(idx+1:end).BandAndChannel];
            if any((node.DeviceConfig(idx).BandAndChannel(1) == bandAndChannels(1:2:end-1)) & (node.DeviceConfig(idx).BandAndChannel(2) == bandAndChannels(2:2:end)))
                error(message('wlan:wlanNode:UnsupportedMultiDeviceFreq'));
            end
        end
    end

    % Validate multilink combination
    if node.IsMLDNode && (numel(node.DeviceConfig.LinkConfig) > 1)
        linkCfg = node.DeviceConfig.LinkConfig;
        % Two links in the same MLD cannot operate in the same frequency
        for idx = 1:numel(linkCfg)-1
            bandAndChannels = [linkCfg(idx+1:end).BandAndChannel];
            if any((linkCfg(idx).BandAndChannel(1) == bandAndChannels(1:2:end-1)) & (linkCfg(idx).BandAndChannel(2) == bandAndChannels(2:2:end)))
                error(message('wlan:wlanNode:UnsupportedMultiLinkFreq'));
            end
        end
    end

    % Frequencies are validated to be unique in the above
    % validation. Check for any self-interference causing
    % frequency configurations within devices/links.
    devCfg = wlan.internal.utils.getDeviceConfig(node);
    numDevices = size(devCfg,2);
    aciModeled = any(~strcmp("co-channel",[devCfg(:).InterferenceModeling]));
    if aciModeled % If ACI is modeled, links must not use overlapping frequencies
        if node.IsMLDNode
            errorStr = "links";
        else
            errorStr = "devices";
        end
        isNonOverlappingACIDeviceIdx = strcmp("non-overlapping-adjacent-channel",[devCfg(:).InterferenceModeling]);
        maxInterferenceOffset = zeros(1,numDevices);
        maxInterferenceOffset(isNonOverlappingACIDeviceIdx) = [devCfg(isNonOverlappingACIDeviceIdx).MaxInterferenceOffset];
        operatingFreqRanges = zeros(numDevices,2);
        operatingFreqRanges(1:numDevices,1) = [devCfg(:).ChannelFrequency]-([devCfg(:).ChannelBandwidth]/2 + maxInterferenceOffset);
        operatingFreqRanges(1:numDevices,2) = [devCfg(:).ChannelFrequency]+([devCfg(:).ChannelBandwidth]/2 + maxInterferenceOffset);

        [~,sortedIdx] = sort(operatingFreqRanges(:,1));
        operatingFreqRanges = operatingFreqRanges(sortedIdx,:);
        for freqIdx = 1:size(operatingFreqRanges, 1)-1
            freqRange1 = operatingFreqRanges(freqIdx,:);
            freqRange2 = operatingFreqRanges(freqIdx+1,:);
            freqOverlap = min(freqRange1(2), freqRange2(2))-max(freqRange1(1), freqRange2(1));
            isFreqOverlap = freqOverlap>0;
            if isFreqOverlap
                error(message("wlan:wlanNode:SelfInterferenceModelingUnsupported", errorStr));
            end
        end
    end
end
end