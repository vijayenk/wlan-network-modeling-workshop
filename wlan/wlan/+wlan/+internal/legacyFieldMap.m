function [y,scalingFactor] = legacyFieldMap(sym,numTones,cfg)
%legacyFieldMap Apply cyclic shift and carrier rotation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = legacyFieldMap(SYM,NUMTONES,CFG) apply cyclic shift, and carrier
%   rotation on SYM. SYM is a frequency domain samples of a given preamble
%   field. NUMTONES is the number of carrier tones in the given preamble
%   field. CFG is the format configuration object.
%
%   Y is the frequency-domain preamble signal. It is a complex matrix of
%   size Ns-by-Nt where Ns represents the number of frequency-domain
%   samples and Nt represents the number of transmit antennas.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>,
%   <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, or <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>.

%   Copyright 2020-2021 The MathWorks, Inc.

%#codegen

Nfft = size(sym,1);

if any(strcmp(cfg.ChannelBandwidth,{'CBW5','CBW10'}))
    numTx = 1;  % Override cfgFormat and set to 1 only, for 802.11j/p
else
    numTx = cfg.NumTransmitAntennas;
end

% Apply gamma rotation to all symbols, puncturing subchannels
[gamma,punc] = wlan.internal.hePreHECarrierRotations(cfg);
symRot = sym .* gamma;

% Replicate over multiple antennas
symMIMO = repmat(symRot,1,1,numTx);

% Total number of standard defined cyclic shifts for eight transmit antenna
% chains for the NonHT or pre-VHT portion of the packet. IEEE Std
% 802.11-2016, Table 21-10.
numCyclicShift = 8;

if isa(cfg,'wlanWURConfig') 
    % No legacy cyclic shift is needed as number of transmit antennas must not exceed 8
    legacyCyclicShift = 0; 
else
    validateConfig(cfg,'CyclicShift'); % Validate cyclic shifts against the number of transmit antennas
    if isa(cfg,'wlanNonHTConfig')
        legacyCyclicShift = cfg.CyclicShifts;
    elseif isa(cfg,'wlanHTConfig')
        legacyCyclicShift = cfg.PreHTCyclicShifts;
        % Total number of standard defined cyclic shifts for four transmit
        % antenna chains for the pre-HT portion of the packet. IEEE Std
        % 802.11-2016, Table 19-9.
        numCyclicShift = 4;
    else % wlanVHTconfig
        legacyCyclicShift = cfg.PreVHTCyclicShifts;
    end
end

% Cyclic shift addition for legacy modulated field
chBW = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
csh = wlan.internal.getCyclicShiftSamples(chBW,numTx,numCyclicShift,legacyCyclicShift);
y = wlan.internal.cyclicShift(symMIMO,csh,Nfft);

% Scaling factor to normalize waveform power
puncNorm = sum(~punc)/numel(punc); % Normalize for punctured subchannels
scalingFactor = Nfft/sqrt(numTx*numTones*puncNorm);

end