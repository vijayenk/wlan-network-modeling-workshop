function updateCCAStateAndAvailableBW(obj, phyCCAIndication, currentTime)
%updateCCAStateAndAvailableBW Updates CCA state and available bandwidth
%based on indication from PHY
%
%   Note: This is an internal undocumented method and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2024-2025 The MathWorks, Inc.

phyCCAStatus = phyCCAIndication.Per20Bitmap;
% Number of primary and secondary channels. Secondary channels means
% secondary 20,40,80 and 160 channels.
numChannels = numel(obj.CCAState);

% Update CCA state
for idx = 1:numChannels
    isChannelIdle = true;
    startIdx = obj.Initial20MHzIndices(idx); % Starting 20 MHz index

    % Get the number of 20 MHz subchannels present in this channel
    if (idx == 1)
        num20MHzSubchannels = 1;
    else
        num20MHzSubchannels = 2^(idx-2);
    end

    % Check if any of the 20 MHz subchannels in the given channel is
    % busy
    if any(phyCCAStatus(startIdx:startIdx + num20MHzSubchannels - 1))
        isChannelIdle = false;
    end
    if isChannelIdle
        % Update timestamp if channel is idle now and was busy previously
        if obj.CCAState(idx)
            obj.CCAIdleTimestamps(idx) = currentTime;
        end
        obj.CCAState(idx) = 0;
    else
        % Update last idle duration if channel turns busy from idle
        if ~obj.CCAState(idx)
            obj.LastCCAIdle2BusyDuration(idx) = currentTime - obj.CCAIdleTimestamps(idx);
        end
        obj.CCAState(idx) = 1;
    end
end
obj.CCAStatePer20 = phyCCAStatus;

% Update available bandwidth
if obj.CCAState(1) % Primary 20 is busy
    obj.AvailableBandwidth = 0;
else
    % Assign available bandwidth if primary channel and contiguous secondary
    % channels are free.
    % [ 0 0 0 0 0 ] -> 320 MHz
    % [ 0 0 0 0 1 ] -> 160 MHz
    % [ 0 0 0 1 x ] -> 80 MHz
    % [ 0 0 1 x x ] -> 40 MHz
    % [ 0 1 x x x ] -> 20 MHz
    % [ 1 x x x x ] -> 0
    for idx = numChannels:-1:1
        if ~any(obj.CCAState(1:idx))
            obj.AvailableBandwidth = (2^idx) * 10;
            break;
        end
    end
end
end
