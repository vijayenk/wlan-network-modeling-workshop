function validateEHTRUSize(RUSize)
%validateEHTRUSize Validate EHT Resource Unit (RU) size
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

mustBeNumeric(RUSize);
mustBeNonempty(RUSize);

if isscalar(RUSize)
    mustBeMember(RUSize,[26 52 106 242 484 996 1992 3984]);
else % MRU: 26+52(78), 106+26(132), 242+484(726), 996+484(1480), 996+484+242(1722), 2x996+484(2476), 3x996(2988), 3x996+484(3472)
    coder.internal.errorIf(~all(ismember(RUSize,[26 52 106 242 484 996])) || ~any(sum(RUSize)==[78 132 726 1480 1722 2476 2988 3472]),'wlan:wlanEHTTBConfig:InvalidRUSize');
end
end
