function y = dmgHeaderBits(cfgDMG)
%dmgHeaderBits Generate DMG Header bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgHeaderBits(CFGDMG) generates the DMG header bits for Control,
%   Single Carrier and OFDM PHYs. The MCS value in the format configuration
%   object <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> is used to distinguish between DMG PHYs.
%
%   Y is uint8-typed, column vector of size N-by-1, where N is 40 for
%   Control, and 48 for Single Carrier and OFDM PHY.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Generate header bits
headerBits = getHeaderBits(cfgDMG);

% Generate header check sequence: Std IEEE 802.11ad-2012, Section 21.3.7
hcs = wlan.internal.crcGenerate(headerBits,16);

% Header bits
y = [headerBits; hcs];

end

function out = getHeaderBits(cfgDMG)

scramInitBits = wlan.internal.dmgScramblerInitializationBits(cfgDMG);

switch phyType(cfgDMG)
    case 'Control' % Control PHY header
        % Std IEEE 802.11ad-2012, Table 21-11
        
        % Reserved: bit 0
        b0 = 0;

        % Scrambler Initialization: bit 1-4
        b14 = flip(scramInitBits(4:end)); 

        % Length: bit 5-14
        b514 = int2bit(cfgDMG.PSDULength,10,false);

        % Packet Type: bit 15
        if cfgDMG.TrainingLength==0
            b15 = 0; % Reserved when TrainingLength is 0
        else
            b15 = double(strcmp(cfgDMG.PacketType,'TRN-T'));
        end

        % Training Length: bit 16-20
        b1620 = int2bit(cfgDMG.TrainingLength/4,5,false);

        % Turnaround: bit 21
        b21 = double(cfgDMG.Turnaround);

        % Reserved bits: bit 22-23
        b2223 = [0; 0];

        out = int8([b0; b14; b514; b15; b1620; b21; b2223]);
    case 'SC'
        % Std IEEE 802.11-2016, Table 20-17
        
        % Scrambler Initialization: bit 0-6
        b06 = flip(scramInitBits);

        % Determine MCS and length to signal
        [mcs,length,extendedMCSIndication] = wlan.internal.dmgMCSLengthSignaling(cfgDMG);

        % MCS: bit 7-11
        b711 = int2bit(mcs,5,false);

        % Length: bit 12-29
        b1229 = int2bit(length,18,false);

        % Additional PPDU: bit 30
        b30 = 0; % Force to false as signaling an additional PPDU not supported

        % Packet Type: bit 31
        if cfgDMG.TrainingLength==0
            b31 = 0; % Reserved when TrainingLength is 0
        else
            b31 = double(strcmp(cfgDMG.PacketType,'TRN-T'));
        end

        % Training Length: bit 32-36
        b3236 = int2bit(cfgDMG.TrainingLength/4,5,false);

        % Aggregation: bit 37
        b37 = double(cfgDMG.AggregatedMPDU);

        % Beam Tracking Request: bit 38
        if cfgDMG.TrainingLength==0
            b38 = 0; % Reserved when TrainingLength is 0
        else
            b38 = double(cfgDMG.BeamTrackingRequest);
        end

        % Last RSSI: bit 39-42
        b3942 = int2bit(cfgDMG.LastRSSI,4,false);

        % Turnaround: bit 43
        b43 = double(cfgDMG.Turnaround);
        
        % Extended MCS used: bit 44
        b44 = extendedMCSIndication;

        % Reserved: bit 45-47
        b4547 = [0; 0; 0];

        out = int8([b06; b711; b1229; b30; b31; b3236; b37; b38; b3942; b43; b44; b4547]);
    otherwise % OFDM PHY header
        % Std IEEE 802.11ad-2012, Table 21-13
        
        % Scrambler Initialization: bit 0-6
        b06 = flip(scramInitBits);

        % Determine MCS and length to signal
        [mcs,length] = wlan.internal.dmgMCSLengthSignaling(cfgDMG);
        
        % MCS: bit 7-11
        b711 = int2bit(mcs,5,false);

        % Length: bit 12-29
        b1229 = int2bit(length,18,false);

        % Additional PPDU: bit 30
        b30 = 0; % Force to false as signaling an additional PPDU not supported

        % Packet Type: bit 31
        if cfgDMG.TrainingLength==0
            b31 = 0; % Reserved when TrainingLength is 0
        else
            b31 = double(strcmp(cfgDMG.PacketType,'TRN-T'));
        end

        % Training Length: bit 32-36
        b3236 = int2bit(cfgDMG.TrainingLength/4,5,false);

        % Aggregation: bit 37
        b37 = double(cfgDMG.AggregatedMPDU);

        % Beam Tracking Request: bit 38
        if cfgDMG.TrainingLength==0
            b38 = 0; % Reserved when TrainingLength is 0
        else
            b38 = double(cfgDMG.BeamTrackingRequest);
        end

        % Tone Pairing Type: bit 39
        if mcs>=13 && mcs<=17
            b39 = double(strcmp(cfgDMG.TonePairingType,'Dynamic'));
        else
            b39 = 0; % Reserved if DTP not applicable
        end

        % DTP Indicator: bit 40
        if mcs>=13 && mcs<=17 && strcmp(cfgDMG.TonePairingType,'Dynamic')
            b40 = double(cfgDMG.DTPIndicator);
        else
            b40 = 0; % Reserved if DTP not used or applicable
        end

        % Last RSSI: bit 41-44
        b4144 = int2bit(cfgDMG.LastRSSI,4,false);

        % Last RSSI: bit 45
        b45 = double(cfgDMG.Turnaround);

        % Reserved: bit 46-47
        b4647 = [0; 0];

        out = int8([b06; b711; b1229; b30; b31; b3236; b37; b38; b39; b40; b4144; b45; b4647]);
end

end
