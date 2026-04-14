function [ruSize,maxRUIndex] = validateEHTRUArgument(ruSize,ruIndex,cbw)
%validateEHTRUArgument Validate the RU argument
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [RUSIZE,RUINDEX] = validateEHTRUArgument(RUSIZE,RUINDEX,CBW) returns
%   the RU size and RU index for a given channel bandwidth in MHz. The RU
%   size and index are validated based on the channel bandwidth.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Validate that RU size and index must have same size
coder.internal.errorIf(numel(ruSize)~=numel(ruIndex),'wlan:wlanEHTTBConfig:InvalidRUSizeIndex');

% Validate that RU size is valid given bandwidth
maxrusize = [242 484 996 2*996 4*996];
bwmaxrusize = maxrusize(log2(cbw/20)+1);
coder.internal.errorIf(any(ruSize>bwmaxrusize),'wlan:he:InvalidRUSizeForBandwidth',bwmaxrusize);

% Validate that RU index is valid given bandwidth
for iru = 1:numel(ruSize)
    maxRUIndex = wlan.internal.ehtMaxNumRUs(cbw,ruSize(iru));
    coder.internal.errorIf(ruIndex(iru)>maxRUIndex,'wlan:he:InvalidRUIndex',maxRUIndex);
end

% Validate that allocation indices result in non-overlapping subcarriers between resource units.
ruInd = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize,ruIndex);
coder.internal.errorIf(numel(ruInd(:))~=numel(unique(ruInd(:))),'wlan:eht:InvalidRUAllocation'); % For codegen

end