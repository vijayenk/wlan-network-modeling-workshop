function meshDestAddress = getMeshDestinationAddress(mpdu)
%getMeshDestinationAddress Extracts mesh destination address from the given MPDU
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   MESHDESTINATIONADDRESS = getMeshDestinationAddress(MPDU) extracts mesh
%   destination address from the given MPDU structure.
%
%   MPDU is the structure of type wlan.internal.utils.defaultMPDU.
%
%   MESHDESTINATIONADDRESS is the hexadecimal represention of the mesh
%   destination address.

%   Copyright 2025 The MathWorks, Inc.

if wlan.internal.utils.isGroupAddress(mpdu.Header.Address1)
    meshDestAddress = mpdu.Header.Address1;
else
    meshDestAddress = mpdu.Header.Address3;
end
end
