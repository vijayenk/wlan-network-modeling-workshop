function [indices,ruInd] = heOccupiedSubcarrierIndices(varargin)
%heOccupiedSubcarrierIndices Occupied indices for HE subcarriers
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   INDICES = heOccupiedSubcarrierIndices(CFGHE) returns the indices of
%   data and pilots within occupied subcarriers given the format
%   configuration object CFGHE.
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
%   CFGHE is a format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, or 
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>. 
% 
%   INDICES = heOccupiedSubcarrierIndices(CFGMU,RUOFINTEREST) returns the 
%   indices for the RU of interest RUOFINTEREST for a multi-user 
%   configuration. If not provided the default is 1. CFGMU is of type 
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>.
%
%   INDICES = heOccupiedSubcarrierIndices(CHANBW,RUSIZE,RUINDEX) returns
%   the indices of data and pilots within occupied subcarriers given the
%   channel bandwidth, RU size, and RU index.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, or 160.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 1992 (2*996).
%
%   RUINDEX is the RU index.
%
%   INDICES = heOccupiedSubcarrierIndices(RUIND,PILOTIND) returns the
%   indices of data and pilots within occupied subcarriers given a vector
%   of active RU subcarrier indices RUIND and pilot indices PILOTIND.
%
%   [INDICES,ACTIVERUINDICES] = heOccupiedSubcarrierIndices(...)
%   additionally returns a column vector containing the active RU
%   subcarrier indices (as returned by heRUSubcarrierIndices)

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

narginchk(1,3);

if isnumeric(varargin{1})
    narginchk(2,3);
    if nargin==2
        % heOccupiedSubcarrierIndices(RUIND,PILOTIND)
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
        % heOccupiedSubcarrierIndices(CHANBW,RUSIZE,RUINDEX)
        cbw = varargin{1};
        ruSize = varargin{2};
        ruIndex = varargin{3};
    end
else
    % heOccupiedSubcarrierIndices(CFGHE,...)
    cfg = varargin{1};
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);

    ruToExtract = 1; % Default
    if nargin>1
        % heOccupiedSubcarrierIndices(CFGMU,RUOFINTEREST)
        ruToExtract = varargin{2};
    end
    ruInfoStr = ruInfo(cfg);
    ruSizes = ruInfoStr.RUSizes;
    ruSize = ruSizes(ruToExtract);
    ruIndex = ruInfoStr.RUIndices(ruToExtract);
end

% Get the occupied data and pilot subcarrier indices
ruInd = wlan.internal.heRUSubcarrierIndices(cbw,ruSize,ruIndex);
pilotInd = wlan.internal.hePilotSubcarrierIndices(cbw,ruSize);
indices = wlan.internal.heOccupiedSubcarrierIndices(ruInd,pilotInd);

end