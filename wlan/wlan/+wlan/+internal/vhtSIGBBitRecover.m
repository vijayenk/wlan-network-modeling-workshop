function bits = vhtSIGBBitRecover(sym, noiseVarEst, csi, chanBW, ofdmInfo)
%vhtSIGBBitRecover Recover information bits in VHT-SIG-B field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS = vhtSIGBBitRecover(SYM, NOISEVAREST, CSI, CHANBW, OFDMINFO)
%   recovers the information bits in the VHT-SIG-B field.
%
%   BITS is an int8 column vector containing the recovered information
%   bits.
%
%   SYM is a complex column vector of length Nsd containing the equalized
%   symbols at data subcarriers. Nsd represents the number of data
%   subcarriers.
%
%   NOISEVAREST is the single or double noise variance estimate. It is a
%   real nonnegative scalar.
%   
%   CSI is the channel state information and is a 48-by-1 column vector of
%   real values of type single or double.
%
%   CHANBW is the channel bandwidth and must be 'CBW20', 'CBW40', or
%   'CBW80'.
%
%   OFDMINFO is a structure containing OFDM parameters.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Segment parsing of symbols
deparserOut = wlanSegmentParseSymbols(sym, chanBW); % [numSD/numSeg, 1, 1, numSeg]
csiDeparserOut = wlanSegmentParseSymbols(csi, chanBW);

% Number of bits per subcarrier per spatial stream
numBPSCS = 1;
% Constellation demapping
qamDemodOut = wlanConstellationDemap(deparserOut, noiseVarEst, numBPSCS);

% Apply CSI and concatenate OFDM symbols in the first dimension
numSeg = 1 + strcmp(chanBW,'CBW160');
qamDemodOut = reshape(qamDemodOut .* csiDeparserOut, [], 1, numSeg);

% Number of data subcarriers
numSD = length(ofdmInfo.DataIndices);
% Number of coded bits per OFDM symbol (BPSK modulation)
numCBPS = numSD;
% Number of coded bits per OFDM symbol per spatial stream per interleaver
% block (1 spatial stream)
numCBPSSI = numCBPS/numSeg;
% Number of encoded streams
numES = 1;

% BCC Deinterleaving
deintlvrOut = wlanBCCDeinterleave(qamDemodOut, 'VHT', numCBPSSI, chanBW);

% Segment deparsing of bits
parserOut = wlanSegmentDeparseBits(deintlvrOut, chanBW, numES, numCBPS, numBPSCS);

% Remove redundant zeros between information bit repetitions
if strcmp(chanBW, 'CBW80')
    infoBitRep = parserOut(1:end-2, :);
elseif strcmp(chanBW, 'CBW160')
    infoBitRep = parserOut([1:end/2-2,end/2+1:end-2], :);
else
    infoBitRep = parserOut;
end

% BCC decoding: length 26 for 'CBW20', 27 for 'CBW40' and 29 for 'CBW80'
% and 'CBW160'
num20 = ofdmInfo.NumSubchannels;
recBitLen = length(infoBitRep)/num20/2;
bits = wlanBCCDecode(mean(reshape(infoBitRep, [], num20), 2), '1/2', recBitLen);

end