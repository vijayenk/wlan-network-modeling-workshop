function isScheduled = scheduleAndCalculateTxInfo(obj, scheduleStations, continueTXOP, excludeIFS)
%scheduleAndCalculateTxInfo Schedules destination stations and calculates
%number of subframes that can be aggregated
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   ISSCHEDULED = scheduleAndCalculateTxInfo(OBJ, SCHEDULESTATIONS, false)
%   schedules destination stations for first frame exchange sequence (FES)
%   or during an internal collision, if SCHEDULESTATIONS is specified as
%   true. To skip station scheduling in this function if destination
%   stations are already scheduled, specify SCHEDULESTATIONS as false. This
%   function also calculates number of MSDUs that can be aggregated for
%   each user.
%
%   ISSCHEDULED = scheduleAndCalculateTxInfo(OBJ, SCHEDULESTATIONS,
%   CONTINUETXOP, EXCLUDEIFS) is used in a multi-frame TXOP, to determine
%   if the next data frame can be scheduled for transmission within the
%   remaining TXOP.
%
%   ISSCHEDULED is a logical scalar that indicates whether a new frame
%   exchange sequence (FES) can be initiated within the remaining TXOP
%   duration.
%
%   OBJ is an object of type edcaMAC.
%
%   CONTINUETXOP is a logical scalar that indicates MAC is trying to
%   determine if a new non-initial frame exchange sequence can be initiated
%   within the remaining TXOP duration.
%
%   EXCLUDEIFS is a logical scalar that indicates whether SIFS/PIFS must be
%   excluded while determining if a new FES can be initiated. If this input
%   is not provided, the function considers a default value of true.

%   Copyright 2022-2025 The MathWorks, Inc.

tx = obj.Tx; % obj.Tx is a handle object
isScheduled = true;

if nargin == 3
    excludeIFS = true;
end

if scheduleStations
    tx.TxStationIDs = 0; % Reset previous scheduled stations
    [txQueueLengths, retryBufferLengths, stationInfo] = getSchedulerInputs(obj, continueTXOP);
end

isNextMultiUserTx = (obj.TransmissionFormat == obj.HE_MU); % Next transmission in an MU transmission
maxDLStations = 1;
if isNextMultiUserTx
    maxDLStations = obj.MaxMUStations;
end

% Run scheduler starting from maximum number stations, until at least one
% packet can be sent for all scheduled STAs.
for staCount = maxDLStations:-1:1
    if scheduleStations
        scheduleInfo = runDLScheduler(obj.Scheduler, obj.OwnerAC + 1, staCount, ...
            txQueueLengths, retryBufferLengths, stationInfo);

        if isNextMultiUserTx
            % No primary AC is scheduled, so end the Multi User TXOP
            terminateTXOP = (~nnz(scheduleInfo.DstStationIDs)) || (~any(scheduleInfo.ACs == (obj.OwnerAC + 1)));
        else
            % Scheduled AC is secondary so end the SU TXOP
            terminateTXOP = (~nnz(scheduleInfo.DstStationIDs)) || (scheduleInfo.ACs(1) ~= (obj.OwnerAC + 1));
        end

        % If no destination or if no primary AC is scheduled 
        if terminateTXOP
            isScheduled = false;
            tx.TxMPDUCount(1:tx.NumTxUsers) = 0;
            return;
        end

        % Scheduled stations and corresponding ACs
        tx.TxStationIDs = scheduleInfo.DstStationIDs;
        tx.TxACs = scheduleInfo.ACs;
        tx.AllocationIndex = scheduleInfo.AllocationIndex;

        % Store Context
        tx.OFDMAScheduleContext.AllocationIndex = scheduleInfo.AllocationIndex;
        tx.OFDMAScheduleContext.UseLowerCenter26ToneRU = scheduleInfo.UseLowerCenter26ToneRU;
        tx.OFDMAScheduleContext.UseUpperCenter26ToneRU = scheduleInfo.UseUpperCenter26ToneRU;
    end

    tx.ProtectNextFrame = isRTSProtectionRequired(obj, continueTXOP, scheduleStations);

    % Calculate max possible number of subframes that can be used to form PSDU
    % (MPDU/A-MPDU)
    if isNextMultiUserTx % Multi-user format
        % Create MU PHY configuration object corresponding to downlink MU data
        % frame and set configuration object properties
        tx.CfgHEMU = wlanHEMUConfig(tx.OFDMAScheduleContext.AllocationIndex, ...
            'LowerCenter26ToneRU', tx.OFDMAScheduleContext.UseLowerCenter26ToneRU, ...
            'UpperCenter26ToneRU', tx.OFDMAScheduleContext.UseUpperCenter26ToneRU);
        tx.CfgHEMU.NumTransmitAntennas = obj.NumTransmitAntennas;

        % Create TB system config object corresponding to UL HE TB response frames
        obj.ULTBSysCfg = wlan.internal.mac.HETBSystemConfig(tx.OFDMAScheduleContext.AllocationIndex, ...
            'LowerCenter26ToneRU', tx.OFDMAScheduleContext.UseLowerCenter26ToneRU, ...
            'UpperCenter26ToneRU',tx.OFDMAScheduleContext.UseUpperCenter26ToneRU);

        isGroupcast = false;
        % Set data transmission vector context
        tx.TxFormat = obj.HE_MU;
        tx.TxAggregatedMPDU = true;
        tx.TxBandwidth = getBandwidthForTx(obj, continueTXOP);
        % Set transmission context
        tx.NumTxUsers = numel(tx.CfgHEMU.User);
        tx.NumAddressFields(1:tx.NumTxUsers) = numAddressFieldsInHeader(obj, isGroupcast);

        % Set data rate for each user
        for userIdx = 1:tx.NumTxUsers
            [tx.TxMCS(userIdx), tx.TxNumSTS(userIdx)] = getDataFrameRateParameters(obj, userIdx, isGroupcast);           

            tx.CfgHEMU.User{userIdx}.MCS = tx.TxMCS(userIdx);
            tx.CfgHEMU.User{userIdx}.NumSpaceTimeStreams = tx.TxNumSTS(userIdx);

            % Set the channel coding type
            obj.ULTBSysCfg.User{userIdx}.ChannelCoding = 'LDPC';
            if obj.DLOFDMAFrameSequence == 1 % Trigger method is TRS
                if obj.ULTBSysCfg.RU{userIdx}.Size < 484
                    obj.ULTBSysCfg.User{userIdx}.ChannelCoding = 'BCC';
                end
            end
        end

        tx.TxMPDUCount = zeros(obj.MaxMUUsers, 1);
        tx.TxPSDULength = 0;
        % Get number of MSDUs that can be aggregated per each user
        [tx.TxMPDUCount, apepLengths] = calculateMPDUCountForMUTx(obj, tx.TxACs, ...
            obj.OwnerAC+1, obj.MaxSubframes, tx.CfgHEMU, excludeIFS);

        if all(tx.TxMPDUCount(1:tx.NumTxUsers) ~= 0)
            tx.TxPSDULength = calculatePSDULength(obj, tx.TxFormat, apepLengths);
            % Increment station serve counts for Round Robin scheduler
            incrementSchedulerNumServes(obj);
            break;
        end

        if staCount == 1 % Unable to send at least one MPDU to a single user
            if obj.TXNAVTimer > 0
                if continueTXOP % Cannot schedule another FES within the remaining TXOP
                    isScheduled = false;
                else % Cannot schedule first FES in the TXOP
                    [tx.TxMPDUCount(1), apepLength] = calculateAPEPLengthForOneMSDU(obj);
                    tx.TxPSDULength = calculatePSDULength(obj, tx.TxFormat, apepLength);
                    isScheduled = true;
                    % Increment station serve counts for Round Robin scheduler
                    incrementSchedulerNumServes(obj);
                end
            else
                idx = find(~(tx.TxMPDUCount(1:tx.NumTxUsers)), 1);
                error(message('wlan:wlanNode:TransmissionTimeExceeded', txMSDULengths(qIndices(1), tx.TxACs(1), 1), tx.TxMCS(idx), tx.TxNumSTS(idx)));
            end
        end

    else % Single user format
        tx.NumTxUsers = 1;

        stationID = tx.TxStationIDs(obj.UserIndexSU);
        acIdx = tx.TxACs(obj.UserIndexSU);
        queueObj = getQueueObj(obj, stationID, acIdx);
        frame = peek(queueObj, stationID, acIdx, 1, 1); % numMPDU=1, numNodes=1
        isManagementFrame = wlan.internal.utils.isManagementFrame(frame.MPDUs(1));
        isGroupcast = (tx.TxStationIDs(obj.UserIndexSU) == obj.BroadcastID);

        tx.NumAddressFields(obj.UserIndexSU) = numAddressFieldsInHeader(obj, isGroupcast);

        % Set data transmission vector context
        if isGroupcast || isManagementFrame
            % Transmit broadcast frames with maximum basic rate in Non-HT format
            % (therefore 1 space-time stream)
            tx.TxFormat = obj.NonHT;
            tx.TxAggregatedMPDU = false;
        else
            tx.TxFormat = obj.TransmissionFormat;
            tx.TxAggregatedMPDU = obj.MPDUAggregation;
        end

        if isManagementFrame
            tx.TxBandwidth = 20;
            [tx.TxMCS(obj.UserIndexSU), tx.TxNumSTS(obj.UserIndexSU)] = getManagementFrameRateParameters(obj, isGroupcast);
            tx.TxMPDUCount(obj.UserIndexSU) = 1;
            tx.TxPSDULength = frame.MPDUs(1).Metadata.MPDULength;            
        else % Data frame
            tx.TxBandwidth = getBandwidthForTx(obj, continueTXOP);
            [tx.TxMCS(obj.UserIndexSU), tx.TxNumSTS(obj.UserIndexSU)] = getDataFrameRateParameters(obj, obj.UserIndexSU, isGroupcast);
            % Get number of MSDUs that can be aggregated
            [tx.TxMPDUCount(obj.UserIndexSU), apepLength, frameWithinTxWindow] = calculateMPDUCountForSUTx(obj, isGroupcast, excludeIFS);
            if (tx.TxMPDUCount(obj.UserIndexSU)==0) && ~frameWithinTxWindow
                % Return if no data frame is scheduled for transmission because next data
                % frame sequence number is out of transmission window.
                isScheduled = false;
                return;
            end
            tx.TxPSDULength = calculatePSDULength(obj, tx.TxFormat, apepLength);
        end

        if tx.TxPSDULength == 0 % FES cannot be scheduled
            if continueTXOP || ~tx.TxAggregatedMPDU
                isScheduled = false;
            else
               [tx.TxMPDUCount(1), apepLength] = calculateAPEPLengthForOneMSDU(obj);
               tx.TxPSDULength = calculatePSDULength(obj, tx.TxFormat, apepLength);
               isScheduled = true;
               % Increment station serve counts for Round Robin scheduler
               incrementSchedulerNumServes(obj);
            end
        else % FES can be scheduled
            % Increment station serve counts for Round Robin scheduler
            incrementSchedulerNumServes(obj);
        end
    end
end
end

% Return MCS and NumSTS to use for data frame transmission
function [mcs, numSTS] = getDataFrameRateParameters(obj, userIdx, isGroupcast)

tx = obj.Tx;
if isGroupcast
    % Transmit broadcast frames with maximum basic rate in Non-HT format
    % (therefore 1 space-time stream)
    mcs = max(obj.NonHTMCSIndicesForBasicRates);
    numSTS = 1;
else
    % Get the data rate from the rate control algorithm
    rateControlInfo = obj.RateControlTxContextTemplate;
    rateControlInfo.FrameType = 'QoS Data';
    rateControlInfo.ReceiverNodeID = tx.TxStationIDs(userIdx);
    rateControlInfo.TransmissionFormat = wlan.internal.utils.getFrameFormatString(tx.TxFormat,'MAC');
    rateControlInfo.ChannelBandwidth = tx.TxBandwidth*1e6;
    rateControlInfo.CurrentTime = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);

    % Get queue object and retry buffer index
    queueObj = getQueueObj(obj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
    [~, retryBufferIdx] = getAvailableRetryBuffer(queueObj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));

    if retryBufferIdx == 0 % No packets available for transmission in retry buffer
        rateControlInfo.IsRetry = false;
    else
        rateControlInfo.IsRetry = true;
    end

    obj.DataFrameRateControlTxContext = rateControlInfo;
    [rateInfo] = rateParameters(obj.RateControl, rateControlInfo);
    rateInfo = checkAndSetHTMIMOMCS(obj, rateInfo);
    mcs = rateInfo.MCS;
    numSTS = rateInfo.NumSpaceTimeStreams;
end
end

% Return MCS and NumSTS to use for data frame transmission
function [mcs, numSTS] = getManagementFrameRateParameters(obj, isGroupcast)

if isGroupcast
    % Transmit broadcast frames with maximum basic rate in Non-HT format
    % (therefore 1 space-time stream)
    mcs = max(obj.NonHTMCSIndicesForBasicRates);
    numSTS = 1;
else
    mcs = 0;
    numSTS = 1;
end
end

% Increment serve counts for scheduler round robin
function incrementSchedulerNumServes(obj)

% Increment station serve counts for Round Robin scheduler
if isa(obj.Scheduler, "wlan.internal.mac.SchedulerRoundRobin")
    incrementNumServes(obj.Scheduler, obj.Tx.TxStationIDs, true);
end
end

% Calculate the number of subframes required to form MU-PSDU
function [mpduCount, apepLength] = calculateMPDUCountForMUTx(obj, acs, ...
    primaryAC, maxAggCount, heMUCfg, excludeIFS)

tx = obj.Tx;
% Number of users in MU PPDU
numUsers = numel(heMUCfg.User);
% Number of MSDUs dequeued for each user
mpduCount = zeros(numUsers, 1);

% Symbol duration including guard interval (microseconds)
switch heMUCfg.GuardInterval
    case 0.8
        symbolTime = 13.6;
    case 1.6
        symbolTime = 14.4;
    otherwise % 3.2
        symbolTime = 16;
end

% Maximum allowed PPDU duration (microseconds)
maxPPDUDuration = round(calculateMaxDataTxTime(obj, true, excludeIFS)*1e-3,3);
numES = 1; % Number of encoding streams
serviceBits = 16;  % IEEE Std 802.11-2016 Sections 17.3.5.2, 19.3.11.2, and Table 21.5. IEEE Std 802.11ax-2021, Table 27-12.
tailBits = 6;

f = wlanFieldIndices(heMUCfg);
dataFieldIndices = f.HEData;
phyOverheadDuration = (dataFieldIndices(1) - 1)/wlan.internal.cbwStr2Num(heMUCfg.ChannelBandwidth);

% PPDU duration
txOpDuration = maxPPDUDuration - phyOverheadDuration;

% Maximum transmission time of the frames corresponding to primary AC
primaryACTxtimeMax = 0;

% Maximum transmission times of the frames corresponding to all secondary
% ACs from highest to lowest priority
secondaryACTxtimeMax = [0 0 0];
acList = [4 3 1 2];
secondaryACs = acList(acList ~= primaryAC);

apepLength = zeros(numUsers, 1);

% Get MSDUs count for each user
for userIdx = 1:numUsers
    [queueLengths, msduLengths] = getQueueAndMSDULengthsForUser(obj, userIdx, false); %isGroupcast=false

    % In case of OFDMA, frames from all users should be aligned to the
    % tx time of primary AC.
    if (acs(userIdx) == primaryAC)
        % Maximum number of symbols can be transmitted in the TXOP
        numSymbols = floor(txOpDuration/symbolTime);
        ndbps = calculateNDBPS(heMUCfg, userIdx);

        if strcmp(heMUCfg.User{userIdx}.ChannelCoding, 'LDPC')
            tailBits = 0;
        end

        % Maximum possible PSDU length for the user
        maxPSDULength = floor(((numSymbols-1)*ndbps - serviceBits - tailBits*numES)/8);

        [mpduCount(userIdx), apepLength(userIdx)] = numMPDUsToAggregate(obj, userIdx, maxAggCount, queueLengths, msduLengths, ...
            tx.TxFormat, tx.NumAddressFields(userIdx), tx.TxAggregatedMPDU, maxPSDULength);

        primaryACTxtime = ceil(apepLength(userIdx)*8/ndbps) * symbolTime;
        % Update 'primaryACTxtimeMax' if required
        primaryACTxtimeMax = max(primaryACTxtimeMax, primaryACTxtime);
    else
        acIdx = find(acs(userIdx) == secondaryACs);
        txOpDuration = updateTxOpDuration(primaryACTxtimeMax, secondaryACTxtimeMax, acIdx);

        % Maximum number of symbols can be transmitted in the TXOP
        numSymbols = floor(txOpDuration/symbolTime);
        ndbps = calculateNDBPS(heMUCfg, userIdx);

        % Maximum possible PSDU length for the user
        maxPSDULength = floor((numSymbols*ndbps)/8);
        
        [mpduCount(userIdx), apepLength(userIdx)] = numMPDUsToAggregate(obj, userIdx, maxAggCount, queueLengths, msduLengths, ...
            tx.TxFormat, tx.NumAddressFields(userIdx), tx.TxAggregatedMPDU, maxPSDULength);

        secondaryACTxtime = ceil(apepLength(userIdx)*8/ndbps) * symbolTime;
        % Update 'secondaryACTxtimeMax' if required
        secondaryACTxtimeMax(acIdx) = max(secondaryACTxtimeMax(acIdx), secondaryACTxtime);
    end
end
end

% Update and return TXOP duration for secondary ACs
function txOpDuration = updateTxOpDuration(primaryACTxtimeMax, secondaryACTxtimeMax, priority)

if any(secondaryACTxtimeMax)
    % Consider txopDuration as minimum of primaryACTxtimeMax and any higher
    % priority AC maximum tx time in case of secondary ACs
    txOpDuration = min([primaryACTxtimeMax, nonzeros(secondaryACTxtimeMax(1:priority-1))']);
else
    txOpDuration = primaryACTxtimeMax;
end
end

% Calculate NDBPS
function ndbps = calculateNDBPS(heMUCfg, userIdx)

% Get NDBPS of the user
if heMUCfg.STBC
    nss = 1;
else
    nss = heMUCfg.User{userIdx}.NumSpaceTimeStreams;
end
rdp = wlan.internal.heRateDependentParameters(heMUCfg.RU{heMUCfg.User{userIdx}.RUNumber}.Size, ...
    heMUCfg.User{userIdx}.MCS,nss,heMUCfg.User{userIdx}.DCM);
ndbps = rdp.NDBPS;
end

% Calculate the number of subframes required to form SU-PSDU
function [mpduCount, apepLength, frameWithinTxWindow] = calculateMPDUCountForSUTx(obj, isGroupcast, excludeIFS)

tx = obj.Tx;
[queueLength, msduLengths] = getQueueAndMSDULengthsForUser(obj, obj.UserIndexSU, isGroupcast);

% Get Max PSDU length that can be transmitted with remaining TXOP
maxPSDULength = calculateMaxPSDULength(obj, tx.TxFormat, excludeIFS);

[mpduCount, apepLength, frameWithinTxWindow] = numMPDUsToAggregate(obj, obj.UserIndexSU, obj.MaxSubframes, ...
    queueLength, msduLengths, tx.TxFormat, tx.NumAddressFields(obj.UserIndexSU), tx.TxAggregatedMPDU, maxPSDULength);
end

% Return queue length and MSDU lengths for the specified user
function [queueLength, msduLengths] = getQueueAndMSDULengthsForUser(obj, userIdx, isGroupcast)

tx = obj.Tx;
% Get queue object, index to access queue and retry buffer index
queueObj = getQueueObj(obj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
[~, retryBufferIdx] = getAvailableRetryBuffer(queueObj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));

if isGroupcast
    % Get the lengths of MSDUs present in MAC queues
    msduLengths = getMSDULengthsinTxQueues(obj.LinkEDCAQueues, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
else
    if retryBufferIdx == 0 % No packets available for this station in retry buffers
        % Get the lengths of MSDUs present in MAC transmission queues
        msduLengths = getMSDULengthsinTxQueues(queueObj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx));
    else
        % Get the lengths of MSDUs present in MAC retry buffer
        msduLengths = getMSDULengthsInRetryBuffer(queueObj, tx.TxStationIDs(userIdx), tx.TxACs(userIdx), retryBufferIdx);
    end
end

queueLength = numTxFramesAvailable(obj, tx.TxACs(userIdx), tx.TxStationIDs(userIdx), queueObj, retryBufferIdx);
end

% Calculate number of MPDUs for aggregation and APEP length
function [mpduCount, totalAPEPLength, frameWithinTxWindow] = numMPDUsToAggregate(obj, userIdx, maxMPDUs, queueLength, ...
    msduLengths, txFormat, numAddressesInHeader, mpduAggregation, maxPSDULen)

tx = obj.Tx;
mpduCount = 0;
totalAPEPLength = 0;

frameLen = 0;
mpduHeaderLen = obj.MPDUOverhead; % Basic MPDU header (26) + FCS (4)
ampduDelimiterLen = 4; % A-MPDU subframe delimiter
ignorePSDULen = true;
if nargin == 9
    ignorePSDULen = false;
end

% Additional conditional bytes in MPDU header
if (txFormat == obj.HE_MU) && (obj.DLOFDMAFrameSequence == 1)
    % Additional 4 bytes for HT Control TRS variant
    mpduHeaderLen = mpduHeaderLen + 4;
end
if (numAddressesInHeader == 4)
    % Add 6 octets for Address-4 field in MAC header Reference:
    % Section-9.2.3 in IEEE Std 802.11-2016
    mpduHeaderLen = mpduHeaderLen + 6;
end
if obj.IsAssociatedSTA && obj.ULOFDMAEnabledAtAP
    % Include BSR control info from the stations if UL OFDMA is enabled at AP
    mpduHeaderLen = mpduHeaderLen + 4;
end

maxMeshControlSize = 0;
stationID = tx.TxStationIDs(userIdx);
acIdx = tx.TxACs(userIdx);
queueObj = getQueueObj(obj, stationID, acIdx);
isGroupcast = (stationID == obj.BroadcastID);
% Add 6 octets for mesh control field in mesh data frames Reference:
% Section-9.2.4.7.3 in IEEE Std 802.11-2016
if obj.IsMeshDevice
    frame = peek(queueObj, stationID, acIdx, 1, 1); % numMPDU=1, numNodes=1
    if (numAddressesInHeader == 4) || (stationID == obj.BroadcastID)
        maxMeshControlSize = 6;
    end
    % Add variable address extension size of mesh control field.
    if ~strcmp(wlan.internal.utils.getMeshDestinationAddress(frame.MPDUs), frame.MPDUs.Metadata.DestinationAddress)
        maxMeshControlSize = maxMeshControlSize + 12; % 12 octets for Address5 and Address6
    end
end

for msduIdx = 1:queueLength
    % MSDU length
    msduLen = msduLengths(msduIdx);

    % Calculate APEP length
    frameLen = frameLen + (mpduHeaderLen + maxMeshControlSize + msduLen);

    % Aggregated MPDU
    if mpduAggregation
        % Delimiter overhead for aggregated frames
        frameLen = frameLen + ampduDelimiterLen;

        % Subframe padding overhead for aggregated frames
        subFramePadding = abs(mod(msduLen+maxMeshControlSize+mpduHeaderLen+ampduDelimiterLen, -4));
        frameLen = frameLen + subFramePadding;
    end

    % Get sequence number by peeking the frame
    frame = peek(queueObj, stationID, acIdx, msduIdx, 1); % numMPDU=1, numNodes=1
    frameSeqNum = frame.MPDUs(end).Header.SequenceNumber;
    frameWithinTxWindow = true;
    % For unicast frames, check whether peeked frame is within transmission
    % window
    if ~isGroupcast
        frameWithinTxWindow = isFrameWithinBATxWindow(obj.SharedMAC, stationID, acIdx, frameSeqNum);
    end

    if (mpduCount < maxMPDUs) && (ignorePSDULen || (frameLen <= maxPSDULen)) && frameWithinTxWindow
        mpduCount = mpduCount + 1;
        totalAPEPLength = totalAPEPLength + mpduHeaderLen + maxMeshControlSize + msduLen;
        if mpduAggregation
            totalAPEPLength = totalAPEPLength + ampduDelimiterLen + subFramePadding;
        end
    else  % Max PSDU length or max subframe limit is reached
        break;
    end

    % Only one MSDU is sufficient if no MPDU aggregation
    if ~mpduAggregation
        break;
    end
end
end

% Return the inputs to run scheduler
function [txQueueLengths, retryBufferLengths, stationInfo] = getSchedulerInputs(obj, continueTXOP)

% Get the destination node IDs for which queues are maintained in shared
% MAC and link specific MAC
sharedQDstStationIDs = getDestinationIDs(obj.SharedEDCAQueues);
linkQDstStationIDs = getDestinationIDs(obj.LinkEDCAQueues);

% Get retry buffer lengths of both shared queues (available for this
% specific link for transmission) and link queues
[sharedRetryBufferLengths, ~] = getAvailableRetryBuffer(obj.SharedEDCAQueues);
[linkRetryBufferLengths, ~] = getAvailableRetryBuffer(obj.LinkEDCAQueues);

% Number of unique destinations in shared and link queues
numUniqueDst = numel(unique([sharedQDstStationIDs linkQDstStationIDs]));
txQueueLengths = zeros(numUniqueDst, 4);
retryBufferLengths = zeros(numUniqueDst, 4);
dstStationIDs = zeros(1, numUniqueDst);
tempIdx = 1;

for idx = 1:numel(sharedQDstStationIDs)
    dstStationIDs(tempIdx) = sharedQDstStationIDs(idx);
    % Packets are present for the destination in both shared and link queues
    if any(sharedQDstStationIDs(idx) == linkQDstStationIDs)
        linkQIdxLogical = (sharedQDstStationIDs(idx) == linkQDstStationIDs);
        % Get the total number of packets for the destination in both shared and
        % link queues
        txQueueLengths(tempIdx, :) = obj.SharedEDCAQueues.TxQueueLengths(idx, :) + ...
            [0 0 0 obj.SharedEDCAQueues.TxManagementQueueLengths(idx)] + ...
            obj.LinkEDCAQueues.TxQueueLengths(linkQIdxLogical, :);
        retryBufferLengths(tempIdx, :) = sharedRetryBufferLengths(idx, :) + ...
            linkRetryBufferLengths(linkQIdxLogical, :);
    else
        % Packets are present for the destination only in shared queues
        txQueueLengths(tempIdx, :) = obj.SharedEDCAQueues.TxQueueLengths(idx, :) + [0 0 0 obj.SharedEDCAQueues.TxManagementQueueLengths(idx)];
        retryBufferLengths(tempIdx, :) = sharedRetryBufferLengths(idx, :);
    end
    tempIdx = tempIdx + 1;
end

for idx = 1:numel(linkQDstStationIDs)
    dstStationIDs(tempIdx) = linkQDstStationIDs(idx);
    if ~any(linkQDstStationIDs(idx) == sharedQDstStationIDs)
        % Packets are present for the destination only in link queues
        txQueueLengths(tempIdx, :) = obj.LinkEDCAQueues.TxQueueLengths(idx, :) + [0 0 0 obj.LinkEDCAQueues.TxManagementQueueLengths(idx)];
        retryBufferLengths(tempIdx, :) = linkRetryBufferLengths(idx, :);
    end
    tempIdx = tempIdx + 1;
end

% Scheduler requires tx queue lengths which includes retry buffer lengths
txQueueLengths = txQueueLengths + retryBufferLengths;

% Fill information required to run scheduler
stationInfo = obj.Scheduler.StationInfo;
stationInfo.ChannelBandwidth = getBandwidthForTx(obj, continueTXOP);
stationInfo.TransmissionFormat = obj.TransmissionFormat;
stationInfo.IDs = dstStationIDs;
end

% Return APEP length for one MSDU within an AMPDU
function [mpduCount, apepLength] = calculateAPEPLengthForOneMSDU(obj)

tx = obj.Tx;
[queueLength, msduLengths] = getQueueAndMSDULengthsForUser(obj, 1, false); % userIdx=1, isGroupcast=false
% Fit at least 1 MSDU in the TXOP even if it exceeds the TXOP limit.
% Reference: Section 10.23.2.9 of IEEE Std. 802.11ax-2021, "The TXOP
% holder may exceed the TXOP limit only if it does not transmit more
% than one Data or Management frame in the TXOP, for the following
% situation: Initial transmission of an MSDU under a block ack agreement,
% where the MSDU is not in an A-MPDU consisting of more than one MPDU
% and the MSDU is not in an A-MSDU."

% At this point, only the primary AC and corresponding STA is selected by
% scheduler. So TxStationIDs, TxACs, NumTxUsers are already updated. Some
% additional context such as MPDU count and PSDU length need to be updated.
[mpduCount, apepLength] = numMPDUsToAggregate(obj, 1, 1, queueLength, msduLengths, ...
    tx.TxFormat, tx.NumAddressFields(1), tx.TxAggregatedMPDU); % userIdx=1, maxMSDUs=1
end