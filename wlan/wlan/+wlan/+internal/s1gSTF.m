function y = s1gSTF(cfgS1G,varargin)
%s1gSTF Short Training Field for S1G transmission format (S1G-STF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = s1gSTF(CFGS1G) generates the S1G Short Training Field (STF)
%   time-domain signal for the S1G transmission format.
%
%   Y is the time-domain S1G STF signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gSTF(cfgS1G,OSF) generates the S1G-STF for the given oversampling
%   factor OSF. When not specified 1 is assumed.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Generate STF as per IEEE P802.11ah/D5.0 Sections 24.3.8.2.1.2,
% 24.3.8.2.2.1.3, and 24.3.8.3.2

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
if ~strcmp(packetFormat(cfgS1G),'S1G-Long')
    validateConfig(cfgS1G,'SMappingMCS10');
end

% OFDM parameters
cfgOFDM = wlan.internal.s1gOFDMConfig(cfgS1G.ChannelBandwidth,'Long','STF');
Nsubchan = ceil(cfgOFDM.FFTLength/64);

numSTSTotal = sum(cfgS1G.NumSpaceTimeStreams);
if strcmp(packetFormat(cfgS1G),'S1G-1M')
    S = s1g1MHzSTFSequence();   
    numSTSTx = numSTSTotal;
    Ntone = 6; % Table 24-7 Tone scaling
else % { 'CBW2','CBW4','CBW4','CBW16' }
    % Non-HT L-STF (IEEE Std:802.11-2012, pg 1695)
    lstf = wlan.internal.lstfSequence();
    % The short training field consists of 12 subcarriers
    S = [zeros(6,1); lstf; zeros(5,1)];
    
    if strcmp(cfgS1G.Preamble,'Short')
        numSTSTx = numSTSTotal;
    else % Preamble=='Long'
        numSTSTx = cfgS1G.NumTransmitAntennas;
    end
    % Table 24-7 Tone scaling
    Ntone = Nsubchan*12; % 12 tones per 2 MHz subchannel
end

% Replicate over channel bandwidth & Tx, and apply phase rotation
lstfMIMO = repmat(S,Nsubchan,1,numSTSTx) .* cfgOFDM.CarrierRotations;

% Cyclic shift addition. The cyclic shift is applied on each transmit
% antenna or space-time stream depending on the mode
csh = wlan.internal.getCyclicShiftVal('S1G',numSTSTx, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));
stfCycShift = wlan.internal.cyclicShift(lstfMIMO,csh,cfgOFDM.FFTLength);

if strcmp(packetFormat(cfgS1G),'S1G-Long')
    % No P mapping matrix of spatial mapping as in omni-portion of packet
    stfSpatialMapped = stfCycShift;
else % 1M or >=2M Short
    % Apply P mapping matrix
    P = wlan.internal.mappingMatrix(numSTSTotal);
    Pd = P(1:numSTSTotal,1).'; % First column of P-matrix
    stfPCoded = stfCycShift .* permute(Pd,[1 3 2]);

    % Spatial mapping
    stfSpatialMapped = wlan.internal.spatialMap(stfPCoded,cfgS1G.SpatialMapping, ...
        cfgS1G.NumTransmitAntennas,cfgS1G.SpatialMappingMatrix);
end

% OFDM modulate
modOut = wlan.internal.ofdmModulate(stfSpatialMapped,0,varargin{:}); % 0 CP length
if strcmp(packetFormat(cfgS1G),'S1G-1M')
    out = [modOut; modOut; modOut; modOut; modOut]; % Repeat to fill 160 us
else % {'CBW2','CBW4','CBW8','CBW16'}
    out = [modOut; modOut; modOut(1:end/2,:)]; % Repeat to fill 80 us
end
% OFDM normalization factor
normFactor = cfgOFDM.FFTLength/sqrt(Ntone*numSTSTx); 
if cfgS1G.MCS==10
    normFactor = normFactor*sqrt(2); % 3dB boost for MCS10
end
y = out*normFactor;
end

function S = s1g1MHzSTFSequence()
% Section 24.3.8.3.2, IEEE P802.11ah/D5.0
S = complex(zeros(32,1));
k = [-12; -8; -4; 4; 8; 12]; % Non zero index
S(k+32/2+1) = [0.5; -1; 1; -1; -1; -0.5]*(1+1i)*sqrt(2/3); % 32-pt FFT
end
