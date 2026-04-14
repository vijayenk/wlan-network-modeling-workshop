classdef wlanS1GDialog < wirelessWaveformGenerator.wlanVHTDialog
%

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
    end

    properties (Hidden)
        NumTransmitAntennasDropDown = {'1', '2', '3', '4'}; % All other OFDM formats use an edit box so only defined for S1G
        PreambleType = 'charPopup'
        PreambleDropDown = {'Long', 'Short'}
        PreambleLabel
        PreambleGUI
        UplinkIndicationType = 'checkbox'
        UplinkIndicationLabel
        UplinkIndicationGUI
        ColorType = 'numericPopup'
        ColorDropDown = {'0', '1', '2', '3', '4', '5', '6', '7'}
        ColorLabel
        ColorGUI
        TravelingPilotsType = 'checkbox'
        TravelingPilotsLabel
        TravelingPilotsGUI
        ResponseIndicationType = 'charPopup'
        ResponseIndicationDropDown = {'None', 'NDP', 'Normal', 'Long'}
        ResponseIndicationLabel
        ResponseIndicationGUI
    end

    methods % constructor
        function obj = wlanS1GDialog(parent)
            obj@wirelessWaveformGenerator.wlanVHTDialog(parent); % call base constructor

            obj.PreambleGUI.(obj.Callback)             = @(a,b) preambleChangedGUI(obj, []);
            obj.SpatialMappingMatrixGUI.(obj.Callback) = @(a,b) spatialMappingMatrixChangedGUI(obj, []);

            channelBandwidthChanged(obj); % adjust visibility of Uplink indication checkbox
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanS1GConfig;
            obj.configGenFcn = @wlanS1GConfig;
            obj.configGenVar = 's1gGCfg';
        end

        function adjustSpec(obj)
            adjustSpec@wirelessWaveformGenerator.wlanVHTDialog(obj);
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:S1GTitle'));
            obj.ChannelBandwidthDropDown = {'1 MHz', '2 MHz', '4 MHz', '8 MHz', '16 MHz'};
            obj.NumTransmitAntennasType = 'numericPopup'; % Non-HT/HT/VHT/HE use an edit box so specify popup for S1G
            obj.ChannelCodingType = 'charText';
        end

        function adjustDialog(~)
        end
        function updateVisibilities(obj)
            updatePSDU(obj);
        end

        function props = displayOrder(~)
            props = {'ChannelBandwidth'; 'Preamble'; 'NumUsers'; 'UserPositions'; 'NumTransmitAntennas'; 'NumSpaceTimeStreams'; 'SpatialMapping'; ...
                     'SpatialMappingMatrix'; 'Beamforming'; 'STBC'; 'MCS'; 'ChannelCoding'; 'APEPLength'; 'GuardInterval'; ...
                     'GroupID'; 'PartialAID'; 'UplinkIndication'; 'Color'; 'TravelingPilots'; 'ResponseIndication'; ...
                     'RecommendSmoothing'; 'PSDULength'};
        end

        function props = props2ExcludeFromConfig(obj)
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanVHTDialog(obj);
            props = [props {'ChannelCoding'}];
        end
        function props = props2ExcludeFromConfigGeneration(obj)
            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanVHTDialog(obj);
            props = [props 'ChannelCoding'];

            if strcmp(obj.ChannelBandwidth, 'CBW1')
                props = [props {'Preamble', 'UplinkIndication'}];
            end

            if ~strcmp(obj.Preamble, 'Long')
                props = [props 'Beamforming', 'GroupID'];
            end

            if obj.NumUsers == 1
                props = [props 'GroupID'];
            else
                props = [props 'TravelingPilots', 'UplinkIndication'];
            end

        end

        function setupDialog(obj)
            setupDialog@wirelessWaveformGenerator.wlanHTDialog(obj);
            % skip setting of Tx Format (for 11ac)
        end

        function restoreDefaults(obj)
            obj.ChannelBandwidth = 'CBW2';
            obj.Preamble = 'Short';
            obj.NumUsers = 1;
            obj.UserPositions = '[0 1]';
            obj.MCS = obj.MCSDropDown{1};
            obj.NumTransmitAntennas = 1;
            obj.NumSpaceTimeStreams = 1;
            obj.SpatialMapping = 'Direct';
            obj.SpatialMappingMatrix = 1;
            obj.Beamforming = true;
            obj.STBC = false;
            obj.ChannelCoding = 'BCC';
            obj.APEPLength = 256;
            obj.GuardInterval = 'Long';
            obj.GroupID = 1;
            obj.PartialAID = 37;
            obj.UplinkIndication = false;
            obj.Color = 0;
            obj.TravelingPilots = false;
            obj.ResponseIndication = 'None';
            obj.RecommendSmoothing = true;
            obj.PSDULength = 258;
        end

        function channelBandwidthChanged(obj, ~)
            channelBandwidthChanged@wirelessWaveformGenerator.wlanVHTDialog(obj);

            if obj.NumUsers == 1
                if strcmp(obj.ChannelBandwidth, 'CBW1')
                    obj.MCSDropDown = [obj.MCSDropDown(1:10) '10 (BPSK, 1/2 rate)' '11 (1024-QAM, 3/4 rate)' '12 (1024-QAM, 5/6 rate)'];
                    obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDown;
                else % MCS 10 should be hidden for all bandwidths except CBW1
                    obj.MCSGUI.(obj.DropdownValues) = [obj.MCSDropDown(1:10)  '11 (1024-QAM, 3/4 rate)' '12 (1024-QAM, 5/6 rate)'];
                end
            end
            updatePreamble(obj);
            updateUplinkIndication(obj);
        end

        function apepLengthChangedGUI(obj, ~)
            try
                val = obj.APEPLength;
                validateattributes(val, {'numeric'}, {'nonnegative', 'scalar', '<=', 2^16-1}, '', 'APEPLength');
            catch e
                obj.errorFromException(e);
            end
            obj.updatePSDU();
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''Preamble: '' ' obj.configGenVar '.Preamble newline ...' newline ...
                   '''Users: '' num2str(' obj.configGenVar '.NumUsers) newline ...' newline ...
                   '''Coding: '' ' obj.configGenVar '.ChannelCoding '' bytes'' newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function groupIDChangedGUI(obj, ~)
            try
                val = obj.GroupID;
                validateattributes(val, {'numeric'}, {'positive', 'scalar', '<=', 62}, '', 'GroupID');
            catch e
                obj.errorFromException(e);
            end
        end

        function preambleChanged(obj, ~)
            updateBeamforming(obj);
            updateGroupID(obj);
            updatePSDU(obj);
        end
        function preambleChangedGUI(obj, ~)
            preambleChanged(obj);
            obj.layoutUIControls();
        end

        function updatePreamble(obj,~)
            setVisible(obj, 'Preamble', ~strcmp(obj.ChannelBandwidth, 'CBW1'));
        end

        function numUsersChanged(obj, ~)
            obj.shouldLayoutControls = false;

            % Set property visibility
            updateBeamforming(obj);
            updateUserPositionsTravelingPilotsSTBC(obj);
            updateGroupID(obj);
            updateUplinkIndication(obj);

            % Set type and values of other GUI elements
            if obj.NumUsers==1
                if strcmp(obj.ChannelBandwidth, 'CBW1') && length(obj.MCSDropDown) == 13
                    obj.MCSDropDown = [obj.MCSDropDown(1:10) '10 (BPSK, 1/2 rate)' '11 (1024-QAM, 3/4 rate)' '12 (1024-QAM, 5/6 rate)'];
                else
                    obj.MCSDropDown = [obj.MCSDropDown(1:10) '11 (1024-QAM, 3/4 rate)' '12 (1024-QAM, 5/6 rate)'];
                end
            end
            setMCSValue(obj);
            if obj.NumUsers > 1
                obj.TravelingPilots = false;
                obj.UserPositions = ['[' num2str(0:(obj.NumUsers-1)) ']'];
            end
            obj.NumTransmitAntennas = obj.NumUsers;
            obj.NumSpaceTimeStreams = ['[' num2str(ones(1, obj.NumUsers)) ']'];

            obj.shouldLayoutControls = true; % do only one layout update - much faster
        end

        function updateUplinkIndication(obj,~)
            setVisible(obj, 'UplinkIndication', ~strcmp(obj.ChannelBandwidth, 'CBW1') && obj.NumUsers == 1);
        end

        function updateBeamforming(obj)
            val = strcmp(obj.Preamble, 'Long') && obj.NumUsers == 1 && strcmp(obj.SpatialMapping, 'Custom');
            setVisible(obj, 'Beamforming', val);
        end

        function updateGroupID(obj)
            vis = obj.NumUsers > 1 && strcmp(obj.Preamble, 'Long');
            setVisible(obj, 'GroupID', vis);
        end

        function updateUserPositionsTravelingPilotsSTBC(obj)
            multiUser = obj.NumUsers > 1;
            setVisible(obj, 'UserPositions', multiUser);
            setVisible(obj, {'TravelingPilots', 'STBC'}, ~multiUser);
        end

        function numSpaceTimeStreamsChangedGUI(obj, ~)
            try
                val = obj.NumSpaceTimeStreams;
                if isscalar(val)
                    validateattributes(val, {'numeric'}, {'positive', '<=', 4}, '', 'NumSpaceTimeStreams');
                else
                    validateattributes(val, {'numeric'}, {'positive', 'numel', obj.NumUsers, '<=', 4}, '', 'NumSpaceTimeStreams');
                end
            catch e
                obj.errorFromException(e);
            end
            numSpaceTimeStreamsChangedGUI@wirelessWaveformGenerator.wlanHTDialog(obj);
        end

        function updateSpatialMappingMatrix(obj, ~)
            updateBeamforming(obj);
            updateSpatialMappingMatrix@wirelessWaveformGenerator.wlanHTDialog(obj);
        end

        function spatialMappingMatrixChangedGUI(obj, ~)
        % Validate spatial mapping matrix
            try
                wlanS1GConfig('SpatialMappingMatrix',obj.SpatialMappingMatrix);
            catch e
                obj.errorFromException(e);
            end
        end
    end
end
