classdef (Abstract) wlanRateControl < handle & matlab.mixin.Copyable
%wlanRateControl Implement rate control algorithm
%   Use this base class to implement any rate control algorithm for
%   single-user transmissions.
%
%   The subclass that extends this base class is required to define these
%   methods and properties:
%       * selectRateParameters method: 
%               This method returns the rate parameters necessary for frame
%               transmission.
%       * processTransmissionStatus method: 
%               This method manages post-transmission operations based on
%               the transmission's success or failure
%       * CustomContextTemplate property: 
%               Specify this property must be specified as a structure
%               containing all fields unique for each receiver. This value
%               specifies the default template for the CustomContext field
%               within the STAContext property.
%
%   wlanRateControl methods (Abstract):
%
%   selectRateParameters        - Select rate control parameters for frame
%                                 transmission
%   processTransmissionStatus   - Process frame transmission status to
%                                 perform post-transmission operations
%
%   wlanRateControl properties (Abstract):
%
%   CustomContextTemplate   - Default custom contextual information
%                             template for each receiver
%
%   wlanRateControl methods:
%
%   deviceConfigurationValue    - Retrieve value of the specified 
%                                 property in the device configuration
%   deviceConfigurationType     - Return the type of device configuration
%                                 on which rate control is implemented
%   bssConfigurationValue       - Retrieve value of the specified BSS
%                                 configuration
%   maxMCS                      - Return maximum MCS that you can select
%   maxNumSpaceTimeStreams      - Return maximum number of space time
%                                 streams that you can select
%   mapReceiverToSTAContext     - Return the index for STAContext 
%                                 property corresponding to the given
%                                 receiver
%
%   wlanRateControl properties:
%
%   STAContext      - Algorithm specific contextual information for each STA

%   Copyright 2024-2025 The MathWorks, Inc.

properties (Access=protected, Abstract)
    %CustomContextTemplate Default custom contextual information template
    %for each receiver
    %   This property defines the information that needs to be maintained
    %   for each receiver. This value is used as the default value for
    %   CustomContext field in STAContext property. The inheriting
    %   sub-class can modify and use this information in its algorithm.
    % 
    %   The inherting sub-class can define this property as a structure with
    %   the necessary fields. For example, current MCS and current NSTS
    %   selected by the algorithm can vary for each receiver. The inheriting
    %   sub-class can define this property as a structure with CurrentMCS and
    %   CurrentNSTS as fields.
    CustomContextTemplate
end

properties (Access=protected)
    %STAContext Algorithm specific contextual information for each STA
    %   This property holds the contextual information that can change for
    %   each receiver. It is an array of structures containing these
    %   fields:
    %       ReceiverID      - Receiver Node ID
    %       CustomContext   - Custom context holding per-receiver information
    %
    %   The default values for this property are assigned by the node. For each
    %   receiver communicating with this node, the node adds an additional
    %   structure to this property with the ReceiverID field containing the
    %   actual receiver ID and the CustomContext field containing the value
    %   defined by the CustomContextTemplate abstract property. The inheriting
    %   sub-class can modify and use the CustomContext for each receiver in
    %   this property.
    STAContext
end

properties (Hidden, Access=protected)
    %DeviceConfig Device configuration
    %   This property is assigned by the node. It holds the configuration for
    %   the device. If the node is a non-MLD, this is a scalar object of type
    %   wlanDeviceConfig. If the node is an MLD, this is a scalar object of 
    %   type wlanMultilinkDeviceConfig and the LinkID property indicates the 
    %   link configuration within this MLD configuration object on which this
    %   rate control object is installed.
    DeviceConfig

    %LinkID Identifier for link in the MLD configuration for the operating frequency
    %   This property is assigned by the node. It holds the index of the link
    %   configuration in the array of link configuration objects present in the
    %   MLD object represented by DeviceConfig property. This
    %   property is only applicable when DeviceConfig is of type wlanMultilinkDeviceConfig.
    LinkID

    %BasicRates Non-HT data rates supported in the BSS
    %   This property is assigned by the node. It holds the Non-HT data rates
    %   supported in the BSS in Mbps as a vector which is subset of [6 9 12 18
    %   24 36 48 54]. The Non-HT rates [6 9 12 18 24 36 48 54] are represented
    %   by MCS indices 0-7 during the selection of MCS value in the 
    %   selectRateParameters method. If the property Use6MbpsForControlFrames
    %   is set to true in the device (or link) configuration then the control
    %   frames are forced to use 6 Mbps date rate without consideration for the
    %   rate control algorithm.
    BasicRates

    %ReceiverIDs List of receiver node IDs
    %   This property holds the list of receiver node IDs for which the context
    %   is being maintained.
    ReceiverIDs

    %MaxSupportedMCS Maximum MCS supported by the transmitter and receiver
    %   This property holds the maximum MCS that is supported by the
    %   transmitter and the receiver.
    MaxSupportedMCS

    %MaxSupportedNSTS Maximum NSTS supported by the transmitter and receiver
    %   This property holds the maximum number of space time streams that are
    %   supported by the transmitter and the receiver.
    MaxSupportedNSTS

    %ObjectAdded Flag indicating that this handle object is added to a node
    ObjectAdded = false;
end

methods
    % Constructor method
    function obj = wlanRateControl(varargin)
        % Name-value pair check
        if (mod(nargin, 2)~=0)
            error(message('wlan:ConfigBase:InvalidPVPairs'))
        end

        for i = 1:2:nargin
            obj.(varargin{i}) = varargin{i+1};
        end
    end
end

methods (Abstract)
    %selectRateParameters Select the rate parameters for frame transmission
    %
    % RATEPARAMS = selectRateParameters(OBJ, TXCONTEXT) returns the rate
    % parameters as a structure that will be used for for transmitting the
    % frame.
    %
    %   RATEPARAMS is a structure containing the rate information that is used
    %   by the node for transmitting the frame. It contains the following
    %   fields:
    %       MCS                  - Non negative integer specifying the
    %                              MCS index used for the frame transmission to
    %                              the station specified in the TXCONTEXT. This
    %                              value must lie in the range of 0 to the
    %                              value returned by maxMCS method.
    %                              Additionally, for control frames, the value
    %                              must also be supported as part of BasicRates
    %                              property.
    %                              Note that,
    %                                   * The selected Non-HT MCS values must
    %                                   be between 0-7 and these values map to
    %                                   data rates [6 9 12 18 24 36 48 54].
    %                                   * The selected HT MCS values must be
    %                                   between 0-7 and these values map to a
    %                                   value in the range [0, 31] using the
    %                                   calculation MCS+(NSTS–1)*8, where NSTS
    %                                   is the value of the NumSpaceTimeStreams
    %                                   field.
    %
    %       NumSpaceTimeStreams  - Positive integer specifying the number of
    %                              space-time streams for the frame
    %                              transmission to the station specified in the
    %                              TXCONTEXT. This value must lie in the range
    %                              of 0 to the value returned by
    %                              maxNumSpaceTimeStreams method.
    %
    %   OBJ is an object of type wlanRateControl.
    %
    %   TXCONTEXT is a structure containing the information about the frame
    %   being transmitted and the transmission context required for the
    %   algorithm to select rate control parameters. It contains the following
    %   fields:
    %       FrameType           - Frame type for which the rate control
    %                             algorithm is invoked. It is specified as one
    %                             of "QoS Data" or "RTS".
    %
    %       ReceiverNodeID      - Node ID of the receiver to which the frame is
    %                             being transmitted. It is specified as a
    %                             scalar integer.
    %
    %       IsRetry             - Flag indicating if the frame is a
    %                             retransmission. It is specified as true if
    %                             the frame is a retransmission.
    %
    %       TransmissionFormat  - String indicating the PHY format used for
    %                             transmission format. It is specified as
    %                             one of "Non-HT", "HT-Mixed", "VHT", "HE-SU",
    %                             "HE-EXT-SU", "HE-MU", "HE-TB", or "EHT-SU".
    %                             If FrameType field value is "RTS", the
    %                             value of this field is always set to "Non-HT".
    %
    %       ChannelBandwidth    - Channel bandwidth that will be used for
    %                             transmission. It is specified in Hz as one of
    %                             20e6, 40e6, 80e6, 160e6, or 320e6.
    %
    %       CurrentTime         - Scalar value representing current simulation
    %                             time in seconds.
    rateParams = selectRateParameters(obj, txContext)

    %processTransmissionStatus Process frame transmission status to perform
    %post-transmission operations
    %
    %   processTransmissionStatus(OBJ, TXCONTEXT, TXSTATUSINFO) performs the
    %   operations that should happen after the frame is transmitted based on
    %   the status of the transmission for which rate parameters were selected.
    %
    %   OBJ is an object of type wlanRateControl.
    %
    %   TXCONTEXT is a structure containing the information about the
    %   transmitted frame and the transmission context using which the
    %   algorithm has previously selected rate control parameters. It contains
    %   the following fields:
    %       FrameType           - Frame type for which the rate control
    %                             algorithm is invoked. It is specified as one
    %                             of "QoS Data" or "RTS".
    %
    %       ReceiverNodeID      - Node ID of the receiver to which the frame is
    %                             being transmitted. It is specified as a
    %                             scalar integer.
    %
    %       IsRetry             - Flag indicating if the frame is a
    %                             retransmission. It is specified as true if
    %                             the frame is a retransmission.
    %
    %       TransmissionFormat  - String indicating the PHY format used for
    %                             transmission format. It is specified as
    %                             one of "Non-HT", "HT-Mixed", "VHT", "HE-SU",
    %                             "HE-EXT-SU", "HE-MU", "HE-TB", or "EHT-SU".
    %                             If FrameType field value is "RTS", the
    %                             value of this field is always set to "Non-HT".
    %
    %       ChannelBandwidth    - Channel bandwidth that will be used for 
    %                             transmission. It is specified in Hz as one of
    %                             20e6, 40e6, 80e6, 160e6, or 320e6.
    %
    %       CurrentTime         - Scalar value representing current simulation
    %                             time in seconds.
    %
    %   TXSTATUSINFO is a structure containing the status of the frame
    %   transmission along with information that may be required for updating
    %   the rate table in the algorithm. It contains the following fields:
    %
    %       IsMPDUSuccess       - Vector of logical values representing the
    %                             transmission status as success or failure.
    %                             Each element in the vector corresponds to the
    %                             status of an MPDU, where true indicates a
    %                             succesful transmission and false indicates a
    %                             failed transmission.
    %
    %       IsMPDUDiscarded     - Vector of logical values representing if the
    %                             frame has been discarded due to successful
    %                             transmission, retry exhaustion, or lifetime
    %                             expiry. Each element in the vector
    %                             corresponds to the discard status of an MPDU,
    %                             where true indicates that it is discarded and
    %                             false indicates that it is not discarded.
    %
    %                               When FrameType is "RTS", IsMPDUDiscarded 
    %                             flag indicates the discard status of data 
    %                             packets from transmission queues.
    %
    %       CurrentTime         - Scalar value representing current simulation
    %                             time in seconds.
    %
    %       ResponseRSSI        - Scalar value indicating the signal strength of 
    %                             the received response in the form of an Ack
    %                             frame, a Block Ack frame, or a CTS frame.
    processTransmissionStatus(obj, txContext, txStatusInfo)
end

methods(Sealed)
    function value = deviceConfigurationValue(obj, prop, varargin)
    %deviceConfigurationValue Retrieves the specified device configuration
    %
    %   VALUE = deviceConfigurationValue(OBJ, PROP) returns the configured
    %   value for the specified property, PROP. 
    %
    %   PROP is a scalar string or a character vector that represents a
    %   property from any of the objects of type wlanDeviceConfig, 
    %   wlanMultilinkDeviceConfig, or wlanLinkConfig. Use
    %   deviceConfigurationType method to determine whether the device on which
    %   rate control object is installed is of type 'wlanDeviceConfig' or
    %   'wlanMultilinkDeviceConfig'. If it returned 'wlanDeviceConfig', the
    %   PROP value must be a valid property from wlanDeviceConfig object.
    %   If it returned 'wlanMultilinkDeviceConfig', the PROP value must be a
    %   valid property from either wlanMultilinkDeviceConfig, or 
    %   wlanLinkConfig.
    %
    %   VALUE is the configured value for the specified property in
    %   wlanDeviceConfig, wlanMultilinkDeviceConfig, or wlanLinkConfig based on
    %   the device configuration type. If the device configuration type is
    %   'wlanMultilinkDeviceConfig' and the property corresponds to
    %   wlanLinkConfig object, the returned value corresponds to the link on
    %   which the rate control object is installed.
    %
    %   VALUE = deviceConfigurationValue(OBJ, PROP, AllLinks=true) returns the
    %   configured values for all the links of the specified property, PROP.
    %   The AllLinks option is applicable only when the device configuration
    %   type is 'wlanMultilinkDeviceConfig'. PROP must be a valid property of
    %   wlanLinkConfig object, specified as a string or character vector.
    %   'AllLinks' option is ignored in all other invalid cases.
    
        if strcmp(prop, "RateControl")
            value = obj;
            return;
        end

        persistent wlanDeviceConfig_PropertyList wlanLinkConfig_PropertyList wlanMultilinkDeviceConfig_PropertyList
        if isempty(wlanDeviceConfig_PropertyList)
            wlanDeviceConfig_PropertyList = properties(wlanDeviceConfig);
            wlanLinkConfig_PropertyList = properties(wlanLinkConfig);
            wlanMultilinkDeviceConfig_PropertyList = properties(wlanMultilinkDeviceConfig);
        end

        funcname = 'deviceConfigurationValue';
        if isa(obj.DeviceConfig,'wlanDeviceConfig') % non-MLD
            if ~any(strcmp(prop, wlanDeviceConfig_PropertyList))
                error(message('wlan:wlanRateControl:UnknownProperty',funcname,'wlanDeviceConfig'))
            end
            value = obj.DeviceConfig.(prop);
        elseif isa(obj.DeviceConfig,'wlanMultilinkDeviceConfig') % MLD
            if any(strcmp(prop, wlanLinkConfig_PropertyList))
                allLinks = false;
                if ~isempty(varargin)
                    if (numel(varargin) ~= 2)
                        error(message("wlan:shared:InvalidNVPairs"))
                    end
                    if ~strcmpi(varargin{1},'AllLinks') || ~islogical(varargin{2}) || ~isscalar(varargin{2})
                        error(message("wlan:wlanRateControl:InvalidAllLinksParam"))
                    end
                    allLinks = varargin{2};
                end
                if allLinks
                    value = [obj.DeviceConfig.LinkConfig(:).(prop)];
                else
                    value = obj.DeviceConfig.LinkConfig(obj.LinkID).(prop);
                end
            else
                if ~any(strcmp(prop, wlanMultilinkDeviceConfig_PropertyList))
                    error(message('wlan:wlanRateControl:UnknownProperty',funcname,'wlanLinkConfig or wlanMultilinkDeviceConfig'))
                end
                value = obj.DeviceConfig.(prop);
            end
        else % empty
            error(message('wlan:wlanRateControl:DeviceConfigEmpty',funcname))
        end
    end

    function devType = deviceConfigurationType(obj)
    %deviceConfigurationType Returns the type of device configuration object
    %
    %   DEVTYPE = deviceConfigurationType(OBJ) returns the class type of device
    %   configuration object.
    %   
    %   DEVTYPE is a character vector representing the class of device
    %   configuration object as one of 'wlanDeviceConfig' or
    %   'wlanMultilinkDeviceConfig'.

        if isempty(obj.DeviceConfig)
            error(message('wlan:wlanRateControl:DeviceConfigEmpty','deviceConfigurationType'))
        end
        devType = class(obj.DeviceConfig);
    end

    function value = bssConfigurationValue(obj, prop)
    %bssConfigurationValue Retrieves the specified BSS configuration value
    %
    %   VALUE = bssConfigurationValue(OBJ, "BasicRates") returns the basic rate
    %   set value configured for the BSS.
    %
    %   VALUE is the set of Non-HT data rates supported in the BSS in Mbps
    %   which is subset of [6 9 12 18 24 36 48 54]. The Non-HT rates [6 9 12 18
    %   24 36 48 54] are represented by MCS indices 0-7 during the selection of
    %   MCS value in the selectRateParameters method. If the property 
    %   Use6MbpsForControlFrames is set to true in the device (or link) 
    %   configuration then the control frames are forced to use 6 Mbps date
    %   rate without consideration for the rate control algorithm.

        if isempty(obj.BasicRates)
            error(message('wlan:wlanRateControl:AssociationConfigEmpty','bssConfigurationValue'))
        end
        if ~any(strcmp(prop, "BasicRates"))
            error(message('wlan:wlanRateControl:UnknownAssociationConfig','bssConfigurationValue'))
        end
        value = obj.BasicRates;
    end

    function mcs = maxMCS(obj, receiverNodeID, txFormat, nsts, cbw)
    %maxMCS Returns the maximum MCS that can be selected for the
    %given receiver
    %
    %   MCS = maxMCS(OBJ, RECEIVERNODEID, TXFORMAT, NSTS, CBW) returns the
    %   maximum MCS value that can be selected by the algorithm for the given
    %   receiver identified by the receiver node ID, RECEIVERNODEID.
    %
    %   MCS is the maximum value of modulation and coding scheme index that is
    %   allowed for the specified receiver.
    %
    %   RECEIVERNODEID is the node ID of the receiver node for which the 
    %   frame transmission is intended. Specify this value as a scalar integer.
    %
    %   TXFORMAT is the transmission format being used for the receiver
    %   specified as one of "Non-HT", "HT-Mixed", "VHT", "HE-SU", "HE-EXT-SU",
    %   "HE-MU", "HE-TB", or "EHT-SU".
    %
    %   NSTS is the number of space time streams being used for the
    %   transmission, specified as a scalar integer in the range [1,8].
    %
    %   CBW is the channel bandwidth in Hz being used for the transmission, 
    %   specified as one of 20e6, 40e6, 80e6, 160e6, or 320e6 Hz.

        if strcmp(txFormat, "EHT-SU")
            maxStdMCS = 13;
        elseif any(strcmp(txFormat, ["HE-SU", "HE-TB", "HE-MU"]))
            maxStdMCS = 11;
        elseif strcmp(txFormat, "HE-EXT-SU")
            maxStdMCS = 2;
        elseif strcmp(txFormat, "VHT")
            % In VHT format, maximum MCS value depends on bandwidth
            % and number of space time streams
            switch cbw
                case  20000000
                    if (nsts == 3) || (nsts == 6)
                        maxStdMCS = 9;
                    else
                        maxStdMCS = 8;
                    end
                case 40000000
                    maxStdMCS = 9;
                case 80000000
                    if (nsts == 6)
                        maxStdMCS = 8;
                    else
                        maxStdMCS = 9;
                    end
                otherwise % 160000000
                    if (nsts == 3)
                        maxStdMCS = 8;
                    else
                        maxStdMCS = 9;
                    end
            end
        elseif strcmp(txFormat, "HT-Mixed")
            if nsts > 4
                error(message("wlan:wlanRateControl:InvalidNSTSHT"))
            end
            maxStdMCS = 7;
        else % "Non-HT"
            if nsts > 1
                error(message("wlan:wlanRateControl:InvalidNSTSNonHT"))
            end
            maxStdMCS = 7;
        end

        rxIdx = mapReceiverToSTAContext(obj, receiverNodeID);
        mcs = min([maxStdMCS, obj.MaxSupportedMCS(rxIdx)]);
    end

    function nsts = maxNumSpaceTimeStreams(obj, receiverNodeID, txFormat)
    %maxNumSpaceTimeStreams Returns the maximum number of space time streams
    %that can be selected for the given receiver
    %
    %   NSTS = maxNumSpaceTimeStreams(OBJ, RECEIVERNODEID, TXFORMAT) returns
    %   the maximum number of space time streams value that can be selected by
    %   the algorithm for the given receiver identified by the receiver node
    %   ID, RECEIVERNODEID.
    %
    %   NSTS is the maximum value of number of space time streams that is
    %   allowed for the specified receiver.
    %
    %   RECEIVERNODEID is the node ID of the receiver node for which the 
    %   frame transmission is intended. Specify this value as a scalar integer.
    %
    %   TXFORMAT is the transmission format being used for the receiver
    %   specified as one of the values supported by TransmissionFormat
    %   property of wlanDeviceConfig object.

        if strcmp(txFormat, "Non-HT")
            maxStdNSTS = 1;
        elseif strcmp(txFormat, "HT-Mixed")
            maxStdNSTS = 4;
        else % VHT, HE, EHT
            maxStdNSTS = 8;
        end

        numTxAntennas = deviceConfigurationValue(obj, "NumTransmitAntennas");
        if isEMLSRSTA(obj)
            % For EMLSR stations, the max NSTS value is limited by sum of transmit
            % antennas on all the links.
            numTxAntennas = sum([obj.DeviceConfig.LinkConfig(:).NumTransmitAntennas]);
        end
        rxIdx = mapReceiverToSTAContext(obj, receiverNodeID);
        nsts = min([maxStdNSTS, numTxAntennas, obj.MaxSupportedNSTS(rxIdx)]);
    end

    function index = mapReceiverToSTAContext(obj, receiverNodeID)
    %mapReceiverToSTAContext Returns the index for the STAContext property
    %corresponding to the given receiver
    %
    %   INDEX = mapReceiverToSTAContext(OBJ, RECEIVERNODEID) returns the index,
    %   INDEX, for the STAContext property corresponding to the given receiver
    %   identified by the receiver node ID, RECEIVERNODEID.
    %
    %   INDEX is the index in the vector of STAContext property that
    %   corresponds to the specified receiver with node ID, RECEIVERNODEID.
    %
    %   RECEIVERNODEID is the node ID of the receiver node for which the rate
    %   control algorithm is invoked. It is specified as a scalar integer.

        index = find(obj.ReceiverIDs == receiverNodeID);
        if isempty(index)
            error(message("wlan:wlanRateControl:UnknownReceiverID"))
        end
    end
end

methods(Hidden, Sealed)
    function setDeviceConfig(obj, devCfg, linkID)
    %setDeviceConfig Store device configuration
        % Remove self-handle reference from the configuration to avoid cyclic dependency
        if isa(devCfg,'wlanMultilinkDeviceConfig')
            for idx = 1:numel(devCfg.LinkConfig)
                linkCfg = devCfg.LinkConfig(idx);
                linkCfg.RateControl = "fixed";
                devCfg = updateLinkConfig(devCfg, idx, linkCfg);
            end
        else % wlanDeviceConfig
            for idx = 1:numel(devCfg)
                devCfg(idx).RateControl = "fixed";
            end
        end
        % Store the configuration
        obj.DeviceConfig = devCfg;
        obj.LinkID = linkID;
    end

    function setAssociationConfig(obj, basicRates)
    %setAssociationConfig Store association configuration
        obj.BasicRates = basicRates;
    end

    function setReceiverContext(obj, receiverID, capabilities)
    %setReceiverContext Set per-receiver custom context
        if any(receiverID == obj.ReceiverIDs)
            rxIdx = find(receiverID == obj.ReceiverIDs);
            staContext = struct(ReceiverID=receiverID, CustomContext=obj.CustomContextTemplate);
            obj.STAContext(rxIdx) = staContext;
            obj.MaxSupportedMCS(rxIdx) = capabilities.MaxMCS;
            obj.MaxSupportedNSTS(rxIdx) = capabilities.MaxNumSpaceTimeStreams;
        else
            obj.ReceiverIDs = [obj.ReceiverIDs receiverID];
            staContext = struct(ReceiverID=receiverID, CustomContext=obj.CustomContextTemplate);
            obj.STAContext = [obj.STAContext staContext];
            obj.MaxSupportedMCS = [obj.MaxSupportedMCS capabilities.MaxMCS];
            obj.MaxSupportedNSTS = [obj.MaxSupportedNSTS capabilities.MaxNumSpaceTimeStreams];
        end
    end

    function flag = isEMLSRSTA(obj)
    %isEMLSRSTA Returns true if this rate control algorithm is installed on an EMLSR STA

        flag = false;
        if isa(obj.DeviceConfig,'wlanMultilinkDeviceConfig') && strcmp(obj.DeviceConfig.Mode, 'STA') && strcmp(obj.DeviceConfig.EnhancedMultilinkMode,'EMLSR')
            flag = true;
        end
    end

    function rateParams = rateParameters(obj, txContext)
    %rateParameters Calls selectRateParameters and returns its output after
    %validation

        rateParams = selectRateParameters(obj, txContext);
        % Validate output rate parameters structure
        if isscalar(rateParams) && isfield(rateParams,'MCS') && isfield(rateParams,'NumSpaceTimeStreams')
            nsts = rateParams.NumSpaceTimeStreams;
            mcs = rateParams.MCS;
            if strcmp(txContext.FrameType,'QoS Data')
                maxMCSValue = maxMCS(obj, txContext.ReceiverNodeID, txContext.TransmissionFormat, rateParams.NumSpaceTimeStreams, txContext.ChannelBandwidth);
                maxNSTSValue = maxNumSpaceTimeStreams(obj, txContext.ReceiverNodeID, txContext.TransmissionFormat);
            else % RTS
                maxMCSValue = 7;
                maxNSTSValue = 1;
            end
            if isempty(nsts) || ~isscalar(nsts) || ~isnumeric(nsts)|| (mod(nsts,1)~=0) || (nsts < 1) || (nsts > maxNSTSValue)
                error(message('wlan:wlanRateControl:InvalidOutputNSTS', maxNSTSValue,txContext.FrameType))
            end
            if isempty(mcs) || ~isscalar(mcs) || ~isnumeric(mcs)|| (mod(mcs,1)~=0) || (mcs < 0) || (mcs > maxMCSValue)
                error(message('wlan:wlanRateControl:InvalidOutputMCS', maxMCSValue, txContext.FrameType))
            end
        else
            error(message("wlan:wlanRateControl:UnexpectedRateParamsOutput"))
        end
    end
end
end
