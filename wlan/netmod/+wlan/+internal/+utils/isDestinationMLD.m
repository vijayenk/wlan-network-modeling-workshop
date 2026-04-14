function flag = isDestinationMLD(node, destinationNodeID)
%isDestinationMLD Returns true if the destination is an MLD node
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FLAG = isDestinationMLD(NODE, DESTINATIONID) returns true if the
%   destination is an MLD node.
%
%   FLAG is a logical scalar indicating that the given destination is an
%   MLD node.
%
%   NODE is an object of type wlanNode.
%
%   DESTINATIONID is a scalar integer indicating the node ID of the
%   destination.

% Copyright 2023-2025 The MathWorks, Inc.

flag = false;

if destinationNodeID ~= 65535
    % MLDMeshNotSupported - In case of mesh or hybrid mesh node, currently only
    % non-MLD is supported. Hence, return false.
    if ~node.IsMeshNode
        if node.IsAPNode % AP
            % Check whether associated STA is an MLD STA. Currently, an MLD AP
            % associates with only MLD STAs.
            destSTAIdx = find(destinationNodeID == [node.RemoteSTAInfo(:).NodeID]);
            flag = node.RemoteSTAInfo(destSTAIdx).IsMLD;
        else % STA
            flag = node.RemoteSTAInfo.IsMLD;
        end
    end
else
    flag = node.IsMLDNode;
end
end
