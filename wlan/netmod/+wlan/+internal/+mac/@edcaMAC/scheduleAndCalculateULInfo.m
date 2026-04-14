function isScheduled = scheduleAndCalculateULInfo(obj, scheduleStations, continueTXOP, excludeIFS)
%scheduleAndCalculateULInfo Schedules stations for uplink transmission
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   ISSCHEDULED = scheduleAndCalculateULInfo(OBJ, SCHEDULESTATIONS, false)
%   schedules stations for uplink transmission in first frame exchange
%   sequence (FES), if SCHEDULESTATIONS is specified as true. To skip
%   station scheduling in this function if destination stations are already
%   scheduled, specify SCHEDULESTATIONS as false. the function also
%   computes the information like MCS, number of spatial streams and L-SIG
%   length required for uplink transmission. If scheduling an uplink
%   transmission fails, this method returns ISSCHEDULED as false.
%
%   ISSCHEDULED = scheduleAndCalculateULInfo(OBJ, SCHEDULESTATIONS,
%   CONTINUETXOP, EXCLUDEIFS) is used in a multi-frame TXOP, to determine
%   if a new uplink sequence can be scheduled within the remaining TXOP.
%
%   ISSCHEDULED is a logical scalar that a new frame exchange sequence can
%   be initiated within the remaining TXOP duration.
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

%   Copyright 2023-2025 The MathWorks, Inc.

tx = obj.Tx; % obj.Tx is a handle object
isScheduled = true;

if nargin == 3
    excludeIFS = true;
end

if scheduleStations
    tx.TxStationIDs = 0; % Reset previous scheduled stations
end

if scheduleStations
    % Fill information required to run scheduler
    stationInfo = obj.Scheduler.StationInfo;
    stationInfo.ChannelBandwidth = getBandwidthForTx(obj, continueTXOP, true); % isTriggerTx=true
    staModeIndices = arrayfun(@(x) strcmp(x.Mode,'STA'), obj.SharedMAC.RemoteSTAInfo);
    stationInfo.IDs = [obj.SharedMAC.RemoteSTAInfo(staModeIndices).NodeID]';

    % Selection of UL stations and allocation index
    ulScheduleInfo = runULScheduler(obj.Scheduler, obj.MaxMUStations, obj.STAQueueInfo, ...
        stationInfo);

    % Scheduled stations and corresponding ACs
    tx.TxStationIDs = ulScheduleInfo.StationIDs;
    numScheduledStations = numel(ulScheduleInfo.StationIDs);
    tx.TxACs = (obj.OwnerAC+1)*ones(numScheduledStations, 1);
    tx.AllocationIndex = ulScheduleInfo.AllocationIndex;

    % Store Context
    tx.OFDMAScheduleContext.AllocationIndex = ulScheduleInfo.AllocationIndex;
    tx.OFDMAScheduleContext.UseLowerCenter26ToneRU = ulScheduleInfo.UseLowerCenter26ToneRU;
    tx.OFDMAScheduleContext.UseUpperCenter26ToneRU = ulScheduleInfo.UseUpperCenter26ToneRU;
end

tx.ProtectNextFrame = isRTSProtectionRequired(obj, continueTXOP, scheduleStations);

numScheduledStations = numel(tx.TxStationIDs);
if numScheduledStations == 0
    % If all the stations reported zero queue sizes, do not schedule an UL
    % OFDMA transmission.
    isScheduled = false;
    return;
end

tx.NumTxUsers = numScheduledStations;
tx.TxBandwidth = getBandwidthForTx(obj, continueTXOP, true); % isTriggerTx=true
obj.ULMCS = zeros(numScheduledStations, 1); % UL HE-MCS assigned by AP
obj.ULNumSTS = zeros(numScheduledStations, 1); % UL NSS assigned by AP

% Create TB system config object required for UL OFDMA
obj.ULTBSysCfg = wlan.internal.mac.HETBSystemConfig(tx.OFDMAScheduleContext.AllocationIndex, ...
    'LowerCenter26ToneRU', tx.OFDMAScheduleContext.UseLowerCenter26ToneRU, ...
    'UpperCenter26ToneRU', tx.OFDMAScheduleContext.UseUpperCenter26ToneRU);

maxQueueSize = 0;

% Determine rate
for userIdx = 1:numScheduledStations
    [obj.ULMCS(userIdx), obj.ULNumSTS(userIdx)] = getTBFrameRateParameters(obj, userIdx);

    % Get the maximum buffer size among all ACs of the scheduled UL STA
    queueSize = getMaxBufferSize(obj, tx.TxStationIDs(userIdx));
    if isempty(queueSize)
        % If buffer status is unknown, consider a default buffer size
        % of 500 bytes
        queueSize = 500;
    end
    maxQueueSize = max(queueSize, maxQueueSize);

    % Set the channel coding type
    obj.ULTBSysCfg.User{userIdx}.ChannelCoding = 'LDPC';
end

% Compute value of Num HE-LTF symbols to be filled in Basic Trigger frame.
% Reference: Section 27.3.11.10 of IEEE Std 802.11ax-2021
maxNumSTS = max(obj.ULNumSTS);
tx.NumHELTFSymbols = wlan.internal.numVHTLTFSymbols(maxNumSTS);

% Initialize with values specified in standard (Section 27.3.11.5 of IEEE
% Std 802.11ax-2021)
signalExtension = 0;
m = 2;

% Fill the required common and user specific parameters in system config
% object
cfgSys = obj.ULTBSysCfg;
cfgSys.TriggerMethod = 'TriggerFrame';
for userIdx = 1:numScheduledStations
    cfgSys.User{userIdx}.NumTransmitAntennas = obj.ULNumSTS(userIdx);
    cfgSys.User{userIdx}.NumSpaceTimeStreams = obj.ULNumSTS(userIdx);
    cfgSys.User{userIdx}.AID12 = getAID(obj.SharedMAC, tx.TxStationIDs(userIdx));
    cfgSys.User{userIdx}.MCS = obj.ULMCS(userIdx);
end

% Maximum allowed PPDU duration (in nanoseconds). Note that for UL OFDMA
% transmissions, AP always accounts for acknowledgement (ACK) duration in
% TXOP. This is done since delayed ACK is not supported.
maxPPDUDuration = calculateMaxDataTxTime(obj, false, excludeIFS);

% Configure APEP length to the maximum queue size
for userIdx = 1:numScheduledStations
    cfgSys.User{userIdx}.APEPLength = maxQueueSize;
end

% Get tx time of HE-TB PPDU
[~,txTime] = wlan.internal.hePLMETxTimePrimative(cfgSys);
if txTime <= maxPPDUDuration % HE TB PPDU duration does not exceed max PPDU duration
    txTime = round(txTime*1e-3, 3);
    % Compute value of UL length field to be filled in Basic Trigger frame
    % Reference: Section 27.3.11.5 of IEEE Std 802.11ax-2021
    tx.LSIGLength = (((txTime-signalExtension-20)/4)*3)-3-m;
    obj.ULTBSysCfg = cfgSys; % Store the configuration

    % Increment station serve counts for Round Robin scheduler
    incrementSchedulerNumServes(obj);
else

    % If maximum queue size does not fit in allocated resources, check whether
    % at least 500 bytes fits in the maximum allowed PPDU duration.
    for userIdx = 1:numScheduledStations
        cfgSys.User{userIdx}.APEPLength = 500;
    end

    % Get tx time of HE-TB PPDU
    [~,txTime] = wlan.internal.hePLMETxTimePrimative(cfgSys);
    if txTime <= maxPPDUDuration % HE TB PPDU duration does not exceed max PPDU duration
        txTime = round(txTime*1e-3, 3);
        % Compute value of UL length field to be filled in Basic Trigger frame
        % Reference: Section 27.3.11.5 of IEEE Std 802.11ax-2021
        tx.LSIGLength = (((txTime-signalExtension-20)/4)*3)-3-m;
        obj.ULTBSysCfg = cfgSys; % Store the configuration

        % Increment station serve counts for Round Robin scheduler
        incrementSchedulerNumServes(obj);
    else
        % Abort the transmission of Basic Trigger frame
        isScheduled = false;
    end
end
end

function incrementSchedulerNumServes(obj)
%incrementSchedulerNumServes Increment serve counts for scheduler round robin

% Increment station serve counts for Round Robin scheduler
if isa(obj.Scheduler, "wlan.internal.mac.SchedulerRoundRobin")
    incrementNumServes(obj.Scheduler, obj.Tx.TxStationIDs, false);
end
end

function [mcs, numSTS] = getTBFrameRateParameters(obj, userIdx)
%getTBFrameRateParameters Return MCS and NumSTS to use for TB transmission
%from specified user

tx = obj.Tx;
rateControlInfo = obj.RateControlTxContextTemplate;
rateControlInfo.FrameType = 'QoS Data';
rateControlInfo.ReceiverNodeID = tx.TxStationIDs(userIdx);
rateControlInfo.TransmissionFormat = wlan.internal.utils.getFrameFormatString(obj.TransmissionFormat,'MAC');
rateControlInfo.ChannelBandwidth = tx.TxBandwidth*1e6;
rateControlInfo.CurrentTime = wlan.internal.utils.nanoseconds2seconds(obj.LastRunTimeNS);
obj.DataFrameRateControlTxContext = rateControlInfo;
[rateInfo] = rateParameters(obj.ULRateControl, rateControlInfo);

mcs = rateInfo.MCS;
numSTS = rateInfo.NumSpaceTimeStreams;
end
