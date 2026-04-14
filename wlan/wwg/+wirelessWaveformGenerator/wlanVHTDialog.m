classdef wlanVHTDialog < wirelessWaveformGenerator.wlanHTDialog
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        NumUsers
    end

    properties (Hidden)
        PreVHTCyclicShiftsType = 'numericEdit'
        PreVHTCyclicShiftsLabel
        PreVHTCyclicShiftsGUI
        NumUsersType = 'numericPopup'
        NumUsersDropDown = {'1', '2', '3', '4'}
        NumUsersLabel
        NumUsersGUI
        UserPositionsType = 'numericEdit'
        UserPositionsLabel
        UserPositionsGUI
        BeamformingType = 'checkbox'
        BeamformingLabel
        BeamformingGUI
        STBCType = 'checkbox'
        STBCLabel
        STBCGUI
        APEPLengthType = 'numericEdit'
        APEPLengthLabel
        APEPLengthGUI
        GroupIDType = 'numericEdit'
        GroupIDLabel
        GroupIDGUI
        PartialAIDType = 'numericEdit'
        PartialAIDLabel
        PartialAIDGUI
    end

    methods % constructor
        function obj = wlanVHTDialog(parent)
            obj@wirelessWaveformGenerator.wlanHTDialog(parent); % call base constructor
            weakObj = matlab.lang.WeakReference(obj);

            % Specify callbacks for changes to VHT GUI elements which impact
            % other elements (may also be used in subclass dialogs)
            obj.PreVHTCyclicShiftsGUI.(obj.Callback) = @(a,b) preVHTCyclicShiftsChanged(weakObj.Handle, []);
            obj.NumUsersGUI.(obj.Callback)           = @(a,b) numUsersChangedGUI(weakObj.Handle, []);
            obj.UserPositionsGUI.(obj.Callback)      = @(a,b) userPositionsChangedGUI(weakObj.Handle, []);
            obj.APEPLengthGUI.(obj.Callback)         = @(a,b) apepLengthChangedGUI(weakObj.Handle, []);
            obj.GroupIDGUI.(obj.Callback)            = @(a,b) groupIDChangedGUI(weakObj.Handle, []);
            obj.PartialAIDGUI.(obj.Callback)         = @(a,b) partialIDChangedGUI(weakObj.Handle, []);
            obj.STBCGUI.(obj.Callback)               = @(a,b) stbcChangedGUI(weakObj.Handle, []);
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanVHTConfig; % so that update happens before construction end
            obj.configGenFcn  = @wlanVHTConfig;
            obj.configGenVar  = 'vhtCfg';
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g Non-HT)
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:VHTTitle', '(Very High Throughput)'));
            obj.ChannelBandwidthDropDown = {'20 MHz', '40 MHz', '80 MHz', '160 MHz'};
            obj.NumSpaceTimeStreamsType = 'numericEdit';
            obj.MCSDropDown = {'0 (BPSK, 1/2 rate)',   '1 (QPSK, 1/2 rate)',    '2 (QPSK, 3/4 rate)', ...
                               '3 (16-QAM, 1/2 rate)', '4 (16-QAM, 3/4 rate)',  '5 (64-QAM, 2/3 rate)', ...
                               '6 (64-QAM, 3/4 rate)', '7 (64-QAM, 5/6 rate)', '8 (256-QAM, 3/4 rate)', ...
                               '9 (256-QAM, 5/6 rate)'};
            obj.PSDULengthType = 'numericText';
        end

        function props = displayOrder(~)
            props = {'TransmissionFormat'; 'ChannelBandwidth'; 'NumUsers'; 'UserPositions'; 'NumTransmitAntennas'; 'PreVHTCyclicShifts'; 'NumSpaceTimeStreams'; 'SpatialMapping'; ...
                     'SpatialMappingMatrix'; 'Beamforming'; 'STBC'; 'MCS'; 'ChannelCoding'; 'APEPLength'; 'GuardInterval';  ...
                     'GroupID'; 'PartialAID'; 'PSDULength'};
        end
        function updateVisibilities(obj)
            obj.updatePSDU();
        end

        function props = props2ExcludeFromConfig(obj)
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanHTDialog(obj);
            props = [props {'PSDULength'}];
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % Return a cell array of properties which should not be "set" using
        % NV pairs when configuring the object in the generated MATLAB
        % script
            try
                props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanHTDialog(obj);
            catch
                % Non-applicable properties (e.g., Spatial Mapping) may be accessed for subclasses (MU 11ax)
                % The corresponding GUI elements may have not been created.
                props = [];
            end
            props = [props {'PSDULength'}];

            if ~isCyclicShiftsVisible(obj)
                props = [props 'PreVHTCyclicShifts'];
            end

            if ~obj.isMultiUser
                props = [props {'UserPositions'}];
                if ~strcmp(obj.SpatialMapping, 'Custom')
                    % Beamforming only appears for single user with custom Spatial mappings
                    props = [props {'Beamforming'}];
                end
            else
                props = [props {'STBC', 'Beamforming'}];
            end
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            obj.GroupID = 63;
            obj.TransmissionFormat = 'Very High Throughput (VHT)';
            obj.NumUsers = 1;
            obj.ChannelBandwidth = 'CBW80'; % Set BW after NumUsers, to avoid failed cfg validations during PSDUlen set
            obj.UserPositions = '[0 1]';
            obj.NumTransmitAntennas = 1;
            obj.PreVHTCyclicShifts = -75;
            obj.NumSpaceTimeStreams = 1;
            obj.SpatialMapping = 'Direct';
            obj.SpatialMappingMatrix = 1;
            obj.Beamforming = true;
            obj.STBC = false;
            obj.MCS = '0 (BPSK, 1/2 rate)';
            obj.ChannelCoding = 'BCC';
            obj.APEPLength = 1024;
            obj.GuardInterval = 'Long';
            obj.PartialAID = 275;
            obj.PSDULength = 1035;
        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanHTDialog(obj);
            obj.TransmissionFormat = 'Very High Throughput (VHT)';
        end

        function n = getNumExtensionStreams(~)
            n = 0;
        end

        function n = get.NumUsers(obj)
            n = obj.getNumUsers(); % allows overrides by .11ax
        end
        function n = getNumUsers(obj)
            n = getDropdownNumVal(obj, 'NumUsers');
        end
        function set.NumUsers(obj, val)
            setNumUsers(obj, val);
        end
        function setNumUsers(obj, val)
            setDropdownNumVal(obj, 'NumUsers', val);
            obj.numUsersChanged();
        end
        function b = isMultiUser(obj)
            b = obj.NumUsers > 1;
        end

        function userPositionsChangedGUI(obj, ~)
            try
                val = obj.UserPositions;
                validateattributes(val, {'numeric'}, {'nonnegative', 'increasing', 'numel', obj.NumUsers, '<=', 3}, '', 'UserPositions');
            catch e
                obj.errorFromException(e);
            end
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Format: VHT'' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''MCS: '' num2str(' obj.configGenVar '.MCS) newline ...' newline ...
                   '''Coding: '' ' obj.configGenVar '.ChannelCoding newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function numSpaceTimeStreamsChangedGUI(obj, ~)
            try
                val = obj.NumSpaceTimeStreams;
                if isscalar(val)
                    validateattributes(val, {'numeric'}, {'positive', '<=', 8}, '', 'NumSpaceTimeStreams');
                else
                    validateattributes(val, {'numeric'}, {'positive', 'numel', obj.NumUsers, '<=', 4}, '', 'NumSpaceTimeStreams');
                end
            catch e
                obj.errorFromException(e);
            end
            numSpaceTimeStreamsChangedGUI@wirelessWaveformGenerator.wlanHTDialog(obj);
        end

        function updateUserPositions(obj)
            setVisible(obj, 'UserPositions', obj.isMultiUser);
        end

        function updateSTBC(obj)
            setVisible(obj, 'STBC', ~obj.isMultiUser);
        end

        function setMCSValue(obj)
            % Set type and value of MCS based on other parameters
            if obj.isMultiUser
                obj.MCSType = 'numericEdit';
                if ~isa(obj.MCSGUI, 'matlab.ui.control.EditField')
                    guiTag = 'MCS';
                    callbackFcn = @(a,b) mcsChangedGUI(obj, []);
                    changeGUI2EditField(obj, guiTag, callbackFcn);
                    layoutUIControls(obj);
                end
                obj.MCSGUI.(obj.EditValue) = ['[' num2str(zeros(1, obj.NumUsers)) ']'];
            else
                obj.MCSType = 'charPopup';
                if ~isa(obj.MCSGUI, 'matlab.ui.control.DropDown')
                    guiTag = 'MCS';
                    callbackFcn = @(a,b) mcsChangedGUI(obj, []);
                    changeGUI2Dropdown(obj, guiTag, callbackFcn);
                    layoutUIControls(obj);
                end
                obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDown;
            end
        end

        function setChannelCodingValue(obj)
            % Set type and value of ChannelCoding based on other parameters
            if obj.isMultiUser
                obj.ChannelCodingType = 'charEdit';
                if ~isa(obj.ChannelCodingGUI, 'matlab.ui.control.EditField')
                    guiTag = 'ChannelCoding';
                    callbackFcn = @(a,b) channelCodingChangedGUI(obj, []);
                    changeGUI2EditField(obj, guiTag, callbackFcn);
                    layoutUIControls(obj);
                end
                str = repmat('''BCC'', ', 1, obj.NumUsers);
                obj.ChannelCodingGUI.(obj.EditValue) = ['{' str(1:end-2) '}'];
            else
                obj.ChannelCodingType = 'charPopup';
                if ~isa(obj.ChannelCodingGUI, 'matlab.ui.control.DropDown')
                    guiTag = 'ChannelCoding';
                    callbackFcn = @(a,b) channelCodingChangedGUI(obj, []);
                    changeGUI2Dropdown(obj, guiTag, callbackFcn);
                    layoutUIControls(obj);
                end
                obj.ChannelCodingGUI.(obj.DropdownValues) = obj.ChannelCodingDropDown;
            end
        end

        function numUsersChanged(obj, ~)
            obj.shouldLayoutControls = false;
            % Set types and values of GUI elements
            obj.setMCSValue();
            obj.setChannelCodingValue();
            if obj.isMultiUser
                obj.UserPositions = ['[' num2str(0:(obj.NumUsers-1)) ']'];
                if isempty(obj.GroupIDGUI.(obj.EditValue)) || any(obj.GroupID == [0 63])
                    obj.GroupID = 62;
                end
            elseif isempty(obj.GroupIDGUI.(obj.EditValue)) || obj.GroupID ~= 0
                obj.GroupID = 63;
            end
            obj.NumTransmitAntennas = obj.NumUsers;
            obj.NumSpaceTimeStreams = ['[' num2str(ones(1, obj.NumUsers)) ']'];

            obj.updateUserPositions();
            obj.updateSTBC();
            obj.updateBeamforming();
            obj.shouldLayoutControls = true; % do only one layout update - much faster
        end
        function numUsersChangedGUI(obj, ~)
            obj.numUsersChanged();
            obj.updatePSDU();
            obj.layoutUIControls();
        end

        function updateBeamforming(obj)
            vis = obj.isMultiUser || ~strcmp('Custom',  obj.SpatialMapping);
            setVisible(obj, 'Beamforming', ~vis);
        end

        function spatialMappingChangedGUI(obj, ~)
            obj.updateBeamforming();
            spatialMappingChangedGUI@wirelessWaveformGenerator.wlanHTDialog(obj);
        end

        function spatialMappingMatrixChangedGUI(obj, ~)
        % Validate spatial mapping matrix
            try
                wlanVHTConfig('SpatialMappingMatrix',obj.SpatialMappingMatrix);
            catch e
                obj.errorFromException(e);
            end
        end

        function stbcChangedGUI(obj, ~)
            updatePSDU(obj);
        end

        function updatePSDU(obj)
            try
                cfg = obj.getConfiguration();

                try
                    validateConfig(cfg);

                    if ~isempty(cfg.PSDULength)
                        obj.PSDULength = cfg.PSDULength;
                    end
                catch e
                    % PSDU length may be undefined
                    obj.PSDULength = '';
                    obj.errorFromException(e);
                end
            catch
                % do not error for updates during construction, when some
                % properties are not set
            end
        end

        function updateMCS(~)
        end

        function psduChanged(~, ~)
        % no checking for read-only value
        end

        function apepLengthChangedGUI(obj, ~)
            try
                val = obj.APEPLength;
                validateattributes(val, {'numeric'}, {'nonnegative', 'scalar', '<=', 2^20-1}, '', 'APEPLength');
            catch e
                obj.errorFromException(e);
            end
            obj.updatePSDU();
        end

        function groupIDChangedGUI(obj, ~)
            try
                val = obj.GroupID;
                validateattributes(val, {'numeric'}, {'nonnegative', 'scalar', '<=', 63}, '', 'GroupID');
            catch e
                obj.errorFromException(e);
            end
        end

        function partialIDChangedGUI(obj, ~)
            try
                val = obj.PartialAID;
                validateattributes(val, {'numeric'}, {'nonnegative', 'scalar', '<=', 511}, '', 'Partial AID');
            catch e
                obj.errorFromException(e);
            end
        end

        function cellDialogs = getDialogsPerColumn(obj)
            cellDialogs{1} = {obj};
            cellDialogs{2} = {obj.Parent.GenerationDialog obj.Parent.FilteringDialog};
        end
    end

    methods (Access = protected)
        function updateCyclicShifts(obj)
        % Update cyclic shift GUI based on dependent properties. This method
        % should be overloaded by each transmission format and called by each
        % dependent property change method, i.e. numTransmitAntennasChanged.
            [isvis,numTxThresh] = isCyclicShiftsVisible(obj);
            if isvis
                % Create a vector of cyclic shifts per antenna to prompt the user
                obj.PreVHTCyclicShiftsGUI.(obj.EditValue) = ['[' num2str(-75*ones(1,obj.NumTransmitAntennas-numTxThresh)) ']'];
                obj.showPreVHTCyclicShiftControl(true);
            else
                obj.showPreVHTCyclicShiftControl(false);
            end
        end

        function changeGUI2EditField(obj, guiTag, callbackFcn)
            delete(obj.([guiTag 'GUI']));
            obj.([guiTag 'GUI']) = uieditfield(Parent=obj.Layout, ...
                                               FontSize = obj.FontSize, ...
                                               Tag = guiTag, ...
                                               Tooltip = obj.getMsgString([guiTag 'TT']), ...
                                               HorizontalAlignment='left', ...
                                               ValueChangedFcn = callbackFcn);
        end

        function changeGUI2Dropdown(obj, guiTag, callbackFcn)
            delete(obj.([guiTag 'GUI']));
            obj.([guiTag 'GUI']) = uidropdown(Parent=obj.Layout, ...
                                              FontSize = obj.FontSize, ...
                                              Tag = guiTag, ...
                                              Tooltip = obj.getMsgString([guiTag 'TT']), ...
                                              ValueChangedFcn = callbackFcn);
        end
    end

    methods(Access = private)
        function showPreVHTCyclicShiftControl(obj,flag)
        % Set cyclic shift GUI visibility
            setVisible(obj, 'PreVHTCyclicShifts', flag);
        end

        function preVHTCyclicShiftsChanged(obj, ~)
        % Independent validation of GUI element value
            try
                obj.validateCyclicShiftGUIValue(obj.PreVHTCyclicShifts,'Pre-VHT cyclic shifts')
            catch e
                obj.errorFromException(e);
            end
        end
    end
end

function [vis,numTxThresh] = isCyclicShiftsVisible(cfg)
% Returns true if the cyclic shift GUI option should be visible
    numTxThresh = 8; % Threshold over which cyclic shifts must be specified
    if cfg.NumTransmitAntennas>numTxThresh
        vis = true;
    else
        vis = false;
    end
end
