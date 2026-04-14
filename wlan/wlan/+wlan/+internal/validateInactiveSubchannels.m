function validateInactiveSubchannels(obj)
%validateInactiveSubchannels validate InactiveSubchannels
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   validateInactiveSubchannels(CFG) Validates the InactiveSubchannels
%   property of CFG.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

N20MHz = wlan.internal.cbwStr2Num(obj.ChannelBandwidth)/20;
coder.internal.errorIf(~any(numel(obj.InactiveSubchannels)==[1 N20MHz]), ...
    'wlan:shared:InvalidInactiveSubchannelsSize',N20MHz);
coder.internal.errorIf(all(obj.InactiveSubchannels), ...
    'wlan:shared:InvalidInactiveSubchannelsValue');
  
end