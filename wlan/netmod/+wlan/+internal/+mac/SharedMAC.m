classdef SharedMAC < handle
    %SharedMAC Create a WLAN shared MAC object
    %
    %   Note: This is an internal undocumented class and its API and/or
    %   functionality may change in subsequent releases.
    %
    %   OBJ = wlan.internal.mac.SharedMAC(MAXQUEUELENGTH, MAXSUBFRAMES) creates
    %   a WLAN shared MAC object, OBJ, for a node. In the context of a
    %   multi-link device (MLD), this object handles shared functionality
    %   between the links. In the context of a non-MLD, this object handles
    %   functionality specific to a device. MAXQUEUELENGTH is the maximum
    %   length of queues in SharedMAC and MAXSUBFRAMES is the maximum number of
    %   frames that can be aggregated.
    %
    %   SharedMAC properties:
    %   ShortRetryLimit             - Maximum number of transmission attempts
    %                                 for a frame
    %   NumLinks                    - Number of links in a multi-link device
    %                                 (MLD)
    %   IsMLD                       - Flag to indicate MLD shared MAC
    %   MLDMACAddress               - MAC address of MLD

    %   Copyright 2023-2025 The MathWorks, Inc.

    properties
        %ShortRetryLimit Maximum number of transmission attempts for a frame
        %   Specify the maximum number of transmission attempts of a frame as an
        %   integer in the range [1, 65535]. The default value is 7.
        ShortRetryLimit = 7;

        %NumLinks Number of links in an MLD
        %   Specify the number of links in an MLD as an integer in the range [1,
        %   15], in case of MLD shared MAC. In case of multi-band device, the value
        %   is 1. The default value is 1.
        NumLinks = 1;

        %IsMLD Flag to indicate MLD shared MAC
        %   Set this flag to true to indicate that the device is an MLD. The
        %   default value is false.
        IsMLD = false;

        %MLDMACAddress MAC address of MLD
        %   Specify MAC address of the MLD as a 12-element character vector or
        %   string scalar denoting a 6-octet hexadecimal value. This property is
        %   applicable only when IsMLD property is set to true. The default value
        %   is '000000000000'.
        MLDMACAddress = '000000000000';

        %EMLPaddingDelay Padding delay to include in an initial control frame (ICF)
        %sent to an EMLSR STA
        %   EMLPaddingDelay is a scalar that contains padding delay in nanoseconds
        %   to include in ICF (MU-RTS) frame sent as first frame of frame exchange
        %   sequence to an EMLSR STA. This property is applicable at an EMLSR STA.
        %   The default value is 0.
        EMLPaddingDelay = 0;

        %EMLTransitionDelay Delay after which all links switch to listening
        %operation
        %   EMLTransitionDelay is a scalar that contains delay in nanoseconds after
        %   which all links switch to listening state after end of frame exchange
        %   in any one of the EMLSR links. This property is applicable at an EMLSR
        %   STA. The default value is 0.
        EMLTransitionDelay = 0;
    end

    properties(Hidden)
        %EDCAQueues Queue management handle object
        %   EDCAQueues represents a WLAN MAC Queue management object.
        EDCAQueues;

        %MSDUMaxLifetime Maximum amount of time to retain an MSDU in queue, after
        %which it is discarded
        %   MSDUMaxLifetime is a scalar that contains the maximum time allowed to
        %   retain an MSDU in nanoseconds, starting from its entry into MAC queue.
        %   After this time, MSDU will be discarded from MAC queue. This value is
        %   applicable for all access categories.
        MSDUMaxLifetime = 512000e3; % 500 TUs = 500 * 1024 microseconds

        %Link2ACMap Map maintaining the list of ACs that can be transmitted in each
        %link
        %   Link2ACMap is a cell array of size 1 x N, where N is the number of
        %   links. Each element contains the ACs mapped to the corresponding link.
        Link2ACMap;

        %RemoteSTAInfo Contains information of associated STAs, associated AP
        %or peer mesh, or other APs detected in the network
        %   This property is an array of structures of size N x 1. N is the number
        %   of associated STAs in case of AP. N equals 1 in case of STA. Each
        %   structure contains following fields:
        %     Mode            - Operating mode of the node indicating if it is a 
        %                       STA, AP, mesh
        %     NodeID          - Node identifier of associated STA or AP
        %     MACAddress      - MAC address of associated STA or AP. Contains one
        %                       or multiple addresses if STA and AP are MLDs due to
        %                       multilink
        %     DeviceID        - Device index or link index/indices on which
        %                       AP is connected to the STA or vice-versa
        %     AID             - Association identifier (AID) assigned to STA.
        %                       Not applicable for AP.
        %     IsMLD           - Flag indicating whether associated STA or AP is
        %                       a multilink device (MLD)
        %     EnhancedMLMode  - Scalar indicating multilink operating mode.
        %                       Applicable only when the STA is an MLD. 0 and 1
        %                       represents STR and EMLSR respectively. Not
        %                       applicable for AP.
        %     NumEMLPadBytes  - Number of padding bytes to include in initial
        %                       control frame (ICF). Applicable only for EMLSR STA.
        %   In case of mesh nodes, this property contains information of peer mesh
        %   nodes. Applicable fields for mesh are NodeID (peer mesh node ID),
        %   MACAddress (peer mesh node MAC address) and DeviceID (device ID on
        %   which a mesh node is connected to its peer mesh node).
        RemoteSTAInfo = struct([]);

        %CurrentEMLSRTxSTA Node ID of the EMLSR STA to which transmission is
        %happening on a link
        %   This property is applicable in case of an AP MLD and is an array of
        %   size N-by-1, where N is the number of links.
        CurrentEMLSRTxSTA;

        %CurrentEMLSRRxSTA Node ID of the EMLSR STA from which reception is
        %happening on a link
        %   This property is applicable in case of an AP MLD and is an array of
        %   size N-by-1, where N is the number of links.
        CurrentEMLSRRxSTA;

        %ActiveEMLSRLink Flag to indicate that an EMLSR link is active
        %   This property is applicable in case of an STA MLD operating in EMLSR
        %   mode and is an array of size N-by-1, where N is the number of links.
        %   When a link turns active, set the corresponding element to true.
        ActiveEMLSRLink;

        %NumPadBytesICF Number of padding bytes in ICF (MU-RTS frame)
        %   This property is applicable in case of EMLSR STA MLD.
        NumPadBytesICF = 0;

        %BroadcastTxInProgress Flag to indicate broadcast data transmission is in
        %progress at AP
        %   This property is applicable in case of an AP MLD which is associated
        %   with at least one EMLSR STA.
        BroadcastTxInProgress;

        %LastTBTT Last target beacon transmission time (in nanoseconds)
        LastTBTT;

        %NextTBTT Next target beacon transmission time (in nanoseconds)
        NextTBTT;

        %IsEDCAParamsUpdated Logical array indicating if EDCA parameters
        %are updated for each link
        %   This property is an array of size M-by-M where each row is a
        %   bitmap used to determine whether to update EDCA Parameter Set,
        %   Basic Multilink, and Reduced Neighbor Report Information
        %   Element (IE) in the beacon frame sent in the corresponding
        %   link. M is the number of links in the MLD. If the EDCA
        %   contention parameters (CWMin, CWMax and AIFS) of any link are
        %   updated, all the elements in the column corresponding to that
        %   link must be set to true. The beacon frame transmitted by other
        %   links must update their IEs to reflect this update. For
        %   non-MLD devices, M=1. For MLD devices, M>=1.
        IsEDCAParamsUpdated;

        %EDCAParamsCount Store update count of EDCA parameters of each link
        %   This property is an array of size M-by-1 where each element
        %   contains the update count of EDCA contention parameters (CWMin,
        %   CWMax and AIFS) for each link. M is the number of links in the
        %   MLD. For non-MLD devices, M=1. For MLD devices, M>=1.
        EDCAParamsCount;

        %BSSIDList Store the BSSID of the APs present in this device
        %   This property is an array of size M-by-12 where each row contains the
        %   BSSID of APs present in this device. In case of non-MLD, only one
        %   address is present (M=1). In case of MLD, addresses for M links are
        %   present (M>=1).
        BSSIDList;

        %BandAndChannel Operating frequency band and channel number of each link
        %   This property is an array of size M-by-2 where each row contains the
        %   operating frequency band and channel of links present in this device.
        %   In case of non-MLD, only one row is present (M=1). In case of MLD,
        %   bands and channels for M links are present (M>=1).
        BandAndChannel = [5, 36];

        %PrimaryChannel Channel number of primary 20 MHz of each link
        %   This property is an array of size M-by-1 where each element contains
        %   the channel number of primary 20 MHz of links present in this device.
        %   In case of non-MLD, only one element is present (M=1). In case of MLD,
        %   primary channel numbers for M links are present (M>=1).
        PrimaryChannel;
    end

    properties (WeakHandle)
        %MAC EDCA MAC layer handle object
        %   MAC represents the WLAN EDCA MAC layer object(s) of type
        %   wlan.internal.mac.edcaMAC present in a device. In case of non-MLD, each
        %   device has a shared MAC and EDCA MAC. So, this property holds a scalar
        %   object. In case of MLD, each device has one shared MAC and can have
        %   more than one EDCA MAC (each corresponding to a link). So, this
        %   property can be a scalar or vector of objects.
        MAC wlan.internal.mac.edcaMAC;
    end

    % Block Ack context for transmission window at originator
    properties(Hidden)
        %WinStartO Starting sequence number of the transmission window at
        %originator
        %   WinStartO is an array of size N-by-5 where N is the number of nodes
        %   with which block ack session is established. First column contains node
        %   IDs and columns 2 through 5 contain starting sequence number
        %   corresponding to AC values of 0-3.
        WinStartO = zeros(0, 5);

        %WinStatusO Status of sequence numbers in the transmission window at
        %originator
        %   WinStatusO is a cell array of size N-by-5 where N is the number of
        %   nodes with which block ack session is established. First column
        %   contains node IDs and columns 2 through 5 contain status of sequence
        %   numbers in the transmission window corresponding to AC values of 0-3.
        %   If a sequence number is discarded, corresponding bit in the status is
        %   set to 1.
        WinStatusO = cell(0, 5);
    end

    properties(Constant)
        % Size of transmission window at block ack originator
        WinSizeO = 1024;
    end

    % Sequence number streams
    properties(Hidden)
        %SNSQoSData Sequence number stream for unicast QoS Data frames
        %   Sequence number stream (counter) for individually addressed QoS Data
        %   frames. This corresponds to SNS2 of Table 10-5 in IEEE Std 802.11-2020.
        %   First column corresponds to receiver node ID and remaining 4 columns
        %   correspond to sequence counter for 4 ACs.
        SNSQoSData = zeros(1, 5);

        %SNSBaseline Sequence number stream for group addressed QoS Data
        %frames or non-time priority, non-QMF management frames
        %   Sequence number stream (counter) for group addressed QoS Data
        %   frames or non-time priority, non-QMF management frames. This
        %   corresponds to SNS1 of Table 10-5 in IEEE Std 802.11-2020.
        SNSBaseline = 0;

        %SNSTimePriorityMgt Sequence number stream for time priority management frames
        %   Sequence number stream (counter) for group addressed QoS Data frames.
        %   This corresponds to SNS3 of Table 10-5 in IEEE Std 802.11-2020.
        %   First column corresponds to receiver node ID and second column
        %   corresponds to sequence counter.
        SNSTimePriorityMgt = zeros(1, 2);

        %SNSQoSNull Sequence number stream for QoS Null frames
        %   Sequence number stream (counter) for QoS Null frames. This corresponds
        %   to SNS5 of Table 10-5 in IEEE Std 802.11-2020.
        SNSQoSNull = 0;

        %SNSQoSDataMLD Sequence number stream for unicast QoS Data frames
        %from an MLD to another MLD
        %   Sequence number stream (counter) for individually addressed QoS Data
        %   frames from an MLD to another MLD. This corresponds to SNS9 of Table
        %   10-5 in IEEE P802.11be/D5.0. First column corresponds to receiver
        %   node ID and remaining 4 columns correspond to sequence counter for 4
        %   ACs.
        SNSQoSDataMLD = zeros(1, 5);

        %SNSMgtMLD Sequence number stream for unicast QoS Data frames
        %from an MLD to another MLD
        %   Sequence number stream (counter) for individually addressed QoS Data
        %   frames from an MLD to another MLD. This corresponds to SNS10 of Table
        %   10-5 in IEEE P802.11be/D5.0. First column corresponds to receiver
        %   node ID and second column corresponds to sequence counter.
        SNSMgtMLD = zeros(1, 2);

        %SNSGroupcastDataMLD Sequence number stream for groupcast data frames
        %from an MLD to another MLD
        %   Sequence number stream (counter) for group addressed data frames from
        %   an MLD to another MLD. This corresponds to SNS11 of Table 10-5 in IEEE
        %   P802.11be/D5.0.
        SNSGroupcastDataMLD = 0;
    end

    % Receiver Caches
    properties(Hidden)
        %RCUnicastDataNonMLD Receiver Cache for unicast data frames when either the
        %receiver or the transmitter is a non-MLD
        %   RCUnicastDataNonMLD is a vector of size N x 4 where 4 is the number of
        %   access categories. Each row corresponds to a specific station in
        %   network. Each element is an integer in the range of [0 - 4095]
        %   representing sequence number of last received frame from corresponding
        %   node in corresponding AC. This corresponds to RC2 of Table 10-6 in IEEE
        %   802.11-2020.
        RCUnicastDataNonMLD = zeros(1, 4);

        %RCGroupcastDataMLD Receiver Cache for groupcast data frames received by an
        %MLD from another MLD
        %   This is an array with 2 columns. Elements in first column are
        %   transmitter node IDs. Elements in 2nd column are the last received
        %   sequence numbers. This corresponds to RC16 of Table 10-6 in IEEE
        %   P802.11be/D5.0.
        RCGroupcastDataMLD = zeros(0, 2);

        %RCUnicastDataMLD Receiver Cache for unicast data frames received by an MLD
        %from another MLD
        %   This is a cell array with 3 columns. Elements in first column are
        %   transmitter node IDs. Elements in the 2nd column are the access
        %   categories and in the 3rd column are set of last received sequence
        %   numbers. This corresponds to RC14 of Table 10-6 in IEEE P802.11be/D5.0.
        RCUnicastDataMLD = cell(0, 3);

        %RCUnicastManagementNonMLD Receiver Cache for unicast management frames
        %received by a non-MLD
        %   This is a cell array with 2 columns. Elements in first column are
        %   transmitter node IDs. Elements in the 2nd column set of last received
        %   sequence numbers. This corresponds to RC4 of Table 10-6 in IEEE
        %   802.11-2020.
        RCUnicastManagementNonMLD = cell(0, 2);

        %RCUnicastManagementMLD Receiver Cache for unicast management frames
        %received by an MLD from another MLD
        %   This is a cell array with 2 columns. Elements in first column are
        %   transmitter node IDs. Elements in the 2nd column are set of last
        %   received sequence numbers. This corresponds to RC15 of Table 10-6 in
        %   IEEE P802.11be/D5.0.
        RCUnicastManagementMLD = cell(0, 2);
    end

    methods
        function obj = SharedMAC(maxQueueLength, maxSubframes, varargin)
            % Name-value pairs
            for idx = 1:2:numel(varargin)
                obj.(varargin{idx}) = varargin{idx+1};
            end

            % Create a WLAN MAC Queue management object
            obj.EDCAQueues = wlan.internal.mac.QueueManager(maxQueueLength, maxSubframes, ...
                NumRetryBuffers=obj.NumLinks, ShortRetryLimit=obj.ShortRetryLimit, ...
                MSDUMaxLifetime=obj.MSDUMaxLifetime, DestinationNodeIDs = 0);

            obj.CurrentEMLSRTxSTA = zeros(obj.NumLinks, 1);
            obj.CurrentEMLSRRxSTA = zeros(obj.NumLinks, 1);
            obj.ActiveEMLSRLink = false(obj.NumLinks, 1);
            obj.BroadcastTxInProgress = false(obj.NumLinks, 1);
            obj.LastTBTT = zeros(obj.NumLinks, 1);
            obj.NextTBTT = zeros(obj.NumLinks, 1);
            obj.IsEDCAParamsUpdated = zeros(obj.NumLinks, obj.NumLinks);
            obj.EDCAParamsCount = zeros(obj.NumLinks, 1);
            obj.BSSIDList = repmat('0', obj.NumLinks, 12);

            % Reference: Section 35.5.2.2.3 of IEEE P802.11be/D5.0
            if obj.EMLPaddingDelay == 0
                obj.NumPadBytesICF = 0;
            else
                % To send an ICF (MU-RTS frame) Non-HT PHY format is used with MCS = 4. Use
                % the same config object to determine number of padding bytes required in
                % ICF.
                mcsTable = wlan.internal.getRateTable(wlanNonHTConfig(MCS=4));
                ndbps = mcsTable.NDBPS;
                if obj.EMLPaddingDelay == 32e3
                    padDelay = 1;
                elseif obj.EMLPaddingDelay == 64e3
                    padDelay = 2;
                elseif obj.EMLPaddingDelay == 128e3
                    padDelay = 3;
                else % 256e3
                    padDelay = 4;
                end
                mPad = pow2(padDelay+2);
                obj.NumPadBytesICF = (ndbps*mPad)/8;
            end
        end

        function mpdu = assignSequenceNumber(obj, mpdu, isMLDReceiver)
            % Assign sequence number to the packet using appropriate sequence number space

            if nargin < 3
                isMLDReceiver = false;
            end

            switch mpdu.Header.FrameType
                case 'QoS Data'
                    mpdu = assignSequenceNumData(obj, mpdu, isMLDReceiver);
                case 'QoS Null'
                    mpdu = assignSequenceNumQoSNull(obj, mpdu);
                case 'Beacon'
                    mpdu = assignSequenceNumBaseline(obj, mpdu);
                case 'Action'
                    % NOTE: Action frames are not yet supported
                    if strcmp(mpdu.Header.ActionType, {'CSI', 'Non compressed Beamforming', 'Compressed Beamforming', 'ASEL Indices Feedback', 'VHT Compressed Beamforming'})
                        mpdu = assignSequenceNumTimePriorityMgt(obj, mpdu);
                    else
                        isUnicast = ~wlan.internal.utils.isGroupAddress(mpdu.Header.Address1);
                        isManagement = ~wlan.internal.utils.isDataFrame(mpdu); % Assume sequence number assignment is called only for data/management frames
                        if isUnicast && isManagement && obj.IsMLD && isMLDReceiver
                            mpdu = assignSequenceNumUnicastMgtMLD(obj, mpdu);
                        else
                            mpdu = assignSequenceNumBaseline(obj, mpdu);
                        end
                    end
                otherwise
                    if nargin < 3
                        rxIdxLogical = (mpdu.Metadata.ReceiverID == [obj.RemoteSTAInfo(:).NodeID]);
                        isMLDReceiver = obj.RemoteSTAInfo(rxIdxLogical).IsMLD;
                    end
                    isUnicast = ~wlan.internal.utils.isGroupAddress(mpdu.Header.Address1);
                    isManagement = ~wlan.internal.utils.isDataFrame(mpdu); % Assume sequence number assignment is called only for data/management frames
                    if isUnicast && isManagement && obj.IsMLD && isMLDReceiver
                        mpdu = assignSequenceNumUnicastMgtMLD(obj, mpdu);
                    else
                        mpdu = assignSequenceNumBaseline(obj, mpdu);
                    end
            end
        end

        function mpdu = assignSequenceNumData(obj, mpdu, isMLDReceiver)
            % Assign sequence number to a data packet using defined sequence number spaces

            ac = wlan.internal.Constants.TID2AC(mpdu.Header.TID+1);
            % Groupcast frames
            if mpdu.Metadata.ReceiverID == 65535
                % The only groupcast currently supported is broadcast. Hence, check for
                % broadcast ID.
                if obj.IsMLD % Multilink device (MLD)
                    mpdu.Header.SequenceNumber = obj.SNSGroupcastDataMLD;
                    % Increment and wrap around
                    obj.SNSGroupcastDataMLD = rem(mpdu.Header.SequenceNumber+1, 4096);
                else % Not MLD
                    mpdu.Header.SequenceNumber = obj.SNSBaseline;
                    % Increment and wrap around
                    obj.SNSBaseline = rem(mpdu.Header.SequenceNumber+1, 4096);
                end
                return;
            end

            if obj.IsMLD && isMLDReceiver
                stationIdx = find(mpdu.Metadata.ReceiverID == obj.SNSQoSDataMLD(:, 1));
                % Assign Sequence Number. Add 2 for AC index because the first column
                % corresponds to receiver ID and sequence counter for ACs start from second
                % column.
                mpdu.Header.SequenceNumber = obj.SNSQoSDataMLD(stationIdx, ac+2);
                % Increment and wrap around
                obj.SNSQoSDataMLD(stationIdx, ac+2) = rem(mpdu.Header.SequenceNumber+1, 4096);
            else
                stationIdx = find(mpdu.Metadata.ReceiverID == obj.SNSQoSData(:, 1));
                % Assign Sequence Number. Add 2 for AC index because the first column
                % corresponds to receiver ID and sequence counter for ACs start from second
                % column.
                mpdu.Header.SequenceNumber = obj.SNSQoSData(stationIdx, ac+2);
                % Increment and wrap around
                obj.SNSQoSData(stationIdx, ac+2) = rem(mpdu.Header.SequenceNumber+1, 4096);
            end
        end

        function mpdu = assignSequenceNumUnicastMgtMLD(obj, mpdu)
            stationIdx = find(mpdu.Metadata.ReceiverID == obj.SNSMgtMLD(:, 1));
            % Assign Sequence Number. Add 2 for AC index because the first column
            % corresponds to receiver ID and sequence counter for ACs start from second
            % column.
            mpdu.Header.SequenceNumber = obj.SNSMgtMLD(stationIdx, 2);
            % Increment and wrap around
            obj.SNSMgtMLD(stationIdx, 2) = rem(mpdu.Header.SequenceNumber+1, 4096);
        end

        function mpdu = assignSequenceNumQoSNull(obj, mpdu)
            % Return sequence number of a QoS Null frame

            sequenceNum = obj.SNSQoSNull;
            mpdu.Header.SequenceNumber = sequenceNum;
            % Update sequence counter
            obj.SNSQoSNull = rem(sequenceNum + 1, 4096);
        end

        function mpdu = assignSequenceNumBaseline(obj, mpdu)
            % Return sequence number of a beacon frame

            sequenceNum = obj.SNSBaseline;
            mpdu.Header.SequenceNumber = sequenceNum;
            % Update sequence counter
            obj.SNSBaseline = rem(sequenceNum + 1, 4096);
        end

        function mpdu = assignSequenceNumTimePriorityMgt(obj, mpdu)
            % Return sequence number of a beacon frame

            stationIdx = find(mpdu.Metadata.ReceiverID == obj.SNSTimePriorityMgt(:, 1));
            % Assign Sequence Number. Second column holds the sequence counter.
            mpdu.Header.SequenceNumber = obj.SNSTimePriorityMgt(stationIdx, 2);
            % Increment and wrap around
            obj.SNSTimePriorityMgt(stationIdx, 2) = rem(mpdu.Header.SequenceNumber+1, 4096);
        end

        function enqueuePacket(obj, packet)
            %enqueuePacket Enqueue packet into MAC queue
            %
            %   enqueuePacket(OBJ, PACKET) enqueues packet into MAC
            %   transmission queues.
            %
            %   OBJ is an object of type SharedMAC.
            %
            %   PACKET is the packet to be enqueued. It is a structure of type
            %   wlan.internal.utils.defaultMPDU

            % Get access category of the packet
            ac = wlan.internal.Constants.TID2AC(packet.Header.TID+1);
            % Enqueue packet
            enqueue(obj.EDCAQueues, packet.Metadata.ReceiverID, ac+1, packet);
        end

        function isFull = isQueueFull(obj, receiverID, ac)
            %isQueueFull Return true if shared queue is full
            %
            %   ISFULL = isQueueFull(OBJ, RECEIVERID, AC) returns status of the
            %   shared queue for specified receiver ID and access category.
            %
            %   The function returns ISFULL as true when shared queue for specified
            %   receiver ID and access category is full. Otherwise, it returns false.
            %
            %   OBJ is an object of type SharedMAC.
            %
            %   RECEIVERID is the node ID of the receiver.
            %
            %   AC is the access category specified as an integer in the range
            %   [0, 3] representing Best Effort, Background, Video, and Voice
            %   traffic.

            isFull = true;
            acIdx = ac + 1;
            qIdx = find(receiverID == getDestinationIDs(obj.EDCAQueues));

            if isempty(qIdx) % Queues are not yet created for given receiver
                qIdx = getQIndexAndExpandContext(obj, receiverID, true);
            end

            if (obj.EDCAQueues.TxQueueLengths(qIdx, acIdx)+sum(obj.EDCAQueues.RetryBufferLengths(qIdx, acIdx, :))) ~= obj.EDCAQueues.MaxQueueLength
                isFull = false;
            end
        end

        function isFull = isManagementQueueFull(obj, receiverID)
            %isManagementQueueFull Return true if shared queue for management frames is full
            %
            %   ISFULL = isManagementQueueFull(OBJ, RECEIVERID) returns
            %   status of the shared queue of management frames for
            %   specified receiver ID and access category.
            %
            %   The function returns ISFULL as true when shared queue for specified
            %   receiver ID and access category is full. Otherwise, it returns false.
            %
            %   OBJ is an object of type SharedMAC.
            %
            %   RECEIVERID is the node ID of the receiver.

            isFull = true;
            acIdx = ac + 1;
            qIdx = find(receiverID == getDestinationIDs(obj.EDCAQueues));

            if isempty(qIdx) % Queues are not yet created for given receiver
                qIdx = getQIndexAndExpandContext(obj, receiverID, true);
            end

            numMgtFramesInRetryBuffer = numManagementFramesInRetryBuffer(obj.EDCAQueues, qIdx);
            if (obj.EDCAQueues.TxQueueLengths(qIdx, acIdx)+numMgtFramesInRetryBuffer) ~= obj.EDCAQueues.MaxQueueLength
                isFull = false;
            end
        end

        function queueIdx = getQIndexAndExpandContext(obj, receiverID, isSharedQ, linkIdx, isMLDReceiver)
            %getQIndexAndExpandContext Expand queues, scheduler context and sequence
            %number space for given receiver ID and return the queue index.
            %
            %   QUEUEIDX = getQIndexAndExpandContext(OBJ, RECEIVERID, ISSHAREDQ)
            %   expands the shared queues for given receiver with ID, RECEIVERID when
            %   ISSHAREDQ is set to true. It also expands scheduler and sequence number
            %   space context.
            %
            %   QUEUEIDX is the index to access queues for the given receiver.
            %
            %   RECEIVERID is the node ID of the receiver.
            %
            %   ISSHAREDQ is a flag indicating that shared queues must be expanded for
            %   given receiver, when set to true. Otherwise, it indicates that link
            %   queues must be expanded.
            %
            %   QUEUEIDX = getQIndexAndExpandContext(OBJ, RECEIVERID, ISSHAREDQ,
            %   LINKIDX, ISMLDRECEIVER) expands the link (EDCA MAC) queues for given
            %   receiver with ID, RECEIVERID when ISSHAREDQ is set to false. It also
            %   expands scheduler and sequence number space context.
            %
            %   LINKIDX is the index of link (EDCA MAC) in case of MLD transmitter. In
            %   case of non-MLD transmitter, as the shared MAC and EDCA MAC corresponds
            %   to a specific device, LINKIDX is specified as 1.
            %
            %   ISMLDRECEIVER is a flag indicating whether the receiver node is an MLD.
            %   The method uses this flag to create sequence number spaces for MLD and
            %   non-MLD data.

            if nargin < 4
                % Link index is not available
                linkIdx = [];
            end
            if isSharedQ
                queueObj = obj.EDCAQueues; % Handle object
            else
                queueObj = obj.MAC(linkIdx).LinkEDCAQueues; % Handle object
            end
            queueIdx = findReceiverID(obj, queueObj, receiverID);

            if isempty(queueIdx) % Queues are not present for the station
                if isSharedQ % Shared queues hold packets for MLD receivers
                    % Expand sequence number space
                    expandSNS(obj, receiverID, isSharedQ);
                    % Expand queues
                    queueIdx = expandQueues(queueObj, receiverID);
                    % Expand scheduler context
                    for idx = 1:obj.NumLinks
                        expandSchedulerContext(obj.MAC(idx).Scheduler, receiverID);
                        % Expand rate control context
                        setRateControlContext(obj, receiverID, idx, obj.MAC(idx).BasicRates);
                    end

                else % Link queues currently hold packets for non-MLD receivers
                    % isMLDReceiver flag is given as input

                    % Expand sequence number space
                    expandSNS(obj, receiverID, isMLDReceiver);
                    % Expand queues
                    queueIdx = expandQueues(queueObj, receiverID);
                    % Expand scheduler context
                    expandSchedulerContext(obj.MAC(linkIdx).Scheduler, receiverID);
                    % Expand rate control context
                    setRateControlContext(obj, receiverID, linkIdx, obj.MAC(linkIdx).BasicRates);
                end

                % Expand transmission window context
                if ~any(receiverID == obj.WinStartO(:, 1))
                    expandBATxWindowContext(obj, receiverID);
                end
            end
        end

        function stationIdx = findReceiverID(~, queueObj, receiverID)
            % Find whether queues for given receiver ID are created in the given queue
            % object

            dstStationIDs = getDestinationIDs(queueObj);
            stationIdx = find(receiverID == dstStationIDs);
        end

        function expandSNS(obj, receiverID, isMLDReceiver)
            % Expands sequence number space for given receiver

            if obj.IsMLD && isMLDReceiver
                if ~any(receiverID == obj.SNSQoSDataMLD(:, 1))
                    % Expand sequence counter
                    obj.SNSQoSDataMLD(end+1, :) = 0;
                    obj.SNSMgtMLD(end+1, :) = 0;
                    numRows = size(obj.SNSQoSDataMLD, 1);
                    % First column contains node ID of receiver
                    obj.SNSQoSDataMLD(numRows, 1) = receiverID;
                    obj.SNSMgtMLD(numRows, 1) = receiverID;
                end
            else
                % Expand sequence counter
                obj.SNSQoSData(end+1, :) = 0;
                numRows = size(obj.SNSQoSData, 1);
                % First column contains node ID of receiver
                obj.SNSQoSData(numRows, 1) = receiverID;
            end

            if ~any(receiverID == obj.SNSTimePriorityMgt(:, 1))
                % Expand sequence counter
                obj.SNSTimePriorityMgt(end+1, :) = 0;
                numRows = size(obj.SNSTimePriorityMgt, 1);
                % First column contains node ID of receiver
                obj.SNSTimePriorityMgt(numRows, 1) = receiverID;
            end
        end

        function expandBATxWindowContext(obj, receiverID)
            % Expands transmission window context at originator

            % Add a new row to WinStartO
            obj.WinStartO(end+1, :) = 0;
            obj.WinStartO(end, 1) = receiverID; % First column contains node ID of receiver
            % Add new row to WinStatusO
            obj.WinStatusO(end+1, 1) = {receiverID};
            obj.WinStatusO(end, 2:5) = repmat({zeros(1,obj.WinSizeO)}, 1, 4);
        end

        function initPreAssociationContext(obj, staInfo)
            %initPreAssociationContext Initialize association context with defaults
            %prior to association process

            % Add association information
            obj.RemoteSTAInfo = staInfo;

            % Update BSSID
            for idx = 1:obj.NumLinks
                obj.BSSIDList(idx, :) = obj.MAC(idx).BSSID;
            end
        end

        function addRemoteSTAInfo(obj, staInfo)
            % Add association information

            % Check whether unassociated yet
            isUnassociated = isscalar(obj.RemoteSTAInfo) && obj.RemoteSTAInfo.NodeID == 0;

            % Overwrite default association info when association is performed
            if isUnassociated && staInfo.NodeID ~= 0 % Association is in progress
                obj.RemoteSTAInfo = staInfo;
            else
                obj.RemoteSTAInfo = [obj.RemoteSTAInfo staInfo];
            end

            % Update BSSID
            for idx = 1:obj.NumLinks
                obj.BSSIDList(idx, :) = obj.MAC(idx).BSSID;
            end

            % Expand Per STA statistics during association
            if obj.IsMLD
                deviceIDs = staInfo.DeviceID;
                for devIdx = 1:numel(deviceIDs)
                    expandPerSTAStatistics(obj.MAC((deviceIDs(devIdx))), staInfo.NodeID);
                end
            else
                expandPerSTAStatistics(obj.MAC, staInfo.NodeID);
            end
        end

        function staInfo = getRemoteSTAInfo(obj, nodeID)
            % Get remote station info

            staInfoIdxLogical = (nodeID == [obj.RemoteSTAInfo(:).NodeID]);
            if any(staInfoIdxLogical)
                staInfo = obj.RemoteSTAInfo(staInfoIdxLogical);
            else
                staInfo = [];
            end
        end

        function setRateControlContext(obj, rxNodeID, linkIdx, basicRates)
            % Add operational device configuration
            setAssociationConfig(obj.MAC(linkIdx).RateControl, basicRates);
            setAssociationConfig(obj.MAC(linkIdx).ULRateControl, basicRates);

            % Set receiver context and add mutually supported capabilities
            apCapabilities = struct('MaxMCS',13,'MaxNumSpaceTimeStreams',8);
            staCapabilities = struct('MaxMCS',13,'MaxNumSpaceTimeStreams',8);
            capabilities = struct('MaxMCS',min(apCapabilities.MaxMCS,staCapabilities.MaxMCS), ...
                'MaxNumSpaceTimeStreams',min(apCapabilities.MaxNumSpaceTimeStreams,staCapabilities.MaxNumSpaceTimeStreams));
            setReceiverContext(obj.MAC(linkIdx).RateControl, rxNodeID, capabilities);
            setReceiverContext(obj.MAC(linkIdx).ULRateControl, rxNodeID, capabilities);
        end

        function aid = getAID(obj, staNodeID)
            % Return the AID of given STA

            aid = obj.RemoteSTAInfo(staNodeID == [obj.RemoteSTAInfo(:).NodeID]).AID;
        end

        function staID = getStationID(obj, aid)
            % Return the AID of given STA

            assocInfo = obj.RemoteSTAInfo(aid == [obj.RemoteSTAInfo(:).AID]);
            if isempty(assocInfo)
                staID = -1; % Unknown
            else
                staID = assocInfo.NodeID; 
            end
        end

        function macAddr = getMACAddress(obj, staNodeID, linkID)
            % Return the MAC address of the given STA which is associated on given
            % link. The object uses this method only for MLD nodes.

            staIdxLogical = (staNodeID == [obj.RemoteSTAInfo(:).NodeID]);
            linkIdxLogical = (linkID == [obj.RemoteSTAInfo(staIdxLogical).DeviceID]);
            macAddr = obj.RemoteSTAInfo(staIdxLogical).MACAddress(linkIdxLogical, :);
        end

        function turnOffOtherLinks(obj, activeEMLSRLinkID)
            % Indicate EDCA MACs of other links to turn off their operations

            for idx = 1:numel(obj.MAC)
                if (idx ~= activeEMLSRLinkID)
                    turnOffLink(obj.MAC(idx));
                end
            end
        end

        function turnOnOtherLinks(obj, activeEMLSRLinkID)
            % Indicate EDCA MACs of other links to turn on their operations

            for idx = 1:numel(obj.MAC)
                if (idx ~= activeEMLSRLinkID)
                    turnOnLink(obj.MAC(idx));
                end
            end
        end

        function flag = isFrameWithinBATxWindow(obj, receiverID, acIdx, frameSeqNum)
            % Check whether given sequence number is within transmission window

            flag = false;
            rowIdxLogical = (receiverID==obj.WinStartO(:, 1));
            winStartO = obj.WinStartO(rowIdxLogical, acIdx+1);
            if mod(frameSeqNum - winStartO, 4096) < obj.WinSizeO
                flag = true;
            end
        end

        function updateBATxWindowStatus(obj, receiverID, acIdx, frameSeqNums)
            % Update the status of given sequence numbers in transmission window and
            % move transmission window to first sequence number whose status is not
            % discarded

            rowIdxLogical = (receiverID==obj.WinStartO(:, 1));
            winStatusO = obj.WinStatusO{rowIdxLogical, acIdx+1};
            winStartO = obj.WinStartO(rowIdxLogical, acIdx+1);

            % Compute distance of sequence numbers from window start
            dist = mod(frameSeqNums - winStartO, 4096) + 1;
            % Find which indices are within the window (1:WindowSize)
            inWindow = (dist >= 1) & (dist <= obj.WinSizeO);           
            winStatusIndices = dist(inWindow); % Indices in winStatusO to update
            winStatusO(winStatusIndices) = 1;

            % Store out-of-window sequence numbers
            outOfWindowSeqNums = frameSeqNums(~inWindow);

            % Advancing transmission window
            [winStartO, winStatusO] = advanceBATxWindow(obj, winStartO, winStatusO);

            % Now process out-of-window sequence numbers (stored before advancing
            % transmission window)
            if ~isempty(outOfWindowSeqNums)
                dist = mod(outOfWindowSeqNums - winStartO, 4096) + 1;
                inWindow = (dist >= 1) & (dist <= obj.WinSizeO);
                winStatusIndices = dist(inWindow);
                winStatusO(winStatusIndices) = 1;

                % Advancing transmission window
                [winStartO, winStatusO] = advanceBATxWindow(obj, winStartO, winStatusO);
            end

            obj.WinStatusO{rowIdxLogical, acIdx+1} = winStatusO;
            obj.WinStartO(rowIdxLogical, acIdx+1) = winStartO;
        end

        function [winStartO, winStatusO] = advanceBATxWindow(obj, winStartO, winStatusO)
            % Advance transmission window to first sequence number whose status is 0

            firstZeroIdx = find(winStatusO == 0, 1);
            if isempty(firstZeroIdx)
                % All are acknowledged, advance window by WindowSize
                winStartO = mod(winStartO + obj.WinSizeO, 4096);
                winStatusO = zeros(1, obj.WinSizeO);
            else
                % Advance to first sequence number with zero status
                nAdvance = firstZeroIdx - 1;
                winStartO = mod(winStartO + nAdvance, 4096);
                winStatusO = [winStatusO(firstZeroIdx:end), zeros(1, nAdvance)];
            end
        end
    end
end
