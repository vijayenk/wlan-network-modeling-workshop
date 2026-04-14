function plr = calculateLinkPLR(srcNode, destNode, bandAndChannel)
%calculateLinkPLR Calculate the packet loss ratio of the specified link
%between the source and destination node
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   calculateLinkPLR(SRCNODE, DESTNODE, BANDANDCHANNEL) calculates the
%   packet loss ratio of the link specified by the band and channel,
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
%   destination node on which PLR is calculated.

% Copyright 2025 The MathWorks, Inc.

plr = zeros(1, max(numel(srcNode), numel(destNode)));
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
            associatedNodeID = perSTAStats.AssociatedNodeID;

            for destNodeIdx = 1:numel(destNode)
                % Intialize as 0 for a specific source-destination pair
                transmittedDataFrames = 0;
                retransmittedDataFrames = 0;
                if any(associatedNodeID == destNode(destNodeIdx).ID) % Increment only if nodes are associated
                    transmittedDataFrames = transmittedDataFrames + ...
                        perSTAStats(associatedNodeID == destNode(destNodeIdx).ID).TransmittedDataFrames;
                    retransmittedDataFrames = retransmittedDataFrames + ...
                        perSTAStats(associatedNodeID == destNode(destNodeIdx).ID).RetransmittedDataFrames;
                end
                plrIdx = max(srcNodeIdx, destNodeIdx);
                if transmittedDataFrames > 0
                    plr(plrIdx) = retransmittedDataFrames/transmittedDataFrames;
                end
            end
        end
    end
end
end