classdef wlanHETBDialog < wirelessWaveformGenerator.wlanHESUBaseDialog
% Dialog for HE TB waveform

%   Copyright 2021-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        TriggerMethod
        DefaultPEDuration
    end

    properties (Hidden)
        TriggerMethodType = 'charPopup'
        TriggerMethodLabel
        TriggerMethodGUI
        TriggerMethodDropDown = {'Trigger frame', 'TRS'}

        % Other RU size element properties defined in HE SU base. Popup only
        % for HE TB so defined here
        RUSizeDropDown = {'26', '52', '106', '242'}

        RUIndexType = 'numericEdit'
        RUIndexLabel
        RUIndexGUI

        PreHEPowerScalingFactorType = 'numericEdit'
        PreHEPowerScalingFactorLabel
        PreHEPowerScalingFactorGUI

        StartingSpaceTimeStreamType = 'numericPopup'
        StartingSpaceTimeStreamLabel
        StartingSpaceTimeStreamGUI
        StartingSpaceTimeStreamDropDown = {'1', '2', '3', '4', '5', '6', '7', '8'}

        PreFECPaddingFactorType = 'numericPopup'
        PreFECPaddingFactorLabel
        PreFECPaddingFactorGUI
        PreFECPaddingFactorDropDown = {'1', '2', '3', '4'}

        LDPCExtraSymbolType = 'checkbox'
        LDPCExtraSymbolLabel
        LDPCExtraSymbolGUI

        PEDisambiguityType = 'checkbox'
        PEDisambiguityLabel
        PEDisambiguityGUI

        LSIGLengthType = 'numericEdit'
        LSIGLengthLabel
        LSIGLengthGUI

        NumDataSymbolsType = 'numericEdit'
        NumDataSymbolsLabel
        NumDataSymbolsGUI

        DefaultPEDurationType = 'numericPopup'
        DefaultPEDurationLabel
        DefaultPEDurationGUI
        DefaultPEDurationDropDown = {'0 ', '2', '4', '8', '12', '16'}

        NumHELTFSymbolsType = 'numericPopup'
        NumHELTFSymbolsLabel
        NumHELTFSymbolsGUI
        NumHELTFSymbolsDropDown = {'1', '2', '4', '6', '8'}

        SingleStreamPilotsType = 'checkbox'
        SingleStreamPilotsLabel
        SingleStreamPilotsGUI

        SpatialReuse1Type = 'numericPopup'
        SpatialReuse1DropDown = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'}
        SpatialReuse1Label
        SpatialReuse1GUI

        SpatialReuse2Type = 'numericPopup'
        SpatialReuse2DropDown = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'}
        SpatialReuse2Label
        SpatialReuse2GUI

        SpatialReuse3Type = 'numericPopup'
        SpatialReuse3DropDown = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'}
        SpatialReuse3Label
        SpatialReuse3GUI

        SpatialReuse4Type = 'numericPopup'
        SpatialReuse4DropDown = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'}
        SpatialReuse4Label
        SpatialReuse4GUI

        HESIGAReservedBitsType = 'numericEdit'
        HESIGAReservedBitsLabel
        HESIGAReservedBitsGUI
    end

    methods
        function obj = wlanHETBDialog(parent)
            obj@wirelessWaveformGenerator.wlanHESUBaseDialog(parent); % call base constructor

            % Callbacks for GUI elements which have other dependencies
            obj.TriggerMethodGUI.(obj.Callback)           = @(a,b) triggerMethodChangedGUI(obj, []);
            obj.RUSizeGUI.(obj.Callback)                  = @(a,b) ruSizeChangedGUI(obj, []);
            obj.RUIndexGUI.(obj.Callback)                 = @(a,b) ruIndexChangedGUI(obj, []);
            obj.PreHEPowerScalingFactorGUI.(obj.Callback) = @(a,b) preHEPowerScalingFactorChangedGUI(obj, []);
            obj.LSIGLengthGUI.(obj.Callback)              = @(a,b) lsigLengthChangedGUI(obj, []);
            obj.HESIGAReservedBitsGUI.(obj.Callback)      = @(a,b) hesigaReservedBitsChangedGUI(obj, []);
            obj.NumDataSymbolsGUI.(obj.Callback)          = @(a,b) numDataSymbolChangedGUI(obj, []);
            obj.StartingSpaceTimeStreamGUI.(obj.Callback) = @(a,b) startingSpaceTimeStreamChangedGUI(obj, []);
            obj.PreFECPaddingFactorGUI.(obj.Callback)     = @(a,b) updatePSDU(obj);
            obj.LDPCExtraSymbolGUI.(obj.Callback)         = @(a,b) updatePSDU(obj);
            obj.PEDisambiguityGUI.(obj.Callback)          = @(a,b) updatePSDU(obj);
            obj.MidamblePeriodicityGUI.(obj.Callback)     = @(a,b) updatePSDU(obj);
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanHETBConfig; % so that update happens before construction end
            obj.configGenFcn = @wlanHETBConfig;
            obj.configGenVar = 'heTBCfg';
        end

        function props = displayOrder(~)
            props = {'HEFormat'; 'TriggerMethod'; ...
                     'ChannelBandwidth'; 'RUSize'; 'RUIndex'; ...
                     'PreHEPowerScalingFactor';...
                     'NumTransmitAntennas'; 'PreHECyclicShifts'; ...
                     'NumSpaceTimeStreams'; 'StartingSpaceTimeStream'; 'SpatialMapping'; ...
                     'SpatialMappingMatrix'; ...
                     'STBC'; 'MCS'; 'DCM'; 'ChannelCoding'; 'PreFECPaddingFactor'; 'LDPCExtraSymbol'; 'PEDisambiguity'; ...
                     'LSIGLength'; 'NumDataSymbols'; ...
                     'DefaultPEDuration'; ...
                     'GuardInterval'; 'HELTFType'; 'NumHELTFSymbols'; ...
                     'SingleStreamPilots'; 'HighDoppler'; 'MidamblePeriodicity';
                     'PSDULength'; ...
                     'BSSColor'; ...
                     'SpatialReuse1'; 'SpatialReuse2'; 'SpatialReuse3'; 'SpatialReuse4'; ...
                     'TXOPDuration'; ...
                     'HESIGAReservedBits'};
        end

        function config = getConfiguration(obj)
            config = getConfiguration@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
        end

        function config = getConfigurationForSave(obj)
        % Default method takes care of everything in the config object that is present in displayOrder
            config = getConfigurationForSave@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
        end

        function updateTBVisibility(obj)
        % Set conditional visibility and values of elements
        % This is additionally called in wlanHEBaseDialog/applyConfiguration()

        % Update in reverse order from bottom to top so that top level
        % visibility is implemented last to make sure correct fields are
        % disabled
            obj.updateRUSize();
            obj.updateNumHELTFSymbols();
            obj.updateDCM();
            obj.updateSTBC();
            obj.updateChannelCodingLDPCExtraSym();
            obj.updateHighDoppler();
            obj.updateMCS();
            obj.updateStartingSpaceTimeStreams();
            obj.triggerMethodChanged();
            obj.updatePSDU();
            obj.updateSampleRate();

            % Update dialog visibility
            obj.layoutUIControls();
        end

        function props = props2ExcludeFromConfig(obj)
        % Exclude properties which are only app controls from being set as
        % in the configuration object
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % When exporting MATLAB script do not show properties which are used
        % in the app but not in the configuration object, or conditionally
        % visible properties
            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            if strcmp(obj.TriggerMethod,'TriggerFrame')
                % If Trigger hide:
                props = [props {'DefaultPEDuration' 'NumDataSymbols'}];
            else
                % If TRS hide:
                props = [props {'LSIGLength' 'PEDisambiguity'}];
            end

            if strcmp(obj.ChannelCoding, 'BCC')
                props = [props 'LDPCExtraSymbol'];
            end
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Format: HE TB'' newline ...' newline ...
                   '''Method: '' ' obj.configGenVar '.TriggerMethod newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''Coding: '' num2str(' obj.configGenVar '.ChannelCoding) newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function addConfigCode(obj, sw)
        % Add any custom object configuration code when exporting MATLAB
        % script
            addConfigCode@wirelessWaveformGenerator.wlanHEBaseDialog(obj, sw);
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g non-HT)
            adjustSpec@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            obj.resetPopupStrings();
        end

        function adjustDialog(obj)
        % Adjustments of UI elements after they have been created - i.e.
        % disable
            adjustDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);

            % Set conditional visibility and values of elements
            obj.updateTBVisibility();

            % Update dialog visibility
            obj.layoutUIControls();
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            obj.HEFormat = 'HE trigger-based'; % In case we return to 11ax, after it was set to MU and user left 11ax.

            % Make sure visibility set when changing from another format
            updateTBVisibility(obj);
        end

        function updateDialogFromConfig(obj,~)
        % Update the visibility and forced values of GUI elements when configuration loaded
            obj.HEFormat = 'HE trigger-based';
            updateTBVisibility(obj); % Update the visibility and forced values of GUI elements when configuration loaded
        end

        function defaultVisualLayout(obj)
            obj.setVisualState(obj.visualNames{1}, true);   % RU & Subcarriers
        end

        function resetPopupStrings(obj)
        % Reset popup menu options
            resetPopupStrings@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            % Trigger-based only supports 1.6 and 3.2 GI
            miS = [' ' char(956) 's'];
            obj.GuardIntervalDropDown = {['1.6' miS], ['3.2' miS]};
            obj.GuardIntervalGUI.(obj.DropdownValues) = obj.GuardIntervalDropDown;

            % Set DefaultPEDuration so we can use the microseconds symbol
            miS = [' ' char(956) 's'];
            obj.DefaultPEDurationDropDown = {['0' miS], ['4' miS], ['8' miS], ['12' miS], ['16' miS]};
            obj.DefaultPEDurationGUI.(obj.DropdownValues) = obj.DefaultPEDurationDropDown;

            % Configure RUSize as popupmenu as popupmenu for HE TB
            obj.RUSizeType = 'numericPopup';
        end

        function restoreDefaults(obj)
            obj.HEFormat = 'HE trigger-based';
            obj.TriggerMethod = 'Trigger frame';
            obj.ChannelBandwidth = 'CBW20';
            obj.RUSize = 242;
            obj.RUIndex = 1;
            obj.PreHEPowerScalingFactor = 1;
            obj.NumTransmitAntennas = 1;
            obj.PreHECyclicShifts = -75;
            obj.NumSpaceTimeStreams = 1;
            obj.StartingSpaceTimeStream = 1;
            obj.SpatialMapping = 'Direct';
            obj.SpatialMappingMatrix = 1;
            obj.STBC = 0;
            obj.MCS = '0 (BPSK, 1/2 rate)';
            obj.DCM = 0;
            obj.ChannelCoding = 'LDPC';
            obj.PreFECPaddingFactor = 4;
            obj.LDPCExtraSymbol = 0;
            obj.PEDisambiguity = 0;
            obj.LSIGLength = 142;
            obj.NumDataSymbols = 10;
            obj.DefaultPEDuration = 0;
            obj.GuardInterval = '3.2'; % No μ character needed as wlanHEEHTBaseDialog.setGuardInterval() adds it
            obj.HELTFType = '4x';
            obj.NumHELTFSymbols = 1;
            obj.SingleStreamPilots = 1;
            obj.HighDoppler = false;
            obj.MidamblePeriodicity = 10;
            obj.BSSColor = 0;
            obj.SpatialReuse1 = 15;
            obj.SpatialReuse2 = 15;
            obj.SpatialReuse3 = 15;
            obj.SpatialReuse4 = 15;
            obj.TXOPDuration = 127;
            obj.HESIGAReservedBits = [1 1 1 1 1 1 1 1 1]';
            obj.PSDULength = obj.getPSDULength(); % update
        end

        function numSpaceTimeStreamsChanged(obj, ~)
        % Common with HE SU
            numSpaceTimeStreamsChanged@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            % Update elements which are also dependent on other elements
            obj.updateStartingSpaceTimeStreams();
            obj.updateNumHELTFSymbols();
        end

        % ChannelBandwidth - set/get defined in VHT
        function channelBandwidthChanged(obj, ~)
        % Update properties only dependent on channel bandwidth
            obj.updateRUSize();
            % Update other dependent properties
            obj.updateChannelCodingLDPCExtraSym();
            obj.updateSampleRate();
        end

        % TriggerMethod
        function n = get.TriggerMethod(obj)
            n = getDropdownVal(obj, 'TriggerMethod');
            % GUI option includes a space so remove this when setting
            % wlanHETBConfig property
            if strcmp(n,'Trigger frame')
                n = 'TriggerFrame';
            end
        end
        function set.TriggerMethod(obj, val)
        % GUI option includes a space so add this when setting
        % GUI element from wlanHETBConfig value
            if strcmp(val,'TriggerFrame')
                val = 'Trigger frame';
            end
            setDropdownVal(obj, 'TriggerMethod', val);
        end

        function ruIndexChangedGUI(obj, ~)
            try
                val = obj.RUIndex;
                validateattributes(val, {'numeric'}, {'real', 'integer', 'scalar', '>=', 1, '<=', 74}, '', 'RU index');
            catch e
                obj.errorFromException(e);
            end
        end

        % STBC - VHT
        function updateSTBC(obj)
        % Update STBC value and enable/disable depending on other properties

        % Dependencies common with HE SU
            updateSTBC@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            % Additionally force STBC=false and disable if TRS used
            if strcmp(obj.TriggerMethod,'TRS')
                obj.STBC = false;
                setEnable(obj, 'STBC', false);
            end
        end

        % ChannelCoding - set/get defined in VHT
        function channelCodingChangedGUI(obj,~)
        % Update GUI elements depending on this and other elements
            obj.updateChannelCodingLDPCExtraSym();
            obj.updatePSDU();

            obj.layoutUIControls();
        end

        % DefaultPEDuration
        function n = get.DefaultPEDuration(obj)
            n = getDropdownVal(obj, 'DefaultPEDuration');
            % remove the microsecond unit
            n = str2double(n(1:end-3));
        end
        function set.DefaultPEDuration(obj, val)
        % add the microsecond unit:
            mi = char(956);
            val = [num2str(val) ' ' mi 's'];
            setDropdownVal(obj, 'DefaultPEDuration', val);
        end

        function updateMCS(obj)
        % Update value and options of MCS based on Trigger method and RU size

        % LDPC is not valid for RU sizes < 484 when TRS used therefore limit
        % MCS options as appropriate
            if obj.onlyLDPCValid()
                options = obj.MCSDropDownFull(1:end-2);
            else
                options = obj.MCSDropDownFull;
            end
            obj.MCSGUI.(obj.DropdownValues) = options;
        end

        function highDopplerChangedGUI(obj, ~)
            % Update PSDULength if HighDoppler changed as the midamble means less data
            highDopplerChangedGUI@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            updatePSDU(obj);
        end
    end

    methods (Access = private)
        function triggerMethodChanged(obj, ~)
            isTRS = strcmp(obj.TriggerMethod,'TRS');

            % If TRS show:
            setVisible(obj, {'DefaultPEDuration', 'NumDataSymbols'}, isTRS);
            % Don't force hiding MidamblePeriodicity as setting HighDoppler to
            % false will do this

            % If Trigger show:
            setVisible(obj, {'LSIGLength', 'PEDisambiguity'}, ~isTRS);

            % TRS has certain hardwired values
            if isTRS
                trsGUI = 'off';

                obj.NumSpaceTimeStreams = 1;
                % StartingSpaceTimeStream set in updateStartingSpaceTimeStreams() as popup dependent on other properties
                % ChannelCoding set in updateChannelCoding() as popup dependent on other properties
                % STBC set in updateSTBC() as value dependent on other properties
                obj.PreFECPaddingFactor = 4;
                % HighDoppler set in updateHighDoppler() as value dependent on other properties
                obj.SingleStreamPilots = true;
                % NumHELTFSymbols set in updateNumHELTFSymbols() as popup dependent on other properties
                obj.SpatialReuse1 = 15;
                obj.SpatialReuse2 = 15;
                obj.SpatialReuse3 = 15;
                obj.SpatialReuse4 = 15;
                obj.HESIGAReservedBits = [1 1 1 1 1 1 1 1 1]';
            else
                trsGUI = 'on';
            end

            % Disable properties which are hardwired for TRS
            setEnable(obj, {'NumSpaceTimeStreams', 'SingleStreamPilots', 'PreFECPaddingFactor', ...
                            'SpatialReuse1', 'SpatialReuse2', 'SpatialReuse3', 'SpatialReuse4', 'HESIGAReservedBits'}, trsGUI);
        end
        function triggerMethodChangedGUI(obj, ~)
        % Update properties only dependent on trigger method
            obj.triggerMethodChanged();
            % Update other dependent properties
            obj.updateSTBC();
            obj.updateMCS();
            obj.updateDCM(); % Dependent on STBC which may be set in updateSTBC
            obj.updateChannelCodingLDPCExtraSym();
            obj.updateStartingSpaceTimeStreams();
            obj.updateNumHELTFSymbols();
            obj.updateHighDoppler();

            obj.updatePSDU();
            obj.layoutUIControls();
        end

        function updateRUSize(obj, ~)
        % Change options and value of RUSize based on ChannelBandwidth
            options = {'26', '52', '106', '242'};
            switch obj.ChannelBandwidth
              case 'CBW20'
                minVal = 4; % 242
              case 'CBW40'
                options = [options {'484'}];
                minVal = 5; % 484
              case 'CBW80'
                options = [options {'484','996'}];
                minVal = 6; % 996
              case 'CBW160'
                options = [options {'484','996','1992'}];
                minVal = 7; % 1992
            end
            % If switching from a large BW to small make sure RU size selected switched to a valid value
            idx = min(find(strcmp(num2str(obj.RUSize), obj.RUSizeGUI.(obj.DropdownValues))), minVal);
            obj.RUSizeGUI.Value = obj.RUSizeGUI.Items{idx};
            obj.RUSizeGUI.(obj.DropdownValues) = options;
        end
        function ruSizeChangedGUI(obj, ~)
        % Update dependent properties
            obj.updateMCS()
            obj.updateChannelCodingLDPCExtraSym();
            obj.updatePSDU();

            obj.layoutUIControls();
        end

        function preHEPowerScalingFactorChangedGUI(obj, ~)
        % Validate value
            try
                val = obj.PreHEPowerScalingFactor;
                validateattributes(val, {'numeric'}, {'real', 'scalar', '>=', 1/sqrt(2), '<=', 1}, '', 'Pre-HE scaling factor');
            catch e
                obj.errorFromException(e);
            end
        end

        function lsigLengthChangedGUI(obj, ~)
        % Validate value
            try
                val = obj.LSIGLength;
                validateattributes(val, {'numeric'}, {'real', 'scalar', 'integer', '>=', 1, '<=', 4093}, '', 'L-SIG length');
                coder.internal.errorIf(mod(val,3)~=1, 'wlan:shared:InvalidLSIGLengthVal');
            catch e
                obj.errorFromException(e);
            end
            % Update dependent elements
            obj.updatePSDU();
        end

        function numDataSymbolChangedGUI(obj, ~)
        % Validate value
            try
                val = obj.NumDataSymbols;
                validateattributes(val, {'numeric'}, {'real', 'scalar', 'integer', '>=', 1}, '', 'Num data symbols');
            catch e
                obj.errorFromException(e);
            end
            % Update dependent elements
            obj.updatePSDU();
        end

        function startingSpaceTimeStreamChangedGUI(obj, ~)
        % Update dependent properties
            obj.updateNumHELTFSymbols()
        end

        function hesigaReservedBitsChangedGUI(obj, ~)
        % Validate value
            try
                val = obj.HESIGAReservedBits;
                validateattributes(val, {'numeric'}, {'integer','numel',9}, '', 'HE-SIG-A reserved bits');
            catch e
                obj.errorFromException(e);
            end
        end

        function updateLDPCExtraSym(obj)
        % Update LDPCExtraSymbol value and enable/disable based on:
        % TriggerMethod, ChannelBandwidth, and ChannelCoding
            isvis = true;
            if strcmp(obj.TriggerMethod,'TRS')
                if obj.RUSize<484
                    isvis = false; % BCC mandatory so hide
                elseif strcmp(obj.ChannelCoding,'LDPC')
                    obj.LDPCExtraSymbol = 1;
                    isvis = true;
                end
            else
                isvis = strcmp(obj.ChannelCoding,'LDPC');
            end
            val = strcmp(obj.TriggerMethod,'TRS') && obj.RUSize>=484 && strcmp(obj.ChannelCoding,'LDPC');
            setEnable( obj, 'LDPCExtraSymbol', ~val);
            setVisible(obj, 'LDPCExtraSymbol', isvis);
        end

        function updateChannelCodingLDPCExtraSym(obj)
        % Update ChannelCoding and LDPCExtraSymbol properties values and
        % enable/disable based on:
        % TriggerMethod, ChannelBandwidth, and ChannelCoding
            obj.updateChannelCoding(); % Includes LDPC extra sym
        end

        function isvalid = onlyLDPCValid(obj)
        % Returns true if LDPC is the only valid channel coding option
            isvalid = strcmp(obj.TriggerMethod,'TRS') && obj.RUSize<484;
        end

        function updateStartingSpaceTimeStreams(obj)
        % Update value and options of starting space time stream based on num
        % space time streams and trigger method

            val = strcmp(obj.TriggerMethod,'TRS');
            if val
                % Force 1 for TRS
                obj.StartingSpaceTimeStreamGUI.Value = '1';
                obj.StartingSpaceTimeStreamGUI.(obj.DropdownValues) = obj.StartingSpaceTimeStreamDropDown;
            else
                % Configure options for starting space-time stream index based on
                % number of space-time streams
                maxVal = (9-obj.NumSpaceTimeStreams);
                options = obj.StartingSpaceTimeStreamDropDown(1:maxVal);

                obj.StartingSpaceTimeStreamGUI.(obj.DropdownValues) = options;
            end
            setEnable(obj, 'StartingSpaceTimeStream', ~val);
        end

        function updateNumHELTFSymbols(obj)
        % Update options for HELTFSymbols based on:
        % number of space-time streams, starting space time stream, and trigger method

            if strcmp(obj.TriggerMethod,'TRS')
                % Force 1 for TRS
                obj.NumHELTFSymbolsGUI.(obj.DropdownValues) = obj.NumHELTFSymbolsDropDown;
                obj.NumHELTFSymbolsGUI.Value = obj.NumHELTFSymbolsGUI.Items{(strcmp(num2str(1),obj.NumHELTFSymbolsDropDown))};
            else
                % If switching from a small number of STS to large make sure num LTF
                % index selected switched to a valid value
                currentNumLTF = obj.NumHELTFSymbols;
                minTotalSTS = obj.NumSpaceTimeStreams+obj.StartingSpaceTimeStream-1;
                minNumLTF = wlan.internal.numVHTLTFSymbols(minTotalSTS);
                minVal = find(strcmp(num2str(minNumLTF),obj.NumHELTFSymbolsDropDown));

                setNumLTF = max(currentNumLTF,minNumLTF);
                options = obj.NumHELTFSymbolsDropDown(minVal:end);
                obj.NumHELTFSymbolsGUI.Value = options{(strcmp(num2str(setNumLTF),options))};
                obj.NumHELTFSymbolsGUI.(obj.DropdownValues) = options;
            end
            setEnable(obj, 'NumHELTFSymbols', ~strcmp(obj.TriggerMethod,'TRS'));
        end
    end

    methods (Access = protected)
        function [vis,numTxThresh] = isCyclicShiftsVisible(obj)
        % Returns true if the cyclic shift GUI option should be visible
        % Called in HE Base
            numTxThresh = 8; % Threshold over which cyclic shifts must be specified
            if obj.NumTransmitAntennas>numTxThresh
                vis = true;
            else
                vis = false;
            end
        end

        function updateChannelCoding(obj)
        % This method is called within HE SU Base of ChannelCoding callback
        % etc so overload here to deal with trigger specific elements
        %
        % Update ChannelCoding value and enable/disable based on:
        % RUSize, NumSpaceTimeStreams, MCS, and TriggerMethod

        % Dependencies common with HE SU
            updateChannelCoding@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            % Update ChannelCoding value and enable/disable based on:
            % TriggerMethod and ChannelBandwidth
            if obj.onlyLDPCValid()
                obj.ChannelCoding = 'BCC';
                obj.ChannelCodingGUI.Enable = 'off';
                setEnable(obj, 'ChannelCoding', false);
            end

            % Update LDPC extra OFDM symbol as channel coding may have been
            % updated
            obj.updateLDPCExtraSym();
        end

        function updateHighDoppler(obj)
        % Change value and enable/disable HighDoppler based on
        % NumSpaceTimeStreams and TriggerMethod

        % Dependencies common with HE SU
            updateHighDoppler@wirelessWaveformGenerator.wlanHESUBaseDialog(obj);

            if strcmp(obj.TriggerMethod,'TRS')
                obj.HighDoppler = false;
                setEnable(obj, 'HighDoppler', false);
            end
        end
    end
end
