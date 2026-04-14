classdef QueueManager < handle
%QueueManager Create a WLAN MAC queue management object
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = wlan.internal.mac.QueueManager(MAXQUEUELENGTH,
%   MAXSUBFRAMESCOUNT) creates a WLAN MAC queue management object, OBJ,
%   with a maximum queue length of MAXQUEUELENGTH and a maximum A-MPDU
%   subframe count of MAXSUBFRAMESCOUNT.
%
%   OBJ = wlan.internal.mac.QueueManager(MAXQUEUELENGTH,
%   MAXSUBFRAMESCOUNT, Name=Value) creates a WLAN MAC queue management
%   object, OBJ, with the specified property Name set to the specified
%   Value. You can specify additional name-value arguments in any order as
%   (Name1=Value1, ..., NameN=ValueN).
%
%   QueueManager properties:
%   ShortRetryLimit     - Maximum number of transmission attempts for an
%                         MPDU
%
%   QueueManager properties (read-only):
%   MaxQueueLength      - Maximum size of a queue
%   MaxSubframesCount   - Maximum subframes present in an A-MPDU
%   NumRetryBuffers     - Number of retransmission buffers
%   TxQueueLengths      - Number of MPDUs buffered for transmission
%   RetryBufferLengths  - Number of MPDUs in retransmission buffers
%   MSDULengths         - Length of each MSDU buffered for transmission

%   Copyright 2022-2025 The MathWorks, Inc.

properties
    %ShortRetryLimit Maximum number of transmission attempts for an MPDU
    % ShortRetryLimit is a scalar in the range [1 65535], representing maximum
    % number of transmission attempts for an MPDU allowed before discard.
    ShortRetryLimit (1, 1) {mustBeInteger} = 7;
end

properties(SetAccess = private, GetAccess = public)
    %MaxQueueLength Maximum size of a queue
    % MaxQueueLength is a scalar representing maximum number of MPDUs that
    % can be stored in a queue.
    MaxQueueLength (1, 1) {mustBeNumeric}

    %MaxSubframesCount Maximum number of subframes in an A-MPDU
    % MaxSubframesCount is a scalar representing maximum number of
    % subframes that can be present in an A-MPDU.
    MaxSubframesCount (1, 1) {mustBeNumeric}

    %NumRetryBuffers Number of retransmission buffers
    % NumRetryBuffers is a scalar representing the number of retransmission
    % buffers. In case of queue object created in shared MAC, specify this
    % property as the number of links affiliated with an MLD shared MAC. In
    % case of queue objects created in EDCA MAC, it has a default value of 1.
    NumRetryBuffers (1, 1) {mustBePositive} = 1;

    %TxQueueLengths Number of data MPDUs buffered for transmission
    % TxQueueLengths is an array of size M x N where N is the maximum
    % number of ACs. Each row corresponds to a specific node in the
    % network. Each element represents number of data MPDUs present in
    % transmission queue in a node in corresponding AC.
    TxQueueLengths

    %TxManagementQueueLengths Number of MMPDUs buffered for transmission
    % TxManagementQueueLengths is an array of size M where each element
    % corresponds to a specific node in the network. Each element
    % represents number of management MPDUs present in transmission queue
    % in a node.
    TxManagementQueueLengths

    %RetryBufferLengths Number of MPDUs in retransmission buffers
    % RetryBufferLengths is an array of size M x N X O where N is the maximum
    % number of ACs and O is the value of NumRetryBuffers. Each row
    % corresponds to a specific node in the network. Each element represents
    % number of MPDUs in retry buffer corresponding to a link, node and AC
    % that are not discarded.
    RetryBufferLengths

    %MSDULengths Length of each MSDU buffered for transmission
    % MSDULengths is an array of size M x N x O where N is the maximum
    % number of ACs and O is the maximum queue length. Each row corresponds
    % to a specific node in the network. Each element represents length of
    % MSDU present in the queue of corresponding node and corresponding AC.
    MSDULengths
end

properties(Constant, Hidden)
    % Maximum number of users in a multi-user(MU) transmission using OFDMA.
    % In 20MHz OFDMA transmission max possible users are 9.
    MaxMUStations = 9;

    % Maximum number of access categories (AC). IEEE 802.11 quality of
    % service (QoS) defines application data priorities by grouping them
    % into 4 ACs.
    MaxACs = 4;
end

properties(Access = private)
    %Packet Structure of each packet in queue (MPDU structure)
    % Packet is a scalar structure containing the MPDU information
    Packet

    %PacketsToAggregate List of packets to be aggregated
    % PacketsToAggregate is a structure containing information of the
    % MPDUs to generate PSDU
    PacketsToAggregate

    %FrameList Dequeued MPDUs corresponding to given nodes
    % FrameList is a vector of structures with N elements, where N is the
    % number of nodes whose packets are dequeued for transmission. Each
    % structure contains MPDUs information to generate PSDU.
    FrameList

    %WriteIndices Write indices of each data queue
    % WriteIndices is an array of size M x N where M is number of
    % nodes in the network and N is the maximum number of ACs.
    WriteIndices

    %WriteIndicesManagementQ Write indices of each management queue
    % WriteIndicesManagementQ is an array of size M where M is number of
    % nodes in the network.
    WriteIndicesManagementQ

    %RetryMPDUIndices MPDU indices that are waiting for retransmission
    % RetryMPDUIndices is a cell array of size M x N x O where N is the maximum
    % number of ACs and O is the value of NumRetryBuffers. Each row corresponds
    % to a specific node in the network. Non-zero elements in each cell
    % represents the indices that are not discarded from a retry buffer
    % corresponding to an AC and a node.
    RetryMPDUIndices
end

properties(Hidden)
    %MSDUMaxLifetime Maximum lifetime after which MSDUs must be discarded
    % MSDUMaxLifetime is a scalar that contains the maximum time in nanoseconds
    % allowed for an MSDU before discard, starting from its enqueue into MAC
    % queue. This value is applicable for all access categories.
    % Reference: Section 10.23.2.12.1 of IEEE Std 802.11-2020
    MSDUMaxLifetime = 512000e3; % 500 TUs = 500 * 1024 microseconds

    %DestinationNodeIDs IDs of nodes for which transmission queues are
    %maintained
    % DestinationNodeIDs is an array of size M x 1. Each element contains the
    % ID of a specific node in the network.
    DestinationNodeIDs = 65535;

    %TxManagementQueue Transmission queues per node per AC
    % TxManagementQueue is an array of size M x N where N is the maximum
    % queue length. Each row corresponds to a specific node in the network.
    % Each element represents a management MPDU structure.
    TxManagementQueues

    %ReadIndicesManagementQueue Read indices of each queue
    % ReadIndicesManagementQueue is an array of size M where each element corresponds to a
    % specific node in the network.
    ReadIndicesManagementQ

    %TxQueues Transmission queues per node per AC
    % TxQueues is an array of size M x N x O where N is the maximum number
    % of ACs and O is the maximum queue length. Each row corresponds to a
    % specific node in the network. Each element represents a data MPDU
    % structure.
    TxQueues

    %ReadIndices Read indices of each queue
    % ReadIndices is an array of size M x N where N is the maximum number
    % of ACs. Each row corresponds to a specific node in the network.
    ReadIndices

    %RetryBuffers Retransmission buffers per node per AC
    % RetryBuffers is an array of size M x N x O where N is the maximum number
    % of ACs and O is the value of NumRetryBuffers. Each row corresponds to a
    % specific node in the network. Each element represents a frame of
    % corresponding AC dequeued from a node to be transmitted on a link.
    RetryBuffers

    %RetryBufferIndices Write indices of retry buffers
    % RetryBufferIndices is an array of size M x N where N is the maximum
    % number of ACs. Each row corresponds to a specific node in the network.
    % Each element represents the index of retry buffer at which the dequeued
    % packet must be inserted.
    RetryBufferIndices

    %RetryMSDULengths Lengths of MSDUs that are waiting for retransmission
    % RetryMSDULengths is a cell array of size M x N x O where N is the maximum
    % number of ACs and O is the value of NumRetryBuffers. Each row corresponds
    % to a specific node in the network. Elements in each cell represents the
    % lengths of MSDUs that are not discarded from a retry buffer corresponding
    % to an AC and a node.
    RetryMSDULengths

    %RetryBufferTxInProgress Flag indicating that transmission of MPDUs in
    %retry buffers is in progress
    % RetryBufferTxInProgress is an array of size M x N x O where N is the
    % maximum number of ACs and O is the value of NumRetryBuffers. Each row
    % corresponds to a specific node in the network. Each element represents
    % whether the transmission of MPDUs in retry buffers is in progress.
    RetryBufferTxInProgress

    %IsRetransmission Flag indicating that transmission of MPDUs in retry
    %buffers is a retransmission
    % IsRetransmission is an array of size M x N x O where N is the maximum
    % number of ACs and O is the value of NumRetryBuffers. Each row corresponds
    % to a specific node in the network. Each element represents that the
    % transmission of MPDUs in retry buffers is a retransmission, when set to
    % true. It is set to true immediately after the start of initial
    % transmission.
    IsRetransmission
end

methods(Access = private)
    function [frameList, numPacketsRetrieved] = getPacketsFromRetryBuffer(obj, frameList, nodeIdx, ac, retryBufferIdx, numMPDU, dequeueFrameIdx)
        % Retrieves the required number of MPDUs from the retry buffer and
        % returns a framelist containing retrieved MPDU information and the
        % number of MPDUs retrieved.

        % Find the indices that are not discarded
        retryIndices = obj.RetryMPDUIndices{nodeIdx, ac, retryBufferIdx};

        % Retry buffer contains less number of MPDUs than to be dequeued
        if obj.RetryBufferLengths(nodeIdx, ac, retryBufferIdx) < numMPDU
            numMPDU = obj.RetryBufferLengths(nodeIdx, ac, retryBufferIdx);
        end

        for idx = 1:numMPDU
            frameList(dequeueFrameIdx).MPDUs(idx) = obj.RetryBuffers(nodeIdx, ac, retryBufferIdx).MPDUs(retryIndices(idx));
        end
        numPacketsRetrieved = numMPDU;
    end

    function dequeuedMPDUInfo = dequeueFromTxQ(obj, nodeIdx, ac, numMPDU, dequeueFrameIdx, MPDUIdx)
        % Dequeues required number of MPDUs from transmission queue and inserts
        % them into FrameList at index corresponding to the staIdx and MPDUIdx.

        dequeuedMPDUInfo = repmat(obj.Packet, obj.MaxSubframesCount, 1);
        for idx = MPDUIdx:MPDUIdx + numMPDU - 1

            readIndex = obj.ReadIndices(nodeIdx, ac);
            obj.FrameList(dequeueFrameIdx).MPDUs(idx) = obj.TxQueues(nodeIdx, ac, readIndex);
            obj.ReadIndices(nodeIdx, ac) = obj.ReadIndices(nodeIdx, ac) + 1;

            % Return dequeued MPDUs info
            dequeuedMPDUInfo(idx - MPDUIdx + 1) = obj.TxQueues(nodeIdx, ac, readIndex);

            % Read index must be reset to 1 after reaching maximum queue length.
            if obj.ReadIndices(nodeIdx, ac) > obj.MaxQueueLength
                obj.ReadIndices(nodeIdx, ac) = 1;
            end
        end
    end

    function dequeuedMPDUInfo = dequeueFromTxManagementQ(obj, nodeIdx, numMPDU, dequeueFrameIdx, MPDUIdx)
        % Dequeues an MPDU from management transmission queue and inserts
        % them into FrameList at index corresponding to the staIdx.

        dequeuedMPDUInfo = repmat(obj.Packet, obj.MaxSubframesCount, 1);
        for idx = MPDUIdx:MPDUIdx + numMPDU - 1

            readIndex = obj.ReadIndicesManagementQ(nodeIdx);
            obj.FrameList(dequeueFrameIdx).MPDUs(idx) = obj.TxManagementQueues(nodeIdx, readIndex);
            obj.ReadIndicesManagementQ(nodeIdx) = obj.ReadIndicesManagementQ(nodeIdx) + 1;

            % Return dequeued MPDUs info
            dequeuedMPDUInfo(idx - MPDUIdx + 1) = obj.TxManagementQueues(nodeIdx, readIndex);

            % Read index must be reset to 1 after reaching maximum queue length.
            if obj.ReadIndicesManagementQ(nodeIdx) > obj.MaxQueueLength
                obj.ReadIndicesManagementQ(nodeIdx) = 1;
            end
        end
    end

    function retryBuffIndex = insertInRetryBuffer(obj, nodeIdx, ac, frame)
        %insertInRetryBuffer Inserts the frame dequeued from transmission queue into retry buffer and
        % increments retry buffer length. This method should be invoked only if
        % buffer is empty.

        buffIndex = obj.RetryBufferIndices(nodeIdx, ac);

        % Retry Buffer is considered occupied if there are packets. If occupied,
        % increment the buffer index and keep looking for an unoccupied space until
        % all buffer indices are checked. The buffer is circular, and the starting
        % index can be any index within the buffer. If buffer is fully occupied,
        % ensure that starting index is checked only once (to avoid infinite loop).
        startingBufferIdx = buffIndex;
        startingBufferIdxChecked = false;
        while obj.RetryBufferLengths(nodeIdx, ac, buffIndex)
            % All buffers are checked, none are available
            if startingBufferIdxChecked && buffIndex == startingBufferIdx
                retryBuffIndex = 0;  % Indicate no buffer available
                return;
            end

            % Mark that the starting index is checked
            if buffIndex == startingBufferIdx
                startingBufferIdxChecked = true;
            end

            % Move to next buffer with wrap-around
            buffIndex = buffIndex + 1;
            if buffIndex > obj.NumRetryBuffers
                buffIndex = 1; % Wrap-around
            end
        end
        retryBuffIndex = buffIndex;
        obj.RetryBuffers(nodeIdx, ac, buffIndex) = frame; % Insert frame into retry buffer

        % Set the retry buffer length
        numPackets = numel(frame.MPDUs);
        obj.RetryBufferLengths(nodeIdx, ac, buffIndex) = numPackets;
        % Remove packets from transmission queue, i.e., decrement transmission
        % queue length
        if wlan.internal.utils.isManagementFrame(frame.MPDUs(1))
            obj.TxManagementQueueLengths(nodeIdx) = obj.TxManagementQueueLengths(nodeIdx) - numPackets;
        else
            obj.TxQueueLengths(nodeIdx, ac) = obj.TxQueueLengths(nodeIdx, ac) - numPackets;
        end

        % Index the packets in retry buffer
        obj.RetryMPDUIndices{nodeIdx, ac, buffIndex} = (1:obj.RetryBufferLengths(nodeIdx, ac, buffIndex))';

        % Store the MSDU lengths of packets inserted into retry buffer
        txMSDULengths = obj.MSDULengths(nodeIdx, ac, :);
        retryMSDULengths = txMSDULengths(1:numPackets);
        obj.RetryMSDULengths{nodeIdx, ac, buffIndex} = retryMSDULengths;

        % As the packets are no longer considered to be in transmission queue,
        % update MSDU lengths.
        txMSDULengths(1:numPackets) = 0;
        validMSDULengths = nonzeros(txMSDULengths);
        obj.MSDULengths(nodeIdx, ac, :) = [validMSDULengths; zeros(obj.MaxQueueLength - numel(validMSDULengths), 1)];

        % Increment the index of retry buffer
        buffIndex = buffIndex + 1;
        if buffIndex > obj.NumRetryBuffers
            buffIndex = 1; % Wrap-around
        end
        obj.RetryBufferIndices(nodeIdx, ac) = buffIndex;
    end

    function frameList = peekFromTxQ(obj, frameList, nodeIdx, ac, numMPDU, dequeueFrameIdx, MPDUIdx)
        % Peeks the required number of MPDUs from the transmission queue
        % and insert them into frameListPeek at index corresponding to the
        % staIdx and MPDUIdx.

        %functionally equivalent to dequeueFromTxQ function but it does not
        %update the readIndices property context at the end unlike the
        %previous.

        readIndex = obj.ReadIndices(nodeIdx, ac);

        for idx = 1:numMPDU
            packet = obj.TxQueues(nodeIdx, ac, readIndex);

            peekedMPDUidx = MPDUIdx+idx-1;
            frameList(dequeueFrameIdx).MPDUs(peekedMPDUidx) = packet;

            readIndex = readIndex+1;
            if readIndex > obj.MaxQueueLength
                readIndex = 1;
            end
        end
    end

    function frameList = peekFromTxManagementQ(obj, frameList, nodeIdx, numMPDU, dequeueFrameIdx, MPDUIdx)
        % Peeks the required number of MPDUs from the transmission queue
        % and insert them into frameListPeek at index corresponding to the
        % staIdx and MPDUIdx.

        %functionally equivalent to dequeueFromTxManagementQ function but
        %it does not update the readIndices property context at the end
        %unlike the previous.

        readIndex = obj.ReadIndicesManagementQ(nodeIdx);

        for idx = 1:numMPDU
            packet = obj.TxManagementQueues(nodeIdx, readIndex);

            peekedMPDUidx = MPDUIdx+idx-1;
            frameList(dequeueFrameIdx).MPDUs(peekedMPDUidx) = packet;

            readIndex = readIndex+1;
            if readIndex > obj.MaxQueueLength
                readIndex = 1;
            end
        end
    end

    function discardedIndices = discardPackets(obj, nodeIndexList, acList, retryBufferIdx, MPDUIndices, numIndices, numNodes)
        %discardPackets Discard packets from retry buffer
        %
        %   DISCARDEDINDICES = discardPackets(OBJ, NODEINDEXLIST, ACLIST,
        %   MPDUINDICES, NUMINDICES, NUMNODES) discards packets.
        %
        %   DISCARDEDINDICES is an array of size M x N where M is the
        %   maximum subframe count and N is the number of nodes for
        %   discard. It contains the indices of discarded packets from each
        %   node.
        %
        %   NODEINDEXLIST is an M x 1 array of queue indices corresponding
        %   to nodes for which packets must be discarded, where M is the
        %   maximum number of users.
        %
        %   ACLIST is an M x 1 array of access categories corresponding to
        %   the node IDs from which packets must be discarded, where M
        %   is the maximum number of users.
        %
        %   MPDUINDICES is an array of size M x N where M is the maximum
        %   subframe count and N is the maximum number of users. It
        %   contains the indices of packets to be discarded corresponding
        %   to node IDs.
        %
        %   NUMINDICES is an M x 1 array of number of indices of packets to
        %   be discarded corresponding to node IDs, where M is the
        %   maximum number of users.
        %
        %   NUMNODES is the number of nodes for discard.

        % Initialize
        discardedIndices = zeros(obj.MaxQueueLength, numNodes);

        for staIdx = 1:numNodes

            % Discard packets if retry buffer is not empty.
            if obj.RetryBufferLengths(nodeIndexList(staIdx), acList(staIdx), retryBufferIdx) ~= 0

                % Find indices that are not already discarded.
                retryMPDUIndices = obj.RetryMPDUIndices{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx};

                for MPDUIdx = 1:numIndices(staIdx)
                    % Discard packet only if its index has not been
                    % discarded before
                    if any(retryMPDUIndices == MPDUIndices(MPDUIdx, staIdx))
                        % Indices of packets that are discarded are made 0
                        discardIdx = (retryMPDUIndices == MPDUIndices(MPDUIdx, staIdx));
                        obj.RetryMPDUIndices{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx}(discardIdx) = 0;
                        % MSDU lengths of discarded packets are made 0
                        obj.RetryMSDULengths{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx}(discardIdx) = 0;

                        % Decrement retry buffer length
                        obj.RetryBufferLengths(nodeIndexList(staIdx), acList(staIdx), retryBufferIdx) = ...
                            obj.RetryBufferLengths(nodeIndexList(staIdx), acList(staIdx), retryBufferIdx) - 1;
                    end
                end

                % Indices that are discarded
                tempDiscardedIndices = find(ismember(retryMPDUIndices, MPDUIndices(1:numIndices(staIdx), staIdx)));
                discardedIndices(1:numel(tempDiscardedIndices),staIdx) = tempDiscardedIndices;

                % Maintain only the retry MPDU indices and MSDU lengths that are not discarded
                retryMPDUIndices = obj.RetryMPDUIndices{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx};
                obj.RetryMPDUIndices{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx} = nonzeros(retryMPDUIndices);
                retryMSDULengths = obj.RetryMSDULengths{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx};
                retryMSDULengths = nonzeros(retryMSDULengths);
                obj.RetryMSDULengths{nodeIndexList(staIdx), acList(staIdx), retryBufferIdx} = reshape(retryMSDULengths, 1, 1, numel(retryMSDULengths));

                % Reset the packet in retry buffer if retry buffer length is 0
                if obj.RetryBufferLengths(nodeIndexList(staIdx), acList(staIdx), retryBufferIdx) == 0
                    obj.RetryBuffers(nodeIndexList(staIdx), acList(staIdx), retryBufferIdx) = obj.PacketsToAggregate;
                    obj.IsRetransmission(nodeIndexList(staIdx), acList(staIdx), retryBufferIdx) = false;
                end
            end
        end
    end

    function isEmptyRetryBuff = checkForEmptyRetryBuffers(obj, nodeIdx, acIdx)
        % Return true if retry buffers are empty and false, otherwise

        isEmptyRetryBuff = true;

        for buffIdx = 1:obj.NumRetryBuffers
            if obj.RetryBufferLengths(nodeIdx, acIdx, buffIdx) && ...
                    ~obj.RetryBufferTxInProgress(nodeIdx, acIdx, buffIdx)
                isEmptyRetryBuff = false;
                break;
            end
        end
    end
end

methods
    function obj = QueueManager(MaxQueueLength, MaxSubframesCount, varargin)
        % Constructor to create a queue object for nodes in the network

        obj.MaxQueueLength = MaxQueueLength;
        obj.MaxSubframesCount = MaxSubframesCount;

        % Name-value pairs
        for idx = 1:2:numel(varargin)
            obj.(varargin{idx}) = varargin{idx+1};
        end

        % Initialize transmission queue information
        obj.Packet = wlan.internal.utils.defaultMPDU;

        % Create queues for one node and add dynamically when required
        obj.TxQueues = repmat(obj.Packet, 1, wlan.internal.mac.QueueManager.MaxACs, MaxQueueLength);
        obj.TxManagementQueues = repmat(obj.Packet, 1, MaxQueueLength);
        obj.TxQueueLengths = zeros(1, wlan.internal.mac.QueueManager.MaxACs);
        obj.TxManagementQueueLengths = 0;
        obj.ReadIndices = ones(1, wlan.internal.mac.QueueManager.MaxACs);
        obj.ReadIndicesManagementQ = 1;
        obj.WriteIndices = ones(1, wlan.internal.mac.QueueManager.MaxACs);
        obj.WriteIndicesManagementQ = 1;
        obj.MSDULengths = zeros(1, wlan.internal.mac.QueueManager.MaxACs, MaxQueueLength);

        % Initialize retry buffer information
        obj.PacketsToAggregate = struct('MPDUs', wlan.internal.utils.defaultMPDU);
        obj.RetryBuffers = repmat(obj.PacketsToAggregate, 1, wlan.internal.mac.QueueManager.MaxACs, obj.NumRetryBuffers);
        obj.RetryBufferLengths = zeros(1, wlan.internal.mac.QueueManager.MaxACs, obj.NumRetryBuffers);
        obj.RetryBufferIndices = ones(1, wlan.internal.mac.QueueManager.MaxACs);
        obj.RetryMPDUIndices = cell(1, wlan.internal.mac.QueueManager.MaxACs, obj.NumRetryBuffers);
        obj.RetryMSDULengths = cell(1, wlan.internal.mac.QueueManager.MaxACs, obj.NumRetryBuffers);
        obj.RetryBufferTxInProgress = false(1, wlan.internal.mac.QueueManager.MaxACs, obj.NumRetryBuffers);
        obj.IsRetransmission = false(1, wlan.internal.mac.QueueManager.MaxACs, obj.NumRetryBuffers);
    end

    function isSuccess = enqueue(obj, nodeID, ac, packet)
        %enqueue Inserts packet into queue
        %
        %   ISSUCCESS = enqueue(OBJ, NODEID, AC, PACKET) inserts packet in
        %   the queue maintained for a node in given AC.
        %
        %   ISSUCCESS is a logical value that indicates the status of enqueue.
        %   % 1 - Enqueue success
        %   % 0 - Enqueue fail
        %
        %   NODEID is the ID of the node for which packet must be enqueued.
        %
        %   AC is the access category of the packet.
        %
        %   PACKET is the MPDU to be enqueued.

        nodeIdx = find(nodeID == obj.DestinationNodeIDs);
        isDataPacket = wlan.internal.utils.isDataFrame(packet);

        if isDataPacket
            % Data queue is full
            if ((obj.TxQueueLengths(nodeIdx, ac)+sum(obj.RetryBufferLengths, 3)) == obj.MaxQueueLength)
                isSuccess = false;

            else % Queue is not full

                % Insert packet into transmission queue and increment queue length.
                % Set corresponding MSDU lengths in MSDULengths array.
                index = obj.WriteIndices(nodeIdx, ac);
                obj.TxQueues(nodeIdx, ac, index) = packet;
                obj.TxQueueLengths(nodeIdx, ac) = obj.TxQueueLengths(nodeIdx, ac) + 1;
                if wlan.internal.utils.isDataFrame(packet)
                    obj.MSDULengths(nodeIdx, ac, obj.TxQueueLengths(nodeIdx, ac)) = packet.FrameBody.MSDU.PacketLength;
                end

                obj.WriteIndices(nodeIdx, ac) = obj.WriteIndices(nodeIdx, ac) + 1;
                % Reset write index to 1 after reaching maximum queue length.
                if obj.WriteIndices(nodeIdx, ac) > obj.MaxQueueLength
                    obj.WriteIndices(nodeIdx, ac) = 1;
                end

                isSuccess = true;
            end

        else % Management packet
            % Check if management queue is full
            numMgtFramesInRetry = numManagementFramesInRetryBuffer(obj,nodeIdx);
            if ((obj.TxManagementQueueLengths(nodeIdx)+numMgtFramesInRetry) == obj.MaxQueueLength)
                isSuccess = false;

            else % Queue is not full

                % Insert packet into transmission queue and increment queue length.
                % Set corresponding MSDU lengths in MSDULengths array.
                index = obj.WriteIndicesManagementQ(nodeIdx);
                obj.TxManagementQueues(nodeIdx, index) = packet;
                obj.TxManagementQueueLengths(nodeIdx) = obj.TxManagementQueueLengths(nodeIdx) + 1;

                obj.WriteIndicesManagementQ(nodeIdx) = obj.WriteIndicesManagementQ(nodeIdx) + 1;
                % Reset write index to 1 after reaching maximum queue length.
                if obj.WriteIndicesManagementQ(nodeIdx) > obj.MaxQueueLength
                    obj.WriteIndicesManagementQ(nodeIdx) = 1;
                end

                isSuccess = true;
            end
        end
    end

    function txFrame = peek(obj, nodeIDList, acList, numMPDU, numNodes)
        %peek Retrieves a specified number of MPDUs from the front of
        %the queue without altering the queue's state
        %
        %   TXFRAME = peek(OBJ, NODEIDLIST, ACLIST, NUMMPDU, NUMNODES)
        %   peeks MPDUs from either transmission queues or retry buffers.
        %   It prioritizes peeking from the retry buffer if MPDUs are
        %   available; if not enough are present, it retrieves the
        %   remaining from the transmission queue. If the retry buffer is
        %   empty, it peeks directly from the transmission queue.
        %
        %   TXFRAME is the aggregate of frames from all peeked nodes
        %
        %   NODEIDLIST is an M x 1 array of IDs of nodes for which packets
        %   must be peeked, where M is the maximum number of users.
        %
        %   ACLIST is an M x 1 array of access category indices
        %   corresponding to the node IDs from which packets are to be
        %   peeked, where M is the number of users.
        %
        %   NUMMPDU is an M x 1 array of required number of MPDUs
        %   corresponding to the node IDs from which packets are to be
        %   peeked, where M is the maximum number of users.
        %
        %   NUMNODES is the number of nodes for peek.

        frameListPeek = repmat(obj.PacketsToAggregate, numNodes, 1);

        for idx = 1:numNodes
            % Index from which MPDU information should be updated in frameListPeek
            mpduIdx = 1;

            % Get the queue index from which packets must be peeked for the given
            % node
            nodeIdx = find(nodeIDList(idx) == obj.DestinationNodeIDs);
            isEmptyRetryBuff = checkForEmptyRetryBuffers(obj, nodeIdx, acList(idx));

            % Get packets from retry buffer if it is not empty
            if ~isEmptyRetryBuff
                [~, retryBuffIndex] = getAvailableRetryBuffer(obj, nodeIDList(idx), acList(idx));

                % Peek the MPDUs from indices that are not already discarded.
                [frameListPeek, numPeeked] = getPacketsFromRetryBuffer(obj, frameListPeek, nodeIdx, acList(idx), retryBuffIndex, numMPDU(idx), idx);

                remainingMPDU = numMPDU(idx) - numPeeked;

                % peek from transmission queue if retry buffer doesn't have sufficient MPDUs to be peeked.
                if remainingMPDU > 0 && obj.TxQueueLengths(nodeIdx, acList(idx))
                    mpduIdx = numMPDU(idx) - remainingMPDU + 1;
                    frameListPeek = peekFromTxQ(obj, frameListPeek, nodeIdx, acList(idx), remainingMPDU, idx, mpduIdx);
                end

                % Peek packets from management queues of given node if retry buffer is empty
            elseif (acList(idx) == 4) && obj.TxManagementQueueLengths(nodeIdx)

                frameListPeek = peekFromTxManagementQ(obj, frameListPeek, nodeIdx, numMPDU(idx), idx, mpduIdx);

                % Peek packets from data queues of given node if retry buffer and management queue both are empty
            elseif obj.TxQueueLengths(nodeIdx, acList(idx))

                frameListPeek = peekFromTxQ(obj, frameListPeek, nodeIdx, acList(idx), numMPDU(idx), idx, mpduIdx);

            else
                % No data in transmission queues and retry buffer
                continue;
            end
        end
        % Aggregate frames from all peeked nodes
        txFrame = frameListPeek;
    end

    function [txFrame, retryBufferIndices] = dequeue(obj, nodeIDList, acList, numMPDU, numNodes)
        %dequeue Dequeues the required number of MPDUs
        %
        %   [TXFRAME, RETRYBUFFERINDICES] = dequeue(OBJ, NODEIDLIST, ACLIST,
        %   NUMMPDU, NUMNODES) dequeues MPDUs from either transmission queues or
        %   retry buffers.
        %
        %   TXFRAME is the aggregate of frames from all dequeued nodes.
        %
        %   RETRYBUFFERINDICES is an M x 1 array corresponding to nodes indicated
        %   in NODEIDLIST. Each element represents the retry buffer index at which
        %   dequeued packet is present. If packet is dequeued from transmission
        %   queues, it is inserted into retry buffers.
        %
        %   NODEIDLIST is an M x 1 array of IDs of nodes for which packets must be
        %   dequeued, where M is the maximum number of users.
        %
        %   ACLIST is an M x 1 array of access category indices corresponding to
        %   the node IDs from which packets must be dequeued, where M is the number
        %   of users.
        %
        %   NUMMPDU is an M x 1 array of required number of MPDUs corresponding to
        %   the node IDs from which packets must be dequeued, where M is the
        %   maximum number of users.
        %
        %   NUMNODES is the number of nodes for dequeue.

        retryBufferIndices = zeros(numNodes, 1);
        obj.FrameList = repmat(obj.PacketsToAggregate, numNodes, 1);

        for idx = 1:numNodes
            % Index from which MPDU information should be updated in FrameList
            MPDUIdx = 1;

            % Get the queue index from which packets must be dequeued for the given
            % node
            nodeIdx = find(nodeIDList(idx) == obj.DestinationNodeIDs);
            isEmptyRetryBuff = checkForEmptyRetryBuffers(obj, nodeIdx, acList(idx));

            % Get packets from retry buffer if it is not empty
            if ~isEmptyRetryBuff
                [~, retryBuffIndex] = getAvailableRetryBuffer(obj, nodeIDList(idx), acList(idx));

                % Get the MPDUs from indices that are not already
                % discarded.
                [obj.FrameList, numDequeued] = getPacketsFromRetryBuffer(obj, obj.FrameList, nodeIdx, acList(idx), retryBuffIndex, numMPDU(idx), idx);

                remainingMPDU = numMPDU(idx) - numDequeued;
                % Dequeue from transmission queue if there are less number of MPDUs than
                % desired in retry buffer.
                if remainingMPDU > 0 && obj.TxQueueLengths(nodeIdx, acList(idx))
                    MPDUIdx = numMPDU(idx) - remainingMPDU + 1;
                    dequeuedMPDUInfo = dequeueFromTxQ(obj, nodeIdx, acList(idx), remainingMPDU, idx, MPDUIdx);

                    if remainingMPDU > obj.TxQueueLengths(nodeIdx, acList(idx))
                        remainingMPDU = obj.TxQueueLengths(nodeIdx, acList(idx));
                    end

                    % Index the MPDUs that are dequeued from transmission queue.
                    retryMPDUIndices = obj.RetryMPDUIndices{nodeIdx, acList(idx), retryBuffIndex};
                    nextRetryMPDUIdx = max(retryMPDUIndices) + 1;
                    MPDUIndices = nextRetryMPDUIdx:nextRetryMPDUIdx + remainingMPDU - 1;
                    retryMPDUIndices(end+1:end+numel(MPDUIndices)) = MPDUIndices;
                    obj.RetryMPDUIndices{nodeIdx, acList(idx), retryBuffIndex} = retryMPDUIndices;

                    % Insert these MPDUs into retry buffer and increment retry buffer length.
                    for index = 1:remainingMPDU
                        obj.RetryBuffers(nodeIdx, acList(idx), retryBuffIndex).MPDUs(MPDUIndices(index)) = dequeuedMPDUInfo(index);
                        obj.RetryBufferLengths(nodeIdx, acList(idx), retryBuffIndex) = ...
                            obj.RetryBufferLengths(nodeIdx, acList(idx), retryBuffIndex) + 1;

                        % Remove packets from transmission queue, i.e., decrement transmission
                        % queue length
                        obj.TxQueueLengths(nodeIdx, acList(idx)) = obj.TxQueueLengths(nodeIdx, acList(idx)) - 1;
                    end

                    % Store the MSDU lengths of packets inserted into retry buffer
                    txMSDULengths = obj.MSDULengths(nodeIdx, acList(idx), :);
                    retryMSDULengths = obj.RetryMSDULengths{nodeIdx, acList(idx), retryBuffIndex};
                    retryMSDULengths(end+1:end+remainingMPDU) = txMSDULengths(1:remainingMPDU);
                    obj.RetryMSDULengths{nodeIdx, acList(idx), retryBuffIndex} = retryMSDULengths;

                    % As the packets are no longer considered to be in transmission queue,
                    % update MSDU lengths.
                    txMSDULengths(1:remainingMPDU) = 0;
                    validMSDULengths = nonzeros(txMSDULengths);
                    obj.MSDULengths(nodeIdx, acList(idx), :) = [validMSDULengths; zeros(obj.MaxQueueLength - numel(validMSDULengths), 1)];
                end
                retryBufferIndices(idx) = retryBuffIndex;

                % Set the flag indicating that the dequeued packets will be attempted for
                % transmission in the current transmit opportunity
                obj.RetryBufferTxInProgress(nodeIdx, acList(idx), retryBuffIndex) = true;

                % Dequeue packets from TxManagementQueues of given node if retry buffer is empty and management frame buffer is non-empty
            elseif (acList(idx) == 4) && obj.TxManagementQueueLengths(nodeIdx)

                % Dequeue an MMPDU from transmission queue.
                dequeueFromTxManagementQ(obj, nodeIdx, 1, idx, MPDUIdx);

                % Insert the dequeued MPDUs into retry buffer
                retryBuffIndex = insertInRetryBuffer(obj, nodeIdx, acList(idx), obj.FrameList(idx));
                retryBufferIndices(idx) = retryBuffIndex;

                % Set the flag indicating that the dequeued packets will be attempted for
                % transmission in the current transmit opportunity
                obj.RetryBufferTxInProgress(nodeIdx, acList(idx), retryBuffIndex) = true;

                % Dequeue packets from data queues of given node if both retry buffer and management queue are empty
            elseif obj.TxQueueLengths(nodeIdx, acList(idx))

                % Dequeue the MPDUs from transmission queue.
                dequeueFromTxQ(obj, nodeIdx, acList(idx), numMPDU(idx), idx, MPDUIdx);

                % Insert the dequeued MPDUs into retry buffer
                retryBuffIndex = insertInRetryBuffer(obj, nodeIdx, acList(idx), obj.FrameList(idx));
                retryBufferIndices(idx) = retryBuffIndex;

                % Set the flag indicating that the dequeued packets will be attempted for
                % transmission in the current transmit opportunity
                obj.RetryBufferTxInProgress(nodeIdx, acList(idx), retryBuffIndex) = true;

                % No data in transmission queues and retry buffer
            else
                retryBufferIndices(idx) = 0;
            end
        end

        % Aggregate frames from all dequeued nodes
        txFrame = obj.FrameList;
    end

    function incrementFrameRetryCount(obj, nodeIDList, acList, numNodes, varargin)
        %incrementFrameRetryCount Increment frame retry counter of MPDUs
        %
        %   incrementFrameRetryCount(OBJ, NODEIDLIST, ACLIST, NUMNODES,
        %   RetryBufferIndex=value) increments the frame retry counter of all the
        %   MPDUs present in retry buffer specified by RETRYBUFFERINDEX value.
        %
        %   NODEIDLIST is an M x 1 array of node IDs for which frame retry counters
        %   of packets must be incremented, where M is the maximum number of users.
        %
        %   ACLIST is an M x 1 array of access category indices corresponding to
        %   the node IDs for which frame retry counters of packets must be
        %   incremented, where M is the maximum number of users.
        %
        %   NUMNODES is the number of nodes for increment.
        %
        %   incrementFrameRetryCount(OBJ, NODEIDLIST, ACLIST, NUMNODES,
        %   MPDUCount=value) increments the frame retry counter of MPDUs present in
        %   retry buffers, if retry buffers are non-empty. Otherwise, frame retry
        %   counters of packets in tx queues are incremented.
        %
        %   MPDUCOUNT value is an M x 1 array containing number of MPDUs for which
        %   frame retry counter must be incremented, where M is the maximum number
        %   of users.

        for staIdx = 1:numNodes
            nodeIdx = find(nodeIDList(staIdx) == obj.DestinationNodeIDs);
            acIdx = acList(staIdx);

            if numel(varargin) == 2 % One NV pair provided
                if strcmp(varargin{1}, "RetryBufferIndex")
                    % Retry buffer index provided
                    retryBufferIdx = varargin{2};
                    numMPDU = 0; % Assign default
                else
                    % Number of MPDUs provided
                    numMPDU = varargin{2};
                    % Get available retry buffer index
                    [~, retryBufferIdx] = getAvailableRetryBuffer(obj, nodeIDList(staIdx), acIdx);
                end
            elseif numel(varargin) == 4 % Two NV pairs provided
                if strcmp(varargin{1}, "RetryBufferIndex")
                    retryBufferIdx = varargin{2};
                    numMPDU = varargin{4};
                else
                    retryBufferIdx = varargin{4};
                    numMPDU = varargin{2};
                end
            end

            if retryBufferIdx ~= 0 % Increment for packets in retry buffer
                % Find indices of packets present in retry buffer
                retryMPDUIndices = obj.RetryMPDUIndices{nodeIdx, acIdx, retryBufferIdx};
                if numMPDU == 0
                    % Increment retry counters for all packets in retry buffer
                    numMPDU = numel(retryMPDUIndices);
                end

                % Increment frame retry counters for packets present in retry buffer
                for mpduIdx = 1:numMPDU
                    obj.RetryBuffers(nodeIdx, acIdx, retryBufferIdx).MPDUs(retryMPDUIndices(mpduIdx)).Metadata.FrameRetryCount = ...
                        obj.RetryBuffers(nodeIdx, acIdx, retryBufferIdx).MPDUs(retryMPDUIndices(mpduIdx)).Metadata.FrameRetryCount + 1;
                end

            elseif (acIdx == 4) && obj.TxManagementQueueLengths(nodeIdx) % Management Tx queues
                readIndex = obj.ReadIndicesManagementQ(nodeIdx);
                if numMPDU == 0
                    numMPDU = 1;
                end

                % Increment frame retry counters for packets present in tx queues
                for mpduIdx = 1:numMPDU
                    obj.TxManagementQueues(nodeIdx, readIndex).Metadata.FrameRetryCount = obj.TxManagementQueues(nodeIdx, readIndex).Metadata.FrameRetryCount + 1;

                    readIndex = readIndex + 1;
                    % Read index must be reset to 1 after reaching
                    % maximum queue length.
                    if readIndex > obj.MaxQueueLength
                        readIndex = 1;
                    end
                end

            else % Tx queues
                % Starting index of packet for which frame retry counter must be
                % incremented
                readIndex = obj.ReadIndices(nodeIdx, acIdx);

                % Increment frame retry counters for packets present in tx queues
                for mpduIdx = 1:numMPDU
                    obj.TxQueues(nodeIdx, acIdx, readIndex).Metadata.FrameRetryCount = ...
                        obj.TxQueues(nodeIdx, acIdx, readIndex).Metadata.FrameRetryCount + 1;

                    readIndex = readIndex + 1;
                    % Read index must be reset to 1 after reaching
                    % maximum queue length.
                    if readIndex > obj.MaxQueueLength
                        readIndex = 1;
                    end
                end
            end
        end
    end

    function [nodeIndicesDiscarded, acIndicesDiscarded, discardedSeqNums, isDiscarded] = discard(obj, currentTime, varargin)
        %discard Discard MPDUs from queues due to lifetime expiry or retry limit
        %exhaust or transmission success
        %
        %   [NODEINDICESDISCARDED, ACINDICESDISCARDED, DISCARDEDSEQNUMS] =
        %   discard(OBJ, CURRENTTIME) discards the MPDUs in all transmission queues
        %   and retry buffers, whose frame retry counter has reached
        %   ShortRetryLimit or MPDU lifetime has expired.
        %
        %   NODEINDICESDISCARDED is an array of node indices within queue (per
        %   node, per AC) for which packets have been discarded. Values in the
        %   array greater than 0 indicate valid values and 0 indicates an invalid
        %   value.
        %
        %   ACINDICESDISCARDED is an array of access category indices within queue
        %   (per node, per AC) for which packets have been discarded. Values in the
        %   array at same index as valid NODEINDICESDISCARDED are valid AC indices
        %   values. Size of ACINDICESDISCARDED is same as the size of
        %   NODEINDICESDISCARDED.
        %
        %   DISCARDEDSEQNUMS is an array of size M-by-N, M is equal to the number
        %   of rows in NODEINDICESDISCARDED and ACINDICESDISCARDED. Each row
        %   contains discarded sequence numbers for a node, AC pair.
        %   nodeIndicesDiscarded(rowNum) gives the Node ID.
        %   acIndicesDiscarded(rowNum) gives the AC index. N is the maximum queue
        %   length. Values other than -1 indicate valid sequence numbers.
        %
        %   CURRENTTIME is the simulation time in nanoseconds.
        %
        %   [.., ISDISCARDED] = discard(OBJ, CURRENTTIME, NODEIDLIST, ACLIST,
        %   RETRYBUFFERINDEXLIST) discards the MPDUs in the queues for nodes
        %   specified in NODEIDLIST, ACLIST and RETRYBUFFERINDEXLIST. MPDU is
        %   discarded if its frame retry counter has reached ShortRetryLimit or its
        %   lifetime has expired.
        %
        %   ISDISCARDED is a logical array where each element represents whether
        %   packet is discarded or not. Each two dimensional array corresponds to
        %   packets in retry buffers of a specific node. Each element indicates
        %   whether the packet in corresponding retry buffer is discarded or not.
        %
        %   NODEIDLIST is an array of IDs of nodes for which packets must be
        %   discarded.
        %
        %   ACLIST is an array of access category indices corresponding to the node
        %   IDs from which packets must be discarded.
        %
        %   RETRYBUFFERINDEXLIST is an array of retry buffer indices corresponding
        %   to nodes for which packets must be discarded.
        %
        %   [.., ISDISCARDED] = discard(OBJ, CURRENTTIME, NODEID, AC,
        %   RETRYBUFFERINDEX, PKTINDICESTODISCARD) discards the MPDUs at given
        %   indices in the given queue. Also discards the MPDUs whose frame retry
        %   counter has reached ShortRetryLimit or MSDU lifetime has expired.
        %
        %   DISCARDINDICES is an array containing the indices of packets to be
        %   discarded corresponding to node ID and AC.

        % Initialize to defaults
        packetIndicesToDiscard = []; % Packet indices to be discarded (input)
        % Indication that tx in progress flag corresponding to a retry buffer must be reset
        resetTxInProgress = false;
        isDiscarded = [];

        if ~isempty(varargin) % Node IDs and AC indices are given
            [~, qRowIndices] = ismember(varargin{1}, obj.DestinationNodeIDs);
            qColIndices = varargin{2};
            retryBufferIndices = varargin{3};
            % If node IDs and AC indices are given as input to discard, it means
            % discard is called for specific destination and AC after transmission.
            % Hence, reset the tx in progress flag.
            resetTxInProgress = true;
            isDiscarded = false(obj.MaxQueueLength, numel(retryBufferIndices), numel(qRowIndices));

            if nargin == 6 % Discard indices are also given
                packetIndicesToDiscard = varargin{4};
            end
        else
            % To iterate over all queues by default, replicate queue row indices for
            % each queue column index and vice versa
            numNodes = size(obj.RetryBuffers, 1); % Number of rows in RetryBuffers correspond to number of nodes
            qRowIndices = reshape(repmat((1:numNodes), obj.MaxACs, 1), 1, []);
            qColIndices = repmat(1:obj.MaxACs, 1, numNodes);
            retryBufferIndices = 1:obj.NumRetryBuffers;
        end
        discardedSeqNums = -1*ones(numel(qRowIndices), obj.MaxQueueLength);
        nodeIndicesDiscarded = zeros(numel(qRowIndices), 1); % Actual discarded node indices in queue
        acIndicesDiscarded = zeros(numel(qRowIndices), 1); % Actual discarded AC indices in queue

        nonzeroRetryBuffer = any(obj.RetryBufferLengths, 'all');

        for qIdx = 1:numel(qRowIndices)
            nodeIdx = qRowIndices(qIdx);
            ac = qColIndices(qIdx);
            packetDiscardedFromRetryBuff = false;
            totalDiscardCount = 0;

            % Check Retry Queues for discard conditions
            if nonzeroRetryBuffer
                for buffIdx = 1:numel(retryBufferIndices)
                    retryBuffIdx = retryBufferIndices(buffIdx);
                    if resetTxInProgress
                        obj.RetryBufferTxInProgress(nodeIdx, ac, retryBuffIdx) = false;
                    end

                    if (obj.RetryBufferLengths(nodeIdx, ac, retryBuffIdx) && ~obj.RetryBufferTxInProgress(nodeIdx, ac, retryBuffIdx))
                        % Find indices of MPDUs present in retry buffers
                        retryMPDUIndices = obj.RetryMPDUIndices{nodeIdx, ac, retryBuffIdx};
                        numRetryMPDUIndices = numel(retryMPDUIndices);
                        indicesToDiscard = zeros(numel(retryMPDUIndices), 1);
                        discardCount = 0;

                        for idx = 1:numRetryMPDUIndices
                            retryMPDUIdx = retryMPDUIndices(idx); % Index of MPDU in retry buffer

                            % Check for discard conditions for packets which are not already discarded
                            % 1. Frame retry counter exhaust
                            % 2. MSDU lifetime expired
                            retryBufMPDU = obj.RetryBuffers(nodeIdx, ac, retryBuffIdx).MPDUs(retryMPDUIdx);
                            if (retryBufMPDU.Metadata.FrameRetryCount == obj.ShortRetryLimit || ...
                                    (currentTime - round(retryBufMPDU.Metadata.MACEntryTime*1e9) >= obj.MSDUMaxLifetime)) || ...
                                    (~isempty(packetIndicesToDiscard) && any(idx == packetIndicesToDiscard)) % Discard the index provided in input
                                discardCount = discardCount + 1;
                                indicesToDiscard(discardCount) = retryMPDUIdx;
                                if strcmp(retryBufMPDU.Header.FrameType, 'QoS Data')
                                    totalDiscardCount = totalDiscardCount + 1;
                                    discardedSeqNums(qIdx, totalDiscardCount) = retryBufMPDU.Header.SequenceNumber;
                                end
                            end
                        end

                        tempIsDiscarded = false(obj.MaxQueueLength, 1);
                        if discardCount > 0
                            % Discard packets from retry buffer
                            discardPackets(obj, nodeIdx, ac, retryBuffIdx, indicesToDiscard, discardCount, 1);
                            % Return the indices of discarded packets w.r.t indices which are not yet
                            % discarded
                            tempIsDiscarded = ismember(retryMPDUIndices, indicesToDiscard(1:discardCount));
                            tempIsDiscarded = reshape(tempIsDiscarded, [], 1); % Reshape as column vector
                            packetDiscardedFromRetryBuff = true;
                        end
                        if nargout > 3
                            isDiscarded(1:numel(tempIsDiscarded), buffIdx, qIdx) = tempIsDiscarded;
                        end
                    end
                end
            end

            packetDiscardedFromTxMgmtQ = false; % Flag indicating at least one packet is discarded from management queue

            % Check Management Queues for discard conditions
            if ac == 4
                while obj.TxManagementQueueLengths(nodeIdx) && ... % Tx Queue is non-empty
                        ~(obj.WriteIndicesManagementQ(nodeIdx) == obj.ReadIndicesManagementQ(nodeIdx)) % Did not reach end of queue
                    % Check for discard conditions
                    % 1. Frame retry counter exhaust
                    % 2. MSDU lifetime expired
                    mgtMPDU = obj.TxManagementQueues(nodeIdx, obj.ReadIndicesManagementQ(nodeIdx));
                    if mgtMPDU.Metadata.FrameRetryCount == obj.ShortRetryLimit || ...
                            (currentTime - round(mgtMPDU.Metadata.MACEntryTime*1e9) >= obj.MSDUMaxLifetime)
                        % Advance the read index of queue to indicate packet is discarded
                        obj.ReadIndicesManagementQ(nodeIdx) = obj.ReadIndicesManagementQ(nodeIdx) + 1;
                        % Read index must be reset to 1 after reaching maximum queue length.
                        if obj.ReadIndicesManagementQ(nodeIdx) > obj.MaxQueueLength
                            obj.ReadIndicesManagementQ(nodeIdx) = 1;
                        end
                        % Decrement transmission queue length
                        obj.TxManagementQueueLengths(nodeIdx) = obj.TxManagementQueueLengths(nodeIdx) - 1;
                        % Remove MSDU length of the packet from 'MSDULengths' property
                        packetDiscardedFromTxMgmtQ = true;
                    else
                        % If an MPDU without satisfying either of the discard conditions is found,
                        % there is no need to check remaining MPDUs. As the queue is a FIFO queue,
                        % frame retry count and MAC entry time of these MPDUs will be '<=' and '>='
                        % respectively to that of current packet.
                        break;
                    end
                end
            end

            packetDiscardedFromTxQ = false; % Flag indicating at least one packet is discarded from data queue
            msduLengthsIndex = 1; % Index in 'MSDULengths' property corresponding to packet at read index

            % Check Normal Queues for discard conditions
            while obj.TxQueueLengths(nodeIdx, ac) && ... % Tx Queue is non-empty
                    ~(obj.WriteIndices(nodeIdx, ac) == obj.ReadIndices(nodeIdx, ac)) % Did not reach end of queue
                % Check for discard conditions
                % 1. Frame retry counter exhaust
                % 2. MSDU lifetime expired
                dataMPDU = obj.TxQueues(nodeIdx, ac, obj.ReadIndices(nodeIdx, ac));
                if dataMPDU.Metadata.FrameRetryCount == obj.ShortRetryLimit || ...
                        (currentTime - round(dataMPDU.Metadata.MACEntryTime*1e9) >= obj.MSDUMaxLifetime)
                    % Advance the read index of queue to indicate packet is discarded
                    obj.ReadIndices(nodeIdx, ac) = obj.ReadIndices(nodeIdx, ac) + 1;
                    % Read index must be reset to 1 after reaching maximum queue length.
                    if obj.ReadIndices(nodeIdx, ac) > obj.MaxQueueLength
                        obj.ReadIndices(nodeIdx, ac) = 1;
                    end
                    % Decrement transmission queue length
                    obj.TxQueueLengths(nodeIdx, ac) = obj.TxQueueLengths(nodeIdx, ac) - 1;
                    % Remove MSDU length of the packet from 'MSDULengths' property
                    obj.MSDULengths(nodeIdx, ac, msduLengthsIndex) = 0;
                    packetDiscardedFromTxQ = true;
                    msduLengthsIndex = msduLengthsIndex + 1;
                    totalDiscardCount = totalDiscardCount + 1;
                    discardedSeqNums(qIdx, totalDiscardCount) = dataMPDU.Header.SequenceNumber;
                else
                    % If an MPDU without satisfying either of the discard conditions is found,
                    % there is no need to check remaining MPDUs. As the queue is a FIFO queue,
                    % frame retry count and MAC entry time of these MPDUs will be '<=' and '>='
                    % respectively to that of current packet.
                    break;
                end
            end

            if packetDiscardedFromTxQ
                % Update MSDULengths array
                msduLengths = obj.MSDULengths(nodeIdx, ac, :);
                validMSDULengths = nonzeros(msduLengths);
                obj.MSDULengths(nodeIdx, ac, :) = [validMSDULengths; ...
                    zeros(obj.MaxQueueLength - numel(validMSDULengths), 1)];
            end

            if packetDiscardedFromTxQ || packetDiscardedFromTxMgmtQ || packetDiscardedFromRetryBuff
                nodeIndicesDiscarded(qIdx) = nodeIdx;
                acIndicesDiscarded(qIdx) = ac;
            end
        end
    end

    function queueIdx = expandQueues(obj, destNodeID)
        %expandQueues Expand queues and associated context
        %
        %   QUEUEIDX = expandQueues(OBJ, DESTNODEID) expands existing queues
        %   dynamically by size one to accommodate one extra node.
        %
        %   OBJ is an object of type QueueManager.

        % Store the destination node ID
        obj.DestinationNodeIDs(end+1) = destNodeID;
        queueIdx = numel(obj.DestinationNodeIDs);

        % Transmission queue and context
        obj.TxQueues(end+1, :, :) = obj.Packet;
        obj.TxManagementQueues(end+1, :) = obj.Packet;
        obj.TxQueueLengths(end+1, :) = 0;
        obj.TxManagementQueueLengths(end+1) = 0;
        obj.WriteIndices(end+1, :) = 1;
        obj.WriteIndicesManagementQ(end+1) = 1;
        obj.ReadIndices(end+1, :) = 1;
        obj.ReadIndicesManagementQ(end+1) = 1;
        obj.MSDULengths(end+1, :, :) = 0;

        % Retransmission queue and context
        obj.RetryBuffers(end+1, :, :) = obj.PacketsToAggregate;
        obj.RetryBufferLengths(end+1, :, :) = 0;
        obj.RetryMPDUIndices(end+1, :, :) = {[]};
        obj.RetryMSDULengths(end+1, :, :) = {[]};
        obj.RetryBufferTxInProgress(end+1, :, :) = false;
        obj.RetryBufferIndices(end+1, :) = 1;
        obj.IsRetransmission(end+1, :, :) = false;
    end

    function queueObj = findStationACQueue(obj, nodeID, acIdx)
        % Return the object if queue for specified node and AC contains data

        queueObj = [];
        if any(nodeID == obj.DestinationNodeIDs)
            nodeIdx = find(nodeID == obj.DestinationNodeIDs);
            if acIdx == 4
                mgmtQLength = obj.TxManagementQueueLengths(nodeIdx);
            else
                mgmtQLength = 0;
            end
            if (obj.TxQueueLengths(nodeIdx, acIdx) + mgmtQLength + sum(obj.RetryBufferLengths(nodeIdx, acIdx, :))) > 0
                % Return queue object if data is present for the specified node in given AC
                queueObj = obj;
            end
        end
    end

    function dstIDs = getDestinationIDs(obj)
        % Return the destination node IDs for which queues are maintained

        dstIDs = obj.DestinationNodeIDs;
    end

    function [retryBufferLength, retryBufferIndices] = getAvailableRetryBuffer(obj, nodeIDs, acIndices)
        % Return the number of packets in retry buffer available for transmission
        % and the corresponding retry buffer indices

        if nargin == 1 % Return required output for all nodes and all ACs
            numNodes = size(obj.TxQueueLengths, 1);
            nodeIndices = 1:numNodes;
            numACs = 4;
            acIndices = 1:4;
        else % Return required output for given node and AC
            numNodes = numel(nodeIDs);
            [~, nodeIndices] = ismember(nodeIDs, obj.DestinationNodeIDs);
            numACs = numel(acIndices);
        end

        retryBufferLength = zeros(numNodes, numACs);
        retryBufferIndices = zeros(numNodes, numACs);

        for nodeIdx = 1:numNodes
            for acIdx = 1:numACs
                for retryBuffIdx = 1:obj.NumRetryBuffers
                    if obj.RetryBufferLengths(nodeIndices(nodeIdx), acIndices(acIdx), retryBuffIdx) && ...
                            ~obj.RetryBufferTxInProgress(nodeIndices(nodeIdx), acIndices(acIdx), retryBuffIdx)
                        % Find the retry buffer which has valid packet for retransmission and whose
                        % packets are not already being transmitted in other links
                        retryBufferLength(nodeIdx, acIdx) = obj.RetryBufferLengths(nodeIndices(nodeIdx), acIndices(acIdx), retryBuffIdx);
                        retryBufferIndices(nodeIdx, acIdx) = retryBuffIdx;
                        break;
                    end
                end
            end
        end
    end

    function numPackets = numPacketsWithTxInProgress(obj)
        % Return the number of packets whose transmission is in progress

        numNodes = size(obj.RetryBuffers, 1);
        numPackets = zeros(numNodes, 4);
        numRetryBuffers = obj.NumRetryBuffers;

        if numRetryBuffers > 1
            retryBufferLengths = obj.RetryBufferLengths;
            retryBufferTxInProgress = obj.RetryBufferTxInProgress;

            for nodeIdx = 1:numNodes
                for acIdx = 1:4
                    availRetryBuffLength = 0;
                    for retryBuffIdx = 1:numRetryBuffers
                        if retryBufferLengths(nodeIdx, acIdx, retryBuffIdx) && retryBufferTxInProgress(nodeIdx, acIdx, retryBuffIdx)
                            % Sum of packets whose transmission is in progress
                            availRetryBuffLength = availRetryBuffLength + retryBufferLengths(nodeIdx, acIdx, retryBuffIdx);
                        end
                    end
                    numPackets(nodeIdx, acIdx) = availRetryBuffLength;
                end
            end
        end
    end

    function numMgtFrames = numManagementFramesInRetryBuffer(obj, nodeIdx)
        % Retrieves the number of MMPDUs from the retry buffer

        numMgtFrames = 0;
        ac = 4;
        retryBuffersLengths = obj.RetryBufferLengths(nodeIdx, ac, :);

        for retryBufferIdx = 1:numel(retryBuffersLengths)
            numFrames = retryBuffersLengths(retryBufferIdx);

            if numFrames
                retryIndices = obj.RetryMPDUIndices{nodeIdx, ac, retryBufferIdx}; % Find the indices that are not discarded
                mpdus = obj.RetryBuffers(nodeIdx, ac, retryBufferIdx).MPDUs;
                for idx = 1:numFrames
                    % All the frames that are not data frame must be
                    % management frames
                    if ~wlan.internal.utils.isDataFrame(mpdus(retryIndices(idx)))
                        numMgtFrames = numMgtFrames + 1;
                    end
                end
            end
        end
    end

    function msduLengths = getMSDULengthsinTxQueues(obj, nodeID, acIdx)
        % Return MSDU lengths of packets in transmission queues

        nodeIdx = nodeID == obj.DestinationNodeIDs;
        msduLengths = obj.MSDULengths(nodeIdx, acIdx, :);
    end

    function retryMSDULengths = getMSDULengthsInRetryBuffer(obj, nodeID, acIdx, retryBufferIdx)
        % Return MSDU lengths of packets in retry buffer specified by buffer index

        nodeIdx = nodeID == obj.DestinationNodeIDs;
        retryMSDULengths = obj.RetryMSDULengths{nodeIdx, acIdx, retryBufferIdx};
    end

    function isRetry = isRetransmission(obj, nodeID, ac, retryBufferIndex)
        nodeIdx = find(nodeID == obj.DestinationNodeIDs);
        isRetry = obj.IsRetransmission(nodeIdx, ac, retryBufferIndex);

        % Set the flag to true after initial transmission
        if ~isRetry
            obj.IsRetransmission(nodeIdx, ac, retryBufferIndex) = true;
        end
    end

    function totalMSDULengths = totalMSDULengthsInTxQueuesPerAC(obj)
        % Return the total MSDU lengths in each AC in Tx queues

        totalMSDULengths = sum(obj.MSDULengths, [1 3]);
    end


    function totalRetryMSDULengths = totalMSDULengthsInRetryBufferPerAC(obj)
        % Return the total MSDU lengths in each AC in retry buffers

        totalRetryMSDULengths = zeros(1, obj.MaxACs);
        for acIdx = 1:obj.MaxACs
            temp = 0;
            for nodeIdx = 1:size(obj.TxQueueLengths, 1)
                for retryBuffIdx = 1:obj.NumRetryBuffers
                    retryMSDULengths = obj.RetryMSDULengths{nodeIdx, acIdx, retryBuffIdx};
                    temp = temp + sum(retryMSDULengths);
                end
            end
            totalRetryMSDULengths(acIdx) = temp;
        end
    end
end
end

