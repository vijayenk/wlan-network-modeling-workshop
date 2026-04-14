function [ofdmCfg, varargout] = hePreHEOFDMConfig(chanBW,varargin)
% hePreHEOFDMConfig obtains OFDM configuration parameters for pre-HE fields
% 
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OFDMCFG = hePreHEOFDMConfig(CHANBW) returns the OFDM configuration as a
%   structure.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   which must be one of the following: 'CBW20','CBW40','CBW80','CBW160'.
%
%   OFDMCFG = hePreHEOFDMConfig(CHANBW,FIELDNAME) returns the OFDM
%   configuration as a structure for the specified field name. The default
%   is 'L-SIG'.
%
%   [...,DATAINDNST,PILOTINDNST] = hePreHEOFDMConfig(...) additionally
%   returns the indices of data and pilots within the occupied subcarriers.
%   Both data and pilot indices are column vectors.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

nargoutchk(0,3);

[FFTLen,numSubchannels] = wlan.internal.cbw2nfft(chanBW);

if nargin>1
    cbw = wlan.internal.cbwStr2Num(chanBW);
    field = varargin{1};
    numTones = wlan.internal.heToneScalingFactor(field,cbw);
else
    numTones = (52+4)*numSubchannels;
end

if nargin>2
    numTXSTS = varargin{2};
else
    numTXSTS = 1; % Assume 1 antenna for normalization
end

% 'Long'
CPLen = FFTLen/4;

numGuardBandsTotal = (FFTLen-numTones-numSubchannels)/numSubchannels;
numGuardBands = [ceil(numGuardBandsTotal/2) floor(numGuardBandsTotal/2)];

pilotIdx20MHz =  [12; 26; 40; 54];
normFactor = FFTLen/sqrt(numTones*numTXSTS); 

% Get non-data subcarrier indices per 20MHz channel bandwidth
nonDataIdxPerGroup = [(1:numGuardBands(1))'; 33; (64-numGuardBands(2)+1:64)'; pilotIdx20MHz];
% Get non-data subcarrier indices for the whole bandwidth
nonDataIdxAll = nonDataIdxPerGroup + 64 * (0:numSubchannels-1);
Nsd = numTones-4*numSubchannels; % Subtract 4 pilot tones per 20 MHz
dataIdx = coder.nullcopy(zeros(Nsd,1));
tmp = (1:FFTLen)';
dataIdx(:) = tmp(~(ismember(tmp,sort(nonDataIdxAll(:)))));
pilotIdx = reshape(pilotIdx20MHz+64*(0:numSubchannels-1),[],1);

ofdmCfg = struct( ...
    'FFTLength',           FFTLen, ...
    'NumSubchannels',      numSubchannels, ...
    'CyclicPrefixLength',  CPLen, ...
    'DataIndices',         dataIdx, ...
    'PilotIndices',        pilotIdx, ...
    'NormalizationFactor', normFactor, ...
    'NumTones',            numTones);

if nargout>1
    % Transform indices addressing whole FFT length, to indices addressing
    % occupied subcarriers
    allIndices = [dataIdx; pilotIdx];
    [~,idxOccupiedSubcarriers] = ismember(allIndices,sort(allIndices));
    dataIndNst = idxOccupiedSubcarriers(1:Nsd); % Data indices within occupied subcarriers
    varargout{1} = dataIndNst;
    if nargout>2
        Nsp = numel(pilotIdx);
        pilotIndNst = idxOccupiedSubcarriers(Nsd+(1:Nsp)); % Pilot indices within occupied subcarriers
        varargout{2} = pilotIndNst;
    end
end
end
