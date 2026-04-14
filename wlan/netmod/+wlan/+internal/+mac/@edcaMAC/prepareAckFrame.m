function frameToPHY = prepareAckFrame(obj, destinationAddress, rxDuration)
% prepareAckFrame(...) Prepares Ack frame response to the received frame.

%   Copyright 2025 The MathWorks, Inc.

% Calculate Ack response transmission time
ackRespTxTime = calculateTxTime(obj, obj.NonHT, obj.AckOrCtsFrameLength, obj.Rx.ResponseMCS, 1, 20); % numSTS = 1, cbw = 20

% Generate Ack frame
frameToPHY = generateAck(obj, destinationAddress, rxDuration, ackRespTxTime);

% Update context
obj.Rx.ResponseStationID = wlan.internal.utils.macAddress2NodeID(destinationAddress);
obj.Rx.ResponseTxTime = ackRespTxTime;
obj.Rx.ResponseLength = obj.AckOrCtsFrameLength;

% Update statistics
obj.Statistics.TransmittedAckFrames = obj.Statistics.TransmittedAckFrames + 1;
end

function frameToPHY = generateAck(obj, destinationAddress, rxDuration, respTxTime)
% generateAck(...) generates Ack frame

    % Calculate duration field
    duration = max(rxDuration*1e3 - obj.SIFSTime - respTxTime, 0); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
    % Convert to microseconds and round off to nanoseconds granularity
    duration = round(duration*1e-3, 3); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
    
    % Fill MPDU fields
    mpdu = obj.MPDUAckTemplate;
    mpdu.Header.FrameType = 'ACK';
    mpdu.Header.Duration = duration;
    mpdu.Header.Address1 = destinationAddress;
    
    % Fill MPDU metadata
    mpdu.Metadata.MPDULength = obj.AckOrCtsFrameLength;
    mpdu.Metadata.SubframeIndex = 1;
    mpdu.Metadata.SubframeLength = obj.AckOrCtsFrameLength;
    
    % Create frame structure to be passed to PHY
    frameToPHY = obj.MACFrameTemplate;
    frameToPHY.MACFrame.MPDU = mpdu;
    frameToPHY.MACFrame.Data = generateControlFrame(obj, mpdu); % generate frame bits for full MAC frame
    frameToPHY.MACFrame.PSDULength = obj.AckOrCtsFrameLength;
end
