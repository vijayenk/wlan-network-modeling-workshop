function macFrameCfg = mpduStruct2Cfg(mpdu, macFrameCfg, frameBodyCfg, cbw320Channelization)
%mpduStruct2Cfg Fills MAC frame configuration object with information from
%given MPDU structure
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   MACFRAMECFG = mpduStruct2Cfg(MPDU, MACFRAMECFG) fills the given MAC
%   frame configuration object, MACFRAMECFG, using the values from the MPDU
%   structure, MPDU.
%
%   MACFRAMECFG is an object of type wlanMACFrameConfig.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU
%
%   MACFRAMECFG = mpduStruct2Cfg(..., FRAMEBODYCFG) also fills the frame
%   body configuration in the MACFRAMECFG from the given structure,
%   FRAMEBODYCFG, which is an object of type wlanMACTriggerUserConfig for
%   trigger frames and an object of type wlanMACManagementConfig for
%   management frames.
%
%   MACFRAMECFG = mpduStruct2Cfg(..., CBW320CHANNELIZATION) also provides
%   information about 320 MHz channelization, only applicable for MU-RTS
%   trigger frame.

%   Copyright 2025 The MathWorks, Inc.

if nargin < 4
    cbw320Channelization = 1;
end

macFrameCfg.FrameType = mpdu.Header.FrameType;
macFrameCfg.ToDS = mpdu.Header.ToDS;
macFrameCfg.FromDS = mpdu.Header.FromDS;
macFrameCfg.Retransmission = mpdu.Header.Retransmission;
macFrameCfg.Duration = mpdu.Header.Duration;
macFrameCfg.Address1 = mpdu.Header.Address1;
macFrameCfg.Address2 = mpdu.Header.Address2;
macFrameCfg.Address3 = mpdu.Header.Address3;
macFrameCfg.Address4 = mpdu.Header.Address4;
macFrameCfg.SequenceNumber = mpdu.Header.SequenceNumber;

if strcmp(mpdu.Header.FrameType, 'QoS Data') || strcmp(mpdu.Header.FrameType, 'QoS Null')
    macFrameCfg.TID = mpdu.Header.TID;
    macFrameCfg.AckPolicy = mpdu.Header.AckPolicy;
    if strcmp(mpdu.Header.FrameType, 'QoS Data')
        macFrameCfg.MeshTTL = mpdu.FrameBody.MeshControl.MeshTTL;
        macFrameCfg.MeshSequenceNumber = mpdu.FrameBody.MeshControl.MeshSequenceNumber;
        macFrameCfg.AddressExtensionMode = mpdu.FrameBody.MeshControl.AddressExtensionMode;
        macFrameCfg.Address5 = mpdu.FrameBody.MeshControl.Address5;
        macFrameCfg.Address6 = mpdu.FrameBody.MeshControl.Address6;
    end

elseif strcmp(mpdu.Header.FrameType, 'Beacon')
    macFrameCfg.ManagementConfig = frameBodyCfg;

elseif strcmp(mpdu.Header.FrameType, 'Block Ack')
    macFrameCfg.SequenceNumber = mpdu.FrameBody.SequenceNumber;
    macFrameCfg.TID = mpdu.FrameBody.TID;
    macFrameCfg.BlockAckBitmap = mpdu.FrameBody.BlockAckBitmap;

elseif strcmp(mpdu.Header.FrameType, 'Multi-STA-BA') % --> Multi-STA-BA is not supported in wlanMACFrameConfig yet
    for idx = 1:numel(mpdu.FrameBody.UserInfo)
        macFrameCfg.SequenceNumber(idx) = mpdu.FrameBody.UserInfo(idx).SequenceNumber;
        macFrameCfg.TID(idx) = mpdu.FrameBody.UserInfo(idx).TID;
        macFrameCfg.BlockAckBitmap(idx,:) = mpdu.FrameBody.UserInfo(idx).BlockAckBitmap;
        % macFrameCfg.AID = mpdu.FrameBody.UserInfo(idx).AID; --> Multi-STA-BA is not supported in wlanMACFrameConfig yet
    end

elseif strcmp(mpdu.Header.FrameType, 'Trigger')
    macFrameCfg.TriggerConfig.TriggerType = mpdu.FrameBody.TriggerType;
    switch mpdu.FrameBody.ChannelBandwidth
        case 20
            macFrameCfg.TriggerConfig.ChannelBandwidth = 'CBW20';
        case 40
            macFrameCfg.TriggerConfig.ChannelBandwidth = 'CBW40';
        case 80
            macFrameCfg.TriggerConfig.ChannelBandwidth = 'CBW80';
        % To indicate 320 MHz, UL BW subfield in Common Info field and
        % UL BW extension subfield in Special User Info field are required.
        % For more understanding, refer Table 9-45g in IEEE P802.11be/D5.0.
        otherwise % 160, 320
            macFrameCfg.TriggerConfig.ChannelBandwidth = 'CBW80+80 or CBW160';
    end
    macFrameCfg.TriggerConfig.CSRequired = mpdu.FrameBody.CSRequired;

    switch mpdu.FrameBody.TriggerType
        case 'Basic' % Basic trigger
            macFrameCfg.TriggerConfig.LSIGLength = mpdu.FrameBody.LSIGLength;
            macFrameCfg.TriggerConfig.NumHELTFSymbols = mpdu.FrameBody.NumHELTFSymbols;            
            frameBodyCfg.TriggerType = mpdu.FrameBody.TriggerType;
            for idx = 1:numel(mpdu.FrameBody.UserInfo)
                frameBodyCfg.AID12 = mpdu.FrameBody.UserInfo(idx).AID12;
                frameBodyCfg.MCS = mpdu.FrameBody.UserInfo(idx).MCS;
                frameBodyCfg.RUSize = mpdu.FrameBody.UserInfo(idx).RUSize;
                frameBodyCfg.RUIndex = mpdu.FrameBody.UserInfo(idx).RUIndex;
                frameBodyCfg.NumSpatialStreams = mpdu.FrameBody.UserInfo(idx).NumSpatialStreams;
                frameBodyCfg.TIDAggregationLimit = mpdu.FrameBody.UserInfo(idx).TIDAggregationLimit;
                frameBodyCfg.PreferredAC = mpdu.FrameBody.UserInfo(idx).PreferredAC;
                macFrameCfg.TriggerConfig = addUserInfo(macFrameCfg.TriggerConfig, frameBodyCfg);
            end
    
        case 'MU-RTS' % MU-RTS trigger
            macFrameCfg.TriggerConfig.CommonInfoVariant = mpdu.FrameBody.CommonInfoVariant;             % Hidden field added for SLS
            macFrameCfg.TriggerConfig.HEorEHTP160 = mpdu.FrameBody.HEorEHTP160;                         % Hidden field added for SLS
            macFrameCfg.TriggerConfig.SpecialUserInfoPresent = mpdu.FrameBody.SpecialUserInfoPresent;   % Hidden field added for SLS

            frameBodyCfg.TriggerType = mpdu.FrameBody.TriggerType;
            % Special User Info field
            if mpdu.FrameBody.SpecialUserInfoPresent
                if any(mpdu.FrameBody.ChannelBandwidth == [20 40 80])
                    ulBWExtension = 0;
                elseif mpdu.FrameBody.ChannelBandwidth == 160
                    ulBWExtension = 1;
                else
                    ulBWExtension = 2; % Default 320-1 channelization
                    if cbw320Channelization == 2
                        ulBWExtension = 3; % 320-2 channelization
                    end
                end
                frameBodyCfg.AID12 = 2007;
                frameBodyCfg.UserInfoVariant = 'Special';
                frameBodyCfg.ULBandwidthExtension = ulBWExtension;
                macFrameCfg.TriggerConfig = addSpecialUserInfo(macFrameCfg.TriggerConfig, frameBodyCfg);
            end
            % User Info fields
            for idx = 1:numel(mpdu.FrameBody.UserInfo)
                frameBodyCfg.AID12 = mpdu.FrameBody.UserInfo(idx).AID12;
                frameBodyCfg.UserInfoVariant = mpdu.FrameBody.UserInfo(idx).UserInfoVariant;
                frameBodyCfg.PS160 =  mpdu.FrameBody.UserInfo(idx).PS160;
                macFrameCfg.TriggerConfig = addUserInfo(macFrameCfg.TriggerConfig, frameBodyCfg);
            end
            macFrameCfg.NumPadBytesICF = mpdu.FrameBody.NumPadBytesICF;
    
        case 'MU-BAR' % MU-BAR trigger
            macFrameCfg.TriggerConfig.LSIGLength = mpdu.FrameBody.LSIGLength;
            macFrameCfg.TriggerConfig.NumHELTFSymbols = mpdu.FrameBody.NumHELTFSymbols;
            frameBodyCfg.TriggerType = mpdu.FrameBody.TriggerType;
            for idx = 1:numel(mpdu.FrameBody.UserInfo)
                frameBodyCfg.AID12 = mpdu.FrameBody.UserInfo(idx).AID12;
                frameBodyCfg.MCS = mpdu.FrameBody.UserInfo(idx).MCS;
                frameBodyCfg.RUSize = mpdu.FrameBody.UserInfo(idx).RUSize;
                frameBodyCfg.RUIndex = mpdu.FrameBody.UserInfo(idx).RUIndex;
                frameBodyCfg.NumSpatialStreams = mpdu.FrameBody.UserInfo(idx).NumSpatialStreams;
                frameBodyCfg.TID = mpdu.FrameBody.UserInfo(idx).TID;
                frameBodyCfg.StartingSequenceNum = mpdu.FrameBody.UserInfo(idx).StartingSequenceNum;
                macFrameCfg.TriggerConfig = addUserInfo(macFrameCfg.TriggerConfig, frameBodyCfg);
            end
    end
end

end