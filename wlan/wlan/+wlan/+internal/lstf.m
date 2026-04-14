function y = lstf(cfgFormat,varargin)
%lstf Non-HT Short Training Field (L-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = lstf(CFGFORMAT) generates the non-HT Short Training Field (L-STF)
%   time-domain signal for the VHT, HT-Mixed, non-HT OFDM, and WUR
%   transmission formats.
%
%   Y is the time-domain L-STF signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>,
%   <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, <a
%   href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>, or <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>, which specifies the
%   parameters for the VHT, HT-Mixed, non-HT OFDM, and WUR formats,
%   respectively. Only OFDM modulation is supported for a wlanNonHTConfig
%   object input.
%
%   Y = lstf(CFGFORMAT,OSF) generates the oversampled L-STF. OSF is the
%   oversampling factor. OSF must be >=1. The resultant IFFT length must be
%   even. The default is 1.
%
%   See also wlanVHTConfig, wlanHTConfig, wlanNonHTConfig, wlanWURConfig,
%   wlanLSTF.

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

if nargin>1
    osf = varargin{1};
else
    osf = 1;
end

% Map subcarriers and replicate over subchannels
LSTF = [zeros(6,1); wlan.internal.lstfSequence(); zeros(5,1)];

% Specify FFT parameters directly for codegen
[fftLen,numSubchannels] = wlan.internal.cbw2nfft(cfgFormat.ChannelBandwidth);
numTones = 12*numSubchannels;

sym = repmat(LSTF,numSubchannels,1); % Replicate for each BW

% Apply gamma rotation, replicate over antennas and apply cyclic shifts
[lstf,scalingFactor] = wlan.internal.legacyFieldMap(sym,numTones,cfgFormat);

% OFDM modulate
modOut = wlan.internal.ofdmModulate(lstf,0,osf); % 0 CP length
y = [modOut; modOut; modOut(1:fftLen*osf/2,:)]*scalingFactor;

end

