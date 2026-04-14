function devCfg = getDeviceConfig(node, devIdx)
%getDeviceConfig Returns device configuration object(s)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEVCFG = getDeviceConfig(NODE) returns a scalar or a vector of objects
%   representing device or link configurations based on whether the NODE is
%   an MLD node or a non-MLD node.
%
%   DEVCFG is a scalar or a vector of objects of type wlanDeviceConfig if
%   the node, NODE, is a non-MLD node. It is a scalar or a vector of objects
%   of type wlanLinkConfig if the node, NODE, is an MLD node. This is a
%   vector of object when the node contains multiple devices/links.
%
%   NODE is an object of type wlanNode.
%
%   DEVCFG = getDeviceConfig(NODE, DEVIDX) returns a scalar object of type
%   wlanDeviceConfig or wlanLinkConfig corresponding to the specified
%   device index, DEVIDX.

%   Copyright 2025 The MathWorks, Inc.

if nargin == 1
    if node.IsMLDNode
        devCfg = [node.DeviceConfig.LinkConfig];
    else
        devCfg = [node.DeviceConfig];
    end
else
    if node.IsMLDNode
        devCfg = node.DeviceConfig.LinkConfig(devIdx);
    else
        devCfg = node.DeviceConfig(devIdx);
    end
end
end