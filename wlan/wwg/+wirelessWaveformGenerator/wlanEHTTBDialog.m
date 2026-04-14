classdef wlanEHTTBDialog < wirelessWaveformGenerator.wlanEHTBaseDialog
% Dialog for EHT TB waveform

%   Copyright 2024-2025 The MathWorks, Inc.

    properties (Access=protected)
        userFigTag = 'UsersEHT_TB';
        ruFigTag = 'RUFigEHT_TB';
    end

    properties (Constant,Hidden)
        nameAdvDlg = 'wirelessWaveformGenerator.wlanEHTTBAdvancedParametersDialog';
    end

    properties % Public access
        EHTTBRUSizeType = 'numericEdit'
        EHTTBRUSizeLabel
        EHTTBRUSizeGUI

        EHTTBRUIndexType = 'numericEdit'
        EHTTBRUIndexLabel
        EHTTBRUIndexGUI

        PreEHTPowerScalingFactorType = 'numericEdit'
        PreEHTPowerScalingFactorLabel
        PreEHTPowerScalingFactorGUI

        EHTTBStartingSpaceTimeStreamType = 'numericPopup'
        EHTTBStartingSpaceTimeStreamDropDown = cellstr(string(1:8));
        EHTTBStartingSpaceTimeStreamLabel
        EHTTBStartingSpaceTimeStreamGUI

        EHTTBPreFECPaddingFactorType = 'numericPopup'
        EHTTBPreFECPaddingFactorDropDown = cellstr(string(1:4));
        EHTTBPreFECPaddingFactorLabel
        EHTTBPreFECPaddingFactorGUI

        EHTTBLDPCExtraSymbolType = 'checkbox'
        EHTTBLDPCExtraSymbolLabel
        EHTTBLDPCExtraSymbolGUI

        EHTTBPEDisambiguityType = 'checkbox'
        EHTTBPEDisambiguityLabel
        EHTTBPEDisambiguityGUI

        EHTTBLSIGLengthType = 'numericEdit'
        EHTTBLSIGLengthLabel
        EHTTBLSIGLengthGUI

        EHTTBNumEHTLTFSymbolsType = 'numericPopup'
        EHTTBNumEHTLTFSymbolsDropDown = cellstr(string([1 2:2:8]));
        EHTTBNumEHTLTFSymbolsLabel
        EHTTBNumEHTLTFSymbolsGUI

        EHTTBSpatialReuse1Type = 'numericEdit'
        EHTTBSpatialReuse1Label
        EHTTBSpatialReuse1GUI

        EHTTBSpatialReuse2Type = 'numericEdit'
        EHTTBSpatialReuse2Label
        EHTTBSpatialReuse2GUI

        EHTTBDisregardBitsUSIG1Type = 'numericEdit'
        EHTTBDisregardBitsUSIG1Label
        EHTTBDisregardBitsUSIG1GUI

        EHTTBDisregardBitsUSIG2Type = 'numericEdit'
        EHTTBDisregardBitsUSIG2Label
        EHTTBDisregardBitsUSIG2GUI

        EHTTBValidateBitUSIG2Type = 'checkbox'
        EHTTBValidateBitUSIG2Label
        EHTTBValidateBitUSIG2GUI
    end

    methods
        function obj = wlanEHTTBDialog(parent) % Constructor
            obj@wirelessWaveformGenerator.wlanEHTBaseDialog(parent); % Call the base constructor
            obj.ChannelCodingGUI.(obj.Callback) = @(a,b) ehttbChannelCodingChangedGUI(obj);
            obj.EHTTBRUSizeGUI.(obj.Callback) = @(a,b) ehttbRUSizeChangedGUI(obj);
            obj.EHTTBRUIndexGUI.(obj.Callback) = @(a,b) ehttbRUSizeChangedGUI(obj);
            obj.PreEHTPowerScalingFactorGUI.(obj.Callback) = @(a,b) preEHTPowerScalingFactorChangedGUI(obj);
            obj.EHTTBLSIGLengthGUI.(obj.Callback) = @(a,b) ehttLSIGLengthChangedGUI(obj);
            obj.SpatialMappingGUI.(obj.Callback) = @(a,b) spatialMappingChangedGUI(obj);
            obj.EHTTBPreFECPaddingFactorGUI.(obj.Callback) = @(a,b) updatePSDU(obj);
            obj.EHTTBPEDisambiguityGUI.(obj.Callback) = @(a,b) updatePSDU(obj);
            obj.EHTTBNumEHTLTFSymbolsGUI.(obj.Callback) = @(a,b) updatePSDU(obj);
            obj.EHTTBLDPCExtraSymbolGUI.(obj.Callback)  = @(a,b) updatePSDU(obj);
            obj.GuardIntervalGUI.(obj.Callback)         = @(a,b) updatePSDU(obj);
            obj.EHTLTFTypeGUI.(obj.Callback)            = @(a,b) updatePSDU(obj);

            % Fetch the `Advanced Parameters` dialog into the current dialog
            if ~isKey(obj.Parent.DialogsMap, obj.nameAdvDlg)
                obj.Parent.DialogsMap(obj.nameAdvDlg) = eval([obj.nameAdvDlg '(obj.Parent)']); %#ok<*EVLDOT>
            end
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.NumUsersDropDown = {'1'};

            % Turn User and RU tables hidden by default
            obj.setExtraConfigFigVisibility(false);

            % Collapse `Advanced Parameters` accordion panel by default
            customAccordion = obj.Parent.AppObj.pParameters.DialogsMap(obj.nameAdvDlg).getPanels;
            customAccordion.Collapsed = true;

            % Property visibility options
            currentDialog = obj.Parent.CurrentDialog;
            % EHTTransmission and advanced parameters are always hidden for EHT TB
            setVisible(currentDialog,{'EHTTransmission','BSSColor','EHTTBSpatialReuse1','EHTTBSpatialReuse2','TXOPDuration','Channelization',...
                                      'EHTTBDisregardBitsUSIG1','EHTTBDisregardBitsUSIG2','EHTTBValidateBitUSIG2'},false);
        end

        function infoDlg = getInfoDialog(obj)
        % Fetch the `Advanced Parameters` dialog for setEnable calls during
        % waveform generation
            infoDlg = obj.Parent.DialogsMap(obj.nameAdvDlg);
        end

        %% Set dialog display order
        function props = displayOrder(~)
        %displayOrder Property display order

        % List of properties in wlanEHTTBConfig
            props = {'EHTPPDUFormat';...
                     'ChannelBandwidth';...
                     'EHTTBRUSize';...
                     'EHTTBRUIndex';...
                     'PreEHTPowerScalingFactor';...
                     'NumTransmitAntennas';...
                     'PreEHTCyclicShifts';...
                     'NumSpaceTimeStreams';...
                     'EHTTBStartingSpaceTimeStream';...
                     'SpatialMapping';...
                     'SpatialMappingMatrix';...
                     'PreEHTPhaseRotation';...
                     'MCS';...
                     'ChannelCoding';...
                     'EHTTBPreFECPaddingFactor';...
                     'EHTTBLDPCExtraSymbol';...
                     'EHTTBPEDisambiguity';...
                     'EHTTBLSIGLength';...
                     'GuardInterval';...
                     'EHTLTFType';...
                     'EHTTBNumEHTLTFSymbols';...
                     'CompressionMode';... % read-only properties
                     'PSDULength';...
                     'BSSColor';... % hidden properties
                     'EHTTBSpatialReuse1';...
                     'EHTTBSpatialReuse2';...
                     'TXOPDuration';...
                     'Channelization';...
                     'EHTTBDisregardBitsUSIG1';...
                     'EHTTBDisregardBitsUSIG2';...
                     'EHTTBValidateBitUSIG2'};
        end

        function adjustSpec(obj)
        %adjustSpec Change graphical elements before creating them which are different than superclass defaults (e.g Non-HT)

            adjustSpec@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            overwriteMCS(obj); % Reset popup menu options
            overwriteNumSpaceTimeStreams(obj); % Reset popup menu options
            overwriteGuardInterval(obj); % Reset popup menu options
            overwriteEHTLTFType(obj); % Reset popup menu options - Add "1x" to the EHT-LTF type dropdown
            obj.PSDULengthType = 'numericText'; % Ensure that PSDU length is for display only
        end

        function overwriteMCS(obj)
            obj.MCSDropDown = obj.userMCS;
            obj.MCSDropDown(contains(obj.MCSDropDown,'14')) = []; % MCS 14 is not applicable to EHT TB
        end

        function overwriteNumSpaceTimeStreams(obj)
            obj.NumSpaceTimeStreamsDropDown = cellstr(string(1:8));
        end

        function overwriteGuardInterval(obj)
            miS = [' ' char(956) 's'];
            obj.GuardIntervalDropDown = {['1.6' miS], ['3.2' miS]};
        end

        function overwriteEHTLTFType(obj)
            obj.EHTLTFTypeDropDown = {'1x', '2x', '4x'};
        end

        function restoreDefaults(obj)
        %restoreDefaults Restore to default value at setup

        % Set defaults of dependent properties
            obj.EHTPPDUFormat = 'EHT TB'; % Define the PPDU type before taking actions related to EHTBaseDialog
            obj.EHTTransmission = 'EHT SU';
            obj.NumUsers = '1';
            restoreDefaults@wirelessWaveformGenerator.wlanEHTBaseDialog(obj); % Set default of common properties
            obj.EHTTBRUSize = [26 106];
            obj.EHTTBRUIndex = [1 2];
            obj.PreEHTPowerScalingFactor = 1;
            obj.NumTransmitAntennas = 1;
            obj.PreEHTCyclicShifts = -75;
            obj.NumSpaceTimeStreams = 1;
            obj.EHTTBStartingSpaceTimeStream = 1;
            obj.SpatialMapping = 'Direct';
            obj.SpatialMappingMatrix = 1;
            obj.PreEHTPhaseRotation = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1];
            obj.MCS = 0;
            obj.ChannelCoding = 'LDPC';
            obj.EHTTBPreFECPaddingFactor = '4';
            obj.EHTTBLDPCExtraSymbol = false;
            obj.EHTTBPEDisambiguity = false;
            obj.EHTTBLSIGLength = 142;
            obj.GuardInterval = '3.2';
            obj.EHTLTFType = '4x';
            obj.EHTTBNumEHTLTFSymbols = '1';
            obj.CompressionMode = obj.configObj.compressionMode;
            obj.PSDULength = obj.configObj.psduLength;

            % Advanced parameters
            obj.BSSColor = 0;
            obj.EHTTBSpatialReuse1 = 15;
            obj.EHTTBSpatialReuse2 = 15;
            obj.Channelization = '320 MHz-1';
            obj.EHTTBDisregardBitsUSIG1 = [1 1 1 1 1 1];
            obj.EHTTBDisregardBitsUSIG2 = [0 1 1 1 1];
            obj.EHTTBValidateBitUSIG2 = true;

            % Try to restore the `Advanced Parameters`, not always possible if the
            % dialog initialization is not complete
            if ~isempty(obj.ChannelBandwidthGUI.UserData)
                dlgAP = obj.Parent.AppObj.pParameters.DialogsMap(obj.nameAdvDlg);
                restoreDefaults(dlgAP);
            end

            % The parameter obj.ChannelBandwidthGUI.UserData is used as a flag to
            % determine if the dialog setup is complete. During the dialog
            % initiation, the obj.ChannelBandwidth assignment causes an error due
            % to the obj.getConfiguration call.
            if ~isempty(obj.ChannelBandwidthGUI.UserData)
                obj.ChannelBandwidth = 'CBW20'; % not possible to call it during dialog initiation (table error)
            end
            obj.ChannelBandwidthGUI.UserData = 'DialogInitialized';
            obj.EHTDUPMode = false;
            obj.NumTransmitAntennas = 1;
            obj.PSDULength = obj.getPSDULength(); % update

            % Re-initialize config object when the dialog initialization is
            % completed
            initConfig(obj);
        end

        function initConfig(obj)
        %initConfig captures the initial EHT object
        % configuration or the object configuration whenever the user changes
        % the object properties through UI
            obj.EHTPPDUFormat = 'EHT TB';
            obj.EHTTransmission = 'EHT SU';
            updateConfigFcn(obj);

            % Generate the config object with the base configuration. Note that
            % the additional parameters RUSize, RUIndex, etc., might not exist in
            % the dialog initiation process.
            try
                obj.configObj = obj.configFcn(ChannelBandwidth=obj.ChannelBandwidth,...
                                              RUSize=obj.EHTTBRUSize,RUIndex=obj.EHTTBRUIndex);
            catch
                obj.configObj = obj.configFcn(ChannelBandwidth=obj.ChannelBandwidth);
            end
            updateEHTTBVisibility(obj)
        end

        function adjustDialog(obj)
        % Adjustments of UI elements after they have been created - i.e.
        % disable
            adjustDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);

            % Set conditional visibility and values of elements
            updateEHTTBVisibility(obj);

            % Update dialog visibility
            layoutUIControls(obj);
        end

        function updateDialogFromConfig(obj,config)
        % updateDialogFromConfig: Update the visibility and forced values of
        % GUI elements when a configuration is loaded.
            obj.EHTPPDUFormat = 'EHT TB';
            tmpSpatialMapping = char(config.SpatialMapping);
            obj.SpatialMapping = [upper(tmpSpatialMapping(1)) tmpSpatialMapping(2:end)];
            obj.PSDULength = config.psduLength; % update

            % Update the EHT TB specific parameters manually since
            % `applyConfiguration` won't be handle it automatically
            obj.EHTTBRUSize = config.RUSize;
            obj.EHTTBRUIndex = config.RUIndex;
            obj.EHTTBPreFECPaddingFactor = config.PreFECPaddingFactor;
            obj.EHTTBLDPCExtraSymbol = config.LDPCExtraSymbol;
            obj.EHTTBPEDisambiguity = config.PEDisambiguity;
            obj.EHTTBLSIGLength = config.LSIGLength;
            obj.EHTTBNumEHTLTFSymbols = config.NumEHTLTFSymbols;

            % Manually update the `Advanced Parameters` GUI using the saved session
            dlgAP = obj.Parent.AppObj.pParameters.DialogsMap(obj.nameAdvDlg);
            dlgAP.BSSColor = config.BSSColor;
            dlgAP.EHTTBSpatialReuse1 = config.SpatialReuse1;
            dlgAP.EHTTBSpatialReuse2 = config.SpatialReuse2;
            if isempty(config.TXOPDuration)
                dlgAP.TXOPDuration = -1;
            else
                dlgAP.TXOPDuration = config.TXOPDuration;
            end
            dlgAP.Channelization = config.Channelization;
            dlgAP.EHTTBDisregardBitsUSIG1 = config.DisregardBitsUSIG1;
            dlgAP.EHTTBDisregardBitsUSIG2 = config.DisregardBitsUSIG2;
            dlgAP.EHTTBValidateBitUSIG2 = config.ValidateBitUSIG2;

            % Update the GUI visibilities
            updateEHTTBVisibility(obj);
        end

        function cellDialogs = getDialogsPerColumn(obj)
            cellDialogs{1} = {obj obj.Parent.DialogsMap(obj.nameAdvDlg)};
            cellDialogs{2} = {obj.Parent.GenerationDialog obj.Parent.FilteringDialog};
        end

        %% Dialog layout
        % The right-hand scope layout needs to be overwritten since the
        % superclass wlanEHTBaseDialog contains RU and User tables, which are
        % not applicable for the EHT TB PDDU format.
        function rows = getNumTileRows(~,~)
            rows = 2; % 1 - Spectrum Analyzer, 2 - RU & Subcarrier Assignment
        end

        function cols = getNumTileColumns(~,~)
            cols = 2;
        end

        function n = numVisibleFigs(obj)
            n = numVisibleFigs@wirelessWaveformGenerator.wlanEHTDialog(obj);
        end

        function [tileCount,tileCoverage,tileOccupancy] = getTileLayout(obj, ~)

        % Determine the number of tiles required to visualize all the elements on the
        % right-hand side scope layout.
            appObj = obj.Parent.WaveformGenerator;
            tileCount = obj.getVisualState('RU & Subcarrier Assignment') +...
                appObj.pPlotSpectrum + ...
                (appObj.pPlotTimeScope || appObj.pPlotCCDF);
            tileCoverage = (1:tileCount)';
            tileOccupancy = repmat(struct('children', []), tileCount, 1);
            tileID = 0; % tile index

            % Spectrum Plot
            if appObj.pPlotSpectrum
                if tileID < tileCount
                    tileID = tileID + 1;
                end
                documentID = appObj.getWebScopeDocumentId(appObj.pSpectrum1);
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            end

            % RU & Subcarrier Assignment (showAllocation) Plot
            if obj.getVisualState('RU & Subcarrier Assignment')
                if tileID < tileCount
                    tileID = tileID + 1;
                end
                documentID = 'waveformGeneratorDocumentGroup_RUSubcarrierAssignment';
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
                tileOccupancy(tileID).showingChildId = documentID;
            end

            % Time Scope
            if appObj.pPlotTimeScope
                if tileID < tileCount
                    tileID = tileID + 1;
                end
                documentID = appObj.getWebScopeDocumentId(appObj.pTimeScope);
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            end

            % Plot CCDF
            if appObj.pPlotCCDF
                if tileID < tileCount
                    tileID = tileID + 1;
                end
                documentID = getTag(obj.Parent.AppObj) + "DocumentGroup_CCDF";
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            end
        end

        function b = spectrumEnabled(~)
            b = true; % Check if the Spectrum Analyzer is enabled
        end

        %% Export to Simulink
        function str = getIconDrawingCommand(obj)
        %getIconDrawingCommand Export to Simulink

            str = ['disp([''Format: ' obj.EHTPPDUFormat ''' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz '' newline ...' newline ...
                   '''Users: '' num2str(' obj.configGenVar '.ruInfo.NumUsers) newline ...' newline ...
                   '''RUs: '' num2str(' obj.configGenVar '.ruInfo.NumRUs) newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        %% Callback functions
        function ehttbChannelCodingChangedGUI(obj)

        % Hide Extra LDPC symbol checkbox if coding is BCC
            setVisible(obj,'EHTTBLDPCExtraSymbol',~strcmp(obj.ChannelCoding,'BCC'));
            initConfig(obj);
            customVisualizations(obj); % Update RU & Subcarrier Assignment plot
            layoutUIControls(obj); % Set Height=0 to invisible properties

            % Update dependent elements
            obj.updatePSDU();
        end

        function ehttbRUSizeChangedGUI(obj)
        % Update the config object and the visualizations
            initConfig(obj);
            customVisualizations(obj); % Update RU & Subcarrier Assignment plot
            layoutUIControls(obj); % Set Height=0 to invisible properties

            % Update dependent elements
            obj.updatePSDU();
        end

        function channelBandwidthChanged(obj, ~)
            dlgAP = obj.Parent.AppObj.pParameters.DialogsMap(obj.nameAdvDlg);

            if strcmp(obj.ChannelBandwidth,'CBW320')
                changeChannelizationVisibility(dlgAP,true);
            else
                changeChannelizationVisibility(dlgAP,false);
            end
            channelBandwidthChanged@wirelessWaveformGenerator.wlanEHTBaseDialog(obj,[]);
        end

        function preEHTPowerScalingFactorChangedGUI(obj)
        % Validate the value
            try
                val = obj.PreEHTPowerScalingFactor;
                validateattributes(val, {'numeric'}, {'real', 'scalar', '>=', 1/sqrt(2), '<=', 1}, '', 'Pre-EHT scaling factor');
            catch e
                obj.errorFromException(e);
            end
        end

        function ehttLSIGLengthChangedGUI(obj, ~)
        % Validate the value
            try
                val = obj.EHTTBLSIGLength;
                validateattributes(val, {'numeric'}, {'real', 'scalar', 'integer', '>=', 1, '<=', 4093}, '', 'L-SIG length');
                coder.internal.errorIf(mod(val,3)~=1, 'wlan:shared:InvalidLSIGLengthValEHT');
            catch e
                obj.errorFromException(e);
            end
            % Update dependent elements
            obj.updatePSDU();
        end

        function spatialMappingChangedGUI(obj)
            val = strcmpi(obj.SpatialMapping, 'Custom');
            setVisible(obj, 'SpatialMappingMatrix', val);
            obj.layoutUIControls();
        end

    end % end methods

    methods (Access = protected)
        function numTransmitAntennasChanged(obj, ~)
        % Update format specific GUI elements (excluding cyclic shifts as
        % common for all formats) when Transmit Antennas changed - by loading
        % a session or changing the GUI value.

        % Update dropdown options when NumTransmitAntennas has changed
            if obj.NumTransmitAntennas == sum(obj.NumSpaceTimeStreams)
                obj.SpatialMappingDropDown = {'Direct', 'Hadamard', 'Fourier', 'Custom'};
                obj.SpatialMappingGUI.(obj.DropdownValues) = {'Direct', 'Hadamard', 'Fourier', 'Custom'};
            else
                obj.SpatialMappingDropDown = {'Hadamard', 'Fourier', 'Custom'};
                obj.SpatialMappingGUI.(obj.DropdownValues) = {'Hadamard', 'Fourier', 'Custom'};
            end
        end
    end

    %% Property Visibilities
    methods (Access = private)
        function updateEHTTBVisibility(obj)
            if ~isKey(obj.Parent.DialogsMap, obj.nameAdvDlg)
                obj.Parent.DialogsMap(obj.nameAdvDlg) = eval([obj.nameAdvDlg '(obj.Parent)']); %#ok<*EVLDOT>
            end

            % Update the visibility of properties
            isCBW320 = strcmp(obj.ChannelBandwidth,'CBW320');
            setVisible(obj.Parent.DialogsMap(obj.nameAdvDlg),'Channelization',isCBW320)
            setVisible(obj,'PreEHTPhaseRotation',isCBW320);
            layoutUIControls(obj.Parent.DialogsMap(obj.nameAdvDlg)) % Set Height=0 to invisible properties
        end
    end

end
