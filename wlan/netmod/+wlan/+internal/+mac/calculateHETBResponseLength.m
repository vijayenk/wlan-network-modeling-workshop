function frameLengths = calculateHETBResponseLength(numTxUsers, baBitmapLength)
%calculateHETBResponseLength Return HE TB BA length for all users
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.
%
%   FRAMELENGTHS = calculateHETBResponseLength(NUMTXUSERS, BABITMAPLENGTH)
%   returns HE TB block ack lengths for all users.
%
%   FRAMELENGTHS is a vector of size NUMTXUSERS, indicating block ack
%   lengths for all the user.
%
%   NUMTXUSERS specifies the number of MU users. NUMTXUSERS is 1 in case of
%   SU transmission.
%
%   BABITMAPLENGTH specifies the size of block ack bitmap in bits.

%   Copyright 2023-2025 The MathWorks, Inc.

frameLengths = zeros(numTxUsers, 1);
for userIdx = 1:numTxUsers
    % Considering all the MPDUs in HE MU PPDU are untagged, only
    % Block Ack frame will be sent in HE TB PPDU in response to HE
    % MU PPDU containing TRS control field.
    % Reference: Section 26.4.4.4 in IEEE Std 802.11ax-2021
    % Considering MU-BAR trigger frame contains BAR Type as
    % 'Compressed BA', any STA receiving MU-BAR trigger frame sends
    % Block Ack frame in HE TB PPDU.
    % Reference: Section 26.4.5 in IEEE Std 802.11ax-2021
    if baBitmapLength == 64
        baFrameLength = 32;
    else % baBitmapLength == 256
        baFrameLength = 56;
    end
    % PSDU length = baFrameLength + 4(delimiter overhead) + 0(subframe padding)
    frameLengths(userIdx) = baFrameLength + 4;
end
end
