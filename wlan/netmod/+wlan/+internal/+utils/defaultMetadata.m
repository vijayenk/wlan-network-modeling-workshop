function metadata = defaultMetadata(Vector)
%defaultMetadata Returns a default metadata structure to be included in the
%Metadata field of wirelessPacket structure.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   METADATA = defaultMetadata() returns a structure with the fields
%
%   Channel              - Structure contantaining abstract channel
%                          information. See <a href="matlab:help('wlan.internal.utils.defaultChannelStructure')">wlan.internal.utils.defaultChannelStructure</a>.
%   Vector               - Structure containing the information of the
%                          received vector from MAC. See
%                          <a href="matlab:help('wlan.internal.utils.defaultTxVector')">wlan.internal.utils.defaultTxVector</a>.
%   PayloadInfo          - Array of structures with each structure
%                          containing the payload information of MPDU.
%                          Duration - Time duration from end of last
%                                     payload in micro seconds
%                          NumBits  - Number of bits in payload
%   PreambleDuration     - Duration of the preamble in nanoseconds
%   HeaderDuration       - Duration of the header in nanoseconds
%   MIMOPreambleDuration - Duration of the beamformed preamble in 
%                          nanoseconds
%   PayloadDuration      - Duration of payload in nanoseconds
%   SubframeLengths      - Lengths of the subframes carried in a A-MPDU
%   SubframeIndices      - Start indices of the subframes in a A-MPDU
%   MACDataType          - wlan.internal.networkUtilsDataTypeMACFrameBits, 
%                          or wlan.internal.networkUtilsDataTypeMACFrameStruct
%                          depending on MAC abstraction
%   MPDUSequenceNumber   - MPDU sequence number
%   PacketGenerationTime - Packet generation time stamp (at origin)
%   PacketID             - Packet identifier assigned at origin
%
%   METADATA = defaultMetadata(VECTOR) creates a defaults structure with
%   the specified vector.

%   Copyright 2022-2025 The MathWorks, Inc.

arguments
    Vector = wlan.internal.utils.defaultTxVector;
end

metadata = struct( ...
    'Channel', wlan.internal.utils.defaultChannelStructure, ...
    'Vector', Vector, ...
    'PayloadInfo', struct('Duration', 0,'NumBits', 0), ...      % Dynamically expanded to NumUsers-by-NumSubframes
    'PreambleDuration', 0, ...
    'HeaderDuration', 0, ...
    'MIMOPreambleDuration', 0, ...
    'OversamplingFactor', 1, ...
    'PayloadDuration', 0, ...
    'NumSubframes', 0, ...        % Dynamically expanded to NumUsers
    'SubframeLengths', 0, ...     % Dynamically expanded to NumUsers-by-NumSubframes
    'SubframeIndices', 0, ...     % Dynamically expanded to NumUsers-by-NumSubframes
    'MACDataType', wlan.internal.Constants.DataTypeMACFrameBits, ...
    'MPDUSequenceNumber', 0, ...  % Dynamically expanded to NumUsers-by-NumSubframes
    'PacketGenerationTime', 0, ...% Dynamically expanded to NumUsers-by-NumSubframes
    'PacketID', 0);               % Dynamically expanded to NumUsers-by-NumSubframes
end