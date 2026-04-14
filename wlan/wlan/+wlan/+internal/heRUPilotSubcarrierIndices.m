function [ind,tac] = heRUPilotSubcarrierIndices(chanBW,ruSize,varargin)
%heRUPilotSubcarrierIndices HE RU pilot subcarrier indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   IND = heRUPilotSubcarrierIndices(CHANBW,RUSIZE) returns a matrix
%   containing the pilot indices for all RUs. Each column is the indices
%   for one RU.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, or 160.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 2*996.
%
%   IND = heRUPilotSubcarrierIndices(...,RUINDEX) optionally returns the
%   indices for only the RU specified by RUINDEX.
%
%   [IND,TAC] = heRUPilotSubcarrierIndices(...) optionally returns a
%   structure of tone allocation constants, with the following fields:
%     NSD - Number of data carrying subcarriers in an RU
%     NSP - Number of pilot carrying subcarriers in an RU
%     NST - Total number of subcarriers in an RU

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

allRUInd = wlan.internal.hePilotSubcarrierIndices(chanBW,ruSize);
ruInd = wlan.internal.heRUSubcarrierIndices(chanBW,ruSize,varargin{:});
tac = wlan.internal.heRUToneAllocationConstants(ruSize);

% Return pilot indices for RU index of interest
% IEEE Std 802.11ax-2021 Tables 27-35/37/39/40/42/43
if nargin>2
    % Return indices for a single RU
    idx = ismember(ruInd,allRUInd);
    ind = coder.nullcopy(zeros(tac.NSP,1));
    ind(:) = ruInd(idx);
else
    % Return indices for all RUs
    numRUs = wlan.internal.heMaxNumRUs(chanBW,ruSize);
    allIndPerRU = coder.nullcopy(zeros(tac.NSP,numRUs));
    for i = 1:numRUs
        tmp = ruInd(:,i);
        idx = ismember(tmp,allRUInd);
        allIndPerRU(:,i) = tmp(idx);
    end
    % Return indices for all RU indices
    ind = allIndPerRU;
end

end