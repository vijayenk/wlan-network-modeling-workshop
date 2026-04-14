function [chanBW, numBPSCS] = validateInterleaveInputs(type, numCBPSSI, varargin)
% validateInterleaveInputs validates inputs of wlanBCCInterleave and
% wlanBCCDeinterleave: type, numCBPSSI, and conditionally mandatory input
% chanBW. Returns chanBW and numBPSCS.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2016-2024 The MathWorks, Inc.

%#codegen

narginchk(2,3);

% Validate interleaving/deinterleaving type
coder.internal.errorIf(~(ischar(type) || (isstring(type) && isscalar(type))) || ~any(strcmp(type, {'Non-HT','VHT'})), ...
    'wlan:wlanBCCInterleave:InvalidIntType');

if nargin>2 && strcmp(type,'VHT')
    % 'VHT' type
    chanBW = varargin{1};
    % Validate channel bandwidth input
    coder.internal.errorIf(~(ischar(chanBW) || (isstring(chanBW) && isscalar(chanBW))) || ...
        ~any(strcmp(chanBW, {'CBW1','CBW2','CBW4','CBW8','CBW16','CBW20','CBW40','CBW80','CBW160'})),...
        'wlan:wlanBCCInterleave:InvalidIntChanBW');
else
    % 'Non-HT' type
    coder.internal.errorIf(strcmp(type,'VHT'),'wlan:wlanBCCInterleave:InvalidVHTIntParameters');
    % Default value for 'Non-HT' type
    chanBW = 'CBW20';
end

% Get numBPSCS and validate numCBPSSI
validateattributes(numCBPSSI,{'numeric'},{'scalar','integer'},mfilename,'numCBPSSI');
if strcmp(type,'Non-HT')
    numSD = 48;
    numBPSCS = numCBPSSI/numSD; % Get numBPSCS from input numCBPSSI
    validValues = numSD*[1 2 4 6 8]; % Compute numCBPSSI for valid numBPSCS values: 1, 2, 4, 6, and 8
    coder.internal.errorIf(~isscalar(numCBPSSI) || ~any(numBPSCS == [1 2 4 6 8]), ...
        'wlan:wlanBCCInterleave:InvalidNonHTNUMCBPSSI',numCBPSSI,validValues(1),validValues(2),validValues(3),validValues(4),validValues(5),numSD);
else % strcmp(type,'VHT')
    switch chanBW
        case 'CBW1'
            numSD = 24;
            numSeg = 1;
        case {'CBW2','CBW20'}
            numSD = 52;
            numSeg = 1;
        case {'CBW4','CBW40'}
            numSD = 108;
            numSeg = 1;
        case {'CBW8','CBW80'}
            numSD = 234;
            numSeg = 1;
        otherwise % {'CBW16','CBW160'}
            numSD = 468;
            numSeg = 2;
    end
    numBPSCS = numCBPSSI*numSeg/numSD; % Get numBPSCS from input numCBPSSI
    validValues = numSD/numSeg*[1 2 4 6 8 10]; % Compute numCBPSSI for valid numBPSCS values: 1, 2, 4, 6, 8 and 10
    coder.internal.errorIf(~isscalar(numCBPSSI) || ~any(numBPSCS == [1 2 4 6 8 10]), ...
        'wlan:wlanBCCInterleave:InvalidVHTNUMCBPSSI',numCBPSSI,chanBW,validValues(1),validValues(2),validValues(3),validValues(4),validValues(5),numSD);
end

end