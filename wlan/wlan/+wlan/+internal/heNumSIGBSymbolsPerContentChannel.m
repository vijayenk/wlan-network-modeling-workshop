function numSym = heNumSIGBSymbolsPerContentChannel(numChannels,numUsersPer20,numCommonFieldBits,NDBPS)
%heNumSIGBSymbolsPerContentChannel Number of symbols in HE SIG-B content channels
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

numSymPerContentChannel = zeros(1,numChannels);
for i = 1:numChannels
    % The allocation for one content channel is every second 20 MHz channel
    % allocation. The lower central 26 tone is carried in the first content
    % channel and the second central 26 tone RU on the second content
    % channel
    % Get the number of pairs and any leftover users
    numPairs = floor(numUsersPer20(i)/2);
    numLeftover = mod(numUsersPer20(i),2);
    % Each pair and any left-over user have 6 tail bits and 4 crc bits
    % appended
    numUserFieldBits = 21*numUsersPer20(i)+(6+4)*(numPairs+numLeftover);
    % Determine the number of symbols required to transmit all the content
    % channel bits
    numContentChannelDataBits = numUserFieldBits+numCommonFieldBits;
    numSymPerContentChannel(i) = ceil(numContentChannelDataBits/NDBPS);
end

% Transmit the greater number of required symbols
numSym = max(numSymPerContentChannel);

end