function params = associationParams(node, associatedSTAs, nvPair)
%associationParams Validate the inputs of associateStations method of
%wlanNode
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   PARAMS = = associationParams(NODE, ASSOCIATEDSTAS, NVPAIR) validates
%   the inputs specified in associateStations method of wlanNode object,
%   NODE.
%
%   PARAMS specifies a structure with the following fields interpreted from
%   the specified NV pair options. See the NV pair descriptions below for
%   more details:
%       BandAndChannel
%       FullBufferTraffic
%
%   NODE is an object of type wlanNode, at which associateStations method is
%   called.
%   
%   ASSOCIATEDSTAS is a list of node objects of type wlanNode, specifying
%   the list of stations to be associated to the AP node, NODE.
%
%   NVPAIR specifies the name-value arguments specified in associateStations
%   method of wlanNode object, NODE. Expected name-value arguments validated
%   are as follows:
%
%   BandAndChannel        - Band and channel to be used to create a BSS.
%                           For association between non-multilink device
%                           (non-MLD) AP and non-MLD STAs or MLD AP and
%                           non-MLD STAs,
%                           * Specify the value as a row vector containing
%                             two elements. The first element represents
%                             band and accepted values are 2.4, 5 and 6
%                             (GHz).
%                             The second element represents any valid
%                             channel number in the specified band.
%                           * The default value is automatically determined
%                             by the node by finding the band and channel
%                             at AP such that the primary 20 MHz subchannel
%                             is included in operating frequency range of
%                             STAs.
%                           For association between MLD AP and MLD STAs,
%                           * Specify the value as an N-by-2 matrix with
%                             each row containing a band and channel
%                             number.
%                           * The default value is a matrix that the
%                             node creates by placing band and channel of
%                             each configured link of AP in a row.
%
%   FullBufferTraffic     - Set full buffer traffic between the AP and
%                           the given list of stations. Following are the
%                           allowed values for this parameter:
%                           "off"   - Full buffer traffic is disabled.
%                           "on"    - Configures two-way full buffer
%                                     traffic between the given AP and
%                                     stations.
%                           "DL"    - Configures full buffer downlink
%                                     traffic from AP to stations.
%                           "UL"    - Configures full buffer uplink
%                                     traffic from stations to the AP.
%                           When full buffer traffic is enabled, the packet
%                           size is 1500 and the access category is 0. If
%                           full buffer traffic is enabled, custom traffic
%                           source cannot be added for access category 0
%                           through <a
%                           href="matlab:help('wlanNode.addTrafficSource')">addTrafficSource</a>. The default value is
%                           "off".

%   Copyright 2025 The MathWorks, Inc.

% Validate inputs
validateattributes(node, {'wlanNode'}, {'scalar'}, 'wlanNode', 'AP node object');
if ~node.DisableValidation
    if ~node.IsAPNode
        error(message('wlan:wlanNode:MustBeAP'));
    end
    validateattributes(associatedSTAs, {'wlanNode'}, {'vector'}, 'wlanNode', '', 2);
    if any(arrayfun(@(x) x.IsAPNode || x.IsMeshNode, associatedSTAs, UniformOutput=true))
        error(message('wlan:wlanNode:NonSTAInSTAList'));
    end
    if ~node.IsMLDNode % Non-MLD
        if any(arrayfun(@(x) x.IsMLDNode, associatedSTAs, UniformOutput=true))
            error(message('wlan:wlanNode:InvalidSTADeviceType', node.Name));
        end
    else % MLD
        numLinks = numel(node.DeviceConfig.LinkConfig);
        mldSTAs = associatedSTAs([associatedSTAs(:).IsMLDNode]);
        if any(arrayfun(@(x) numel(x.DeviceConfig.LinkConfig), mldSTAs, UniformOutput=true) ~= numLinks)
            error(message('wlan:wlanNode:UnequalNumLinks'));
        end
    end
    % Validate NV pairs
    if mod(numel(nvPair),2)
        error(message('wlan:ConfigBase:InvalidPVPairs'));
    end
end

params = struct(BandAndChannel=[], FullBufferTraffic="off");
for idx = 1:2:numel(nvPair)
    paramName = nvPair{idx};
    paramValue = nvPair{idx+1};
    if ~node.DisableValidation
        paramName = validatestring(paramName, ["BandAndChannel", "FullBufferTraffic"], 'wlanNode', 'parameter name');
        switch paramName
            case 'BandAndChannel'
                validateattributes(paramValue, {'numeric'}, {'nonempty', 'ncols',2}, 'wlanNode', paramName);
                numRows = size(paramValue, 1);
                for rowIdx = 1:numRows
                    wlan.internal.validation.bandAndChannel(paramValue(rowIdx, :), paramName);
                end
            otherwise % 'FullBufferTraffic'
                paramValue = validatestring(paramValue, ["on", "off", "DL", "UL"], 'wlanNode', paramName);
        end
    end
    params.(paramName) = paramValue;
end
end
