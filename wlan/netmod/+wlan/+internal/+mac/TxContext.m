classdef TxContext < handle
%TxContext Create an object to maintain context specific to transmit
%states (TRANSMIT_STATE/RECEIVERESPONSE) for MAC
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = wlan.internal.mac.TxContext(MAXSUBFRAMES, MAXMUUSERS,
%   CHANNELBANDWIDTH) creates an object OBJ that stores properties required
%   for transmissions from MAC, with all properties set to their default
%   values. MAXSUBFRAMES is the maximum number of subframes present in an
%   A-MPDU. MAXMUUSERS is the maximum number of users supported in an MU
%   frame. CHANNELBANDWIDTH is the channel bandwidth configured by the user
%   in units of MHz.

%   Copyright 2022-2025 The MathWorks, Inc.

%% Scheduled station related properties
properties  
    %NumTxUsers Holds the number of scheduled stations
    %   NumTxUsers is a scalar representing the number of users to/from whom
    %   data transmission is scheduled.
    %   In TRANSMIT_STATE, it is set at the start of each frame exchange
    %   sequence to:
    %     * Number of users to/from whom data transmission is scheduled
    %   In TRANSMITRESPONSE_STATE, it is set to:
    %     * 1 as the station (STA) is sending HE TB data frame to AP
    %   In TRANSMIT_STATE, it is used to:
    %     * Calculate lengths of MU-RTS, MU-BAR and Basic trigger frames
    %   In TRANSMIT_STATE and RECEIVERESPONSE_STATE, it is used to:
    %     * Access context or variables maintained per user
    NumTxUsers = 1;

    %TxStationIDs Holds node IDs of scheduled stations until the end of
    %frame exchange sequence
    %   TxStationIDs is a column vector with number of valid values stored
    %   in NumTxUsers property.
    %   In TRANSMIT_STATE, it is set whenever scheduling takes place within a
    %   TXOP to:
    %     * Node IDs of stations returned by scheduler
    %   In TRANSMITRESPONSE_STATE, it is set to:
    %     * Node ID of associated access point (AP) as the station (STA) is
    %       sending HE TB data frame to AP.
    %   In TRANSMIT_STATE, it is used to:
    %     * Access the station specific context
    %     * Fill AID and STA_ID values in a trigger frame and TXVECTOR
    %       respectively
    %   In RECEIVERESPONSE_STATE, it is used to:
    %     * Access the context specific to station present in RXVECTOR
    %     * Fill required info in event notification data
    %   It is reset at the end of TXOP.
    TxStationIDs;

    %TxACs Holds the ACs of scheduled stations incremented by 1 until the end
    %of frame exchange sequence
    %   TxACs is a column vector with number of valid values stored in
    %   NumTxUsers property.
    %   In TRANSMIT_STATE, it is set at the start of each frame
    %   exchange sequence to:
    %     * ACs corresponding to scheduled stations, incremented by 1
    %   In TRANSMIT_STATE, it is used to:
    %     * Provide AC info to rate control algorithm
    %     * Fill TID values in an MU-BAR trigger frame
    %   In TRANSMIT_STATE and RECEIVERESPONSE_STATE, it is used to:
    %     * Index the per AC context or statistics  
    TxACs;
end

%% Frame and frame length related properties
properties
    %NextTxFrameType Holds enumerated value of the frame type to be
    %transmitted (excluding control response frames)
    %   NextTxFrameType is a scalar integer indicating the frame type to be
    %   transmitted.
    %   In TRANSMIT_STATE (for initial FES) and RECEIVERESPONSE_STATE (for
    %   non-initial FES), it is set to either of the following constant properties of
    %   wlan.internal.mac.edcaMAC:
    %     * RTS = 1
    %     * QoSData = 3
    %     * MURTSTrigger = 6
    %     * MUBARTrigger = 7
    %     * BasicTrigger = 8
    %     * Beacon = 11
    %     * CFEnd = 12
    %   In TRANSMIT_STATE and TRANSMITRESPONSE_STATE, it is used to
    %   prepare a specific frame.
    %   It is reset after frame transmission is completed.
    NextTxFrameType = wlan.internal.Constants.UnknownFrameType;

    %LastTxFrameType Holds enumerated value of the last transmitted frame
    %type (excluding control response frames)
    %   LastTxFrameType is a scalar integer indicating the last transmitted
    %   frame type.
    %   In TRANSMIT_STATE and TRANSMITRESPONSE_STATE, it is set to
    %   NextTxFrameType after frame transmission is completed.
    %   In RECEIVERESPONSE_STATE, it is used to perform actions based on
    %   the most recently transmitted frame.
    %   It is reset at the end of TXOP.
    LastTxFrameType = wlan.internal.Constants.UnknownFrameType;

    %TxFrame Holds the data frame dequeued from MAC queues until the end of
    %frame exchange sequence
    %   In TRANSMIT_STATE, it is set at the start of each frame
    %   exchange sequence to:
    %     * Frame dequeued from MAC queues
    %   In TRANSMIT_STATE, it is used to:
    %     * Know whether the data transmission in current sequence is
    %       unicast or broadcast
    %     * Fill the fields in data frame sent to PHY
    %   In RECEIVERESPONSE_STATE, it is used to:
    %     * Fill required info in event notification data
    TxFrame;

    %TxMPDUCount Holds the number of MPDUs aggregated for each user until
    %the end of frame exchange sequence
    %   TxMPDUCount is a column vector with number of valid values stored
    %   in NumTxUsers property.
    %   In TRANSMIT_STATE and CONTEND_STATE, it is set at the start of
    %   frame exchange sequence and during an internal collision respectively
    %   to:
    %     * Number of MPDUs that can be aggregated, limited by maximum PSDU
    %       length, aggregation limit and MPDUs waiting in queue
    %   In TRANSMIT_STATE, it is used to:
    %     * Dequeue the required number of MPDUs from MAC queues
    %     * Expect the type of response (Ack or Block Ack) while filling
    %       duration field
    %     * Increment statistics when ack is disabled
    %   In RECEIVERESPONSE_STATE and CONTEND_STATE, it is used to increment
    %   frame retry count for MSDUs whose transmission failed or suffered an
    %   internal collision.
    TxMPDUCount;

    %TxPSDULength Holds the length of PSDU, valid until data frame is
    %transmitted in a frame exchange sequence
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * Length of PSDU containing data frame
    %   In TRANSMIT_STATE, it is used to:
    %     * Decide if RTS/CTS protection mechanism is required
    %     * Fill Length field for data frames in event notifications
    TxPSDULength = 0;

    %TxFrameLength Holds PSDU/APEP length for each user, valid until data
    %frame is transmitted in a frame exchange sequence
    %   TxFrameLength is a column vector with number of valid values stored
    %   in NumTxUsers property.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * PSDU length for Non-HT, HT-Mixed formats
    %     * APEP length for VHT, HE formats
    %   In TRANSMIT_STATE, it is used to:
    %     * Calculate PSDU transmission time
    %     * Fill metadata in frame to PHY, abstract MAC frame fields and
    %       related fields in TX_START request to PHY
    TxFrameLength;

    %TxMPDULengths Holds the Length of MPDUs for each user, valid until data
    %frame is transmitted in a frame exchange sequence
    %   TxMPDULengths is an array, where each column contains MPDU lengths
    %   corresponding to a user.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * Lengths of MPDUs transmitted to each user
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill metadata in frame to PHY and abstract MAC frame fields
    TxMPDULengths;

    %TxSubframeLengths Holds the length of A-MPDU subframes for each user,
    %valid until data frame is transmitted in a frame exchange sequence
    %   TxSubframeLengths is an array, where each column contains A-MPDU
    %   subframe lengths corresponding to a user.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * Length of A-MPDU subframes (MPDU length + delimiter + optional
    %       padding) to a user
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill metadata in frame to PHY
    TxSubframeLengths;

    %NumAddressFields Number of address fields in MAC header of the frame,
    %valid until data frame is transmitted in a frame exchange sequence
    %   NumAddressFields is a column vector.
    %   In TRANSMIT_STATE, it is set at the start of each frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * Number of address fields in MAC header for each user
    %   In TRANSMIT_STATE, it is used to:
    %     * Calculate MPDU header length considering "Address4" field
    %     * Consider Mesh Control field in unicast mesh frames
    %     * Set fields appropriately in data frames
    NumAddressFields;

    %FrameTxTime Holds duration to transmit frame from PHY, valid until
    %frame transmission is completed
    %   In TRANSMIT_STATE, it is set to:
    %     * Duration to transmit any frame from PHY
    %   In TRANSMIT_STATE, it is used to:
    %     * Indicate MAC that frame transmission is in progress or done
    FrameTxTime = 0;
end

%% Data Tx vector related properties
properties
    %TxFormat Holds PHY format to transmit data frame, valid until data frame
    %is transmitted in a frame exchange sequence
    %   TxFormat is a scalar specified as one of the following constants from
    %   wlan.internal.FrameFormats: NonHT, HTMixed, VHT, HE_SU, HE_EXT_SU,
    %   HE_MU, HE_TB, or EHT_SU.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * PHY format used for transmitting a data frame
    %   In TRANSMIT_STATE, it is used to:
    %     * Calculate PSDU length of the data frame
    %     * Calculate PSDU transmission time
    %     * Calculate MCS to transmit response frame
    %     * Know whether a transmission is an MU transmission
    %     * Fill related fields in TX_START request of data frame to PHY
    %   In RECEIVERESPONSE_STATE, it is used to:
    %     * Identify whether response is solicited in HE-TB PPDU
    TxFormat;

    %TxAggregatedMPDU Holds indication whether data frame is aggregated, valid
    %until data frame is transmitted in a frame exchange sequence
    %   TxAggregatedMPDU is a logical scalar.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * true, if a data frame has MPDUs aggregated
    %     * false, otherwise
    %   In TRANSMIT_STATE, it is used to:
    %     * Calculate MCS to transmit response frame
    %   In RECEIVERESPONSE_STATE, it is used to increment frame retry count
    %   for the MSDUs sent in non-aggregated frames.
    TxAggregatedMPDU = false;

    %TxMCS Holds MCS index to transmit data frame, valid until data frame
    %is transmitted in a frame exchange sequence
    %   TxMCS is a column vector with number of valid values stored
    %   in NumTxUsers property.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * MCS index used for transmitting a data frame to each user
    %   In TRANSMIT_STATE, it is used along with TxNumSTS property to:
    %     * Calculate max PSDU length allowed
    %     * Calculate PSDU transmission time
    %     * Calculate MCS to transmit response frame
    %     * Fill related fields in TX_START request of data frame to PHY
    TxMCS;

    %TxNumSTS Holds number of space-time streams to transmit data frame
    %until the end of frame exchange sequence
    %   TxNumSTS is a column vector with number of valid values stored
    %   in NumTxUsers property.
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * Number of space-time streams used for transmitting data frame
    %       to each user
    %   In TRANSMIT_STATE, it is used to:
    %     * Assign NumSpaceTimeStreams field in MU-BAR trigger frame
    TxNumSTS;

    %TxBandwidth Holds the bandwidth used to transmit a frame in MHz
    %   In TRANSMIT_STATE (initial FES) and RECEIVERESPONSE_STATE
    %   (non-initial FES), it is set to:
    %     * TXOPBandwidth, in case of an MU-RTS frame (if present)
    %       and MU-frame (MUAllNodesSameBWSupported)
    %     * TXOPBandwidth, in case of initial FES with a broadcast data frame
    %     * Minimum of TXOPBandwidth and receiver bandwidth, in case of initial
    %       FES with RTS frame (if present) and SU data frame
    %     * Minimum of last RTS transmission bandwidth, receiver bandwidth and
    %       available bandwidth based on CCA, in case of non-initial FES with
    %       RTS frame (if present) and SU data frame, given the TXOP is
    %       protected by RTS/CTS exchange
    %     * Minimum of bandwidth of initial frame in first non-HT duplicate
    %       frame exchange, receiver bandwidth and available bandwidth based on
    %       CCA, in case of non-initial FES with SU data frame and TXOP does not
    %       have an RTS/CTS exchange but has at least one non-HT duplicate frame
    %       exchange
    %     * Minimum of last PPDU transmission bandwidth, receiver bandwidth and
    %       available bandwidth based on CCA, in case of non-initial FES with
    %       SU data frame and TXOP does not have RTS/CTS or non-HT duplicate
    %       frame exchange
    %     * For CF-End frame transmission and broadcast data frame transmission
    %       in non-initial FES, last three bullet points in above list apply
    %       without the receiver bandwidth
    %     * TXOPBandwidth, in case of Basic TF
    %   In TRANSMIT_STATE, it is used to:
    %     * Calculate tx time of data frame
    %     * Fill in TxVector and pass to phy tx in TxStart request
    %     * Response MCS calculation
    %   It is reset when the TXOP ends.
    TxBandwidth;

    %AllocationIndex Allocation index for OFDMA transmission, valid until
    %data frame is transmitted in a frame exchange sequence
    %   AllocationIndex is a scalar or vector. It is a scalar when channel
    %   bandwidth is 20 MHz and, a vector when channel bandwidth is greater
    %   than 20 MHz. Each element in the vector represents allocation index
    %   for each 20 MHz subchannel.
    %   In TRANSMIT_STATE, it is set at the start of each frame exchange
    %   sequence (before transmission of data or applicable MU-RTS) to:
    %     * Allocation index of an OFDMA transmission
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill corresponding field in TX_START request sent to PHY for
    %       HE MU frames
    AllocationIndex = 0;
end

%% Acknowledgment related properties
properties
    %NoAck Holds indication that acknowledgment is disabled for data frame,
    %valid until transmission of current data frame
    %   In TRANSMIT_STATE, it is set at the start of frame exchange
    %   sequence (before transmission of data or applicable RTS/MU-RTS) to:
    %     * true for a broadcast data frame
    %     * true to disable acknowledgment for unicast data frame
    %     * false otherwise
    %   In TRANSMIT_STATE, it is used to:
    %     * Compute duration field of RTS and data frames
    %     * Set 'Ack Policy' field in data frames
    %     * Perform appropriate state transitions after data frame transmission
    NoAck = false;

    %ExpectedAckType Expected acknowledgment type
    %   In TRANSMIT_STATE, it is set while sending data frame soliciting
    %   response to either 1, 2 or 3 representing 'ACK', 'Block Ack', and
    %   'Multi-STA-BA' respectively.
    %   It is reset to 0 while exiting RECEIVERESPONSE_STATE.
    ExpectedAckType = 0;

    %WaitForResponseTimer Timer for waiting on response frame
    %   In state entry of RECEIVERESPONSE_STATE, it is set to a timeout timer
    %   after which the transmission is considered a failure if no response is
    %   received within this time. 
    %   In RECEIVERESPONSE_STATE, it is used to check whether the response
    %   timeout has expired.
    WaitForResponseTimer;

    %IgnoreResponseTimeout Flag to ignore receive timeout trigger
    %   In state entry of RECEIVERESPONSE_STATE, IgnoreResponseTimeout is
    %   initialized to false.
    %   In RECEIVERESPONSE_STATE, 
    %       * This flag is set to true if an RxStart is received.
    %   In RECEIVERESPONSE_STATE, 
    %       * This flag is used to determine if response timeout operations
    %         need to be performed and decide which state to move to when CCA
    %         indications are received
    %   In RECEIVERESPONSE_STATE,
    %       * This flag is reset after handling the response timeout
    %         operations.
    IgnoreResponseTimeout;
end

%% Bandwidth and bandwidth signaling related properties
properties
    %TXOPBandwidth Holds the available bandwidth for TXOP in MHz
    %   In TRANSMIT_STATE, it is set at the beginning of a TXOP and remains
    %   constant until the TXOP ends to:
    %     * 20 MHz, if TXOP is acquired to transmit a Beacon frame
    %     * Maximum bandwidth where secondary channels are idle for DIFS in 2.4
    %       GHz band or PIFS in 5 and 6 GHz bands
    %   Additionally, it is set in CONTEND_STATE as mentioned above during
    %   internal collision.
    %   In TRANSMIT_STATE, it is used to:
    %     * Determine the bandwidth of the transmission(s) in initial frame
    %       exchange sequence (FES)
    %   In RECEIVERESPONSE_STATE, it is used to:
    %     * Determine the bandwidth of transmission(s) in non-initial FES
    %   It is reset when the TXOP ends.
    TXOPBandwidth;

    %LastRTSBandwidth Holds the bandwidth of last transmitted non-HT or non-HT
    %duplicate RTS/MU-RTS by the TXOP holder in current TXOP in MHz
    %   LastRTSBandwidth is a scalar indicating the bandwidth of last
    %   transmitted non-HT or non-HT duplicate RTS/MU-RTS in the current TXOP.
    %   In TRANSMIT_STATE, it is set when transmitting an RTS/MU-RTS to:
    %     * Bandwidth of the RTS/MU-RTS frame
    %   In RECEIVERESPONSE_STATE, it is used to:
    %     * Determine the bandwidth of the transmission of non-initial FES,
    %       when TXOP is protected by RTS/CTS or MU-RTS/CTS exchange
    %     * Determine the bandwidth of CF-End frame transmission, when TXOP is
    %       protected by MU-RTS/CTS exchange
    %   It is reset when the TXOP ends.
    LastRTSBandwidth = 0;

    %FirstNonHTDupBandwidth Holds the bandwidth of initial frame in first non-HT
    %duplicate frame exchange in current TXOP in MHz
    %   FirstNonHTDupBandwidth is a scalar indicating the bandwidth of initial
    %   frame in first non-HT duplicate frame exchange in the current TXOP.
    %   This is applicable when there is no RTS/CTS or MU-RTS/CTS exchange in
    %   non-HT duplicate format in TXOP.
    %   In TRANSMIT_STATE and RECEIVERESPONSE_STATE, it is set when
    %   there's no RTS/MU-RTS frame in TXOP to:
    %     * Bandwidth of the initial frame in the first non-HT duplicate frame
    %       exchange. Non-HT duplicate frame exchanges include:
    %       ** Frame exchange with non-HT acknowledgement
    %       ** Frame exchange with non-HT data frame
    %       ** Frame exchange with non-HT MU-BAR frame or Basic TF
    %   Usage is same as LastRTSBandwidth. It is reset when the TXOP ends.
    FirstNonHTDupBandwidth = 0;

    %LastPPDUBandwidth Holds the bandwidth of last transmitted PPDU by the TXOP
    %holder in current TXOP
    %   LastPPDUBandwidth is a scalar indicating the bandwidth of last
    %   transmitted frame in current TXOP.
    %   Usage is same as LastRTSBandwidth. It is reset when the TXOP ends.
    LastPPDUBandwidth = 0;

    %BWSignaledInRTS Holds indication that bandwidth signaling information is
    %sent in RTS frame
    %   BWSignaledInRTS is a flag indicating bandwidth signaling information is
    %   included in RTS frame.
    %   In TRANSMIT_STATE, it is set when RTS is sent in a Non-HT duplicate
    %   frame (BW of RTS frame > 20 MHz) to a VHT STA.
    %   In RECEIVERESPONSE_STATE, it is used to indicate whether
    %   NonHTChannelBandwidth parameter in RxVector corresponding to CTS is a
    %   valid value or not.
    %   It is reset when a frame exchange sequence is completed.
    BWSignaledInRTS = false;
end

%% Downlink/uplink OFDMA related properties
properties
    %StartingSequenceNums Starting sequence numbers of the frame, valid
    %until MU-BAR frame is transmitted in OFDMA frame sequence
    %   StartingSequenceNums is a column vector with number of valid values
    %   stored in NumTxUsers property.
    %   In TRANSMIT_STATE, it is set while sending a data frame to:
    %     * First sequence number in the set of MPDUs to each user
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill corresponding field in MU-BAR trigger frame sent after HE
    %       MU data frame
    StartingSequenceNums;

    %LSIGLength Length of the LSIG field of solicited HE-TB frames, valid
    %until trigger frame is transmitted in OFDMA frame sequence
    %   In TRANSMIT_STATE, it is set while sending an MU-RTS or Basic
    %   trigger frame or data frame to:
    %     * LSIG length of HE-TB PPDU responses solicited by trigger
    %       frame/frame with TRS control field in frame sequence
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill corresponding field in MU-BAR trigger frame sent after a HE
    %       MU data frame
    %     * Fill corresponding field in Basic trigger frame
    LSIGLength = 0;

    %NumHELTFSymbols Number of HE LTF symbols in solicited HE-TB frames,
    %valid until trigger frame is transmitted in OFDMA frame sequence
    %   In TRANSMIT_STATE, it is set while sending an MU-RTS or Basic
    %   trigger or data frame to:
    %     * Number of long training field symbols of the HE-TB PPDU
    %       responses solicited by trigger frame/frame with TRS control
    %       field in frame sequence
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill corresponding field in MU-BAR trigger frame sent after a HE
    %       MU data frame
    %     * Fill corresponding field in Basic trigger frame
    NumHELTFSymbols = 1;

    %NumDataSymbols Number of HE data OFDM symbols in each solicited HE-TB
    %frame
    %   NumDataSymbols is a column vector with number of valid values
    %   stored in NumTxUsers property.
    %   In TRANSMIT_STATE, it is set while sending an MU-RTS or data
    %   frame to:
    %     * Number of data symbols of the HE-TB PPDU response solicited
    %       from each user by trigger frame/frame with TRS control field
    %       in frame sequence
    %   In TRANSMIT_STATE, it is used to:
    %     * Fill corresponding field in TRS Control field in a HE MU data
    %       frame
    NumDataSymbols;

    %NumResponses Number of responses received after sending a data frame 
    %   In RECEIVERESPONSE_STATE, it is incremented by 1 for each response
    %   received after sending a data frame.
    %   In RECEIVERESPONSE_STATE, it is used when CCA Idle indication is
    %   received to know how many users have responded. If frames from all
    %   users are errored, MAC transitions to ERRORRECOVERY_STATE.
    %   It is reset to 0 at the entry of RECEIVERESPONSE_STATE.
    NumResponses = 0;
end

%% Multi-frame TXOP related properties
properties
    %ContinueMFTXOP Holds indication that the current TXOP can be continued
    %to initiate a new frame exchange sequence (FES)
    %   It is set at the end of current FES in the following states,
    %   provided there is sufficient time to initiate a new FES
    %       *In TRANSMIT_STATE, it is set to true when transmission of
    %        the current data frame is completed (No acknowledgment)
    %       *In RECEIVERESPONSE_STATE, it is set to true when the current
    %        frame exchange sequence ends (with/without receiving
    %        expected acknowledgment, or expected trigger response)
    %
    %   It is used in TRANSMIT_STATE to handle the code flow for
    %   subsequent frame exchange sequences within a TXOP
    %
    %   If TXOPLimit is zero, this flag is always set to false.
    ContinueMFTXOP = false;

    %DoPIFSRecovery Holds indication that MAC must wait for PIFS time
    %before initiating a new frame exchange sequence (FES)
    %   It is set at the end of current FES in the RECEIVERESPONSE_STATE,
    %   provided the last transmission has failed and there is sufficient time
    %   to initiate a new FES. The last transmission is considered as failed in
    %   the following cases:
    %       * Response frame is not received with RxEnd indication from PHY
    %       * Response timeout elapsed without receiving RxStart indication from PHY
    %       * Failed to decode the received frame (FCSFail)
    %       * Received an RxError indication from PHY
    %   The above cases are considered transmission failure as per section
    %   10.23.2.2 of IEEE Std 802.11-2020. If a transmission failure
    %   happened due to reception of a valid frame, but an unexpected
    %   response, PIFS recovery is not attempted, and TXOP is ended.
    %
    %   If TXOPLimit is zero, this flag is always set to false.
    DoPIFSRecovery = false;

    %IsTXOPInitialFrame Holds indication if the frame transmitted is the
    %first frame in the TXOP
    %   In TRANSMIT_STATE, it is set to true when a TXOP is initialized.
    %   In RECEIVERESPONSE_STATE, it is used to check if transmission failed
    %   for the initial frame in a TXOP.
    %
    %   It is reset when the first frame exchange sequence ends.
    IsTXOPInitialFrame = true;

    %LastTxFail Holds indication that the last transmission has failed
    %   In RECEIVERESPONSE_STATE, it is set to true in the following cases:
    %       * Response frame is not received with RxEnd indication from PHY
    %       * Response timeout elapsed without receiving RxStart indication from PHY
    %       * Failed to decode the received frame (FCSFail)
    %       * Received an errored frame or RxError indication from PHY
    %
    %   It is used to determine if PIFS recovery is necessary before the
    %   next transmission.
    %
    %   It is reset to false at the end of current TXOP.
    LastTxFail = false;

    %ProtectNextFrame Holds indication that the next frame exchange
    %sequence (FES) within the TXOP requires protection
    %   It is set to true in the following situations:
    %     * For an initial FES, it is set to true if RTS is enabled. For an AP
    %     transmission to EMLSR STA, it is always set to true.
    %     * In a non-initial FES in a multi frame TXOP, if the scheduled
    %     stations change within the current TXOP, and RTS/CTS or MU-RTS/CTS
    %     protection is enabled.
    %     * In a non-initial FES in a multi frame TXOP by an AP to EMLSR STA,
    %     if the last transmission has failed, ICF (MU-RTS)/CTS protection is
    %     required.
    %
    %   It is reset to false at the end of current TXOP.
    ProtectNextFrame = false;

    %OFDMAScheduleContext Holds scheduler context for OFDMA transmissions
    %   It holds the following context that can be reused in subsequent
    %   Downlink OFDMA or Uplink OFDMA transmissions within the current
    %   TXOP: AllocationIndex, UseLowerCenter26ToneRU, UseUpperCenter26ToneRU,
    %   and StationIDs.
    %
    %   If there are data frames for the scheduled stations (at TXOP
    %   Start), this context can be reused for a new FES within the
    %   TXOP initiated for the previously scheduled STAs.
    %
    %   It is updated each time the scheduler runs, and cleared at the
    %   end of current TXOP.
    OFDMAScheduleContext;
end

%% Queue access related properties
properties
    %RetryBufferIndices Indices of retransmission buffer from which
    %packets are transmitted
    %   RetryBufferIndices is a column vector of indices corresponding to
    %   stations in TxStationIDs.
    %   In TRANSMIT_STATE, it is set during dequeue to:
    %     * Index of retransmission buffer from which packets are
    %       transmitted
    %   In TRANSMIT_STATE, TRANSMITRESPONSE_STATE, it is used  when
    %   ack is disabled to:
    %     * Discard packets from a specific retransmission buffer
    %     * Get lengths of MSDUs transmitted to increment statistics
    %   In RECEIVERESPONSE_STATE, it is used  when ack is enabled to:
    %     * Discard packets from a specific retransmission buffer
    %     * Increment frame retry counters when required
    %     * Get lengths of MSDUs transmitted to increment statistics
    RetryBufferIndices;
end

%% PHY config objects
properties
    %PHY configuration objects for generating data frame and calculating
    %frame transmission time
    CfgNonHT;       % Non-HT config object
    CfgHT;          % HT config object
    CfgVHT;         % VHT config object
    CfgHE;          % HE config object
    CfgHEMU;        % HE-MU config object
    CfgTB;          % HE-TB config object
    CfgEHT;         % EHT config object
end

% Public methods
methods
    function obj = TxContext(maxSubframes, maxMUUsers, channelBandwidth)
        % Initialize
        obj.TxStationIDs = zeros(maxMUUsers, 1);
        obj.TxACs = zeros(maxMUUsers, 1);
        obj.RetryBufferIndices = zeros(maxMUUsers, 1);
        obj.TxFrameLength = zeros(maxMUUsers, 1);
        obj.TxMPDUCount = zeros(maxMUUsers, 1);
        obj.TxMCS = zeros(maxMUUsers, 1);
        obj.TxNumSTS = ones(maxMUUsers, 1);
        obj.StartingSequenceNums = zeros(maxMUUsers, 1);
        obj.TxMPDULengths = zeros(maxSubframes, maxMUUsers);
        obj.TxSubframeLengths = zeros(maxSubframes, maxMUUsers);
        obj.NumDataSymbols = zeros(maxMUUsers, 1);
        obj.NumAddressFields = zeros(maxMUUsers, 1);

        % Fill PHY configuration objects for Sending data
        obj.CfgHT = wlanHTConfig('ChannelBandwidth', 'CBW20');
        obj.CfgVHT = wlanVHTConfig('ChannelBandwidth', 'CBW20');
        obj.CfgHE = wlanHESUConfig('ChannelBandwidth', 'CBW20');
        obj.CfgNonHT = wlanNonHTConfig('ChannelBandwidth', 'CBW20');
        obj.CfgHEMU = wlanHEMUConfig(0);
        obj.CfgTB = wlanHETBConfig('ChannelBandwidth', 'CBW20');
        obj.CfgEHT = wlanEHTMUConfig("CBW"+channelBandwidth);

        % Initialize TxFrame structure
        obj.TxFrame = wlan.internal.utils.defaultMPDU;

        % OFDMA Schedule context
        obj.OFDMAScheduleContext = struct('AllocationIndex', 0, ...
        'UseLowerCenter26ToneRU', false, ...
        'UseUpperCenter26ToneRU', false, ...
        'StationIDs', 0);
    end
end
end
