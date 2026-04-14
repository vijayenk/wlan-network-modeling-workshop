function notifyReceptionEnded(obj, phyFailure, ppduInfo, bandwidth)
%notifyReceptionEnded Invoke callbacks registered for ReceptionEnded event
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   notifyReceptionEnded(OBJ, PHYFAILURE, PPDUINFO, BANDWIDTH,
%   MACFRAMERECEIVED) invokes callbacks registered for ReceptionEnded event
%   and passes notification data to callbacks.
%
%   PHYFAILURE is an integer indicating decode failure at PHY. 0 indicates
%   success and 1 indicates failure.
%
%   PPDUINFO is a structure containing information of the received PPDU,
%   with fields 'StartTime' and 'CenterFrequency'.
%
%   BANDWIDTH is the bandwidth of current reception in MHz.
%
%   MACFRAMERECEIVED is a flag indicating whether PHY has decoded payload
%   and sent it to MAC.

%   Copyright 2025 The MathWorks, Inc.

notificationData = obj.EventTemplate;
notificationData.EventName = "ReceptionEnded";
notificationData.Timestamp = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);

receptionEnded = obj.ReceptionEnded;
rxVec = obj.Rx.RxVector;
frameFormat = rxVec.PPDUFormat;

if obj.IncludeVector
    % PPDU parameters - RxVector parameters
    ppduParams = obj.PPDUParametersTemplate;

    if phyFailure == 0 % PHY header decoded and sent to MAC
        ppduParams.Format = string(wlan.internal.utils.getFrameFormatString(frameFormat, 'MAC'));
        if ppduParams.Format == "HE-MU"
            ppduParams.Format = "HE-MU-OFDMA";
        end
        ppduParams.Aggregation = rxVec.AggregatedMPDU;
        if any(frameFormat == [obj.HE_MU, obj.HE_SU, obj.HE_EXT_SU, obj.HE_TB, obj.EHT_SU, obj.EHT_MU, obj.EHT_TB])
            ppduParams.TXOPDuration = rxVec.TXOPDuration;
            ppduParams.BSSColor = rxVec.BSSColor;
        end
        if any(frameFormat == [obj.NonHT, obj.HE_MU])
            % Multiple CTS frames are received in response to MU-RTS and therefore PHY
            % sends multiple PerUserInfo fields. But it must be considered as a single
            % PPDU reception. As the below parameters are same for all received CTS,
            % assign first one.
            % In case of HE-MU PPDU, the first per-user info field contains information
            % of current user. PHY assigns it in this way.
            ppduParams.MCS = rxVec.PerUserInfo(1).MCS;
            ppduParams.NumSpaceTimeStreams = rxVec.PerUserInfo(1).NumSpaceTimeStreams;
        else
            ppduParams.MCS = [rxVec.PerUserInfo(:).MCS];
            ppduParams.NumSpaceTimeStreams = [rxVec.PerUserInfo(:).NumSpaceTimeStreams];
        end
        ppduParams.TransmitPower = rxVec.PerUserInfo(1).TxPower;
    end
    receptionEnded.PPDUParameters = ppduParams;
end

if phyFailure == 0 % PHY header decoded and sent to MAC
    if any(frameFormat == [obj.NonHT, obj.HE_MU])
        receptionEnded.Length = rxVec.PerUserInfo(1).Length;
    else
        receptionEnded.Length = [rxVec.PerUserInfo(:).Length];
    end
end
receptionEnded.Duration = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS) - ppduInfo.StartTime;
receptionEnded.ReceiveCenterFrequency = ppduInfo.CenterFrequency;
receptionEnded.ReceiveBandwidth = bandwidth;
receptionEnded.PHYDecodeStatus = -1*phyFailure;
receptionEnded.IsIntendedReception = any(receptionEnded.IsIntendedReception);
notificationData.EventData = receptionEnded;

% Trigger ReceptionEnded event
callbacks = obj.ReceptionEndedFcn;
for idx = 1:numel(callbacks)
    callbacks{idx}(notificationData);
end

% Reset
obj.ReceptionEnded = obj.ReceptionEndedTemplate;
end
