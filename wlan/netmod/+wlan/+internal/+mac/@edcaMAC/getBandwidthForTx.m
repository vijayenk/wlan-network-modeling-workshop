function bw = getBandwidthForTx(obj, continueTXOP, isTriggerTx)
%getBandwidthForTx Returns the available bandwidth input for DL/UL
%scheduler or bandwidth for transmission (if scheduling has already
%happened)
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2024-2025 The MathWorks, Inc.

tx = obj.Tx;
isScheduled = tx.TxStationIDs(obj.UserIndexSU) ~= 0; % TxStationIDs is assigned only after scheduler has run

if nargin == 2
    isTriggerTx = false;
end

if ~continueTXOP % Initial TXOP
    if isScheduled && (tx.TxStationIDs(obj.UserIndexSU) ~= obj.BroadcastID) % Scheduled a non-broadcast frame
        if isTriggerTx || (tx.TxFormat == obj.HE_MU) % Multi-user
            % MUAllNodesSameBWSupported
            % In case of MU, ChannelBandwidth = AvailableBandwidth = TXOPBandwidth = TxBandwidth
            bw = tx.TXOPBandwidth;

        else % Single User
            % Get the bandwidth supported by receiver
            receiverID = tx.TxStationIDs(obj.UserIndexSU);
            rxBandwidth = getReceiverBW(obj, receiverID);
            bw = min(rxBandwidth, tx.TXOPBandwidth);
        end

    else % Not scheduled or scheduled a broadcast frame
        % 1. For initial TXOP, available BW for scheduling is TXOPBandwidth
        % 2. Send broadcast frame in TXOPBandwidth
        bw = tx.TXOPBandwidth;
    end

else % Non-Initial TXOP
    if (obj.Tx.NextTxFrameType == obj.CFEnd) % CF-End frame
        bw = getBWForNonInitialFES(obj);

    elseif isScheduled && (tx.TxStationIDs(obj.UserIndexSU) ~= obj.BroadcastID) % Scheduled a non-broadcast frame
        if isTriggerTx || (tx.TxFormat == obj.HE_MU) % Multi-user
            % MUAllNodesSameBWSupported
            % In case of MU, ChannelBandwidth = AvailableBandwidth = TXOPBandwidth = TxBandwidth
            bw = tx.TXOPBandwidth;

        else % Single User
            % Get the bandwidth supported by receiver
            receiverID = tx.TxStationIDs(obj.UserIndexSU);
            rxBandwidth = getReceiverBW(obj, receiverID);
            bw = getBWForNonInitialFES(obj, rxBandwidth);
        end

    else % Not scheduled or scheduled a broadcast frame
        bw = getBWForNonInitialFES(obj);
    end
end
end

function rxBandwidth = getReceiverBW(obj, rxNodeID)
% Return the bandwidth to use for transmission to a specific receiver

staIdxLogical = (rxNodeID == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
if ~obj.IsAffiliatedWithMLD % Non-MLD
    rxBandwidth = obj.SharedMAC.RemoteSTAInfo(staIdxLogical).Bandwidth;
else % MLD
    linkIdxLogical = (obj.DeviceID == [obj.SharedMAC.RemoteSTAInfo(staIdxLogical).DeviceID]);
    rxBandwidth = obj.SharedMAC.RemoteSTAInfo(staIdxLogical).Bandwidth(linkIdxLogical);
end
end

function bw = getBWForNonInitialFES(obj, rxBandwidth)
% Return bandwidth available for non-initial PPDU based on Section
% 10.23.2.8 of IEEE Std 802.11ax-2021

tx = obj.Tx;
if nargin == 1
    rxBandwidth = inf; % Not applicable
end

if tx.LastRTSBandwidth
    % If TXOP is protected by an RTS/CTS or MU-RTS/CTS exchange, transmit
    % non-initial PPDU with a BW less than or equal to last RTS/MU-RTS
    % transmitted by TXOP holder. Reference: Section 10.23.2.8 of IEEE Std
    % 802.11ax-2021
    bw = min([tx.LastRTSBandwidth, rxBandwidth, obj.AvailableBandwidth]);
elseif tx.FirstNonHTDupBandwidth
    % If TXOP does not have RTS/MU-RTS, transmit non-initial PPDU with a BW
    % less than or equal to initial frame in the first non-HT duplicate frame
    % exchange. Reference: Section 10.23.2.8 of IEEE Std 802.11ax-2021
    bw = min([tx.FirstNonHTDupBandwidth, rxBandwidth, obj.AvailableBandwidth]);
else
    % If there is no non-HT duplicate frame in a TXOP, transmit non-initial
    % PPDU with a BW less than or equal to the preceeding PPDU
    % Reference: Section 10.23.2.8 of IEEE Std 802.11ax-2021
    bw = min([tx.LastPPDUBandwidth, rxBandwidth, obj.AvailableBandwidth]);
end
end
