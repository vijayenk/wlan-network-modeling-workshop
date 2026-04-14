classdef wlanHESUDialog < wirelessWaveformGenerator.wlanHESUBaseDialog & wirelessWaveformGenerator.hasInactiveSubchannels
% Dialog for HE SU waveform

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
    end

    properties (Hidden)
        Upper106ToneRUType = 'checkbox'
        Upper106ToneRULabel
        Upper106ToneRUGUI
        PreHESpatialMappingType = 'checkbox'
        PreHESpatialMappingLabel
        PreHESpatialMappingGUI
        NominalPacketPaddingType = 'numericPopup'
        NominalPacketPaddingLabel
        NominalPacketPaddingGUI
        NominalPacketPaddingDropDown = {'0', '8', '16'}
    end

    methods
        function obj = wlanHESUDialog(parent)
            obj@wirelessWaveformGenerator.wlanHESUBaseDialog(parent); % call base constructor

            % Specify callbacks for changes to HE GUI elements which impact
            % other elements
            obj.PreHESpatialMappingGUI.(obj.Callback) = @(a,b) preHESpatialMappingChanged(obj, []);
            obj.Upper106ToneRUGUI.(obj.Callback)      = @(a,b) upper106ToneRUChangedGUI(obj, []);

            updateRUSize(obj);
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanHESUConfig; % so that update happens before construction end
            obj.configGenFcn = @wlanHESUConfig;
            obj.configGenVar = 'heSUCfg';
        end

        function props = displayOrder(~)
            props = {'HEFormat'; 'ChannelBandwidth'; 'Upper106ToneRU'; ...
                     'NumTransmitAntennas'; 'PreHECyclicShifts'; 'NumSpaceTimeStreams'; 'SpatialMapping'; ...
                     'SpatialMappingMatrix'; 'Beamforming'; 'PreHESpatialMapping'; ...
                     'STBC'; 'MCS'; 'DCM'; 'ChannelCoding'; 'APEPLength'; 'GuardInterval'; ...
                     'HELTFType'; 'UplinkIndication'; 'BSSColor'; 'SpatialReuse'; ...
                     'TXOPDuration'; 'HighDoppler'; 'MidamblePeriodicity'; ...
                     'InactiveSubchannel1'; 'InactiveSubchannel2'; 'InactiveSubchannel3'; 'InactiveSubchannel4'; ...
                     'InactiveSubchannel5'; 'InactiveSubchannel6'; 'InactiveSubchannel7'; 'InactiveSubchannel8'; ...
                     'NominalPacketPadding'; 'PSDULength'; 'RUSize'};
        end
        function updateVisibilities(obj)
            channelBandwidthChanged(obj);
            apepChanged(obj);
        end


        function config = getConfiguration(obj)
        % Get configuration object from dialog
            config = getConfiguration@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            config.ExtendedRange = strcmp(obj.HEFormat, 'HE extended range single-user');
            config = getConfiguration@wirelessWaveformGenerator.hasInactiveSubchannels(obj,config);
        end

        function config = getConfigurationForSave(obj)
        % Default method takes care of everything in the config object that is present in displayOrder
            config = getConfigurationForSave@wirelessWaveformGenerator.wlanHEBaseDialog(obj);

            % Map displayed InactiveSubchannels to the corresponding config prop
            config.InactiveSubchannels = obj.InactiveSubchannels;
        end

        function str = getIconDrawingCommand(obj)
            if ~strcmp(obj.HEFormat, 'HE extended range single-user')
                format = 'SU''';
            else
                format = 'ER SU''';
            end

            str = ['disp([''Format: HE ' format ' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''Coding: '' ' obj.configGenVar '.ChannelCoding newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function applyConfiguration(obj, config)
        % For 11ax, applyConfiguration is always directed to wlanHESUDialog
        % so redirect to base to implemnet format specific behavior
            applyConfiguration@wirelessWaveformGenerator.wlanHESUBaseDialog(obj, config);
        end

        function props = props2ExcludeFromConfig(obj)
        % Exclude properties which are only app controls from being set as
        % in the configuration object
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);
            props = [props props2ExcludeFromConfig@wirelessWaveformGenerator.hasInactiveSubchannels(obj)];
            props = [props {'RUSize'}];
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % When exporting MATLAB script do not show properties which are used
        % in the app but not in the configuration object, or conditionally
        % visible properties
            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);
            props = [props props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.hasInactiveSubchannels(obj)];
            props = [props {'RUSize'}];
            if obj.APEPLength == 0
                props = [props 'NominalPacketPadding'];
            end

            if ~strcmp(obj.HEFormat, 'HE extended range single-user')
                props = [props 'Upper106ToneRU'];
            end
        end

        function addConfigCode(obj, sw)
        % Add any custom object configuration code when exporting MATLAB
        % script
            addConfigCode@wirelessWaveformGenerator.wlanHEBaseDialog(obj, sw);
            if strcmp(obj.HEFormat, 'HE extended range single-user')
                addcr(sw, [obj.configGenVar '.ExtendedRange = true;']);
            end
            addConfigCode@wirelessWaveformGenerator.hasInactiveSubchannels(obj, sw);

            addcr(sw, '');
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g non-HT)
            adjustSpec@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            % Configure RUSize as text
            obj.RUSizeType = 'numericText';
        end

        function adjustDialog(obj)
        % Adjustments of UI elements after they have been created - i.e.
        % disable
            adjustDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            adjustDialog@wirelessWaveformGenerator.hasInactiveSubchannels(obj);
            setVisible(obj, {'Beamforming', 'Upper106ToneRU'}, false);
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            obj.HEFormat = 'HE single-user'; % In case we return to 11ax, after it was set to MU and user left 11ax.
        end

        function updateDialogFromConfig(obj,config)
        % Update the visibility and forced values of GUI elements when configuration loaded
            if config.ExtendedRange
                obj.HEFormat = 'HE extended range single-user';
            else
                obj.HEFormat = 'HE single-user';
            end
            updateSUERVisibility(obj);
            updateSTBC(obj);
            updateDCM(obj);
            updateDialogFromConfig@wirelessWaveformGenerator.hasInactiveSubchannels(obj,config);
        end

        function defaultVisualLayout(obj)
            obj.setVisualState(obj.visualNames{1}, true);   % RU & Subcarriers
        end

        function resetPopupStrings(obj)
        % Reset popup menu options
            resetPopupStrings@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            obj.NominalPacketPaddingGUI.(obj.DropdownValues) = obj.NominalPacketPaddingDropDown;
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            restoreDefaults@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            restoreDefaults@wirelessWaveformGenerator.hasInactiveSubchannels(obj);
            obj.HEFormat = 'HE single-user';
            obj.ChannelBandwidth = 'CBW20';
            obj.Upper106ToneRU = false;
            obj.NumSpaceTimeStreams = 1;
            obj.SpatialMapping = 'Direct';
            obj.SpatialMappingMatrix = 1;
            obj.PreHESpatialMapping = false;
            obj.Beamforming = true;
            obj.MCS = '0 (BPSK, 1/2 rate)';
            obj.STBC = false;
            obj.DCM = false;
            obj.ChannelCoding = 'LDPC';
            obj.APEPLength = 100;
            obj.PSDULength = obj.getPSDULength(); % update
            

            % Ensure that the CBW dropdown is restored to an editable state
            setEnable(obj, 'ChannelBandwidth', true);
        end

        function updateSUERVisibility(obj)
        % Update visibility of elements depending on HE format
            extendedRange = strcmp(obj.HEFormat, 'HE extended range single-user');
            if extendedRange
                obj.ChannelBandwidth = 'CBW20'; % only option for extended range
            end
            setVisible(obj, 'Upper106ToneRU', extendedRange);
            setEnable(obj, 'ChannelBandwidth', ~extendedRange);

            obj.updateRUSize();
            obj.updateMCS();

            obj.updatePSDU(); % HE format affects PSDU len
        end

        function heFormatChanged(obj, ~)
            heFormatChanged@wirelessWaveformGenerator.wlanHEBaseDialog(obj);

            updateRUSize(obj);
        end

        function apepLengthChangedGUI(obj, ~)
            try
                val = obj.APEPLength;
                validateattributes(val, {'numeric'}, {'nonnegative', 'scalar', '<=', 6500531}, '', 'APEPLength');
            catch e
                obj.errorFromException(e);
            end
            apepChanged(obj);
            layoutUIControls(obj);
        end

        function apepChanged(obj, ~)
            % Hide Nominal Packet Extension if APEPLength == 0
            setVisible(obj, 'NominalPacketPadding', obj.APEPLength ~= 0);
            updateInactiveSubchannelsGUI(obj);
            updatePSDU(obj);
        end

        function updateRUSize(obj)
            try
                cfg = obj.getConfiguration;
                s = cfg.ruInfo();
                obj.RUSize = s.RUSizes;
            catch
                % object is still initializing, not ready for an ruInfo call
            end
        end

        function channelBandwidthChanged(obj, ~)
            channelBandwidthChanged@wirelessWaveformGenerator.wlanVHTDialog(obj, []);
            updateRUSize(obj);
            updateChannelCoding(obj);
            updateInactiveSubchannelsGUI(obj);
        end

        function upper106ToneRUChangedGUI(obj, ~)
            obj.updateMCS();

            updateRUSize(obj);
            obj.updateDCM();
            obj.updateChannelCoding();
        end

        function updateMCS(obj)
        % Update value and options for MCS based on HE format

            if strcmp(obj.HEFormat, 'HE extended range single-user')
                if obj.Upper106ToneRU
                    options = obj.MCSDropDownFull(1);
                else
                    options = obj.MCSDropDownFull(1:3);
                end
                obj.MCSGUI.(obj.DropdownValues) = options;
            else
                obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDownFull;
            end
        end

        function outro(obj, ~)
            % Ensure that the CBW dropdown is restored to an editable state
            setEnable(obj, 'ChannelBandwidth', true);
        end
    end

    methods (Access = private)
        function preHESpatialMappingChanged(obj, ~)
        % Show or hide pre-HE cyclic shift controls
            obj.updateCyclicShifts(); % Implemented in HE base
            obj.layoutUIControls();
        end
    end

    methods (Access = protected)
        function [vis,numTxThresh] = isCyclicShiftsVisible(obj)
        % Returns true if the cyclic shift GUI option should be visible
        % Called in HE Base
            numTxThresh = 8; % Threshold over which cyclic shifts must be specified
            if obj.NumTransmitAntennas>numTxThresh && obj.PreHESpatialMapping==false
                vis = true;
            else
                vis = false;
            end
        end

        function [lower,upper] = inactiveSubchannelsApplicable(obj,varargin)
        % Inactive subchannels only applicable for NDP 80 MHz or 160 MHz.
        % Returns true if applicable for the current configuration.
            if nargin==1
                cfg = obj;
            else
                cfg = varargin{1};
            end
            lower = (cfg.APEPLength == 0) && any(strcmp(cfg.ChannelBandwidth, {'CBW80','CBW160'}));
            upper = (cfg.APEPLength == 0) && strcmp(cfg.ChannelBandwidth, 'CBW160');
        end
    end
end
