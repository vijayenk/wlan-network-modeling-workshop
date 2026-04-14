function [y, bits] = wlanVHTSIGA(cfgVHT, varargin)
%wlanVHTSIGA VHT Signal A (VHT-SIG-A) field
%
%   [Y, BITS] = wlanVHTSIGA(CFGVHT) generates the VHT Signal A
%   (VHT-SIG-A) field time-domain waveform for the VHT transmission format.
%
%   Y is the time-domain VHT-SIG-A field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   BITS is the VHT-SIG-A signaling bits. It is an int8-typed, binary column
%   vector of length 48.
%
%   CFGVHT is the format configuration object of type wlanVHTConfig which
%   specifies the parameters for the VHT format.
%
%   Y = wlanVHTSIGA(CFGVHT,'OversamplingFactor',OSF) generates the
%   VHT-SIG-A oversampled by a factor OSF. OSF must be >=1. The resultant
%   cyclic prefix length in samples must be integer-valued for all symbols.
%   The default is 1.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(1,3);
validateattributes(cfgVHT, {'wlanVHTConfig'}, {'scalar'}, mfilename, ...
                   'VHT format configuration object');
cfgInfo = validateConfig(cfgVHT, 'SpatialMCSGID');

osf = wlan.internal.parseOSF(varargin{:});

coder.varsize('channelCoding',[1,4]);
channelCoding = getChannelCoding(cfgVHT);

% Validate the pre-VHT cyclic shifts against the number of transmit
% antennas chains
validateConfig(cfgVHT, 'CyclicShift');

% Total number of standard defined cyclic shifts for eight transmit antenna
% chains for the pre-VHT portion of the packet. IEEE Std 802.11-2016, Table
% 21-10.
numCyclicShift = 8;

% VHT-SIG-A1 structure - Table 22-12, IEEE Std 802.11ac-2013
% BW field
switch cfgVHT.ChannelBandwidth
    case 'CBW20'
        bw = [0 0];
    case 'CBW40'
        bw = [1 0];     % right-msb orientation
    case 'CBW80'
        bw = [0 1];     % right-msb orientation
    otherwise % 'CBW160', 'CBW80+80'
        bw = [1 1];
end

% STBC, NSTS/Partial AID fields
if cfgVHT.NumUsers == 1
    STBC = double(cfgVHT.STBC);
    STSAndPAID = [int2bit(cfgVHT.NumSpaceTimeStreams(1)-1, 3, false).', ...
                  int2bit(cfgVHT.PartialAID, 9, false).'];
else
    STBC = 0;
    STSAndPAID = zeros(1, 12);
    for u = 1:cfgVHT.NumUsers
        STSAndPAID(3*cfgVHT.UserPositions(u)+(1:3)) = ...
                    int2bit(cfgVHT.NumSpaceTimeStreams(u), 3, false).';
    end
end

% Preset TransmitPowerSaveNotAllowed to false
TransmitPowerSaveNotAllowed = 0;

% Assemble fields with reserved bits
vhtsiga1 = int8([bw 1 STBC int2bit(cfgVHT.GroupID, 6, false).', ...
            STSAndPAID, TransmitPowerSaveNotAllowed 1].');

% VHT-SIG-A2 structure - Table 22-12, IEEE Std 802.11ac-2013
% Guard interval bits
if strcmp(cfgVHT.GuardInterval, 'Long')
    b0_2  = 0;
    b1_2  = 0;
else % Short GI
    Nsym = cfgInfo.NumDataSymbols;
    b0_2 = 1;
    b1_2 = double((mod(Nsym, 10)==9));     
end

% Channel coding bits
% Update b3 for LDPC coding, once enabled
if cfgVHT.NumUsers == 1
    if strcmp(channelCoding{1}, 'BCC')
        b2_2 = 0;
        b3_2 = 0;
    else  % LDPC
        b2_2 = 1;
        b3_2 = cfgInfo.ExtraLDPCSymbol;     
    end
    b2Tob7 = [b2_2; b3_2; int2bit(cfgVHT.MCS(1), 4, false)];
else 
    MUCoding = ones(4, 1);
    for u = 1:cfgVHT.NumUsers
        MUCoding(cfgVHT.UserPositions(u)+1) = ...
                        double(strcmp(channelCoding{u}, 'LDPC'));
    end
    b2Tob7 = [MUCoding(1); cfgInfo.ExtraLDPCSymbol; MUCoding(2:4); 1];
end

% Set BEAMFORMED bit
b8 = ((cfgVHT.NumUsers == 1) && strcmp(cfgVHT.SpatialMapping, 'Custom') ...
      && cfgVHT.Beamforming) || (cfgVHT.NumUsers > 1);

% Concatenate the first 0-9 bits
vhtsiga2_09 = int8([b0_2; b1_2; b2Tob7; b8; 1]);

% Generate the CRC
crc = wlan.internal.crcGenerate([vhtsiga1; vhtsiga2_09]);

% VHT-SIG-A2 bits
vhtsiga2 = [vhtsiga2_09; crc; zeros(6,1,'int8')]; % 24 bits

% Concatenate the SIG-A1 and A2 fields together - 48 bits
bits = [vhtsiga1; vhtsiga2];

%% Process VHT-SIG-A bits

% Get OFDM parameters
numTx = cfgVHT.NumTransmitAntennas;
ofdm = wlan.internal.vhtOFDMInfo('VHT-SIG-A', cfgVHT.ChannelBandwidth, 1);

% Encoding, interleaving, constellation mapping according to Section 18.3.5
phRot = [0 pi/2]; % Rotate only 2nd symbol
dataSym = wlan.internal.vhtSIGAEncodeInterleaveMap(bits, phRot);

% Add pilot subcarriers, IEEE Std 802.11ac-2013, Eqn 22-28
z = 1;      % 2nd and 3rd pilot symbols
numSym = 2; 
pilots = wlan.internal.nonHTPilots(numSym, z);

% Pilot insertion according to Section 18.3.5.9, duplication and phase rotation
sym = complex(zeros(ofdm.FFTLength, numSym)); 
sym(ofdm.ActiveFFTIndices(ofdm.DataIndices),:) = repmat(dataSym, ofdm.NumSubchannels, 1);
sym(ofdm.ActiveFFTIndices(ofdm.PilotIndices),:) = repmat(pilots, ofdm.NumSubchannels, 1);
gamma = wlan.internal.vhtCarrierRotations(ofdm.NumSubchannels);
sym = sym .* gamma; % Apply to both sym

% Replicate VHT-SIG-A field over multiple antennas
vhtsigMIMO = repmat(sym, 1, 1, numTx);    

% Cyclic shift addition
csh = wlan.internal.getCyclicShiftSamples(20*ofdm.NumSubchannels, numTx, numCyclicShift, cfgVHT.PreVHTCyclicShifts);
vhtCycShift = wlan.internal.cyclicShift(vhtsigMIMO, csh, ofdm.FFTLength);

wout = wlan.internal.ofdmModulate(vhtCycShift, ofdm.CPLength, osf);
y  = wout * ofdm.FFTLength/sqrt(numTx*ofdm.NumTones);

end
