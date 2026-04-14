function checkSROpportunity(obj, rxVector)
%checkSROpportunity Check if SR opportunity can be identified
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   checkSROpportunity(OBJ, RXVECTOR) checks if spatial reuse opportunity
%   can be identified. If it is identified, CCA reset is done and transmit
%   power is restricted.
%
%   RXVECTOR is a structure of type wlan.internal.utils.defaultTxVector.

%   Copyright 2025 The MathWorks, Inc.

if rxVector.BSSColor == 0 || obj.BSSColor == 0
    % No SR operation allowed when BSSColor is set to zero.
    return;
end

% Frame is an OBSS and received signal strength is less than OBSS PD
% threshold. RSSI is filled with signal power in dBm.
if rxVector.BSSColor ~= obj.BSSColor && rxVector.RSSI < obj.UpdatedOBSSPDThreshold

    % Store the OBSSPD to be applied for the received OBSS frame.
    fillOBSSPDBuffer(obj);

    % Reset CCA only when both NAV timers have elapsed
    isNAVExpired = checkNAVTimerAndResetContext(obj, obj.LastRunTimeNS);
    if isNAVExpired
        % Send CCARESET.Request to PHY.
        % Refer section 8.3.5.10 and section 26.10.2.2 in IEEE Std
        % 802.11ax-2021.
        resetCCAToCheckSROpportunity(obj);
    end
end
end

function resetCCAToCheckSROpportunity(obj)
%resetCCAToCheckSROpportunity Notify the PHY receiver about the CCARESET
%request to check for SR opportunity
%
%   Reference: Section 26.10.2.2 - General operation with non-SRG OBSS PD
%   level in IEEE std 802.11 2021.

    phyIndication = obj.ResetPHYCCAFcn();
    
    obj.SROpportunityIdentified = false;
    if phyIndication.MessageType == obj.CCAIndication
        updateCCAStateAndAvailableBW(obj, phyIndication, obj.LastRunTimeNS);
        if ~obj.CCAState(1) % Primary 20 is idle
            % The HE STA may resume EDCAF procedures after the PHY-CCARESET.request
            % primitive is sent, provided that the medium condition is not otherwise
            % indicated as BUSY. Reference: Section 26.10.2.6 in IEEE std 802.11 2021.
            obj.SROpportunityIdentified = true;
        end
    end
end

function fillOBSSPDBuffer(obj)
%fillOBSSPDBuffer Fill the OBSS PD buffer vector on the reception of an
%OBSS frame for which SR opportunity is identified.

    % OBSS PD threshold lies between the minimum and maximum OBSS PD
    % thresholds, store them in buffer.
    if (obj.UpdatedOBSSPDThreshold > obj.OBSSPDThresholdMin) && (obj.UpdatedOBSSPDThreshold <= obj.OBSSPDThresholdMax)
    
        % Store all the OBSS PD thresholds during OBSS frames receptions.
        % Different OBSSPD values can be applied for different OBSS frames
        % based on the type of receiving OBSS frame(SRG(Spatial reuse
        % groups), Non-SRG or PSR(Parametrized spatial reuse)) and the
        % usage of OBSS PD algorithms. We support Non-SRG OBSSPD and
        % constant OBSS PD.
        obj.OBSSPDBuffer = [obj.UpdatedOBSSPDThreshold, obj.OBSSPDBuffer];
    
        % Power restriction flag to indicate that power must be restricted
        % when STA gains TXOP. This flag will be reset when the gained TXOP
        % ends.
        obj.RestrictSRTxPower = true;
    end
end
