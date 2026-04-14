function [ofdmCfg, varargout] = getOFDMConfig(chanBW, CPType, fieldType, varargin)
% getOFDMConfig Obtain OFDM configuration parameters
% 
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OFDMCFG = getOFDMConfig(CHANBW, CPTYPE, FIELDTYPE, NUMSTS) returns the
%   OFDM configuration as a structure.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%   'CBW10', 'CBW5' are also supported and result in same configuration as
%   'CBW20'.
%
%   CPTYPE is a character vector or string and must be one of 'Long', 
%   'Short'.
%
%   FIELDTYPE is a character vector or string and must be one of 'Legacy',
%   'HT', or 'VHT'.
%
%   NUMSTS is the number of space-time streams.
%
%   [...,DATAINDNST,PILOTINDNST] = getOFDMConfig(...) additionally
%   returns the indices of data and pilots within the occupied subcarriers.
%   Both data and pilot indices are column vectors.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(3,4);
nargoutchk(0,3);

% Expect chanBW to be 5, 10, 20, 40, 80, 160, or 320 MHz
wlan.internal.validateParam('NONHTEHTCHANBW', chanBW, mfilename);

if ~isempty(varargin)
    % Need numSTS for HT or VHT (non-legacy) or numTX for legacy
    numTxSTS = varargin{1};
else
    numTxSTS = 1;
end

% FFT length and number of subchannels
[FFTLen,Num20MHzChan] = wlan.internal.cbw2nfft(chanBW);

% Carrier rotation: IEEE Std 802.11ac-2013 Section 22.3.7.5.
carrierRotation = wlan.internal.vhtCarrierRotations(Num20MHzChan);

if strcmp(CPType, 'Long')
    CPLen = FFTLen/4;
elseif strcmp(CPType, 'Short')
    CPLen = FFTLen/8;
else % 'Half'
    CPLen = FFTLen/2;
end

if strcmp(fieldType, 'Legacy') 
    numGuardBands = [6; 5]; 
    pilotIdx20MHz =  [12; 26; 40; 54];
    normFactor = FFTLen/sqrt(52*Num20MHzChan*numTxSTS);
    
    % Get non-data subcarrier indices per 20MHz channel bandwidth
    nonDataIdxPerGroup = [(1:numGuardBands(1))'; 33; (64-numGuardBands(2)+1:64)'; pilotIdx20MHz];
    % Get non-data subcarrier indices for the whole bandwidth
    nonDataIdxAll = nonDataIdxPerGroup + 64 * (0:Num20MHzChan-1);
    Nsd = 48*Num20MHzChan;
    dataIdx = coder.nullcopy(zeros(Nsd,1));
    dataIdx(:) = setdiff((1:FFTLen)', nonDataIdxAll(:), 'stable');
    pilotIdx = reshape(pilotIdx20MHz+64*(0:Num20MHzChan-1), [], 1);
else % 'HT' & 'VHT'
    switch chanBW
      case 'CBW40'
        numGuardBands = [6; 5]; 
        customNullIdx = [-1; 1];
        pilotIdx = [-53; -25; -11; 11; 25; 53];  
      case 'CBW80'
        numGuardBands = [6; 5];
        customNullIdx = [-1; 1];
        pilotIdx = [-103; -75; -39; -11; 11; 39; 75; 103];
      case 'CBW80+80' % Merge with 80MHz case, if same. Separate for now
        numGuardBands = [6; 5];
        customNullIdx = [-1; 1];
        pilotIdx = [-103; -75; -39; -11; 11; 39; 75; 103]; 
      case 'CBW160'
        numGuardBands = [6; 5];
        customNullIdx = [(-129:-127)'; (-5:-1)'; (1:5)'; (127:129)'];
        pilotIdx = [-231; -203; -167; -139; -117; -89; -53; -25; 25; 53; 89; 117; 139; 167; 203; 231]; 
      otherwise  % CBW20, CBW10, CBW5
        numGuardBands = [4; 3];
        customNullIdx = [];
        pilotIdx = [-21; -7; 7; 21];
    end
    
    pilotIdx = pilotIdx + FFTLen/2 + 1; % Convert to 1-based indexing
    customNullIdx = customNullIdx + FFTLen/2 + 1; % Convert to 1-based indexing
    % Get non-data subcarrier indices for the whole bandwidth
    nonDataIdx = [(1:numGuardBands(1))'; FFTLen/2+1; (FFTLen-numGuardBands(2)+1:FFTLen)'; pilotIdx; customNullIdx];
    Nsd = FFTLen-numel(nonDataIdx);
    dataIdx = coder.nullcopy(zeros(Nsd,1));
    dataIdx(:) = setdiff((1:FFTLen)', nonDataIdx, 'stable');
    normFactor = FFTLen/sqrt(numTxSTS*(length(dataIdx)+length(pilotIdx)));
end

ofdmCfg = struct( ...
    'FFTLength',           FFTLen, ...
    'CyclicPrefixLength',  CPLen, ...
    'DataIndices',         dataIdx, ...
    'PilotIndices',        pilotIdx, ...
    'CarrierRotations',    carrierRotation, ...
    'NormalizationFactor', normFactor, ...
    'NumTones',            numel(dataIdx)+numel(pilotIdx),...
    'NumSubchannels',      Num20MHzChan);

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
