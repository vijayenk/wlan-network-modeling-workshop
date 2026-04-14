function y = wlanVHTLTFDemodulate(rx,cfg,varargin)
%wlanVHTLTFDemodulate OFDM demodulate VHT-LTF signal
%
%   Y = wlanVHTLTFDemodulate(RX,CFG) demodulates the time-domain VHT-LTF
%   received signal for the VHT transmission format.
%
%   Y is the frequency-domain signal corresponding to the VHT-LTF, returned
%   as a complex matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst
%   represents the number of data and pilot subcarriers in the VHT-LTF.
%   Nsym represents the number of OFDM symbols in the VHT-LTF. Nr
%   represents the number of receive antennas.
%
%   RX is the received time-domain VHT-LTF signal, specified as a complex
%   matrix of size Ns-by-Nr. Ns represents the number of samples, which can
%   be greater than or equal to the VHT-LTF length, lenVHT, where only the
%   first lenVHT samples of RXVHTLTF are used.
%
%   CFG is the format configuration object of type wlanVHTConfig, which
%   specifies the parameters for the VHT format.
%
%   Y = wlanVHTLTFDemodulate(RX,CHANBW,NUMSTS) demodulates the received
%   signal for the specified channel bandwidth, CHANBW, and the number of
%   space-time streams, NUMSTS. Both CHANBW and NUMSTS have the same
%   attributes as the corresponding ChannelBandwidth and
%   NumSpaceTimeStreams properties of the wlanVHTConfig format
%   configuration object.
%
%   Y = wlanVHTLTFDemodulate(...,SYMOFFSET) specifies the optional OFDM
%   symbol sampling offset as a fraction of the cyclic prefix length
%   between 0 and 1, inclusive. When unspecified, a value of 0.75 is used.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(2,4);

symOffset = 0.75; % Default

if ischar(cfg) || isstring(cfg)
    % wlanVHTLTFDemodulate(RXVHTLTF,CHANBW,NUMSTS,...) syntax
    chanBW = wlan.internal.validateParam('CHANBW', cfg, mfilename);

    numSTSVec = varargin{1};
    wlan.internal.validateParam('NUMSTS', numSTSVec, mfilename);

    if nargin>3
        symOffset = varargin{2};
        validateattributes(symOffset, {'numeric'}, {'scalar','>=',0,'<=',1}, mfilename, 'SYMOFFSET');
    end
else
    % wlanVHTLTFDemodulate(RXVHTLTF,CFGVHT,...) syntax
    % cfgVHT validation
    validateattributes(cfg, {'wlanVHTConfig'}, {'scalar'}, mfilename, 'VHT format configuration object');
    % Dependent validation not needed for CHANBW, numSTS properties
    chanBW = cfg.ChannelBandwidth;
    numSTSVec = cfg.NumSpaceTimeStreams;

    if nargin>2
        symOffset = varargin{1};
        validateattributes(symOffset, {'numeric'}, {'scalar','>=',0,'<=',1}, mfilename, 'SYMOFFSET');
    end
end

% Input rx validation
validateattributes(rx, {'double','single'}, {'2d', 'finite'}, 'rxVHTLTF', 'VHT-LTF signal');

[numSamples,numRx] = size(rx);
if numSamples == 0
    y = zeros(0, 0, numRx, 'like', rx);
    return;
end

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-LTF',chanBW);

% Cross-validation between inputs
numSym = wlan.internal.numVHTLTFSymbols(sum(numSTSVec));
minInpLen = numSym*(ofdmInfo.FFTLength+ofdmInfo.CPLength);
coder.internal.errorIf(numSamples<minInpLen,'wlan:wlanVHTLTFDemodulate:ShortDataInput',minInpLen);

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
y = wlan.internal.legacyOFDMDemodulate(rx(1:minInpLen,:),ofdmInfo,symOffset,sum(numSTSVec));

end

