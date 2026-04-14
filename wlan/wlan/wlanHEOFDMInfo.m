function info = wlanHEOFDMInfo(fieldname,varargin)
%wlanHEOFDMInfo OFDM information for HE
%   INFO = wlanHEOFDMInfo(FIELDNAME,CFG) returns a structure containing
%   OFDM information for the specified field and configuration.
%
%   INFO is a structure with the these fields:
%     FFTLength              - FFT length
%     SampleRate             - Sample rate of waveform
%     CPLength               - Cyclic prefix length
%     NumTones               - Number of active subcarriers
%     NumSubchannels         - Number of 20 MHz subchannels
%     ActiveFrequencyIndices - Indices of active subcarriers relative to DC
%                              in the range [-NFFT/2, NFFT/2-1]
%     ActiveFFTIndices       - Indices of active subcarriers within the FFT
%                              in the range [1, NFFT]
%     DataIndices            - Indices of data within the active
%                              subcarriers in the range [1, NumTones]
%     PilotIndices           - Indices of pilots within the active
%                              subcarriers in the range [1, NumTones]
%
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG',
%   'RL-SIG', 'HE-SIG-A', 'HE-SIG-B', 'HE-LTF', or 'HE-Data'.
%
%   CFG is a format configuration object of type wlanHESUConfig,
%   wlanHEMUConfig, wlanHETBConfig, or wlanHERecoveryConfig. When
%   wlanHEMUConfig is provided and FIELDNAME is 'HE-LTF' or 'HE-Data' an
%   additional RU number argument is required as described below.
%
%   When CFG is a wlanHETBConfig object and the FeedbackNDP property
%   is true, the function interleaves the subcarrier indices for active and
%   complementary tone sets for the specified value of the RUToneSetIndex
%   property in accordance with Table 27-32 of IEEE Std 802.11ax-2021.
%
%   INFO = wlanHEOFDMInfo(HEFIELD,CFGHEMU,RUNUMBER) returns OFDM info for
%   the resource unit (RU) of interest for a multi-user configuration.
%
%   HEFIELD is 'HE-Data' or 'HE-LTF'.
%   CFGHEMU is a format configuration object of type wlanHEMUConfig.
%   RUNUMBER is the number of the RU of interest.
%
%   When a format configuration object is not available, individual fields
%   can be demodulated using the below syntaxes:
%
%   INFO = wlanHEOFDMInfo(HEFIELD,CHANBW,HEGI,RU) returns OFDM info for the
%   resource unit (RU) of interest for a multi-user configuration. If RU is
%   not specified a full band or single-user configuration is assumed.
%
%   CHANBW must be 'CBW20', 'CBW40', 'CBW80', or 'CBW160'.
%   HEGI is the guard interval in microseconds and must be one of 0.8, 1.6,
%   and 3.2.
%   RU is a row vector specifying the RU information [size index].
%   Size must be one of 26, 52, 106, 242, 484, 996 or 1992, and must be
%   appropriate for the specified channel bandwidth.
%
%   INFO = wlanHEOFDMInfo(PREHEFIELD,CHANBW) returns the OFDM info for
%   pre-HE fields.
%
%   PREHEFIELD is one of 'L-LTF','L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B'.
%
%   INFO = wlanHEOFDMInfo(...,'OversamplingFactor',OSF) returns OFDM
%   information to oversample by a factor OSF. OSF must be >=1. The
%   oversampled cyclic prefix length in samples must be integer-valued. The
%   default is 1.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(2,8);
fieldname = validatestring(fieldname,{'HE-Data','HE-LTF','HE-SIG-B','HE-SIG-A','RL-SIG','L-SIG','L-LTF'},mfilename,'field');
[chanBW,guardInterval,rusize,ruindex,osf] = parseInputs(fieldname,varargin{:});

isFeedBackNDP = isa(varargin{1},'wlanHETBConfig') && varargin{1}.FeedbackNDP;
if isFeedBackNDP
    [info,fftLength,cpLength] = wlan.internal.heOFDMInfo(fieldname,chanBW,guardInterval,rusize,ruindex,osf,isFeedBackNDP,varargin{1}.RUToneSetIndex);
else
    [info,fftLength,cpLength] = wlan.internal.heOFDMInfo(fieldname,chanBW,guardInterval,rusize,ruindex,osf);
end

wlan.internal.validateOFDMOSF(osf,fftLength,cpLength);
end

function [chanBW,guardInterval,rusize,ruindex,osf] = parseInputs(fieldname,varargin)
% Parse inputs to return parameters

    if isstring(varargin{1}) || ischar(varargin{1})
        % wlanHEOFDMInfo(FIELDNAME,CHANBW,...)
        [chanBW,guardInterval,rusize,ruindex,osf] = parseFlatSignatures(fieldname,varargin{:});
    else
        switch class(varargin{1})
            case 'wlanHEMUConfig'
                % wlanHEOFDMInfo(FIELDNAME,CFGMU,RUNUM,...)
                [chanBW,guardInterval,rusize,ruindex,osf] = parseMUSignatures(fieldname,varargin{:});
            case {'wlanHESUConfig','wlanHETBConfig'}
                % wlanHEOFDMInfo(FIELDNAME,CFGSU,...)
                cfg = varargin{1};
                chanBW = cfg.ChannelBandwidth;
                guardInterval = cfg.GuardInterval;
                allocInfo = ruInfo(cfg);
                rusize = allocInfo.RUSizes;
                ruindex = allocInfo.RUIndices;
                % Allow for optional RU number before NV pairs (even though it is not used)
                osf = parseOSFWithOptionalNumeric(varargin{2:end});
            case 'wlanHERecoveryConfig'
                % wlanHEOFDMInfo(FIELDNAME,CFGREC,...)
                cfg = varargin{1};
                chanBW = cfg.ChannelBandwidth;
                guardInterval = cfg.GuardInterval;
                rusize = cfg.RUSize;
                ruindex = cfg.RUIndex;
                wlan.internal.validateParam('CHANBW',chanBW,mfilename);
                if any(strcmp(fieldname,{'HE-Data','HE-LTF'}))
                    coder.internal.errorIf(guardInterval==-1,'wlan:wlanHEOFDMInfo:InvalidGI'); % GI undefined
                    wlan.internal.validateRUArgument([rusize ruindex],wlan.internal.cbwStr2Num(chanBW));
                end
                osf = parseOSFWithOptionalNumeric(varargin{2:end});
            otherwise
                coder.internal.error('wlan:wlanHEOFDMInfo:UnexpectedArgument');
        end
    end
end

function [chanBW,guardInterval,rusize,ruindex,osf] = parseFlatSignatures(fieldname,varargin)
% Parse signatures without a configuration object

    chanBW = wlan.internal.validateParam('CHANBW',varargin{1});

    % Defaults
    cbw = wlan.internal.cbwStr2Num(chanBW);
    rusize = wlan.internal.heFullBandRUSize(cbw);
    ruindex = 1;
    guardInterval = 3.2;
    if any(strcmp(fieldname,{'HE-Data','HE-LTF'}))
        if nargin<3
            coder.internal.error('wlan:shared:ExpectedGI');
        else
            guardInterval = validateGI(varargin{2});
            if nargin>3 && ~(ischar(varargin{3}) || isstring(varargin{3}))
                % wlanHEOFDMInfo(FIELDNAME,CHANBW,GI,RU,...)
                [rusize,ruindex] = wlan.internal.validateRUArgument(varargin{3},cbw);
                nvp = wlan.internal.demodNVPairParse(varargin{4:end});
                osf = nvp.OversamplingFactor;
            else
                % wlanHEOFDMInfo(FIELDNAME,CHANBW,GI) or wlanHEOFDMInfo(FIELDNAME,CHANBW,GI,NAME,VALUE)
                nvp = wlan.internal.demodNVPairParse(varargin{3:end});
                osf = nvp.OversamplingFactor;
            end
        end
    else
        % Allow for optional GI (and RU) before NV pairs for legacy
        % fields (to help with codegen)
        if nargin>2 && isnumeric(varargin{2})
            if nargin>3 && isnumeric(varargin{3})
                % GI and RU optional
                nvp = wlan.internal.demodNVPairParse(varargin{4:end});
            else
                % GI optional
                nvp = wlan.internal.demodNVPairParse(varargin{3:end});
            end
        else
            nvp = wlan.internal.demodNVPairParse(varargin{2:end});
        end
        osf = nvp.OversamplingFactor;
    end
end

function [chanBW,guardInterval,rusize,ruindex,osf] = parseMUSignatures(fieldname,varargin)
% Parse signature with wlanHEMUConfig object

    cfg = varargin{1};
    chanBW = cfg.ChannelBandwidth;
    guardInterval = cfg.GuardInterval;
    allocInfo = ruInfo(cfg);
    ruNumber = 1; % Default

    if any(strcmp(fieldname,{'HE-LTF','HE-Data'}))
        % wlanHEOFDMInfo(FIELDNAME,CFGMU,RUNUM)
        if nargin<3
            coder.internal.error('wlan:shared:ExpectedRUNumberHE');
        else
            ruNumber = varargin{2};
            validateRUNumber(ruNumber,allocInfo.NumRUs);
            nvp = wlan.internal.demodNVPairParse(varargin{3:end});
            osf = nvp.OversamplingFactor;
        end
    else
        % Allow for optional RU number before NV pairs (even though it is not used)
        osf = parseOSFWithOptionalNumeric(varargin{2:end});
    end
    rusize = allocInfo.RUSizes(ruNumber);
    ruindex = allocInfo.RUIndices(ruNumber);
end

function gi = validateGI(giin)
    % Do not perform compile time check on type etc to allow for GI to be optional
    if ~isnumeric(giin) || ~isscalar(giin) || ~ismember(giin,[0.8 1.6 3.2])
        coder.internal.error('wlan:wlanHEOFDMInfo:InvalidGI');
    end
    gi = double(giin(1)); % Force type and scalar for codegen (as may be in NV path when field is legacy)
end

function validateRUNumber(ruNumber,numRUs)
    validateattributes(ruNumber,{'numeric'},{'scalar','integer','>',0,'<=',numRUs},mfilename,'RU Number');
end

function osf = parseOSFWithOptionalNumeric(varargin)
    if nargin>0 && isnumeric(varargin{1})
        % Ignore optional numeric
        nvp = wlan.internal.demodNVPairParse(varargin{2:end});
    else
        nvp = wlan.internal.demodNVPairParse(varargin{:});
    end
    osf = nvp.OversamplingFactor;
end

