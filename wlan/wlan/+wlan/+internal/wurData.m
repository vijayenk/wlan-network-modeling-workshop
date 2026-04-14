function txData = wurData(psdu,cfgFormat,osf,varargin)
%wurData WUR Data field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   TXDATA = wurData(PSDU,CFGFORMAT,OSF) generates the WUR-Data field for 20
%   MHz WUR PPDUs.
%
%   TXDATA is a time-domain WUR-data field. It is a complex matrix of
%   Ns-by-Nt, where Ns represents the number of samples in the data field
%   and Nt represents the number of transmit antennas.
%
%   PSDU is the PHY service data unit input for a subchannel. PSDU is a
%   double or int8 typed binary column vector of length
%   CFGFormat.PSDULength*8.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>,
%   which specifies the parameters for the WUR PPDU format.
%
%   OSF is the oversampling factor.
%
%   TXDATA = wurData(...,SUBCHANNELINDEX) generates the WUR-Data field for
%   a specific 20 MHz subchannel.
%
%   SUBCHANNELINDEX indicates the subchannel index for CBW20, CBW40 and
%   CBW80 and must be between 1 and 4 inclusive.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

subchannelIndex = 1;
if nargin>3
    subchannelIndex = varargin{1};
end

params = wlan.internal.wurTxTime(cfgFormat);
if ~any(params.ActiveSubchannels==subchannelIndex) % Inactive subchannels
    sr = wlan.internal.cbwStr2Num(cfgFormat.ChannelBandwidth)*osf*1e6;
    t = wlan.internal.wurTimingRelatedConstants(cfgFormat.Subchannel{subchannelIndex}.DataRate);
    tData = params.NPad(subchannelIndex)*4*1e3-t.TWURSync;
    % Zero padding for inactive subchannels
    txData = complex(zeros(fix(sr*tData*1e-9),cfgFormat.NumTransmitAntennas));
    return
end
 
% Active subchannels, WUR Encoding
seqEncoding = wlan.internal.wurEncoding(psdu,cfgFormat.Subchannel{subchannelIndex}.DataRate);

% Generate On symbols
NSym = numel(seqEncoding);
onwg = wlan.internal.wurOnSymSequence(cfgFormat.Subchannel{subchannelIndex}.DataRate,cfgFormat,subchannelIndex);
onwg = repmat(onwg,1,NSym,cfgFormat.NumTransmitAntennas); % Same seq per symbol and antenna

% Generate On symbols - offset randomized by number of symbols in the Sync field
p = wlan.internal.wurSymbolParameters(cfgFormat.Subchannel{subchannelIndex}.DataRate);
onWGSym = wlan.internal.wurMCOOKOnSymbols(onwg,cfgFormat.Subchannel{subchannelIndex}.DataRate,subchannelIndex,cfgFormat,osf,p.NWURSync);

% Select on or off symbol based on sequence (off is zeros)
txData = complex(zeros(size(onWGSym,1),NSym,cfgFormat.NumTransmitAntennas));
txData(:,seqEncoding==1,:) = onWGSym(:,seqEncoding==1,:);
txData = reshape(txData,[],cfgFormat.NumTransmitAntennas);

% Padding if needed
if params.NPad(subchannelIndex)>0
    % Encode with bit '1'
    seqPadding = wlan.internal.wurEncoding(ones(params.NPad(subchannelIndex),1),'HDR'); % IEEE P802.11ba/D8.0, December 2020, Section 30.3.11
    NSymPadding = numel(seqPadding);
    onwgPadding = wlan.internal.wurOnSymSequence('HDR',cfgFormat,subchannelIndex);
    onwgPadding = repmat(onwgPadding,1,NSymPadding,cfgFormat.NumTransmitAntennas);

    % Generate On symbols for padding by setting the state of symbol randomizer continued from the WUR-Data field
    onWGPadding = wlan.internal.wurMCOOKOnSymbols(onwgPadding,'HDR',subchannelIndex,cfgFormat,osf,p.NWURSync+params.NSYM(subchannelIndex));

    % Select on or off symbol based on sequence (off is zeros) for padding
    txPadding = complex(zeros(size(onWGPadding,1),NSymPadding,cfgFormat.NumTransmitAntennas));
    txPadding(:,seqPadding==1,:) = onWGPadding(:,seqPadding==1,:);

    txPadding = reshape(txPadding,[],cfgFormat.NumTransmitAntennas);
    txData = [txData; txPadding];
end

% Scaling for all active subchannels
txData = txData./sqrt(cfgFormat.NumUsers);

end

