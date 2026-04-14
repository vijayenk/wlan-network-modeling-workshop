function controlFrameBits = generateControlFrame(obj, mpdu)
%generateControlFrame Generate and return MAC control frame bits
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   CONTROLFRAMEBITS = generateControlFrame(OBJ, MPDU) generates control
%   frame bits.
%
%   CONTROLFRAMEBITS is the sequence of frame bits generated. It is empty
%   if the MAC frame abstraction is enabled.
%
%   OBJ is an object of type edcaMAC.
%
%   MPDU is a structure of type wlan.internal.utils.defaultMPDU with the
%   information to generate control frame bits.

%   Copyright 2022-2025 The MathWorks, Inc.

if ~isempty(obj.TransmissionStartedFcn)
    obj.TransmissionStarted = obj.TransmissionStartedTemplate;
end

if obj.FrameAbstraction
    controlFrameBits = [];

else % Full MAC
    cfgMAC = obj.EmptyMACConfig;
    trigUserCfg = obj.EmptyMACTriggerUserConfig;

    % CBW320 channelization for MU-RTS
    cbw320Channelization = 1; % default
    if strcmp(mpdu.Header.FrameType, 'Trigger') && strcmp(mpdu.FrameBody.TriggerType, "MU-RTS") && (mpdu.FrameBody.ChannelBandwidth == 320)
        linkIdx = getLinkIndex(obj);
        channel = obj.SharedMAC.BandAndChannel(linkIdx,2);
        if any(channel == [63 127 191])
            cbw320Channelization = 2;
        end
    end

    % Create config object for frame generation
    cfgMAC = wlan.internal.utils.mpduStruct2Cfg(mpdu, cfgMAC, trigUserCfg, cbw320Channelization);

    % Generate control frame bits
    [controlFrameBytes, controlFrameBits] =  wlan.internal.macGenerateMPDU([],cfgMAC); % controlFrame is column vector
    if ~isempty(obj.TransmissionStartedFcn)
        obj.TransmissionStarted.PDU = {double(controlFrameBytes)};
    end
end

end
