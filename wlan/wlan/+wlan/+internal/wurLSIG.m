function [y, bits] = wurLSIG(cfgFormat,varargin)
%wurLSIG Non-HT SIGNAL field (L-SIG)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, BITS] = wurLSIG(CFGFORMAT) generates the non-HT SIGNAL field
%   (L-SIG) time-domain signal for the WUR PPDU formats.
%
%   Y is the time-domain L-SIG field signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   BITS is the signaling bits used for the non-HT SIGNAL field. It is
%   an int8-typed, binary column vector of length 24.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU formats.
%
%   [Y, BITS] = wurLSIG(CFGFORMAT,OSF) generates the L-SIG oversampled by a
%   factor OSF. OSF must be >=1. The resultant cyclic prefix length in
%   samples must be integer-valued for all symbols. The default is 1.
%
%   See also wlanWURConfig.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

% Set the RATE value to 4 bit binary code. The code value is fixed
% to [1 1 0 1] representing 6Mb/s in legacy 20 MHz CBW.
% See IEEE P802.11ba/D8.0, December 2020, Section 30.3.9.2.3
R = [1; 1; 0; 1];
params = wlan.internal.wurTxTime(cfgFormat);

% Construct the SIGNAL field. Length parameter with LSB first, which is 12 bits
lengthBits = int2bit(params.LSIGLength,12,false);

% Even parity bit
parityBit = mod(sum([R;lengthBits],1),2);

% The SIGNAL field (IEEE Std 802.11-2016, Section 17.3.4.2)
bits = [R; 0; lengthBits; parityBit; zeros(6,1,'int8')];

% Process L-SIG bits
encodedBits = wlanBCCEncode(bits,'1/2');
interleavedBits = wlanBCCInterleave(encodedBits,'Non-HT',48);
modData = wlanConstellationMap(interleavedBits,1);

% Add pilot symbols, from IEEE Std 802.11-2016, Equation 19-14
Nsym = 1; % One symbol
z = 0;    % No offset as first symbol is with pilots
modPilots = wlan.internal.nonHTPilots(Nsym,z);

% Generate the L-SIG field
y = wlan.internal.lsigModulate(modData,modPilots,cfgFormat,varargin{:});

end
