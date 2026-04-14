function mpdu = cfg2mpduStruct(macFrameCfg, mpdu, macPayload, isMeshDevice)
%cfg2mpduStruct Fills the MPDU structure using the information in the given
%MAC frame configuration object
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   MPDU = cfg2mpduStruct(MACFRAMECFG, MPDU, MACPAYLOAD, ISMESHDEVICE)
%   fills the given MPDU structure, MPDU, using the values from the MAC
%   frame configuration object, MACFRAMECFG.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU.
%
%   MACFRAMECFG is an object of type wlanMACFrameConfig.
%
%   MACPAYLOAD is the decimal bytes of the MSDU if the MPDU is a data
%   frame. Otherwise, this input is empty.
%
%   ISMESHDEVICE is a flag indicating if this is a mesh device.

%   Copyright 2025 The MathWorks, Inc.

mpdu.Header.FrameType = macFrameCfg.FrameType;
mpdu.Header.Retransmission = macFrameCfg.Retransmission;
mpdu.Header.ToDS = macFrameCfg.ToDS;
mpdu.Header.FromDS = macFrameCfg.FromDS;
mpdu.Header.Duration = macFrameCfg.Duration;
mpdu.Header.Address1 = macFrameCfg.Address1;
mpdu.Header.Address2 = macFrameCfg.Address2;
mpdu.Header.Address3 = macFrameCfg.Address3;
mpdu.Header.Address4 = macFrameCfg.Address4;
if ~strcmp(getType(macFrameCfg), 'Control')
    mpdu.Header.SequenceNumber = macFrameCfg.SequenceNumber;
end

if strcmp(mpdu.Header.FrameType, 'QoS Data') || strcmp(mpdu.Header.FrameType, 'QoS Null')
    mpdu.FrameBody = wlan.internal.utils.defaultMPDUFrameBody(mpdu.Header.FrameType);
    mpdu.Header.TID = macFrameCfg.TID;
    mpdu.Header.AckPolicy = macFrameCfg.AckPolicy;
    if strcmp(macFrameCfg.FrameType, 'QoS Data')
        mpdu.FrameBody.MeshControl.MeshTTL = macFrameCfg.MeshTTL;
        mpdu.FrameBody.MeshControl.MeshSequenceNumber = macFrameCfg.MeshSequenceNumber;
        mpdu.FrameBody.MeshControl.AddressExtensionMode = macFrameCfg.AddressExtensionMode;
        mpdu.FrameBody.MeshControl.Address5 = macFrameCfg.Address5;
        mpdu.FrameBody.MeshControl.Address6 = macFrameCfg.Address6;
        mpdu.FrameBody.MSDU.Packet = macPayload;
        mpdu.FrameBody.MSDU.PacketLength = numel(macPayload);
        mpdu.FrameBody.MSDU.AccessCategory = wlan.internal.Constants.TID2AC(mpdu.Header.TID+1);
    end

elseif strcmp(macFrameCfg.FrameType, 'Beacon')
    mpdu.FrameBody = wlan.internal.utils.defaultMPDUFrameBody('Beacon');
    mpdu = wlan.internal.utils.decodeFullMACBeaconIEs(mpdu, macFrameCfg);

elseif strcmp(macFrameCfg.FrameType, 'Block Ack')
    mpdu.FrameBody = wlan.internal.utils.defaultMPDUFrameBody('Block Ack');
    mpdu.FrameBody.SequenceNumber = macFrameCfg.SequenceNumber;
    mpdu.FrameBody.TID = macFrameCfg.TID;
    mpdu.FrameBody.BlockAckBitmap = macFrameCfg.BlockAckBitmap;

elseif strcmp(macFrameCfg.FrameType, 'Multi-STA-BA') % --> Multi-STA-BA is not supported in wlanMACFrameConfig yet
    mpdu.FrameBody = wlan.internal.utils.defaultMPDUFrameBody('Multi-STA-BA');
    for idx = 1:numel(macFrameCfg.SequenceNumber)
        mpdu.FrameBody.UserInfo(idx).SequenceNumber = macFrameCfg.SequenceNumber(idx);
        mpdu.FrameBody.UserInfo(idx).TID = macFrameCfg.TID(idx);
        mpdu.FrameBody.UserInfo(idx).BlockAckBitmap = macFrameCfg.BlockAckBitmap(idx);
        % mpdu.FrameBody.UserInfo(idx).AID = macFrameCfg.AID(idx); --> Multi-STA-BA is not supported in wlanMACFrameConfig yet
    end

elseif strcmp(macFrameCfg.FrameType, 'Trigger')
    mpdu.FrameBody = wlan.internal.utils.defaultMPDUFrameBody('Trigger', macFrameCfg.TriggerType);
    trigCfg = macFrameCfg.TriggerConfig;
    
    mpdu.FrameBody.TriggerType = trigCfg.TriggerType;
    mpdu.FrameBody.CSRequired = trigCfg.CSRequired;
    if strcmp(trigCfg.ChannelBandwidth, 'CBW20')
        mpdu.FrameBody.ChannelBandwidth = 20;
    elseif strcmp(trigCfg.ChannelBandwidth, 'CBW40')
        mpdu.FrameBody.ChannelBandwidth = 40;
    elseif strcmp(trigCfg.ChannelBandwidth, 'CBW80')
        mpdu.FrameBody.ChannelBandwidth = 80;
    else % 'CBW80+80 or CBW160'
        % To indicate 320 MHz, UL BW subfield in Common Info field and
        % UL BW extension subfield in Special User Info field are required.
        % For more understanding, refer Table 9-45g in IEEE P802.11be/D5.0.
        mpdu.FrameBody.ChannelBandwidth = 160; % Value 320 MHz is identified and overriden in MU-RTS case based on special user info field
    end

    switch trigCfg.TriggerType
        case 'Basic' % Basic trigger
            mpdu.FrameBody.LSIGLength = trigCfg.LSIGLength;
            mpdu.FrameBody.NumHELTFSymbols = trigCfg.NumHELTFSymbols;
            for idx = 1:numel(trigCfg.UserInfo)
                mpdu.FrameBody.UserInfo(idx).AID12 = trigCfg.UserInfo{idx}.AID12;
                mpdu.FrameBody.UserInfo(idx).MCS = trigCfg.UserInfo{idx}.MCS;
                mpdu.FrameBody.UserInfo(idx).RUSize = trigCfg.UserInfo{idx}.RUSize;
                mpdu.FrameBody.UserInfo(idx).RUIndex = trigCfg.UserInfo{idx}.RUIndex;
                mpdu.FrameBody.UserInfo(idx).NumSpatialStreams = trigCfg.UserInfo{idx}.NumSpatialStreams;
                mpdu.FrameBody.UserInfo(idx).TIDAggregationLimit = trigCfg.UserInfo{idx}.TIDAggregationLimit;
                mpdu.FrameBody.UserInfo(idx).PreferredAC = trigCfg.UserInfo{idx}.PreferredAC;
            end
    
        case 'MU-RTS' % MU-RTS trigger
            for idx = 1:numel(trigCfg.UserInfo)
                mpdu.FrameBody.UserInfo(idx).AID12 = trigCfg.UserInfo{idx}.AID12;
                mpdu.FrameBody.UserInfo(idx).UserInfoVariant = trigCfg.UserInfo{idx}.UserInfoVariant; % Hidden field added for SLS
                mpdu.FrameBody.UserInfo(idx).PS160 = trigCfg.UserInfo{idx}.PS160;                     % Hidden field added for SLS
                if (trigCfg.UserInfo{idx}.AID12 == 2007) && strcmp(trigCfg.UserInfo{idx}.UserInfoVariant, 'Special') && (trigCfg.UserInfo{idx}.ULBandwidthExtension > 1) % Hidden fields added for SLS
                    mpdu.FrameBody.ChannelBandwidth = 320;
                end
            end
            mpdu.FrameBody.CommonInfoVariant = trigCfg.CommonInfoVariant;             % Hidden field added for SLS
            mpdu.FrameBody.HEorEHTP160 = trigCfg.HEorEHTP160;                         % Hidden field added for SLS
            mpdu.FrameBody.SpecialUserInfoPresent = trigCfg.SpecialUserInfoPresent;   % Hidden field added for SLS
            mpdu.FrameBody.NumPadBytesICF = macFrameCfg.NumPadBytesICF;               % Hidden field added for SLS

        case 'MU-BAR' % MU-BAR trigger
            mpdu.FrameBody.LSIGLength = trigCfg.LSIGLength;
            mpdu.FrameBody.NumHELTFSymbols = trigCfg.NumHELTFSymbols;
            for idx = 1:numel(trigCfg.UserInfo)
                mpdu.FrameBody.UserInfo(idx).AID12 = trigCfg.UserInfo{idx}.AID12;
                mpdu.FrameBody.UserInfo(idx).MCS = trigCfg.UserInfo{idx}.MCS;
                mpdu.FrameBody.UserInfo(idx).RUSize = trigCfg.UserInfo{idx}.RUSize;
                mpdu.FrameBody.UserInfo(idx).RUIndex = trigCfg.UserInfo{idx}.RUIndex;
                mpdu.FrameBody.UserInfo(idx).NumSpatialStreams = trigCfg.UserInfo{idx}.NumSpatialStreams;
                mpdu.FrameBody.UserInfo(idx).TID = trigCfg.UserInfo{idx}.TID ;
                mpdu.FrameBody.UserInfo(idx).StartingSequenceNum = trigCfg.UserInfo{idx}.StartingSequenceNum ;
            end
    end
end

% mpdu.Header.AControlID   ---> Field only used in Abstract MAC frame
% mpdu.Header.AControlInfo ---> Field only used in Abstract MAC frame

% Fill MPDU metadata fields
isGroupAddr = wlan.internal.utils.isGroupAddress(macFrameCfg.Address1);
if isGroupAddr
    if isMeshDevice % Packet received on mesh
        % Address3 contains the mesh source address (SA) in mesh groupcast
        % frames. As current implementation supports scenarios where mesh
        % SA is same as SA for groupcast frames, assign mesh SA to SA.
        mpdu.Metadata.SourceAddress = mpdu.Header.Address3;
        mpdu.Metadata.DestinationAddress = macFrameCfg.Address1;
    else
        if macFrameCfg.ToDS && ~macFrameCfg.FromDS % Sent by STA
            % Address2 contains TA (= SA) and Address3 contains DA
            mpdu.Metadata.SourceAddress = macFrameCfg.Address2;
            mpdu.Metadata.DestinationAddress = macFrameCfg.Address3;
        else % Frame sent by AP
            % Address3 contains SA and Address1 contains DA
            mpdu.Metadata.SourceAddress = macFrameCfg.Address3;
            mpdu.Metadata.DestinationAddress = macFrameCfg.Address1;
        end
    end

else
    if isMeshDevice % Individually addressed mesh data frames
        mpdu.Metadata.DestinationAddress = macFrameCfg.Address3;
        mpdu.Metadata.SourceAddress = macFrameCfg.Address4;
        if macFrameCfg.AddressExtensionMode == 2
            % Addresses 5 and 6 are present and correspond to final DA
            % and SA
            mpdu.Metadata.DestinationAddress = macFrameCfg.Address5;
            mpdu.Metadata.SourceAddress = macFrameCfg.Address6;
        end
    else
        if macFrameCfg.ToDS && ~macFrameCfg.FromDS % Frame sent by STA
            % Address2 contains TA (= SA) and Address3 contains DA
            mpdu.Metadata.SourceAddress = macFrameCfg.Address2;
            mpdu.Metadata.DestinationAddress = macFrameCfg.Address3;
        else
            % Address3 contains SA and Address1 contains DA
            mpdu.Metadata.SourceAddress = macFrameCfg.Address3;
            mpdu.Metadata.DestinationAddress = macFrameCfg.Address1;
        end
    end
end

% Get the ID of immediate destination node from RA
mpdu.Metadata.ReceiverID = wlan.internal.utils.macAddress2NodeID(macFrameCfg.Address1);
mpdu.Metadata.DestinationID = wlan.internal.utils.macAddress2NodeID(mpdu.Metadata.DestinationAddress);

end