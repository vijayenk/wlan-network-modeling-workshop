function txSync = wurSync(cfgFormat,osf,varargin)
%wurSync WUR-Sync field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   TXSYNC = wurSync(CFGFORMAT,OSF) generates the WUR-Sync field for a 20
%   MHz WUR PPDU.
%
%   TXSYNC is the time-domain WUR-Sync field signal. It is a complex matrix 
%   of size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU format.
%
%   OSF is the oversampling factor.
%
%   TXSYNC = wurSync(...,SUBCHANNELINDEX) generates the WUR-Sync field for
%   a specific 20 MHz subchannel.
%
%   SUBCHANNELINDEX indicates the subchannel index for CBW20, CBW40, and
%   CBW80 and must be between 1 and 4 inclusive.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

subchannelIndex = 1;
if nargin>2
    subchannelIndex = varargin{1};
end

activeSubchannels = getActiveSubchannelIndex(cfgFormat);
if ~any(activeSubchannels==subchannelIndex) % Inactive subchannels
    sr = wlan.internal.cbwStr2Num(cfgFormat.ChannelBandwidth)*osf*1e6;
    t = wlan.internal.wurTimingRelatedConstants(cfgFormat.Subchannel{subchannelIndex}.DataRate);
    % Zero padding for inactive subchannels
    txSync = complex(zeros(fix(sr*t.TWURSync*1e-9),cfgFormat.NumTransmitAntennas));
    return
end

% Active subchannels
% 32-bit sequence, IEEE P802.11ba/D8.0, December 2020, Equation (30-9)
W = [1 0 1 0 0 1 0 0 1 0 1 1 1 0 1 1 0 0 0 1 0 1 1 1 0 0 1 1 1 0 0 0].';

switch cfgFormat.Subchannel{subchannelIndex}.DataRate
    case 'LDR'
        seq = [W; W];
    otherwise
        seq = double(~W); % For codegen
end

onwg = wlan.internal.wurOnSymSequence('HDR',cfgFormat,subchannelIndex); % Always use HDR sequence for Sync fields
NSym = numel(seq);
onwg = repmat(onwg,1,NSym,cfgFormat.NumTransmitAntennas); % Use the same sequence for all symbols

% Generate On symbols
onWGSym = wlan.internal.wurMCOOKOnSymbols(onwg,'HDR',subchannelIndex,cfgFormat,osf); % HDR sequence for Sync fields

% Select on or off symbol based on sequence (off is zeros)
txSync = complex(zeros(size(onWGSym,1),NSym,cfgFormat.NumTransmitAntennas));
txSync(:,seq==1,:) = onWGSym(:,seq==1,:);
txSync = reshape(txSync,[],cfgFormat.NumTransmitAntennas);

% Scaling for all active subchannels
txSync = txSync./sqrt(cfgFormat.NumUsers);

end
