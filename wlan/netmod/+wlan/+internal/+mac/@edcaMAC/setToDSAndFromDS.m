function mpdu = setToDSAndFromDS(obj, mpdu, receiverID)
%setToDSAndFromDS Set ToDS and FromDS fields in MPDU header

%   Copyright 2025 The MathWorks, Inc.

if obj.IsAPDevice || obj.IsMeshDevice
    mpdu.Header.FromDS = true;
else % STA
    mpdu.Header.FromDS = false;
end
if receiverID == obj.BroadcastID
    mpdu.Header.ToDS = false;
else
    staIdxLogical = (receiverID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
    receiverOperatingMode = obj.SharedMAC.RemoteSTAInfo(staIdxLogical).Mode;
    if strcmp(receiverOperatingMode, 'STA')
        mpdu.Header.ToDS = false;
    else % AP or mesh
        mpdu.Header.ToDS = true;
    end
end
end
