function [ofdmDemod,cpe,peg,pilotGain] = trackingOFDMDemodulate(rxData,chanEstPilots,fnRefPilots,fnDemodulator,numOFDMSym,cfgOFDM,cfgRec)
%trackingOFDMDemodulate OFDM demodulation with pilot tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [SYM,CPE,PEG,PILOTGAIN] = trackingOFDMDemodulate(RXDATA,CHANESTPILOTS,
%     REFPILOTS,NUMOFDMSYM,SYMOFFSET,CFGOFDM,CFGREC) performs OFDM
%     demodulation of data symbols with optional pilot tracking.
%
%   SYM is a complex Nst-by-Nsym-by-Nr array containing the demodulated
%   symbols at active subcarriers. Nst represents the number of data and
%   pilot subcarriers, Nsym represents the number of OFDM symbols in the
%   Data field, and Nr represents the number of receiver antennas.
%
%   CPE is a column vector of length Nsym containing the common phase error
%   between each received and expected OFDM symbol.
%
%   PEG is a column vector of length Nsym containing the phase error
%   gradient per OFDM symbol in degrees per subcarrier. This error is
%   caused by a sample rate offset between transmitter and receiver.
%
%   PILOTGAIN is a Nsym-by-Nsp array containing the gain of each pilot
%   per symbol. Nsp is the number of pilots.
%
%   RXDATA is the received time-domain Data field signal, specified as an
%   Ns-by-Nr matrix of real or complex values. Ns represents the number of
%   time-domain samples in the Data field and Nr represents the number of
%   receive antennas. Ns can be greater than the Data field length; in this
%   case additional samples at the end of RXDATA, if not required, are not
%   used. When sample rate offset tracking is enabled using the optional
%   CFGREC argument, additional samples may be required in RXDATA. This is
%   to allow for the receiver running at a higher sample rate than the
%   transmitter and therefore more samples being required.
%
%   CHANESTPILOTS is a complex Nsp-by-Nsts-by-Nr array containing the
%   channel gains at pilot subcarriers. Nsts is the number of space-time
%   streams.
%
%   REFPILOTS is a function handle for a function which generates reference
%   pilots.
%
%   NUMOFDMSYM is the number of OFDM symbols expected.
%
%   SYMOFFSET is the OFDM sampling offset as a fraction of the cyclic
%   prefix.
%
%   CFGOFDM is an OFDM configuration structure.
%
%   CFGREC is a
%   <a href="matlab:help('trackingRecoveryConfig')">trackingRecoveryConfig</a>
%   configuration object that configures different algorithm options for
%   data recovery.
%
%   Table for time and phase trackings
%   -------------------------------------------------
%   | Time  | Phase |   Tracking functionality   |
%   -------------------------------------------------
%   |   0   |   0   |     No Joint tracking      |
%   |   0   |   1   |     Phase only tracking    |
%   |   1   |   0   |     Time only tracking     |
%   |   1   |   1   |      Joint tracking        |
%   -------------------------------------------------
%
%   If PilotGainTracking is false, there is no amplitude tracking. If
%   PilotGainTracking is true, there is amplitude tracking.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

cpe = [];
peg = [];
pilotGain = [];

if cfgRec.IQImbalanceCorrection
    [refPilots, usePilotInd] = fnRefPilots();

    % Use only pilots at usePilotInd locations as other pilots may face
    % interference from data subcarriers because of IQ imbalance
    cfgOFDM.PilotIndices = cfgOFDM.PilotIndices(usePilotInd,:,:);
    chanEstPilots = chanEstPilots(usePilotInd,:,:);
else
    refPilots = fnRefPilots();
end

if ~(cfgRec.PilotTimeTracking || cfgRec.PilotPhaseTracking || cfgRec.PilotGainTracking)
    % No tracking or measurements, just demodulate
    ofdmDemod = fnDemodulator(rxData);
    ofdmDemod = ofdmDemod(:,1:numOFDMSym,:); % Truncate output as extra samples may be passed
    return
end

% Extract the used pilot subcarriers if NaN exist in chanEst for 1xHE-LTF
[chanEstPilots,refPilots,cfgOFDM] = wlan.internal.extractUsedPilots(chanEstPilots,refPilots,cfgOFDM);

% Do common OFDM demodulation only when phase or gain tracking is enabled.
if cfgRec.PilotPhaseTracking || cfgRec.PilotGainTracking
    ofdmDemod = fnDemodulator(rxData);
    ofdmDemod = ofdmDemod(:,1:numOFDMSym,:); % Truncate output as extra samples may be passed
    ofdmDemodPilots = ofdmDemod(cfgOFDM.PilotIndices,:,:);
    estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilots,refPilots);
end

% Time only tracking or Joint tracking (Time and phase). Perform joint
% measurement and correction when both time and phase tracking are enabled.
if cfgRec.PilotTimeTracking
    % Reduce the size of the averaging window if it exceeds the number of
    % OFDM symbols. If it is even then use the largest odd window we can.
    if cfgRec.PilotTrackingWindow>numOFDMSym
        cfgRec.PilotTrackingWindow = numOFDMSym-(rem(numOFDMSym,2)==0);
    end
    [ofdmDemod,peg,cpe] = demodulateWithPhaseTracking(rxData,chanEstPilots,refPilots,fnDemodulator,numOFDMSym,cfgOFDM,cfgRec);
    % Compute the updated OFDM demodulated pilots from the time and
    % phase corrected ofdmDemod in case of joint tracking.
    ofdmDemodPilots = ofdmDemod(cfgOFDM.PilotIndices,:,:);
    % Phase only tracking
elseif cfgRec.PilotPhaseTracking
    cpe = wlan.internal.commonPhaseErrorEstimate(ofdmDemodPilots, estRxPilots);
    ofdmDemod = wlan.internal.commonPhaseErrorCorrect(ofdmDemod, cpe);
    cpe = cpe.';
end

% Amplitude only tracking
if cfgRec.PilotGainTracking
    % Estimate AE and gain correct symbols. 
    pilotGain = wlan.internal.amplitudeErrorEstimate(ofdmDemodPilots, estRxPilots);
    ofdmDemod = wlan.internal.amplitudeErrorCorrect(ofdmDemod, pilotGain);
end
end

function [ofdmDemod,peg,cpe] = demodulateWithPhaseTracking(rxData,chanEstPilots,refPilots,fnDemodulator,numOFDMSym,cfgOFDM,cfgRec)

pilotInd = cfgOFDM.PilotIndices;
N = cfgOFDM.FFTLength;                         % FFT length is samples
Ng = cfgOFDM.CPLength;                         % Number of samples in GI
Ns = (N+Ng);                                   % Number of samples per symbols
kp = cfgOFDM.ActiveFrequencyIndices(pilotInd); % Indices of pilot carrying subcarriers
Np = numel(pilotInd);                          % Number of pilot carrying subcarriers
Nt = cfgOFDM.NumTones;    % Number of active subcarriers
Nr = size(chanEstPilots,3);                    % Number of receive antennas

% Reshape for computation
chanEstPilotsR = permute(chanEstPilots,[3 2 1]);
refPilotsR = permute(refPilots,[3 1 2]); % Generate reference pilots

ofdmDemod = zeros(Nt,numOFDMSym,Nr,'like',1i);
perr = zeros(Np,numOFDMSym,'like',1i); % Pilot error
delta = zeros(numOFDMSym,1);
omega = zeros(numOFDMSym,1);
skipDupStore = zeros(numOFDMSym,1);
skipdup = 0;
nD = 0; % Number of OFDM symbols demodulated
for n = 1:numOFDMSym
    % Get index of samples to demodulate in current symbol
    skipDupStore(n) = skipdup;
    idx = (n-1)*Ns+(1:Ns)+skipdup;
    if any(idx>size(rxData,1))
        % Break from loop if we run out of data
        coder.internal.warning('wlan:trackingOFDMDemodulate:NotEnoughSamples',numOFDMSym,n-1);
        break;
    end

    % OFDM demodulation
    demodSym = fnDemodulator(rxData(idx,:));
    ofdmDemod(:,n,:) = demodSym(:,1,1:Nr); % for codegen

    % Calculate pilot error
    ofdmDemodPilots = demodSym(pilotInd,1,1:Nr);
    ofdmDemodPilotsR = permute(ofdmDemodPilots,[2 3 1]);

    for p = 1:Np
        perr(p,n) = reshape(conj(ofdmDemodPilotsR(1,:,p))*chanEstPilotsR(:,:,p)*refPilotsR(:,p,n),1,1);
    end

    % Average pilots over time window
    perridx = max((n-cfgRec.PilotTrackingWindow+1),1):n;
    % Find indices which span across a skip/dup
    spanSkipDup = perridx(skipDupStore(perridx)~=skipDupStore(perridx(end)));
    if any(spanSkipDup)
        % Remove phase shift offset caused by skip/dup and average
        skipdupVal = (skipDupStore(perridx)-skipDupStore(perridx(end))).';
        perrav = sum(perr(:,perridx).*exp(1i*2*pi*bsxfun(@times,skipdupVal,kp)/N),2);
    else
        perrav = sum(perr(:,perridx),2);
    end

    % Subtract the common phase error from the current estimates to
    % avoid needing to wrap (use phasor to avoid angles wrapping across
    % pilots before subtraction)
    sumperrav = sum(perrav); % Essentially weighted average of phases
    sumperrav = sumperrav./abs(sumperrav); % Normalize
    perrav = perrav.*conj(sumperrav);

    % Least square estimation with covariance estimate per symbol
    j = lscov([kp ones(size(kp))],angle(perrav),abs(perrav));
    delta(n) = j(1); % Time offset

    % Add subtracted common phase error to current estimate
    omega(n) = j(2)+angle(sumperrav);

    % Skip or duplicate a sample in the next OFDM symbol if
    % required
    if delta(n)>=(2*pi/N)*0.9
        skipdup = skipdup+1; % Skip
    elseif delta(n)<=-(2*pi/N)*0.9
        skipdup = skipdup-1; % Duplicate
    end
    nD = n; % Record number of demodulated symbols
end

% The averaging causes a delay which we correct for before applying
% correction
delay = (cfgRec.PilotTrackingWindow-1)/2;

% When a skip-dup occurred we changed the phase to allow averaging over
% the skip/dup. Now correct for any phase change applied
skipindTmp = bsxfun(@plus,(find((diff(skipDupStore))==1)+1),(0:delay-1));
skipind = skipindTmp(:); % for codegen
dupindTmp = bsxfun(@plus,(find((diff(skipDupStore))==-1)+1),(0:delay-1));
dupind = dupindTmp(:); % for codegen
skipCorrIdx = skipind(skipind<=numOFDMSym);
delta(skipCorrIdx) = delta(skipCorrIdx)+2*pi/N;
dupCorrIdx = dupind(dupind<=numOFDMSym);
delta(dupCorrIdx) = delta(dupCorrIdx)-2*pi/N;

% Use shrinking window at end of waveform to average pilots and account
% for delay
keepIdx = setdiff(1:numOFDMSym,2:2:cfgRec.PilotTrackingWindow); % Remove even averages at start when growing window
deltaTmp = [delta(keepIdx); zeros(delay,1)];
omegaTmp = [omega(keepIdx); zeros(delay,1)];
extDelta = zeros(delay,1);
for i = 1:delay
    % Remove difference of phases due to skip/dup over averaging window
    skipdupVal = (skipDupStore(nD-(cfgRec.PilotTrackingWindow-2*i)+1:nD)-skipDupStore(nD)).';
    perrav = sum(perr(:,nD-(cfgRec.PilotTrackingWindow-2*i)+1:nD).*exp(1i*2*pi.*bsxfun(@times,skipdupVal,kp)/N),2);
    % Remove average CPE before LS estimation to avoid need to wrap phase
    sumperrav = sum(perrav);
    sumperrav = sumperrav./abs(sumperrav); % Normalize
    angleperrav = angle(perrav.*conj(sumperrav));
    % Least-square estimation
    jt = lscov([kp ones(size(kp))],angleperrav,abs(perrav));
    extDelta(i) = jt(1);
    % Reapply phase offset removed for averaging due to skip/dup
    extDelta(i) = extDelta(i)-skipdupVal(delay-i+1)*2*pi/N;
    % Add removed CPE
    omegaTmp(nD-delay+i) = jt(2)+angle(sumperrav);
end
delta(1:nD) = [deltaTmp(1:nD-delay); extDelta];
omega = omegaTmp;

% Apply correction if requested
% Correction for timing
corr = exp(1i*delta.'.*cfgOFDM.ActiveFrequencyIndices);
% Correction for phase only when phase tracking is enabled
if cfgRec.PilotPhaseTracking
    corr = corr.*exp(1i*omega.');
end

% Apply per symbol correction of data subcarriers
ofdmDemod(:,1:nD,:) = ofdmDemod(:,1:nD,:).*corr(:,1:nD);
% Return estimate of impairments
cpe = -omega;
peg = -delta;

end

function x = lscov(A,b,V)
% Weights given, scale rows of design matrix and response.
D = sqrt(V(:));
A(:,1) = A(:,1).*D;
A(:,2) = A(:,2).*D;
b = b.*D;

% Factor the design matrix, incorporate covariances or weights into the
% system of equations, and transform the response vector.
[Q,R] = qr(A,0);
z = Q'*b;

% Compute the LS coefficients
x = real(R\z);
end

