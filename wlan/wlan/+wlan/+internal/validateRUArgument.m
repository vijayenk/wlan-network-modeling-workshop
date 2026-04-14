function [rusize,ruindex] = validateRUArgument(ru,cbw)
%validateRUArgument Validate the RU argument
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [RUSIZE,RUINDEX] = validateRUArgument(RU,CBW) returns the RU size and
%   RU index for a given RU vector [size index] and channel bandwidth in
%   MHz. The RU size and index are validated based on the channel
%   bandwidth.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

% Defaults for codegen
rusize = 242;
ruindex = 1;

if ~isnumeric(ru) || size(ru,2)~=2
    coder.internal.error('wlan:he:InvalidRU');
    return;
end

rusize = ru(:,1);
ruindex = ru(:,2);
% Validate that RU size is valid given bandwidth
coder.internal.errorIf(any(~ismember(rusize,[26 52 106 242 484 996 1992])),'wlan:he:InvalidRUSize');
maxrusize = [242 484 996 2*996];
bwmaxrusize = maxrusize(log2(cbw/20)+1);
coder.internal.errorIf(any(rusize>bwmaxrusize),'wlan:he:InvalidRUSizeForBandwidth',bwmaxrusize);

% Validate that RU index is valid given bandwidth
for iru = 1:numel(rusize)
    maxruindex = wlan.internal.heMaxNumRUs(cbw,rusize(iru));
    coder.internal.errorIf(ruindex(iru)<1 || ruindex(iru)>maxruindex,'wlan:he:InvalidRUIndex',maxruindex);
end

end