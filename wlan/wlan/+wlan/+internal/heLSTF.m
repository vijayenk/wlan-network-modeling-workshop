function y = heLSTF(cfgHE,varargin)
%heLSTF Non-HT Short Training Field (L-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heLSTF(CFGHE) generates the Non-HT Short Training Field (L-STF)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain L-STF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heLSTF(CFGHE,OSF) generates the L-STF for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   Example: Generate an L-STF field for an 80MHz single user PPDU format
%
%     cfgHE = wlanHESUConfig('ChannelBandwidth','CBW80');
%     y = wlan.internal.heLSTF(cfgHE);
%     plot(abs(y));
%
%   See also wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

LSTF = wlan.internal.lstfSequence();

% Number of tone used for scaling the signal
% Ref: IEEE P802.11ax/D4.1, Table 27-16
chBW = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);
N_LSTF_TONE = wlan.internal.heToneScalingFactor('L-STF',chBW);
N_LLTF_TONE = wlan.internal.heToneScalingFactor('L-LTF',chBW);
N_LSIG_TONE = wlan.internal.heToneScalingFactor('L-SIG',chBW);
epsilon = sqrt(N_LLTF_TONE/N_LSIG_TONE); % Power scaling factor

extendedRangeSF = 1;
if strcmp(packetFormat(cfgHE),'HE-EXT-SU')
    % For HE extended range
    extendedRangeSF = sqrt(2);
end

% Mapping
osf = 1;
if nargin>1
    osf = varargin{1};
end
cfgOFDM  = wlan.internal.hePreHEOFDMConfig(cfgHE.ChannelBandwidth);
Nfft     = cfgOFDM.FFTLength*osf;
num20    = cfgOFDM.NumSubchannels;
LSTF     =  [zeros(6,1); LSTF; zeros(5,1)];
symOFDM  = repmat(LSTF,num20,1); % Replicate for each BW
[lstf,scalingFactor] = wlan.internal.hePreHEFieldMap(symOFDM,N_LSTF_TONE,cfgHE);

% OFDM modulate
modOut = wlan.internal.ofdmModulate(lstf,0,varargin{:}); % 0 CP length
out = [modOut; modOut; modOut(1:Nfft/2,:)];
y = out*scalingFactor*epsilon*extendedRangeSF;

end
