function [bits, failCRC] = htSIGBitRecover(sym, noiseVarEst, csi)
%htSIGBitRecover Recover information bits in HT-SIG field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS, FAILCRC] = htSIGBitRecover(SYM, NOISEVAREST, CSI) recovers the
%   information bits in the HT-SIG field and performs CRC check.
%
%   BITS is an int8 column vector of length 48 containing the recovered
%   information bits.
%
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar.
%
%   SYM are the single or double complex demodulated VHT-SIG-A symbols of
%   size 48-by-2.
%
%   NOISEVAREST is the single or double noise variance estimate. It is a
%   real nonnegative scalar.
%   
%   CSI is the channel state information and is a 48-by-1 column vector of
%   real values of type single or double.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

% Constellation demapping
demodOut = wlanConstellationDemap(sym, noiseVarEst, 1, pi/2);

% Apply CSI and concatenate OFDM symbols in the first dimension
demodOut = reshape(demodOut .* repmat(csi, 1, 2), 48*2, 1);

% Deinterleaving
deintlvrOut = wlanBCCDeinterleave(demodOut, 'Non-HT', 48);

% BCC decoding 
bits = wlanBCCDecode(deintlvrOut(:), '1/2');

% CRC detection
[~, failCRC] = wlan.internal.crcDetect(bits(1:42));

end
