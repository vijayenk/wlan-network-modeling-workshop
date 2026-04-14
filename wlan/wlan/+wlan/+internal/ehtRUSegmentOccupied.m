function occupied = ehtRUSegmentOccupied(cbw,ruSize,ruIndex)
%ehtRUSegmentOccupied 20 MHz segment index containing the specified RU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OCCUPIED = ehtRUSegmentOccupied(CBW,RUSIZE,RUINDEX) returns a
%   NumRUs-by-NumSegment logical matrix, indicating which 20 MHz segments
%   are occupied by an RU.
%
%   CBW is the channel bandwidth and must be 20, 40, 80, 160, or 320.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, 2x996, or 4x996. It can be a scalar or array.
%
%   RUINDEX is the 1-based RU index. It must be the same size as RUSIZE.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

assert(all(size(ruSize)==size(ruIndex)));

% Get the start and end index for each 20 MHz segment in the EHT portion
N20MHz = cbw/20;
Nfft = 256;
k20MHzStart = (0:Nfft:(Nfft*N20MHz)-1)-Nfft*N20MHz/2;
k20MHzEnd = k20MHzStart+Nfft-1;

numRUs = numel(ruSize);
occupied = coder.nullcopy(false(numRUs,N20MHz));
for i = 1:numRUs
    % Get the active frequency indices for the RU of interest
    k = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize(i),ruIndex(i));

    % Determine if any subcarriers are within a 20 MHz segment
    occupied(i,:) = any(k>=k20MHzStart & k<=k20MHzEnd);
end

end