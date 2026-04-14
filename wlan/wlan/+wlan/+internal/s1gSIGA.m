function [y, bits] = s1gSIGA(cfgS1G,varargin)
%s1gSIGA S1G-A SIGNAL (S1G-SIG-A) field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,BITS] = s1gSIGA(CFGS1G) generates the S1G SIGNAL (S1G-SIG) field
%   time-domain waveform for the S1G transmission format.
%
%   Y is the time-domain SIG field signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   BITS is the signaling bits used for the S1G SIGNAL field. It is an
%   int8-typed, binary column vector of length 48.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gSIGA(cfgS1G,OSF) generates the S1G-SIG for the given
%   oversampling factor OSF. When not specified 1 is assumed.
%
%   Example: 
%   %  Generate the S1G SIG-A waveform for a 4MHz transmission format
%
%      cfgS1G = wlanS1GConfig;              % Format configuration
%      cfgS1G.ChannelBandwidth = 'CBW4';    % Set to 4MHz
%      sigOut = s1gSIGA(cfgS1G);
%
%   See also wlanS1GConfig.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

narginchk(1,2);

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(~strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GShort1M');
validateConfig(cfgS1G,'SpatialMCSTPilotsID');

% Get signaling bits
sigBits = wlan.internal.s1gSignalingBits(cfgS1G);

% Generate the CRC
numBits = 4; % IEEE P802.11ah/D5.0, Section 24.3.8.2.1.5
crc = wlan.internal.crcGenerate(sigBits,numBits);

% Concatenate signaling bits, NDP indication bit, CRC bits and tail bits
bits = [sigBits; crc; zeros(6,1,'int8')];

numSym = 2;
z = 0; % First pilot
pilots = wlan.internal.nonHTPilots(numSym,z);

% Cyclic shift
csh = wlan.internal.getCyclicShiftVal('S1G',cfgS1G.NumTransmitAntennas, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));
phRot = [pi/2 0]; % Only first symbol rotated: [QBPSK BPSK]
% Encoding, interleaving and constellation mapping according to Section
% 18.3.5.6/7/8
dataSym = wlan.internal.vhtSIGAEncodeInterleaveMap(bits,phRot);

% Get OFDM parameters
cfgOFDM = wlan.internal.s1gOFDMConfig(cfgS1G.ChannelBandwidth,'Long', ...
    'SIG-A',cfgS1G.NumTransmitAntennas);

% Pilot insertion according to Section 18.3.5.9, duplication over full
% bandwidth and phase rotation
Nsubchan = ceil(cfgOFDM.FFTLength/64);
sym = complex(zeros(cfgOFDM.FFTLength,numSym)); 
sym(cfgOFDM.DataIndices,:) = repmat(dataSym,Nsubchan,1);
sym(cfgOFDM.PilotIndices,:) = repmat(pilots,Nsubchan,1);
sym = sym .* cfgOFDM.CarrierRotations; % Same rotation for both symbols

% Replicate SIG field over multiple transmit antennas
sigMIMO  = repmat(sym,[1 1 cfgS1G.NumTransmitAntennas]);

% Cyclic shift addition
% The cyclic shift is applied per transmit antenna.
sigCycShift = wlan.internal.cyclicShift(sigMIMO,csh,cfgOFDM.FFTLength);

% OFDM modulation
wout = wlan.internal.ofdmModulate(sigCycShift,cfgOFDM.CyclicPrefixLength,varargin{:});
y  = wout*cfgOFDM.NormalizationFactor;

end
