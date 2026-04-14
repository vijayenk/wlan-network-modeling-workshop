classdef PowerControl < handle
%PowerControl Base class for transmission power control algorithms
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   This is the base class for implementing any power control algorithm
%   and defines the supported interface.
%
%   PowerControl methods:
%
%   getTxPower - Get required power to transmit a frame to destination station
%
%   PowerControl properties:
%
%   ControlInfo -  Structure containing information required to select Tx
%                  power
 
%   Copyright 2022-2025 The MathWorks, Inc.

properties
    %ControlInfo Structure containing information required to select Tx
    %power
    %   This structure contains information required for power control
    %   algorithm to select transmission power. The MAC layer must fill the
    %   information required for all the supported power control algorithms
    %   before calling the getTxPower method. This structure can be
    %   extended to include other properties for custom algorithms. The
    %   control info fields are:
    %       MCS                - MCS index used to transmit frame
    %       ChannelBandwidth   - Channel bandwidth
    ControlInfo = struct('MCS', 0, 'ChannelBandwidth', 20);
end

methods
    % Constructor method
    function obj = PowerControl(varargin)
        % Name-value pair check
        if (mod(nargin, 2)~=0)
            error(message('wlan:ConfigBase:InvalidPVPairs'))
        end

        for i = 1:2:nargin
            obj.(varargin{i}) = varargin{i+1};
        end
    end
end

methods (Abstract)
    txPower = getTxPower(obj, controlInfo)
    %getTxPower Get required power to transmit a frame to destination station
    %   TXPOWER = getTxPower(OBJ, CONTROLINFO) returns transmission power,
    %   TXPOWER required for transmitting a frame to destination station.
    %
    %   TXPOWER is a scalar integer specifying the power in dBm required to
    %   transmit a frame.
    %
    %   OBJ is an object of type PowerControl.
    %
    %   CONTROLINFO is a structure containing information required for
    %   power control algorithm to select transmission power. The MAC layer
    %   must fill the information required for all the supported power
    %   control algorithms before calling the getTxPower method. This
    %   structure can be extended to include other properties for custom
    %   algorithms. The control info fields are:
    %       MCS                - MCS index used to transmit frame
    %       ChannelBandwidth   - Channel bandwidth
end
end
