function flag = isGroupAddress(macAddress)
%isGroupAddress Returns true if given MAC address is a groupcast address
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FLAG = isGroupAddress(MACADDRESS) returns true if the given MAC
%   address, MACADDRESS, is a groupcast address.
%
%   FLAG is a logical scalar indicating whether MAC address is a groupcast
%   address
%
%   MACADDRESS is a 12-element string or character vector representing
%   6-octet hexadecimal value.

% Copyright 2023-2025 The MathWorks, Inc.

flag = rem(hex2dec(macAddress(1:2)), 2);

end
