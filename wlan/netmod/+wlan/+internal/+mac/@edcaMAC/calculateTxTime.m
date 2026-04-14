function duration = calculateTxTime(obj, frameFormat, psduLength, mcs, numSTS, varargin)
%calculateTxTime Calculate the physical layer protocol data unit (PPDU)
%transmission time
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   DURATION = calculateTxTime(OBJ, FRAMEFORMAT, PSDULENGTH, MCS, NUMSTS,
%   CBW) returns the transmission time for PPDU of format other than
%   wlan.internal.FrameFormats.HE_TB.
%
%   DURATION is an integer, indicates the duration to transmit PPDU in
%   nanoseconds.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMEFORMAT specifies the format of the PSDU to be transmitted. It is a
%   constant value defined in wlan.internal.FrameFormats.
%
%   PSDULENGTH is the length of the PSDU in bytes. In case of MU
%   transmission, it is a vector with values corresponding to each user.
%
%   MCS is the MCS index for transmitting the MAC frame. In case of MU
%   transmission, it is a vector with values corresponding to each user.
%
%   NUMSTS is the number of spatial streams used for transmitting the MAC
%   frame. In case of MU transmission, it is a vector with values
%   corresponding to each user.
%
%   CBW is an integer, indicates the channel bandwidth used for
%   transmitting the MAC frame.
%
%   DURATION = calculateTxTime(OBJ, FRAMEFORMAT, PSDULENGTH, MCS, NUMSTS,
%   TRIGMETHOD) returns the transmission time for PPDU of format
%   wlan.internal.FrameFormats.HE_TB.
%
%   TRIGMETHOD is the type of trigger that solicited the UL HE-TB frame.
%   Possible values are 'TriggerFrame' or 'TRS'.

%   Copyright 2022-2025 The MathWorks, Inc.

tx = obj.Tx; % Tx context
if frameFormat == obj.HE_TB
    trigMethod = varargin{1};
else
    cbw = varargin{1};
end

userIdx = obj.UserIndexSU;

switch frameFormat
    case obj.NonHT
        % Pre-calculated durations for most used control frame lengths
        if (cbw == 20) && (numSTS(userIdx) == 1)
            switch psduLength(userIdx)
                case 14
                    txTimePerMCS = [44000, 36000, 32000, 28000, 28000, 24000, 24000, 24000];
                    duration = txTimePerMCS(mcs(userIdx)+1);
                    return;
                case 20
                    txTimePerMCS = [52000, 44000, 36000, 32000, 28000, 28000, 24000, 24000];
                    duration = txTimePerMCS(mcs(userIdx)+1);
                    return;
                case 32
                    txTimePerMCS = [68000, 52000, 44000, 36000, 32000, 28000, 28000, 28000];
                    duration = txTimePerMCS(mcs(userIdx)+1);
                    return;
                case 56
                    txTimePerMCS = [100000, 76000, 60000, 48000, 40000, 36000, 32000, 32000];
                    duration = txTimePerMCS(mcs(userIdx)+1);
                    return;
                case 88
                    txTimePerMCS = [144000, 104000, 84000, 64000, 52000, 44000, 36000, 36000];
                    duration = txTimePerMCS(mcs(userIdx)+1);
                    return;
                case 152
                    txTimePerMCS = [228000, 160000, 124000, 92000, 72000, 56000, 48000, 44000];
                    duration = txTimePerMCS(mcs(userIdx)+1);
                    return;
            end
        end

        % Non-HT format configuration object
        cbwStr = wlan.internal.utils.getChannelBandwidthStr(cbw); % Channel bandwidth
        tx.CfgNonHT.ChannelBandwidth = cbwStr;
        tx.CfgNonHT.MCS = mcs(userIdx);
        tx.CfgNonHT.NumTransmitAntennas = numSTS(userIdx);
        tx.CfgNonHT.PSDULength = psduLength(userIdx);

        % Get PPDU info
        ppduInfo = validateConfig(tx.CfgNonHT);

    case obj.HTMixed
        % HT format configuration object
        cbwStr = wlan.internal.utils.getChannelBandwidthStr(cbw); % Channel bandwidth
        tx.CfgHT.ChannelBandwidth = cbwStr;
        tx.CfgHT.MCS = mcs(userIdx);
        tx.CfgHT.NumTransmitAntennas = numSTS(userIdx);
        tx.CfgHT.NumSpaceTimeStreams = numSTS(userIdx);
        tx.CfgHT.PSDULength = psduLength;

        % Get PPDU info
        ppduInfo = validateConfig(tx.CfgHT);

    case obj.VHT
        % VHT format configuration object
        cbwStr = wlan.internal.utils.getChannelBandwidthStr(cbw); % Channel bandwidth
        tx.CfgVHT.ChannelBandwidth = cbwStr;
        tx.CfgVHT.MCS = mcs(userIdx);
        tx.CfgVHT.NumTransmitAntennas = numSTS(userIdx);
        tx.CfgVHT.NumSpaceTimeStreams = numSTS(userIdx);
        tx.CfgVHT.APEPLength = psduLength(userIdx);

        % Get PPDU info
        ppduInfo = validateConfig(tx.CfgVHT);

    case {obj.HE_SU, obj.HE_EXT_SU}
        % HE format configuration object
        cbwStr = wlan.internal.utils.getChannelBandwidthStr(cbw); % Channel bandwidth
        tx.CfgHE.ChannelBandwidth = cbwStr;
        tx.CfgHE.ExtendedRange = false;
        if frameFormat == obj.HE_EXT_SU
            tx.CfgHE.ExtendedRange = true;
        end
        tx.CfgHE.MCS = mcs(userIdx);
        tx.CfgHE.NumTransmitAntennas = numSTS(userIdx);
        tx.CfgHE.NumSpaceTimeStreams = numSTS(userIdx);
        tx.CfgHE.APEPLength = psduLength(userIdx);

        % Get PPDU info
        ppduInfo = validateConfig(tx.CfgHE);

    case obj.EHT_SU
        % EHT format configuration object
        tx.CfgEHT.User{userIdx}.MCS = mcs(userIdx);
        tx.CfgEHT.NumTransmitAntennas = numSTS(userIdx);
        tx.CfgEHT.User{userIdx}.NumSpaceTimeStreams = numSTS(userIdx);
        tx.CfgEHT.User{userIdx}.APEPLength = psduLength(userIdx);
        
        % Get PPDU info
        ppduInfo = validateConfig(tx.CfgEHT);

    case obj.HE_MU
        % HE-MU PHY configuration object
        tx.CfgHEMU.NumTransmitAntennas = obj.NumTransmitAntennas;
        for userIdx = 1:tx.NumTxUsers
            tx.CfgHEMU.User{userIdx}.MCS = mcs(userIdx);
            tx.CfgHEMU.User{userIdx}.APEPLength = psduLength(userIdx);
            tx.CfgHEMU.User{userIdx}.NumSpaceTimeStreams = numSTS(userIdx);
        end

        % Get PPDU info
        ppduInfo = validateConfig(tx.CfgHEMU);

    case obj.HE_TB
        cfgSys = obj.ULTBSysCfg;
        cfgSys.TriggerMethod = trigMethod;
        ruSizes = ruInfo(cfgSys).RUSizes;

        for userIdx = 1:tx.NumTxUsers
            % Fill user specific fields
            cfgSys.User{userIdx}.NumTransmitAntennas = numSTS(userIdx);
            cfgSys.User{userIdx}.NumSpaceTimeStreams = numSTS(userIdx);
            cfgSys.User{userIdx}.APEPLength = psduLength(userIdx);
            cfgSys.User{userIdx}.AID12 = getAID(obj.SharedMAC, tx.TxStationIDs(userIdx));
            cfgSys.User{userIdx}.MCS = mcs(userIdx);

            if ruSizes(userIdx) < 484 && strcmp(trigMethod, 'TRS')
                cfgSys.User{userIdx}.ChannelCoding = 'BCC';
            end
        end

        % Get valid TRS configuration object
        if strcmp(trigMethod, 'TRS')
            cfgSys = getTRSConfiguration(cfgSys);
        end

        % Set common transmission properties and get tx time of HE-TB PPDU
        ppduInfo = validateConfig(cfgSys);
        tx.NumHELTFSymbols = wlan.internal.numVHTLTFSymbols(max(ruInfo(cfgSys).NumSpaceTimeStreamsPerRU));
        for userIdx = 1:tx.NumTxUsers
            tx.NumDataSymbols(userIdx) = ppduInfo.NumDataSymbols;
        end
        tx.LSIGLength = ppduInfo.LSIGLength;
end

% Tx time of the PPDU
duration = round(ceil(ppduInfo.TxTime)*1e3);
end
