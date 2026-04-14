function [MCS,PSDULength] = interpretLSIG(recLSIGBits)
% InterpretLSIG Interprets recovered L-SIG bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [MCS,PSDULENGTH] = interpretLSIG(RECLSIGBITS) returns the modulation
%   and coding scheme and PSDU length given the recovered L-SIG bits.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Rate and length are determined from bits
rate = double(recLSIGBits(1:3));
bitsPSDULen = double(recLSIGBits(5+(1:12)));

% MCS rate table, IEEE Std 802.11-2016, Table 17-6.
R = wlan.internal.nonHTRateSignalBits();
mcstmp = find(all(R(1:3,:)==rate))-1;
MCS = mcstmp(1); % For codegen
PSDULength = bit2int(bitsPSDULen,12,false);

end

