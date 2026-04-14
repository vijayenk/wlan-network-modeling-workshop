classdef wlanEHTSoundingNDPDialog < wirelessWaveformGenerator.wlanEHTBaseDialog
%Dialog for EHT Sounding NDP waveform

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Access=protected)
        userFigTag = 'UsersEHT_Sounding';
        ruFigTag = 'RUFigEHT_Sounding';
    end

    methods
        function obj = wlanEHTSoundingNDPDialog(parent) % Constructor
            obj@wirelessWaveformGenerator.wlanEHTBaseDialog(parent); % Call base constructor
            createRUTable(obj);
            createUserTable(obj);
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.EHTTransmission = 'Sounding NDP';
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
            restoreDefaults@wirelessWaveformGenerator.wlanEHTBaseDialog(obj);
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'Sounding NDP';

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

            obj.NumTransmitAntennas = 1;
            obj.EHTDUPMode = false;
            updateEHTSoundingVisibility(obj);
        end

        function initConfig(obj)
        %initConfig Get object configuration
        %  initConfig captures the initial EHT object configuration or the
        %  object configuration whenever the user changes the object properties
        %  through UI

            updateConfigFcn(obj);
            updateEHTSoundingVisibility(obj);
            config = obj.configFcn(obj.ChannelBandwidth,'NumUsers',obj.NumUsers,'PuncturedChannelFieldValue',obj.PuncturedChannelFieldValue,'EHTDUPMode',obj.EHTDUPMode);
            config.User{1}.APEPLength = 0;
            obj.configObj = config;
        end

        function updateDialogFromConfig(obj,config)
        %updateDialogFromConfig Update the visibility and forced values of GUI elements when configuration loaded
            obj.EHTPPDUFormat = 'EHT MU';
            obj.EHTTransmission = 'Sounding NDP';
            updateEHTSoundingVisibility(obj);
            obj.configObj.RU = config.RU;
            obj.configObj.User = config.User;
            updateTables(obj);
        end
    end

    %% Visibility
    methods (Access = private)
        function updateEHTSoundingVisibility(obj)
        % Update visibility of elements depending on EHT Sounding NDP PPDU format
            isCBW320 = strcmp(obj.ChannelBandwidth,'CBW320');
            setVisible(obj,{'NumUsers','EHTDUPMode'},false);
            flag = isCBWAbove40MHz(obj);
            setVisible(obj,{'PuncturedChannelFieldValue'},flag); % Visibility for EHT-DUP mode
            setVisible(obj,{'PreEHTPhaseRotation','Channelization'},isCBW320);
            obj.layoutUIControls();
        end
    end

end
