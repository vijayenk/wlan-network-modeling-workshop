classdef RateControlFixed < wlanRateControl
%RateControlFixed Uses a fixed rate algorithm
%   OBJ = wlan.internal.mac.RateControlFixed Create a fixed rate algorithm
%   object.
%
%   RateControlFixed methods:
%
%   selectRateParameters        - Select rate control parameters for frame transmission
%   processTransmissionStatus   - Perform operations based on the frame transmission status

%   Copyright 2022-2025 The MathWorks, Inc.

properties (Access=protected)
    %CustomContextTemplate No custom context required for fixed rate algorithm
    CustomContextTemplate = [];
end

methods
    % Constructor
    function obj = RateControlFixed(varargin)
        obj@wlanRateControl(varargin{:});
    end

    function [rateInfo] = selectRateParameters(obj, txContext)
        %selectRateParameters Returns the rate parameters for frame transmission
        % [RATEPARAMS] = selectRateParameters(OBJ, TXCONTEXT) returns the rate
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
        %                             of "QoS Data", "RTS", "MU-RTS", "MU-BAR".
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
        %                             transmission format. It is specified as
        %                             one of 'Non-HT', 'HT-Mixed', 'VHT', 'HE-SU', 
        %                             'HE-EXT-SU', 'HE-MU', 'HE-TB', or 'EHT-SU'.
        %
        %       ChannelBandwidth    - Channel bandwidth that will be used for 
        %                             transmission. It is specified in Hz as one of
        %                             20e6, 40e6, 80e6, 160e6, or 320e6.
        %
        %       CurrentTime         - Scalar value representing current simulation
        %                             time in seconds.

        if strcmp(txContext.FrameType, 'QoS Data')
            mcs = deviceConfigurationValue(obj,'MCS');
            if isEMLSRSTA(obj)
                % Override NSTS value for data transmissions from an EMLSR station to use sum of NSTS of all links
                numSTS = sum([obj.DeviceConfig.LinkConfig(:).NumSpaceTimeStreams]);
            else
                numSTS = deviceConfigurationValue(obj,'NumSpaceTimeStreams');
            end
        elseif strcmp(txContext.FrameType, 'MU-BAR') || strcmp(txContext.FrameType, 'MU-RTS')
            % Use maximum basic rate for MU-RTS and MU-BAR
            mcs = basicRateIndex(obj,max(obj.BasicRates));
            % Transmit with 1 space-time stream
            numSTS = 1;
        else % RTS
            % Using basic rate of 6 Mbps for RTS
            mcs = 0;
            % Transmit with 1 space-time stream
            numSTS = 1;
        end
        rateInfo.MCS = mcs;
        rateInfo.NumSpaceTimeStreams = numSTS;
    end

    function processTransmissionStatus(~, ~, ~)
    %processTransmissionStatus Perform operations based on the frame
    %transmission status

        % No action, since the rate is fixed
    end
end

methods(Access = private)
    function value = basicRateIndex(~,basicRate)
        dataRateSet = [6 9 12 18 24 36 48 54];
        dataRateSetIndices = [0 1 2 3 4 5 6 7];
        numBasicRates = numel(basicRate);
        value = zeros(1, numBasicRates);
        for idx = 1:numBasicRates
            brIdxLogical = (basicRate(idx) == dataRateSet);
            value(idx) = dataRateSetIndices(brIdxLogical);
        end
    end
end
end
