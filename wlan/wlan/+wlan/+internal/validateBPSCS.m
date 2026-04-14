function validateBPSCS(numBPSCS)
% validateBPSCS(numBPSCS) validates the input number of coded bits per
% subcarrier per spatial stream
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

coder.internal.errorIf(~isfloat(numBPSCS) || ~isscalar(numBPSCS) || ...
    ~any(numBPSCS == [1 2 4 6 8 10 12]), ...
    'wlan:wlanConstellationMap:InvalidNUMBPSCSMap');

end