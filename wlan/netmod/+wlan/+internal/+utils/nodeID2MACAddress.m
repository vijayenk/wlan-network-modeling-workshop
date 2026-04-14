function macAddr = nodeID2MACAddress(nodeID)
%nodeID2MACAddress Returns MAC address corresponding to the given node ID
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   MACADDR = nodeID2MACAddress(NODEID) returns the MAC address for the
%   given node with ID, NODEID.
%
%   MACADDR is a character vector with 12 elements, representing the 6
%   octets of the MAC address in hexadecimal format.
%
%   NODEID is specified as either scalar or vector. If it is scalar, the
%   value specifies the node ID. If it is vector ([NODEID DEVICEID]),
%   the value specifies the node ID, NODEID along with the device ID,
%   DEVICEID.
%
%   See also wlan.internal.utils.macAddress2NodeID.

%   Copyright 2022-2025 The MathWorks, Inc.

if numel(nodeID) > 1
    % Extract the node ID and device ID, if vector
    nID = nodeID(1);
    deviceID = nodeID(2);
else
    % Extract the node ID and assign default device ID, if scalar
    nID = nodeID;
    deviceID = 1;
end

% Generate a MAC address, use the 2nd byte for the device ID and use
% ultimate and penultimate bytes for node ID.
if nID == 65535 % Broadcast Node ID
    macAddrDec = [255 255 255 255 255 255];
else % nID > 0
    % MAC address break-up
    %   * Byte 1    - Contains the information about MAC address type. All MAC
    %   addresses that are locally managed should set Bit-1 (second bit from
    %   LSB) of the first byte to 1. Set it to 0 to use globally unique (OUI
    %   enforced) MAC addresses. This function assigns MAC addresses that are
    %   locally administrated.
    %   * Byte 2    - Contains device ID or link ID
    %   * Bytes 3,4 - Unused
    %   * Bytes 5,6 - Contains node ID
    macAddrDec = [2 deviceID 0 0 floor(nID/250) rem(nID, 250)];
end
macAddr = reshape(dec2hex(macAddrDec, 2)', 1, []);
end
