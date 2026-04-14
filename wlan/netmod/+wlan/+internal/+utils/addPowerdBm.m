function totalPowerindBm = addPowerdBm(firstPower, secondPower)
%addPowerdBm Returns the total power in dBm for two power values of units
%in dBm
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

totalPowerinmW = db2pow(firstPower) + db2pow(secondPower);
totalPowerindBm = pow2db(totalPowerinmW);
end