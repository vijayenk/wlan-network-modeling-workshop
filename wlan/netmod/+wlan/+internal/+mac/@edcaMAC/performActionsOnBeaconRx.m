function performActionsOnBeaconRx(obj, rxMPDU)
%performActionsOnBeaconRx Perform actions based on the received beacon
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   performActionsOnBeaconRx(OBJ, RXMPDU) performs actions based on the
%   received beacon.
%       1. If EDCA parameter set is updated, the updated parameters are
%          adopted by the STA (based on whether updating is enabled through
%          AllowEDCAParamsUpdate flag).
%       2. Beacon frame relevant statistics are updated.
%   
%   OBJ is an object of type wlan.internal.mac.edcaMAC.
%
%   RXMPDU is the received MPDU structure defined in
%   wlan.internal.utils.defaultMPDU.

%   Copyright 2025 The MathWorks, Inc.

% Apply EDCA Parameters from the beacon if STA receives a beacon with
% updated EDCA Parameter set
if obj.IsAssociatedSTA && obj.AllowEDCAParamsUpdate && strcmp(rxMPDU.Header.Address2, obj.BSSID)
    edcaParamsUpdated = false;
    if obj.IsAffiliatedWithMLD
        linkIdx = getLinkIndex(obj);
        if obj.SharedMAC.EDCAParamsCount(linkIdx) < rxMPDU.FrameBody.EDCAParamsCount
            edcaParamsUpdated = true;
            obj.SharedMAC.EDCAParamsCount(linkIdx) = rxMPDU.FrameBody.EDCAParamsCount;
        end
    else
        if obj.SharedMAC(obj.DeviceID).EDCAParamsCount < rxMPDU.FrameBody.EDCAParamsCount
            edcaParamsUpdated = true;
            obj.SharedMAC(obj.DeviceID).EDCAParamsCount = rxMPDU.FrameBody.EDCAParamsCount;
        end
    end

    if edcaParamsUpdated
        obj.AIFS = rxMPDU.FrameBody.AIFS;
        obj.CWMin = rxMPDU.FrameBody.CWMin;
        obj.CWMax = rxMPDU.FrameBody.CWMax;
        obj.TXOPLimit = rxMPDU.FrameBody.TXOPLimit;
    end
end

% Store other APs information
if obj.IsAPDevice
    isExistingNeighborAPInfo = false;
    rxNodeID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2);
    % Check if an entry exists for this neighbor AP
    for nodeIdx = 1:numel(obj.SharedMAC.RemoteSTAInfo)
        if rxNodeID == obj.SharedMAC.RemoteSTAInfo(nodeIdx).NodeID
            isExistingNeighborAPInfo = true;
        end
    end
    % Add an entry for this neighboring AP if there is no existing entry
    if ~isExistingNeighborAPInfo
        neighborAPNodeID = wlan.internal.utils.macAddress2NodeID(rxMPDU.Header.Address2);
        remoteSTAInfo = wlan.internal.utils.defaultRemoteSTAInfo;
        remoteSTAInfo.NodeID = neighborAPNodeID;
        remoteSTAInfo.MACAddress = rxMPDU.Header.Address2;
        remoteSTAInfo.DeviceID = obj.DeviceID;
        remoteSTAInfo.Mode = "AP";
        remoteSTAInfo.AID = 0;
        remoteSTAInfo.IsMLD = rxMPDU.FrameBody.IsAffiliatedWithMLD;
        remoteSTAInfo.EnhancedMLMode = 0;
        remoteSTAInfo.NumEMLPadBytes = 0;
        remoteSTAInfo.Bandwidth = rxMPDU.FrameBody.ChannelBandwidth; % In MHz
        remoteSTAInfo.MaxSupportedStandard = rxMPDU.FrameBody.MaxSupportedStandard;
        addRemoteSTAInfo(obj.SharedMAC, remoteSTAInfo);
    end
end

end
