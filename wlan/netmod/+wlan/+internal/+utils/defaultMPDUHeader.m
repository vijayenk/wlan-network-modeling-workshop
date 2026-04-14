function header = defaultMPDUHeader(frameType)
%defaultMPDUHeader Returns a default structure for MPDU frame header
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   HEADER = defaultMPDUHeader returns a default application
%   packet structure with the following fields.
%
%   FrameType       - Indicates the subtype of frame control field
%   ToDS            - ToDS flag of frame control field
%   FromDS          - FromDS flag of frame control field
%   Duration        - Duration field
%   Retransmission  - Retransmission flag
%   SequenceNumber  - Sequence number
%   TID             - TID indicating any value from 0-7
%   AckPolicy       - String indicating ack policy
%   Address1        - String indicating Address1 in hexadecimal format
%   Address2        - String indicating Address2 in hexadecimal format
%   Address3        - String indicating Address3 in hexadecimal format
%   Address4        - String indicating Address4 in hexadecimal format
%   AControlID      - AControl identifier. Takes -1 (Invalid) or 0 (TRS control) or 3 (BRS control)
%   AControlInfo    - Takes either wlan.internal.utils.defaultBSRControlInfo
%                     or wlan.internal.utils.defaultTRSControlInfo
%
%   APPLICATIONPACKET = defaultMPDUHeader(FRAMETYPE) returns the default
%   application packet structure with the given value FRAMETYPE assigned to
%   FrameType field.

% Copyright 2025 The MathWorks, Inc.

    arguments
        frameType = 'QoS Data';
    end

    header = struct( ...
        'FrameType', frameType, ...
        'ToDS', false, ...
        'FromDS', true, ...
        'Duration', 0, ...
        'Retransmission', false, ...
        'SequenceNumber', 0, ...
        'TID', 0, ...
        'AckPolicy', 'Normal Ack/Implicit Block Ack Request', ...   % 'No Ack' | 'Normal Ack/Implicit Block Ack Request' | 'Block Ack' | 'No explicit acknowledgment/PSMP Ack/HTP Ack'
        'Address1', '000000000000', ...
        'Address2', '000000000000', ...
        'Address3', '000000000000', ...
        'Address4', '000000000000', ...
        'AControlID', -1, ...
        'AControlInfo', []);
end