function nest = wlanHEDataNoiseEstimate(x,chanEstSSPilots,cfg,ruNumber)
%wlanHEDataNoiseEstimate Estimate noise power using HE data field pilots
%
%   NEST = wlanHEDataNoiseEstimate(x,CHANESTSSPILOTS,CFGHE) estimates the
%   variance of additive white Gaussian noise using the demodulated pilot
%   symbols in the HE data field and single-stream channel estimates at
%   pilot subcarriers. The noise estimate is averaged over the number of
%   symbols and receive antennas.
%
%   NEST is a single or double positive real scalar.
%
%   X is a complex Nsp-by-Nsym-by-Nr array containing the demodulated pilot
%   subcarriers in the HE data field, where Nsp is the number of pilot
%   subcarriers, Nsym is the number of demodulated HE-Data symbols, and Nr
%   is the number of receive antennas.
%
%   CHANESTSSPILOTS is a single or double complex Nsp-by-Nltf-by-Nr array
%   containing the channel gains at pilot subcarrier locations for each
%   symbol, assuming one space-time stream at the transmitter. Nltf is the
%   number of HE-LTF symbols.
%
%   CFGHE is a format configuration object of type wlanHESUConfig,
%   wlanHETBConfig, or wlanHERecoveryConfig.
%
%   NEST = wlanHEDataNoiseEstimate(X,CHANESTSSPILOTS,CFGMU,RUNUMBER)
%   estimates the variance of additive white Gaussian noise for the
%   multi-user HE format input X.
%
%   CFGMU is a format configuration object of type wlanHEMUConfig.
%
%   RUNUMBER is the resource unit (RU) index.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen
arguments
    x {mustBeFloat,mustBeFinite}
    chanEstSSPilots {mustBeFloat}
    cfg (1,1) {wlan.internal.validateHEConfigObject(cfg)}
    ruNumber (1,1) {mustBeFloat,mustBePositive,mustBeInteger} = 1
end

if isa(cfg,'wlanHEMUConfig')
    narginchk(4,4)
    sigbInfo = wlan.internal.heSIGBCodingInfo(cfg);
    numHESIGB = sigbInfo.NumSymbols;
    pktFormat = packetFormat(cfg);
    allocInfo = ruInfo(cfg);
    coder.internal.errorIf(ruNumber>allocInfo.NumRUs,'wlan:shared:InvalidRUIdx',ruNumber,allocInfo.NumRUs);
    ruSize = allocInfo.RUSizes(ruNumber);
elseif isa(cfg,'wlanHERecoveryConfig')
    wlan.internal.mustBeDefined(cfg.RUSize,'RUSize');
    wlan.internal.mustBeDefined(cfg.PacketFormat,'PacketFormat');
    ruSize = cfg.RUSize;
    pktFormat = cfg.PacketFormat;
    if strcmp(pktFormat,'HE-MU')
        s = getSIGBLength(cfg);
        numHESIGB = s.NumSIGBSymbols;
    else
        numHESIGB = 0;
    end
else
    % SU, EXT SU, TB
    numHESIGB = 0;
    pktFormat = packetFormat(cfg);
    allocInfo = ruInfo(cfg);
    ruSize = allocInfo.RUSizes(1);
end

% Validate number of pilot subcarriers, corresponding to an RU size
[nsp,Nsym,nrx] = size(x);
tac = wlan.internal.heRUToneAllocationConstants(ruSize);
coder.internal.errorIf(nsp~=tac.NSP,'wlan:shared:IncorrectSC',tac.NSP,nsp);

% Validate chanEstSSPilots, corresponding to an RU size
[nspChanEst,~,nrxChanEst] = size(chanEstSSPilots);
coder.internal.errorIf(nspChanEst~=tac.NSP,'wlan:shared:IncorrectPilotSC',tac.NSD,nspChanEst);

% Validate number of receive antennas
coder.internal.errorIf(nrx~=nrxChanEst,'wlan:shared:IncorrectNumRx');

if strcmp(pktFormat,'HE-EXT-SU')
    numHESIGA = 4;
else % SU or MU
    numHESIGA = 2;
end

z = 2+numHESIGA+numHESIGB; % Pilot symbol offset
% Get the reference pilots for one space-time stream, pilot sequence same
% for all space-time streams
n = 0:Nsym-1;
refPilots = wlan.internal.hePilots(ruSize,1,n,z); % Nsp-by-Nsym-by-1

% Average single-stream pilot estimates over symbols (2nd dimension)
avChanEstSSPilots = mean(chanEstSSPilots,2); % Nsp-by-1-by-Nrx

% Estimate channel at pilot location using least square estimates
chanEstPilotsLoc = x./refPilots; % Nsp-by-Nsym-by-Nrx

% Subtract the noisy least squares estimates of the channel at pilot symbol
% locations from the noise averaged single stream pilot symbol estimates of
% the channel
err = chanEstPilotsLoc-avChanEstSSPilots; % Nsp-by-Nsym-by-Nrx

% Get power of error and average over pilot symbols, subcarriers and
% receive antennas
useIdx = ~isnan(err); % NaNs may exist in 1xHELTF
nest = real(mean(err(useIdx).*conj(err(useIdx)),'all')); % For codegen

end
