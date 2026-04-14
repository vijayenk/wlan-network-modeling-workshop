function trafficInfoPerDestination = trafficParams(node, options)
%trafficParams Validate the NV pairs for addTrafficSource method of
%wlanNode
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   TRAFFICINFOPERDESTINATION = trafficParams(NODE, OPTIONS) validates the
%   NV pair options, OPTIONS, specified in addTrafficSource method of
%   wlanNode object, NODE.
%
%   TRAFFICINFOPERDESTINATION is a structure with the following fields:
%       DestinationNodeID   - ID of the destination node, specified as a
%                             number
%       DestinationNodeName - Name of the destination node, specified as a
%                             string
%       AccessCategory      - Access category specified for the traffic, 
%                             specified as a number
%       TechnologyType      - Integer indication WLAN as technology type,
%                             always returned as wnet.TechnologyType.WLAN.
%
%   NODE is an object of type wlanNode.
%
%   OPTIONS is a structure holding the NV pairs specified to
%   addTrafficSource method of wlanNode object.

%   Copyright 2025 The MathWorks, Inc.

% Initialize NV Params
params = struct(DestinationNode=[], AccessCategory=0);
% Validate options (N-V pairs of addTrafficSource)
if isfield(options,'DestinationNode')
    if ~node(1).DisableValidation
        if ~isscalar(node) && ~isscalar(options.DestinationNode)
            error(message('wlan:wlanNode:UnsupportedMultipleSrcMultipleDest'));
        end
    end
    params.DestinationNode = options.DestinationNode;
end

if isfield(options,'AccessCategory')
    params.AccessCategory = options.AccessCategory;
end

% Initialize a template for traffic information
trafficInfoTemplate = struct(DestinationNodeID=[], DestinationNodeName="", AccessCategory=0, TechnologyType=wnet.TechnologyType.WLAN);
trafficInfoTemplate.AccessCategory = params.AccessCategory;
trafficInfoPerDestination = trafficInfoTemplate;
if ~isempty(params.DestinationNode)
    % Validate each source destination node pair and update the traffic information
    destinationNodes = params.DestinationNode;
    trafficInfoPerDestination = repmat(trafficInfoTemplate, 1, numel(destinationNodes));
    numSources = numel(node);
    sourceNodeIDs = zeros(numSources, 1);
    for srcIdx = 1:numSources
        srcNode = node(srcIdx);
        numDestinations = numel(destinationNodes);
        destinationNodeIDs = zeros(numDestinations, 1);
        for destIdx = 1:numDestinations
            if ~node(1).DisableValidation
                % Error when source is AP and destination is not an
                % associated station. Allow when the node has a mesh
                % device (AP+Mesh node).
                isDestinationAssociatedSTA = false;
                if ~isempty(srcNode.RemoteSTAInfo)
                    destIdxLogical = (destinationNodes(destIdx).ID == [srcNode.RemoteSTAInfo(:).NodeID]);
                    if any(destIdxLogical) % Destination is an associated STA or peer mesh STA
                        aid = srcNode.RemoteSTAInfo(destIdxLogical).AID;
                        isDestinationAssociatedSTA = (aid ~= 0); % Non-zero AID indicates destination is one of the associated STAs
                    end
                end
                if (srcNode.IsAPNode && ~srcNode.IsMeshNode) && (isempty(srcNode.RemoteSTAInfo) || ~isDestinationAssociatedSTA)
                    error(message('wlan:wlanNode:APDestinationUnassociated'));
                end
                % Error when source is STA and
                %   * Unassociated
                %   * Destination is not in the same BSS
                isSTA = ~srcNode.IsAPNode && ~srcNode.IsMeshNode;
                if isSTA
                    if ~srcNode.MAC(1).IsAssociatedSTA % First index should suffice as this is same for all devices
                        error(message('wlan:wlanNode:STADestinationUnassociated'));
                    else
                        % Check if a common BSS exists between the source and destination node
                        commonBSSFound = false;
                        for srcDevIdx = 1:numel(srcNode.MAC)
                            commonBSSFound = any(arrayfun(@(x) strcmp(x.BSSID, srcNode.MAC(srcDevIdx).BSSID), destinationNodes(destIdx).MAC));
                            if commonBSSFound
                                break;
                            end
                        end
                        if ~commonBSSFound
                            error(message('wlan:wlanNode:STADestinationUnassociated'));
                        end
                    end
                end

                % Error for duplicate traffic source (Validates for duplicate source/destination between different addTrafficSource calls)
                if any((destinationNodes(destIdx).ID == [srcNode.Application.PacketInfo(:).DestinationNodeID]) & ...
                        (params.AccessCategory == [srcNode.Application.PacketInfo(:).AccessCategory]))
                    error(message('wlan:wlanNode:DuplicateTrafficSource', srcNode.Name, destinationNodes(destIdx).Name, params.AccessCategory));
                end

                destinationNodeIDs(destIdx) = destinationNodes(destIdx).ID;
                % Error for duplicate traffic source (Validates for duplicate destinations in same addTrafficSource call)
                if destIdx > 1 && any(destinationNodes(destIdx).ID == destinationNodeIDs(1:destIdx-1))
                    error(message('wlan:wlanNode:DuplicateTrafficSource', srcNode.Name, destinationNodes(destIdx).Name, params.AccessCategory));
                end
            end
            trafficInfoPerDestination(destIdx).DestinationNodeID = destinationNodes(destIdx).ID;
            trafficInfoPerDestination(destIdx).DestinationNodeName = destinationNodes(destIdx).Name;
        end
        if ~node(1).DisableValidation
            sourceNodeIDs(srcIdx) = srcNode.ID;
            % Error for duplicate traffic source (Validates for duplicate sources in same addTrafficSource call)
            if srcIdx > 1 && any(srcNode.ID == sourceNodeIDs(1:srcIdx-1))
                error(message('wlan:wlanNode:DuplicateTrafficSource', srcNode.Name, destinationNodes(destIdx).Name, params.AccessCategory));
            end
        end
    end

else % No value provided for DestinationNode argument
    for nodeIdx = 1:numel(node)
        if ~node(1).DisableValidation
            devCfg = node(nodeIdx).DeviceConfig;
            devType = "device";

            if node(nodeIdx).IsMLDNode
                if node(nodeIdx).IsAPNode % AP MLD
                    % Check whether any of the associated STAs is an EMLSR STA
                    if any([node(nodeIdx).RemoteSTAInfo(:).EnhancedMLMode])
                        error(message('wlan:wlanNode:UnsupportedBroadcastAPMLD', node(nodeIdx).Name));
                    end
                else % STA MLD
                    if strcmp(node(nodeIdx).DeviceConfig.EnhancedMultilinkMode, "EMLSR")
                        error(message('wlan:wlanNode:UnsupportedBroadcastEMLSRSTA', node(nodeIdx).Name));
                    end
                end

                devCfg = devCfg.LinkConfig;
                devType = "link";
            end

            % Broadcast traffic is not supported with OFDMA transmissions
            for idx=1:numel(devCfg)
                if strcmp(devCfg(idx).TransmissionFormat, "HE-MU-OFDMA")
                    error(message('wlan:wlanNode:BroadcastUnsupportedWithOFDMA', devType, idx, node(nodeIdx).Name));
                end
            end

            % Broadcast (with Best Effort) and Full Buffer not supported (DuplicateTrafficSource)
            if params.AccessCategory == 0 && node(nodeIdx).FullBufferTrafficEnabled
                error(message('wlan:wlanNode:DuplicateTrafficSource', node(nodeIdx).Name, "Broadcast", params.AccessCategory));
            end
        end
    end
end
end
