function y = ldpcEncode(x,cfg)
%ldpcEncode Low-Density-Parity-Check (LDPC) encoder
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ldpcEncode(X, CFG) encodes the binary input data X using LDPC
%   parameters as specified in CFG. The input data is LDPC encoded as
%   defined in [1], section 19.3.11.7.5 and section 21.3.10.5.4
%   respectively.
%
%   Input X must be a column vector of length equal to number of SERVICE,
%   PSDU and Padding bits.
%
%   CFG should be a structure including the fields:
%   VecPayloadBits   - Number of payload bits within a codeword
%   Rate             - Coding rate
%   NumCW            - Number of LDPC codewords
%   LengthLDPC       - LDPC codeword length
%   VecShortenBits   - Vector of shortening bits in each codeword
%   VecPunctureBits  - Vector of puncture bits in each codeword
%   VecRepeatBits    - Number of coded bits to be repeated
%   NumAvailableBits - Number of available bits
%
%   %   References:
%   [1] IEEE Std 802.11(TM)-2020 IEEE Standard for Information technology -
%   Telecommunications and information exchange between systems - Local and
%   metropolitan area networks - Specific requirements - Part 11: Wireless
%   LAN Medium Access Control (MAC) and Physical Layer (PHY)
%   Specifications.
%
%   See also ldpcDecode, getLDPCparameters. 

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

numCW            = cfg.NumCW;
lengthLDPC       = cfg.LengthLDPC;
vecShortenBits   = cfg.VecShortenBits; 
vecPunctureBits  = cfg.VecPunctureBits;
numPunctureBits  = sum(cfg.VecPunctureBits);
vecRepeatBits    = cfg.VecRepeatBits;
vecPayloadBits   = cfg.VecPayloadBits;
rate             = cfg.Rate;
shortBoundary    = cfg.ShortBoundary;

if shortBoundary == 0
    % Only one value contained within vecPayloadBits and vecShortenBits
    uniqNumPayloadBits = vecPayloadBits(1);
    uniqShortBits = vecShortenBits(1);
    blkData = [reshape(x,uniqNumPayloadBits,[]);zeros(uniqShortBits,numCW)];
else
    % Two unique values contained within vecPayloadBits and vecShortenBits
    % These two values are separated by the shortBoundary
    uniqNumPayloadBits = [vecPayloadBits(1) vecPayloadBits(shortBoundary+1)];
    uniqShortBits = [vecShortenBits(1) vecShortenBits(shortBoundary+1)];
    bits = x(1:uniqNumPayloadBits(1)*shortBoundary);
    reshapeBits = [reshape(bits,uniqNumPayloadBits(1),[]);zeros(uniqShortBits(1),shortBoundary)];
    bits2 = x(uniqNumPayloadBits(1)*shortBoundary+1:end);
    reshapeBits2 = [reshape(bits2,uniqNumPayloadBits(2),[]);zeros(uniqShortBits(2),numCW-shortBoundary)];
    blkData = [reshapeBits reshapeBits2];
end

parityBits = wlan.internal.ldpcEncodeCore(blkData, rate); % NumParityBits-by-NumCWs

startIdx = 0;
dataIdx  = 0;
y = coder.nullcopy(zeros(cfg.NumAvailableBits,1,'int8'));

for nCW = 1:numCW 
    inpBits = x(startIdx+(1:vecPayloadBits(nCW)));
    if(numPunctureBits > 0) % Puncturing
        outPunc = parityBits(1:end-(vecPunctureBits(nCW)),nCW);
        out = [inpBits;outPunc];
    else % Repetition
        % Compute the number of coded bits to be repeated
        infoParityBits = [inpBits;parityBits(:,nCW)];
        % Code word length after Shortening and Repeating
        cwLength = lengthLDPC - vecShortenBits(nCW) + vecRepeatBits(nCW);
        % Extend the length of the coded bits by appending repeating bits
        repeatFactor = ceil(cwLength/length(infoParityBits));
        repeatBlkData = kron(ones(1, repeatFactor,'int8'), infoParityBits.');
        out = repeatBlkData(1:cwLength).';
    end
    y(dataIdx+(1:length(out))) = out;         % Store output
    startIdx = startIdx + vecPayloadBits(nCW);% Update index
    dataIdx  = dataIdx+length(out);
end
