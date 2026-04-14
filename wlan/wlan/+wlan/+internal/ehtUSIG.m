function [y,bits] = ehtUSIG(cfgEHT,varargin)
%ehtUSIG U-SIG Field (U-SIG)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,BITS] = ehtUSIG(CFGEHT) generates the U-SIG field time-domain signal
%   for the EHT transmission format.
%
%   Y is the time-domain U-SIG signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   BITS are the U-SIG signaling bits of size 52-by-L It is of type int8. L
%   is the number of 80 MHz segments in the given bandwidth. L is 1 for
%   CBW20, CBW40, and CBW80. L is 2 and 4 for CBW160 and CBW320.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   Y = ehtUSIG(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

% Fixed encoding parameters for U-SIG, IEEE P802.11be/D2.0, Section 36.3.12.7
ruSizeInterleave = 56;
numBPSCS = 1;
numNDBPS = 26; % Number of data bits in each symbols
numCBPS = numNDBPS*2;
numBPSSI = numCBPS;
Nsym = 2; % Number of U-SIG symbols

cbw = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
num80 = 1; % Number of 80 MHz segments
switch cbw
    case 20
        num20Per80 = 1; % Number of 20 MHz segments per 80 MHz
    case 40
        num20Per80 = 2;
    otherwise
        num20Per80 = 4;
        num80 = cbw/80; % Number of 80 MHz segment
end

% Generate U-SIG bits
usigBitsPerSegment = wlan.internal.ehtUSIGBits(cfgEHT,num80);
bits = zeros(numCBPS,num80,'int8');
sym = complex(zeros(numCBPS*num20Per80*num80,Nsym));

for s=1:num80
    crcVal = wlan.internal.crcGenerate(usigBitsPerSegment(:,s));
    bits(:,s) = [usigBitsPerSegment(:,s); crcVal(1:4); zeros(6,1)]; % C4 to C7 with C7 first + tail bits

    % Encode, interleave and map
    encodedSIG = wlanBCCEncode(bits(:,s),'1/2');
    interleavedData = wlan.internal.heBCCInterleave(encodedSIG,ruSizeInterleave,numBPSCS,numBPSSI,false);
    symMap = wlanConstellationMap(reshape(interleavedData,numCBPS,Nsym),numBPSCS);

    % Replicate over 20 MHz segment within each 80 MHz segment
    sym((1:numCBPS*num20Per80)+numCBPS*num20Per80*(s-1),:) = repmat(symMap,num20Per80,1);
end

% Add pilots
% Setup for pilot symbols offset and number of pilot symbols in each format
z = 2; % Number of offset for the pilot symbols
pilots = wlan.internal.nonHTPilots(Nsym,z);

% Pilot and data mapping
cfgOFDM = wlan.internal.hePreHEOFDMConfig(cfgEHT.ChannelBandwidth);
num20 = cfgOFDM.NumSubchannels;
cpLen = cfgOFDM.CyclicPrefixLength;
N_USIG_TONE = cfgOFDM.NumTones;
symOFDM = complex(zeros(cfgOFDM.FFTLength,Nsym));
symOFDM(cfgOFDM.DataIndices,:) = sym;
symOFDM(cfgOFDM.PilotIndices,:) = repmat(pilots,num20,1); % Replicate over 20 MHz subchannels
[ehtwUSIG,scalingFactor] = wlan.internal.ehtPreEHTFieldMap(symOFDM,N_USIG_TONE,cfgEHT);

% OFDM modulate
wout = wlan.internal.ofdmModulate(ehtwUSIG,cpLen,varargin{:});
y = wout*scalingFactor;

end
