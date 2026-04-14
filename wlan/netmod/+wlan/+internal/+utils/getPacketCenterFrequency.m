function packetCenterFreq = getPacketCenterFrequency(operatingFreq, operatingBW, ...
    primaryChannelIndex, packetBW, centerFreqOffsetList)
%getPacketCenterFrequency Returns the center frequency for the current
%transmit packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PACKETCENTERFREQ = getPacketCenterFrequency(OPERATINGFREQ, OPERATINGBW,
%   PRIMARYCHANNELINDEX, PACKETBW, CENTERFREQOFFSETLIST) returns the center
%   frequency of packet in Hz.
%
%   PACKETCENTERFREQ is the center frequency of current transmit packet in Hz.
%
%   OPERATINGFREQ is the center frequency of operation of a device/link in
%   Hz.
%
%   OPERATINGBW is the bandwidth of operation of a device/link in MHz.
%
%   PRIMARYCHANNELINDEX is the index of primary 20 MHz of a device/link.
%
%   PACKETBW is the bandwidth of current transmit packet in MHz.
%
%   CENTERFREQOFFSETLIST is a cell array containing center frequency offset
%   of all possible bandwdiths in a given OPERATINGBW.

%   Copyright 2024-2025 The MathWorks, Inc.

indexPacketBW = log2(packetBW/10);
% Get the candidate centerfrequency offsets for current packet BW from the
% look up table
currentCandidateCentFreqOffset = cell2mat(centerFreqOffsetList(indexPacketBW));

% Num of groups of current packet bandwidth within the operating bandwidth,
% e.g., 4 of 40 MHz non-overlapping channel grouping is possible within a
% 160 MHz operating bandwidth
numGroupsForPacketBW = operatingBW/(20*numel(currentCandidateCentFreqOffset));
indexCenFreqOffset = ceil(primaryChannelIndex/numGroupsForPacketBW);

packetCenterFreq = operatingFreq + currentCandidateCentFreqOffset(indexCenFreqOffset);
end
