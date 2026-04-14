function avgLatency = calculateLatency(srcNode, destNode)
%calculateLatency Calculate the average application packet latency
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   calculateLatency(SRCNODE, DESTNODE) calculates the average application
%   latency of the packets transmitted from source node to the destination
%   nodes.
%
%   SRCNODE is an object or an array of objects of type wlanNode
%   representing the source node.
%
%   DESTNODE is an object or an array of objects of type wlanNode
%   representing the destination node.

% Copyright 2025 The MathWorks, Inc.

avgLatency = zeros(1, max(numel(srcNode), numel(destNode)));
for destNodeIdx = 1:numel(destNode)
    % Store the latency stats of the destination node
    rxAppLatencyStats = destNode(destNodeIdx).RxAppLatencyStats;

    % If the destination node has not received any packets, RxAppLatencyStats
    % is an empty structure
    if ~isempty(rxAppLatencyStats)
        for srcNodeIdx = 1:numel(srcNode)
            % Find the index at which the values associated to the source node are
            % stored in the rxAppLatencyStats
            idxLogical = ([rxAppLatencyStats.SourceNodeID] == srcNode(srcNodeIdx).ID);
            % Calculate average latency only if destination node has received at least
            % one packet from source node
            if any(idxLogical) && rxAppLatencyStats(idxLogical).ReceivedPackets > 0
                latency = rxAppLatencyStats(idxLogical).AggregatePacketLatency/rxAppLatencyStats(idxLogical).ReceivedPackets;
                latencyIdx = max(srcNodeIdx, destNodeIdx);
                avgLatency(latencyIdx) = latency;
                destNode(destNodeIdx).RxAppLatencyStats(idxLogical).AveragePacketLatency = latency;
            end
        end
    end
end
end