function bandAndChannel(value, paramname)
%bandAndChannel Validates the input band and channel vector
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   bandAndChannel(VALUE, PARAMNAME) validates band and channel input and
%   throws relevant errors.
%
%   VALUE is a row vector of size 2 where first element is band and second
%   element is channel number.
%
%   PARAMNAME is the name of band and channel property/argument that is
%   being validated.

%   Copyright 2025 The MathWorks, Inc.

validateattributes(value, {'numeric'}, {'numel',2}, 'bandAndChannel', paramname);
freqBand = value(1);
channelNum = value(2);
validateattributes(channelNum, {'numeric'}, {'integer'}, 'bandAndChannel', "channel number(s) in "+paramname);

% Validate band and channel
switch freqBand
    case 2.4
        % All channels in 2.4 GHz as per Section 19.3.15.2 of IEEE Std 802.11-2020
        isValidChannelNum = (channelNum >= 1 && channelNum <= 14);
        if ~isValidChannelNum
            error(message('wlan:wlanChannelFrequency:InvalidChNumber','2.4',channelNum,14));
        end
    case 5
        % All channels in 5 GHz as per Section 19.3.15.3 of IEEE Std 802.11-2020
        isValidChannelNum = (channelNum >= 1 && channelNum <= 200);
        if ~isValidChannelNum
            error(message('wlan:wlanChannelFrequency:InvalidChNumber','5',channelNum,200));
        end
    case 6
        % All channels in 6 GHz as per 27.3.23.2 of IEEE Std 802.11ax-2021
        isValidChannelNum = (channelNum >= 1 && channelNum <= 233);
        if ~isValidChannelNum
            error(message('wlan:wlanChannelFrequency:InvalidChNumber','6',channelNum,233));
        end
    otherwise
        error(message('wlan:wlanChannelFrequency:InvalidBand'));
end
end
