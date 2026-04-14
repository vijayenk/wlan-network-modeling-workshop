classdef MeshBridge < handle
%MeshBridge Create an object to handle mesh bridging functionality
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   MESHBRIDGEOBJ = wlan.internal.mesh.MeshBridge(MAC) creates an object
%   that handles bridging functionality in mesh networks and forwarding
%   from an access point (AP). MAC is a scalar or vector of MAC objects of
%   type <a href="matlab:help('wlan.internal.mac.edcaMAC')">edcaMAC</a>
%   present in the node.
%
%   MeshBridge methods:
%
%   addPath        - Add a path to the mesh forwarding table
%   addProxyInfo   - Add proxy information
%   statistics     - Get the mesh statistics
%
%   MeshBridge properties:
%
%   MeshTTL        - Maximum number of hops allowed to forward a packet from
%                    source in mesh network
%
%   MeshBridge read-only properties:
%
%   ForwardTable   - Mesh forwarding table
%   ProxyTable     - Table containing proxy information

%   Copyright 2022-2025 The MathWorks, Inc.

properties
    %MeshTTL Mesh time to live(TTL) is the maximum number of hops allowed
    %to forward a packet from source in mesh network
    %   Specify this property as a positive integer scalar or vector in the
    %   range of [1 - 255]. Each element represents the TTL value of a device
    %   in a node and is applicable only for mesh devices. Default value is 31.
    MeshTTL = 31;
end

properties(GetAccess = public, SetAccess = private)
    %ForwardTable Mesh forwarding table
    %   Specify the address of the next hop for each destination node in
    %   mesh network. It is specified as N x 4 cell array, where each row
    %   corresponds to a specific node in mesh network. Each row contains:
    %       - Mesh (destination) node ID
    %       - MAC address of mesh destination node
    %       - Next hop node address
    %       - ID of device on which packet has to be forwarded.
    ForwardTable = {0 '000000000000' '000000000000' 0};

    %ProxyTable Table containing proxy information
    %   Specify the address which proxies an external STA in the network.
    %   It is specified as N x 3 cell array, where each row corresponds to
    %   an external STA. Each row contains:
    %       - External STA (destination) node ID
    %       - MAC address of external STA
    %       - Proxy address for the external STA
    %   External STA corresponds to STA outside mesh BSS and in an 802.11
    %   BSS.
    ProxyTable = {0 '000000000000' '000000000000'};
end

properties (Constant)
    %MaxSequenceNumber Mesh sequence number is a 4-byte value. The maximum
    %value is 2^32-1.
    MaxSequenceNumber = 2^32-1;

    %CacheSize Integer specifying size of cache used for duplicate
    %detection from a source
    CacheSize = 128;
end

properties (Hidden)
    %MeshSequenceCounter Sequence counter per each source address
    %   This is a cell array. First column represents the source address
    %   and the second column represents the counter value. The counter
    %   gets updated for each new packet transmission from the
    %   corresponding source address. Refer section - 9.2.4.7.3 in IEEE Std
    %   802.11-2016.
    MeshSequenceCounter = cell(1, 2);

    %RemoteSTAInfo Contains information of associated STAs, associated AP
    %or peer mesh, or other APs detected in the network
    %   This property is an array of structures of size N x 1, where N is the
    %   number of associated STAs. Each structure contains following fields:
    %     Mode            - Operating mode of the node indicating if it is a 
    %                       STA, AP, mesh
    %     NodeID          - Node identifier of associated STA
    %     MACAddress      - MAC address of associated STA. Contains one
    %                       or multiple addresses if STA and AP are MLDs
    %                       due to multilink setup
    %     DeviceID        - Device index or link index/indices on which
    %                       AP is connected to the STA
    %     AID             - Association identifier (AID) assigned to STA
    %     IsMLD           - Flag indicating whether associated STA is
    %                       a multilink device (MLD)
    %     EnhancedMLMode  - Scalar indicating multilink operating mode.
    %                       Applicable only when the STA is an MLD. 0
    %                       and 1 represents STR and EMLSR respectively.
    %     NumEMLPadBytes  - Number of padding bytes to include in initial
    %                       control frame (ICF). Applicable for EMLSR STA.
    %   In case of mesh, peer mesh node information is not added as it is
    %   already maintained in ForwardTable.
    RemoteSTAInfo = struct([]);

    % MeshStatistics is a scalar or an array of structures captured at each
    % device in the node.
    MeshStatistics;
end

properties (SetAccess = private)
    %RxDuplicatePackets Number of duplicate packets received
    RxDuplicatePackets = cell(1, 2);

    %PacketCache Packet cache used to detect the duplicate packets
    %   This is a cell array. Each element specifies the original source
    %   address and a window of 128 previously received mesh sequence
    %   numbers which are not duplicate.
    PacketCache = cell(1, 2);

    %SrcDestWarningPairs Source and destination pairs for which warning has
    %been thrown
    %   This is an array of size N x 2. Each row indicates a source
    %   destination pair for which warning has been thrown for packet drop
    %   at AP device while forwarding.
    SrcDestWarningPairs = zeros(1, 2);

    %MAC WLAN (EDCA) MAC layer object
    %   This property is a scalar or vector of objects of type <a
    %   href="matlab:help('wlan.internal.mac.edcaMAC')">edcaMAC</a>. This object contains
    %   methods and properties related to WLAN EDCA MAC layer.
    MAC;

    %SharedMAC WLAN shared MAC layer object
    %   This property is a scalar or vector of objects of type <a
    %   href="matlab:help('wlan.internal.mac.SharedMAC')">sharedMAC</a>. In the
    %   context of a multi-link device (MLD), this object handles shared
    %   functionality between the links. In the context of a non-MLD, this
    %   object handles functionality specific to a device.
    SharedMAC;

    %ForwardTableLength Length of mesh forwarding table
    %   ForwardTableLength is an integer representing length of mesh
    %   forwarding table. It represents the number of rows in <a
    %   href="matlab:help('wlan.internal.mesh.MeshBridge/ForwardTable')">ForwardTable</a>.
    ForwardTableLength = 0;

    %ProxyTableLength Length of proxy information table
    %   ProxyTableLength is an integer representing length of proxy
    %   information table. It represents the number of rows in <a
    %   href="matlab:help('wlan.internal.mesh.MeshBridge/ProxyTable')">ProxyTable</a>.
    ProxyTableLength = 0;
end

properties (Access = private)
    % CacheIndex is an array. Each element specifies an index in the 128
    % size window at which non-duplicate sequence number must be inserted.
    % Each row represents a source specified in corresponding row of
    % PacketCache.
    CacheIndex = 0;
end

% Mesh statistics
properties (GetAccess = public, SetAccess = private, Description = 'Metrics')
    %Statistics Structure containing statistics captured at mesh
    Statistics = struct(...
        'MSDUsToBeForwadedPerAC', zeros(1, 4), ...      % Number of MSDUs to be forwarded
        'MSDUBytesToBeForwardedPerAC', zeros(1, 4), ... % Number of MSDU bytes to be forwarded
        'DroppedMSDUsNoFurtherPath', 0, ...             % Number of MSDUs dropped due to no further path
        'DroppedMSDUsDuplicate', 0, ...                 % Number of duplicate MSDUs dropped
        'DroppedMSDUsTTLZero', 0);                      % Number of MSDUs dropped due to insufficient TTL
end

methods
    function obj = MeshBridge(mac, varargin)
        % Store references of MAC objects present in node
        obj.MAC = mac;
        % Name-value pairs
        for idx = 1:2:nargin-1
            obj.(varargin{idx}) = varargin{idx+1};
        end

        % Initialize statistics
        numDevices = numel(mac);
        obj.MeshStatistics = repmat(obj.Statistics, 1, numDevices);
    end

    function addPath(obj, destinationNodeID, destinationMACAddress, ...
            nextHopMACAddress, forwardDeviceID)
        %addPath Add a path to the mesh forwarding table for the given
        %destination ID
        %
        %   addPath(OBJ, DESTINATIONNODEID, DESTINATIONMACADDRESS,
        %   NEXTHOPMACADDRESS, FORWARDDEVICEID) adds path to the forwarding
        %   table for given destination node.
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   DESTINATIONNODEID is the node identifier(ID) of destination
        %   mesh node.
        %
        %   DESTINATIONMACADDRESS is the MAC address of destination mesh
        %   node.
        %
        %   NEXTHOPMACADDRESS is the MAC address of node to which next hop
        %   is taken to reach the given destination.
        %
        %   FORWARDDEVICEID is the ID of device on which packet has to be
        %   sent to next hop node.

        % Get the index from the forward table which is having the path
        % for the given destination ID
        tableIdx = ([obj.ForwardTable{:, 1}] == destinationNodeID);
        if any(tableIdx)
            tableIdx = find(tableIdx);
        else
            obj.ForwardTableLength = obj.ForwardTableLength+1;
            tableIdx = obj.ForwardTableLength;
        end

        [obj.ForwardTable{tableIdx, :}] = deal(destinationNodeID, destinationMACAddress, nextHopMACAddress, forwardDeviceID);
    end

    function addProxyInfo(obj, destinationNodeID, destinationMACAddress, meshDestinationAddress)
        %addProxyInfo Add proxy information for the specified destination
        %ID
        %
        %   addProxyInfo(OBJ, DESTINATIONNODEID, DESTINATIONMACADDRESS,
        %   MESHDESTINATIONADDRESS) adds proxy information to a table for the
        %   specified destination node.
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   DESTINATIONNODEID is the node identifier(ID) of an external
        %   destination node.
        %
        %   DESTINATIONMACADDRESS is the MAC address of external
        %   destination node.
        %
        %   MESHDESTINATIONADDRESS is the MAC address of mesh node that
        %   proxies the specified destination.

        % Get the index from the proxy table which is having the proxy
        % information of the given destination ID
        tableIdx = ([obj.ProxyTable{:, 1}] == destinationNodeID);
        if any(tableIdx)
            tableIdx = find(tableIdx);
        else
            obj.ProxyTableLength = obj.ProxyTableLength + 1;
            tableIdx = obj.ProxyTableLength;
        end

        [obj.ProxyTable{tableIdx, :}] = deal(destinationNodeID, destinationMACAddress, meshDestinationAddress);
    end

    function meshStats = statistics(obj, deviceID)
        %statistics Get the statistics captured at mesh bridge
        %
        %   MESHSTATS = statistics(OBJ, DEVICEID) returns statistics
        %   captured at mesh bridge.
        %
        %   MESHSTATS is a structure containing captured statistics for a
        %   device in node.
        %
        %   OBJ is the object of type wlan.internal.mesh.MeshBridge.
        %
        %   DEVICEID is the identifier of device in node.

        meshStats = struct(PacketsToBeForwarded=0, PayloadBytesToBeForwarded=0, DroppedPackets=0);
        
        meshStats.PacketsToBeForwarded = sum(obj.MeshStatistics(deviceID).MSDUsToBeForwadedPerAC);
        meshStats.PayloadBytesToBeForwarded = sum(obj.MeshStatistics(deviceID).MSDUBytesToBeForwardedPerAC);
        meshStats.DroppedPackets = obj.MeshStatistics(deviceID).DroppedMSDUsNoFurtherPath + obj.MeshStatistics(deviceID).DroppedMSDUsDuplicate + obj.MeshStatistics(deviceID).DroppedMSDUsTTLZero;
    end
end

methods(Hidden)
    function meshSequenceNumber = getMeshSequenceNumber(obj, sourceAddress)
        %getMeshSequenceNumber Get sequence number for transmission from
        %given source
        %
        %   MESHSEQUENCENUMBER = getMeshSequenceNumber(OBJ, SOURCEADDRESS)
        %   returns sequence number to be assigned to a packet from given
        %   source.
        %
        %   MESHSEQUENCENUMBER is the sequence number of packet.
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   SOURCEADDRESS is the MAC address of mesh source node.

        % Get the index for source address mesh sequence counter
        srcIdx = strcmpi(obj.MeshSequenceCounter(:, 1), sourceAddress);
        if any(srcIdx)
            % Update the mesh sequence counter
            seqCounter = obj.MeshSequenceCounter{srcIdx, 2} + 1;
            % Initialize the counter to 0 when it reaches maximum value
            if seqCounter > obj.MaxSequenceNumber
                seqCounter = 0;
            end
            meshSequenceNumber = seqCounter;
            obj.MeshSequenceCounter{srcIdx, 2} = seqCounter;
        else
            % Start the mesh sequence counter from zero
            % Reference: Section-9.2.4.7.3 in IEEE Std 802.11-2016 
            obj.MeshSequenceCounter = [obj.MeshSequenceCounter; {sourceAddress 0}];
            meshSequenceNumber = 0;
        end
    end

    function isDuplicate = isDuplicateFrame(obj, sourceAddress, sequenceNumber, deviceID)
        %isDuplicateFrame Check whether the frame is already received or
        %not
        %
        %   ISDUPLICATE = isDuplicateFrame(OBJ, SOURCEADDRESS,
        %   SEQUENCENUMBER, DEVICEID) updates packet cache and returns a flag
        %   indicating whether the frame with given sequence number is
        %   duplicate or not.
        %
        %   ISDUPLICATE is a flag which indicates the frame is duplicate
        %   when true.
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   SOURCEADDRESS is the MAC address of mesh source node of
        %   received packet.
        %
        %   SEQUENCENUMBER is the sequence number of received packet.
        %
        %   DEVICEID is the identifier of the device in which MAC layer
        %   is operating.

        % Initialize
        isDuplicate = false;

        % Original source address
        txIdx = strcmpi(obj.PacketCache(:, 1), sourceAddress);
        % Received the packet from source existing in cache
        if any(txIdx)
            % Get sequence numbers present in cache
            seqNumCache = obj.PacketCache{txIdx, 2};
            % Received duplicate packet with old sequence number
            if any(sequenceNumber == seqNumCache)
                isDuplicate = true;
                obj.RxDuplicatePackets{txIdx, 2} = obj.RxDuplicatePackets{txIdx, 2} + 1;
                obj.MeshStatistics(deviceID).DroppedMSDUsDuplicate = obj.MeshStatistics(deviceID).DroppedMSDUsDuplicate + 1;
            else
                % Insert new sequence number into packet cache
                obj.CacheIndex(txIdx) = obj.CacheIndex(txIdx) + 1;
                if obj.CacheIndex(txIdx) > obj.CacheSize
                    obj.CacheIndex(txIdx) = 1;
                end
                seqNumCache(obj.CacheIndex(txIdx)) = sequenceNumber;
                obj.PacketCache{txIdx, 2} = seqNumCache;
            end
        else
            % Initialize the sequence number index in packet cache to 1
            obj.CacheIndex = [obj.CacheIndex 1];
            seqNumCache = zeros(obj.CacheSize, 1); % Initialize a cache of size 128
            seqNumCache(1) = sequenceNumber; % Insert sequence number at index 1
            % Add the new original source address into the packet cache
            obj.PacketCache = [obj.PacketCache; {sourceAddress, seqNumCache}];
            obj.RxDuplicatePackets = [obj.RxDuplicatePackets; {sourceAddress, 0}];
        end
    end

    function forwardAppData(obj, macPacket, deviceID, isGroup)
        %forwardAppData Forward decoded MSDUs based on mesh forwarding
        %table and AP association information
        %
        %   forwardAppData(OBJ, MACPACKET, DEVICEID, ISGROUP) pushes packet
        %   into MAC queue corresponding to the device it has to be
        %   forwarded.
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   MACPACKET is the decoded application packet structure.
        %
        %   DEVICEID is the ID of the device in which MAC layer is operating.
        %
        %   ISGROUP is a flag indicating broadcast packet.

        % Initialize the MAC queue packet structure
        packetToQueue = macPacket;
 
        % Flag to indicate whether to forward broadcast packet in AP device
        groupAPForward = false;
        isDestinationAssociatedSTA = false;
        if ~isempty(obj.RemoteSTAInfo) % Associations are present
            isDestinationAssociatedSTA = any(packetToQueue.Metadata.DestinationID == [obj.RemoteSTAInfo(:).NodeID]);
        end
        % Destination ID is an associated STA
        if isDestinationAssociatedSTA
            staIdxLogical = (packetToQueue.Metadata.DestinationID == [obj.RemoteSTAInfo(:).NodeID]);
            isMLDReceiver = obj.RemoteSTAInfo(staIdxLogical).IsMLD;
            if isMLDReceiver % If STA is MLD, AP is also MLD in current support
                forwardMLDPacket(obj, packetToQueue);
                return;
            else % AP non-MLD or MLD
                % Get device or link index on which AP is connected to STA
                forwardDeviceIdx = obj.RemoteSTAInfo(staIdxLogical).DeviceID;
                % Add address fields to the packet
                destAddress = obj.RemoteSTAInfo(staIdxLogical).MACAddress;
                packetToQueue.Header.Address1 = destAddress;
                packetToQueue.Metadata.ReceiverID = packetToQueue.Metadata.DestinationID;
                packetToQueue.Metadata.DestinationAddress = destAddress;
            end
        elseif isGroup && obj.MAC(deviceID).IsAPDevice % Broadcast received on AP device
            if obj.MAC(deviceID).IsAffiliatedWithMLD % AP MLD
                forwardMLDPacket(obj, packetToQueue);
                return;
            else
                packetToQueue.Header.Address1 = packetToQueue.Metadata.DestinationAddress;
                packetToQueue.Metadata.ReceiverID = packetToQueue.Metadata.DestinationID;
                forwardDeviceIdx = deviceID;
                groupAPForward = true;
            end
        elseif any([obj.MAC.IsMeshDevice]) % Node has at least one mesh device
            % Get the next hop addresses for transmitting the data
            [forwardDeviceIdx, ~, meshDestinationAddress, nextHopAddress] = ...
                nextHop(obj, packetToQueue.Metadata.DestinationID);

            if forwardDeviceIdx == -1
                % Proxy information present at node but path not found

                % Drop the packet and update statistics
                obj.MeshStatistics(deviceID).DroppedMSDUsNoFurtherPath = obj.MeshStatistics(deviceID).DroppedMSDUsNoFurtherPath + 1;
                return;
            elseif forwardDeviceIdx == -2
                % Proxy information not present at node. In this case, node
                % is assumed to be a propagator of traffic and forwards
                % packet towards mesh DA

                % Get route to this mesh DA from forwarding table
                meshDestAddress = wlan.internal.utils.getMeshDestinationAddress(packetToQueue);
                meshDestNodeID = wlan.internal.utils.macAddress2NodeID(meshDestAddress);
                [forwardDeviceIdx, ~, ~, nextHopAddress] = nextHop(obj, meshDestNodeID);

                if forwardDeviceIdx >= 0 % Path present to mesh DA
                    packetToQueue.Header.Address1 = nextHopAddress;
                    packetToQueue.Metadata.ReceiverID = wlan.internal.utils.macAddress2NodeID(nextHopAddress);
                else
                    % Drop the packet and update statistics
                    obj.MeshStatistics(deviceID).DroppedMSDUsNoFurtherPath = obj.MeshStatistics(deviceID).DroppedMSDUsNoFurtherPath + 1;
                    return;
                end
            else
                % Next hop is the broadcast address
                if isGroup
                    forwardDeviceIdx = 1:numel(obj.MAC);
                else
                    % Update the addresses of the received application data
                    packetToQueue.Header.Address1 = nextHopAddress;
                    packetToQueue.Header.Address3 = meshDestinationAddress;
                    packetToQueue.Metadata.ReceiverID = wlan.internal.utils.macAddress2NodeID(nextHopAddress);
                end
            end
        else % Unable to forward packet from AP due to no association
            % Get the source node ID from the source address
            srcNode = wlan.internal.utils.macAddress2NodeID(packetToQueue.Metadata.SourceAddress);
            destNode = packetToQueue.Metadata.DestinationID;
            isWarned = (obj.SrcDestWarningPairs == [srcNode destNode]);
            isWarned = all(isWarned, 2);
            % Do not throw warning if warning has been previously
            % thrown
            if ~any(isWarned)
                % Store the source, destination pair
                obj.SrcDestWarningPairs = [obj.SrcDestWarningPairs; srcNode packetToQueue.Metadata.DestinationID];
                % Throw warning if destination is not an associated STA
                warning(message('wlan:wlanNode:PacketDroppedAtAP', srcNode, ...
                    packetToQueue.Metadata.DestinationID, obj.MAC(1).NodeID));
            end
            return;
        end

        % Check whether the buffers in each device MAC is empty
        emptyBuffers = true(1, numel(forwardDeviceIdx));
        for idx=1:numel(forwardDeviceIdx)
            % Get the source MAC device
            mac = obj.MAC(forwardDeviceIdx(idx));
            % Only forward from non-MLDs (AP/mesh) is handled here. Currently, non-MLD
            % forwards packets to other non-MLD. So, check whether link queues are
            % available.
            if isQueueFull(mac, packetToQueue.Metadata.ReceiverID, wlan.internal.Constants.TID2AC(packetToQueue.Header.TID+1))
                emptyBuffers(idx) = false;
            end
        end
        % Return if MAC buffers for all devices are full
        if ~any(emptyBuffers)
            return;
        end

        seqNumAssigned = false;
        for idx = 1:numel(forwardDeviceIdx)
            % Get the source MAC device to push the application packet
            mac = obj.MAC(forwardDeviceIdx(idx));
            forwardDeviceID = mac.DeviceID;
            if mac.IsMeshDevice % Mesh forwarding
                % Decrement TTL
                packetToQueue.FrameBody.MeshControl.MeshTTL = packetToQueue.FrameBody.MeshControl.MeshTTL - 1;
                meshSourceAddress = wlan.internal.utils.getMeshSourceAddress(packetToQueue);
                if strcmp(meshSourceAddress, '000000000000')
                    % If the packet to be forwarded doesn't contain mesh
                    % source address and has to be forwarded on mesh,
                    % assign mesh SA
                    packetToQueue.Header.Address4 = mac.MACAddress;
                    % Assign TTL and Mesh Sequence Number
                    packetToQueue.FrameBody.MeshControl.MeshTTL = obj.MeshTTL(forwardDeviceIdx(idx));
                    packetToQueue.FrameBody.MeshControl.MeshSequenceNumber = getMeshSequenceNumber(obj, mac.MACAddress);
                end

                if packetToQueue.FrameBody.MeshControl.MeshTTL < 1
                    % Drop the packet and update statistics
                    obj.MeshStatistics(forwardDeviceID).DroppedMSDUsTTLZero = obj.MeshStatistics(forwardDeviceID).DroppedMSDUsTTLZero + 1;
                else
                    acIdx = wlan.internal.Constants.TID2AC(macPacket.Header.TID+1) + 1;
                    % Update number of MSDUs and number of bytes pushed into MAC queue for forwarding
                    obj.MeshStatistics(forwardDeviceID).MSDUsToBeForwadedPerAC(acIdx) = ...
                        obj.MeshStatistics(forwardDeviceID).MSDUsToBeForwadedPerAC(acIdx) + 1;
                    obj.MeshStatistics(forwardDeviceID).MSDUBytesToBeForwardedPerAC(acIdx) = ...
                        obj.MeshStatistics(forwardDeviceID).MSDUBytesToBeForwardedPerAC(acIdx) + macPacket.FrameBody.MSDU.PacketLength;
                    packetToQueue.Metadata.MACEntryTime = round(obj.MAC(deviceID).LastRunTimeNS/1e9, 9);
                    % Assign sequence number
                    if isGroup
                        % Assign sequence only once and push into all links. To assign sequence
                        % number, consider shared MAC object of first device
                        if ~seqNumAssigned
                            packetToQueue = assignSequenceNumber(obj.SharedMAC(1), packetToQueue);
                            seqNumAssigned = true;
                        end
                    else
                        isMLDDestination = false; % MLDMeshNotSupported
                        packetToQueue = assignSequenceNumber(obj.SharedMAC(forwardDeviceIdx(idx)), packetToQueue, isMLDDestination);
                    end
                    % Push the packet into MAC queue to forward it to the next hop
                    enqueuePacket(mac, packetToQueue);
                end
            else % AP forwarding
                if ~isGroup ... % Forward unicast packet to non-MLD STA
                        || groupAPForward % Do not forward mesh broadcast into AP device
                    % Assign sequence number
                    isMLDDestination = false;
                    if mac.IsAffiliatedWithMLD % AP MLD
                        sharedMAC = obj.SharedMAC;
                    else
                        sharedMAC = obj.SharedMAC(forwardDeviceIdx(idx));
                    end
                    packetToQueue = assignSequenceNumber(sharedMAC, packetToQueue, isMLDDestination);
                    % Push the packet into MAC queue to forward it to the STA
                    packetToQueue.Metadata.MACEntryTime = round(obj.MAC(deviceID).LastRunTimeNS/1e9, 9);
                    enqueuePacket(mac, packetToQueue);
                end
            end
        end
    end

    function [forwardDeviceID, destinationAddress, meshDestinationAddress, nextHopAddress] = ...
            nextHop(obj, destinationID)
        %nextHop Get next hop information to the given destination node
        %
        %   [FORWARDDEVICEID, DESTINATIONADDRESS, ...
        %   MESHDESTINATIONADDRESS, NEXTHOPADDRESS] = nextHop(OBJ,
        %   DESTINATIONID) returns next hop information to reach the given
        %   destination node.
        %
        %   FORWARDDEVICEID is the device index on which packet has to be
        %   sent to next hop node. The method returns following values:
        %       >0 - when path is found
        %        0 - when destination is broadcast
        %       -1 - when no path is found from proxy and forwarding tables
        %       -2 - when no path is found from forwarding table and proxy
        %            information is not present
        %
        %   DESTINATIONADDRESS is the MAC address of destination node.
        %
        %   MESHDESTINATIONADDRESS is the MAC address of destination mesh
        %   node.
        %
        %   NEXTHOPADDRESS is the MAC address of node to which next hop is
        %   taken to reach the given destination.
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   DESTINATIONID is the node identifier(ID) of destination node.

        forwardDeviceID = -1;
        destinationAddress = [];
        meshDestinationAddress = [];
        nextHopAddress = [];
        % Destination is the broadcast ID
        if (destinationID == 65535)
            % Packet forwards into all the available devices
            forwardDeviceID = 0;
            destinationAddress = 'FFFFFFFFFFFF'; % Broadcast address
            meshDestinationAddress = 'FFFFFFFFFFFF'; % Broadcast address
            nextHopAddress = 'FFFFFFFFFFFF'; % Broadcast address
        else
            % Get the path of the specified destination node
            meshNodeIDs = [obj.ForwardTable{:, 1}];
            pathIdx = destinationID == meshNodeIDs;

            % Path not present in forwarding table. Look in proxy table
            if ~any(pathIdx)
                if obj.ProxyTableLength ~= 0 % Proxy information is present
                    proxyIdx = destinationID == [obj.ProxyTable{:, 1}];

                    % Proxy address found for the destination node
                    if any(proxyIdx)
                        destinationAddress = obj.ProxyTable{proxyIdx, 2};
                        % Get mesh destination address from proxy table
                        meshDestinationAddress = obj.ProxyTable{proxyIdx, 3};
                        meshDestinationID = wlan.internal.utils.macAddress2NodeID(meshDestinationAddress);
                        % Search for the mesh destination node in mesh forwarding table
                        pathIdx = meshDestinationID == meshNodeIDs;
                    end

                    % No path exists for the mesh destination node or the
                    % specified destination node
                    if ~any(proxyIdx) || ~any(pathIdx)
                        return;
                    end
                else
                    % No proxy information at this node. This node is
                    % assumed to be a propagator.
                    pathIdx = 0;
                end
            else % Path found in forwarding table
                % Final destination address
                destinationAddress = obj.ForwardTable{pathIdx, 2};
                % Mesh DA is same as final destination address when the
                % destination ID is found in mesh forwarding table
                meshDestinationAddress = destinationAddress;
            end

            if any(pathIdx) % Path found
                % Source device index
                forwardDeviceID = obj.ForwardTable{pathIdx, 4};
                % Immediate next hop address
                nextHopAddress = obj.ForwardTable{pathIdx, 3};
            else % Path not found from forwarding table and proxy information is also not present
                forwardDeviceID = -2;
            end
        end
    end

    function isIntendedForAppRx = handleReceivedMeshPacket(obj, rxMPDU, selfMACAddress, deviceID)

        isIntendedForAppRx = false;
        isGroupAddr = wlan.internal.utils.isGroupAddress(rxMPDU.Header.Address1);
        meshSourceAddress = wlan.internal.utils.getMeshSourceAddress(rxMPDU);

        if isGroupAddr
            % Check whether the packet is already received or not
            isDuplicate = isDuplicateFrame(obj, meshSourceAddress, rxMPDU.FrameBody.MeshControl.MeshSequenceNumber, deviceID);
            isMeshFrameOriginatedFromSelf = strcmp(meshSourceAddress,selfMACAddress);

            if ~isDuplicate && ~isMeshFrameOriginatedFromSelf
                isIntendedForAppRx = true;
                % Forward the packet in all the MAC devices if
                % remaining mesh forward hops are greater than 1
                forwardAppData(obj, rxMPDU, deviceID, isGroupAddr);
            end
        else
            if rxMPDU.Header.ToDS && rxMPDU.Header.FromDS % Four address frame received on mesh
                % Check whether the packet is already received or not
                isDuplicate = isDuplicateFrame(obj, meshSourceAddress, rxMPDU.FrameBody.MeshControl.MeshSequenceNumber, deviceID);

                % Non-duplicate mesh packet (MSDU)
                if ~isDuplicate
                    % Packet reached mesh destination address (DA)
                    if strcmp(selfMACAddress, rxMPDU.Metadata.DestinationAddress)
                        % Give packet to application layer if the mesh DA is final DA
                        isIntendedForAppRx = true;
                    else
                        forwardAppData(obj, rxMPDU, deviceID, isGroupAddr);
                    end
                end
            end

        end
    end

    function addRemoteSTAInfo(obj, staInfo)
        % Add association information
        obj.RemoteSTAInfo = [obj.RemoteSTAInfo staInfo];
    end
end

methods(Access = private)
    function forwardMLDPacket(obj, packetToQueue)
        %forwardMLDPacket Forward packets to STA MLDs from AP MLD
        %
        %   forwardMLDPacket(OBJ, PACKETTOQUEUE) forwards the
        %   decoded MSDUs to STA MLD(s).
        %
        %   OBJ is an object of type wlan.internal.mesh.MeshBridge.
        %
        %   PACKETTOQUEUE is the packet structure to be pushed into MAC queues.

        % Fill remaining fields in packet to be queued
        packetToQueue.Header.Address1 = packetToQueue.Metadata.DestinationAddress;
        packetToQueue.Metadata.ReceiverID = packetToQueue.Metadata.DestinationID;
        packetToQueue.Metadata.MACEntryTime = round(obj.MAC(1).LastRunTimeNS/1e9, 9);
        ac = wlan.internal.Constants.TID2AC(packetToQueue.Header.TID+1);

        if packetToQueue.Metadata.DestinationID ~= 65535
            % Check whether shared queues are full
            bufferAvailable = ~isQueueFull(obj.SharedMAC, packetToQueue.Metadata.ReceiverID, ac);

            if bufferAvailable
                % Assign sequence number
                isMLDDestination = true;
                packetToQueue = assignSequenceNumber(obj.SharedMAC, packetToQueue, isMLDDestination);
                % Push the packet into the MAC queue
                enqueuePacket(obj.SharedMAC, packetToQueue);
            end
        else
            % Push broadcast packet in link queues based on AC to link mapping
            sourceDeviceIdx = [];
            for devIdx = 1:numel(obj.MAC)
                if any(obj.SharedMAC.Link2ACMap{devIdx} == ac)
                    sourceDeviceIdx = [sourceDeviceIdx devIdx]; %#ok<*AGROW>
                end
            end

            bufferAvailable = false(1, numel(sourceDeviceIdx));
            for idx = 1:numel(sourceDeviceIdx)
                % Get the source MAC device to push the application packet
                mac = obj.MAC(sourceDeviceIdx(idx));
                bufferAvailable(idx) = ~isQueueFull(mac, packetToQueue.Metadata.ReceiverID, ac);
            end

            if any(bufferAvailable)
                % Assign same sequence number and push into all links
                packetToQueue = assignSequenceNumber(obj.SharedMAC, packetToQueue);

                for idx = 1:numel(sourceDeviceIdx)
                    if bufferAvailable(idx)
                        % Push the packet into the MAC queue
                        enqueuePacket(obj.MAC(sourceDeviceIdx(idx)), packetToQueue);
                    end
                end
            end
        end
    end
end
end
