function kpiParams(srcNode, destNode, bandAndChannel)
%kpiParams Validates inputs to kpi method
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   kpiParams(SRCNODE, DESTNODE, BANDANDCHANNEL) validates inputs specified
%   in kpi method.
%
%   SRCNODE is an object of type wlanNode, representing the source node.
%
%   DESTNODE is an object of type wlanNode, representing the destination node.
%
%   BANDANDCHANNEL is a vector of two elements representing band and
%   channel number values. This value is non-empty when the user wants to
%   calculate KPIs for a specific operating link between source and
%   destination nodes identified by the band and channel.

%   Copyright 2025 The MathWorks, Inc.

if ~srcNode(1).DisableValidation
    % Check if atleast one of the inputs is scalar
    if ~isscalar(srcNode) && ~isscalar(destNode)
        error(message('wlan:wlanNode:KPIInvalidSignature'));
    end

    % Store information about mode: AP or STA or MESH
    srcMode = [];
    destMode = [];

    for i = 1:numel(srcNode)
        srcMode = [srcMode operatingMode(srcNode(i))];
    end

    for i = 1:numel(destNode)
        destMode = [destMode operatingMode(destNode(i))];
    end

    % Check if any of the source or destination nodes is a mesh node
    if any(strcmp(srcMode, 'mesh')) || any(strcmp(destMode, 'mesh'))
        error(message('wlan:wlanNode:MustBeAPOrSTA'));
    end

    % Check if all nodes in vector are operating in same mode
    if ~all(strcmp(srcMode(1), srcMode))
        error(message('wlan:wlanNode:KPIMustHaveSameMode', 'source nodes'));
    end

    if ~all(strcmp(destMode(1), destMode))
        error(message('wlan:wlanNode:KPIMustHaveSameMode', 'destination nodes'));
    end

    % Check if one STA is mapped to multiple AP
    if (~isscalar(srcNode) &&  isequal(destMode(1),'STA')) || ...
            (~isscalar(destNode) && isequal(srcMode(1),'STA'))
        error(message('wlan:wlanNode:UnsupportedInputCombination'));
    end

    % Check if source and destination nodes are a valid pair
    % While the kpi function doesn't allow STA/STA pair, internal support for
    % calculation of latency between two STA nodes is present
    modePair = srcMode(1) + "/" + destMode(1);
    validModePairs = ["AP/STA", "STA/AP"];
    if ~any(strcmp(modePair,validModePairs))
        error(message('wlan:wlanNode:KPIInvalidModeCombination', modePair, validModePairs(1), validModePairs(2)));
    end

    if ~isempty(bandAndChannel)
        % Validate the bandAndChannel values
        validateattributes(bandAndChannel, {'numeric'}, {'row'}, 'wlanNode', 'BandAndChannel');
        wlan.internal.validation.bandAndChannel(bandAndChannel, 'BandAndChannel');

        % Check if there is atleast one source node operating on specified
        % bandAndChannel
        srcValid = false;
        for i = 1:numel(srcNode)
            if any(all([srcNode(i).SharedMAC.BandAndChannel] == bandAndChannel, 2))
                srcValid = true;
            end
        end

        % Check if there is atleast one destination node operating on specified
        % bandAndChannel
        destValid = false;
        for i = 1:numel(destNode)
            if any(all([destNode(i).SharedMAC.BandAndChannel] == bandAndChannel, 2))
                destValid = true;
            end
        end

        if ~(srcValid && destValid)
            error(message('wlan:wlanNode:KPINoCommonBandAndChannel', string(bandAndChannel(1)), bandAndChannel(2)));
        end
    end
end
end

function mode = operatingMode(node)
%operatingMode Returns the operation mode of the node

if node.IsMeshNode
    mode = "mesh";
elseif node.IsAPNode
    mode = "AP";
else
    mode = "STA";
end
end