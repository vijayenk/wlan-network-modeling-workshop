function stsIdxs = getSTSIndices(cfg,userIdx)
%getSTSIndex Extract STS indices for the specified user
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   STSIDX = getSTSIndex(CFG,USERIDX) returns the space-time stream
%   indices for the specific user. The USERIDX input only applies when CFG
%   is a wlanHEMUConfig or a wlanEHTMUConfig.
%
%   Copyright 2025 The MathWorks, Inc.

%#codegen

cfgType = class(cfg);
if contains(cfgType,"VHT") && ~isscalar(cfg.NumSpaceTimeStreams) % VHT MU Config Object
    % Index into streams for the user of interest
    numSTSVec = cfg.NumSpaceTimeStreams; % Num of STSs for all users
    numSTSu = numSTSVec(userIdx); % Num of STSs for current user
    stsIdxs = sum(numSTSVec(1:(userIdx-1)))+(1:numSTSu);
elseif contains(cfgType,"MU") % EHT/HE MU config object
    allSTSIdxs = wlan.internal.heSpaceTimeStreamIndices(cfg);
    stsIdxs = allSTSIdxs(1,userIdx):allSTSIdxs(2,userIdx);
elseif contains(cfgType,"Recovery") && contains(packetFormat(cfg),"MU") % EHT/HE MU Recovery Object
    stsIdxs = cfg.SpaceTimeStreamStartingIndex:(cfg.SpaceTimeStreamStartingIndex+cfg.NumSpaceTimeStreams-1);
elseif contains(cfgType,"TB")
    % Get space-time stream indices for the current user
    stsIdxs = cfg.StartingSpaceTimeStream-1+(1:cfg.NumSpaceTimeStreams);
else % VHT/HE/EHT SU config object
    stsIdxs = 1:cfg.NumSpaceTimeStreams;
end

end