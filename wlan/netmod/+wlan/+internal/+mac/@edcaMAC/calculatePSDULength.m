function psduLength = calculatePSDULength(obj, txFormat, apepLength)
%calculatePSDULength Returns the maximum PSDU apepLength
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   PSDULENGTH = calculatePSDULength(MACOBJ, TXFORMAT, EXCLUDEIFS) returns
%   the PSDU length for the given APEP length and the transmission context
%   stored in MACOBJ.
%
%   PSDULENGTH is a scalar value indicating the calculated PSDU length.
%
%   MACOBJ is an object of type wlan.internal.mac.edcaMAC.
%
%   TXFORMAT is the physical layer (PHY) frame format, specified as a
%   constant value defined in the class wlan.internal.FrameFormats.
%
%   APEPLENGTH is a scalar (for SU frames) or a vector (for MU frames)
%   value, indicating the APEP lengths of the frames for which PSDU length
%   needs to be calculated.

%   Copyright 2025 The MathWorks, Inc.

tx = obj.Tx; % Tx context

cbwStr = wlan.internal.utils.getChannelBandwidthStr(tx.TxBandwidth); % Channel bandwidth

switch txFormat
    case obj.NonHT
        tx.CfgNonHT.ChannelBandwidth = cbwStr;
        tx.CfgNonHT.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgNonHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        psduLength = apepLength;

    case obj.HTMixed
        % Fill HT config object
        tx.CfgHT.ChannelBandwidth = cbwStr;
        tx.CfgHT.AggregatedMPDU = tx.TxAggregatedMPDU;
        tx.CfgHT.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgHT.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgHT.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        psduLength = apepLength;

    case obj.VHT
        % Fill VHT config object
        tx.CfgVHT.ChannelBandwidth = cbwStr;
        tx.CfgVHT.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgVHT.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgVHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgVHT.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        tx.CfgVHT.APEPLength = apepLength;
        ppduInfo = validateConfig(tx.CfgVHT);
        psduLength = ppduInfo.PSDULength;

    case {obj.HE_EXT_SU, obj.HE_SU}
        % Fill HE config object
        tx.CfgHE.ExtendedRange = (txFormat == obj.HE_EXT_SU);
        tx.CfgHE.ChannelBandwidth = cbwStr;
        tx.CfgHE.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgHE.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgHE.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgHE.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        tx.CfgHE.APEPLength = apepLength;
        ppduInfo = validateConfig(tx.CfgHE);
        psduLength = ppduInfo.PSDULength;

    case obj.HE_MU
        % Fill HE-MU config object
        tx.CfgHEMU.NumTransmitAntennas = obj.NumTransmitAntennas;
        for userIdx = 1:tx.NumTxUsers
            tx.CfgHEMU.User{userIdx}.MCS = tx.TxMCS(userIdx);
            tx.CfgHEMU.User{userIdx}.APEPLength = apepLength(userIdx);
            tx.CfgHEMU.User{userIdx}.NumSpaceTimeStreams = tx.TxNumSTS(userIdx);
            tx.CfgHEMU.RU{userIdx}.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        end
        ppduInfo = validateConfig(tx.CfgHEMU);
        psduLength = ppduInfo.PSDULength;

    case obj.EHT_SU
        suIndex = 1;
        tx.CfgEHT = wlanEHTMUConfig(cbwStr); % cbwStr contains bandwidth decided for this transmission
        % Fill EHT config object
        tx.CfgEHT.User{suIndex}.MCS = tx.TxMCS(obj.UserIndexSU);
        tx.CfgEHT.User{suIndex}.NumSpaceTimeStreams = tx.TxNumSTS(obj.UserIndexSU);
        tx.CfgEHT.NumTransmitAntennas = obj.NumTransmitAntennas;
        tx.CfgEHT.RU{suIndex}.SpatialMapping = 'Fourier'; % Force to allow validation of any NumTx and NumSTS
        tx.CfgEHT.User{suIndex}.APEPLength = apepLength;
        ppduInfo = validateConfig(tx.CfgEHT);
        psduLength = ppduInfo.PSDULength;
end
end