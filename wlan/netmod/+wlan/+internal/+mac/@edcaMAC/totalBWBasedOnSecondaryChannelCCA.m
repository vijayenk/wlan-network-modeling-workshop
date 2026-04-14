function bw = totalBWBasedOnSecondaryChannelCCA(obj, useLastCCAIdleDuration)
%totalBWBasedOnSecondaryChannelCCA Return available bandwidth based on
%secondary channels CCA status.
%
%   BW = totalBWBasedOnSecondaryChannelCCA(OBJ, USELASTCCAIDLEDURATION)
%   returns the available bandwidth after considering the CCA status of the
%   secondary 20 MHz channels.
%
%   BW is the available channel bandwidth after considering CCA status of
%   secondary channels, returned as 20, 40, 80, 160, or 320.
%
%   USELASTCCAIDLEDURATION is a flag indicating if last calculated CCA idle
%   duration should be used. If set to true, this function uses the last
%   calculated CCA idle duration before turning busy. If set to false, this
%   function calculates the idle duration from the current time to
%   previously captured CCA idle timestamps.

%   Copyright 2024-2025 The MathWorks, Inc.

numSubchannels = numel(obj.CCAState); % Number of primary and secondary subchannels
% This method is called after an AC won contention. An AC wins contention
% only if primary 20 MHz is available. So, a minimum of 20 MHz is available
% for TXOP.
bw = 20;
% Get the additional bandwidth based on CCA state and idle time of
% secondary subchannels
for idx = numSubchannels:-1:2
    if all(obj.CCAState(2:idx) == 0) % Secondary subchannels are idle
        % Check if the secondary subchannels are idle for required time
        if useLastCCAIdleDuration
            isChannelIdleForExpTime = (obj.LastCCAIdle2BusyDuration(2:idx)) >= obj.PIFSTime;
        else
            isChannelIdleForExpTime = (obj.LastRunTimeNS-obj.CCAIdleTimestamps(2:idx)) >= obj.RequiredSecChannelIdleTime;
        end
        if all(isChannelIdleForExpTime)
            bw = (2^idx) * 10;
            break;
        end
    end
end
end
