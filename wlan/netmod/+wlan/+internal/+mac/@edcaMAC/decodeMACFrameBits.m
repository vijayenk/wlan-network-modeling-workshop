function [rxMPDU, decodeStatus] = decodeMACFrameBits(obj, frame, format)
%decodeMACFrameBits Decode the given full MAC frame
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   [RXMPDU, DECODESTATUS]= decodeMACFrameBits(OBJ, FRAME, FORMAT) decodes
%   the given full MAC frame.
%
%   RXMPDU is a structure representing MPDU defined in
%   wlan.internal.utils.defaultMPDU.
%
%   DECODESTATUS is an integer in the range [-2,0] which indicates the
%   decoding status of MPDU. 0 indicates success and non-zero values
%   indicate failures.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAME represents the MAC frame received with header and payload
%   information.
%
%   FORMAT specifies the received frame format as a constant value defined
%   in the class wlan.internal.FrameFormats.

%   Copyright 2022-2025 The MathWorks, Inc.

rxMPDU = obj.MPDUTemplate;
if (format == obj.HE_EXT_SU)
    obj.HESUConfig.ExtendedRange = true;
elseif format == obj.HTMixed
    obj.HTConfig.AggregatedMPDU = obj.Rx.RxVector.AggregatedMPDU;
end

% Decode the MPDU
if isempty(frame)
    % For empty MPDU considering it as decode failure and assigning default
    % values
    decodeStatus = wlanMACDecodeStatus.NotEnoughData;
else
    [macConfig, decPayload, decodeStatus] = wlanMPDUDecode(frame, DataFormat='bits', IsMeshFrame=obj.IsMeshDevice, DisableValidation=true, OutputDecimalOctets=true, DecodeEHTVariantTriggerFields=true);
end

% Valid MPDU
if strcmp(decodeStatus, 'Success')
    if numel(decPayload)
        msduBytes = uint8(decPayload{1}); % MSDU aggregation is not supported yet, so extract 1st element in cell array of MSDUs
    else
        msduBytes = [];
    end
    rxMPDU = wlan.internal.utils.cfg2mpduStruct(macConfig, rxMPDU, msduBytes, obj.IsMeshDevice);
    decodeStatus = 0; % Indicates success
elseif strcmp(decodeStatus, 'FCSFailed')
    decodeStatus = -2; % Indicates FCS failure
else
    decodeStatus = -1; % Indicates any other type of failure
end
end
