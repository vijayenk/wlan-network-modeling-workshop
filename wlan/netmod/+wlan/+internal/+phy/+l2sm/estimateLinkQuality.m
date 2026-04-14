function SINR = estimateLinkQuality(soi, int, noiseFigure, subcarrierSubsampling)
%estimateLinkQuality Calculate the SINR per subcarrier and spatial stream
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SINR = estimateLinkQuality(SOI,INT,RUIDX,NF,SS) calculates the SINR per
%   subcarrier and spatial stream given the signal of interest SOI,
%   interferers INT, RU index RUIDX, noise figure NF, and subcarrier
%   subsampling factor SS.
%
%   SIG and INT are structures with the following fields:
%     Config      - Configuration object
%     Field       - 'data' or 'preamble'
%     OFDMConfig  - Structure with OFDM information
%     RUIndex     - RU index if an OFDMA configuration
%

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

numSOI = numel(soi); % Number of signals of interest
Psoi = [soi.RxPower].'; % Receive power of transmitter(s) of interest (force column)
field_soi = soi(1).Field; % All signals of interest have same field

isNonHT = isstruct(soi(1).Config) || isa(soi(1).Config, 'wlanNonHTConfig'); % CBW320NONHTDUP
rxOFDMInfo = soi(1).OFDMConfig; % OFDM info the same for all signals of interest

% Noise power at receiver in a subcarrier
BW = rxOFDMInfo.SampleRate/rxOFDMInfo.FFTLength; % Bandwidth per subcarrier (Hz)
N0 = wnet.internal.calculateThermalNoise(BW,noiseFigure); % Noise power per subcarrier (Watts)

% Get channel matrix for signal of interest
Hsoi = getChannel(soi(1), rxOFDMInfo, subcarrierSubsampling);

% Get precoding matrix for signal of interest
if numSOI > 1
    % Processing UL-OFDMA HE-TB preamble or CTS in response to MU-RTS
    assert(strcmp(field_soi,'preamble') || isNonHT,'Combined UL-OFDMA processing only supported for preamble or non-HT data (MU-RTS)')

    Pmax = max(Psoi);
    Pnorm = Psoi./Pmax; % Normalize all powers by max
    Psoi = Pmax; % Use max for rest of processing

    % Concatenate transmit antennas for spatial mapping matrices - treat as
    % a single transmission from one transmitter
    Wsoi = zeros(ceil(rxOFDMInfo.NumTones/subcarrierSubsampling), 1, 0); % Preamble or non-HT so single space-times stream
    for u = 1:numSOI
        W = wlan.internal.phy.l2sm.getPrecodingMatrix(soi(u), subcarrierSubsampling);
        W = W.*sqrt(Pnorm(u)); % Scale precoding matrix to account for power differences between uplink transmissions
        Wsoi = cat(3, Wsoi, W);
    end
else
    assert(soi.Config.NumTransmitAntennas==size(Hsoi,2),'Number of transmit antennas must match')
    Wsoi = wlan.internal.phy.l2sm.getPrecodingMatrix(soi, subcarrierSubsampling);
end
HW_soi = wireless.internal.L2SM.calculateHW(Hsoi, Wsoi);

% Combine subchannels if same data transmitted on multiple subchannels (a
% non-HT transmission, or the preamble). Each subchannel is treated as
% another set of receive antennas.
Nsc = rxOFDMInfo.NumSubchannels;
combineSC = Nsc>1 && (any(strcmp(field_soi,'preamble')) || isNonHT);
if combineSC
    HW_soi = wlan.internal.mergeSubchannels(HW_soi, Nsc);
end

% Calculate SINR
numInt = numel(int); % Number of interfering signals
if numInt > 0
    % With interference
    Pint = [int.RxPower].'; % Receive power of interferer(s) (force column)
    HW_int = cell(numInt, 1);
    for i = 1:numInt              
        % Get channel matrix and precoding for interferer (projected onto OFDM configuration of signal of interest)
        Hi = getChannel(int(i), rxOFDMInfo, subcarrierSubsampling);
        Wi = wlan.internal.phy.l2sm.getPrecodingMatrix(int(i), soi(1), subcarrierSubsampling);
        HWi = calculateHWInt(Hi,Wi);
        if combineSC
            HWi = wlan.internal.mergeSubchannels(HWi, Nsc);
        end
        HW_int{i} = HWi;
    end
    SINR = wireless.internal.L2SM.calculateSINRs(HW_soi, Psoi, N0, HW_int, Pint);
else
    % No interference
    SINR = wireless.internal.L2SM.calculateSINRs(HW_soi, Psoi, N0);
end
end

function H = getChannel(sig, ofdmInfo, subcarrierSubsampling)
    % Calculate channel matrix from path gains
    
    if subcarrierSubsampling>1
        % Subsample the channel
        ofdmInfo.ActiveFFTIndices = ofdmInfo.ActiveFFTIndices(1:subcarrierSubsampling:end);
    end
    Htmp = wlan.internal.phy.l2sm.perfectChannelEstimate(sig.PathGains, sig.PathFilters, ofdmInfo, sig.TimingOffset);
    % Average over symbols and permute to Nst-by-Nt-by-Nr
    H = permute(mean(Htmp,2),[1 3 4 5 2]);
end

function HW = calculateHWInt(H, W)
    % Combine channel and precoding matrix into an effective channel matrix

    % Create empty HW array with the same number of subcarriers as the
    % channel. Walk along the array using each precoding array in turn to
    % create effective channel matrix.
    [Nst_h,Nt_h,Nr_h] = size(H);
    Nsts_ruMax = max(cellfun(@width,W)); % Maxmimum number of space-time streams
    HW = zeros(Nst_h,Nsts_ruMax,Nr_h);
    offset = 0;
    for i = 1:numel(W)
        [Nst_wr,Nsts_wr,Ntx_wr] = size(W{i});
        assert(all(Nt_h==Ntx_wr),'Mismatch in precoding and channel matrix dimensions for interferer')
        
        stIdx = offset + (1:Nst_wr); % Indices of precoding subcarriers within channel
        HW(stIdx,1:Nsts_wr,:) = wireless.internal.L2SM.calculateHW(H(stIdx,:,:), W{i});
        offset = offset+Nst_wr;
    end
end
