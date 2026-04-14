classdef (Abstract) PHYTx < handle
%PHYTx Define WLAN physical layer transmitter interface
%class
%   The class acts as a base class for all the WLAN physical layer
%   transmitters. It defines the interface to physical layer transmitter.
%   It declares the properties and methods to be used by higher layers to
%   interact with the phy transmitter.

%   Copyright 2022-2025 The MathWorks, Inc.

% Public, tunable properties
properties
    %IsNodeTypeAP Flag for node type
    %   Specify the type of node (AP/STA). Value true denotes AP & false
    %   denotes STA
    IsNodeTypeAP (1, 1) logical = false;

    %TxGain Signal transmission gain in dB
    %   Specify the Tx power as a scalar value. It specifies the signal
    %   transmission gain in dB. The default value is 1 dB.
    TxGain (1, 1) {mustBeNumeric, mustBeFinite} = 1.0;

    %DeviceID Identifier of device containing PHY
    %   Specify the device identifier containing PHY layer as an integer
    %   scalar starting from 1.
    DeviceID = 1;

    %EventNotificationFcn Function handle to notify the node about event
    %trigger
    %   Specify the function handle to notify the node about event trigger.
    EventNotificationFcn = [];

    %SendPacketFcn Function handle to notify the node to send the packet
    %   Specify the function handle to notify the node to send the packet
    SendPacketFcn = [];

    %PrimaryChannelIndex Primary channel index
    PrimaryChannelIndex = 1;
end

properties (Hidden)
    % Structure holding the default template for output waveform data
    TransmitWaveformTemplate

    %OperatingFrequency Frequency of operation in Hz
    OperatingFrequency = 5.180*1e9;

    %HasListener Structure with event names as field names containing flags
    %indicating whether they have a listener
    HasListener = wlan.internal.utils.defaultEventList;
end

% Configure based on values from MAC
properties (Access = protected)
    % Waveform generator configuration objects (Tx)

    %NonHTConfig Non-HT configuration object
    NonHTConfig;

    %HTConfig HT configuration object
    HTConfig;

    %VHTConfig VHT configuration object
    VHTConfig;

    %HESUConfig HE-SU configuration object
    HESUConfig;

    %HEMUConfig HE-MU configuration object
    HEMUConfig;

    %HETBConfig HE-TB configuration object
    HETBConfig;

    %EHTSUConfig EHT-SU configuration object
    EHTSUConfig;
end

properties (Access = protected)
    %TxVector Structure for storing Tx Vector information
    TxVector;

    %UserIndexSU User index for single user processing. Index '1' will be
    %used in case of single user and downlink multi-user reception. Indices
    %greater than '1' will be used in case of downlink multi-user
    %transmission and uplink multi-user reception.
    UserIndexSU = 1;

    %MaxSubframes Maximum subframes in an AMPDU
    MaxSubframes = 256;

    %MaxMUUsers Maximum number of users
    MaxMUUsers = 74;

    %ChannelBandwidth Channel Bandwidth
    ChannelBandwidth = 20;

    %NumUsers Number of users in MU PPDU transmission
    NumUsers = 1;

    %NumSTS Number of space time streams
    NumSTS;
end

% PHY transmitter statistics
properties (GetAccess = public, SetAccess = protected)
    %TransmittedPackets Number of packets transmitted from PHY
    TransmittedPackets = 0;

    %PhyNumTxWhileActiveOBSSTx Number of transmissions when there are
    %active transmissions in overlapping basic service sets (BSS) and BSS
    %coloring is enabled
    PhyNumTxWhileActiveOBSSTx = 0;

    %TransmittedPayloadBytes Number of bytes transmitted from PHY
    TransmittedPayloadBytes = 0;
end

% Constant Properties
properties(Constant, Hidden)
    % Frame formats
    NonHT = wlan.internal.FrameFormats.NonHT;
    HTMixed = wlan.internal.FrameFormats.HTMixed;
    VHT = wlan.internal.FrameFormats.VHT;
    HE_SU = wlan.internal.FrameFormats.HE_SU;
    HE_EXT_SU = wlan.internal.FrameFormats.HE_EXT_SU;
    HE_MU = wlan.internal.FrameFormats.HE_MU;
    HE_TB = wlan.internal.FrameFormats.HE_TB;
    EHT_SU = wlan.internal.FrameFormats.EHT_SU;

    % Packet is empty
    PacketTypeEmpty = wlan.internal.Constants.PacketTypeEmpty;

    % Packet contains IQ samples as data (Full MAC + Full PHY)
    DataTypeIQData = wlan.internal.Constants.DataTypeIQData;

    % Packet containa MAC frame bits as data (Full MAC + ABS PHY)
    DataTypeMACFrameBits = wlan.internal.Constants.DataTypeMACFrameBits;

    % Packet contains MAC configuration structure as data (ABS MAC + ABS PHY)
    DataTypeMACFrameStruct = wlan.internal.Constants.DataTypeMACFrameStruct;

    % PHY primitives
    CCAIndication = wlan.internal.PHYPrimitives.CCAIndication;
    RxStartIndication = wlan.internal.PHYPrimitives.RxStartIndication;
    RxEndIndication = wlan.internal.PHYPrimitives.RxEndIndication;
    RxErrorIndication = wlan.internal.PHYPrimitives.RxErrorIndication;
    TxStartRequest = wlan.internal.PHYPrimitives.TxStartRequest;
    UnknownIndication = wlan.internal.PHYPrimitives.UnknownIndication;
end

% PHY transmitter events
properties (SetAccess = protected)
    % Structure capturing state changes for statistics/visualization
    StateChangedTemplate;
end

methods (Abstract, Access = protected)
    txWaveform = generateWaveform(obj, currentTime, frameToPHY);
    % generateWaveform Generate the WLAN waveform
    %
    %   TXWAVEFORM = generateWaveform (OBJ, CURRENTTIME, PPDU) generates a WLAN
    %   waveform containing PHY and MAC metadata.
    %
    %   TXWAVEFORM is the output waveform to be transmitted which is a
    %   structure of type wirelessPacket.
    %
    %   CURRENTTIME is the simulation time in nanoseconds.
    %
    %   PPDU - PPDU is the received WLAN physical layer Protocol Data
    %          Unit (PDU).
end

methods (Access = protected)
    function durations = getFieldDurations(obj)
        % Returns a structure with the legacy-preamble, header,
        % mimo-preamble, and symbol durations in nanoseconds

        switch obj.TxVector.PPDUFormat
            case obj.NonHT
                headerDuration = 4e3; % Header duration - L-SIG
                mimoPreambleDuration = 0; % Only L-LTF present
                symbolDuration = 4e3;

            case obj.HTMixed
                % Header duration - L-SIG + HT-SIG1 + HT-SIG2
                headerDuration = (1 + 2) * 4e3;
                if wlan.internal.inESSMode(obj.HTConfig)
                    numESS = obj.HTConfig.NumExtensionStreams;
                else
                    numESS = 0;
                end
                % MIMO preamble duration - HT-STF + HT-LTF
                numMIMOPreamSym = 1 + wlan.internal.numVHTLTFSymbols(obj.HTConfig.NumSpaceTimeStreams) + wlan.internal.numHTELTFSymbols(numESS);
                mimoPreambleDuration = numMIMOPreamSym * 4e3;
                symbolDuration = 4e3;
                assert(strcmp(obj.HTConfig.GuardInterval,'Long'),'Only long GI supported')

            case obj.VHT
                % Header duration - L-SIG + VHT-SIG-A1 + VHT-SIG-A2
                % VHT header can optinally be extended to end of first
                % VHT-Data symbols, this is to be considered for VHT-MU
                headerDuration = (1 + 2) * 4e3;
                % MIMO preamble duration - VHT-STF + VHT-LTF + VHT-SIG-B
                numMIMOPreamSym = 1 + wlan.internal.numVHTLTFSymbols(sum(obj.VHTConfig.NumSpaceTimeStreams)) + 1;
                mimoPreambleDuration = numMIMOPreamSym * 4e3;
                symbolDuration = 4e3;
                assert(strcmp(obj.VHTConfig.GuardInterval,'Long'),'Only long GI supported')

            case {obj.HE_SU, obj.HE_EXT_SU}
                trc = wlan.internal.heTimingRelatedConstants(obj.HESUConfig.GuardInterval,obj.HESUConfig.HELTFType,4,0);
                switch obj.TxVector.PPDUFormat
                    case obj.HE_SU
                        % Header duration - L-SIG + RL-SIG + HE-SIG-A (8Î¼s)
                        headerDuration = trc.TLSIG + trc.TRLSIG + trc.THESIGA;
                    otherwise % obj.HE_EXT_SU
                        % Header duration - L-SIG + RL-SIG + HE-SIG-A (16Î¼s)
                        headerDuration = trc.TLSIG + trc.TRLSIG + trc.THESIGAR;
                end
                % MIMO preamble duration - HE-STF + HE-LTF
                NHELTF = wlan.internal.numVHTLTFSymbols(obj.HESUConfig.NumSpaceTimeStreams);
                mimoPreambleDuration = trc.THESTFNT + NHELTF * trc.THELTFSYM;
                symbolDuration = trc.TSYM;

            case obj.HE_MU
                % Header duration - L-SIG + RL-SIG + HE-SIG-A + HE-SIG-B
                sigbInfo = wlan.internal.heSIGBCodingInfo(obj.HEMUConfig);
                NHESIGB = sigbInfo.NumSymbols;
                trc = wlan.internal.heTimingRelatedConstants(obj.HEMUConfig.GuardInterval,obj.HEMUConfig.HELTFType,4,0);
                headerDuration = trc.TLSIG + trc.TRLSIG + trc.THESIGA + NHESIGB*trc.THESIGB;
                % MIMO preamble duration - HE-STF + HE-LTF
                allocationInfo = ruInfo(obj.HEMUConfig);
                NHELTF = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU(allocationInfo.RUAssigned)));
                mimoPreambleDuration = trc.THESTFNT + NHELTF*trc.THELTFSYM;
                symbolDuration = trc.TSYM;

            case obj.HE_TB
                % Header duration - L-SIG + RL-SIG + HE-SIG-A
                trc = wlan.internal.heTBTimingRelatedConstants(obj.HETBConfig);
                headerDuration = trc.TLSIG + trc.TRLSIG + trc.THESIGA;
                % MIMO preamble duration - HE-STF + HE-LTF
                NHELTF = obj.HETBConfig.NumHELTFSymbols;
                mimoPreambleDuration = trc.THESTFT + NHELTF * trc.THELTFSYM;
                symbolDuration = trc.TSYM;

            case obj.EHT_SU
                % Header duration - L-SIG + RL-SIG + U-SIG + EHT-SIG
                ehtSIGInfo = wlan.internal.ehtSIGCodingInfo(obj.EHTSUConfig);
                NEHTSIG = ehtSIGInfo.NumSIGSymbols;
                trc = wlan.internal.ehtTimingRelatedConstants(obj.EHTSUConfig);
                headerDuration = trc.TLSIG + trc.TRLSIG + trc.TUSIG + NEHTSIG * trc.TEHTSIG;
                % MIMO preamble duration - EHT-STF + EHT-LTF
                allocationInfo = ruInfo(obj.EHTSUConfig);
                NEHTLTF = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU(allocationInfo.RUAssigned))) + obj.EHTSUConfig.NumExtraEHTLTFSymbols;
                mimoPreambleDuration = trc.TEHTSTFNT + NEHTLTF * trc.TEHTLTFSYM;
                symbolDuration = trc.TSYM;
        end

        preambleDuration = 16e3; % Duration of legacy preamble (L-STF and L-LTF)
        durations = struct('Preamble',preambleDuration,'Header',headerDuration,'MIMOPreamble',mimoPreambleDuration,'Symbol',symbolDuration);
    end
end

methods
    function run(obj, currentTime, macReqToPHY, frameToPHY)
    %run Run physical layer transmit operations for a WLAN node
    %   run(OBJ, CURRENTTIME, MACREQTOPHY, FRAMETOPHY) runs the following
    %   transmit operations
    %       * Handling the MAC requests
    %       * Transmitting the waveform
    %
    %   CURRENTTIME is the simulation time in nanoseconds.
    %
    %   MACREQTOPHY is a structure containing the details of request from
    %   MAC layer. This structure is valid only when its field MessageType
    %   is set to value other than
    %   wlan.internal.PHYPrimitives.UnknownIndication. See <a
    %   href="matlab:help('wlan.internal.utils.defaultIndicationToMAC')">wlan.internal.utils.defaultIndicationToMAC</a>.
    %
    %   FRAMETOPHY is a structure containing the frame metadata received
    %   from the MAC layer. It is an empty value when there is nothing to
    %   pass to PHY layer. See <a
    %   href="matlab:help('wlan.internal.utils.defaultMACFrame')">wlan.internal.utils.defaultMACFrame</a>.

        % Process MAC requests
        if macReqToPHY.MessageType == wlan.internal.PHYPrimitives.TxStartRequest
            phyIndHandle(obj, macReqToPHY);
        end

        % Process MAC frame
        if ~isempty(frameToPHY)
            txWaveform = generateWaveform(obj, currentTime, frameToPHY);

            % Update statistics
            obj.TransmittedPackets = obj.TransmittedPackets + 1;
            obj.TransmittedPayloadBytes = obj.TransmittedPayloadBytes + sum([obj.TxVector.PerUserInfo.Length]);

            % Trigger event to indicate waveform transmission
            if obj.HasListener.StateChanged
                stateChanged = obj.StateChangedTemplate;
                stateChanged.DeviceID = obj.DeviceID;
                stateChanged.State = "Transmission";
                stateChanged.Duration = round(txWaveform.Duration, 9);
                stateChanged.Frequency = txWaveform.CenterFrequency;
                stateChanged.Bandwidth = txWaveform.Bandwidth;
                obj.EventNotificationFcn('StateChanged', stateChanged);
            end
        end
    end

    function phyTxStats = statistics(obj)
        %statistics Return PHY transmitter statistics

        phyTxStats = struct;
        phyTxMetrics = obj.getMetricsList();
        for statIdx = 1:numel(phyTxMetrics)
            phyTxStats.(phyTxMetrics{statIdx}) = obj.(phyTxMetrics{statIdx});
        end
    end

    function setPrimaryChannelInfo(obj, primaryChannelIndex)
        %setPrimaryChannelInfo Add primary channel index and primary
        %channel frequency information to phyTx
        obj.PrimaryChannelIndex = primaryChannelIndex;
    end
end

methods
    % Constructor
    function obj = PHYTx(varargin)
    % Perform one-time calculations, such as computing constants

        % Name-value pair check
        if mod(nargin,2)
            error(message('wlan:shared:InvalidNumOptionalInputs'))
        end

        % Name-value pairs
        for idx = 1:2:numel(varargin)
            obj.(varargin{idx}) = varargin{idx+1};
        end

        % Initialize the structures Tx vector, metadata, and signal to
        % default values
        obj.TxVector = wlan.internal.utils.defaultTxVector;
        obj.TransmitWaveformTemplate = wirelessPacket;
        obj.TransmitWaveformTemplate.Metadata = wlan.internal.utils.defaultMetadata(obj.TxVector);

        % Initialize the frame config properties
        obj.NonHTConfig = wlanNonHTConfig; % Non-HT configuration object
        obj.HTConfig = wlanHTConfig; % HT configuration object
        % For VHT config default bandwidth is 80MHz. Update it to 20MHz
        obj.VHTConfig = wlanVHTConfig('ChannelBandwidth', 'CBW20');
        obj.HESUConfig = wlanHESUConfig; % HE-SU configuration object

        % Initialize to default structures       
        obj.StateChangedTemplate = struct('DeviceID', obj.DeviceID, ...
            'CurrentTime', 0, 'State', "Transmission", 'Duration', 0, ...
            'Frequency', 0, 'Bandwidth', 0);
    end
end

methods (Access = protected)

    function phyIndHandle(obj, macReq)
    %phyIndHandle Build the PHY transmitter object using the Tx
    %vector.
    %
    %   phyIndHandle(OBJ, MACREQ) builds the PHY transmitter object using
    %   the PHY transmitter vector received from MAC layer.
    %
    %   MACREQ  - Contains PHY Tx vector received from MAC layer

        obj.TxVector = macReq.Vector;
        txVector = macReq.Vector;

        obj.NumSTS = [txVector.PerUserInfo.NumSpaceTimeStreams];
        obj.ChannelBandwidth = txVector.ChannelBandwidth;
        obj.NumUsers = 1; % Default

        if txVector.PPDUFormat ~= obj.NonHT
            % Use Fourier mapping when there are more antennas than
            % space-time streams and Direct mapping (default), unless
            % other mapping already specified
            spatialMapping = [obj.TxVector.PerUserInfo.SpatialMapping];
            spatialMapping(spatialMapping=="Direct" & txVector.NumTransmitChains~=obj.NumSTS) = "Fourier";
        end

        % Configure the PHY object using transmission vector information
        switch txVector.PPDUFormat
            case obj.NonHT
                nonHTConfig = obj.NonHTConfig;
                nonHTConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                nonHTConfig.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(txVector.ChannelBandwidth);
                nonHTConfig.PSDULength = txVector.PerUserInfo.Length;
                nonHTConfig.MCS = txVector.PerUserInfo.MCS;
                obj.TxVector.PerUserInfo(obj.UserIndexSU).Length = nonHTConfig.PSDULength;
                obj.NonHTConfig = nonHTConfig;

            case obj.HTMixed
                htConfig = obj.HTConfig;
                htConfig.PSDULength = txVector.PerUserInfo.Length;
                htConfig.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(txVector.ChannelBandwidth);
                htConfig.MCS = txVector.PerUserInfo.MCS;
                htConfig.AggregatedMPDU = txVector.AggregatedMPDU;
                htConfig.NumSpaceTimeStreams = txVector.PerUserInfo.NumSpaceTimeStreams;
                htConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                htConfig.SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).Length = htConfig.PSDULength;
                obj.HTConfig = htConfig;

            case obj.VHT
                vhtConfig = obj.VHTConfig;
                vhtConfig.APEPLength = txVector.PerUserInfo(obj.UserIndexSU).Length;
                vhtConfig.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(txVector.ChannelBandwidth);
                vhtConfig.MCS = txVector.PerUserInfo(obj.UserIndexSU).MCS;
                vhtConfig.NumSpaceTimeStreams = txVector.PerUserInfo(obj.UserIndexSU).NumSpaceTimeStreams;
                vhtConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                vhtConfig.SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).Length = vhtConfig.PSDULength;
                obj.VHTConfig = vhtConfig;

            case {obj.HE_SU, obj.HE_EXT_SU}
                heSUConfig = obj.HESUConfig;
                heSUConfig.APEPLength = txVector.PerUserInfo.Length;
                heSUConfig.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(txVector.ChannelBandwidth);
                heSUConfig.MCS = txVector.PerUserInfo.MCS;
                heSUConfig.NumSpaceTimeStreams = txVector.PerUserInfo.NumSpaceTimeStreams;
                heSUConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                heSUConfig.BSSColor = txVector.BSSColor;
                heSUConfig.UplinkIndication = txVector.UplinkIndication;
                heSUConfig.TXOPDuration = txVector.TXOPDuration;
                heSUConfig.ExtendedRange = (txVector.PPDUFormat == obj.HE_EXT_SU);
                heSUConfig.SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).Length = heSUConfig.getPSDULength;
                obj.HESUConfig = heSUConfig;

            case obj.HE_MU
                heMUConfig = wlanHEMUConfig(txVector.RUAllocation, ...
                    'LowerCenter26ToneRU', txVector.LowerCenter26ToneRU, ...
                    'UpperCenter26ToneRU', txVector.UpperCenter26ToneRU);
                heMUConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                heMUConfig.BSSColor = txVector.BSSColor;
                heMUConfig.UplinkIndication = txVector.UplinkIndication;
                heMUConfig.TXOPDuration = txVector.TXOPDuration;
                obj.NumUsers = numel(heMUConfig.User);
                for userIndex = 1:obj.NumUsers
                    user = heMUConfig.User{userIndex};
                    user.MCS = txVector.PerUserInfo(userIndex).MCS;
                    user.APEPLength = txVector.PerUserInfo(userIndex).Length;
                    user.STAID = txVector.PerUserInfo(userIndex).StationID;
                    user.NumSpaceTimeStreams = txVector.PerUserInfo(userIndex).NumSpaceTimeStreams;
                    heMUConfig.User{userIndex} = user;
                    % Assume OFDMA so 1 RU per user
                    heMUConfig.RU{userIndex}.SpatialMapping = spatialMapping(userIndex);
                    obj.TxVector.PerUserInfo(userIndex).SpatialMapping = spatialMapping(userIndex);
                end
                psduLengths = heMUConfig.getPSDULength;
                for userIndex = 1:obj.NumUsers
                    obj.TxVector.PerUserInfo(userIndex).Length = psduLengths(userIndex);
                end
                assert(numel(heMUConfig.RU)==numel(heMUConfig.User),'Expected number of RUs and Users to be the same')
                obj.HEMUConfig = heMUConfig;

            case obj.HE_TB
                heTBConfig = wlanHETBConfig;
                heTBConfig.TriggerMethod = txVector.TriggerMethod;
                heTBConfig.ChannelBandwidth = wlan.internal.utils.getChannelBandwidthStr(txVector.ChannelBandwidth);
                heTBConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                heTBConfig.NumSpaceTimeStreams = txVector.PerUserInfo.NumSpaceTimeStreams;
                heTBConfig.NumHELTFSymbols = txVector.NumHELTFSymbols;
                heTBConfig.BSSColor = txVector.BSSColor;
                heTBConfig.TXOPDuration = txVector.TXOPDuration;
                heTBConfig.RUSize = txVector.RUAllocation(1);
                heTBConfig.RUIndex = txVector.RUAllocation(2);
                heTBConfig.MCS = txVector.PerUserInfo.MCS;
                if strcmp(heTBConfig.TriggerMethod, 'TRS')
                    heTBConfig.NumDataSymbols = txVector.LSIGLength;
                    if heTBConfig.RUSize < 484
                        heTBConfig.ChannelCoding = 'BCC';
                    else
                        heTBConfig.LDPCExtraSymbol = true;
                    end
                else
                    heTBConfig.LSIGLength = txVector.LSIGLength;
                end
                heTBConfig.SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).Length = heTBConfig.getPSDULength;
                obj.HETBConfig = heTBConfig;

            case obj.EHT_SU
                ehtSUConfig = wlanEHTMUConfig(wlan.internal.utils.getChannelBandwidthStr(txVector.ChannelBandwidth));
                ehtSUConfig.User{obj.UserIndexSU}.APEPLength = txVector.PerUserInfo.Length;
                ehtSUConfig.User{obj.UserIndexSU}.MCS = txVector.PerUserInfo.MCS;
                ehtSUConfig.User{obj.UserIndexSU}.NumSpaceTimeStreams = txVector.PerUserInfo.NumSpaceTimeStreams;
                ehtSUConfig.User{obj.UserIndexSU}.STAID = txVector.PerUserInfo.StationID;
                ehtSUConfig.NumTransmitAntennas = txVector.NumTransmitChains;
                ehtSUConfig.BSSColor = txVector.BSSColor;
                ehtSUConfig.UplinkIndication = txVector.UplinkIndication;
                ehtSUConfig.TXOPDuration = txVector.TXOPDuration;
                ehtSUConfig.Channelization = txVector.Channelization320MHz;
                ehtSUConfig.RU{obj.UserIndexSU}.SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).SpatialMapping = spatialMapping(obj.UserIndexSU);
                obj.TxVector.PerUserInfo(obj.UserIndexSU).Length = psduLength(ehtSUConfig);
                obj.EHTSUConfig = ehtSUConfig;
        end
    end
end

methods (Static)
    function availableMetrics = getMetricsList()
    %getMetricsList Return the available metrics at PHY transmitter
    %
    %   AVAILABLEMETRICS is a cell array containing all the available
    %   metrics at the PHY transmitter

        availableMetrics  = {'TransmittedPackets', 'TransmittedPayloadBytes'};
    end
end
end
