classdef wlanHEMUDialog < wirelessWaveformGenerator.wlanHEBaseDialog
% Dialog for HE MU waveform

%   Copyright 2018-2025 The MathWorks, Inc.

    properties (Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
    end

    properties (Dependent, Hidden)
        AllocationIndex
    end

    properties (Hidden)
        SIGBCompressionType = 'checkbox'
        SIGBCompressionLabel
        SIGBCompressionGUI
        SIGBMCSType = 'numericPopup'
        SIGBMCSDropDown = {'0', '1', '2', '3', '4', '5'}
        SIGBMCSLabel
        SIGBMCSGUI
        SIGBDCMType = 'checkbox'
        SIGBDCMLabel
        SIGBDCMGUI
        AllocationIndex1Type = 'numericEdit'
        AllocationIndex1GUI
        AllocationIndex1Label
        AllocationIndex2Type = 'numericEdit'
        AllocationIndex2GUI
        AllocationIndex2Label
        AllocationIndex3Type = 'numericEdit'
        AllocationIndex3GUI
        AllocationIndex3Label
        AllocationIndex4Type = 'numericEdit'
        AllocationIndex4GUI
        AllocationIndex4Label
        AllocationIndex5Type = 'numericEdit'
        AllocationIndex5GUI
        AllocationIndex5Label
        AllocationIndex6Type = 'numericEdit'
        AllocationIndex6GUI
        AllocationIndex6Label
        AllocationIndex7Type = 'numericEdit'
        AllocationIndex7GUI
        AllocationIndex7Label
        AllocationIndex8Type = 'numericEdit'
        AllocationIndex8GUI
        AllocationIndex8Label
        LowerCenter26ToneRUType = 'checkbox'
        LowerCenter26ToneRULabel
        LowerCenter26ToneRUGUI
        UpperCenter26ToneRUType = 'checkbox'
        UpperCenter26ToneRULabel
        UpperCenter26ToneRUGUI

        PrimarySubchannelType = 'numericPopup'
        PrimarySubchannelDropDown = {'1', '2', '3', '4', '5', '6', '7', '8'}
        PrimarySubchannelLabel
        PrimarySubchannelGUI

        configObj

        ruFig
        userFig
        ruTable
        userTable
        userMCS = {'0 (BPSK, 1/2 rate)',   '1 (QPSK, 1/2 rate)',    '2 (QPSK, 3/4 rate)', ...
                   '3 (16-QAM, 1/2 rate)', '4 (16-QAM, 3/4 rate)',  '5 (64-QAM, 2/3 rate)', ...
                   '6 (64-QAM, 3/4 rate)', '7 (64-QAM, 5/6 rate)', '8 (256-QAM, 3/4 rate)', ...
                   '9 (256-QAM, 5/6 rate)', '10 (1024-QAM, 3/4 rate)', ...
                   '11 (1024-QAM, 5/6 rate)'}
        subchannelColors = {'--mw-backgroundColor-input';...                % default background
                            '--mw-graphics-colorOrder-11-tertiary';...     % semantic color
                            '--mw-graphics-colorOrder-10-secondary';...    % semantic color
                            '--mw-graphics-colorOrder-8-secondary';...     % semantic color
                            '--mw-graphics-colorOrder-5-tertiary';...      % semantic color
                            '--mw-graphics-colorOrder-4-tertiary';...      % semantic color
                            '--mw-graphics-colorOrder-2-secondary';...     % semantic color
                            '--mw-graphics-colorOrder-3-tertiary';...      % semantic color
                           }
    end

    methods
        function obj = wlanHEMUDialog(parent)
            obj@wirelessWaveformGenerator.wlanHEBaseDialog(parent); % call base constructor

            % Specify callbacks for changes to HE MU GUI elements which impact
            % other elements
            obj.SIGBCompressionGUI.(obj.Callback)     = @(a,b) sigbCompressionChangedGUI(obj, []);
            obj.SIGBMCSGUI.(obj.Callback)             = @(a,b) sigbMcsChangedGUI(obj, []);
            obj.STBCGUI.(obj.Callback)                = @(a,b) stbcChanged(obj, []);
            obj.AllocationIndex1GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex1GUI);
            obj.AllocationIndex2GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex2GUI);
            obj.AllocationIndex3GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex3GUI);
            obj.AllocationIndex4GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex4GUI);
            obj.AllocationIndex5GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex5GUI);
            obj.AllocationIndex6GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex6GUI);
            obj.AllocationIndex7GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex7GUI);
            obj.AllocationIndex8GUI.(obj.Callback)    = @(a,b) validateAllocIndex(obj, obj.AllocationIndex8GUI);
            obj.LowerCenter26ToneRUGUI.(obj.Callback) = @(a,b) center26ToneRUChangedGUI(obj, []);
            obj.UpperCenter26ToneRUGUI.(obj.Callback) = @(a,b) center26ToneRUChangedGUI(obj, []);


            obj.sigbCompressionChanged(); % trigger visibility update for NumUsers/AllocIndex/PrimarySubchannel

            if isempty(obj.ruFig)
                document = matlab.ui.internal.FigureDocument(...
                    'Title',  'Resource Units', ...
                    'Tag', 'RUFig', ...
                    'DocumentGroupTag', 'waveformGeneratorDocumentGroup', ...
                    'Closable', false);
                addDocument(obj.Parent.WaveformGenerator.AppContainer, document);
                obj.ruFig = document.Figure;
                obj.ruFig.AutoResizeChildren = 'off';
                obj.ruFig.SizeChangedFcn = @(a, b) figResizedCallback(obj, []);
            end
            if isempty(obj.userFig)
                document = matlab.ui.internal.FigureDocument(...
                    'Title',  'Users', ...
                    'Tag', 'UsersHEMU', ...
                    'DocumentGroupTag', 'waveformGeneratorDocumentGroup', ...
                    'Closable', false);
                addDocument(obj.Parent.WaveformGenerator.AppContainer, document);
                obj.userFig = document.Figure;
                obj.userFig.AutoResizeChildren = 'off';
                obj.userFig.SizeChangedFcn = @(a, b) figResizedCallback(obj, []);
            end
            obj.setExtraConfigFigVisibility(true);
            createRUTable(obj);
            createUserTable(obj);

            figResizedCallback(obj); % make sure tables are laid out properly
        end

        function setExtraConfigFigVisibility(obj, visibility)
            obj.ruFig.Visible = visibility;
            obj.userFig.Visible = visibility;
        end

        function setupDialog(obj)
            obj.setExtraConfigFigVisibility(true);
            setupDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
        end

        function adjustDialog(obj)
            adjustDialog@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            set([obj.NumUsersLabel obj.NumUsersGUI obj.AllocationIndex2GUI, obj.AllocationIndex2Label ...
                 obj.AllocationIndex3GUI, obj.AllocationIndex3Label obj.AllocationIndex4GUI, obj.AllocationIndex4Label ...
                 obj.AllocationIndex5GUI, obj.AllocationIndex5Label obj.AllocationIndex6GUI, obj.AllocationIndex6Label, ...
                 obj.AllocationIndex7GUI, obj.AllocationIndex7Label obj.AllocationIndex8GUI, obj.AllocationIndex8Label], ...
               'Visible', ~obj.SIGBCompression && strcmp(obj.ChannelBandwidth, 'CBW160'));
        end

        function updateDialogFromConfig(obj,config)
        % Update the visibility and forced values of GUI elements when configuration loaded
        % MU case
            obj.HEFormat = 'HE multi-user';
            obj.sigbCompressionChanged(); % trigger visibility update for NumUsers/AllocIndex
            obj.layoutUIControls();
            obj.AllocationIndex  = config.AllocationIndex; % Trigger set to individual props (#1-8)
            initConfig(obj); % Allocation may change so re-initialize object
            obj.configObj.RU     = config.RU;
            obj.configObj.User   = config.User;
            updateTables(obj);
        end

        function resetPopupStrings(~)
        % Reset popup menu options
        end

        function outro(obj, ~)
        % Turn of User and RU Tables when switching to a different waveform type
            obj.setExtraConfigFigVisibility(false);
        end

        function figResizedCallback(obj, ~)
            margin = 20;
            if ~isempty(obj.ruTable) && isgraphics(obj.ruTable) && all(obj.ruTable.Parent.Position([3 4])>margin)
                obj.ruTable.Position    = max(0, [10 10 obj.ruTable.Parent.Position(3)-margin ...
                                                  obj.ruTable.Parent.Position(4)-margin]);
            end
            if ~isempty(obj.userTable) && isgraphics(obj.userTable) && all(obj.userTable.Parent.Position([3 4])>margin)
                obj.userTable.Position  = max(0, [10 10 obj.userTable.Parent.Position(3)-margin ...
                                                  obj.userTable.Parent.Position(4)-margin]);
            end
            drawnow nocallbacks;
        end

        function str = getIconDrawingCommand(obj)
            str = ['disp([''Format: HE MU'' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz'' newline ...' newline ...
                   '''Users: '' num2str(' obj.configGenVar '.ruInfo.NumUsers) newline ...' newline ...
                   '''RUs: '' num2str(' obj.configGenVar '.ruInfo.NumRUs) newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        function createRUTable(obj)
            if isempty(obj.ruTable)
                columnWidths = {100 130 110 90, 45, 50, 85};
                obj.ruTable = uitable('Parent', obj.ruFig, ...
                                      'Position',       [10 10 obj.ruFig.Position(3)-20 obj.ruFig.Position(4)-20], ...
                                      'ColumnName',     {getString(message('wlan:waveformGeneratorApp:PowerBoostFactorHeader')), ...
                                                         getString(message('wlan:waveformGeneratorApp:SpatialMappingHeader')), ...
                                                         getString(message('wlan:waveformGeneratorApp:SpatialMappingMatrixHeader')), ...
                                                         getString(message('wlan:waveformGeneratorApp:BeamformHeader')), ...
                                                         getString(message('wlan:waveformGeneratorApp:SizeHeader')), ...
                                                         getString(message('wlan:waveformGeneratorApp:RUIndexHeader')), ...
                                                         getString(message('wlan:waveformGeneratorApp:UsersHeader'))}, ...
                                      'ColumnFormat',   {[] {'Direct', 'Hadamard', 'Fourier', 'Custom'} 'char' [] [] [] 'char'},...
                                      'ColumnEditable', [true true true true false false false],...
                                      'ColumnWidth',    columnWidths, ...
                                      'Data',           ruObj2Table(obj), ...
                                      'CellEditCallback', @obj.ruTableCallback, ...
                                      'RearrangeableColumns', false);
                updateTableRowColor(obj.ruTable, obj.subchannelColors{1}); % Default background color with no-stripes
                ruTableCallback(obj);
            end
        end

        function data = ruObj2Table(obj)
            ruCell = obj.configObj.RU;
            data = cell(length(ruCell), 7);
            for idx = 1:length(ruCell)
                ruObj = ruCell{idx};
                if strcmp(ruObj.SpatialMapping, 'Custom')
                    % uitable cannot accept vector values so it must be converted to string
                    if ndims(ruObj.SpatialMappingMatrix) <= 2
                        spatialMapMatrix = mat2str(ruObj.SpatialMappingMatrix);
                    else
                        % mat2str only works with 2D arrays.
                        % Also wlanHEMURU.SpatialMappingMatrix only accepts numeric
                        % values. So the following is needed:
                        spatialMapMatrix = [ 'reshape(' mat2str(ruObj.SpatialMappingMatrix(:)) ', ' mat2str(size(ruObj.SpatialMappingMatrix)) ')'];
                    end
                    beamforming = ruObj.Beamforming;
                else
                    spatialMapMatrix = 'N/A';
                    beamforming = false;
                end
                data(idx, :) = {ruObj.PowerBoostFactor  ruObj.SpatialMapping  spatialMapMatrix  ...
                                beamforming   num2str(ruObj.Size)      num2str(ruObj.Index)   mat2str(ruObj.UserNumbers)};
            end
        end

        function createUserTable(obj)
            if isempty(obj.userTable)
                columnWidths = {80 130 95 50 70 60 70 40 60};
                obj.userTable = uitable('Parent', obj.userFig, ...
                                        'Position',       [10 10 obj.userFig.Position(3)-20 obj.userFig.Position(4)-20], ...
                                        'ColumnName',     {getString(message('wlan:waveformGeneratorApp:APEPLengthHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:MCSHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:SpaceTimeStreamsHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:DCMHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:ChannelCodingHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:STAIDHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:PacketPaddingHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:RUHeader')), ...
                                                           getString(message('wlan:waveformGeneratorApp:PSDULengthHeader'))}, ...
                                        'ColumnFormat',   {[] obj.userMCS {'1', '2','3', '4', '5', '6', '7', '8'} [] {'LDPC' 'BCC'}, [], {'0', '8', '16'}, [] []},...
                                        'ColumnEditable', [true true true true true true true false false],...
                                        'ColumnWidth',    columnWidths, ...
                                        'Data',           userObj2Table(obj), ...
                                        'CellEditCallback', @obj.userTableCallback, ...
                                        'RearrangeableColumns', false);
                updateTableRowColor(obj.userTable, obj.subchannelColors{1}); % Default background color with no-stripes

                userTableCallback(obj);
            end
        end

        function data = userObj2Table(obj)
            userCell = obj.configObj.User;
            data = cell(length(userCell), 9);
            psduLens = obj.configObj.getPSDULength;
            for idx = 1:length(userCell)
                userObj = userCell{idx};
                mcs = obj.userMCS(startsWith(obj.userMCS, [num2str(userObj.MCS) ' ']));
                data(idx, :) = {userObj.APEPLength  mcs{:}           num2str(userObj.NumSpaceTimeStreams) ...
                                userObj.DCM         userObj.ChannelCoding userObj.STAID  userObj.NominalPacketPadding userObj.RUNumber psduLens(idx)}; %#ok<CCAT>
            end
        end

        function rus = ruTable2Obj(obj)
            t = obj.ruTable.Data;
            rus = cell(1, size(t, 1));
            for rowIdx = 1:size(t, 1)
                row = t(rowIdx, :);
                ruSize              = str2double(row{5});
                index               = str2double(row{6});
                userNums            = str2num(row{7}); %#ok<*ST2NM>
                ru = wlanHEMURU(ruSize, index, userNums);
                ru.PowerBoostFactor = row{1};
                ru.SpatialMapping   = row{2};
                if ~strcmp(row{3}, 'N/A')
                    ru.SpatialMappingMatrix = str2num(row{3});
                end
                ru.Beamforming = logical(row{4});
                rus{rowIdx} = ru;
            end
        end

        function users = userTable2Obj(obj)
            t = obj.userTable.Data;
            users = cell(1, size(t, 1));
            for rowIdx = 1:size(t, 1)
                row = t(rowIdx, :);
                ruNumber      = row{8};
                user          = wlanHEMUUser(ruNumber);
                user.APEPLength = row{1};
                mcsStr        = row{2};
                spaceIdx      = strfind(mcsStr, ' ');
                user.MCS        = str2double(mcsStr(1:spaceIdx(1)-1));
                user.NumSpaceTimeStreams  = str2double(row{3});
                user.DCM                  = logical(row{4});
                user.ChannelCoding        = row{5};
                user.STAID                = row{6};
                user.NominalPacketPadding = row{7};
                % When creating a wlanHEMUConfig object, by default the
                % PostFECPaddingSeed of each user is set to the user number - do
                % the same here.
                user.PostFECPaddingSeed = rowIdx;
                users{rowIdx} = user;
            end
        end

        function updateTables(obj)
            if ~isempty(obj.ruTable)
                obj.ruTable.Data    = ruObj2Table(obj);
            end
            if ~isempty(obj.userTable)
                obj.userTable.Data  = userObj2Table(obj);
            end

            if ~obj.SIGBCompression && ~strcmp(obj.ChannelBandwidth, 'CBW20')
                % Multiple subchannels: Color rows of the same subchannel with the same semantic color
                for idx = 1:length(obj.AllocationIndex)
                    try
                        % construct stand-alone config object, to measure RUs and Users:
                        c = wlanHEMUConfig(obj.AllocationIndex(idx));
                        numRUs    = length(c.RU);
                        numUsers  = length(c.User);

                        updateTableRowColor(obj.ruTable, obj.subchannelColors{idx}, (idx-1)*numRUs+1:idx*numRUs);
                        updateTableRowColor(obj.userTable, obj.subchannelColors{idx}, (idx-1)*numUsers+1:idx*numUsers);
                    catch
                        % In case one Allocation Index (e.g., 114) has no users
                    end
                end
            end

            try
                customVisualizations(obj); % Update RU allocation plot
            catch
                % init. In AppContainer, figures are created in setScopeLayout()
                % instead of Dialog constructor.
            end
        end

        function ruTableCallback(obj, ~, ~)

            setDirty(obj);

            % correct read-only values
            data = obj.ruTable.Data;
            for idx = 1:size(data, 1)
                row = data(idx, :);
                if ~strcmp(row{2}, 'Custom')
                    % Spatial Mapping Matrix
                    data{idx, 3} = 'N/A';
                    data{idx, 4} = false;
                else
                    % Custom spatial mapping
                    if strcmp(row{3}, 'N/A')
                        data{idx, 3} = mat2str(obj.configObj.RU{idx}.SpatialMappingMatrix);
                    end
                end
            end

            try
                % Error if RU settings invalid
                for idx = 1:size(data, 1)
                    % Power boost factor
                    validateattributes(data{idx,1},{'numeric'},{'scalar','>=',0.5,'<=',2},'','Power boost factor');

                    % Spatial mapping matrix
                    if ~strcmp(data{idx,3},'N/A')
                        wlan.internal.heValidateSpatialMappingMatrix(str2num(data{idx,3}));
                    end
                end
            catch e
                obj.errorFromException(e);
                return
            end

            obj.ruTable.Data = data;

            try
                % error for invalid allocation indices
                initConfig(obj);
            catch e
                obj.errorFromException(e);
            end

            obj.configObj.RU = ruTable2Obj(obj);
        end


        function userTableCallback(obj, ~, ~)

            setDirty(obj);

            % correct read-only values
            data = obj.userTable.Data;
            for idx = 1:size(data, 1)
                row = data(idx, :);
                numSTstreams = str2double(row{3});
                mcs = row{2};
                ruNo = obj.configObj.User{idx}.RUNumber;
                numUsers = length(obj.configObj.RU{ruNo}.UserNumbers);
                if numUsers > 1 || numSTstreams > 2 || ~any(strcmp(mcs, obj.userMCS([1 2 4 5])))
                    data(idx, 4) = {false}; % DCM
                end
                ruSize = obj.configObj.RU{row{8}}.Size;
                if numSTstreams > 4 || any(strcmp(mcs, obj.userMCS([11 12]))) || ruSize > 242
                    data(idx, 5) = {'LDPC'}; % Channel Coding
                end
            end

            try
                % Error if User settings invalid
                for idx = 1:size(data, 1)
                    % APEP length
                    validateattributes(data{idx,1},{'numeric'},{'integer','scalar','>=',1,'<=',6500631},'','APEP length');

                    % Station ID
                    validateattributes(data{idx,6},{'numeric'},{'integer','scalar','>=',0,'<=',2047},'','Station ID');
                end
            catch exc % in case allocation index is invalid
                obj.errorFromException(exc);
                return
            end

            obj.userTable.Data = data;

            obj.configObj.User = userTable2Obj(obj);
            try
                updateTables(obj); % update PSDU length
            catch exc % in case allocation index is invalid
                obj.errorFromException(exc);
            end
        end

        function cleanupDlg(obj)
        % Dialog-specific cleanup when app is closing. Custom WLAN UL has
        % additional UI objects that need deletion when the app is closing.
            delete([obj.ruFig; obj.userFig])
        end

        function config = getConfiguration(obj)
        % superclass method does not apply because configuration object needs
        % input arguments and also because hierarchy exists
            initConfig(obj);
            config = obj.configObj;
            if ~isempty(obj.ruTable)
                config.RU                   = ruTable2Obj(obj);
            end
            if ~isempty(obj.userTable)
                config.User                 = userTable2Obj(obj);
            end
            config.PrimarySubchannel    = obj.PrimarySubchannel;
            config.NumTransmitAntennas  = obj.NumTransmitAntennas;
            config.PreHECyclicShifts    = obj.PreHECyclicShifts;
            config.STBC                 = obj.STBC;
            config.GuardInterval        = obj.GuardInterval;
            config.HELTFType            = obj.HELTFType;
            config.SIGBCompression      = obj.SIGBCompression;
            config.SIGBMCS              = obj.SIGBMCS;
            config.SIGBDCM              = obj.SIGBDCM;
            config.UplinkIndication     = obj.UplinkIndication;
            config.BSSColor             = obj.BSSColor;
            config.SpatialReuse         = obj.SpatialReuse;
            config.TXOPDuration         = obj.TXOPDuration;
            config.HighDoppler          = obj.HighDoppler;
            config.MidamblePeriodicity  = obj.MidamblePeriodicity;

            obj.configObj = config; % Update object with table entries
        end
        function addConfigCode(obj, sw)
        % Add to the exported MATLAB code

        % Constructor:
            add(sw, [obj.configGenVar ' = wlanHEMUConfig(' mat2str(obj.AllocationIndex)]);

            lower26Active = wlan.internal.heLowerCenter26ToneRUActive(obj.AllocationIndex);
            if lower26Active
                add(sw, [', ''LowerCenter26ToneRU'', ', num2str(obj.LowerCenter26ToneRU)]);
            end
            upper26Active = wlan.internal.heUpperCenter26ToneRUActive(obj.AllocationIndex);
            if upper26Active
                add(sw, [', ''UpperCenter26ToneRU'', ', num2str(obj.UpperCenter26ToneRU)]);
            end
            addcr(sw, ', ...');
            % Top-level properties:
            if obj.isPrimarySubchannelControlVisible()
                addcr(sw, ['''PrimarySubchannel'', ', num2str(obj.PrimarySubchannel) ', ...']);
            end
            addcr(sw, ['''NumTransmitAntennas'', '  num2str(obj.NumTransmitAntennas) ', ...']);
            if obj.isCyclicShiftsVisible()
                addcr(sw, ['''PreHECyclicShifts'', '  obj.PreHECyclicShiftsGUI.(obj.EditValue) ', ...']);
            end
            addcr(sw, ['''STBC'', '                 num2str(obj.STBC) ', ...']);
            addcr(sw, ['''GuardInterval'', '        num2str(obj.GuardInterval) ', ...']);
            addcr(sw, ['''HELTFType'', '            num2str(obj.HELTFType) ', ...']);
            addcr(sw, ['''SIGBCompression'', '      num2str(obj.SIGBCompression) ', ...']);
            addcr(sw, ['''SIGBMCS'', '              num2str(obj.SIGBMCS) ', ...']);
            addcr(sw, ['''SIGBDCM'', '              num2str(obj.SIGBDCM) ', ...']);
            addcr(sw, ['''UplinkIndication'', '     num2str(obj.UplinkIndication) ', ...']);
            addcr(sw, ['''BSSColor'', '             obj.BSSColorGUI.(obj.EditValue) ', ...']);
            addcr(sw, ['''SpatialReuse'', '         num2str(obj.SpatialReuse) ', ...']);
            addcr(sw, ['''TXOPDuration'', '         obj.TXOPDurationGUI.(obj.EditValue) ', ...']);
            addcr(sw, ['''HighDoppler'', '          num2str(obj.HighDoppler) ', ...']);
            add(sw,   ['''SIGBCompression'', '      num2str(obj.SIGBCompression)]);
            if obj.HighDoppler
                addcr(sw, ', ...');
                add(sw, ['''MidamblePeriodicity'', '      num2str(obj.MidamblePeriodicity)]);
            end
            addcr(sw, ');');
            addcr(sw, '');

            % RU config properties:
            addcr(sw, ['% ' getString(message('wlan:waveformGeneratorApp:RUConfigComment'))]);
            ruObjs = ruTable2Obj(obj);
            for idx = 1:length(ruObjs)
                addcr(sw, [obj.configGenVar '.RU{' num2str(idx) '}.PowerBoostFactor = '   num2str(ruObjs{idx}.PowerBoostFactor) ';']);
                addcr(sw, [obj.configGenVar '.RU{' num2str(idx) '}.SpatialMapping = '''   ruObjs{idx}.SpatialMapping ''';']);
                if strcmp(ruObjs{idx}.SpatialMapping, 'Custom')
                    if ndims(ruObjs{idx}.SpatialMappingMatrix) <= 2
                        addcr(sw, [obj.configGenVar '.RU{' num2str(idx) '}.SpatialMappingMatrix = '   mat2str(ruObjs{idx}.SpatialMappingMatrix) ';']);
                    else
                        % mat2str only works with 2D arrays.
                        addcr(sw, [obj.configGenVar '.RU{' num2str(idx) '}.SpatialMappingMatrix = reshape(' mat2str(ruObjs{idx}.SpatialMappingMatrix(:)) ', ' mat2str(size(ruObjs{idx}.SpatialMappingMatrix)) ');']);
                    end
                    addcr(sw, [obj.configGenVar '.RU{' num2str(idx) '}.Beamforming = '            num2str(ruObjs{idx}.Beamforming) ';']);
                end
            end
            addcr(sw, '');

            % User config properties:
            addcr(sw, ['% ' getString(message('wlan:waveformGeneratorApp:UserConfigComment'))]);
            userObjs = userTable2Obj(obj);
            for idx = 1:length(userObjs)
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.APEPLength = '           num2str(userObjs{idx}.APEPLength) ';']);
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.MCS = '                  num2str(userObjs{idx}.MCS) ';']);
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.NumSpaceTimeStreams = '  num2str(userObjs{idx}.NumSpaceTimeStreams) ';']);
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.DCM = '                  num2str(userObjs{idx}.DCM) ';']);
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.ChannelCoding = '''      userObjs{idx}.ChannelCoding ''';']);
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.STAID = '                num2str(userObjs{idx}.STAID) ';']);
                addcr(sw, [obj.configGenVar '.User{' num2str(idx) '}.NominalPacketPadding = ' num2str(userObjs{idx}.NominalPacketPadding) ';']);
            end
            addcr(sw, '');
        end

        function adjustSpec(obj)
        % Change graphical elements before creating them which are different
        % than superclass defaults (e.g Non-HT)
            adjustSpec@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            obj.NumUsersDropDown = {'1', '2', '3', '4', '5', '6', '7', '8'};
        end

        function props = displayOrder(~)
            props = {'HEFormat'; 'ChannelBandwidth'; 'SIGBCompression'; 'NumUsers'; ...
                     'AllocationIndex1'; 'AllocationIndex2'; 'AllocationIndex3'; 'AllocationIndex4'; ...
                     'AllocationIndex5'; 'AllocationIndex6'; 'AllocationIndex7'; 'AllocationIndex8'; ...
                     'LowerCenter26ToneRU'; 'UpperCenter26ToneRU'; 'PrimarySubchannel'; ...
                     'NumTransmitAntennas'; 'PreHECyclicShifts'; 'STBC'; 'GuardInterval'; 'HELTFType'; ...
                     'SIGBMCS'; 'SIGBDCM'; 'UplinkIndication'; 'BSSColor'; 'SpatialReuse'; ...
                     'TXOPDuration'; 'HighDoppler'; 'MidamblePeriodicity';};
        end

        function updateConfigFcn(obj)
            obj.configFcn = @wlanHEMUConfig; % so that update happens before construction end
            obj.configGenFcn = @wlanHEMUConfig;
            obj.configGenVar = 'heMUCfg';
        end

        function config = initConfig(obj)
            obj.updateConfigFcn();

            upper26Active = wlan.internal.heUpperCenter26ToneRUActive(obj.AllocationIndex);
            setVisible(obj, 'UpperCenter26ToneRU', upper26Active);
            upper26 = false;
            if upper26Active
                upper26 = obj.UpperCenter26ToneRU;
            end

            lower26Active = wlan.internal.heLowerCenter26ToneRUActive(obj.AllocationIndex);
            setVisible(obj, 'LowerCenter26ToneRU', lower26Active);
            lower26 = false;
            if lower26Active
                lower26 = obj.LowerCenter26ToneRU;
            end

            config = obj.configFcn(obj.AllocationIndex, 'LowerCenter26ToneRU', lower26, ...
                                   'UpperCenter26ToneRU', upper26);

            obj.configObj = config;
        end

        function props = props2ExcludeFromConfig(obj)
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            props = [props {'AllocationIndex', 'ChannelBandwidth', 'LowerCenter26ToneRU', 'UpperCenter26ToneRU'}];
        end

        function defaultVisualLayout(obj)
            obj.setVisualState(obj.visualNames{1}, true);  % RU & Subcarriers
                                                           %       obj.setVisualState(obj.visualNames{2}, true);  % SIG1B
        end

        function restoreDefaults(obj)
        % Set defaults of dependent properties
            obj.HEFormat = 'HE multi-user';
            obj.ChannelBandwidth = 'CBW20';
            obj.AllocationIndex1 = 0;
            obj.AllocationIndex2 = 0;
            obj.AllocationIndex3 = 0;
            obj.AllocationIndex4 = 0;
            obj.AllocationIndex5 = 0;
            obj.AllocationIndex6 = 0;
            obj.AllocationIndex7 = 0;
            obj.AllocationIndex8 = 0;
            obj.PrimarySubchannel = 1;

            % Fetch inherited properties
            restoreDefaults@wirelessWaveformGenerator.wlanHEBaseDialog(obj);

            % HEMU specific properties
            obj.SIGBCompression = false;
            sigbCompressionChanged(obj); % SIGB compression changed callback
            obj.NumUsers = 1;
            obj.SIGBMCS = 0;
            obj.SIGBDCM = false;
            obj.LowerCenter26ToneRU = false;
            obj.UpperCenter26ToneRU = false;
        end

        function stbcChanged(obj, ~)
        % MCS
            columnFormat = obj.userTable.ColumnFormat;
            if obj.STBC
                columnFormat{2} = obj.userMCS([1 2 4 5]);
            else
                columnFormat{2} = obj.userMCS;
            end
            obj.userTable.ColumnFormat = columnFormat;

            % ST Streams
            columnEditable = obj.userTable.ColumnEditable;
            if obj.STBC
                data = obj.userTable.Data;
                data(:, 3) = deal({'2'});
                data(:, 4) = deal({false});
                obj.userTable.Data = data;
            end
            columnEditable(3) = ~obj.STBC;
            columnEditable(4) = ~obj.STBC; % DCM
            obj.userTable.ColumnEditable = columnEditable;
        end

        function updateSTBCVis(obj)
            ri = ruInfo(obj.configObj);
            setVisible(obj, 'STBC', ~any(ri.NumUsersPerRU > 1));
            obj.layoutUIControls();
        end

        function channelBandwidthChanged(obj, ~)
            updateAllocIndexVisibility(obj);
            updatePrimarySubchannelSelectionVisibility(obj);
            try
                initConfig(obj); % New Allocation Index
                updateTables(obj);
            catch % in case of invalid alloc Index, still take care of layout
            end
            channelBandwidthChanged@wirelessWaveformGenerator.wlanVHTDialog(obj, []);
        end

        function validateAllocIndex(obj, gui)
            try
                try
                    val = str2double(gui.(obj.EditValue));
                    validateattributes(val, {'numeric'}, {'real', 'integer', 'scalar', '>=', 0, '<=', 223}, '', 'allocation index');
                catch e
                    obj.errorFromException(e);
                end
                obj.configObjChanged();
            catch
                % In case configuration needs to take place in multiple steps; do
                % not error for intermediate invalid states.
            end
        end

        function center26ToneRUChangedGUI(obj, ~)
        % Handle lower or upper 26-tone RU being set
            try
                obj.configObjChanged();
            catch
                % In case configuration needs to take place in multiple steps; do
                % not error for intermediate invalid states.
            end
        end

        function configObjChanged(obj, ~)

            initConfig(obj);
            obj.ChannelBandwidth = obj.configObj.ChannelBandwidth;

            updateTables(obj);

            updateSTBCVis(obj);
        end

        function sigbCompressionChanged(obj , ~)
            setVisible(obj, 'NumUsers', obj.SIGBCompression);

            % Update visibility of elements which are dependent on SIG-B compression
            updateAllocIndexVisibility(obj);
            updatePrimarySubchannelSelectionVisibility(obj);

            try
                initConfig(obj); % New Allocation Index
                updateTables(obj);
            catch % in case of invalid alloc Index, still take care of layout
            end
        end
        function sigbCompressionChangedGUI(obj , ~)
            sigbCompressionChanged(obj);
            layoutUIControls(obj);
        end

        function numUsersChanged(obj , ~)
            initConfig(obj); % New Allocation Index
            updateTables(obj);
        end

        function updateAllocIndexVisibility(obj)
            setVisible(obj, 'AllocationIndex1', ~obj.SIGBCompression);

            setVisible(obj, 'AllocationIndex2', ~obj.SIGBCompression && ~strcmp(obj.ChannelBandwidth, 'CBW20'));

            setVisible(obj, {'AllocationIndex3', 'AllocationIndex4'},  ~obj.SIGBCompression && any(strcmp(obj.ChannelBandwidth, {'CBW80' 'CBW160'})) );

            setVisible(obj, {'AllocationIndex5', 'AllocationIndex6', 'AllocationIndex7', 'AllocationIndex8'}, ...
                       ~obj.SIGBCompression && strcmp(obj.ChannelBandwidth, 'CBW160'));
        end

        function updatePrimarySubchannelSelectionVisibility(obj)
        % Applicable for only 80 MHz and 160 MHz
            isActive = obj.isPrimarySubchannelControlVisible();
            setVisible(obj, 'PrimarySubchannel', isActive);

            if isActive
                % Get options available for each bandwidth
                if strcmp(obj.ChannelBandwidth,'CBW80')
                    maxIndex = 4;
                else
                    maxIndex = 8;
                end
                maxVal = find(strcmp(num2str(maxIndex), obj.PrimarySubchannelDropDown));
                options = obj.PrimarySubchannelDropDown(1:maxVal);

                obj.PrimarySubchannelGUI.(obj.DropdownValues) = options;
            end
        end

        function sigbMcsChangedGUI(obj, ~)
            setVisible(obj, 'SIGBDCM', any(obj.SIGBMCS == [0 1 3 4]));
            layoutUIControls(obj);
        end

        function n = get.AllocationIndex(obj)
            if obj.SIGBCompression
                switch obj.ChannelBandwidth
                  case 'CBW20'
                    offset = 191;
                  case 'CBW40'
                    offset = 199;
                  case 'CBW80'
                    offset = 207;
                  case 'CBW160'
                    offset = 215;
                end
                n = offset + obj.NumUsers;
            else
                switch obj.ChannelBandwidth
                  case 'CBW20'
                    n = obj.AllocationIndex1;
                  case 'CBW40'
                    n = [obj.AllocationIndex1 obj.AllocationIndex2];
                  case 'CBW80'
                    n = [obj.AllocationIndex1 obj.AllocationIndex2 ...
                         obj.AllocationIndex3 obj.AllocationIndex4];
                  case 'CBW160'
                    n = [obj.AllocationIndex1 obj.AllocationIndex2 ...
                         obj.AllocationIndex3 obj.AllocationIndex4 ...
                         obj.AllocationIndex5 obj.AllocationIndex6 ...
                         obj.AllocationIndex7 obj.AllocationIndex8];
                end
            end
        end

        function set.AllocationIndex(obj, val)
            if ~obj.SIGBCompression
                obj.AllocationIndex1 = val(1);

                if ~strcmp(obj.ChannelBandwidth, 'CBW20')
                    obj.AllocationIndex2 = val(2);

                    if ~strcmp(obj.ChannelBandwidth, 'CBW40')
                        obj.AllocationIndex3 = val(3);
                        obj.AllocationIndex4 = val(4);

                        if ~strcmp(obj.ChannelBandwidth, 'CBW80')
                            obj.AllocationIndex5 = val(5);
                            obj.AllocationIndex6 = val(6);
                            obj.AllocationIndex7 = val(7);
                            obj.AllocationIndex8 = val(8);
                        end
                    end
                end

                % else nothing to display, allocation index controls are hidden
            end
        end

        function cols = getNumTileColumns(~, ~)
            cols = 2;
        end
        function rows = getNumTileRows(~, ~)
            rows = 3;
        end

        function tiles = getNumTiles(~, ~)
            tiles = 1 + 3; % 1 for config, 2 for tables and 1 for all visuals
        end

        function n = numVisibleFigs(obj)
            n = numVisibleFigs@wirelessWaveformGenerator.wlanHEBaseDialog(obj);
            n = n + 2; % 1 for RU table + 1 for User table
        end

        function [tileCount, tileCoverage, tileOccupancy] = getTileLayout(obj, ~)

            appObj = obj.Parent.WaveformGenerator;
            numTableTiles = 2;
            tileCount = numTableTiles + (obj.getVisualState('RU & Subcarrier Assignment') || appObj.pPlotSpectrum || appObj.pPlotTimeScope || appObj.pPlotConstellation || appObj.pPlotCCDF);

            tileCoverage = (1:tileCount)';

            tileOccupancy = repmat(struct('children', []), tileCount, 1);

            tileID = 1;
            documentID = 'waveformGeneratorDocumentGroup_RUFig';
            str = struct('showOrder', 1, 'id', documentID);
            tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            tileOccupancy(tileID).showingChildId = documentID;

            tileID = tileID + 1;
            documentID = 'waveformGeneratorDocumentGroup_UsersHEMU';
            str = struct('showOrder', 1, 'id', documentID);
            tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            tileOccupancy(tileID).showingChildId = documentID;

            % showAllocation Plot
            tileID = tileID + 1;
            if obj.getVisualState('RU & Subcarrier Assignment')
                documentID = 'waveformGeneratorDocumentGroup_RUSubcarrierAssignment';
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
                tileOccupancy(tileID).showingChildId = documentID;
            end

            % Spectrum Plot
            if appObj.pPlotSpectrum
                documentID = appObj.getWebScopeDocumentId(appObj.pSpectrum1);
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            end

            % Time Scope
            if appObj.pPlotTimeScope
                documentID = appObj.getWebScopeDocumentId(appObj.pTimeScope);
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            end

            % Plot CCDF
            if appObj.pPlotCCDF
                documentID = getTag(obj.Parent.AppObj) + "DocumentGroup_CCDF";
                str = struct('showOrder', 1, 'id', documentID);
                tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            end
        end


        function b = spectrumEnabled(~)
            b = false;
        end
    end

    methods (Access = protected)
        function numTransmitAntennasChanged(~, ~)
        % Update format specific GUI elements (excluding cyclic shifts as
        % common for all formats) when Transmit Antennas changed - by loading
        % a session or changing the GUI value.

        % Empty implementation as no NumSpaceTimeStreams property so overload
        % to not use HT implementation.
        end

        function [vis,numTxThresh] = isCyclicShiftsVisible(obj)
        % Returns true if the cyclic shift GUI option should be visible
        % Called in HE Base
            numTxThresh = 8; % Threshold over which cyclic shifts must be specified
            if obj.NumTransmitAntennas>numTxThresh
                vis = true;
            else
                vis = false;
            end
        end
    end

    methods (Access = private)
        function f = isPrimarySubchannelControlVisible(obj)
        % Returns true if the primary subchannel GUI options shoule be visible
            f = ~obj.SIGBCompression && any(strcmp(obj.ChannelBandwidth,{'CBW80','CBW160'}));
        end
    end
end

function updateTableRowColor(table, colorVal, varargin)
% Update the background color of the given row element in a uitable
% using a semantic/regular color value. If row indexes are not provided the
% function changes the background color of the entire table
    if isempty(varargin)
        addStyle(table,matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor', colorVal));
    else
        rowIdx = varargin{:};
        addStyle(table,matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor', colorVal),'row',rowIdx);
    end
end
