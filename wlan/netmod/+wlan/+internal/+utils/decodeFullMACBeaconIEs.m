function mpdu = decodeFullMACBeaconIEs(mpdu, rxCfg)
%decodeFullMACBeaconIEs Decode the information elements and fill the
%FrameBody subfield in the mpdu structure
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   MPDU = decodeFullMACBeaconIEs(MPDU, MACFRAMECFG) decodes the required
%   information from the hexadecimal representation of IE information
%   present in the decoded configuration, MACFRAMECFG.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU.
%
%   MACFRAMECFG is an object of type wlanMACFrameConfig, representing the
%   decoded configuration from MPDU bits.

%   Copyright 2025 The MathWorks, Inc.

elementIDs = [];
elementIDExtensions = [];
elementIDValues = [rxCfg.ManagementConfig.InformationElements{:,1}];
if ~isempty(elementIDValues)
    elementIDs = elementIDValues(1:2:end);
    elementIDExtensions = elementIDValues(2:2:end);
end

mpdu.FrameBody.Timestamp = rxCfg.ManagementConfig.Timestamp;
mpdu.FrameBody.BeaconInterval = rxCfg.ManagementConfig.BeaconInterval;
mpdu.FrameBody.SSID = rxCfg.ManagementConfig.SSID;
mpdu.FrameBody.IsMeshBeacon = ~rxCfg.ManagementConfig.ESSCapability; % Since IBSSCapability is always false in simulation, Mesh is assumed
mpdu.FrameBody.MaxSupportedStandard = wlan.internal.Constants.Std80211a;
mpdu = fillBasicRates(mpdu, rxCfg);

secChannelOffset = 0; % Init

for ieIdx = 1:numel(elementIDs)
    switch elementIDs(ieIdx) 
        case 12 % EDCA Parameter Set Element
            if ~mpdu.FrameBody.IsMeshBeacon
                mpdu = decodeEDCAParameterSet(mpdu, rxCfg.ManagementConfig.InformationElements{ieIdx,2});
            end

        case 127 % Extended Capabilities Element
            % Extended Capabilities Element
            % For more information, refer section 9.4.2.26 in IEEE Std 802.11-2020.

        case 45 % HT Capabilities Element
            % For more information, refer section 9.4.2.55 in IEEE Std 802.11-2020.
            mpdu.FrameBody.MaxSupportedStandard = wlan.internal.Constants.Std80211n;

        case 61 % HT Operation Element
            htOperationInformation = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
            mpdu.FrameBody.PrimaryChannel = htOperationInformation(1);
            secChannelOffset = bit2int(bitget(htOperationInformation(2),1:2)',2,false);
            if secChannelOffset == 0
                mpdu.FrameBody.ChannelBandwidth = 20;
            else
                mpdu.FrameBody.ChannelBandwidth = 40;
                if secChannelOffset == 1
                    mpdu.FrameBody.PrimaryChannelIndex = 1;
                elseif secChannelOffset == 3
                    mpdu.FrameBody.PrimaryChannelIndex = 2;
                end
            end

        case 191 % VHT Capabilities Element
            % For more information, refer section 9.4.2.157 in IEEE Std 802.11-2020.
            % VHT Capabilities information
            mpdu.FrameBody.MaxSupportedStandard = wlan.internal.Constants.Std80211ac;

        case 192 % VHT Operation Element
            % For more information, refer section 9.4.2.158 in IEEE Std 802.11-2020.

            vhtOperationInformation = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
            channelWidthInd = vhtOperationInformation(1);
            channelCenterFreqSegment1 = vhtOperationInformation(3);

            if secChannelOffset == 0 % 20 MHz
                mpdu.FrameBody.ChannelBandwidth = 20;
            else
                if channelWidthInd == 0
                    mpdu.FrameBody.ChannelBandwidth = 40;
                elseif channelWidthInd == 1
                    if channelCenterFreqSegment1 == 0
                        mpdu.FrameBody.ChannelBandwidth = 80;
                    else
                        mpdu.FrameBody.ChannelBandwidth = 160;
                    end
                end
            end
    
        case 255
            % For more information, refer section 9.4.2.248 in IEEE Std 802.11-2021.
            switch elementIDExtensions(ieIdx)
                case 35 % HE MAC Capabilities
                    mpdu.FrameBody.MaxSupportedStandard = wlan.internal.Constants.Std80211ax;

                case 36 % HE Operation Element
                    % For more information, refer section 9.4.2.249 in IEEE Std 802.11-2021.
                    
                    heOperationInformation = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
                    vhtOperInfoPresent = bitget(heOperationInformation(2),7);
                    coHostedBSS = bitget(heOperationInformation(2),8);
                    sixGHzInfoPresent = bitget(heOperationInformation(3),2);
                    mpdu.FrameBody.BSSColor = bit2int(bitget(heOperationInformation(4),1:6)',6,false);
                    pos = 5;
                    % Basic HE-MCS and NSS set (2 bytes)
                    pos = pos+2;
                    if vhtOperInfoPresent % 3 bytes
                        pos = pos+3;
                    end
                    if coHostedBSS % 1 byte
                        pos = pos+1;
                    end
                    if sixGHzInfoPresent
                        % 6 GHz operation info (5 bytes)
                        sixGHzOperInfo = heOperationInformation(pos:pos+4);
                        mpdu.FrameBody.PrimaryChannel = sixGHzOperInfo(1);
                    end

                case 106 % EHT Operation Element
                    % For more information, refer section 9.4.2.311 in IEEE P802.11be/D5.0
                    ehtOperationInformation = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
                    ehtOperationParameters = ehtOperationInformation(1); % EHT operations parameters
                    ehtOperationInformationPresent = bitget(ehtOperationParameters, 1);
                    if ehtOperationInformationPresent
                        control = ehtOperationInformation(6);
                        chanWidth = bit2int(bitget(control, 1:3)',3,false);
                        switch chanWidth
                            case 0
                                mpdu.FrameBody.ChannelBandwidth = 20;
                            case 1
                                mpdu.FrameBody.ChannelBandwidth = 40;
                            case 2
                                mpdu.FrameBody.ChannelBandwidth = 80;
                            case 3
                                mpdu.FrameBody.ChannelBandwidth = 160;
                            case 4
                                mpdu.FrameBody.ChannelBandwidth = 320;
                        end
                    end

                case 108 % EHT capabilities element
                    % For more information, refer section 9.4.2.313 in IEEE P802.11be/D5.0
                    % EHT MAC capabilities
                    mpdu.FrameBody.MaxSupportedStandard = wlan.internal.Constants.Std80211be;

                case 107 % Basic Multi Link Element
                    mpdu.FrameBody.IsAffiliatedWithMLD = true;
                    mlInformation = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
                    mlControl1 = mlInformation(1);
                    mlControl2 = mlInformation(2);
                    presenceBitmap1 = bitget(mlControl1,5:8);
                    linkIDInfoPresent = presenceBitmap1(1);
                    bssParamsChangeCountPresent = presenceBitmap1(2);
                    MediumSyncDelayInfoPresent = presenceBitmap1(3);
                    EMLCapabilitiesPresent = presenceBitmap1(4);
                    
                    presenceBitmap2 = bitget(mlControl2,1:3);
                    mldCapabilitiesAndOperationsPresent = presenceBitmap2(1);
                    apMLDIDPresent = presenceBitmap2(2);
                    extMLDCapabilitiesAndOperationsPresent = presenceBitmap2(3);

                    mpdu.FrameBody.MLDMACAddress = reshape(dec2hex(mlInformation(4:9),2)',1,[]);
                    pos = 10;
                    if linkIDInfoPresent
                        % Interpret Link ID
                        mpdu.FrameBody.LinkID = bit2int(bitget(mlInformation(pos),1:4)',4,false);
                        pos = pos+1;
                    end
                    if bssParamsChangeCountPresent
                        pos = pos+1;
                    end
                    if MediumSyncDelayInfoPresent
                        pos = pos+2;
                    end
                    if EMLCapabilitiesPresent
                        pos = pos+2;
                    end
                    if mldCapabilitiesAndOperationsPresent
                        % Interpret max number of links
                        mpdu.FrameBody.NumLinks = bit2int(bitget(mlInformation(pos),1:4)',4,false) + 1;
                        pos = pos+2;
                    end
                    if apMLDIDPresent
                        pos = pos+1;
                    end
                    if extMLDCapabilitiesAndOperationsPresent
                        pos = pos+2; %#ok<*NASGU>
                    end
            end

        case 201 % Reduced Neighbor Report element
            neighborAPInfoFields = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
            totalIELength = numel(neighborAPInfoFields);
            pos = 1;
            rnrIdx = 0;
            
            while pos < totalIELength
                tbttInfoHeaderByte1 = neighborAPInfoFields(pos);
                pos = pos+1;
                tbttInfoFieldType = bit2int(bitget(tbttInfoHeaderByte1,1:2)',2,false);
                tbttInfoCount = bit2int(bitget(tbttInfoHeaderByte1,5:8)',4,false) + 1;
                tbttInfoLength = neighborAPInfoFields(pos);
                pos = pos+1;
                % neighborAPInfoFields(3) - Operating class
                pos = pos+1; 
                % neighborAPInfoFields(4) - Channel number
                pos = pos+1; 
                totalTBTTInfoSetLength = tbttInfoCount*tbttInfoLength;

                if totalIELength >= pos+totalTBTTInfoSetLength-1
                    for idx = 1:tbttInfoCount
                        if tbttInfoFieldType == 0
                            % TBTT offset
                            tbttOffset = neighborAPInfoFields(pos);
                            pos = pos+1;
                            if tbttInfoLength == 16
                                % BSSID
                                bssid = reshape(dec2hex(neighborAPInfoFields(pos:pos+5),2)',1,[]);
                                pos = pos+6;
                                % Short SSID
                                pos = pos+4;
                                % BSS parameters
                                pos = pos+1;
                                % 20 MHz PSD
                                pos = pos+1;
                                % MLD parameters
                                apMLDID = neighborAPInfoFields(pos);
                                linkID = bit2int(bitget(neighborAPInfoFields(pos+1),1:4)',4,false);
                                bssParamsChangeCount = bit2int([bitget(neighborAPInfoFields(pos+1),5:8) bitget(neighborAPInfoFields(pos+2),1:4)]',8,false);
                                pos = pos+3;

                                rnrIdx = rnrIdx + 1;
                                mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).LinkID = linkID;
                                mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).BSSIDList = string(bssid);
                                mpdu.FrameBody.RNRNeighborAPInfo(rnrIdx).EDCAParamsCount = bssParamsChangeCount;
                            end
                        end
                    end
                end
            end

        case 114 % Mesh ID Element
            meshID = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
            mpdu.FrameBody.MeshID = char(meshID);

        case 113 % Mesh Configuration Element
            meshConfigInformation = rxCfg.ManagementConfig.InformationElements{ieIdx,2};
            meshFormationInfo = meshConfigInformation(6);
            mpdu.FrameBody.NumMeshPeers = bit2int(bitget(meshFormationInfo,2:7)',6,false);

    end
end
end

function mpdu = fillBasicRates(mpdu, rxCfg)
    x = strtok(rxCfg.ManagementConfig.BasicRates,' Mbps');
    numBasicRates = numel(x);
    mpdu.FrameBody.BasicRates = zeros(1,numBasicRates);
    for idx = 1:numBasicRates
        mpdu.FrameBody.BasicRates(idx) = str2double(x{idx});
    end
end

function mpdu = decodeEDCAParameterSet(mpdu, ieInformation)
%edcaParameterSetElement Return the hexadecimal octets for EDCA Parameter Set element

    % QoSInfo - '00'
    % Update EDCA Info - '00'. It is reserved for non-S1G STAs.
    % AC_BE Parameter Record - 4 octets
    % AC_BK Parameter Record - 4 octets
    % AC_VI Parameter Record - 4 octets
    % AC_VO Parameter Record - 4 octets
    % For more information, refer section 9.4.2.28 in IEEE Std 802.11-2020.

    qosInfo = ieInformation(1);
    edcaParamSetUpdateCount = bit2int(bitget(qosInfo,1:4)',4,false);
    mpdu.FrameBody.EDCAParamsCount = edcaParamSetUpdateCount;
    pos = 3;
    for idx = 1:4
        acParameterRecord = ieInformation(pos:pos+4-1);
        pos = pos+4;
        AIFSNBits = bitget(acParameterRecord(1),4:-1:1); % Byte1 - B0-B3
        mpdu.FrameBody.AIFS(idx) = bi2deOptimized(AIFSNBits);
        ECWMinBits = bitget(acParameterRecord(2),4:-1:1); % Byte2 - B0-B3
        ECWMin = bi2deOptimized(ECWMinBits);
        mpdu.FrameBody.CWMin(idx) = 2^ECWMin - 1;
        ECWMaxBits = bitget(acParameterRecord(2),8:-1:5); % Byte2 - B4-B7
        ECWMax = bi2deOptimized(ECWMaxBits);
        mpdu.FrameBody.CWMax(idx) = 2^ECWMax - 1;
        TXOPLimitBits = int2bit(acParameterRecord(3:4),8,false); % Byte1 - B0-B3
        mpdu.FrameBody.TXOPLimit(idx) = bit2int(TXOPLimitBits(:),16,false);
    end
end

function dec = bi2deOptimized(bin)
    dec = comm.internal.utilities.bi2deLeftMSB(double(bin), 2);
end