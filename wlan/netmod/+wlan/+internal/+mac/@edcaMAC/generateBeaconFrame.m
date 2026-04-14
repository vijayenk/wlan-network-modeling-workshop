function [frameToPHY, beaconFrameLength] = generateBeaconFrame(obj)
%generateBeaconFrame Generate a Beacon frame to be sent to PHY
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   [FRAMETOPHY, BEACONFRAMELENGTH] = generateBeaconFrame(OBJ) generates a
%   beacon frame, and returns the frame along with its length.
%
%   FRAMETOPHY is a structure of type edcaMAC.MACFrameTemplate, indicates
%   the MAC beacon frame passed to PHY transmitter.
%
%   BEACONFRAMELENGTH is an integer, indicates the length of the beacon
%   frame, in bytes.
%
%   OBJ is an object of type edcaMAC.

%   Copyright 2023-2025 The MathWorks, Inc.

frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = obj.MPDUBeaconTemplate;
mpdu = frameToPHY.MACFrame.MPDU;
linkID = getLinkIndex(obj);

% Generate beacon information elements (IE) for the first beacon and reuse
% them while generating subsequent beacons.
if obj.Statistics.TransmittedBeaconFrames == 0
    % Form abstract beacon and store here
    mpdu.Header.FrameType = 'Beacon';
    mpdu.Header.ToDS = 0;
    mpdu.Header.FromDS = 1;
    mpdu.Header.Address1 = 'FFFFFFFFFFFF';
    mpdu.Header.Address2 = obj.MACAddress;
    mpdu.Header.Address3 = obj.MACAddress;
    mpdu.Header.Duration = 0;

    % Add beacon parameters in abstract MAC frame. Timestamp, beacon
    % interval, SSID/MeshID, and the total payload length are shown in
    % the structure. To generate beacons of the same size in abstract
    % and full MAC for a given configuration, the total beacon payload
    % length takes into account all the fields and information elements
    % supported for full MAC beacon frame, in abstract beacon frame as well.
    if obj.IsMeshDevice % Find number of mesh peers, this is required to form Mesh Configuration IE
        meshNeighbors = obj.MeshNeighbors;
        meshNeighbors = cell2mat(meshNeighbors');
        meshNeighbors = unique(meshNeighbors,'rows');
        numMeshPeers = size(meshNeighbors,1);
    else
        numMeshPeers = 0;
    end
    mpdu.FrameBody.Timestamp = 0;
    mpdu.FrameBody.BeaconInterval = obj.BeaconInterval;

    mpdu.FrameBody.SSID = "WLAN";
    mpdu.FrameBody.IsMeshBeacon = obj.IsMeshDevice;
    mpdu.FrameBody.MeshID = []; % Applicable only for mesh beacons
    if obj.IsMeshDevice % Update MeshID for mesh beacons
        mpdu.FrameBody.MeshID = "WLAN";
    end
    mpdu.FrameBody.ChannelBandwidth = obj.ChannelBandwidth;
    mpdu.FrameBody.PrimaryChannel = obj.SharedMAC.PrimaryChannel;
    mpdu.FrameBody.PrimaryChannelIndex = obj.PrimaryChannelIndex;
    mpdu.FrameBody.BasicRates = obj.BasicRates;
    mpdu.FrameBody.AIFS = obj.AIFS;
    mpdu.FrameBody.CWMin = obj.CWMin;
    mpdu.FrameBody.CWMax = obj.CWMax;
    mpdu.FrameBody.BSSColor = obj.BSSColor;
    mpdu.FrameBody.NumMeshPeers = numMeshPeers;
    mpdu.FrameBody.IsAffiliatedWithMLD = obj.IsAffiliatedWithMLD;
    mpdu.FrameBody.MLDMACAddress = obj.SharedMAC.MLDMACAddress;
    mpdu.FrameBody.LinkID = linkID;
    mpdu.FrameBody.NumLinks = obj.SharedMAC.NumLinks;
    mpdu.FrameBody.EDCAParamsCount = obj.SharedMAC.EDCAParamsCount;
    mpdu.FrameBody.TXOPLimit = ceil((obj.TXOPLimit*1e-3)/32);
    selfLinkID = getLinkIndex(obj);
    rnrIdx = 0;
    for linkIdx = 1:mpdu.FrameBody.NumLinks
        if selfLinkID ~= linkIdx
            rnrIdx = rnrIdx + 1;
            mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).LinkID = linkIdx;
            mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).EDCAParamsCount = obj.SharedMAC.EDCAParamsCount(linkIdx);
            mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).TBTTOffset = floor(abs(obj.SharedMAC.NextTBTT(linkIdx) - obj.SharedMAC.LastTBTT(selfLinkID))/1024e3);
            mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).BSSIDList = obj.SharedMAC.BSSIDList(linkIdx,:);
        end
    end

    % Obtain element ID and length of each information element
    [informationElements, elementIDs, totalPayloadLength] = wlan.internal.mac.generateBeaconInformationElements(mpdu.FrameBody, obj.SharedMAC.BandAndChannel(linkID,:), obj.FrameAbstraction);

    if ~obj.FrameAbstraction % Full MAC beacon frame context
        managementCfg = obj.EmptyMACManagementConfig;
        managementCfg.FrameType = 'Beacon';
        managementCfg.BeaconInterval = obj.BeaconInterval;
        managementCfg.Timestamp = 0;
        managementCfg.ShortSlotTimeUsed = true;
        
        if obj.IsMeshDevice
            managementCfg.ESSCapability = false;
        end
        for elementIDx = 1:size(elementIDs,2)
            managementCfg = managementCfg.addIE(elementIDs{elementIDx}, informationElements{elementIDx});
        end

        % Update beacon frame context object to be used later for subsequent beacon transmissions
        obj.BeaconFrameContext.MACManagementConfigObject = managementCfg;
        obj.BeaconFrameContext.ElementIDs = elementIDs;
        obj.BeaconFrameContext.InformationElements = informationElements;
    end

    frameToPHY.MACFrame.MPDU = mpdu;
    obj.BeaconFrameContext.AbstractBeaconFrame = frameToPHY;
    obj.BeaconFrameContext.NumPayloadBytes = totalPayloadLength;
else
    frameToPHY = obj.BeaconFrameContext.AbstractBeaconFrame;
    mpdu = frameToPHY.MACFrame.MPDU;
end

mpdu = assignSequenceNumber(obj.SharedMAC, mpdu);
mpdu.FrameBody.Timestamp = round(obj.LastRunTimeNS/1e3, 0); % LastRunTimeNS contains time at which MAC is invoked
mpdu.FrameBody.ChannelBandwidth = obj.ChannelBandwidth;
mpdu.FrameBody.PrimaryChannel = obj.SharedMAC.PrimaryChannel;
mpdu.FrameBody.PrimaryChannelIndex = obj.PrimaryChannelIndex;
mpdu.FrameBody.BasicRates = obj.BasicRates;
mpdu.FrameBody.AIFS = obj.AIFS;
mpdu.FrameBody.CWMin = obj.CWMin;
mpdu.FrameBody.CWMax = obj.CWMax;
mpdu.FrameBody.EDCAParamsCount = obj.SharedMAC.EDCAParamsCount;
mpdu.FrameBody.TXOPLimit = ceil((obj.TXOPLimit*1e-3)/32);
selfLinkID = getLinkIndex(obj);
rnrIdx = 0;
for linkIdx = 1:mpdu.FrameBody.NumLinks
    if selfLinkID ~= linkIdx
        rnrIdx = rnrIdx + 1;
        mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).LinkID = linkIdx;
        mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).EDCAParamsCount = obj.SharedMAC.EDCAParamsCount(linkIdx);
        mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).TBTTOffset = floor(abs(obj.SharedMAC.NextTBTT(linkIdx) - obj.SharedMAC.LastTBTT(selfLinkID))/1024e3);
    end
end
mpdu.FCSPass = true;
mpdu.DelimiterPass = true;

if ~isempty(obj.TransmissionStartedFcn)
    obj.TransmissionStarted = obj.TransmissionStartedTemplate;
end

% Update abstract beacon frames
if obj.FrameAbstraction
    mpduOverhead = 28; % Beacon frame header - 24, FCS - 4
    beaconFrameLength = obj.BeaconFrameContext.NumPayloadBytes + mpduOverhead;   

else % Form full MAC beacon frames
    cfgMAC = obj.EmptyMACConfig;

    % Check and update any IEs if required
    if obj.IsAPDevice 
        % Update information elements affected by a change in the EDCA contention parameters
        if any(obj.SharedMAC.IsEDCAParamsUpdated(linkID, :))
            updateBeaconConfig(obj, 12, mpdu); % EDCA Parameter Set
            if obj.IsAffiliatedWithMLD
                updateBeaconConfig(obj, [255 107], mpdu); % Basic Multilink
            end
        end
        % Update Reduced Neighbor Report element every time to account for
        % varying TBTT offsets between APs affiliated with the same AP MLD
        if obj.IsAffiliatedWithMLD
            updateBeaconConfig(obj, 201, mpdu);
        end
    end
    % Retrieve beacon configuration object with added IEs
    managementCfg = obj.BeaconFrameContext.MACManagementConfigObject;
    % Update timestamp
    managementCfg.Timestamp = round(obj.LastRunTimeNS/1e3, 0); % LastRunTimeNS contains time at which MAC is invoked
    cfgMAC = wlan.internal.utils.mpduStruct2Cfg(mpdu, cfgMAC, managementCfg);
 
    % Generate beacon frame bits
    [beaconFrame, beaconFrameBits] = wlan.internal.macGenerateMPDU([],cfgMAC); % beaconFrame is column vector
    beaconFrame = double(beaconFrame);
    beaconFrameLength = size(beaconFrame,1);
    if ~isempty(obj.TransmissionStartedFcn)
        % MPDUs are filled only for full MAC frames. In case of abstract MAC
        % frames, this field is empty ([]).
        obj.TransmissionStarted.PDU = {beaconFrame};
    end
    frameToPHY.MACFrame.Data = beaconFrameBits;
end

mpdu.Metadata.MPDULength = beaconFrameLength;
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = beaconFrameLength;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.PSDULength = beaconFrameLength;
frameToPHY.PacketGenerationTime = round(obj.LastRunTimeNS/1e9, 9); % LastRunTimeNS contains time at which MAC is invoked

% Reset IsEDCAParamsUpdated flag
obj.SharedMAC.IsEDCAParamsUpdated(linkID, :) = false;
end

function updateBeaconConfig(obj, elementID, mpdu)
%updateBeaconConfig Update beacon configuration object

    cfgBeacon = obj.BeaconFrameContext.MACManagementConfigObject;
    updatedIE = wlan.internal.mac.generateBeaconInformationElements(mpdu.FrameBody, obj.SharedMAC.BandAndChannel(mpdu.FrameBody.LinkID,:), obj.FrameAbstraction, elementID);
    % Find index from stored context
    elementIDs = obj.BeaconFrameContext.ElementIDs;
    for idx = 1:numel(elementIDs)
        if elementIDs{1,idx} == elementID
            updateIndex = idx;
        end
    end

    cfgBeacon = cfgBeacon.addIE(elementID, updatedIE);
    obj.BeaconFrameContext.InformationElements{1, updateIndex} = updatedIE;
    obj.BeaconFrameContext.MACManagementConfigObject = cfgBeacon;
end
