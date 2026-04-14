function demod = ehtLTFDemodulate(rx,ltfType,symOffset,cfgOFDM)
%ehtLTFDemodulate Demodulate HE-LTF and EHT-LTF fields
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEMOD = ehtLTFDemodulate(RX,LTFTYPE,SYMOFFSET,CFGOFDM) demodulates the
%   time-domain received signal RX for the given LTF type, OFDM symbol
%   offset, and OFDM demodulation parameters appropriate for HE-LTF and
%   EHT-LTF field.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

switch ltfType(1) % For codegen
    case 1
        N_EHT_LTF_Mode = 4;
    case 2
        N_EHT_LTF_Mode = 2;
    otherwise % 4
        N_EHT_LTF_Mode = 1;
end

uncompFFTLength = cfgOFDM.FFTLength;
compFFTLength = uncompFFTLength/N_EHT_LTF_Mode;

% Calculate number of symbols to demodulate
Ns = compFFTLength+cfgOFDM.CPLength;
[numSamples,numRx] = size(rx);

% Validate input length
wlan.internal.demodValidateMinInputLength(numSamples,Ns);

numSym = floor(numSamples/Ns);
numSamples = numSym*(compFFTLength+cfgOFDM.CPLength);

% OFDM demodulate
prmStr = struct;
prmStr.NumReceiveAntennas = numRx;
prmStr.FFTLength = compFFTLength; % Use compressed FFT length
prmStr.NumSymbols = numSym;
prmStr.SymbolOffset = round(symOffset*cfgOFDM.CPLength);
prmStr.CyclicPrefixLength = cfgOFDM.CPLength;
compressedfftout = coder.nullcopy(complex(zeros(compFFTLength,numSym,numRx,'like',rx)));
compressedfftout(:) = comm.internal.ofdm.demodulate(rx(1:numSamples(1),:),prmStr); % For codegen

% Decompress EHT-LTF
fftout = complex(zeros(uncompFFTLength,numSym,numRx,'like',rx));
fftout(1:N_EHT_LTF_Mode:end,:,:) = compressedfftout;

% Extract active subcarriers from full FFT
demod = fftout(cfgOFDM.ActiveFFTIndices,:,:);

% Scale by number of tones and FFT length at transmitter
demod = demod*sqrt(cfgOFDM.NumTones/N_EHT_LTF_Mode)/compFFTLength;

end