function channelBandwidth = getChannelBWFromBandChannel(band, channelNum)
%getBandChannelFromCenterFreq Return the frequency band and channel
%number corresponding to the given center frequency
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CHANNELBANDWIDTH = getChannelBWFromBandChannel(BAND, CHANNELNUM) returns
%   the channel bandwidth corresponding to the input band and channel.
%   CHANNELNUM must correspond to a supported channel number as used in
%   wlan.internal.utils.getChannelMap. If an unsupported CHANNELNUM is provided,
%   the function returns empty value for CHANNELBANDWIDTH.
%
%   CHANNELBANDWIDTH is the channel bandwidth in Hz.
%
%   BAND is the operating frequency band in GHz.
%
%   CHANNELNUM is a positive integer, specifying a channel number.

%   Copyright 2025 The MathWorks, Inc.

channelBandwidth = [];
channelMap = wlan.internal.utils.getChannelMap(band);
for colIdx = 1:size(channelMap,2)
    channels = channelMap(2:end, colIdx);
    channels = unique([channels{:}]);
    matchedChannel = find(channels == channelNum, 1);
    if ~isempty(matchedChannel)
        break;
    end
end
switch colIdx
    case 1
        channelBandwidth = 20e6;
    case 2
        channelBandwidth = 40e6;
    case 3
        channelBandwidth = 80e6;
    case 4
        channelBandwidth = 160e6;
    case 5
        channelBandwidth = 320e6;
end
end