function y = heBCCInterleave(x,ruSize,numBPSCS,numCBPSSI,DCM,varargin)
%heBCCInterleave HE BCC interleaving
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = heBCCInterleave(X,RUSIZE,NBPSCS,NCBPSSI,DCM,NCBPSLAST) outputs the
%   interleaved binary convolutionally encoded data input X as defined in
%   IEEE Std 802.11ax-2021, Section 27.3.12.8 and IEEE P802.11be/D2.0,
%   Section 36.3.13.6
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
%   Y = heBCCInterleave(X,56,NBPSCS,NCBPSSI,DCM) outputs the interleaved
%   binary convolutionally encoded data input X as defined in IEEE IEEE Std
%   802.11ax-2021, Section 27.3.11.8, parameterized for the HE-SIG-B field.
%
%   See also heBCCDeinterleave

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

% Get BCC interleaver/deinterleaver parameters
[numCol,numRow,numRot] = wlan.internal.heBCCInterleaveParameters(ruSize,numBPSCS,DCM);

numSS = size(x,2);
if DCM && numBPSCS==1 && any(ruSize==[106 132 242]) && numSS==1
    % Pad 1 bit per symbol to "make up for NCBPS coded bits": IEEE
    % 802.11-16/0620 and IEEE P802.11be/D2.0, Section 36.3.13.3.2

    % We required NCBPSLAST in this case to calculate whether we need
    % to pad the last symbol.
    assert(nargin>5);
    NCBPSLAST = varargin{1};

    % If the pre-FEC padding factor is 4 then we need to pad all symbols
    % including the last mSTBC with 1 bit. We need to pad the last mSTBC as
    % NDBPS and NCBPS are note consistent. If the pre-FEC padding factor is
    % not 4 then the post-FEC padding takes care of the padding for the
    % last symbol. NOTE: as STBC is not used with DCM we only have to worry
    % about 1 symbol at the end, not 2.
    numCBPSPrePad = numCBPSSI-1; % Need to pad 1 bit
    [numSamples,numSS,numSeg] = size(x);
    if NCBPSLAST~=numCBPSSI
        % We only need to pad 1 bit to symbols before the last
        extraBits = mod(numSamples,numCBPSPrePad);
        NSYMToPad = ((numSamples-extraBits)/numCBPSPrePad)-1;
    else
        % We need to add 1 bit padding to all symbols
        NSYMToPad = numSamples/numCBPSPrePad;
    end
    xToPad = x(1:(numCBPSPrePad*NSYMToPad*numSS));
    perSymbol = reshape(permute(xToPad,[1 4 2 3]),numCBPSPrePad,NSYMToPad,numSS,numSeg);
    perSymbolPadded = [perSymbol; zeros(1,NSYMToPad,numSS,numSeg,'like',perSymbol)]; % Pad with '0'
    xPadded = permute(reshape(perSymbolPadded,numCBPSSI*NSYMToPad,numSS,numSeg),[1 3 4 2]);
    xToInterleave = [xPadded; x(numCBPSPrePad*NSYMToPad*numSS+1:end)];
else
    xToInterleave = x;
end

% Interleave
y = wlan.internal.bccInterleaveCore(xToInterleave,numBPSCS,numCBPSSI,numCol,numRow,numRot);

end