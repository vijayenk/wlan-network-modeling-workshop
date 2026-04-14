function params = heRateDependentParameters(ruSize,mcs,NSS,DCM)
%heRateDependentParameters HE rate dependent parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PARAMS = heRateDependentParameters(RUSIZE,MCS,NSS,DCM) returns a
%   structure containing the rate dependent parameters according to IEEE
%   Std 802.11ax-2021, IEEE P802.11be/D7.0, and IEEE P802.11bn/D0.1,
%   January 2025.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 78,
%   106, 132, 242, 484, 726, 968, 996, 1480, 1722, 1992, 2476, 2988, 3472,
%   or 3984.
%
%   MCS is the modulation and coding scheme and must be between 0 to 15
%   (inclusive), 17, 19, 20, and 23.
%
%   NSS is the number of spatial streams.
%
%   DCM is a logical representing if dual carrier modulation is used.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

[NBPSCS,R,constellationIndex] = wlan.internal.getMCSTable(mcs);
p = wlan.internal.heRUToneAllocationConstants(ruSize);
if ~DCM
    NSD = p.NSD;
else
    if mcs==14
        % EHT-DUP mode modeled as single RU for whole bandwidth. Therefore,
        % NSD retured by heRUToneAllocationConstants for this RU size needs
        % to be adjusted.
        NSD = p.NSD/4; % Table 36-87 of IEEE P802.11be/D7.0
    else
        NSD = p.NSD/2;
    end
end

NCBPS = NSD*NBPSCS*NSS;
NDBPS = floor(NCBPS*R); % As per IEEE 802.11-16/0620

params = struct( ...
    'Rate',      R, ...
    'NBPSCS',    NBPSCS, ...
    'NSD',       NSD, ...
    'NCBPS',     NCBPS, ...
    'NDBPS',     NDBPS, ...
    'NSS',       NSS, ...
    'ModIndex',  constellationIndex);

end