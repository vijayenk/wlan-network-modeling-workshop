function occupied = uhrDRURUSegmentOccupied(cbw,dbw,ruSize,ruIndex)
%uhrDRURUSegmentOccupied 20 MHz segment index containing the specified RU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OCCUPIED = uhrDRURUSegmentOccupied(CBW,DBW,RUSIZE,RUINDEX) returns a
%   1-by-Subchannel logical matrix, indicating which 20 MHz subchannel
%   are occupied by an RU.
%
%   CBW is the channel bandwidth and must be 20, 40, 80, 160, or 320.
%
% 	DBW is the distribution bandwidth and must be 20, 40, or 80.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, 2x996, or 4x996. It can be a scalar or array.
%
%   RUINDEX is the 1-based RU index. It must be the same size as RUSIZE.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

assert(all(size(ruSize)==size(ruIndex)));

% Get the start and end index for each 20 MHz segment in the EHT portion
N20MHz = cbw/20;
Nfft = 256;
k20MHzStart = (0:Nfft:(Nfft*N20MHz)-1)-Nfft*N20MHz/2;
k20MHzEnd = k20MHzStart+Nfft-1;

% Get the active frequency indices for the RU of interest
k = wlan.internal.uhrDRUSubcarrierIndices(cbw,dbw,ruSize,ruIndex);

% Determine if any subcarriers are within a 20 MHz segment
occupied = any(k>=k20MHzStart & k<=k20MHzEnd);


