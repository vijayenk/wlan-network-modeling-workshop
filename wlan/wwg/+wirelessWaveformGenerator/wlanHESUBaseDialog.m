classdef wlanHESUBaseDialog < wirelessWaveformGenerator.wlanHEBaseDialog
% Share common dialog components and visibility between HE TB and HE SU
% (both a transmission intended for a single user)

%   Copyright 2020-2024 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        RUSize
    end

    properties (Hidden)
        DCMType = 'checkbox'
        DCMLabel
        DCMGUI

        RUSizeType % text for HE SU and popupmenu for HE TB
        RUSizeLabel
        RUSizeGUI

        MCSDropDownFull = {'0 (BPSK, 1/2 rate)',   '1 (QPSK, 1/2 rate)',    '2 (QPSK, 3/4 rate)', ...
                           '3 (16-QAM, 1/2 rate)', '4 (16-QAM, 3/4 rate)',  '5 (64-QAM, 2/3 rate)', ...
                           '6 (64-QAM, 3/4 rate)', '7 (64-QAM, 5/6 rate)', '8 (256-QAM, 3/4 rate)', ...
                           '9 (256-QAM, 5/6 rate)', '10 (1024-QAM, 3/4 rate)', ...
                           '11 (1024-QAM, 5/6 rate)'};
    end

    methods
        function obj = wlanHESUBaseDialog(parent)
            obj@wirelessWaveformGenerator.wlanHEBaseDialog(parent); % call base constructor

            % Specify callbacks for changes to HE GUI elements which impact
            % other elements
            obj.DCMGUI.(obj.Callback) = @(a,b) dcmChangedGUI(obj, []);
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g non-HT)
            adjustSpec@wirelessWaveformGenerator.wlanHEBaseDialog(obj);

            obj.resetPopupStrings();
        end

        function props = props2ExcludeFromConfigGeneration(obj)
        % When exporting MATLAB script do not show properties which are used
        % in the app but not in the configuration object, or conditionally
        % visible properties
            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanHEBaseDialog(obj);

            if ~(obj.NumSpaceTimeStreams == 2) || obj.DCM
                props = [props 'STBC'];
            end

            if (obj.NumSpaceTimeStreams > 2) || obj.STBC || ~any(obj.MCS == [0 1 3 4])
                props = [props 'DCM'];
            end
        end

        function resetPopupStrings(obj)
        % Reset popup menu options

            obj.NumSpaceTimeStreamsType = 'numericPopup';
            obj.NumSpaceTimeStreamsDropDown = {'1', '2', '3', '4', '5', '6', '7', '8'};
            obj.NumSpaceTimeStreamsGUI.(obj.DropdownValues) = obj.NumSpaceTimeStreamsDropDown;
            obj.MCSDropDown = obj.MCSDropDownFull;
            obj.MCSGUI.(obj.DropdownValues) = obj.MCSDropDown;
        end

        function spatialMappingMatrixChangedGUI(obj, ~)
        % Validate spatial mapping matrix
            try
                wlan.internal.heValidateSpatialMappingMatrix(obj.SpatialMappingMatrix);
            catch e
                obj.errorFromException(e);
            end
        end

        function numSpaceTimeStreamsChanged(obj, ~)
        % Called when the number of space-time streams change in HE SU/HE TB

        % Update elements which are only dependent on SpaceTimeStreams
            obj.updateHighDoppler();

            % Update elements which are also dependent on other elements
            obj.updateSTBC();
            obj.updateDCM();
            obj.updateChannelCoding();

            numSpaceTimeStreamsChanged@wirelessWaveformGenerator.wlanVHTDialog(obj);
        end

        function stbcChangedGUI(obj, ~)
        % Update elements which are also dependent on other elements
            obj.updateDCM();
            obj.updatePSDU();

            obj.layoutUIControls();
        end

        function mcsChangedGUI(obj, ~)
        % Update elements which are also dependent on other elements
            obj.updateDCM();
            obj.updateSTBC();
            obj.updateChannelCoding();
            obj.updatePSDU();

            obj.layoutUIControls();
        end

        % RUSize
        function v = get.RUSize(obj)
            if isa(obj.RUSizeGUI, 'matlab.ui.control.Label')
                v = getTextNumVal(obj, 'RUSize');
            else %popupmenu
                v = getDropdownNumVal(obj, 'RUSize');
            end
        end
        function set.RUSize(obj, val)
            if isa(obj.RUSizeGUI, 'matlab.ui.control.Label')
                setTextVal(obj, 'RUSize', val);
            else %popupmenu
                setDropdownNumVal(obj, 'RUSize', val);
            end
        end

        function updateSTBC(obj)
        % Change value and enable/disable STBC based on:
        % NumSpaceTimeStreams, DCM
            val = (obj.NumSpaceTimeStreams == 2) && ~obj.DCM;
            if ~val
                obj.STBC = false;
            end
            setEnable(obj, 'STBC', val);
        end

        function updateDCM(obj)
        % Change value and enable/disable DCM based on:
        % NumSpaceTimeStreams, STBC, MCS
            val = (obj.NumSpaceTimeStreams <= 2) && ~obj.STBC && any(obj.MCS == [0 1 3 4]);
            if ~val
                obj.DCM = false;
            end
            setEnable(obj, 'DCM', val);
        end

    end

    methods (Access = private)
        function dcmChangedGUI(obj, ~)
        % Update elements dependent on this and other properties
            obj.updateSTBC();
            obj.updatePSDU();
        end
    end

    methods (Access = protected)
        function updateChannelCoding(obj)
        % Change value of ChannelCoding based on:
        % RUSize (ChannelBandwidth, Upper106ToneRU), NumSpaceTimeStreams, and MCS

            try % in case the object is still initializing
                cfg = obj.getConfiguration;
                s = cfg.ruInfo();
                ruSizes = s.RUSizes;
                bccInvalid = any(obj.MCS == [10 11]) || obj.NumSpaceTimeStreams > 4 || any(ruSizes>242);
                if bccInvalid
                    % Force channel coding and disable if it must be LDPC
                    obj.ChannelCodingGUI.(obj.DropdownValues) = obj.ChannelCodingDropDown;
                    obj.ChannelCodingGUI.Value = 'LDPC';
                end
                setEnable(obj, 'ChannelCoding', ~bccInvalid);
            catch

            end
        end

        function updateHighDoppler(obj)
        % Change value and enable/disable HighDoppler based on
        % NumSpaceTimeStreams
            val = obj.NumSpaceTimeStreams > 4;
            if val
                obj.HighDoppler = false;
            end
            setEnable(obj, 'HighDoppler', ~val);
        end

        function val = getEditValue(obj,prop)
        % Get the numeric (double) value from a edit GUI element
            val = evalin('base', obj.(prop).(obj.EditValue));
        end
    end

end
