function [y,bits] = ehtSIG(cfgEHT,varargin)
%ehtSIG EHT-SIG Field (EHT-SIG)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,BITS] = ehtSIG(CFGEHT) generates the EHT-SIG field (EHT-SIG)
%   time-domain signal for the EHT MU transmission format.
%
%   Y is the time-domain EHT-SIG signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   BITS are the EHT-SIG signaling bits. For OFDMA it is of type int8,
%   binary matrix of size NDBPS*NumSym-by-C-by-L, where NDBPS is the number
%   of data bits per symbols, NumSym is the number of EHT-SIG symbols. C is
%   the number of content channel. C is one for 20 MHz and two for 40 MHz,
%   80 MHz, 160 MHz, and 320 MHz channel bandwidth. L is the number of 80
%   MHz segments and is one for 20 MHz, 40 MHz, and 80 MHz. L is two and
%   four for 160 MHz and 320 MHz respectively.
%
%   For multi-user non-OFDMA the number of BITS is a binary matrix of size
%   NDBPS*NumSym-by-C. For single-user non-OFDMA and NDP the binary matrix
%   is of size NDBPS*NumSym-by-1.
%
%   CFGEHT is the format configuration object of type <a
%   href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a>.
%
%   Y = ehtSIG(CFGEHT,OSF) generates a signal oversampled by the
%   oversampling factor OSF. When not specified, 1 is assumed.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

osf = 1;
if nargin>1
    osf = varargin{1};
end

[bits,codingInfo] = wlan.internal.ehtSIGBits(cfgEHT);

Nsym = codingInfo.NumSIGSymbols; % Number of EHT-SIG symbols
L = codingInfo.NumSegments; % Number of segments

% OFDM parameters
chanBW = cfgEHT.ChannelBandwidth;
cfgOFDM = wlan.internal.hePreHEOFDMConfig(chanBW);
Nfft = cfgOFDM.FFTLength;
cpLen = cfgOFDM.CyclicPrefixLength;
chBW = wlan.internal.cbwStr2Num(chanBW);
num20 = cfgOFDM.NumSubchannels;

% Number of 20 MHz repetitions within a 80 MHz subblock
switch chBW
    case 20
        num20Repetitions = 1; 
    case 40
        num20Repetitions = 2;
    otherwise 
        num20Repetitions = 4;
end

if cfgEHT.pIsOFDMA
    N = ceil(num20Repetitions/2); % Number of content channel repetitions
    N_Seq = repmat([1 2],1,N);
    N_Seq = N_Seq(1:num20Repetitions); % Repeat within an 80 MHz subblock
else
    N = ceil(num20/2); % Number of content channel repetitions
    N_Seq = repmat([1 2],1,N);
    N_Seq = N_Seq(1:num20); % Repetition sequence
    num20Repetitions = num20; % There is a single block in non-OFDMA, SU or NDP
end

dataSym = coder.nullcopy(complex(zeros(52*num20,Nsym))); % NSD is fixed i.e. 52
% Interleave parameters
NCBPSSI = codingInfo.NCBPS/codingInfo.NSS;
ruSize = 56; % RUSize 56 is fixed as defined in Table 27-35 of IEEE Std 802.11ax-2021

for i=1:L
    % Encode each content channel within a 80 MHz frequency segment
    encodedBits = wlanBCCEncode(bits(:,:,i),codingInfo.Rate);

    % Interleave all bits together, as effectively they will be split at symbol boundaries
    interleavedBits = wlan.internal.heBCCInterleave(encodedBits(:),ruSize,codingInfo.NBPSCS,NCBPSSI,codingInfo.DCM);

    % Reshape to form OFDM symbols, NCBPS-by-NumSym-by-C
    interleavedSym = reshape(interleavedBits,codingInfo.NCBPS,Nsym,codingInfo.NumContentChannels);

    % Constellation mapping (with optional DCM)
    mappedSym = wlan.internal.heConstellationMap(interleavedSym,codingInfo.NBPSCS,codingInfo.DCM); % 52-by-NumSym-by-C

    if codingInfo.CompressionMode==1 % Single user or NDP
        dataSym((1:52*num20)+(52*num20)*(i-1),:) = repmat(mappedSym,num20,1); % 52*num20-by-NumSym
    else
        % Replicate over 20 MHz segment
        dataSym((1:52*num20Repetitions)+(52*num20Repetitions)*(i-1),:) = reshape(permute(mappedSym(:,:,N_Seq),[1 3 2]),[],Nsym,1); % 52*num20Repetitions-by-NumSym
    end
end

z = 4; % Pilot symbols offset
% Pilots across content channels
pilotSym = repmat(wlan.internal.nonHTPilots(Nsym,z),num20,1); % num20-by-numSym

% Map data and pilots
sym = complex(zeros(Nfft,Nsym));
sym(cfgOFDM.DataIndices,:) = dataSym;
sym(cfgOFDM.PilotIndices,:) = pilotSym;

% Apply gamma rotation per 20 MHz frequency segment
[sym,scalingFactor] = wlan.internal.ehtPreEHTFieldMap(sym,cfgOFDM.NumTones,cfgEHT);

if cfgEHT.EHTSIGMCS~=15
    % Add Gamma scaling per content channel
    GammaRef = ones(Nfft,1);
    dataInd = reshape(cfgOFDM.DataIndices,[],num20);
    % Negate every second data symbol in the second half of each 20 MHz channel
    GammaRef(dataInd(end/2+1+1:2:end,:)) = -1;
    sym = sym.*GammaRef;
end

% OFDM modulate
if osf>1
    padding = zeros((osf-1)*Nfft/2,Nsym,cfgEHT.NumTransmitAntennas,'like',sym);
    sym = [padding; sym; padding];
    scalingFactor = scalingFactor*osf;
    cpLen = cpLen*osf;
end
y = wlan.internal.ofdmModulate(sym,cpLen)*scalingFactor;

end