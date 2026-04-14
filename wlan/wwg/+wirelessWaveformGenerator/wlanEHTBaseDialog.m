classdef wlanEHTBaseDialog < wirelessWaveformGenerator.wlanEHTDialog
% Base dialog class for 802.11be (EHT - Extremely High Throughput)

%   Copyright 2023-2025 The MathWorks, Inc.

    properties (Access=public,Dependent)
        % List of properties with custom GETers/SETers. All others from
        % displayOrder() get generic GETer/SETer from Dialog.m
        EHTDUPMode
        PuncturedChannelFieldValue
        EHTLTFType
        Channelization
    end

    properties (Access=protected,Abstract)
        userFigTag
        ruFigTag
    end

    properties (Access=protected)
        configObj
        CompressionMode
    end

    properties (Access=private)
        ReadOnlyCellStyle = matlab.ui.style.internal.SemanticStyle('BackgroundColor','--mw-backgroundColor-input-readonly','FontColor','--mw-color-readOnly');
        ReadOnlyCellBehavior = matlab.ui.style.Behavior('Editable','off');
    end

    properties % Public access
        EHTPPDUFormatType = 'charPopup'
        EHTPPDUFormatDropDown = {'EHT MU','EHT TB'}
        EHTPPDUFormatLabel
        EHTPPDUFormatGUI
        EHTTransmissionType = 'charPopup'
        EHTTransmissionDropDown = {'EHT SU','MU-MIMO','OFDMA','Sounding NDP'}
        EHTTransmissionLabel
        EHTTransmissionGUI
        EHTDUPModeType = 'checkbox'
        EHTDUPModeLabel
        EHTDUPModeGUI
        PuncturedChannelFieldValueType = 'charPopup'
        PuncturedChannelFieldValueDropDown = {'0 [1 1 1 1]', '1 [x 1 1 1]', '2 [1 x 1 1]', '3 [1 1 x 1]', '4 [1 1 1 x]', ...% 80 MHz
                                              '0 [1 1 1 1 1 1 1 1]', '1 [x 1 1 1 1 1 1 1]', '2 [1 x 1 1 1 1 1 1]', '3 [1 1 x 1 1 1 1 1]', '4 [1 1 1 x 1 1 1 1]', '5 [1 1 1 1 x 1 1 1]', '6 [1 1 1 1 1 x 1 1]', ...
                                              '7 [1 1 1 1 1 1 x 1]', '8 [1 1 1 1 1 1 1 x]', '9 [x x 1 1 1 1 1 1]', '10 [1 1 x x 1 1 1 1]', '11 [1 1 1 1 x x 1 1]', '12 [1 1 1 1 1 1 x x]', ... % 160 MHz
                                              '0 [1 1 1 1 1 1 1 1]', '1 [x 1 1 1 1 1 1 1]', '2 [1 x 1 1 1 1 1 1]', '3 [1 1 x 1 1 1 1 1]', '4 [1 1 1 x 1 1 1 1]','5 [1 1 1 1 x 1 1 1]', '6 [1 1 1 1 1 x 1 1]', ...
                                              '7 [1 1 1 1 1 1 x 1]', '8 [1 1 1 1 1 1 1 x]', '9 [x x 1 1 1 1 1 1]', '10 [1 1 x x 1 1 1 1]', '11 [1 1 1 1 x x 1 1]', '12 [1 1 1 1 1 1 x x]', '13 [x x x 1 1 1 1 1]', ...
                                              '14 [x x 1 x 1 1 1 1]', '15 [x x 1 1 x 1 1 1]', '16 [x x 1 1 1 x 1 1]', '17 [x x 1 1 1 1 x 1]', '18 [x x 1 1 1 1 1 x]', '19 [x 1 1 1 1 1 x x]', '20 [1 x 1 1 1 1 x x]', ...
                                              '21 [1 1 x 1 1 1 x x]', '22 [1 1 1 x 1 1 x x]', '23 [1 1 1 1 x 1 x x]', '24 [1 1 1 1 1 x x x]'} ;  % 320 MHz
        PuncturedChannelFieldValueLabel
        PuncturedChannelFieldValueGUI
        PreEHTCyclicShiftsType = 'numericEdit'
        PreEHTCyclicShiftsLabel
        PreEHTCyclicShiftsGUI
        EHTLTFTypeType = 'charPopup'
        EHTLTFTypeDropDown = {'2x','4x'}
        EHTLTFTypeLabel
        EHTLTFTypeGUI
        NumExtraEHTLTFSymbolsType = 'numericPopup'
        NumExtraEHTLTFSymbolsDropDown = {'0','1', '2', '3', '4', '5', '6', '7'};
        NumExtraEHTLTFSymbolsLabel
        NumExtraEHTLTFSymbolsGUI
        EHTSIGMCSType = 'numericPopup'
        EHTSIGMCSDropDown = {'0','1','3','15'};
        EHTSIGMCSLabel
        EHTSIGMCSGUI
        ChannelizationType = 'charPopup'
        ChannelizationDropDown = {'320 MHz-1','320 MHz-2'};
        ChannelizationLabel
        ChannelizationGUI
        CompressionModeType = 'numericText'
        CompressionModeLabel
        CompressionModeGUI
        PreEHTPhaseRotationType = 'numericEdit'
        PreEHTPhaseRotationLabel
        PreEHTPhaseRotationGUI

        ruFig
        userFig
        ruTable
        userTable

        userMCS = {'0 (BPSK, 1/2 rate)','1 (QPSK, 1/2 rate)', '2 (QPSK, 3/4 rate)', ...
                   '3 (16-QAM, 1/2 rate)','4 (16-QAM, 3/4 rate)','5 (64-QAM, 2/3 rate)', ...
                   '6 (64-QAM, 3/4 rate)','7 (64-QAM, 5/6 rate)','8 (256-QAM, 3/4 rate)', ...
                   '9 (256-QAM, 5/6 rate)','10 (1024-QAM, 3/4 rate)', '11 (1024-QAM, 5/6 rate)',...
                   '12 (4096-QAM, 3/4 rate)','13 (4096-QAM, 5/6 rate)','14 (BPSK-DCM, 1/2 rate)','15 (BPSK-DCM, 1/2 rate)'};
    end

    methods

        function obj = wlanEHTBaseDialog(parent)
            obj@wirelessWaveformGenerator.wlanEHTDialog(parent); % Call base constructor
            weakObj = matlab.lang.WeakReference(obj);

            obj.EHTPPDUFormatGUI.(obj.Callback)              = @(a,b) ehtFormatChangedGUI(weakObj.Handle);
            obj.EHTTransmissionGUI.(obj.Callback)            = @(a,b) ehtFormatChangedGUI(weakObj.Handle);
            obj.ChannelBandwidthGUI.(obj.Callback)           = @(a,b) channelBandwidthChangedGUI(weakObj.Handle);
            obj.EHTDUPModeGUI.(obj.Callback)                 = @(a,b) ehtDUPModeChangedGUI(weakObj.Handle);
            obj.PreEHTPhaseRotationGUI.(obj.Callback)        = @(a,b) preEHTPhaseRotationChangedGUI(weakObj.Handle);
            obj.PuncturedChannelFieldValueGUI.(obj.Callback) = @(a,b) puncturedChannelFieldValueChangedGUI(weakObj.Handle);
            obj.PreEHTCyclicShiftsGUI.(obj.Callback)         = @(a,b) preEHTCyclicShiftsChangedGUI(weakObj.Handle);
            obj.NumExtraEHTLTFSymbolsGUI.(obj.Callback)      = @(a,b) numExtraEHTLTFSymbolsGUI(weakObj.Handle);
            obj.TXOPDurationGUI.(obj.Callback)               = @(a,b) txopDurationChangedGUI(weakObj.Handle);

            if isempty(obj.ruFig)
                document = matlab.ui.internal.FigureDocument(...
                    'Title','Resource Units', ...
                    'Tag',obj.ruFigTag, ...
                    'DocumentGroupTag','waveformGeneratorDocumentGroup', ...
                    'Closable',false);
                addDocument(obj.Parent.WaveformGenerator.AppContainer, document);
                obj.ruFig = document.Figure;
                obj.ruFig.AutoResizeChildren = 'off';
                obj.ruFig.SizeChangedFcn = @(a, b) figResizedCallback(obj,[]);
            end

            if isempty(obj.userFig)
                document = matlab.ui.internal.FigureDocument(...
                    'Title','Users', ...
                    'Tag',obj.userFigTag, ...
                    'DocumentGroupTag','waveformGeneratorDocumentGroup', ...
                    'Closable',false);
                addDocument(obj.Parent.WaveformGenerator.AppContainer, document);
                obj.userFig = document.Figure;
                obj.userFig.AutoResizeChildren = 'off';
                obj.userFig.SizeChangedFcn = @(a, b) figResizedCallback(obj,[]);
            end

            figResizedCallback(obj); % Make sure tables are laid out properly
        end

        %% Control switching between different formats and waveform types
        function outro(obj,~)
        % Turn off User and RU Tables when switching to a different waveform type

            obj.setExtraConfigFigVisibility(false);

            pause(0.5); % allow duplicate RU/User figures to hide, to facilitate new layout 
        end

        function setExtraConfigFigVisibility(obj,visibility)
        % Close figures when switching different formats

            obj.ruFig.Visible = visibility;
            obj.userFig.Visible = visibility;
        end

        %% Tables for Users and RUs
        function figResizedCallback(obj, ~)
        % Reposition the figures when the tables are moved

            margin = 20;
            if ~isempty(obj.ruTable) && isgraphics(obj.ruTable) && all(obj.ruTable.Parent.Position([3 4])>margin)
                obj.ruTable.Position = max(0,[10 10 obj.ruTable.Parent.Position(3)-margin obj.ruTable.Parent.Position(4)-margin]); % Location and size of the table, specified as a four-element vector of the form [left bottom width height]
            end

            if ~isempty(obj.userTable) && isgraphics(obj.userTable) && all(obj.userTable.Parent.Position([3 4])>margin)
                obj.userTable.Position = max(0,[10 10 obj.userTable.Parent.Position(3)-margin obj.userTable.Parent.Position(4)-margin]); % Location and size of the table, specified as a four-element vector of the form [left bottom width height]
            end
            drawnow nocallbacks;
        end

        function createRUTable(obj)
        %createRUTable creates numRUs x 7 table, where the column labels are
        % given as follows: Power Boost Factor | Spatial Mapping | Spatial
        % Mapping Matrix | Beamform | Size | RU Index | User(s)
            if isempty(obj.ruTable)
                % Set the column widths using ColumnName property value
                columnWidths = {100 130 110 90, 120, 120, 120};
                obj.ruTable = uitable('Parent',obj.ruFig, ...
                                      'Position', [10 10 obj.ruFig.Position(3)-20 obj.ruFig.Position(4)-20], ...
                                      'ColumnName', {getString(message('wlan:waveformGeneratorApp:PowerBoostFactorHeader')), ...
                                                     getString(message('wlan:waveformGeneratorApp:SpatialMappingHeader')), ...
                                                     getString(message('wlan:waveformGeneratorApp:SpatialMappingMatrixHeader')), ...
                                                     getString(message('wlan:waveformGeneratorApp:BeamformHeader')), ...
                                                     getString(message('wlan:waveformGeneratorApp:SizeHeader')), ...
                                                     getString(message('wlan:waveformGeneratorApp:RUIndexHeader')), ...
                                                     getString(message('wlan:waveformGeneratorApp:UsersHeader'))}, ...
                                      'ColumnFormat', {[] {'Direct','Hadamard','Fourier','Custom'} 'char' [] [] [] 'char'},...
                                      'ColumnWidth', columnWidths, ...
                                      'ColumnEditable', true, ...
                                      'Data', ruObj2Table(obj), ...
                                      'CellEditCallback', @obj.ruTableCallback, ...
                                      'RearrangeableColumns', false, ...
                                      'RowStriping', false);
                % Control cell editability and gray color
                obj.ruTable.UserData.isReadOnly = repmat([false(1,3) true true true true],size(obj.ruTable.Data,1),1);
                ruTableCallback(obj);
            end
        end

        function data = ruObj2Table(obj)
            ruCell = obj.configObj.RU;
            data = cell(length(ruCell),7);
            beamforming = false;
            for idx = 1:length(ruCell)
                ruObj = ruCell{idx};
                if ruObj.SpatialMapping==wlan.type.SpatialMapping.custom
                    if strcmp(obj.EHTTransmission,'MU-MIMO')
                        if isscalar(ruObj.SpatialMappingMatrix) && ruObj.SpatialMappingMatrix==1
                            spatialMapMatrix = mat2str(ones(2,2));
                        else
                            % mat2str only works with 2D arrays.
                            % Also wlanEHTRU.SpatialMappingMatrix only accepts numeric
                            % values. So the following is needed:
                            spatialMapMatrix = [ 'reshape(' mat2str(ruObj.SpatialMappingMatrix(:)) ', ' mat2str(size(ruObj.SpatialMappingMatrix)) ')'];
                        end
                    else
                        % uitable cannot accept vector values so it must be converted to string
                        if ndims(ruObj.SpatialMappingMatrix) <= 2
                            spatialMapMatrix = mat2str(ruObj.SpatialMappingMatrix);
                        else
                            spatialMapMatrix = [ 'reshape(' mat2str(ruObj.SpatialMappingMatrix(:)) ', ' mat2str(size(ruObj.SpatialMappingMatrix)) ')'];
                        end
                        beamforming = ruObj.Beamforming;
                        obj.ruTable.UserData.isReadOnly(idx,4) = 0;
                    end
                else
                    spatialMapMatrix = 'N/A';
                end

                spatialMappingChar = char(ruObj.SpatialMapping);
                ruSizeChar = num2str(ruObj.Size);
                ruIndexChar = num2str(ruObj.Index);

                % Check if the ruSize (5th column) or ruIndex (6th column)
                % is a vector, if yes, wrap them with '[' and ']'
                if ~isscalar(ruObj.Size)
                    ruSizeChar = ['[' num2str(ruObj.Size) ']'];
                end

                if ~isscalar(ruObj.Index)
                    ruIndexChar = ['[' num2str(ruObj.Index) ']'];
                end

                data(idx,:) = {ruObj.PowerBoostFactor  [upper(spatialMappingChar(1))  lower(spatialMappingChar(2:end))] spatialMapMatrix  ...
                               beamforming  ruSizeChar ruIndexChar mat2str(ruObj.UserNumbers)};
            end
        end

        function createUserTable(obj)
        %createUserTable creates numUsers x 8 table, where the column labels are
        % given as follows: APEP Length (bytes) | MCS | Space-Time Streams
        % Channel Coding | Station ID | Packet Padding (μs) | RU | PSDU
            if isempty(obj.userTable)
                % Set the column widths using ColumnName property value
                columnWidths = {100 130 110 90, 120, 120, 120, 120};
                obj.userTable = uitable('Parent',obj.userFig, ...
                                        'Position', [10 10 obj.userFig.Position(3)-20 obj.userFig.Position(4)-20], ...
                                        'ColumnName', {getString(message('wlan:waveformGeneratorApp:APEPLengthHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:MCSHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:SpaceTimeStreamsHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:ChannelCodingHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:STAIDHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:PacketPaddingHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:RUHeader')), ...
                                                       getString(message('wlan:waveformGeneratorApp:PSDULengthHeader'))}, ...
                                        'ColumnFormat', {[] {obj.userMCS{1:14} obj.userMCS{16}} {'1', '2','3', '4', '5', '6', '7', '8'} {'LDPC', 'BCC'}, [], {'0', '8', '16'}, [] []},...
                                        'ColumnWidth', columnWidths, ...
                                        'ColumnEditable', true, ...
                                        'Data', userObj2Table(obj), ...
                                        'CellEditCallback', @obj.userTableCallback, ...
                                        'RearrangeableColumns', false, ...
                                        'RowStriping', false);
                % Control cell editability and gray color
                obj.userTable.UserData.isReadOnly = repmat([false(1,6) true true],size(obj.userTable.Data,1),1);
                userTableCallback(obj);
            end
        end

        function rus = ruTable2Obj(obj)
            t = obj.ruTable.Data;
            rus = cell(1,size(t,1));
            for rowIdx = 1:size(t,1) % Loop over the rows of RU Table
                row = t(rowIdx,:);
                % If the row is a vector, strip the '[', ' ', and ']' from ruSize and ruIndex
                ruSize = str2num(erase(row{5},{'[',']'}));
                ruIndex = str2num(erase(row{6},{'[',']'}));
                userNums = str2num(row{7}); %#ok<*ST2NM>
                ru = wlanEHTRU(ruSize,ruIndex,userNums);
                ru.PowerBoostFactor = row{1};
                ru.SpatialMapping = row{2};
                if ~strcmp(row{3},'N/A')
                    ru.SpatialMappingMatrix = str2num(row{3});
                end
                ru.Beamforming = logical(row{4});
                rus{rowIdx} = ru;
            end
        end

        function ruTableCallback(obj,~,~)
            setDirty(obj);
            % Restore cell editability and gray color
            obj.ruTable.UserData.isReadOnly = repmat([false(1,3) true true true true],size(obj.ruTable.Data,1),1);

            % The Size, RU Index, and User(s) columns of the Resource Unit
            % Table are set to read only. The value of these columns are
            % set by the user defined configuration.
            ruTableData = obj.ruTable.Data;
            for idx = 1:size(ruTableData, 1)
                row = ruTableData(idx, :);
                % If SpatialMapping is not Custom make the cell read-only
                if ~strcmpi(row{2},char(wlan.type.SpatialMapping.custom))
                    % Spatial Mapping Matrix
                    ruTableData{idx,3} = 'N/A'; % Spatial Mapping Matrix column is set to 'N/A'
                    ruTableData{idx,4} = false; % Beamform column is set to false
                    obj.ruTable.UserData.isReadOnly(idx,4) = true; % Beamform column is read only
                else % SpatialMapping is Custom
                    if strcmp(row{3},'N/A') % replace the N/A with 1
                        ruTableData{idx,3} = mat2str(obj.configObj.RU{idx}.SpatialMappingMatrix);
                    end
                    if ~strcmp(obj.EHTTransmission,'MU-MIMO')
                        obj.ruTable.UserData.isReadOnly(idx,4) = false; % Beamform column is editable
                    end
                end

                % Error if RU settings invalid
                try
                    % Power boost factor
                    validateattributes(ruTableData{idx,1},{'numeric'},{'scalar','>=',0.5,'<=',2},'','Power boost factor');
                    % Spatial mapping matrix
                    if ~strcmp(ruTableData{idx,3},'N/A')
                        wlan.internal.ehtValidateSpatialMappingMatrix(str2num(ruTableData{idx,3}));
                    end
                catch e
                    obj.errorFromException(e);
                    return
                end
            end

            obj.ruTable.Data = ruTableData;
            obj.configObj.RU = ruTable2Obj(obj);
            % Always call updateTables after the changes are reflected in the config object
            updateTables(obj);
        end

        function data = userObj2Table(obj)
            userCell = obj.configObj.User;
            ruCell = obj.configObj.RU;
            data = cell(length(userCell),8);
            psduLens = obj.configObj.psduLength;
            for idx = 1:length(userCell) % Loop over each user in the config object
                userObj = userCell{idx};
                ruObj = ruCell{userObj.RUNumber};
                mcs = obj.userMCS(startsWith(obj.userMCS, [num2str(userObj.MCS) ' ']));
                data(idx,:) = {userObj.APEPLength  mcs{:} num2str(userObj.NumSpaceTimeStreams) ...
                               upper(char(userObj.ChannelCoding)) userObj.STAID  userObj.NominalPacketPadding userObj.RUNumber psduLens(idx)}; %#ok<CCAT>

                if userObj.NumSpaceTimeStreams>=5 || any(ruObj.Size>242)
                    obj.userTable.UserData.isReadOnly(idx,4) = 1;
                end

                if any(strcmp(mcs,{'14 (BPSK-DCM, 1/2 rate)','15 (BPSK-DCM, 1/2 rate)'}))
                    obj.userTable.UserData.isReadOnly(idx,3) = 1;
                end
            end
        end

        function userTableCallback(obj, ~, ~)

            setDirty(obj);
            % Restore cell editability and gray color
            obj.userTable.UserData.isReadOnly = repmat([false(1,6) true true],size(obj.userTable.Data,1),1);

            % The Size and PSDU Length(bytes) columns of User Table are set
            % to read only. The value of these columns are set by the user
            % defined configuration.
            userTableData = obj.userTable.Data; % Correct read-only values
            for idx = 1:size(userTableData,1)
                row = userTableData(idx, :);
                numSTstreams = str2double(row{3});
                mcs = row{2};
                ruSize = obj.configObj.RU{row{7}}.Size;
                if numSTstreams > 4 || any(strcmp(mcs,obj.userMCS([11 12 13 14]))) || any(ruSize>242)
                    userTableData(idx,4) = {'LDPC'};
                    obj.userTable.UserData.isReadOnly(idx,4) = true; % ChannelCoding column is set to read only
                end

                if any(strcmp(mcs,obj.userMCS([15 16])))
                    userTableData(idx,3) = {'1'}; % Space-Time Streams should be 1 for MCS 14/15
                    obj.userTable.UserData.isReadOnly(idx,3) = true; % Space-Time Streams column is set to read only
                end

                % Error if User settings invalid
                if ~strcmp(obj.EHTTransmission,'Sounding NDP')
                    try
                        validateattributes(userTableData{idx,5},{'numeric'},{'integer','scalar','>=',0,'<=',2047},'','Station ID'); % Station ID
                        validateattributes(userTableData{idx,1},{'numeric'},{'integer','scalar','>=',1,'<=',15523198},'','APEP length'); % APEPLength
                    catch e
                        obj.errorFromException(e);
                        return
                    end
                else
                    try
                        validateattributes(userTableData{idx,5},{'numeric'},{'integer','scalar','>=',0,'<=',2047},'','Station ID'); % Station ID
                    catch e
                        obj.errorFromException(e);
                        return
                    end
                end
            end

            if obj.configObj.EHTDUPMode
                userTableData(idx,2) = obj.userMCS(15); % MCS is set to 15
                userTableData(idx,3) = {'1'}; % Space-Time Streams is 1
                obj.userTable.UserData.isReadOnly(idx,2:3) = true; % MCS and Space-Time Streams columns are set to read only
            end

            if strcmp(obj.EHTTransmission,'Sounding NDP')
                obj.userTable.UserData.isReadOnly(idx,1) = true; % APEP Length(bytes) column is set to read only
            end

            obj.userTable.Data = userTableData;
            obj.configObj.User = userTable2Obj(obj);
            % Always call updateTables after the changes are reflected in the config object
            try
                updateTables(obj); % Update PSDU length
            catch exc % In case the number of space-time streams is invalid for MU-MIMO
                obj.errorFromException(exc);
            end
        end

        function updateTables(obj)
            if ~isempty(obj.ruTable)
                obj.ruTable.Data = ruObj2Table(obj);
                updateReadOnlyCellsStyle(obj,obj.ruTable); % Update RU table styles
            end

            if ~isempty(obj.userTable)
                obj.userTable.Data = userObj2Table(obj);
                updateReadOnlyCellsStyle(obj,obj.userTable); % Update User table styles
            end

            customVisualizations(obj); % Update RU allocation plot
        end

        function users = userTable2Obj(obj)
            t = obj.userTable.Data;
            users = cell(1, size(t,1));
            for rowIdx = 1:size(t,1) % Loop over the rows of User Table
                row = t(rowIdx, :);
                ruNumber = row{7};
                user = wlanEHTUser(ruNumber);
                user.APEPLength = row{1};
                mcsStr = row{2};
                spaceIdx = strfind(mcsStr,' ');
                user.MCS = str2double(mcsStr(1:spaceIdx(1)-1));
                user.NumSpaceTimeStreams  = str2double(row{3});
                user.ChannelCoding = row{4};
                user.STAID = row{5};
                user.NominalPacketPadding = row{6};
                % When creating a wlanEHTMUConfig object, by default the
                % PostFECPaddingSeed of each user is set to the user number - do
                % the same here.
                user.PostFECPaddingSeed = rowIdx;
                users{rowIdx} = user;
            end
        end

        function cleanupDlg(obj)
        % Dialog-specific cleanup when app is closing. Custom WLAN UL has
        % additional UI objects that need deletion when the app is closing.
            delete([obj.ruFig; obj.userFig])
        end

        %% Call backs
        function ehtFormatChangedGUI(obj)
            appObj = obj.Parent.WaveformGenerator;
            freezeApp(appObj);

            switch obj.EHTPPDUFormat
              case 'EHT MU'
                if strcmp(obj.EHTTransmission,'EHT SU')
                    className = 'wirelessWaveformGenerator.wlanEHTSUDialog';
                elseif strcmp(obj.EHTTransmission,'MU-MIMO')
                    className = 'wirelessWaveformGenerator.wlanEHTMUMIMODialog';
                elseif strcmp(obj.EHTTransmission,'OFDMA')
                    className = 'wirelessWaveformGenerator.wlanEHTOFDMADialog';
                elseif strcmp(obj.EHTTransmission,'Sounding NDP')
                    className = 'wirelessWaveformGenerator.wlanEHTSoundingNDPDialog';
                end
              otherwise % EHT TB
                className = 'wirelessWaveformGenerator.wlanEHTTBDialog';
            end

            if ~isempty(appObj) && ~strcmp(className, class(appObj.pParameters.CurrentDialog))
                % Initialization has completed
                appObj.setParametersDialog(className);
            end

            currDialog = obj.Parent.CurrentDialog;
            currDialog.EHTPPDUFormat = obj.EHTPPDUFormat;
            initConfig(currDialog); % initialize the configuration for the given PPDU or transmission

            currDialog.layoutUIControls();
            obj.layoutPanels();

            unfreezeApp(appObj);
        end

        function numUsersChanged(obj,~)
            initConfig(obj);

            % Don't try to update the tables if the PPDU format is EHT TB
            if strcmp(obj.EHTPPDUFormat,'EHT MU')
                updateTables(obj);
                userTableCallback(obj);
            end
        end

        function channelBandwidthChangedGUI(obj)
            channelBandwidthChanged(obj);
            obj.layoutUIControls();
        end

        function channelBandwidthChanged(obj,~)
            if strcmp(obj.EHTPPDUFormat,'EHT MU')
                % PuncturedChannelFieldValue is only applicable to CBW80,
                % CBW160, and CBW320.
                %
                % The current behavior is to restore the
                % PuncturedChannelFieldValue to default if the channel
                % bandwidth value changes.
                if strcmp(obj.ChannelBandwidth, 'CBW20') || strcmp(obj.ChannelBandwidth, 'CBW40')
                    obj.PuncturedChannelFieldValue = 0;
                end

                % PreEHTPhaseRotation is only applicable to CBW320. Do not
                % force it to the object for other bandwidth values.
                %
                % The current behavior is to store the user-entered
                % PreEHTPhaseRotation value and reload it when coming back
                % from any channel bandwidth value other than CBW320.
                if strcmp(obj.ChannelBandwidth, 'CBW320')
                    % Load the PreEHTPhaseRotation when returning to
                    % CBW320, if not the first time.
                    if ~isempty(obj.PreEHTPhaseRotationGUI.UserData)
                        obj.PreEHTPhaseRotation = obj.PreEHTPhaseRotationGUI.UserData;
                    end
                else
                    % Save the PreEHTPhaseRotation when leaving CBW320
                    obj.PreEHTPhaseRotationGUI.UserData = obj.PreEHTPhaseRotation;

                    % Set PreEHTPhaseRotation to the default
                    obj.PreEHTPhaseRotation = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1];
                end

                updatePuncturedChannelFieldValues(obj);
                if ~obj.EHTDUPMode
                    data = obj.userTable.Data;
                    data(1,2) = obj.userMCS(1); % Set the MCS to default so the object is in working state
                    obj.userTable.Data = data;
                end

                initConfig(obj);
                updateTables(obj);
                userTableCallback(obj);
                ruTableCallback(obj);
                channelBandwidthChanged@wirelessWaveformGenerator.wlanEHTDialog(obj,[]);
            else % EHT TB
                initConfig(obj);
                customVisualizations(obj); % Update RU & Subcarrier Assignment plot
                channelBandwidthChanged@wirelessWaveformGenerator.wlanEHTDialog(obj,[]);
            end
        end

        function ehtDUPModeChangedGUI(obj)
            % Freeze/unfreeze the app, this should reduce the probability of
            % changing 'Punctured channel field' when 'EHT-DUP mode' is set.
            obj.Parent.AppObj.freezeApp;
            channelBandwidthChanged(obj);
            dupModeChanged(obj);
            userTableCallback(obj);
            obj.Parent.AppObj.unfreezeApp
        end

        function puncturedChannelFieldValueChangedGUI(obj)
            initConfig(obj);
            updateTables(obj);
        end

        %% Exclude properties from the config object
        function props = props2ExcludeFromConfig(obj)
            props = props2ExcludeFromConfig@wirelessWaveformGenerator.wlanVHTDialog(obj);
            props = [props {'EHTPPDUFormat','EHTTransmission','CompressionMode'}];
        end

        function props = props2ExcludeFromConfigGeneration(obj)
        % Return a cell array of properties which should not be "set" using
        % NV pairs when configuring the object in the generated MATLAB
        % script

            props = props2ExcludeFromConfigGeneration@wirelessWaveformGenerator.wlanVHTDialog(obj);
            props = [props {'EHTPPDUFormat','EHTTransmission','CompressionMode'}];

            if ~obj.isCyclicShiftsVisible()
                props = [props 'PreEHTCyclicShifts'];
            end
        end

        %% Set graphical elements
        function adjustSpec(obj)
        %adjustSpec Change graphical elements before creating them which are different than superclass defaults (e.g Non-HT)

            adjustSpec@wirelessWaveformGenerator.wlanEHTDialog(obj);
            obj.TitleString = getString(message('wlan:waveformGeneratorApp:EHTTitle')); % Set EHT title for the property defined in the superclass
            obj.ChannelBandwidthDropDown = {'20 MHz','40 MHz','80 MHz','160 MHz','320 MHz'};
            miS = [' ' char(956) 's'];
            obj.GuardIntervalDropDown = {['0.8' miS], ['1.6' miS], ['3.2' miS]};
        end

        function setupDialog(obj)
            obj.setExtraConfigFigVisibility(true);
            setupDialog@wirelessWaveformGenerator.wlanAdvancedFormatsDialog(obj);
            obj.EHTPPDUFormat = 'EHT MU'; % In case we return to 11ax, after it was set to MU and the user left 11ax
        end

        %% Set object properties and defaults
        function restoreDefaults(obj)
        %restoreDefaults Restore to default value at setup

        % Set defaults of dependent properties
            restoreDefaults@wirelessWaveformGenerator.wlanEHTDialog(obj); % Restore default of common properties in EHT
            obj.NumTransmitAntennas = 1;
            obj.PreEHTCyclicShifts = -75;
            obj.PreEHTPhaseRotation = [1 -1 -1 -1 1 -1 -1 -1 -1 1 1 1 -1 1 1 1];
            obj.TXOPDuration = -1;
            obj.GuardInterval = '3.2';
            obj.EHTLTFType = '4x';
            obj.NumExtraEHTLTFSymbols = 0;
            obj.EHTSIGMCS = 0;
            obj.Channelization = '320 MHz-1';
            obj.CompressionMode = obj.configObj.compressionMode;

            if ~isempty(obj.userTable) && ~obj.EHTDUPMode
                obj.userTable.UserData.isReadOnly(1,2:3) = false;
                dupModeChanged(obj);
                updateReadOnlyCellsStyle(obj,obj.userTable);
            end
        end

        function config = getConfiguration(obj)
        %getConfiguration Get object configuration

        % Here, superclass method does not apply because configuration object needs input arguments
            initConfig(obj);
            config = obj.configObj;

            % Don't generate RU and User tables if the PPDU format is EHT TB
            if strcmp(obj.EHTPPDUFormat,'EHT MU')
                if ~isempty(obj.ruTable)
                    config.RU = ruTable2Obj(obj);
                end
                if ~isempty(obj.userTable)
                    config.User = userTable2Obj(obj);
                end

                config.EHTSIGMCS             = obj.EHTSIGMCS;
                config.UplinkIndication      = obj.UplinkIndication;
                config.SpatialReuse          = obj.SpatialReuse;
                config.NumExtraEHTLTFSymbols = obj.NumExtraEHTLTFSymbols;
                config.BSSColor              = obj.BSSColor;
                config.TXOPDuration          = obj.TXOPDuration;
                config.Channelization        = obj.Channelization;
            else % EHT TB
                % Update the main dialog parameters
                config.RUSize                   = obj.EHTTBRUSize;
                config.RUIndex                  = obj.EHTTBRUIndex;
                config.PreEHTPowerScalingFactor = obj.PreEHTPowerScalingFactor;
                config.NumSpaceTimeStreams      = obj.NumSpaceTimeStreams;
                config.StartingSpaceTimeStream  = obj.EHTTBStartingSpaceTimeStream;
                config.SpatialMapping           = obj.SpatialMapping;
                config.SpatialMappingMatrix     = obj.SpatialMappingMatrix;
                config.MCS                      = obj.MCS;
                config.ChannelCoding            = obj.ChannelCoding;
                config.PreFECPaddingFactor      = obj.EHTTBPreFECPaddingFactor;
                config.LDPCExtraSymbol          = obj.EHTTBLDPCExtraSymbol;
                config.PEDisambiguity           = obj.EHTTBPEDisambiguity;
                config.LSIGLength               = obj.EHTTBLSIGLength;
                config.NumEHTLTFSymbols         = obj.EHTTBNumEHTLTFSymbols;

                % Update the `Advanced Parameters` dialog parameters
                if isKey(obj.Parent.AppObj.pParameters.DialogsMap, obj.nameAdvDlg)
                    dlgAP = obj.Parent.AppObj.pParameters.DialogsMap(obj.nameAdvDlg);
    
                    % Need to Update the advanced parameters, the remaining
                    % properties under advanced parameters are updated in
                    % getConfiguration method of wlanEHTBaseDialog
                    config.BSSColor           = dlgAP.BSSColor;
                    config.SpatialReuse1      = dlgAP.EHTTBSpatialReuse1;
                    config.SpatialReuse2      = dlgAP.EHTTBSpatialReuse2;
                    config.TXOPDuration       = dlgAP.TXOPDuration;
                    config.Channelization     = dlgAP.Channelization;
                    config.DisregardBitsUSIG1 = int8(dlgAP.EHTTBDisregardBitsUSIG1);
                    config.DisregardBitsUSIG2 = int8(dlgAP.EHTTBDisregardBitsUSIG2);
                    config.ValidateBitUSIG2   = int8(dlgAP.EHTTBValidateBitUSIG2);
                end
            end
            % Shared parameters
            config.NumTransmitAntennas   = obj.NumTransmitAntennas;
            config.PreEHTCyclicShifts    = obj.PreEHTCyclicShifts;
            config.EHTLTFType            = obj.EHTLTFType;
            config.GuardInterval         = obj.GuardInterval;
            config.PreEHTPhaseRotation   = obj.PreEHTPhaseRotation;

            obj.configObj = config; % Update object with the updated parameters and table entries
        end

        function pLen = getPSDULength(obj)
        % Fetch PSDU length from the config object
            cfg = obj.getConfiguration;
            pLen = cfg.psduLength();
        end

        function updateConfigFcn(obj)
        % Get the config object function
            switch obj.EHTPPDUFormat
              case 'EHT MU'
                % Default config object handles for EHT MU PPDU formats
                obj.configFcn = @wlanEHTMUConfig; % Get the handle of the config object for interaction
                obj.configGenFcn = @wlanEHTMUConfig; % Get the handle of the config object for generation

                if strcmp(obj.EHTTransmission,'EHT SU')
                    obj.configGenVar = 'ehtSUCfg';
                elseif strcmp(obj.EHTTransmission,'MU-MIMO')
                    obj.configGenVar = 'ehtMUMIMOCfg';
                elseif strcmp(obj.EHTTransmission,'OFDMA')
                    obj.configGenVar = 'ehtOFDMACfg';
                elseif strcmp(obj.EHTTransmission,'Sounding NDP')
                    obj.configGenVar = 'ehtNDPCfg';
                end
              otherwise % EHT TB
                        % Overwrite the config object handles if EHT TB PPDU format is
                        % selected
                obj.configGenVar = 'ehtTBCfg';
                obj.configFcn = @wlanEHTTBConfig; % Get the handle of the config object for interaction
                obj.configGenFcn = @wlanEHTTBConfig; % Get the handle of the config object for generation
            end
        end

        function updatePSDU(obj)
        %updatePSDU Update PSDU length
            try
                obj.PSDULength = obj.psduLength();
            catch
                % in case the object is still initializing and PSDU cannot be calculated
            end
        end

        function psduLen = psduLength(obj)
        %psduLength Get PSDULength

            cfg = obj.getConfiguration; % Get the object configuration
            psduLen = cfg.psduLength();
        end

        %% MATLAB code generation
        function str = psduGetterStr(~,cfgStr)
        %psduGetterStr Get the method name for PSDULength in 11be used for MATLAB and Simulink code generation

            str = ['psduLength(' cfgStr ')'];
        end

        %% Get and Set method for the dependent properties
        function set.CompressionMode(obj,val)
        % Display the CompressionMode value, which doesn't require a get
        % method since it will not be used in waveform generation
            setTextVal(obj,'CompressionMode',val)
        end

        function n = get.EHTDUPMode(obj)
            if any(strcmp(obj.ChannelBandwidth,{'CBW20','CBW40'}))
                n = 0; % EHTDUPMode is not applicable for CBW20 and CBW80
            else
                n = getCheckboxVal(obj,'EHTDUPMode');
            end
        end

        function set.EHTDUPMode(obj, val)
            setCheckboxVal(obj,'EHTDUPMode',val);
        end

        function n = get.PuncturedChannelFieldValue(obj)
            v = getDropdownVal(obj,'PuncturedChannelFieldValue');
            if strcmp(obj.ChannelBandwidth,'CBW80')
                n = str2double(v(1));
            elseif any(strcmp(obj.ChannelBandwidth,{'CBW160','CBW320'}))
                n = str2double(v(1:2));
            else
                n = 0;
            end
        end

        function set.PuncturedChannelFieldValue(obj,val)
            setDropdownVal(obj,'PuncturedChannelFieldValue',obj.PuncturedChannelFieldValueGUI.Items{val+1});
        end

        function n = get.EHTLTFType(obj)
            n = getDropdownVal(obj,'EHTLTFType');
            n = str2double(erase(n,'x'));
        end

        function set.EHTLTFType(obj,val)
            setDropdownStartingVal(obj,'EHTLTFType',num2str(val(1)));
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

        function n = getGuardInterval(obj)
            n = getGuardInterval@wirelessWaveformGenerator.wlanVHTDialog(obj);
            % remove the microsecond unit
            n = str2double(n(1:3));
        end

        function setGuardInterval(obj, val)
        % add the microsecond unit:
            mi = char(956);
            val = [num2str(val) ' ' mi 's'];
            setDropdownVal(obj, 'GuardInterval', val);
        end

        %% Dialog layout
        function cols = getNumTileColumns(~,~)
            cols = 2;
        end

        function rows = getNumTileRows(~,~)
            rows = 3;
        end

        function tiles = getNumTiles(~,~)
            tiles = 1 + 3; % 1 for config, 2 for tables and 1 for all visuals
        end

        function n = numVisibleFigs(obj)
            n = numVisibleFigs@wirelessWaveformGenerator.wlanEHTDialog(obj);
            n = n + 2; % 1 for RU table + 1 for User table
        end

        function [tileCount,tileCoverage,tileOccupancy] = getTileLayout(obj, ~)

            appObj = obj.Parent.WaveformGenerator;
            numTableTiles = 2;
            tileCount = numTableTiles + (obj.getVisualState('RU & Subcarrier Assignment') || appObj.pPlotSpectrum || appObj.pPlotTimeScope || appObj.pPlotCCDF);

            tileCoverage = (1:tileCount)';

            tileOccupancy = repmat(struct('children', []), tileCount, 1);

            % RU Table
            tileID = 1;
            documentID = ['waveformGeneratorDocumentGroup_' obj.ruFigTag];
            str = struct('showOrder', 1, 'id', documentID);
            tileOccupancy(tileID).children = [tileOccupancy(tileID).children str];
            tileOccupancy(tileID).showingChildId = documentID;

            % User Table
            tileID = tileID + 1;
            documentID = ['waveformGeneratorDocumentGroup_' obj.userFigTag];
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

        %% Export to MATLAB script
        function addConfigCode(obj, sw)
        % Add configuration code when exporting to MATLAB script

            if strcmp(obj.EHTPPDUFormat,'EHT MU')
                % Constructor
                if strcmp(obj.EHTTransmission,'OFDMA')
                    if obj.IsSameEHTSignalling
                        % Create allocation index matrix from a 1x16 vector
                        if strcmp(obj.ChannelBandwidth,'CBW160')
                            add(sw,[obj.configGenVar ' = wlanEHTMUConfig(' mat2str(repmat(obj.EHTAllocationIndex,2,1))]);
                        else % CBW320
                            add(sw,[obj.configGenVar ' = wlanEHTMUConfig(' mat2str(repmat(obj.EHTAllocationIndex,4,1))]);
                        end
                    else % IsSameEHTSignalling unchecked
                        add(sw,[obj.configGenVar ' = wlanEHTMUConfig(' mat2str(obj.EHTAllocationIndex)]);
                    end
                else
                    add(sw,[obj.configGenVar ' = wlanEHTMUConfig(''' obj.ChannelBandwidth ''', ''NumUsers'', ',num2str(obj.NumUsers) ', ''PuncturedChannelFieldValue'', ',num2str(obj.PuncturedChannelFieldValue) ', ''EHTDUPMode'', ',num2str(obj.EHTDUPMode)]);
                end
                addcr(sw, ', ...');

                % Top-level properties:
                addcr(sw, ['''NumTransmitAntennas'', '  num2str(obj.NumTransmitAntennas) ', ...']);
                if obj.isCyclicShiftsVisible()
                    addcr(sw,['''PreEHTCyclicShifts'', '  obj.PreEHTCyclicShiftsGUI.(obj.EditValue) ', ...']);
                end
                isCBW320 = strcmp(obj.ChannelBandwidth,'CBW320');
                if isCBW320
                    addcr(sw,['''PreEHTPhaseRotation'', '  obj.PreEHTPhaseRotationGUI.(obj.EditValue) ', ...']);
                end
                addcr(sw, ['''GuardInterval'', '         num2str(obj.GuardInterval) ', ...']);
                addcr(sw, ['''EHTLTFType'', '            num2str(obj.EHTLTFType) ', ...']);
                addcr(sw, ['''NumExtraEHTLTFSymbols'', ' num2str(obj.NumExtraEHTLTFSymbols) ', ...']);
                addcr(sw, ['''EHTSIGMCS'', '             num2str(obj.EHTSIGMCS) ', ...']);
                addcr(sw, ['''UplinkIndication'', '      num2str(obj.UplinkIndication) ', ...']);
                addcr(sw, ['''BSSColor'', '              num2str(obj.BSSColor) ', ...']);
                addcr(sw, ['''SpatialReuse'', '          num2str(obj.SpatialReuse) ', ...']);


                if isCBW320
                    if isempty(obj.TXOPDuration)
                        addcr(sw,['''TXOPDuration'', '  '[]' ', ...']);
                    else
                        addcr(sw,['''TXOPDuration'', '  num2str(obj.TXOPDuration) ', ...']);
                    end
                    add(sw,['''Channelization'', '   num2str(obj.Channelization)]);
                else
                    if isempty(obj.TXOPDuration)
                        addcr(sw,['''TXOPDuration'', '  '[]' ' ...']);
                    else
                        add(sw,['''TXOPDuration'', '   num2str(obj.TXOPDuration)]);
                    end
                end

                addcr(sw, ');');
                addcr(sw, '');

                % RU config properties:
                addcr(sw, ['% ' getString(message('wlan:waveformGeneratorApp:RUConfigComment'))]);
                ruObjs = ruTable2Obj(obj);
                for idx = 1:length(ruObjs)
                    addcr(sw,[obj.configGenVar '.RU{' num2str(idx) '}.PowerBoostFactor = '   num2str(ruObjs{idx}.PowerBoostFactor) ';']);
                    addcr(sw,[obj.configGenVar '.RU{' num2str(idx) '}.SpatialMapping = '''   char(ruObjs{idx}.SpatialMapping) ''';']);
                    if ruObjs{idx}.SpatialMapping==wlan.type.SpatialMapping.custom
                        if ndims(ruObjs{idx}.SpatialMappingMatrix) <= 2
                            addcr(sw,[obj.configGenVar '.RU{' num2str(idx) '}.SpatialMappingMatrix = '   mat2str(ruObjs{idx}.SpatialMappingMatrix) ';']);
                        else
                            % mat2str only works with 2D arrays.
                            addcr(sw,[obj.configGenVar '.RU{' num2str(idx) '}.SpatialMappingMatrix = reshape(' mat2str(ruObjs{idx}.SpatialMappingMatrix(:)) ', ' mat2str(size(ruObjs{idx}.SpatialMappingMatrix)) ');']);
                        end
                        addcr(sw,[obj.configGenVar '.RU{' num2str(idx) '}.Beamforming = '            num2str(ruObjs{idx}.Beamforming) ';']);
                    end
                end
                addcr(sw, '');

                % User config properties:
                addcr(sw,['% ' getString(message('wlan:waveformGeneratorApp:UserConfigComment'))]);
                userObjs = userTable2Obj(obj);
                for idx = 1:length(userObjs)
                    addcr(sw,[obj.configGenVar '.User{' num2str(idx) '}.APEPLength = '           num2str(userObjs{idx}.APEPLength) ';']);
                    addcr(sw,[obj.configGenVar '.User{' num2str(idx) '}.MCS = '                  num2str(userObjs{idx}.MCS) ';']);
                    addcr(sw,[obj.configGenVar '.User{' num2str(idx) '}.NumSpaceTimeStreams = '  num2str(userObjs{idx}.NumSpaceTimeStreams) ';']);
                    addcr(sw,[obj.configGenVar '.User{' num2str(idx) '}.ChannelCoding = '''      char(userObjs{idx}.ChannelCoding) ''';']);
                    addcr(sw,[obj.configGenVar '.User{' num2str(idx) '}.STAID = '                num2str(userObjs{idx}.STAID) ';']);
                    addcr(sw,[obj.configGenVar '.User{' num2str(idx) '}.NominalPacketPadding = ' num2str(userObjs{idx}.NominalPacketPadding) ';']);
                end
                addcr(sw,'');
            else % EHT TB
                 % Constructor
                add(sw,[obj.configGenVar ' = wlanEHTTBConfig(''', 'ChannelBandwidth'', ''', obj.ChannelBandwidth, ''', ...']);
                addcr(sw, ''); % linebreak
                if isscalar(obj.EHTTBRUSize)
                    addcr(sw, ['''RUSize'', ', num2str(obj.EHTTBRUSize), ', ...']);
                else
                    addcr(sw, ['''RUSize'', [', num2str(obj.EHTTBRUSize), '], ...']);
                end
                if isscalar(obj.EHTTBRUIndex)
                    addcr(sw, ['''RUIndex'', ', num2str(obj.EHTTBRUIndex), ', ...']);
                else
                    addcr(sw, ['''RUIndex'', [', num2str(obj.EHTTBRUIndex), '], ...']);
                end
                addcr(sw, ['''PreEHTPowerScalingFactor'', ', num2str(obj.PreEHTPowerScalingFactor), ', ...']);
                addcr(sw, ['''NumTransmitAntennas'', ', num2str(obj.NumTransmitAntennas), ', ...']);
                if obj.isCyclicShiftsVisible()
                    addcr(sw,['''PreEHTCyclicShifts'', '  obj.PreEHTCyclicShiftsGUI.(obj.EditValue), ', ...']);
                end
                addcr(sw, ['''NumSpaceTimeStreams'', ', num2str(obj.NumSpaceTimeStreams), ', ...']);
                addcr(sw, ['''StartingSpaceTimeStream'', ', num2str(obj.EHTTBStartingSpaceTimeStream), ', ...']);
                addcr(sw, ['''SpatialMapping'', ''', char(obj.SpatialMapping), ''', ...']);
                if strcmp(obj.SpatialMapping,'Custom')
                    addcr(sw, ['''SpatialMappingMatrix'', ', num2str(obj.SpatialMappingMatrix), ', ...']);
                end
                if strcmp(obj.ChannelBandwidth,'CBW320')
                    addcr(sw,['''PreEHTPhaseRotation'', '  obj.PreEHTPhaseRotationGUI.(obj.EditValue) ', ...']);
                end
                addcr(sw, ['''MCS'', ', num2str(obj.MCS), ', ...']);
                addcr(sw, ['''ChannelCoding'', ''', char(obj.ChannelCoding ), ''', ...']);
                addcr(sw, ['''PreFECPaddingFactor'', ', num2str(obj.EHTTBPreFECPaddingFactor), ', ...']);
                if strcmp(obj.ChannelCoding,'LDPC')
                    addcr(sw, ['''LDPCExtraSymbol'', ', num2str(obj.EHTTBLDPCExtraSymbol), ', ...']);
                end
                addcr(sw, ['''PEDisambiguity'', ', num2str(obj.EHTTBPEDisambiguity ), ', ...']);
                addcr(sw, ['''LSIGLength'', ', num2str(obj.EHTTBLSIGLength), ', ...']);
                addcr(sw, ['''GuardInterval'', ', num2str(obj.GuardInterval), ', ...']);
                addcr(sw, ['''EHTLTFType'', ', num2str(obj.EHTLTFType), ', ...']);
                addcr(sw, ['''NumEHTLTFSymbols'', ', num2str(obj.EHTTBNumEHTLTFSymbols), ', ...']);
                addcr(sw, ['''BSSColor'', ', num2str(obj.BSSColor), ', ...']);
                addcr(sw, ['''SpatialReuse1'', ', num2str(obj.EHTTBSpatialReuse1), ', ...']);
                addcr(sw, ['''SpatialReuse2'', ', num2str(obj.EHTTBSpatialReuse2), ', ...']);
                addcr(sw,['''TXOPDuration'', '   num2str(obj.TXOPDurationGUI.(obj.EditValue)), ', ...']);
                if strcmp(obj.ChannelBandwidth,'CBW320')
                    addcr(sw,['''Channelization'', '   num2str(obj.Channelization), ', ...']);
                end
                addcr(sw,['''DisregardBitsUSIG1'', ['   num2str(obj.EHTTBDisregardBitsUSIG1), '], ...']);
                addcr(sw,['''DisregardBitsUSIG2'', ['   num2str(obj.EHTTBDisregardBitsUSIG2), '], ...']);
                add(sw,['''ValidateBitUSIG2'', '   num2str(obj.EHTTBValidateBitUSIG2)]);
                addcr(sw, ');');
                addcr(sw, '');
            end
        end

        %% Export to Simulink
        function str = getIconDrawingCommand(obj)
        %getIconDrawingCommand Export to Simulink

            str = ['disp([''Format: ' obj.EHTPPDUFormat ''' newline ...' newline ...
                   '''Transmission type: ' obj.EHTTransmission ''' newline ...' newline ...
                   '''Bandwidth: '' strrep(' obj.configGenVar '.ChannelBandwidth,''CBW'','''') '' MHz '' newline ...' newline ...
                   '''Users: '' num2str(' obj.configGenVar '.ruInfo.NumUsers) newline ...' newline ...
                   '''RUs: '' num2str(' obj.configGenVar '.ruInfo.NumRUs) newline ...' newline ...
                   '''Packets: '' num2str(numPackets) ]);'];
        end

        %% Load session
        function config = applyConfiguration(obj,config)
        %applyConfiguration Called when a session is loaded and a configuration is applied to the GUI

            appObj = obj.Parent.WaveformGenerator;
            if isa(config,'wlanEHTMUConfig')
                switch config.compressionMode
                  case 0 % OFDMA
                    appObj.setParametersDialog('wirelessWaveformGenerator.wlanEHTOFDMADialog');
                  case 1 % EHT SU or Sounding NDP
                    if config.User{1}.APEPLength==0
                        appObj.setParametersDialog('wirelessWaveformGenerator.wlanEHTSoundingNDPDialog');
                    else
                        appObj.setParametersDialog('wirelessWaveformGenerator.wlanEHTSUDialog');
                    end
                  case 2 % MU-MIMO
                    appObj.setParametersDialog('wirelessWaveformGenerator.wlanEHTMUMIMODialog');
                end
            else % wlanEHTTBConfig
                appObj.setParametersDialog('wirelessWaveformGenerator.wlanEHTTBDialog');
            end

            currDialog = obj.Parent.CurrentDialog;
            applyConfiguration@wirelessWaveformGenerator.WaveformConfigurationDialog(currDialog,config);

            % Update the visibility and forced values of GUI elements when configuration loaded
            updateDialogFromConfig(currDialog,config);
        end

        function updateReadOnlyCellsStyle(obj,tables)
        % Update the style of read-only cells for the specified table by
        % following these steps:
        % 1. Clear out the existing styles that might have been previous
        %    applied to the cells of the specified table
        % 2. Apply the style to the now clean table
            resetTableStyle(obj,tables);
            setReadOnlyCellsStyle(obj,tables);
        end

        function updateCyclicShifts(obj)
        % Update cyclic shift GUI based on dependent properties. This method
        % should be overloaded by each transmission format and called by each
        % dependent property change method, i.e. numTransmitAntennasChanged.
        % isCyclicShiftsVisible() is implemented by SU and MU dialogs as
        % conditions different for each
            [isVis,numTxThresh] = obj.isCyclicShiftsVisible();
            if isVis
                % Create a vector of cyclic shifts per antenna to prompt the user
                obj.PreEHTCyclicShiftsGUI.(obj.EditValue) = ['[' num2str(-75*ones(1,obj.NumTransmitAntennas-numTxThresh)) ']'];
                setVisible(obj,{'PreEHTCyclicShifts'},true);
            else
                setVisible(obj,{'PreEHTCyclicShifts'},false);
            end
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

        function dupModeChanged(obj)
            if ~obj.EHTDUPMode
                data = obj.userTable.Data;
                data(1,2) = obj.userMCS(1); % Set the MCS so the object is in working state
                obj.userTable.Data = data;
            end
        end

        function flag = isCBWAbove40MHz(obj)
            switch obj.ChannelBandwidth
              case {'CBW80','CBW160','CBW320'}
                flag = true;
              otherwise
                flag = false;
            end
        end

        function preEHTPhaseRotationChangedGUI(obj)
            validatePreEHTPhaseRotationGUIValue(obj);
        end

        function updatePuncturedChannelFieldValues(obj)
            items = obj.PuncturedChannelFieldValueDropDown;

            switch obj.ChannelBandwidth
              case 'CBW80'
                puncturedChannelFieldVal = items(1:5);
                puncturedChannelFieldValDUPMode = items(1);
              case 'CBW160'
                puncturedChannelFieldVal = items(6:18);
                puncturedChannelFieldValDUPMode = items(6);
              otherwise % 320 MHz (and for CBW20/40 EHT DUP mode is not applicable)
                puncturedChannelFieldVal = items(19:end);
                puncturedChannelFieldValDUPMode = items(19);
            end

            if obj.EHTDUPMode
                obj.PuncturedChannelFieldValueGUI.Items = puncturedChannelFieldValDUPMode;
            else
                obj.PuncturedChannelFieldValueGUI.Items = puncturedChannelFieldVal;
            end
        end
    end

    methods (Access = private)
        function preEHTCyclicShiftsChangedGUI(obj)
        % Independent validation of GUI element value
            try
                obj.validateCyclicShiftGUIValue(obj.PreEHTCyclicShifts,'Pre-EHT cyclic shifts');
            catch e
                obj.errorFromException(e);
            end
        end

        function validatePreEHTPhaseRotationGUIValue(obj)
        % Independent validation of GUI element value
            try
                validateattributes(obj.PreEHTPhaseRotation,{'numeric'},{'row','nonempty','real','size',[1 16]},'','Pre-EHT rotation coefficients');
            catch e
                obj.errorFromException(e);
            end
        end

        function numExtraEHTLTFSymbolsGUI(obj)
        % Independent validation of GUI element value
            try
                config = getConfiguration(obj);
                wlan.internal.validateNumExtraEHTLTFSymbols(config);
            catch e
                obj.errorFromException(e);
            end
        end

        function setReadOnlyCellsStyle(obj,table)
        % Set the style and behavior of read-only cells for the specific table

        % Find read-only cells and set the styles
            [row,col] = find(table.UserData.isReadOnly);
            addStyle(table,obj.ReadOnlyCellStyle,'cell',[row(:),col(:)]); % Gray out read-only cells
            addStyle(table,obj.ReadOnlyCellBehavior,'cell',[row(:),col(:)]); % Make read-only cells non-editable
        end

        function resetTableStyle(~,table)
        % Remove the format of the cell within a Table
            removeStyle(table);
        end

        function txopDurationChangedGUI(obj,~)
        % Independent validation of GUI element value
            try
                validateTXOPDuration(obj);
            catch e
                obj.errorFromException(e);
            end
        end
    end

end