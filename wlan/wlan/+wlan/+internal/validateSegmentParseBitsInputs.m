function numSS = validateSegmentParseBitsInputs(x, numES, numCBPS, numBPSCS)
% validateSegmentParseBitsInput validates inputs of wlanSegmentParseBits
% and wlanSegmentDeparseBits: x, numES, numCBPS, and numBPSCS. Returns
% numSS.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2017 The MathWorks, Inc.

%#codegen

% Validate number of columns of x (numSS)
coder.internal.errorIf(~any(size(x,2) == 1:8), 'wlan:wlanSegmentParseBits:InvalidInputColumnsNUMSS');
numSS = size(x, 2);

% Validate numES
wlan.internal.validateParam('NUMES', numES);

% Validate numBPSCS
wlan.internal.validateParam('NUMBPSCS', numBPSCS);

% Validate numCBPS
coder.internal.errorIf((~isscalar(numCBPS) || ~(any(numCBPS == [468 980 1960]*numBPSCS*numSS))), 'wlan:wlanSegmentParseBits:InvalidNUMCBPS');

% Cross-validation between inputs
coder.internal.errorIf(mod(numel(x), numCBPS) ~= 0, 'wlan:wlanSegmentParseBits:InvalidInputNUMCBPS');

end