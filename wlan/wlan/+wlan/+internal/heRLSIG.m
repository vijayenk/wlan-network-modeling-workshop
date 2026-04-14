function [y, bits] = heRLSIG(cfgHE,varargin)
%heRLSIG Repeated Non-HT SIGNAL Field (RL-SIG)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heRLSIG(CFGHE) generates the Repeated Non-HT SIGNAL Field (RL-SIG)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain RL-SIG signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heRLSIG(CFGHE,OSF) generates the RL-SIG for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   Example: Generate the RL-SIG field for a single user HE PPDU format.
%
%     cfgHE = wlanHESUConfig();
%     y = wlan.internal.heRLSIG(cfgHE);
%     plot(abs(y));
%
%   See also wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

% Set the RATE value to 4 bit binary code. The code value is fixed to [1 1
% 0 1] representing 6Mb/s in legacy 20MHz CBW, IEEE Std 802.11ax-2021 Section
% 27.3.11.5.

R = [1; 1; 0; 1];

% L-SIG length calculation
if isa(cfgHE,'wlanHETBConfig')
    [~,TXTIME] = wlan.internal.hePLMETxTimePrimative(cfgHE);
    length = wlan.internal.heLSIGLengthCalculation(cfgHE,TXTIME);
else
    length = wlan.internal.heLSIGLengthCalculation(cfgHE);
end

% Construct the SIGNAL field. Length parameter with LSB first, which is 12
% bits
lengthBits = int2bit(length,12,false);

% Even parity bit 
parityBit = mod(sum([R;lengthBits],1),2);

% The SIGNAL field (IEEE Std 802.11-2016, Section 17.3.4.2)
bits = [R; 0; lengthBits; parityBit; zeros(6,1,'int8')];

% Process RL-SIG bits
encodedBits = wlanBCCEncode(bits,'1/2');
interleavedBits = wlanBCCInterleave(encodedBits,'Non-HT',48);
modData = wlanConstellationMap(interleavedBits,1);

% Data mapping with extra BPSK symbols
cfgOFDM      = wlan.internal.hePreHEOFDMConfig(cfgHE.ChannelBandwidth,'RL-SIG');
num20        = cfgOFDM.NumSubchannels;
CPLen        = cfgOFDM.CyclicPrefixLength;
N_RLSIG_TONE = cfgOFDM.NumTones;
dataSymbol   = complex(zeros(cfgOFDM.FFTLength,1));

if strcmp(packetFormat(cfgHE),'HE-EXT-SU')
    SF = sqrt(2);
    % Subcarrier based scaling factor only applied to HE_EXT_SU format
    dataSymbol(cfgOFDM.DataIndices,1) = repmat([-SF; -SF; modData; -SF; SF],num20,1);
else
    dataSymbol(cfgOFDM.DataIndices,1) = repmat([-1; -1; modData; -1; 1],num20,1);
end

% Add pilot symbols, from IEEE Std 802.11-2016, Equation 19-14
Nsym = 1; % One symbol
z = 1;    % Second symbol with pilots
dataSymbol(cfgOFDM.PilotIndices,1) = repmat(wlan.internal.nonHTPilots(Nsym,z),num20,1);
[rlsig,scalingFactor] = wlan.internal.hePreHEFieldMap(dataSymbol,N_RLSIG_TONE,cfgHE);

% OFDM modulate
y = wlan.internal.ofdmModulate(rlsig,CPLen,varargin{:})*scalingFactor;

end
