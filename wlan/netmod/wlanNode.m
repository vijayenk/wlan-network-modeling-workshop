classdef wlanNode < wnet.Node
%wlanNode WLAN node
%   NODEOBJ = wlanNode creates a default WLAN node object.
%
%   NODEOBJ = wlanNode(Name=Value) creates one or more similar WLAN node
%   objects with the specified property Name set to the specified Value.
%   You can specify additional name-value arguments in any order as
%   (Name1=Value1, ..., NameN=ValueN). The number of rows in the "Position"
%   property defines the number of nodes created. "Position" must be an
%   N-by-3 matrix where N(>=1) is the number of nodes, and each row must
%   contain three numeric values representing the [X, Y, Z] position of a
%   node in meters. The output, NODEOBJ, is an object or a row vector of
%   objects of the type wlanNode. You can also specify multiple names for
%   "Name" property corresponding to number of nodes created. Multiple
%   names must be specified either as a vector of strings or a cell array
%   of character vectors. If you do not specify the name, the object uses a
%   default name "NodeX", where 'X' is ID of the node. Assuming 'N' nodes
%   are created and 'M' names are supplied, if (M>N) then trailing (M-N)
%   names are ignored, and if (N>M) then trailing (N-M) nodes are set to
%   default names. You can set the "Position" and "Name" properties for
%   multiple nodes simultaneously when you specify them as N-V arguments
%   while creating the object(s). After creating the nodes, you can only
%   set the "Position" and "Name" properties for one node object at a time.
%
%   wlanNode properties (configurable through N-V pair as well as public settable):
%
%   Position                - Position of the node
%
%   wlanNode properties (configurable through N-V pair only):
%
%   Name                    - Name of the node
%   MACModel                - Type of MAC modelled
%   PHYModel                - Type of PHY modelled
%   DeviceConfig            - Device configuration
%
%   wlanNode properties (read-only):
%
%   ID                      - Node identifier
%   Mobility                - Node mobility model object
%   Velocity                - Node velocity
%
%   wlanNode methods:
%
%   associateStations       - Associate stations to WLAN node
%   addTrafficSource        - Add data traffic source to WLAN node
%   addMeshPath             - Add mesh path to WLAN node
%   update                  - Update configuration of WLAN node
%   statistics              - Get the statistics of WLAN node
%   addMobility             - Add mobility model to WLAN node
%   registerEventCallback   - Registers a callback for an event from WLAN node
%
%   % Example 1:
%   %   Create a wlanNode object with the name "MyNode".
%
%   myNode = wlanNode(Name="MyNode");
%   disp(myNode)
%
%   % Example 2:
%   %   Create an access point (AP) node with packet transmission format 
%   %   set to "VHT" and modulation and coding scheme (MCS) value set to 7.
%
%   deviceCfg = wlanDeviceConfig(Mode="AP", ...
%                                TransmissionFormat="VHT", ...
%                                MCS=7);
%   apNode = wlanNode(DeviceConfig=deviceCfg);
%
%   % Example 3:
%   %   Create three station (STA) nodes operating on 5 GHz band and 
%   %   channel number 44.
%
%   % 3 positions for 3 STA nodes
%   staPositions = [0 0 0; 10 0 0; 20 0 0];
%   % Set band and channel
%   deviceCfg = wlanDeviceConfig(Mode="STA", BandAndChannel=[5 44]);
%   % Create an array of 3 STA node objects
%   staNodes = wlanNode(Position=staPositions, DeviceConfig=deviceCfg);
%
%   % Example 4:
%   %   Create, Configure, and Simulate Wireless Local Area Network with one
%   %   AP and one STA.
% 
%   % Initialize wireless network simulator
%   networksimulator = wirelessNetworkSimulator.init;
% 
%   % Create a WLAN node with AP device configuration
%   apDeviceCfg = wlanDeviceConfig(Mode="AP");
%   apNode = wlanNode(Name="AP",DeviceConfig=apDeviceCfg);
% 
%   % Create a WLAN node with STA device configuration
%   staDeviceCfg = wlanDeviceConfig(Mode="STA");
%   staNode = wlanNode(Name="STA",DeviceConfig=staDeviceCfg);
% 
%   % Associate the STA to the AP and configure downlink full buffer traffic
%   associateStations(apNode,staNode,FullBufferTraffic="DL");
% 
%   % Add nodes to the simulation
%   addNodes(networksimulator,[apNode,staNode]);
% 
%   % Run simulation for 1 second
%   run(networksimulator,1);
% 
%   % Retrieve and display statistics of AP and STA
%   apStats = statistics(apNode);
%   staStats = statistics(staNode);
%   disp(apStats)
%   disp(staStats)
%
%   See also wlanDeviceConfig, wlanMultilinkDeviceConfig

%   Copyright 2022-2025 The MathWorks, Inc.

    properties(SetAccess = private)
        %MACModel Type of MAC modelled
        %   Specify the MAC model as "full-mac-with-frame-abstraction" or
        %   "full-mac". After the object is created this property is read-only. If
        %   this property is set as "full-mac", all MAC frame operations are
        %   modelled. If this property is set as "full-mac-with-frame-abstraction",
        %   all MAC operations are modelled but the MAC frame bits are not
        %   generated. Instead, a structure with MAC frame information is passed in
        %   the packet from transmitting node to receiving node. The default value
        %   is "full-mac-with-frame-abstraction".
        MACModel = "full-mac-with-frame-abstraction";

        %PHYModel Type of PHY modelled
        %   Specify the PHY model as "abstract-phy-tgax-evaluation-methodology",
        %   "abstract-phy-tgax-mac-calibration", or "full-phy". After the object is
        %   created this property is read-only. The value
        %   "abstract-phy-tgax-evaluation-methodology" corresponds to the
        %   abstraction mentioned in the Appendix-1 of IEEE 802.11-14/0571r12 TGax
        %   evaluation methodology document and "abstract-phy-tgax-mac-calibration"
        %   corresponds to the abstraction mentioned in the IEEE 802.11-14/0980r16
        %   TGax simulation scenarios document. The value "full-phy" corresponds to
        %   the full physical layer processing. The default value is
        %   "abstract-phy-tgax-evaluation-methodology".
        PHYModel = "abstract-phy-tgax-evaluation-methodology";

        %DeviceConfig Device configuration
        %   Specify the device configuration as a scalar object of type
        %   wlanDeviceConfig or wlanMultilinkDeviceConfig. If you want to configure
        %   more than one non-multilink devices (non-MLD), specify this value as a
        %   vector of wlanDeviceConfig objects. After you create the object, this
        %   property is read-only. When you configure multiple non-MLDs, the Mode
        %   property of wlanDeviceConfig objects in the vector must be set to
        %   either "AP" or "mesh". The default value is an object of the type
        %   wlanDeviceConfig with default parameters.
        DeviceConfig (1, :) {mustBeA(DeviceConfig, ["wlanDeviceConfig" "wlanMultilinkDeviceConfig"])} = wlanDeviceConfig;
    end

    events(Hidden)
        %TransmissionStatus is triggered after decoding the response frames
        % or after waiting for response timeout and determining the transmission
        % status of RTS/MU-RTS and data frames. This event is triggered for each
        % user in the transmission. TransmissionStatus passes the event
        % notification along with this structure as input to the registered
        % callback:
        %   DeviceID           - Scalar representing device identifier.
        %   CurrentTime        - Scalar representing current simulation
        %                        time in seconds.
        %   FrameType          - String representing frame type as one of
        %                        "QoS Data", "RTS", or "MU-RTS".
        %   ReceiverNodeID     - Scalar representing ID of the node to
        %                        which frame is transmitted
        %   MPDUSuccess        - Logical scalar when transmitted frame is
        %                        an MPDU and vector when it is an A-MPDU.
        %                        Each element represents transmission
        %                        status as:
        %                          'true'  - Transmission success
        %                          'false' - Transmission failure
        %   MPDUDiscarded      - Logical scalar when transmitted frame
        %                        is an MPDU and vector when it is an
        %                        A-MPDU. Each element represents whether
        %                        the MPDU is discarded:
        %                          'true'  - MPDU discarded
        %                          'false' - MPDU not discarded
        %                        When FrameType is "RTS" or "MU-RTS",
        %                        MPDUDiscarded flag indicates the status of
        %                        discard of data packets from transmission
        %                        queues.
        %   TimeInQueue        - Scalar when transmitted frame is an
        %                        MPDU and vector when it is an A-MPDU. Each
        %                        element represents time in seconds spent
        %                        by packet in MAC queue. This is applicable
        %                        for MPDUs whose MPDUDiscarded flag is set
        %                        to true.
        %   AccessCategory     - Scalar when transmitted frame is an
        %                        MPDU and vector when it is an A-MPDU. Each
        %                        element represents access category of the
        %                        MPDU, where 0, 1, 2 and 3 represents
        %                        Best-Effort, Background, Video and Voice
        %                        respectively. When FrameType is "RTS" or
        %                        "MU-RTS", it indicates the access category
        %                        of the corresponding "QoS Data".
        %   ResponseRSSI       - Scalar value representing the signal
        %                        strength of the received response in the
        %                        form of an Ack frame, a Block Ack frame,
        %                        or a CTS frame.
        TransmissionStatus;

        %MPDUGenerated is triggered on generation of an MPDU in the MAC
        % layer. This event is triggered only in case of full MAC frame generation.
        % For A-MPDUs, this is triggered when all MPDU(s) in the A-MPDU are
        % generated. MPDUGenerated passes the event notification along with this
        % structure as input to the registered callback:
        %   DeviceID    - Scalar representing device identifier.
        %   CurrentTime - Scalar representing current simulation time in seconds.
        %   MPDU        - Cell array of MPDU(s) where each element is a vector
        %                 containing MPDU bytes in decimal format.
        %   Frequency   - Scalar representing center frequency of transmitting
        %                 PPDU in Hz.
        MPDUGenerated;

        %MPDUDecoded is triggered either when a decode failure is indicated by PHY
        % to MAC layer or on decoding of an MPDU in the MAC layer. In first case,
        % the decode failure may be due to failed preamble decoding or failed
        % header decoding or filtered PPDU or carrier lost. In second case, for
        % A-MPDUs, this is triggered when all MPDU(s) in the A-MPDU are decoded.
        % MPDUDecoded passes the event notification along with this structure as
        % input to the registered callback:
        %   DeviceID        - Scalar representing device identifier.
        %   CurrentTime     - Scalar representing current simulation time in seconds.
        %   MPDU            - Cell array of MPDU(s) where each element is a vector
        %                     containing MPDU bytes in decimal format in case of full
        %                     MAC frames.
        %                     Structure containing information of all MPDUs in a MAC
        %                     frame in case of abstract MAC frames
        %   FCSFail         - Flag representing frame check sequence (FCS) failure at
        %                     MAC. In case of multiple MPDUs, it is a vector with
        %                     values for each MPDU.
        %   PHYDecodeFail   - Logical scalar representing a decode failure at PHY,
        %                     when set to true. When set to true, MPDU and FCSFail
        %                     fields are not applicable.
        %   PPDUStartTime   - Scalar representing PPDU start time in seconds.
        %   Frequency       - Scalar representing center frequency of PPDU in Hz.
        %   Bandwidth       - Scalar representing bandwidth of PPDU in Hz.
        MPDUDecoded;

        %AppDataReceived is triggered after the decoded packet is received
        % by the application from the MAC layer. AppDataReceived passes the event
        % notification along with this structure as input to the registered
        % callback:
        %   Packet               - Vector of data bytes. When MAC packet is
        %                          abstracted, Data contains empty value.
        %   PacketLength         - Length of the packet in bytes.
        %   PacketID             - Unique identifier for the packet assigned by
        %                          the source node, to identify the packet.
        %   PacketGenerationTime - Timestamp of the packet generation in seconds.
        %   SourceNodeID         - Source transmitter node identifier.
        %   AccessCategory       - Scalar representing access category of
        %                          transmitted frame. This value can be 0, 1, 2, or
        %                          3 representing Best-Effort, Background, Video,
        %                          or Voice respectively. Applicable only when
        %                          'FrameType' is 'QoS Data'.
        %   CurrentTime          - Scalar representing the current simulation
        %                          time in seconds.
        AppDataReceived

        %StateChanged is triggered on any change in the state of the device.
        % StateChanged passes the event notification along with this structure as
        % input to the registered callback:
        %   DeviceID    - Scalar representing device identifier.
        %   CurrentTime - Scalar representing current simulation time in seconds.
        %   State       - State of device specified as "Idle", "Sleep", "Contention",
        %                 "Transmission", or "Reception".
        %   Duration    - Scalar representing state duration.
        %   Frequency   - Scalar representing center frequency of transmitted
        %                 waveform in Hz. Applicable only when State is
        %                 "Transmission.
        %   Bandwidth   - Scalar representing bandwidth of transmitted waveform
        %                 in Hz. Applicable only when State is "Transmission".
        StateChanged;
    end

    properties(SetAccess=private, Hidden)
        %MACFrameAbstraction MAC frame abstraction
        %   Set this property to true to indicate MAC frame is abstracted. After
        %   the object is created this property is read-only. The default value is
        %   true. MACFrameAbstraction aliases MACModel which is going to replace
        %   this property.
        MACFrameAbstraction (1, 1) logical = true;

        %PHYAbstractionMethod PHY abstraction method
        %   Specify the PHY abstraction method as "tgax-evaluation-methodology",
        %   "tgax-mac-calibration", or "none". After the object is created this
        %   property is read-only. The default value is
        %   "tgax-evaluation-methodology". PHYAbstractionMethod aliases PHYModel
        %   which is going to replace this property.
        PHYAbstractionMethod = "tgax-evaluation-methodology";
    end

    properties (Hidden)
        %MeshBridge Mesh bridging object
        %   This property is an object of type wlan.internal.mesh.MeshBridge. This
        %   object contains methods and properties related to mesh forwarding.
        MeshBridge

        %Application WLAN application layer object
        %   Specify this property as an object of type
        %   wnet.internal.trafficManager. This object contains methods and
        %   properties related to application layer.
        Application;

        %SharedMAC WLAN shared MAC layer object
        %   This property is a vector of objects of type wlan.internal.mac.SharedMAC.
        %   This object performs functionalities like sequence number assignment,
        %   shared queue maintenance, association context maintenance and link
        %   management. This is a scalar when the node contains a multilink device
        %   (MLD) and is common to all the links in the MLD. This is also a scalar
        %   when the node supports only a single non-MLD. Otherwise, this property
        %   is specified as a vector of objects.
        SharedMAC;

        %MAC WLAN EDCA MAC layer object
        %   This property is a vector of objects of type wlan.internal.mac.edcaMAC.
        %   This object maintains WLAN MAC layer state machine and is responsible
        %   for contention, transmit, and receive operations. This is a scalar when
        %   the node supports only a single non-MLD or an MLD with single link .
        %   Otherwise, this property is specified as a vector of objects.
        MAC;

        %PHYTx WLAN physical layer transmitter object
        %   This property is a vector of abstracted PHY objects
        %   wlan.internal.phy.AbstractPHYTx. This object contains methods and
        %   properties related to WLAN PHY transmitter. This is a scalar when the
        %   node supports only a single device. Otherwise, this property is
        %   specified as a vector of objects.
        PHYTx;

        %PHYRx WLAN physical layer receiver object
        %   This property is a vector of abstracted PHY objects
        %   wlan.internal.phy.AbstractPHYRx. This object contains methods and
        %   properties related to WLAN PHY receiver. This is a scalar when the node
        %   supports only a single device. Otherwise, this property is specified as
        %   a vector of objects.
        PHYRx;

        %PacketLatency Packet latency of each application packet received
        %   This property is a vector of numeric values. Each value
        %   specifies the latency computed for every packet received in
        %   microseconds.
        PacketLatency = 0;

        %PacketLatencyIdx Current index of the packet latency vector
        %   This property is a numeric value. This property specifies current index
        %   of the packet latency vector.
        PacketLatencyIdx = 0;

        %RemoteSTAInfo Contains information of associated STAs, associated AP
        %or peer mesh, or other APs detected in the network
        %   This property is an array of structures of size N x 1. N is the number
        %   of associated STAs in case of AP. N equals 1 in case of STA. Each
        %   structure contains following fields:
        %     Mode            - Operating mode of the node indicating if it is a 
        %                       STA, AP, mesh
        %     NodeID          - Node identifier of associated STA or AP
        %     MACAddress      - MAC address of associated STA or AP. Contains one
        %                       or multiple addresses if STA and AP are MLDs due to
        %                       multilink
        %     DeviceID        - Device index or link index/indices on which
        %                       AP is connected to the STA or vice-versa
        %     AID             - Association identifier (AID) assigned to STA.
        %                       Not applicable for AP.
        %     IsMLD           - Flag indicating whether associated STA or AP is
        %                       a multilink device (MLD)
        %     EnhancedMLMode  - Scalar indicating mode of enhanced multilink
        %                       operation (MLO). Applicable only when the
        %                       associated STA is an MLD. 0 and 1 represents STR
        %                       and EMLSR respectively. Not applicable for AP.
        %     NumEMLPadBytes  - Number of padding bytes to include in initial
        %                       control frame (ICF). Applicable only for associated
        %                       EMLSR STA.
        %     Bandwidth       - Bandwidth to use for communication with associated
        %                       STA or AP. If AP and STA are MLDs, this field is a
        %                       scalar or vector. Units are in MHz.
        %   In case of mesh nodes, this property contains information of peer mesh
        %   nodes. Applicable fields for mesh are NodeID (peer mesh node ID),
        %   MACAddress (peer mesh node MAC address) and DeviceID (device ID on
        %   which a mesh node is connected to its peer mesh node).
        RemoteSTAInfo = struct([]);

        %RemoteSTAInfoTemplate Structure template of the node information to be
        %stored
        RemoteSTAInfoTemplate = wlan.internal.utils.defaultRemoteSTAInfo;

        %RxAppLatencyStats Latency statistics captured at the application layer of
        %the receiver
        %   This property is an array of structures. Each element represents a
        %   structure for a unique source. Each structure includes the following
        %   fields:
        %     SourceNodeID              - Node identifier of a specific source
        %     ReceivedPackets           - Total number of packets received from the
        %                                 source node
        %     ReceivedBytes             - Total number of bytes received from the
        %                                 source node
        %     AggregatePacketLatency    - Total latency of all packets received
        %                                 from the source node in seconds
        %     AveragePacketLatency      - Average latency of all packets received
        %                                 from the source node in seconds
        RxAppLatencyStats = struct([]);

        %RxAppLatencyStatsTemplate Structure template of the latency information to
        %be stored
        %   Upon receiving the initial packet from a source node, the node creates
        %   a structure and stores the node ID of the source Node by initializing
        %   the SourceNodeID field. The object then adds this structure to the
        %   RxAppLatencyStats property.
        RxAppLatencyStatsTemplate = struct('SourceNodeID', 0, ...
            'ReceivedPackets', 0, ...
            'ReceivedBytes', 0, ...
            'AggregatePacketLatency', 0, ...
            'AveragePacketLatency', 0);

        %MeshNeighbors Mesh neighbor node IDs
        %   This property is an array of the IDs of mesh nodes that are identified
        %   as neighbors.
        MeshNeighbors;

        %InterferenceFidelity Fidelity level of modeling the interference
        %   This property is an array of size 1-by-N, where N is the number
        %   of devices. Each element represents the type of interference
        %   modeling:
        %   0   -   'co-channel'
        %   1   -   'overlapping-adjacent-channel'
        %   2   -   'non-overlapping-adjacent-channel'
        InterferenceFidelity;

        %IsPHYAbstracted Is PHY abstracted
        IsPHYAbstracted = true;

        %IsMACFrameAbstracted Is MAC frame abstracted
        IsMACFrameAbstracted = true;

        %IsMeshNode Is mesh capable node
        IsMeshNode = false;

        %IsAPNode Is an AP node
        IsAPNode = false;

        %IsMLDNode Is the node with multilink device (MLD)
        IsMLDNode = false;

        %IsEMLSRSTA Is a multilink device (MLD) STA node with EMLSR mode
        IsEMLSRSTA = false;

        %NonFullBufferTrafficEnabled Indicates whether non full buffer traffic is
        %enabled
        NonFullBufferTrafficEnabled = false;

        %FullBufferTrafficEnabled Indicates whether full buffer traffic is enabled
        FullBufferTrafficEnabled = false;

        %FullBufferContextTemplate Template structure for full buffer traffic context 
        FullBufferContextTemplate = struct('DestinationID', 0, 'DestinationName', '', 'MACQueuePacket', [], 'SourceDeviceIdx', 1, 'IsGroupAddress', false, 'IsMLDDestination', false);

        %FullBufferContext Structure containing context for full buffer traffic
        FullBufferContext;

        %FullBufferSourceNodeIDs Vector containing the node IDs of associated
        %STAs at which full buffer traffic is enabled in case of AP and vice-versa
        FullBufferSourceNodeIDs = [];

        %FullBufferAppPacket Structure containing full buffer application packet info
        FullBufferAppPacket = wlan.internal.utils.defaultMSDU;

        %MACQueuePacketTemplate Template structure containing MPDU fields
        %for MAC Tx queue
        MACQueuePacketTemplate = wlan.internal.utils.defaultMPDU;

        %PacketIDCounter Packet ID counter for full buffer traffic
        PacketIDCounter;

        %LastRunTime Timestamp (in seconds) when the node last ran. This gets
        %updated every time the node runs
        LastRunTime = 0;

        % Scalar value indicating total packet latency at application layer for all
        % the applications.
        TotalPacketLatency = 0;

        %MaxUsers Maximum number of users a node can support in downlink MU
        MaxUsers = 9;

        %FullBufferPacketSize Packet size for full buffer traffic
        FullBufferPacketSize = 1500;

        % Frame formats
        NonHT;
        HTMixed;
        VHT;
        HE_SU;
        HE_EXT_SU;
        HE_MU;
        HE_TB;
        EHT_SU;

        % Data is empty
        PacketTypeEmpty;

        % Data containing IQ samples (Full MAC + Full PHY)
        DataTypeIQData;

        % Data containing MAC PPDU bits (Full MAC + ABS PHY)
        DataTypeMACFrameBits;

        % Data containing MAC configuration structure (ABS MAC + ABS PHY)
        DataTypeMACFrameStruct;

        % Maximum number of STAs that can be associated on an AP device
        AssociationLimit = 2007;

        % Flag to disable validations during setup
        DisableValidation = false;
    end

    % Configuration for internal capabilities
    properties (Hidden)
        %IncludeVector Flag indicating whether to include Tx/Rx vector in
        %MPDUDecoded, TransmissionStarted and ReceptionEnded events notification
        %data
        %   Specify this property as true to include Tx vector in notification data
        %   of TransmissionStarted event and Rx vector in notification data of
        %   ReceptionEnded and MPDUDecoded events. The default
        %   value is false.
        IncludeVector = false;
        
        %MaxSupportedStandard Max supported standard
        %   Specify this property as an integer value in the range [0, 5]
        %   representing standards 802.11a, 802.11g, 802.11n, 802.11ac,
        %   802.11ax, 802.11be. This property takes the enumerated constant
        %   values from wlan.internal.Constants.Std80211XX.
        MaxSupportedStandard = wlan.internal.Constants.Std80211be;

        %AllowEDCAParamsUpdate Allow updating EDCA parameters at STA from beacon
        %   Specify this property as true to let the STA adopt EDCA
        %   parameters received in the beacon frame from its AP. This is
        %   applicable for only STA mode.
        AllowEDCAParamsUpdate = false;
    end

    properties (Dependent,Hidden,SetAccess=private)
        %InterferenceBuffer Interference buffer object
        %   This property is a scalar or vector of interference buffer objects
        %   wnet.internal.interferenceBuffer. This object contains methods and
        %   properties related to modeling the interference in the PHY receiver.
        %   This is a scalar when the node supports only a single device.
        %   Otherwise, this property is returned as a row vector of objects.
        InterferenceBuffer
    end

    properties (Access = protected)
        %RxInfo Receiver information
        RxInfo;

        %NumAssociatedSTAsPerDevice Number of associated STAs on each device if
        %node is an AP
        NumAssociatedSTAsPerDevice = 0;

        %HasStarted Indicates if the node has started running in the simulation
        HasStarted = false;
    end

    properties(SetAccess=protected, Hidden)
        %NumDevices Number of devices (network interfaces) in the node
        NumDevices = 1

        %TransmitterBuffer Transmitted packets to be distributed to other nodes
        % Vector of packets of type wirelessPacket
        % transmitted by this node and to be sent over the channel
        TransmitterBuffer

        %ReceiveBuffer Received packets to be processed by the node
        % Cell array of packets of type wirelessPacket
        % received after applying channel model
        ReceiveBuffer = cell(0,1)

        %ReceiveBufferIdx Number of packets in the ReceiveBuffer
        ReceiveBufferIdx = 0

        %ReceiveFrequency Reception center frequencies of the node
        % Vector of size N, where N is the number of interfaces. The
        % units are in Hz
        ReceiveFrequency

        %ReceiveBandwidth Reception bandwidths of the node
        % Vector of size N, where N is the number of interfaces. The
        % units are in Hz
        ReceiveBandwidth

        %NumTransmitAntennas Number of transmit antennas for each device on the
        %node
        NumTransmitAntennas
    end

    properties (Hidden, Constant)
        MACModel_Values = ["full-mac", "full-mac-with-frame-abstraction"];

        PHYModel_Values = ["abstract-phy-tgax-evaluation-methodology", "abstract-phy-tgax-mac-calibration", "full-phy"];

        PHYAbstractionMethod_Values = ["tgax-evaluation-methodology", "tgax-mac-calibration", "none"];

        BroadcastID = 65535;
    end

    methods
        function obj = wlanNode(varargin)
            % Name-value pair check
            if mod(nargin,2) == 1
                error(message('wlan:ConfigBase:InvalidPVPairs'))
            end

            % Initialize with defaults, in case user doesn't configure
            obj.SharedMAC = wlan.internal.mac.SharedMAC.empty;
            obj.MAC = wlan.internal.mac.edcaMAC.empty;
            obj.MeshBridge = wlan.internal.mesh.MeshBridge(obj.MAC);
            obj.ReceiveFrequency = zeros(1, 0);
            obj.DeviceConfig = wlanDeviceConfig;
            obj.FullBufferContext = obj.FullBufferContextTemplate;

            % Initialize constant properties
            obj.NonHT = wlan.internal.FrameFormats.NonHT;
            obj.HTMixed = wlan.internal.FrameFormats.HTMixed;
            obj.VHT = wlan.internal.FrameFormats.VHT;
            obj.HE_SU = wlan.internal.FrameFormats.HE_SU;
            obj.HE_EXT_SU = wlan.internal.FrameFormats.HE_EXT_SU;
            obj.HE_MU = wlan.internal.FrameFormats.HE_MU;
            obj.HE_TB = wlan.internal.FrameFormats.HE_TB;
            obj.EHT_SU = wlan.internal.FrameFormats.EHT_SU;
            obj.PacketTypeEmpty = wlan.internal.Constants.PacketTypeEmpty;
            obj.DataTypeIQData = wlan.internal.Constants.DataTypeIQData;
            obj.DataTypeMACFrameBits = wlan.internal.Constants.DataTypeMACFrameBits;
            obj.DataTypeMACFrameStruct = wlan.internal.Constants.DataTypeMACFrameStruct;

            numNodes = 1;
            isMACModelSpecified = false;
            isMACFrameAbstractionSpecified = false;
            isPHYModelSpecified = false;
            isPHYAbstractionMethodSpecified = false;
            disableValidation = false;
            if nargin > 0
                % Identify number of nodes user intends to create based on
                % Position value
                for idx = 1:2:nargin-1
                    % Search the presence of 'Position' N-V pair argument
                    if strcmp(varargin{idx},"Position")
                        validateattributes(varargin{idx+1}, {'numeric'}, {'nonempty', 'ncols', 3, 'finite'}, 'wlanNode', 'Position');
                        positionValue = varargin{idx+1};
                        numNodes = size(varargin{idx+1}, 1);
                    end
                    % Search the presence of 'Name' N-V pair argument
                    if strcmp(varargin{idx},"Name")
                        nameValue = string(varargin{idx+1});
                        validateattributes(nameValue,{'char','string'},{'vector'},'wlanNode',"Name"); %,idx)
                    end
                    % Identify MACModel, PHYModel, MACFrameAbstraction, and
                    % PHYAbstractionMethod properties to check if both are assigned.
                    if strcmp(varargin{idx},"MACModel")
                        if isMACFrameAbstractionSpecified
                            error(message("wlan:wlanNode:MACModelSpecifiedWithTwoProperties"))
                        end
                        isMACModelSpecified = true;
                    elseif strcmp(varargin{idx},"MACFrameAbstraction")
                        if isMACModelSpecified
                            error(message("wlan:wlanNode:MACModelSpecifiedWithTwoProperties"))
                        end
                        isMACFrameAbstractionSpecified = true;
                    elseif strcmp(varargin{idx},"PHYModel")
                        if isPHYAbstractionMethodSpecified
                            error(message("wlan:wlanNode:PHYModelSpecifiedWithTwoProperties"))
                        end
                        isPHYModelSpecified = true;
                    elseif strcmp(varargin{idx},"PHYAbstractionMethod")
                        if isPHYModelSpecified
                            error(message( "wlan:wlanNode:PHYModelSpecifiedWithTwoProperties"))
                        end
                        isPHYAbstractionMethodSpecified = true;
                    end
                    % Search the presence of 'DisableValidation' N-V pair argument
                    if strcmp(varargin{idx},"DisableValidation")
                        disableValidation = varargin{idx+1};
                    end
                end

                obj(1:numNodes) = obj;
                className = class(obj(1));
                classFunc = str2func(className);
                for idx = 2:numNodes
                    % To support vectorization when inheriting "wlanNode", instantiate
                    % class based on the object's class
                    obj(idx) = classFunc('DisableValidation',disableValidation);
                end

                % Set the configuration of nodes as per the N-V pairs
                for idx = 1:2:nargin-1
                    name = varargin{idx};
                    value = varargin{idx+1};
                    switch (name)
                        case 'Position'
                            % Set position for nodes
                            for j = 1:numNodes
                                obj(j).Position = positionValue(j, :);
                            end
                        case 'Name'
                            % Set name for nodes. If name is not supplied
                            % for all nodes, then leave the trailing nodes
                            % with default names
                            nameCount = min(numel(nameValue), numNodes);
                            for j=1:nameCount
                                obj(j).Name = nameValue(j);
                            end
                        otherwise
                            % Make all the nodes identical by setting same
                            % value for all the configurable properties,
                            % except position and name
                            [obj.(char(name))] = deal(value);

                            if strcmp(name, "MACModel") || strcmp(name, "PHYModel")
                                for j = 1:numNodes
                                    setAlias(obj(j), name, obj(j).(char(name)));
                                end
                            end
                    end
                end
            end

            if isa(obj(1).DeviceConfig(1), 'wlanMultilinkDeviceConfig') && numel(obj(1).DeviceConfig) > 1
                error(message('wlan:wlanNode:InvalidNumMLD'))
            end

            [obj.IsMLDNode] = deal(isa(obj(1).DeviceConfig(1), 'wlanMultilinkDeviceConfig'));
            
            appPacketContext = struct(AccessCategory=0, DestinationNodeID=0, DestinationNodeName="", TechnologyType=wnet.TechnologyType.WLAN); % App packet context fields
            for idx = 1:numNodes
                % Application

                % Use weak-references for cross-linking handle objects
                objWeakRef = matlab.lang.WeakReference(obj(idx));
                notificationFcn = @(eventName, eventData) objWeakRef.Handle.triggerEvent(eventName, eventData); % Function handle for event notification
                sendPacketFcn = @(packet) wlan.internal.utils.sendPacketToMAC(obj(idx), packet);                            % Function handle for pushing packets from App into MAC
                obj(idx).Application = wnet.internal.trafficManager(obj(idx).ID, sendPacketFcn, ...
                    notificationFcn, PacketContext=appPacketContext, DataAbstraction=strcmp(obj(idx).MACModel, "full-mac-with-frame-abstraction"), ...
                    NodeName=obj(idx).Name, NotificationContext="AccessCategory"); %#ok<*AGROW>

                % Validate the configuration
                setFrequencies(obj(idx));
                wlan.internal.validation.multipleOperatingFreq(obj(idx));

                % Mode flags
                obj(idx).IsMeshNode = ~obj(idx).IsMLDNode && any([obj(idx).DeviceConfig(:).IsMeshDevice]);
                obj(idx).IsAPNode = any([obj(idx).DeviceConfig(:).IsAPDevice]);

                if strcmpi(obj(idx).PHYModel, "full-phy")
                    obj(idx).IsPHYAbstracted = false;
                    obj(idx).PHYTx = wlan.internal.phy.FullPHYTx.empty;
                    obj(idx).PHYRx = wlan.internal.phy.FullPHYRx.empty;
                else
                    obj(idx).PHYTx = wlan.internal.phy.AbstractPHYTx.empty;
                    obj(idx).PHYRx = wlan.internal.phy.AbstractPHYRx.empty;
                end
                if strcmpi(obj(idx).MACModel, 'full-mac')
                    obj(idx).IsMACFrameAbstracted = false;
                end

                % Initialize
                init(obj(idx));
            end
        end

        function set.MACModel(obj, value)
            value = validatestring(value, obj.MACModel_Values, 'wlanNode', 'MACModel');
            obj.MACModel = value;
        end

        function set.PHYModel(obj, value)
            value = validatestring(value, obj.PHYModel_Values, 'wlanNode', 'PHYModel');
            obj.PHYModel = value;
        end

        function set.PHYAbstractionMethod(obj, value)
            value = validatestring(value, obj.PHYAbstractionMethod_Values, 'wlanNode', 'PHYAbstractionMethod');
            obj.PHYAbstractionMethod = value;
            setAlias(obj, 'PHYAbstractionMethod', value);
        end

        function set.MACFrameAbstraction(obj, value)
            obj.MACFrameAbstraction = value;
            setAlias(obj, 'MACFrameAbstraction', value);
        end

        function set.IncludeVector(obj, value)
            obj.IncludeVector = value;
            updateMACParameter(obj, "IncludeVector", value);
        end

        function set.AllowEDCAParamsUpdate(obj, value)
            obj.AllowEDCAParamsUpdate = value;
            updateMACParameter(obj, "AllowEDCAParamsUpdate", value);
        end

        function value = get.InterferenceBuffer(obj)
            value = [obj.PHYRx.Interference];
        end
    end

    methods
        function associateStations(obj, associatedSTAs, varargin)
        %associateStations Associate stations with a WLAN AP node
        %
        %   associateStations(OBJ,ASSOCIATEDSTAS) associates the stations in
        %   ASSOCIATEDSTAS to the AP node specified by OBJ.
        %
        %   OBJ is an object of type wlanNode with Mode property of at least one
        %   device in DeviceConfig set to "AP".
        %
        %   ASSOCIATEDSTAS is a scalar or a vector of wlanNode objects of STA(s) in
        %   the BSS. Mode property must be set to "STA" within the DeviceConfig
        %   property of each of these objects.
        %
        %   associateStations(...,Name=Value) specifies additional name-value
        %   arguments described below. When a name-value argument is not specified,
        %   the function uses its default value.
        %
        %   BandAndChannel - Band and channel for the BSS.
        %   For association between non-multilink device (non-MLD) AP and non-MLD
        %   STAs or MLD AP and non-MLD STAs,
        %   * Specify the value as a row vector containing two elements, [band
        %     channel]. Accepted values for band are 2.4, 5 and 6 (GHz). channel is
        %     any valid channel number in the specified band.
        %   * The default value is the band and channel at AP whose primary 20 MHz
        %     subchannel is included in operating frequency range of STAs.
        %   For association between MLD AP and MLD STAs,
        %   * Specify the value as an N-by-2 matrix with each row containing [band
        %     channel].
        %   * The default value is a matrix with band and channel of each
        %     configured link of AP in a row.
        %
        %   FullBufferTraffic - Direction of full buffer traffic between the AP and
        %                       stations.
        %   Allowed values for this parameter:
        %     "off"   - Full buffer traffic is disabled.
        %     "on"    - Two-way full buffer traffic.
        %     "DL"    - Downlink traffic from AP to stations.
        %     "UL"    - Uplink traffic from stations to the AP.
        %   When full buffer traffic is enabled,
        %   * Packet size is 1500 and access category (AC) is 0.
        %   * Custom traffic source cannot be added for AC 0 through addTrafficSource.
        %   The default value is "off".

            narginchk(2, 6);

            % Validate inputs
            associationNVParams = wlan.internal.validation.associationParams(obj, associatedSTAs, varargin);
            % Find the AP and STA device/link indices on which association must be
            % performed. Also, get the primary20 index in STA and bandwidth used for
            % communication between AP and STA.
            [apDeviceIdx, staDeviceIdx, staPrimary20Idx, commonBandwidth] = wlan.internal.findDevicesToAssociate(obj, associatedSTAs, associationNVParams);

            if ~obj.IsMLDNode % Non-MLD AP
                % Association is done only on one frequency (link)
                numLinks = 1;
            else
                % Association is done on multiple frequencies (links)
                numLinks = numel(obj.DeviceConfig.LinkConfig);
            end

            numSTA = numel(associatedSTAs);
            assocIndices = [];
            % Configure information of AP at associated STA and vice-versa
            for staIdx = 1:numSTA
                staNode = associatedSTAs(staIdx);

                if ~staNode.IsMLDNode
                    % Association is performed with only one AP device and the corresponding AP
                    % device index is present at 'staIdx' index in apDeviceIdx variable.
                    numAssociationsPerSTA = 1;
                    if ~isempty(assocIndices)
                        assocIndices = assocIndices(end)+1;
                    else
                        assocIndices = staIdx;
                    end
                    % Check if non-MLD STA is already associated
                    existingAssociation = false;
                    if ~isempty(obj.RemoteSTAInfo) && any(staNode.ID == [obj.RemoteSTAInfo(:).NodeID])
                        idxLogical = (staNode.ID == [obj.RemoteSTAInfo(:).NodeID]);
                        existingAssociation = strcmp(staNode.MAC.MACAddress, obj.RemoteSTAInfo(idxLogical).MACAddress) && (apDeviceIdx(staIdx) == obj.RemoteSTAInfo(idxLogical).DeviceID);
                    end
                else
                    % Association is performed on multiple links of AP. Get the indices to
                    % access the corresponding AP links from apDeviceIdx variable.
                    numAssociationsPerSTA = numLinks;
                    if ~isempty(assocIndices)
                        assocIndices = assocIndices(end)+1:assocIndices(end)+numLinks;
                    else
                        assocIndices = (staIdx-1)*numLinks + 1:staIdx*numLinks;
                    end
                    % Check if MLD STA is already associated
                    existingAssociation = ~isempty(obj.RemoteSTAInfo) && any(staNode.ID == [obj.RemoteSTAInfo(:).NodeID]);
                end

                if existingAssociation
                    error(message('wlan:wlanNode:ExistingAssociation', staNode.Name, obj.Name))
                end

                % Association information
                associatedSTAMACAddress = repmat('0', numAssociationsPerSTA, 12);
                associatedAPDeviceIDs = zeros(numAssociationsPerSTA, 1);
                associatedSTAAID = 0;
                associatedAPMACAddress = repmat('0', numAssociationsPerSTA, 12);
                associatedSTADeviceIDs = zeros(numAssociationsPerSTA, 1);
                associatedBandwidthInHz = zeros(numAssociationsPerSTA, 1);

                for idx = 1:numAssociationsPerSTA
                    assocIdx = assocIndices(idx);
                    wlan.internal.validation.associationCompatibility(obj, staNode, apDeviceIdx(assocIdx), staDeviceIdx(assocIdx));

                    % Check if association limit exceeded at AP
                    if obj.IsMLDNode
                        if obj.NumAssociatedSTAsPerDevice+1 > obj.AssociationLimit
                            error(message('wlan:wlanNode:AssociationLimitExceeded', staNode.Name, obj.Name, obj.AssociationLimit))
                        end
                    else
                        if obj.NumAssociatedSTAsPerDevice(apDeviceIdx(assocIdx))+1 > obj.AssociationLimit
                            error(message('wlan:wlanNode:AssociationLimitExceeded', staNode.Name, obj.Name, obj.AssociationLimit))
                        end
                    end

                    % Add connection info to the station node (BSSID and Basic
                    % rates)
                    bssid = obj.MAC(apDeviceIdx(assocIdx)).MACAddress;
                    basicRates = obj.MAC(apDeviceIdx(assocIdx)).BasicRates;
                    bssColor = obj.MAC(apDeviceIdx(assocIdx)).BSSColor;
                    if obj.IsMLDNode
                        if idx == 1
                            % Assign AID during setup on first link. An AP MLD assigns single AID value
                            % to STA MLD. Reference: Section 35.3.5 of IEEE P802.11be/D5.0.
                            obj.NumAssociatedSTAsPerDevice = obj.NumAssociatedSTAsPerDevice + 1;
                            associatedSTAAID = obj.NumAssociatedSTAsPerDevice;
                        end
                    else
                        obj.NumAssociatedSTAsPerDevice(apDeviceIdx(assocIdx)) = obj.NumAssociatedSTAsPerDevice(apDeviceIdx(assocIdx)) + 1;
                        associatedSTAAID = obj.NumAssociatedSTAsPerDevice(apDeviceIdx(assocIdx));
                    end

                    % Add connection specific information (BSSID, AID, etc.) to MAC/PHY
                    addConnection(staNode.MAC(staDeviceIdx(assocIdx)), "STA", associatedSTAAID, bssColor, bssid, basicRates);
                    addConnection(staNode.PHYRx(staDeviceIdx(assocIdx)), "STA", associatedSTAAID, bssColor);
                    addConnection(obj.PHYRx(apDeviceIdx(assocIdx)), "AP", associatedSTAAID);

                    % Add rate control information
                    setRateControlContext(obj, staNode, apDeviceIdx(assocIdx), basicRates);
                    setRateControlContext(staNode, obj, staDeviceIdx(assocIdx), basicRates);

                    % Add primary channel information at AP and STA MAC and phy modules
                    devCfg = wlan.internal.utils.getDeviceConfig(obj, apDeviceIdx(assocIdx));
                    [~,primaryChannelFrequency] = wlan.internal.utils.getPrimaryChannel(devCfg.BandAndChannel, devCfg.ChannelBandwidth, devCfg.PrimaryChannelIndex);
                    wlan.internal.utils.setPrimaryChannelInfoAtLayers(obj, apDeviceIdx(assocIdx), devCfg.PrimaryChannelIndex, primaryChannelFrequency);
                    wlan.internal.utils.setPrimaryChannelInfoAtLayers(staNode, staDeviceIdx(assocIdx), staPrimary20Idx(assocIdx), primaryChannelFrequency);

                    % Store association information
                    associatedSTAMACAddress(idx, :) = staNode.MAC(staDeviceIdx(assocIdx)).MACAddress;
                    associatedAPDeviceIDs(idx) = apDeviceIdx(assocIdx);
                    associatedAPMACAddress(idx, :) = obj.MAC(apDeviceIdx(assocIdx)).MACAddress;
                    associatedSTADeviceIDs(idx) = staDeviceIdx(assocIdx);
                    associatedBandwidthInHz(idx) = commonBandwidth(assocIdx);

                    % If UL OFDMA is enabled at AP, assume that all the stations in BSS would
                    % support trigger based transmissions. Indicate the stations that AP is
                    % configured to trigger UL OFDMA transmissions.
                    if obj.MAC(apDeviceIdx(assocIdx)).ULOFDMAEnabled
                        staNode.MAC(staDeviceIdx(assocIdx)).ULOFDMAEnabledAtAP = true;
                    end

                    staMLDMode = 0; % 0 indicates STR. Applicable only if STA is an MLD STA.
                    if staNode.IsMLDNode && strcmp(staNode.DeviceConfig.EnhancedMultilinkMode, "EMLSR")
                        staMLDMode = 1; % 1 indicates EMLSR (currently supported enhanced multilink mode)
                        if obj.DeviceConfig.LinkConfig(apDeviceIdx(assocIdx)).NumTransmitAntennas ~= staNode.MAC(staDeviceIdx(assocIdx)).NumTransmitAntennas
                            error(message('wlan:wlanNode:UnsupportedNumTxAntennasEMLSR', obj.Name, staNode.Name))
                        end
                        % In case of EMLSR STA MLD associated to an AP MLD, store medium sync delay
                        % information
                        if obj.IsMLDNode
                            addMediumSyncDelayInfo(staNode.MAC(staDeviceIdx(assocIdx)), round(obj.DeviceConfig.MediumSyncDuration*32e3), ...
                                obj.DeviceConfig.MediumSyncEDThreshold, obj.DeviceConfig.MediumSyncMaxTXOPs);
                        end
                    end
                end

                % Beacon transmissions are not supported at AP associated with an EMLSR STA
                if staMLDMode && obj.IsMLDNode && ~any([obj.DeviceConfig.LinkConfig(:).BeaconInterval] == inf)
                    error(message('wlan:wlanNode:UnsupportedBeaconAPMLD', obj.Name))
                end

                % Add information of STA at AP
                staInfo = obj.RemoteSTAInfoTemplate;
				staInfo.Mode = "STA";
                staInfo.NodeID = staNode.ID;
                staInfo.MACAddress = associatedSTAMACAddress;
                staInfo.DeviceID = associatedAPDeviceIDs;
                staInfo.AID = associatedSTAAID;
                staInfo.IsMLD = staNode.IsMLDNode;
                staInfo.EnhancedMLMode = staMLDMode;
                staInfo.NumEMLPadBytes = staNode.SharedMAC.NumPadBytesICF;
                staInfo.Bandwidth = associatedBandwidthInHz/1e6; % In MHz
                staInfo.MaxSupportedStandard = staNode.MaxSupportedStandard;

                % Overwrite default association info when association is performed
                isUnassociated = isscalar(obj.RemoteSTAInfo) && obj.RemoteSTAInfo.NodeID == 0;
                if isUnassociated && staInfo.NodeID ~= 0 % Association is in progress
                    obj.RemoteSTAInfo = staInfo;
                else
                    obj.RemoteSTAInfo = [obj.RemoteSTAInfo staInfo];
                end

                % Add association information at shared MAC
                if obj.IsMLDNode % AP is an MLD
                    addRemoteSTAInfo(obj.SharedMAC, staInfo);

                else % Non-MLD
                    % Add required information of STA at non-MLD AP
                    addRemoteSTAInfo(obj.SharedMAC(apDeviceIdx(staIdx)), staInfo);
                end

                % Configure association information at mesh bridge of AP to handle
                % forwarding from AP.
                if obj.IsAPNode
                    addRemoteSTAInfo(obj.MeshBridge, staInfo);
                end

                % Add information of AP at STA
                apInfo = obj.RemoteSTAInfoTemplate;
                apInfo.Mode = "AP";
                apInfo.NodeID = obj.ID;
                apInfo.MACAddress = associatedAPMACAddress;
                apInfo.DeviceID = associatedSTADeviceIDs;
                apInfo.AID = 0; % Not applicable for AP
                apInfo.IsMLD = obj.IsMLDNode;
                apInfo.EnhancedMLMode = 0; % Not applicable for AP
                apInfo.NumEMLPadBytes = 0; % Not applicable for AP
                apInfo.Bandwidth = associatedBandwidthInHz/1e6; % In MHz
                apInfo.MaxSupportedStandard = obj.MaxSupportedStandard;
                staNode.RemoteSTAInfo = apInfo;

                % Add association information at shared MAC
                addRemoteSTAInfo(staNode.SharedMAC, apInfo);
            end

            % Configure full buffer traffic based on the input 'FullBufferTraffic' parameter
            wlan.internal.configureFullBufferTraffic(obj, associationNVParams.FullBufferTraffic, associatedSTAs);
        end

        function addTrafficSource(obj, trafficSource, options)
        %addTrafficSource Add data traffic source to WLAN node
        %
        %   addTrafficSource(OBJ,TRAFFICSOURCE) copies the data traffic source object
        %   TRAFFICSOURCE, and adds it to the nodes specified by OBJ.
        %
        %   OBJ is a scalar or vector of wlanNode objects. If specified as vector,
        %   the DestinationNode NV argument must be unspecified or a scalar.
        %
        %   TRAFFICSOURCE is a scalar wnet.Traffic object, such as
        %   networkTrafficOnOff, networkTrafficFTP, networkTrafficVideoConference,
        %   networkTrafficVoIP, or a custom subclass. A copy is added to the node
        %   and hence any changes made to the TRAFFICSOURCE object after addition
        %   are not reflected. If you specify the "MACModel" property of OBJ as
        %   "full-mac", this object function generates an application traffic
        %   packet.
        %
        %   addTrafficSource(...,Name=Value) specifies additional name-value
        %   arguments described below. When a name-value argument is not specified,
        %   the function uses its default value.
        %
        %   DestinationNode - Destination node object
        %   Specify as a scalar or vector of wlanNode objects. If a vector, then
        %   source node OBJ must be a scalar. If not specified, the source node
        %   broadcasts traffic. If source is an EMLSR STA MLD or an AP MLD with at
        %   least one associated EMLSR STA, you must specify this argument.
        %
        %   AccessCategory - Access category (AC) of the generated traffic
        %   Specify as a scalar integer in the range [0, 3]. The four values
        %   respectively correspond to the Best Effort, Background, Video, and
        %   Voice ACs. The default value is 0.

            arguments
                obj (1,:)
                trafficSource (1,1) wnet.Traffic
                options.DestinationNode (1,:) wlanNode
                options.AccessCategory (1,1) {mustBeMember(options.AccessCategory, [0 1 2 3])};
            end

            % Dynamic traffic addition is not supported
            if any([obj.HasStarted])
                error(message('wlan:wlanNode:NotSupportedOperation', 'addTrafficSource', obj(find(any([obj.HasStarted]),1)).Name));
            end
            % Validate the traffic parameters
            trafficInfoPerDestination = wlan.internal.validation.trafficParams(obj, options);

            % Add the traffic source to the application traffic manager
            numDestinations = numel(trafficInfoPerDestination);
            numSources = numel(obj);
            for sourceIdx = 1:numSources
                for destIdx = 1:numDestinations
                    if (obj(sourceIdx).FullBufferTrafficEnabled) && ...
                            (~isempty(trafficInfoPerDestination(destIdx).DestinationNodeID) && ...
                            any(trafficInfoPerDestination(destIdx).DestinationNodeID == [obj(sourceIdx).FullBufferContext(:).DestinationID]))
                        % Full buffer traffic is enabled between the given source and destination
                        error(message('wlan:wlanNode:FullBufferEnabled',obj(sourceIdx).Name,trafficInfoPerDestination(destIdx).DestinationNodeName));
                    end
                    addTrafficSource(obj(sourceIdx).Application, copy(trafficSource), trafficInfoPerDestination(destIdx));
                end
                obj(sourceIdx).NonFullBufferTrafficEnabled = true;
            end
        end

        function addMeshPath(obj, destinationNode, varargin)
        %addMeshPath Add mesh path to WLAN node
        %
        %   addMeshPath(OBJ,DESTINATIONNODE) specifies that the destination node,
        %   DESTINATIONNODE, is an immediate mesh receiver for the source node,
        %   OBJ.
        %
        %   OBJ is a source wlanNode object.
        %
        %   DESTINATIONNODE is a destination wlanNode object.
        %
        %   addMeshPath(...,MESHPATHNODE) specifies the mesh node, MESHPATHNODE, to
        %   which OBJ sends the packets to communicate with DESTINATIONNODE.
        %
        %   MESHPATHNODE is a wlanNode object, specifying one of these roles:
        %   * Next hop node - For mesh destination node, this input specifies
        %     the next hop node. The next hop node refers to an immediate mesh
        %     receiver to which the source node forwards the packets.
        %   * Proxy mesh gate - For non-mesh destination node, this input specifies
        %     the proxy mesh gate. The proxy mesh gate refers to any mesh node that
        %     can forward packets to a non-mesh node.
        %
        %   addMeshPath(...,Name=Value) specifies additional name-value arguments
        %   described below. When a name-value argument is not specified, the
        %   function uses its default value.
        %
        %   SourceBandAndChannel - Band and channel on which the source node transmits
        %                          packets to the next hop node.
        %   Specify as a vector of two values. The first value must be 2.4, 5, or 6
        %   and the second value must be a valid channel number in the band. The
        %   input uses this default configuration:
        %   * If the mesh path node is the next hop node, the function selects the
        %     common band and channel pair between the source node and next hop node.
        %     If there are multiple pairs, you must specify a value for this input.
        %   * If the mesh path node is the proxy mesh gate, the function selects
        %   the band and channel of a mesh device. If there are multiple mesh
        %   devices, you must specify a value for this input.
        %
        %   MeshPathBandAndChannel - Band and channel on which the mesh path node
        %                            receives packets.
        %   Dimensions, allowed values and default values are same as
        %   SourceBandAndChannel.
        %
        %   DestinationBandAndChannel  - Band and channel on which the destination
        %   node should receive the packets.
        %   Dimensions and allowed values are same as above two arguments. The
        %   input uses this default configuration:
        %   * If the destination node is a mesh node, the function selects the band
        %     and channel of a mesh device. If there are multiple mesh devices, you
        %     must specify a value for this input.
        %   * If the destination node is a non-mesh node with only one device, the
        %     function selects the band and channel of that device. If there are
        %     multiple devices, you must specify a value for this input.

            narginchk(2, 9);

            validateattributes(obj, {'wlanNode'}, {'scalar'}, 'wlanNode', 'obj');
            % Validate the input parameters
            [meshPathNode, params] = wlan.internal.validation.meshPathParams(obj, nargin, destinationNode, varargin{:});
            [sourceDeviceID, meshPathDevID, destDevID] = wlan.internal.mesh.findDevicesToAddMeshPath(obj, destinationNode, meshPathNode, params);

            destinationID = destinationNode.ID;
            destinationAddress = wlan.internal.utils.nodeID2MACAddress([destinationNode.ID destDevID]);
            meshPathAddress = wlan.internal.utils.nodeID2MACAddress([meshPathNode.ID meshPathDevID]);

            if destinationNode.IsMeshNode % Forwarding information
                % Validate association compatibility before adding path for
                % communication
                wlan.internal.validation.associationCompatibility(obj, meshPathNode, sourceDeviceID, meshPathDevID);
                % Add next hop (meshPathAddress) information
                addPath(obj.MeshBridge, destinationID, destinationAddress, meshPathAddress, sourceDeviceID);
                addPeerMeshSTAInfo(obj, meshPathNode, sourceDeviceID, meshPathDevID);
                setBiDirectionalPaths(obj, destinationNode, meshPathNode, sourceDeviceID, destDevID, meshPathDevID);
                % Set rate control context
                basicRates = [6 12 24]; % No configuration option for mesh nodes yet
                setRateControlContext(obj, meshPathNode, sourceDeviceID, basicRates);
                setRateControlContext(meshPathNode, obj, meshPathDevID, basicRates);
            else % Proxy information
                % Add proxy mesh (meshPathAddress) information
                addProxyInfo(obj.MeshBridge, destinationID, destinationAddress, meshPathAddress);
            end

            % Update Mesh Neighbors in MAC
            obj.MAC(sourceDeviceID).MeshNeighbors{end+1} = [meshPathNode.ID meshPathDevID];
            meshPathNode.MAC(meshPathDevID).MeshNeighbors{end+1} = [obj.ID sourceDeviceID];
        end

        function update(obj, deviceID, varargin)
        %update Update configuration of WLAN Node
        %
        %   update(OBJ,Name=Value) updates the configuration of the node. You can
        %   update the following properties through this method.
        %
        %   CWMin     - Minimum range of contention window for the four
        %               access categories (ACs), specified as a vector of
        %               four integers in the range [1, 1023]. The four 
        %               entries are the minimum ranges for the Best Effort,
        %               Background, Video, and Voice ACs, respectively.
        %
        %   CWMax     - Maximum range of contention window for the four ACs,
        %               specified as a vector of four integers in the range
        %               [1, 1023]. The four entries are the maximum ranges
        %               for the Best Effort, Background, Video, and Voice
        %               ACs, respectively.
        %
        %   AIFS      - Arbitrary interframe space values for the four ACs,
        %               specified as a vector of four integers in the range
        %               [2, 15]. The entries of the vector represent the AIFS
        %               values, in slots, for the Best Effort, Background,
        %               Video, and Voice ACs, respectively.
        %
        %   update(OBJ,DEVICEID,Name=Value) updates the configuration for a
        %   specific device in a non-MLD node or a specific link in a device in an
        %   MLD node. For a non-MLD node, DEVICEID is a scalar and specifies the
        %   device ID which is the array index in the DeviceConfig property of the
        %   OBJ. If DEVICEID is not specified, the default value is 1. For an MLD
        %   node, DEVICEID is a vector in which the first element specifies the
        %   device ID. The second element specifies the link ID which is the array
        %   index in the LinkConfig property of DeviceConfig property of the OBJ.
        %   If DEVICEID is not specified, the default value is [1 1].

            validateattributes(obj, {'wlanNode'}, {'scalar'}, 'wlanNode', 'obj');
            if nargin == 1
                error(message('wlan:wlanNode:NoUpdate'))
            end

            linkID = 1; % Default
            if mod(nargin, 2) == 1
                nvPairs = [{deviceID}, varargin];
                deviceID = 1;
            else
                nvPairs = varargin;
                if obj.IsMLDNode
                    if numel(deviceID)~=2
                        error(message('wlan:wlanNode:UpdateInvalidDeviceID'))
                    end
                    devID = deviceID;
                    deviceID = devID(1);
                    linkID = devID(2);
                    if ~(isnumeric(deviceID) && isreal(deviceID) && (deviceID==floor(deviceID))) ... % Integer check
                        || deviceID < 1 || deviceID > numel(obj.DeviceConfig)
                        error(message('wlan:wlanNode:UpdateInvalidLink', 'First', 'multilink devices'))
                    end
                    if ~(isnumeric(linkID) && isreal(linkID) && (linkID==floor(linkID))) ... % Integer check
                        || linkID < 1 || linkID > numel(obj.DeviceConfig.LinkConfig)
                        error(message('wlan:wlanNode:UpdateInvalidLink', 'Second', 'links in the specified multilink device'))
                    end
                else
                    validateattributes(deviceID, {'numeric'}, {'scalar', 'integer', 'positive', '<=', numel(obj.DeviceConfig)}, '', 'device ID');
                end
            end

            if ~obj.IsMLDNode % Non MLD
                cfg = obj.DeviceConfig(deviceID);
                macIdx = deviceID;
            else % MLD
                cfg = obj.DeviceConfig(deviceID).LinkConfig(linkID);
                macIdx = linkID;
            end

            numParamUpdates = 0;
            for idx = 1:2:numel(nvPairs)
                switch nvPairs{idx}
                    case {'CWMin', 'CWMax', 'AIFS'}
                        cfg.(nvPairs{idx}) = nvPairs{idx+1};
                        updateContentionParams(obj.MAC(macIdx), nvPairs{idx}, nvPairs{idx+1});
                        numParamUpdates = numParamUpdates + 1;
                    otherwise
                        error(message('wlan:wlanNode:InvalidUpdateParameter'))
                end
            end

            if ~obj.IsMLDNode % Non MLD
                obj.DeviceConfig(deviceID) = cfg;
                obj.SharedMAC(macIdx).IsEDCAParamsUpdated = true;
                obj.SharedMAC(macIdx).EDCAParamsCount = obj.SharedMAC(macIdx).EDCAParamsCount + 1*(numParamUpdates>=1);
            else % MLD
                obj.DeviceConfig(deviceID) = updateLinkConfig(obj.DeviceConfig(deviceID), linkID, cfg);
                obj.SharedMAC.IsEDCAParamsUpdated(:, macIdx) = true;
                obj.SharedMAC.EDCAParamsCount(macIdx) = obj.SharedMAC.EDCAParamsCount(macIdx) + 1*(numParamUpdates>=1);
            end
        end

        function stats = statistics(obj, varargin)
        %statistics Returns statistics of WLAN Node
        %
        %   [STATISTICS] = statistics(OBJ) returns the statistics as a structure
        %   for the given node object, OBJ. If the input OBJ is a vector, the
        %   output is a row vector of structures corresponding to statistics of each
        %   node.
        %
        %   [STATISTICS] = statistics(OBJ,"all") returns additional statistics as
        %   well as the default ones that the previous syntax returns.
        %
        %   STATISTICS is a structure containing the statistics of the node. If 
        %   the input OBJ is a vector of nodes, STATISTICS is a vector of 
        %   structures corresponding to the input vector of nodes.

            % Validate that input is a vector
            validateattributes(obj, {'wlanNode'}, {'vector'}, 'wlanNode', '', 1);

            % Return the output stats as a row vector
            stats = repmat(struct, 1, numel(obj));

            option = [];
            if ~isempty(varargin)
                option = validatestring(varargin{1}, "all", 'wlanNode', '');
            end
            % Calculate the number of unique frequencies
            for idx = 1:numel(obj)
                node = obj(idx);

                % Initialize
                mac = node.MAC;
                phyTx = node.PHYTx;
                phyRx = node.PHYRx;
                meshBridge = node.MeshBridge;

                % App statistics in App sub-structure
                stats(idx).Name = node.Name;
                stats(idx).ID = node.ID;
                stats(idx).App = getAppStats(node, option);

                for deviceID = 1:numel(obj(idx).DeviceConfig)
                    isMLD = isa(obj(idx).DeviceConfig(deviceID), 'wlanMultilinkDeviceConfig');
                    if ~isMLD
                        % MAC statistics in MAC sub-structure
                        stats(idx).MAC(deviceID) = statistics(mac(deviceID), option);
                    else
                        % MLD MAC statistics in MAC sub-structure
                        numLinks = numel(obj(idx).DeviceConfig.LinkConfig);
                        for linkID = 1:numLinks
                            linkMACStats(linkID) = statistics(mac(linkID), option);
                        end
                        stats(idx).MAC(deviceID) = wlan.internal.statistics.mldStatistics(linkMACStats);

                        % MLD per-link statistics in MAC sub-structure when "all" is provided
                        if ~isempty(option)
                            stats(idx).MAC(deviceID).Link = linkMACStats;
                        end
                    end

                    if ~isMLD
                        % PHY statistics in PHY sub-structure. Merge the PHYTx and
                        % PHYRx statistics structures into one structure
                        phyTxStats = statistics(phyTx(deviceID));
                        phyRxStats = statistics(phyRx(deviceID));
                        stats(idx).PHY(deviceID) = cell2struct([struct2cell(phyTxStats); struct2cell(phyRxStats)], [fieldnames(phyTxStats); fieldnames(phyRxStats)]);
                    else
                        % MLD PHY statistics in PHY sub-structure.
                        numLinks = numel(obj(idx).DeviceConfig.LinkConfig);
                        for linkID = 1:numLinks
                            phyTxStats = statistics(phyTx(linkID));
                            phyRxStats = statistics(phyRx(linkID));
                            linkPHYStats(linkID) = cell2struct([struct2cell(phyTxStats); struct2cell(phyRxStats)], [fieldnames(phyTxStats); fieldnames(phyRxStats)]);
                        end
                        stats(idx).PHY(deviceID) = wlan.internal.statistics.mldStatistics(linkPHYStats);

                        % MLD per-link statistics in PHY sub-structure when "all" is provided
                        if ~isempty(option)
                            stats(idx).PHY(deviceID).Link = linkPHYStats;
                        end
                    end

                    % Mesh statistics in Mesh sub-structure
                    stats(idx).Mesh(deviceID) = statistics(meshBridge, deviceID);
                end
            end
        end

        function registerEventCallback(obj, eventName, callback)
            %registerEventCallback Registers a callback for an event from node
            %
            %   registerEventCallback(OBJ, EVENTNAME, CALLBACK) registers a function
            %   callback, CALLBACK, for the specified event, EVENTNAME, from the node,
            %   OBJ. CALLBACK is a callback function invoked when the node notifies the
            %   event.
            %
            %   OBJ is a scalar or vector of objects of type wlanNode.
            %
            %   EVENTNAME is a string scalar or vector, specified as
            %   "TransmissionStarted", "ReceptionEnded", "AppPacketGenerated", or
            %   "AppPacketReceived".
            %
            %   CALLBACK is a scalar function handle. The syntax for callback function
            %   must be @(eventStruct) callback(eventStruct). wlanNode object passes
            %   structure with event notification data as a mandatory argument to the
            %   callback function.

            arguments
                obj (1,:)
                eventName (1,:) string
                callback (1,1) function_handle
            end

            % Check whether the input event names are valid
            validEventNames = ["TransmissionStarted","ReceptionEnded","AppPacketGenerated","AppPacketReceived"];
            numEvents = numel(eventName);
            for eventIdx = 1:numEvents
                eventName(eventIdx) = wnet.internal.matchString(eventName(eventIdx), validEventNames, 'registerEventCallback', 'eventName');
            end

            % Check whether there are any duplicate event names
            uniqueEventNames = unique(eventName);
            numUniqueEvents = numel(uniqueEventNames);
            if (numEvents ~= numUniqueEvents)
                warning(message('wnet:Node:DuplicateEvents'));
            end

            for nodeIdx = 1:numel(obj)
                node = obj(nodeIdx);
                for eventIdx = 1:numUniqueEvents
                    ev = uniqueEventNames(eventIdx);
                    switch ev
                        case "TransmissionStarted"
                            for macIdx = 1:node.NumDevices
                                node.MAC(macIdx).TransmissionStartedFcn{end+1} = callback;
                            end
                        case "ReceptionEnded"
                            for macIdx = 1:node.NumDevices
                                node.MAC(macIdx).ReceptionEndedFcn{end+1} = callback;
                            end
                        case "AppPacketGenerated"
                            node.Application.AppPacketGeneratedFcn{end+1} = callback;
                        case "AppPacketReceived"
                            node.Application.AppPacketReceivedFcn{end+1} = callback;
                        case "ChangingState"
                            for macIdx = 1:node.NumDevices
                                node.MAC(macIdx).ChangingStateFcn{end+1} = callback;
                            end
                    end
                end
            end
        end

        function nextInvokeTime = run(obj, currentTime)
            %run Runs the WLAN node
            %
            %   NEXTINVOKETIME = run(OBJ, CURRENTTIME) runs the
            %   functionality of WLAN node and returns the time at which
            %   this node should be run again.
            %
            %   NEXTINVOKETIME is the time in seconds at which the run
            %   function must be invoked again. The simulator may invoke
            %   this function earlier than this time if required, for
            %   example when a packet is added to the receive buffer of
            %   this node.
            %
            %   OBJ is a wlanNode object.
            %
            %   CURRENTTIME is the current simulation time in seconds.

            % Initialize
            nextInvokeTimes = zeros(1, 0);
            nextIdx = 1;

            % Update simulation time
            obj.LastRunTime = currentTime;
            currentTimeInNS = round(currentTime*1e9); % current time in nanoseconds
            % Check for event listeners
            if ~obj.HasStarted
                % Perform the actions needed in the initial run of the node
                performPreRunActions(obj);
                obj.HasStarted = true;
            end

            if obj.NonFullBufferTrafficEnabled
                % Run the application layer
                nextAppInvokeTime = run(obj.Application, currentTimeInNS);
            else
                nextAppInvokeTime = Inf;
            end

            for deviceIdx = 1:obj.NumDevices
                % Rx buffer has data to be processed
                if obj.ReceiveBufferIdx(deviceIdx) ~= 0
                    rxBuffer = obj.ReceiveBuffer{deviceIdx};
                    for idx = 1:obj.ReceiveBufferIdx(deviceIdx)
                        % Process the received data
                        deviceInvokeTime = runLayers(obj, deviceIdx, currentTimeInNS, rxBuffer{idx});
                        nextInvokeTimes(nextIdx:nextIdx+1) = deviceInvokeTime;
                        % Increment the nextInvokeTimes vector index by 2 to
                        % fill MAC and PHY invoke times in next iteration.
                        nextIdx = nextIdx+2;
                    end
                    obj.ReceiveBufferIdx(deviceIdx) = 0;
                else % Rx buffer has no data to process
                    % Update the time to the MAC and PHY layers
                    deviceInvokeTime = runLayers(obj, deviceIdx, currentTimeInNS, []);
                    nextInvokeTimes(nextIdx:nextIdx+1) = deviceInvokeTime;
                    nextIdx = nextIdx+2;
                end
            end

            % Get the next invoke time
            nextInvokeTime = min([nextInvokeTimes nextAppInvokeTime]);
            nextInvokeTime = round(nextInvokeTime/1e9, 9);
        end

        function packets = pullTransmittedPacket(obj)
            %pullTransmittedPacket Read the data to be transmitted from transmit buffer
            %
            %   PACKETS = pullTransmittedPacket(OBJ) reads the packets to be
            %   transmitted at the current time and empties the transmission buffer.
            %
            %   OBJ is a wlanNode object.
            % 
            %   PACKETS are the packets to be transmitted. Each packet is a structure of
            %   the format wirelessPacket.
            %
            %   Note: This should only be called by the
            %   wirelessNetworkSimulator during the simulation.

            packets = obj.TransmitterBuffer;
            obj.TransmitterBuffer = [];
        end

        function [flag, rxInfo] = isPacketRelevant(obj, packet)
            %isPacketRelevant Return flag to indicate if the input packet
            %is relevant for this node
            %
            %   [FLAG, RXINFO] = isPacketRelevant(OBJ, PACKET) checks
            %   whether the packet, PACKET, is relevant for this node,
            %   before applying channel model. If the output FLAG is true,
            %   the packet is of interest and the RXINFO specifies the
            %   receiver information needed for applying channel on the
            %   incoming packet, PACKET.
            %
            %   FLAG is a logical scalar value indicating whether the packet will be
            %   accepted by the node for reception or not. Value 1 (true) represents that
            %   packet is relevant and 0 (false) represents irrelevant.
            %
            %   The function returns the output, RXINFO, and is valid only when the
            %   FLAG value is 1 (true). If the FLAG value is 0 (false), the output
            %   RXINFO can be []. The RXINFO is a structure and  contains these fields:
            %   ID       - Node identifier of the receiver
            %   Position - Current receiver position in Cartesian x-, y-, and z-
            %              coordinates, specified as a real-valued vector of the form
            %              [x y z]. Units are in meters.
            %   Velocity - Current receiver velocity (v) in the x-, y-, and
            %              z-directions, specified as a real-valued vector of the form
            %              [vx vy vz]. Units are in meters per second.
            %   NumReceiveAntennas - Number of receiver antennas.
            %
            %   OBJ is a wlanNode object.
            %
            %   PACKET is the packet received from the channel. This is a
            %   structure of type wirelessPacket.

            % Initialize
            flag = false;
            rxInfo = obj.RxInfo;

            % If it is self-packet (transmitted by this node) do not get this
            % packet
            if packet.TransmitterID == obj.ID
                return;
            end

            for deviceID = 1:obj.NumDevices
                flag = wlan.internal.utils.isFrequencyOverlapping(obj, packet, deviceID);
                if flag
                    rxInfo.Position = obj.Position;
                    rxInfo.Velocity = obj.Velocity;
                    % Use the maximum number of receive antennas
                    rxInfo.NumReceiveAntennas = obj.MAC(deviceID).NumTransmitAntennas;
                    break;
                end
            end
        end

        function pushReceivedPacket(obj, packet)
            %pushReceivedPacket Push the received packet to the node
            %
            %   pushReceivedPacket(OBJ, PACKETS) pushes the received packet,
            %   PACKET, to the reception buffer of the node.
            %
            %   OBJ is a wlanNode object.
            %
            %   PACKET is the received packet. It is a structure of the format
            %   wirelessPacket.

            if isempty(packet)
                return;
            end

            % Copy the received packet to the device (network interface)
            % buffers of the node only if the frequency is overlapping
            for deviceID = 1:obj.NumDevices
                if wlan.internal.utils.isFrequencyOverlapping(obj, packet, deviceID)
                    wlan.internal.validation.rxCompatibility(obj, packet, deviceID);
                    obj.ReceiveBufferIdx(deviceID) = obj.ReceiveBufferIdx(deviceID) + 1;
                    obj.ReceiveBuffer{deviceID}{obj.ReceiveBufferIdx(deviceID)} = packet;
                end
            end
        end
    end

    methods(Hidden)
        function init(obj)
            %init Initialize and setup the node stack

            % Extract node ID
            nodeIdx = obj.ID;

            if ~obj.IsMLDNode
                % In case of non-MLD node, devCfg contains per device configuration
                devCfg = obj.DeviceConfig;
            else
                % In case of MLD node, devCfg contains per link configuration
                devCfg = obj.DeviceConfig.LinkConfig;
            end

            wlan.internal.validation.macAndPHYAbstraction(obj, devCfg);
            devCfg = wlan.internal.utils.getDeviceConfig(obj);
            obj.NumTransmitAntennas = [devCfg(:).NumTransmitAntennas];

            % Number of devices in the node in case of non-MLD node. Number of links in
            % case of MLD node.
            numDevices = numel(devCfg);

            if obj.IsMLDNode
                % Get EMLSR padding delay and transition delay in nanoseconds
                emlsrPaddingDelay = round(obj.DeviceConfig.EnhancedMultilinkPaddingDelay*1e9); % in nanoseconds
                emlsrTransitionDelay = round(obj.DeviceConfig.EnhancedMultilinkTransitionDelay*1e9); % in nanoseconds

                % In case of MLD, create one shared MAC
                maxSubframes = max([devCfg(:).MPDUAggregationLimit]);
                obj.SharedMAC = wlan.internal.mac.SharedMAC(obj.DeviceConfig.TransmitQueueSize, maxSubframes, ...
                    ShortRetryLimit=obj.DeviceConfig.ShortRetryLimit, ...
                    NumLinks=numDevices, IsMLD=obj.IsMLDNode, ...
                    EMLPaddingDelay=emlsrPaddingDelay, EMLTransitionDelay=emlsrTransitionDelay);

                % Store AC to link mapping information in shared MAC
                acs = cell(0, numDevices);
                % Store band and channel of each link
                bandsAndChannels = zeros(numDevices, 2);
                primaryChannelNums = zeros(numDevices, 1);
                primaryChannelFreqs = zeros(numDevices, 1);
                primaryChannelIndices = zeros(numDevices, 1);
                % Get the information of AC to link mapping, band and channel and primary
                % channel from each link config
                for linkIdx = 1:numel(obj.DeviceConfig.LinkConfig)
                    linkCfg = obj.DeviceConfig.LinkConfig(linkIdx);
                    acs{linkIdx} = linkCfg.MappedACs;
                    bandsAndChannels(linkIdx, :) = linkCfg.BandAndChannel;
                    primaryChannelIndices(linkIdx) = getPrimaryChannelIndex(obj, linkCfg);
                    [primaryChannelNums(linkIdx), primaryChannelFreqs(linkIdx)] = wlan.internal.utils.getPrimaryChannel(linkCfg.BandAndChannel, ...
                        linkCfg.ChannelBandwidth, primaryChannelIndices(linkIdx));
                end
                obj.SharedMAC.Link2ACMap = acs;
                obj.SharedMAC.BandAndChannel = bandsAndChannels;
                obj.SharedMAC.PrimaryChannel = primaryChannelNums; % This information is needed at AP for Beacon fields

                sharedMAC = obj.SharedMAC;

                % Store the parameters which are applicable per device in case of non-MLD
                % and configured common to all links in case of MLD
                txQueueSize = obj.DeviceConfig.TransmitQueueSize;
                isMeshDevice = obj.DeviceConfig.IsMeshDevice;
                isAPDevice = obj.DeviceConfig.IsAPDevice;
            end

            % For the following properties, assign defaults because these capabilities
            % are not supported in case of MLD. These values are updated with device
            % configuration values later in case of non-MLD.
            maxMUStations = 1;
            dlOfdmaFrameSequence = 2;
            bssColor = 0;
            obssPDThreshold = -82;
            obj.InterferenceFidelity = zeros(1,numDevices); % Type of interference modeling

            % Configure and add the devices with MAC and PHY layers
            for devIdx = 1:numDevices
                % Get number of space time streams
                if obj.IsMLDNode && strcmp(obj.DeviceConfig.Mode, "STA") && ...
                        strcmp(obj.DeviceConfig.EnhancedMultilinkMode, "EMLSR") % EMLSR STA
                    obj.IsEMLSRSTA = true;
                end

                % Configure the rate control algorithm at MAC for DL transmissions from the device
                if strcmp(devCfg(devIdx).RateControl,'fixed')
                    % Create a new rate control object for each node and each device/link,
                    % because rate control is a handle class.
                    rateControlAlgorithm = wlan.internal.mac.RateControlFixed;
                elseif strcmp(devCfg(devIdx).RateControl,'auto-rate-fallback')
                    % Create a new rate control object for each node and each device/link,
                    % because rate control is a handle class.
                    rateControlAlgorithm = wlanRateControlARF;
                else % Custom rate control
                    rateControlAlgorithm = copy(devCfg(devIdx).RateControl);
                    if ~obj.IsMLDNode
                        obj.DeviceConfig(devIdx).RateControl = rateControlAlgorithm;
                    else
                        linkCfg = obj.DeviceConfig.LinkConfig(devIdx);
                        linkCfg.RateControl = rateControlAlgorithm;
                        obj.DeviceConfig = updateLinkConfig(obj.DeviceConfig, devIdx, linkCfg);
                    end
                end

                % Configure the rate control algorithm at MAC for UL transmissions triggered by the device
                ulRateControlAlgorithm = wlan.internal.mac.RateControlFixed;

                % Configure the power control algorithm at MAC
                powerControl = devCfg(devIdx).PowerControl;
                assert(strcmp(powerControl, 'FixedPower'));
                powerControlAlgorithm = wlan.internal.mac.PowerControlFixed(Power=devCfg(devIdx).TransmitPower);

                % Initialize the scheduler
                macScheduler = wlan.internal.mac.SchedulerRoundRobin;

                % Initialize values related to EMLSR
                EMLSRListenAntennas = 0;

                transmissionFormat = wlan.internal.utils.getFrameFormatConstant(devCfg(devIdx).TransmissionFormat);
                % Determine whether UL OFDMA is enabled
                ulOFDMAEnabled = false;
                % DL and UL MU OFDMA are not yet supported in an MLD. Hence, check whether
                % it is an MLD node.
                if ~obj.IsMLDNode
                    % EnableUplinkOFDMA flag is applicable only for an AP when the
                    % TransmissionFormat is either HE-SU or HE-MU-OFDMA
                    if strcmp(devCfg(devIdx).Mode, "AP") && any(strcmp(devCfg(devIdx).TransmissionFormat, ["HE-SU", "HE-MU-OFDMA"])) && ...
                            devCfg(devIdx).EnableUplinkOFDMA
                        ulOFDMAEnabled = true;
                        % Full MAC frame generation and decoding is not supported for triggered
                        % multiuser transmissions
                        if strcmp(obj.MACModel, "full-mac") && devCfg(devIdx).EnableUplinkOFDMA
                            error(message('wlan:wlanNode:UnsupportedMACModelForOFDMA'))
                        end
                    end

                    % In case of non-MLD, create one shared MAC for each device.
                    primaryChannelIdx = getPrimaryChannelIndex(obj, devCfg(devIdx));
                    [primaryChannelNum,primaryChannelFreq] = wlan.internal.utils.getPrimaryChannel(devCfg(devIdx).BandAndChannel, devCfg(devIdx).ChannelBandwidth, primaryChannelIdx);
                    sharedMAC = wlan.internal.mac.SharedMAC(devCfg(devIdx).TransmitQueueSize, devCfg(devIdx).MPDUAggregationLimit, ...
                        ShortRetryLimit=devCfg(devIdx).ShortRetryLimit, ...
                        NumLinks=1, IsMLD=obj.IsMLDNode, BandAndChannel=devCfg(devIdx).BandAndChannel, ...
                        PrimaryChannel=primaryChannelNum); % This information is needed at AP for Beacon fields
                    obj.SharedMAC(devIdx) = sharedMAC;

                    % Set rate control context
                    setDeviceConfig(rateControlAlgorithm, devCfg(devIdx), devIdx);
                    setDeviceConfig(ulRateControlAlgorithm, devCfg(devIdx), devIdx);

                    isMeshDevice = devCfg(devIdx).IsMeshDevice;
                    isAPDevice = devCfg(devIdx).IsAPDevice;
                    txQueueSize = devCfg(devIdx).TransmitQueueSize;
                    maxMUStations = devCfg(devIdx).MaxMUStations;
                    dlOfdmaFrameSequence = devCfg(devIdx).DLOFDMAFrameSequence;
                    bssColor = 0;
                    obssPDThreshold = -82;
                    if ~isMeshDevice
                        if isAPDevice % AP node
                            if any(transmissionFormat == [wlan.internal.FrameFormats.HE_SU ...
                                    wlan.internal.FrameFormats.HE_EXT_SU wlan.internal.FrameFormats.EHT_SU])
                                bssColor = devCfg(devIdx).BSSColor;
                            end
                        end
                        obssPDThreshold = devCfg(devIdx).OBSSPDThreshold;
                        basicRates = devCfg(devIdx).BasicRates;
                    else
                        basicRates = [6 12 24]; % No configuration option for mesh yet
                    end
                    numTransmitAntennas = devCfg(devIdx).NumTransmitAntennas;
                    numReceiveAntennas = numTransmitAntennas;
                else
                    % Set rate control context
                    setDeviceConfig(rateControlAlgorithm, obj.DeviceConfig, devIdx);
                    setDeviceConfig(ulRateControlAlgorithm, obj.DeviceConfig, devIdx);

                    if obj.IsEMLSRSTA
                        numTransmitAntennas = sum([obj.DeviceConfig.LinkConfig(:).NumTransmitAntennas]);
                        EMLSRListenAntennas = devCfg(devIdx).NumTransmitAntennas;
                        numReceiveAntennas = EMLSRListenAntennas; % Initial value
                    else
                        numTransmitAntennas = devCfg(devIdx).NumTransmitAntennas;
                        numReceiveAntennas = numTransmitAntennas;
                    end
                    primaryChannelIdx = primaryChannelIndices(devIdx);
                    primaryChannelFreq = primaryChannelFreqs(devIdx);
                    basicRates = devCfg(devIdx).BasicRates;
                end

                % Validate channel bandwidth supported for beacon transmission
                if obj.IsMLDNode
                    isBeaconEnabled = strcmp(obj.DeviceConfig.Mode, "AP") && isfinite(devCfg(devIdx).BeaconInterval);
                else
                    isBeaconEnabled = ~strcmp(devCfg(devIdx).Mode, "STA") && isfinite(devCfg(devIdx).BeaconInterval);
                end
                if isBeaconEnabled && ~strcmp(obj.PHYModel, "full-phy") && devCfg(devIdx).ChannelBandwidth ~= 20e6
                    error(message('wlan:wlanNode:InvalidBandwidthForBeacon'))
                end

                % Get the operating frequency of the device from the band and channel
                bandAndChannel = devCfg(devIdx).BandAndChannel;
                operatingFrequency = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));

                % Generate a separate address for each device in the node
                macAddressHex = wlan.internal.utils.nodeID2MACAddress([obj.ID devIdx]);

                % MAC layer
                mac = wlan.internal.mac.edcaMAC(NodeID=nodeIdx, ...
                        NodeName=obj.Name, ...
                        DeviceID=devIdx, ...
                        MACAddress=macAddressHex, ...
                        OperatingFrequency = operatingFrequency, ...
                        ChannelBandwidth=devCfg(devIdx).ChannelBandwidth/1e6, ...
                        PrimaryChannelIndex=primaryChannelIdx, ...
                        TransmissionFormat=transmissionFormat, ...
                        MPDUAggregation=wlan.internal.utils.isMPDUAggregationEnabled(obj, devIdx), ...
                        DisableAck=devCfg(devIdx).DisableAck, ...
                        CWMin=devCfg(devIdx).CWMin, ...
                        CWMax=devCfg(devIdx).CWMax, ...
                        AIFS=devCfg(devIdx).AIFS, ...
                        TXOPLimit=devCfg(devIdx).TXOPLimit*32e3, ...
                        NumTransmitAntennas=numTransmitAntennas, ...
                        NumReceiveAntennas=numReceiveAntennas, ...
                        DisableRTS=devCfg(devIdx).DisableRTS, ...
                        RTSThreshold=devCfg(devIdx).RTSThreshold,...
                        Use6MbpsForControlFrames=devCfg(devIdx).Use6MbpsForControlFrames, ...
                        BasicRates=basicRates, ...
                        RateControl=rateControlAlgorithm, ...
                        PowerControl=powerControlAlgorithm, ...
                        FrameAbstraction=strcmp(obj.MACModel, "full-mac-with-frame-abstraction"), ...
                        IsMeshDevice=isMeshDevice, ...
                        IsAPDevice=isAPDevice, ...
                        SharedMAC=sharedMAC, ...
                        Scheduler=macScheduler, ...
                        SharedEDCAQueues=sharedMAC.EDCAQueues, ...
                        MaxMUStations=maxMUStations, ...
                        DLOFDMAFrameSequence=dlOfdmaFrameSequence, ...
                        ULOFDMAEnabled=ulOFDMAEnabled, ...
                        ULRateControl=ulRateControlAlgorithm, ...
                        MaxSubframes=devCfg(devIdx).MPDUAggregationLimit, ...
                        MaxQueueLength=txQueueSize, ...
                        SIFSTime=16e3, ...
                        BSSColor=bssColor, ...
                        OBSSPDThreshold=obssPDThreshold, ...
                        BeaconInterval=devCfg(devIdx).BeaconInterval, ...
                        InitialBeaconOffset=devCfg(devIdx).InitialBeaconOffset, ...
                        IsEMLSRSTA=obj.IsEMLSRSTA, ...
                        NumEMLSRListenAntennas=EMLSRListenAntennas, ...
                        MaxSupportedStandard=obj.MaxSupportedStandard, ...
                        IncludeVector=obj.IncludeVector, ...
                        AllowEDCAParamsUpdate=obj.AllowEDCAParamsUpdate);

                % Initialize context that is used in association. This is done to
                % ensure such properties have correct values for both associated and
                % unassociated nodes.
                initPreAssociationContext(mac);

                % Configure interference fidelity
                switch devCfg(devIdx).InterferenceModeling
                    case 'co-channel'
                        obj.InterferenceFidelity(devIdx) = 0;
                    case 'overlapping-adjacent-channel'
                        obj.InterferenceFidelity(devIdx) = 1;
                    otherwise % 'non-overlapping-adjacent-channel'
                        obj.InterferenceFidelity(devIdx) = 2;
                end

                if strcmp(obj.PHYModel,"full-phy")
                    if obj.InterferenceFidelity(devIdx) == 0
                        % Modeling co-channel interference
                        osf = 1;
                    else
                        % Oversampling waveform for modeling ACI
                        osf = 1.125;
                    end
                    phyTx = wlan.internal.phy.FullPHYTx(...
                        IsNodeTypeAP=isAPDevice, ...
                        TxGain=devCfg(devIdx).TransmitGain, ...
                        DeviceID=devIdx, ...
                        OversamplingFactor=osf, ...
                        OperatingFrequency = operatingFrequency, ...
                        OperatingBandwidth=devCfg(devIdx).ChannelBandwidth/1e6, ... % Configured bandwidth
                        PrimaryChannelIndex=primaryChannelIdx);
                    phyRx = wlan.internal.phy.FullPHYRx(NodeID=nodeIdx, ...
                        EDThreshold=devCfg(devIdx).EDThreshold, ...
                        RxGain=devCfg(devIdx).ReceiveGain, ...
                        NoiseFigure=devCfg(devIdx).NoiseFigure, ...
                        OperatingFrequency = operatingFrequency, ...
                        ChannelBandwidth=devCfg(devIdx).ChannelBandwidth/1e6, ...
                        DeviceID=devIdx, ...
                        BSSColor=bssColor, ...
                        NumReceiveAntennas=numReceiveAntennas, ...
                        MaxReceiveAntennas=numTransmitAntennas, ... % Total number of receive antennas is assumed to be same as the number of transmit antennas
                        PrimaryChannelFrequency=primaryChannelFreq, ...
                        PrimaryChannelIndex=primaryChannelIdx, ...
                        IsAP = isAPDevice, ...
                        IsSTA = ~isAPDevice && ~isMeshDevice);
                else
                    % Physical layer transmitter
                    phyTx = wlan.internal.phy.AbstractPHYTx(...
                        IsNodeTypeAP=isAPDevice, ...
                        TxGain=devCfg(devIdx).TransmitGain, ...
                        MaxSubframes=devCfg(devIdx).MPDUAggregationLimit, ...
                        OperatingFrequency = operatingFrequency, ...
                        ChannelBandwidth=devCfg(devIdx).ChannelBandwidth/1e6, ...
                        DeviceID=devIdx, ...
                        PrimaryChannelIndex=primaryChannelIdx);

                    % Physical layer receiver
                    phyRx = wlan.internal.phy.AbstractPHYRx(NodeID=nodeIdx, ...
                        EDThreshold=devCfg(devIdx).EDThreshold, ...
                        RxGain=devCfg(devIdx).ReceiveGain, ...
                        AbstractionType=obj.PHYModel, ...
                        NoiseFigure = devCfg(devIdx).NoiseFigure, ...
                        SubcarrierSubsampling = 4, ...
                        MaxSubframes=devCfg(devIdx).MPDUAggregationLimit, ...
                        OperatingFrequency = operatingFrequency, ...
                        ChannelBandwidth=devCfg(devIdx).ChannelBandwidth/1e6, ...
                        DeviceID=devIdx, ...
                        BSSColor=bssColor, ...
                        OBSSPDThreshold=obssPDThreshold, ...
                        NumReceiveAntennas=numReceiveAntennas, ...
                        MaxReceiveAntennas=numTransmitAntennas, ... % Total number of receive antennas is assumed to be same as the number of transmit antennas
                        PrimaryChannelFrequency=primaryChannelFreq, ...
                        PrimaryChannelIndex=primaryChannelIdx, ...
                        IsAP = isAPDevice, ...
                        IsSTA = ~isAPDevice && ~isMeshDevice);
                end

                % Use weak-references for cross-linking handle objects
                objWeakRef = matlab.lang.WeakReference(obj);
                % Register function handle at MAC for pushing packets from node to MAC queue
                mac.PushPacketToQueueFcn = @(destIdx, ac) wlan.internal.fillPacketInMACQueueWithFBCtx(objWeakRef.Handle, destIdx, ac);
                % Register function handle at MAC for handling packets after MAC processing
                mac.HandleReceivePacketFcn = @(deviceID, packetToApp, isMeshDevice, isIntendedForAppRx, packetGenerationTime, currentTimeInNs) ...
                    objWeakRef.Handle.handleReceivedPacket(deviceID, packetToApp, isMeshDevice, isIntendedForAppRx, packetGenerationTime, currentTimeInNs);

                % Register function handle at MAC to notify the PHY mode change to phy Rx
                mac.SetPHYModeFcn = @(phyMode)phyRx.setPHYMode(phyMode);
                % Register function handle at MAC to send CCA reset request to phy Rx
                mac.ResetPHYCCAFcn = @phyRx.resetPHYCCA;
                % Register function handle at MAC to send Trigger request to phy Rx
                if ~obj.IsMLDNode && devCfg(devIdx).EnableUplinkOFDMA || strcmp(devCfg(devIdx).TransmissionFormat, "HE-MU-OFDMA")
                    mac.SendTrigRequestFcn = @(expiryTime)phyRx.handleTrigRequest(expiryTime);
                end
                % Register function handle at MAC to notify phy Rx about medium sync delay (MSD) timer
                % start and reset at MAC
                mac.MSDTimerStartFcn = @(msdOFDMEDThreshold)phyRx.msdTimerStart(msdOFDMEDThreshold);
                mac.MSDTimerResetFcn = @phyRx.msdTimerReset;
                % Register function handle at MAC to notify phy Rx about the number of active receive antennas
                mac.SetNumRxAntennasFcn = @(numAntennas)phyRx.updateNumActiveRxAntennas(numAntennas);

                % Register function handle for events notification
                eventNotificationFcn = @(eventName, eventData) objWeakRef.Handle.triggerEvent(eventName, eventData);
                mac.EventNotificationFcn = eventNotificationFcn;
                phyTx.EventNotificationFcn = eventNotificationFcn;
                phyRx.EventNotificationFcn = eventNotificationFcn;

                % Register function handle for sending packets from PHY Tx
                sendPacketFcn = @(packet) objWeakRef.Handle.addToTxBuffer(packet);
                phyTx.SendPacketFcn = sendPacketFcn;

                % Add the device
                addDevice(obj, devIdx, mac, phyTx, phyRx);

                if ~obj.IsMLDNode
                    % In case of non-MLD, store EDCA MAC layer object in the corresponding
                    % shared MAC layer object.
                    obj.SharedMAC(devIdx).MAC = mac;
                end
            end

            if obj.IsMLDNode % MLD node
                meshTTL = 31; % Assign default value as mesh is not supported in MLD
            else % Non-MLD
                meshTTL = [devCfg(:).MeshTTL];
            end

            % Mesh bridge
            obj.MeshBridge = wlan.internal.mesh.MeshBridge(obj.MAC, MeshTTL=meshTTL, SharedMAC=obj.SharedMAC);
            % Register function handle at mesh for handling packets after MAC processing
            for idx = 1:numel(obj.MAC)
                meshObjWeakRef = matlab.lang.WeakReference(obj.MeshBridge);
                obj.MAC(idx).HandleReceiveMeshPacketFcn = @(rxMPDU, selfMACAddress, deviceID) ...
                    meshObjWeakRef.Handle.handleReceivedMeshPacket(rxMPDU, selfMACAddress, deviceID);
            end
            % Initialize the receiving buffers for each device within the node. The
            % corresponding frequencies for each device are stored in
            % 'ReceiveFrequency'.
            obj.ReceiveBuffer = cell(numDevices, 1);
            obj.ReceiveBufferIdx = zeros(1, numDevices);

            % Initialize receiver information
            obj.RxInfo = struct(ID=obj.ID, Position=[0 0 0], Velocity=[0 0 0]);

            % Initialize association information
            if obj.IsMLDNode
                % An MLD node currently supports only one multi-link device. So, initialize
                % as a scalar.
                obj.NumAssociatedSTAsPerDevice = 0;
            else
                obj.NumAssociatedSTAsPerDevice = zeros(numDevices, 1);
            end

            if obj.IsMLDNode
                % In case of multi link, store the EDCA MAC layer objects in the shared
                % MAC layer object.
                obj.SharedMAC.MAC = obj.MAC;
                % Generate an MLD MAC address by setting the device index input to 0
                obj.SharedMAC.MLDMACAddress = wlan.internal.utils.nodeID2MACAddress([obj.ID 0]);
                % The AID value assigned to a non-AP MLD associated with AP MLD is in the
                % range of 1-2006. Reference: Section 9.4.1.8 of IEEE P802.11be/D5.0.
                % Hence, set the maximum number of associations to 2006.
                obj.AssociationLimit = 2006;
            end

            % Initialize association parameters at sharedMAC. These are
            % done to ensure such properties have correct values for both
            % associated and unassociated nodes.
            obj.RemoteSTAInfo = obj.RemoteSTAInfoTemplate;
            for idx = 1:numel(obj.SharedMAC)
                initPreAssociationContext(obj.SharedMAC(idx), obj.RemoteSTAInfo);
            end
        end

        function pushPacketToQueue(obj, destIdx, ac)
        %pushPacketToQueue Generate and push application packet to the MAC queue
            wlan.internal.fillPacketInMACQueueWithFBCtx(obj, destIdx, ac);
        end

        function setAPFullBufferTrafficContext(obj, associatedStations)
        %setAPFullBufferTrafficContext Initialize full buffer traffic context
            numStations = numel(associatedStations);
            obj.PacketIDCounter = [obj.PacketIDCounter, zeros(1, numStations)];
            obj.FullBufferTrafficEnabled = true;
            fullBufferAppPacket = obj.FullBufferAppPacket;
            fullBufferAppPacket.Packet = ones(obj.FullBufferPacketSize, 1);
            fullBufferAppPacket.PacketLength = obj.FullBufferPacketSize;
            fullBufferAppPacket.AccessCategory = 0;
            fullBufferAppPacket.SourceNodeID = obj.ID;
            fullBufferContext = repmat(obj.FullBufferContextTemplate, 1, numStations);

            for idx = 1:numStations
                fullBufferAppPacket.DestinationNodeID = associatedStations(idx).ID;
                fullBufferAppPacket.DestinationNodeName = string(associatedStations(idx).Name);
                fullBufferContext(idx).DestinationID = associatedStations(idx).ID;
                fullBufferContext(idx).DestinationName = string(associatedStations(idx).Name);
                fullBufferContext(idx).IsMLDDestination = associatedStations(idx).IsMLDNode;   % Check if the destination is an MLD
                [fullBufferContext(idx).MACQueuePacket, fullBufferContext(idx).SourceDeviceIdx] = wlan.internal.utils.addDestinationInfo(obj, fullBufferAppPacket);  % Add destination information to the packet
                fullBufferContext(idx).IsGroupAddress = wlan.internal.utils.isGroupAddress(fullBufferContext(idx).MACQueuePacket.Header.Address1);            % Check if the destination is a groupcast address

                associatedStations(idx).FullBufferSourceNodeIDs = obj.ID;
            end
            numDestinations = numel(obj.FullBufferContext);
            startIdx = 1 + numDestinations * ~((numDestinations==1) && (obj.FullBufferContext.DestinationID==0));
            endIdx = startIdx+numStations-1;
            obj.FullBufferContext(startIdx:endIdx) = fullBufferContext;
        end

        function setSTAFullBufferTrafficContext(obj, associatedAP)
        %setSTAFullBufferTrafficContext Initialize full buffer traffic context
            obj.PacketIDCounter = 0;
            obj.FullBufferTrafficEnabled = true;

            % Full buffer MAC packet and its context
            fullBufferContext = obj.FullBufferContextTemplate;
            fullBufferAppPacket = obj.FullBufferAppPacket;
            fullBufferAppPacket.PacketLength = obj.FullBufferPacketSize;
            fullBufferAppPacket.Packet = ones(obj.FullBufferPacketSize, 1);
            fullBufferAppPacket.AccessCategory = 0;
            fullBufferAppPacket.SourceNodeID = obj.ID;
            fullBufferAppPacket.DestinationNodeID = associatedAP.ID;
            fullBufferAppPacket.DestinationNodeName = associatedAP.Name;
            fullBufferContext.IsMLDDestination = (obj.IsMLDNode) && (associatedAP.IsMLDNode);   % Check if the destination is an MLD
            fullBufferContext.DestinationID = associatedAP.ID;
            fullBufferContext.DestinationName = associatedAP.Name;
            [fullBufferContext.MACQueuePacket, fullBufferContext.SourceDeviceIdx] = wlan.internal.utils.addDestinationInfo(obj, fullBufferAppPacket);  % Add destination information to the packet
            fullBufferContext.IsGroupAddress = wlan.internal.utils.isGroupAddress(fullBufferContext.MACQueuePacket.Header.Address1);            % Check if the destination is a groupcast address
            obj.FullBufferContext = fullBufferContext;
            associatedAP.FullBufferSourceNodeIDs = [associatedAP.FullBufferSourceNodeIDs obj.ID];
        end

        function packetID = packetIDCounter(obj, destIdx)
        %packetIDCounter Returns packet ID for app packets (used for full buffer
        %traffic)

            obj.PacketIDCounter(destIdx) = obj.PacketIDCounter(destIdx) + 1;
            packetID = obj.PacketIDCounter(destIdx);
        end

        function value = getPrimaryChannelIndex(obj, cfg)
        %getPrimaryChannelIndex Returns primary channel index for the specified
        %device/link configuration

            value = ones(1, numel(cfg));
            for idx = 1:numel(cfg)
                if obj.IsMLDNode
                    isAP = strcmp(obj.DeviceConfig.Mode, "AP");
                else
                    isAP = strcmp(cfg(idx).Mode, "AP");
                end

                if isAP && cfg(idx).ChannelBandwidth > 20e6
                    value(idx) = cfg(idx).PrimaryChannelIndex;
                end
            end
        end

        function kpiValue = kpi(srcNode, destNode, kpiString, options)
            %kpi Returns key performance indicators (KPIs) for WLAN nodes
            %
            %   KPIVALUE = kpi(SRCNODE, DESTNODE, KPISTRING, OPTIONS) returns the KPI
            %   value, KPIVALUE, specified by KPISTRING, from the source node, SRCNODE
            %   to the destination node, DESTNODE. The function calculates KPIs where
            %   either the source node or the destination node can be a vector,
            %   enabling multiple KPI calculations across different node pairs.
            %
            %   KPIVALUE is the calculated value of the specified kpi string,
            %   KPISTRING. If you provide multiple source-destination pairs, kpiValue
            %   is a row vector containing the KPI value for each pair.
            %
            %   SRCNODE is a scalar or a vector of wlanNode objects.
            %
            %   DESTNODE is a scalar or a vector of wlanNode objects.
            %
            %   KPISTRING specifies the name of the KPI to measure, specified as
            %   "throughput", "PLR" or "latency".
            %
            %   OPTIONS is a structure with the following fields -
            %
            %   Layer           - This field specifies the layer at which you want to
            %                     measure the KPI. Valid values of this field are: "MAC"
            %                     and "App".
            %
            %   BandAndChannel  - Specify this field when you want to measure the KPI
            %                     exclusively for a specific Band and Channel between
            %                     the source and destination node. If you do not
            %                     specify BandAndChannel, this object function
            %                     calculates the total KPI between the source node and
            %                     destination node.

            arguments
                srcNode (1,:) wlanNode
                destNode (1,:) wlanNode
                kpiString (1,1) string {mustBeMember(kpiString,["throughput", "PLR", "latency"])}
                options.Layer (1,1) string {mustBeMember(options.Layer, ["MAC", "App"])}
                options.BandAndChannel (1,2)
            end

            % Check that Layer parameter has been specified in options
            if ~isfield(options, "Layer")
                error(message('wlan:wlanNode:KPIMustHaveLayerNV'))
            end

            bandAndChannel = [];
            % Check if BandAndChannel parameter has been specified in options
            if isfield(options, "BandAndChannel")
                bandAndChannel = options.BandAndChannel;
            end

            % Validate invalid input combinations
            invalidCombination = false;
            layer = options.Layer;
            if strcmp(layer, "App") && ~strcmp(kpiString, "latency")
                invalidCombination = true;
            elseif strcmp(layer, "MAC") && (strcmp(kpiString, "latency"))
                invalidCombination = true;
            end

            if invalidCombination
                error(message('wlan:wlanNode:KPIInvalidInputCombination', kpiString, layer))
            end
            if ~isempty(bandAndChannel) && (strcmp(kpiString, "latency"))
                error(message('wlan:wlanNode:UnsupportedLinkLevelLatency'))
            end

            wlan.internal.validation.kpiParams(srcNode, destNode, bandAndChannel);

            kpiValue = [];
            if strcmp(kpiString, 'throughput')
                if ~isempty(bandAndChannel)
                    kpiValue = wlan.internal.statistics.calculateLinkThroughput(srcNode, destNode, bandAndChannel);
                else
                    kpiValue = wlan.internal.statistics.calculateThroughput(srcNode, destNode);
                end
            elseif strcmp(kpiString, 'PLR')
                if ~isempty(bandAndChannel)
                    kpiValue = wlan.internal.statistics.calculateLinkPLR(srcNode, destNode, bandAndChannel);
                else
                    kpiValue = wlan.internal.statistics.calculatePLR(srcNode, destNode);
                end
            elseif strcmp(kpiString, 'latency')
                kpiValue = wlan.internal.statistics.calculateLatency(srcNode, destNode);
            end
        end

        function setRateControlContext(obj, rxNode, devID, basicRates)
            % Add operational device configuration
            setAssociationConfig(obj.MAC(devID).RateControl, basicRates);
            setAssociationConfig(obj.MAC(devID).ULRateControl, basicRates);
            
            % Set receiver context and add mutually supported capabilities
            apCapabilities = struct('MaxMCS',13,'MaxNumSpaceTimeStreams',8);
            staCapabilities = struct('MaxMCS',13,'MaxNumSpaceTimeStreams',8);
            capabilities = struct('MaxMCS',min(apCapabilities.MaxMCS,staCapabilities.MaxMCS), ...
                'MaxNumSpaceTimeStreams',min(apCapabilities.MaxNumSpaceTimeStreams,staCapabilities.MaxNumSpaceTimeStreams));
            setReceiverContext(obj.MAC(devID).RateControl, rxNode.ID, capabilities);
            setReceiverContext(obj.MAC(devID).ULRateControl, rxNode.ID, capabilities);
        end
    end

    methods (Access = protected)
        function addDevice(obj, deviceID, mac, phyTx, phyRx)
            %addDevice Add a device to the node
            %
            %   addDevice(OBJ, DEVICEID, MAC, PHYTX, PHYRX) adds a device to the node
            %   with the given MAC and PHY objects.
            %
            %   OBJ is a wlanNode object.
            %
            %   DEVICEID is the identifier of the device.
            %
            %   MAC is an object of type wlan.internal.mac.edcaMAC. This object contains
            %   methods and properties related to WLAN MAC layer.
            %
            %   PHYTX is an abstracted PHY object of type
            %   wlan.internal.phy.AbstractPHYTx or wlan.internal.phy.FullPHYTx. This object
            %   contains methods and properties related to WLAN PHY transmitter.
            %
            %   PHYRX is an abstracted PHY object of type
            %   wlan.internal.phy.AbstractPHYRx or wlan.internal.phy.FullPHYRx. This object
            %   contains methods and properties related to WLAN PHY receiver.

            % Update the device information
            obj.MAC(deviceID) = mac;
            obj.PHYTx(deviceID) = phyTx;
            obj.PHYRx(deviceID) = phyRx;

            if ~obj.IsMLDNode
                cfg = obj.DeviceConfig(deviceID);
            else
                cfg = obj.DeviceConfig.LinkConfig(deviceID);
            end
            obj.ReceiveBandwidth(deviceID) = cfg.ChannelBandwidth;
        end

        function nextInvokeTime = runLayers(obj, deviceIdx, currentTime, rxPacket)
            %runLayers Runs the layers of the node with the received signal
            %and returns the next invoke time in microseconds

            % MAC object
            mac = obj.MAC(deviceIdx);
            % PHY Tx object
            phyTx = obj.PHYTx(deviceIdx);
            % PHY Rx object
            phyRx = obj.PHYRx(deviceIdx);

            % Invoke the PHY receiver module
            [nextPHYInvokeTime, indicationToMAC, frameToMAC] = run(phyRx, currentTime, rxPacket);

            % Invoke the MAC layer
            [nextMACInvokeTime, macReqToPHY, frameToPHY] = run(mac, currentTime, indicationToMAC, frameToMAC);

            % Invoke the PHY transmitter module (pass MAC requests to PHY)
            if (macReqToPHY.MessageType == wlan.internal.PHYPrimitives.TxStartRequest) || ~isempty(frameToPHY)
                run(phyTx, currentTime, macReqToPHY, frameToPHY);
            end

            % Return the next invoke times of PHY and MAC modules
            nextInvokeTime = [nextPHYInvokeTime nextMACInvokeTime];
        end

        function addToTxBuffer(obj, packet)
            %addToTxBuffer Adds the packet to Tx buffer
            
            packet.TransmitterID = obj.ID;
            packet.TransmitterPosition = obj.Position;
            packet.TransmitterVelocity = obj.Velocity;
            obj.TransmitterBuffer = [obj.TransmitterBuffer packet];
        end

        function triggerEvent(obj, eventName, eventData)
            %triggerEvent Trigger the event to notify all the listeners

            if event.hasListener(obj, eventName)
                % LastRunTime contains the time at which node is invoked.
                eventData.CurrentTime = obj.LastRunTime;
                eventDataObj = wnet.internal.nodeEventData;
                eventDataObj.Data = eventData;
                notify(obj, eventName, eventDataObj);
            end
        end

        function receiveAppData(obj, macPacket, packetGenerationTime, currentTimeInNs)
            %receiveAppData Calculate the received application packet latency

            % Update the packet latency
            obj.PacketLatencyIdx = obj.PacketLatencyIdx + 1;
            obj.PacketLatency(obj.PacketLatencyIdx) = round(currentTimeInNs*1e-9 - packetGenerationTime, 9); % In seconds
            obj.TotalPacketLatency = obj.TotalPacketLatency + obj.PacketLatency(obj.PacketLatencyIdx);

            % Reception handling at App layer
            appReceivePacket(obj, macPacket.FrameBody.MSDU, currentTimeInNs);

            % Update the RxAppLatencyStats
            sourceNodeID = wlan.internal.utils.macAddress2NodeID(macPacket.Metadata.SourceAddress);
            destinationNodeID = wlan.internal.utils.macAddress2NodeID(macPacket.Metadata.DestinationAddress);
            % Check to see if the packet was broadcasted
            if ~(destinationNodeID == obj.BroadcastID)
                % Check if the RxAppLatencyStats has a structure to store latency values from
                % source node
                if (isempty(obj.RxAppLatencyStats) || ~any([obj.RxAppLatencyStats.SourceNodeID] == sourceNodeID))
                    % Add a structure to store latency values from source node
                    rxAppLatencyStats = obj.RxAppLatencyStatsTemplate;
                    rxAppLatencyStats.SourceNodeID = sourceNodeID;
                    obj.RxAppLatencyStats = [obj.RxAppLatencyStats rxAppLatencyStats];
                end
                % Update the values in the structure associated with the source node.
                idxLogical = ([obj.RxAppLatencyStats.SourceNodeID] == sourceNodeID);
                obj.RxAppLatencyStats(idxLogical).AggregatePacketLatency = ...
                    obj.RxAppLatencyStats(idxLogical).AggregatePacketLatency + ...
                    round(currentTimeInNs*1e-9 - packetGenerationTime, 9);
                obj.RxAppLatencyStats(idxLogical).ReceivedPackets = ...
                    obj.RxAppLatencyStats(idxLogical).ReceivedPackets + 1;
                obj.RxAppLatencyStats(idxLogical).ReceivedBytes = ...
                    obj.RxAppLatencyStats(idxLogical).ReceivedBytes + macPacket.FrameBody.MSDU.PacketLength;
            end
        end

        function appReceivePacket(obj, packetInfo, currentTimeInNs)
            %appReceivePacket Sends packet to application layer

            isFullBufferTrafficReception = (packetInfo.AccessCategory == 0) && any(obj.FullBufferSourceNodeIDs == packetInfo.SourceNodeID);
            if isFullBufferTrafficReception
                % Do not trigger AppPacketReceived event if full buffer traffic is enabled
                % at source. So, empty the AppPacketReceivedFcn in trafficManager and
                % reassign after sending packet.
                appPacketReceivedFcn = obj.Application.AppPacketReceivedFcn;
                obj.Application.AppPacketReceivedFcn = [];
                obj.Application.receivePacket(packetInfo, currentTimeInNs);
                obj.Application.AppPacketReceivedFcn = appPacketReceivedFcn;
            else
                obj.Application.receivePacket(packetInfo, currentTimeInNs);
            end
        end

        function handleReceivedPacket(obj, deviceID, rxMPDU, isMeshDevice, isIntendedForAppRx, packetGenerationTime, currentTimeInNs)
            %handleReceivedPacket Handle each decoded MSDU received from MAC

            if isIntendedForAppRx
                % Give packet to application layer if it is intended for application layer
                % reception
                receiveAppData(obj, rxMPDU, packetGenerationTime, currentTimeInNs);
            elseif ~isMeshDevice && obj.IsAPNode
                isGroupAddr = wlan.internal.utils.isGroupAddress(rxMPDU.Metadata.DestinationAddress);
                if isGroupAddr
                    % Give broadcast packet received by AP to application layer
                    receiveAppData(obj, rxMPDU, packetGenerationTime, currentTimeInNs);
                end
                if ~strcmp(obj.MAC(deviceID).MACAddress, rxMPDU.Metadata.DestinationAddress)
                    % We're not the final destination, or the destination is a broadcast address
                    forwardAppData(obj.MeshBridge, rxMPDU, deviceID, isGroupAddr);
                end
            end
        end

        function appStats = getAppStats(obj, varargin)
        %getAppStats Get application statistics

            appStats = statistics(obj.Application);
            perTrafficSourceStats = appStats.TrafficSources;
            appStats = rmfield(appStats, 'TrafficSources');

            allInputGiven = ~isempty(varargin) && strcmp(varargin{1}, "all");
            if allInputGiven % "all" input is provided
                nonFullBufferDestIDs = [];
                fullBufferDestIDs = [];
                if ~isempty(perTrafficSourceStats) % Non full buffer traffic present
                    [nonFullBufferDestIDs, tsIndices] = unique([perTrafficSourceStats(:).DestinationNodeID]);
                end
                if obj.FullBufferTrafficEnabled % Full buffer traffic present
                    fullBufferDestIDs = [obj.FullBufferContext(:).DestinationID];
                end
                destinationIDs = unique([nonFullBufferDestIDs fullBufferDestIDs]);
                if ~isempty(destinationIDs)
                    appStats.Destinations = repmat(struct('NodeID', [], ...
                        'NodeName', [], 'TransmittedPackets', 0, ...
                        'TransmittedBytes', 0), 1, numel(destinationIDs));
                end
            end

            % Fill Destinations sub-structure if "all" is provided in input
            if allInputGiven && ~isempty(perTrafficSourceStats)
                nonFullBufferDestNames = [perTrafficSourceStats(tsIndices).DestinationNodeName];
                numNonFullBufferDestinations = numel(nonFullBufferDestIDs);

                for dstIdx = 1:numNonFullBufferDestinations
                    dstIdxLogical = (nonFullBufferDestIDs(dstIdx) == destinationIDs);
                    appStats.Destinations(dstIdxLogical).NodeID = nonFullBufferDestIDs(dstIdx);
                    appStats.Destinations(dstIdxLogical).NodeName = nonFullBufferDestNames(dstIdx);

                    % Loop over each traffic source and add the stats number to
                    % the corresponding destination
                    for idx=1:numel(perTrafficSourceStats)
                        trafficSourceStat = perTrafficSourceStats(idx);
                        appDestinationID = trafficSourceStat.DestinationNodeID;
                        if appDestinationID == nonFullBufferDestIDs(dstIdx)
                            appStats.Destinations(dstIdxLogical).TransmittedPackets = ...
                                appStats.Destinations(dstIdxLogical).TransmittedPackets + trafficSourceStat.TransmittedPackets;
                            appStats.Destinations(dstIdxLogical).TransmittedBytes = ...
                                appStats.Destinations(dstIdxLogical).TransmittedBytes + trafficSourceStat.TransmittedBytes;
                        end
                    end
                end
            end

            if obj.FullBufferTrafficEnabled
                numFullBufferPackets = sum(obj.PacketIDCounter);
                appStats.TransmittedPackets = appStats.TransmittedPackets + numFullBufferPackets;
                appStats.TransmittedBytes = appStats.TransmittedBytes + numFullBufferPackets*obj.FullBufferPacketSize;
                % Fill Destinations sub-structure if "all" is provided in input
                if allInputGiven
                    numFullBufferDestinations = numel(fullBufferDestIDs);
                    for idx = 1:numFullBufferDestinations
                        dstIdxLogical = (fullBufferDestIDs(idx) == destinationIDs);
                        if any(fullBufferDestIDs(idx) == nonFullBufferDestIDs)
                            % Both full buffer traffic and non full buffer traffic is enabled for the
                            % destination. Add full buffer stats to existing 'Destinations'
                            % sub-structure.
                            numFullBufferPackets = obj.PacketIDCounter(idx);
                            appStats.Destinations(dstIdxLogical).TransmittedPackets = ...
                                appStats.Destinations(dstIdxLogical).TransmittedPackets + numFullBufferPackets;
                            appStats.Destinations(dstIdxLogical).TransmittedBytes = ...
                                appStats.Destinations(dstIdxLogical).TransmittedBytes + numFullBufferPackets*obj.FullBufferPacketSize;
                        else
                            appStats.Destinations(dstIdxLogical).NodeID = obj.FullBufferContext(idx).DestinationID;
                            appStats.Destinations(dstIdxLogical).NodeName = obj.FullBufferContext(idx).DestinationName;
                            appStats.Destinations(dstIdxLogical).TransmittedPackets = obj.PacketIDCounter(idx);
                            appStats.Destinations(dstIdxLogical).TransmittedBytes = obj.PacketIDCounter(idx)*obj.FullBufferPacketSize;
                        end
                    end
                end
            end
        end

        function setFrequencies(obj)
        %setFrequencies Sets the frequencies from the given band and
        %channel values for each device/link config

            if ~obj.IsMLDNode % Non-MLD
                obj.NumDevices = numel(obj.DeviceConfig);
            else % MLD
                % Consider each link as a device
                obj.NumDevices = obj.DeviceConfig.NumLinks;
                % Validate the multilink device
                validateConfig(obj.DeviceConfig);
            end

            for idx = 1:obj.NumDevices
                if ~obj.IsMLDNode % Non-MLD
                    cfg = obj.DeviceConfig(idx);
                    % Validate device config
                    cfg = validateConfig(cfg);
                    % Assign the validated device config back to DeviceConfig property.
                    obj.DeviceConfig(idx) = cfg;
                else % MLD
                    cfg = obj.DeviceConfig.LinkConfig(idx);
                end

                % Set the receive frequency and bandwidth
                obj.ReceiveFrequency(idx) = cfg.ChannelFrequency;
                obj.ReceiveBandwidth(idx) = cfg.ChannelBandwidth;
            end
        end

        function setBiDirectionalPaths(obj, destinationNode, meshPathNode, sourceDeviceID, destDevID, meshPathDevID)
        % Auto-find neighbor nodes and set bi-directional paths if a
        % path is not already set

            meshPathAddress = wlan.internal.utils.nodeID2MACAddress([meshPathNode.ID meshPathDevID]);

            % Add backward path for direct neighbors and one-hop
            % neighbors
            if (destinationNode.ID == meshPathNode.ID)
                % Add neighbor nodes
                if ~any(destinationNode.ID == obj.MeshNeighbors)
                    obj.MeshNeighbors(end+1) = destinationNode.ID;
                end
                if ~any(obj.ID == destinationNode.MeshNeighbors)
                    destinationNode.MeshNeighbors(end+1) = obj.ID;
                end
                % Backward path for neighbor node
                if ~any([destinationNode.MeshBridge.ForwardTable{:, 1}] == obj.ID)
                    addPath(destinationNode.MeshBridge, obj.ID, obj.MAC(sourceDeviceID).MACAddress, obj.MAC(sourceDeviceID).MACAddress, destDevID);
                    addPeerMeshSTAInfo(destinationNode, obj, destDevID, sourceDeviceID);
                end
            else % Non-neighbors

                % The source node and next hop node (mesh path node)
                % are implicitly neighbors

                % Add neighbor nodes
                if ~any(meshPathNode.ID == obj.MeshNeighbors)
                    obj.MeshNeighbors(end+1) = meshPathNode.ID;
                end
                if ~any(obj.ID == meshPathNode.MeshNeighbors)
                    meshPathNode.MeshNeighbors(end+1) = obj.ID;
                end
                % Add path from source node to next hop node
                if ~any([obj.MeshBridge.ForwardTable{:, 1}] == meshPathNode.ID)
                    addPath(obj.MeshBridge, meshPathNode.ID, meshPathAddress, meshPathAddress, sourceDeviceID);
                end
                % Add path from next hop node to source node
                if ~any([meshPathNode.MeshBridge.ForwardTable{:, 1}] == obj.ID)
                    addPath(meshPathNode.MeshBridge, obj.ID, obj.MAC(sourceDeviceID).MACAddress, obj.MAC(sourceDeviceID).MACAddress, meshPathDevID);
                    addPeerMeshSTAInfo(meshPathNode, obj, meshPathDevID, sourceDeviceID);
                end

                if ~any([destinationNode.MeshBridge.ForwardTable{:, 1}] == obj.ID)
                    % Check if destination and mesh path nodes are
                    % neighbors. Since mesh path node (i.e. next hop node)
                    % is implicitly a neighbor for the source node,
                    % destination is within 2 hops.
                    twoHopNeighbor = any(destinationNode.ID == meshPathNode.MeshNeighbors);

                    % If destination is a two hop neighbor, add backward
                    % path if there is no entry already
                    if twoHopNeighbor
                        % Validate association compatibility before adding path for
                        % communication
                        wlan.internal.validation.associationCompatibility(destinationNode, obj, destDevID, sourceDeviceID);
                        addPath(destinationNode.MeshBridge, obj.ID, obj.MAC(sourceDeviceID).MACAddress, meshPathAddress, destDevID);
                        addPeerMeshSTAInfo(destinationNode, meshPathNode, destDevID, meshPathDevID);
                        % Set rate control context
                        basicRates = [6 12 24]; % No configuration option for mesh yet
                        setRateControlContext(meshPathNode, destinationNode, meshPathDevID, basicRates);
                        setRateControlContext(destinationNode, meshPathNode, destDevID, basicRates);
                    end
                end
            end
        end

        function performPreRunActions(obj)
            checkEventListeners(obj);
            if obj.FullBufferTrafficEnabled
                wlan.internal.fillTrafficBuffer(obj);
            end
        end

        function checkEventListeners(obj)
        %checkEventListeners Checks whether events have listeners and returns a
        %structure with event names as field names holding flags indicating true if
        %it has a listener.
    
            hasListenerEvtStruct = wlan.internal.utils.defaultEventList;

            if event.hasListener(obj,'MPDUGenerated')
                hasListenerEvtStruct.MPDUGenerated = true;
            end
            if event.hasListener(obj,'MPDUDecoded')
                hasListenerEvtStruct.MPDUDecoded = true;
            end
            if event.hasListener(obj,'TransmissionStatus')
                hasListenerEvtStruct.TransmissionStatus = true;
            end
            if event.hasListener(obj,'StateChanged')
                hasListenerEvtStruct.StateChanged = true;
            end
            if event.hasListener(obj,'AppDataReceived')
                hasListenerEvtStruct.AppDataReceived = true;
            end
            for idx = 1:numel(obj.MAC)
                obj.MAC(idx).HasListener = hasListenerEvtStruct;
                obj.PHYTx(idx).HasListener = hasListenerEvtStruct;
                obj.PHYRx(idx).HasListener = hasListenerEvtStruct;
            end
        end

        function updateMACParameter(obj, parameter, value)
            %updateMACParameter Updates MAC parameter with the specified value

            for idx = 1:numel(obj.MAC)
                obj.MAC(idx).(parameter) = value;
            end
        end
    end

    methods(Access=private)
         function addPeerMeshSTAInfo(obj, peerNode, selfDeviceID, peerDeviceID)
             % Add peer mesh STA info. Information includes peer mesh node
             % ID, peer mesh node MAC address, device ID on which this node
             % is connected to its peer mesh node and the bandwidth used
             % for communication with peer node.

             peerNodeID = peerNode.ID;
             peerNodeAddress = peerNode.MAC(peerDeviceID).MACAddress;
             % Add the information of peer mesh STA if it is not already present
             if isempty(obj.RemoteSTAInfo) || ~any(peerNodeID == [obj.RemoteSTAInfo(:).NodeID])
                 staInfo = obj.RemoteSTAInfoTemplate;
                 staInfo.NodeID = peerNodeID;
                 staInfo.MACAddress = peerNodeAddress;
                 staInfo.DeviceID = selfDeviceID;
                 staInfo.Mode = "mesh";
                 bwToUseInHz = min(obj.DeviceConfig(selfDeviceID).ChannelBandwidth, ...
                     peerNode.DeviceConfig(peerDeviceID).ChannelBandwidth);
                 staInfo.Bandwidth = bwToUseInHz/1e6; % In MHz
                 staInfo.MaxSupportedStandard = peerNode.MaxSupportedStandard;
                 obj.RemoteSTAInfo = [obj.RemoteSTAInfo staInfo];
                 addRemoteSTAInfo(obj.SharedMAC(selfDeviceID), staInfo);

                 % Add primary channel information at MAC and phy modules
                 primaryChannelIdx = 1; % Not configurable for mesh. Hence consider default
                 devCfg = wlan.internal.utils.getDeviceConfig(obj, selfDeviceID);
                 [~,primaryChannelFrequency] = wlan.internal.utils.getPrimaryChannel(devCfg.BandAndChannel, devCfg.ChannelBandwidth, primaryChannelIdx);
                 wlan.internal.utils.setPrimaryChannelInfoAtLayers(obj, selfDeviceID, primaryChannelIdx, primaryChannelFrequency);
                 % As peer node is also of same BW and center frequency, configuring same
                 % primary index as this node
                 wlan.internal.utils.setPrimaryChannelInfoAtLayers(peerNode, peerDeviceID, primaryChannelIdx, primaryChannelFrequency);

             elseif any(peerNodeID == [obj.RemoteSTAInfo(:).NodeID])
                 % Update the information if it is already present
                 peerNodeIdxLogical = (peerNodeID == [obj.RemoteSTAInfo(:).NodeID]);
                 staInfo = obj.RemoteSTAInfo(peerNodeIdxLogical);
                 if ~any(selfDeviceID == staInfo.DeviceID)
                     idx = numel(staInfo.DeviceID)+1;
                     staInfo.MACAddress(idx, :) = peerNodeAddress;
                     staInfo.DeviceID(idx) = selfDeviceID;
                     staInfo.Mode = "mesh";
                     bwToUseInHz = min(obj.DeviceConfig(selfDeviceID).ChannelBandwidth, ...
                         peerNode.DeviceConfig(peerDeviceID).ChannelBandwidth);
                     staInfo.Bandwidth = bwToUseInHz/1e6; % In MHz
                     obj.RemoteSTAInfo(peerNodeIdxLogical) = staInfo;
                     addRemoteSTAInfo(obj.SharedMAC(selfDeviceID), staInfo);

                     % Add primary channel information at MAC and phy modules
                     primaryChannelIdx = 1; % Not configurable for mesh. Hence consider default
                     devCfg = wlan.internal.utils.getDeviceConfig(obj, selfDeviceID);
                     [~,primaryChannelFrequency] = wlan.internal.utils.getPrimaryChannel(devCfg.BandAndChannel, devCfg.ChannelBandwidth, primaryChannelIdx);
                     wlan.internal.utils.setPrimaryChannelInfoAtLayers(obj, selfDeviceID, primaryChannelIdx, primaryChannelFrequency);
                     % As peer node is also of same BW and center frequency, configuring same
                     % primary index as this node
                     wlan.internal.utils.setPrimaryChannelInfoAtLayers(peerNode, peerDeviceID, primaryChannelIdx, primaryChannelFrequency);
                 end
             end
         end

         function setAlias(obj, property, value)
             switch property
                 case "PHYAbstractionMethod"
                     switch value
                         case "none" 
                             obj.PHYModel = "full-phy";
                         case "tgax-mac-calibration"
                             obj.PHYModel = "abstract-phy-tgax-mac-calibration";
                         otherwise % "tgax-evaluation-methodology"
                             obj.PHYModel = "abstract-phy-tgax-evaluation-methodology";
                     end
                 case "MACFrameAbstraction"
                     if value
                         obj.MACModel = "full-mac-with-frame-abstraction";
                     else
                         obj.MACModel = "full-mac";
                     end
                 case "PHYModel"
                     switch value
                         case "full-phy"
                             obj.PHYAbstractionMethod = "none";
                         case "abstract-phy-tgax-mac-calibration"
                             obj.PHYAbstractionMethod = "tgax-mac-calibration";
                         otherwise % "abstract-phy-tgax-evaluation-methodology"
                             obj.PHYAbstractionMethod = "tgax-evaluation-methodology";
                     end
                 case "MACModel"
                     if strcmp(value, "full-mac")
                         obj.MACFrameAbstraction = false;
                     else % "full-mac-with-frame-abstraction"
                         obj.MACFrameAbstraction = true;
                     end
             end
         end
    end
end
