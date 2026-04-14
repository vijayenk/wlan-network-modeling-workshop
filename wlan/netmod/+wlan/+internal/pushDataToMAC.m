function isPacketQueued = pushDataToMAC(node, mpdu, sourceDeviceIdx, isGroupAddress, isMLDDestination)
%pushDataToMAC Push application data into applicable instances of the MAC
%layer operating on different frequencies
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   ISPACKETQUEUED = pushDataToMAC(NODE, MPDU, SOURCEDEVICEID,
%   ISGROUPADDRESS, ISMLDDESTINATION) pushes the specified packet, MPDU, to
%   an appropriate queue based on the information specified by
%   SOURCEDEVICEIDX, ISGROUPADDRESS, and ISMLDDESTINATION.
%
%   ISPACKETQUEUED is a logical scalar indicating whether the given
%   application packet has been queued at the MAC layer.
%
%   NODE is an object of type wlanNode.
%
%   MPDU is the packet (structure) to be pushed into MAC layer queue(s).
%
%   SOURCEDEVICEIDX is the device ID of the transmitting source.
%
%   ISGROUPADDRESS specifies whether the input packet is a group-addressed
%   frame.
%
%   ISMLDDESTINATION specifies whether the input packet is an MLD node.   

% Copyright 2023-2025 The MathWorks, Inc.
    
    currentTimeInSec = node.LastRunTime;
    ac = wlan.internal.Constants.TID2AC(mpdu.Header.TID+1);

    if isGroupAddress % groupcast
        isPacketQueued = pushGroupcastPacket(node, mpdu, ac, currentTimeInSec);
    else % unicast
        if node.IsMLDNode && isMLDDestination % MLD node & MLD destination
            isPacketQueued = pushUnicastMLDPacket(node, mpdu, ac, currentTimeInSec, isMLDDestination);
        else
            isPacketQueued = pushUnicastNonMLDPacket(node, mpdu, ac, currentTimeInSec, sourceDeviceIdx, isMLDDestination);
        end
    end
end


%pushUnicastNonMLDPacket Push unicast packet (destined to non-MLD) into
%per-link queues
function isPacketQueued = pushUnicastNonMLDPacket(node, mpdu, ac, currentTimeInSec, sourceDeviceIdx, isMLDDestination)

    bufferAvailable = false;                            % Non-MLD unicast packet pushing
    
    if sourceDeviceIdx > 0 % Further path exists
        % Get the source MAC device to push the application packet
        mac = node.MAC(sourceDeviceIdx);
        if node.IsMLDNode
            sharedMAC = node.SharedMAC;
        else
            sharedMAC = node.SharedMAC(sourceDeviceIdx);
        end
        
        % Check if buffer available in the link queue
        isDataFrame = wlan.internal.utils.isDataFrame(mpdu);
        if isDataFrame
            bufferAvailable = ~isQueueFull(mac, mpdu.Metadata.ReceiverID, ac);
        else
            bufferAvailable = ~isManagementQueueFull(mac, mpdu.Metadata.ReceiverID);
        end

        % Push packet into queue if buffer is available
        if bufferAvailable
            % Assign sequence number
            mpdu = assignSequenceNumber(sharedMAC, mpdu, isMLDDestination);
            % Packet origin source address
            mpdu.Metadata.SourceAddress = mac.MACAddress;
            if mac.IsMeshDevice && isDataFrame % Data frame to be sent on mesh
                % Packet generated at mesh STA. Assign mesh SA same as SA.
                mpdu.Header.Address4 = mpdu.Metadata.SourceAddress;
                % Mesh control fields
                mpdu.FrameBody.MeshControl.MeshSequenceNumber = getMeshSequenceNumber(node.MeshBridge, mac.MACAddress);
                mpdu.FrameBody.MeshControl.MeshTTL = node.MeshBridge.MeshTTL(sourceDeviceIdx);
            end
            mpdu.Metadata.MACEntryTime = currentTimeInSec;
            % Push the application data into the MAC queue
            enqueuePacket(mac, mpdu);
        end
    end
    % Return packet queuing status
    isPacketQueued = any(bufferAvailable);
end

%pushUnicastMLDPacket Push unicast packet (destined to MLD) into shared queue
function isPacketQueued = pushUnicastMLDPacket(node, mpdu, ac, currentTimeInSec, isMLDDestination)

    sharedMAC = node.SharedMAC;              % Shared MAC
    
    % Check if buffer is available in shared queues
    isDataFrame = wlan.internal.utils.isDataFrame(mpdu);
    if isDataFrame
        bufferAvailable = ~isQueueFull(sharedMAC, mpdu.Metadata.ReceiverID, ac);
    else
        bufferAvailable = ~isManagementQueueFull(sharedMAC, mpdu.Metadata.ReceiverID);
    end
    
    if bufferAvailable
        mpdu = assignSequenceNumber(sharedMAC, mpdu, isMLDDestination);
        mpdu.Metadata.MACEntryTime = currentTimeInSec;
        % Push the application data into the MAC queue
        enqueuePacket(sharedMAC, mpdu);
    end
    isPacketQueued = bufferAvailable;
end

%pushGroupcastPacket Push groupcast packet into queue
function isPacketQueued = pushGroupcastPacket(node, mpdu, ac, currentTimeInSec)

    sourceDeviceIdx = 1:node.NumDevices;                % Push groupcast packets into all devices/links

    % Get the shared MAC object
    if node.IsMLDNode && node.IsAPNode % Broadcast from MLD AP
        sharedMAC = node.SharedMAC;
        % Consider the link indices which are mapped to the AC of broadcast packet
        sourceDeviceIdx = [];
        for devIdx = 1:node.NumDevices
            if any(sharedMAC.Link2ACMap{devIdx} == ac)
                sourceDeviceIdx = [sourceDeviceIdx devIdx]; %#ok<AGROW>
            end
        end
    else % Broadcast from non-MLD AP
        sharedMAC = node.SharedMAC(1);
    end

    isDataFrame = wlan.internal.utils.isDataFrame(mpdu);
    bufferAvailable = false(1, numel(sourceDeviceIdx));
    % Check whether MAC buffer is available in all devices/links
    for idx = 1:numel(sourceDeviceIdx)
        if isDataFrame
            bufferAvailable(idx) = ~isQueueFull(node.MAC(sourceDeviceIdx(idx)), mpdu.Metadata.ReceiverID, ac);
        else
            bufferAvailable(idx) = ~isManagementQueueFull(node.MAC(sourceDeviceIdx(idx)), mpdu.Metadata.ReceiverID);
        end
    end

    if any(bufferAvailable)
        % Assign same sequence number and push into all links. To assign same
        % sequence number, only shared MAC object of first device is considered
        % above.
        mpdu = assignSequenceNumber(sharedMAC, mpdu);
    end

    for idx = 1:numel(sourceDeviceIdx)
        if bufferAvailable(idx)
            % Get the source MAC device to push the application packet
            mac = node.MAC(sourceDeviceIdx(idx));
            % Packet origin source address
            mpdu.Metadata.SourceAddress = mac.MACAddress;
            if mac.IsMeshDevice % Packet to be sent on mesh
                % Packet generated at mesh STA. Assign mesh SA same as SA.
                mpdu.Header.Address3 = mpdu.Metadata.SourceAddress;
                if isDataFrame
                    % Mesh sequence number & TTL
                    mpdu.FrameBody.MeshControl.MeshSequenceNumber = getMeshSequenceNumber(node.MeshBridge, mac.MACAddress);
                    mpdu.FrameBody.MeshControl.MeshTTL = node.MeshBridge.MeshTTL(sourceDeviceIdx(idx));
                end
            end
            mpdu.Metadata.MACEntryTime = currentTimeInSec;
            % Push the application data into the MAC queue
            enqueuePacket(mac, mpdu);
        end
    end
    % Return packet queuing status
    isPacketQueued = any(bufferAvailable);
end
