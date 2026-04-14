function srcAddress = getSourceAddress(mpdu)
%getSourceAddress Extracts source address from the given MPDU
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   SRCADDRESS = getSourceAddress(MPDU) extracts source address from the
%   given MPDU structure.
%
%   MPDU is the structure of type wlan.internal.utils.defaultMPDU.
%
%   SRCADDRESS is the hexadecimal represention of the source address.

%   Copyright 2025 The MathWorks, Inc.

srcAddress = mpdu.Header.Address2; % Frame from STA or management type frame

if ~mpdu.Header.ToDS && mpdu.Header.FromDS % From AP
    srcAddress = mpdu.Header.Address3;

elseif mpdu.Header.ToDS && mpdu.Header.FromDS % From mesh
    isGroupAddress = wlan.internal.utils.isGroupAddress(mpdu.Header.Address1);
    if isGroupAddress
        srcAddress = mpdu.Header.Address3;
    else % unicast
        if mpdu.FrameBody.MeshControl.AddressExtensionMode == 2
            srcAddress = mpdu.FrameBody.MeshControl.Address6;
        else
            srcAddress = mpdu.Header.Address4;
        end
    end
end

end