function [indices,ruInd] = ehtOccupiedSubcarrierIndices(varargin)
%ehtOccupiedSubcarrierIndices Occupied indices for EHT subcarriers
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   INDICES = ehtOccupiedSubcarrierIndices(CHANBW,RUSIZE,RUINDEX) returns
%   the indices of data and pilots within occupied subcarriers given the
%   channel bandwidth, RU size, and RU index.
% 
%   INDICES is a structure with the following fields:
% 
%     Data   - Indices of data within active subcarriers
%     Pilot  - Indices of pilots within active subcarriers
% 
%   Data is a Nsd-by-1 column vector, where Nsd is the number of active
%   data subcarriers.
% 
%   Pilots is a Nsp-by-1 column vector, where Nsp is the number of active
%   pilot subcarriers.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, 160 or 320.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, 1992 (2*996), or 3984 (4*996). When RUSIZE is a vector
%   the INDICES contains the concatenated for all RUs (assuming all RUs are
%   part of an MRU).
%
%   RUINDEX is the RU index.
%
%   INDICES = ehtOccupiedSubcarrierIndices(RUIND,PILOTIND) returns the
%   indices of data and pilots within occupied subcarriers given a vector
%   of active RU subcarrier indices RUIND and pilot indices PILOTIND.
%
%   [INDICES,ACTIVERUINDICES] = ehtOccupiedSubcarrierIndices(...)
%   additionally returns a column vector containing the active RU
%   subcarrier indices (as returned by ehtRUSubcarrierIndices)

%   Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(1,3);
if isnumeric(varargin{1})
    narginchk(2,3);
    if nargin==2
        % ehtOccupiedSubcarrierIndices(RUIND,PILOTIND)
        ruInd = varargin{1};
        pilotInd = varargin{2};
        seqInd = (1:size(ruInd,1))';
        idx = ismember(ruInd,pilotInd);
    
        % Return indices in a structure
        indices = struct;
        indices.Data = seqInd(~idx); % Data indices within occupied subcarriers
        indices.Pilot = seqInd(idx); % Pilot indices within occupied subcarriers
        return
    else
        % ehtOccupiedSubcarrierIndices(CHANBW,RUSIZE,RUINDEX)
        cbw = varargin{1};
        ruSize = varargin{2};
        ruIndex = varargin{3};
    end
else
    % ehtOccupiedSubcarrierIndices(CFGHE,...)
    cfg = varargin{1};
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);

    ruToExtract = 1; % Default
    if nargin>1
        % ehtOccupiedSubcarrierIndices(CFGMU,RUOFINTEREST)
        ruToExtract = varargin{2};
    end
    ruInfoStr = ruInfo(cfg);
    ruSizes = ruInfoStr.RUSizes;
    ruSize = ruSizes{ruToExtract};
    ruIndex = ruInfoStr.RUIndices{ruToExtract};
end

% Get the occupied data and pilot subcarrier indices
if isscalar(ruSize)
    ruInd = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize,ruIndex);
    pilotInd = wlan.internal.ehtPilotSubcarrierIndices(cbw,ruSize);
    indices = wlan.internal.ehtOccupiedSubcarrierIndices(ruInd,pilotInd);
else
    % Process per RU and combine
    offset = cumsum([0 ruSize]);
    ruInd = zeros(0,1);
    indices = struct('Data',zeros(0,1),'Pilot',zeros(0,1));
    for r = 1:numel(ruSize)
        % Get the occupied data and pilot subcarrier indices
        subRUInd = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSize(r),ruIndex(r));
        pilotInd = wlan.internal.ehtPilotSubcarrierIndices(cbw,ruSize(r));
        subIndices = wlan.internal.ehtOccupiedSubcarrierIndices(subRUInd,pilotInd);
        ruInd = [ruInd; subRUInd]; %#ok<AGROW> 
        indices.Data = [indices.Data; offset(r)+subIndices.Data];
        indices.Pilot = [indices.Pilot; offset(r)+subIndices.Pilot];
    end
end
end
