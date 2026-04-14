function demod = demodulateLLTF(rx,cfgOFDM,symOffset)
%demodulateLLTF OFDM demodulate L-LTF field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEMOD = demodulateLLTF(RX,CFGOFDM,SYMOFFSET) OFDM demodulates the time
%   domain L-LTF field signal RX given the OFDM configuration structure
%   CFGOFDM and OFDM symbol offset SYMOFFSET.

%   Copyright 2020-2021 The MathWorks, Inc.

%#codegen

[numSamples,numRx] = size(rx);

if numSamples==0
    demod = complex(zeros(cfgOFDM.NumTones,0,numRx,class(rx))); % Return empty for 0 samples
    return;
end

% Deal with 0 CP length for L-LTF
secondSymIdx = cfgOFDM.FFTLength+(1:1.5*cfgOFDM.FFTLength);
if any(secondSymIdx>size(rx,1))
    % If not enough samples for second symbol do not demodulate
    demod = wlan.internal.ofdmDemodulate(rx(1:1.5*cfgOFDM.FFTLength,:),cfgOFDM,symOffset);
else
    % Demodulate both symbols
    demod = wlan.internal.ofdmDemodulate([rx(1:1.5*cfgOFDM.FFTLength,:); rx(secondSymIdx,:)],cfgOFDM,symOffset);
end

end