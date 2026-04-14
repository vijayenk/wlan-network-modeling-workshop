classdef wlanHTDialog < wirelessWaveformGenerator.wlanNonHTDialog
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        NumSpaceTimeStreams
        GuardInterval
        ChannelCoding
    end

    properties (Hidden)
        PreHTCyclicShiftsType = 'numericEdit'
        PreHTCyclicShiftsLabel
        PreHTCyclicShiftsGUI
        NumSpaceTimeStreamsType = 'numericPopup'
        NumSpaceTimeStreamsDropDown = {'1', '2', '3', '4'}
        NumSpaceTimeStreamsLabel
        NumSpaceTimeStreamsGUI
        NumExtensionStreamsType = 'numericPopup'
        NumExtensionStreamsDropDown = {'0', '1', '2', '3'}
        NumExtensionStreamsLabel
        NumExtensionStreamsGUI
        SpatialMappingType = 'charPopup'
        SpatialMappingDropDown = {'Direct', 'Hadamard', 'Fourier', 'Custom'}
        SpatialMappingLabel
        SpatialMappingGUI
        SpatialMappingMatrixType = 'numericEdit'
        SpatialMappingMatrixLabel
        SpatialMappingMatrixGUI
        GuardIntervalType = 'charPopup'
        GuardIntervalDropDown = {'Long', 'Short'}
        GuardIntervalLabel
        GuardIntervalGUI
        ChannelCodingType = 'charPopup'
        ChannelCodingDropDown = {'BCC', 'LDPC'}
        ChannelCodingLabel
        ChannelCodingGUI
        AggregatedMPDUType = 'checkbox'
        AggregatedMPDULabel
        AggregatedMPDUGUI
        RecommendSmoothingType = 'checkbox'
        RecommendSmoothingLabel
        RecommendSmoothingGUI
    end

    methods % constructor
        function obj = wlanHTDialog(parent)
            obj@wirelessWaveformGenerator.wlanNonHTDialog(parent); % call base constructor
            weakObj = matlab.lang.WeakReference(obj);

            % Specify callbacks for changes to HT GUI elements which impact
            % other elements (may also be used in subclass dialogs)
            obj.PreHTCyclicShiftsGUI.(obj.Callback)    = @(a,b) preHTCyclicShiftsChangedGUI(weakObj.Handle, []);
            obj.SpatialMappingGUI.(obj.Callback)       = @(a,b) spatialMappingChangedGUI(weakObj.Handle, []);
            obj.SpatialMappingMatrixGUI.(obj.Callback) = @(a,b) spatialMappingMatrixChangedGUI(weakObj.Handle, []);
            obj.NumSpaceTimeStreamsGUI.(obj.Callback)  = @(a,b) numSpaceTimeStreamsChangedGUI(weakObj.Handle, []);
            obj.GuardIntervalGUI.(obj.Callback)        = @(a,b) guardIntervalChangedGUI(weakObj.Handle, []);
            if ~strcmp(obj.ChannelCodingType, 'charText')
                % no callback for uilabel
                obj.ChannelCodingGUI.(obj.Callback)    = @(a,b) channelCodingChangedGUI(weakObj.Handle, []);
            end
            obj.NumExtensionStreamsGUI.(obj.Callback)  = @(a,b) numExtensionStreamsChangedGUI(weakObj.Handle, []);
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanHTConfig;
            obj.configGenFcn = @wlanHTConfig;
            obj.configGenVar = 'htCfg';
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g Non-HT)
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:HTTitle', '(High Throughput)'));
            obj.ChannelBandwidthDropDown = {'20 MHz', '40 MHz'};
            obj.MCSDropDown = {'0 (BPSK, 1/2 rate, 1 spatial stream)',   '1 (QPSK, 1/2 rate, 1 spatial stream)',    '2 (QPSK, 3/4 rate, 1 spatial stream)', ...
                               '3 (16-QAM, 1/2 rate, 1 spatial stream)', '4 (16-QAM, 3/4 rate, 1 spatial stream)',  '5 (64-QAM, 2/3 rate, 1 spatial stream)', ...
                               '6 (64-QAM, 3/4 rate, 1 spatial stream)', '7 (64-QAM, 5/6 rate, 1 spatial stream)'};
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanWaveformConfiguration(obj); % skip 11a/g/j/p-specific setup
        end

        function psduChanged(obj, ~)
            try
                val = obj.PSDULength;
                validateattributes(val, {'numeric'}, {'positive', 'scalar', '<=', 2^16-1}, '', 'PSDULength');
            catch e
                obj.errorFromException(e);
            end
        end

        function updateVisibilities(obj)
            updateSpatialMapping(obj);
            updateSpatialMappingMatrix(obj);
            updateNumExtensionStreams(obj);
            updateMCS(obj);
            updatePSDU(obj);
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            obj.TransmissionFormat = 'High Throughput (HT)';
            obj.ChannelBandwidth = 'CBW20';
            obj.NumTransmitAntennas = 1;
            obj.PreHTCyclicShifts = -75;
            obj.NumSpaceTimeStreams = 1;
            obj.NumExtensionStreams = 0;
            obj.SpatialMapping = 'Direct';
            obj.SpatialMappingMatrix = 1;
            obj.GuardInterval = 'Long';
            obj.ChannelCoding = 'BCC';
            obj.AggregatedMPDU = false;
            obj.RecommendSmoothing = true;
            obj.PSDULength = 1024;
            obj.setDropdownStartingVal('MCS', '0');
        end

        function updateSpatialMapping(obj)
            % Update options for SpatialMapping drop-down options

            if isExtensionStreamsVisible(obj) && getNumExtensionStreams(obj) > 0
                obj.SpatialMappingDropDown = {'Custom'};
            elseif obj.NumTransmitAntennas == sum(obj.NumSpaceTimeStreams)
                obj.SpatialMappingDropDown = {'Direct', 'Hadamard', 'Fourier', 'Custom'};
            else
                obj.SpatialMappingDropDown = {'Hadamard', 'Fourier', 'Custom'};
            end
            obj.SpatialMappingGUI.(obj.DropdownValues) = obj.SpatialMappingDropDown;
            % Do not set value as we assume it set correctly already
        end

        function numExtensionStreamsChangedGUI(obj, ~)
            updateSpatialMapping(obj);
            updateSpatialMappingMatrix(obj);
            updateMCS(obj);
            updatePSDU(obj);
            obj.layoutUIControls();
        end

        function n = getNumExtensionStreams(obj)
            n = obj.NumExtensionStreams;
        end

        function flag = isExtensionStreamsVisible(obj)
            flag = ~((obj.NumTransmitAntennas==sum(obj.NumSpaceTimeStreams)) || sum(obj.NumSpaceTimeStreams)==4);
        end

        function updateNumExtensionStreams(obj)
            setVisible(obj, 'NumExtensionStreams', isExtensionStreamsVisible(obj));
        end

        function numSpaceTimeStreamsChanged(obj, ~)
            updateSpatialMapping(obj);
            updateSpatialMappingMatrix(obj);
            updateNumExtensionStreams(obj);
            updateMCS(obj);
        end
        function numSpaceTimeStreamsChangedGUI(obj, ~)
            numSpaceTimeStreamsChanged(obj);
            obj.layoutUIControls();
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Format: HT'' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''Coding: '' ' obj.configGenVar '.ChannelCoding newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function updateMCS(obj)
            numST = obj.NumSpaceTimeStreams;
            if numST == 4
                numSS = [2 3 4];
            elseif numST == 3
                numSS = [2 3];
            elseif numST == 2
                numSS = [1 2];
            elseif numST == 1
                numSS = 1;
            end
            mcs = {};
            for idx = numSS
                off = 8*(idx-1);
                if idx == 1
                    stream = 'stream';
                else
                    stream = 'streams';
                end

                mcs = [mcs {[num2str(off)   ' (BPSK, 1/2 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+1) ' (QPSK, 1/2 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+2) ' (QPSK, 3/4 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+3) ' (16-QAM, 1/2 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+4) ' (16-QAM, 3/4 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+5) ' (64-QAM, 2/3 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+6) ' (64-QAM, 3/4 rate, ' num2str(idx) ' spatial ' stream ')'], ...
                            [num2str(off+7) ' (64-QAM, 5/6 rate, ' num2str(idx) ' spatial ' stream ')'] }]; %#ok<AGROW>

            end
            obj.MCSGUI.(obj.DropdownValues) = mcs;
        end

        function updateSpatialMappingMatrix(obj)
            val = strcmpi(obj.SpatialMapping, 'Custom');
            setVisible(obj, 'SpatialMappingMatrix', val);
        end
        function spatialMappingChangedGUI(obj, ~)
            updateSpatialMappingMatrix(obj);
            obj.layoutUIControls();
        end

        function props = displayOrder(~)
            props = {'TransmissionFormat'; 'ChannelBandwidth'; 'NumTransmitAntennas'; 'PreHTCyclicShifts'; 'NumSpaceTimeStreams'; 'NumExtensionStreams'; 'SpatialMapping'; ...
                     'SpatialMappingMatrix'; 'MCS'; 'GuardInterval'; 'ChannelCoding'; 'AggregatedMPDU'; 'RecommendSmoothing'; 'PSDULength'};
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % Return a cell array of properties which should not be "set" using
        % NV pairs when configuring the object in the generated MATLAB
        % script
            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanNonHTDialog(obj);

            if ~isCyclicShiftsVisible(obj)
                props = [props 'PreHTCyclicShifts'];
            end

            if ~strcmp(obj.SpatialMapping, 'Custom')
                props = [props {'SpatialMappingMatrix'}];
            end
            if (isequal(obj.NumTransmitAntennas, sum(obj.NumSpaceTimeStreams)) ||  isequal(sum(obj.NumSpaceTimeStreams), 4))
                props = [props {'NumExtensionStreams'}];
            end
        end

        function n = get.NumSpaceTimeStreams(obj)
            if isa(obj.NumSpaceTimeStreamsGUI, 'matlab.ui.control.EditField')
                n = getEditVal(obj, 'NumSpaceTimeStreams');
            else %popupmenu
                n = getDropdownNumVal(obj, 'NumSpaceTimeStreams');
            end
        end
        function set.NumSpaceTimeStreams(obj, val)
            if isa(obj.NumSpaceTimeStreamsGUI, 'matlab.ui.control.EditField')

                setEditVal(obj, 'NumSpaceTimeStreams', val);
            else %popupmenu
                setDropdownNumVal(obj, 'NumSpaceTimeStreams', val);
            end

            obj.numSpaceTimeStreamsChanged();
        end

        function spatialMappingMatrixChangedGUI(obj, ~)
        % Validate spatial mapping matrix
            try
                wlanHTConfig('SpatialMappingMatrix',obj.SpatialMappingMatrix);
            catch e
                obj.errorFromException(e);
            end
        end

        function guardIntervalChangedGUI(obj, ~)
            updatePSDU(obj);
            updateWindowTransitionTime(obj);
        end

        function n = get.GuardInterval(obj)
            n = obj.getGuardInterval(); % allows overrides
        end
        function n = getGuardInterval(obj)
            n = getDropdownVal(obj, 'GuardInterval');
        end
        function setGuardInterval(obj, val)
            setDropdownVal(obj, 'GuardInterval', val);
        end
        function set.GuardInterval(obj, val)
            setGuardInterval(obj, val);
            updateWindowTransitionTime(obj);
        end

        function channelCodingChangedGUI(obj, ~)
            updatePSDU(obj);
        end

        function v = get.ChannelCoding(obj)
            if isa(obj.ChannelCodingGUI, 'matlab.ui.control.Label')

                v = getTextVal(obj, 'ChannelCoding');

            elseif isa(obj.ChannelCodingGUI, 'matlab.ui.control.EditField')

                v = getEditVal(obj, 'ChannelCoding');

            else %popupmenu
                v = getDropdownVal(obj, 'ChannelCoding');
            end
        end
        function set.ChannelCoding(obj, val)
            if iscell(val)
                val2 = '{';
                for idx = 1:length(val)
                    val2 = [val2 '''' val{idx} '''']; %#ok<AGROW>
                    if idx ~= length(val)
                        val2 = [val2 ', ']; %#ok<AGROW>
                    end
                end
                val = [val2 '}'];
            end

            if isa(obj.ChannelCodingGUI, 'matlab.ui.control.Label')
                setTextVal(obj, 'ChannelCoding', val);

            elseif isa(obj.ChannelCodingGUI, 'matlab.ui.control.EditField')

                setEditVal(obj, 'ChannelCoding', val);

            else %popupmenu
                setval = find(contains(obj.ChannelCodingGUI.(obj.DropdownValues), val));
                if isempty(setval)
                    obj.ChannelCodingGUI.Value = obj.ChannelCodingGUI.(obj.DropdownValues){end};
                else
                    obj.ChannelCodingGUI.Value = obj.ChannelCodingGUI.(obj.DropdownValues){setval};
                end
            end
        end
    end

    methods (Access = protected)
        function numTransmitAntennasChanged(obj, ~)
        % Update format specific GUI elements (excluding cyclic shifts as
        % common for all formats) when Transmit Antennas changed - by loading
        % a session or changing the GUI value.
            % Update HT behavior when NumTransmitAntennas has changed
            obj.updateSpatialMapping();
            obj.updateSpatialMappingMatrix();
            obj.updateNumExtensionStreams();
        end

        function updateCyclicShifts(obj)
        % Update cyclic shift GUI based on dependent properties. This method
        % should be overloaded by each transmission format and called by each
        % dependent property change method, i.e. numTransmitAntennasChanged.
            [isVis,numTxThresh] = isCyclicShiftsVisible(obj);
            if isVis
                % Create a vector of cyclic shifts per antenna to prompt the user
                obj.PreHTCyclicShiftsGUI.(obj.EditValue) = ['[' num2str(-75*ones(1,obj.NumTransmitAntennas-numTxThresh)) ']'];
                obj.showPreHTCyclicShiftControl(true);
            else
                obj.showPreHTCyclicShiftControl(false);
            end
        end
    end

    methods (Access = private)
        function showPreHTCyclicShiftControl(obj,flag)
        % Set visibility of GUI elements related to Pre-HT cyclic shift
            setVisible(obj, 'PreHTCyclicShifts', flag);
        end

        function preHTCyclicShiftsChangedGUI(obj, ~)
        % Called when GUI element changed. Independent validation of GUI
        % element value
            try
                obj.validateCyclicShiftGUIValue(obj.PreHTCyclicShifts,'Pre-HT cyclic shifts')
            catch e
                obj.errorFromException(e);
            end
        end
    end

end

function [vis,numTxThresh] = isCyclicShiftsVisible(cfg)
% Returns true if the cyclic shift GUI option should be visible
    numTxThresh = 4; % Threshold over which cyclic shifts must be specified
    if cfg.NumTransmitAntennas>numTxThresh
        vis = true;
    else
        vis = false;
    end
end
