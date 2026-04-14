function meshSourceAddress = getMeshSourceAddress(mpdu)
%getMeshSourceAddress Extracts mesh source address from the given MPDU
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   MESHSOURCEADDRESS = getMeshSourceAddress(MPDU) extracts mesh source
%   address from the given MPDU structure.
%
%   MPDU is the structure of type wlan.internal.utils.defaultMPDU.
%
%   MESHSOURCEADDRESS is the hexadecimal represention of the mesh source
%   address.

%   Copyright 2025 The MathWorks, Inc.

if wlan.internal.utils.isGroupAddress(mpdu.Header.Address1)
    meshSourceAddress = mpdu.Header.Address3;
else
    meshSourceAddress = mpdu.Header.Address4;
end
end
