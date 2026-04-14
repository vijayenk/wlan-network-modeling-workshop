function bits = ehtUSIGBits(cfg,L)
%ehtUSIGBits Generate U-SIG field bits for EHT MU and EHT TB format
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS = ehtUSIGBits(CFG,L) generates the U-SIG bits for the given
%   configuration and number of 80 MHz segments, L as defined in Table
%   36-33 of IEEE P802.11be/D2.0.
%
%   BITS is of type double, binary matrix of size 42-by-L, where L
%   represents the number of 80 MHz segments and is 1 for 20 MHz, 40 MHz,
%   and 80 MHz. L is 2 and 4 for 160 MHz and 320 MHz.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
isEHTMU = strcmp(packetFormat(cfg),'EHT-MU');

% U-SIG-1
% PHY Version Identifier
B100_02 = [0; 0; 0]; % Set to 0 for EHT

% Channel bandwidth
switch cbw
    case 20
        bandwidth = 0;
    case 40
        bandwidth = 1;
    case 80
        bandwidth = 2;
    case 160
        bandwidth = 3;
    otherwise % 320 MHz-1
        if cfg.Channelization==1 % 320 MHz-1
            bandwidth = 4;
        else % 320MHz-2
            bandwidth = 5;
        end
end
B103_05 = int2bit(bandwidth,3,false);

if isEHTMU
    % UL/DL Indication
    if cfg.UplinkIndication
        B106_06 = 1; % 1 for Uplink
    else
        B106_06 = 0; % 0 for Downlink
    end

    % BSS Color
    B107_12 = int2bit(cfg.BSSColor,6,false);

    % TXOP duration
    B113_19 = convertTXOPDuration(cfg.TXOPDuration);

    % Disregard
    B120_24 = [1 1 1 1 1].';

    % Validate
    B125_25 = 1;

    % U-SIG-2
    % PPDU type and compression mode
    mode = compressionMode(cfg);
    B200_01 = int2bit(mode,2,false);

    % Validate
    B202_02 = 1;

    % Punctured channel information
    if any(mode==[1 2])
        switch cbw
            case {20 40}
                puncturedBitsPerSegment = [0; 0; 0; 0; 0];
            otherwise
                puncturedBitsPerSegment = int2bit(cfg.PuncturedChannelFieldValue,5,false);
        end
        % Puncturing pattern per 80 MHz segment
        B203_07 = repmat(puncturedBitsPerSegment,1,L);
    else % mode==0
        puncturingPattern = repmat(cfg.PuncturingPattern,1,max(1,80/cbw)); % Extend punctured 20 MHz subchannels per 80 MHz segment for signaling
        B203_07 = [~reshape(puncturingPattern,4,max(ceil(cbw/80),1)); ones(1,max(1,cbw/80))]; % B7 is set to one
    end

    % Validate
    B208_08 = 1;

    % EHT-SIG MCS
    switch cfg.EHTSIGMCS
        case 0
            B209_10 = [0; 0];
        case 1
            B209_10 = [1; 0];
        case 3
            B209_10 = [0; 1];
        otherwise % MCS 15
            B209_10 = [1; 1];
    end

    % Number of EHT-SIG symbols 
    sigbInfo = wlan.internal.ehtSIGCodingInfo(cfg);
    B211_15 = int2bit(sigbInfo.NumSIGSymbols-1,5,false);

    % All bits other than puncturing pattern are same for all 80 MHz segments
    bits = [repmat([B100_02; B103_05; B106_06; B107_12; B113_19; B120_24; B125_25],1,L); repmat([B200_01; B202_02],1,L); B203_07; repmat([B208_08; B209_10; B211_15],1,L)];
else % EHT TB
    B106_06 = 1; % UL/DL Indication

    % BSS Color
    B107_12 = int2bit(cfg.BSSColor,6,false);

    % TXOP duration
    B113_19 = convertTXOPDuration(cfg.TXOPDuration);

    % Disregard
    B120_25 = cfg.DisregardBitsUSIG1;

    B200_01 = [0; 0]; % PPDU Type and Compressed Mode

    % Validate
    B202_02 = cfg.ValidateBitUSIG2;

    % Spatial Reuse 1
    B203_06 = int2bit(cfg.SpatialReuse1,4,false);

    % Spatial Reuse 2
    B207_10 = int2bit(cfg.SpatialReuse2,4,false);

    % Disregard
    B211_15 = cfg.DisregardBitsUSIG2;

    % Bits 0-41: Calculate CRC
    preCRCBits = [B100_02; B103_05; B106_06; B107_12; B113_19; B120_25; B200_01; B202_02; B203_06; B207_10; B211_15];

    % The U-SIG contents are identical in all non-punctured 20 MHz
    % subchannels within the PPDU bandwidth.
    bits = repmat(preCRCBits,1,L); % USIG bits per Segment
end

end


function y = convertTXOPDuration(x)
%convertTXOPDuration Convert TXOPDuration in microseconds into bits
%
%   X is in microseconds between 0 and 8448. Y is of type double, binary
%   vector of size 7-by-1 representing an integer between 1 and 127
%   inclusive as defined in Table 36-28 of IEEE P802.11be/D2.0.

if isempty(x) % No duration information is represented by 127
    y = int2bit(127,7,false);
elseif x < 512
    y = int2bit(2*floor(x/8),7,false); % b13b19
else
    y = int2bit(2*floor((x-512)/128)+1,7,false); % b13b19
end
end