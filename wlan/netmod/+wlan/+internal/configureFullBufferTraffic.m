function configureFullBufferTraffic(apNode, fullBufferTrafficType, associatedStations)
%configureFullBufferTraffic Fills traffic buffer based on the given full
%buffer traffic configuration
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   configureFullBufferTraffic(NODE, FULLBUFFERCONFIGTYPE,
%   ASSOCIATEDSTATIONS) configures the nodes with full buffer traffic
%   context.
%
%   NODE is an object of type wlanNode.
%
%   FULLBUFFERCONFIGTYPE is an option string specified as "on", "DL", "UL",
%   or "none" representing bi-directional traffic, downlink traffic, uplink
%   traffic, or no traffic respectively.
%
%   ASSOCIATEDSTATIONS is a vector of objects of type wlanNode,
%   representing the list of stations associated to this AP.

% Copyright 2023-2025 The MathWorks, Inc.

switch fullBufferTrafficType
    case "on"
        % DL traffic - from AP to stations
        numStations = numel(associatedStations);
        setAPFullBufferTrafficContext(apNode, associatedStations);

        % UL traffic - from station nodes to AP
        for idx = 1:numStations
            setSTAFullBufferTrafficContext(associatedStations(idx), apNode);
        end

    case "DL"
        % DL traffic - from AP to stations
        setAPFullBufferTrafficContext(apNode, associatedStations);

    case "UL"
        numStations = numel(associatedStations);
        % UL traffic - from station nodes to AP
        for idx = 1:numStations
            setSTAFullBufferTrafficContext(associatedStations(idx), apNode);
        end
end
end
