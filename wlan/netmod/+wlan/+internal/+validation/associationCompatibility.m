function associationCompatibility(node, associatedSTA, deviceIdx, associatedSTADeviceIdx)
%associationCompatibility Validate compatibility of association parameters
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   associationCompatibility(NODE, ASSOCIATEDSTA, DEVICEIDX,
%   ASSOCIATEDSTADEVICEIDX) validates the compatibility of association
%   parameters.
%
%   NODE is an object of type wlanNode, specifying the AP node.
%
%   ASSOCIATEDSTA is an object of type wlanNode, specifying the associated
%   STA node.
%
%   DEVICEIDX is the device ID of the AP node for which compatibility is
%   being validated.
%
%   ASSOCIATEDSTADEVICEIDX is the device ID of the STA node for which
%   compatibility is being validated.

%   Copyright 2025 The MathWorks, Inc.

if ~node.DisableValidation
    devCfg = wlan.internal.utils.getDeviceConfig(node, deviceIdx);
    assocSTADevCfg = wlan.internal.utils.getDeviceConfig(associatedSTA, associatedSTADeviceIdx);
    if devCfg.MPDUAggregationLimit ~= assocSTADevCfg.MPDUAggregationLimit
        error(message("wlan:wlanNode:IncompatibleMPDUAggregationLimit"));
    end
end
end