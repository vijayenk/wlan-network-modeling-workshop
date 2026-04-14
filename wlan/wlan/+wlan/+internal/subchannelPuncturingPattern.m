function mask = subchannelPuncturingPattern(varargin)
%subchannelPuncturingPattern Generate HE preamble field puncturing pattern
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   MASK = subchannelPuncturingPattern(CFG) returns a logical array,
%   MASK, were each element indicates if a 20 MHz subchannel is punctured
%   given a format configuration object.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>, <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>,
%   <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>, <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>, <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a>, or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   MASK = subchannelPuncturingPattern(ALLOCATIONINDEX) returns a logical
%   array, MASK, were each element indicates if a 20 MHz subchannel is
%   punctured given an allocation index.
%
%   ALLOCATIONINDEX is a row vector describing the RU allocation per 20 MHz
%   subchannel.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

narginchk(1,1)

if isnumeric(varargin{1})
    % MASK = subchannelPuncturingPattern(ALLOCATIONINDEX)
    allocationIndex = varargin{1};
    mask = muPunctureMask(allocationIndex);
    return
else
    % MASK = subchannelPuncturingPattern(CFG)
    cfg = varargin{1};
end

[~,num20] = wlan.internal.cbw2nfft(cfg.ChannelBandwidth);
if isa(cfg,'wlanHEMUConfig')
    mask = muPunctureMask(cfg.AllocationIndex);
elseif isa(cfg,'wlanHETBConfig')
    % Puncture 20 MHz segments which do not contain an RU for trigger-based PPDU
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    if cfg.FeedbackNDP
        mask = true(1,num20);
        ruIndex = wlan.internal.heTBNDPSubchannelIndex(cbw,cfg.RUToneSetIndex);
        mask(ruIndex) = 0;
    else
        mask = ~wlan.internal.heRUSegmentOccupied(cbw,cfg.RUSize,cfg.RUIndex);
    end
elseif isa(cfg,'wlanNonHTConfig')
    if any(num20==[4 8 16])
        % Preamble puncturing is only applicable for Non-HT duplicate 80,
        % 160 MHz, and 320 MHz
        if isscalar(cfg.InactiveSubchannels)
            mask = repmat(cfg.InactiveSubchannels==true,1,num20);
        else
            mask = cfg.InactiveSubchannels==true;
            assert(numel(mask)==num20)
        end
    else
        mask = false(1,num20);
    end
elseif isa(cfg,'wlanWURConfig')
    if num20==4
        % Preamble puncturing is only applicable for 80 MHz
        mask = cfg.InactiveSubchannels;
    else
        mask = false(1,num20);
    end
elseif isa(cfg,'wlanVHTConfig') || isa(cfg,'wlanHTConfig')
    mask = false(1,num20);
elseif (isa(cfg,'wlanEHTMUConfig') || strcmp(packetFormat(cfg),'UHR-MU') || strcmp(packetFormat(cfg),'UHR-ELR')) && ~isa(cfg,'wlanHESUConfig') % For codegen
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    mask = cfg.PuncturingPattern;
    if ~cfg.pIsOFDMA && cbw==320 % non-OFDMA
        % Convert 40 MHz to 20 MHz puncturing pattern
        mask = repelem(cfg.PuncturingPattern(1,:),2); % For codegen
    end
elseif isa(cfg,'wlanEHTTBConfig')
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    punctureMaskPerRU = ~wlan.internal.ehtRUSegmentOccupied(cbw,cfg.RUSize,cfg.RUIndex);
    mask = all(punctureMaskPerRU,1);
elseif strcmp(packetFormat(cfg),'UHR-TB') && ~isa(cfg,'wlanHESUConfig') % UHR TB
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    if cfg.DRU
        dbw = wlan.internal.dbwStr2Num(cfg.DistributionBandwidth);
        punctureMaskPerRU = ~wlan.internal.uhrDRURUSegmentOccupied(cbw,dbw,cfg.RUSize,cfg.RUIndex);
    else
        punctureMaskPerRU = ~wlan.internal.ehtRUSegmentOccupied(cbw,cfg.RUSize,cfg.RUIndex);
    end
    mask = all(punctureMaskPerRU,1);
else % HE-SU
    if cfg.APEPLength==0 && any(num20==[4 8])
        % Preamble puncturing is only applicable for HE SU NDP, 80 and 160 MHz
        if isscalar(cfg.InactiveSubchannels)
            mask = repmat(cfg.InactiveSubchannels==true,1,num20);
        else
            mask = cfg.InactiveSubchannels==true;
            assert(numel(mask)==num20)
        end
    else
        mask = false(1,num20);
    end
end

end

function mask = muPunctureMask(allocationIndex)
    if numel(allocationIndex)>=4 
        % Preamble puncturing is only applicable to 80 MHz or 160 MHz HE MU
        adjacentAllocationIndexPairs = reshape(allocationIndex,2,[]).';
        allocationIndex114Pairs = adjacentAllocationIndexPairs == [114 114];
        combineMask = (adjacentAllocationIndexPairs==113 | repmat(all(allocationIndex114Pairs,2),1,2))';
        mask = combineMask(:)';
    else
        mask = false(1,numel(allocationIndex));
    end
end