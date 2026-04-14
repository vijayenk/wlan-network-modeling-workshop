function [nodeID, deviceID] = macAddress2NodeID(macAddress)
%macAddress2NodeID Return node ID corresponding to the given MAC address
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [NODEID, DEVICEID] = macAddress2NodeID(MACADDRESS) returns the node ID
%   for the given MAC address, MACADDRESS.
%
%   NODEID value specifies the node ID for given MAC address.
%
%   DEVICEID value specifies the device ID for given MAC address.
%
%   MACADDRESS is a decimal vector with 6 elements, representing the 6
%   octets of the MAC address in decimal format.
%
%   See also wlan.internal.utils.nodeID2MACAddress.

%   Copyright 2022-2025 The MathWorks, Inc.

% Assign default value to output variable
macAddrDec = hex2dec((reshape(macAddress, 2, [])'))';
% Node address is broadcast address
if isequal(macAddrDec, [255 255 255 255 255 255])
    nodeID = 65535; % Broadcast Node ID
    deviceID = 1;
else
    nodeID = macAddrDec(end-1)*250+macAddrDec(end);
    deviceID = macAddrDec(2);
end
end
