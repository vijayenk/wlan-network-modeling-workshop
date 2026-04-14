function info = wlanDMGOFDMInfo
%wlanDMGOFDMInfo OFDM information for DMG
%   INFO = wlanDMGOFDMInfo returns OFDM info for DMG.
%
%   INFO is a structure with these fields:
%     FFTLength              - FFT length
%     SampleRate             - Sample rate of waveform
%     CPLength               - Cyclic prefix length
%     NumTones               - Number of active subcarriers
%     ActiveFrequencyIndices - Indices of active subcarriers relative to DC
%                              in the range [-NFFT/2, NFFT/2-1]
%     ActiveFFTIndices       - Indices of active subcarriers within the FFT
%                              in the range [1, NFFT]
%     DataIndices            - Indices of data within the active 
%                              subcarriers in the range [1, NumTones]
%     PilotIndices           - Indices of pilots within the active
%                              subcarriers in the range [1, NumTones]

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

fftLength = 512;
cpLength = 128;

% Get the indices of data and pilots within active subcarriers
freqInd = [-177:-2 2:177].';
pilotIdx = [-150; -130; -110; -90; -70; -50; -30; -10; 10; 30; 50; 70; 90; 110; 130; 150];
idx = ismember(freqInd,pilotIdx);
seqInd = (1:numel(freqInd))';
pilotIndices = seqInd(idx);
dataIndices = seqInd(~idx);

% Form structure
info = struct;
info.FFTLength = fftLength;
info.SampleRate = 2640e6;
info.CPLength = cpLength;
info.NumTones = numel(freqInd);
info.ActiveFrequencyIndices = freqInd;
info.ActiveFFTIndices = freqInd+fftLength/2+1;
info.DataIndices = dataIndices;
info.PilotIndices = pilotIndices;

end
