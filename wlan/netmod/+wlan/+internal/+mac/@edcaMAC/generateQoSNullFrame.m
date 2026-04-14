function frameToPHY = generateQoSNullFrame(obj, frameTxTime)
%generateQoSNullFrame Generate QoS Null frame to be sent to PHY
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   FRAMETOPHY = generateQoSNullFrame(OBJ, FRAMETXTIME) generates QoS Null
%   frame to be sent to physical layer.
%
%   FRAMETOPHY is the generated null frame.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMETXTIME is the frame transmission time in nanoseconds.

%   Copyright 2023-2025 The MathWorks, Inc.

tx = obj.Tx;
retry = false; % Set the retry flag to false for QoS Null frame, as there is no payload (MSDU).
acIndex = tx.TxACs(obj.UserIndexSU);

% As the QoS Null frame is transmitted in an A-MPDU, increment A-MPDU
% transmission count.
obj.TransmittedAMPDUsPerAC(acIndex) = obj.TransmittedAMPDUsPerAC(acIndex) + 1;

% Fill MPDU fields
mpdu = obj.MPDUQoSNullTemplate;
durationField = round(obj.Rx.TriggerDurationField*1e3) - obj.SIFSTime - frameTxTime; % In nanoseconds
% Convert durationField to microseconds to align with units of 'Duration' field in MAC frame
durationField = max(round(durationField*1e-3, 3), 0); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
mpdu.Header.Duration = durationField;
mpdu.Header.Retransmission = retry;
receiverNodeID = wlan.internal.utils.macAddress2NodeID(obj.BSSID);
mpdu = setToDSAndFromDS(obj, mpdu, receiverNodeID);
mpdu.Header.Address1 = obj.BSSID; % Receiver address (RA)
mpdu.Header.Address2 = obj.MACAddress; % Transmitter address (TA)
mpdu.Header.Address3 = obj.BSSID;
% Consider the A-MPDU contents according to Table 9-531/Table 9-534 of IEEE
% Std 802.11ax-2021 and set the ack policy to 'No Ack' for QoS Null frame.
% Reference: Section 26.5.2.4 of IEEE Std 802.11ax-2021
mpdu.Header.AckPolicy = 'No Ack';
mpdu = assignSequenceNumber(obj.SharedMAC, mpdu);
mpdu.Header.TID = wlan.internal.Constants.AC2TID(tx.TxACs(obj.UserIndexSU));
if obj.IsAssociatedSTA && obj.ULOFDMAEnabledAtAP
    % Fill BSR Control information in uplink frames from STA, when UL OFDMA is
    % enabled at AP. When UL OFDMA is enabled at AP, it is informed to STA
    % during association.

    % BSR Control Info is present in each MPDU header. But not maintaining it
    % per MPDU for simplicity. Also, same information would be present in all
    % MPDUs.
    mpdu.Header.AControlID = 3; % Identifier representing that BSR control info is present in AControlInfo
    mpdu.Header.AControlInfo = getBSRControlInfo(obj);
end

% Fill MPDU metadata
mpduIdx = 1;
mpdu.Metadata.MPDULength = tx.TxMPDULengths(mpduIdx, obj.UserIndexSU);
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = tx.TxMPDULengths(mpduIdx, obj.UserIndexSU) + 4; % Adding MPDU delimiter length of 4 bytes

% Create frame structure to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.PSDULength = tx.TxFrameLength(obj.UserIndexSU);
frameToPHY.SequenceNumbers(obj.UserIndexSU, mpduIdx) = mpdu.Header.SequenceNumber;

obj.TXOPDuration = durationField; % Fill for HE PPDUs

end
