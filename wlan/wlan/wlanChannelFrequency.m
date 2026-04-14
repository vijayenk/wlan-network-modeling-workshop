function fc = wlanChannelFrequency(channel,band)
%wlanChannelFrequency WLAN channel center frequency
%
%   FC = wlanChannelFrequency(CHANNEL,BAND) returns the WLAN channel center
%   frequency, in Hertz, for the specified channel numbers CHANNEL, within
%   the operating bands BAND.
%
%   FC is a scalar or an array containing the WLAN channel center frequency
%   in Hertz, where the size is the same as the CHANNEL.
%
%   CHANNEL is an integer scalar or array containing the WLAN channel
%   numbers. Valid WLAN channel numbers are:
%     1-14    (2.4 GHz band)
%     1-200   (5 GHz band)
%     1-233   (6 GHz band)
%   See Annex E of IEEE Std 802.11-2020, IEEE Std 802.11ax-2021 and IEEE
%   P802.11be/D1.0 for more information.
%
%   BAND is a scalar or array containing the band in Gigahertz for each
%   channel numbers specified in CHANNEL. Band must be one of:
%     2.4     (2.401 - 2.495 GHz)
%     5       (5.030 - 5.895 GHz)
%     6       (5.925 - 7.125 GHz)
%   If BAND is a scalar and CHANNEL is a vector, the function assumes the
%   same band for all channel numbers.

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

% Validate the property of the channel number and the band
validateattributes(channel,{'double'},{'positive','integer'},mfilename,'channel number');
validateattributes(band,{'double'},{'positive'},mfilename,'band');

% BAND must be the same size as CHANNEL or a scalar
coder.internal.errorIf(numel(band)~=1&&(numel(band)~=numel(channel)),'wlan:wlanChannelFrequency:InvalidBandSize');

if isscalar(band)
    fc = channelization(channel,band);
else % BAND is an array
    fc = coder.nullcopy(zeros(size(channel)));
    for i = 1:numel(channel)
        fc(i) = channelization(channel(i),band(i));
    end
end

end

function freqCenter = channelization(channelNum,freqBand)
switch freqBand
    case 2.4
        % IEEE Std 802.11-2020, December 2020, Table 15-6 and 16-6
        isValidChannelNum = channelNum <= 14;
        if all(isValidChannelNum,'all')
            % IEEE Std 802.11-2020, December 2020, Section 19.3.15.2, Equation 19-87
            freqCenter = 2407e6 + 5e6 * channelNum; % Only applicable for the channel number between 1 and 13
            % Channel 14 is valid only for DSSS and CCK modes in Japan
            freqCenter(channelNum==14) = 2484e6;
        else
            invalidChannelNum = channelNum(~isValidChannelNum);
            coder.internal.error('wlan:wlanChannelFrequency:InvalidChNumber','2.4',invalidChannelNum(1),14);
        end
    case 5
        isValidChannelNum = channelNum <= 200;
        if all(isValidChannelNum,'all')
            % IEEE Std 802.11-2020, December 2020, Section 17.3.8.4.2, Equation 17-27
            freqCenter = 5e9 + 5e6 * channelNum;
        else
            invalidChannelNum = channelNum(~isValidChannelNum);
            coder.internal.error('wlan:wlanChannelFrequency:InvalidChNumber','5',invalidChannelNum(1),200);
        end
    case 6
        isValidChannelNum = channelNum <= 233;
        if all(isValidChannelNum,'all')
            % Table E-4, Annex E, IEEE Std 802.11ax-2021
            if channelNum == 2
                channelStartingFrequency = 5925e6;
            else
                channelStartingFrequency = 5950e6;
            end
            % IEEE Std 802.11ax-2021, Section 27.3.23.2, Equation 27-135
            freqCenter = channelStartingFrequency + 5e6 * channelNum;
        else
            invalidChannelNum = channelNum(~isValidChannelNum);
            coder.internal.error('wlan:wlanChannelFrequency:InvalidChNumber','6',invalidChannelNum(1),233);
        end
    otherwise
        coder.internal.error('wlan:wlanChannelFrequency:InvalidBand');
end
end


