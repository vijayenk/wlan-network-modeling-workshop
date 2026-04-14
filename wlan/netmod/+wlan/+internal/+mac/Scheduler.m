classdef Scheduler < handle
%Scheduler Base class for scheduling algorithms
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   This is the base class for implementing any scheduling algorithm.
%
%   Scheduler methods:
%
%   runDLScheduler - Schedules destination stations for transmissions from
%                    the device
%   runULScheduler - Schedules stations for uplink multi-user
%                    transmissions

%   Copyright 2022-2025 The MathWorks, Inc.

properties(GetAccess = public, SetAccess = protected)
    %DLScheduleInfo Structure containing IDs, ACs and allocation index of
    %scheduled destination stations
    %   DstStationIDs          - Node IDs of scheduled stations
    %   ACs                    - ACs of scheduled stations
    %   AllocationIndex        - OFDMA allocation index
    %   UseLowerCenter26ToneRU - Use lower center 26 tone resource unit (RU)
    %   UseUpperCenter26ToneRU - Use upper center 26 tone RU
    %
    %   For single-user transmissions, the first element of ACs field is
    %   the primary AC and the remaining elements are zeros. For
    %   multi-user(MU) transmissions, ACs field contains AC corresponding
    %   to scheduled stations. AllocationIndex field is applicable for
    %   multi-user(MU) OFDMA transmissions.
    DLScheduleInfo

    %StationInfo Station information structure
    %   This structure contains the station information required for the
    %   resource scheduler to select the stations for transmission and allocate
    %   resources to them. The MAC layer must fill the information required for
    %   the supported scheduler algorithms before calling the runDLScheduler
    %   and runULScheduler methods. This structure can be extended to include
    %   other properties for custom algorithms. The station info fields are:
    %       IDs                 - IDs of stations whose information is filled
    %       SINR                - Signal to interference plus noise ratio of each station
    %       AllocatedTxPower    - Allocated transmission power to each station
    %       MCS                 - MCS index to be used for transmission to each station
    %       NSS                 - Number of space time streams allocated to each station
    %       RSSI                - Received signal strength of acknowledgment from each station
    %       ChannelBandwidth    - Bandwidth of the transmission
    %       TxMSDULengths       - Buffered MSDU lengths to each station
    StationInfo

    %ULScheduleInfo Structure containing IDs of scheduled stations for
    %uplink transmissions and allocation index
    %   StationIDs             - Node IDs of scheduled stations
    %   AllocationIndex        - OFDMA allocation index
    %   UseLowerCenter26ToneRU - Use lower center 26 tone RU
    %   UseUpperCenter26ToneRU - Use upper center 26 tone RU
    ULScheduleInfo
end

properties(Access = protected)
    %MaxMUUsers Maximum number of users addressed in an MU frame
    MaxMUUsers = 74;
end

properties(Constant, Hidden)
    % IEEE 802.11 quality of service (QoS) defines application
    % data priorities by grouping them into 4 access categories.
    MaxACs = 4;
end

methods
    % Constructor method
    function obj = Scheduler(varargin)

        % Maximum DL users(160 MHz BW)
        maxMUUsers = 74;

        if nargin > 2
            % Name-value pair check
            if (mod(nargin-2, 2)~=0)
            error(message('wlan:ConfigBase:InvalidPVPairs'))
            end

            for i = 1:2:nargin-2
                obj.(varargin{i}) = varargin{i+1};
            end
        end

        obj.MaxMUUsers = maxMUUsers;

        obj.DLScheduleInfo = struct('DstStationIDs', zeros(maxMUUsers, 1),...
            'ACs', zeros(maxMUUsers, 1),...
            'AllocationIndex', 0, ...
            'UseLowerCenter26ToneRU', false, ...
            'UseUpperCenter26ToneRU', false);

        obj.StationInfo = struct('IDs', 0, 'SINR', 0, 'AllocatedTxPower', 0, ...
            'MCS', 0, 'NSS', 0, 'RSSI', 0, 'ChannelBandwidth', 20, ...
            'MSDULengths', 0, 'TransmissionFormat', wlan.internal.FrameFormats.NonHT);

        obj.ULScheduleInfo = struct('StationIDs', zeros(maxMUUsers, 1),...
            'AllocationIndex', 0, ...
            'UseLowerCenter26ToneRU', false, ...
            'UseUpperCenter26ToneRU', false);
    end
end

methods(Abstract)
    scheduleDLStations(obj, primaryAC, maxUsers,txQueueLengths,retryQueueLengths,stationInfo)
    %scheduleDLStations(...) Schedules destination stations for transmissions
    %from the device based on scheduling algorithm

    scheduleULStations(obj, maxUsers, queueInfo, stationInfo)
    %scheduleULStations(...) Schedules stations for uplink transmissions based
    %on scheduling algorithm
end

methods
    function dlScheduleInfo = runDLScheduler(obj, primaryAC, maxUsers, ...
            txQueueLengths, retryQueueLengths, stationInfo)
        %runDLScheduler Schedules destination stations for transmissions
        %from device
        %
        %   DLSCHEDULEINFO = runDLScheduler(OBJ, PRIMARYAC, MAXUSERS,
        %   EDCAQUEUES, STATIONINFO) schedules destination stations.
        %
        %   DLSCHEDULEINFO is a structure with fields DSTSTATIONIDS, ACS,
        %   ALLOCATIONINDEX.
        %   DSTSTATIONIDS          - IDs of scheduled stations
        %   ACS                    - Access Categories of scheduled stations
        %   ALLOCATIONINDEX        - Allocation index for OFDMA transmission
        %   USELOWERCENTER26TONERU - This property will be set to true in
        %                            the following cases:
        %                            User is allocated to the center
        %                            26-tone RU of the lower frequency 80
        %                            MHz.
        %                            User is allocated to each of
        %                            the center26-tone RU of the lower
        %                            frequency 80 MHz and that of the
        %                            higher frequency 80 MHz individually.
        %   USEUPPERCENTER26TONERU - This property will be set to true in
        %                            the following cases:
        %                            User is allocated to the center
        %                            26-tone RU of the higher frequency 80
        %                            MHz.
        %                            User is allocated to each of the
        %                            center26-tone RU of the lower
        %                            frequency 80 MHz and that of the
        %                            higher frequency 80 MHz individually.
        %
        %   PRIMARYAC is the primary access category of the transmission.
        %
        %   MAXUSERS is the maximum number of users that can be scheduled
        %   in a multi-user transmission. For single-user transmissions,
        %   value of MAXUSERS must be 1.
        %
        %   TXQUEUELENGTHS represents the number of MSDUs buffered for
        %   transmission
        %
        %   RETRYQUEUELENGTHS represents the number of MSDUs in
        %   retransmission queue
        %
        %   STATIONINFO is a station information structure. See <a
        %   href="matlab:help('Scheduler.StationInfo')">StationInfo</a>
        %   for more info.

        % Initialize
        obj.DLScheduleInfo.DstStationIDs = zeros(obj.MaxMUUsers, 1);
        obj.DLScheduleInfo.ACs = zeros(obj.MaxMUUsers, 1);
        obj.DLScheduleInfo.UseLowerCenter26ToneRU = false;
        obj.DLScheduleInfo.UseUpperCenter26ToneRU = false;
        scheduleDLStations(obj, primaryAC, maxUsers, txQueueLengths, retryQueueLengths, stationInfo);
        dlScheduleInfo = obj.DLScheduleInfo;
    end

    function ulScheduleInfo = runULScheduler(obj, maxUsers, queueInfo, ...
            stationInfo)
        %runULScheduler Schedules stations for uplink multi-user
        %transmissions
        %
        %   ULSCHEDULEINFO = runULScheduler(OBJ, MAXUSERS, QUEUEINFO,
        %   STATIONINFO) schedules stations for uplink multi-user OFDMA
        %   transmissions.
        %
        %   ULSCHEDULEINFO represents the UL scheduling information and is
        %   a structure containing following fields:
        %     STATIONIDS             - IDs of scheduled stations
        %     ALLOCATIONINDEX        - Allocation index for OFDMA transmission
        %     USELOWERCENTER26TONERU - This property will be set to true in
        %                              the following cases:
        %                              User is allocated to the center
        %                              26-tone RU of the lower frequency 80
        %                              MHz.
        %                              User is allocated to each of
        %                              the center26-tone RU of the lower
        %                              frequency 80 MHz and that of the
        %                              higher frequency 80 MHz individually.
        %     USEUPPERCENTER26TONERU - This property will be set to true in
        %                              the following cases:
        %                              User is allocated to the center
        %                              26-tone RU of the higher frequency 80
        %                              MHz.
        %                              User is allocated to each of the
        %                              center26-tone RU of the lower
        %                              frequency 80 MHz and that of the
        %                              higher frequency 80 MHz individually.
        %
        %   MAXUSERS is the maximum number of users that can be scheduled
        %   in a multi-user transmission.
        %
        %   QUEUEINFO is an array of size M-by-3. Elements in first column
        %   are associated STA IDs, in second column are access categories
        %   and in third column are queue sizes in bytes.
        %
        %   STATIONINFO is a station information structure. See <a
        %   href="matlab:help('Scheduler.StationInfo')">StationInfo</a>
        %   for more info.

        % Initialize
        obj.ULScheduleInfo.StationIDs = zeros(obj.MaxMUUsers, 1);
        obj.ULScheduleInfo.UseLowerCenter26ToneRU = false;
        obj.ULScheduleInfo.UseUpperCenter26ToneRU = false;
        scheduleULStations(obj, maxUsers, queueInfo, stationInfo);
        ulScheduleInfo = obj.ULScheduleInfo;
    end

    function resetSchedulerContext(~)
        %resetSchedulerContext Resets the context maintained by scheduler.
        %
        %   resetSchedulerContext(OBJ) resets the context maintained by scheduler.
        %   The MAC layer might need to call this method at appropriate instances
        %   like TXOP end. This is a base implementation that does nothing. Derived
        %   classes must overwrite this method with necessary context.
    end
end
end
