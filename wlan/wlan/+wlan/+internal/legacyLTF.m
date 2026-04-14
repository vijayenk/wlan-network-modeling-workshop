function y = legacyLTF(chanBW,varargin)
%legacyLTF Legacy Long Training Field (L-LTF) for the given channel bandwidth
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = legacyLTF(CHANBW) generates the Legacy Long Training Field (L-LTF)
%   time-domain signal for the given channel bandwidth (CHANBW).
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
%   'CBW320'.
%
%   Y = legacyLTF(...,NUMTX) generates a complex matrix of size
%   Ns-by-NUMTX, where Ns represents the number of time-domain samples and
%   NUMTX represents the number of transmit antennas.
%
%   Y = legacyLTF(...,OSF) generates the Legacy Long Training Field (L-LTF)
%   time-domain signal for an oversampling factor OSF. OSF must >=1 and
%   result in an integer number of cyclic prefix samples and an even FFT
%   length.

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

numTx = 1;
osf = 1;
if nargin>1
    numTx = varargin{1};
    assert(9>numTx,'numTx must be less than or equal to 8.');
    if nargin==3
        osf = varargin{2};
    end
end

[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
LLTF = [zeros(6,1); lltfLower; 0; lltfUpper; zeros(5,1)];

if any(strcmp(chanBW,{'CBW5','CBW10'}))
    fftLen = wlan.internal.cbw2nfft(chanBW);
    cpLen = [fftLen/2 0];
    numSubChannels = fftLen/64;
    N_LLTF_TONE = 52*numSubChannels;
else
    cfgOFDM = wlan.internal.hePreHEOFDMConfig(chanBW,'L-LTF');
    cpLen = [cfgOFDM.FFTLength/2 0];
    numSubChannels = cfgOFDM.NumSubchannels;
    N_LLTF_TONE = cfgOFDM.NumTones;
end

% Replicate L-LTF sequence for each 20 MHz BW
symOFDM = repmat(LLTF,numSubChannels,1);
[lltf,scalingFactor] = legacyFieldMap(symOFDM,N_LLTF_TONE,chanBW,numTx);
sym = [lltf lltf];
out = wlan.internal.ofdmModulate(sym,cpLen,osf);
y = out*scalingFactor;

end

function [y,scalingFactor] = legacyFieldMap(dataSymbol,numTones,chanBW,numTx)
%legacyFieldMap Apply carrier rotation

    Nfft = size(dataSymbol,1);
    chBW = wlan.internal.cbwStr2Num(chanBW);
    gamma = wlan.internal.vhtCarrierRotations(chanBW);
    % Apply gamma rotation to all symbols, puncturing subchannels
    y = dataSymbol .* gamma;
    symMIMO = repmat(y,1,1,numTx);
    csh = wlan.internal.getCyclicShiftVal('OFDM',numTx,chBW);
    y = wlan.internal.cyclicShift(symMIMO,csh,Nfft);
    scalingFactor = Nfft/sqrt(numTx*numTones);
end
