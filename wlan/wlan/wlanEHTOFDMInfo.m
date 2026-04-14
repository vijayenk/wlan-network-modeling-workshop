function info = wlanEHTOFDMInfo(fieldname,cfg,varargin)
%wlanEHTOFDMInfo OFDM information for EHT
%   INFO = wlanEHTOFDMInfo(FIELDNAME,CFG) returns a structure containing
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
%   'RL-SIG', 'U-SIG', 'EHT-SIG', 'EHT-LTF', or 'EHT-Data'.
%
%   CFG is a format configuration object of type wlanEHTMUConfig, 
%   wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   INFO = wlanEHTOFDMInfo(FIELDNAME,CFG,RUNUMBER) returns a structure
%   containing OFDM information for the resource unit (RU) of interest,
%   RUNUMBER.
%
%   #  For an EHT MU OFDMA PPDU type, when FIELDNAME is 'EHT-LTF' or
%      'EHT-Data', RUNUMBER is required.
%   #  For a EHT MU non-OFDMA PPDU type, when FIELDNAME is 'EHT-LTF' or
%      'EHT-Data', RUNUMBER is not required.
%   #  For an EHT TB PPDU type RUNUMBER is not required.
%   #  When FIELDNAME is 'L-LTF', 'L-SIG', 'RL-SIG', 'U-SIG', or 'EHT-SIG',
%      RUNUMBER is not required.
%   #  For wlanEHTRecoveryConfig, RUNUMBER is not required.
%
%   INFO = wlanEHTOFDMInfo(...,'OversamplingFactor',OSF) returns OFDM
%   information to oversample by a factor OSF. OSF must be >=1. The
%   oversampled cyclic prefix length in samples must be integer-valued. The
%   default is 1.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

narginchk(2,5);
fieldname = validatestring(fieldname,{'EHT-Data','EHT-LTF','EHT-SIG','U-SIG','RL-SIG','L-SIG','L-LTF'},mfilename,'field');
validateattributes(cfg,{'wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{'scalar'},mfilename,'format configuration object');
[chanBW,guardInterval,rusize,ruindex,osf] = parseInputs(fieldname,cfg,varargin{:});

[info,fftLength,cpLength] = wlan.internal.ehtOFDMInfo(fieldname,chanBW,guardInterval,rusize,ruindex,osf);

wlan.internal.validateOFDMOSF(osf,fftLength,cpLength);
end

function [chanBW,guardInterval,rusize,ruindex,osf] = parseInputs(fieldname,cfg,varargin)
% Parse signature with wlanEHTMUConfig object
    chanBW = wlan.internal.validateParam('EHTCHANBW',cfg.ChannelBandwidth,mfilename);
    cbw = wlan.internal.cbwStr2Num(chanBW);
    guardInterval = cfg.GuardInterval;
    ruNumber = 1; % Default
    isEHTMU = isa(cfg,'wlanEHTMUConfig');
    if isEHTMU || isa(cfg,'wlanEHTTBConfig')
        allocInfo = ruInfo(cfg);
        if any(strcmp(fieldname,{'EHT-LTF','EHT-Data'}))
            mode = compressionMode(cfg);
            if mode==0 && isEHTMU % EHT MU (DL-OFDMA)
                if nargin>2 && isnumeric(varargin{1}) % wlanEHTOFDMInfo(FIELDNAME,CFG,RUNUM,...)
                    ruNumber = varargin{1};
                    wlan.internal.validateRUNumber(ruNumber,allocInfo.NumRUs);
                    osf = wlan.internal.parseOSF(varargin{2:end});
                else % wlanEHTOFDMInfo(FIELDNAME,CFG) or wlanEHTOFDMInfo(FIELDNAME,CFG,N-V)
                    coder.internal.error('wlan:shared:ExpectedRUNumberEHT');
                end
            else % EHT MU (MU-MIMO) or EHT TB
                % wlanEHTOFDMInfo(FIELDNAME,CFG)
                osf = parseOSFWithOptionalNumeric(varargin{:});
            end
        else
            % Allow for optional RU number before NV pairs (even though it is not used)
            osf = parseOSFWithOptionalNumeric(varargin{:});
        end
        rusize = allocInfo.RUSizes{ruNumber};
        ruindex = allocInfo.RUIndices{ruNumber};
    else % wlanEHTRecoveryConfig
        rusize = cfg.RUSize;
        ruindex = cfg.RUIndex;
        if any(strcmp(fieldname,{'EHT-Data','EHT-LTF'}))
            wlan.internal.mustBeDefined(guardInterval,'GuardInterval'); % Check for undefined state
            wlan.internal.mustBeDefined(cfg.RUSize,'RUSize'); % Check for undefined state
            wlan.internal.mustBeDefined(cfg.RUIndex,'RUIndex'); % Check for undefined state
            wlan.internal.validateEHTRUArgument(rusize,ruindex,cbw);
        end
        osf = parseOSFWithOptionalNumeric(varargin{:});
    end
end

function osf = parseOSFWithOptionalNumeric(varargin)
    if nargin>0 && isnumeric(varargin{1})
        % Ignore optional numeric
        osf = wlan.internal.parseOSF(varargin{2:end});
    else
        osf = wlan.internal.parseOSF(varargin{:});
    end
end

