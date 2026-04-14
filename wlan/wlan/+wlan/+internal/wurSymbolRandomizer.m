function [m,Tcsr,n,b] = wurSymbolRandomizer(NSym,dataRate,varargin)
%wurSymbolRandomizer WUR symbol randomizer
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [m,Tcsr,n,b] = wurSymbolRandomizer(NSym,dataRate) generates the On-Off
%   waveform for a 20 MHz subchannel.
%
%   m is a 1-by-Nsym vector of value -1 or +1 that multiplied with the
%   input waveform, where Nsym is the number of symbols. See
%   P802.11ba/D8.0, December 2020, Figure 30-9 and Equation 30-3.
%
%   Tcsr represents the pseudorandom cyclic shift described in IEEE
%   P802.11ba/D8.0, December 2020, Section 30.3.4.4.
%
%   N represents the cyclic shift index.
%
%   NSYM represents the number of symbols to be randomized.
%
%   b is a NSYM-by-3 matrix consisting of state progressions of least
%   significant bit (b0) to the most significant bit (b2).
%
%   DATARATE specifies the transmission rate as character vector or string
%   and must be 'LDR', or 'HDR'.
%
%   [m,Tcsr,n,b] = wurSymbolRandomizer(...,symOffset) generates
%   the On-Off waveforms for a specific 20 MHz subchannel.
%
%   SYMOFFSET is the symbol offset to progress the state of the linear
%   feedback shift register.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

symOffset = 0;
if nargin>2
    symOffset = varargin{1};
end

scramInit = 127; % P802.11ba/D8.0, December 2020, Table 30-8.
scramblerInitBits = int2bit(scramInit,7);

% Scrambling sequence generated using generator polynomial
% If symbol offset is greater than 0 progress scrambler state
for d = 1:symOffset
    I = xor(scramblerInitBits(1),scramblerInitBits(4)); % x7 xor x4
    scramblerInitBits(1:end-1) = scramblerInitBits(2:end); % Left-shift
    scramblerInitBits(7) = I;                           % Update x1
end

buffSize = NSym; % bits to be randomized
I = zeros(buffSize,1,'int8');
b = zeros(buffSize,3,'int8'); %b2b1b0
bit = zeros(buffSize,1,'int8');

% Scrambling sequence generated using generator polynomial
for d = 1:buffSize
    I(d) = xor(scramblerInitBits(1),scramblerInitBits(4)); % x7 xor x4
    b(d,:) = scramblerInitBits([5 6 7]);
    bit(d) = scramblerInitBits(1);                         % x7 as output bit to convert
    scramblerInitBits(1:end-1) = scramblerInitBits(2:end); % Left-shift
    scramblerInitBits(7) = I(d);                           % Update x1
end

% Logical 0 converted to 1, and 1 to -1
m = zeros(size(I)).';
m(bit==1) = -1;
m(bit==0) = 1;

% b0 least significant (left-msb)
n = bit2int(b.',size(b,2)).';

Tcsr = wlan.internal.wurCyclicShift(dataRate,n);

end

