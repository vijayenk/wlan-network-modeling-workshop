function [y, bits] = wlanHTSIG(cfgHT,varargin)
%wlanHTSIG HT SIGNAL (HT-SIG) field
%
%   [Y, BITS] = wlanHTSIG(CFGHT) generates the HT SIGNAL (HT-SIG)
%   field time-domain waveform for the HT-Mixed transmission format.
%
%   Y is the time-domain HT-SIG field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   BITS is the signaling bits used for the HT SIGNAL field. It is an
%   int8-typed, binary column vector of length 48.
%
%   CFGHT is the format configuration object of type wlanHTConfig which
%   specifies the parameters for the HT-Mixed format.
%
%   Y = wlanHTSIG(CFGHT,'OversamplingFactor',OSF) generates the HT-SIG
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(1,3);

% Validate input HT format
validateattributes(cfgHT, {'wlanHTConfig'}, {'scalar'}, mfilename, ...
                   'HT-Mixed format configuration object');
validateConfig(cfgHT, 'MCSSTSTx'); % MCS, Length, STS, Tx

% Validate the pre-HT cyclic shifts against the number of transmit antennas
% chains
validateConfig(cfgHT, 'CyclicShift');

osf = wlan.internal.parseOSF(varargin{:});

% Total number of standard defined cyclic shifts for four transmit antenna
% chains for the pre-HT portion of the packet. IEEE Std 802.11-2016, Table
% 19-9.
numCyclicShift = 4;

%% Build the signaling bits
% HT-SIG1 structure
b17 = int2bit(cfgHT.MCS, 7, false);
switch cfgHT.ChannelBandwidth
    case {'CBW40'}
        b8 = 1;
    otherwise
        b8 = 0; % for 20MHz only, offset not implemented
end
b924 = int2bit(cfgHT.PSDULength, 16, false);

htsig1 = [b17; b8; b924]; % 24 bits

% HT-SIG2 structure
b1 = double(cfgHT.RecommendSmoothing);
b2 = double(cfgHT.PSDULength~=0);    % Not Sounding

% Set Aggregation bit
b4 = double(cfgHT.AggregatedMPDU);

% STBC value
Nss = floor(cfgHT.MCS/8)+1;
STBC = cfgHT.NumSpaceTimeStreams - Nss;
b56 = int2bit(STBC, 2, false);

b7 = double(strcmp(cfgHT.ChannelCoding, 'LDPC'));
b8 = double(strcmp(cfgHT.GuardInterval, 'Short'));
if wlan.internal.inESSMode(cfgHT)
    numESS = cfgHT.NumExtensionStreams;
else
    numESS = 0;
end
b910 = int2bit(numESS, 2, false);

% Concatenate the first 0-9 bits
htsig2_09 = [b1; b2; 1; b4; b56; b7; b8; b910];

% Generate the CRC
crc = wlan.internal.crcGenerate([htsig1; htsig2_09]);

% HT SIG2 bits
htsig2 = [htsig2_09; crc; zeros(6,1, 'int8')]; % 24 bits

% Concatenate the HT-SIG-1 and HT-SIG-2 fields together: 48 bits
bits = [htsig1; htsig2];

%% Process HT-SIG bits
encodedSIG  = wlanBCCEncode(bits, '1/2');
interleavedSIG = wlanBCCInterleave(encodedSIG, 'Non-HT', 48);
dataSym = wlanConstellationMap(interleavedSIG, 1, pi/2);

% Reshape to form OFDM symbols
dataSym = reshape(dataSym, 48, 2);

% Get OFDM parameters
ofdm = wlan.internal.vhtOFDMInfo('HT-SIG', cfgHT.ChannelBandwidth, 1);

firstSym = complex(zeros(ofdm.FFTLength,1)); 
secSym   = complex(zeros(ofdm.FFTLength,1)); 

% Add pilot subcarriers, from IEEE Std 802.11-2012, Eqn 20-17
firstSym(ofdm.ActiveFFTIndices(ofdm.DataIndices))   = repmat(dataSym(:,1), ofdm.NumSubchannels, 1);
Nsym = 1; % Create pilots symbol-by-symbol
z = 1;    % Offset by 1 to account for L-SIG pilot symbol
firstSym(ofdm.ActiveFFTIndices(ofdm.PilotIndices)) = repmat(wlan.internal.nonHTPilots(Nsym, z), ofdm.NumSubchannels, 1);
secSym(ofdm.ActiveFFTIndices(ofdm.DataIndices))    = repmat(dataSym(:,2), ofdm.NumSubchannels, 1);
z = 2; % Offset by 2 to account for L-SIG and first HT-SIG pilot symbols
secSym(ofdm.ActiveFFTIndices(ofdm.PilotIndices))   = repmat(wlan.internal.nonHTPilots(Nsym, z), ofdm.NumSubchannels, 1);

% Replicate over bandwidth, with tone rotation (gamma)
gamma = wlan.internal.vhtCarrierRotations(ofdm.NumSubchannels);
firstSymAll = firstSym .* gamma;
secSymAll   = secSym   .* gamma;

% Concatenate the two HT-SIG symbols and replicate over multiple transmit
% antennas
numTx = cfgHT.NumTransmitAntennas;
htsigMIMO = repmat([firstSymAll, secSymAll],[1 1 numTx]);

% Cyclic shift addition
csh = wlan.internal.getCyclicShiftSamples(20*ofdm.NumSubchannels, numTx, numCyclicShift, cfgHT.PreHTCyclicShifts);
htCycShift = wlan.internal.cyclicShift(htsigMIMO, csh, ofdm.FFTLength);

wout = wlan.internal.ofdmModulate(htCycShift, ofdm.CPLength, osf);
y  = wout * ofdm.FFTLength/sqrt(numTx*ofdm.NumTones);

end

