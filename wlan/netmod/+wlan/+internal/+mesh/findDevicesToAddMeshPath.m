function [srcDevID, meshPathDevID, destDevID] = findDevicesToAddMeshPath(sourceNode, destinationNode, meshPathNode, params)
%findDevicesToAddMeshPath Returns the device IDs for source, destination, and
%mesh path nodes.
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   [SRCDEVID, MESHPATHDEVID, DESTDEVID] =
%   findDevicesToAddMeshPath(SOURCENODE, DESTINATIONNODE, MESHPATHNODE,
%   PARAMS) finds the device IDs for source, destination, and mesh path
%   nodes either through the name-value arguments specified through PARAMS
%   argument or through the common operating frequencies between the source
%   and next hop nodes.
%
%   SRCDEVID is the source device ID corresponding to the node, SOURCENODE,
%   through which the mesh path is being added.
%
%   MESHPATHDEVID is the source device ID corresponding to the next hop
%   nodes, MESHPATHNODE. This is the next hop node in the mesh path from
%   the source node. If destination node is not a mesh node, this
%   represents the last mesh node in the path that can forward the packet
%   to the destination node, DESTINATIONNODE.
%
%   DESTDEVID is the destination device ID corresponding to the destination
%   node, DESTINATIONNODE, for which the path is being added.
%
%   SOURCENODE is an object of type wlanNode, representing the source node.
%
%   DESTINATIONNODE is an object of type wlanNode, representing the
%   destination node.
%
%   MESHPATHNODE is an object of type wlanNode, representing the next hop
%   node (if destination is a mesh node) or the final mesh node in the path
%   which can forward the packet to the non-mesh destination.
%
%   PARAMS is a structure holding the list of name-value arguments
%   passed to addMeshPath, whose fields are described as follows:
%
%   SourceBandAndChannel       - Band and channel on which the source
%                                node must transmit packets to the next hop
%                                node. Specify this input as a vector of
%                                two values. The first value must be 2.4,
%                                5, or 6 and the second value must be a
%                                valid channel number in the band.
%
%                                The input uses this default configuration:
%                                * If the mesh path node is the next hop
%                                  node, the function selects the common
%                                  band and channel between the source node
%                                  and next hop node. If there are multiple
%                                  common band-channel pairs, you must
%                                  specify a value for this input.
%                                * If the mesh path node is the proxy mesh
%                                  gate, the function selects the band and
%                                  channel belonging to a mesh device. If
%                                  there are multiple mesh devices, you
%                                  must specify a value for this input.
%
%   MeshPathBandAndChannel     - Band and channel on which the mesh path
%                                node must receive the packets. Specify
%                                this input as a vector of two values. The
%                                first value must be 2.4, 5, or 6 and the
%                                second value must be a valid channel
%                                number in the band.
%
%                                The input uses this default configuration:
%                                * If the mesh path node is the next hop
%                                  node, the function selects the common
%                                  band and channel between the source node
%                                  and next hop node.
%                                * If the mesh path node is the proxy mesh
%                                  gate, the function selects the band and
%                                  channel belonging to a mesh device. If
%                                  there are multiple mesh devices, you
%                                  must specify a value for this input.
%
%   DestinationBandAndChannel  - Band and channel on which the destination
%                                node should receive the packets. Specify
%                                this input as a vector of two values. The
%                                first value must be 2.4, 5, or 6 and the
%                                second value must be a valid channel
%                                number in the band.
%
%                                The input uses this default configuration:
%                                * If the destination node is a mesh node,
%                                  the function selects the band and
%                                  channel belonging to a mesh device. If
%                                  there are multiple mesh devices, you
%                                  must specify a value for this input.
%                                * If the destination node is a non-mesh
%                                  node and only one device is present, the
%                                  function selects the band and channel of
%                                  that device in the node. If there are
%                                  multiple devices, you must specify a
%                                  value for this input.

%   Copyright 2025 The MathWorks, Inc.

% Extract the user given parameter values (if any).
sourceBandAndChannel = params.SourceBandAndChannel;
destBandAndChannel = params.DestinationBandAndChannel;
meshPathBandAndChannel = params.MeshPathBandAndChannel;

if destinationNode.IsMeshNode % Forwarding path information
    % * Source node & mesh path node (next hop) are neighbors
    % * Destination node may or may not be neighbor of next hop node

    if isempty(sourceBandAndChannel) && isempty(meshPathBandAndChannel)
        % Source & mesh path node band and channels are not given by the user

        % Find common mesh operating frequency between the source and mesh path nodes
        sourceMeshDevIDs = find([sourceNode.MAC(:).IsMeshDevice]);
        meshPathMeshDevIDs = find([meshPathNode.MAC(:).IsMeshDevice]);
        commonFreq = intersect(sourceNode.ReceiveFrequency(sourceMeshDevIDs), meshPathNode.ReceiveFrequency(meshPathMeshDevIDs));
        if numel(commonFreq) > 1
            error(message('wlan:wlanNode:MultipleCommonMeshBandAndChannel'));
        end
        if isempty(commonFreq)
            error(message('wlan:wlanNode:NoCommonMeshBandAndChannel'));
        end
        % Find device IDs
        srcDevID = find(commonFreq == sourceNode.ReceiveFrequency);
        meshPathDevID = find(commonFreq == meshPathNode.ReceiveFrequency);

    elseif isempty(meshPathBandAndChannel)
        % Mesh path node band and channel is not given by the user, source band and
        % channel is given by the user

        % Find source device ID
        srcDevID = getDeviceID(sourceNode, sourceBandAndChannel);
        if isempty(srcDevID)
            error(message('wlan:wlanNode:InvalidSourceBandAndChannel', 'source'));
        end
        % Next hop node should receive packets on the source band and channel.
        meshPathDevID = getDeviceID(meshPathNode, sourceBandAndChannel);
        if isempty(meshPathDevID)
            error(message('wlan:wlanNode:InvalidSourceBandAndChannel', 'mesh path'));
        end

    elseif isempty(sourceBandAndChannel)
        % Source band and channel is not given by the user, mesh path node band and
        % channel is given by the user

        % Find mesh path device ID
        meshPathDevID = getDeviceID(meshPathNode, meshPathBandAndChannel);
        if isempty(meshPathDevID)
            error(message('wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path'));
        end
        % Source node should send packets on the mesh path band and channel.
        srcDevID = getDeviceID(sourceNode, meshPathBandAndChannel);
        if isempty(srcDevID)
            error(message('wlan:wlanNode:InvalidMeshPathBandAndChannel', 'source'));
        end

    else % Source & mesh path nodes band and channel are given by the user
        % Find source device ID
        srcDevID = getDeviceID(sourceNode, sourceBandAndChannel);
        if isempty(srcDevID)
            error(message('wlan:wlanNode:InvalidSourceBandAndChannel', 'source'));
        end
        % Find mesh path device ID
        meshPathDevID = getDeviceID(sourceNode, meshPathBandAndChannel);
        if isempty(meshPathDevID)
            error(message('wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path'));
        end

        % Check if source and mesh path (next hop) band and channels are the same
        if ~all(sourceBandAndChannel == meshPathBandAndChannel)
            error(message('wlan:wlanNode:BandAndChannelMismatch'));
        end
    end

    if isempty(destBandAndChannel)
        % Destination band and channel is not given by the user
        destDevID = 1;
        if numel(destinationNode.DeviceConfig) > 1
            if meshPathNode.ID == destinationNode.ID
                destDevID = meshPathDevID;
            else
                % Find mesh device ID in the destination node if there are multiple devices
                destDevID = find([destinationNode.MAC(:).IsMeshDevice]);
                if ~isempty(destDevID) && any(destinationNode.ID == meshPathNode.MeshNeighbors)
                    % If mesh and destination are neighbors, find the common mesh frequency
                    meshPathMeshDevIDs = find([meshPathNode.MAC(:).IsMeshDevice]);
                    commonFreq = intersect(destinationNode.ReceiveFrequency(destDevID), meshPathNode.ReceiveFrequency(meshPathMeshDevIDs));
                    if ~isempty(commonFreq)
                        [~, ~, destDevID] = intersect(commonFreq, destinationNode.ReceiveFrequency);
                    end
                end
                if ~isscalar(destDevID)
                    error(message('wlan:wlanNode:NeedBandAndChannelParameter', 'DestinationBandAndChannel', 'destination'));
                end
            end
        end
    else % Destination band and channel is given by the user
        % Find destination device ID
        destDevID = getDeviceID(destinationNode, destBandAndChannel);
        if isempty(destDevID)
            error(message('wlan:wlanNode:InvalidDestinationBandAndChannel'));
        end
    end

else % Proxy mesh information
    % * Destination node is not a mesh node
    % * Mesh path node is a mesh node
    % * Destination node and mesh path node (proxy mesh node) are neighbors
    % * Source node and mesh path node may or may not be neighbors

    if isempty(sourceBandAndChannel) && isempty(meshPathBandAndChannel)
        % Source & mesh path node band and channels are not given by the user

        % Try to find a mesh device ID on the source node
        srcDevID = find([sourceNode.MAC(:).IsMeshDevice]);
        if ~isscalar(srcDevID)
            error(message('wlan:wlanNode:NeedBandAndChannelParameter', 'SourceBandAndChannel', 'source'));
        end
        % Try to find a mesh device ID on the mesh path node
        meshPathDevID = find([meshPathNode.MAC(:).IsMeshDevice]);
        if ~isscalar(meshPathDevID)
            error(message('wlan:wlanNode:NeedBandAndChannelParameter', 'MeshPathBandAndChannel', 'mesh path'));
        end

    elseif isempty(meshPathBandAndChannel)
        % Mesh path node band and channel is not given by the user, source band and
        % channel is given by the user

        % Find source device ID
        srcDevID = getDeviceID(sourceNode, sourceBandAndChannel);
        if isempty(srcDevID)
            error(message('wlan:wlanNode:InvalidSourceBandAndChannel', 'source'));
        end
        % Try to find a mesh device ID on the mesh path node
        meshPathDevID = find([meshPathNode.MAC(:).IsMeshDevice]);
        if ~isscalar(meshPathDevID)
            error(message('wlan:wlanNode:NeedBandAndChannelParameter', 'MeshPathBandAndChannel', 'mesh path'));
        end

    elseif isempty(sourceBandAndChannel)
        % Source band and channel is not given by the user, mesh path node band and
        % channel is given by the user

        % Find mesh path device ID
        meshPathDevID = getDeviceID(meshPathNode, meshPathBandAndChannel);
        if isempty(meshPathDevID)
            error(message('wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path'));
        end
        % Try to find a mesh device ID on the source node
        srcDevID = find([sourceNode.MAC(:).IsMeshDevice]);
        if ~isscalar(srcDevID)
            error(message('wlan:wlanNode:NeedBandAndChannelParameter', 'SourceBandAndChannel', 'source'));
        end

    else % Source & mesh path nodes band and channel are given by the user
        % Find source device ID
        srcDevID = getDeviceID(sourceNode, sourceBandAndChannel);
        if isempty(srcDevID)
            error(message('wlan:wlanNode:InvalidSourceBandAndChannel', 'source'));
        end
        % Find mesh path device ID
        meshPathDevID = getDeviceID(sourceNode, meshPathBandAndChannel);
        if isempty(meshPathDevID)
            error(message('wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path'));
        end
    end

    if isempty(destBandAndChannel)
        % Destination band and channel is not given by the user
        if numel(destinationNode.DeviceConfig) > 1
            error(message('wlan:wlanNode:NeedBandAndChannelParameter', 'DestinationBandAndChannel', 'destination'));
        end
        destDevID = 1;
    else % Destination band and channel is given by the user
        % Find destination device ID
        destDevID = getDeviceID(destinationNode, destBandAndChannel);
        if isempty(destDevID)
            error(message('wlan:wlanNode:InvalidDestinationBandAndChannel'));
        end
    end
end
end

function deviceID = getDeviceID(node, bandAndChannel)
%getDeviceID Return device ID corresponding to the specified band and channel

    frequency = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));
    deviceID = find(node.ReceiveFrequency == frequency, 1);
end
