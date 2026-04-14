function flag = isMPDUAggregationEnabled(node, deviceIdx)
%isMPDUAggregationEnabled Returns true if MPDU aggregation is enabled
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FLAG = isMPDUAggregationEnabled(NODE, DEVICEID) returns true if MPDU
%   aggregation is enabled.
%
%   FLAG is a logical scalar indicating if MPDU aggregation is enabled
%
%   NODE is an object of type wlanNode.
%
%   DEVICEID is the ID of device within the node for which MPDU aggregation
%   is checked.

% Copyright 2023-2025 The MathWorks, Inc.

if ~node.IsMLDNode
    cfg = node.DeviceConfig(deviceIdx);
else
    cfg = node.DeviceConfig.LinkConfig(deviceIdx);
end

flag = true;
if strcmp(cfg.TransmissionFormat, 'Non-HT') || (strcmp(cfg.TransmissionFormat, 'HT-Mixed') && ~cfg.AggregateHTMPDU)
    flag = false;
end

end
