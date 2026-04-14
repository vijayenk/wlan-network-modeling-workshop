function [freqInd,pilotIdx] = preEHTToneIndices(numSubchannels)
%preEHTToneIndices Pre-EHT tone indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [FREQIND,PILOTIND] = preEHTToneIndices(NUMSUBCHANNELS) returns the
%   subcarrier frequency indices for active subcarrier and pilots for
%   pre-EHT fields, given the number of 20 MHz subchannels.
%
%   FREQIND and PILOTIND are the indices of active subcarriers relative to
%   DC in the range [-NFFT/2, NFFT/2-1].

%   Copyright 2022 The MathWorks, Inc.

%#codegen

pilotIdx20 = [-21; -7; 7; 21];
freqInd20 = [-28:-1 1:28].';
% Replicate indices for each 20 MHz subchannel
switch numSubchannels
    case 1
        pilotIdxTmp = pilotIdx20;
        freqIndTmp = freqInd20;
    case 2
        freqIndTmp = freqInd20 + [0 64] - 32;
        pilotIdxTmp = pilotIdx20 + [0 64] - 32;
    case 4
        freqIndTmp = freqInd20 + (0:64:192) - (64+32);
        pilotIdxTmp = pilotIdx20 + (0:64:192) - (64+32);
    case 8
        freqIndTmp = freqInd20 + (0:64:448) - (128+64+32);
        pilotIdxTmp = pilotIdx20 + (0:64:448) - (128+64+32);
    otherwise % 16
        assert(numSubchannels==16)
        freqIndTmp = freqInd20 + (0:64:960) - (256+128+64+32);
        pilotIdxTmp = pilotIdx20 + (0:64:960) - (256+128+64+32);
end
% Return as column vectors
freqInd = freqIndTmp(:);
pilotIdx = pilotIdxTmp(:);

end
