function flag = isFrequencyOverlapping(node, packet, deviceID)
%isFrequencyOverlapping Check if frequency of a packet is overlapping
%with the operating frequency of the device
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FLAG = isFrequencyOverlapping(NODE, PACKET, DEVICEID) checks if the
%   frequency of the packet, PACKET, overlaps with the operating frequency
%   of the node, NODE.
%   
%   FLAG is a logical value indicating whether frequency is overlapping/
%
%   NODE is an object of type wlanNode, which received the packet, PACKET.
%
%   PACKET is the received packet structure of type
%   wirelessPacket.
%
%   DEVICEID is the ID of device within the node with which frequency
%   overlap needs to be checked.

%   Copyright 2023-2025 The MathWorks, Inc.

% Check if frequency of the packet is overlapping with the
% frequency range of the interference modeling configuration in
% the node

if node.InterferenceFidelity(deviceID) == 0
    if ~packet.Abstraction
        % Error when receiving non-WLAN packets
        if ~(packet.TechnologyType==wnet.TechnologyType.WLAN)
            error(message('wlan:wlanNode:CoChannelModelingMustBeWLAN'));
        end
        % Error when receiving WLAN packets those are oversampled
        if ~(packet.Metadata.OversamplingFactor==1)
            error(message('wlan:wlanNode:InterferenceModelingConfigureConflict'))
        end
    end
    % Check if the center frequency of received WLAN packet is same as that configured in the nodes
    %        |----------------------------|
    %        |             SOI            |
    %        |----------------------------|
    %        :                            :
    %        :                            :
    %        |----------------------------|
    %        |         Interference       |
    %        |----------------------------|
    %                 (co-channel)
    flag = packet.CenterFrequency == node.ReceiveFrequency(deviceID);
    % If the center frequency of the node and received packet are not matching,
    % check if any partial overlap is present and throw error stating ACI
    % modeling is needed for proper modeling.
    if ~flag
        % Calculate frequency range of operation for received packet
        rxStartFreq = packet.CenterFrequency-packet.Bandwidth/2;
        rxEndFreq = packet.CenterFrequency+packet.Bandwidth/2;
        % Calculate frequency range of operation for the node
        if node.IsMLDNode
            devCfg = node.DeviceConfig.LinkConfig;
        else
            devCfg = node.DeviceConfig;
        end
        operatingStartFreq = node.ReceiveFrequency(deviceID)-devCfg(deviceID).ChannelBandwidth/2;
        operatingEndFreq = node.ReceiveFrequency(deviceID)+devCfg(deviceID).ChannelBandwidth/2;
        % Check if there is any frequency overlap
        freqOverlap = min(rxEndFreq, operatingEndFreq)-max(rxStartFreq, operatingStartFreq);
        if freqOverlap>0
            error(message("wlan:wlanNode:NeedACIForPartialOverlappingFreqs", node.ID, packet.TransmitterID))
        end
    end
else % Modeling ACI
    % Error when receiving WLAN packets those are not oversampled
    if ((packet.TechnologyType==wnet.TechnologyType.WLAN) && (packet.Metadata.OversamplingFactor==1))
        error(message('wlan:wlanNode:InterferenceModelingConfigureConflict'));
    end

    % Calculate the start and end frequencies of received packet and receiver configuration
    rxStartFreq = packet.CenterFrequency-packet.Bandwidth/2;
    rxEndFreq = packet.CenterFrequency+packet.Bandwidth/2;

    % Return wlanDeviceConfig or wlanLinkConfig objects
    if node.IsMLDNode
        devCfg = node.DeviceConfig.LinkConfig;
    else
        devCfg = node.DeviceConfig;
    end
    operatingStartFreq = node.ReceiveFrequency(deviceID)-devCfg(deviceID).ChannelBandwidth/2;
    operatingEndFreq = node.ReceiveFrequency(deviceID)+devCfg(deviceID).ChannelBandwidth/2;

    if node.InterferenceFidelity(deviceID) == 1
        % In the diagram below, when freqOverlap>0, it represents the scenario of partial overlapping (overlapping-ACI)
        %      |-----------------------:----|
        %      |           SOI         :****|
        %      |-----------------------:----|
        %                              :    :
        %                              :    :
        %                              |----:-----------------------|
        %                              |****:     Interference      |
        %                              |----:-----------------------|
        %                              <---->
        %                            freqOverlap
        freqOverlap = min(rxEndFreq, operatingEndFreq)-max(rxStartFreq, operatingStartFreq);
        flag = freqOverlap>0;
    else
        % In the diagram below, for a fixed value of MaxInterferenceOffset, when freqOverlap>=0, it represents the scenario of non-overlapping ACI
        %      |----------------------------|..:....:
        %      |           SOI              |..:****:
        %      |----------------------------|..:....:
        %                                   <------->
        %                             MaxInterferenceOffset
        %                                      :    :
        %                                      :    :
        %                                      |----:-----------------------|
        %                                      |****:     Interference      |
        %                                      |----:-----------------------|
        %                                      <---->
        %                                    freqOverlap
        freqOverlap = min(rxEndFreq, operatingEndFreq+devCfg(deviceID).MaxInterferenceOffset) ...
            - max(rxStartFreq, operatingStartFreq-devCfg(deviceID).MaxInterferenceOffset);
        flag = freqOverlap>=0;
    end
end

end
