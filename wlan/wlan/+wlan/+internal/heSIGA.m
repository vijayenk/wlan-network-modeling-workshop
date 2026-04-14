function [y, bits] = heSIGA(cfgHE,varargin)
%heSIGA HE Signal A Field (HE-SIG-A)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heSIGA(CFGHE) generates the HE Signal A Field (HE-SIG-A)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain HE-SIG-A signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   BITS are the HE-SIG-A signaling bits. It is of type double, binary
%   column vector of length 52.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heSIGA(CFGHE,OSF) generates the HE-SIG-A for the given oversampling
%   factor OSF. When not specified 1 is assumed.
%
%   Example: Generate HE-SIG-A field for an 80MHz multiuser PPDU format.
%
%     cfgHE = wlanHEMUConfig([0 1 2 3]);
%     cfgHE.MCSSIGB = 5
%     y = wlan.internal.heSIGA(cfgHE);
%     plot(abs(y));
%
%   See also wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

% Fixed encoding parameters for HE-SIG-A
ruSizeInterleave = 56; % IEEE BCC interleavers, Table 27-35
numBPSCS         = 1; 
numNDBPS         = 26; % Number of data bits in each symbols
numSeg           = 1;  % Single segment due to 20MHz
numCBPS          = numNDBPS*2;
numBPSSI         = numCBPS*numSeg;

% Generate HE-SIG-A bits
bits = wlan.internal.heSIGABits(cfgHE);

% DCM is not used for HE-SIG-A. IEEE Std 802.11ax-2021, Section 27.3.11.8.
DCM = false;

% Encode and interleave
encodedSIG = wlanBCCEncode(bits,'1/2');
interleavedData = wlan.internal.heBCCInterleave(encodedSIG,ruSizeInterleave,numBPSCS,numBPSSI,DCM);

if any(strcmp(packetFormat(cfgHE),{'HE-SU','HE-MU','HE-TB'}))
    Nsym = 2; % 2 HE-SIG-A symbols for HE-SU, HE-MU and HE-TB PPDU
    % Symbol A1 and A2
    phRot = 0;
    sym = wlanConstellationMap(reshape(interleavedData,numCBPS,2),numBPSCS,phRot);
else % 'HE-EXT-SU'
    Nsym = 4; % 4 HE-SIG-A symbols for HE extended range single user format
    sym = zeros(52,Nsym);
    
    % Symbol A1 and A3
    % Contains encoded and interleaved data
    phRot = 0;
    sym(:,[1 3]) = wlanConstellationMap(reshape(interleavedData,numCBPS,2),numBPSCS,phRot);
    
    % Symbol A2 and A4
    % Contains encoded but un-interleaved data
    phRot = [pi/2 0];
    sym(:,[2 4]) = wlanConstellationMap(reshape(encodedSIG,numCBPS,2),numBPSCS,phRot);
end

% Add pilots
% Setup for pilot symbols offset and number of pilot symbols in each format
z = 2; % Number of offset for the pilot symbols  
pilots = wlan.internal.nonHTPilots(Nsym,z);

% Pilot and data mapping
cfgOFDM         = wlan.internal.hePreHEOFDMConfig(cfgHE.ChannelBandwidth,'HE-SIG-A');
num20           = cfgOFDM.NumSubchannels;
N_HESIGA_TONE   = cfgOFDM.NumTones;
symOFDM         = complex(zeros(cfgOFDM.FFTLength,Nsym));

% Replicate over multiple 20MHz channel BWs
symOFDM(cfgOFDM.DataIndices,:)  = repmat(sym,num20,1); 
symOFDM(cfgOFDM.PilotIndices,:) = repmat(pilots,num20,1);
[hewSIGA,scalingFactor] = wlan.internal.hePreHEFieldMap(symOFDM,N_HESIGA_TONE,cfgHE);

% OFDM modulate
wout = wlan.internal.ofdmModulate(hewSIGA,cfgOFDM.CyclicPrefixLength,varargin{:});
y  = wout*scalingFactor;

end
