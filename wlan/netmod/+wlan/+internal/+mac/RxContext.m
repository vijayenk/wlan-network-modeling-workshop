classdef RxContext < handle
%RxContext Create an object to maintain context specific to
%RECEIVE_STATE for a node
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   OBJ = wlan.internal.mac.RxContext(BITMAPLENGTH, MAXMUUSERS) creates an
%   object, OBJ to maintain context specific to specific to frames received
%   at a node. BITMAPLENGTH is the allowed Block Ack bitmap length.
%   MAXMUUSERS is the maximum number of users supported in a multi-user
%   transmission.

%   Copyright 2022-2025 The MathWorks, Inc.

properties
    %RxVector Reception parameters vector received from PHY
    %   RxVector is a structure containing rx vector parameters received
    %   from PHY layer.
    %
    %   In RECEIVE_STATE,,  EMLSRRECEIVE_STATE, and
    %   RECEIVERESPONSE_STATE
    %       * It is set to the Vector field received in RxStart indication
    %   In RECEIVE_STATE,,  EMLSRRECEIVE_STATE, and
    %   RECEIVERESPONSE_STATE
    %       * It is used to apply appropriate MAC decoding methods
    %       * It is used to set Rx context
    %       * It is used in generating response frames and response MCS
    %       calculation
    %       * It is used in calculating MU response time for a received trigger
    %       via Trigger frame or MU Data containing TRS control field.
    %       * It is used in filling the event information for MPDUDecoded event
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used for determining response bandwidth
    %   In TRANSMIT_STATE,
    %       * It is used in setting CBW transmission context for an HE TB
    %       transmission
    RxVector;

    %RxSeqNums Received frame sequence numbers
    %   RxSeqNums is a vector representing the sequence numbers of the
    %   received frame.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the list of received sequence numbers in the
    %       AMPDU.
    %   In RECEIVE_STATE,
    %       * It is used to generate BA in response to the received MU-BAR
    %       corresponding to a previous AMPDU transmission.
    RxSeqNums;

    %RxErrorPHYFailure Flag to indicate Rx error indication from PHY layer
    %   RxErrorPHYFailure is a logical scalar. It is set to true in
    %   RECEIVERESPONSE and RECEIVE_STATE states when:
    %     * Rx error indication is received from PHY layer
    %
    %   In RECEIVE_STATE, EMLSRRECEIVE_STATE, and RECEIVERESPONSE_STATE
    %       * It is set to true if RxError is received from PHY
    %       * It is set to true if RxEnd is received without a MAC frame
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, INACTIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is used in determining if the recent reception resulted in
    %       any kind of PHY failure after CCA Idle indication is received
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, INACTIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is reset after the flag is checked.
    RxErrorPHYFailure = false;

    %RxErrorMACFailure Flag to indicate reception of frames with FCS failure or
    %unexpected response reception
    %   RxErrorMACFailure is a logical vector of size N x 1 where N is the
    %   number of users in a MU transmission. The element corresponding to
    %   received frame is set to true in RECEIVERESPONSE_STATE, and RECEIVE_STATE
    %   states in case of FCS failure in the frame.
    %
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is set to true if the received frame has FCS failure,
    %       delimiter failure, invalid frame length, or it is an unsupported
    %       frame.
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, INACTIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is used in determining if the recent reception resulted in
    %       any kind of MAC failure after CCA Idle indication is received
    %   In RECEIVE_STATE,
    %       * It is used to reset the EMLSR STA's link status at AP so that it can
    %       transmit to other links of EMLSR STA.
    %       * It is used in determining if state needs to be changed to
    %       NAVWAIT_STATE.
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, INACTIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is reset after the flag is checked.
    RxErrorMACFailure

    %LastRxFrameTypeNeedingResponse Type of the frame last received and
    %solicits response
    %   LastRxFrameTypeNeedingResponse is an enumerated value containing
    %   the type of frame received recently intended to this node and
    %   solicits a response frame. It is set to either of the following
    %   constant properties of edcaMAC: RTS, QoSData, MURTSTrigger,
    %   MUBARTrigger, BasicTrigger, QoSNull.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the last received frame type that needs a response.
    %   In TRANSMIT_STATE,
    %       * It is used to determine if trigger based transmission needs to be
    %       scheduled
    %   In RECEIVE_STATE,
    %       * It is used to check if state needs to be changed to
    %       TRANSMITRESPONSE_STATE.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used to determine type of actions based on the frame type
    %       * It is used in generating TxStart request
    %       * It is used in determining if performing CS is required
    %       * It is used to switch off PHY Rx during SIFS for non-trigger
    %       frames where CS is not required.
    %       * It is used in turning an EMLSR link active
    %   In INACTIVE_STATE,
    %       * It is reset in the state entry function.
    %   In TRANSMIT_STATE,
    %       * It is reset in the state exit function.
    LastRxFrameTypeNeedingResponse = wlan.internal.Constants.UnknownFrameType;
end

% Response frame context corresponding to received frame
properties
    %ResponseFrame Structure to store response frame
    %   ResponseFrame is a structure containing the generated response
    %   frame.
    %
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is set to the response frame to be sent in response to a
    %       received frame.
    %   In RECEIVE_STATE,  EMLSRRECEIVE_STATE, and
    %   RECEIVERESPONSE_STATE,
    %       * It is used to check if state needs to be changed to
    %       TRANSMITRESPONSE_STATE.
    %   In RECEIVE_STATE,
    %       * It is used to reset the EMLSR STA's link status at AP so that it can
    %       transmit to other links of EMLSR STA.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used as the frame to be sent as response.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is reset if response cannot be sent due to NAV, CCA, or BW
    %       restrictions.
    %       * It is reset after response has been transmitted.
    %   In INACTIVE_STATE,
    %       * It is reset in the state entry function.
    ResponseFrame;

    %ResponseStationID ID of the node to which response must be sent
    %   ResponseStationID is a scalar representing identifier of the node
    %   to which response must be sent. The initial value is 0.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the STA node ID to which response needs to be sent.
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the STA node ID to which response needs to be sent
    %       for the received HE TB frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in generating the TxStartRequest of the response frame
    %   In RECEIVERESPONSE_STATE,
    %       * It is used in generating frame to be sent in response to received
    %       HE TB frame.
    %   In RECEIVERESPONSE_STATE and  EMLSRRECEIVE_STATE,
    %       * It is reset before processing any received non-response frame.
    ResponseStationID = 0;

    %ResponseNumSTS Number of space-time streams to use for response frame
    %   ResponseNumSTS is a scalar value representing the number of
    %   space-time streams to use for response frame. The initial value is
    %   1.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the NumSTS of the response frame.
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the NumSTS of the frame to be sent in response to
    %       received HE TB frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in generating the TxStartRequest of the response frame
    %   In TRANSMIT_STATE and RECEIVE_STATE,
    %       * It is used in calculating response transmission time.
    ResponseNumSTS = 1;

    %ResponseMCS MCS index of response frame
    %   ResponseMCS is a scalar integer value representing MCS Index of the
    %   frame to be sent as response to received frame. In case of control
    %   response frames, it is in the range of [0 - 7]. In case of HE TB
    %   response to Basic Trigger frame, it is the value specified in UL
    %   HE-MCS field of Basic Trigger frame.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the MCS of the response frame.
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the MCS of the frame to be sent in response to
    %       received HE TB frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in generating the TxStartRequest of the response frame
    %   In TRANSMIT_STATE and RECEIVE_STATE,
    %       * It is used in calculating response transmission time.
    ResponseMCS = 0;

    %ResponseLength Length of response frame
    %   ResponseLength is a scalar value representing length of response
    %   frame in octets.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the PSDU length of the response frame.
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the PSDU length of the frame to be sent in response
    %       to received HE TB frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in generating TxStart request
    %       * It is used to notify information in TransmissionStarted event
    ResponseLength = 0;

    %ResponseRU Information of RU in which HE TB response must be sent
    %   ResponseRU is a vector [x y] where x is the size of RU and y is the
    %   index of RU.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the [RUSize, RUInfo] information of the received MU
    %       frame (MU Data or MU trigger)
    %   In RECEIVE_STATE,
    %       * It is used in calculating MU response time.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in performing/assessing CS (carrier sensing).
    %   In TRANSMIT_STATE,
    %       * It is used in calculating PSDU length of the HE TB response
    %       frame.
    %   In TRANSMIT_STATE and TRANSMITRESPONSE_STATE,
    %       * It is used in generating TxStartRequest for the HE TB response
    %       frame.
    ResponseRU;

    %ResponseTxTime Duration to transmit response frame from physical layer
    %   ResponseTxTime is a scalar representing duration to transmit
    %   response frame from physical layer.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the calculated response transmission time.
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the calculated transmission time of the frame to be
    %       sent in response to received HE TB frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used to assess and wait for the transmission to end.
    %       * It is used to notify information in TransmissionStarted event
    ResponseTxTime = 0;
end

% Information received in Trigger frames for UL transmission
properties
    %ULTriggerMethod Trigger method followed in multi-user transmission
    %   ULTriggerMethod is a character vector representing the method of
    %   soliciting an uplink (UL) HE-TB BA or Ack frame. Setting
    %   ULTriggerMethod to 'TRS' represents that UL frame is solicited using
    %   TRS control in MU PPDU, where as setting ULTriggerMethod to
    %   'TriggerFrame' represents that UL frame is solicited using a trigger
    %   frame. The initial value is 'TRS'
    %
    %   In RECEIVE_STATE,
    %       * It is set to either either "TriggerMethod" or "TRS" based on
    %       whether received frame is a Trigger frame or a Data frame with TRS
    %       control field.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in generating TxStartRequest for the response to the
    %       trigger received in the form of a Trigger frame or a Data frame
    %       with TRS control.
    %   In RECEIVE_STATE,
    %       * It is used in calculating MU response time.
    ULTriggerMethod = 'TRS';

    %ULLSIGLength LSIG length of the HE-TB frame
    %   ULLSIGLength is a scalar representing LSIG length of the HE-TB uplink
    %   frame. This is applicable in case of multi-user transmission.
    %
    %   In RECEIVE_STATE,
    %       * It is set to LSIGLength field decoded from the received trigger
    %       frame.
    %   In TRANSMIT_STATE and TRANSMITRESPONSE_STATE,
    %       * It is used in generating TxStartRequest for the HE TB response
    %       frame.
    %   In TRANSMIT_STATE,
    %       * It is used in calculating PSDU length of the HE TB response
    %       frame.
    ULLSIGLength;

    %ULNumHELTFSymbols Number of HE LTF symbols
    %   ULNumHELTFSymbols is a scalar representing the number of long training
    %   field symbols of the HE-TB PPDU response. Intended STAs set this value
    %   from the corresponding field in trigger frame sent by associated AP.
    %
    %   In RECEIVE_STATE,
    %       * It is set to NumHELTFSymbols field decoded from the received
    %       trigger frame.
    %   In TRANSMIT_STATE and TRANSMITRESPONSE_STATE,
    %       * It is used in generating TxStartRequest for the HE TB response
    %       frame.
    %   In RECEIVE_STATE,
    %       * It is used in calculating MU response time.
    %   In TRANSMIT_STATE,
    %       * It is used in calculating PSDU length of the HE TB response
    %       frame.
    ULNumHELTFSymbols = 1;

    %ULNumDataSymbols Number of HE data OFDM symbols
    %   ULNumDataSymbols is a scalar representing the number of data symbols
    %   of the HE-TB PPDU response. This is applicable in case of
    %   multi-user transmission.
    %
    %   In RECEIVE_STATE,
    %       * It is set to ULNumDataSymbols field decoded from the TRS control
    %       field of the received frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in generating TxStartRequest for the HE TB frame in
    %       response to frame containing TRS control field.
    %   In RECEIVE_STATE,
    %       * It is used in calculating MU response time.
    ULNumDataSymbols;

    %ULPreferredAC Lowest AC recommended by AP for aggregation of MPDUs in HE
    %TB data frame
    %   ULPreferredAC is a scalar representing the lowest AC that is
    %   recommended for aggregation of MPDUs in the A-MPDU contained in the
    %   HE TB PPDU sent as a response to the Basic Trigger frame.
    %
    %   In RECEIVE_STATE,
    %       * It is set to PreferredAC field decoded from the received basic
    %       trigger frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in selecting/scheduling ACs for transmitting data
    %       frames in response to a trigger frame.
    ULPreferredAC;

    %ULTIDAggregationLimit Maximum number of TIDs that can be aggregated by the
    %STA in the A-MPDU sent in UL HE-TB data frame
    %   ULTIDAggregationLimit is a scalar representing the maximum number of
    %   TIDs that the STA can send in an A-MPDU sent as response to Basic
    %   Trigger frame.
    %
    %   In RECEIVE_STATE,
    %       * It is set to TIDAggregationLimit field decoded from the received
    %       basic trigger frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used in selecting/scheduling ACs for transmitting data
    %       frames in response to a trigger frame.
    ULTIDAggregationLimit;
end

% Reception context used for timeout, NAV or BW signaling checks
properties
    %IgnoreReceiveTimeout Flag to ignore receive timeout trigger
    %   In state entry of  EMLSRRECEIVE_STATE, IgnoreReceiveTimeout is
    %   initialized to false.
    %   In  EMLSRRECEIVE_STATE, 
    %       * This flag is set to true if an RxStart is received. 
    %       * This flag is set to false again if the received frame does not
    %       require a response, to wait for next RxStart
    %   In  EMLSRRECEIVE_STATE,
    %       * This flag is used to determine if RxStart is received based on
    %       which error handling is performed when CCA indicates IDLE
    %       with/without PHY Rx Error indication prior to this.
    %   In state exit of  EMLSRRECEIVE_STATE, this flag is reset to true.
    IgnoreReceiveTimeout

    %WaitingForNAVReset Flag to indicate that NAV should be reset
    %   WaitingForNAVReset is a logical value that is set to true to
    %   indicate that NAV should be reset to zero.
    %
    %   In RECEIVE_STATE, 
    %       * It is set to true when NAV is set due to RTS or MU-RTS frame
    %       reception.
    %   In state entry of NAVWAIT_STATE, 
    %       * It is used to set appropriate NAV based on whether NAV is set due
    %       to RTS/MU-RTS or other frames.
    %   In ERRORRECOVERY_STATE, INACTIVE_STATE, NAVWAIT_STATE, RECEIVE_STATE, and
    %   TRANSMITRESPONSE_STATE, 
    %       * It is used to determine if RTS NAV reset timer needs to be
    %       checked for expiry and NAV needs to be reset.
    %   In RECEIVE_STATE and  EMLSRRECEIVE_STATE, 
    %       * This flag is reset to false if RxStart is received within NAV
    %       timeout after RxEnd corresponding to RTS/MU-RTS, to avoid resetting
    %       NAV. It is also reset after NAV is reset due to timeout expiry
    %       after its purpose is served.
    WaitingForNAVReset

    %RTSReceivedFrom Transmitter address of the RTS or MU-RTS frame intended to
    %us
    %   In RECEIVE_STATE, 
    %       * This property is set to store the RTS transmitter address.
    %   In TRANSMITRESPONSE_STATE, 
    %       * It is used to determine if NAV is set by TXOP owner.
    RTSReceivedFrom = '000000000000';

    %BWSignalingTAPresent Flag to indicate that the received frame contains
    %bandwidth signaling transmitter address
    %   In RECEIVE_STATE, 
    %       * This flag is set to true to determine whether BW signaling is
    %       present in the NonHT frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * This flag is used to determine whether or not to respond and what
    %       bandwidth to use for the response transmission.
    %   In state exit of TRANSMITRESPONSE_STATE,
    %       * This flag is reset to false.
    IsBWSignalingTAPresent = false;
end

% Reception context used in UL frame exchange
properties
    %CSRequired Flag to indicate carrier sensing is required
    %   CSRequired is a logical scalar indicating physical and virtual
    %   carrier sensing has to be done before responding to a trigger
    %   frame, when set to true.
    %
    %   In RECEIVE_STATE,
    %       * It is set to the decoded CSRequired field from MU-RTS or Basic
    %       trigger frame.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is used to determine if CS (carrier sensing) needs to be
    %       performed before response transmission.
    %   In TRANSMITRESPONSE_STATE,
    %       * It is reset to false after its purpose is served to determine if
    %       CS needs to be performed.
    CSRequired = false;

    %ULFramesFail Flag to indicate that all the subframes in an UL HE-TB
    %data transmission had FCS failures
    %   In RECEIVERESPONSE_STATE, 
    %       * It is set to determine if all subframes (entire AMPDU) failed in
    %       the UL frame that is received in response to trigger frame.
    %   In RECEIVERESPONSE_STATE, 
    %       * It is used to set LastTxFail transmission context property.
    ULFramesFail = false;

    %HETBDurationField Duration field of HE TB PPDU (maintained at AP)
    %   In RECEIVERESPONSE_STATE, 
    %       * It is set to store the duration field value in the UL frame
    %       received in response to trigger frame.
    %   In RECEIVERESPONSE_STATE, 
    %       * It is used to calculate the duration field of the response frame
    %       that is sent in response to the received UL HE TB frame.
    HETBDurationField;

    %TriggerDurationField Duration field of Basic trigger frame or initial
    %control frame, i.e., MU-RTS frame in microseconds (maintained at STA)
    %   In RECEIVE_STATE, 
    %       * It is set to store the duration field value in the received
    %       trigger frame.
    %   In RECEIVE_STATE, 
    %       * It is used to calculate the duration field of the UL HE TB frame
    %       sent in response to the trigger frame.
    TriggerDurationField;
end

% Reception context used in EMLSR frame exchange
properties
    %IsIntendedNoAckFrame Flag to indicate that an intended data/null frame
    %with 'No Ack' ack policy is received
    %   In  EMLSRRECEIVE_STATE, RECEIVE_STATE, and RECEIVERESPONSE_STATE,
    %       * It is set to true if the received frame does not require an Ack.
    %   In  EMLSRRECEIVE_STATE,
    %       * It is used to check if the timeout for RxStart needs to be
    %       restarted.
    IsIntendedNoAckFrame = false;
end

% Block Ack Context
properties(Hidden)
    %BlockAckBitmap BA bitmap for all four access categories
    %   BlockAckBitmap is an array of size N x 4 x M where 4 is the number of
    %   access categories, and M is the maximum number of subframes in an
    %   aggregated frame. Each row corresponds to a specific station in
    %   network. The third dimension represents Block Ack bitmap for frames
    %   from corresponding node and AC.
    %
    %   In RECEIVE_STATE and RECEIVERESPONSE_STATE,
    %       * It is updated with the bitmap being sent out in the Block Ack
    %       response frame.
    %       * It is expanded to accommodate the new STA IDs detected in the
    %       received frames.
    %   In RECEIVE_STATE and RECEIVERESPONSE_STATE,
    %       * It is used in maintaining Block Ack scoreboard for received data
    %       frames and generating response Block Ack frame.
    %       * It is used in detecting duplicate frames.
    BlockAckBitmap;

    %LastSSN Last starting sequence number(SSN)
    %   LastSSN is an array of size N x 4 where 4 is the number of access
    %   categories. Each row corresponds to a specific station in network.
    %   Each element is in the range of [0 - 4095] and represents starting
    %   sequence number of last received frame from corresponding node in
    %   the corresponding AC.
    %
    %   In RECEIVE_STATE and RECEIVERESPONSE_STATE,
    %       * It is updated with the starting sequence number in the Block Ack
    %       response frame.
    %       * It is expanded to accommodate the new STA IDs detected in the
    %       received frames.
    %   In RECEIVE_STATE and RECEIVERESPONSE_STATE,
    %       * It is used in maintaining Block Ack scoreboard for received data
    %       frames and generating response Block Ack frame.
    %       * It is used in detecting duplicate frames.
    LastSSN;

    %BAScoreboardSourceIDs Vector of source node IDs for which Block Ack
    %scoreboard is maintained
    %   The row index corresponding to a source is used for indexing reception
    %   (BA bitmap) context maintained per source.
    %
    %   In RECEIVE_STATE and RECEIVERESPONSE_STATE,
    %       * It is expanded to store the new STA IDs detected in the received
    %       frames.
    %   In RECEIVE_STATE and RECEIVERESPONSE_STATE,
    %       * It is used in accessing Block Ack scoreboard context
    %       corresponding to specific STAs.
    BAScoreboardSourceIDs = 0;
end

% Multi-STA BA context
properties
    %MultiSTABAContextSTAIndices Indices to access BA context to form Multi-STA BA
    %   MultiSTABAContextSTAIndices is an array of size M x 1, where each
    %   element represents index to access block ack bitmap context to form
    %   Multi-STA BA.
    %
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the STA indices corresponding to the entries for BA
    %       bitmap context.
    %   In RECEIVERESPONSE_STATE,
    %       * It is used to access the context of BA Bitmap for all users to
    %       which response should be sent while generating MultiSTABA response
    %       frame.
    MultiSTABAContextSTAIndices

    %MultiSTABAContextTIDs TIDs in which UL multi-user data is received
    %   MultiSTABAContextTIDs is an array of size M x 1, where each element
    %   represents the TID in which UL HE-TB data is received.
    %
    %   In RECEIVERESPONSE_STATE,
    %       * It is set to the TIDs corresponding to the entries for TIDs
    %       context.
    %   In RECEIVERESPONSE_STATE,
    %       * It is used to access the context of TIDs for all users to which
    %       response should be sent while generating MultiSTABA response frame.
    MultiSTABAContextTIDs
end

% Spatial Reuse context
properties
    %RTSRxTimestamp Timestamp at which an RTS/MU-RTS frame is received
    %   In RECEIVE_STATE, 
    %       * It is set to RTS reception timestamp when NAV is set due to RTS
    %       or MU-RTS frame reception.
    %   In RECEIVERESPONSE_STATE,
    %       * It is used to determine the time difference between RTS reception
    %       and CTS reception based on which we determine whether NAV should be
    %       updated from the received CTS.
    %   In RECEIVERESPONSE_STATE,
    %       * It is reset after calculating the time difference.
    RTSRxTimestamp

    %OBSSRTSNAVUpdated Flag to indicate that an inter-BSS RTS/MU-RTS frame is not
    %ignored and NAV is updated
    %   In RECEIVE_STATE, 
    %       * It is set to true when NAV is set due to RTS or MU-RTS frame
    %       reception.
    %   In RECEIVERESPONSE_STATE,
    %       * It is used to determine if NAV should be updated from received
    %       CTS.
    %   In RECEIVERESPONSE_STATE,
    %       * It is reset after using the flag to check whether NAV should be
    %       updated from received CTS.
    OBSSRTSNAVUpdated
end

methods
    function obj = RxContext(bitmapLength, maxMUUsers, varargin)
        % Constructor to create object for maintaining context specific to
        % RECEIVE_STATE.

        obj.RxErrorMACFailure = false(maxMUUsers, 1);
        obj.WaitingForNAVReset = false;
        obj.IgnoreReceiveTimeout = false;
        obj.RxSeqNums = zeros(bitmapLength, 1);
        obj.RTSRxTimestamp = 0;
        obj.OBSSRTSNAVUpdated = false;
        obj.MultiSTABAContextSTAIndices = zeros(maxMUUsers, 1);
        obj.MultiSTABAContextTIDs = zeros(maxMUUsers, 1);

        % Create context to be maintained for each source. Initialize for
        % one node and grow dynamically
        obj.BlockAckBitmap = zeros(1, 4, bitmapLength);
        obj.LastSSN = -1*ones(1, 4);

        % Assign properties specified as name-value pairs
        for idx = 1:2:numel(varargin)
            obj.(varargin{idx}) = varargin{idx+1};
        end
        
        % Reuse the default TxVector structure template defined for PHY layer
        % in wlan.internal.utils folder since it has the same fields as RxVector
        obj.RxVector = wlan.internal.utils.defaultTxVector;
    end
end
end
