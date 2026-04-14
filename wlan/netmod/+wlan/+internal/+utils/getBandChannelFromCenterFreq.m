function [band, channelNum] = getBandChannelFromCenterFreq(centerFreq)
%getBandChannelFromCenterFreq Return the frequency band and channel
%number corresponding to the given center frequency
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BAND, CHANNELNUM] = getBandChannelFromCenterFreq(CENTERFREQ)
%   returns the frequency band and channel number corresponding to the
%   input channel center frequency. CENTERFREQ must correspond to a
%   supported channel number as used in wlan.internal.utils.getChannelMap. If an
%   unsupported CENTERFREQ is provided, the function returns empty values
%   for BAND and CHANNELNUM.
%
%   BAND is the operating frequency band in GHz.
%
%   CHANNELNUM is a positive integer, specifiying a channel number.
%
%   CENTERFREQ is the operating channel center frequency in Hz.

%   Copyright 2025 The MathWorks, Inc.

% Channels 1-13 are supported in the 2.4 GHz band. The center frequencies
% corresponding to these channels are considered as the lower (2412 MHz)
% and upper bounds (2472 MHz) respectively for a center frequency in this
% band.
if centerFreq >= 2412*1e6 && centerFreq <= 2472*1e6
    band = 2.4;
    % Equation 19-87, Section 19.3.15.2 of IEEE Std 802.11-2020
    channelNum = (centerFreq - 2407e6)/5e6;

% Subset of channels in the range 36-177 are supported in the 5 GHz band.
% The center frequencies corresponding to these channels are considered as
% the lower (5180 MHz) and upper bounds (5885 MHz) respectively for a
% center frequency in this band.
elseif centerFreq >= 5180*1e6 && centerFreq <= 5885*1e6
    band = 5;
    % Equation 19-88, Section 19.3.15.3 of IEEE Std 802.11-2020
    channelNum = (centerFreq - 5000e6)/5e6;

% Subset of channels in the range 1-233 are supported in the 6 GHz band.
% The center frequencies corresponding to channel 2 and channel 233 are
% considered as the lower (5935 MHz) and upper bounds (7115 MHz)
% respectively for a center frequency in this band.
elseif centerFreq >= 5935*1e6 && centerFreq <= 7115*1e6
    band = 6;
    % Table E-4, Annex E, IEEE Std 802.11ax-2021, starting frequency is
    % different for Channel 2 in 6 GHz
    if centerFreq == 5935e6
        channelStartingFrequency = 5925e6;
    else % For channel numbers 1-233, except 2
        channelStartingFrequency = 5950e6;
    end
    channelNum = (centerFreq - channelStartingFrequency)/5e6;
else % Empty defaults for unsupported center frequency
    band = [];
    channelNum = [];
end
end
