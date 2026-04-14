function validatePreEHTPowerScalingFactor(PreEHTPowerScalingFactor)
%validatePreEHTPowerScalingFactor Validate Pre-EHT power scaling factor
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

coder.internal.errorIf((PreEHTPowerScalingFactor<1/sqrt(2) || PreEHTPowerScalingFactor>1),'wlan:shared:InvalidPowerScalingFactor');

end