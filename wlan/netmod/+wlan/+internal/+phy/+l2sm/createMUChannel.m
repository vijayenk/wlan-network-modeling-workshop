function [pathGains,pathDelays,userTxIdx] = createMUChannel(sig)
%createMUChannel Create multi-user channel info from signals
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PATHGAINS,PATHDELAYS,USERTXIDX] = createMUChannel(SIG) returns
%   combined channel information from the structure array SIG. Channels in
%   each signal are combined into a single MIMO channel for OFDMA, with
%   different transmit antennas for each signal. This assumes the channel
%   snapshot time is the same for all signals. USERTXIDX is a cell array
%   containing the transmit antenna indices for each signal in the
%   resultant PATHGAINS.

%   Copyright 2022-2025 The MathWorks, Inc.

% If all channels have same channel snapshot times combine together into a
% combined path gains and path delays array

% Create vector of all possible path delays from all signal channels
allPathDelays = [sig.PathDelays];
pathDelays = unique(allPathDelays,'sorted');

% Get the number of transmit antennas in each channel
numSig = numel(sig);
numCS = zeros(1,numSig);
numTx = zeros(1,numSig);
numRx = zeros(1,numSig);
for i = 1:numSig
    [numCS(i),~,numTx(i),numRx(i)] = size(sig(i).PathGains);
end
assert(all(numCS==numCS(1)),'All signal channels must have the same number of snapshots')
assert(all(numRx==numRx(1)),'All signal channels must have the same number of receive antennas')

% Combine all path gains by finding the path gains in each signal
% associated with each path delay
pathGains = zeros(numCS(1),numel(pathDelays),sum(numTx),numRx(1));
% Offset for the starting transmit antenna inde for each user
offsets = cumsum([0 numTx(1:end-1)]);
% Transmit antennas indices for each signal within combined pathGains
userTxIdx = cell(1,numSig);
for i = 1:numSig
    [l,~] = find(sig(i).PathDelays==pathDelays');
    userTxIdx{i} = offsets(i)+(1:numTx(i));
    pathGains(:,l,userTxIdx{i},:) = sig(i).PathGains;
end
end
