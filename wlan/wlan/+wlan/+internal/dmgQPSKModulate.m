function y = dmgQPSKModulate(bits)
%dmgQPSKModulate DMG QPSK Modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgQPSKModulate(BITS) modulated bits as per IEEE 802.11ad-2012
%   Section 21.5.3.2.4.3.
%
%   Y is the QPSK modulated symbols before tone pairing. It is a complex
%   M-by-2 matrix, where each column contains the symbols for paired tones.
%
%   BITS is the bits to modulate. It is of size N-by-1 of type uint8, where
%   N is the number of encoded bits.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

narginchk(1,2);

% IEEE 802.11ad-2012 Section 21.5.3.2.4.3 QPSK Modulation

% Generate QPSK modulated symbols split into two sets of constellation
% points; for d(k) and d(Pk)
bits = wlanConstellationMap(reshape(bits,2,numel(bits)/2).',2);

% Apply DCM mapping matrix
Q = (1/sqrt(5))*[1 2; -2 1]; % DCM mapping matrix
y = (Q*[bits(:,1) bits(:,2)].').';

end