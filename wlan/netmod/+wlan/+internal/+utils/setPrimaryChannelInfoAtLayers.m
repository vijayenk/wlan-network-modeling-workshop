function setPrimaryChannelInfoAtLayers(node, deviceIdx, primaryChannelIdx, primaryChannelFreq)
%setPrimaryChannelInfoAtLayers Sets primary channel information at MAC and
%PHY layers
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   setPrimaryChannelInfoAtLayers(NODE, DEVICEIDX, PRIMARYCHANNELIDX,
%   PRIMARYCHANNELFREQ) sets primary channel information at MAC and PHY
%   layers of a device/link in a node.
%
%   NODE is the wlanNode object.
%
%   DEVICEIDX is a scalar representing the index of device or link.
%
%   PRIMARYCHANNELIDX is a scalar representing index of primary 20 MHz
%   channel in the configured bandwidth.
%
%   PRIMARYCHANNELFREQ is a scalar representing center frequency of primary
%   20 MHz channel. Units are in Hz.

%   Copyright 2024-2025 The MathWorks, Inc.

setPrimaryChannelInfo(node.MAC(deviceIdx), primaryChannelIdx);
setPrimaryChannelInfo(node.PHYTx(deviceIdx), primaryChannelIdx);
setPrimaryChannelInfo(node.PHYRx(deviceIdx), primaryChannelIdx, primaryChannelFreq);
end
