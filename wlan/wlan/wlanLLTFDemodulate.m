function y = wlanLLTFDemodulate(rx,cfgFormat,varargin)
%wlanLLTFDemodulate OFDM demodulate L-LTF signal
%   Y = wlanLLTFDemodulate(RX,CHANBW) demodulates the time-domain non-HT
%   Long training field (L-LTF) received signal for EHT, HE, VHT, HT-Mixed,
%   and non-HT OFDM transmission formats.
%
%   Y is the frequency-domain signal corresponding to the L-LTF.
%   It is a complex matrix or 3-D array of size Nst-by-2-by-Nr, where Nst
%   represents the number of used subcarriers in the L-LTF, and Nr
%   represents the number of receive antennas. Two OFDM symbols are
%   demodulated for the L-LTF.
%
%   RX is the received time-domain L-LTF signal, specified as a single or
%   double complex matrix of size Ns-by-Nr, where Ns represents the number
%   of time-domain samples. Ns can be greater than or equal to the L-LTF
%   length, lenLLTF, where only the first lenLLTF samples of RXLLTF are
%   used.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
%   'CBW320'.
%
%   Y = wlanLLTFDemodulate(RX,CFGFORMAT) similarly demodulates the received
%   signal when a transmission configuration object is specified.
%   CFGFORMAT is of type wlanNonHTConfig or wlanHTConfig or wlanVHTConfig
%   that specifies the channel bandwidth. Only OFDM modulation is supported
%   for a wlanNonHTConfig object input.
%
%   Y = wlanLLTFDemodulate(...,SYMOFFSET) specifies the optional OFDM
%   symbol sampling offset as a fraction of the cyclic prefix length
%   between 0 and 1, inclusive. When unspecified a value of 0.75 is used.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(2,3);

% cfgFormat validation - character vector, string scalar or object
if ischar(cfgFormat) || isstring(cfgFormat)
    % wlanLLTFDemodulate(RXLLTF,CHANBW,...) syntax
    chanBW = cfgFormat;
    chanBW = wlan.internal.validateParam('NONHTEHTCHANBW', chanBW, mfilename);
else
    % wlanLLTFDemodulate(RXLLTF,CFGFORMAT,...) syntax
    % Validate the format configuration object
    validateattributes(cfgFormat, {'wlanVHTConfig', 'wlanHTConfig', 'wlanNonHTConfig'}, {'scalar'}, mfilename, 'format configuration object');

    % Only applicable for OFDM and DUP-OFDM modulations
    coder.internal.errorIf( isa(cfgFormat, 'wlanNonHTConfig') && ~strcmp(cfgFormat.Modulation, 'OFDM'), 'wlan:wlanLLTFDemodulate:InvalidDSSS');

    chanBW = cfgFormat.ChannelBandwidth;
end

% Input validation
validateattributes(rx, {'single', 'double'}, {'2d', 'finite'}, mfilename, 'L-LTF signal');

if nargin==3
    validateattributes(varargin{1}, {'double'}, {'real', 'scalar', '>=', 0,'<=', 1}, mfilename, 'symOffset');
    symOffset = varargin{1};
else    % default
    symOffset = 0.75;
end

numRx = size(rx, 2);
if size(rx, 1) == 0
    y = zeros(0, 0, numRx, class(rx));
    return;
end

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('L-LTF',chanBW);

% Validate length of input
minInputLength = 2.5*ofdmInfo.FFTLength;
coder.internal.errorIf(size(rx,1)<minInputLength,'wlan:wlanLLTFDemodulate:ShortDataInput',minInputLength);

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
y = wlan.internal.demodulateLLTF(rx,ofdmInfo,symOffset);

% Remove phase rotation on subcarriers
gamma = wlan.internal.vhtCarrierRotations(ofdmInfo.NumSubchannels);
y = y ./ gamma(ofdmInfo.ActiveFFTIndices);

end

