function [y, bits] = wlanLSIG(cfgFormat,varargin)
%wlanLSIG Non-HT SIGNAL field (L-SIG)
%   [Y, BITS] = wlanLSIG(CFGFORMAT) generates the non-HT SIGNAL field
%   (L-SIG) time-domain signal for the VHT, HT-Mixed, and non-HT OFDM
%   transmission formats.
%
%   Y is the time-domain L-SIG field signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   BITS is the signaling bits used for the non-HT SIGNAL field. It is
%   an int8-typed, binary column vector of length 24.
%
%   CFGFORMAT is the format configuration object of type wlanVHTConfig, 
%   wlanHTConfig, or wlanNonHTConfig, which specifies the parameters for
%   the VHT, HT-Mixed, and non-HT OFDM formats, respectively. Only OFDM 
%   modulation is supported for a wlanNonHTConfig object input.
%
%   Y = wlanLSIG(CFGFORMAT,'OversamplingFactor',OSF) generates the L-SIG
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);

% Validate the format configuration object
validateattributes(cfgFormat, {'wlanVHTConfig', 'wlanHTConfig', ...
    'wlanNonHTConfig'}, {'scalar'}, 'wlanLSIG', ...
    'format configuration object');

osf = wlan.internal.parseOSF(varargin{:});

if isa(cfgFormat, 'wlanVHTConfig')
    % Validate VHT configuration
    s = validateConfig(cfgFormat, 'MCSSTSTx');
    txTime = s.TxTime;

    % Set the RATE value to 4 bit binary code. The code value is fixed
    % to [1 1 0 1] representing 6Mb/s in legacy 20MHz CBW.
    % As per 22.3.8.2.4, p/256, IEEE Std 802.11ac-2013.
    R = [1; 1; 0; 1];
    length = ceil((txTime - 20)/4)*3 - 3;

elseif isa(cfgFormat, 'wlanHTConfig')
    % Validate HT configuration
    s = validateConfig(cfgFormat, 'MCSSTSTx');
    txTime = s.TxTime;

    % Set the RATE value to 4 bit binary code. The code value is fixed
    % to [1 1 0 1] representing 6Mb/s in legacy 20MHz CBW.
    % As per Sec. 20.2.9.3.6 and Sec. 9.23.4, IEEE Std 802.11-2012
    R = [1; 1; 0; 1];
    % Assuming signalExtension = 0, from Sec 9.23.4.
    length = ceil((txTime - 20)/4)*3 - 3;

elseif isa(cfgFormat, 'wlanNonHTConfig')
    % Only applicable for OFDM and DUP-OFDM modulations
    coder.internal.errorIf( ~strcmp(cfgFormat.Modulation, 'OFDM'), ...
        'wlan:wlanLSIG:InvalidNonHTLSIG');
    validateConfig(cfgFormat);

    R = wlan.internal.nonHTRateSignalBits(cfgFormat.MCS);
    length = cfgFormat.PSDULength;
end

% Construct the SIGNAL field. Length parameter with LSB first, which is 12 bits
lengthBits = int2bit(length,12,false);

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
y = wlan.internal.lsigModulate(modData,modPilots,cfgFormat,osf);

end

