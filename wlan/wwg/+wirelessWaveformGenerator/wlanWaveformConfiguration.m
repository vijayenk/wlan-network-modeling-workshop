classdef wlanWaveformConfiguration < wirelessWaveformGenerator.WaveformConfigurationDialog
%

%   Copyright 2018-2024 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        PSDULength
    end

    properties (Hidden)
        generateFcn = @wlanWaveformGenerator

        PSDULengthType = 'numericEdit'
        PSDULengthLabel
        PSDULengthGUI
    end

    methods % constructor
        function obj = wlanWaveformConfiguration(parent)
            obj@wirelessWaveformGenerator.WaveformConfigurationDialog(parent); % call base constructor
        end

        function setupDialog(obj)
            valWin = true;
            generationDialog = obj.Parent.GenerationDialog;
            setVisible(generationDialog, {'OversamplingFactor', 'ScramblerInitialization', 'OutputSampleRate'}, true);
            setVisible(generationDialog, 'InitialScramblerSequence', false);
            setVisible(generationDialog, 'WindowTransitionTime', valWin);
            generationDialog.ScramblerInitialization = 93;
            generationDialog.WindowTransitionTime = 1.0e-07;
            layoutUIControls(generationDialog);

            setupDialog@wirelessWaveformGenerator.WaveformConfigurationDialog(obj);
            % Generator defaults are restored by setupDialog. Always call
            % updateSampleRate after setupDialog
            updateSampleRate(obj);
        end
        % Set Help button to doc page of WLAN Waveform Generator:
        function helpCallback(~)
            helpview('wlan', 'WLANWaveformGenerator_app');
        end

        function updateSampleRate(obj)
        % Set the sample rate in the generation dialog based on current
        % waveform
            genDialog = obj.getGenerationDialog();
            if ~isempty(genDialog) && isa(genDialog, 'wirelessWaveformGenerator.wlanGenerationConfiguration')
                genDialog.OutputSampleRate = getSampleRate(obj)/1e6;
            end
        end

        function sr = getSampleRate(obj)
        % Use try-catch as sample rate may be called by a Dialog before
        % loading complete
            try
                cfg = obj.getConfiguration();
                if hasOversampling(obj)
                    try
                        osf = obj.getGenerationDialog().OversamplingFactor;

                        % Ensure osf is positive
                        if osf < 0
                            osf = 1;
                        end
                    catch
                        % Ensure osf is valid (e.g., not a character)
                        osf = 1;
                    end
                else
                    osf = 1;
                end
                sr = wlanSampleRate(cfg)*osf;
            catch
                % Fetch the channel bandwidth and calculate the sampling
                % rate value from the current dialog, even if the
                % getConfiguration call fails
                osf = obj.getGenerationDialog().OversamplingFactor;
                sr = wlanSampleRate(obj.ChannelBandwidth)*osf;
            end
        end
        function str = getSampleRateStr(obj)
            if hasOversampling(obj)
                str = ['wlanSampleRate(' obj.configGenVar ', ''OversamplingFactor'', '  obj.getGenerationDialog().OversamplingFactorGUI.(obj.EditValue) ')'];
            else
                str = ['wlanSampleRate(' obj.configGenVar ')'];
            end
        end

        function b = hasWindowing(~)
            b = true;
        end
        function b = mayHaveEmptyTimePeriods(obj)
        % prevent Spectrum Analyzer from going blank for empty signal contents
            b = false;
            generationDialog = obj.Parent.GenerationDialog;
            if ~isempty(generationDialog)
                b = generationDialog.NumFrames > 1 && generationDialog.IdleTime >0;
            end
        end

        function config = getConfigurationForSave(obj)
            config.waveform = obj.getConfiguration;  % wlanConfig objects do not accept workspace variables (strings)
            config.generation = getConfigurationForSave(obj.Parent.GenerationDialog);
            config.filtering = getConfigurationForSave(obj.Parent.FilteringDialog);
        end

        function c = getSourceClass(~)
            c = 'wirelessWaveformGenerator.wlanGenerationConfiguration';
        end

        function b = zoomSinglePacketTimeScope(~)
            b = false;
        end

        function psduChanged(obj, ~)
            try
                val = obj.PSDULength;
                validateattributes(val, {'numeric'}, {'positive', 'scalar', '<=', 4095}, '', 'PSDULength');
            catch e
                obj.errorFromException(e);
            end
        end

        function n = get.PSDULength(obj)
            n = getPSDULength(obj);
        end

        function n = getPSDULength(obj)
            if isa(obj.PSDULengthGUI, 'matlab.ui.control.Label')
                n = getTextNumVal(obj, 'PSDULength');
            else
                n = getEditVal(obj, 'PSDULength');
            end
        end
        function set.PSDULength(obj, value)
            if isa(obj.PSDULengthGUI, 'matlab.ui.control.Label')
                setTextVal(obj, 'PSDULength', value);
            else
                setEditVal(obj, 'PSDULength', value);
            end

            obj.psduChanged();
        end

        function waveform = generateWaveform(obj)
            % The error for an invalid allocation indices combination
            % should only be thrown if the "Generate" button is pressed,
            % not while switching between EHT transmission types. This has
            % been ensured using the obj.EHTAllocationIndex1GUI.UserData
            % flag.
            if isa(obj,'wirelessWaveformGenerator.wlanEHTOFDMADialog') && strcmp(obj.EHTTransmission,'OFDMA')
                obj.EHTAllocationIndex1GUI.UserData = 'GenerateButtonPressed';

                % [Generation-time check] If the user-provided allocation
                % indices are scalar, error in dialog and stop waveform
                % generation if any allocation is not scalar, otherwise
                % generate the new config object
                try
                    for i = 1:wlan.internal.cbwStr2Num(obj.ChannelBandwidth)/20
                        validateattributes(getEditVal(obj, ['EHTAllocationIndex' num2str(i)]),...
                            {'numeric'},{'real','integer','scalar','>=',0,'<=',303}, '', ['Allocation index #' num2str(i)])
                    end
                catch e
                    % Throw the exception to the generateWaveform try-catch
                    % and terminate the generation
                    throw(e)
                end
            end

            % Validate TXOPDuration for EHT. This is to make sure that the same error message is thrown when the user press the generate button
		    if isa(obj,'wirelessWaveformGenerator.wlanEHTDialog') %#ok<ALIGN>
                try
                    x = obj.TXOPDuration;
                    isInValid = ~isempty(x) && (~isnumeric(x) || ~isscalar(x) || x<0 || x>8448 || ~isreal(x) || (mod(x,1)~=0));
                    coder.internal.errorIf(isInValid,'wlan:waveformGeneratorApp:InvalidTXOPDurationWWG');
                catch e
                    throw(e)
                end
            end

            config = obj.getConfiguration;
            generationDialog = obj.Parent.GenerationDialog;
            MPDU = generationDialog.MPDU(obj.PSDULength*8);

            numFrames = generationDialog.NumFrames;
            idleTime = generationDialog.IdleTime;
            % The ScramblerInitialization NV pair of the generator is set to
            % different properties based on the configuration
            scramblerInit = generationDialog.(generationDialog.ScramblerInitializationGeneratorVar);

            waveform = [];
            if isa(obj, 'wirelessWaveformGenerator.wlanOFDMWaveformConfiguration')
                windowTime = generationDialog.WindowTransitionTime;
                osf = generationDialog.OversamplingFactor;
                waveform = [waveform; ...
                            obj.generateFcn(MPDU, config, 'NumPackets', numFrames, ...
                                            'IdleTime', idleTime, 'ScramblerInitialization', scramblerInit, ...
                                            'WindowTransitionTime', windowTime, 'OversamplingFactor', osf)];
            else
                waveform = [waveform; ...
                            obj.generateFcn(MPDU, config, 'NumPackets', numFrames, ...
                                            'IdleTime', idleTime, 'ScramblerInitialization', scramblerInit)];
            end
        end
        function addGenerationCode(obj, sw)
            genDialog = obj.getGenerationDialog();
            addcr(sw, ['waveform = wlanWaveformGenerator(in, ' obj.configGenVar ', ...']);
            addcr(sw, '''NumPackets'', numPackets, ...');
            addcr(sw, ['''IdleTime'', '  genDialog.IdleTimeGUI.(obj.EditValue) ', ...']);
            if hasOversampling(obj)
                addcr(sw, ['''OversamplingFactor'', '  genDialog.OversamplingFactorGUI.(obj.EditValue) ', ...']);
            end
            % The ScramblerInitialization NV pair of the generator is set to
            % different properties based on the configuration
            scramblerInitString = genDialog.([(genDialog.ScramblerInitializationGeneratorVar) 'GUI']).(obj.EditValue);
            addcr(sw, ['''ScramblerInitialization'', ' scramblerInitString ', ...']);
            addcr(sw, ['''WindowTransitionTime'', '  genDialog.WindowTransitionTimeGUI.(obj.EditValue) ');']);
        end

        function addInputCode(obj, sw)
        % Input source for the exported MATLAB code
            psduLen = getPSDULength(obj);
            genDialog = obj.getGenerationDialog();
            if all(psduLen == 0) % NDP
                addcr(sw, '% Input bit source');
                addcr(sw, 'in = [];');
                addcr(sw, ['numPackets = ' genDialog.NumFramesGUI.(obj.EditValue) ';']);
                addcr(sw, '');
            else % Data packet
                 % When the "Bit source" is one of the PN sequences: If PSDULength is
                 % a scalar, the code for a single source is exported. Otherwise, if
                 % PSDULength is a vector, a for loop is exported to handle multiple
                 % sources.
                 %
                 % When the "Bit source" is User-defined, input bits become
                 % randi([0, 1], 1000, 1)
                addcr(sw, ['numPackets = ' genDialog.NumFramesGUI.(obj.EditValue) ';']);
                addInputCode(obj.Parent.GenerationDialog, sw, ['8*' obj.psduGetterStr(obj.configGenVar)], false, ~isscalar(psduLen));
                addcr(sw, '');
            end
        end

        function str = psduGetterStr(~, cfgStr)
            str = [cfgStr '.PSDULength'];
        end

        function [configline, configParam] = getConfigParam(obj)
            configline = '';
            configParam = obj.configGenVar;
        end

        function [blockName, maskTitleName, waveNameText] = getMaskTextWaveName(obj)
            blockName = ['WLAN ' strrep(obj.Parent.WaveformGenerator.pCurrentExtensionType,'/','//')]; % Symbol '/' misinterpreted by Simulink;
            maskTitleName = ['WLAN ' obj.Parent.WaveformGenerator.pCurrentExtensionType ' Waveform Generator'];
            waveNameText = ['WLAN ' obj.Parent.WaveformGenerator.pCurrentExtensionType];
        end

        function userDataText = getUserDataText(~)
            userDataText = 'configuration';
        end

        function AppDochyperlink = getAppLink(~)
            AppDochyperlink = '<a href="matlab:helpview(''wlan'',''WLANWaveformGenerator_app'')">WLAN Waveform Generator</a>';
        end

        function BlockDochyperlink = getBlockLink(~)
            BlockDochyperlink = 'helpview(''wlan'', ''WLANWaveformGenerator_block'')';
        end

        function cellDialogs = getDialogsPerColumn(obj)
            cellDialogs{1} = {obj obj.Parent.GenerationDialog obj.Parent.FilteringDialog};
        end

        function str = getCatalogPrefix(~)
            str = 'wlan:waveformGeneratorApp:';
        end

        function o = offersCCDF(~)
            o = true;
        end

        function tf = hasOversampling(~)
        % By default WLAN waveforms include oversampling configuration
            tf = true;
        end

        % Overload to modify loaded configuration
        function newData = mapToNewRelease(obj, newData)
            newData = mapToNewRelease@wirelessWaveformGenerator.WaveformConfigurationDialog(obj,newData);
            % If no generation oversampling field and Sps field when loading,
            % then use the Sps value as oversampling factor. This maintains
            % backwards compatibility
            if hasOversampling(obj) && isfield(newData.Waveform.Configuration.filtering,'Sps') && ~isfield(newData.Waveform.Configuration.generation,'OversamplingFactor')
                newData.Waveform.Configuration.generation.OversamplingFactor = newData.Waveform.Configuration.filtering.Sps;
                newData.Waveform.Configuration.filtering.Sps = 1; % Default to 1 as oversampling applied in generator
            end
        end
    end
end
