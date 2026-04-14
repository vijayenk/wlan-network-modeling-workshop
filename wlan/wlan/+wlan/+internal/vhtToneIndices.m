function [freqInd, pilotIdx] = vhtToneIndices(numSubchannels)
%vhtToneIndices VHT tone indices
%   [FREQIND,PILOTIND] = vhtToneIndices(NUMSC) returns the subcarrier
%   frequency indices for active subcarrier and pilots for VHT fields,
%   given the number of 20MHz subchannels.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

    switch numSubchannels
      case 1
        pilotIdx = [-21; -7; 7; 21];
        freqInd = [-28:-1 1:28].';
      case 2
        pilotIdx = [-53; -25; -11; 11; 25; 53];
        freqInd = [-58:-2 2:58].';
      case 4
        pilotIdx = [-103; -75; -39; -11; 11; 39; 75; 103];
        freqInd = [-122:-2 2:122].';
      otherwise % 8
        assert(numSubchannels==8)
        pilotIdx = [-231; -203; -167; -139; -117; -89; -53; -25; 25; 53; 89; 117; 139; 167; 203; 231];
        freqInd = [-250:-130 -126:-6 6:126 130:250].';
    end

end
