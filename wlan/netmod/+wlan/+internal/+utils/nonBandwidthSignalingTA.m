function [macAddress, isBWSigPresent] = nonBandwidthSignalingTA(macAddress)
%nonBandwidthSignalingTA Converts given address into a non-bandwidth signaling address
%   [MACADDRESS, ISBWSIGPRESENT] = nonBandwidthSignalingTA(MACADDRESS)
%   converts the given MAC address into a non-bandwidth signaling address.
%   The input must be a string or character vector representing a MAC
%   address in hexadecimal format. It also indicates if bandwidth signaling
%   is indicated in the MAC address through the flag, ISBWSIGPRESENT.

%   Copyright 2024-2025 The MathWorks, Inc.

    macAddress = char(macAddress);
    origByte1 = macAddress(1,1:2);
    modByte1 = dec2hex(bitset(hex2dec(macAddress(1,1:2)), 1, 0), 2);
    macAddress(1,1:2) = modByte1;
    isBWSigPresent = ~all(origByte1 == modByte1);
end
