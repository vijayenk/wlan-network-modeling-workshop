function [dataInd,pilotInd,tac] = heSubcarrierIndices(chanBW,varargin)
%heSubcarrierIndices HE subcarrier indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [DATAIND,PILOTIND] = heSubcarrierIndices(CHANBW,RUSIZE) returns
%   matrices containing the data and pilot indices for all RUs. Each column
%   is the indices for one RU.
%
%   CHANBW is the channel bandwidth and must be 20, 40, or 80.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, or 996.
%
%   [DATAIND,PILOTIND] = heSubcarrierIndices(CHANBW) returns matrices
%   containing the data and pilot indices assuming a full bandwidth
%   allocation.
%
%   [DATAIND,PILOTIND] = heSubcarrierIndices(CHANBW,RUSIZE,RUINDEX)
%   optionally returns the indices for only the RU specified by RUINDEX.
%
%   [DATAIND,PILOTIND,TAC] = heSubcarrierIndices(...) optionally returns a
%   structure of tone allocation constants, with the following fields:
%     NSD - Number of data carrying subcarriers in an RU
%     NSP - Number of pilot carrying subcarriers in an RU
%     NST - Total number of subcarriers in an RU

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen

ruInd = wlan.internal.heRUSubcarrierIndices(chanBW,varargin{:});
[pilotInd,tac] = wlan.internal.heRUPilotSubcarrierIndices(chanBW,varargin{:});
% Remove pilot indices from occupied subcarrier indices to determine data
% indices
dataInd = coder.nullcopy(zeros(tac.NSD,size(ruInd,2)));
for i = 1:size(ruInd,2) 
    tmp = ruInd(:,i);
    dataInd(:,i) = tmp(~(ismember(tmp,pilotInd(:,i))));
end

end