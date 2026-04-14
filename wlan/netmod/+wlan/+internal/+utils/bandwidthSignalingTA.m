function macAddress = bandwidthSignalingTA(macAddress)
%bandwidthSignalingTA Converts given address into a bandwidth signaling address
%   MACADDRESS = bandwidthSignalingTA(MACADDRESS) converts the given MAC
%   address into a bandwidth signaling address. The input must be a string
%   or character vector representing a MAC address in hexadecimal format.

%   Copyright 2025 The MathWorks, Inc.

    macAddress = char(macAddress);
    byte1 = dec2hex(bitset(hex2dec(macAddress(1,1:2)), 1), 2);
    macAddress(1,1:2) = byte1;
end
