function [y, bits] = s1gSIG(cfgS1G,varargin)
%s1gSIG S1G SIGNAL (S1G-SIG) field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,BITS] = s1gSIG(CFGS1G) generates the S1G SIGNAL (S1G-SIG) field
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
%   Y = s1gSIG(cfgS1G,OSF) generates the S1G-SIG for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   Example: 
%   %  Generate the S1G SIG waveform for a 4MHz transmission format
%
%      cfgS1G = wlanS1GConfig;              % Format configuration
%      cfgS1G.ChannelBandwidth = 'CBW4';    % Set to 4MHz
%      sigOut = s1gSIG(cfgS1G);
%
%   See also wlanS1GConfig.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GLong');
validateConfig(cfgS1G,'SMappingMCSTPilotsID');

% Bits 0-36 are either signaling bits or the CMAC body based on
% NDPIndication. Only support signaling bits at preset.
bodyBits = wlan.internal.s1gSignalingBits(cfgS1G);

% Generate the CRC
numBits = 4; % IEEE P802.11ah/D5.0, Section 24.3.8.2.1.5
crc = wlan.internal.crcGenerate(bodyBits,numBits);

% Concatenate signaling bits, NDP indication bit, CRC bits and tail bits
bits = [bodyBits; crc; zeros(6,1,'int8')];

% Get OFDM parameters
chanBW = cfgS1G.ChannelBandwidth;
numSTS = cfgS1G.NumSpaceTimeStreams(1);
cfgOFDM = wlan.internal.s1gOFDMConfig(chanBW,'Long','SIG',numSTS);

if strcmp(packetFormat(cfgS1G),'S1G-1M') % 1 MHz SIG
    % Encode according to Section 18.3.5.6
    encodedSIG  = wlanBCCEncode(bits,'1/2');

    % Repetition coding according to Section 24.3.9.5
    repeatedSIG = wlan.internal.repetitionForMCS10(encodedSIG);

    % Interleaving according to 1 MHz MCS 10 flow
    numSym = 6;   % Number of OFDM symbols
    numBPSCS = 1; % Modulation order
    numCBPS = 24; % Number of coded bits per symbol; 144 bits in 6 symbols
    interleaveFormat = 'VHT'; % VHT interleaver for 1 MHz mode (Table 24-20)
    numSS = 1; % 1 spatial stream
    interleavedData = wlanBCCInterleave(repeatedSIG,interleaveFormat,numCBPS,chanBW);

    % BPSK constellation mapping according to Section 18.3.5.8
    dataSym = wlanConstellationMap(interleavedData,numBPSCS);
    
    % Reshape to form OFDM symbols
    dataSym = reshape(dataSym,numCBPS/numBPSCS,numSym,numSS);

    n = (0:numSym-1).';
    z = 0; % First pilot
    pilots = wlan.internal.vhtPilots(n,z,chanBW,numSS);
else % Short preamble >= 2 MHz SIG
    % Encoding, interleaving and constellation mapping according to Section
    % 18.3.5.6/7/8
    phRot = pi/2; % Both symbols rotated: [QBPSK QBPSK]
    dataSym = wlan.internal.vhtSIGAEncodeInterleaveMap(bits,phRot);
    % Pilots according to Section 18.3.5.9
    numSym = 2;
    z = 0; % First pilot
    pilots = wlan.internal.nonHTPilots(numSym,z);
end

% Pilot insertion, duplication over bandwidth and phase rotation
sym = complex(zeros(cfgOFDM.FFTLength,numSym)); 
Nsubchan = ceil(cfgOFDM.FFTLength/64);
sym(cfgOFDM.DataIndices,:) = repmat(dataSym,Nsubchan,1); 
sym(cfgOFDM.PilotIndices,:) = repmat(pilots(:,:,1),Nsubchan,1); % Index for codegen
sym = sym .* cfgOFDM.CarrierRotations;

% Get P_HTLTF mapping matrix
Phtltf = wlan.internal.mappingMatrix(numSTS);
Pd = Phtltf(1:numSTS,1).'; % First column of P matrix

% Replicate SIG field over multiple space-time streams
sigMIMO = repmat(sym,1,1,numSTS);

% Apply orthogonal mapping matrix
sigMIMO = sigMIMO .* permute(Pd,[3 1 2]);

% Cyclic shift addition per space-time stream
csh = wlan.internal.getCyclicShiftVal('S1G',numSTS,wlan.internal.cbwStr2Num(chanBW));
sigCycShift = wlan.internal.cyclicShift(sigMIMO,csh,cfgOFDM.FFTLength);

% Apply spatial mapping
sigSpatialMapped = wlan.internal.spatialMap(sigCycShift, ...
    cfgS1G.SpatialMapping,cfgS1G.NumTransmitAntennas,cfgS1G.SpatialMappingMatrix);

% OFDM Modulation
y = wlan.internal.ofdmModulate(sigSpatialMapped,cfgOFDM.CyclicPrefixLength,varargin{:})*cfgOFDM.NormalizationFactor;

end
