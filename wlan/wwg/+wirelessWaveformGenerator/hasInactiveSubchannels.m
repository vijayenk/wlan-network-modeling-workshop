classdef hasInactiveSubchannels < handle
%hasInactiveSubchannels Dialog elements and behavior for waveform with inactive subchannel
%   hasInactiveSubchannels GUI elements:
%     InactiveSubchannel1 - checkbox
%     InactiveSubchannel2 - checkbox
%     InactiveSubchannel3 - checkbox
%     InactiveSubchannel4 - checkbox
%     InactiveSubchannel5 - checkbox
%     InactiveSubchannel6 - checkbox
%     InactiveSubchannel7 - checkbox
%     InactiveSubchannel8 - checkbox
%
%   hasInactiveSubchannels configuration object properties:
%     InactiveSubchannels - Dependent, hidden, set based on GUI elements
%
%   hasInactiveSubchannels methods:
%     getConfiguration                  - Updates configuration object
%                                         based on elements
%     props2ExcludeFromConfig           - Returns a list of properties in
%                                         the dialog which do not
%                                         correspond to configuration
%                                         object properties
%     props2ExcludeFromConfigGeneration - Returns a list of properties in
%                                         the dialog which should not
%                                         appear in exported MATLAB code
%                                         when creating the configuration
%                                         object
%     addConfigCode                     - Adds custom config object
%                                         creating code for MATLAB script
%                                         export
%     adjustDialog                      - Adjustments of UI elements after
%                                         they have been created
%     restoreDefaults                   - Restore defaults of dependent
%                                         properties
%     updateDialogFromConfig            - Updates the visibility and forced
%                                         values of GUI elements when
%                                         configuration loaded
%     inactiveSubchannelsApplicable     - Override to provide custom
%                                         control when lower and upper
%                                         subchannels are applicable.
%                                         Returns indication of if upper
%                                         and or lower subchannels are
%                                         active based on the
%                                         configuration.
%     updateInactiveSubchannelsGUI      - Updates GUI elements, e.g.
%                                         visibility base on
%                                         inactiveSubchannelsApplicable()
%                                         implementation

%   Copyright 2020-2024 The MathWorks, Inc.

    properties (Dependent, Hidden)
        % Property set indirectly using other controls in the app
        InactiveSubchannels
    end

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
    end

    properties (Hidden)
        InactiveSubchannel1Type = 'checkbox'
        InactiveSubchannel1Label
        InactiveSubchannel1GUI
        InactiveSubchannel2Type = 'checkbox'
        InactiveSubchannel2Label
        InactiveSubchannel2GUI
        InactiveSubchannel3Type = 'checkbox'
        InactiveSubchannel3Label
        InactiveSubchannel3GUI
        InactiveSubchannel4Type = 'checkbox'
        InactiveSubchannel4Label
        InactiveSubchannel4GUI
        InactiveSubchannel5Type = 'checkbox'
        InactiveSubchannel5Label
        InactiveSubchannel5GUI
        InactiveSubchannel6Type = 'checkbox'
        InactiveSubchannel6Label
        InactiveSubchannel6GUI
        InactiveSubchannel7Type = 'checkbox'
        InactiveSubchannel7Label
        InactiveSubchannel7GUI
        InactiveSubchannel8Type = 'checkbox'
        InactiveSubchannel8Label
        InactiveSubchannel8GUI
    end

    methods
        function config = getConfiguration(obj,config)
        % Update configuration object from dialog
        % Map displayed InactiveSubchannels to the corresponding config prop
            config.InactiveSubchannels = obj.InactiveSubchannels;
        end

        function props = props2ExcludeFromConfig(~)
        % Return a cell array of properties which are not part of the
        % configuration object but are part of the dialog and therefore
        % should be excluded for forming a config
            props = {'InactiveSubchannel1','InactiveSubchannel2','InactiveSubchannel3','InactiveSubchannel4', ...
                     'InactiveSubchannel5','InactiveSubchannel6','InactiveSubchannel7','InactiveSubchannel8'};
        end
        function props = props2ExcludeFromConfigGeneration(obj)
        % Return a cell array of properties which should not be "set" using
        % NV pairs when configuring the object in the generated MATLAB
        % script
            props = props2ExcludeFromConfig(obj);
        end

        function addConfigCode(obj, sw)
        % Add any custom object configuration code when exporting MATLAB script
            if inactiveSubchannelsApplicable(obj)
                % Set InactiveSubchannels property of configuration object if applicable
                addcr(sw, [obj.configGenVar '.InactiveSubchannels = [' num2str(obj.InactiveSubchannels) '];']);
            end
        end

        function adjustDialog(obj)
        % Adjustments of UI elements after they have been created - i.e.
        % disable
            obj.setInactiveSubchannelGUIVisible(false);
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            obj.setAllInactiveSubchannelControls(false); % Default all to false
        end

        function updateDialogFromConfig(obj,config)
        % Update the visibility and forced values of GUI elements when
        % configuration loaded
            setInactiveSubchannelGUIElementsFromConfig(obj,config);
        end

        function n = get.InactiveSubchannels(obj)
        % Get the appropriate InactiveSubchannels property of
        % wlanHESUConfig based on app controls
            n = getInactiveSubchannelsVector(obj);
        end
    end

    methods (Access=protected)
        function updateInactiveSubchannelsGUI(obj)
        % Show or hide inactive subchannel related controls
        % Layout controls and panels externally
            try % in case the object is still initializing
                [lowerVisible,upperVisible] = inactiveSubchannelsApplicable(obj);
                setVisible(obj, {'InactiveSubchannel1', 'InactiveSubchannel2', ...
                                 'InactiveSubchannel3', 'InactiveSubchannel4'}, lowerVisible);

                % Upper channels only applicable for 160 MHz
                setVisible(obj, {'InactiveSubchannel5', 'InactiveSubchannel6', ...
                                 'InactiveSubchannel7', 'InactiveSubchannel8'}, upperVisible);
            catch

            end
        end

        function [lower,upper] = inactiveSubchannelsApplicable(obj,varargin)
        % Inactive subchannels only applicable for 80 MHz or 160 MHz. Returns
        % true if the lower or upper subchannels are applicable for the given
        % object or configuration.
            if nargin==1
                cfg = obj;
            else
                cfg = varargin{1};
            end
            lower = any(strcmp(cfg.ChannelBandwidth,{'CBW80','CBW160'}));
            upper = strcmp(cfg.ChannelBandwidth,'CBW160');
        end
    end

    methods (Access=private)
        function v = getInactiveSubchannelsVector(obj)
        % Returns a vector suitable for the InactiveSubchannels property
        % of wlanNonHTConfig given the app settings
            v = false;
            [lowerActive,upperActive] = inactiveSubchannelsApplicable(obj);
            if upperActive
                v = [obj.InactiveSubchannel1 obj.InactiveSubchannel2 obj.InactiveSubchannel3 obj.InactiveSubchannel4 ...
                     obj.InactiveSubchannel5 obj.InactiveSubchannel6 obj.InactiveSubchannel7 obj.InactiveSubchannel8];
            elseif lowerActive
                v = [obj.InactiveSubchannel1 obj.InactiveSubchannel2 obj.InactiveSubchannel3 obj.InactiveSubchannel4];
            end
        end

        function setAllInactiveSubchannelControls(obj,val)
        % Set all inactive subchannel properties to a value
            obj.InactiveSubchannel1 = val;
            obj.InactiveSubchannel2 = val;
            obj.InactiveSubchannel3 = val;
            obj.InactiveSubchannel4 = val;
            obj.InactiveSubchannel5 = val;
            obj.InactiveSubchannel6 = val;
            obj.InactiveSubchannel7 = val;
            obj.InactiveSubchannel8 = val;
        end

        function setInactiveSubchannelGUIElementsFromConfig(obj,config)
        % Map non-displayed InactiveSubchannels to the corresponding visible properties
            setAllInactiveSubchannelControls(obj, false); % Default all to false
            if isprop(config,'InactiveSubchannels')
                % Make sure field exists for backwards compatibility and if a MU
                % object is passed
                val = config.InactiveSubchannels;
                [lowerActive,upperActive] = inactiveSubchannelsApplicable(obj,config);
                if lowerActive
                    % InactiveSubchannels should only have 1, 4 or 8 elements for a
                    % active and valid case. Set the appropriate inactive subchannel
                    % control properties.
                    if numel(val)>1
                        obj.InactiveSubchannel1 = val(1);
                        obj.InactiveSubchannel2 = val(2);
                        obj.InactiveSubchannel3 = val(3);
                        obj.InactiveSubchannel4 = val(4);
                        if upperActive && numel(val)>4
                            obj.InactiveSubchannel5 = val(5);
                            obj.InactiveSubchannel6 = val(6);
                            obj.InactiveSubchannel7 = val(7);
                            obj.InactiveSubchannel8 = val(8);
                        end
                    else
                        % Scalar is possible so set all inactive subchannels to scalar
                        setAllInactiveSubchannelControls(obj,val);
                    end
                end
            end
        end

        function setInactiveSubchannelGUIVisible(obj,flag)
        % Set the visibility of inactive subchannel GUI labels and elements
            setVisible(obj, {'InactiveSubchannel1', 'InactiveSubchannel2', ...
                             'InactiveSubchannel3', 'InactiveSubchannel4', 'InactiveSubchannel5', ...
                             'InactiveSubchannel6', 'InactiveSubchannel7', 'InactiveSubchannel8'}, flag);
        end
    end

end
