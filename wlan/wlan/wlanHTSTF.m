function y = wlanHTSTF(cfgHT,varargin)
%wlanHTSTF HT Short Training Field (HT-STF)
%
%   Y = wlanHTSTF(CFGHT) generates the HT Short Training Field (HT-STF)
%   time-domain signal for the HT-Mixed transmission format.
%
%   Y is the time-domain HT-STF signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   CFGHT is the format configuration object of type wlanHTConfig which
%   specifies the parameters for the HT-Mixed format.
%
%   Y = wlanHTSTF(CFGHT,'OversamplingFactor',OSF) generates the HT-STF
%   oversampled by a factor OSF. OSF must be >=1. The resultant IFFT length
%   must be even. The default is 1.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(1,3);
validateattributes(cfgHT, {'wlanHTConfig'}, {'scalar'}, mfilename, ...
                   'HT-Mixed format configuration object');
validateConfig(cfgHT, 'SMapping'); 

osf = wlan.internal.parseOSF(varargin{:});

numSTS = cfgHT.NumSpaceTimeStreams;

% OFDM parameters (use HT-LTF but ignore CP length)
ofdm = wlan.internal.vhtOFDMInfo('HT-LTF', cfgHT.ChannelBandwidth, 1);

% Non-HT L-STF (IEEE Std:802.11-2012, pg 1695)
HTSTF = wlan.internal.lstfSequence();

NHTFtones = 12*ofdm.NumSubchannels;  % as per Table 20-8, Std 802.11-2012
htf = [zeros(6,1); HTSTF; zeros(5,1)];

% Replicate over channel bandwidth & numSTS, and apply phase rotation
gamma = wlan.internal.vhtCarrierRotations(ofdm.NumSubchannels);
htfMIMO = repmat(htf, ofdm.NumSubchannels, 1, numSTS) .* gamma;

% Cyclic shift applied per STS
csh = wlan.internal.getCyclicShiftVal('VHT', numSTS, 20*ofdm.NumSubchannels);
htfCycShift = wlan.internal.cyclicShift(htfMIMO, csh, ofdm.FFTLength);

% Spatial mapping
htfSpatialMapped = wlan.internal.spatialMap(htfCycShift, cfgHT.SpatialMapping, cfgHT.NumTransmitAntennas, cfgHT.SpatialMappingMatrix);

% OFDM modulation
out = wlan.internal.ofdmModulate(htfSpatialMapped,[ofdm.CPLength 0],osf);
y = out * (ofdm.FFTLength/sqrt(NHTFtones*numSTS));

end
