classdef wlanDMGDialog < wirelessWaveformGenerator.wlanOFDMWaveformConfiguration
%

%   Copyright 2018-2024 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        MCS
        PacketType
    end

    properties (Hidden)
        configFcn = @wlanDMGConfig
        configGenFcn = @wlanDMGConfig
        configGenVar = 'dmgCfg'

        TitleString = getString(message('wlan:waveformGeneratorApp:DMGTitle'))
        PHYType = 'charPopup'
        PHYDropDown = {'Control', 'Single-carrier', 'OFDM'}
        PHYLabel
        PHYGUI
        MCSType = 'charPopup'
        MCSDropDown = {'0 (DBPSK, 1/2 rate)'}
        MCSDropDownControl = {'0 (DBPSK, 1/2 rate)'}
        MCSDropDownSC ={'1 (pi/2 BPSK, 1/2 rate)',    '2 (pi/2 BPSK, 1/2 rate)', ...
                        '3 (pi/2 BPSK, 5/8 rate)',     '4 (pi/2 BPSK, 3/4 rate)',    '5 (pi/2 BPSK, 13/16 rate)', ...
                        '6 (pi/2 QPSK, 1/2 rate)',     '7 (pi/2 QPSK, 5/8 rate)',    '8 (pi/2 QPSK, 3/4 rate)', ...
                        '9 (pi/2 QPSK, 13/16 rate)',   '9.1 (pi/2 QPSK, 7/8 rate)', '10 (pi/2 16-QAM, 1/2 rate)', '11 (pi/2 16-QAM, 5/8 rate)', ...
                        '12 (pi/2 16-QAM, 3/4 rate)',  '12.1 (pi/2 16-QAM, 3/4 rate)', '12.2 (pi/2 16-QAM, 7/8 rate)', ...
                        '12.3 (64-QAM, 5/8 rate)', '12.4 (64-QAM, 3/4 rate)',  '12.5 (64-QAM, 13/16 rate)', ...
                        '12.6 (64-QAM, 7/8 rate)',}
        MCSDropDownOFDM = {'13 (SQPSK, 1/2 rate)',       '14 (SQPSK, 5/8 rate)', ...
                           '15 (QPSK, 1/2 rate)',         '16 (QPSK, 5/8 rate)',        '17 (QPSK, 3/4 rate)', ...
                           '18 (16-QAM, 1/2 rate)',       '19 (16-QAM, 5/8 rate)',      '20 (16-QAM, 3/4 rate)', ...
                           '21 (16-QAM, 13/16 rate)',     '22 (64-QAM, 5/8 rate)',      '23 (64-QAM, 3/4 rate)', ...
                           '24 (64-QAM, 13/16 rate)'
                          }
        MCSLabel
        MCSGUI
        TrainingLengthType = 'numericPopup'
        TrainingLengthDropDown = {'0' '4' '8' '12' '16' '20' '24' '28' '32' '36' '40' '44' '48' '52' '56' '60' '64'}
        TrainingLengthLabel
        TrainingLengthGUI
        PacketTypeType = 'charPopup'
        PacketTypeDropDown = {'Receive training' 'Transmit training'}
        PacketTypeLabel
        PacketTypeGUI
        BeamTrackingRequestType = 'checkbox'
        BeamTrackingRequestGUI
        TonePairingTypeType = 'charPopup'
        TonePairingTypeDropDown = {'Static' 'Dynamic'}
        TonePairingTypeLabel
        TonePairingTypeGUI
        DTPGroupPairIndexType = 'numericEdit'
        DTPGroupPairIndexLabel
        DTPGroupPairIndexGUI
        DTPIndicatorType = 'checkbox'
        DTPIndicatorGUI
        AggregatedMPDUType = 'checkbox'
        AggregatedMPDUGUI
        LastRSSIType = 'numericPopup'
        LastRSSIDropDown = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'}
        LastRSSILabel
        LastRSSIGUI
        TurnaroundType = 'checkbox'
        TurnaroundGUI
    end

    methods % constructor
        function obj = wlanDMGDialog(parent)
            obj@wirelessWaveformGenerator.wlanOFDMWaveformConfiguration(parent); % call base constructor

            obj.PHYGUI.(obj.Callback)               = @(a,b) phyChangedGUI(obj, []);
            obj.MCSGUI.(obj.Callback)               = @(a,b) mcsChangedGUI(obj, []);
            obj.TonePairingTypeGUI.(obj.Callback)   = @(a,b) tonePairingChangedGUI(obj, []);
            obj.TrainingLengthGUI.(obj.Callback)    = @(a,b) trainingLengthChangedGUI(obj, []);
            obj.DTPGroupPairIndexGUI.(obj.Callback) = @(a,b) dtpEditChanged(obj, []);
        end

        function props = props2ExcludeFromConfig(~)
            props = {'PHY'};
        end
        function props = props2ExcludeFromConfigGeneration(obj)
            props = {'PHY'};
            mcs = str2double(obj.MCS);
            if mcs == 0
                props = [props 'AggregatedMPDU', 'LastRSSI'];
            end
            if (mcs >= 13 && mcs <= 17)
                if ~strcmp(obj.TonePairingType, 'Dynamic')
                    props = [props 'DTPGroupPairIndex', 'DTPIndicator'];
                end
            else
                props = [props 'TonePairingType', 'DTPGroupPairIndex', 'DTPIndicator'];
            end

            if obj.TrainingLength == 0
                props = [props 'PacketType', 'BeamTrackingRequest'];
            end
        end
        function config = getConfiguration(obj)
            config = getConfiguration@wirelessWaveformGenerator.WaveformConfigurationDialog(obj);
            if ~isempty(obj.Parent.GenerationDialog)
                config.ScramblerInitialization = obj.Parent.GenerationDialog.ScramblerInitialization;
            end
        end

        function config = getConfigurationForSave(obj)
            config.waveform.PHY = obj.PHY;  % wlanConfig objects do not accept workspace variables (strings)
            config.waveform.object = obj.getConfiguration;  % wlanConfig objects do not accept workspace variables (strings)
            config.generation = getConfigurationForSave(obj.Parent.GenerationDialog);
            config.filtering = getConfigurationForSave(obj.Parent.FilteringDialog);
        end

        function config = applyConfiguration(obj, config)

            obj.PHY = config.PHY;
            obj.phyChanged();
            applyConfiguration@wirelessWaveformGenerator.WaveformConfigurationDialog(obj, config.object);
        end
        function updateVisibilities(obj)
            obj.mcsChanged();
            obj.trainingLengthChanged();
        end

        function props = displayOrder(~)
            props = {'PHY'; 'MCS'; 'TrainingLength'; 'PacketType'; 'BeamTrackingRequest'; 'TonePairingType'; ...
                     'DTPGroupPairIndex'; 'DTPIndicator'; 'PSDULength'; 'AggregatedMPDU'; 'LastRSSI'; 'Turnaround'};
        end

        function b = hasWindowing(obj)
            b = strcmp(obj.PHY, 'OFDM');
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''PHY type: ' obj.PHY ''' newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''PSDU: '' num2str(' obj.configGenVar '.PSDULength) '' bytes'' newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function addGenerationCode(obj, sw)
            genDialog = obj.getGenerationDialog();
            addcr(sw, ['waveform = wlanWaveformGenerator(in, ' obj.configGenVar ', ...']);
            addcr(sw, ['''NumPackets'', '               genDialog.NumFramesGUI.(obj.EditValue) ', ...']);
            addcr(sw, ['''IdleTime'', '                 genDialog.IdleTimeGUI.(obj.EditValue) ', ...']);
            if strcmp(obj.PHY, 'OFDM')
                addcr(sw, ['''WindowTransitionTime'', '   genDialog.WindowTransitionTimeGUI.(obj.EditValue) ', ...']);
            end
            addcr(sw, ['''ScramblerInitialization'', '  genDialog.ScramblerInitializationGUI.(obj.EditValue) ');']);
        end

        function setupDialog(obj)
            if any(strcmp(obj.PHY, {'Control', 'Single-carrier'}))
                valWin = false;
            else
                valWin = true;
            end
            generationDialog = obj.Parent.GenerationDialog;
            setVisible(generationDialog, {'OversamplingFactor', 'OutputSampleRate', 'InitialScramblerSequence'}, false);
            setVisible(generationDialog, 'ScramblerInitialization', true);
            setVisible(generationDialog, 'WindowTransitionTime', valWin);
            generationDialog.ScramblerInitialization = 2;
            generationDialog.WindowTransitionTime = 16/2640e6;
            layoutUIControls(generationDialog);

            setupDialog@wirelessWaveformGenerator.WaveformConfigurationDialog(obj);
        end

        function restoreDefaults(obj)
            obj.MCS = '0';
            obj.TrainingLength = 0;
            obj.PacketType = 'Receive training';
            obj.BeamTrackingRequest = false;
            obj.TonePairingType = 'Static';
            obj.DTPGroupPairIndex = '[0:41]''';
            obj.DTPIndicator = false;
            obj.AggregatedMPDU = false;
            obj.LastRSSI = 0;
            obj.Turnaround = false;
            obj.PSDULength = 1000;
        end

        function phyChanged(obj, ~)
            if strcmp(obj.PHY, 'Control')
                obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDownControl;
            elseif strcmp(obj.PHY, 'Single-carrier')
                obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDownSC;
            else % OFDM
                obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDownOFDM;
            end

            mcsChanged(obj);

            if ~strcmp(obj.PHY, 'OFDM')
                val = false;
            else
                val = true;
            end
            generationDialog = obj.Parent.GenerationDialog;
            setVisible(generationDialog, 'WindowTransitionTime', val);

            if isKey(obj.Parent.DialogsMap, 'wirelessAppContainer.transmitter.TxWaveformDialogICT')
                txDialog = obj.Parent.DialogsMap('wirelessAppContainer.transmitter.TxWaveformDialogICT');
                setVisible(txDialog, 'TukeyWindowing', ~obj.hasWindowing());
            end
        end
        function phyChangedGUI(obj, ~)
            phyChanged(obj);
            obj.layoutUIControls();
            obj.Parent.GenerationDialog.layoutUIControls();
        end

        function psduChanged(obj, ~)
            try
                val = obj.PSDULength;
                validateattributes(val, {'numeric'}, {'positive', 'scalar', '<=', 2^18-1}, '', 'PSDULength');
            catch e
                obj.errorFromException(e);
            end
        end

        function mcsChanged(obj, ~)
            mcs = str2double(obj.MCS);
            val = strcmp(obj.TonePairingType, 'Dynamic') && (mcs >= 13 && mcs <= 17);
            setVisible(obj, {'DTPGroupPairIndex', 'DTPIndicator'}, val);
            setVisible(obj, 'TonePairingType', mcs >= 13 && mcs <= 17);
            setVisible(obj, {'AggregatedMPDU', 'LastRSSI'}, mcs ~= 0);
        end
        function mcsChangedGUI(obj, ~)
            mcsChanged(obj);
            obj.layoutUIControls();
        end

        function tonePairingChangedGUI(obj, ~)
            mcsChanged(obj);
            obj.layoutUIControls();
        end

        function trainingLengthChanged(obj, ~)
            setVisible(obj, {'PacketType', 'BeamTrackingRequest'}, obj.TrainingLength > 0);
        end
        function trainingLengthChangedGUI(obj, ~)
            trainingLengthChanged(obj);
            obj.layoutUIControls();
        end

        function n = get.MCS(obj)
            n = getDropdownVal(obj, 'MCS');
            n = strtrim(n(1:min([strfind(n, '/') strfind(n, '(')])-1));
        end
        function set.MCS(obj, value)
        % The MCS value will be in the first 4 characters (1 to 12.6).
        % Discrad remaining characters as they include ratios which may
        % match MCS number.
            mcsStrs = cellfun(@(x)x(1:4), obj.MCSGUI.(obj.DropdownValues), 'UniformOutput', false);
            % The first match will be the correct match
            obj.MCSGUI.Value = obj.MCSGUI.(obj.DropdownValues){find(contains(mcsStrs, value), 1, 'first')};

            obj.mcsChanged();
        end

        function n = get.PacketType(obj)
            n = getDropdownVal(obj, 'PacketType');
            if strcmp(n, 'Receive training')
                n = 'TRN-R';
            else
                n = 'TRN-T';
            end
        end
        function set.PacketType(obj, val)
            if strcmp(val, 'TRN-R')
                val = 'Receive training';
            else
                val = 'Transmit training';
            end
            setDropdownVal(obj, 'PacketType', val);
        end

        function dtpEditChanged(obj, ~)
            try
                val = obj.DTPGroupPairIndex;
                validateattributes(val, {'numeric'}, {'column', 'nrows', 42, 'nonnegative', '<=', 41}, '', 'DTPGroupPairIndex');
            catch e
                obj.errorFromException(e);
            end
        end

        function tf = hasOversampling(~)
        % Format does not include oversampling parameter
            tf = false;
        end

    end
end
