function [phyFormat, isAggFrame] = phyConfigTophyFormat(phyConfig, disableValidation, isAMPDU)
%phyConfigTophyFormat Returns the PHY format for a given PHY configuration
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   [PHYFORMAT, ISAGGFRAME] = phyConfigTophyFormat(PHYCONFIG,
%   DISABLEVALIDATION, ISAMPDU) returns physical layer (PHY) frame format
%   PHYFORMAT, corresponding to the input PHY configuration object
%   PHYCONFIG.
%
%   PHYFORMAT is a character vector representing the PHY frame format.
%
%   ISAGGFRAME returns whether frame aggregation is enabled after
%   validating the input PHY configuration object and the aggregation flag
%   ISAMPDU.
%
%   PHYCONFIG is a format configuration object of type wlanNonHTConfig, 
%   wlanHTConfig, wlanVHTConfig, wlanHERecoveryConfig, wlanHESUConfig, 
%   wlanHETBConfig, wlanHEMUConfig, or wlanEHTMUConfig.
%
%   DISABLEVALIDATION is a logical scalar specifying if input validation
%   must be disabled.
%
%   ISAMPDU is a logical scalar specifying whether frame aggregation is enabled.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

if nargin == 2
    isAMPDU = true;
end

if disableValidation
    isAggFrame = isAMPDU;
    if ischar(phyConfig) || isstring(phyConfig)
        phyFormat = phyConfig;
    else
        if strcmp(class(phyConfig), 'wlanNonHTConfig') %#ok<*STISA>
            phyFormat = 'Non-HT';
            isAggFrame = false;
        elseif strcmp(class(phyConfig), 'wlanHTConfig')
            phyFormat = 'HT-Mixed';
        elseif strcmp(class(phyConfig), 'wlanVHTConfig')
            phyFormat = 'VHT';
        elseif strcmp(class(phyConfig), 'wlanEHTMUConfig')
            phyFormat ='EHT-SU';
        elseif strcmp(class(phyConfig), 'wlanHESUConfig')
            phyFormat = phyConfig.packetFormat;
        else% 'wlanHERecoveryConfig', 'wlanHETBConfig', 'wlanHEMUConfig'
            phyFormat = 'HE-SU';
        end
    end
else
    if ischar(phyConfig) || isstring(phyConfig) % PHY format string is provided as input
        isAggFrame = isAMPDU;
        if isAMPDU
            phyFormat = validatestring(phyConfig, {'HT-Mixed', 'VHT', 'HE-SU', 'HE-EXT-SU', 'HE-TB', 'HE-MU', 'EHT-SU'}, mfilename);
        else
            phyFormat = validatestring(phyConfig, {'Non-HT', 'HT-Mixed', 'VHT', 'HE-SU', 'HE-EXT-SU', 'HE-TB', 'HE-MU', 'EHT-SU'}, mfilename);
        end
        if any(strcmp(phyFormat, {'HE-TB', 'HE-MU'}))
            phyFormat = 'HE-SU';
        end
    else % PHY config is provided as input
        validateattributes(phyConfig, {'wlanNonHTConfig', 'wlanHTConfig', 'wlanVHTConfig', 'wlanHESUConfig', ...
            'wlanHERecoveryConfig', 'wlanHETBConfig', 'wlanHEMUConfig', 'wlanEHTMUConfig'}, {'scalar'}, '', 'Input 2');
        switch class(phyConfig)
            case 'wlanNonHTConfig'
                phyFormat = 'Non-HT';
                isAggFrame = false;
            case 'wlanHTConfig'
                phyFormat = 'HT-Mixed';
                isAggFrame = phyConfig.AggregatedMPDU;
            case 'wlanVHTConfig'
                phyFormat = 'VHT';
                isAggFrame = true;
            case 'wlanEHTMUConfig'
                % Validate wlanEHTMUConfig object for SU format
                if (numel(phyConfig.User) ~= 1)
                    coder.internal.error('wlan:shared:InvalidEHTPHYConfig');
                end
                % Validate unsupported EHT DUP format
                if phyConfig.EHTDUPMode
                    coder.internal.error('wlan:shared:EHTDUPModeNotSupported');
                end                    
                phyFormat ='EHT-SU';
                isAggFrame = true;
            case 'wlanHESUConfig'
                phyFormat = phyConfig.packetFormat;
                isAggFrame = true;
            otherwise % 'wlanHERecoveryConfig', 'wlanHETBConfig', 'wlanHEMUConfig'
                phyFormat = 'HE-SU';
                isAggFrame = true;
        end
        % Check if the frame is non-aggregated
        if isAMPDU && ~isAggFrame
            coder.internal.error('wlan:wlanAMPDUDeaggregate:NotAnAMPDU');
        end
    end
end
end
