function y = ehtLLTF(cfgEHT,varargin)
%ehtLLTF Legacy Long Training Field (L-LTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtLLTF(CFGEHT) generates the Legacy Long Training Field (L-LTF)
%   time-domain signal for the EHT transmission format.
%
%   Y is the time-domain L-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   Y = ehtLLTF(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
LLTF = [zeros(6,1); lltfLower; 0; lltfUpper; zeros(5,1)];

% Number of tone used for scaling the signal. IEEE P802.11be/D2.0 Table 36-26
cfgOFDM = wlan.internal.hePreHEOFDMConfig(cfgEHT.ChannelBandwidth,'L-LTF');
chBW = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
N_LLTF_TONE = cfgOFDM.NumTones;
N_LSIG_TONE = wlan.internal.heToneScalingFactor('L-SIG',chBW);
epsilon = sqrt(N_LLTF_TONE/N_LSIG_TONE);

% Replicate L-LTF sequence for each 20 MHz bandwidth
symOFDM = repmat(LLTF,cfgOFDM.NumSubchannels,1);
[lltf,scalingFactor] = wlan.internal.ehtPreEHTFieldMap(symOFDM,N_LLTF_TONE,cfgEHT);

% OFDM modulate
out = wlan.internal.ofdmModulate([lltf lltf],[cfgOFDM.FFTLength/2 0],varargin{:});
if strcmp(packetFormat(cfgEHT),'UHR-ELR')
    y = out*scalingFactor*epsilon*sqrt(2); % Section 38.3.14.1. IEEE P802.11bn/D0.1, January 2025
else
    y = out*scalingFactor*epsilon;
end
