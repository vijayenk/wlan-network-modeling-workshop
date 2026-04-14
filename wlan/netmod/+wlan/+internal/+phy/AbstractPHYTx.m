classdef AbstractPHYTx < wlan.internal.phy.PHYTx
%AbstractPHYTx Create a handle object for WLAN abstracted PHY transmitter
%	WLANPHYTx = wlan.internal.phy.AbstractPHYTx creates a handle object for
%	WLAN PHY transmitter object supporting the following operations:
%       - Handling requests from MAC layer
%       - Creating an abstracted waveform (PPDU)
%       - Handling transmit power (Tx power)
%
%   WLANPHYTx = wlan.internal.phy.AbstractPHYTx(Name, Value) creates a
%   handle object for WLAN PHY transmitter with the specified property Name
%   set to the specified Value. You can specify additional name-value pair
%   arguments in any order as (Name1, Value1, ..., NameN, ValueN).
%
%   AbstractPHYTx methods:
%
%   run     - Run the physical layer transmit operations
%
%   AbstractPHYTx properties:
%
%   IsNodeTypeAP     - Specifies the type of node (AP/STA)
%   TxGain           - Specifies the transmission gain of the node in dB

%   Copyright 2022-2025 The MathWorks, Inc.

methods
    function obj = AbstractPHYTx(varargin)
        %AbstractPHYTx Create an instance of abstracted PHY transmitter class

        obj = obj@wlan.internal.phy.PHYTx(varargin{:});
    end
end

methods (Access = protected)
    function txWaveform = generateWaveform(obj, currentTime, ppdu)
        % generateWaveform Generate the WLAN waveform
        %
        %   TXWAVEFORM = generateWaveform (OBJ, CURRENTTIME, PPDU) generates 
        %   a WLAN waveform containing PHY and MAC metadata.
        %
        %   TXWAVEFORM is the output waveform to be transmitted which is a
        %   structure of type wirelessPacket. This packet holds the abstracted 
        %   form of waveform data.
        %
        %   CURRENTTIME is the simulation time in nanoseconds.
        %
        %   PPDU - PPDU is the received WLAN physical layer Protocol Data
        %          Unit (PDU).

        % Update signal power
        sigPower = obj.TxVector.PerUserInfo(obj.UserIndexSU).TxPower + obj.TxGain;

        % Calculate the duration of the waveform
        switch obj.TxVector.PPDUFormat
            case obj.NonHT
                txTime = transmitTime(obj.NonHTConfig,"nanoseconds");
            case obj.HTMixed
                txTime = transmitTime(obj.HTConfig,"nanoseconds");
            case obj.VHT
                txTime = transmitTime(obj.VHTConfig,"nanoseconds");
            case {obj.HE_SU, obj.HE_EXT_SU}
                txTime = transmitTime(obj.HESUConfig,"nanoseconds");
            case obj.HE_MU
                txTime = transmitTime(obj.HEMUConfig,"nanoseconds");
            case obj.HE_TB
                txTime = transmitTime(obj.HETBConfig,"nanoseconds");
            case obj.EHT_SU
                txTime = transmitTime(obj.EHTSUConfig,"nanoseconds");
        end
        durations = getFieldDurations(obj);

        % Calculate the payload duration by removing the durations of
        % legacy preamble, header and MIMO preamble from the total PPDU
        % duration.
        payloadDuration = txTime - (durations.Preamble + durations.Header + durations.MIMOPreamble);

        switch obj.TxVector.PPDUFormat
            case obj.NonHT
                mcsTable = wlan.internal.getRateTable(obj.NonHTConfig);
                ndbps = mcsTable.NDBPS;
            case obj.HTMixed
                mcsTable = wlan.internal.getRateTable(obj.HTConfig);
                ndbps = mcsTable.NDBPS;
            case obj.VHT
                mcsTable = wlan.internal.getRateTable(obj.VHTConfig);
                ndbps = mcsTable.NDBPS(1);
            case {obj.HE_SU, obj.HE_EXT_SU}
                [~, userCodingParams] = wlan.internal.heCodingParameters(obj.HESUConfig);
                ndbps = userCodingParams.NDBPS(1);
            case obj.HE_MU
                [~, userCodingParams] = wlan.internal.heCodingParameters(obj.HEMUConfig);
                ndbps = zeros(obj.NumUsers, 1); % Number of data bits per symbol
                for userIdx = 1:obj.NumUsers
                    ndbps(userIdx) = userCodingParams(userIdx).NDBPS;
                end
            case obj.HE_TB
                [~, userCodingParams] = wlan.internal.heCodingParameters(obj.HETBConfig);
                ndbps = userCodingParams.NDBPS;
            case obj.EHT_SU
                [~, userCodingParams] = wlan.internal.ehtCodingParameters(obj.EHTSUConfig);
                ndbps = userCodingParams.NDBPS;
        end

        % Fill required metadata based on transmission
        txWaveform = obj.TransmitWaveformTemplate;
        metadata = txWaveform.Metadata;
        metadata.Vector = obj.TxVector;
        metadata.PreambleDuration = durations.Preamble;
        metadata.HeaderDuration = durations.Header;
        metadata.MIMOPreambleDuration = durations.MIMOPreamble;

        for userIdx = 1:obj.NumUsers
            numServiceBits = 16;
            mpdus = ppdu.MACFrame(userIdx).MPDU;
            numSubframes = numel(mpdus); % Number of subframes
            subframeStartByteIndices = zeros(numSubframes,1);
            subframeLengths = zeros(numSubframes,1);
            for sfidx = 1:numSubframes
                subframeStartByteIndices(sfidx) = mpdus(sfidx).Metadata.SubframeIndex; % Byte index of the start of each subframe
                subframeLengths(sfidx) = mpdus(sfidx).Metadata.SubframeLength; % Length of subframes (or PSDU if not A-MPDU) in bytes
            end

            % The abstraction method calculates the probability of decoding
            % each MPDU within the A-MPDU (or a PSDU if A-MPDUs are not
            % present).
            %
            % An A-MPDU subframe consists of a delimiter, MPDU, and
            % padding. To decode each MPDU successfully the delimiter must
            % also be decoded. The padding within each subframe does not
            % need to be decoded.
            %
            % The A-MPDU duration is split into "chunks" of OFDM symbols
            % for decoding, each of which contains at least one A-MPDU
            % subframe. The simulator advances to the end of a chunk to
            % "decode" the MPDU within.
            %
            % Calculate the number of OFDM symbols (and time) in each
            % "chunk". subframeDurationToAdvance is the time to advance to
            % process that subframe (excluding padding). Therefore, if two
            % subframes are transmitted on the same OFDM symbol
            % subframeDurationToAdvance is 0 for the second subframe.
            %
            % Any OFDM symbols containing only tail bits, A-MPDU padding,
            % or PHY padding are not abstracted (no "chunk" is created).

            % Number of bits to decode for each subframe includes
            % delimiter (if present) and MPDU. If no A-MPDU then the length
            % is the PSDU length.
            subframeNumBits = subframeLengths*8;

            % Start bit of each MPDU subframe within PSDU (delimiter).
            % The initial bits are service bits.
            chunkStartBit = (subframeStartByteIndices-1)*8+1+numServiceBits;

            % End bit of each MPDU within PSDU (before MPDU subframe
            % padding or EOF padding)
            chunkEndBit = chunkStartBit+subframeNumBits-1;

            % End OFDM symbol index of each chunk
            chunkEndOFDMSymbol = ceil(chunkEndBit./ndbps(userIdx)); % 1-based

            % Get the time difference between the end of each chunk,
            % the simulator will advance to this point to process each
            % subframe.
            numSymbolsToAdvanceForEachChunk = [chunkEndOFDMSymbol(1); diff(chunkEndOFDMSymbol)];
            subframeDurationToAdvance = numSymbolsToAdvanceForEachChunk.*durations.Symbol;

            % Fill metadata
            metadata.NumSubframes(userIdx) = numSubframes;
            for sfIdx = 1:numSubframes
                metadata.PayloadInfo(userIdx, sfIdx).Duration = subframeDurationToAdvance(sfIdx); % nanoseconds
                metadata.PayloadInfo(userIdx, sfIdx).NumBits = subframeNumBits(sfIdx);
            end
            metadata.SubframeLengths(userIdx, 1:numSubframes) = subframeLengths;
            metadata.SubframeIndices(userIdx, 1:numSubframes) = subframeStartByteIndices;
        end

        metadata.PayloadDuration = payloadDuration; % nanoseconds
        % QoS Data frames contain application packet. Since full MAC/PHY does not
        % encode actual app packet information, MAC receiver cannot decode the
        % following app packet information. Hence this information is being passed
        % as metadata.
        metadata.PacketGenerationTime = ppdu.PacketGenerationTime;
        metadata.PacketID = ppdu.PacketID;
        % To access a particular subframe's metadata information (packet ID, packet
        % generation time) above, MAC needs to know the exact subframe number in
        % the decoded MAC frame which is not possible because of potential subframe
        % reception failures. Hence MPDU sequence number is being passed as
        % metadata to allow MAC in finding the exact subframe index by mapping the
        % decoded subframe's sequence number with the following list.
        metadata.MPDUSequenceNumber = ppdu.SequenceNumbers;

        % Form waveform
        if isempty(ppdu.MACFrame(obj.UserIndexSU).Data)
            metadata.MACDataType = obj.DataTypeMACFrameStruct;
        else
            metadata.MACDataType = obj.DataTypeMACFrameBits;
        end
        txWaveform.Data = ppdu.MACFrame;
        txWaveform.Abstraction = true;
        txWaveform.TechnologyType = wnet.TechnologyType.WLAN; % WLAN signal type
        txWaveform.StartTime = wlan.internal.utils.nanoseconds2seconds(currentTime);
        txWaveform.Duration = wlan.internal.utils.nanoseconds2seconds(txTime);
        txWaveform.Bandwidth = obj.ChannelBandwidth*1e6;
        txWaveform.NumTransmitAntennas = obj.TxVector.NumTransmitChains;
        txWaveform.CenterFrequency = obj.OperatingFrequency;
        txWaveform.SampleRate = obj.ChannelBandwidth*1e6;
        txWaveform.Power = sigPower;
        txWaveform.Metadata = metadata;
        obj.SendPacketFcn(txWaveform);
    end
end
end
