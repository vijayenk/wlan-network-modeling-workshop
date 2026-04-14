function mpduLength = controlFrameMPDULength(obj, frameType, triggerType, numUsersIncluded, isICFFrame)
%controlFrameMPDULength Return MPDU length of given control frame type
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   MPDULENGTH = controlFrameMPDULength(OBJ, FRAMETYPE) returns the MPDU
%   length for the given control frame type.
%
%   OBJ is an object of type edcaMAC.
%
%   FRAMETYPE indicates the type of control frame.
%
%   MPDULENGTH = controlFrameMPDULength(..., TRIGGERTYPE, NUMUSERSINCLUDED,
%   ISICFFRAME) returns the MPDU length for trigger frames or Multi-STA BA
%   frame. TRIGGERTYPE input is ignored for Multi-STA BA.
%
%   TRIGGERTYPE indicates the type of trigger, if the control frame is a
%   trigger frame.
%
%   NUMUSERSINCLUDED indicates the number of user info fields included in
%   the trigger frame or number of STA info fields included in the
%   Multi-STA BA frame.
%
%   ISICFFRAME indicates whether the frame is an ICF frame if the control
%   frame is a trigger frame.
%
%   MPDULENGTH is an integer, indicates the MPDU length of the control
%   frame, in bytes.

%   Copyright 2025 The MathWorks, Inc.

switch frameType
    case 'RTS'
        % RTS frame length = 20 bytes (Frame control=2 + Duration=2 + RA=6 + TA=6 + FCS=4)
        mpduLength = 20;

    case 'CF-End'
        % CF-End frame length = 20 bytes (Frame control=2 + Duration=2 + RA=6 + BSSID(TA)=6 + FCS=4)
        mpduLength = 20;

    case 'CTS'
        % CTS frame length = 20 bytes (Frame control=2 + Duration=2 + RA=6 + FCS=4)
        mpduLength = 14;

    case 'ACK'
        % ACK frame length = 20 bytes (Frame control=2 + Duration=2 + RA=6 + FCS=4)
        mpduLength = 14;

    case 'Trigger'
        switch triggerType
            case 'MU-RTS'
                if isICFFrame
                    mpduLength = getICFLength(obj);
                else
                    % MU-RTS frame length = 28 bytes(header + common info field +
                    % FCS) + (5 bytes * number of users represented in user info
                    % fields), assuming all the users are associated and no RA-RU
                    % assignment
                    mpduLength = 28 + (5 * numUsersIncluded);
                end

            case 'MU-BAR'
                % MU-BAR frame length = 28 bytes(header + common info field + FCS)
                % + (9 bytes * number of users represented in user info fields),
                % assuming all the users are associated and no RA-RU assignment
                mpduLength = 28 + (9 * numUsersIncluded);

            case 'Basic'
                % Basic trigger frame length = 28 bytes(header + common info field + FCS) +
                % 6 bytes (Trigger Dependent User Info)
                % * number of users represented in user info fields,
                % assuming all the users are associated and no RA-RU
                % assignment
                mpduLength = 28 + (6 * numUsersIncluded);
        end

    case 'Multi-STA-BA'
        % Multi-STA BA length = 22 (Header + BA Control + FCS) + (4 (AID TID Info +
        % BA Starting Sequence Control) + Bitmap length in octets) * Number of
        % users. Reference: Section 9.3.1.8.7 of IEEE Std 802.11ax-2021
        mpduLength = 22 + (4+obj.BABitmapLength/8)*numUsersIncluded;

    otherwise % Block Ack
        % Block Ack length = 22 (Header + BA Control + FCS) + 2 (Starting
        % Sequence Control) + BABitmapLength/8
        if obj.BABitmapLength == 64
            mpduLength = 32;
        elseif obj.BABitmapLength == 256
            mpduLength = 56;
        elseif obj.BABitmapLength == 512 
            mpduLength = 88;
        else % obj.BABitmapLength == 1024
            mpduLength = 152;
        end
end
end

function frameLength  = getICFLength(obj)
% Return length of initial control frame (ICF)

frameLength = 28 + (5 * obj.Tx.NumTxUsers);
if obj.Tx.TxBandwidth == 320
    % Include special user info field if BW is 320 MHz. Special user info has
    % length equal to the other user info field(s) in same trigger frame.
    % Reference: Section 9.3.1.22.9, Table 9-45a, and Table 9-45g of
    % IEEE P802.11be/D5.0
    frameLength = frameLength + 5;
end

% Get the padding bytes to use in MU-RTS frame
numPadBytes = 0;
for userIdx = 1:obj.Tx.NumTxUsers
    staIdxLogical = (obj.Tx.TxStationIDs(userIdx) == [obj.SharedMAC.RemoteSTAInfo(:).NodeID]);
    numPadBytesForSTA = obj.SharedMAC.RemoteSTAInfo(staIdxLogical).NumEMLPadBytes;
    % AP ensures that the padding duration of MU-RTS frame (ICF) is greater
    % than or equal to the maximum for all the STAs with which frame exchanges
    % are initiated. Reference: Section 35.3.17 of IEEE P802.11be/D5.0
    numPadBytes = max(numPadBytes, numPadBytesForSTA);
end
% Add padding bytes to control frame length
frameLength = frameLength + numPadBytes;
% The MU-RTS frame sent as ICF is considered to have EHT User Info variant.
% But the fields are kept same as HE variant for simplicity.
end