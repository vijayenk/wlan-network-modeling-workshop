function y = heLLTF(cfgHE,varargin)
%heLLTF Non-HT Long Training Field (L-LTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heLLTF(CFGHE) generates the Non-HT Long Training Field (L-LTF)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain L-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heLLTF(CFGHE,OSF) generates the L-LTF for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   Example: Generate an L-LTF field for an 40MHz single user PPDU format
%
%     cfgHE = wlanHESUConfig('ChannelBandwidth','CBW40');
%     y = wlan.internal.heLLTF(cfgHE);
%     plot(abs(y));
%
%   See also wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
LLTF = [zeros(6,1); lltfLower; 0; lltfUpper; zeros(5,1)];

% Number of tone used for scaling the signal. IEEE P802.11ax/D4.1, Table 27-16
cfgOFDM     = wlan.internal.hePreHEOFDMConfig(cfgHE.ChannelBandwidth,'L-LTF');
chBW        = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);
N_LLTF_TONE = cfgOFDM.NumTones;
N_LSIG_TONE = wlan.internal.heToneScalingFactor('L-SIG',chBW);
epsilon     = sqrt(N_LLTF_TONE/N_LSIG_TONE);

extendedRangeSF = 1;
if strcmp(packetFormat(cfgHE),'HE-EXT-SU')
    % For HE extended range
    extendedRangeSF = sqrt(2);
end

% Replicate L-LTF sequence for each 20MHz BW
symOFDM = repmat(LLTF,cfgOFDM.NumSubchannels,1); 
[lltf,scalingFactor] = wlan.internal.hePreHEFieldMap(symOFDM,N_LLTF_TONE,cfgHE);

% OFDM modulate
out = wlan.internal.ofdmModulate([lltf lltf],[cfgOFDM.FFTLength/2 0],varargin{:});
y = out*scalingFactor*epsilon*extendedRangeSF;

end
