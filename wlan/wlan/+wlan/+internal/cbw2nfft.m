function [FFTLen,NumSC] = cbw2nfft(chanBW)
%cbw2nfft Get FFT length for the given channel bandwidth
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FFTLEN = cbw2nfft(CHANBW) returns the FFT length given the channel
%   bandwidth. CHANBW is the channel bandwidth and must be 'CBW5', 'CBW10',
%   'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%
%   [FFTLEN,NSC] = cbw2fft(CHANBW) additionally returns the number of
%   subchannels.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

switch chanBW
    case 'CBW40'
        NumSC = 2;
    case 'CBW80'
        NumSC = 4;
    case 'CBW160'
        NumSC = 8;
    case 'CBW320'
        NumSC = 16;
    otherwise % For 'CBW20', 'CBW10', 'CBW5'
        NumSC = 1;
end

FFTLen = 64*NumSC;

end