function msdu = defaultMSDU()
%defaultMSDU Returns a default MSDU packet structure
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   MSDU = defaultMSDU returns a default application packet structure with
%   the following fields.
%
%   Packet               - An empty application packet
%   PacketID             - Application packet identifier
%   PacketLength         - Length of the application packet (in bytes)
%   PacketGenerationTime - Time of generation of application packet (in seconds)
%   SourceNodeID         - Node identifier of the source from which application
%                          packet has originated
%   AccessCategory       - Access category of the application packet
%   DestinationNodeID    - Identifier of the node to which the application
%                          packet is destined
%   DestinationNodeName  - Name of the node to which the application
%                          packet is destined

% Copyright 2025 The MathWorks, Inc.

msdu = struct(...
    'Packet', [], ...
    'PacketID', 0, ...
    'PacketLength', 0, ...
    'PacketGenerationTime', 0, ...
    'AccessCategory', 0, ...
    'SourceNodeID', [], ...
    'DestinationNodeID', [], ...
    'DestinationNodeName', '', ..., ...
    'TechnologyType', wnet.TechnologyType.WLAN, ...
    'Tags', []);
end