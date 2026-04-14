function fillTrafficBuffer(node)
%fillTrafficBuffer Fill the buffer with packets
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   fillTrafficBuffer(NODE) fills the traffic buffers based on the given
%   full buffer traffic configuration.
%
%   NODE is an object of type wlanNode.

% Copyright 2025 The MathWorks, Inc.

ac = 0;
numDestinations = numel(node.FullBufferContext);

for destIdx = 1:numDestinations
    if node.IsMLDNode && node.FullBufferContext(destIdx).IsMLDDestination
        % Association currently is supported between AP MLD and STA MLD, on
        % all the links. Hence, get the link IDs of MLD node starting from 1.
        deviceIndex = 1:node.DeviceConfig.NumLinks;
        mac = node.SharedMAC;
    else
        deviceIndex = wlan.internal.utils.mapDestination2Device(node, node.FullBufferContext(destIdx).DestinationID);
        mac = node.MAC(deviceIndex);
    end
    for idx = 1:numel(deviceIndex)
        setFullBufferTrafficContext(node.MAC(deviceIndex(idx)), [node.FullBufferContext(:).DestinationID]);
    end

    while ~isQueueFull(mac, node.FullBufferContext(destIdx).DestinationID, ac)
        wlan.internal.fillPacketInMACQueueWithFBCtx(node, destIdx, ac+1);
    end
end
end