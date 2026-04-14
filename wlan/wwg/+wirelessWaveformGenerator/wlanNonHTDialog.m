classdef wlanNonHTDialog < wirelessWaveformGenerator.wlanOFDMWaveformConfiguration
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Constant)
        Modulation = 'OFDM'
    end

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        ChannelBandwidth
        NumTransmitAntennas
        MCS
    end

    properties (Hidden)
        stdLabel

        configFcn     = @wlanNonHTConfig
        configGenFcn  = @wlanNonHTConfig
        configGenVar  = 'nonHTCfg'

        TitleString = getString(message('wlan:waveformGeneratorApp:NHTTitle', 'IEEE 802.11a'))
        TransmissionFormatType = 'charPopup'
        TransmissionFormatDropDown = {'Non High Throughput (Non-HT)', 'High Throughput (HT)', 'Very High Throughput (VHT)'}
        TransmissionFormatLabel
        TransmissionFormatGUI
        ModulationType = 'charText'
        ModulationLabel
        ModulationGUI
        ChannelBandwidthType = 'charPopup'
        ChannelBandwidthDropDown = {'10 MHz (802.11j)', '20 MHz (802.11a/g)'}
        ChannelBandwidthLabel
        ChannelBandwidthGUI
        NumTransmitAntennasType = 'numericEdit'
        NumTransmitAntennasLabel
        NumTransmitAntennasGUI
        CyclicShiftsType = 'numericEdit'
        CyclicShiftsLabel
        CyclicShiftsGUI
        MCSType = 'charPopup'
        MCSDropDown = {'0 (BPSK, 1/2 rate)',    '1 (BPSK, 3/4 rate)',   '2 (QPSK, 1/2 rate)', ...
                       '3 (QPSK, 3/4 rate)',    '4 (16-QAM, 1/2 rate)', '5 (16-QAM, 3/4 rate)', ...
                       '6 (64-QAM, 2/3 rate)',  '7 (64-QAM, 3/4 rate)'}
        MCSLabel
        MCSGUI

        SignalChannelBandwidthType = 'checkbox'
        SignalChannelBandwidthLabel
        SignalChannelBandwidthGUI

        BandwidthOperationType = 'charPopup'
        BandwidthOperationDropDown = {'Absent', 'Dynamic', 'Static'}
        BandwidthOperationLabel
        BandwidthOperationGUI

        DisplayOrder = {'TransmissionFormat'; 'Modulation'; 'ChannelBandwidth'; 'MCS'; ...
                        'NumTransmitAntennas'; 'CyclicShifts'; 'PSDULength'; 'SignalChannelBandwidth'; 'BandwidthOperation'; ...
                       };
    end

    methods % constructor
        function obj = wlanNonHTDialog(parent)
            obj@wirelessWaveformGenerator.wlanOFDMWaveformConfiguration(parent); % call base constructor
            weakObj = matlab.lang.WeakReference(obj);

            % Specify callbacks for changes to Non-HT GUI elements which impact
            % other elements (may also be used in subclass dialogs)
            obj.TransmissionFormatGUI.(obj.Callback)     = @(a,b) transmissionFormatChangedGUI(weakObj.Handle, []);
            obj.MCSGUI.(obj.Callback)                    = @(a,b) mcsChangedGUI(weakObj.Handle, []);
            obj.ChannelBandwidthGUI.(obj.Callback)       = @(a,b) channelBandwidthChangedGUI(weakObj.Handle, []);
            obj.NumTransmitAntennasGUI.(obj.Callback)    = @(a,b) numTransmitAntennasChangedGUI(weakObj.Handle, []);
            obj.CyclicShiftsGUI.(obj.Callback)           = @(a,b) cyclicShiftsChangedGUI(weakObj.Handle, []);
            obj.SignalChannelBandwidthGUI.(obj.Callback) = @(a,b) SignalChannelBandwidthChangedGUI(weakObj.Handle, []);
        end

        function setupDialog(obj)
            obj.stdLabel = obj.Parent.WaveformGenerator.pCurrentExtensionType;
            initialize(obj);
            % Do not show transmission format, number of transmit antennas,
            % cyclic shift, and bandwidth signaling controls as they should not
            % be visible for 11p and 11a/g/j. Other properties are added when
            % txFormatChanged() is called.
            obj.DisplayOrder = {'Modulation'; 'ChannelBandwidth'; 'MCS'; 'PSDULength'};
            setVisible(obj, {'TransmissionFormat', 'NumTransmitAntennas', ...
                             'SignalChannelBandwidth', 'BandwidthOperation'}, false);
            obj.showCyclicShiftControl(false);
            layoutUIControls(obj); % update visibility now that controls turned off

            setupDialog@wirelessWaveformGenerator.wlanWaveformConfiguration(obj);
        end

        function initialize(obj)
            if contains(obj.stdLabel,'a/g/j')
                obj.ChannelBandwidthDropDown = {'10 MHz (802.11j)', '20 MHz (802.11a/g)'};
                obj.ChannelBandwidthGUI.(obj.DropdownValues) = obj.ChannelBandwidthDropDown;
                obj.ChannelBandwidth = 'CBW20';

            elseif endsWith(obj.stdLabel,'p')
                obj.ChannelBandwidthDropDown = {'5 MHz', '10 MHz'};
                obj.ChannelBandwidthGUI.(obj.DropdownValues) = obj.ChannelBandwidthDropDown;
                obj.ChannelBandwidth = 'CBW10';
            end

            obj.TitleString = getString(message('wlan:waveformGeneratorApp:NHTTitle', obj.stdLabel));
            setTitle(obj, obj.TitleString);
        end

        function props = props2ExcludeFromConfig(~)
        % Dependent properties of the object which are not properties of the
        % corresponding configuration object
            props = {'TransmissionFormat'};
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % Return a cell array of properties which should not be "set" using
        % NV pairs when configuring the object in the generated MATLAB
        % script
            props = {'TransmissionFormat'};

            if ~isCyclicShiftsVisible(obj)
                props = [props 'CyclicShifts'];
            end
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Format: Non-HT''  newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''PSDU: '' num2str(' obj.configGenVar '.PSDULength) '' bytes'' newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function config = applyConfiguration(obj, config)
        % Called when a session is loaded and the configuration is applied to
        % the GUI
            switch class(config)
              case 'wlanNonHTConfig'
                obj.TransmissionFormat = 'Non High Throughput (Non-HT)';
                if isVisible(obj, 'TransmissionFormat')
                    % we are under 11n/ac, not 11a/j/p
                    obj.txFormatChanged();
                end
              case 'wlanHTConfig'
                obj.TransmissionFormat = 'High Throughput (HT)';
                obj.txFormatChanged();
              case 'wlanVHTConfig'
                obj.TransmissionFormat = 'Very High Throughput (VHT)';
                obj.txFormatChanged();
            end

            applyConfiguration@wirelessWaveformGenerator.WaveformConfigurationDialog(obj.Parent.CurrentDialog, config);

            % Update conditional dependency visibility after setting dialog
            % elements
            if isa(config,'wlanNonHTConfig')
                std = obj.Parent.WaveformGenerator.pCurrentExtensionType;
                if ~(contains(std, 'a/g/j') || endsWith(std, 'p'))
                    % Do not update if a/g/j/p as same dialog may have bandwidth
                    % signaling set
                    obj.Parent.CurrentDialog.updateScramblerVisibility();
                end
            end
        end

        function str = generation2code(obj)
            str = sprintf('MPDU = randi([0 1], 1000, 1);\n');
            str = [str 'waveform = ' func2str(obj.generateFcn) '(MPDU, config);'];
        end

        function restoreDefaults(obj)
        % Set defaults of standard dependent properties
            if ~isempty(obj.stdLabel) % skip if the dialog is getting initialized
                if contains(obj.stdLabel,'a/g/j')
                    obj.ChannelBandwidth = 'CBW20';
                elseif contains(obj.stdLabel,'p')
                    obj.ChannelBandwidth = 'CBW10';
                end
            end

            % Set defaults of standard independent properties
            obj.NumTransmitAntennas = 1;
            obj.CyclicShifts = -75;
            obj.MCS = '0 (BPSK, 1/2 rate)';
            obj.SignalChannelBandwidth = false;
            obj.BandwidthOperation = 'Absent';
            obj.PSDULength = 1000;
        end

        function props = displayOrder(obj)
            props = obj.DisplayOrder;
        end

        function txFormatChanged(obj, ~)
        % Transmission format changed - update GUI elements etc
            switch obj.TransmissionFormat
              case 'Non High Throughput (Non-HT)'
                className = 'wirelessWaveformGenerator.wlanNonHTDialog';
              case 'High Throughput (HT)'
                className = 'wirelessWaveformGenerator.wlanHTDialog';
              case 'Very High Throughput (VHT)'
                className = 'wirelessWaveformGenerator.wlanVHTDialog';
            end
            appObj = obj.Parent.WaveformGenerator;
            if ~isempty(appObj)
                % init has completed
                appObj.setParametersDialog(className);
            end
            currDialog = obj.Parent.CurrentDialog;
            if strcmp(obj.TransmissionFormat, 'Non High Throughput (Non-HT)')
                % Set visibility of properties when switching to Non-HT format from
                % the defaults which are for a/j/p
                currDialog.DisplayOrder = {'TransmissionFormat'; 'Modulation'; 'ChannelBandwidth'; 'MCS'; ...
                                           'NumTransmitAntennas'; 'CyclicShifts'; 'PSDULength'; 'SignalChannelBandwidth'; 'BandwidthOperation'};
                currDialog.ChannelBandwidthGUI.(obj.DropdownValues) = {'20 MHz', '40 MHz', '80 MHz', '160 MHz'};
                currDialog.setTitle(getString(message('wlan:waveformGeneratorApp:VHTTitle', '(Non High Throughput)')));
                setVisible(currDialog, {'TransmissionFormat', 'NumTransmitAntennas'}, true);
                % When switching to non-HT from another format set cyclic shift
                % visibility
                isVis = isCyclicShiftsVisible(currDialog);
                setVisible(currDialog, 'CyclicShifts', isVis);
                % Set bandwidth signaling (and scrambler control) visibility
                setVisible(currDialog, 'SignalChannelBandwidth', true)
                currDialog.updateBandwidthOpeartion();
                currDialog.updateScramblerVisibility();
                % Visibility changed so update UI controls
                currDialog.layoutUIControls();
            end
            currDialog.TransmissionFormat = obj.TransmissionFormat;
        end
        function transmissionFormatChangedGUI(obj, ~)
        % Update elements when Format GUI element changed

        % show indication that App is loading something
            appObj = obj.Parent.WaveformGenerator;
            freezeApp(appObj);

            obj.txFormatChanged();

            drawnow; % wait for new panels to be drawn before removing the Freeze status

            % make App responsive:
            unfreezeApp(appObj);
        end

        function channelBandwidthChanged(obj, ~)
            updateSampleRate(obj);
            updateWindowTransitionTime(obj);
        end
        function channelBandwidthChangedGUI(obj, ~)
            channelBandwidthChanged(obj);
            updatePSDU(obj);
            % Layout controls and panels as we may have hidden/shown controls
            obj.layoutUIControls();
        end

        function bw = get.ChannelBandwidth(obj)
            bw = getDropdownVal(obj, 'ChannelBandwidth');
            index = strfind(bw, ' ');
            bw = ['CBW' bw(1:index(1)-1)];
        end
        function set.ChannelBandwidth(obj, value)
            value = [value(4:end) ' MHz'];
            setDropdownStartingVal(obj, 'ChannelBandwidth', num2str(value));
            channelBandwidthChanged(obj);
        end

        function n = get.NumTransmitAntennas(obj)
            if isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.Label')
                n = getTextNumVal(obj, 'NumTransmitAntennas');
            elseif isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.EditField')
                n = getEditVal(obj, 'NumTransmitAntennas');
            else % popupmenu
                n = getDropdownNumVal(obj, 'NumTransmitAntennas');
            end
        end
        function set.NumTransmitAntennas(obj, value)
        % Called when session loaded therefore need to configure cyclic shift
        % visibility
            if isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.Label')
                setTextVal(obj, 'NumTransmitAntennas', value);
            elseif isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.EditField')
                setEditVal(obj, 'NumTransmitAntennas', value);
            else % popupmenu
                setDropdownNumVal(obj, 'NumTransmitAntennas', value);
            end

            obj.numTransmitAntennasChanged(); % Implemented by HT to control STS, spatial mapping etc.
            obj.updateCyclicShifts(); % Visibility of cyclic shifts
            obj.layoutUIControls();
        end

        function mcsChangedGUI(obj, ~)
            updatePSDU(obj);
        end

        function n = get.MCS(obj)
            if isa(obj.MCSGUI, 'matlab.ui.control.Label')
                n = getTextNumVal(obj, 'MCS');

            elseif isa(obj.MCSGUI, 'matlab.ui.control.EditField')

                n = getEditVal(obj, 'MCS');

            else
                n = getDropdownVal(obj, 'MCS');
                n = str2double(n(1:min([strfind(n, '/') strfind(n, '(')])-1));
            end
        end
        function set.MCS(obj, value)
            if isa(obj.MCSGUI, 'matlab.ui.control.Label')

                setTextVal(obj, 'MCS', value);

            elseif isa(obj.MCSGUI, 'matlab.ui.control.EditField')

                setEditVal(obj, 'MCS', value);

            else % popupmenu
                setDropdownStartingVal(obj, 'MCS', num2str(value));
            end
        end

        function updatePSDU(~)
        end

        function createUIControls(obj)
            createUIControls@wirelessWaveformGenerator.WaveformConfigurationDialog(obj);

            obj.ModulationGUI.(obj.TextValue) = 'OFDM';
        end
    end

    methods (Access = protected)
        % Protected methods will be called or overloaded by other transmission
        % formats
        function numTransmitAntennasChanged(~)
        % Update format specific GUI elements (excluding cyclic shifts as
        % common for all formats) when Transmit Antennas changed - by loading
        % a session or changing the GUI value.
        %
        % Exclude cyclic shift as for all transmission dialogs we want to
        % update cyclic shift controls but may choose to do nothing else if
        % Transmit Antennas is changed. Therefore allows this function to be
        % implemented empty rather than forcing all methods to call
        % updateCyclicShifts().
        %
        % For Non-HT no specific action require so empty method.
        end

        function updateCyclicShifts(obj)
        % Update cyclic shift GUI based on dependent properties. This method
        % should be overloaded by each transmission format and called by each
        % dependent property change method, i.e. numTransmitAntennasChanged.
            [isVis,numTxThresh] = isCyclicShiftsVisible(obj);
            if isVis
                % Create a vector of cyclic shifts per antenna to prompt the user
                obj.CyclicShiftsGUI.(obj.EditValue) = ['[' num2str(-75*ones(1,obj.NumTransmitAntennas-numTxThresh)) ']'];
                obj.showCyclicShiftControl(true);
            else
                obj.showCyclicShiftControl(false);
            end
        end

        function validateCyclicShiftGUIValue(~,val,valstr)
        % Independent validation of GUI element value. Called by transmission
        % format dialogs to validate cyclic shifts.
            validateattributes(val, {'numeric'}, {'row', 'nonempty', 'real', 'integer','>=', -200, '<=', 0}, '', valstr);
        end

        function [vis,numTxThresh] = isCyclicShiftsVisible(cfg)
        % Returns true if the cyclic shift GUI option should be visible
            numTxThresh = 8; % Threshold over which cyclic shifts must be specified
            if cfg.NumTransmitAntennas>numTxThresh
                vis = true;
            else
                vis = false;
            end
        end

        function updateBandwidthOpeartion(obj)
        % Update elements dependent on this and other properties
            setVisible(obj, 'BandwidthOperation', obj.SignalChannelBandwidth);
        end

        function updateScramblerVisibility(obj)
        % Show either ScramblerInitialization or InitialScramblerSequence
        % depending on SignalChannelBandwidth

            showInitScramSeq = obj.SignalChannelBandwidth;
            obj.showInitialScramblerSequence(showInitScramSeq)
            layoutUIControls(obj.Parent.GenerationDialog); % need to insert the new visible properties to Accordion panel
        end
    end

    methods (Access = private)
        % Made new methods private to be clear that they are not to be called
        % by subclasses
        function numTransmitAntennasChangedGUI(obj, ~)
        % Update elements when Transmit antennas GUI element changed

        % Independent validation of GUI element value
            try
                val = obj.NumTransmitAntennas;
                validateattributes(val, {'numeric'}, {'scalar', 'real', 'integer','>=', 1}, '', 'Transmit antennas');
            catch e
                obj.errorFromException(e);
                return % Do not take further action
            end
            obj.numTransmitAntennasChanged(); % Implemented by HT to control STS etc.
            obj.updateCyclicShifts();
            obj.layoutUIControls();
        end

        function cyclicShiftsChangedGUI(obj, ~)
        % Independent validation of GUI element value
            try
                obj.validateCyclicShiftGUIValue(obj.CyclicShifts,'Cyclic shifts')
            catch e
                obj.errorFromException(e);
            end
        end

        function showCyclicShiftControl(obj,flag)
        % Set cyclic shift GUI visibility
            setVisible(obj, 'CyclicShifts', flag);
        end

        function SignalChannelBandwidthChangedGUI(obj, ~)
        % Update elements when SignalChannelBandwidth GUI element changed
            obj.updateBandwidthOpeartion();
            obj.updateScramblerVisibility();

            obj.layoutUIControls();
            generationDialog = obj.Parent.GenerationDialog;
            layoutUIControls(generationDialog);
        end

        function showInitialScramblerSequence(obj,flag)
        % Set the generation dialog to show initial scrambler sequence (true)
        % or scrambler initialization (false)
            setVisible(obj.Parent.GenerationDialog, 'ScramblerInitialization', ~flag);
            setVisible(obj.Parent.GenerationDialog, 'InitialScramblerSequence', flag);
        end
    end
end
