function [y,scalingFactor] = ehtPreEHTFieldMap(dataSymbol,numTones,cfgEHT)
%ehtPreEHTFieldMap Apply Cyclic Shift and Carrier Rotation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtPreEHTFieldMap(DATASYMBOL,NUMTONES,CFGEHT) apply cyclic shift,
%   and carrier rotation on DATASYMBOL. DATASYMBOL is a frequency domain
%   samples of a given preamble field. NUMTONES is the number of carrier
%   tones in the given preamble field. CFGEHT is the format configuration
%   object.
%
%   Y is the frequency-domain preamble signal. It is a complex matrix of
%   size Ns-by-Nt where Ns represents the number of frequency-domain
%   samples and Nt represents the number of transmit antennas.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or 
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

chBW = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);
Nfft = size(dataSymbol,1);
numTx = cfgEHT.NumTransmitAntennas;
[gamma,punc] = wlan.internal.ehtPreEHTCarrierRotations(cfgEHT);

puncNorm = sum(~punc)/numel(punc);
scalingFactor = Nfft/(sqrt(cfgEHT.NumTransmitAntennas*numTones)*sqrt(puncNorm));

if any(strcmp(packetFormat(cfgEHT),{'EHT-TB','UHR-TB'})) % Power scaling for Pre-EHT/UHR TB fields
    scalingFactor = scalingFactor*cfgEHT.PreEHTPowerScalingFactor; % Section 36.3.11.4 of IEEE P802.11be/D7.0
end

% Apply gamma rotation to all symbols, puncturing subchannels
symRot = dataSymbol.*gamma;

% Replicate over multiple antennas
symMIMO = repmat(symRot,1,1,numTx);

% Total number of standard defined cyclic shifts for eight transmit
% antenna chains for the pre-EHT portion of the packet. IEEE Std
% 802.11-2016, Table 21-10.
numCyclicShift = 8;

% Cyclic shift addition for pre-EHT modulated field
csh = wlan.internal.getCyclicShiftSamples(chBW,numTx,numCyclicShift,cfgEHT.PreEHTCyclicShifts);
y = wlan.internal.cyclicShift(symMIMO,csh,Nfft);

end