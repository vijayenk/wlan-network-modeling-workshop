function [mcsIndex, frameLength] = controlFrameRateAndLen(obj, frameType)
%controlFrameRateAndLen Return the MCS index and length of the specified
%control frame
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   [MCSINDEX, FRAMELENGTH] = controlFrameRateAndLen(OBJ, FRAMETYPE)
%   returns the MCS index and length of the control frame specified by
%   FRAMETYPE.
%
%   MCSINDEX is the MCS in which the control frame should be transmitted.
%
%   FRAMELENGTH is the length of the control frame.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMETYPE is an enumerated value of the frame type specified as one of
%   the following constant values of edcaMAC object: RTS, MURTSTrigger,
%   MUBARTrigger, BasicTrigger, CFEnd.

%   Copyright 2024-2025 The MathWorks, Inc.

tx = obj.Tx;

% Calculate frame length
if (frameType == obj.RTS)
    frameLength = controlFrameMPDULength(obj, 'RTS');

elseif (frameType == obj.MURTSTrigger)
    if isAPToEMLSRSTATransmission(obj) % ICF (MU-RTS)
        isICFFrame = true;
        frameLength = controlFrameMPDULength(obj, 'Trigger', 'MU-RTS', tx.NumTxUsers, isICFFrame);
    else
        % MU-RTS frame length = 28 bytes(header + common info field +
        % FCS) + (5 bytes * number of users represented in user info
        % fields), assuming all the users are associated and no RA-RU
        % assignment
        isICFFrame = false;
        frameLength = controlFrameMPDULength(obj, 'Trigger', 'MU-RTS', tx.NumTxUsers, isICFFrame);
    end

elseif (frameType == obj.MUBARTrigger)
    % MU-BAR frame length = 28 bytes(header + common info field + FCS)
    % + (9 bytes * number of users represented in user info fields),
    % assuming all the users are associated and no RA-RU assignment
    isICFFrame = false;
    frameLength = controlFrameMPDULength(obj, 'Trigger', 'MU-BAR', tx.NumTxUsers, isICFFrame);

elseif (frameType == obj.BasicTrigger)
    % Basic trigger frame length = 28 bytes(header + common info field + FCS) +
    % 6 bytes (Trigger Dependent User Info)
    % * number of users represented in user info fields,
    % assuming all the users are associated and no RA-RU
    % assignment
    isICFFrame = false;
    frameLength = controlFrameMPDULength(obj, 'Trigger', 'Basic', tx.NumTxUsers, isICFFrame);

elseif (frameType == obj.CFEnd)
    % CF-End frame length = 20 bytes (Frame control=2 + Duration=2 + RA=6 +
    % BSSID(TA)=6 + FCS=4)
    frameLength = controlFrameMPDULength(obj, 'CF-End');
end

% Control frame type                                 |  Rate to use
% ---------------------------------------------------|---------------------
% All control frames when Use6MbpsForControlFrames   |      6 Mbps
% is true                                            |
% RTS frame                                          |      6 Mbps
% MU-RTS frame for OFDMA                             |  Maximum rate from BasicRates set
% Initial Control Frame (MU-RTS)                     |      24 Mbps
% MU-BAR frame                                       |  Maximum rate from BasicRates set
% Basic trigger frame to single user                 |      6 Mbps
% Basic trigger frame to multiple users              |  Maximum rate from BasicRates set
% CF-End frame                                       |      6 Mbps

% Calculate frame rate
if obj.Use6MbpsForControlFrames
    mcsIndex = obj.NonHTMCSIndex6Mbps;
    return;
end

% If a control frame is broadcast, use maximum of basic rates. This is
% implementation specific. As per the IEEE Std 802.11, any of the basic
% rates can be used.
if (frameType == obj.RTS)
    destStationID = tx.TxStationIDs(obj.UserIndexSU);
    acIndex = tx.TxACs(obj.UserIndexSU);

    % Rate at which RTS has to be transmitted
    % Reference: Section 10.6.6.2 (When RTS initiates a TXOP) and
    % Section 10.6.6.4 (When RTS is non-initial frame of a TXOP) of
    % IEEE Std 802.11-2020
    rateControlInfo = obj.RateControlTxContextTemplate;
    rateControlInfo.FrameType = 'RTS';
    rateControlInfo.ReceiverNodeID = destStationID;
    rateControlInfo.TransmissionFormat = "Non-HT";
    rateControlInfo.ChannelBandwidth = tx.TxBandwidth*1e6;
    % LastRunTimeNS contains time at which MAC is invoked
    rateControlInfo.CurrentTime = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);
    queueObj = getQueueObj(obj, destStationID, acIndex);
    [~, retryBufferIdx] = getAvailableRetryBuffer(queueObj, destStationID, acIndex);
    if retryBufferIdx == 0 % No packets available for this station in retry buffers
        rateControlInfo.IsRetry = false;
    else
        rateControlInfo.IsRetry = true;
    end
    obj.ControlFrameRateControlTxContext = rateControlInfo;
    rateInfo = rateParameters(obj.RateControl, rateControlInfo);
    mcsIndex = rateInfo.MCS;

elseif (frameType == obj.MURTSTrigger)
    if isAPToEMLSRSTATransmission(obj) % MU-RTS for ICF
        % Initial control frames are sent in Non-HT format at either 6, 12 or 24
        % Mbps. Reference: Section 35.3.17 of IEEE P802.11be/D5.0. Choose 24
        % Mbps (maximum of [6 12 24] similar to broadcast data frame rate) to
        % transmit ICF. This is implementation specific.
        mcsIndex = 4; % MCS corresponding to 24 Mbps

    else
        % MU-RTS for multi-user transmission
        % Reference: Section 10.6.6.1 of IEEE Std 802.11ax-2021
        % Fixed rate control for MU transmissions
        rateControlInfo = obj.RateControlTxContextTemplate;
        rateControlInfo.FrameType = 'MU-RTS';
        rateControlInfo.ReceiverNodeID = tx.TxStationIDs(obj.UserIndexSU);
        rateControlInfo.IsRetry = false;
        rateControlInfo.TransmissionFormat = "Non-HT";
        rateControlInfo.ChannelBandwidth = tx.TxBandwidth*1e6;
        % LastRunTimeNS contains time at which MAC is invoked
        rateControlInfo.CurrentTime = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);
        obj.ControlFrameRateControlTxContext = rateControlInfo;
        rateInfo = rateParameters(obj.RateControl, rateControlInfo);
        mcsIndex = rateInfo.MCS;
    end

elseif (frameType == obj.MUBARTrigger) % MU-BAR for multi-user transmission
    % Fixed rate control for MU transmissions
    rateControlInfo = obj.RateControlTxContextTemplate;
    rateControlInfo.FrameType = 'MU-BAR';
    rateControlInfo.ReceiverNodeID = tx.TxStationIDs(obj.UserIndexSU);
    rateControlInfo.IsRetry = false;
    rateControlInfo.TransmissionFormat = "Non-HT";
    rateControlInfo.ChannelBandwidth = tx.TxBandwidth*1e6;
    % LastRunTimeNS contains time at which MAC is invoked
    rateControlInfo.CurrentTime = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);
    obj.ControlFrameRateControlTxContext = rateControlInfo;
    rateInfo = rateParameters(obj.RateControl, rateControlInfo);
    mcsIndex = rateInfo.MCS;

elseif (frameType == obj.BasicTrigger)
    % Determine Basic Trigger frame rate
    if tx.NumTxUsers > 1
        % Use maximum basic rate if Basic Trigger frame is a broadcast frame
        % (similar to the broadcast data frame rate)
        mcsIndex = max(obj.NonHTMCSIndicesForBasicRates);
    else
        % Use 6 Mbps if Basic Trigger frame is a unicast frame
        mcsIndex = obj.NonHTMCSIndex6Mbps;
    end

elseif (frameType == obj.CFEnd)
    % Reference: Section 10.6.6.3 of IEEE Std 802.11-2020 
    mcsIndex = obj.NonHTMCSIndex6Mbps;
end
end
