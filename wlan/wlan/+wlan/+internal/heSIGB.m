function [y, bits] = heSIGB(cfgHE,varargin)
%heSIGB HE Signal B Field (HE-SIG-B)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSIGB(CFGHE) generates the HE Signal B Field (HE-SIG-B)
%   time-domain signal for the HE multiuser (MU) transmission format.
%
%   Y is the time-domain HE-SIG-B signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   BITS are the HE-SIG-B signaling bits. It is of type double, binary
%   column vector. The length of HE-SIG-B depends on the number of RUs and
%   the users within each RU.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a> 
%
%   Y = heSIGB(CFGHE,OSF) generates the HE-SIG-B for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   Examples:
%
%   Example 1:
%       % Generate HE-SIG-B field for an 80MHz multiuser PPDU (OFDMA)
%       % format.
%
%       cfgHE = wlanHEMUConfig([0 1 2 3]);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
%
%   Example 2:
%       % Generate HE-SIG-B field for an 80MHz multiuser PPDU (MU-MIMO and
%       % OFDMA) format.
%
%       cfgHE = wlanHEMUConfig([0 193 192 194]);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
%
%   Example 3:
%       % Generate HE-SIG-B field for an 80MHz multiuser PPDU (OFDMA)
%       % format with preamble puncturing.
%
%       cfgHE = wlanHEMUConfig([0 113 2 3]);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
%
%   Example 4:
%       % Generate HE-SIG-B field for an 80MHz multiuser PPDU (OFDMA)
%       % format with 4 users in HE-SIG-B content channel 1 and 2 users in 
%       % HE-SIG-B content channel 2.
%
%       cfgHE = wlanHEMUConfig([202 114 192 193]);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
%
%   Example 5:
%       % Generate HE-SIG-B field for a full bandwidth MU-MIMO
%       % configuration at 80MHz bandwidth with SIGB compression. There are
%       % four users in HE-SIG-B content channel 1 and three users in
%       % HE-SIG-B content channel 2.
%
%       cfgHE = wlanHEMUConfig(214);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
% 
%   Example 6:
%       % Generate HE-SIG-B field for a full bandwidth MU-MIMO
%       % configuration at 80MHz bandwidth without SIGB compression. There
%       % are seven users in HE-SIG-B content channel 1 and no user in
%       % HE-SIG-B content channel 2.
%
%       cfgHE = wlanHEMUConfig([214 115 115 115]);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
%
%   Example 7:
%       % Generate HE-SIG-B field for a full bandwidth MU-MIMO 
%       % configuration at 20MHz bandwidth with SIGB compression. The three
%       % users are on a single content channel. The content channel
%       % includes both the common and user field bits.
%
%       cfgHE = wlanHEMUConfig(194);
%       y = wlan.internal.heSIGB(cfgHE);
%       plot(abs(y));
%
%   See also wlanHEMUConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

validateattributes(cfgHE,{'wlanHEMUConfig'},{'scalar'},mfilename,'HE-MU format configuration object');

[bits,sigbInfo] = wlan.internal.heSIGBBits(cfgHE);

% Encode each content channel
% According to IEEE 11-16-0037/01 we can effectively code all of HE-SIG-B
% at once and this is equivalent to rate 1/2 encoding each field and then
% performing continuous puncturing. Encode each content channel separately
% (a column)
encodedBits = wlanBCCEncode(bits,sigbInfo.Rate);

% Interleave all bits together, as effectively they will be split at symbol
% boundaries
numSeg = 1; % BCC only valid for RU<=242 therefore 1 segment, IEEE Std 802.11ax-2021, Section 27.3.12.8
NCBPSSI = sigbInfo.NCBPS/sigbInfo.NSS/numSeg;
ruSize = 56; % RuSize 56 fixed for HE-SIG-B. IEEE Std 802.11ax-2021, Table 27-16
interleavedBits = wlan.internal.heBCCInterleave(encodedBits(:),ruSize,sigbInfo.NBPSCS,NCBPSSI,sigbInfo.DCM);

% Reshape to form OFDM symbols, NCBPS-by-numSym-by-numContentChs
interleavedSym = reshape(interleavedBits,sigbInfo.NCBPS,sigbInfo.NumSymbols,sigbInfo.NumContentChannels);

% Constellation mapping (with optional DCM), 52-by-numSym-by-numContentChs
mappedSym = wlan.internal.heConstellationMap(interleavedSym,sigbInfo.NBPSCS,cfgHE.SIGBDCM);

cfgOFDM = wlan.internal.hePreHEOFDMConfig(cfgHE.ChannelBandwidth,'HE-SIG-B');
Nfft    = cfgOFDM.FFTLength;
CPLen   = cfgOFDM.CyclicPrefixLength;
num20   = cfgOFDM.NumSubchannels;
numSym  = sigbInfo.NumSymbols;

% Total number of standard defined cyclic shifts for eight transmit antenna
% chains for the pre-HE portion of the packet. IEEE Std 802.11-2016, Table
% 21-10.
numCyclicShift = 8;
numTx = cfgHE.NumTransmitAntennas;
    
% Duplicate the content channels, alternating, across full bandwidth. The
% third dimension of mappedSym is the content channels, in order of low to
% high absolute frequency, therefore duplicate them in that order.
N = ceil(num20/2); % Number of content channel repetitions
N_Seq = repmat([1 2],1,N);
N_Seq = N_Seq(1:num20); % Repetition sequence
dataSym = reshape(permute(mappedSym(:,:,N_Seq),[1 3 2]),[],numSym,1); % 52*num20-by-numSym

z = 4; % Pilot symbols offset
% Pilots across content channels
pilotSym = repmat(wlan.internal.nonHTPilots(numSym,z),num20,1); % 4*num20-by-numSym 

% Map data and pilots
sigBsymbol = complex(zeros(Nfft,numSym));
sigBsymbol(cfgOFDM.DataIndices,:) = dataSym;
sigBsymbol(cfgOFDM.PilotIndices,:) = pilotSym;

% Apply gamma rotation per 20 MHz frequency segment
[gamma,punctureMask] = wlan.internal.hePreHECarrierRotations(cfgHE);
sigBsymbol = sigBsymbol .* gamma;

if ~(cfgHE.SIGBMCS == 0 && cfgHE.SIGBDCM== true)
    % Add Gamma scaling per content channel
    GammaRef = ones(Nfft,1);
    dataInd = reshape(cfgOFDM.DataIndices,[],num20);
    % Negate every second data symbol in the second half of each 20 MHz
    % channel
    GammaRef(dataInd(end/2+1+1:2:end,:)) = -1;
    sigBsymbol = sigBsymbol .* GammaRef;
end

% Replicate over multiple antennas
symMIMO = repmat(sigBsymbol,1,1,cfgHE.NumTransmitAntennas);

% Cyclic shift addition
csh = wlan.internal.getCyclicShiftSamples(20*num20,numTx,numCyclicShift,cfgHE.PreHECyclicShifts);
cyclicShiftSIGB = wlan.internal.cyclicShift(symMIMO,csh,Nfft);

% OFDM modulate
puncNorm = sum(~punctureMask)/numel(punctureMask); % Normalize for punctured subchannels as per IEEE Std 802.11ax-2021, Equation 27-21
scalingFactor = Nfft/sqrt(cfgHE.NumTransmitAntennas*cfgOFDM.NumTones*puncNorm);
y = wlan.internal.ofdmModulate(cyclicShiftSIGB,CPLen,varargin{:})*scalingFactor;

end
