function psduLength = calculateMaxPSDULength(obj, txFormat, excludeIFS)
%calculateMaxPSDULength Returns the maximum PSDU length
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   PSDULENGTH = calculateMaxPSDULength(MACOBJ, TXFORMAT, EXCLUDEIFS)
%   returns the maximum length of the PSDU that can be formed with the
%   transmission context stored in MACOBJ.
%
%   PSDULENGTH is a scalar value indicating the maximum PSDU length.
%
%   MACOBJ is an object of type wlan.internal.mac.edcaMAC.
%
%   TXFORMAT is the physical layer (PHY) frame format, specified as a
%   constant value defined in the class wlan.internal.FrameFormats.
%
%   EXCLUDEIFS is a flag indicating whether to exclude initial IFS time
%   before the FES (SIFS/PIFS) during the calculation.

%   Copyright 2025 The MathWorks, Inc.

% Minimum transmission time (in microseconds) required for each PHY
% format with maximum possible spatial streams and bandwidth
if txFormat == obj.EHT_SU
    minPHYTxTime = 188; % ChannelBandwidth="CBW320", NumSpaceTimeStreams = 8, NumTransmitAntennas = 8
elseif any(txFormat == [obj.HE_SU obj.HE_EXT_SU])
    minPHYTxTime = 180; % ChannelBandwidth="CBW160", NumSpaceTimeStreams = 8, NumTransmitAntennas = 8
elseif txFormat == obj.VHT
    minPHYTxTime = 72; % ChannelBandwidth="CBW160", NumSpaceTimeStreams = 8, NumTransmitAntennas = 8
elseif txFormat == obj.HTMixed
    minPHYTxTime = 52; % ChannelBandwidth="CBW40", NumSpaceTimeStreams = 4, NumTransmitAntennas = 4, cfg.MCS = 31
elseif txFormat == obj.NonHT
    minPHYTxTime = 28; % ChannelBandwidth="CBW20", NumTransmitAntennas = 8
end

maxTxTime = round(calculateMaxDataTxTime(obj, true, excludeIFS)*1e-3,3); % DL transmission

if maxTxTime == 0 || (maxTxTime < minPHYTxTime) % Not enough available time
    psduLength = 0;
    return;
end

tx = obj.Tx; % Tx context
cbwStr = wlan.internal.utils.getChannelBandwidthStr(tx.TxBandwidth); % Channel bandwidth

switch txFormat
    case obj.NonHT
        tx.CfgNonHT.ChannelBandwidth = cbwStr;
        tx.CfgNonHT.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgNonHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        % To avoid symbol padding and exceeding maximum transmission
        % time, PSDU length is calculated for a symbol time less than
        % the maxTxTime
        psduLength = wlanPSDULength(tx.CfgNonHT, TxTime=maxTxTime, SuppressWarnings=true, DisableValidation=true);
        maxStdLength = 4095; % Maximum length allowed by the standard

    case obj.HTMixed
        % Fill HT config object
        tx.CfgHT.ChannelBandwidth = cbwStr;
        tx.CfgHT.AggregatedMPDU = tx.TxAggregatedMPDU;
        tx.CfgHT.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgHT.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgHT.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        % To avoid symbol padding and exceeding maximum transmission
        % time, PSDU length is calculated for a symbol time less than
        % the maxTxTime
        psduLength = wlanPSDULength(tx.CfgHT, TxTime=maxTxTime, SuppressWarnings=true, DisableValidation=true);
        maxStdLength = 65535; % Maximum length allowed by the standard

    case obj.VHT
        % Fill VHT config object
        tx.CfgVHT.ChannelBandwidth = cbwStr;
        tx.CfgVHT.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgVHT.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgVHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgVHT.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        % To avoid symbol padding and exceeding maximum transmission
        % time, PSDU length is calculated for a symbol time less than
        % the maxTxTime
        psduLength = wlanPSDULength(tx.CfgVHT, TxTime=maxTxTime, SuppressWarnings=true, DisableValidation=true);
        maxStdLength = 1048575; % Maximum length allowed by the standard

    case {obj.HE_EXT_SU, obj.HE_SU}
        % Fill HE config object
        tx.CfgHE.ExtendedRange = (obj.TransmissionFormat == obj.HE_EXT_SU);
        tx.CfgHE.ChannelBandwidth = cbwStr;
        tx.CfgHE.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgHE.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgHE.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgHE.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        % To avoid symbol padding and exceeding maximum transmission
        % time, PSDU length is calculated for a symbol time less than
        % the maxTxTime
        psduLength = wlanPSDULength(tx.CfgHE, TxTime=maxTxTime, SuppressWarnings=true, DisableValidation=true);
        maxStdLength = 6500631; % Maximum length allowed by the standard

    case obj.EHT_SU
        suIndex = 1;
        tx.CfgEHT = wlanEHTMUConfig(cbwStr); % cbwStr contains bandwidth decided for this transmission
        % Fill EHT config object
        tx.CfgEHT.User{suIndex}.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgEHT.User{suIndex}.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgEHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgEHT.RU{suIndex}.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        % To avoid symbol padding and exceeding maximum transmission
        % time, PSDU length is calculated for a symbol time less than
        % the maxTxTime
        psduLength = wlanPSDULength(tx.CfgEHT, TxTime=maxTxTime, SuppressWarnings=true, DisableValidation=true);
        maxStdLength = 15523198; % Maximum length allowed by the standard
end

if txFormat ~= obj.NonHT
    if psduLength > maxStdLength
        psduLength = maxStdLength;
    end
end
end