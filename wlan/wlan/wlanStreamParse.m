function y = wlanStreamParse(x,numSS,numCBPS,numBPSCS)
%wlanStreamParse Stream parser
%
%   Y = wlanStreamParse(X,NUMSS,NUMCBPS,NUMBPSCS) parses encoded bits X
%   into spatial streams following the operation defined in IEEE
%   802.11-2020 Sections 19.3.11.8.2 and 21.3.10.6, and IEEE 802.11ax-2021
%   Section 27.3.12.6.
%
%   Y is a matrix of size (Ncbpss*Nsym)-by-NUMSS containing stream-parsed
%   data, where Ncbpss is the number of coded bits per OFDM symbol per
%   spatial stream, Nsym is the number of OFDM symbols, and NUMSS is the
%   number of spatial streams.
%
%   X is a matrix of size (Ncbps*Nsym/Nes)-by-Nes containing the encoded
%   bits, where Nes is the number of encoded streams.
%
%   NUMSS is a positive integer specifying the number of spatial streams.
%
%   NUMCBPS is a positive integer specifying the number of coded bits per
%   OFDM symbol. Typically, NUMCBPS is NUMBPSCS*NUMSS*Nsd, where Nsd is the
%   number of data-carrying subcarriers.
%
%   NUMBPSCS is a positive integer specifying the number of coded bits per
%   subcarrier per spatial stream.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate arguments
validateattributes(numBPSCS,{'numeric'},{'scalar','positive','integer'},mfilename,'numBPSCS');
coder.internal.errorIf(numBPSCS~=1 & mod(numBPSCS,2),'wlan:wlanStreamParse:InvalidNUMBPSCS'); % Must be 1 or even
validateattributes(numSS,{'numeric'},{'scalar','positive','integer'},mfilename,'numSS');
validateattributes(numCBPS,{'numeric'},{'scalar','positive','integer'},mfilename,'numCBPS');

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(0,numSS,'like',x);
    return;
end

validateattributes(x,{'single','double','int8'},{'2d'},mfilename,'Input x');

if (size(x,2) == 1) && (numSS == 1) % 1 encoded stream & 1 spatial stream
    y = x;
    return
end

coder.internal.errorIf(mod(numel(x),numCBPS) ~= 0,'wlan:wlanStreamParse:InvalidInputSizeNUMCBPS'); % Integer number of OFDM symbols

% IEEE Std 802.11-2020, Sections 19.3.11.8.2 and 21.3.10.6
numES = size(x,2);
blkSize = max(1,numBPSCS/2); % Eq. 21.68
sumS = numSS*blkSize;
numBlock = floor(numCBPS/(numES*sumS)); % Eq. 21.69
% Number of OFDM symbols
numSym = size(x,1)*numES/numCBPS;
% Number of coded bits per OFDM symbol per spatial stream
numCBPSS = numCBPS/numSS;

% Cross-validation between inputs and numES (size(x,2))
coder.internal.errorIf(~(numCBPS == numBlock*numES*sumS || numES == numSS),'wlan:wlanStreamParse:InvalidInputRelation');

tailLen = numCBPS - numBlock*numES*sumS;
if tailLen>0
    % Stream parsing per OFDM symbol when numCBPS > numBlock*numES*sumS
    % (Ref: IEEE Std 802.11-2020, Section 21.3.10.6)
    % VHT 'CBW160', numSS = 5, MCS = 5
    % VHT 'CBW160', numSS = 5, MCS = 6
    % VHT 'CBW160', numSS = 7, MCS = 5
    % VHT 'CBW160', numSS = 7, MCS = 6
    y = coder.nullcopy(zeros(numCBPSS*numSym,numSS,'like',x));
    M = tailLen/(blkSize*numES); % Eq. 21.70
    % M must be integer as it is the number of spatial streams to assign tail bits to
    coder.internal.errorIf(M~=floor(M),'wlan:wlanStreamParse:InvalidInputRelation');

    % 1st part of each OFDM symbol
    firstInd = (1:numCBPSS-M*blkSize).' + (0:numSym-1) * numCBPSS;
    tempSym = reshape(x(firstInd(:),:),blkSize,numSS,[],numES); % [blkSize, numSS, numBlock, numES]
    tempSym = permute(tempSym,[1 4 3 2]); % [blkSize, numES, numBlock, numSS]
    y(firstInd(:),:) = reshape(tempSym,[],numSS); % [numCBPSS-M*blkSize, numSS]

    % 2nd part of each OFDM symbol
    secondInd = (numCBPSS-M*blkSize+1:numCBPSS).' + (0:numSym-1) * numCBPSS;
    for k = 1:numSym
        tempSym2 = reshape(x(secondInd(:,k),:),blkSize,numSS,[]); % [blkSize, numSS, M]
        tempSym2 = permute(tempSym2,[1 3 2]); % [blkSize, M, numSS]
        y(secondInd(:,k),:) = reshape(tempSym2,[],numSS); % [M*blkSize, numSS]
    end
else % Stream parsing for all OFDM symbols with no tail
    tempX = reshape(x,blkSize,numSS,[],numES); % [blkSize, numSS, numBlock*numSym, numES]
    tempX = permute(tempX,[1 4 3 2]); % [blkSize, numES, numBlock*numSym, numSS]
    y = reshape(tempX,[],numSS); % [numCBPSS*numSym, numSS]
end

end
