function macReqToPHY = generateTxStartRequest(obj, frameFormat, cbw, mcsIndex, ...
    numSTS, psduLength, stationIDs, varargin)
%generateTxStartRequest Generate Tx start request
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   MACREQTOPHY = generateTxStartRequest(OBJ, FRAMEFORMAT, CBW, MCSINDEX,
%   NUMSTS, PSDULENGTH, STATIONIDS) generates Tx start request that is to
%   be sent to PHY layer for frame formats other than HE-TB.
%
%   MACREQTOPHY represents Tx start request from MAC to PHY.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMEFORMAT is the PHY format, specified as a constant value defined in
%   the class wlan.internal.FrameFormats.
%
%   CBW is the channel bandwidth specified as one of 20, 40, 80, or 160.
%
%   MCSINDEX is the MCS index of frame for which transmission start request
%   is being generated. In case of MU transmission, it is a vector with
%   values corresponding to each user.
%
%   NUMSTS is the number of space-time streams for which transmission start
%   request is being generated. In case of MU transmission, it is a vector
%   with values corresponding to each user.
%
%   PSDULENGTH is the length of frame for which transmission start request
%   is being generated. In case of MU transmission, it is a vector with
%   values corresponding to each user.
%
%   STATIONIDS is the identifiers of stations to which the frame is
%   intended. In case of MU transmission, it is a vector with values
%   corresponding to each user.
%
%   MACREQTOPHY = generateTxStartRequest(OBJ, edcaMAC.NONHT, CBW, MCSINDEX,
%   NUMSTS, PSDULENGTH, STATIONIDS, BWOPERATIONTYPE) generates Tx start 
%   request that is to be sent to PHY layer for a Non-HT DUP PPDU.
%
%   BWOPERATIONTYPE indicates the type of Non-HT DUP bandwidth operation as
%   one of 'Static' or 'Dynamic'.
%
%   MACREQTOPHY = generateTxStartRequest(OBJ, edcaMAC.HE_TB, CBW, MCSINDEX,
%   NUMSTS, PSDULENGTH, STATIONIDS, TRIGMETHOD, HETBINFO) generates Tx
%   start request that is to be sent to PHY layer for a HE-TB PPDU.
%
%   TRIGMETHOD is the type of trigger that solicited the frame for which
%   transmission start request is being generated. Possible values are
%   'TriggerFrame' or 'TRS'.
%
%   HETBINFO stores number of data symbols when trigger method is 'TRS'. It
%   stores the length of the LSIG field when trigger method is given as
%   'TriggerFrame'.

%   Copyright 2022-2025 The MathWorks, Inc.

macReqToPHY = obj.EmptyRequestToPHY;
% Copy to local variables to avoid multiple dot notations
vector = macReqToPHY.Vector;
numUsers = nnz(psduLength);
perUserInfo = repmat(macReqToPHY.Vector.PerUserInfo, 1, numUsers);

macReqToPHY.MessageType = obj.TxStartRequest;

if nargin == 8 % Request for Non-HT DUP format
    bwOperationType = varargin{1};
    if ~strcmp(bwOperationType, 'Absent')
        vector.BandwidthOperation = bwOperationType;
        vector.SignalChannelBandwidth = true;
        vector.NonHTChannelBandwidth = cbw;
    end

elseif nargin == 9 % Request for HE_TB format
    trigMethod = varargin{1};
    heTBInfo = varargin{2};
end

if frameFormat == obj.NonHT
    mpduAggregation = false;
elseif frameFormat == obj.HTMixed
    mpduAggregation = obj.Tx.TxAggregatedMPDU;
else % VHT/HE
    mpduAggregation = true;
end

% Fill common Tx vector parameters
vector.PPDUFormat = frameFormat;

% Fill UplinkIndication only for HE_SU, HE_MU, HE_EXT_SU, EHT_SU,
% EHT_MU formats. For all other cases, it is not applicable. Refer Section
% 27.2.2 of IEEE Std 802.11ax-2021 and Section 36.2.2 of IEEE
% P802.11be/D5.0.
uplinkIndFormat = (frameFormat == obj.HE_SU) || (frameFormat == obj.HE_MU) || (frameFormat == obj.HE_EXT_SU) || ...
    (frameFormat == obj.EHT_SU) || (frameFormat == obj.EHT_MU);
if uplinkIndFormat
    % STA can only transmit to AP. For mesh devices, set this flag to false
    vector.UplinkIndication = obj.IsAssociatedSTA && ~obj.IsMeshDevice;
end

vector.ChannelBandwidth = cbw;
% Fill channelization information for 320 MHz
if cbw == 320
    linkIdx = getLinkIndex(obj);
    channel = obj.SharedMAC.BandAndChannel(linkIdx,2);
    % Default channelization for 320 MHz is 1. Update if any of the 320MHz-2
    % channels are used
    if any(channel == [63 127 191])
        vector.Channelization320MHz = 2;
    end
end
vector.AggregatedMPDU = mpduAggregation;
isTBFormat = (frameFormat == obj.HE_TB);
if uplinkIndFormat || isTBFormat
    vector.BSSColor = obj.BSSColor;
end

if obj.TXOPDuration ~= -1 % Duration is valid
    % If the calculated duration information is smaller than 8448 μs, the
    % TXOP_DURATION shall be set to the calculated duration information.
    % Otherwise, TXOP_DURATION shall be set to 8448.
    %
    % Reference: Table 27-1-TXVECTOR and RXVECTOR parameters of IEEE std
    % 802.11ax-2021, Table 36-1 of IEEE P802.11be/D5.0.

    txopDuration = min(obj.TXOPDuration, 8448);
    if (frameFormat == obj.EHT_SU) % EHT single user
        if txopDuration < 512
            vector.TXOPDuration = 2*floor(txopDuration/8);
        else
            vector.TXOPDuration = 2*floor((txopDuration -512)/128)+1;
        end
    else
        % A microsecond duration must be encoded to a value between 0-127
        % in TXOP subfield of HE-SIG-A field. This subfield has 7 bits
        % (B0-B7), B0 is the MSB.
        % 
        % For a duration lesser than 512 microseconds, B0 = 0 (which holds
        % bit value of 0), and B1-B6 is calculated. Otherwise, B0 = 1
        % (which holds bit value of 64), and B1-B6 is calculated
        % accordingly.
        if txopDuration < 512
            vector.TXOPDuration = floor(txopDuration/8);
        else
            vector.TXOPDuration = 64 + floor((txopDuration -512)/128);
        end
    end
end

useAIDInVector = false;
if frameFormat == obj.HE_MU
    vector.RUAllocation = obj.Tx.AllocationIndex;
    useAIDInVector = ~obj.IsMeshDevice; % AID used only for AP/STA
elseif frameFormat == obj.EHT_SU 
    useAIDInVector = ~obj.IsMeshDevice; % AID used only for AP/STA
elseif isTBFormat
    % Current implementation supports HE_TB frame to be sent in same RU
    % in which HE_MU with TRS or trigger frame is received
    rx = obj.Rx;
    vector.RUAllocation = [rx.ResponseRU(1) rx.ResponseRU(2)];
    vector.TriggerMethod = trigMethod;
    if strcmp(trigMethod, 'TRS')
        % NumHELTFSymbols is set to 1 when TriggerMethod is TRS.
        % Reference: 26.5.2.3.4 of IEEE Std 802.11ax-2021
        vector.NumHELTFSymbols = 1;
        % LSIGLength contains number of UL Data Symbols
        vector.LSIGLength = heTBInfo;
    else % Trigger frame
        vector.NumHELTFSymbols = rx.ULNumHELTFSymbols;
        vector.LSIGLength = heTBInfo;
    end
end
vector.NumTransmitChains = obj.NumTransmitAntennas;
vector.LowerCenter26ToneRU = obj.Tx.CfgHEMU.LowerCenter26ToneRU;
vector.UpperCenter26ToneRU = obj.Tx.CfgHEMU.UpperCenter26ToneRU;

% Fill per user Tx vector parameters
for userIdx = 1:numUsers
    perUserInfo(userIdx).MCS = mcsIndex(userIdx);
    perUserInfo(userIdx).Length = psduLength(userIdx);
    if useAIDInVector
        if obj.IsAPDevice % AP stores AID value of its associated STA
            perUserInfo(userIdx).StationID = getAID(obj.SharedMAC, stationIDs(userIdx));
        else % STA stores its AID value assigned by the AP
            perUserInfo(userIdx).StationID = obj.AID;
        end
    else
        perUserInfo(userIdx).StationID = stationIDs(userIdx);
    end
    % Fill NumSpaceTimeStreams based on format and trigger method
    perUserInfo(userIdx).NumSpaceTimeStreams = numSTS(userIdx);
    if isTBFormat
        if strcmp(trigMethod, 'TRS')
            % NumSpaceTimeStreams must be 1, when trigger method is TRS
            perUserInfo(userIdx).NumSpaceTimeStreams = 1;
        else
            perUserInfo(userIdx).NumSpaceTimeStreams = numSTS(userIdx);
        end
    end
    perUserInfo(userIdx).TxPower = getTransmitPower(obj, mcsIndex(userIdx), numSTS(userIdx), cbw);
end

% Re-assign the structure fields
vector.PerUserInfo = perUserInfo;
macReqToPHY.Vector = vector;
end

function txPower = getTransmitPower(obj, mcsIndex, numSTS, cbw)
%getTransmitPower Return the transmit power in dBm.
%
%   TXPOWER = GETTRANSMITPOWER(OBJ, MCSINDEX, NUMSTS, CBW) returns the
%   transmit power in dBm.
%
%   OBJ is an object of type edcaMAC.
%
%   MCSINDEX is the MCS index of frame for which transmission start request
%   is being generated.
%
%   NUMSTS is the number of space-time streams for which transmission start
%   request is being generated.
%
%   CBW is the channel bandwidth specified as one of 20, 40, 80, or 160.

    % Initialization to calculate signal transmission power
    controlInfo = obj.PowerControl.ControlInfo;

    % Power calculation
    controlInfo.MCS = mcsIndex;
    controlInfo.ChannelBandwidth = cbw;
    txPower = getTxPower(obj.PowerControl, controlInfo);

    if obj.RestrictSRTxPower
        % Refer section 26.10.2.4 in IEEE Std 802.11-2020. The
        % TXPowerReference is 4 dB higher for APs with more than 2 spatial
        % streams.
        txPowerReference = 21;
        if obj.IsAPDevice && numSTS > 2
            txPowerReference = 25;
        end

        for idx=1:numel(obj.OBSSPDBuffer)
            % Restrict the Tx Power. This OBSS PD SR transmit power
            % restriction shall be terminated at the end of the TXOP that
            % this STA gains once its backoff reaches zero.

            txPowerMax = txPowerReference - (obj.OBSSPDBuffer(idx) - obj.OBSSPDThresholdMin);
            txPower = min([txPowerMax, txPower]);
        end
    end
end
