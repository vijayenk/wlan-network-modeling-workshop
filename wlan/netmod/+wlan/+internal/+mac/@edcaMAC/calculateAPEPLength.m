function [apepLength, mpduLengths, subframeLengths] = calculateAPEPLength(obj, ...
    isQoSNull, txFormat, mpduAggregation)
%calculateAPEPLength Returns APEP length in octets
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   [APEPLENGTH, MPDULENGTHS, SUBFRAMELENGTHS] = calculateAPEPLength(OBJ,
%   ISQOSNULL, TXFORMAT, MPDUAGGREGATION) returns the length of the PSDU
%   before end of frame (EOF) padding, MPDUs and A-MPDU subframes based on
%   the transmission frame dequeued from MAC queues, when ISQOSNULL is
%   specified as false. If ISQOSNULL is true, the function returns the
%   lengths corresponding to QoS Null frame sent in an A-MPDU.
%
%   APEPLENGTH is a vector, indicates the APEP length in octets for each
%   user.
%
%   MPDULENGTHS is a m-by-n vector, indicates the length of each MPDU in
%   octets. Here, m indicates the maximum number of subframes and n
%   indicates number of users in transmission.
%
%   SUBFRAMELENGTHS is a m-by-n vector, indicates the length of each A-MPDU
%   subframe in octets. Here, m indicates the maximum number of subframes
%   and n indicates number of users in transmission.
%
%   OBJ is an object of type edcaMAC.
%
%   TXFORMAT is the physical layer (PHY) frame format, specified as a
%   constant value defined in the class wlan.internal.FrameFormats.
%
%   MPDUAGGREGATION is a flag indicating MPDU aggregation is enabled.

%   Copyright 2022-2025 The MathWorks, Inc.

if isQoSNull
    % MPDU overhead = 26 (MPDU header) + 4 (FCS) + 4 (BSR Control)
    % Length of BSR Control = 2 bits (fixed) + 4 bits (A-Control ID) + 26 bits
    % (A-Control information)
    % Reference: Section 9.2.4.6.3a of IEEE Std 802.11ax-2021
    mpduOverhead = 34;

    % Calculate MPDU length
    mpduLengths = mpduOverhead;
    subframeLengths = mpduLengths + 4 + ... % Delimiter
        abs(mod(mpduLengths, -4)); % Padding
    apepLength = subframeLengths;

else
    tx = obj.Tx;
    apepLength = zeros(tx.NumTxUsers, 1);
    mpduLengths = zeros(obj.MaxSubframes, tx.NumTxUsers);
    subframeLengths = zeros(obj.MaxSubframes, tx.NumTxUsers);
    mpduOverhead = 30; % Fixed overhead for QoS Data frame
    if ((obj.TransmissionFormat == obj.HE_MU) && (obj.DLOFDMAFrameSequence == 1)) || (obj.IsAssociatedSTA && obj.ULOFDMAEnabledAtAP) % TRS control field or BSR control field
        % Additional fields: HT control
        % TRS Control and BSR Control are present in HE variant of HT Control
        % field. These fields are called A-Control fields. TRS Control is present
        % in frames transmitted by AP if the frame exchange sequence doesn't
        % include MU-BAR frame. BSR Control is present in frames sent by STA whose
        % associated AP can trigger UL OFDMA transmissions. Length of HT Control =
        % 2 bits (fixed) + 4 bits (A-Control ID) + 26 bits (A-Control information)
        % Reference: Section 9.2.4.6.3a of IEEE Std 802.11ax-2021
        mpduOverhead = mpduOverhead + 4;
    end

    for userIdx = 1:tx.NumTxUsers
        mpduList = tx.TxFrame(userIdx).MPDUs;
        numMPDUs = numel(mpduList);
        isGroupAddr = wlan.internal.utils.isGroupAddress(mpduList(1).Header.Address1);
        if tx.NumAddressFields(userIdx) == 4
            % Additional fields: Address-4
            mpduOverhead = mpduOverhead + 6;
        end
        
        for i = 1:numMPDUs
            meshControlSize = 0;
            if obj.IsMeshDevice % Frames sent by mesh STAs have mesh control field
                % Add 6 octets for mesh control field in mesh data frames
                % Reference: Section-9.2.4.7.3 in IEEE Std 802.11-2016
                if tx.NumAddressFields(obj.UserIndexSU) == 4 || isGroupAddr
                    meshControlSize = 6; % Octets
                    % Add variable address extension size of mesh control field.
                    % Only address extension mode of 0 and 2 are currently
                    % supported as external source addresses are not in the scope
                    % of implementation for groupcast frames.
                    if ~strcmp(wlan.internal.utils.getMeshDestinationAddress(mpduList(i)), mpduList(i).Metadata.DestinationAddress)
                        meshControlSize = meshControlSize + 12; % 12 octets for Address5 and Address6
                    end
                end
            end

            % Calculate MPDU length
            if wlan.internal.utils.isDataFrame(mpduList(i))
                frameBodyLength = mpduList(i).FrameBody.MSDU.PacketLength;
            else
                frameBodyLength = mpduList(i).Metadata.MPDULength - (mpduOverhead + meshControlSize);
            end
            mpduLengths(i, userIdx) = mpduOverhead + meshControlSize + frameBodyLength;
            subframeLengths(i, userIdx) = mpduLengths(i, userIdx);

            % Calculate APEP length
            apepLength(userIdx) = apepLength(userIdx) + mpduLengths(i, userIdx);

            % Aggregated MPDU
            if mpduAggregation
                % Delimiter overhead for aggregated frames (4 Octets)
                apepLength(userIdx) = apepLength(userIdx) + 4;
                subframeLengths(i, userIdx) = subframeLengths(i, userIdx) + 4;

                % Subframe padding overhead for aggregated frames
                subFramePadding = abs(mod(frameBodyLength + meshControlSize + mpduOverhead, -4));
                % Last subframe doesn't have padding in case of HT A-MPDU
                if (i == numMPDUs) && (txFormat == obj.HTMixed)
                    subFramePadding = 0;
                end
                apepLength(userIdx) = apepLength(userIdx) + subFramePadding;
                subframeLengths(i, userIdx) = subframeLengths(i, userIdx) + subFramePadding;
            end
        end
    end
end
end
