function trackedSym = amplitudeErrorCorrect(sym,ae)
%amplitudeErrorCorrect amplitude error correction
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   TRACKEDSYM = amplitudeErrorCorrect(SYM,AE) returns amplitude corrected
%   OFDM symbols given an amplitude error.
%
%   SYM is a complex Nsc-by-Nsym-by-Nr array containing the received OFDM
%   symbols at pilot subcarriers. Nsc is the number of subcarriers.
%
%   AE is a Nsym-by-Nr vector containing the amplitude error per OFDM
%   symbol and receive antenna. Nsym is the number of OFDM symbols and Nr
%   is the number of receive antennas.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

% Amplitude correct per OFDM symbol and receive antenna
trackedSym = sym./ae;
end

