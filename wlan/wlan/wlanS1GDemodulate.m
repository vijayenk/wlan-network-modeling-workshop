function sym = wlanS1GDemodulate(rx,fieldname,cfg,varargin)
%wlanS1GDemodulate Demodulate S1G fields
%   SYM = wlanS1GDemodulate(RX,FIELD,CFG) demodulates the time-domain
%   received signal RX using OFDM demodulation parameters appropriate for
%   the specified FIELD and the given configuration CFG.
%
%   SYM is the demodulated frequency-domain signal, returned as a complex
%   matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst is the number of
%   active (occupied) subcarriers in the field. Nsym is the number of OFDM
%   symbols. Nr is the number of receive antennas.
%
%   RX is the received time-domain signal, specified as a complex matrix of
%   size Ns-by-Nr, where Ns represents the number of time-domain samples.
%   If Ns is not an integer multiple of the OFDM symbol length for the
%   specified field, then mod(Ns,symbol length) trailing samples are
%   ignored.
%
%   FIELD is the field of interest and must be one of: 'S1G-LTF1',
%   'S1G-SIG', 'S1G-LTF2N', 'S1G-SIG-A','S1G-DLTF', 'S1G-SIG-B',
%   'S1G-Data'.
%
%   CFG is a format configuration object of type wlanS1GConfig.
%   FIELD must be relevant for the configuration specified with CFG.
%
%   SYM = wlanS1GDemodulate(...,'OversamplingFactor',OSF) specifies the
%   optional oversampling factor of the waveform to demodulate. The
%   oversampling factor must be greater than or equal to 1. The default
%   value is 1. When you specify an oversampling factor greater than 1, the
%   function uses a larger FFT size to demodulate the oversampled waveform.
%   The oversampling factor must result in an integer number of samples in
%   the cyclic prefix.
%
%   SYM = wlanS1GDemodulate(...,'OFDMSymbolOffset',SYMOFFSET) specifies
%   the optional OFDM symbol sampling offset as a fraction of the cyclic
%   prefix length between 0 and 1, inclusive. When unspecified, a value of
%   0.75 is used.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

% Validate inputs
validateattributes(rx,{'double'},{'2d','finite','nonempty'},mfilename,'rx');
[numSamples,numRx] = size(rx);

% Get OFDM symbol offset and oversampling factor
nvp = wlan.internal.demodNVPairParse(varargin{:});

% Get OFDM info
cfgOFDM = wlanS1GOFDMInfo(fieldname,cfg,'OversamplingFactor',nvp.OversamplingFactor);

if numSamples==0
    sym = complex(zeros(cfgOFDM.NumTones,0,numRx)); % Return empty for 0 samples
    return;
end
% Validate input length
Ns1 = cfgOFDM.FFTLength+cfgOFDM.CPLength(1); % Number of samples in first OFDM symbol
coder.internal.errorIf(numSamples<Ns1,'wlan:shared:ShortDataInput',Ns1);

if numel(cfgOFDM.CPLength)>1
    % OFDM demodulate field with different cyclic prefix per symbol
    fftout = cpPerSymOFDMDemod(rx,cfgOFDM,nvp.SymOffset);
else
    % OFDM demodulate field with same cyclic prefix for all symbols
    numSym = floor(numSamples/Ns1); % Calculate number of symbols to demodulate
    fftout = ofdmdemod(rx(1:numSym*Ns1,:),cfgOFDM.FFTLength,cfgOFDM.CPLength,round(nvp.SymOffset*cfgOFDM.CPLength));
end

% Remove gamma rotation
fftout = removeGammaRotation(fftout,cfgOFDM);

% Extract active subcarriers from full FFT
sym = fftout(cfgOFDM.ActiveFFTIndices,:,:);

% Scale the demodulated waveform
sym = sym*sqrt(cfgOFDM.NumTones)/cfgOFDM.FFTLength;

end

function fftout = removeGammaRotation(fftout,cfgOFDM)
	% Tone rotation: Section 24.3.7. (gamma)
    gamma = wlan.internal.s1gGammaPhase(cfgOFDM.NumSubchannels);
    toneRotation = reshape(repmat(gamma,cfgOFDM.FFTLength/cfgOFDM.NumSubchannels,1),[],1);
    fftout = fftout .* conj(toneRotation);
end

% OFDM demodulate when the cyclic prefix length can change per symbol
function postShift = cpPerSymOFDMDemod(x,cfgOFDM,ofdmSymOffset)
    [numSamples,numRx] = size(x);

    Nfft = cfgOFDM.FFTLength;
    Ncp = cfgOFDM.CPLength;

    % Remove cyclic prefix
    numCPSamples = sum(Nfft+Ncp);
    numTrailingSym = max(floor((numSamples-numCPSamples)/(Nfft+Ncp(end))),0);
    % Replicate last cyclic prefix length for remaining symbols
    Ncp = [Ncp repmat(Ncp(end),1,numTrailingSym)];

    % Get the start offset of each OFDM symbol (after CP)
    postCPStartOffset = [0 cumsum(Ncp(1:end-1)+Nfft)]+Ncp;

    % If the CP length is 0, demodulate assuming the last symbol
    % essentially contains a CP of the same size as the previous symbol
    CPLenUse = Ncp;
    symOffsetUse = round(ofdmSymOffset*Ncp);
    numSym = numel(Ncp);
    for symIdx = 2:numSym
        if CPLenUse(symIdx)==0
            CPLenUse(symIdx) = CPLenUse(symIdx-1);
            symOffsetUse(symIdx) = symOffsetUse(symIdx-1);
        end
    end
    CPFractionUse = CPLenUse-symOffsetUse;

    postCPRemovalFull = coder.nullcopy(complex(zeros(Nfft,numSym,numRx)));
    finalSymIdx = numSym;
    for symIdx = 1:numSym
        symPart = postCPStartOffset(symIdx)+(1:Nfft-CPFractionUse(symIdx));
        if any(symPart>size(x,1))
            % Not enough samples to form complete symbol
            finalSymIdx = symIdx-1;
            break;
        end
        cpPart = postCPStartOffset(symIdx)-(CPFractionUse(symIdx):-1:1)+1;
        postCPRemovalFull(:,symIdx,:) = x([symPart cpPart],:,:);
    end
    postCPRemoval = postCPRemovalFull(:,1:finalSymIdx,:);

    % FFT
    postFFT = fft(postCPRemoval,[],1);

    % FFT shift
    if isreal(postFFT)
        postShift = complex(fftshift(postFFT,1),0);
    else
        postShift = fftshift(postFFT,1);
    end
end
