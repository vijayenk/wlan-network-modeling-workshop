classdef SchedulerRoundRobin < wlan.internal.mac.Scheduler
%SchedulerRoundRobin Create round-robin scheduler object
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = wlan.internal.mac.SchedulerRoundRobin creates a round-robin
%   scheduler object, OBJ, for a multi-user network.

%   Copyright 2022-2025 The MathWorks, Inc.

properties(Access = private)
    % Counter to track number of chances of transmission to each station
    NumDLServes

    % List of stations among which scheduling must be performed
    DLStationIDs;

    % List of stations among which uplink scheduling must be performed
    ULStationIDs;

    % Stations with secondary AC data in transmission queues
    SecondaryACStations

    % Stations with secondary AC data in retry buffers
    SecondaryACRetryStations

    % Counter to track number of chances of uplink transmission for each
    % station
    NumULServes

    %STAScheduledInDLTXOP Flag indicating if a station has been scheduled for
    %downlink transmission in the current transmission opportunity (TXOP)
    %
    %   It is updated each time the scheduler runs, and cleared at the
    %   start of a new TXOP. Its dimensions are expanded dynamically, when
    %   the queue sizes for a station are non-empty. This dimension is the
    %   same as DLStationIDs.
    STAScheduledInDLTXOP;

    %STAScheduledInULTXOP Flag indicating if a station has been scheduled for
    %uplink transmission in the current transmission opportunity (TXOP)
    %
    %   It is updated each time the scheduler runs, and cleared at the
    %   start of a new TXOP. Its dimensions are updated each time the uplink
    %   scheduler runs. This dimension is the same as ULStationIDs.
    STAScheduledInULTXOP;
end

methods(Access = private)
    function secACs = secondaryACs(~, stationsList, txQueueLengths)
        % secondaryACs Returns access categories of stations that does
        % not contain primary ac data.

        if ~isempty(stationsList)
            for staIdx = numel(stationsList):-1:1
                % Secondary AC with data for a given station
                secACs(staIdx) = find(txQueueLengths(stationsList(staIdx),:), 1);
            end
        else
            secACs = zeros(0, 1);
        end
    end
end

methods
    function obj = SchedulerRoundRobin(varargin)
        % Constructor to create scheduler object.
        obj@wlan.internal.mac.Scheduler(varargin{:});

        % Initialize for one node and later grow dynamically
        obj.NumDLServes = 0;
        obj.DLStationIDs = 65535;
        obj.STAScheduledInDLTXOP = false;
        % Initialize to empty until number of associated STAs is known
        obj.NumULServes = [];
        obj.ULStationIDs = [];
    end

    function scheduleDLStations(obj, primaryAC, maxUsers, txQueueLengths, retryBufferLengths, stationInfo)
        % scheduleDLStations schedules destination stations

        bandwidth = stationInfo.ChannelBandwidth;

        % Number of stations to which data is queued
        numStations = size(txQueueLengths, 1);

        % Bitmap to indicate status of scheduling of each station.
        scheduleFlags = zeros(numStations, 1);

        % Stations with non-zero transmission buffer lengths
        txBufferedStations = find(~all(txQueueLengths == 0, 2))';
        txBufferedACs = zeros(numel(txBufferedStations), 1);
        txBufferedStationIDs = stationInfo.IDs(txBufferedStations);
        [~, numDLServesIndices] = ismember(txBufferedStationIDs, obj.DLStationIDs);

        % Get number of previous chances of transmission for above stations
        % and sort them.
        numServes = obj.NumDLServes(numDLServesIndices);
        [sortedNumServes, sortedIndices] = sort(numServes);

        % Rearrange active stations according to ascending order of number
        % of chances of transmission.
        txBufferedStations = txBufferedStations(sortedIndices);

        % Find retry stations with primary AC data and set schedule flags
        % to 1.
        primaryACRetryStations = find(retryBufferLengths(:, primaryAC))';
        scheduleFlags(primaryACRetryStations) = 1;

        % Find stations with primary AC data in transmission queues that
        % doesn't have primary AC data for retry and set corresponding
        % schedule flags to 1.
        primaryACStations = find(txQueueLengths(:, primaryAC))';
        primaryACStations = primaryACStations(scheduleFlags(primaryACStations) == 0);
        scheduleFlags(primaryACStations) = 1;

        % Assign weights as -3 for stations with primary AC data in retry
        % queues and -2 for stations with primary AC data in transmission
        % queues and set their corresponding ACs as primary AC.
        stations_cat3 = ismember(txBufferedStations, primaryACRetryStations);
        sortedNumServes(stations_cat3) = -3;
        txBufferedACs(stations_cat3) = primaryAC;
        stations_cat2 = ismember(txBufferedStations, primaryACStations);
        sortedNumServes(stations_cat2) = -2;
        txBufferedACs(stations_cat2) = primaryAC;

        acList = [2 1 3 4];
        % Get list of secondary ACs.
        acList(acList == primaryAC) = [];

        % Find stations with secondary AC data in retry buffers - Stations with
        % non-zero retry buffers, but excluding stations that are already scheduled
        % for primary AC.
        obj.SecondaryACRetryStations = find((sum(retryBufferLengths(:, acList), 2) ~= 0));
        obj.SecondaryACRetryStations = obj.SecondaryACRetryStations(scheduleFlags(obj.SecondaryACRetryStations) == 0);

        % Sort the list of stations with secondary AC data for retry
        % according to number of serves and set their schedule flags to 1.
        secondaryACRetryStationIDs = stationInfo.IDs(obj.SecondaryACRetryStations);
        [~, numDLServesIndices] = ismember(secondaryACRetryStationIDs, obj.DLStationIDs);
        [~, sortedRetrySecondaryACIndices] = sort(obj.NumDLServes(numDLServesIndices));
        obj.SecondaryACRetryStations = obj.SecondaryACRetryStations(sortedRetrySecondaryACIndices);
        scheduleFlags(obj.SecondaryACRetryStations) = 1;

        % Assign weight as -1 to secondary AC retry stations and get their
        % corresponding secondary ACs.
        stations_cat1 = ismember(txBufferedStations, obj.SecondaryACRetryStations);
        sortedNumServes(stations_cat1) = -1;
        txBufferedACs(stations_cat1) = secondaryACs(obj, obj.SecondaryACRetryStations, txQueueLengths);

        % Find stations with secondary AC data for normal transmission.
        obj.SecondaryACStations = txBufferedStations(scheduleFlags(txBufferedStations) == 0);

        % Sort the list of stations with secondary AC data for normal
        % transmission according to number of serves and get their
        % corresponding secondary ACs.
        secondaryACStationIDs = stationInfo.IDs(obj.SecondaryACStations);
        [~, numDLServesIndices] = ismember(secondaryACStationIDs, obj.DLStationIDs);
        [~, sortedSecondaryACIndices] = sort(obj.NumDLServes(numDLServesIndices));
        obj.SecondaryACStations = obj.SecondaryACStations(sortedSecondaryACIndices);
        txBufferedACs(scheduleFlags(txBufferedStations) == 0) = ...
            secondaryACs(obj, obj.SecondaryACStations, txQueueLengths);

        % Sort according to weights
        [~, tempSortedIndices] = sort(sortedNumServes);

        if numel(txBufferedStations) >= maxUsers
            dstStationIndices(1:maxUsers) = ...
                txBufferedStations(tempSortedIndices(1:maxUsers));
            obj.DLScheduleInfo.ACs(1:maxUsers) = txBufferedACs(tempSortedIndices(1:maxUsers));
        else
            dstStationIndices(1:numel(txBufferedStations)) ...
                = txBufferedStations(tempSortedIndices);
            obj.DLScheduleInfo.ACs(1:numel(txBufferedStations)) = txBufferedACs(tempSortedIndices);
        end

        % Re-arrange stations in the order of primary AC stations followed
        % by secondary AC stations from higher to lower priority
        secACs = obj.DLScheduleInfo.ACs(~(obj.DLScheduleInfo.ACs == primaryAC ...
            | obj.DLScheduleInfo.ACs == 0));
        secondaryACIndices = find(~(obj.DLScheduleInfo.ACs == primaryAC ...
            | obj.DLScheduleInfo.ACs == 0));
        secondaryACStas = dstStationIndices(secondaryACIndices);
        tempSecondaryACs = secACs; % Store original array
        % Assign weights according to priority of AC
        secACs(secACs == acList(1)) = -1;
        secACs(secACs == acList(2)) = -2;
        secACs(secACs == acList(3)) = -3;
        [~, sortedIndices] = sort(secACs);
        obj.DLScheduleInfo.ACs(secondaryACIndices) = tempSecondaryACs(sortedIndices);
        dstStationIndices(secondaryACIndices) = secondaryACStas(sortedIndices);

        dlSTAs = nnz(dstStationIndices);
        % Assign allocation index
        if stationInfo.TransmissionFormat == wlan.internal.FrameFormats.HE_MU % Allocation index is required only for 'HE-MU-OFDMA' format
            obj.DLScheduleInfo.AllocationIndex = wlan.internal.mac.SchedulerRoundRobin.heAssignAllocationIndex(dlSTAs, bandwidth);
        end

        if dlSTAs == 37 && bandwidth == 80 || dlSTAs == 73 && bandwidth == 160
            obj.DLScheduleInfo.UseLowerCenter26ToneRU = true;
            obj.DLScheduleInfo.UseUpperCenter26ToneRU = false;
        elseif dlSTAs == 74 && bandwidth == 160
            obj.DLScheduleInfo.UseLowerCenter26ToneRU = true;
            obj.DLScheduleInfo.UseUpperCenter26ToneRU = true;
        end

        % Change the destination station indices to destination station IDs
        obj.DLScheduleInfo.DstStationIDs(1:numel(dstStationIndices)) = stationInfo.IDs(dstStationIndices);
    end

    function expandSchedulerContext(obj, stationID)
        %expandSchedulerContext Expand context maintained in scheduler
        %
        %   expandSchedulerContext(OBJ, STATIONID) expands scheduler context for
        %   the node specified by STATIONID.
        %
        %   OBJ is an object of type SchedulerRoundRobin.
        %
        %   STATIONID is the node ID of the station.

        if ~any(stationID == obj.DLStationIDs)
            obj.DLStationIDs(end+1) = stationID;
            obj.NumDLServes(end+1) = 0;
            obj.STAScheduledInDLTXOP(end+1) = false;
        end
    end

    function incrementNumServes(obj, stationIDs, dlServe)
        %incrementNumServes Increment the number of serves maintained by the
        %scheduler for each destination node
        %
        %   incrementNumServes(OBJ, STATIONIDS, DLSERVE) increments the
        %   number of serves maintained for each destination node.
        %
        %   OBJ is an object of type SchedulerRoundRobin.
        %
        %   STATIONIDS are the node IDs of the stations which are scheduled
        %   for transmission.
        %
        %   DLSERVE defines whether the downlink or uplink serves need an
        %   update.

        if dlServe
            % Find stations which are not scheduled yet
            nonScheduledSTAs = obj.STAScheduledInDLTXOP == false;
            % Find indices of stations which are scheduled currently
            staIdxLogical = ismember(obj.DLStationIDs, stationIDs);
            % Among the list of scheduled stations, find the stations which
            % are not previously scheduled in the current TXOP, and increment
            % their serve count
            staUpdateIdxLogical = nonScheduledSTAs & staIdxLogical;
            obj.NumDLServes(staUpdateIdxLogical) = obj.NumDLServes(staUpdateIdxLogical) + 1;
            % Update the context
            obj.STAScheduledInDLTXOP(staUpdateIdxLogical) = true;
        else
            % Find stations which are not scheduled yet
            nonScheduledSTAs = obj.STAScheduledInULTXOP == false;
            % Find indices of stations which are scheduled currently
            staIdxLogical = ismember(obj.ULStationIDs, stationIDs);
            % Among the list of scheduled stations, find the stations which
            % are not previously scheduled in the current TXOP, and increment
            % their serve count
            staUpdateIdxLogical = nonScheduledSTAs & staIdxLogical;
            obj.NumULServes(staUpdateIdxLogical) = obj.NumULServes(staUpdateIdxLogical) + 1;
            % Update the context
            obj.STAScheduledInULTXOP(staUpdateIdxLogical) = true;
        end
    end

    function resetSchedulerContext(obj)
        % Reset the context indicating whether station has been scheduled
        % in the current TXOP

        obj.STAScheduledInDLTXOP(:) = false;
        obj.STAScheduledInULTXOP(:) = false;
    end

    function scheduleULStations(obj, maxUsers, queueInfo, stationInfo)
        %scheduleULStations Schedules stations for UL multi-user transmissions

        staList = stationInfo.IDs;
        obj.ULStationIDs = staList;
        numSTAs = numel(staList); % Number of associated STAs
        if isempty(obj.NumULServes)
            % Initialize for all associated STAs
            obj.NumULServes = zeros(numSTAs, 1);
            obj.STAScheduledInULTXOP = false(numSTAs, 1);
        end

        % Queue information of stations is not available
        if isempty(queueInfo)
            numServes = obj.NumULServes(1:numSTAs);
            [~, sortedIndices] = sort(numServes);

            % Choose the stations based on number of previous chances of
            % transmission
            if numSTAs < maxUsers
                maxUsers = numSTAs;
            end
            obj.ULScheduleInfo.StationIDs = staList(sortedIndices(1:maxUsers));

        else % Queue information is available
            % Get STAs whose queue info is available and non-zero
            nonzeroBufferIndices = ~(queueInfo(:, 3) == 0);
            staIDsWithNonzeroBuffer = unique(queueInfo(nonzeroBufferIndices, 1));
            numSTAsWithNonzeroBuffer = numel(staIDsWithNonzeroBuffer);
            numSTAsRemaining = 0;

            if numSTAsWithNonzeroBuffer < maxUsers
                % Remaining number of STAs that can be scheduled
                numSTAsRemaining = maxUsers - numSTAsWithNonzeroBuffer;
            else
                % Get the previous chances of transmission of STAs with
                % info and sort them
                numServes = obj.NumULServes(ismember(staList, staIDsWithNonzeroBuffer));
                [~, sortedIndices] = sort(numServes);

                obj.ULScheduleInfo.StationIDs = staIDsWithNonzeroBuffer(sortedIndices(1:maxUsers));
            end

            if numSTAsRemaining > 0
                staIDsWithInfo = unique(queueInfo(:, 1));
                remainingSTAs = staList(~ismember(staList, staIDsWithInfo));

                % Get the previous chances of transmission of remaining
                % STAs and sort them
                numServes = obj.NumULServes(ismember(staList, remainingSTAs));
                [~, sortedIndices] = sort(numServes);

                if numel(remainingSTAs) < numSTAsRemaining
                    numSTAsRemaining = numel(remainingSTAs);
                end

                obj.ULScheduleInfo.StationIDs = [staIDsWithNonzeroBuffer; remainingSTAs(sortedIndices(1:numSTAsRemaining))];
            end
        end

        % RU allocation
        numScheduledStations = numel(obj.ULScheduleInfo.StationIDs);
        if numScheduledStations > 0
            obj.ULScheduleInfo.AllocationIndex = ...
                wlan.internal.mac.SchedulerRoundRobin.heAssignAllocationIndex(numScheduledStations, stationInfo.ChannelBandwidth);

            if numScheduledStations == 37 && stationInfo.ChannelBandwidth == 80 ...
                    || numScheduledStations == 73 && stationInfo.ChannelBandwidth == 160
                obj.ULScheduleInfo.UseLowerCenter26ToneRU = true;
                obj.ULScheduleInfo.UseUpperCenter26ToneRU = false;
            elseif numScheduledStations == 74 && stationInfo.ChannelBandwidth == 160
                obj.ULScheduleInfo.UseLowerCenter26ToneRU = true;
                obj.ULScheduleInfo.UseUpperCenter26ToneRU = true;
            end
        end
    end
end

methods(Static, Access = private)
    function allocationIdx = heAssignAllocationIndex(numUsers, bandwidth)
        %heAssignAllocationIndex Return OFDMA allocation index
        %
        %   ALLOCATIONIDX = heAssignAllocationIndex(NUMUSERS, BANDWIDTH)
        %   returns OFDMA allocation index.
        %
        %   ALLOCATIONIDX is a scalar or vector representing allocation index
        %   for OFDMA transmission. It is a scalar, when channel bandwidth is
        %   20 MHz and a vector, when channel bandwidth is greater than 20 MHz.
        %   Each element in the vector represents allocation index for each 20
        %   MHz subchannel.
        %
        %   NUMUSERS is the number of scheduled downlink stations
        %
        %   BANDWIDTH is the channel bandwidth specified as one of 20, 40, 80, or
        %   160.

        if bandwidth == 20
            allocationIdx = wlan.internal.mac.SchedulerRoundRobin.subChannelAllocationIndex(numUsers);
        elseif (bandwidth == 40) || (bandwidth == 80) || (bandwidth == 160)
            % For channel bandwidth greater than 20 MHz, allocation index
            % should be specified for each 20 MHz subchannel.

            % Number of 20 MHz subchannels
            num20MHzChannels = bandwidth/20;

            allocationIdx = zeros(1, num20MHzChannels);
            if numUsers >= num20MHzChannels
                % Obtain number of users in each subchannel
                numUsersIn20MHz = wlan.internal.mac.SchedulerRoundRobin.getNumUsers(num20MHzChannels, numUsers);
                % Get allocation index for each subchannel
                for idx = 1:num20MHzChannels
                    allocationIdx(idx) = wlan.internal.mac.SchedulerRoundRobin.subChannelAllocationIndex(numUsersIn20MHz(idx));
                end
            else
                allocationIdx = wlan.internal.mac.SchedulerRoundRobin.channelAllocationIndex(numUsers, bandwidth);
            end
        end
    end

    function numUsersIn20MHz = getNumUsers(num20MHzChannels, totalNumUsers)
        %getNumUsers Return number of users in each 20 MHz subchannel

        % First assign equal number of users to each subchannel
        numUsersInSubchannel = repmat(floor(totalNumUsers/num20MHzChannels), num20MHzChannels, 1);
        % Total remaining users
        totalRemainingUsers = rem(totalNumUsers, num20MHzChannels);
        % Next assign remaining users to each subchannel
        remainingUsers = ones(totalRemainingUsers, 1);
        remainingUsers(end+1:num20MHzChannels, 1) = 0;
        % Total number of users in each subchannel
        numUsersIn20MHz = numUsersInSubchannel + remainingUsers;

        if any(numUsersIn20MHz > 9)
            numUsersIn20MHz(numUsersIn20MHz > 9) = 9;
        end
    end

    function allocIdx = subChannelAllocationIndex(numUsers)
        %subChannelAllocationIndex Return allocation index for 20 MHz
        %subchannel

        allocationTable = wlan.internal.heRUAllocationTable;

        % Obtain number of users and corresponding number of RUs from the
        % allocation table
        numUsersAndNumRU = table2array(allocationTable(:, 3:4));

        % Get indices of rows where each user is assigned a single RU
        ind = find(numUsersAndNumRU(:, 1) == numUsers);
        ind = ind(numUsersAndNumRU(ind, 2) == numUsers);

        % Get allocation indices less than 200. Allocation indices greater
        % than 200 corresponds to RUs with more than 242 tones
        allocationIndices = table2array(allocationTable(ind, 1));
        allocationIndices = allocationIndices(allocationIndices < 200);

        % Assign allocation index, such that difference between users RU size
        % is minimum
        ruSizes = table2array(allocationTable(allocationIndices+1, 6));
        maxDiff = Inf;
        allocIdx = allocationIndices(1);

        for idx = 1:numel(ruSizes)
            diffs= abs(diff(ruSizes{idx, 1}));
            if max( diffs(diffs>=0)) < maxDiff
                maxDiff= max( diffs(diffs>=0));
                allocIdx = allocationIndices(idx);
            end
        end
    end

    function allocIdx = channelAllocationIndex(numUsers, bandwidth)
        %channelAllocationIndex Return allocation index for the channel when
        %number of users is less than number of 20MHz subchannels, for
        %bandwidths greater than 20 MHz

        switch bandwidth
            case 40
                if numUsers == 1
                    allocIdx = [200 114];
                end

            case 80
                if numUsers == 1
                    allocIdx = [208 115 115 115];
                elseif numUsers == 2
                    allocIdx = [200 114 200 114];
                elseif numUsers == 3
                    allocIdx = [200 114 192 192];
                end

            case 160
                if numUsers == 1
                    allocIdx = [216 115 115 115 115 115 115 115];
                elseif numUsers == 2
                    allocIdx = [208 115 115 115 208 115 115 115];
                elseif numUsers == 3
                    allocIdx = [208 115 115 115 200 114 200 114];
                elseif numUsers == 4
                    allocIdx = [200 114 200 114 200 114 200 114];
                elseif numUsers == 5
                    allocIdx = [200 114 200 114 200 114 192 192];
                elseif numUsers == 6
                    allocIdx = [200 114 200 114 192 192 192 192];
                elseif numUsers == 7
                    allocIdx = [200 114 192 192 192 192 192 192];
                end
        end
    end
end
end
