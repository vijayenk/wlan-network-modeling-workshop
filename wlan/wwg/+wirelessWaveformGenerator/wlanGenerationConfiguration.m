classdef wlanGenerationConfiguration < wirelessAppContainer.sources.PacketizedSourceDialog
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent, Hidden)
        % The property used to set the scrambler initialization in the
        % generator config indirectly using other controls in the app
        ScramblerInitializationGeneratorVar
    end

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        WindowTransitionTime
        OutputSampleRate
    end

    properties (Hidden)
        ScramblerInitializationType = 'numericEdit'
        ScramblerInitializationLabel
        ScramblerInitializationGUI
        InitialScramblerSequenceType = 'numericEdit'
        InitialScramblerSequenceLabel
        InitialScramblerSequenceGUI
        WindowTransitionTimeType = 'numericEdit'
        WindowTransitionTimeLabel
        WindowTransitionTimeGUI
        OversamplingFactorType = 'numericEdit'
        OversamplingFactorLabel
        OversamplingFactorGUI
        OutputSampleRateType = 'numericText'
        OutputSampleRateLabel
        OutputSampleRateGUI
    end

    methods % constructor
        function obj = wlanGenerationConfiguration(parent)
            obj@wirelessAppContainer.sources.PacketizedSourceDialog(parent); % call base constructor

            % add callbacks
            obj.ScramblerInitializationGUI.(obj.Callback) = @(a, b) scramblerInitializationChanged(obj, []);
            obj.InitialScramblerSequenceGUI.(obj.Callback) = @(a, b) initialScramblerSequenceChanged(obj, []);
            obj.WindowTransitionTimeGUI.(obj.Callback) = @(a, b) windowTimeChanged(obj, []);
            obj.OversamplingFactorGUI.(obj.Callback) = @(a, b) oversamplingFactorChangedGUI(obj, []);

        end

        function adjustSpec(obj)
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:GenConfigTitle'));
        end

        function props = displayOrder(~)
            props = {'NumFrames'; 'IdleTime'; 'InputSource'; 'InputValue'; ...
                     'OversamplingFactor'; 'ScramblerInitialization'; 'InitialScramblerSequence'; 'WindowTransitionTime'; 'OutputSampleRate'};
        end

        function props = props2ExcludeFromConfig(obj)
        % Returns list of properties from Dialog which are not in
        % configuration object
            if useInitialScramblerSequence(obj)
                props = {'ScramblerInitialization'};
            else
                props = {'InitialScramblerSequence'};
            end
            if ~hasOversampling(obj.Parent.CurrentDialog)
                props = [props 'OversamplingFactor'];
            end
            props = [props 'OutputSampleRate'];
        end

        function restoreDefaults(obj)
            restoreDefaults@wirelessAppContainer.sources.PacketizedSourceDialog(obj);
            type = obj.Parent.WaveformGenerator.pCurrentExtensionType;
            if strcmp(type, '802.11ad')
                obj.WindowTransitionTime = 16/2640e6;
                obj.ScramblerInitialization = 2;
            else
                obj.WindowTransitionTime = 1e-7;
                obj.ScramblerInitialization = 93;
            end
            obj.InitialScramblerSequence = 11;
            obj.OversamplingFactor = 1;
        end

        function config = applyConfiguration(obj, config)
            applyConfiguration@wirelessAppContainer.sources.BitSourceDialog(obj, config);
            waveDialog = obj.Parent.CurrentDialog;
            updateSampleRate(waveDialog);
        end

        function scramblerInitializationChanged(obj, ~)
            try
                val = obj.ScramblerInitialization;
                type = obj.Parent.WaveformGenerator.pCurrentExtensionType;
                if strcmp(type, '802.11ad')
                    mcs = str2double(obj.Parent.DialogsMap('wirelessWaveformGenerator.wlanDMGDialog').MCS);
                    if mcs == 0
                        minVal = 1;
                        maxVal = 15;
                    elseif any(abs(mcs - [9.1 12.1 12.2 12.3 12.4 12.5 12.6]) < eps)
                        minVal = 0;
                        maxVal = 31;
                    else %OFDM
                        minVal = 1;
                        maxVal = 127;
                    end
                else
                    minVal = 1;
                    maxVal = 127;
                end
                validateattributes(val, {'double', 'int8'}, {'>=', minVal, '<=', maxVal}, '', 'Scrambler Initialization');
            catch e
                obj.errorFromException(e);
            end
        end

        function initialScramblerSequenceChanged(obj, ~)
        % Validate user input is within range based on configuration
            try
                val = obj.InitialScramblerSequence;
                range = scramblerRange(getConfiguration(obj.Parent.CurrentDialog));
                validateattributes(val, {'numeric'}, {'>=', range(1), '<=', range(2)}, '', 'Initial scrambler sequence');
            catch e
                obj.errorFromException(e);
            end
        end

        function var = get.ScramblerInitializationGeneratorVar(obj)
        % Get the appropriate ScramblerInitialization property to user when
        % generating the waveform based on app controls
            if useInitialScramblerSequence(obj)
                var = 'InitialScramblerSequence';
            else
                var = 'ScramblerInitialization';
            end
        end

        function oversamplingFactorChangedGUI(obj, ~)
        % Validate value
            try
                osf = obj.OversamplingFactor;
                validateattributes(osf, {'numeric'}, {'real','finite','scalar','>=',1}, '', 'Oversampling factor')
            catch e
                obj.errorFromException(e);
            end
            waveDialog = obj.Parent.CurrentDialog;
            updateSampleRate(waveDialog);
        end

        function n = get.OutputSampleRate(obj)
            n = str2double(obj.OutputSampleRateGUI.(obj.TextValue)(1:end-4));
        end
        function set.OutputSampleRate(obj, value)
            obj.OutputSampleRateGUI.(obj.TextValue) = [num2str(value) ' MHz'];
        end

        function n = get.WindowTransitionTime(obj)
            if isempty(obj.WindowTransitionTimeGUI.(obj.EditValue))
                n = 0;
            else
                n = evalin('base', obj.WindowTransitionTimeGUI.(obj.EditValue));
            end
        end
        function set.WindowTransitionTime(obj, value)
            obj.WindowTransitionTimeGUI.(obj.EditValue) = num2str(value);

            obj.windowTimeChanged();
        end

        function windowTimeChanged(obj, varargin)
            if isempty(varargin) || isempty(varargin{1})
                waveDialog = obj.Parent.CurrentDialog;
            else
                waveDialog = varargin{1};
            end

            if isempty(obj.Parent.WaveformGenerator) || ...
                    ~contains(obj.Parent.WaveformGenerator.pCurrentExtensionType, '.11') || ...
                    contains(obj.Parent.WaveformGenerator.pCurrentExtensionType, '.11b/g')
                return % initialization with CST/OFDM
            end
            type = obj.Parent.WaveformGenerator.pCurrentExtensionType;
            try
                val = obj.WindowTransitionTime;
                if strcmp(type, '802.11ad')
                    maxValue = 256/2640e6;

                elseif ~isa(waveDialog, 'wirelessWaveformGenerator.axNonHTDialog')  && (isa(waveDialog, 'wirelessWaveformGenerator.wlanHEBaseDialog') || isa(waveDialog, 'wirelessWaveformGenerator.wlanEHTBaseDialog'))
                    % The 'WindowTransitionTime' value must be less than or
                    % equal to twice the minimum cyclic prefix duration
                    % within all fields in the waveform. Therefore the
                    % cyclic prefix duration of the pre-HE fields limits
                    % the maximum 'WindowTransitionTime' to 1.6 us, rather
                    % than depending on the guard interval.
                    maxValue = 1.6e-06;
                else
                    if ~isa(waveDialog, 'wirelessWaveformGenerator.axNonHTDialog') && isa(waveDialog, 'wirelessWaveformGenerator.wlanHTDialog')
                        if strcmp(waveDialog.GuardInterval, 'Long')
                            if strcmp(type, '802.11ah')
                                maxValue = 1.6e-5;
                            else
                                maxValue = 1.6e-6;
                            end
                        else
                            if strcmp(type, '802.11ah')
                                maxValue = 8e-6;
                            else
                                maxValue = 8e-7;
                            end
                        end
                    else
                        try
                            if strcmp(waveDialog.ChannelBandwidth, 'CBW5')
                                maxValue = 6.4e-6;
                            elseif strcmp(waveDialog.ChannelBandwidth, 'CBW10')
                                maxValue = 3.2e-6;
                            else % CBW20, CBW40, CBW80
                                maxValue = 1.6e-6;
                            end
                        catch
                            % it could happen during a transition from a different type
                            maxValue = inf;
                        end
                    end
                end
                validateattributes(val, {'numeric'}, {'nonnegative', 'scalar', '<=', maxValue}, '', 'Window Transition Time');
            catch e
                obj.errorFromException(e);
            end
        end

        function msg = getMsgString(~, id, varargin)
            msgID = ['wlan:waveformGeneratorApp:' id];
            msg = getString(message(msgID, varargin{:}));
        end
    end
end

function useit = useInitialScramblerSequence(obj)
    waveDialog = obj.Parent.CurrentDialog;
    if any(strcmp(class(waveDialog), {'wirelessWaveformGenerator.axNonHTDialog', 'wirelessWaveformGenerator.wlanNonHTDialog'}))
        useit = waveDialog.SignalChannelBandwidth;
    else
        useit = false;
    end
end
