function k = hePuncturedRUSubcarrierIndices(cfgHE)
%hePuncturedRUSubcarrierIndices Punctured RU subcarrier indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   K = hePuncturedRUSubcarrierIndices(CFGHE) returns an array K of
%   punctured subcarrier indices.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, or 
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>.

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

k = zeros(0,1); % Default no punctured subcarriers

% Get the puncture mask for each 20 MHz subchannel
if any(strcmp(packetFormat(cfgHE),{'HE-SU','HE-EXT-SU'})) % Also for HEz
    subchannelsPunctured = wlan.internal.subchannelPuncturingPattern(cfgHE);
    if any(subchannelsPunctured)       
        cbw = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);
        ruSize = 242; % Puncture 20 MHz subchannel
        for ruIndex = 1:numel(subchannelsPunctured)
            if subchannelsPunctured(ruIndex)
                k = [k; wlan.internal.heRUSubcarrierIndices(cbw,ruSize,ruIndex)]; %#ok<AGROW>
            end
        end
        
        % Puncture center 26-tone RU if adjacent to 242-tone RU which is
        % punctured; IEEE P802.11ax/D4.1 Section 27.3.16.
        if cbw>40 && any(subchannelsPunctured([2 3]))
            ruSize = 26; % Puncture lower center 26-tone RU
            ruIndex = 19;
            % Extract first to last so we null out the DC subcarriers too
            % as at 80 MHz there are fewer DC carriers at 996 than 26
            centerRUIndices = wlan.internal.heRUSubcarrierIndices(cbw,ruSize,ruIndex);
            k = [k; (centerRUIndices(1):centerRUIndices(end))'];
        end
        if cbw>80 && any(subchannelsPunctured([6 7]))
            ruSize = 26; % Puncture upper center 26-tone RU
            ruIndex = 56;
            % Extract first to last so we null out the DC subcarriers too
            % as at 80 MHz there are fewer DC carriers at 996 than 26
            centerRUIndices = wlan.internal.heRUSubcarrierIndices(cbw,ruSize,ruIndex);
            k = [k; (centerRUIndices(1):centerRUIndices(end))'];
        end
        % Sort so setdiff can be used with the indices with codegen
        k = sort(k);
    end
end
end