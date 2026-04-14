function [y, bits] = wurBPSKMark1(cfgFormat,varargin)
%wurBPSKMark1 A BPSK Modulated OFDM Symbol (WUR BPSK-Mark1 field)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, BITS] = wurBPSKMark1(CFGFORMAT) generates the BPSK Modulated OFDM
%   time-domain signal (BPSK-Mark1 field) for the WUR PPDU formats.
%
%   Y is the time-domain BPSK-Mark1 field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   BITS contains the signaling bits used for the BPSK-Mark1 field in an
%   int8-typed binary column vector of length 24.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU formats.
%
%   [Y, BITS] = wurBPSKMark1(CFGFORMAT,OSF) generates the BPSK-Mark1 field
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.
%
%   See also wlanWURConfig.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

% Set the RATE value to 4 bit binary code. The code value is fixed
% to [1 1 0 1] representing 6Mb/s in legacy 20 MHz CBW.
% See IEEE P802.11ba/D8.0, December 2020, Section 30.3.9.2.4
R = [1; 1; 0; 1];
params = wlan.internal.wurTxTime(cfgFormat);

% Construct the SIGNAL field. Length parameter with LSB first, which is 12 bits
lengthBits = int2bit(params.LSIGLength,12,false);

% Even parity bit
parityBit = mod(sum([R;lengthBits],1),2);

% The SIGNAL field (IEEE Std 802.11-2016, Section 17.3.4.2)
bits = [R; 0; lengthBits; parityBit; zeros(6,1,'int8')];

% Process BPSKMark1 bits
encodedBits = wlanBCCEncode(bits,'1/2');
interleavedBits = wlanBCCInterleave(encodedBits,'Non-HT',48);

% XOR operation (IEEE 802.11ba/D8.0, December 2020, Section 30.3.5.5)
xorinterleavebits = bitxor(interleavedBits,1);
modData = wlanConstellationMap(xorinterleavebits,1);

% Add pilot symbols, from IEEE Std 802.11-2016, Equation 19-14
Nsym = 1; % One symbol
z = 1;    % Second pilot value used, from IEEE 802.11ba/D8.0, December 2020, Equation 30-7
modPilots = wlan.internal.nonHTPilots(Nsym,z);

% Generate the BPSKMark1 field
y = wlan.internal.lsigModulate(modData,modPilots,cfgFormat,varargin{:});

end
