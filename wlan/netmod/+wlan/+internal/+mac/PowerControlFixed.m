classdef PowerControlFixed < wlan.internal.mac.PowerControl
%PowerControlFixed Uses fixed transmit power with powerControl interface
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = wlan.internal.mac.PowerControlFixed creates a fixed transmit
%   power selection object that provides powerControl interface.
%
%   PowerControlFixed methods:
%
%   getTxPower - Get required power to transmit a frame to destination station
%
%   PowerControlFixed properties:
%
%   Power      - Fixed power to be used for signal transmission

%   Copyright 2022-2025 The MathWorks, Inc.

properties
    %Power Fixed power to be used for signal transmission
    %   Power is a scalar specified in the range of [0 - 30] representing
    %   power in dBm to be used for signal transmission. The default value
    %   is 15.
    Power (1,1) {mustBeNumeric, mustBeReal} = 15;
end

methods
    % Constructor
    function obj = PowerControlFixed(varargin)
        obj@wlan.internal.mac.PowerControl(varargin{:});
    end

    function txPower = getTxPower(obj, ~)
        %getTxPower Get required power to transmit a frame to destination station
        %   TXPOWER = getTxPower(OBJ, CONTROLINFO) returns transmission
        %   power, TXPOWER required for transmitting a frame to destination
        %   station.
        %
        %   TXPOWER is a scalar integer specifying the power in dBm
        %   required to transmit a frame.
        %
        %   OBJ is an object of type wlan.internal.mac.PowerControl.
        %
        %   CONTROLINFO is a structure containing information required for
        %   power control algorithm to select transmission power. The MAC
        %   layer must fill the information required for all the supported
        %   power control algorithms before calling the getTxPower method.
        %   This structure can be extended to include other properties for
        %   custom algorithms. The control info fields are:
        %       MCS                - MCS index used to transmit frame
        %       ChannelBandwidth   - Channel bandwidth

        txPower = obj.Power;
    end

end
end

