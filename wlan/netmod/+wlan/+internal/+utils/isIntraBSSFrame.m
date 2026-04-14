function status = isIntraBSSFrame(bssColor, bssID, rxVector, txopHolder, rxCfg)
%isIntraBSSFrame Determines whether the received frame is intra-BSS
%frame
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases
%
%   STATUS = isIntraBSSFrame(BSSCOLOR, BSSID, RXVECTOR, TXOPHOLDER) returns
%   STATUS as true if the received frame is intra-BSS, otherwise returns
%   false. This signature is used when the MAC frame cannot be decoded.
%
%   BSSCOLOR is an identifier of a basic service set as an
%   integer scalar in the range [0 63].
%
%   BSSID is the MAC address of the access point (AP).
%
%   RXVECTOR is a structure containing rx vector parameters received
%   from PHY layer.
%
%   TXOPHOLDER is the saved TXOP holder address.
%
%   STATUS = isIntraBSSFrame(BSSCOLOR, BSSID, RXVECTOR, TXOPHOLDER, RXCFG)
%   returns STATUS as true if the received frame is intra-BSS, otherwise
%   returns false. RXCFG is the MAC frame configuration object of the
%   received frame.
%
%   RXCFG is the mac frame configuration obj of type wlanMACFrameConfig in
%   case of full MAC and a structure in case of abstracted MAC frame.

%   Copyright 2025 The MathWorks, Inc.

status = false;

% Form BSSID
bssid = ['02', bssID(3:end)];

% RXCFG will be empty when FCS is failed for the received frame. In this
% case only RXVECTOR is used to determine whether the frame is an inter-BSS
% or intra-BSS frame.
if nargin < 5
    % Use BSSColor to decide if it's an intra-BSS frame. Refer Section 26.2.2
    % of IEEE Std. 802.11ax-2021.
    status = (rxVector.BSSColor == bssColor) && (rxVector.BSSColor ~= 0);
    return;
end

if strcmp(rxCfg.Header.FrameType, 'CTS') || strcmp(rxCfg.Header.FrameType, 'ACK')
    % CTS frame or ACK frame. For control frames without TA but has an RA,
    % check whether RA matches with saved TXOP holder address. Reference:
    % Section 26.2.2 of IEEE 802.11ax-2021
    if strcmp(rxCfg.Header.Address1, txopHolder)
        status = true;
    end
elseif wlan.internal.utils.isControlFrame(rxCfg) % RTS, Block Ack, Multi-STA-BA, Trigger, CF-End
    if strcmp(rxCfg.Header.Address1, bssid) || strcmp(rxCfg.Header.Address2, bssid)
        status = true;
    end
else % QoSData, QoS Null, or Management
    if strcmp(rxCfg.Header.Address3, bssid) || strcmp(rxCfg.Header.Address2, bssid) || strcmp(rxCfg.Header.Address1, bssid)
        status = true;
    end
end
end