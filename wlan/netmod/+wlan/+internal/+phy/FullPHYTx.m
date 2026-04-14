classdef FullPHYTx < wlan.internal.phy.PHYTx
%FullPHYTx Create a handle object for WLAN PHY transmitter
%	WLANPHYTx = wlan.internal.phy.FullPHYTx creates a handle object for
%	WLAN PHY transmitter supporting the following operations:
%       - Handling requests from MAC layer
%       - Creating waveform (PPDU)
%       - Handling transmit power (Tx power)
%
%   WLANPHYTx = wlan.internal.phy.FullPHYTx(Name, Value) creates a handle
%   object for WLAN PHY transmitter with the specified property Name set to
%   the specified Value. You can specify additional name-value pair
%   arguments in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   FullPHYTx methods:
%
%   run     - Run the physical layer transmit operations
%
%   FullPHYTx properties:
%
%   IsNodeTypeAP        - Specifies the type of node (AP/STA)
%   TxPower             - Specifies the transmission power of the node in dBm
%   TxGain              - Specifies the transmission gain of the node in dB
%   OversamplingFactor  - Specifies the oversampling factor used when generating waveforms

% Copyright 2022-2025 The MathWorks, Inc.

properties
    %OversamplingFactor Oversampling factor
    %   Specify the oversampling factor used when generating waveforms. The
    %   default value is 1.
    OversamplingFactor (1, 1) {mustBeNumeric, mustBeGreaterThanOrEqual(OversamplingFactor, 1)} = 1;

    %OperatingBandwidth Operating bandwidth
    %   Specify the operating bandwidth of current transmitter in MHz. The
    %   default value is 20.
    OperatingBandwidth = 20;
end

properties (Access = private)
    %CandidateCentFreqOffset Candidate ceneter frequency offset
    CandidateCentFreqOffset = {};
end

methods
    function obj = FullPHYTx(varargin)
        %FullPHYTx Create an instance of PHY transmitter class

        obj = obj@wlan.internal.phy.PHYTx(varargin{:});
        obj.CandidateCentFreqOffset = wlan.internal.utils.getChannelCenterFreqOffset(obj.OperatingBandwidth);
    end
end

methods (Access = private)
    function outputSamples = applyTxPowerLevelAndGain(obj, iqSamples, gain)
        %applyTxPowerLevelAndGain Applies Tx power level and gain to IQ
        %samples

        % Apply default Tx power to IQ samples.
        scale = 10.^((-30 + obj.TxVector.PerUserInfo(obj.UserIndexSU).TxPower + gain)/20);
        outputSamples = iqSamples * scale;
    end
end

methods (Access = protected)
    function txWaveform = generateWaveform(obj, currentTime, ppdu)
    % generateWaveform Generate the WLAN waveform
    %
    %   TXWAVEFORM = generateWaveform (OBJ, PPDU) generates the WLAN waveform.
    %   The waveform contains the PHY metadata and MAC metadata
    %
    %   TXWAVEFORM is the output waveform to be transmitted which is a
    %   structure of type wirelessPacket.
    %
    %   PPDU - PPDU is the received WLAN physical layer Protocol Data
    %          Unit (PDU).

        % Update signal power
        sigPower = obj.TxVector.PerUserInfo(obj.UserIndexSU).TxPower + obj.TxGain;
        psdu = cell(1,numel(ppdu.MACFrame));
        for idx = 1:numel(ppdu.MACFrame)
            psdu{idx} = ppdu.MACFrame(idx).Data; % Full MAC Frame(Expressed as uint8 vector)
        end

        osf = obj.OversamplingFactor;
        switch obj.TxVector.PPDUFormat
            case obj.NonHT
                % CH_BANDWIDTH_IN_NON_HT is already set in the phyTxInterface
                obj.NonHTConfig.SignalChannelBandwidth = obj.TxVector.SignalChannelBandwidth;
                obj.NonHTConfig.BandwidthOperation = obj.TxVector.BandwidthOperation;
                if obj.TxVector.SignalChannelBandwidth % BW signaling for CTS and RTS
                    % Generate the initial scrambler sequence
                    scramblerInitialState = randi(scramblerRange(obj.NonHTConfig));
                elseif obj.TxVector.ScramblerInitialValue ~= -1  % Only set for MU-RTS
                    scramblerInitialState = obj.TxVector.ScramblerInitialValue;
                else
                    % No BW signaling, use default scrambler initial value in wlanWaveformGenerator
                    scramblerInitialState = 93; % Default in wlanWaveformGenerator
                end
                % Generate Non-HT waveform
                waveform = wlanWaveformGenerator(psdu, obj.NonHTConfig, OversamplingFactor=osf, ScramblerInitialization=scramblerInitialState);
            case obj.HTMixed
                % Generate HT waveform
                waveform = wlanWaveformGenerator(psdu, obj.HTConfig, OversamplingFactor=osf);
            case obj.VHT
                % Generate VHT waveform
                waveform = wlanWaveformGenerator(psdu, obj.VHTConfig, OversamplingFactor=osf);
            case {obj.HE_SU, obj.HE_EXT_SU}
                % Generate HE SU waveform
                waveform = wlanWaveformGenerator(psdu, obj.HESUConfig, OversamplingFactor=osf);
            case obj.EHT_SU
                % Generate EHT SU waveform
                waveform = wlanWaveformGenerator(psdu, obj.EHTSUConfig, OversamplingFactor=osf);
        end

        % Number of baseband samples and streams in waveform
        numBBSamples = size(waveform,1)/osf;

        % Apply Tx gain to the waveform and cast to single
        waveform = obj.applyTxPowerLevelAndGain(single(waveform), obj.TxGain);

        % Duration of the waveform
        durationWaveform = round((numBBSamples*(1/obj.ChannelBandwidth)))*1e3; % in nanoseconds
 
        % Fill metadata of transmit waveform
        txWaveform = obj.TransmitWaveformTemplate;
        metadata = txWaveform.Metadata;
        metadata.Vector = obj.TxVector;
        metadata.PacketGenerationTime = 0;
        metadata.PacketID = 0;
        metadata.MPDUSequenceNumber = 0;
        for userIdx = 1:numel(ppdu.MACFrame)
            mpdus = ppdu.MACFrame(userIdx).MPDU;
            numSubframes = numel(mpdus);
            metadata.NumSubframes(userIdx) = numSubframes;
            for subframeIdx = 1:numSubframes
                if strcmp(mpdus(subframeIdx).Header.FrameType,'QoS Data')
                    % QoS Data frames contain application packet. Since full MAC/PHY does not
                    % encode actual app packet information, MAC receiver cannot decode the
                    % following app packet information. Hence this information is being passed
                    % as metadata.
                    metadata.PacketGenerationTime(userIdx,subframeIdx) =  mpdus(subframeIdx).FrameBody.MSDU.PacketGenerationTime;
                    metadata.PacketID(userIdx,subframeIdx) = mpdus(subframeIdx).FrameBody.MSDU.PacketID;
                    % To access a particular subframe's metadata information (packet ID, packet
                    % generation time) above, MAC needs to know the exact subframe number in
                    % the decoded MAC frame which is not possible because of potential subframe
                    % reception failures. Hence MPDU sequence number is being passed as
                    % metadata to allow MAC in finding the exact subframe index by mapping the
                    % decoded subframe's sequence number with the following list.
                    metadata.MPDUSequenceNumber(userIdx,subframeIdx) = mpdus(subframeIdx).Header.SequenceNumber;
                end
            end
        end
        durationField = getFieldDurations(obj); % in nanoseconds
        metadata.PreambleDuration = durationField.Preamble;
        metadata.HeaderDuration = durationField.Header;
        metadata.MIMOPreambleDuration = durationField.MIMOPreamble;
        metadata.PayloadDuration = durationWaveform - durationField.Preamble - durationField.Header - durationField.MIMOPreamble;
        metadata.OversamplingFactor = osf;

        % Form transmit waveform
        txWaveform.TechnologyType = wnet.TechnologyType.WLAN;
        txWaveform.StartTime = wlan.internal.utils.nanoseconds2seconds(currentTime);
        txWaveform.Duration = wlan.internal.utils.nanoseconds2seconds(durationWaveform);
        txWaveform.CenterFrequency = wlan.internal.utils.getPacketCenterFrequency(obj.OperatingFrequency, ...
            obj.OperatingBandwidth, obj.PrimaryChannelIndex, obj.ChannelBandwidth, obj.CandidateCentFreqOffset);
        txWaveform.Bandwidth = obj.ChannelBandwidth*1e6;
        txWaveform.NumTransmitAntennas = obj.TxVector.NumTransmitChains;
        txWaveform.Power = sigPower;
        txWaveform.SampleRate = obj.ChannelBandwidth*1e6*osf;
        txWaveform.Data = waveform;
        txWaveform.Metadata = metadata;
        obj.SendPacketFcn(txWaveform);
    end
end
end
