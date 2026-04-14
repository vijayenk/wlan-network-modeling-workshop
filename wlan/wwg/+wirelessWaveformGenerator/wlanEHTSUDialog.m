classdef wlanEHTSUDialog < wirelessWaveformGenerator.wlanEHTBaseDialog
%Dialog for EHT SU waveform

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Access=protected)
        userFigTag = 'UsersEHT_SU';
        ruFigTag = 'RUFigEHT_SU';
    end

    methods
        function obj = wlanEHTSUDialog(parent) % Constructor
            obj@wirelessWaveformGenerator.wlanEHTBaseDialog(parent); % Call base constructor
            createRUTable(obj);
            createUserTable(obj);
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.EHTTransmission = 'EHT SU';
        end

        %% Set dialog display order
        function props = displayOrder(~)
        %displayOrder Property display order

        % List of properties in wlanEHTMUConfig
            props = {'EHTPPDUFormat';'EHTTransmission';'UplinkIndication';'ChannelBandwidth';'NumUsers';'EHTDUPMode';'PuncturedChannelFieldValue';'NumTransmitAntennas'; ...
                     'PreEHTCyclicShifts';'PreEHTPhaseRotation';'GuardInterval';'EHTLTFType';'NumExtraEHTLTFSymbols';'EHTSIGMCS';'BSSColor'; ...
                     'SpatialReuse';'TXOPDuration';'Channelization';'CompressionMode'};
        end

        function adjustSpec(obj)
        %adjustSpec Change graphical elements before creating them which are different than superclass defaults (e.g Non-HT)

            adjustSpec@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.NumUsersDropDown = {'1'};
        end

        function restoreDefaults(obj)
        %restoreDefaults Restore to default value at setup

        % Set defaults of dependent properties
            restoreDefaults@wirelessWaveformGenerator.wlanEHTBaseDialog(obj); % Set default of common properties
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'EHT SU';

            % The parameter obj.ChannelBandwidthGUI.UserData is used as a flag
            % to distinguish between different app sessions. The initial dialog
            % setup occurs during app initiation and is separate from
            % subsequent new sessions and changed transmission types. Please
            % note that the call to obj.ChannelBandwidth assignment causes an
            % error due to the associated obj.getConfiguration call.
            if ~isempty(obj.ChannelBandwidthGUI.UserData)
                obj.ChannelBandwidth = 'CBW20'; % not possible to call it during dialog initiation (table error)
            end
            obj.ChannelBandwidthGUI.UserData = 'DialogInitialized';

            obj.EHTDUPMode = false;
            obj.NumTransmitAntennas = 1;
            updateEHTSUVisibility(obj);
        end

        function initConfig(obj)
        %initConfig Get object configuration
        %  initConfig captures the initial EHT object configuration or the
        %  object configuration whenever the user changes the object properties
        %  through UI

            updateConfigFcn(obj);
            updateEHTSUVisibility(obj);
            obj.configObj = obj.configFcn(obj.ChannelBandwidth,'NumUsers',1,'PuncturedChannelFieldValue',obj.PuncturedChannelFieldValue,'EHTDUPMode',obj.EHTDUPMode);
        end

        function updateDialogFromConfig(obj,config)
        %updateDialogFromConfig Update the visibility and forced values of GUI elements when configuration loaded
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'EHT SU';
            updateEHTSUVisibility(obj);
            if config.EHTDUPMode
                obj.EHTDUPMode = true;
                ehtDUPModeChangedGUI(obj);
            end
            obj.configObj.RU = config.RU;
            obj.configObj.User = config.User;
            updateTables(obj);
        end
    end

    %% Visibility
    methods (Access = private)
        function updateEHTSUVisibility(obj)
        % Update visibility of elements depending on EHT SU PPDU format
            updatePuncturedChannelFieldValues(obj);
            flag = isCBWAbove40MHz(obj);
            setVisible(obj,{'NumUsers'},false)
            setVisible(obj,{'PuncturedChannelFieldValue'},flag); % Visibility for EHT-DUP mode
            setVisible(obj,{'EHTDUPMode'},flag); % Visibility for EHT-DUP mode
            setVisible(obj,{'PreEHTPhaseRotation','Channelization'}, strcmp(obj.ChannelBandwidth,'CBW320'))
        end
    end

end
