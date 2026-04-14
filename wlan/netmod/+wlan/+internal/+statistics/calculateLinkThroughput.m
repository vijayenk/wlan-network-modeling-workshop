function throughput = calculateLinkThroughput(srcNode, destNode, bandAndChannel)
%calculateLinkThroughput Calculate the throughput of the links specified by
%bandAndChannel between the source and destination nodes.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   calculateLinkThroughput(SRCNODE, DESTNODE, BANDANDCHANNEL) calculates
%   the throughput of the link specified by the band and channel,
%   BANDANDCHANNEL, between the source and destination nodes.
%
%   SRCNODE is an object or an array of objects of type wlanNode
%   representing the source node.
%
%   DESTNODE is an object or an array of objects of type wlanNode
%   representing the destination node.
%
%   BANDANDCHANNEL is a vector of 2 values representing band and channel
%   number respectively that indicates the link between source and
%   destination node on which throughput is calculated.

% Copyright 2025 The MathWorks, Inc.

throughput = zeros(1, max(numel(srcNode), numel(destNode)));
for srcNodeIdx = 1:numel(srcNode)
    % Find the index of the specified link
    macIdx = all([srcNode(srcNodeIdx).SharedMAC.BandAndChannel] == bandAndChannel, 2);
    macObj = srcNode(srcNodeIdx).MAC(macIdx);

    % Check that the source node has atleast one device operating on the
    % specified band and channel
    if ~isempty(macObj)
        perSTAStats = getPerSTAStatistics(macObj);

        % perSTAStats will be an empty structure if the device; macObj has no
        % associations
        if ~isempty(perSTAStats)
            associatedNodeID = [perSTAStats.AssociatedNodeID];

            for destNodeIdx = 1:numel(destNode)
                % Intialize as 0 for a specific source-destination pair
                transmittedPayloadBytes = 0;
                if any(associatedNodeID == destNode(destNodeIdx).ID) % Increment only if nodes are associated
                    % Add the values to transmitted payload bytes
                    transmittedPayloadBytes = transmittedPayloadBytes + ...
                        perSTAStats(associatedNodeID == destNode(destNodeIdx).ID).TransmittedPayloadBytes;
                end
                simulationTime = srcNode(srcNodeIdx).LastRunTime; %Time in seconds
                tputIdx = max(srcNodeIdx, destNodeIdx);
                throughput(tputIdx) = (transmittedPayloadBytes*8*1e-6)/simulationTime;
            end
        end
    end
end
end