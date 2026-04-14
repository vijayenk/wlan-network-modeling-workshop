classdef wlanRateControlARF < wlanRateControl
    %wlanRateControlARF Auto rate fallback (ARF) algorithm
    %   OBJ = wlanRateControlARF creates a default auto rate
    %   fallback (ARF) rate control object.
    %
    %   OBJ = wlanRateControlARF(...,Name,Value) creates an auto
    %   rate fallback (ARF) rate control object, OBJ, with the specified
    %   property Name set to the specified Value. You can specify
    %   additional name-value pair arguments in any order as (Name1,Value1,
    %   ...,NameN,ValueN).
    %
    %   wlanRateControlARF object functions:
    %
    %   selectRateParameters        - Select rate control parameters for 
    %                                 frame transmission
    %   processTransmissionStatus   - Process frame transmission status to
    %                                 perform post-transmission operations
    %   deviceConfigurationValue    - Retrieve value of the specified 
    %                                 property in the device configuration
    %   deviceConfigurationType     - Return the type of device configuration
    %                                 on which rate control is implemented
    %   bssConfigurationValue       - Retrieve value of the specified BSS
    %                                 configuration
    %   maxMCS                      - Return maximum MCS that you can select
    %   maxNumSpaceTimeStreams      - Return maximum number of space time
    %                                 streams that you can select
    %   mapReceiverToSTAContext     - Return the index for STAContext
    %                                 property corresponding to the given
    %                                 receiver
    %
    %   wlanRateControlARF properties:
    %
    %   SuccessThreshold    - Successful transmission threshold for rate increment
    %   FailureThreshold    - Failure transmission threshold for rate decrement

    %   Copyright 2024 The MathWorks, Inc.

    properties
        %SuccessThreshold Successful transmission threshold for rate increment
        %   Specify the success threshold as a scalar integer, representing the
        %   number of successful transmissions after which the rate is incremented.
        %   The default is 10.
        SuccessThreshold(1,1) {mustBeNumeric, mustBePositive, mustBeInteger} = 10;

        %FailureThreshold Transmission failure threshold for rate decrement
        %   Specify the failure threshold as a scalar integer, representing the
        %   number of transmission failures after which the rate is decremented.
        %   The default is 2.
        FailureThreshold(1,1) {mustBeNumeric, mustBePositive, mustBeInteger} = 2;
    end

    properties (Access=protected)
        %CustomContextTemplate Default custom context for each receiver
        CustomContextTemplate = struct(CurrentDataRate = 0, ...
                                    CurrentControlRateIdx = 1, ...
                                    PrevDataIncrementFlag = 0, ...
                                    PrevControlIncrementFlag = 0, ...
                                    ConsecutiveDataSuccessCount = 0, ...
                                    ConsecutiveDataFailureCount = 0, ...
                                    ConsecutiveControlSuccessCount = 0, ...
                                    ConsecutiveControlFailureCount = 0);
    end

    properties (Access=private, Dependent)
        % List of indices of Non-HT data rates supported in Basic Service Set
        BasicRateIndices
    end

    methods
        % Constructor method
        function obj = wlanRateControlARF(varargin)
            obj@wlanRateControl(varargin{:});
        end

        function rateParams = selectRateParameters(obj, txContext)
            %selectRateParameters Returns the rate parameters for frame transmission
            %
            % RATEPARAMS = selectRateParameters(OBJ, TXCONTEXT) returns the rate
            % parameters as a structure that will be used for for transmitting the
            % frame.
            %
            %   RATEPARAMS is a structure containing the rate information that is used
            %   by the node for transmitting the frame. It contains the following
            %   fields:
            %       MCS                  - Non negative integer specifying the
            %                              MCS index used for the frame transmission to
            %                              the station specified in the TXCONTEXT. This
            %                              value lies in the range of 0 to the value
            %                              returned by maxMCS method.
            %
            %       NumSpaceTimeStreams  - Positive integer specifying the number of
            %                              space-time streams for the frame
            %                              transmission to the station specified in the
            %                              TXCONTEXT. This value lies in the range
            %                              of 0 to the value returned by
            %                              maxNumSpaceTimeStreams method.
            %
            %   OBJ is an object of type wlanRateControl.
            %
            %   TXCONTEXT is a structure containing the information about the frame
            %   being transmitted and the transmission context required for the
            %   algorithm to select rate control parameters. It contains the following
            %   fields:
            %       FrameType           - Frame type for which the rate control
            %                             algorithm is invoked. It is specified as one
            %                             of "QoS Data" or "RTS".
            %
            %       ReceiverNodeID      - Node ID of the receiver to which the frame is
            %                             being transmitted. It is specified as a
            %                             scalar integer.
            %
            %       IsRetry             - Flag indicating if the frame is a
            %                             retransmission. It is specified as true if
            %                             the frame is a retransmission.
            %
            %       TransmissionFormat  - String indicating the PHY format used for
            %                             transmission format. It is specified as one
            %                             of "Non-HT", "HT-Mixed", "VHT", "HE-SU",
            %                             "HE-EXT-SU", "HE-MU", "HE-TB", or "EHT-SU".
            %                             If FrameType field value is "RTS", the
            %                             value of this field is always set to "Non-HT".
            %
            %       ChannelBandwidth    - Channel bandwidth that will be used for 
            %                             transmission. It is specified in Hz as one of
            %                             20e6, 40e6, 80e6, 160e6, or 320e6.
            %
            %       CurrentTime         - Scalar value representing current simulation
            %                             time in seconds.

            % Assign defaults
            rateParams.MCS = 0;
            rateParams.NumSpaceTimeStreams = 1;

            % Get the index of receiver node ID in the STAContext property
            rxStationIdx = mapReceiverToSTAContext(obj, txContext.ReceiverNodeID);

            if strcmp(txContext.FrameType, 'QoS Data')
                [rateParams] = getDataRate(obj, rxStationIdx, txContext);
            elseif strcmp(txContext.FrameType,'RTS')
                [rateParams] = getControlRate(obj, rxStationIdx);
            end
        end

        function processTransmissionStatus(obj, txContext, txStatusInfo)
            %processTransmissionStatus Process frame transmission status to
            %perform post-transmission operations
            %
            %   processTransmissionStatus(OBJ, TXCONTEXT, TXSTATUSINFO) handles the
            %   operations that should happen after the frame is transmitted based on
            %   the status of the recent frame transmission for which rate parameters
            %   were selected.
            %
            %   OBJ is an object of type wlanRateControl.
            %
            %   TXCONTEXT is a structure containing the information about the
            %   transmitted frame and the transmission context using which the
            %   algorithm has previously selected rate control parameters. It contains
            %   the following fields:
            %       FrameType           - Frame type for which the rate control
            %                             algorithm is invoked. It is specified as one
            %                             of "QoS Data" or "RTS".
            %
            %       ReceiverNodeID      - Node ID of the receiver to which the frame is
            %                             being transmitted. It is specified as a
            %                             scalar integer.
            %
            %       IsRetry             - Flag indicating if the frame is a
            %                             retransmission. It is specified as true if
            %                             the frame is a retransmission.
            %
            %       TransmissionFormat  - String indicating the PHY format used for
            %                             transmission format. It is specified as one
            %                             of "Non-HT", "HT-Mixed", "VHT", "HE-SU",
            %                             "HE-EXT-SU", "HE-MU", "HE-TB", or "EHT-SU".
            %                             If FrameType field value is "RTS", the
            %                             value of this field is always set to "Non-HT".
            %
            %       ChannelBandwidth    - Channel bandwidth that will be used for 
            %                             transmission. It is specified in Hz as one of
            %                             20e6, 40e6, 80e6, 160e6, or 320e6.
            %
            %       CurrentTime         - Scalar value representing current simulation
            %                             time in seconds.
            %
            %   TXSTATUSINFO is a structure containing the status of the frame
            %   transmission along with information that may be required for updating
            %   the rate table in the algorithm. It contains the following fields:
            %
            %       IsMPDUSuccess       - Vector of logical values representing the
            %                             transmission status as success or failure.
            %                             Each element in the vector corresponds to the
            %                             status of an MPDU, where true indicates a
            %                             successful transmission and false indicates a
            %                             failed transmission.
            %
            %       IsMPDUDiscarded     - Vector of logical values representing if the
            %                             frame has been discarded due to successful
            %                             transmission, retry exhaustion, or lifetime
            %                             expiry. Each element in the vector
            %                             corresponds to the discard status of an MPDU,
            %                             where true indicates that it is discarded and
            %                             false indicates that it is not discarded.
            %
            %                               When FrameType is "RTS", IsMPDUDiscarded flag 
            %                             indicates the discard status of data packets
            %                             from transmission queues.
            %
            %       CurrentTime         - Scalar value representing current simulation
            %                             time in seconds.
            %
            %       ResponseRSSI        - Scalar value indicating the signal strength of
            %                             the received response in the form of an Ack
            %                             frame, a Block Ack frame, or a CTS frame.

            % Get the index of receiver node ID in the STAContext property
            rxStationIdx = mapReceiverToSTAContext(obj, txContext.ReceiverNodeID);

            isFail = ~txStatusInfo.IsMPDUSuccess;
            if isscalar(isFail)
                txFailed = isFail;
            else
                % For an A-MPDU, consider transmission as a failure if number
                % of failed subframes is greater than number of acked subframes
                txFailed = nnz(isFail) > nnz(~isFail);
            end

            if strcmp(txContext.FrameType, 'QoS Data')
                updateDataFrameStatus(obj, txContext.ReceiverNodeID, rxStationIdx, txContext, txFailed);
            elseif strcmp(txContext.FrameType,'RTS')
                updateControlFrameStatus(obj, rxStationIdx, txContext, txFailed);
            end
        end
    end

    methods
        function value = get.BasicRateIndices(obj)
            value = find((ismember([6 9 12 18 24 36 48 54],bssConfigurationValue(obj,"BasicRates")))==1) - 1;
        end
    end

    methods(Access = private)
        % Get rate for Data frames
        function rateParams = getDataRate(obj, staIdx, txContext)
            devType = deviceConfigurationType(obj);
            if strcmp(devType, 'wlanMultilinkDeviceConfig') && strcmp(deviceConfigurationValue(obj,'Mode'), "STA") && strcmp(deviceConfigurationValue(obj,'EnhancedMultilinkMode'), "EMLSR")
                % Use sum of all NSTS for data transmissions from an EMLSR STA
                nsts = sum(deviceConfigurationValue(obj,'NumSpaceTimeStreams',AllLinks=true));
            else
                nsts = deviceConfigurationValue(obj,'NumSpaceTimeStreams');
            end
            if txContext.TransmissionFormat == "HT-Mixed"
                mcsIndex = ((nsts-1)*8) + obj.STAContext(staIdx).CustomContext.CurrentDataRate;
            else
                mcsIndex = obj.STAContext(staIdx).CustomContext.CurrentDataRate;
            end
            rateParams.MCS = mcsIndex;
            rateParams.NumSpaceTimeStreams = nsts;
        end

        % Get rate for SU control frames (RTS) transmission
        function rateParams = getControlRate(obj, staIdx)
            idx =  obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx;
            rateParams.MCS = obj.BasicRateIndices(idx);

            % Transmit with 1 space-time stream
            rateParams.NumSpaceTimeStreams = 1;
        end

        % Update transmission status for Data frames
        function updateDataFrameStatus(obj, rxNodeID, staIdx, txContext, isFail)
            % Transmission failure
            if isFail
                obj.STAContext(staIdx).CustomContext.ConsecutiveDataFailureCount = obj.STAContext(staIdx).CustomContext.ConsecutiveDataFailureCount + 1;
                obj.STAContext(staIdx).CustomContext.ConsecutiveDataSuccessCount = 0;

                % Decrement the data rate if the transmission failed
                % immediately after incrementing the data rate
                if obj.STAContext(staIdx).CustomContext.PrevDataIncrementFlag
                    decrementRate(obj, staIdx, txContext);
                    obj.STAContext(staIdx).CustomContext.ConsecutiveDataFailureCount = 0;
                    obj.STAContext(staIdx).CustomContext.PrevDataIncrementFlag = false;
                end

                % If the consecutive failure count reached threshold, decrement
                % data rate
                if (obj.STAContext(staIdx).CustomContext.ConsecutiveDataFailureCount >= obj.FailureThreshold)
                    decrementRate(obj, staIdx, txContext);
                end

            else % Successful transmission
                obj.STAContext(staIdx).CustomContext.ConsecutiveDataSuccessCount = obj.STAContext(staIdx).CustomContext.ConsecutiveDataSuccessCount + 1;
                obj.STAContext(staIdx).CustomContext.ConsecutiveDataFailureCount = 0;
                obj.STAContext(staIdx).CustomContext.PrevDataIncrementFlag = false;
                % If the consecutive success count reached threshold,
                % increment data rate
                if (obj.STAContext(staIdx).CustomContext.ConsecutiveDataSuccessCount >= obj.SuccessThreshold)
                    incrementRate(obj, rxNodeID, staIdx, txContext);
                    obj.STAContext(staIdx).CustomContext.PrevDataIncrementFlag = true;
                end
            end
        end

        % Increment rate for Data frames
        function incrementRate(obj, rxNodeID, staIdx, txContext)
            nsts = deviceConfigurationValue(obj,'NumSpaceTimeStreams');
            % Keep the same rate if the rate is the maximum rate.
            if obj.STAContext(staIdx).CustomContext.CurrentDataRate < maxMCS(obj, rxNodeID, txContext.TransmissionFormat, nsts, txContext.ChannelBandwidth)
                % If the rate is not the maximum rate, then increment the rate.
                obj.STAContext(staIdx).CustomContext.CurrentDataRate = obj.STAContext(staIdx).CustomContext.CurrentDataRate + 1;

                % Increment the rate, if the data rate is invalid for a
                % configured combination of bandwidth, frame format, and
                % space time streams.
                if (txContext.ChannelBandwidth == 80e6 && txContext.TransmissionFormat == "VHT") && (nsts == 3 || nsts == 7) ...
                        && obj.STAContext(staIdx).CustomContext.CurrentDataRate == 6 % Special case for VHT, invalid combination
                    obj.STAContext(staIdx).CustomContext.CurrentDataRate = obj.STAContext(staIdx).CustomContext.CurrentDataRate + 1;
                end
            end

            % Reset counters for the new rate
            obj.STAContext(staIdx).CustomContext.ConsecutiveDataSuccessCount = 0;
        end

        % Decrement rate for Data frames
        function decrementRate(obj, staIdx, txContext)
            % Keep the same rate if the rate is the minimum rate.
            if obj.STAContext(staIdx).CustomContext.CurrentDataRate ~= 0
                % If the rate is not the minimum, then decrement the rate.
                obj.STAContext(staIdx).CustomContext.CurrentDataRate = obj.STAContext(staIdx).CustomContext.CurrentDataRate - 1;

                % Decrement the rate, if the data rate is invalid for a
                % configured combination of bandwidth, frame format, and
                % space time streams.
                nsts = deviceConfigurationValue(obj,'NumSpaceTimeStreams');
                if (txContext.ChannelBandwidth == 80e6 && txContext.TransmissionFormat == "VHT") && (nsts == 3 || nsts == 7) ...
                        && obj.STAContext(staIdx).CustomContext.CurrentDataRate == 6 % Special case for VHT, invalid combination
                    obj.STAContext(staIdx).CustomContext.CurrentDataRate = obj.STAContext(staIdx).CustomContext.CurrentDataRate - 1;
                end
            end

            % Reset counters for the new rate
            obj.STAContext(staIdx).CustomContext.ConsecutiveDataFailureCount = 0;
        end

        % Update transmission status for control frames
        function updateControlFrameStatus(obj, staIdx, ~, isFail)
            % Transmission failure
            if isFail
                obj.STAContext(staIdx).CustomContext.ConsecutiveControlFailureCount = obj.STAContext(staIdx).CustomContext.ConsecutiveControlFailureCount + 1;
                obj.STAContext(staIdx).CustomContext.ConsecutiveControlSuccessCount = 0;

                % Decrement the control frame rate if the transmission failed
                % immediately after incrementing the control frame rate
                if obj.STAContext(staIdx).CustomContext.PrevControlIncrementFlag
                    % Keep the same rate if the rate is the minimum rate.
                    if obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx ~= 1
                        % If the rate is not the minimum, then decrement the rate.
                        obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx = obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx - 1;
                    end
                    obj.STAContext(staIdx).CustomContext.ConsecutiveControlFailureCount = 0;
                    obj.STAContext(staIdx).CustomContext.PrevControlIncrementFlag = false;
                end

                % If the consecutive failure count reached threshold, decrement
                % control frame rate
                if (obj.STAContext(staIdx).CustomContext.ConsecutiveControlFailureCount >= obj.FailureThreshold)
                   decrementControlRate(obj, staIdx);
                end

            else % Successful transmission
                obj.STAContext(staIdx).CustomContext.ConsecutiveControlSuccessCount = obj.STAContext(staIdx).CustomContext.ConsecutiveControlSuccessCount + 1;
                obj.STAContext(staIdx).CustomContext.ConsecutiveControlFailureCount = 0;
                obj.STAContext(staIdx).CustomContext.PrevControlIncrementFlag = false;

                % If the consecutive success count reached threshold,
                % increment control frame rate
                if (obj.STAContext(staIdx).CustomContext.ConsecutiveControlSuccessCount >= obj.SuccessThreshold)
                    incrementControlRate(obj, staIdx);
                    obj.STAContext(staIdx).CustomContext.PrevControlIncrementFlag = true;
                end
            end
        end

        % Increment rate for control frames
        function incrementControlRate(obj, staIdx)
            % Keep the same rate if the rate is the maximum rate.
            if obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx < numel(obj.BasicRateIndices)
                % If the rate is not the maximum rate, then increment the rate.
                obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx = obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx + 1;
            end

            % Reset counters for the new rate
            obj.STAContext(staIdx).CustomContext.ConsecutiveControlSuccessCount = 0;
        end

        % Decrement rate for control frames
        function decrementControlRate(obj, staIdx)
            % Keep the same rate if the rate is the minimum rate.
            if obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx ~= 1
                % If the rate is not the minimum, then decrement the rate.
                obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx = obj.STAContext(staIdx).CustomContext.CurrentControlRateIdx - 1;
            end

            % Reset counters for the new rate
            obj.STAContext(staIdx).CustomContext.ConsecutiveControlFailureCount = 0;
        end
    end
end