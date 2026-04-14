function frameToPHY = generateManagementFrame(obj, mpdu, frameTxTime)
%

%   Copyright 2025 The MathWorks, Inc.

tx = obj.Tx;

% Adjust duration field for MF TXOP
mpdu.Header.Duration = adjustDurationForMFTXOP(obj, frameTxTime, mpdu.Header.Duration);

% Fill MPDU metadata
mpdu.Metadata.SubframeIndex = 1;
mpdu.Metadata.SubframeLength = mpdu.Metadata.MPDULength; % Assuming MPDU length is filled at this point

% Create frame structure to be passed to PHY
frameToPHY = obj.MACFrameTemplate;
frameToPHY.MACFrame.MPDU = mpdu;
frameToPHY.MACFrame.Data = [];
frameToPHY.MACFrame.PSDULength = mpdu.Metadata.MPDULength;
frameToPHY.SequenceNumbers = frameToPHY.MACFrame.MPDU.Header.SequenceNumber;

% Store context
% tx.TxMCS(obj.UserIndexSU) = 0;
% tx.TxNumSTS(obj.UserIndexSU) = 1;
% tx.TxFrameLength = frameToPHY.MACFrame.PSDULength;
% tx.TxStationIDs(obj.UserIndexSU) = frameToPHY.MACFrame.MPDU.Metadata.ReceiverID;
% tx.TxBandwidth = 20;
% frameTxTime = calculateTxTime(obj, obj.NonHT, tx.TxFrameLength, tx.TxMCS(obj.UserIndexSU), tx.TxNumSTS(obj.UserIndexSU), tx.TxBandwidth);

if ~tx.NoAck
    tx.ExpectedAckType = obj.ACK;
end

% Update Statistics
if frameToPHY.MACFrame.MPDU.Header.Retransmission
    obj.RetransmittedManagementFrames = obj.RetransmittedManagementFrames + 1;
end

end

function updatedDuration = adjustDurationForMFTXOP(obj, frameTxTime, remFESDuration)
%adjustDurationForMFTXOP Return updated duration for multiple protection

if obj.TXNAVTimer == 0 % Zero TXOP limit
    updatedDuration = remFESDuration;
else
    if frameTxTime + remFESDuration <= obj.TXNAVTimer
        updatedDuration = obj.TXNAVTimer - frameTxTime; % In nanoseconds
    else
        % If data transmission exceeds TXOP limit ( Reference:
        % Section 10.23.2.9 of IEEE Std. 802.11ax-2021, The TXOP
        % holder may exceed the TXOP limit only if it does not
        % transmit more than one Data or Management frame in the
        % TXOP, for the following situation: Initial transmission of
        % an MSDU under a block ack agreement, where the MSDU is not
        % in an A-MPDU consisting of more than one MPDU and the
        % MSDU is not in an A-MSDU."), fill duration accordingly
        updatedDuration = remFESDuration;
    end
end
end
