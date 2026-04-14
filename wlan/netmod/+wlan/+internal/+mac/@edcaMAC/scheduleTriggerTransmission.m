function nextFrameType = scheduleTriggerTransmission(obj, isInitialFES, excludeIFS)
%scheduleTriggerTransmission Schedules stations for uplink OFDMA and
%determines the next frame to be transmitted (MU-RTS/Basic trigger frame)
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTFRAMETYPE = scheduleTriggerTransmission(OBJ, false) schedules
%   destination stations for first frame exchange sequence (FES) and
%   returns the type of frame to be transmitted next.
%
%   NEXTFRAMETYPE = scheduleTriggerTransmission(OBJ, ISINITIALFES,
%   EXCLUDEIFS) is used for a non-initial FES in a multi-frame TXOP to
%   schedule stations if required.
%
%   NEXTFRAMETYPE is an enumerated value returned as one of the following
%   constant values of edcaMAC object: MURTSTrigger, BasicTrigger.
%
%   OBJ is an object of type edcaMAC.
%
%   ISINITIALFES is a logical scalar. If specified as false, MAC checks if
%   a non-initial frame exchange sequence can start within the remaining
%   TXOP duration.
%
%   EXCLUDEIFS is a logical scalar that indicates whether SIFS/PIFS must be
%   excluded while determining if a new FES can be initiated. If this input
%   is not provided, the function considers a default value of true.

%   Copyright 2025 The MathWorks, Inc.

nextFrameType = obj.UnknownFrameType;
if nargin == 2
    excludeIFS = true;
end

scheduleStations = isSTASchedulingRequired(obj, isInitialFES);
% Schedule stations for UL MU transmission
isScheduled = scheduleAndCalculateULInfo(obj, scheduleStations, ~isInitialFES, excludeIFS);
if ~isScheduled
    return;
end

if obj.Tx.ProtectNextFrame
    nextFrameType = obj.MURTSTrigger;
else
    nextFrameType = obj.BasicTrigger;
end
end

function scheduleSTAs = isSTASchedulingRequired(obj, isInitialFES)
% Decide whether it is necessary to schedule stations for upcoming
% transmission. In a TXOP, schedule only for the first FES, or if there are
% no more frames from previously scheduled station.

scheduleSTAs = false;
if isInitialFES
    scheduleSTAs = true;
else
    numScheduledStations = numel(obj.Tx.TxStationIDs);
    for userIdx = 1:numScheduledStations
        % Get the maximum buffer size among all ACs of the scheduled UL STA
        queueSize = getMaxBufferSize(obj, obj.Tx.TxStationIDs(userIdx));
        if queueSize == 0 % If no more frames from a previously scheduled station
            scheduleSTAs = true;
            break;
        end
    end
end
end