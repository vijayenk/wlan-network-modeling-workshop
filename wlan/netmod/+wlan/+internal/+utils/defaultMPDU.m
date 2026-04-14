function mpdu = defaultMPDU(header, framebody)
%defaultMPDU Returns a default MPDU packet structure
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   MPDU = defaultMPDU returns an MPDU packet structure.
%   The optional inputs HEADER and FRAMEBODY are assigned to Header and
%   FrameBody substructures respectively in the returned MPDU structure.
%
%   MPDU is a structure with the following fields.
%
%   Header              - Header substructure of type wlan.internal.utils.defaultMPDUHeader.
%   FrameBody           - Frame body substructure of type wlan.internal.utils.defaultMPDUFrameBody.
%   FCSPass             - Flag indicating if FCS is valid
%   DelimiterPass       - Flag indicating if Delimiter is valid. Applicable
%                         if MPDU is part of AMPDU.
%   Metadata            - Substructure containing following fields:
%           MPDULength          - Length of the MPDU in bytes
%           SourceAddress       - String indicating source address in hexadecimal format
%           DestinationAddress  - String indicating destination address in hexadecimal format
%           ReceiverID          - ID of the receiver node
%           DestinationID       - ID of the destination node
%           FrameRetryCount     - Retransmission count of this frame
%           MACEntryTime        - Time at which this MPDU entered MAC, in seconds
%           SubframeIndex       - Start index of the subframe
%           SubframeLength      - Length of the subframe
%
%   MPDU = defaultMPDU(HEADER, FRAMEBODY) returns an MPDU packet structure
%   with the inputs HEADER and FRAMEBODY assigned to Header and FrameBody
%   substructures respectively in the returned MPDU structure.
%   HEADER is an structure of type wlan.internal.utils.defaultMPDUHeader.
%
%   FRAMEBODY is an structure of type wlan.internal.utils.defaultMPDUFrameBody.

% Copyright 2025 The MathWorks, Inc.

arguments
    header = wlan.internal.utils.defaultMPDUHeader;
    framebody = wlan.internal.utils.defaultMPDUFrameBody('QoS Data');
end

mpdu = struct(...
            'Header', header, ...
            'FrameBody', framebody, ...
            'FCSPass', true, ...
            'DelimiterPass', true, ...
            'Metadata', mpduMetadata);
end

function metadata = mpduMetadata()
    metadata = struct(...
                    'MPDULength', 0, ...
                    'SourceAddress', '000000000000', ...
                    'DestinationAddress', '000000000000', ...
                    'ReceiverID', 0, ...
                    'DestinationID', 0, ...
                    'FrameRetryCount', 0, ...   
                    'MACEntryTime', 0, ...
                    'SubframeIndex', 0, ...
                    'SubframeLength', 0);
end
