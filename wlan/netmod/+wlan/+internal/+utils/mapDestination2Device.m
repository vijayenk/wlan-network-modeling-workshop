function [srcDeviceID, dstAddress] = mapDestination2Device(node, dstID)
%mapDestination2Device Return the source device ID and destination MAC
%address for the given destination ID
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [SRCDEVICEID, DSTADDRESS] = mapDestination2Device(NODE, DSTID) returns
%   the source device ID on which packet has to be sent to the destination
%   specified by the destination ID, DSTID, and the destination MAC address
%   corresponding to the given destination ID, DSTID.
%
%   SRCDEVICEID is the source device ID on which the packet has to be sent
%   to reach the given destination.
%
%   DSTADDRESS is the destination MAC address corresponding to the given
%   destination ID.
%
%   NODE is an object of type wlanNode.
%
%   DSTID is a scalar integer indicating the node ID of the destination.

% Copyright 2023-2025 The MathWorks, Inc.

    % Initialize
    dstAddress = [];
    
    if node.IsAPNode
        if dstID == 65535
            dstAddress = 'FFFFFFFFFFFF';        % Broadcast address
            srcDeviceID = 1:node.NumDevices;    % Send on all devices
            return;
        end
        destIdx = find(dstID == [node.RemoteSTAInfo(:).NodeID]);
        if ~isempty(destIdx) % Destination is one of associated STAs
            dstAddress = node.RemoteSTAInfo(destIdx).MACAddress;  % Destination address
            srcDeviceID = node.RemoteSTAInfo(destIdx).DeviceID; % Device ID on which destination node is associated
        else
            % Return device index as -1 if STA is not found in
            % associated STAs list
            srcDeviceID = -1;
        end
    else
        dstAddress = wlan.internal.utils.nodeID2MACAddress([dstID, 1]);
        % Consider only first device in case of:
        % 1. STA in BSS - first device is the only device
        % 2. Node (neither AP nor STA) - only the first device is
        % assumed to be active and used for transmission
        srcDeviceID = 1;
    end
end
