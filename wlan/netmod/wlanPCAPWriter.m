classdef wlanPCAPWriter < comm.internal.ConfigBase & comm_sysmod.internal.pcapCommon
    %wlanPCAPWriter Create a WLAN PCAP or PCAPNG file writer object
    %
    %   OBJ = wlanPCAPWriter creates a default WLAN packet capture (PCAP) or
    %   packet capture next generation (PCAPNG) file writer object, OBJ, that
    %   writes WLAN MAC packets into a file with the .pcap or .pcapng
    %   extension.
    %
    %   OBJ = wlanPCAPWriter(Name, Value) creates a WLAN PCAP or PCAPNG file
    %   writer object, OBJ, with properties specified by one or more name-value
    %   pairs. You can specify additional name-value pair arguments in any
    %   order as (Name1,Value1,...,NameN,ValueN). When you do not specify a
    %   property name and value, the object uses the default value.
    %
    %   When you specify 'N' WLAN nodes using 'Node' name-value pair, the
    %   output is a row vector of 'N' wlanPCAPWriter objects, each
    %   corresponding to a node. Each wlanPCAPWriter object creates one or more
    %   packet capture files corresponding to its node, based on the file
    %   extension and operating bands and channels. You can also specify
    %   multiple names in the 'FileName' property with each name corresponding
    %   to the packet capture file created for each node. Assuming 'N' nodes
    %   are specified and 'M' file names are specified, if (M>N) then trailing
    %   (M-N) names are ignored, and if (N>M) then trailing (N-M) packet
    %   capture files are set to default names.
    %
    %   OBJ = wlanPCAPWriter('PCAPWriter', PCAPOBJ) creates a WLAN PCAP or
    %   PCAPNG file writer object, OBJ, using the configuration specified in
    %   PCAPOBJ. PCAPOBJ is an object of type pcapngWriter or pcapWriter.
    %
    %   OBJ = wlanPCAPWriter('PCAPWriter', PCAPOBJ, 'RadiotapPresent',
    %   ISPRESENT) creates a WLAN PCAP or PCAPNG file writer object, OBJ, using
    %   the configuration specified in PCAPOBJ. To write the radiotap header
    %   into the pcap file with the packet, set ISPRESENT to true.
    %
    %   wlanPCAPWriter methods:
    %   write           - Write WLAN MAC packet contents into a file with
    %                     the .pcap or .pcapng extension
    %
    %   wlanPCAPWriter Name-Value pairs:
    %   FileName        - File name specified as either a character row
    %                     vector, string scalar, or a string vector
    %                     representing an absolute or relative path. You
    %                     can specify a vector only if you specify 'Node'
    %                     property.
    %
    %                     If you do not specify the 'Node' property, the
    %                     default file name is 'wlanCapture'. If you
    %                     specify the 'Node' property, the default file
    %                     name will be formatted as
    %                     'NodeName_NodeID_Band_ChannelNumber_Timestamp'.
    %                     If you specify the 'Node' property, and specify
    %                     'FileExtension' as 'pcapng', the default file
    %                     name will be formatted as
    %                     'NodeName_NodeID_Timestamp'.
    %   ByteOrder       - Byte order, specified as 'little-endian' or
    %                     'big-endian'. The default value is 'little-endian'.
    %   FileExtension   - File extension as 'pcap' or 'pcapng'. The default
    %                     value is 'pcap'.
    %   Node            - A scalar or vector representing WLAN nodes
    %                     configured in the network of type <a
    %                     href="matlab:help('wlanNode')">wlanNode</a>. When 'N'
    %                     nodes are specified, the output will be a row vector
    %                     of 'N' wlanPCAPWriter objects.
    %   FileComment     - Additional info given by the user as a comment for
    %                     the file, specified as a character row vector or a
    %                     string. The default value is an empty character
    %                     array. To enable this property, set the
    %                     'FileExtension' property to 'pcapng'.
    %   Interface       - Name of the device that captures packets, specified
    %                     as a character row vector or a string. The default
    %                     value is 'WLAN'. To enable this property, set the
    %                     'FileExtension' property to 'pcapng'.
    %   RadiotapPresent - Flag to indicate whether radiotap is present. The
    %                     default value is false.
    %   PCAPWriter      - Object of type pcapngWriter or pcapWriter.
    %                     When you set this property, OBJ derives the FileName,
    %                     FileExtension, FileComment, and ByteOrder properties
    %                     in accordance from the PCAPOBJ input.
    %   PipeName        - Name of pipe file of type FIFO. Specified as a
    %                     character row vector or string scalar
    %                     representing an absolute or relative path. Pipe
    %                     must be created outside MATLAB before using the
    %                     pipe interface of pcapWriter. The default value
    %                     is empty. Specifying the PipeName is not
    %                     supported when FileName or a PCAPWriter object
    %                     is specified.

    %   Copyright 2020-2025 The MathWorks, Inc.

    %#codegen

    properties (Dependent, SetAccess = private)
        %FileName Name of the PCAP or PCAPNG file
        %   Specify the file name as either a character row vector, string scalar,
        %   or a string vector representing an absolute or relative path. You can
        %   specify a vector only if you specify 'Node' property.
        %
        %   If you do not specify the 'Node' property, the default file name is
        %   'wlanCapture'. If you specify the 'Node' property, the default file name
        %   will be formatted as 'NodeName_NodeID_Band_ChannelNumber_Timestamp'. If
        %   you specify the 'Node' property, and specify 'FileExtension' as 'pcapng', the
        %   default file name will be formatted as 'NodeName_NodeID_Timestamp'.
        %
        %   NodeName and NodeID reflect the 'Name' and 'ID' values respectively of
        %   a wlanNode object. Band reflects the configured band of the WLAN node,
        %   and can be either 2G4 (2.4 GHz), 5G (5 GHz), or 6G (6 GHz).
        %   ChannelNumber follows the format CHX, where X is the configured channel
        %   number of the WLAN node. The Timestamp suffix follows the format
        %   'yyyyMMdd_HHmmss'.
        FileName

        %PipeName Pipe name represented as an absolute or relative path
        %   Specify the pipe name as a character row vector or string. It is
        %   expected that the pipe has already been created outside of MATLAB. The
        %   default value is an empty character.
        PipeName

        %ByteOrder Byte order
        %   Specify the byte order as 'little-endian' or 'big-endian'. The
        %   default value is 'little-endian'.
        ByteOrder

        %FileComment Comment for the file
        %   Specify any additional comment for the file as a character row vector
        %   or a string. To enable this property, set the 'FileExtension' property
        %   to 'pcapng'. The default value is an empty character array.
        FileComment
    end

    properties (GetAccess = public, SetAccess = private)
        %FileExtension Extension of the PCAP or PCAPNG file
        %   Specify the file extension as 'pcap' or 'pcapng'. The default value is
        %   'pcap'.
        FileExtension = 'pcap'

        %Interface Name of the device used to capture data
        %   Specify interface as a character vector or a string in UTF-8 format. To
        %   enable this property, set the 'FileExtension' property to 'pcapng'. The
        %   default value is 'WLAN'.
        %
        %   This property is not applicable if 'Node' property is specified. In
        %   this case, the interface names are generated internally for each node
        %   in the format, 'Band_ChannelNumber'. Band reflects the configured band
        %   of the WLAN node, and can be either 2G4 (2.4 GHz), 5G (5 GHz), or 6G (6
        %   GHz). ChannelNumber follows the format CHX, where X is the configured
        %   channel number of the WLAN node.
        Interface = 'WLAN'

        %RadiotapPresent Flag to indicate whether radiotap is present
        %   Set this property to true to indicate that the radiotap header
        %   is present. The default value is false.
        RadiotapPresent (1, 1) logical = false

        %PCAPWriter Packet writer object
        %   Set this property as of type pcapngWriter or pcapWriter. When
        %   PCAPWriter is set, the properties FileName, FileExtension, FileComment,
        %   and ByteOrder are taken from the object specified in the PCAPWriter.
        PCAPWriter
    end

    properties (WeakHandle, GetAccess = public, SetAccess = private)
        %Node Configured WLAN Nodes in the network
        %   Specify the WLAN nodes configured in the network as a scalar or
        %   vector of objects of type <a
        %   href="matlab:help('wlanNode')">wlanNode</a>.
        Node wlanNode
    end

    properties (Access = private)
        %InterfaceID Unique identifier for an interface
        InterfaceID = 0

        %IsPCAPNG Indicates whether the file format is PCAPNG
        IsPCAPNG (1, 1) logical = false;

        %PCAPPacketWriter PCAP packet writer object. If node with multiple
        %devices/links is specified, it is an array of pcapWriter objects.
        PCAPPacketWriter

        %PCAPNGPacketWriter PCAPNG packet writer object
        PCAPNGPacketWriter

        %SimulationInitPOSIXTimestamp The POSIX timestamp at the instance of
        %simulator initialization. It is expressed in microseconds considering
        %1-Jan-1970 UTC as start, and is represented in uint64 format.
        SimulationInitPOSIXTimestamp uint64

        %SimulationInitTimestamp The timestamp at the instance of simulator
        %initialization. It is expressed in datetime format as 'dd-MMM-yyyy
        %HH:mm:ss' with the 'local' time zone.
        SimulationInitTimestamp datetime

        %IsUserInvoked Flag specifying whether wlanPCAPWriter is invoked by user
        IsUserInvoked = true;
    end

    properties (Hidden)
        %DisableValidation Disable the validation for input arguments of write
        %method
        %   Specify this property as a scalar logical. When true, validation is not
        %   performed on the input arguments and the packet is expected to be
        %   octets in decimal format.
        DisableValidation (1, 1) logical = false
    end

    properties (Constant, Hidden)
        %LinkType Link type for WLAN MAC packet without radiotap header
        LinkType = 105

        %RadiotapLinkType Link type for WLAN MAC packet with radiotap header
        RadiotapLinkType = 127

        %FileExtensionValues Values which the 'FileExtension' property can take
        FileExtension_Values = {'pcap', 'pcapng'};
    end

    properties (Access = private)
        %Frame configuration objects used for calculating data rate
        HTConfigObject = wlanHTConfig;
        VHTConfigObject = wlanVHTConfig;
        HESUConfigObject = wlanHESUConfig;

        %RadiotapFields Structure of radiotap fields
        %   This property stores the logical values to enable different
        %   radiotap fields.
        RadiotapFields = radiotapFieldsStruct();
        RadiotapFieldNames;
    end

    methods (Access = protected)
        function flag = isInactiveProperty(obj, prop)
            switch prop
                case 'PipeName'
                    flag = isempty(obj.PipeName);
                case 'FileName'
                    flag = ~isempty(obj.PipeName);
                case {'FileComment', 'Interface'}
                    flag = strcmp(obj.FileExtension, 'pcap');
                case 'PCAPWriter'
                    flag = isempty(obj.PCAPWriter);
                otherwise
                    flag = false;
            end
        end
    end

    methods (Access = private)
        function setFileExtension(obj, value)
            value = validatestring(value, obj.FileExtension_Values, 'wlanPCAPWriter', 'FileExtension');
            obj.FileExtension = '';
            obj.FileExtension = value;
        end

        function setInterface(obj, value)
            validateattributes(value, {'char', 'string'}, {'row'}, ...
                'wlanPCAPWriter', 'Interface');
            obj.Interface = char(value);
        end

        function setPCAPWriter(obj, value)
            validateattributes(value, {'pcapngWriter', 'pcapWriter'}, ...
                {'scalar'}, 'wlanPCAPWriter', 'PCAPWriter');
            obj.PCAPWriter = value;
        end

        function setupPCAPWriter(obj, linkType)
            % Setup for PCAP writer
            obj.FileExtension = 'pcap';
            obj.PCAPPacketWriter = obj.PCAPWriter;
            coder.internal.errorIf(obj.PCAPPacketWriter.GlobalHeaderPresent, ...
                'shared_comm_sysmod:pcapWriter:MultipleInterfacesNotAccepted');
            obj.PCAPPacketWriter.writeGlobalHeader(linkType);
        end

        function setupPCAPNGWriter(obj, linkType)
            % Setup for PCAPNG writer
            obj.FileExtension = 'pcapng';
            obj.PCAPNGPacketWriter = obj.PCAPWriter;

            % Update interface names and IDs, if operating in simulation path and Node
            % argument is specified
            if isempty(coder.target) && ~isempty(obj.Node)
                % This method is invoked for each node in the constructor. So consider the
                % first node here.
                inputNode = obj.Node(1);

                % Generate the interface names and interface IDs
                generateInterfacesForNode(obj, inputNode, linkType);
            else
                obj.InterfaceID = obj.PCAPNGPacketWriter.writeInterfaceDescriptionBlock(linkType, obj.Interface);
            end
        end

        function createPacketCaptureFile(obj, pcapFileName, pcapngFileName, byteOrder, fileComment, linkType, pcapidx)
            %createPacketCaptureFile Create the packet capture file for PCAP/PCAPNG

            % For codegen, default writer setup for both pcapWriter and pcapngWriter
            isCodegenPath = ~isempty(coder.target);
            if isCodegenPath
                obj.PCAPPacketWriter = pcapWriter('FileName', pcapFileName, 'ByteOrder', byteOrder);
                obj.PCAPNGPacketWriter = pcapngWriter('FileName', (pcapngFileName), 'ByteOrder', byteOrder, 'FileComment', fileComment);
            end

            % Update PCAP and PCAPNG writer objects
            if ~obj.IsPCAPNG
                % If Node input is not specified then pcap index is always 1 
                if nargin < 7
                    pcapidx = 1;
                end
                if ~isCodegenPath && ~isempty(obj.Node)
                    % Add pcapWriter Objects and create pcap files
                    obj.PCAPPacketWriter = [obj.PCAPPacketWriter pcapWriter('FileName', pcapFileName, 'ByteOrder', byteOrder)];

                    % Warn if file comment is ignored for pcap
                    if ~isempty(fileComment)
                        coder.internal.warning('shared_comm_sysmod:pcapWriter:IgnoreFileComment');
                    end
                    obj.PCAPPacketWriter(pcapidx).writeGlobalHeader(linkType);
                else
                    obj.PCAPPacketWriter = pcapWriter('FileName', pcapFileName, 'ByteOrder', byteOrder);

                    % Warn if file comment is ignored for pcap
                    if ~isempty(fileComment)
                        coder.internal.warning('shared_comm_sysmod:pcapWriter:IgnoreFileComment');
                    end
                    obj.PCAPPacketWriter.writeGlobalHeader(linkType);
                end
            else
                obj.PCAPNGPacketWriter = pcapngWriter('FileName', (pcapngFileName), 'ByteOrder', byteOrder, 'FileComment', fileComment);
                if ~isCodegenPath && ~isempty(obj.Node)
                    % Generate the interface names and interface IDs
                    generateInterfacesForNode(obj, obj.Node, linkType);
                else
                    obj.InterfaceID =  obj.PCAPNGPacketWriter.writeInterfaceDescriptionBlock(linkType, obj.Interface);
                end
            end
        end

        function generateInterfacesForNode(obj, node, linkType)
            %updateInterfacesForNode Generate the interface names and interface IDs for
            %the given node

            % Find the number of devices/links configured the node
            [numConfigs, configObjects]=getInterfaceDetails(node);

            % Overwrite the 'WLAN' default value with InterfaceName generated for the
            % device/links
            obj.Interface = [];

            % Overwrite the default value with InterfaceID generated for the
            % device/links
            obj.InterfaceID = [];

            % Loop over the number of devices/links
            for deviceID = 1:numConfigs
                % InterfaceName is empty. Add interface name for each interface
                obj.Interface = [obj.Interface addBandChannelSuffixes("", configObjects(deviceID).BandAndChannel)];

                % InterfaceID is empty. Add Interface ID for each interface
                obj.InterfaceID = [obj.InterfaceID  obj.PCAPNGPacketWriter.writeInterfaceDescriptionBlock(linkType, obj.Interface(deviceID))];
            end
        end

        function createPipeSetup(obj, pipeName, byteOrder, fileComment, linkType)
            %createPipeSetup Set up the pipe for writing using the
            %appropriate packet writer
            if obj.IsPCAPNG
                obj.PCAPNGPacketWriter = pcapngWriter(PipeName=pipeName, ByteOrder=byteOrder, FileComment=fileComment);
                if ~isempty(obj.Node)
                    % Generate the interface names and interface IDs
                    generateInterfacesForNode(obj, obj.Node, linkType);
                else
                    obj.InterfaceID =  writeInterfaceDescriptionBlock(obj.PCAPNGPacketWriter, linkType, obj.Interface);
                end
                % For code generation, create a dummy writer
                if ~isempty(coder.target)
                    obj.PCAPPacketWriter = pcapWriter;
                end
            else
                obj.PCAPPacketWriter = pcapWriter(PipeName=pipeName, ByteOrder=byteOrder);
                writeGlobalHeader(obj.PCAPPacketWriter, linkType);
                % For code generation, create a dummy writer
                if ~isempty(coder.target)
                    obj.PCAPNGPacketWriter = pcapngWriter;
                end
            end
        end
    end

    %% Methods to capture packets from a node
    methods (Access = private)
        function setupNode(obj, node)
            % Setup for nodes
            obj.Node = node;

            % Get the network simulator instance to retrieve the init timestamp
            ns = wirelessNetworkSimulator.getInstance;
            obj.SimulationInitTimestamp = ns.InitTimestamp;

            % The current POSIX time in microseconds
            obj.SimulationInitPOSIXTimestamp = posixtime(obj.SimulationInitTimestamp)*1e6;

            if ~strcmp(obj.Node.MACModel,"full-mac")
                coder.internal.warning("wlan:wlanPCAPWriter:AbstractedMACNotValid");
                return;
            end
            obj.Node.IncludeVector = true;

            % Register events at the wlan nodes
            registerEventCallback(obj.Node, "TransmissionStarted", @(eventData) obj.capturePackets(eventData));
            registerEventCallback(obj.Node, "ReceptionEnded", @(eventData) obj.capturePackets(eventData));
        end

        function capturePackets(obj, eventData)
            %capturePackets Callback function that writes the MAC packets into
            %PCAP or PCAPNG file
            %
            %   capturePackets(OBJ, EVENTDATA) is a callback function that writes the
            %   packets into PCAP/PCAPNG format when 'TransmissionStarted' or 'ReceptionEnded'
            %   is triggered from node. Radiotap header is also added to packets.
            %
            %   OBJ is an object of type wlanPCAPWriter.
            %
            %   EVENTDATA is a structure containing the notification data passed by the
            %   event.

            isTransmissionStarted = strcmp(eventData.EventName, "TransmissionStarted");
            isReceptionEnded = strcmp(eventData.EventName, "ReceptionEnded");

            if isTransmissionStarted || isReceptionEnded
                macFrame = eventData.EventData.PDU;
                % For received frames (captured via ReceptionEnded event), write only if
                % packet has been successfully decoded at PHY layer.
                if isReceptionEnded && (eventData.EventData.PHYDecodeStatus ~= 0) % Non-zero value indicates failures
                    return;
                end

                % Calculate the POSIX timestamp of the packet transmitted or received in
                % microseconds
                pcapTimestamp = eventData.Timestamp*1e6 + obj.SimulationInitPOSIXTimestamp;

                % Identifier of Device/Link
                deviceID = find(obj.Node.ReceiveFrequency == eventData.EventData.CenterFrequency);
                if obj.RadiotapPresent
                    radiotapBytes = formRadiotap(obj, eventData);
                    for frameIDx = 1:numel(macFrame)
                        % For received frames, radiotapBytes is 2D array containing the radiotap
                        % bytes for each subframe. The radiotap flags byte (has FCS bit) must be
                        % filled accordingly
                        if isReceptionEnded
                            write(obj,macFrame{frameIDx},pcapTimestamp,'Radiotap',radiotapBytes(frameIDx,:),'DeviceID',deviceID);
                        else % FCS information is not available for transmitted frames
                            write(obj,macFrame{frameIDx},pcapTimestamp,'Radiotap',radiotapBytes,'DeviceID',deviceID);
                        end
                    end
                else % No Radiotap header
                    for frameIDx = 1:numel(macFrame)
                        write(obj,macFrame{frameIDx},pcapTimestamp,'DeviceID',deviceID);
                    end
                end
            end
        end
    end

    %% Constructor and public methods
    methods
        function obj = wlanPCAPWriter(varargin)
            %wlanPCAPWriter Create a WLAN PCAP packet writer object

            % Name-value pair check
            coder.internal.errorIf(mod(nargin,2)~=0,'MATLAB:system:invalidPVPairs');

            % Initialize isPCAPWriterNVProvided and interfaceFlag to false to indicate
            % 'PacketWriter' and 'Interface' name-value pair is not given as input.
            isPCAPWriterNVProvided = false;
            isInterfaceNVProvided = false;

            % File name for dummy pcapWriter or pcapngWriter for codegen,
            % which will be used to create the object. No file will be
            % created using this dummy file name.
            dummyFileName = 'dummyFileForCodegen';

            fileName = 'wlanCapture';
            byteOrder = 'little-endian';
            fileComment = blanks(0);
            pipeName = blanks(0);
            nodes = [];
            numNodes = 0;
            isPipeNameNVProvided = false;

            if isempty(coder.target) % Simulation path
                fileNameFlag = false;
                nvPairsFlag = false;

                nvPairs = {'FileName','ByteOrder','FileComment','FileExtension',...
                    'Node','Interface','RadiotapPresent','PCAPWriter','PipeName'};

                % Process name-value pairs
                for i = 1:2:nargin-1
                    % Do not validate NV pairs for internal properties
                    if strcmp(varargin{i},"IsUserInvoked")
                        obj.IsUserInvoked = varargin{i+1};
                    elseif strcmp(varargin{i},"DisableValidation")
                        obj.DisableValidation = varargin{i+1};
                    else
                        name = wnet.internal.matchString(varargin{i}, nvPairs, 'wlanPCAPWriter');
                        value = varargin{i+1};
                        switch name
                            case 'FileName'
                                fileName = validateFileNames(value);
                                fileNameFlag = true;
                                nvPairsFlag = true;
                            case 'FileComment'
                                fileComment = value;
                                nvPairsFlag = true;
                            case 'ByteOrder'
                                byteOrder = value;
                                nvPairsFlag = true;
                            case 'FileExtension'
                                setFileExtension(obj, value);
                                nvPairsFlag = true;
                            case 'Node'
                                nodes = validateNodes(value);
                                numNodes = numel(nodes);
                            case 'Interface'
                                setInterface(obj, value);
                                isInterfaceNVProvided = true;
                            case 'RadiotapPresent'
                                obj.RadiotapPresent = value;
                            case 'PipeName'
                                pipeName = value;
                                isPipeNameNVProvided = true;
                            otherwise % 'PCAPWriter'
                                isPCAPWriterNVProvided = true;
                                setPCAPWriter(obj, value);
                        end

                        if ~fileNameFlag && numNodes > 0
                            fileName = '';
                        end
                    end
                end

                % If nodes with multiple devices/links are specified, custom file names can
                % be specified only if FileExtension is specified as 'pcapng'. Validate
                % this only when user invokes wlanPCAPWriter.
                if obj.IsUserInvoked
                    for nodeIdx = 1:numNodes
                        [numConfigs, ~] = getInterfaceDetails(nodes(nodeIdx));
                        coder.internal.errorIf(numConfigs > 1 && fileNameFlag && strcmp(obj.FileExtension, 'pcap'), ...
                            'wlan:wlanPCAPWriter:PCAPFileNameUnsupportedWithMultiPHYNodes', nodes(nodeIdx).Name);
                    end
                end

                % An error is thrown when a PCAPWriter object is specified with any of
                % FileName, FileComment, ByteOrder, or FileExtension as name-value pairs,
                % because packets need to be directly written to the file.
                coder.internal.errorIf((isPCAPWriterNVProvided && nvPairsFlag), ...
                    'shared_comm_sysmod:pcapWriter:InvalidParameters', 'wlanPCAPWriter');

                % Filename should be scalar when nodes are not present
                coder.internal.errorIf((fileNameFlag && numel(fileName)>1 && numNodes==0), ...
                        'shared_comm_sysmod:pcapWriter:FileNameMustBeScalar');

                % The isPCAPWriterNVProvided signifies that an already opened scalar writer
                % object is supplied as input, thereby allowing logging from only one node.
                coder.internal.errorIf((isPCAPWriterNVProvided && numNodes>1), ...
                    'shared_comm_sysmod:pcapWriter:PCAPWriterWithMultiNode');

                % Interface names are internally generated for each device/link within a
                % node. So a custom interface name is not required.
                coder.internal.errorIf((isInterfaceNVProvided && numNodes>0), ...
                    'wlan:wlanPCAPWriter:InterfaceWithNode');

                % Radiotap information is always specified in little
                % endian byte-order.
                coder.internal.errorIf((obj.RadiotapPresent==1 && strcmp(byteOrder,"big-endian")), ...
                    'wlan:wlanPCAPWriter:RadiotapEndianess');

                % The isPipeNameNVProvided signifies that the we are writing to a pipe,
                % thereby allowing logging from only one node.
                coder.internal.errorIf((isPipeNameNVProvided && numNodes > 1), ...
                    'shared_comm_sysmod:pcapWriter:PipeWithMultiNode');

                % Throw an error if a pipe name is specified along with a file name or 
                % PCAPWriter object
                coder.internal.errorIf(isPipeNameNVProvided && (fileNameFlag || isPCAPWriterNVProvided), ...
                    'shared_comm_sysmod:pcapWriter:PipeNameNVIsNotSupported');
            else % Codegen path
                nvPairs = {'FileName','ByteOrder','FileComment','FileExtension',...
                    'Interface','RadiotapPresent','PCAPWriter', 'PipeName'};

                % Select parsing options
                popts = struct('PartialMatching', true, 'CaseSensitivity', false);

                % Parse inputs
                pStruct = coder.internal.parseParameterInputs(nvPairs, popts, varargin{:});

                if pStruct.PCAPWriter
                    isPCAPWriterNVProvided = true;
                end

                coder.internal.errorIf(isPCAPWriterNVProvided && ...
                    (pStruct.FileName || pStruct.FileExtension || ...
                    pStruct.ByteOrder || pStruct.FileComment), ...
                    'shared_comm_sysmod:pcapWriter:InvalidParameters', 'wlanPCAPWriter');

                if pStruct.PipeName
                    isPipeNameNVProvided = true;
                end

                % Get values for the N-V pair or set defaults for the
                % optional arguments
                byteOrder = coder.internal.getParameterValue(pStruct.ByteOrder, ...
                    coder.const('little-endian'), varargin{:});

                fileName = coder.internal.getParameterValue( ...
                    pStruct.FileName, 'wlanCapture', varargin{:});

                fileComment = coder.internal.getParameterValue( ...
                    pStruct.FileComment, blanks(0), varargin{:});

                obj.RadiotapPresent = coder.internal.getParameterValue( ...
                    pStruct.RadiotapPresent, false, varargin{:});

                setFileExtension(obj, coder.internal.getParameterValue( ...
                    pStruct.FileExtension, coder.const('pcap'), varargin{:}));

                setInterface(obj, coder.internal.getParameterValue( ...
                    pStruct.Interface, coder.const('pcap'), varargin{:}));

                pipeName = coder.internal.getParameterValue( ...
                    pStruct.PipeName, blanks(0), varargin{:});

                defaultVal = pcapWriter('FileName', dummyFileName);
                setPCAPWriter(obj, coder.internal.getParameterValue( ...
                    pStruct.PCAPWriter, defaultVal, varargin{:}));
            end

            % Set link type based on radiotap presence
            if obj.RadiotapPresent
                linkType = obj.RadiotapLinkType;
                obj.RadiotapFieldNames = fieldnames(obj.RadiotapFields);
            else
                linkType = obj.LinkType;
            end

            % File name for pcap and pcapng files
            if (~isPCAPWriterNVProvided && strcmp(obj.FileExtension, 'pcap')) || ...
                    (isPCAPWriterNVProvided && isa(obj.PCAPWriter, 'pcapWriter'))
                pcapFileName = fileName;
                pcapngFileName = dummyFileName;
            else
                pcapFileName = dummyFileName;
                pcapngFileName = fileName;
                obj.IsPCAPNG = true;
            end

            if isPipeNameNVProvided
                % When pipe is provided, create pipe setup and return
                % Update object with node and add event callbacks
                if numNodes > 0
                    setupNode(obj, nodes);
                end
                createPipeSetup(obj, pipeName, byteOrder, fileComment, linkType);
                return;
            end

            if ~isempty(coder.target) % Codegen path
                if isPCAPWriterNVProvided
                    if isa(obj.PCAPWriter, 'pcapWriter')
                        % If pcapWriter object is provided, use that object
                        % to write the packets. Write the global header
                        % into the file. Initialize a dummy pcapngWriter to
                        % accommodate codegen.
                        setupPCAPWriter(obj, linkType);
                        obj.PCAPNGPacketWriter = pcapngWriter('FileName', pcapngFileName, 'ByteOrder', byteOrder, 'FileComment', fileComment);
                    else
                        % If pcapngWriter object is provided, use that
                        % object for writing the packets. Write the
                        % interface description into the file and
                        % initialize a dummy pcapWriter to accommodate
                        % codegen.
                        setupPCAPNGWriter(obj, linkType);
                        obj.PCAPPacketWriter = pcapWriter('FileName', pcapFileName, 'ByteOrder', byteOrder);
                    end
                else
                    % If no PCAP writer object is provided, create a PCAP
                    % writer object based on extension and write the global
                    % header into the file
                    createPacketCaptureFile(obj, pcapFileName, pcapngFileName, byteOrder, fileComment, linkType);
                end
            else % Simulation path
                if isPCAPWriterNVProvided
                    % PCAPWriter object is provided and single 'Node' input
                    % argument is specified
                    if ~isempty(nodes) 
                        % Add events to capture packets into the PCAPWriter
                        % object
                        setupNode(obj, nodes);
                    end

                    if isa(obj.PCAPWriter, 'pcapWriter')
                        % If pcapWriter object is provided, use that object
                        % to write the packets. Write the global header
                        % into the file.
                        setupPCAPWriter(obj, linkType);
                    else
                        % If pcapngWriter object is provided, use that
                        % object for writing the packets. Write the
                        % interface description into the file.
                        setupPCAPNGWriter(obj, linkType);
                    end
                else
                    % If no PCAPWriter object is provided and a 'Node'
                    % input argument is specified
                    if numNodes > 0
                        % Update object with nodes and add listeners to the
                        % object to write the packets into the pcap file
                        setupNode(obj, nodes(1));

                        % Set filename for capture of each node. If name is not supplied for all
                        % the nodes then leave the trailing nodes with default names and assign
                        % filename for each object from the provided list
                        fName = assignFileName(fileName, 1, nodes(1), obj.IsPCAPNG, obj.SimulationInitTimestamp);

                        % Create pcap file and write the global header
                        % based on the PCAP type
                        if obj.IsPCAPNG
                            createPacketCaptureFile(obj, dummyFileName, fName, byteOrder, fileComment, linkType);
                        else
                            for idx=1:numel(fName)
                                createPacketCaptureFile(obj, fName(idx), dummyFileName, byteOrder, fileComment, linkType,idx);
                            end
                        end

                        % Replicate object for N nodes
                        if numNodes > 1
                            obj = repmat(obj, 1, numNodes);
                            for nodeIdx = 2:numNodes
                                fName = assignFileName(fileName, nodeIdx, nodes(nodeIdx), obj(nodeIdx).IsPCAPNG, obj(1).SimulationInitTimestamp);
                                obj(nodeIdx) = wlanPCAPWriter(Node=nodes(nodeIdx), FileName=fName, ByteOrder=byteOrder, ...
                                    FileExtension=obj(1).FileExtension, FileComment=fileComment, ...
                                    RadiotapPresent=obj(1).RadiotapPresent, IsUserInvoked=false, DisableValidation=obj(1).DisableValidation);
                            end
                        end
                    else
                        % Create a pcap file when no arguments are passed
                        % and without any nodes passed.
                        createPacketCaptureFile(obj, pcapFileName, pcapngFileName, byteOrder, fileComment, linkType);
                    end
                end

                % Invoke the set method and update DisableValidation flag in underlying
                % pcapWriter/pcapngWriter. For the first call of wlanPCAPWriter, this is an
                % array so index the first object.
                obj(1).DisableValidation = obj(1).DisableValidation;
            end
        end

        function value = get.FileName(obj)
            if obj.IsPCAPNG
                value = obj.PCAPNGPacketWriter.FileName;
            else
                value = obj.PCAPPacketWriter.FileName;
            end
        end

        function value = get.PipeName(obj)
            if obj.IsPCAPNG
                value = obj.PCAPNGPacketWriter.PipeName;
            else
                value = obj.PCAPPacketWriter.PipeName;
            end
        end

        function value = get.FileComment(obj)
            if obj.IsPCAPNG
                value = obj.PCAPNGPacketWriter.FileComment;
            else
                value = blanks(0);
            end
        end

        function value = get.ByteOrder(obj)
            if obj.IsPCAPNG
                value = obj.PCAPNGPacketWriter.ByteOrder;
            else
                value = obj.PCAPPacketWriter.ByteOrder;
            end
        end

        function set.DisableValidation(obj, value)
            obj.DisableValidation = value;
            if obj.IsPCAPNG %#ok<*MCSUP>
                if ~isempty(obj.PCAPNGPacketWriter)
                    obj.PCAPNGPacketWriter.DisableValidation = value;
                end
            else
                if ~isempty(obj.PCAPPacketWriter)
                    for pcapIdx = 1:numel(obj.PCAPPacketWriter)
                        obj.PCAPPacketWriter(pcapIdx).DisableValidation = value;
                    end
                end
            end
        end

        function write(obj, packet, timestamp, varargin)
            %WRITE Write a packet into a file with .pcap or .pcapng extension
            %
            %   write(OBJ, PACKET, TIMESTAMP) writes a WLAN MAC packet into a file
            %   with the .pcap or .pcapng extension
            %
            %   PACKET is the WLAN MAC packet specified as one of these types:
            %    - A binary vector representing bits
            %    - A character vector representing octets in hexadecimal format
            %    - A string scalar representing octets in hexadecimal format
            %    - A numeric vector, where each element is in the range [0, 255],
            %      representing octets in decimal format
            %    - An n-by-2 character array, where each row represents an octet
            %      in hexadecimal format
            %
            %   TIMESTAMP is specified as a nonnegative scalar integer. It is the
            %   packet arrival time in microseconds since 1-Jan-1970 UTC.
            %
            %   WRITE(OBJ, PACKET, TIMESTAMP, Name=Value) specifies additional
            %   name-value arguments described below. When a name-value pair is not
            %   specified, the object function uses the default value.
            %
            %     Radiotap       - Radiotap holds the packet metadata provided by the
            %                      user in addition to the packet, specified as one of
            %                      these types:
            %                       - A binary vector representing bits
            %                       - A character vector representing octets in
            %                         hexadecimal format
            %                       - A string scalar representing octets in
            %                         hexadecimal format
            %                       - A numeric vector, where each element is in the
            %                         range [0, 255], representing octets in decimal
            %                         format
            %                       - An n-by-2 character array, where each row
            %                         represents an octet in hexadecimal format
            %     PacketComment  - Packet comment, specified as a character vector or
            %                      string scalar. The default value is an empty
            %                      character vector.
            %     PacketFormat   - Specifies the format of the input data packet as
            %                      'bits' or 'octets'. The default value is 'octets'.
            %                      If it is specified as 'octets', the packet can be a
            %                      numeric vector representing octets in decimal format
            %                      or alternatively, it can be a character array or
            %                      string scalar representing octets in hexadecimal
            %                      format. Otherwise, packet is a binary vector.
            %     RadiotapFormat - Specifies the radiotap of the input data as 'bits'
            %                      or 'octets'. The default value is 'octets'. If it is
            %                      specified as 'octets', the radiotap can be a numeric
            %                      vector representing octets in decimal format or
            %                      alternatively, it can be a character array or string
            %                      scalar representing octets in hexadecimal format.
            %                      Otherwise, radiotap is a binary vector.

            % Perform validations, if validation is not disabled
            if ~obj.DisableValidation
                narginchk(3, 11);
                coder.internal.errorIf(mod(nargin-3,2)~=0,'MATLAB:system:invalidPVPairs');
            end

            % Allowed N-V pairs. Preserve the order for the switch-case.
            nvPairs = {'PacketFormat','PacketComment','Radiotap','RadiotapFormat'};
            if isempty(coder.target) % Simulation path
                % Initialize with default values
                pktFormat = 'octets';
                pktComment = '';
                radiotapFormat = 'octets';
                radiotapInput = false;
                deviceID = 1;

                % Apply name-value pairs
                for i = 1:2:nargin-3
                    % Do not validate for 'DeviceID' since it is a hidden
                    % parameter
                    if strcmp(varargin{i},"DeviceID")
                        % Device ID - Identified for Link or Device ID
                        deviceID = varargin{i+1};
                    else
                        [~, pIdx] = wnet.internal.matchString(varargin{i}, nvPairs);
                        switch pIdx
                            case 1 % PacketFormat
                                pktFormat = varargin{i+1};
                            case 2 % PacketComment
                                pktComment = varargin{i+1};
                            case 3 % Radiotap
                                radiotap = varargin{i+1};
                                radiotapInput = true;
                            otherwise % Radiotap format
                                radiotapFormat = varargin{i+1};
                        end
                    end
                end
            else % Codegen path
                % Select parsing options
                popts = struct('PartialMatching', true, 'CaseSensitivity', false);

                % Parse inputs
                pStruct = coder.internal.parseParameterInputs(nvPairs,popts,varargin{:});

                % Get values for the N-V pair or set defaults for the optional arguments
                pktFormat = coder.internal.getParameterValue( ...
                    pStruct.PacketFormat, coder.const('octets'), varargin{:});

                pktComment = coder.internal.getParameterValue( ...
                    pStruct.PacketComment, blanks(0), varargin{:});

                radiotapFormat = coder.internal.getParameterValue( ...
                    pStruct.RadiotapFormat, coder.const('octets'), varargin{:});

                radiotap = coder.internal.getParameterValue( ...
                    pStruct.Radiotap, blanks(0), varargin{:});

                radiotapInput = ~isempty(radiotap);
            end

            % Check whether the validation is enabled
            if ~obj.DisableValidation
                % Validate packet and return octets in decimal format
                packetData = obj.validatePayloadFormat(packet, ...
                    wnet.internal.matchString(pktFormat, {'bits','octets'}, 'wlanPCAPWriter',' PacketFormat'));
                if radiotapInput
                    % Validate radiotap and return octets in decimal format
                    radiotapData = obj.validatePayloadFormat(radiotap, ...
                        wnet.internal.matchString(radiotapFormat, {'bits','octets'}, 'wlanPCAPWriter', 'RadiotapFormat'));
                end
            else
                packetData = double(packet);
                if radiotapInput
                    if iscolumn(radiotap)
                        radiotapData = radiotap;
                    else
                        % Convert row vector to column vector
                        radiotapData = radiotap';
                    end
                end

            end

            % Check if Radiotap is passed as name-value pair
            if radiotapInput
                % Calculate the radiotap length from 3rd and 4th bytes
                radiotapLength = radiotapData(3)+radiotapData(4)*256;

                if obj.RadiotapPresent
                    if numel(radiotapData) ~= radiotapLength
                        coder.internal.error('wlan:wlanPCAPWriter:InvalidRadiotap');
                    end
                else % Got Radiotap information, though not expected. Ignore.
                    coder.internal.warning('wlan:wlanPCAPWriter:IgnoreRadiotapHeader');
                    radiotapData = [];
                end
            else
                radiotapData = [];
                if obj.RadiotapPresent % Expecting Radiotap information
                    coder.internal.error('wlan:wlanPCAPWriter:NoRadiotap');
                end
            end


            % Form packet by concatenating header and data
            packet = [radiotapData; packetData];
            % Determine if writing to PCAPNG or PCAP format
            if obj.IsPCAPNG
                % Determine the interface ID
                if isscalar(obj.InterfaceID) % Scalar node input or no node input
                    id = obj.InterfaceID; % Default value 0
                else % With Node input
                    id = obj.InterfaceID(deviceID);
                end

                % Write packet to PCAPNG format
                if isempty(pktComment)
                    write(obj.PCAPNGPacketWriter, packet, timestamp, id);
                else
                    write(obj.PCAPNGPacketWriter, packet, timestamp, id, 'PacketComment', pktComment);
                end
            else
                if isscalar(obj.PCAPPacketWriter)
                    pcapwriter = obj.PCAPPacketWriter;
                else
                    pcapwriter = obj.PCAPPacketWriter(deviceID);
                end
                % Write packet to PCAP format
                write(pcapwriter, packet, timestamp);
            end
        end
    end


    %% Methods related to radiotap
    methods (Access = private)
        function radiotapBytes = formRadiotap(obj, eventData)
            %formRadiotap Returns the radiotap bytes
            %
            %   formRadiotap(EVENTDATA) is a function that forms and
            %   returns the radiotap bytes.
            %
            %   EVENTDATA is a structure containing event notification data.
            %
            %   The following radiotap fields are formed using context captured from
            %   EVENTDATA. Channel, Flags, TSFT, HE, MCS, Rate, VHT, dBm TX power,
            %   timestamp, USIG, EHT.

            isReceptionEnded = strcmp(eventData.EventName, "ReceptionEnded");

            headerRevision = 0;
            headerPad = 0;
            radiotapBytes = [headerRevision headerPad 0 0]; % header length is 0 initially
            radiotapFields = obj.RadiotapFields;

            packetInfo = eventData.EventData.PPDUParameters;
            if strcmp(packetInfo.Format, "HT-Mixed") % MCS information is captured only for HT
                radiotapFields.MCSInformation = 1;
            elseif strcmp(packetInfo.Format, "VHT")
                radiotapFields.VHTInformation = 1;
            elseif strcmp(packetInfo.Format, "HE-SU") || strcmp(packetInfo.Format, "HE-EXT-SU")
                radiotapFields.HEInformation = 1;
            elseif strcmp(packetInfo.Format, "HE-TB")
                radiotapFields.LSIG = 1;
            elseif strcmp(packetInfo.Format, "EHT-SU")
                radiotapFields.TLVs = 1;
                radiotapFields.Ext = 1;
            end

            % Do not fill rate byte if it exceeds 255
            dataRate = getDataRate(obj,eventData);
            dataRate = round(dataRate);
            if dataRate > 255
                radiotapFields.Rate = 0;
            end

            % Get the logical values as an array
            fieldVector = cellfun(@(x)(radiotapFields.(x)),obj.RadiotapFieldNames);
            radiotapFlagBytes = bit2int(fieldVector,8,false)';

            % Append to radiotap
            radiotapBytes = [radiotapBytes radiotapFlagBytes];
            
            % Append Ext bitmasks for EHT Packets
            if radiotapFields.Ext
            radiotapBytes = [radiotapBytes 6 0 0 0]; % for USIG and EHT fields
            end

            if radiotapFields.TSFT
                % Check for 8 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),8);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end
                % Timestamp in microseconds represented in 8-octet little-endian
                mactime = round(eventData.Timestamp/1e-6);
                tsftBytes = decToByteArray_le(mactime, 8);
                
                radiotapBytes = [radiotapBytes tsftBytes];
            end

            if radiotapFields.Flags
                % Form Flags byte, only 'FCS at end' is true by default,
                % decimal 16;
                radiotapBytes = [radiotapBytes 16];
                if isReceptionEnded
                    flagsIndex = numel(radiotapBytes);
                end
            end

            if radiotapFields.Rate
                % Fill previously computed Rate byte
                radiotapBytes = [radiotapBytes dataRate];
            end

            if radiotapFields.Channel
                % Check for 2 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),2);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end
                channelBytes = formRadiotapChannelBytes(eventData);
                radiotapBytes = [radiotapBytes channelBytes];
            end

            if radiotapFields.dBmTxPower
                % dBm Tx Power
                if isReceptionEnded
                    txPower = round(packetInfo.TransmitPower,0);
                else
                    txPower = round(eventData.EventData.TransmitPower,0);
                end
                radiotapBytes = [radiotapBytes txPower];
            end

            if radiotapFields.MCSInformation
                % Form MCS information bytes
                mcsBytes = formRadiotapMCSBytes(eventData);
                radiotapBytes = [radiotapBytes mcsBytes];
            end

            if radiotapFields.VHTInformation
                if ~obj.DisableValidation
                    assert(packetInfo.MCS<=9,'Max MCS is 9');
                    assert(packetInfo.NumSpaceTimeStreams<=8,'Max NSS is 8');
                end

                % Check for 2 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),2);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end

                % Form VHT information bytes
                VHTInformationBytes = formRadiotapVHTBytes(eventData);
                radiotapBytes = [radiotapBytes VHTInformationBytes];
            end

            if radiotapFields.FrameTimestamp
                % Check for 8 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),8);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end

                % Form timestamp bytes
                timestampBytes = formRadiotapTimestampBytes(eventData.Timestamp);
                % Append to radiotap
                radiotapBytes = [radiotapBytes timestampBytes];
            end

            if radiotapFields.HEInformation
                % Check for 2 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),2);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end

                % Form HE radiotap bytes
                HEInformationBytes = formRadiotapHEBytes(eventData);
                radiotapBytes = [radiotapBytes HEInformationBytes];
            end

            if radiotapFields.LSIG
                % Check for 2 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),2);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end

                % Form LSIG bytes
                LSIGBytes = formRadiotapLSIGBytes(packetInfo);
                radiotapBytes = [radiotapBytes LSIGBytes];
            end

            if radiotapFields.TLVs
                % Check for 4 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),4);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end

                % Form USIG bytes
                USIGBytes = formRadiotapUSIGBytes(eventData);
                radiotapBytes = [radiotapBytes USIGBytes];

                % Check for 4 bytes alignment
                numZeroPad = getPadLength(size(radiotapBytes,2),4);
                if numZeroPad~=0
                    radiotapBytes = [radiotapBytes zeros(1,numZeroPad)];
                end

                % Form EHT bytes
                EHTBytes = formRadiotapEHTBytes(packetInfo);
                radiotapBytes = [radiotapBytes EHTBytes];
            end

            % Final header length (2-octets) as little-endian
            radiotapBytes(3:4) = decToByteArray_le(size(radiotapBytes,2),2);

            % Fill FCS at end flag for each subframe
            if isReceptionEnded
                numSubframes = numel(eventData.EventData.PDU);
                fcsBytes = (eventData.EventData.PDUDecodeStatus == -2); % FCS fail
                outputRadiotap = repmat(radiotapBytes, numSubframes, 1);
                for i = 1:numSubframes
                    if fcsBytes(i)
                        outputRadiotap(i,flagsIndex) = 80;
                    end
                end
                radiotapBytes =  outputRadiotap;
            end
        end

        function dataRate = getDataRate(obj,eventData)
            %formRadiotapRateByte Returns the data rate for captured frame

            packetInfo = eventData.EventData.PPDUParameters;
            mcs = packetInfo.MCS;
            numSTS = packetInfo.NumSpaceTimeStreams;
            if strcmp(eventData.EventName, "TransmissionStarted")
                packetBW = eventData.EventData.TransmitBandwidth;
            else
                packetBW = eventData.EventData.ReceiveBandwidth;
            end
            cbw = "CBW" + round(packetBW/1e6);

            % Form data rate
            if strcmp(packetInfo.Format, "Non-HT")
                switch mcs
                    case 0 % 6 Mbps
                        dataRate = 6;
                    case 1 % 9 Mbps
                        dataRate = 9;
                    case 2 % 12 Mbps
                        dataRate = 12;
                    case 3 % 18 Mbps
                        dataRate = 18;
                    case 4 % 24 Mbps
                        dataRate = 24;
                    case 5 % 36 Mbps
                        dataRate = 36;
                    case 6  % 48 Mbps
                        dataRate = 48;
                    otherwise % 54 Mbps
                        dataRate = 54;
                end
                dataRate = dataRate*1e3/500; % in units of 500 Kbps

            elseif strcmp(packetInfo.Format, "HT-Mixed")
                htConfig = obj.HTConfigObject;
                htConfig.ChannelBandwidth = cbw;
                htConfig.AggregatedMPDU = packetInfo.Aggregation;
                htConfig.MCS = mcs;
                htConfig.NumTransmitAntennas = numSTS; % Set as NumSTS for validation
                htConfig.NumSpaceTimeStreams = numSTS;

                r = wlan.internal.getRateTable(htConfig);
                symbolTime = 4; % in microseconds
                dataRate = (r.NDBPS/symbolTime)*1e3/500; % in units of 500 Kbps

            elseif strcmp(packetInfo.Format, "VHT")
                vhtConfig = obj.VHTConfigObject;
                vhtConfig.ChannelBandwidth = cbw;
                vhtConfig.MCS = mcs;
                vhtConfig.NumTransmitAntennas = numSTS;
                vhtConfig.NumSpaceTimeStreams = numSTS;

                r = wlan.internal.getRateTable(vhtConfig);
                symbolTime = 4; % in microseconds
                dataRate = (r.NDBPS(1)/symbolTime)*1e3/500;

            elseif strcmp(packetInfo.Format, "HE-SU") || strcmp(packetInfo.Format, "HE-EXT-SU")
                heSUConfig = obj.HESUConfigObject;
                heSUConfig.ChannelBandwidth = cbw;
                heSUConfig.MCS = mcs;
                heSUConfig.ExtendedRange = strcmp(packetInfo.Format, "HE-EXT-SU");
                heSUConfig.NumTransmitAntennas = numSTS;
                heSUConfig.NumSpaceTimeStreams = numSTS;
                r = wlan.internal.heRateDependentParameters(ruInfo(heSUConfig).RUSizes,mcs,numSTS,heSUConfig.DCM);
                symbolTime = 16; % in microseconds
                dataRate = (r.NDBPS/symbolTime)*1e3/500;

            elseif strcmp(packetInfo.Format, "EHT-SU")
                ehtSUConfig = wlanEHTMUConfig(cbw);
                ehtSUConfig.User{1}.MCS = mcs;
                ehtSUConfig.NumTransmitAntennas = numSTS;
                [~,r] = wlan.internal.ehtCodingParameters(ehtSUConfig);
                symbolTime = 16; % in microseconds
                dataRate = (r.NDBPS/symbolTime)*1e3/500;
            end
        end
    end
end


%% Local functions

function radiotapFields = radiotapFieldsStruct()
%radiotapFieldsStruct Structure of radiotap flags with default logical values

% Ref: https://www.radiotap.org/fields/defined
radiotapFields = struct('TSFT', 1, ... % 802.11 Time Synchronization Function timer
    'Flags', 1, ...            % Properties of transmitted and received frames
    'Rate', 1, ...             % TX or RX data rate
    'Channel', 1, ...          % Tx or Rx frequency in MHz, followed by flags
    'FHSS', 0, ...             % The hop set and pattern for frequency-hopping radios
    'dBmAntennaSignal', 0, ... % RF signal power at the antenna(decibels from a 1 milliwatt reference)
    'dBmAntennaNoise', 0, ...  % RF noise power at the antenna(decibels from a 1 milliwatt reference)
    'LockQuality', 0, ...      % Quality of Barker code lock, unitless
    'TxAttenuation', 0, ...    % Transmit power expressed as unitless distance from max power set at factory calibration
    'dBTxAttenuation', 0, ...  % Transmit power expressed as decibel distance from max power set at factory calibration
    'dBmTxPower', 1, ...       % Transmit power expressed as dBm (decibels from a 1 milliwatt reference)
    'Antenna', 0, ...          % Unitless indication of the Rx or Tx antenna for this packet
    'dBAntennaSignal', 0, ...  % RF signal power at the antenna, decibel difference from an arbitrary, fixed reference
    'dBAntennaNoise', 0, ...   % RF noise power at the antenna, decibel difference from an arbitrary, fixed reference
    'RxFlags', 0, ...          % Properties of received frames
    'TxFlags', 0, ...          % Properties of transmitted frames
    'DataRetries', 0, ...      % Reserved field
    'ChannelPlus', 0, ...      % Reserved field
    'SomeReserved', 0, ...     % Reserved field
    'MCSInformation', 0, ...   % MCS rate index as in IEEE_802.11n-2009
    'AMPDUStatus', 0, ...      % Frame was received as part of an a-MPDU
    'VHTInformation', 0, ...   % Information for VHT frames
    'FrameTimestamp', 1, ...   % Frame timestamp
    'HEInformation', 0, ...    % Frame was received or transmitted using the HE PHY
    'HEMUInformation', 0, ...  % PPDUs of HE_MU type that wasn't already captured in the regular HE field.
    'HEMUOtherUserInfo', 0, ...
    'ZeroLengthPSDU', 0, ...   % no PSDU captured for this PPDU
    'LSIG', 0, ...             % L-SIG contents, if known
    'TLVs', 0, ...             % type-length-value item list
    'RadiotapNSnext', 0, ...   % Reserved field
    'VendorNSnext', 0, ...     % Reserved field
    'Ext', 0);                 % Reserved field
end

function padLen = getPadLength(dateLen, byteAlignment)
%getPadLength Returns the length of padding for a given byte alignment

padLen = mod(-dateLen, byteAlignment);
end

function byteArray = decToByteArray_le(decValue, len)
%decToByteArray_le Convert a decimal number to little-endian octet vector

byteArray = zeros(1,len);
for i=1:len
    byteArray(i) = mod(decValue, 256);
    decValue = floor(decValue/256);
end
end

function LSIGBytes = formRadiotapLSIGBytes(packetInfo)
%formRadiotapLSIGBytes Returns the LSIG radiotap bytes for the captured
%frame

% Form L-SIG, u16 data1, data2.
% Ref: https://www.radiotap.org/fields/L-SIG.html

LSIGBytes = zeros(1, 4);

% data1_byte1: length known (2)
LSIGBytes(1:2) = [2 0];

% L-SIG length is stored in the higher 12 bits of data2
len = packetInfo.LSIGLength * 16;

% data2: length
LSIGBytes(3:4) = [mod(len, 256), floor(len/256)];
end

function mcsBytes = formRadiotapMCSBytes(eventData)
%formRadiotapMCSBytes Returns the MCS bytes for captured frame

% Ref: https://www.radiotap.org/fields/MCS.html
% Form MCS, u8 known, u8 flags, u8 mcs for HT-format enabled
mcsBytes= zeros(1,3);

packetInfo = eventData.EventData.PPDUParameters;
if strcmp(packetInfo.Format, "HT-Mixed")
    known = 31; % BW known (1), MCS index known (2), Guard Interval known (4), HT Format known (8) , FEC type known (16)

    if strcmp(eventData.EventName, "TransmissionStarted")
        packetBW = eventData.EventData.TransmitBandwidth/1e6;
    else
        packetBW = eventData.EventData.ReceiveBandwidth/1e6;
    end
    switch packetBW
        case 20
            chanBW = 0;
        case 40
            chanBW = 1;
        otherwise
            chanBW = 0; % 20L and 20U sidebands are not implemented, default 0
    end
    flags = chanBW; % Bandwidth
    % FEC type: BCC (0),
    % HT format: mixed (0),
    % Guard Interval: long GI (0)
    mcsBytes = [known flags packetInfo.MCS];
end
end

function VHTInformationBytes = formRadiotapVHTBytes(eventData)
%VHTInformationBytes Return the radiotap VHT bytes for captured frame

if strcmp(eventData.EventName, "TransmissionStarted")
    packetBW = eventData.EventData.TransmitBandwidth/1e6;
else
    packetBW = eventData.EventData.ReceiveBandwidth/1e6;
end

% Ref: https://www.radiotap.org/fields/VHT.html
% 12 bytes VHT info - u16 known, u8 flags, u8 bandwidth, u8 mcs_nss[4],
% u8 coding, u8 group_id, u16 partial_aid
VHTInformationBytes = zeros(1,12);

% known_byte1 - STBC known(1), Guard Interval known(4), BW known(64)
VHTInformationBytes(1:2) = [69 0];

% flags: STBC: 0, Guard Interval: Long GI(0)
VHTInformationBytes(3) = 0;

% Form bandwidth byte (0x1f)
switch packetBW
    case 20
        VHTInformationBytes(4) = 0;
    case 40
        VHTInformationBytes(4) = 1;
    case 80
        VHTInformationBytes(4) = 4;
    case 160
        VHTInformationBytes(4) = 11;
end

% Form mcs_nss byte for 1 user Number of spatial streams is same as number
% of space time streams if STBC is not in use
mcs = eventData.EventData.PPDUParameters.MCS;
numSTS = eventData.EventData.PPDUParameters.NumSpaceTimeStreams;
mcs_nss = 16*mcs + numSTS;
VHTInformationBytes(5) = mcs_nss;
% Keeping coding, group_id, and partial_aid as 0
end

function timestampBytes = formRadiotapTimestampBytes(captureTime)
%formRadiotapTimestampBytes Returns the radiotap timestamp bytes for
%captured frame

% Ref: https://www.radiotap.org/fields/timestamp.html
% 12 bytes field - u64 timestamp, u16 accuracy, u8 unit/position, u8 flags

% Timestamp in nanoseconds represented in 8-octet little-endian
timestampBytes = decToByteArray_le(round(captureTime*1e6,0), 8);

accuracy = [1 0]; % Value 1 in 2-octet little endian

% unit/position - microseconds(1), first bit of MPDU and matches TSFT field(0)
unit_pos = 1;

% flags - Accuracy known(2)
flags = 2;
timestampBytes = [timestampBytes accuracy unit_pos flags];
end

function HEInformationBytes = formRadiotapHEBytes(eventData)
%HEInformationBytes Returns the radiotap HE bytes for the captured frame

% Ref: https://www.radiotap.org/fields/HE.html
% Form HE, u16 data1, data2, data3, data4, data5, data6

HEInformationBytes = zeros(1, 12);

packetInfo = eventData.EventData.PPDUParameters;
% Form data1
if strcmp(packetInfo.Format, "HE-SU")
    data1_LSB = 228; % Radiotap: HE_SU(0), BSS Color known(4), MCS known(32), DCM known(64), Coding known(128)
elseif strcmp(packetInfo.Format, "HE-EXT-SU")
    data1_LSB = 229; % Radiotap: HE_EXT_SU(1), BSS Color known(4), MCS known(32), DCM known(64), Coding known(128)
elseif strcmp(packetInfo.Format, "HE-MU")
    data1_LSB = 230; % Radiotap: HE_MU(2), BSS Color known(4), MCS known(32), DCM known(64), Coding known(128)
elseif strcmp(packetInfo.Format, "HE-TB")
    data1_LSB = 231; % Radiotap: HE_TRIG(3), BSS Color known(4), MCS known(32), DCM known(64), Coding known(128)
else
    data1_LSB = 228; % Show HE_SU for all other frames
end
HEInformationBytes(1) = data1_LSB;
% data1_byte2- STBC known (2), data BW/RU allocation known (64), Doppler known(128)
HEInformationBytes(2) = 194;

% Form data2
% Byte1- GI known(2), TxOP known(64)
HEInformationBytes(3:4) = [66 0];

% Form data3
% Byte1- BSS Color
HEInformationBytes(5) = packetInfo.BSSColor;
% Byte2- MCS , DCM(0), Coding- LDPC(32), STBC(0)
HEInformationBytes(6) = packetInfo.MCS+32; % Radiotap:

if strcmp(eventData.EventName, "TransmissionStarted")
    packetBW = eventData.EventData.TransmitBandwidth/1e6;
else
    packetBW = eventData.EventData.ReceiveBandwidth/1e6;
end
% Form data5 (data4 not necessary)
switch packetBW
    case 20
        cbw = 0;
    case 40
        cbw = 1;
    case 80
        cbw = 2;
    case 160
        cbw = 3;
end
% data5_byte1: Bandwidth (cbw), Guard Interval: 3.2us (32)
HEInformationBytes(9) = cbw+32;
% Keep data5 MSB as 0

% Form data6
% Byte1 - NSTS, Doppler(0)
HEInformationBytes(11) = packetInfo.NumSpaceTimeStreams;
% Byte2 - TXOP
HEInformationBytes(12) = packetInfo.TXOPDuration;
end

function channelBytes = formRadiotapChannelBytes(eventData)
%formRadiotapChannelBytes Return the channel bytes for captured frame

% Ref: https://www.radiotap.org/fields/Channel.html
% Form Channel, u16 frequency, u16 flags
channelBytes = zeros(1,4);

%Convert frequency from Hz to MHz
if strcmp(eventData.EventName, "TransmissionStarted")
    packetFreq = eventData.EventData.TransmitCenterFrequency;
else
    packetFreq = eventData.EventData.ReceiveCenterFrequency;
end
frequencyInMHz = round(packetFreq/1e6);
channelBytes(1:2) = [mod(frequencyInMHz,256), floor(frequencyInMHz/256)]; %Radiotap: Frequency

if frequencyInMHz < 2500 % 2.4GHz band
    channelBytes(3:4) = [192 0]; % flags: OFDM Channel(64), 2GHz spectrum channel (128)
elseif frequencyInMHz < 5895 % 5GHz band
    channelBytes(3:4) = [64 1]; % flags: OFDM Channel(64), 5GHz spectrum channel (256)
else % 6GHz band
    channelBytes(3:4) = [64 0]; % flags: OFDM Channel(64)
end
end

function USIGBytes = formRadiotapUSIGBytes(eventData)
%formRadiotapUSIGBytes Returns the USIG radiotap bytes for the captured frame

packetInfo = eventData.EventData.PPDUParameters;
% Ref: https://www.radiotap.org/fields/U-SIG.html
% Form U-SIG, u32 Common, value, mask.
if strcmp(eventData.EventName, "TransmissionStarted")
    packetBW = eventData.EventData.TransmitBandwidth/1e6;
else
    packetBW = eventData.EventData.ReceiveBandwidth/1e6;
end
switch packetBW
    case 20
        cbw = 0;
    case 40
        cbw = 1;
    case 80
        cbw = 2;
    case 160
        cbw = 3;
    case 320
        cbw = 4;
end

% Form common bytes
common = zeros(1,4);
% Byte1: known - PHY version Identifier(1), BW(2), BSS Color(8),
% TXOP known(16), validate bits checked(64), validate bits OK(128)
common(1) = 219;

% Byte2: BW
if(mod(cbw,2))
    common(2) = 128; % PHY version identifier: 0
end

% Byte3: BW, BSS Color
common(3) = floor(mod(cbw, 8)/2) + 8*packetInfo.BSSColor;

% Byte4: BSS Color, TXOP
common(4) = 2*packetInfo.TXOPDuration + floor(packetInfo.BSSColor/32);

% value = zeros(1,4);
% 33: Type-Length-Value for USIG-Field
% 12: Length of USIG field
USIGBytes = [ 33 0 12 0 common 0 0 0 0 0 0 0 0 ];
end

function EHTBytes = formRadiotapEHTBytes(packetInfo)
%formRadiotapEHTBytes Returns the EHT radiotap bytes for the captured frame

% Ref: https://www.radiotap.org/fields/EHT.html
% Form EHT, u32 known, data1, data2, data3, data4, data5, data6, data7, data8, data9, user_info

known = zeros(1,4);
% known: GI known (4), Number of LTF symbols known (16)
known(1) = 20;

data0 = zeros(1,4);
data0(2) = 7; % GI: 3.2us (2), LTF symbol size: 4x (7)

% Form user_info
user_info = zeros(1,4);
% Byte1: MCS known (2), Coding Known (4), NSS known (16)
user_info(1) = 22;
% Byte2: STA-ID
% Byte3: MCS, STA-ID, Coding: LDPC(8)
user_info(3) = 16*packetInfo.MCS+8;
% Byte4: NSS
user_info(4) = packetInfo.NumSpaceTimeStreams;

% 34: Type-Length-Value for EHT-Field
% 44: Length of the EHT field
EHTBytes = [34 0 44 0 known data0 zeros(1,32) user_info];
end

function nodes = validateNodes(nodes)
% Validate WLAN node inputs
coder.internal.errorIf(iscell(nodes), 'shared_comm_sysmod:pcapWriter:CellArrayOfNodesNotSupported');
validateattributes(nodes(1), "wlanNode", {'scalar'});
end

function fileName = validateFileNames(value)
if iscell(value)
    % Check if it's a cell array of character vectors or strings
    if all(cellfun(@(x) ischar(x) || isstring(x), value))
        validateattributes(value, {'cell'}, {'row'}, 'wlanPCAPWriter', 'FileName');
    end
    fileName = string(value);
else
    % Check if it's a character vector or string
    validateattributes(value, {'char', 'string'}, {'nonempty','row'}, 'wlanPCAPWriter', 'FileName');
    fileName = string(value);
end
end

function fName = assignFileName(fileName, idx, node, isPCAPNG, timestampInput)
%assignFileName Return file names used for each node

% Check if default names are generated for multi-band/multi-link node for PCAP
[numConfigs, configObjects] = getInterfaceDetails(node);
generateDefaultPCAPNames = ~isPCAPNG && numConfigs > 1;

% Check if file name is available for this node
isFileNamePresent = numel(fileName) >= idx;

% File name is available for this node, and it is not a case of default name
% generation for multi-band/multi-link PCAP files
if isFileNamePresent && ~generateDefaultPCAPNames
    fName = fileName(idx);
else
    % Create string for timestamp suffix
    timestamp = string(datetime(timestampInput, Format="yyyyMMdd_HHmmss"));
    
    if isPCAPNG
        % Use node name and node ID to form the file name
        fName = node.Name + "_" + node.ID;

        % Add timestamp as a suffix to the name
        fName = fName+"_"+timestamp;
    else
        for idx = numConfigs:-1:1
            % Use node name and node ID to form the file name
            fName(idx) = node.Name + "_" + node.ID; %#ok<*EMVDF>

            % Add frequency band and channel number a suffix to the name
            fName(idx) = addBandChannelSuffixes(fName(idx)+"_", configObjects(idx).BandAndChannel);

            % Add timestamp as a suffix to the name
            fName(idx) = fName(idx)+"_"+timestamp;
        end
    end
end
end

function bandStr = getBandString(band)
%getBandString Convert band frequency to string

    switch band
        case 2.4
            bandStr = "2G4";
        case 5
            bandStr = "5G";
        case 6
            bandStr = "6G";
        otherwise
            bandStr = "Unknown";
    end
end

function updatedName = addBandChannelSuffixes(name, bandAndChannel)
%addBandChannelSuffixes Add band, channel suffixes to the name

    band = bandAndChannel(1);
    channel = bandAndChannel(2);
    updatedName = name + getBandString(band) + "_CH" + channel;
end

function [numConfigs,configObjects] = getInterfaceDetails(node)
%getInterfaceDetails Return the number and objects of device/link configurations

    if node.IsMLDNode
        numConfigs = node.DeviceConfig.NumLinks;
        configObjects = node.DeviceConfig.LinkConfig;
    else
        numConfigs = numel(node.DeviceConfig);
        configObjects = node.DeviceConfig;
    end
end

% LocalWords:  pcapng radiotap endian mbps kbps mpdu ofdm
