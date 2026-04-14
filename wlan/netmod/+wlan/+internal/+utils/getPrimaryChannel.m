function [primaryChannelNum,primary20Freq] = getPrimaryChannel(bandAndChannel, bandwidth, primaryChannelIdx)
%getPrimaryChannel Return primary channel number and center frequency
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   [PRIMARYCHANNELNUM,PRIMARY20FREQ] = getPrimaryChannel(BANDANDCHANNEL,
%   BANDWIDTH, PRIMARYCHANNELIDX) returns the primary channel number and
%   primary 20MHz subchannel center frequency.
%
%   PRIMARYCHANNELNUM is the channel number corresponding to primary 20MHz
%   subchannel.
%
%   PRIMARY20FREQ is the center frequency corresponding to primary 20MHz
%   subchannel.
%
%   BANDANDCHANNEL is a vector of two elements representing band and
%   channel number values. 
%
%   BANDWIDTH is the operating channel bandwidth in Hz.
%
%   PRIMARYCHANNELIDX is the index for the primary 20MHz subchannel within
%   the operational channel bandwidth.

%   Copyright 2025 The MathWorks, Inc.

operatingFreq = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));
startingFreq = operatingFreq - bandwidth/2;
primary20Freq = startingFreq + (primaryChannelIdx-1)*20e6 + 10e6;

% Get channel number from center frequency
[~, primaryChannelNum] = wlan.internal.utils.getBandChannelFromCenterFreq(primary20Freq);
end