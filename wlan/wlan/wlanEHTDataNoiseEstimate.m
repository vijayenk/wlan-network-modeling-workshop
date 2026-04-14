function nest = wlanEHTDataNoiseEstimate(x,chanEstSSPilots,cfg,ruNumber)
%wlanEHTDataNoiseEstimate Estimate noise power using EHT data field pilots
%
%   NEST = wlanEHTDataNoiseEstimate(x,CHANESTSSPILOTS,CFG) estimates the
%   variance of additive white Gaussian noise using the demodulated pilot
%   symbols in the EHT data field and single-stream channel estimates at
%   pilot subcarriers. The noise estimate is averaged over the number of
%   symbols and receive antennas.
%
%   NEST is a single or double positive real scalar.
%
%   X is a complex Nsp-by-Nsym-by-Nr array containing demodulated pilot
%   subcarriers in EHT data field, where Nsp is the number of pilot
%   subcarriers, Nsym is the number of demodulated EHT-Data symbols, and Nr
%   is the number of receive antennas.
%
%   CHANESTSSPILOTS is a complex Nsp-by-Nltf-by-Nr array containing the
%   channel gains at pilot subcarrier locations for each symbol, assuming
%   one space-time stream at the transmitter. Nltf is the number of EHT-LTF
%   symbols.
%
%   CFG is a format configuration object of type wlanEHTMUConfig, or
%   wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   NEST = wlanEHTDataNoiseEstimate(...,RUNUMBER) estimates the variance of
%   additive white Gaussian noise for an EHT packet format. RUNUMBER is the
%   RU (resource unit) index.
%
%   #  For an EHT MU OFDMA PPDU type, RUNUMBER is required.
%   #  For an EHT MU non-OFDMA PPDU type, RUNUMBER is not required.
%   #  For an EHT TB PPDU type RUNUMBER is not required.
%   #  For wlanEHTRecoveryConfig, RUNUMBER is not required.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen
arguments
    x {mustBeFloat,mustBeFinite}
    chanEstSSPilots {mustBeFloat}
    cfg (1,1) {wlan.internal.validateEHTConfigObject(cfg)}
    ruNumber (1,1) {mustBeFloat,mustBePositive,mustBeInteger} = 1
end

if isa(cfg,'wlanEHTMUConfig')
    allocInfo = ruInfo(cfg);
    if nargin==4 && compressionMode(cfg)==0
        coder.internal.errorIf(ruNumber>allocInfo.NumRUs,'wlan:shared:InvalidRUIdx',ruNumber,allocInfo.NumRUs);
        ruSize = allocInfo.RUSizes{ruNumber};
    else
        ruSize = allocInfo.RUSizes{1};
    end
    sigInfo = wlan.internal.ehtSIGCodingInfo(cfg);
    numEHTSIG = sigInfo.NumSIGSymbols; % Number of OFDM symbols in EHT-SIG field
elseif isa(cfg,'wlanEHTRecoveryConfig')
    wlan.internal.mustBeDefined(cfg.RUSize,'RUSize');
    wlan.internal.mustBeDefined(cfg.NumEHTSIGSymbolsSignaled,'NumEHTSIGSymbolsSignaled');
    ruSize = cfg.RUSize;
    numEHTSIG = cfg.NumEHTSIGSymbolsSignaled;
else % EHT TB
    allocInfo = ruInfo(cfg);
    ruSize = allocInfo.RUSizes{1};
    numEHTSIG = 0;
end

% Validate number of pilot subcarriers, corresponding to an RU size
[nsp,Nsym,nrx] = size(x);
tac = wlan.internal.heRUToneAllocationConstants(sum(ruSize));
coder.internal.errorIf(nsp~=tac.NSP,'wlan:shared:IncorrectSC',tac.NSP,nsp);

% Validate chanEstSSPilots, corresponding to an RU size
[nspChanEst,~,nrxChanEst] = size(chanEstSSPilots);
coder.internal.errorIf(nspChanEst~=tac.NSP,'wlan:shared:IncorrectPilotSC',tac.NSD,nspChanEst);

% Validate number of receive antennas
coder.internal.errorIf(nrx~=nrxChanEst,'wlan:shared:IncorrectNumRx');

numUSIG = 2; % Number of OFDM symbols in U-SIG field
z = 2+numUSIG+numEHTSIG; % Pilot symbol offset
% Get the reference pilots for one space-time stream, pilot sequence same
% for all space-time streams
n = 0:Nsym-1;
refPilots = wlan.internal.ehtPilots(ruSize,1,n,z); % Nsp-by-Nsym-by-1

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
nest = real(mean(err.*conj(err),'all'));

end
