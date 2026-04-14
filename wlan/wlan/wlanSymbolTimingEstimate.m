function [startOffset, M] = wlanSymbolTimingEstimate(x,chanBW,threshold,nameValueArgs)
%wlanSymbolTimingEstimate Fine symbol timing estimation using the L-LTF
%   STARTOFFSET = wlanSymbolTimingEstimate(X,CHANBW) returns the offset
%   from the start of the input waveform to the estimated start of the
%   L-STF using cross-correlation with the L-LTF. Only non-HT with OFDM
%   modulation, HT-mixed, VHT, HE and EHT packet formats are supported.
%
%   X is the received time-domain signal on which symbol timing is
%   performed. It is a single or double Ns-by-Nr matrix of real or complex
%   values, where Ns represents the number of time-domain samples and Nr
%   represents the number of receive antennas. It is expected that X
%   contains the L-LTF.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be one of 'CBW5', 'CBW10', 'CBW20' 'CBW40', 'CBW80', 'CBW160',
%   or 'CBW320'.
%
%   STARTOFFSET is an integer within the range [-L, Ns-2L], where L denotes
%   the length of the L-LTF. STARTOFFSET is empty when Ns<L. When
%   STARTOFFSET is negative, this implies the input waveform does not
%   contain a complete L-STF.
%
%   STARTOFFSET = wlanSymbolTimingEstimate(...,THRESHOLD) optionally
%   specifies the threshold which the decision metric must meet or exceed
%   to obtain a symbol timing estimate. THRESHOLD is a real scalar between
%   0 and 1. When unspecified a value of 1 is used by default.
%
%   [STARTOFFSET,M] = wlanSymbolTimingEstimate(...) returns the decision
%   metric used to perform the symbol timing algorithm. M is a real vector
%   of size (Ns-L+1)-by-1, representing the cross-correlation between X and
%   locally generated L-LTF of the first transmit antenna.
%
%   [...] = wlanSymbolTimingEstimate(...,'OversamplingFactor',OSF) specifies the
%   optional oversampling factor of the waveform. The oversampling factor
%   must be greater than or equal to 1. The default value is 1. When you
%   specify an oversampling factor greater than 1, the function uses a
%   larger FFT size and process the oversampled waveform to determine the
%   the start of the input waveform to the estimated start of the L-STF.
%   The oversampling factor must result in an integer number of samples in
%   the cyclic prefix.

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen

arguments
    x (:, :) {mustBeFloat,mustBeFinite};
    chanBW;
    threshold (1,1) {mustBeNumeric,mustBeGreaterThanOrEqual(threshold,0),mustBeLessThanOrEqual(threshold,1)} = 1;
    nameValueArgs.OversamplingFactor (1,1) {mustBeNumeric,mustBeFinite,mustBeGreaterThanOrEqual(nameValueArgs.OversamplingFactor,1)} = 1;
end

chanBW = wlan.internal.validateParam('NONHTEHTCHANBW',chanBW,mfilename); % Validate Channel Bandwidth
osf = nameValueArgs.OversamplingFactor;
fftLen = wlan.internal.cbw2nfft(chanBW);
wlan.internal.validateOFDMOSF(osf,fftLen,fftLen/2); % Validate OSF

% Get sampling rate
fs = 1e6*wlan.internal.cbwStr2Num(chanBW)*osf;

% Generate L-LTF
LLTF = wlan.internal.legacyLTF(chanBW,1,osf);

% startOffset and M are returned as empty when input signal length is less
% than that of L-LTF
L = size(LLTF,1);
if size(x,1) < L
    startOffset = [];
    M = [];
    return;
end

% Calculate cross-correlation between x and L-LTF from the 1st antenna
corr = filter(conj(flipud(LLTF(:, 1))),1,x);

% Calculate decision metric and get initial timing estimate
Metric = sum(abs(corr(L:end, :)).^2,2);
[Mmax, nInitial] = max(Metric);

% Refine timing estimate by taking into account cyclic shift delay (CSD).
% The largest CSD defined in 802.11n/ac. Round to nearest integer due to
% non-integer oversampling factor.
deltaCSD = round(200e-9*fs);

if (nInitial + deltaCSD) > length(Metric)
    idx = find(Metric(nInitial:end) >= threshold*Mmax,1,'last');
else
    idx = find(Metric(nInitial:nInitial + deltaCSD) >= threshold*Mmax,1,'last');
end
nMax = nInitial + (idx - 1);

% Prepare the output
startOffset = nMax - L - 1;
M = double(Metric); % For codegen

end
