function activeSubchan = detectActiveSubchan(lsigDemodData,numSubchannels)
%detectActiveSubchan Detect active (non-punctured) 20 MHz subchannels from
% L-SIG demodulated symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   ACTIVESUBCHAN = detectActiveSubchan(LSIGDEMODDATA,NUMSUBCHANNELS)
%
%   ACTIVESUBCHAN are the active 20 MHz subchannels. It is a column vector
%   of logical values with size equal to the number of 20 MHz subchannels
%   in the current bandwidth.
%
%   LSIGDEMODDATA are the L-SIG demodulated symbols
%
%   NUMSUBCHANNELS are the number of 20 MHz subchannels in the current
%   bandwidth.

%   Copyright 2025 The MathWorks, Inc.

% Average the L-SIG and RL-SIG fields if present
lsigDemodData = mean(lsigDemodData,2);

% Average the powers of L-SIG demodulated symbols over receiver antennas
lsigDemodDataRx = mean(lsigDemodData,3);

% Find the average power of each 20 MHz subchannel
subChPower = mean(abs(reshape(lsigDemodDataRx,[],numSubchannels)).^2,1);

% Normalize the powers with the maximum power
normPower = subChPower./max(subChPower);

if max(subChPower)~=0
    % If the normalized power is above a threshold, the subchannel is
    % active
    activeSubchan = (normPower>1e-2).'; % 1e-2 is computed empirically
else
    % when subChPower has all zeros, assign 1's to activeSubChan to avoid
    % NaN
    activeSubchan = true(numSubchannels,1);
end
end