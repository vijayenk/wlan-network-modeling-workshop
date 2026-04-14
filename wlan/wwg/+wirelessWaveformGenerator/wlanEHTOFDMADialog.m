classdef wlanEHTOFDMADialog < wirelessWaveformGenerator.wlanEHTBaseDialog
%Dialog for EHT OFDMA waveform

% Copyright 2023-2025 The MathWorks, Inc.

    properties (Access=protected)
        userFigTag = 'UsersEHT_OFDMA';
        ruFigTag = 'RUFigEHT_OFDMA';
    end

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
    end

    properties (Dependent, Hidden)
        EHTAllocationIndex
    end

    properties (Hidden)
        EHTAllocationIndex1Type = 'numericEdit'
        EHTAllocationIndex1GUI
        EHTAllocationIndex1Label
        EHTAllocationIndex2Type = 'numericEdit'
        EHTAllocationIndex2GUI
        EHTAllocationIndex2Label
        EHTAllocationIndex3Type = 'numericEdit'
        EHTAllocationIndex3GUI
        EHTAllocationIndex3Label
        EHTAllocationIndex4Type = 'numericEdit'
        EHTAllocationIndex4GUI
        EHTAllocationIndex4Label
        EHTAllocationIndex5Type = 'numericEdit'
        EHTAllocationIndex5GUI
        EHTAllocationIndex5Label
        EHTAllocationIndex6Type = 'numericEdit'
        EHTAllocationIndex6GUI
        EHTAllocationIndex6Label
        EHTAllocationIndex7Type = 'numericEdit'
        EHTAllocationIndex7GUI
        EHTAllocationIndex7Label
        EHTAllocationIndex8Type = 'numericEdit'
        EHTAllocationIndex8GUI
        EHTAllocationIndex8Label
        EHTAllocationIndex9Type = 'numericEdit'
        EHTAllocationIndex9GUI
        EHTAllocationIndex9Label
        EHTAllocationIndex10Type = 'numericEdit'
        EHTAllocationIndex10GUI
        EHTAllocationIndex10Label
        EHTAllocationIndex11Type = 'numericEdit'
        EHTAllocationIndex11GUI
        EHTAllocationIndex11Label
        EHTAllocationIndex12Type = 'numericEdit'
        EHTAllocationIndex12GUI
        EHTAllocationIndex12Label
        EHTAllocationIndex13Type = 'numericEdit'
        EHTAllocationIndex13GUI
        EHTAllocationIndex13Label
        EHTAllocationIndex14Type = 'numericEdit'
        EHTAllocationIndex14GUI
        EHTAllocationIndex14Label
        EHTAllocationIndex15Type = 'numericEdit'
        EHTAllocationIndex15GUI
        EHTAllocationIndex15Label
        EHTAllocationIndex16Type = 'numericEdit'
        EHTAllocationIndex16GUI
        EHTAllocationIndex16Label
        IsSameEHTSignallingType = 'checkbox'
        IsSameEHTSignallingLabel
        IsSameEHTSignallingGUI
    end

    methods
        %% Class constructor
        function obj = wlanEHTOFDMADialog(parent)
            obj@wirelessWaveformGenerator.wlanEHTBaseDialog(parent); % Call base constructor
            createRUTable(obj);
            createUserTable(obj);

            % Specify callbacks for changes to EHT GUI elements that impact other elements
            obj.EHTAllocationIndex1GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex1GUI);
            obj.EHTAllocationIndex2GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex2GUI);
            obj.EHTAllocationIndex3GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex3GUI);
            obj.EHTAllocationIndex4GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex4GUI);
            obj.EHTAllocationIndex5GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex5GUI);
            obj.EHTAllocationIndex6GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex6GUI);
            obj.EHTAllocationIndex7GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex7GUI);
            obj.EHTAllocationIndex8GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex8GUI);
            obj.EHTAllocationIndex9GUI.(obj.Callback)     = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex9GUI);
            obj.EHTAllocationIndex10GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex10GUI);
            obj.EHTAllocationIndex11GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex11GUI);
            obj.EHTAllocationIndex12GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex12GUI);
            obj.EHTAllocationIndex13GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex13GUI);
            obj.EHTAllocationIndex14GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex14GUI);
            obj.EHTAllocationIndex15GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex15GUI);
            obj.EHTAllocationIndex16GUI.(obj.Callback)    = @(a,b) validateAllocationIndex(obj, obj.EHTAllocationIndex16GUI);
            obj.IsSameEHTSignallingGUI.(obj.Callback)     = @(a,b) IsSameEHTSignallingChangedGUI(obj, []);
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.EHTTransmission = 'OFDMA';
        end

        function adjustDialog(obj)
            adjustDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            updateEHTOFDMAVisibility(obj);
            str = 'EHTAllocationIndex';
            arrayAllocationProps = arrayfun(@(x) [str num2str(x)], 2:16,  'UniformOutput', false);
            setVisible(obj, arrayAllocationProps, false); % AllocationIndex #2-16 are hidden for CBW20
            setVisible(obj, 'IsSameEHTSignalling', false); % Same signaling is hidden for CBW20
        end

        %% Set dialog display order
        function props = displayOrder(~)
        %displayOrder Property display order

        % List of properties in wlanEHTMUConfig
            props = {'EHTPPDUFormat';'EHTTransmission';'UplinkIndication';'ChannelBandwidth';'NumUsers';'EHTDUPMode';'PuncturedChannelFieldValue';
                     'EHTAllocationIndex1'; 'EHTAllocationIndex2'; 'EHTAllocationIndex3'; 'EHTAllocationIndex4'; 'EHTAllocationIndex5'; 'EHTAllocationIndex6'; 'EHTAllocationIndex7'; 'EHTAllocationIndex8'; ...
                     'EHTAllocationIndex9'; 'EHTAllocationIndex10'; 'EHTAllocationIndex11'; 'EHTAllocationIndex12'; 'EHTAllocationIndex13'; 'EHTAllocationIndex14'; 'EHTAllocationIndex15'; 'EHTAllocationIndex16'; ...
                     'IsSameEHTSignalling'; 'NumTransmitAntennas'; 'PreEHTCyclicShifts';'PreEHTPhaseRotation';'GuardInterval';'EHTLTFType';'NumExtraEHTLTFSymbols';'EHTSIGMCS';'BSSColor'; 'SpatialReuse'; ...
                     'TXOPDuration';'Channelization';'CompressionMode'};
        end

        function adjustSpec(obj)
        %adjustSpec Change graphical elements before creating them which are different than superclass defaults (e.g Non-HT)

            adjustSpec@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
        end

        function restoreDefaults(obj)
        %restoreDefaults Restore to default values during setup

        % Set defaults of dependent properties
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'OFDMA';

            % Set multiple Allocation Index properties at once. The syntax is
            % setMultipleAllocationIndices(obj,Allocation Indices,value)
            setMultipleAllocationIndices(obj,1:16,50);

            % The parameter obj.ChannelBandwidthGUI.UserData is used as a flag to
            % distinguish between different app sessions. The initial dialog
            % setup occurs during app initiation and is separate from subsequent
            % new sessions and changed transmission types. Please note that the
            % call to obj.ChannelBandwidth assignment causes an error due to the
            % associated obj.getConfiguration call.
            if ~isempty(obj.ChannelBandwidthGUI.UserData)
                obj.ChannelBandwidth = 'CBW20';
            end
            obj.ChannelBandwidthGUI.UserData = 'DialogInitialized';

            % Restore defaults after setting the defaults in order to avoid
            % empty EHTAllocationIndex
            restoreDefaults@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.IsSameEHTSignalling = false;
            obj.IsSameEHTSignallingGUI.UserData = [];
            obj.NumTransmitAntennas = 1;

            % NumUsers and PuncturedChannelFieldValue are hidden
            updateEHTOFDMAVisibility(obj);

        end

        function initConfig(obj)
        %initConfig Constructs the default configuration

            obj.updateConfigFcn();
            updateEHTOFDMAVisibility(obj);

            % [try] to generate a config object by using the given
            % allocation indices. If it fails [catch];
            %
            % (i) Ignore the config object generation if initConfig() has
            % been triggered due to the EHT Transmission type change,
            %
            % (ii) Try to create a config object again and rethrow the
            % error in the current dialog, if initConfig() has been
            % triggered due to the obj.getConfiguration call.
            %
            % In summary, the error should only be thrown if the "Generate"
            % button is pressed, not while switching between EHT
            % transmission types. This has been ensured using the
            % obj.EHTAllocationIndex1GUI.UserData flag.
            try
                % Try to create a config object using the allocation
                % indices
                obj.configObj = obj.configFcn(obj.EHTAllocationIndex);

                if obj.IsSameEHTSignalling
                    if strcmp(obj.ChannelBandwidth,'CBW320')
                        obj.configObj = obj.configFcn(repmat(obj.EHTAllocationIndex,4,1));
                    else % CBW160
                        obj.configObj = obj.configFcn(repmat(obj.EHTAllocationIndex,2,1));
                    end
                end
            catch
                % Rethrow the error (comes from the object) if the
                % "Generate" button is pressed
                if ~isempty(obj.EHTAllocationIndex1GUI.UserData)
                    try
                        obj.configObj = obj.configFcn(obj.EHTAllocationIndex);
                    catch e
                        obj.errorFromException(e);
                        obj.EHTAllocationIndex1GUI.UserData = [];
                    end
                end
            end
        end

        function updateDialogFromConfig(obj,config)
        %updateDialogFromConfig Update the visibility and forces values of GUI elements when configuration loaded
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'OFDMA';
            for i = 1:length(config.AllocationIndex)
                setMultipleAllocationIndices(obj,i,config.AllocationIndex(i));
            end
            obj.configObj = config;
            updateTables(obj);
            updateEHTOFDMAVisibility(obj);
        end

        function channelBandwidthChanged(obj, ~)
        % Restore the default values after the channel bandwidth has been changed
            obj.EHTAllocationIndex1GUI.UserData = [];
            obj.NumTransmitAntennas = 1;

            % Set the OFDMA dialog specific parameters back to their default values
            if strcmp(obj.ChannelBandwidth,'CBW320') && ...
                    isfield(obj.IsSameEHTSignallingGUI.UserData,'CBW320') && ~isempty(obj.IsSameEHTSignallingGUI.UserData.CBW320)
                obj.IsSameEHTSignalling = obj.IsSameEHTSignallingGUI.UserData.CBW320; % store the user set same signalling value
            elseif strcmp(obj.ChannelBandwidth,'CBW160') && ...
                    isfield(obj.IsSameEHTSignallingGUI.UserData,'CBW160') && ~isempty(obj.IsSameEHTSignallingGUI.UserData.CBW160)
                obj.IsSameEHTSignalling = obj.IsSameEHTSignallingGUI.UserData.CBW160; % store the user set same signalling value
            else
                obj.IsSameEHTSignalling = false; % default for other bandwidth values
            end
            channelBandwidthChanged@wirelessWaveformGenerator.wlanEHTBaseDialog(obj,[]);

            % Modify inherited channelBandwidthChanged method
            updateAllocationIndexVisibility(obj);
        end

        function IsSameEHTSignallingChangedGUI(obj,~)
        % Decide what happens when IsSameEHTSignalling checkbox value changes
            if strcmp(obj.ChannelBandwidth,'CBW320')
                obj.IsSameEHTSignallingGUI.UserData.CBW320 = obj.IsSameEHTSignalling; % Store the same signalling data
            else % CBW160
                obj.IsSameEHTSignallingGUI.UserData.CBW160 = obj.IsSameEHTSignalling; % Store the same signalling data
            end
            initConfig(obj); % re-initialize the config object with new allocation indices
            updateTables(obj);
        end

        function configObjChanged(obj, ~)
        % Decide what happens when config object properties change

        % Modify inherited channelBandwidthChanged method
            updateAllocationIndexVisibility(obj);

            initConfig(obj);
            updateTables(obj);
            ruTableCallback(obj);
            userTableCallback(obj);
        end

        function setMultipleAllocationIndices(obj,range,value)
            for i = min(range):max(range)
                obj.(['EHTAllocationIndex' num2str(i)]) = value;
            end
        end

        %% Set/Get methods
        function n = get.EHTAllocationIndex(obj)
            switch obj.ChannelBandwidth
              case 'CBW20'
                n = obj.EHTAllocationIndex1;
              case 'CBW40'
                n = [obj.EHTAllocationIndex1 obj.EHTAllocationIndex2];
              case 'CBW80'
                n = [obj.EHTAllocationIndex1 obj.EHTAllocationIndex2 ...
                     obj.EHTAllocationIndex3 obj.EHTAllocationIndex4];
              case 'CBW160'
                n = [obj.EHTAllocationIndex1 obj.EHTAllocationIndex2 ...
                     obj.EHTAllocationIndex3 obj.EHTAllocationIndex4 ...
                     obj.EHTAllocationIndex5 obj.EHTAllocationIndex6 ...
                     obj.EHTAllocationIndex7 obj.EHTAllocationIndex8];
              case 'CBW320'
                n = [obj.EHTAllocationIndex1 obj.EHTAllocationIndex2 ...
                     obj.EHTAllocationIndex3 obj.EHTAllocationIndex4 ...
                     obj.EHTAllocationIndex5 obj.EHTAllocationIndex6 ...
                     obj.EHTAllocationIndex7 obj.EHTAllocationIndex8 ...
                     obj.EHTAllocationIndex9 obj.EHTAllocationIndex10 ...
                     obj.EHTAllocationIndex11 obj.EHTAllocationIndex12 ...
                     obj.EHTAllocationIndex13 obj.EHTAllocationIndex14 ...
                     obj.EHTAllocationIndex15 obj.EHTAllocationIndex16];
            end
        end

        %% Exclude properties from the config object
        function props = props2ExcludeFromConfig(obj)
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            props = [props {'EHTAllocationIndex','EHTPPDUFormat','EHTTransmission','CompressionMode'}];
        end

    end

    %% Visibility
    methods (Access = private)
        function updateEHTOFDMAVisibility(obj)
        % Update visibility of elements for OFDMA dialog
            setVisible(obj,{'UplinkIndication','NumUsers','EHTDUPMode','PuncturedChannelFieldValue'},false);
            setVisible(obj,{'PreEHTPhaseRotation','Channelization'},strcmp(obj.ChannelBandwidth,'CBW320'));
        end

        function validateAllocationIndex(obj, ~)
            % [Validation-time check] If the user-provided allocation
            % indices are scalar, error in dialog and stop config object
            % generation if any allocation is not scalar, otherwise
            % generate the new config object
            try
                for i = 1:wlan.internal.cbwStr2Num(obj.ChannelBandwidth)/20
                    validateattributes(getEditVal(obj, ['EHTAllocationIndex' num2str(i)]),...
                        {'numeric'},{'real','integer','scalar','>=',0,'<=',303}, '', ['Allocation index #' num2str(i)])
                end
            catch e
                obj.errorFromException(e);
                return
            end

            % Call the config object is changed callback
            try
                configObjChanged(obj);
            catch
                % Do not show any error to the user if the given allocation index
                % is not valid until the user is done with setting their
                % configuration and hits the "Generate" button.
            end
        end

        function updateAllocationIndexVisibility(obj)
        % Update visibility of allocation indices depending on the channel
        % bandwidth
            str = 'EHTAllocationIndex';
            arrayAllocationProps = arrayfun(@(x) [str num2str(x)], 1:16,  'UniformOutput', false);
            setVisible(obj, arrayAllocationProps, false);

            setVisible(obj, arrayAllocationProps(1),    true); % Allocation Index #1 is always visible
            setVisible(obj, arrayAllocationProps(2),    any(strcmp(obj.ChannelBandwidth, {'CBW40','CBW80','CBW160','CBW320'})));
            setVisible(obj, arrayAllocationProps(3:4),  any(strcmp(obj.ChannelBandwidth, {'CBW80','CBW160','CBW320'})));
            setVisible(obj, arrayAllocationProps(5:8),  any(strcmp(obj.ChannelBandwidth, {'CBW160','CBW320'})));
            setVisible(obj, arrayAllocationProps(9:16), strcmp(obj.ChannelBandwidth, 'CBW320'));

            setVisible(obj, 'IsSameEHTSignalling',  any(strcmp(obj.ChannelBandwidth, {'CBW160','CBW320'})));
        end
    end
end
