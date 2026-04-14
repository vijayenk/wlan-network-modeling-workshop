function foffset = wlanCoarseCFOEstimate(in,chanBW,corrOffset,nameValueArgs)
%wlanCoarseCFOEstimate Coarse carrier frequency offset estimation
%   FOFFSET = wlanCoarseCFOEstimate(IN,CHANBW) estimates the carrier
%   frequency offset FOFFSET in Hertz using time-domain L-STF (non-HT Short
%   Training Field). The short length of the periodic sequence within the
%   L-STF allows coarse frequency offset estimation to be performed.
%
%   IN is a single or double complex Ns-by-Nr matrix where Ns is the number
%   of time domain samples in the L-STF, and Nr is the number of receive
%   antennas. If Ns exceeds the number of time domain samples in the L-STF,
%   trailing samples are not used for estimation.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
%   'CBW320'.
%
%   FOFFSET = wlanCoarseCFOEstimate(IN,CHANBW,CORROFFSET) estimates the
%   carrier frequency offset with a specified correlation offset
%   CORROFFSET. The correlation offset specifies the start of the
%   correlation as a fraction of the guard interval between 0 and 1,
%   inclusive. The guard interval for coarse estimation is the first 0.8us
%   of the L-STF for 20 MHz operation. When unspecified a value of 0.75 is
%   used.
%
%   FOFFSET = wlanCoarseCFOEstimate(...,'OversamplingFactor',OSF) specifies
%   the optional oversampling factor of the waveform. The oversampling
%   factor must be greater than or equal to 1. The default value is 1. When
%   you specify an oversampling factor greater than 1, the function uses a
%   larger FFT size and process the oversampled waveform to determine the
%   coarse frequency offset. The oversampling factor must result in an
%   integer number of samples in the cyclic prefix.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

arguments
    in (:, :) {mustBeFloat,mustBeFinite};
    chanBW;
    corrOffset (1,1) {mustBeNumeric,mustBeGreaterThanOrEqual(corrOffset,0),mustBeLessThanOrEqual(corrOffset,1)} = 0.75;
    nameValueArgs.OversamplingFactor (1,1) {mustBeNumeric,mustBeFinite,mustBeGreaterThanOrEqual(nameValueArgs.OversamplingFactor,1)} = 1;
end

% Validate the channel bandwidth
chanBW = wlan.internal.validateParam('NONHTEHTCHANBW',chanBW,mfilename);

if any(strcmp(chanBW,{'CBW5','CBW10','CBW20'}))
    % Same FFT length for 5/10/20 MHz
    num20 = 1;
else
    num20 = wlan.internal.cbwStr2Num(chanBW)/20;
end

osf = nameValueArgs.OversamplingFactor;
nominalFFTLen = 64*num20;
wlan.internal.validateOFDMOSF(osf,nominalFFTLen,nominalFFTLen/2); % Validate OSF
fftLen = nominalFFTLen*osf;
Nstf = 160*num20*osf; % Number of samples in L-STF
fs = wlan.internal.cbwStr2Num(chanBW)*1e6*osf;

% Extract L-STF or as many samples as we can
lstf = double(in(1:min(Nstf,end),:));

% Coarse CFO estimate assuming 4 repetitions per FFT period
M = fftLen/4;     % Number of samples per repetition
GI = fftLen/4;    % Guard interval length
S = M*9;          % Maximum useful part of L-STF
N = size(lstf,1); % Number of samples in the input

% We need at most S samples
offset = round(corrOffset*GI);
use = lstf(offset+(1:min(S,N-offset)),:);
foffset = wlan.internal.cfoEstimate(use,M).*fs/M;

