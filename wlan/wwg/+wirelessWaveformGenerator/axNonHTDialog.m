classdef axNonHTDialog < wirelessWaveformGenerator.wlanHEBaseDialog & wirelessWaveformGenerator.hasInactiveSubchannels
% Dialog for HE SU waveform

%   Copyright 2021-2025 The MathWorks, Inc.

    methods
        function obj = axNonHTDialog(parent)
            obj@wirelessWaveformGenerator.wlanHEBaseDialog(parent); % call base constructor
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanNonHTConfig; % so that update happens before construction end
            obj.configGenFcn = @wlanNonHTConfig;
            obj.configGenVar = 'nonhtCfg';
        end

        function props = displayOrder(~)
            props = {'HEFormat'; 'Modulation'; 'ChannelBandwidth'; 'MCS'; ...
                     'NumTransmitAntennas'; 'CyclicShifts'; 'PSDULength'; 'SignalChannelBandwidth';'BandwidthOperation'; ...
                     'InactiveSubchannel1'; 'InactiveSubchannel2'; 'InactiveSubchannel3'; 'InactiveSubchannel4'; ...
                     'InactiveSubchannel5'; 'InactiveSubchannel6'; 'InactiveSubchannel7'; 'InactiveSubchannel8'; ...
                    };
        end

        function config = getConfiguration(obj)
        % Get configuration object from dialog
            config = getConfiguration@wirelessWaveformGenerator.wlanNonHTDialog(obj);
            config = getConfiguration@wirelessWaveformGenerator.hasInactiveSubchannels(obj,config);
        end

        function config = getConfigurationForSave(obj)
        % Default method takes care of everything in the config object that is present in displayOrder
            config = getConfigurationForSave@wirelessWaveformGenerator.wlanNonHTDialog(obj);

            % Map displayed InactiveSubchannels to the corresponding config prop
            config.InactiveSubchannels = obj.InactiveSubchannels;
        end

        function addConfigCode(obj, sw)
        % Add any custom object configuration code when exporting MATLAB
        % script
            addConfigCode@wirelessWaveformGenerator.wlanNonHTDialog(obj, sw);
            addConfigCode@wirelessWaveformGenerator.hasInactiveSubchannels(obj, sw);
            addcr(sw, '');
        end

        function props = props2ExcludeFromConfig(obj)
        % Exclude properties which are only app controls from being set as
        % in the configuration object
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanNonHTDialog(obj);
            props = [props props2ExcludeFromConfig@wirelessWaveformGenerator.hasInactiveSubchannels(obj)];
            props = [props {'HEFormat'}];
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % When exporting MATLAB script do not show properties which are used
        % in the app but not in the configuration object, or conditionally
        % visible properties
            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanNonHTDialog(obj);
            props = [props props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.hasInactiveSubchannels(obj)];
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g HE)
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:NHTTitle', obj.Parent.WaveformGenerator.pCurrentExtensionType));
            obj.PSDULengthType = 'numericEdit';
            obj.resetPopupStrings();
        end

        function adjustDialog(obj)
        % Adjustments of UI elements after they have been created - i.e.
        % disable
            adjustDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            adjustDialog@wirelessWaveformGenerator.hasInactiveSubchannels(obj);
            obj.PSDULengthGUI.(obj.Callback) = @(a, b) psduChanged(obj, []);
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanWaveformConfiguration(obj);
            obj.HEFormat = 'Non high throughput (Non-HT)'; % In case we return to 11ax, after it was set to MU and user left 11ax
        end

        function update11axNonHTVisibility(obj)
        % Update dependent visibility
            obj.updateBandwidthOpeartion();
            obj.updateScramblerVisibility();
            obj.updateInactiveSubchannelsGUI();
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Format: Non-HT'' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''Tx antennas: '' num2str(' obj.configGenVar '.NumTransmitAntennas) newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end


        function updateDialogFromConfig(obj,config)
        % Update the visibility and forced values of GUI elements when configuration loaded
            obj.HEFormat = 'Non high throughput (Non-HT)';
            updateDialogFromConfig@wirelessWaveformGenerator.hasInactiveSubchannels(obj,config);
            obj.updateScramblerVisibility();
            obj.setVisualState('RU & Subcarrier Assignment', false);
        end

        function defaultVisualLayout(obj)
        % No RU & Subcarrier display
            obj.setVisualState(obj.visualNames{1}, false);
        end

        function resetPopupStrings(obj)
        % Reset popup menu options
            obj.ChannelBandwidthDropDown = {'20 MHz', '40 MHz', '80 MHz', '160 MHz'};
            obj.MCSDropDown = {'0 (BPSK, 1/2 rate)', '1 (BPSK, 3/4 rate)', '2 (QPSK, 1/2 rate)', ...
                               '3 (QPSK, 3/4 rate)', '4 (16-QAM, 1/2 rate)', '5 (16-QAM, 3/4 rate)', ...
                               '6 (64-QAM, 2/3 rate)', '7 (64-QAM, 3/4 rate)'};
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            restoreDefaults@wirelessWaveformGenerator.hasInactiveSubchannels(obj);
            obj.HEFormat = 'Non high throughput (Non-HT)';
            obj.ChannelBandwidth = 'CBW20';
            obj.NumTransmitAntennas = 1;
            obj.CyclicShifts = -75;
            obj.MCS = '0 (BPSK, 1/2 rate)';
            obj.SignalChannelBandwidth = false;
            obj.BandwidthOperation = 'Absent';
            obj.PSDULength = 1000;
        end

        function heFormatChanged(obj, ~)
            heFormatChanged@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
        end

        function channelBandwidthChanged(obj, ~)
            channelBandwidthChanged@wirelessWaveformGenerator.wlanNonHTDialog(obj, []);
            updateInactiveSubchannelsGUI(obj);
        end

        function n = getPSDULength(obj)
            n = getPSDULength@wirelessWaveformGenerator.wlanWaveformConfiguration(obj);
        end

        function psduChanged(~, ~)
        % No callback action when PSDULength changed
        end

        function updatePSDU(~)
        % PSDU edit box so no need to update
        end

        function customVisualizations(obj, varargin)
        % RU & Subcarriers common for HE, show no axis for non-HT
            if obj.getVisualState(obj.visualNames{1})
                fig = obj.getVisualFig(obj.visualNames{1});
                if isempty(fig.Children)
                    ax = axes(fig);
                else
                    ax = findall(fig, 'Type', 'Axes');
                end
                ax(1).Visible = 'off'; % Hide axis
            end
        end

        function addCustomVisualizationCode(~, ~)
        % No custom visualization as never show RU and Subcarrier Assignment
        end

    end

    methods (Access = protected)
        function updateCyclicShifts(obj)
        % Update cyclic shift GUI based on dependent properties. This method
        % should be overloaded by each transmission format and called by each
        % dependent property change method, i.e. numTransmitAntennasChanged.
            updateCyclicShifts@wirelessWaveformGenerator.wlanNonHTDialog(obj);
        end

        function [vis,numTxThresh] = isCyclicShiftsVisible(obj)
        % Returns true if the cyclic shift GUI option should be visible
            [vis,numTxThresh] = isCyclicShiftsVisible@wirelessWaveformGenerator.wlanNonHTDialog(obj);
        end

        function numTransmitAntennasChanged(obj)
            numTransmitAntennasChanged@wirelessWaveformGenerator.wlanNonHTDialog(obj);
        end
    end
end
