function y = wlanStreamDeparse(x,numES,numCBPS,numBPSCS)
%wlanStreamDeparse Stream deparser
%
%   Y = wlanStreamDeparse(X,NUMES,NUMCBPS,NUMBPSCS) deparses spatial
%   streams in stream-parsed data X to form encoded streams. Stream
%   deparsing is the inverse of the operation defined in IEEE 802.11-2020
%   Sections 19.3.11.8.2 and 21.3.10.6, and IEEE 802.11ax-2021, Section
%   27.3.12.6.
%
%   Y is a matrix of size (Ncbps*Nsym/Nes)-by-Nes containing
%   stream-deparsed data, where Ncbps is the number of coded bits per OFDM
%   symbol, Nsym is the number of OFDM symbols, and Nes is the number of
%   encoded streams.
%
%   X is a matrix of size (Ncbpss*Nsym)-by-Nss containing stream-parsed
%   data, where Ncbpss is the number of coded bits per OFDM symbol per
%   spatial stream and Nss is the number of spatial streams.
%
%   NUMES is a positive integer representing the number of encoded streams.
%
%   NUMCBPS is a positive integer specifying the number of coded bits per
%   OFDM symbol. Typically, NUMCBPS is NUMBPSCS*Nss*Nsd, where Nsd is the
%   number of data-carrying subcarriers.
%
%   NUMBPSCS is a positive integer specifying the number of coded bits per
%   subcarrier per spatial stream.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate arguments
validateattributes(numBPSCS,{'numeric'},{'scalar','positive','integer'},mfilename,'numBPSCS');
coder.internal.errorIf(numBPSCS~=1 & mod(numBPSCS,2),'wlan:wlanStreamParse:InvalidNUMBPSCS'); % Must be 1 or even
validateattributes(numES,{'numeric'},{'scalar','integer','positive'},mfilename,'numES');
validateattributes(numCBPS,{'numeric'},{'scalar','integer','positive'},mfilename,'numCBPS');

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(0,numES,'like',x);
    return;
end

validateattributes(x,{'double','single'},{'2d'},mfilename,'Input x');

if (size(x, 2) == 1) && (numES == 1) % 1 spatial stream and 1 encoded stream
    y = x;
    return
end

coder.internal.errorIf(mod(numel(x),numCBPS) ~= 0,'wlan:wlanStreamParse:InvalidInputSizeNUMCBPS'); % Integer number of OFDM symbols

numSS = size(x,2);
blkSize = max(1,numBPSCS/2); % Eq. 21.68
sumS = numSS*blkSize;
numBlock = floor(numCBPS/(numES*sumS)); % Eq. 21.69
% Number of coded bits per OFDM symbol per spatial stream
numCBPSS = numCBPS/numSS;
% Number of OFDM symbols
numSym = size(x,1)/numCBPSS;

% Cross-validation between inputs and numSS (size(x,2))
coder.internal.errorIf(~(numCBPS == numBlock*numES*sumS || numES == numSS),'wlan:wlanStreamParse:InvalidInputRelation');

tailLen = numCBPS - numBlock*numES*sumS;
if tailLen>0
    % Stream deparsing per OFDM symbol when numCBPS > numBlock*numES*sumS
    % (Ref: IEEE Std 802.11-2020, Section 21.3.10.6)
    % VHT 'CBW160', numSS = 5, numES = 5, MCS = 5
    % VHT 'CBW160', numSS = 5, numES = 5, MCS = 6
    % VHT 'CBW160', numSS = 7, numES = 7, MCS = 5
    % VHT 'CBW160', numSS = 7, numES = 7, MCS = 6
    assert(numES==numSS) % Above cases on valid in this condition
    y = zeros(numCBPSS*numSym,numSS,'like',x);
    M = tailLen/(blkSize*numES); % Eq. 21.70
    % M must be integer as it is the number of spatial streams to assign tail bits to
    coder.internal.errorIf(M~=floor(M),'wlan:wlanStreamParse:InvalidInputRelation');

    % 1st part of each OFDM symbol
    firstInd = (1:numCBPSS-M*blkSize).' + (0:numSym-1) * numCBPSS;
    tempSym = reshape(x(firstInd(:),:),blkSize,numES,[],numSS); % [blkSize, numES, numBlock, numSS]
    tempSym = permute(tempSym,[1 4 3 2]); % [blkSize, numSS, numBlock, numES]
    tempSymReshape = reshape(tempSym,[],numES); % For codegen
    y(firstInd(:),1:numES) = tempSymReshape(:,1:numES); % [numCBPSS-M*blkSize, numES]

    % 2nd part of each OFDM symbol
    secondInd = (numCBPSS-M*blkSize+1:numCBPSS).' + (0:numSym-1) * numCBPSS;
    for k = 1:numSym
        tempSym2 = reshape(x(secondInd(:,k),:),blkSize,[],numSS); % [blkSize, M, numSS]
        tempSym2 = permute(tempSym2,[1 3 2]); % [blkSize, numSS, M]
        tempSym2Reshape = reshape(tempSym2,[],numES); % For codegen
        y(secondInd(:,k),1:numES) = tempSym2Reshape(:,1:numES); % [M*blkSize, numES]
    end
else % Stream deparsing for all OFDM symbols with no tail
    tempX = reshape(x,blkSize,numES,[],numSS); % [blkSize, numES, numBlock*numSym, numSS]
    tempX = permute(tempX,[1 4 3 2]); % [blkSize, numSS, numBlock*numSym, numES]
    y = reshape(tempX,[],numES); % [(numCBPS*numSym/numES), numES]
end

end
