classdef wlanEHTTBAdvancedParametersDialog < wirelessWaveformGenerator.wlanEHTDialog
%

%   Copyright 2024-2025 The MathWorks, Inc.

    properties (Access=public,Dependent)
        Channelization
    end

    properties (Constant,Hidden)
        classNameTB = 'wirelessWaveformGenerator.wlanEHTTBDialog';
    end

    properties % Public access
        EHTTBSpatialReuse1Type = 'numericEdit'
        EHTTBSpatialReuse1Label
        EHTTBSpatialReuse1GUI

        EHTTBSpatialReuse2Type = 'numericEdit'
        EHTTBSpatialReuse2Label
        EHTTBSpatialReuse2GUI

        ChannelizationType = 'charPopup'
        ChannelizationDropDown = {'320 MHz-1','320 MHz-2'};
        ChannelizationLabel
        ChannelizationGUI

        EHTTBDisregardBitsUSIG1Type = 'numericEdit'
        EHTTBDisregardBitsUSIG1Label
        EHTTBDisregardBitsUSIG1GUI

        EHTTBDisregardBitsUSIG2Type = 'numericEdit'
        EHTTBDisregardBitsUSIG2Label
        EHTTBDisregardBitsUSIG2GUI

        EHTTBValidateBitUSIG2Type = 'checkbox'
        EHTTBValidateBitUSIG2Label
        EHTTBValidateBitUSIG2GUI
    end

    methods
        function obj = wlanEHTTBAdvancedParametersDialog(parent)
            obj@wirelessWaveformGenerator.wlanEHTDialog(parent); % call base constructor
            obj.BSSColorGUI.(obj.Callback) = @(a,b) bssColorChangedGUI(obj);
            obj.ChannelizationGUI.(obj.Callback) = @(a,b) channelizationChangedGUI(obj);
            obj.EHTTBSpatialReuse1GUI.(obj.Callback) = @(a,b) spatialReuse1ChangedGUI(obj);
            obj.EHTTBSpatialReuse2GUI.(obj.Callback) = @(a,b) spatialReuse2ChangedGUI(obj);
            obj.TXOPDurationGUI.(obj.Callback) = @(a,b) validateTXOPDurationGUI(obj);
            obj.EHTTBDisregardBitsUSIG1GUI.(obj.Callback) = @(a,b) disregardBitsUSIG1ChangedGUI(obj);
            obj.EHTTBDisregardBitsUSIG2GUI.(obj.Callback) = @(a,b) disregardBitsUSIG2ChangedGUI(obj);
            obj.EHTTBValidateBitUSIG2GUI.(obj.Callback) = @(a,b) validateBitUSIG2ChangedGUI(obj);
        end

        function adjustSpec(obj)
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:EHTTBAdvancedParametersTitle'));
        end

        function adjustDialog(obj)
            adjustDialog@wirelessWaveformGenerator.wlanEHTDialog(obj);
            obj.BSSColorGUI.Tag = 'advBSSColor';
            obj.EHTTBSpatialReuse1GUI.Tag = 'advEHTTBSpatialReuse1';
            obj.EHTTBSpatialReuse2GUI.Tag = 'advEHTTBSpatialReuse2';
            obj.TXOPDurationGUI.Tag = 'advTXOPDuration';
            obj.ChannelizationGUI.Tag = 'advChannelization';
            obj.EHTTBDisregardBitsUSIG1GUI.Tag = 'advEHTTBDisregardBitsUSIG1';
            obj.EHTTBDisregardBitsUSIG2GUI.Tag = 'advEHTTBDisregardBitsUSIG2';
            obj.EHTTBValidateBitUSIG2GUI.Tag = 'advEHTTBValidateBitUSIG2';
        end

        function updateDialogFromConfig(obj,config)
        %updateDialogFromConfig Update the visibility and forced values of
        % GUI elements when configuration is loaded
            obj.BSSColor = config.BSSColor;
            obj.Channelization = config.Channelization;
            obj.EHTTBSpatialReuse1 = config.SpatialReuse1;
            obj.EHTTBSpatialReuse2 = config.SpatialReuse2;
            obj.TXOPDuration = config.TXOPDuration;
            obj.EHTTBDisregardBitsUSIG1 = config.DisregardBitsUSIG1;
            obj.EHTTBDisregardBitsUSIG2 = config.DisregardBitsUSIG2;
            obj.EHTTBValidateBitUSIG2 = config.ValidateBitUSIG2;
        end

        function props = displayOrder(~)
            props = {'BSSColor','EHTTBSpatialReuse1','EHTTBSpatialReuse2','TXOPDuration','Channelization',...
                     'EHTTBDisregardBitsUSIG1','EHTTBDisregardBitsUSIG2','EHTTBValidateBitUSIG2'};
        end

        function restoreDefaults(obj)
            obj.BSSColor = 0;
            obj.EHTTBSpatialReuse1 = 15;
            obj.EHTTBSpatialReuse2 = 15;
            obj.TXOPDuration = -1;
            obj.Channelization = '320 MHz-1';
            obj.EHTTBDisregardBitsUSIG1 = [1 1 1 1 1 1];
            obj.EHTTBDisregardBitsUSIG2 = [0 1 1 1 1];
            obj.EHTTBValidateBitUSIG2 = true;
        end

        %% Callback functions
        function pushAdvancedParameters(obj)
        %pushAdvancedParameters pushes the "Advanced Parameters" values to
        % the main EHTTBDialog
            dlgTB = obj.Parent.AppObj.pParameters.DialogsMap(obj.classNameTB);
            dlgTB.BSSColor = obj.BSSColor;
            dlgTB.Channelization = obj.Channelization;
            dlgTB.EHTTBSpatialReuse1 = obj.EHTTBSpatialReuse1;
            dlgTB.EHTTBSpatialReuse2 = obj.EHTTBSpatialReuse2;
            % Validate TXOPDuration. This is to ensure that the same error
            % message is thrown by the app and the config object
            validateTXOPDuration(obj);
            dlgTB.TXOPDuration = obj.TXOPDuration;
            dlgTB.EHTTBDisregardBitsUSIG1 = obj.EHTTBDisregardBitsUSIG1;
            dlgTB.EHTTBDisregardBitsUSIG2 = obj.EHTTBDisregardBitsUSIG2;
            dlgTB.EHTTBValidateBitUSIG2 = obj.EHTTBValidateBitUSIG2;

            getConfiguration(dlgTB);
            customVisualizations(dlgTB); % Update RU & Subcarrier Assignment plot
            layoutUIControls(dlgTB); % Set Height=0 to invisible properties
        end

        function bssColorChangedGUI(obj)
        % Validate the value
            try
                validateattributes(obj.BSSColor,{'numeric'},{'real','integer','scalar','>=',0,'<=',63},'','BSS color');
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function channelizationChangedGUI(obj)
        % Check if the current object is valid
            try
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function changeChannelizationVisibility(obj,flag)
            setVisible(obj,'Channelization',flag);
            layoutUIControls(obj); % Set Height=0 to invisible properties
        end

        function spatialReuse1ChangedGUI(obj)
        % Validate the value
            try
                validateattributes(obj.EHTTBSpatialReuse1,{'numeric'},{'real','integer','scalar','>=',0,'<=',15},'','Spatial Reuse 1');
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function spatialReuse2ChangedGUI(obj)
        % Validate the value
            try
                validateattributes(obj.EHTTBSpatialReuse2,{'numeric'},{'real','integer','scalar','>=',0,'<=',15},'','Spatial Reuse 2');
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function validateTXOPDurationGUI(obj)
        % Validate the value
            try
                % Overwrite dlgTB.TXOPDuration before the validator for
                % TXOPDuration this is to ensure that the same error
                % message is thrown when the user clicks the generate
                % button.
                dlgTB = obj.Parent.AppObj.pParameters.DialogsMap(obj.classNameTB);
                dlgTB.TXOPDuration = obj.TXOPDuration;
                validateTXOPDuration(obj);
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function disregardBitsUSIG1ChangedGUI(obj)
        % Validate the value
            try
                validateattributes(obj.EHTTBDisregardBitsUSIG1,{'numeric'},{'real','binary','vector',},'','Disregard U-SIG1 Bits');
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function disregardBitsUSIG2ChangedGUI(obj)
        % Validate the value
            try
                validateattributes(obj.EHTTBDisregardBitsUSIG1,{'numeric'},{'real','binary','vector',},'','Disregard U-SIG2 Bits');
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function validateBitUSIG2ChangedGUI(obj)
            try
                pushAdvancedParameters(obj);
            catch e
                obj.errorFromException(e);
            end
        end

        function n = get.Channelization(obj)
            n = getDropdownVal(obj,'Channelization');
            n = str2double(extractAfter(n,'-'));
        end

        function set.Channelization(obj,val)
            if isnumeric(val) % Needed when loading the session
                if val==1
                    setDropdownStartingVal(obj,'Channelization',obj.ChannelizationDropDown{1});
                else
                    setDropdownStartingVal(obj,'Channelization',obj.ChannelizationDropDown{2});
                end
            else
                setDropdownStartingVal(obj,'Channelization',extractBefore(val,'-'));
            end
        end

    end

end
