function nextFrameType = scheduleTriggerBasedTransmission(obj)
%scheduleTriggerBasedTransmission Determines whether to send a QoS Null
%frame or QoS data frame in response to Basic trigger frame
%
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTFRAMETYPE = prepareULTBFrame(OBJ) determines the type of frame to
%   be sent in response to Basic trigger frame and the AC for transmission.
%
%   NEXTFRAMETYPE is an enumerated value returned as one of the following
%   constant values of edcaMAC object: QoSData, QoSNull.
%
%   OBJ is an object of type edcaMAC.

%   Copyright 2025 The MathWorks, Inc.

tx = obj.Tx; % obj.Tx is a handle object
rx = obj.Rx; % obj.Rx is a handle object
tx.NumTxUsers = 1;
nextFrameType = obj.QoSData;
apID = wlan.internal.utils.macAddress2NodeID(obj.BSSID); % Node ID of associated AP

% Determine the expected UL PSDU length
cfgTB = tx.CfgTB;
% Fill the parameters in PHY config object of UL HE TB PPDU
cfgTB.TriggerMethod = "TriggerFrame";
cfgTB.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(rx.RxVector.ChannelBandwidth);
cfgTB.RUSize = rx.ResponseRU(1);
cfgTB.RUIndex = rx.ResponseRU(2);
cfgTB.NumTransmitAntennas = obj.NumTransmitAntennas;
cfgTB.NumSpaceTimeStreams = rx.ResponseNumSTS;
cfgTB.SpatialMapping = 'Fourier'; % This is to allow any combination of NumSTS and NumTxAntennas
cfgTB.MCS = rx.ResponseMCS;
cfgTB.LSIGLength = rx.ULLSIGLength;
cfgTB.NumHELTFSymbols = rx.ULNumHELTFSymbols;
cfgTB.ChannelCoding = 'LDPC';
expectedPSDULength = cfgTB.getPSDULength;
tx.CfgTB = cfgTB;

% As MU is supported only in non-MLD, packets to AP will be present in
% per-link queues. So, consider per-link queues for further operations
queueObj = obj.LinkEDCAQueues;
% Discard any packets whose lifetime expired
discard(obj, false, queueObj);

% Determine transmission AC
acs = [2 1 3 4];
preferredIdx = find(acs == rx.ULPreferredAC+1);
% Store the ACs starting from preferred AC and followed by ACs of higher
% priority followed by ACs of lower priority. Refer to Section 26.6.3.1 of
% IEEE Standard 802.11ax-2021. This section refers to TIDs. But considering
% the mapping of AC to TID, the same applies for ACs.
acs = [rx.ULPreferredAC+1 acs(preferredIdx+1:end) acs(1:preferredIdx-1)];

tx.TxMPDUCount(obj.UserIndexSU) = 0;
if size(queueObj.TxQueueLengths, 1) == 1 || (rx.ULTIDAggregationLimit == 0 && ~obj.DisableAck)
    % Send QoS Null frame in the A-MPDU carried in HE-TB PPDU as defined in:
    %   Table 9-531 of IEEE Std 802.11ax-2021, if there is no data to send to
    %   AP. If number of rows in queueLengths variable is 1, it means that
    %   there are queues in 4 ACs only for 1 STA. These default queues
    %   correspond to broadcast.
    %
    %   Table 9-534 of IEEE Std 802.11ax-2021, if the TID Aggregation Limit
    %   subfield is 0. In this case, STA shall send MPDUs that doesn't solicit
    %   immediate response. Reference: Section 26.5.2.2.4 of IEEE Std
    %   802.11ax-2021.
    nextFrameType = obj.QoSNull;
    tx.TxACs(obj.UserIndexSU) = rx.ULPreferredAC+1;

else
    maxSubframes = obj.MaxSubframes;
    if obj.DisableAck
        % If the data doesn't solicit an immediate response, send an S-MPDU with
        % QoS Data with 'No Ack' in the A-MPDU carried in HE-TB PPDU as defined in
        % Table 9-534 of IEEE Std 802.11ax-2021.
        maxSubframes = 1;
    end

    for acIdx = 1:4
        ac = acs(acIdx);
        [~, retryBufferIdx] = getAvailableRetryBuffer(queueObj, apID, ac);
        queueLength = numTxFramesAvailable(obj, ac, apID, queueObj, retryBufferIdx);

        % Determine the count of MSDUs that can be aggregated in the AC
        if queueLength > 0
            tx.TxACs(obj.UserIndexSU) = ac;

            if retryBufferIdx == 0 % No packets available for AP in retry buffer
                % Get the lengths of MSDUs present in MAC transmission queues
                txMSDULengths = getMSDULengthsinTxQueues(queueObj, apID, ac);
            else
                % Get the lengths of MSDUs present in MAC retry buffer
                txMSDULengths = getMSDULengthsInRetryBuffer(queueObj, apID, ac, retryBufferIdx);
            end

            psduLength = 0; % Initialize
            mpduOverhead = obj.MPDUOverhead + 4; % 4 bytes for HT Control (BSR Control)

            for msduIdx = 1:queueLength
                % MSDU length
                msduLen = txMSDULengths(msduIdx);

                % Calculate PSDU length
                psduLength = psduLength + (mpduOverhead + msduLen);

                % Delimiter overhead for aggregated frames (4 Octets)
                psduLength = psduLength + 4;

                % Subframe padding overhead for aggregated frames
                subFramePadding = abs(mod(msduLen+mpduOverhead, -4));
                psduLength = psduLength + subFramePadding;

                if (tx.TxMPDUCount(obj.UserIndexSU) < maxSubframes) && (psduLength <= expectedPSDULength)
                    tx.TxMPDUCount(obj.UserIndexSU) = tx.TxMPDUCount(obj.UserIndexSU) + 1;
                else  % Max PSDU length is reached
                    break;
                end
            end

            if tx.TxMPDUCount(obj.UserIndexSU) > 0
                % At least 1 MSDU of the AC can be sent in allocated resources
                break;
            end
        end
    end

    if tx.TxMPDUCount(obj.UserIndexSU) == 0
        % Allocated resources are not sufficient. Send QoS Null in the A-MPDU
        % carried in HE-TB PPDU as defined in Table 9-531 of IEEE Std
        % 802.11ax-2021.
        nextFrameType = obj.QoSNull;
        tx.TxACs(obj.UserIndexSU) = rx.ULPreferredAC+1;
    end
end

% Set the required transmission context
tx.TxStationIDs(obj.UserIndexSU) = apID;
tx.TxFormat = obj.HE_TB;
tx.TxAggregatedMPDU = true;
tx.TxMCS(obj.UserIndexSU) = rx.ResponseMCS;
tx.TxNumSTS(obj.UserIndexSU) = rx.ResponseNumSTS;
tx.TxBandwidth = rx.RxVector.ChannelBandwidth;

isQoSNull = (nextFrameType == obj.QoSNull);
if isQoSNull
    % Disabling acknowledgment for QoS Null frames
    tx.NoAck = true;

    % Set required transmission context
    tx.NumAddressFields(obj.UserIndexSU) = 3;
else
    % Set flags (Ack policy for this frame transmission)
    tx.NoAck = obj.DisableAck;

    % Set required transmission context
    isGroupcast = false;
    tx.NumAddressFields(obj.UserIndexSU) = numAddressFieldsInHeader(obj, isGroupcast);
end
end