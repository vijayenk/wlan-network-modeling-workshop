function est = wlanLLTFNoiseEstimate(rxSym)
%wlanLLTFNoiseEstimate Estimate noise power using L-LTF and S1G-LTF1
%
%   EST = wlanLLTFNoiseEstimate(RXSYM) estimates the mean noise power in
%   watts using the demodulated L-LTF and S1G-LTF1 symbols assuming 1ohm
%   resistance.
%
%   RXSYM is the frequency-domain signal corresponding to the L-LTF or
%   S1G-LTF1. It is a complex single or double array of size
%   Nst-by-2-by-Nr, where Nst is the number of used subcarriers, and Nr is
%   the number of receive antennas. Two OFDM symbols in the fields are used
%   to estimate the noise power. Noise estimation using the S1G-LTF1 field
%   for the S1G 1MHz format is not supported.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

arguments
    rxSym(:,2,:) {mustBeFloat,mustBeFinite,mustBeNonempty};
end

numSC = size(rxSym,1);

% Noise estimate
noiseEst = sum(abs(rxSym(:,1,:)-rxSym(:,2,:)).^2,1)/(2*numSC);
est = mean(noiseEst);
end
