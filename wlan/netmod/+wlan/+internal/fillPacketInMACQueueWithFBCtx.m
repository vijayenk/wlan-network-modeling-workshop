function fillPacketInMACQueueWithFBCtx(node, destIdx, ac)
%fillPacketInMACQueueWithFBCtx Generate application packet with full buffer
%context and push to the MAC queue
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   fillPacketInMACQueueWithFBCtx(NODE, DESTIDX, AC) creates an application
%   packet with full buffer context and pushes to the MAC queue.
%
%   NODE is an object of type wlanNode.
%
%   DESTIDX is the node ID of the destination node.
%
%   AC is the access category specified as 1-4 (BE/BK/VI/VO).

% Copyright 2023-2025 The MathWorks, Inc.

if (ac == 1)
    fullBufferCtx = node.FullBufferContext(destIdx);
    macQueuePacket = fullBufferCtx.MACQueuePacket;
    macQueuePacket.FrameBody.MSDU.PacketID = packetIDCounter(node, destIdx);
    macQueuePacket.FrameBody.MSDU.PacketGenerationTime = node.LastRunTime; % Packet generation time stamp at origin

    % Push app packet to MAC layer
    wlan.internal.pushDataToMAC(node, macQueuePacket, fullBufferCtx.SourceDeviceIdx, fullBufferCtx.IsGroupAddress, fullBufferCtx.IsMLDDestination);
end
end
