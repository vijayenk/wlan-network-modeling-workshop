function y = lltf(cfgFormat,varargin)
%lltf Non-HT Long Training Field (L-LTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = lltf(CFGFORMAT) generates the non-HT Long Training Field (L-LTF)
%   time-domain signal for the VHT, HT-Mixed, non-HT OFDM, and WUR
%   transmission formats.
%
%   Y is the time-domain L-LTF signal. It is a complex matrix of size
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
%   Y = lltf(CFGFORMAT,OSF) generates the L-LTF oversampled by a factor
%   OSF. OSF must be >=1. The resultant cyclic prefix length in samples
%   must be integer-valued for all symbols. The default is 1.
%
%   See also wlanVHTConfig, wlanHTConfig, wlanNonHTConfig, wlanWURConfig,
%   wlanLLTF.

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
LLTF = [zeros(6,1); lltfLower; 0; lltfUpper; zeros(5,1)];

% Specify FFT parameters directly for codegen
[fftLen,numSubchannels] = wlan.internal.cbw2nfft(cfgFormat.ChannelBandwidth);
numTones = 52*numSubchannels;

% Replicate L-LTF sequence for each 20MHz subchannel
sym = repmat(LLTF,numSubchannels,1);

% Apply gamma rotation, replicate over antennas and apply cyclic shifts
[lltf,scalingFactor] = wlan.internal.legacyFieldMap(sym,numTones,cfgFormat);

% OFDM modulate with double length GI for first symbol, no GI for second
out = wlan.internal.ofdmModulate([lltf lltf],[fftLen/2 0],varargin{:});
y = out*scalingFactor;

end
