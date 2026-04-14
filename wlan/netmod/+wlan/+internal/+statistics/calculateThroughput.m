function throughput = calculateThroughput(srcNode, destNode)
%calculateThroughput Calculate the throughput between source and
%destination nodes
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   calculateThroughput(SRCNODE, DESTNODE) calculates the throughput
%   between the source and destination nodes.
%
%   SRCNODE is an object or an array of objects of type wlanNode
%   representing the source node.
%
%   DESTNODE is an object or an array of objects of type wlanNode
%   representing the destination node.

% Copyright 2025 The MathWorks, Inc.

throughput = zeros(1, max(numel(srcNode), numel(destNode)));
for srcNodeIdx = 1:numel(srcNode)
    % Store the perSTAStats of each device of source node
    perSTAStatsCell = {};
    % Store the ID of nodes associated with the device
    srcAssociationInfo = {};
    for macIdx = 1:numel(srcNode(srcNodeIdx).MAC)
        macObj = srcNode(srcNodeIdx).MAC(macIdx);
        perSTAStats = getPerSTAStatistics(macObj);
        if ~isempty(perSTAStats)
            perSTAStatsCell = [perSTAStatsCell perSTAStats];
            srcAssociationInfo = [srcAssociationInfo [perSTAStats.AssociatedNodeID]];
        end
    end

    for destNodeIdx = 1:numel(destNode)
        % Intialize as 0 for a specific source-destination pair
        transmittedPayloadBytes = 0;
        for idx = 1: numel(perSTAStatsCell)
            % Find the index at which the values associated to the destination node are
            % stored in the perSTAStatsCell
            idxLogical = (srcAssociationInfo{idx} == destNode(destNodeIdx).ID);
            if any(idxLogical) % Increment only if nodes are associated
                perSTAStats = perSTAStatsCell{idx};
                % Add the values to transmitted payload bytes
                transmittedPayloadBytes = transmittedPayloadBytes + perSTAStats(idxLogical).TransmittedPayloadBytes;
            end
        end
        simulationTime = srcNode(srcNodeIdx).LastRunTime; %Time in seconds
        % Calculate the throughput
        tputIdx = max(srcNodeIdx, destNodeIdx);
        throughput(tputIdx) = (transmittedPayloadBytes*8*1e-6)/simulationTime;
    end
end
end