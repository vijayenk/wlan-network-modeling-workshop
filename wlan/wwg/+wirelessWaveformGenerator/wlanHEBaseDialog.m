classdef wlanHEBaseDialog < wirelessWaveformGenerator.wlanHEEHTBaseDialog
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        HELTFType
        HighDoppler
    end

    properties (Hidden)
        HEFormatType = 'charPopup'
        HEFormatDropDown = {'HE single-user', 'HE extended range single-user', 'HE multi-user', 'HE trigger-based', 'Non high throughput (Non-HT)'}
        HEFormatLabel
        HEFormatGUI
        PreHECyclicShiftsType = 'numericEdit'
        PreHECyclicShiftsLabel
        PreHECyclicShiftsGUI
        HELTFTypeType = 'charPopup'
        HELTFTypeDropDown = {'1x', '2x', '4x'}
        HELTFTypeLabel
        HELTFTypeGUI
        HighDopplerType = 'checkbox'
        HighDopplerLabel
        HighDopplerGUI
        MidamblePeriodicityType = 'numericPopup'
        MidamblePeriodicityDropDown = {'10', '20'}
        MidamblePeriodicityLabel
        MidamblePeriodicityGUI
    end

    methods (Static)
        function hPropDb = getPropertySet(~)
            hPropDb = extmgr.PropertySet(...
                'Visualizations','mxArray',{'RU & Subcarrier Assignment'});
        end
    end

    methods

        function obj = wlanHEBaseDialog(parent)
            obj@wirelessWaveformGenerator.wlanHEEHTBaseDialog(parent); % call base constructor
            weakObj = matlab.lang.WeakReference(obj);

            % Specify callbacks for changes to HE GUI elements which impact
            % other elements (may also be used in subclass dialogs)
            obj.HEFormatGUI.(obj.Callback)          = @(a,b) heFormatChanged(weakObj.Handle, []);
            obj.PreHECyclicShiftsGUI.(obj.Callback) = @(a,b) preHECyclicShiftsChanged(weakObj.Handle, []);
            obj.HighDopplerGUI.(obj.Callback)       = @(a,b) highDopplerChangedGUI(weakObj.Handle, []);
            obj.TXOPDurationGUI.(obj.Callback)      = @(a,b) txopDurationChangedGUI(weakObj.Handle,[]);
        end

        function props = props2ExcludeFromConfig(obj)
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanVHTDialog(obj);
            props = [props {'HEFormat', 'PSDULength'}];
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % Return a cell array of properties which should not be "set" using
        % NV pairs when configuring the object in the generated MATLAB
        % script

            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanVHTDialog(obj);
            props = [props {'HEFormat', 'PSDULength'}];

            if ~obj.isCyclicShiftsVisible()
                props = [props 'PreHECyclicShifts'];
            end

            if ~obj.HighDoppler
                props = [props 'MidamblePeriodicity'];
            end
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g Non-HT)
            adjustSpec@wirelessWaveformGenerator.wlanHEEHTBaseDialog(obj);
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:HETitle'));
            miS = [' ' char(956) 's'];
            obj.GuardIntervalDropDown = {['0.8' miS], ['1.6' miS], ['3.2' miS]};
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanHTDialog(obj);
            % skip setting of Tx Format (for 11ac)
        end

        function config = applyConfiguration(obj, config)
        % Called when a session is loaded and a configuration is applied to
        % the GUI

            appObj = obj.Parent.WaveformGenerator;
            if isa(config, 'wlanHESUConfig')
                appObj.setParametersDialog('wirelessWaveformGenerator.wlanHESUDialog');
            elseif isa(config, 'wlanHETBConfig')
                appObj.setParametersDialog('wirelessWaveformGenerator.wlanHETBDialog');
            elseif isa(config, 'wlanNonHTConfig')
                appObj.setParametersDialog('wirelessWaveformGenerator.axNonHTDialog');
            else
                % MU case
                % we need to transition to new dialog first:
                appObj.setParametersDialog('wirelessWaveformGenerator.wlanHEMUDialog');
            end

            currDialog = obj.Parent.CurrentDialog;
            resetPopupStrings(currDialog); % Reset popup options so when loading a session all values can be set
            applyConfiguration@wirelessWaveformGenerator.WaveformConfigurationDialog(currDialog, config);

            % Update the visibility and forced values of GUI elements when configuration loaded
            updateDialogFromConfig(currDialog, config);
        end

        function updatePSDU(obj)
        % HE config objects have a method, not a property for PSDULength
            try
                obj.PSDULength = obj.getPSDULength();
            catch
                % in case the object is still initializing and PSDU cannot be calculated
            end
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            restoreDefaults@wirelessWaveformGenerator.wlanHEEHTBaseDialog(obj);
            obj.HEFormat = 'HE single-user';
            obj.NumTransmitAntennas = 1;
            obj.PreHECyclicShifts = -75;
            obj.STBC = false;
            obj.GuardInterval = '3.2'; % No μ character needed as wlanHEEHTBaseDialog.setGuardInterval() adds it
            obj.HELTFType = '4x';
            obj.TXOPDuration = 127;
            obj.HighDoppler = false;
            obj.MidamblePeriodicity = 10;
        end

        function heFormatChanged(obj, ~)
            appObj = obj.Parent.WaveformGenerator;
            freezeApp(appObj);

            obj.shouldLayoutControls = false;
            firstTimeMU = false;
            switch obj.HEFormat
              case 'HE multi-user'
                className = 'wirelessWaveformGenerator.wlanHEMUDialog';
                firstTimeMU = ~isKey(obj.Parent.DialogsMap, className);
              case 'HE trigger-based'
                className = 'wirelessWaveformGenerator.wlanHETBDialog';
              case 'Non high throughput (Non-HT)'
                className = 'wirelessWaveformGenerator.axNonHTDialog';
              otherwise % Single-user, extended range single user
                className = 'wirelessWaveformGenerator.wlanHESUDialog';
            end

            if ~isempty(appObj) && ~strcmp(className, class(appObj.pParameters.CurrentDialog))
                % init has completed
                appObj.setParametersDialog(className);
            end
            currDialog = obj.Parent.CurrentDialog;
            currDialog.HEFormat = obj.HEFormat;

            if ~firstTimeMU
                if strcmp(obj.HEFormat, 'HE multi-user')
                    % entering a multi-user configuration; enable new figures
                    currDialog.setExtraConfigFigVisibility(true);

                elseif isa(obj, 'wirelessWaveformGenerator.wlanHEMUDialog')
                    % leaving a multi-user configuration; disable old figures
                    obj.setExtraConfigFigVisibility(false);
                end
                drawnow; % otherwise tiles may be misplaced upon MU <-> TB changes
                appObj.setScopeLayout();
            end

            if any(strcmp(obj.HEFormat, {'HE single-user','HE extended range single-user'}))
                % Update visibility of HE SU
                currDialog.updateSUERVisibility();
            elseif strcmp(obj.HEFormat, 'Non high throughput (Non-HT)')
                % Update visibility of Non-HT
                currDialog.update11axNonHTVisibility();
                currDialog.setVisualState('RU & Subcarrier Assignment', false);
            end

            obj.shouldLayoutControls = true;
            currDialog.layoutUIControls();
            obj.layoutPanels();

            unfreezeApp(appObj);
        end

        function b = isMultiUser(obj)
            b = strcmp(obj.HEFormat, 'HE multi-user');
        end

        function highDopplerChanged(obj, ~)
            setVisible(obj, 'MidamblePeriodicity', obj.HighDoppler);
        end
        function highDopplerChangedGUI(obj, ~)
            highDopplerChanged(obj);
            layoutUIControls(obj);
        end

        function pLen = getPSDULength(obj)
        % Fetch from the config obj
            cfg = obj.getConfiguration;
            pLen = cfg.getPSDULength();
        end
        function psduChanged(obj)
            setVisible(obj, 'PSDULength', length(obj.PSDULength)<=5);
        end
        function str = psduGetterStr(~, cfgStr)
            str = ['getPSDULength(' cfgStr ')'];
        end
        function v = get.HighDoppler(obj)
            v = getCheckboxVal(obj, 'HighDoppler');
        end
        function set.HighDoppler(obj, val)
            setCheckboxVal(obj, 'HighDoppler', val);
            obj.highDopplerChanged();
        end

        function n = get.HELTFType(obj)
            n = getDropdownVal(obj, 'HELTFType');
            n = str2double(replace(n, 'x', ''));
        end
        function set.HELTFType(obj, val)
            setDropdownStartingVal(obj, 'HELTFType', num2str(val(1)));
        end
    end

    methods (Access = protected, Abstract)
        % Returns true if the cyclic shift GUI option should be visible and the
        % number of antenna threshold.
        % Implemented by HE SU and HE MU
        [vis,numTxThresh] = isCyclicShiftsVisible(obj);
    end

    methods (Access = protected)
        function updateCyclicShifts(obj)
        % Update cyclic shift GUI based on dependent properties. This method
        % should be overloaded by each transmission format and called by each
        % dependent property change method, i.e. numTransmitAntennasChanged.
        % isCyclicShiftsVisible() is implemented by SU and MU dialogs as
        % conditions different for each
            [isVis,numTxThresh] = obj.isCyclicShiftsVisible();
            if isVis
                % Create a vector of cyclic shifts per antenna to prompt the user
                obj.PreHECyclicShiftsGUI.(obj.EditValue) = ['[' num2str(-75*ones(1,obj.NumTransmitAntennas-numTxThresh)) ']'];
                obj.showPreHECyclicShiftControl(true);
            else
                obj.showPreHECyclicShiftControl(false);
            end
        end
    end

    methods (Access = private)
        function preHECyclicShiftsChanged(obj, ~)
        % Independent validation of GUI element value
            try
                obj.validateCyclicShiftGUIValue(obj.PreHECyclicShifts,'Pre-HE cyclic shifts');
            catch e
                obj.errorFromException(e);
            end
        end

        function showPreHECyclicShiftControl(obj,flag)
            setVisible(obj, 'PreHECyclicShifts', flag);
        end

        function txopDurationChangedGUI(obj, ~)
            try
                val = obj.TXOPDuration;
                validateattributes(val, {'numeric'}, {'real', 'integer', 'scalar', '>=', 0, '<=', 127}, '', 'TXOP duration');
            catch e
                obj.errorFromException(e);
            end
        end
    end
end
