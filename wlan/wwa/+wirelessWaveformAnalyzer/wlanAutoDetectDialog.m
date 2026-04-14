classdef wlanAutoDetectDialog < wirelessWaveformAnalyzer.waveformConfigurationDialog
    %

    %   Copyright 2023-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        EqualizationMethod
    end

    properties (Hidden)
        TitleString = getString(message('comm:waveformAnalyzer:DemodTitle'))
        configFcn = @struct
        configGenFcn = @struct
        configGenVar = 'cfg'

        DCBlockingType = 'checkbox'
        DCBlockingLabel
        DCBlockingGUI

        PilotTimeTrackingType = 'checkbox'
        PilotTimeTrackingGUI
        PilotTimeTrackingLabel

        PilotPhaseTrackingType = 'checkbox'
        PilotPhaseTrackingGUI
        PilotPhaseTrackingLabel

        PilotGainTrackingType = 'checkbox'
        PilotGainTrackingGUI
        PilotGainTrackingLabel

        IQImbalanceCorrectionType = 'checkbox'
        IQImbalanceCorrectionGUI
        IQImbalanceCorrectionLabel

        DataAidedEqualizationType = 'checkbox'
        DataAidedEqualizationGUI
        DataAidedEqualizationLabel

        EqualizationMethodType = 'charPopup'
        EqualizationMethodDropDown = {'MMSE', 'ZF'}
        EqualizationMethodGUI
        EqualizationMethodLabel
    end

    methods (Static)
        function hPropDb = getPropertySet(~)
            hPropDb = extmgr.PropertySet(...
                'Visualizations', 'mxArray', {'Subcarrier EVM', 'Symbol EVM', 'Spectral Flatness', 'Detection Info', 'Signaling Info', 'Field Info', 'RU Info', 'User Info'});
        end
    end

    methods
        function obj = wlanAutoDetectDialog(parent)
            obj@wirelessWaveformAnalyzer.waveformConfigurationDialog(parent); % call base constructor
            className = 'wirelessWaveformAnalyzer.wwaImportDialog';
            if ~isKey(obj.Parent.DialogsMap, className)
                obj.Parent.DialogsMap(className) = eval([className '(obj.Parent)']); %#ok<*EVLDOT>
            end
        end

        function props = displayOrder(~)
            props = {'DCBlocking'; 'PilotTimeTracking'; 'PilotPhaseTracking'; 'PilotGainTracking'; 'IQImbalanceCorrection'; 'DataAidedEqualization'; 'EqualizationMethod'};
        end

        function restoreDefaults(obj)
            obj.DCBlocking = true;
            obj.PilotTimeTracking = true;
            obj.PilotPhaseTracking = true;
            obj.PilotGainTracking = true;
            obj.IQImbalanceCorrection = false;
            obj.DataAidedEqualization = false;
            obj.EqualizationMethod = 'MMSE';
        end

        % EqualizationMethod enable
        function r = get.EqualizationMethod(obj)
            r =  obj.EqualizationMethodDropDown{contains(obj.EqualizationMethodDropDown, obj.EqualizationMethodGUI.Value)};
        end
        function set.EqualizationMethod(obj, val)
            obj.EqualizationMethodGUI.Value = obj.EqualizationMethodGUI.Items{contains(obj.EqualizationMethodDropDown, val)};
        end

        function sr = getSampleRate(obj)
            % Set the symbol rate, as per the standard
            className = 'wirelessWaveformAnalyzer.wwaImportDialog';
            if isKey(obj.Parent.DialogsMap, className)
                wwaImportDialogProp = obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog');
                sr = wwaImportDialogProp.SamplingRate;
            end
            % Overwrite the value with the one present in radio dialog
            if ~isempty(obj.Parent.AppObj.pParameters.RadioDialog)
                sr = obj.Parent.AppObj.pParameters.RadioDialog.SamplingRate;
            end
        end

        function sps = getSamplesPerSymbol(obj)
            % % importDialog = obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog');
            % % channelBW = wlan.internal.cbwStr2Num(importDialog.ChannelBandwidth)*1e6;
            % % sps = importDialog.SamplingRate/channelBW;
            sps = 1;
        end

        function b = offersTimeScope(~)
            b = true;
        end

        function b = offersSpectrumAnalyzer(~)
            b = true;
        end

        function b = offersConstellation(~)
            b = true;
        end

        function b = constellationEnabled(~)
            b = true;
        end

        function b = overridesConstellatonPlot(~)
            b = true;
        end

        function b = constellationNames(obj)
            b = obj.Parent.WaveformGenerator.pLegendStr;
        end

        function config = getConfigForSave(obj)
            config.demodParams = getConfigurationForSave(obj);
            importObj = obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog');
            config.waveformParams = getImportConfiguration(importObj);
            waveGenDialog = obj.Parent.WaveformGenerator;
            config.waveformParams.WLANWaveform = waveGenDialog.pWaveform;
        end

        function customLoadActions(obj, newData)
            importDialog = obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog');
            importDialog.applyConfiguration(newData.Waveform.Configuration.waveformParams);
            if isfield(newData.Waveform.Configuration,'demodParams')
                obj.Parent.CurrentDialog.applyConfiguration(newData.Waveform.Configuration.demodParams);
            end
            obj.Parent.WaveformGenerator.pWaveform = newData.Waveform.Configuration.waveformParams.WLANWaveform;
        end

        function cellDialogs = getDialogsPerColumn(obj)
            % When IQ file is selected or when App just launched. In these
            % cases, show the Waveform Parameters accordion and
            % Demodulation Parameters accordion.
            if contains(obj.Parent.AppObj.pCurrentInputMode,'File') || ...
                    isempty(obj.Parent.AppObj.pCurrentInputMode)
                cellDialogs{1} = {obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog') obj};
            else
                % Hardware or Instrument
                dialogs = {obj.Parent.AppObj.pParameters.RadioDialog obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog') obj};
                dialogs = dialogs(~cellfun('isempty',dialogs));
                cellDialogs{1} = dialogs;
            end
        end

        function extraPanels = getExtraPanels(obj)
            extraPanels = getExtraPanels@wirelessWaveformAnalyzer.waveformConfigurationDialog(obj);
            extraPanelTabs = {obj.Parent.AppObj.pParameters.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog')};
            extraPanels = cat(1,extraPanels,extraPanelTabs);
        end

        function defaultVisualLayout(obj)
            for idx = 1:length(obj.visualNames)
                obj.setVisualState(obj.visualNames{idx}, true);
            end
        end

        function detInfo = detectionInfoLayout(obj, analyzer, pktNum)
            [TdetSum, detInfo] = analyzer.detectionSummary;

            TMacSum = analyzer.macSummary(pktNum);
            if ~isempty(TMacSum) 
                if any(strcmp(TMacSum.("FCS Status"), 'Not Verified')) % Check if any frame is 'Not Verified'
                    TMacSumFCSStatus = 'Not Verified';
                elseif ~all(strcmp(TMacSum.("FCS Status"), 'Pass'))  % Even if FCS check fails for one MDPU frame
                    TMacSumFCSStatus = 'Fail';
                else
                    TMacSumFCSStatus = 'Pass'; % Every MPDU frame should pass FCS
                end
                TMacSumSFType = unique(TMacSum.("MAC Frame Sub-type"));
            else % No MAC is displayed for an NDP packet
                TMacSumFCSStatus = '-';
                TMacSumSFType = '-';
            end

            currDialog = obj.Parent.CurrentDialog;
            hFig1 = currDialog.getVisualFig(obj.visualNames{4});
            % Update the detection info layout visibility with reference to
            % Visualize dropdown. 
            if ~currDialog.getVisualState(obj.visualNames{4})
                hFig1.Visible = 'off';
            else
                hFig1.Visible = 'on';
            end
            if(~isempty(hFig1) && ~isempty(TdetSum))
                g = uigridlayout(hFig1);
                g.Scrollable = 'on';
                g.ColumnWidth = {'1x','1x'};
                g.RowHeight = {'fit', 'fit','fit'};

                TdetSumTemp = TdetSum(pktNum,:);
                TdetSumTemp.("FCS Status") = string(TMacSumFCSStatus);
                TdetSumTemp.("MAC Frame Sub-type") = string(TMacSumSFType);
                detInfo.FCSStatus = string(TMacSumFCSStatus);
                detInfo.MACFrameSubtype = string(TMacSumSFType);

                TdetSumTemp2 = rows2vars(TdetSumTemp);
                p1 = rmmissing(TdetSumTemp2);
                p0 = uitable(g,'Data',p1);
                p0.ColumnName{1} = 'Field';
                p0.ColumnName{2} = 'Value';
                p0.Layout.Row = [1 2];
                p0.Layout.Column = [1 2] ;
                p0.RowStriping = "off";
            end
        end

        function signalingInfo = signalingInfoLayout(obj, analyzer, pktNum)
            TsigSum = analyzer.signalingSummary(pktNum);
            currDialog = obj.Parent.CurrentDialog;
            hFig5 = currDialog.getVisualFig(obj.visualNames{5});            
            if ~currDialog.getVisualState(obj.visualNames{5})
                hFig5.Visible = 'off';
            else
                % Make the visibility to on as when visibility is set to
                % off due to signalingSummary being empty, it is still
                % retained as off in same app session. 
                hFig5.Visible = 'on';
            end
            if(~isempty(hFig5))
                if(~isempty(TsigSum))
                    g = uigridlayout(hFig5);
                    g.Scrollable = 'on';
                    g.ColumnWidth = {'1x','1x'};
                    g.RowHeight = {'fit', 'fit','fit'};

                    p0 = rmmissing(rows2vars(TsigSum(1,:)));
                    p1 = uitable(g,'Data',p0);
                    p1.ColumnName{1} = 'Field';p1.ColumnName{2} = 'Value';
                    p1.Layout.Row = [1 2];
                    p1.Layout.Column = [1 2];
                    p1.RowStriping = "off";

                    appObj = obj.Parent.AppObj;
                    if appObj.SuppressWarnings
                        warningsToSuppress = "MATLAB:table:ModifiedVarnames";
                        warningState = arrayfun(@(x)warning('off',x),warningsToSuppress);
                        restoreWarningState = @()arrayfun(@(x)warning(x),warningState);
                        warn = onCleanup(restoreWarningState);
                    end
                    % warning('off','MATLAB:table:ModifiedVarnames');
                    s = table2struct(TsigSum);
                    fns = fieldnames(s);
                    for idx = 1:length(fns)
                        v = s.(fns{idx});
                        if~(isnan(str2double(v)))
                            s.(fns{idx}) = str2double(v);
                        else
                            s.(fns{idx}) = char(v);
                        end
                        if contains(v,'0x')
                            s.(fns{idx}) = char(v);
                        end
                    end
                    signalingInfo = s;
                else
                    clf(hFig5);
                    hFig5.Visible = 'off';
                    signalingInfo = [];
                end
            end
        end

        function fieldInfo = fieldInfoLayout(obj, analyzer, pktNum)
            currDialog = obj.Parent.CurrentDialog;
            hFig6 = currDialog.getVisualFig(obj.visualNames{6});
            if ~currDialog.getVisualState(obj.visualNames{6})
                hFig6.Visible = 'off';
            else
                hFig6.Visible = 'on';
            end
            [TFSum, fieldInfo]= analyzer.fieldSummary(pktNum);
            if(~isempty(hFig6))
                if ~isempty(TFSum)
                    g = uigridlayout(hFig6);
                    g.Scrollable = 'on';
                    g.ColumnWidth = {'1x','1x'};
                    % g.RowHeight = {'fit', 'fit', 'fit'};

                    p1 = uitable(g,'Data',TFSum);
                    p1.Layout.Row = [1 2];
                    p1.Layout.Column = [1 2] ;
                    p1.RowStriping = "off";
                else
                    clf(hFig6);
                    hFig6.Visible = 'off';
                end
            end
        end

        function ruInfo = ruInfoLayout(obj, analyzer, pktNum)
            currDialog = obj.Parent.CurrentDialog;
            hFig7 = currDialog.getVisualFig(obj.visualNames{7});
            if ~currDialog.getVisualState(obj.visualNames{7})
                hFig7.Visible = 'off';
            else
                hFig7.Visible = 'on';
            end
            [TruSum, ruInfo] = analyzer.ruSummary(pktNum);
            if ~isempty(hFig7)
                if ~isempty(TruSum)
                    g = uigridlayout(hFig7);
                    g.Scrollable = 'on';
                    g.ColumnWidth = {'1x','1x'};

                    p1 = uitable(g,'Data',rows2vars(TruSum));
                    p1.ColumnName{1} = 'Field';
                    for cIdx = 2:size(p1.Data,2)
                        p1.ColumnName{cIdx} = sprintf('RU #%d',cIdx-1);
                    end
                    p1.Layout.Row = [1 2];
                    p1.Layout.Column = [1 2] ;
                    p1.RowStriping = "off";
                else
                    clf(hFig7);
                    hFig7.Visible = 'off';
                end
            end
        end

        function userInfo = userInfoLayout(obj, analyzer, pktNum)
            currDialog = obj.Parent.CurrentDialog;
            hFig8 = currDialog.getVisualFig(obj.visualNames{8});
            if ~currDialog.getVisualState(obj.visualNames{8})
                hFig8.Visible = 'off';
            else
                hFig8.Visible = 'on';
            end
            [TuserSum, psduBits] = analyzer.userSummary(pktNum);      
            if ~isempty(hFig8)
                if ~isempty(TuserSum)
                    g = uigridlayout(hFig8);
                    g.Scrollable = 'on';
                    g.ColumnWidth = {'1x','1x'};

                    p1 = uitable(g,'Data',rows2vars(TuserSum));
                    p1.ColumnName{1} = 'Field';
                    for cIdx = 2:size(p1.Data,2)
                        p1.ColumnName{cIdx} = sprintf('User #%d',cIdx-1);
                    end
                    p1.Layout.Row = [1 2];
                    p1.Layout.Column = [1 2] ;
                    p1.RowStriping = "off";

                    appObj = obj.Parent.AppObj;
                    if appObj.SuppressWarnings
                        warningsToSuppress = "MATLAB:table:ModifiedVarnames";
                        warningState = arrayfun(@(x)warning('off',x),warningsToSuppress);
                        restoreWarningState = @()arrayfun(@(x)warning(x),warningState);
                        warn = onCleanup(restoreWarningState);
                    end
                    s = table2struct(TuserSum);

                    fns = fieldnames(s);
                    for sIdx = 1:length(s)
                        for idx = 1:length(fns)
                            v = s(sIdx).(fns{idx});
                            if isstring(v)
                                if~(isnan(str2double(v)))
                                    s(sIdx).(fns{idx}) = str2double(v);
                                else
                                    s(sIdx).(fns{idx}) = char(v);
                                end
                            else
                                s(sIdx).(fns{idx}) = v;
                            end
                        end
                    end
                    userInfo = s;
                    if iscell(psduBits)
                        for i = 1:numel(userInfo)
                            userInfo(i).PSDU = psduBits{i}; % Assign the i-th PSDU bit sequence to the struct entry
                        end
                    else
                        for i = 1:numel(userInfo)
                            userInfo(i).PSDU = psduBits; % Directly assign if psduBits is not a cell array
                        end
                    end

                else
                    userInfo = [];
                    clf(hFig8);
                    hFig8.Visible = 'off';
                end
            end
        end

        function plotSubcarrierEVM(obj, analyzer, pktNum)
            hFig = obj.Parent.CurrentDialog.getVisualFig(obj.visualNames{1});
            hFig.Color = [1 1 1]*0.13;
            if(~isempty(hFig))
                clf(hFig);
                analyzer.plotSubcarrierEVM(hFig,pktNum);
            end
        end

        function plotSymbolEVM(obj, analyzer, pktNum)
            hFig = obj.Parent.CurrentDialog.getVisualFig(obj.visualNames{2});
            hFig.Color = [1 1 1]*0.13;
            if(~isempty(hFig))
                clf(hFig);
                analyzer.plotSymbolEVM(hFig,pktNum);
            end
        end

        function plotSpectralFlatness(obj, analyzer, pktNum)
            hFig = obj.Parent.CurrentDialog.getVisualFig(obj.visualNames{3});
            hFig.Color = [1 1 1]*0.13;
            if(~isempty(hFig))
                clf(hFig);
                wwaImportDialogProp = obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog');
                chanbw = wwaImportDialogProp.ChannelBandwidth;
                analyzer.plotSpectralFlatness(hFig,chanbw,pktNum);
            end
        end

        function [customConstellationOutputs, referenceConstellationOutputs, legendStr] = getConstellationSymbols(obj, analyzer, pktNum)
            [eqSym, referenceConstellation, legendStr] = analyzer.plotConstellation(pktNum);
            if(~isempty(referenceConstellation) && ~isempty(eqSym))
                userInfo = analyzer.userSummary(pktNum);
                userInfoMCS = userInfo.MCS;
                [~, idx] = unique(userInfoMCS);
                referenceConstellationOutputs = referenceConstellation(idx);
                % Assign eqSym as a cell array to customConstellationOutputs
                if(iscell(eqSym))
                    customConstellationOutputs = eqSym;
                else
                    customConstellationOutputs = {eqSym};
                end

                appObj = obj.Parent.AppObj;
                if numel(customConstellationOutputs) > 20
                    % Add this condition to avoid the multi-port error
                    % message when Constellation is disabled from visualize
                    % dropdown.
                    statusMsg = getString(message('comm:waveformAnalyzer:AnalyzingWaveform','WLAN'));
                    multiPortFlag = appObj.pPlotConstellation && (strcmp(appObj.pStatusLabel.Text,statusMsg));
                    if multiPortFlag
                        fig = obj.Parent.Layout.Parent;
                        msg = getString(message('comm:waveformAnalyzer:UnexpectedNumInputPorts'));
                        uiconfirm(fig,msg,'Unexpected number of input ports','Options','Ok','Icon','warning');
                    end
                    customConstellationOutputs = customConstellationOutputs(1:20);
                end
            else
                referenceConstellationOutputs = [];
                customConstellationOutputs = [];
            end
        end

        % For viewing Detection and Decode summary
        function [customConstellationOutputs, referenceConstellationOutputs, legendStr] = customVisualizations(obj,varargin)
            analyzerDialog = obj.Parent.WaveformGenerator;
            analyzer = analyzerDialog.prxAnalyzer;
            % For 1st Packet
            pktNum = 1;
            customConstellationOutputs = [];
            referenceConstellationOutputs = [];
            legendStr = [];
            analyzerOut = [];

            if(isempty(analyzer))
                obj.restoreAxes();
                return;
            else
                % Detection info
                detInfo = detectionInfoLayout(obj, analyzer, pktNum);
                analyzerOut.detectionInfo = detInfo;

                % Signaling info
                signalingInfo = signalingInfoLayout(obj, analyzer, pktNum);
                analyzerOut.signalingInfo = signalingInfo;

                % Field info
                fieldInfo = fieldInfoLayout(obj, analyzer, pktNum);
                analyzerOut.fieldInfo = fieldInfo;

                % RU info
                ruInfo = ruInfoLayout(obj, analyzer, pktNum);
                analyzerOut.ruInfo = ruInfo;

                % User info
                userInfo = userInfoLayout(obj, analyzer, pktNum);
                analyzerOut.userInfo = userInfo;

                % Update plots and analyzer outputs based on signaling
                % information
                if(~isempty(signalingInfo))

                    % Plot sub-carrier EVM
                    plotSubcarrierEVM(obj, analyzer, pktNum);

                    % Plot symbol EVM
                    plotSymbolEVM(obj, analyzer, pktNum);

                    % Plot spectral flatness
                    plotSpectralFlatness(obj, analyzer, pktNum);

                    % Get equalized symbols for Constellation Diagram
                    [customConstellationOutputs, referenceConstellationOutputs, legendStr] = getConstellationSymbols(obj, analyzer, pktNum);

                else
                    obj.restoreAxes();
                    analyzerOut.fieldInfo = [];
                    analyzerOut.ruInfo = [];
                    analyzerOut.userInfo = [];
                end
                obj.Parent.WaveformGenerator.pAnalyzerOut = analyzerOut;
                obj.Parent.WaveformGenerator.pLegendStr = legendStr;
            end
        end

        % Analyze waveform
        function analyzer = analyzeWaveform(obj, varargin)

            wwaImportDialogProp = obj.Parent.DialogsMap('wirelessWaveformAnalyzer.wwaImportDialog');
            waveGenDialog = obj.Parent.WaveformGenerator;
            if ~isempty(obj.Parent.AppObj.pParameters.RadioDialog)
                % If RadioDialog is not empty, the input mode is not file.
                % This method is executed only when there is a capture
                % available with the dialog.
                sr = obj.Parent.AppObj.pParameters.RadioDialog.SamplingRate;
            else
                sr = wwaImportDialogProp.SamplingRate;
            end
            chanBW = wwaImportDialogProp.ChannelBandwidth;
            chanBWNum = wlan.internal.cbwStr2Num(chanBW)*1e6;

            validateattributes(sr,{'double'},{'nonnan','real','integer','positive',...
                'scalar','>=',chanBWNum},mfilename,'Sample rate');

            if sr~=chanBWNum
                msg = ['Resampling input waveform from ' num2str(sr/1e6) ' MHz to ' num2str(chanBWNum/1e6) ' MHz'];
                waveGenDialog.setStatus(msg);
            end
            % When user imports a new file or when the user opens a saved
            % session which has a new file (not demo waveform)
            if ((waveGenDialog.pImportFlag) && (~isempty(waveGenDialog.pWaveform))) ...
                    || ((~strcmp(wwaImportDialogProp.FileName,'wlanDemoWaveform.mat')) && (~isempty(waveGenDialog.pWaveform)))
                rxData = waveGenDialog.pWaveform;
            else
                % When user directly hits analyze button immediately after
                % launching app
                fileName = fullfile(fileparts(mfilename('fullpath')),'+internal','wlanDemoWaveform.mat');
                loadedData = load(fileName);
                rxData = loadedData.waveform;
                waveGenDialog.pWaveform = rxData;
            end

            % Set the waveform with the RadioDialog if present. The value
            % is present, only when the input mode is not file.
            if ~isempty(obj.Parent.AppObj.pParameters.RadioDialog)
                rxData = obj.Parent.AppObj.pParameters.RadioDialog.pWaveform;
            end

            % Assign parameters
            analyzer = wirelessWaveformAnalyzer.internal.WaveformAnalyzer;
            analyzer.DCBlocking = obj.DCBlocking;
            analyzer.PilotTimeTracking = obj.PilotTimeTracking;
            analyzer.PilotPhaseTracking = obj.PilotPhaseTracking;
            analyzer.PilotGainTracking = obj.PilotGainTracking;
            analyzer.IQImbalanceCorrection = obj.IQImbalanceCorrection;
            analyzer.DataAidedEqualization = obj.DataAidedEqualization;
            analyzer.EqualizationMethod = obj.EqualizationMethod;

            validateattributes(rxData,{'double','single'},{'2d','finite'},mfilename,'waveform');

            % Convert row vector to column vector
            if(isrow(rxData))
                rxData = rxData.';
            end

            % Perform WLAN analysis
            process(analyzer,rxData,chanBW,sr);
        end

        % Restore plot axes
        function restoreAxes(obj)
            % For dark plots
            hFig = obj.Parent.CurrentDialog.getVisualFig(obj.visualNames{1});
            clf(hFig);
            hFig.Color = [1 1 1]*0.13;
            ax = axes(hFig); %#ok<LAXES>
            set(hFig, 'NumberTitle', 'off', 'Name', 'Subcarrier EVM');
            axis(ax, 'xy');
            % hold(ax, 'on');
            set(ax,'Color',[0 0 0],'XColor',[1 1 1]*0.8,'YColor',...
                [1 1 1]*0.8,'ZColor',[1 1 1]*0.8,'FontSize',9);
            xlabel(ax,'Subcarrier Number','Color',[1 1 1]*0.8,'FontSize',9);
            ylabel(ax,'EVM (dB)','Color',[1 1 1]*0.8,'FontSize',9);
            grid(ax,'on');
            ax.GridColor = [1 1 1];
            box(ax,'on');

            %
            hFig = obj.Parent.CurrentDialog.getVisualFig(obj.visualNames{2});
            clf(hFig);
            hFig.Color = [1 1 1]*0.13;
            ax = axes(hFig); %#ok<LAXES>
            set(hFig, 'NumberTitle', 'off', 'Name', 'Symbol EVM');
            axis(ax, 'xy');
            % hold(ax, 'on');
            set(ax,'Color',[0 0 0],'XColor',[1 1 1]*0.8,'YColor',...
                [1 1 1]*0.8,'ZColor',[1 1 1]*0.8,'FontSize',9);
            xlabel(ax,'Symbol Number','Color',[1 1 1]*0.8,'FontSize',9);
            ylabel(ax,'EVM (dB)','Color',[1 1 1]*0.8,'FontSize',9);
            grid(ax,'on');
            ax.GridColor = [1 1 1];
            box(ax,'on');

            %
            hFig = obj.Parent.CurrentDialog.getVisualFig(obj.visualNames{3});
            clf(hFig);
            hFig.Color = [1 1 1]*0.13;
            ax = axes(hFig); %#ok<LAXES>
            % set(hFig, 'NumberTitle', 'off', 'Name', 'Sub-carrier EVM');
            axis(ax, 'xy');
            % hold(ax, 'on');
            set(ax,'Color',[0 0 0],'XColor',[1 1 1]*0.8,'YColor',...
                [1 1 1]*0.8,'ZColor',[1 1 1]*0.8,'FontSize',9);
            xlabel(ax,'Subcarrier Index','Color',[1 1 1]*0.8,'FontSize',9);
            ylabel(ax,'Deviation (dB)','Color',[1 1 1]*0.8,'FontSize',9);
            grid(ax,'on');
            ax.GridColor = [1 1 1];
            box(ax,'on');
        end

        function cols = getNumTileColumns(obj, ~)
            tileInfo = getTileInfo(obj);
            cols = tileInfo.cols;
        end

        function rows = getNumTileRows(obj, ~)
            tileInfo = getTileInfo(obj);
            rows = tileInfo.rows;
        end

        function colW = getColWeights(obj, ~)
            tileInfo = getTileInfo(obj);
            colW = tileInfo.colW;
        end

        function rowW = getRowWeights(obj, ~)
            tileInfo = getTileInfo(obj);
            rowW = tileInfo.rowW;
        end

        % Adjust tile layouts
        function [tileCount, tileCoverage, tileOccupancy] = getTileLayout(obj, ~)

            appObj = obj.Parent.WaveformGenerator;
            tileInfo = getTileInfo(obj);
            tileCoverage = tileInfo.coverage;
            numInfoVisuals = tileInfo.infovisuals;
            plotVisuals = tileInfo.plotvisuals;
            tileCount = numel(unique(tileCoverage));

            tileOccupancy = repmat(struct('children', []), tileCount, 1);
            idx = 1;

            docGroup = getTag(obj.Parent.AppObj) + "DocumentGroup";

            if appObj.pPlotTimeScope
                documentID = appObj.getWebScopeDocumentId(appObj.pTimeScope);
                timeScopeChild = struct('showOrder',0,'id',documentID,'title','Time Scope');
                timeScopeChildId = documentID;
                tileOccupancy(1).children = timeScopeChild;
                tileOccupancy(1).showingChildId = timeScopeChildId;
                tileOccupancy(1).showingChildTitle = "Time Scope";
                idx = 2;
            else
                timeScopeChild = [];
                timeScopeChildId = [];
            end

            if appObj.pPlotSpectrum
                documentID = appObj.getWebScopeDocumentId(appObj.pSpectrum1);
                spectrumChild = struct('showOrder',1,'id',documentID,'title','Spectrum Analyzer');
                spectrumChildId = documentID;
                tileOccupancy(1).children = [spectrumChild timeScopeChild];
                tileOccupancy(1).showingChildId = [spectrumChildId timeScopeChildId];
                tileOccupancy(1).showingChildTitle = "Spectrum Analyzer";
                if appObj.pPlotTimeScope
                    tileOccupancy(1).showingChildTitle = "Time Scope";
                end
                idx = 2;
            end

            if appObj.pPlotConstellation
                documentID = appObj.getWebScopeDocumentId(appObj.pConstellation);
                str = struct('showOrder', 2, 'id', documentID,'title','Constellation Diagram');
                % To support one plot and table, 2 plots (one
                % Constellation) and table
                if (plotVisuals == 1 && numInfoVisuals >= 1) || (plotVisuals == 2 && numInfoVisuals >= 1)
                    tileOccupancy(idx).children = [tileOccupancy(idx).children str];
                    tileOccupancy(idx).showingChildId = documentID;
                    tileOccupancy(idx).showingChildTitle = 'Constellation Diagram';
                else
                    tileOccupancy(end).children = [tileOccupancy(end).children str];
                    tileOccupancy(end).showingChildId = documentID;
                    tileOccupancy(end).showingChildTitle = 'Constellation Diagram';
                end
            end

            infoDocCount = 1; % Count of visuals which end with Info
            if numInfoVisuals && plotVisuals >= 1
                idx = 2;
                idx = idx + 1;
            end
            % This condition is to avoid 2 by 2 layout when we
            % have only Symbol EVM/ Spectral EVM and table
            if (~appObj.pPlotConstellation && ~appObj.pPlotTimeScope && ~appObj.pPlotSpectrum) ...
                    || (~appObj.pPlotTimeScope && ~appObj.pPlotSpectrum && plotVisuals >= 3)
                idx = 1;
            end
            for k = 1:length(obj.visualNames)
                if obj.getVisualState(obj.visualNames{k})
                    documentID = docGroup + '_' + obj.getFigureTag(obj.visualNames{k});
                    str = struct('showOrder', 2, 'id', documentID,'title',obj.visualNames{k});

                    if contains(obj.visualNames{k}, 'Info')
                        infoChildren(infoDocCount,1) = str;
                        infoChildId(infoDocCount,1) = documentID;
                        infoDocCount = infoDocCount + 1;
                    else
                        tileOccupancy(idx).children = str;
                        tileOccupancy(idx).showingChildId = documentID;
                        tileOccupancy(idx).showingChildTitle = obj.visualNames{k};
                        idx = idx + 1;
                        % Preserve idx 2 for table
                        if idx == 2 && numInfoVisuals
                            idx = idx + 1;
                        end
                    end
                end
            end
            if numInfoVisuals
                % Combine all detection summary documents in Tile 2
                tileOccupancy(2).children = infoChildren;
                tileOccupancy(2).showingChildId = infoChildId;
                tileOccupancy(2).showingChildTitle = "Detection Info";
            end
        end
        function tileInfo = getTileInfo(obj)
            appObj = obj.Parent.WaveformGenerator;
            numEVMVisuals = 0; numInfoVisuals = 0;
            for k = 1:length(obj.visualNames)
                if contains(obj.visualNames{k}, 'Info')
                    numInfoVisuals = obj.getVisualState(obj.visualNames{k}) + numInfoVisuals;
                else
                    numEVMVisuals = obj.getVisualState(obj.visualNames{k}) + numEVMVisuals;
                end
            end
            numScopeVisuals = appObj.pPlotTimeScope + appObj.pPlotSpectrum + appObj.pPlotConstellation;
            plotVisuals = numScopeVisuals + numEVMVisuals;
            % 1 Tile: A plot or a table
            if (plotVisuals == 1 && numInfoVisuals == 0) || (plotVisuals == 0 && numInfoVisuals >= 1)
                cols = 1 + 1; colW = 1;
                rows = 1; rowW = 1;
                tileCoverage = 1;
                % 2 Tiles: Two plots or a plot and a table
            elseif (plotVisuals == 2 && numInfoVisuals == 0) || (plotVisuals == 1 && numInfoVisuals >= 1)
                cols = 1 + 2; colW = [0 1 1]';
                rows = 1; rowW = 1;
                tileCoverage = [1 2];
                % 3 Tiles: Three plots or two plots and a table or one plot and
                % two tables
            elseif (plotVisuals == 3 && numInfoVisuals == 0) || (plotVisuals == 2 && numInfoVisuals >= 1) || (plotVisuals == 1 && numInfoVisuals >= 2)
                cols = 1 + 2; colW = [0 1 1]';
                rows = 2; rowW = [0.5 0.5];
                tileCoverage = [1 2; 3 3];
                % 4 Tiles: Four plots or three plots and one tables or two
                % plots and two tables or one plot and three tables
            elseif (plotVisuals == 4 && numInfoVisuals == 0) || (plotVisuals == 3 && numInfoVisuals >= 1) ||...
                    (plotVisuals == 2 && numInfoVisuals >= 2) || (plotVisuals == 1 && numInfoVisuals >= 3)
                cols = 1 + 2; colW = [0 1 1]';
                rows = 2; rowW = [0.5 0.5];
                tileCoverage = [1 2; 3 4];
                % 5 Tiles: Five plots or four plots and one table or three
                % plots and two tables or two plots and three tables
            elseif (plotVisuals == 5 && numInfoVisuals == 0) || (plotVisuals == 4 && numInfoVisuals >= 1) || (plotVisuals == 3 && numInfoVisuals >= 2) ||...
                    (plotVisuals == 2 && numInfoVisuals >= 3) || (plotVisuals == 1 && numInfoVisuals >= 4)
                cols = 1 + 3; colW = [0 1 1 1 ]';
                rows = 2; rowW = [0.5 0.5];
                tileCoverage = [1 1 2; 3 4 5];
                % 6 Tiles: Six plots or five plots and one table (default
                % layout) or four plots and two tables or three plots and three
                % tables or two plots and four tables or one plot and five
                % tables
            elseif (plotVisuals == 6) || (plotVisuals == 5 && numInfoVisuals >= 1) || (plotVisuals == 4 && numInfoVisuals >= 2) ||...
                    (plotVisuals == 3 && numInfoVisuals >= 3) || (plotVisuals == 2 && numInfoVisuals >= 4) || (plotVisuals == 1 && numInfoVisuals >= 5)
                cols = 1 + 4; colW = [0 1 1 1 1]';
                rows = 2; rowW = [0.5 0.5];
                tileCoverage = [1 1 2 2; 3 4 5 6];
            end
            tileInfo.cols = cols;
            tileInfo.colW = colW;
            tileInfo.rows = rows;
            tileInfo.rowW = rowW;
            tileInfo.coverage = tileCoverage;
            tileInfo.infovisuals = numInfoVisuals;
            tileInfo.plotvisuals = plotVisuals;
        end

        function helpCallback(~)
            helpview('wlan', 'wlanWaveformAnalyzer-app');
        end

        function AppDochyperlink = getAppLink(~)
            AppDochyperlink = '<a href="matlab:helpview(''wlan'', ''wlanWaveformAnalyzer-app'')">WLAN Waveform Analyzer</a>';
        end
    end
end
