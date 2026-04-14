function allocInfo =  ehtAllocationParams(allocationIndex)
%ehtAllocationParams EHT RU allocation parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   allocInfo = ehtAllocationParams(INDEX) returns a structure for an OFDMA
%   format containing information given the allocation assignment INDEX.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

% Check if allocation index are same across all 80 MHz subblock
    allocIndex = zeros(1,size(allocationIndex,1)*4);
    signalUsersPerSubblock = size(unique(allocationIndex,'rows'),1)==1;
    if signalUsersPerSubblock
        allocInfo = wlan.internal.ehtAllocationInfo(allocationIndex);
    else
        for i=1:size(allocationIndex,1) % Extract the diagonal elements per 80 MHz subblock and construct the allocation index as 1-by-N vector
            allocIndex((1:4)+4*(i-1)) = allocationIndex(i,(1:4)+4*(i-1));
        end
        allocInfo = wlan.internal.ehtAllocationInfo(allocIndex);
    end
end
