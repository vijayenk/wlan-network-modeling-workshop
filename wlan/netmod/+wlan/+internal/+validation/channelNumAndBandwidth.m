function channelNumAndBandwidth(band, channel, cbw)
    %channelNumAndBandwidth Validates channel number and bandwidth as per Annex
    %E of IEEE Std 802.11-2020, IEEE Std 802.11ax-2021 and Draft P802.11be/D5.0
    %
    %   Note: This is an internal undocumented function and its API and/or
    %   functionality may change in subsequent releases.
    %
    %   channelNumAndBandwidth(BAND, CHANNEL, CBW) validates whether a channel
    %   in a band is valid for the specified bandwidth as per Annex E.
    %
    %   BAND is a scalar with one of the following values: 2.4, 5, 6.
    %
    %   CHANNEL is a scalar integer in the range [1, 14] when band is 2.4, [1,
    %   200] when band is 5 and [1, 233] when band is 6.
    %
    %   CBW is a scalar with one of the following values: 20e6, 40e6, 80e6,
    %   160e6, 320e6.

    %   Copyright 2024-2025 The MathWorks, Inc.

    channelMap = wlan.internal.utils.getChannelMap(band);
    columnIdx = log2(cbw/10e6); % Column index that contains channels of given BW
    validChannels = [channelMap{2:end,columnIdx}];
    validChannels = unique(nonzeros(validChannels));
    if ~any(channel==validChannels)
        error(message('wlan:shared:InvalidChannelForCBW', ...
            cbw/1e6, band, mat2str(validChannels')))
    end
end
