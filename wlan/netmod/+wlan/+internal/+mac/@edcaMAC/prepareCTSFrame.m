function frameToPHY = prepareCTSFrame(obj, destinationAddress, rxDuration)
% prepareCTSFrame(...) Prepares CTS frame response to the received RTS frame.

%   Copyright 2025 The MathWorks, Inc.

% Calculate CTS response transmission time
ctsRespTxTime = calculateTxTime(obj, obj.NonHT, obj.AckOrCtsFrameLength, obj.Rx.ResponseMCS, 1, 20); % numSTS = 1, cbw = 20

% Generate CTS frame
frameToPHY = generateCTS(obj, destinationAddress, rxDuration, ctsRespTxTime);

% Update context
obj.Rx.ResponseStationID = wlan.internal.utils.macAddress2NodeID(destinationAddress);
obj.Rx.ResponseTxTime = ctsRespTxTime;
obj.Rx.ResponseLength = obj.AckOrCtsFrameLength;
end

function frameToPHY = generateCTS(obj, destinationAddress, rxDuration, respTxTime)
% generateCTS(...) generates CTS frame

    % Calculate duration field
    duration = max(rxDuration*1e3 - obj.SIFSTime - respTxTime, 0); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
    % Convert to microseconds and round off to nanoseconds granularity
    duration = round(duration*1e-3, 3); % Reference: Section 9.2.5.1 of IEEE Std 802.11-2020
    
    % Fill MPDU fields
    mpdu = obj.MPDUCTSTemplate;
    mpdu.Header.FrameType = 'CTS';
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
