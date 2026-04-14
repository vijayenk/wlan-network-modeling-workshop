function notifyTransmissionStarted(obj, psduLength, txTime, txVector)
%notifyTransmissionStarted Invoke callbacks registered for
%TransmissionStarted event
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   notifyTransmissionStarted(OBJ, PSDULENGTH, TXTIME, TXVECTOR) invokes
%   callbacks registered for TransmissionStarted event and passes
%   notification data to callbacks.
%
%   PSDULENGTH is the number of bytes sent from MAC to PHY in current
%   transmission.
%
%   TXTIME is the duration of current transmission in nanoseconds.
%
%   TXVECTOR is the transmit parameters vector.

%   Copyright 2025 The MathWorks, Inc.

% Information for triggering TransmissionStarted event
notificationData = obj.EventTemplate;
notificationData.EventName = "TransmissionStarted";
notificationData.Timestamp = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);
txStartedInfo = obj.TransmissionStarted;
txStartedInfo.Length = psduLength;
txStartedInfo.Duration = wlan.internal.utils.nanoseconds2seconds(txTime);
txStartedInfo.TransmitPower = txVector.PerUserInfo(1).TxPower;
txBandwidth = txVector.ChannelBandwidth;
txStartedInfo.TransmitCenterFrequency = wlan.internal.utils.getPacketCenterFrequency(obj.OperatingFrequency, ...
    obj.ChannelBandwidth, obj.PrimaryChannelIndex, txBandwidth, obj.CandidateCentFreqOffset);
txStartedInfo.TransmitBandwidth = txBandwidth*1e6;
if obj.IncludeVector
    % PPDU parameters - TxVector parameters
    ppduParams = obj.PPDUParametersTemplate;
    frameFormat = txVector.PPDUFormat;
    ppduParams.Format = string(wlan.internal.utils.getFrameFormatString(frameFormat, 'MAC'));
    if ppduParams.Format == "HE-MU"
        ppduParams.Format = "HE-MU-OFDMA";
    end
    ppduParams.Aggregation = txVector.AggregatedMPDU;
    if any(frameFormat == [obj.HE_MU, obj.HE_SU, obj.HE_EXT_SU, obj.HE_TB, obj.EHT_SU, obj.EHT_MU, obj.EHT_TB])
        ppduParams.TXOPDuration = txVector.TXOPDuration;
        ppduParams.BSSColor = txVector.BSSColor;
    end
    ppduParams.MCS = [txVector.PerUserInfo(:).MCS];
    ppduParams.NumSpaceTimeStreams = [txVector.PerUserInfo(:).NumSpaceTimeStreams];
    txStartedInfo.PPDUParameters = ppduParams;
end
notificationData.EventData = txStartedInfo;

% Trigger TransmissionStarted event
callbacks = obj.TransmissionStartedFcn;
for idx = 1:numel(callbacks)
    callbacks{idx}(notificationData);
end
end
