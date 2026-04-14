function nextFrameType = scheduleTransmission(obj, isInitialFES, excludeIFS)
%scheduleTransmission Schedules and selects a frame for transmission
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   NEXTFRAMETYPE = scheduleTransmission(OBJ) schedules a trigger based
%   transmission in response to a trigger frame. NEXTFRAMETYPE is an
%   enumerated value of the selected frame type returned as one of the
%   following constant values of edcaMAC object: QoSData, QoSNull.
%
%   NEXTFRAMETYPE = scheduleTransmission(OBJ, true) schedules either a
%   beacon transmission or a transmission from the device or a transmission
%   triggered by the device. This is for an initial frame exchange sequence
%   (FES).
%
%   NEXTFRAMETYPE = scheduleTransmission(OBJ, ISINITIALFES, EXCLUDEIFS)
%   schedules a transmission from the device or a transmission triggered by
%   the device. This is for a non-initial FES in a multi-frame TXOP.
%
%   NEXTFRAMETYPE is an enumerated value of the selected frame type
%   returned as one of the following constant values of edcaMAC object:
%   RTS, QoSData, MURTSTrigger, BasicTrigger.
%
%   OBJ is an object of type edcaMAC.
%
%   ISINITIALFES is a logical scalar. If specified as false, MAC checks if
%   a non-initial frame exchange sequence can start within the remaining
%   TXOP duration.
%
%   EXCLUDEIFS is a logical scalar that indicates whether SIFS/PIFS must be
%   excluded while determining if a new FES can be initiated.

%   Copyright 2025 The MathWorks, Inc.

nextFrameType = obj.UnknownFrameType;
if (obj.Rx.LastRxFrameTypeNeedingResponse == obj.BasicTrigger)
    nextFrameType = scheduleTriggerBasedTransmission(obj);

else
    if isInitialFES
        acIndex = obj.OwnerAC + 1;
        if (acIndex == 4) && obj.TBTTAcquired % Beacon has to be transmitted from the device
            nextFrameType = obj.Beacon;

        else
            if isQueueEmpty(obj, acIndex)
                if obj.IsAPDevice && obj.ULOFDMAEnabled
                    % If AP has won contention and the transmission queues are empty, then UL
                    % OFDMA transmission can be triggered.
                    nextFrameType = scheduleTriggerTransmission(obj, isInitialFES);
                    if nextFrameType ~= obj.UnknownFrameType
                        obj.ULOFDMAScheduled = true;
                        obj.PrevDLTransmission = false;
                    end
                end
            else
                % Call DL scheduler at AP in following cases:
                % 1. When UL OFDMA is not enabled, i.e., only DL transmissions are
                % configured
                % 2. When both DL and UL transmissions are enabled and prev transmission is
                % not DL. And DL traffic is available in primary AC.
                scheduleDLTxAtAP = ~obj.ULOFDMAEnabled || ~obj.PrevDLTransmission;
                % Schedule an UL OFDMA transmission if at least one STA has
                % reported non-zero queue size.
                scheduleULTxFromSTAs = any(obj.STAQueueInfo(:, 3));
                if obj.IsAPDevice && ~scheduleDLTxAtAP && scheduleULTxFromSTAs
                    nextFrameType = scheduleTriggerTransmission(obj, isInitialFES);
                    if nextFrameType ~= obj.UnknownFrameType
                        obj.ULOFDMAScheduled = true;
                        obj.PrevDLTransmission = false;
                    end
                else
                    nextFrameType = scheduleNonTriggerTransmission(obj, isInitialFES);
                    if nextFrameType ~= obj.UnknownFrameType
                        obj.ULOFDMAScheduled = false;
                        obj.PrevDLTransmission = true;
                    end
                end
            end
        end

    else % Non-initial frame exchange sequence
        if ~obj.ULOFDMAScheduled % Set each time during contention
            nextFrameType = scheduleNonTriggerTransmission(obj, isInitialFES, excludeIFS);
        else
            nextFrameType = scheduleTriggerTransmission(obj, isInitialFES, excludeIFS);
        end
    end
end
end