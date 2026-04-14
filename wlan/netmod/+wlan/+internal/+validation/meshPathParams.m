function [meshPathNode, params] = meshPathParams(node, nInputs, destinationNode, varargin)
%meshPathParams Validate the inputs of addMeshPath method of wlanNode
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   [MESHPATHNODE, PARAMS] = meshPathParams(NODE, NINPUTS, DESTINATIONNODE)
%   validates the inputs specified in addMeshPath method of wlanNode
%   object, NODE.
%
%   MESHPATHNODE is an object of type wlanNode, specifying the next hop
%   node interpreted from the number of input arguments, NINPUTS, specified
%   in addMeshPath method of wlanNode object, NODE.
%
%   PARAMS specifies a structure with the following fields interpreted from
%   the specified NV pair options. See the NV pair descriptions below for
%   more details:
%       SourceBandAndChannel
%       MeshPathBandAndChannel
%       DestinationBandAndChannel
%
%   NODE is an object of type wlanNode, at which mesh path is being added.
%   
%   NINPUTS is the number of input arguments specified in the addMeshPath
%   method of wlanNode object, NODE.
%
%   DESTINATIONNODE is an object of type wlanNode, to which mesh path is
%   being added.
%
%   [...] = = meshPathParams(..., Name=Value) specified additional
%   name-value arguments to be validated. Expected name-value arguments
%   validated are as follows:
%
%   SourceBandAndChannel       - Band and channel on which the source
%                                node must transmit packets to the next hop
%                                node. Specify this input as a vector of
%                                two values. The first value must be 2.4,
%                                5, or 6 and the second value must be a
%                                valid channel number in the band.
%
%                                The input uses this default configuration:
%                                * If the mesh path node is the next hop
%                                  node, the function selects the common
%                                  band and channel between the source node
%                                  and next hop node. If there are multiple
%                                  common band-channel pairs, you must
%                                  specify a value for this input.
%                                * If the mesh path node is the proxy mesh
%                                  gate, the function selects the band and
%                                  channel belonging to a mesh device. If
%                                  there are multiple mesh devices, you
%                                  must specify a value for this input.
%
%   MeshPathBandAndChannel     - Band and channel on which the mesh path
%                                node must receive the packets. Specify
%                                this input as a vector of two values. The
%                                first value must be 2.4, 5, or 6 and the
%                                second value must be a valid channel
%                                number in the band.
%
%                                The input uses this default configuration:
%                                * If the mesh path node is the next hop
%                                  node, the function selects the common
%                                  band and channel between the source node
%                                  and next hop node.
%                                * If the mesh path node is the proxy mesh
%                                  gate, the function selects the band and
%                                  channel belonging to a mesh device. If
%                                  there are multiple mesh devices, you
%                                  must specify a value for this input.
%
%   DestinationBandAndChannel  - Band and channel on which the destination
%                                node should receive the packets. Specify
%                                this input as a vector of two values. The
%                                first value must be 2.4, 5, or 6 and the
%                                second value must be a valid channel
%                                number in the band.
%
%                                The input uses this default configuration:
%                                * If the destination node is a mesh node,
%                                  the function selects the band and
%                                  channel belonging to a mesh device. If
%                                  there are multiple mesh devices, you
%                                  must specify a value for this input.
%                                * If the destination node is a non-mesh
%                                  node and only one device is present, the
%                                  function selects the band and channel of
%                                  that device in the node. If there are
%                                  multiple devices, you must specify a
%                                  value for this input.

%   Copyright 2025 The MathWorks, Inc.

if ~node.DisableValidation
    if ~node.IsMeshNode
        error(message('wlan:wlanNode:MustBeMesh', 'first'));
    end
    validateattributes(destinationNode, {'wlanNode'}, {'scalar'}, '', 'destination node');
end
if (mod(nInputs, 2) == 0) % mesh path node not given as input
    if ~node.DisableValidation && ~destinationNode.IsMeshNode
        error(message('wlan:wlanNode:NeedProxyNode'));
    end
    meshPathNode = destinationNode;
    nvPair = varargin;
else % mesh path node given as input
    meshPathNode = varargin{1};
    if ~node.DisableValidation
        validateattributes(meshPathNode, {'wlanNode'}, {'scalar'}, '', 'mesh path node');
        if ~meshPathNode.IsMeshNode
            error(message('wlan:wlanNode:MustBeMesh', 'third'));
        end
    end
    nvPair = varargin(2:end);
end

% NV pairs
params = struct(SourceBandAndChannel=[], MeshPathBandAndChannel=[], DestinationBandAndChannel=[]);
for idx = 1:2:numel(nvPair)
    paramName = nvPair{idx};
    if ~node.DisableValidation
        paramName = validatestring(nvPair{idx}, ["SourceBandAndChannel" "MeshPathBandAndChannel" "DestinationBandAndChannel"], 'wlanNode', 'parameter name');
        validateattributes(nvPair{idx+1}, {'numeric'}, {'row'}, 'wlanNode', paramName);
        wlan.internal.validation.bandAndChannel(nvPair{idx+1}, paramName);
    end
    params.(paramName) = nvPair{idx+1};
end
end