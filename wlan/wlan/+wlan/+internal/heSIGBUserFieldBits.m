function y = heSIGBUserFieldBits(staid,spatialConfig,txBeamforming,mcs,dcm,codingBits,isMU)
%heSIGBUserFieldBits Generate HE-SIG-B User Field bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSIGBUserFieldBits(...) generates the HE SIG-B user field
%   bits for each user with in a resource unit.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

% IEEE Std 802.11ax-2021, Table 27-24 and 27-25
staIDBits = int2bit(staid,11,false);
mcsBits = int2bit(mcs,4,false);
dcmBits = double(dcm); % For MU-MIMO this is reserved (0)
if isMU
    % For MU-MIMO allocation per RU
    txBeamformingBits = [];
    spatialConfigUse = spatialConfig;
else
    % For single user MIMO allocation per RU
    txBeamformingBits = double(txBeamforming);
    spatialConfigUse = spatialConfig(1:3);
end

y = [staIDBits; spatialConfigUse; txBeamformingBits; mcsBits; dcmBits; codingBits];
    
end


