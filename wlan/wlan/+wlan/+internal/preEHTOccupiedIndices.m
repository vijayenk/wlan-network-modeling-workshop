function [dataInd,pilotInd] = preEHTOccupiedIndices(freqInd,pilotIdx)
%preEHTOccupiedIndices Pre-EHT tone indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [DATAIND,PILOTIND] = preEHTOccupiedIndices(FREQIND,PILOTIND) returns
%   the pilot and data indices within the active subcarriers in the range
%   [1, NumTones], where active subcarriers are the indices of active
%   subcarriers relative to DC in the range [-NFFT/2, NFFT/2-1].

%   Copyright 2022 The MathWorks, Inc.

%#codegen

idx = ismember(freqInd,pilotIdx);
seqInd = (1:numel(freqInd))';
pilotInd = seqInd(idx);
dataInd = seqInd(~idx);

end