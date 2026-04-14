function y = ehtLSTF(cfgEHT,varargin)
%ehtLSTF Legacy Short Training Field (L-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtLSTF(CFGEHT) generates the legacy Short Training Field (L-STF)
%   time-domain signal for the EHT transmission format.
%
%   Y is the time-domain L-STF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   Y = ehtLSTF(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

osf = 1;
if nargin>1
    osf = varargin{1};
end

LSTF = wlan.internal.lstfSequence();

% Number of tone used for scaling the signal. IEEE P802.11be/D2.0, Table 36-26
chBW = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
N_LSTF_TONE = wlan.internal.heToneScalingFactor('L-STF',chBW);
N_LLTF_TONE = wlan.internal.heToneScalingFactor('L-LTF',chBW);
N_LSIG_TONE = wlan.internal.heToneScalingFactor('L-SIG',chBW);
epsilon = sqrt(N_LLTF_TONE/N_LSIG_TONE); % Power scaling factor

% Mapping
cfgOFDM = wlan.internal.hePreHEOFDMConfig(cfgEHT.ChannelBandwidth);
Nfft = cfgOFDM.FFTLength*osf;
num20 = cfgOFDM.NumSubchannels;
LSTF = [zeros(6,1); LSTF; zeros(5,1)];
symOFDM = repmat(LSTF,num20,1); % Replicate for each bandwidth
[lstf,scalingFactor] = wlan.internal.ehtPreEHTFieldMap(symOFDM,N_LSTF_TONE,cfgEHT);

% OFDM modulate
modOut = wlan.internal.ofdmModulate(lstf,0,varargin{:}); % 0 CP length
out = [modOut; modOut; modOut(1:Nfft/2,:)];
if strcmp(packetFormat(cfgEHT),'UHR-ELR')
    y = out*scalingFactor*epsilon*sqrt(2); % Section 38.3.14.1. IEEE P802.11bn/D0.1, January 2025
else
    y = out*scalingFactor*epsilon;
end

end
