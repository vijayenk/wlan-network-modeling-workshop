function plr = calculatePLR(srcNode, destNode)
%calculatePLR Calculate the packet loss ratio between source and
%destination nodes
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   calculatePLR(SRCNODE, DESTNODE) calculates the packet loss ratio
%   between the source and destination nodes.
%
%   SRCNODE is an object or an array of objects of type wlanNode
%   representing the source node.
%
%   DESTNODE is an object or an array of objects of type wlanNode
%   representing the destination node.

% Copyright 2025 The MathWorks, Inc.

plr = zeros(1, max(numel(srcNode), numel(destNode)));
for srcNodeIdx = 1:numel(srcNode)
    % Store the perSTAStats of each device/link of source node
    perSTAStatsCell = {};
    % Store the ID of nodes associated with the device/link
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
        transmittedDataFrames = 0;
        retransmittedDataFrames = 0;
        % Iterate through all the perSTAStats
        for idx = 1: numel(perSTAStatsCell)
            % Find the index at which the values associated to the destination node are
            % stored in the perSTAStats
            idxLogical = (srcAssociationInfo{idx} == destNode(destNodeIdx).ID);
            if any(idxLogical) % Increment only if nodes are associated
                perSTAStats = perSTAStatsCell{idx};
                transmittedDataFrames = transmittedDataFrames + sum([perSTAStats(idxLogical).TransmittedDataFrames]);
                retransmittedDataFrames = retransmittedDataFrames + sum([perSTAStats(idxLogical).RetransmittedDataFrames]);
            end
        end
        plrIdx = max(srcNodeIdx, destNodeIdx);
        if transmittedDataFrames > 0
            plr(plrIdx) = retransmittedDataFrames/transmittedDataFrames;
        end
    end
end
end