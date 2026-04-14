function [freqInd,pilotIdx] = nonHTToneIndices(numSubchannels)
%nonHTToneIndices Non-HT tone indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [FREQIND,PILOTIND] = nonHTToneIndices(NUMSUBCHANNELS) returns the
%   subcarrier frequency indices for active subcarrier and pilots for
%   non-HT fields, given the number of 20MHz subchannels.

%   Copyright 2018-2021 The MathWorks, Inc.

%#codegen

pilotIdx20 = [-21; -7; 7; 21];
freqInd20 = [-26:-1 1:26].';
if numSubchannels==1
    pilotIdxTmp = pilotIdx20;
    freqIndTmp = freqInd20;
else
    % Replicate indices for each 20 MHz subchannel
    maxOffset = 64*(numSubchannels-1);
    freqIndTmp = freqInd20 + (0:64:maxOffset) - maxOffset/2;
    pilotIdxTmp = pilotIdx20 + (0:64:maxOffset) - maxOffset/2;
end

% Indices returned as column vectors
freqInd = freqIndTmp(:);
pilotIdx = pilotIdxTmp(:);

end