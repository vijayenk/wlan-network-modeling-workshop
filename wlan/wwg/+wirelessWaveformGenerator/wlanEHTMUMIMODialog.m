classdef wlanEHTMUMIMODialog < wirelessWaveformGenerator.wlanEHTBaseDialog
%Dialog for EHT MU-MIMO waveform

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Access=protected)
        userFigTag = 'UsersEHT_MU';
        ruFigTag = 'RUFigEHT_MU';
    end

    methods
        function obj = wlanEHTMUMIMODialog(parent) % Constructor
            obj@wirelessWaveformGenerator.wlanEHTBaseDialog(parent); % Call base constructor
            createRUTable(obj);
            createUserTable(obj);
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.EHTTransmission = 'MU-MIMO';
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
            obj.NumUsersDropDown = {'2' '3' '4' '5' '6' '7' '8'};
        end

        function restoreDefaults(obj)
        %restoreDefaults Restore to default value at setup

        % Set defaults of dependent properties
            restoreDefaults@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'MU-MIMO';

            % The parameter obj.ChannelBandwidthGUI.UserData is used as a flag
            % to distinguish between different app sessions. The initial dialog
            % setup occurs during app initiation and is separate from
            % subsequent new sessions and changed transmission types. Please
            % note that the call to obj.ChannelBandwidth assignment causes an
            % error due to the associated obj.getConfiguration call.
            if ~isempty(obj.ChannelBandwidthGUI.UserData)
                obj.ChannelBandwidth = 'CBW20'; % not possible to call it during dialog initiation (table error)
                obj.NumUsers = 2;
            end
            obj.ChannelBandwidthGUI.UserData = 'dialogInitialized';

            obj.EHTDUPMode = false; % EHTDUPMode only applies to a single user configuration
            obj.NumTransmitAntennas = 2;
            updateEHTMIMOVisibility(obj);
        end

        function initConfig(obj)
        %initConfig Get object configuration
        %  initConfig captures the initial EHT object configuration or the
        %  object configuration whenever the user changes the object properties
        %  through UI

            obj.updateConfigFcn();
            updateEHTMIMOVisibility(obj);
            obj.configObj = obj.configFcn(obj.ChannelBandwidth,'NumUsers',obj.NumUsers,'PuncturedChannelFieldValue',obj.PuncturedChannelFieldValue,'EHTDUPMode',obj.EHTDUPMode);
        end

        function updateDialogFromConfig(obj,config)
        %updateDialogFromConfig Update the visibility and forced values of GUI elements when configuration loaded
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'MU-MIMO';
            updateEHTMIMOVisibility(obj);
            obj.configObj.RU = config.RU;
            obj.configObj.User = config.User;
            updateTables(obj);
        end
    end

    %% Visibility
    methods (Access = private)
        function updateEHTMIMOVisibility(obj)
        % Update visibility of elements depending on EHT MU PPDU format
            obj.CompressionMode = 2;
            isCBW = isCBWAbove40MHz(obj);
            isCBW320 = strcmp(obj.ChannelBandwidth,'CBW320');
            setVisible(obj,{'NumUsers'},true);
            setVisible(obj,{'UplinkIndication','EHTDUPMode'},false);
            setVisible(obj,{'PuncturedChannelFieldValue'},isCBW);
            setVisible(obj,{'PreEHTPhaseRotation','Channelization'},isCBW320);
            obj.layoutUIControls();
        end
    end

end
