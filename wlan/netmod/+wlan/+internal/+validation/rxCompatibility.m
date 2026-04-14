function rxCompatibility(node, packet, deviceID)
%rxCompatibility Validate Rx compatibility with the received packet
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   rxCompatibility(NODE, PACKET, DEVICEID) validates Rx compatibility with
%   the received packet.
%
%   NODE is an object of type wlanNode, representing the receiving node.
%
%   PACKET is the received wireless packet of type wirelessPacket.
%
%   DEVICEID is the device ID corresponding to the frequency on which the
%   packet is received.

%   Copyright 2025 The MathWorks, Inc.

if ~node.DisableValidation
    % MAC/PHY abstractions compatibility
    if node.IsPHYAbstracted % Node uses abstract PHY
        if ~packet.Abstraction
            error(message("wlan:wlanNode:IncompatiblePHYAbstraction"));
        end

        if node.IsMACFrameAbstracted % Node uses abstract MAC frame
            if packet.Metadata.MACDataType ~= node.DataTypeMACFrameStruct
                error(message("wlan:wlanNode:IncompatibleMACAbstraction"));
            end
        else % Node uses full MAC frame
            if packet.Metadata.MACDataType == node.DataTypeMACFrameStruct
                error(message("wlan:wlanNode:IncompatibleMACAbstraction"));
            end
        end

    else % Node uses Full PHY
        if packet.Abstraction
            error(message("wlan:wlanNode:IncompatiblePHYAbstraction"));
        end
    end

    % Antennas compatibility
    if (packet.TechnologyType == wnet.TechnologyType.WLAN) && ~node.IsEMLSRSTA && ((node.NumTransmitAntennas(deviceID)) ~= packet.NumTransmitAntennas)
        error(message("wlan:wlanNode:IncompatibleNumAntennas"));
    end
end
end