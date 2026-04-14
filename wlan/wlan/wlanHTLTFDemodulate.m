function y = wlanHTLTFDemodulate(rx, cfgHT, varargin)
%wlanHTLTFDemodulate OFDM demodulate HT-LTF signal
%
%   Y = wlanHTLTFDemodulate(RX, CFGHT) demodulates the time-domain HT-LTF
%   received signal for the HT-Mixed transmission format.
%
%   Y is the frequency-domain signal corresponding to the HT-LTF. It is a
%   complex matrix or 3-D array of size Nst-by-Nsym-by-Nr, where Nst
%   represents the number of data and pilot subcarriers in the HT-LTF, Nsym
%   represents the number of OFDM symbols in the HT-LTF, and Nr represents
%   the number of receive antennas.
%
%   RX is the received time-domain HT-LTF signal. It is a complex matrix of
%   size Ns-by-Nr, where Ns represents the number of samples. Ns can be
%   greater than or equal to the HT-LTF length, lenHT, where only the first
%   lenHT samples of RXHTLTF are used.
%
%   CFGHT is the format configuration object of type wlanHTConfig, which
%   specifies the parameters for the HT-Mixed format.
%
%   Y = wlanHTLTFDemodulate(..., SYMOFFSET) specifies the optional OFDM
%   symbol sampling offset as a fraction of the cyclic prefix length
%   between 0 and 1, inclusive. When unspecified, a value of 0.75 is used.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(2,3);

% cfgHT validation
validateattributes(cfgHT, {'wlanHTConfig'}, {'scalar'}, mfilename, ...
                   'HT-Mixed format configuration object');
validateConfig(cfgHT, 'EssSTS');

% Input rxHTLTF validation
validateattributes(rx, {'double', 'single'}, {'2d', 'finite'}, ...
                   'rxHTLTF', 'HT-LTF signal');

if nargin == 3
    validateattributes(varargin{1}, {'numeric'}, ...
                       {'real','scalar','>=',0,'<=',1}, mfilename, 'symOffset');

    symOffset = varargin{1};
else    % default
    symOffset = 0.75;
end

numRx = size(rx, 2);
if size(rx, 1) == 0
    y = zeros(0, 0, numRx, 'like', rx);
    return;
end

chanBW = cfgHT.ChannelBandwidth;
numSTS = cfgHT.NumSpaceTimeStreams;
if wlan.internal.inESSMode(cfgHT)
    numESS = cfgHT.NumExtensionStreams;
else
    numESS = 0;
end
[~,~,dltf,eltf] = wlan.internal.vhtltfSequence(chanBW, numSTS, numESS);
numSym = dltf+eltf;

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('HT-LTF',chanBW);

% Validate length of input
minInpLen = numSym*(ofdmInfo.FFTLength+ofdmInfo.CPLength);
coder.internal.errorIf(size(rx, 1) < minInpLen, ...
                       'wlan:wlanHTLTFDemodulate:ShortDataInput', minInpLen);

% OFDM demodulate HT-DLTFs and HT-ELTFs together with de-normalization and remove phase rotation per subcarrier
y = wlan.internal.legacyOFDMDemodulate(rx(1:minInpLen,:),ofdmInfo,symOffset,numSTS);

if numESS>0
    % Rescale ELTFs
    y(:,dltf+(1:eltf),:) = y(:,dltf+(1:eltf),:).*sqrt(numSTS/numESS);
end

end

