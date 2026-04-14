function ofdmInfo = getOFDMInfo(cfg,field,ruNumber)
%getOFDMInfo Returns a structure containing OFDM information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OFDMINFO = getOFDMInfo(CFG,FIELD,RUNUMBER) returns a structure
%   containing OFDM information for HE MU, EHT MU, and EHT TB object, the
%   field of interest is 'preamble' or 'data'. RU number is required for <a
%   href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a> and <a
%   href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> config
%   object.
%
%   The optional ruNumber is not required for Non-HT, HT, VHT, HE SU, HE TB
%   and EHT TB packet format.

%   Copyright 2022-2025 The MathWorks, Inc.

if nargin<3 || ruNumber<1
  ruNumber = 1;
end

pktFormat = packetFormat(cfg);
switch field
    case 'data'
        % Get OFDM info for data fields of formats
        switch pktFormat
            case {'EHT-MU','EHT-TB'}
                allocInfo = ruInfo(cfg);
                ruSize = allocInfo.RUSizes{ruNumber};
                ruIdx = allocInfo.RUIndices{ruNumber};
                ofdmInfo = wlan.internal.ehtOFDMInfo('EHT-Data',cfg.ChannelBandwidth,cfg.GuardInterval,ruSize,ruIdx);
            case 'HE-MU'
                allocInfo = ruInfo(cfg);
                ruSize = allocInfo.RUSizes(ruNumber);
                ruIdx = allocInfo.RUIndices(ruNumber);
                ofdmInfo = wlan.internal.heOFDMInfo('HE-Data',cfg.ChannelBandwidth,cfg.GuardInterval,ruSize,ruIdx);
            case {'HE-SU','HE-EXT-SU','HE-TB'}
                allocInfo = ruInfo(cfg);
                ruSize = allocInfo.RUSizes;
                ruIdx = allocInfo.RUIndices;
                ofdmInfo = wlan.internal.heOFDMInfo('HE-Data',cfg.ChannelBandwidth,cfg.GuardInterval,ruSize,ruIdx);
            case 'VHT'
                ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-Data',cfg.ChannelBandwidth,cfg.GuardInterval);
            case 'HT-MF'
                ofdmInfo = wlan.internal.vhtOFDMInfo('HT-Data',cfg.ChannelBandwidth,cfg.GuardInterval);
            case 'Non-HT'
                ofdmInfo = wlan.internal.vhtOFDMInfo('NonHT-Data',cfg.ChannelBandwidth);
            otherwise
                assert(false,'Unexpected format');
        end
    case 'preamble'
        % Get OFDM info for preamble fields of formats
        switch pktFormat
            case 'EHT-MU'
                ofdmInfo = wlan.internal.ehtOFDMInfo('EHT-SIG',cfg.ChannelBandwidth);
            case 'EHT-TB'
                ofdmInfo = wlan.internal.ehtOFDMInfo('U-SIG',cfg.ChannelBandwidth);
            case {'HE-SU','HE-EXT-SU','HE-TB','HE-MU'}
                ofdmInfo = wlan.internal.heOFDMInfo('HE-SIG-A',cfg.ChannelBandwidth);
            case 'VHT'
                ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-SIG-A',cfg.ChannelBandwidth);
            case 'HT-MF'
                ofdmInfo = wlan.internal.vhtOFDMInfo('HT-SIG',cfg.ChannelBandwidth);
            case 'Non-HT'
                ofdmInfo = wlan.internal.vhtOFDMInfo('L-SIG',cfg.ChannelBandwidth);
            otherwise
                assert(false,'Unexpected format');
        end
    otherwise
        assert(false,'Unexpected field')
end
end
