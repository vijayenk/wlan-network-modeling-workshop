function y = heBCCDeinterleave(x,ruSize,numBPSCS,numCBPSSI,DCM,NCBPSLAST)
%heBCCDeinterleave HE BCC deinterleaving
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = heBCCDeinterleave(X,RUSIZE,NBPSCS,NCBPSSI,DCM,NCBPSLAST) outputs
%   the binary convolutionally deinterleaved input X, as defined in IEEE
%   Std 802.11ax-2021, Section 27.3.12.8 and IEEE P802.11be/D2.0, Section
%   36.3.13.6
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 78,
%   106, 132, or 242.
%
%   NUMBPSCS is the number of coded bits per single carrier per spatial
%   stream.
%
%   NUMCBPSSI is the number of coded bits per OFDM symbol per spatial
%   stream per interleaver block.
%
%   DCM is a logical representing if dual carrier modulation is used.
%
%   NCBPSLAST is the number of coded bits per symbol in the last OFDM
%   symbol.
%
%   See also heBCCInterleave

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

% Get BCC interleaver/deinterleaver parameters
[numCol,numRow,numRot] = wlan.internal.heBCCInterleaveParameters(ruSize,numBPSCS,DCM);

% Deinterleave
deinterleaved = wlan.internal.bccDeinterleaveCore(x,numBPSCS,numCBPSSI,numCol,numRow,numRot);

[numSamples,numSS,~] = size(deinterleaved); % numSamples-by-numSS-by-numSeg
if DCM && numBPSCS==1 && any(ruSize==[106 132 242]) && numSS==1
    % Remove 1 bit padding applied for special case

    % If the pre-FEC padding factor is 4 then we only need to remove
    % the 1 bit padding from the symbols up to the last, as post-FEC
    % depadding will have removed all of the padding from the last
    % symbol. For other padding factors we need to remove the 1 bit
    % padding from all symbols including the last.
    % NOTE: as STBC is not used with DCM we only have to worry about 1
    % symbol at the end, not 2.
    if NCBPSLAST~=numCBPSSI
        % Depad all symbols apart from last
        NSYMToDepad = numSamples/numCBPSSI-1;
    else
        % Depad all symbols including last
        NSYMToDepad = numSamples/numCBPSSI;
    end
    samplesToDepad = deinterleaved((1:NSYMToDepad*numCBPSSI)'); % numSS == numSeg == 1
    perSymbolPadded = reshape(samplesToDepad,numCBPSSI,NSYMToDepad);
    depadded = reshape(perSymbolPadded(1:end-1,:),(numCBPSSI-1)*NSYMToDepad,1);
    y = [depadded; deinterleaved((NSYMToDepad*numCBPSSI+1:end)')]; % numSS == numSeg == 1
else
    y = deinterleaved;
end

end