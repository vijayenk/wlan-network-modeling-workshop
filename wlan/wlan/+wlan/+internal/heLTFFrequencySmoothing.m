function estSmooth = heLTFFrequencySmoothing(est,kRU,span)
%heLTFFrequencySmoothing Frequency smoothing for HE-LTF or EHT-LTF channel
%estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   ESTSMOOTH = HELTFFrequencySmoothing(EST,KRU,SPAN) perform moving
%   average filtering in the frequency domain for HE-LTF or EHT-LTF channel
%   estimation. The algorithm performs smoothing over groups of contiguous
%   subcarriers across the entire allocation. For each subcarrier, its
%   channel estimate is replaced by the average of its own value and those
%   of its neighboring subcarriers, as specified by the span parameter.
%
%   EST is an array characterizing the estimated channel for the data and
%   pilot subcarriers. EST is a complex Nst-by-Nsts-by-Nr array
%   characterizing the estimated channel for the data and pilot
%   subcarriers, where Nst is the number of occupied subcarriers, Nsts is
%   the total number of space-time streams, and Nr is the number of receive
%   antennas.
%
%   KRU represents the indices of active subcarriers relative to DC in the
%   range [-NFFT/2, NFFT/2-1].
%
%   SPAN is an positive odd scalar that indicates the width of the
%   smoothing window.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

% No smoothing when the span is 1
if span==1
    estSmooth = est;
    return;
end

estSmooth = coder.nullcopy(zeros(size(est),'like',est));

% Get the indices of the discontinuity in active subcarrier indices.
ind = find(diff(kRU)>1);

% groupOffset array stores the starting boundary of each group, beginning
% with zero to indicate the offset of the first group. Each entry specifies
% the starting position of a group in the overall allocation.
groupOffset = [0; ind];

% groupSize array specifies how many subcarriers are allocated to each
% group for frequency smoothing
groupSize = diff([groupOffset; numel(kRU)]);
for i = 1:numel(groupSize)
    idx = (1:groupSize(i)) + groupOffset(i);
    estSmooth(idx,:,:) = wlan.internal.frequencySmoothing(est(idx,:,:),span);
end
end