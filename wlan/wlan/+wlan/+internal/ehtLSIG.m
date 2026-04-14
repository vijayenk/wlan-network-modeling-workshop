function [y,bits] = ehtLSIG(cfgEHT,varargin)
%ehtLSIG Legacy SIGNAL Field (L-SIG)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtLSIG(CFGEHT) generates the Legacy SIGNAL Field (L-SIG)
%   time-domain signal for the EHT transmission format.
%
%   Y is the time-domain L-SIG signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   Y = ehtLSIG(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

% Set the RATE value to 4 bit binary code. The code value is fixed to [1 1
% 0 1] representing 6Mb/s in legacy 20 MHz CBW, IEEE P802.11be/D2.0 Section
% 36.3.12.5.
R = [1; 1; 0; 1];

% L-SIG length calculation.
if any(strcmp(packetFormat(cfgEHT),{'EHT-TB','UHR-TB'})) % EHT/UHR
    lsigLength = cfgEHT.LSIGLength+2;
else
    % L-SIG length calculation
    s = validateConfig(cfgEHT,'DataLocationLength');
    SignalExtension = 0;
    sf = 1e3; % Scaling factor to convert time from ns to us
    lsigLength = ceil((s.TxTime*sf-SignalExtension-20e3)/4e3)*3-3; % The IEEE P802.11be/D2.0, Equation 36-17
end

% Construct the SIGNAL field. Length parameter with LSB first, which is 12 bits
lengthBits = int2bit(lsigLength,12,false);

% Even parity bit
parityBit = mod(sum([R;lengthBits],1),2);

% The SIGNAL field (IEEE Std 802.11-2016, Section 17.3.4.2)
bits = [R; 0; lengthBits; parityBit; zeros(6,1,'int8')];

% Process L-SIG bits
encodedBits = wlanBCCEncode(bits,'1/2');
interleavedBits = wlanBCCInterleave(encodedBits,'Non-HT',48);
modData = wlanConstellationMap(interleavedBits,1);

% Data mapping with extra BPSK symbols
cfgOFDM = wlan.internal.hePreHEOFDMConfig(cfgEHT.ChannelBandwidth,'L-SIG');
num20 = cfgOFDM.NumSubchannels;
CPLen = cfgOFDM.CyclicPrefixLength;
N_LSIG_TONE = cfgOFDM.NumTones;
dataSymbol = complex(zeros(cfgOFDM.FFTLength,1));
dataSymbol(cfgOFDM.DataIndices,1) = repmat([-1; -1; modData; -1; 1],num20,1);

% Add pilot symbols, from IEEE Std 802.11-2016, Equation 19-14
Nsym = 1; % One symbol
z = 0; % No offset as first symbol is with pilots
dataSymbol(cfgOFDM.PilotIndices,1) = repmat(wlan.internal.nonHTPilots(Nsym,z),num20,1);
[lsig,scalingFactor] = wlan.internal.ehtPreEHTFieldMap(dataSymbol,N_LSIG_TONE,cfgEHT);

% OFDM modulate
y = wlan.internal.ofdmModulate(lsig,CPLen,varargin{:})*scalingFactor;

end
