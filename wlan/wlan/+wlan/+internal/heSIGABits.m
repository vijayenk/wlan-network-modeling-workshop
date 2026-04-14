function bits = heSIGABits(cfgHE)
%heSIGABits Generate HE-SIG-A bits for HE format
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   BITS = heSIGABits(CFGHE) generates the HE-SIG-A bits for the given
%   configuration.
%
%   BITS are the HE-SIG-A signaling bits. It is of type double, binary
%   column vector of length 52.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

chBW = wlan.internal.cbwStr2Num(cfgHE.ChannelBandwidth);

if isa(cfgHE,'wlanHETBConfig')
    %% Symbol A1: IEEE Std 802.11ax-2021, Table 27-21
    
    % Bit 0: Format
    A100 = 0; % Set to 0 for 'HE-TB'
    
    % Bits 1-6: BSS Color
    A101_06 = int2bit(cfgHE.BSSColor,6,false);
    
    % Bits 7-10: Spatial Reuse
    A107_10 = int2bit(cfgHE.SpatialReuse1,4,false);
    
    % Bits 11-14: Spatial Reuse
    A111_14 = int2bit(cfgHE.SpatialReuse2,4,false);
       
    % Spatial Reuse, bits 15-18
    A115_18 = int2bit(cfgHE.SpatialReuse3,4,false);
     
    % Bits 19-22: Spatial Reuse
    A119_22 = int2bit(cfgHE.SpatialReuse4,4,false);
    
    % Bits 23: Reserve
    A123 = 1;
    
    % Bits 24-25: Bandwidth
     switch chBW
        case 20
            A124_25 = [0; 0];
        case 40
            A124_25 = [1; 0]; % right MSB
        case 80
            A124_25 = [0; 1]; % right MSB
         otherwise % 160
            A124_25 = [1; 1]; % right MSB
    end
   
    A1 = [A100; A101_06; A107_10; A111_14; A115_18; A119_22; A123; A124_25];
    
    %% Symbol A2: IEEE Std 802.11ax-2021, Table 27-21
    
    % Bits 0-6: TXOP duration 
    A200_06 = int2bit(cfgHE.TXOPDuration,7,false);
    
    % Bits 7:15: Reserve
    A207_15 = cfgHE.HESIGAReservedBits;
    
    A2preCRC = [A200_06; A207_15];
    
    % Bits 0-41: Calculate CRC
    preCRCBits = [A1; A2preCRC];
    A216_19CRC = wlan.internal.crcGenerate(preCRCBits);
    A216_19 = A216_19CRC(1:4); % C4 to C7 with C7 first
   
    A2 = [A2preCRC; A216_19; zeros(6,1,'int8')]; % Add tail bits
     
elseif isa(cfgHE,'wlanHEMUConfig')
    %% Symbol A1: IEEE Std 802.11ax-2021, Table 27-20 
    
    allocInfo  = ruInfo(cfgHE);
    maxNumSTSPerRU = max(allocInfo.NumSpaceTimeStreamsPerRU);
    numUsers = sum(allocInfo.NumUsersPerRU);
    
    % Assume 0 nominal packet extension and 5 GHz operation (signal
    % extension = 0)
    [PEDisambiguityTx,paddingPrams] = hePEDisambiguityCalculation(cfgHE);
    
    % Bit 1: TransmissionDirection
    if cfgHE.UplinkIndication
        A100 = 1; % 1 for Uplink
    else
        A100 = 0; % 0 for Downlink
    end
    
    % Bits 2-3: SIGB MCS
    switch cfgHE.SIGBMCS
        case 0 
            mcs = 0; % MCS 0;
        case 1
            mcs = 1; % MCS 1;
        case 2
            mcs = 2; % MCS 2;
        case 3
            mcs = 3; % MCS 3;
        case 4
            mcs = 4; % MCS 4;
        otherwise % 5
            assert(cfgHE.SIGBMCS==5)
            mcs = 5; % MCS 5;
    end
    A101_03 = int2bit(mcs,3,false);
    
    % Bits 4: SIGB DCM
    A104 = double(cfgHE.SIGBDCM);
    
    % Bits 5-10: BSS Color
    A105_10 = int2bit(cfgHE.BSSColor,6,false);
    
    % Bits 11-14: Spatial Reuse 
    A111_14 = int2bit(cfgHE.SpatialReuse,4,false);
    
    % Bits 15-17: Preamble puncturing
    bandwidth = wlan.internal.heSIGAChannelBWValue(cfgHE);

    A115_17 =  int2bit(bandwidth,3,false);
    
    % Bits 18-21: Number of HE-SIGB symbols 
    sigbInfo = wlan.internal.heSIGBCodingInfo(cfgHE);
    numSIGBSym = sigbInfo.NumSymbols;
    
    % Set SIGB compression for full MU-MIMO
    SIGBCompressionEnabled = sigbInfo.Compression;
    if SIGBCompressionEnabled
        A118_21 = int2bit(numUsers-1,4,false);
    else
        if numSIGBSym<16
            A118_21 = int2bit(numSIGBSym-1,4,false);
        else 
            numSIGBSym = 15; % IEEE Std 802.11ax-2021, Table 27-20
            A118_21 = int2bit(numSIGBSym,4,false);
        end
    end
     
    % Bit 22: SIGB Compression, 
    A122 = SIGBCompressionEnabled; 
    
    % Bits 23-24: G1 + LTF mode 
    if cfgHE.HELTFType==4 && cfgHE.GuardInterval==0.8
        val = 0;
    elseif cfgHE.HELTFType==2 && cfgHE.GuardInterval==0.8
        val = 1; 
    elseif cfgHE.HELTFType==2 && cfgHE.GuardInterval==1.6
        val = 2;
    else %cfgHE.HELTFType==4 && cfgHE.GuardInterval==3.2
        assert(cfgHE.HELTFType==4 && cfgHE.GuardInterval==3.2)
        val = 3;
    end
    A123_24 = int2bit(val,2,false);
    
    % Bit 25: Doppler
    A25 = double(cfgHE.HighDoppler);
    
    A1 = [A100; A101_03; A104; A105_10; A111_14; A115_17; A118_21; A122; A123_24; A25];
    
    %% Symbol A2: IEEE Std 802.11ax-2021, Table 27-20
    
    % Bits 0-6: TXOP duration
    A200_06 = int2bit(cfgHE.TXOPDuration,7,false);
    
    % Bits: Reserved
    A207 = 1;
    
    % Bits 8-10: Number of HE-LTF Symbols 
    NumHELTFSymbol = wlan.internal.numVHTLTFSymbols(maxNumSTSPerRU);
    if cfgHE.HighDoppler
        switch NumHELTFSymbol
            case 1
                numHELTFSignal = 0;
            case 2
                numHELTFSignal = 1;
            otherwise % 4
                assert(NumHELTFSymbol==4)
                numHELTFSignal = 2;
        end
        A208_9 = int2bit(numHELTFSignal,2,false);
        A208_10 = [A208_9; double(cfgHE.MidamblePeriodicity==20)];
    else
        switch NumHELTFSymbol
            case 1
                numHELTFSignal = 0;
            case 2
                numHELTFSignal = 1;
            case 4
                numHELTFSignal = 2;
            case 6
                numHELTFSignal = 3;
            otherwise % 8
                assert(NumHELTFSymbol==8)
                numHELTFSignal = 4;
        end
        A208_10 = int2bit(numHELTFSignal,3,false);
    end
    
    % Bit 11: Extra LDPC symbol
    A211 = paddingPrams.LDPCExtraSymbol;
    
    % Bit 12: STBC
    A212 = cfgHE.STBC;

    % Bit 13-14: Pre-FEC Padding Factor
    A213_14 = preFECPaddingFactorEncoding(paddingPrams.PreFECPaddingFactor);
   
    % Bit 15: PE Disambiguity
    A215 = PEDisambiguityTx;
    
    A2preCRC = [A200_06; A207; A208_10; A211; A212; A213_14; A215];
        
    % Calculate CRC on bits 0-41
    preCRCBits = [A1; A2preCRC];
    A216_19CRC = wlan.internal.crcGenerate(preCRCBits);
    A216_19 = A216_19CRC(1:4); % C4 to C7 with C7 first
     
    A2 = [A2preCRC; A216_19; zeros(6,1,'int8')]; % Add tail bits
     
else % HE-SU
%% Symbol A1: IEEE Std 802.11ax-2021, Table 27-18 
    
    formatType = packetFormat(cfgHE);
    
    % Assume 0 nominal packet extension and 5 GHz operation (signal
    % extension = 0)
    [PEDisambiguityTx,paddingPrams] = hePEDisambiguityCalculation(cfgHE);
    
    % Bit 0: Format
    A100 = 1; % Set to 1 since this is 'HE-SU','HE-EXT-SU' PPDU
    
    % Bit 1: Beam Change 
    if ~cfgHE.PreHESpatialMapping
       A101 = 1;
    else
       A101 = 0; 
    end
    
    % Bit 2: TransmissionDirection
    if cfgHE.UplinkIndication
        A102 = 1; % 1 for Uplink
    else
        A102 = 0; % 0 for Downlink
    end
    
    % Bits 3-6: MCS 
    A103_06 = int2bit(cfgHE.MCS,4,false); % For all modes
        
    % Bit 7: DCM 
    % DCM is only configurable for MCS 0,1,3,4.
    if any(cfgHE.MCS==[0 1 3 4]) && cfgHE.DCM
        A107 = 1;
    else
        A107 = 0;
    end
    
    % Bits 8-13: Color
    A108_13 = int2bit(cfgHE.BSSColor,6,false);
    
    % Reserved
    A114 = 1;
    
    % Bit 15-18: Spatial reuse
    A115_18 = int2bit(cfgHE.SpatialReuse,4,false);
    
    % Bits 19-20: Bandwidth 
    if strcmp(formatType,'HE-SU')
        switch chBW
            case 20
                A119_20 = [0; 0]; % right MSB
            case 40
                A119_20 = [1; 0]; % right MSB
            case 80
                A119_20 = [0; 1]; % right MSB
            otherwise
                A119_20 = [1; 1]; % right MSB
        end
    else % 'HE-EXT-SU'
        if strcmp(packetFormat(cfgHE),'HE-EXT-SU') && cfgHE.Upper106ToneRU
            A119_20 = [1; 0]; % Upper 106-tone RU within the primary 20MHz
        else
            A119_20 = [0; 0]; % Full allocation correspond to CBW20
        end
    end
    
    % Bits 21-22: GI duration 
    if cfgHE.HELTFType==1 && cfgHE.GuardInterval==0.8
        val = 0;
    elseif cfgHE.HELTFType==2 && cfgHE.GuardInterval==0.8
        val = 1; 
    elseif cfgHE.HELTFType==2 && cfgHE.GuardInterval==1.6
        val = 2;
    elseif cfgHE.HELTFType==4 && cfgHE.GuardInterval==0.8
        val = 3;
        % Overwrite the DCM field to 1. IEEE Std 802.11ax-2021, Table 27-18
        A107 = 1;
    else % cfgHE.HELTFType==4 && strcmp(cfgHE.GuardInterval,3.2)
        val = 3;
    end
    A121_22 = int2bit(val,2,false);
    
    % Bits 23-25: Number of space time streams
    if isa(cfgHE,'wlanHESUConfig')
        numSTS = cfgHE.NumSpaceTimeStreams;
    else % For HEz
        numSTS = cfgHE.User{1}.NumSpaceTimeStreams;
    end
    % IEEE Std 802.11ax-2021, Table 27-18
    if strcmp(formatType,'HE-SU') 
        if cfgHE.HighDoppler
            A123_24 = int2bit(numSTS-1,2,false);
            A123_25 = [A123_24; double(cfgHE.MidamblePeriodicity==20)];
        else
            A123_25 = int2bit(numSTS-1,3,false);
        end
    else
        if cfgHE.HighDoppler
            if (cfgHE.STBC==0) && (numSTS==1)
                A123_24 = int2bit(0,2,false);
            else % (cfgHE.STBC==1) && (numSTS==2)
                A123_24 = int2bit(1,2,false);
            end
            A123_25 = [A123_24; double(cfgHE.MidamblePeriodicity==20)];
        else
            if (cfgHE.STBC==0) && (numSTS==1)
                A123_25 = int2bit(0,3,false);
            else % (cfgHE.STBC==1) && (numSTS==2)
                A123_25 = int2bit(1,3,false);
            end
        end
    end
    
    A1 = [A100; A101; A102; A103_06; A107; A108_13; A114; A115_18; A119_20; A121_22; A123_25];
    
    %% Symbol A2: IEEE Std 802.11ax-2021, Table 27-18
    
    % Bits 0-6: TXOP duration 
    A200_06 = int2bit(cfgHE.TXOPDuration,7,false);
    
    % Bit 7: Channel coding
    if strcmp(cfgHE.ChannelCoding,'LDPC')
        A207 = 1;
    else
        A207 = 0; % Default to BCC
    end
    
    % Bit 8: Extra LDPC symbol
    if strcmp(cfgHE.ChannelCoding,'LDPC')
        A208 = double(paddingPrams.LDPCExtraSymbol); % Ref:IEEE 802.11-17/1383r5
    else
        assert(strcmp(cfgHE.ChannelCoding,'BCC'))
        A208 = 1; % Reserved and set to 1
    end
   
    % Bit 9: STBC
    A209 = double(cfgHE.STBC);
    if cfgHE.HELTFType==4 && cfgHE.GuardInterval==0.8
       % Overwrite the STBC field to 1
       A209 = 1; 
    end
   
    % Bit 10: TXBF
    if strcmp(cfgHE.SpatialMapping,'Custom')
        A210 = double(cfgHE.Beamforming);
    else
        A210 = 0;
    end
   
    % Bits 11-12: Pre-FEC Padding Factor 
    A211_12 = preFECPaddingFactorEncoding(paddingPrams.PreFECPaddingFactor);
   
    % Bit 13: PE Disambiguity 
    A213 = PEDisambiguityTx;
   
    % Bit 14: Reserve
    A214 = 1;
   
    % Bit 15: Doppler
    A215 = cfgHE.HighDoppler;
   
    A2preCRC = [A200_06; A207; A208; A209; A210; A211_12; A213; A214; A215];
   
    % Bits 0-41: Calculate CRC 
    preCRCBits = [A1; A2preCRC];
    A216_19CRC = wlan.internal.crcGenerate(preCRCBits);
    A216_19 = A216_19CRC(1:4); % C4 to C7 with C7 first
   
    A2 = [A2preCRC; A216_19; zeros(6,1,'int8')]; % Add tail bits
    
end

% Concatenate the SIG-A1 and A2 fields together - 26x2 bits
bits = [A1; A2];

end

function b0b1 = preFECPaddingFactorEncoding(PreFECPaddingFactor)
%preFECPaddingFactorEncoding Pre-FEC Padding Factor subfield encoding

    % IEEE Std 802.11ax-2021, Table 27-18, Table 27-20, Table 27-21
    switch PreFECPaddingFactor
        case 1
            b0b1 = [1; 0];
        case 2
            b0b1 = [0; 1];
        case 3
            b0b1 = [1; 1];
        otherwise % 4
            assert(isequal(PreFECPaddingFactor,4))
            b0b1 = [0; 0];
    end
end


function [peDisambiguity,codingInfo] = hePEDisambiguityCalculation(cfg)
%hePEDisambiguityCalculation PE Disambiguity calculation. IEEE Std 802.11ax-2021, Section 27.3.13
    [~,TXTIME,codingInfo] = wlan.internal.hePLMETxTimePrimative(cfg);
    npp = wlan.internal.heNominalPacketPadding(cfg);
    trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,codingInfo.PreFECPaddingFactor,npp,codingInfo.NSYM);
    TSYM = trc.TSYM;
    SignalExtension = 0; % Assume 5 GHz band
    TPE = trc.TPE;

    % Signal extension is in microseconds and should be 0 if in 5 GHz band
    % or 6us in the 2.4 GHz band if required (IEEE 802.11-2016 Table 19-25
    % and IEEE Std 802.11ax-2021, Section 27.3.6.3)
    assert(any(SignalExtension==[0 6]));
    sf = 1e-3; % TXTIME in ns so convert to us for equation before comparison
    peDisambiguity = (TPE+round(4/sf*(ceil((TXTIME*sf-SignalExtension-20)/4)-(TXTIME*sf-SignalExtension-20)/4)))>=TSYM; % IEEE Std 802.11ax-2021, Equation 27-118
end
