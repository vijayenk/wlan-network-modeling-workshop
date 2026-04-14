classdef wlanAdvancedFormatsDialog < wirelessWaveformGenerator.wlanOFDMWaveformConfiguration
% Base dialog for all the standard specific formats
% At the moment it only supports the 802.11be (EHT)

%   Copyright 2024-2025 The MathWorks, Inc.

properties (Dependent)
    ChannelBandwidth
    GuardInterval
    MCS
    NumUsers
    NumTransmitAntennas
    NumSpaceTimeStreams
end

properties (Hidden) % Public
    stdLabel
    TitleString = getString(message('wlan:waveformGeneratorApp:EHTTitle'))

    % Initializing abstract properties
    configFcn     = @dummyFcn
    configGenFcn  = @dummyFcn
    configGenVar  = ''

    % EHT-specific properties (except EHT TB)
    ChannelBandwidthType = 'charPopup'
    ChannelBandwidthDropDown = {''}
    ChannelBandwidthLabel
    ChannelBandwidthGUI

    GuardIntervalType = 'charPopup'
    GuardIntervalDropDown = {''}
    GuardIntervalLabel
    GuardIntervalGUI

    NumUsersType = 'numericPopup'
    NumUsersDropDown = {''}
    NumUsersLabel
    NumUsersGUI

    NumTransmitAntennasType = 'numericEdit'
    NumTransmitAntennasLabel
    NumTransmitAntennasGUI

    % EHT TB required properties
    MCSType = 'charPopup'
    MCSDropDown = {''} % MCSs will be overwritten by EHT TB
    MCSLabel
    MCSGUI

    NumSpaceTimeStreamsType = 'numericPopup'
    NumSpaceTimeStreamsDropDown = {''} % NumSTS will be overwritten by EHT TB
    NumSpaceTimeStreamsLabel
    NumSpaceTimeStreamsGUI

    SpatialMappingType = 'charPopup'
    SpatialMappingDropDown = {''}
    SpatialMappingLabel
    SpatialMappingGUI

    SpatialMappingMatrixType = 'numericEdit'
    SpatialMappingMatrixLabel
    SpatialMappingMatrixGUI

    ChannelCodingType = 'charPopup'
    ChannelCodingDropDown = {'BCC', 'LDPC'}
    ChannelCodingLabel
    ChannelCodingGUI
end

methods (Static)
end

methods % public
    function obj = wlanAdvancedFormatsDialog(parent)
        obj@wirelessWaveformGenerator.wlanOFDMWaveformConfiguration(parent); % Call base constructor
        weakObj = matlab.lang.WeakReference(obj);

        obj.ChannelBandwidthGUI.(obj.Callback)    = @(a,b) channelBandwidthChangedGUI(weakObj.Handle, []);
        obj.NumUsersGUI.(obj.Callback)            = @(a,b) numUsersChangedGUI(weakObj.Handle, []);
        obj.NumTransmitAntennasGUI.(obj.Callback) = @(a,b) numTransmitAntennasChangedGUI(weakObj.Handle, []);
        obj.SpatialMappingGUI.(obj.Callback)      = @(a,b) spatialMappingChangedGUI(weakObj.Handle, []);
        obj.NumSpaceTimeStreamsGUI.(obj.Callback) = @(a,b) numSpaceTimeStreamsChangedGUI(weakObj.Handle, []);
        obj.MCSGUI.(obj.Callback)                 = @(a,b) updatePSDU(obj);
    end

    function setupDialog(obj)
        setupDialog@wirelessWaveformGenerator.wlanWaveformConfiguration(obj);
    end

    % Left-hand side waveform generation layout
    %  |  Column 1:           |  Column 2:            |
    %  |  +----------------+  |  +--------------------+
    %  |  |  {Standard     |  |  |  {obj.Parent.      |
    %  |  |   Specific}    |  |  |   GenerationDialog |
    %  |  +----------------+  |  +--------------------+
    %  |                      |  |  {obj.Parent.      |
    %  |                      |  |   FilteringDialog} |
    %  |                      |  +--------------------+
    function cellDialogs = getDialogsPerColumn(obj)
        cellDialogs{1} = {obj};
        cellDialogs{2} = {obj.Parent.GenerationDialog obj.Parent.FilteringDialog};
    end

    function channelBandwidthChanged(obj, ~)
        updatePSDU(obj);
        updateSampleRate(obj);
        updateWindowTransitionTime(obj);
    end

    function psduChanged(~, ~)
        % This method should be overloaded by each transmission format to
        % support vector PSDU length, which expects a scalar by default.
    end

    function numUsersChangedGUI(obj, ~)
        % This method should be overloaded to react to changes in the
        % number of users.
        numUsersChanged(obj);
        obj.layoutUIControls();
    end

    function numSpaceTimeStreamsChangedGUI(obj, ~)
        numSpaceTimeStreamsChanged(obj);
        obj.layoutUIControls();
    end

    function numSpaceTimeStreamsChanged(obj, ~)
        if obj.NumTransmitAntennas == sum(obj.NumSpaceTimeStreams)
            obj.SpatialMappingDropDown = {'Direct', 'Hadamard', 'Fourier', 'Custom'};
            obj.SpatialMappingGUI.(obj.DropdownValues) = obj.SpatialMappingDropDown;
            obj.SpatialMappingGUI.Value = 'Direct';
        else
            obj.SpatialMappingDropDown = {'Hadamard', 'Fourier', 'Custom'};
            obj.SpatialMappingGUI.(obj.DropdownValues) = obj.SpatialMappingDropDown ;
        end
        updateSpatialMappingMatrix(obj);
        updatePSDU(obj);
    end

    function updateSpatialMappingMatrix(obj, ~)
        val = strcmpi(obj.SpatialMapping, 'Custom');
        setVisible(obj, 'SpatialMappingMatrix', val);
    end

    function spatialMappingChangedGUI(obj, ~)
        updateSpatialMappingMatrix(obj);
        obj.layoutUIControls();
    end

    %% GETer and SETer functions

    % ----- get/set for GuardInterval -----
    function n = get.GuardInterval(obj)
        n = getDropdownVal(obj, 'GuardInterval');
        n = str2double(n(1:3)); % remove the microsecond unit
    end
    %
    function set.GuardInterval(obj, val)
        updatePSDU(obj); % executes `getConfiguration()` and `psduLength()`

        % Add the microsecond unit
        val = [num2str(val) ' ' char(956) 's'];
        setDropdownVal(obj,'GuardInterval',val);
    end

    % ----- get/set for ChannelBandwidth -----
    function bw = get.ChannelBandwidth(obj)
        bw = getDropdownVal(obj, 'ChannelBandwidth');
        bw = ['CBW' bw(1:end-4)];
    end
    %
    function set.ChannelBandwidth(obj, value)
        value = [value(4:end) ' MHz'];
        setDropdownStartingVal(obj, 'ChannelBandwidth', num2str(value));
        channelBandwidthChangedGUI(obj);
    end

    % ----- get/set for MCS -----
    function n = get.MCS(obj)
        if isa(obj.MCSGUI, 'matlab.ui.control.Label')
            n = getTextNumVal(obj, 'MCS');
        elseif isa(obj.MCSGUI, 'matlab.ui.control.EditField')
            n = getEditVal(obj, 'MCS');
        else % dropdown
            n = getDropdownVal(obj, 'MCS');
            n = str2double(n(1:min([strfind(n, '/') strfind(n, '(')])-1));
        end
    end
    %
    function set.MCS(obj, value)
        if isa(obj.MCSGUI, 'matlab.ui.control.Label')
            setTextVal(obj, 'MCS', value);
        elseif isa(obj.MCSGUI, 'matlab.ui.control.EditField')
            setEditVal(obj, 'MCS', val);
        else % drowpdown
            setDropdownStartingVal(obj, 'MCS', num2str(value));
        end
        updatePSDU(obj);
    end

    % ----- get/set for NumUsers -----
    function n = get.NumUsers(obj)
        n = getDropdownNumVal(obj, 'NumUsers');
    end
    %
    function set.NumUsers(obj, val)
        setDropdownNumVal(obj, 'NumUsers', val);

        obj.numUsersChanged();
        obj.updatePSDU();
    end

    % ----- get/set for NumTransmitAntennas -----
    function n = get.NumTransmitAntennas(obj)
        if isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.Label')
            n = getTextNumVal(obj, 'NumTransmitAntennas');
        elseif isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.EditField')
            n = getEditVal(obj, 'NumTransmitAntennas');
        else % popupmenu
            n = getDropdownNumVal(obj, 'NumTransmitAntennas');
        end
    end
    %
    function set.NumTransmitAntennas(obj, value)
        % Called when session loaded therefore need to configure cyclic shift
        % visibility
        if isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.Label')
            setTextVal(obj, 'NumTransmitAntennas', value);
        elseif isa(obj.NumTransmitAntennasGUI, 'matlab.ui.control.EditField')
            setEditVal(obj, 'NumTransmitAntennas', value);
        else % popupmenu
            setDropdownNumVal(obj, 'NumTransmitAntennas', value);
        end

        % Implemented by wlanAbstractFormat to control STS, spatial mapping,
        % and visibility of cyclic shifts, and to update other visualizations.
        obj.numTransmitAntennasChanged();
        obj.updateCyclicShifts();
        obj.layoutUIControls();
    end

    % ----- get/set for NumSpaceTimeStreams -----
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
        updatePSDU(obj);
    end

end

methods (Access = protected)
    % Protected methods will be called or overloaded by other transmission
    % formats
    function numTransmitAntennasChangedGUI(obj, ~)
        % Update elements when Transmit antennas GUI element changed
        % Independent validation of GUI element value
        try
            val = obj.NumTransmitAntennas;
            validateattributes(val, {'numeric'}, {'scalar', 'real', 'integer','>=', 1}, '', 'Transmit antennas');
        catch e
            obj.errorFromException(e);
            return % Do not take further action
        end
        
         % Implemented by wlanAbstractFormat to control STS, spatial mapping,
        % and visibility of cyclic shifts, and to update other visualizations.
        obj.numTransmitAntennasChanged();
        obj.updateCyclicShifts();
        obj.layoutUIControls();
    end

    function numTransmitAntennasChanged(~)
        % Update format specific GUI elements (excluding cyclic shifts as
        % common for all formats) when Transmit Antennas changed - by loading
        % a session or changing the GUI value.
        %
        % Exclude cyclic shift as for all transmission dialogs we want to
        % update cyclic shift controls but may choose to do nothing else if
        % Transmit Antennas is changed. Therefore allows this function to be
        % implemented empty rather than forcing all methods to call
        % updateCyclicShifts().
        %
        % For Non-HT no specific action require so empty method.
    end

    function [vis,numTxThresh] = isCyclicShiftsVisible(cfg)
        % Returns true if the cyclic shift GUI option should be visible
        numTxThresh = 8; % Threshold over which cyclic shifts must be specified
        if cfg.NumTransmitAntennas > numTxThresh
            vis = true;
        else
            vis = false;
        end
    end

    function validateCyclicShiftGUIValue(~,val,valstr)
        % Independent validation of GUI element value. Called by transmission
        % format dialogs to validate cyclic shifts.
        validateattributes(val, {'numeric'}, {'row', 'nonempty', 'real', 'integer','>=', -200, '<=', 0}, '', valstr);
    end
end

end
