classdef wlanHEEHTBaseDialog < wirelessWaveformGenerator.wlanVHTDialog
% Base dialog class for common elements between HE and EHT format

%   Copyright 2023-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
    end

    properties % Public
        UplinkIndicationType = 'checkbox'
        UplinkIndicationLabel
        UplinkIndicationGUI
        BSSColorType = 'numericEdit'
        BSSColorLabel
        BSSColorGUI
        SpatialReuseType = 'numericPopup'
        SpatialReuseDropDown = {'0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15'}
        SpatialReuseLabel
        SpatialReuseGUI
        TXOPDurationType = 'numericEdit'
        TXOPDurationLabel
        TXOPDurationGUI
    end

    methods (Static)
        function hPropDb = getPropertySet(~)
        %getPropertySet Add 'RU & Subcarrier Assignment' in Visualize dropdown

            hPropDb = extmgr.PropertySet('Visualizations','mxArray',{'RU & Subcarrier Assignment'});
        end
    end

    methods
        function obj = wlanHEEHTBaseDialog (parent)
            obj@wirelessWaveformGenerator.wlanVHTDialog(parent); % Call base constructor
            weakObj = matlab.lang.WeakReference(obj);

            obj.BSSColorGUI.(obj.Callback) = @(a,b) bssColorChanged(weakObj.Handle,[]);
        end

        function restoreDefaults(obj)
        %restoreDefaults Restore to default value at setup

        %Set defaults of dependent properties
            obj.UplinkIndication = false;
            obj.BSSColor = 0;
            obj.SpatialReuse = 0;
        end

        function updateVisibilities(~)
        % clear actions from VHT class
        end

        function n = getGuardInterval(obj)
            n = getGuardInterval@wirelessWaveformGenerator.wlanVHTDialog(obj);
            n = str2double(n(1:3)); % Remove the microsecond unit
        end

        function setGuardInterval(obj,val)
            mi = char(956); % Add the microsecond unit:
            val = [num2str(val) ' ' mi 's'];
            setDropdownVal(obj,'GuardInterval',val);
        end

        function figureAdded(obj,~)
        %figureAdded Set visualization during initialization i.e. when the figure is added or removed

            customVisualizations(obj);
        end

        function resetCustomVisuals(obj)
        %resetCustomVisuals Set visualization during initialization or format change

            customVisualizations(obj);
        end

        %% Visualization
        function customVisualizations(obj,varargin)
        %customVisualizations Controls plot allocation using showAllocation.

            try
                if obj.getVisualState(obj.visualNames{1})
                    fig = obj.getVisualFig(obj.visualNames{1});
                    if isempty(fig.Children)
                        ax = axes(fig);
                    else
                        ax = findall(fig,'Type','Axes');
                    end
                    obj.getConfiguration.showAllocation(ax);
                end
            catch
                % called during init, GUI is not ready
            end
        end

        function addCustomVisualizationCode(obj,sw)
        % RU & Subcarriers common for single-user, trigger-based, and multi-user
            if obj.getVisualState(obj.visualNames{1})
                addcr(sw,['% ' getString(message('wlan:waveformGeneratorApp:RUPlotComment'))]);
                addcr(sw,['showAllocation(' obj.configGenVar ');']);
            end
        end
    end

    methods (Access = protected)
        %% Call backs
        function bssColorChanged(obj, ~)
            try
                validateattributes(obj.BSSColor,{'numeric'},{'real','integer','scalar','>=',0,'<=',63},'','BSS color');
            catch e
                obj.errorFromException(e);
            end
        end
    end
end
