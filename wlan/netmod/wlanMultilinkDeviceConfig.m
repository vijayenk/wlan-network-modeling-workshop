classdef wlanMultilinkDeviceConfig < comm.internal.ConfigBase
%wlanMultilinkDeviceConfig WLAN multilink device (MLD) configuration
%   DEVICECFG = wlanMultilinkDeviceConfig() creates a default WLAN MLD
%   configuration object.
%
%   DEVICECFG = wlanMultilinkDeviceConfig(Name=Value) creates a WLAN MLD
%   configuration object with the specified property Name set to the
%   specified Value. You can specify additional name-value arguments in any
%   order as (Name1=Value1, ..., NameN=ValueN).
%
%   wlanMultilinkDeviceConfig properties:
%
%   Mode                             - Operating mode of the MLD
%   ShortRetryLimit                  - Maximum number of transmission attempts for a frame
%   LinkConfig                       - Link configuration
%   EnhancedMultilinkMode            - Mode of enhanced multilink operation (MLO)
%   EnhancedMultilinkTransitionDelay - Enhanced multilink single radio (EMLSR) transition delay in seconds
%   EnhancedMultilinkPaddingDelay    - EMLSR padding delay in seconds

%   Copyright 2023-2025 The MathWorks, Inc.

properties
    %Mode Operating mode of the MLD
    %   Specify the operating mode as "STA" or "AP". The default value is
    %   "STA".
    Mode = "STA";

    %ShortRetryLimit Maximum number of transmission attempts for a frame
    %   Specify the maximum number of transmission attempts for a frame as an
    %   integer in the range [1, 65535]. The default value is 7.
    ShortRetryLimit (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(ShortRetryLimit,1), mustBeLessThanOrEqual(ShortRetryLimit,65535)} = 7;

    %EnhancedMultilinkMode Mode of enhanced MLO
    %   Specify the enhanced MLO mode as "none" or "EMLSR". This property is
    %   applicable only when Mode value is
    %   set to "STA". The default is "none".
    EnhancedMultilinkMode = "none";

    %EnhancedMultilinkTransitionDelay EMLSR transition delay in seconds
    %   Specify the transition delay as 0, 16e-6, 32e-6, 64e-6, 128e-6, or
    %   256e-6. Units are in seconds. This value represents the transition
    %   delay time required by the MLD station to switch from exchanging frames
    %   on one of the enabled EMLSR links to the listening operation on all the
    %   enabled EMLSR links. This property is applicable only when Mode is set
    %   to "STA" and EnhancedMultilinkMode is set to "EMLSR". The default value
    %   is 0.
    EnhancedMultilinkTransitionDelay (1, 1) {mustBeMember(EnhancedMultilinkTransitionDelay, [0 16e-6 32e-6 64e-6 128e-6 256e-6])} = 0;

    %EnhancedMultilinkPaddingDelay EMLSR padding delay in seconds
    %   Specify the padding delay as 0, 32e-6, 64e-6, 128e-6, or 256e-6. Units
    %   are in seconds. This value represents the minimum required MAC padding
    %   duration conveyed by the MLD station to the MLD AP, to be applied for
    %   the padding field in the initial control frame. This property is only
    %   applicable when Mode is set to "STA" and EnhancedMultilinkMode is set
    %   to "EMLSR". The default value is 0.
    EnhancedMultilinkPaddingDelay (1, 1) {mustBeMember(EnhancedMultilinkPaddingDelay, [0 32e-6 64e-6 128e-6 256e-6])} = 0;
end

properties(SetAccess = private)
    %LinkConfig Link configuration
    %   Specify the link configuration as a scalar object or a vector of
    %   objects of the type wlanLinkConfig. If you want to configure multiple
    %   links in the MLD, specify this value as a vector. After you create the
    %   object, this property is read-only. The default value is an object of
    %   the type wlanLinkConfig with default parameters.
    LinkConfig (1, :) wlanLinkConfig;
end

properties (Hidden)
    %TransmitQueueSize Size of a MAC transmission queue
    %   Specify the size of the queue for buffering the frames (MSDUs) to be
    %   transmitted from the MAC layer as an integer scalar in the range [1,
    %   2048]. The queue size specified here corresponds to the size of each
    %   per-destination and per-AC queue. The default value is 1024.
    TransmitQueueSize (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(TransmitQueueSize,1), mustBeLessThanOrEqual(TransmitQueueSize,2048)} = 1024;

    %NumLinks Number of affiliated links in MLD
    NumLinks = 1;

    %MediumSyncDuration Duration value of medium sync delay timer in units of
    %32 microseconds
    %   Specify the duration value of medium sync delay timer as an integer in
    %   the range [0, 255]. Units are in 32 microseconds. This value represents
    %   the initial value of medium sync delay timer at a STA whose
    %   EnhancedMultilinkMode is "EMLSR". AP conveys this value to associated
    %   EMLSR STAs during association. This property is only applicable when
    %   Mode is set to "AP. The default value is 0.
    MediumSyncDuration (1, 1) {mustBeMember(MediumSyncDuration, 0:255)} = 0;

    %MediumSyncEDThreshold ED threshold in dBm to use during medium
    %synchronization recovery
    %   Specify the ED threshold in dBm as an integer in the range [-72, -62].
    %   This value represents the ED threshold that an EMLSR STA uses when it
    %   has non-zero medium sync delay timer i.e., when STA is performing
    %   medium synchronization recovery. AP conveys this value to associated
    %   EMLSR STAs during association. This property is only applicable when
    %   Mode is set to "AP. The default value is -72.
    MediumSyncEDThreshold (1, 1) {mustBeMember(MediumSyncEDThreshold, -72:-62)} = -72;

    %MediumSyncMaxTXOPs Maximum number of TXOPs during medium synchronization
    %recovery
    %   Specify the maximum number of TXOPs as either an integer in the range
    %   [1, 15] or Inf. This value represents the maximum number of TXOPs an
    %   EMLSR STA attempts to initiate when it has non-zero medium sync delay
    %   timer i.e., when STA is performing medium synchronization recovery. AP
    %   conveys this value to associated EMLSR STAs during association. This
    %   property is only applicable when Mode is set to "AP. The default value
    %   is Inf.
    MediumSyncMaxTXOPs (1, 1) = Inf;
end

properties (Hidden, Dependent)
    %IsAPDevice Flag indicating AP MLD
    IsAPDevice;
end

properties (Hidden, Constant)
    %IsMeshDevice Flag indicating mesh device
    % The value is set to false as multilink operation (MLO) is not supported
    % in mesh devices.
    IsMeshDevice = false;
end

properties (Hidden, Constant)
    Mode_Values = ["STA", "AP"];
    EnhancedMultilinkMode_Values = ["none" "EMLSR"];
end

methods
    function obj = wlanMultilinkDeviceConfig(varargin)
        % Name-value pair check
        if (mod(nargin,2) == 1)
            error(message('wlan:ConfigBase:InvalidPVPairs'))
        end

        % Initialize to default values
        obj.LinkConfig = wlanLinkConfig;

        % Name-value pairs
        for idx = 1:2:nargin-1
            obj.(varargin{idx}) = varargin{idx+1};
        end

        obj.NumLinks = numel(obj.LinkConfig);
    end

    function obj = set.Mode(obj, value)
        value = validatestring(value, obj.Mode_Values, 'wlanMultilinkDeviceConfig', 'Mode');
        obj.Mode = value;
    end

    function obj = set.EnhancedMultilinkMode(obj, value)
        value = validatestring(value, obj.EnhancedMultilinkMode_Values, 'wlanMultilinkDeviceConfig', 'EnhancedMultilinkMode');
        obj.EnhancedMultilinkMode = value;
    end

    function value = get.IsAPDevice(obj)
        value = strcmp(obj.Mode, "AP");
    end

    function obj = validateConfig(obj)
        % Maximum number of allowed links is 15
        if numel(obj.LinkConfig) > 15
            error(message('wlan:wlanMultilinkDeviceConfig:InvalidNumLinks'))
        end
        % AIFS value 1 is only allowed for AP
        if ~obj.IsAPDevice && any([obj.LinkConfig(:).AIFS] == 1)
            error(message('wlan:wlanMultilinkDeviceConfig:InvalidAIFSForNonAP'))
        end
        for linkIdx = 1:obj.NumLinks
            % Check for any missing mandatory rates in BasicRates
            if obj.IsAPDevice && ~all(ismember([6 12 24], obj.LinkConfig(linkIdx).BasicRates))
                error(message('wlan:wlanMultilinkDeviceConfig:MandatoryRatesMissing', ...
                    linkIdx, obj.LinkConfig(linkIdx).BandAndChannel(1), obj.LinkConfig(linkIdx).BandAndChannel(2)))
            end
            % Validate link config objects
            validateConfig(obj.LinkConfig(linkIdx));
        end

        % Validate MediumSyncMaxTXOPs
        if ~isinf(obj.MediumSyncMaxTXOPs) && ~any(obj.MediumSyncMaxTXOPs == 1:15)
            error("MediumSyncMaxTXOPs must be either Inf or an integer in the range [1, 15]");
        end

        isEMLSRSTA = false;
        if obj.IsAPDevice
            for idx = 1:obj.NumLinks
                linkCfg = obj.LinkConfig(idx);

                if isfinite(linkCfg.BeaconInterval)
                    % Validate initial beacon offset
                    if (isempty(linkCfg.InitialBeaconOffset) || numel(linkCfg.InitialBeaconOffset) > 2)
                        error(message('wlan:wlanMultilinkDeviceConfig:InvalidBeaconOffset', ...
                            idx, linkCfg.BandAndChannel(1), linkCfg.BandAndChannel(2)))
                    end
                    if numel(linkCfg.InitialBeaconOffset) == 2
                        if linkCfg.InitialBeaconOffset(1) > linkCfg.InitialBeaconOffset(2)
                            error(message('wlan:wlanMultilinkDeviceConfig:InvalidBeaconOffsetRange', ...
                                idx, linkCfg.BandAndChannel(1), linkCfg.BandAndChannel(2)))
                        end
                    end
                    % Maximum number of links allowed when beacon transmission is enabled is
                    % 13. Because the reduced neighbor report element can carry the neighbor AP
                    % information of 12 links without exceeding maximum information element
                    % length (255 octets).
                    if obj.NumLinks > 13
                        error(message('wlan:wlanMultilinkDeviceConfig:InvalidNumLinksBeacon'))
                    end
                end

                validateNumSTS(linkCfg, linkCfg.NumSpaceTimeStreams, linkCfg.NumTransmitAntennas, isEMLSRSTA);
                % Validate PrimaryChannelIndex based on bandwidth
                if linkCfg.ChannelBandwidth ~= 20e6
                    if linkCfg.PrimaryChannelIndex>(linkCfg.ChannelBandwidth/20e6)
                        error(message("wlan:shared:InvalidPrimaryChannelIndex", linkCfg.ChannelBandwidth/20e6, linkCfg.ChannelBandwidth/1e6))
                    end
                end
            end

        elseif strcmp(obj.EnhancedMultilinkMode, "none") % STA operating in STR mode
            for idx = 1:obj.NumLinks
                linkCfg = obj.LinkConfig(idx);
                validateNumSTS(linkCfg, linkCfg.NumSpaceTimeStreams, linkCfg.NumTransmitAntennas, isEMLSRSTA);
            end

        else % STA operating in EMLSR mode
            isEMLSRSTA = true;
            % Aggregate number of antennas and STS
            numTransmitAntennas = sum([obj.LinkConfig(:).NumTransmitAntennas]);
            if numTransmitAntennas > 8
                error(message('wlan:wlanMultilinkDeviceConfig:InvalidEMLSRNumTxAntennas'))
            end
            numSTS = sum([obj.LinkConfig(:).NumSpaceTimeStreams]);
            for idx = 1:obj.NumLinks
                linkCfg = obj.LinkConfig(idx);
                validateNumSTS(linkCfg, numSTS, numTransmitAntennas, isEMLSRSTA);
            end
        end
    end
end

methods(Hidden)
    function obj = updateLinkConfig(obj, linkID, linkCfg)
        %updateLinkConfig Updates the link configuration
        %
        %   OBJ = updateLinkConfig(OBJ, LINKID, LINKCFG) updates the link
        %   configuration object specified by LINKID with new configuration,
        %   LINKCFG.

        obj.LinkConfig(linkID) = linkCfg;
    end
end
end
