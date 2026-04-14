function demod = ofdmDemodulate(rx,cfgOFDM,symOffset)
%ofdmDemodulate OFDM demodulate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEMOD = ofdmDemodulate(RX,CFGOFDM,SYMOFFSET) OFDM demodulates the time
%   domain input RX given the OFDM configuration structure CFGOFDM and
%   OFDM symbol offset SYMOFFSET.

%   Copyright 2020-2021 The MathWorks, Inc.

%#codegen

[numSamples,numRx] = size(rx);

if numSamples==0
    demod = complex(zeros(cfgOFDM.NumTones,0,numRx,class(rx))); % Return empty for 0 samples
    return;
end

% Calculate number of symbols to demodulate
Ns = cfgOFDM.FFTLength+cfgOFDM.CPLength(1);
numSym = floor(numSamples/Ns);
numSamples = numSym*Ns;

% OFDM demodulate
prmStr = struct;
prmStr.NumReceiveAntennas = numRx;
prmStr.FFTLength = cfgOFDM.FFTLength;
prmStr.NumSymbols = numSym;
prmStr.SymbolOffset = round(symOffset*cfgOFDM.CPLength(1));
prmStr.CyclicPrefixLength = cfgOFDM.CPLength(1);
fftout = comm.internal.ofdm.demodulate(rx(1:numSamples,:),prmStr);

% Extract active subcarriers from full FFT
demod = fftout(cfgOFDM.ActiveFFTIndices,:,:);

% Scale by number of active tones and FFT length
demod = demod*sqrt(cfgOFDM.NumTones)/cfgOFDM.FFTLength;
end