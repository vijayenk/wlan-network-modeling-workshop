classdef wlanDSSSDialog < wirelessWaveformGenerator.wlanWaveformConfiguration
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Constant)
        Modulation = 'DSSS'
    end

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        DataRate
    end

    properties (Hidden)
        configFcn     = @wlanNonHTConfig
        configGenFcn  = @wlanNonHTConfig
        configGenVar  = 'dsssCfg'

        TitleString = 'IEEE 802.11b/g (Non High Throughput)'
        ModulationType = 'charText'
        ModulationLabel
        ModulationGUI
        DataRateType = 'charPopup'
        DataRateDropDown = {'1 Mbps', '2 Mbps', '5.5 Mbps', '11 Mbps'}
        DataRateLabel
        DataRateGUI
        PreambleType = 'charPopup'
        PreambleDropDown = {'Long', 'Short'}
        PreambleLabel
        PreambleGUI
        LockedClocksType = 'checkbox'
        LockedClocksGUI
    end

    methods % constructor
        function obj = wlanDSSSDialog(parent)
            obj@wirelessWaveformGenerator.wlanWaveformConfiguration(parent); % call base constructor
        end

        function props = displayOrder(~)
            props = {'Modulation'; 'DataRate'; 'Preamble'; 'LockedClocks'; 'PSDULength'};
        end

        function b = spectrumEnabled(~)
            b = true;
        end

        function b = timeScopeEnabled(~)
            b = true;
        end

        function b = offersConstellation(~)
            b = true;
        end

        function b = constellationEnabled(~)
            b = true;
        end

        function b = hasWindowing(~)
            b = false;
        end

        function setupDialog(obj)
            obj.Parent.FilteringDialog.FilteringDropDown = {'None', 'Normal raised cosine', 'Root raised cosine', 'Custom'};
            obj.Parent.FilteringDialog.FilteringGUI.(obj.DropdownValues) = obj.Parent.FilteringDialog.FilteringDropDown;

            generationDialog = obj.Parent.GenerationDialog;
            % No oversampling factor, scrambler or windowing control for DSSS
            setVisible(generationDialog, {'OversamplingFactor', 'ScramblerInitialization', ...
                                          'InitialScramblerSequence', 'WindowTransitionTime', 'OutputSampleRate'}, false);
            layoutUIControls(generationDialog);

            setupDialog@wirelessWaveformGenerator.WaveformConfigurationDialog(obj);
        end

        function createUIControls(obj)
            createUIControls@wirelessWaveformGenerator.WaveformConfigurationDialog(obj);
            obj.ModulationGUI.(obj.TextValue) = 'DSSS';
            setEnable(obj, 'Preamble', false);
            obj.DataRateGUI.(obj.Callback) = @(a, b) rateChanged(obj, []);
        end

        function addGenerationCode(obj, sw)
            genDialog = obj.getGenerationDialog();
            addcr(sw, ['waveform = wlanWaveformGenerator(in, ' obj.configGenVar ', ...']);
            addcr(sw, ['''NumPackets'', '  genDialog.NumFramesGUI.(obj.EditValue) ', ...']);
            addcr(sw, ['''IdleTime'', '  genDialog.IdleTimeGUI.(obj.EditValue) ');']);
        end


        function restoreDefaults(obj)
            obj.DataRate = '1Mbps';
            obj.Preamble = 'Long';
            obj.LockedClocks = true;
            obj.PSDULength = 1000;
        end

        function config = getConfigurationForSave(obj)
            config = getConfigurationForSave@wirelessWaveformGenerator.wlanWaveformConfiguration(obj);
            config.generation = rmfield(config.generation, {'ScramblerInitialization', 'WindowTransitionTime'});
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Modulation: '' ' obj.configGenVar '.Modulation newline ...' newline ...
                   '''Data rate: '' insertBefore(' obj.configGenVar '.DataRate,lettersPattern,'' '') newline ...' newline ...
                   '''Preamble: '' ' obj.configGenVar '.Preamble newline ...' newline ...
                   '''PSDU: '' num2str(' obj.configGenVar '.PSDULength) '' bytes'' newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function rateChanged(obj, ~)
            if strcmp(obj.DataRate, '1Mbps')
                setEnable(obj, 'Preamble', false);
                obj.Preamble = 'Long';
            else
                setEnable(obj, 'Preamble', true);
            end
        end

        function dataRate = get.DataRate(obj)
        % change '1 Mbps' to '1Mbps' so that waveform generator does not error
            val = getDropdownVal(obj, 'DataRate');
            dataRate = replace(val, ' ', '');
        end
        function set.DataRate(obj, val)
        % change '1 Mbps' to '1Mbps' so that waveform generator does not error
            val = replace(val, 'M', ' M');
            setDropdownVal(obj, 'DataRate', val);
        end

        function tf = hasOversampling(~)
        % Format does not include oversampling parameter
            tf = false;
        end
    end
end
