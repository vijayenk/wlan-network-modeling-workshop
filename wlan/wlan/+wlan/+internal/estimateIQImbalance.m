function [iqImbal, activeSubchan] = estimateIQImbalance(lsigDemodData,lltfChanEstData,cfgOFDM)
%estimateIQImbalance Estimate IQ gain and phase imbalances using L-LTF channel estimates and L-SIG demodulated symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [IQIMBAL,ACTIVESUBCHAN] = estimateIQImbalance(LSIGDEMODDATA,LLTFCHANESTDATA,CFGOFDM)
%
%   IQIMBAL is the estimated IQ imbalance. It is a row vector of 2 elements
%   consisting of IQ gain imbalance in dB and IQ phase imbalance in
%   degrees.
%
%   ACTIVESUBCHAN is a column vector of active 20 MHz subchannels in the
%   given bandwidth
%
%   LSIGDEMODDATA are the demodulated LSIG data symbols
%
%   LLTFCHANESTDATA are the channel estimates corresponding to data
%   subcarriers
%
%   CFGOFDM is the OFDM configuration object

%   Reference:
%   [1] M. Janaswamy, N. K. Chavali and S. Batabyal, "Measurement of
%   transmitter IQ parameters in HT and VHT wireless LAN systems," 2016
%   International Conference on Signal Processing and Communications
%   (SPCOM), Bangalore.

%   Copyright 2025 The MathWorks, Inc.

if isfield(cfgOFDM,'ActiveFFTIndices')
    dataInd = cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices);
else
    dataInd = cfgOFDM.DataIndices;
end
numSubchannels = cfgOFDM.NumSubchannels;

% Detect active subchannels and subcarriers
activeSubchan = wlan.internal.detectActiveSubchan(lsigDemodData,numSubchannels);
subCPerSubCh = 64;
activeSubChanMask = repelem(activeSubchan,subCPerSubCh,1);


% Generate reference LLTF symbols to compute gamma ratios
[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
numLSIGDataPerSubChan = numel(dataInd)/numSubchannels;
if numLSIGDataPerSubChan==52
    lltfSeqFull = [zeros(4,1); -1; -1; lltfLower; 0; lltfUpper; -1; 1; zeros(3,1)];
else
    lltfSeqFull = [zeros(6,1); lltfLower; 0; lltfUpper; zeros(5,1)];
end
lltfSeqFull = repmat(lltfSeqFull,numSubchannels,1);
lltfSeqActive = lltfSeqFull(dataInd);
% Compute ratio of conjugate mirror reference symbol and current reference
% symbol as given in eq (7) of [1]
refSymRatio = conj(lltfSeqActive(end:-1:1))./lltfSeqActive;

% Obtain tone rotations
tonerot = wlan.internal.vhtCarrierRotations(numSubchannels);
tonerot = tonerot.*double(activeSubChanMask);
toneRotInv = tonerot(end:-1:1);
tkData = tonerot(dataInd);
tminuskData = toneRotInv(dataInd);

% Equalize L-SIG symbols with LLTF channel estimates by LS method
lsigEqSym = lsigDemodData./lltfChanEstData;
lsigEqSym = mean(lsigEqSym,[2 3]);

% Demap equalized L-SIG symbols to nearest BPSK constellation point. The IQ
% imbalance doesn't affect this demapping. Use the demapped symbols as
% reference symbols.
xk = sign(real(lsigEqSym));
xminusk = xk(end:-1:1);

% Formulae used:
% beta = 1-alpha
% lsigDemodData = (alpha*xk*tk+beta*conj(xminusk)*conj(tminusk))*H;
% lltfChEst = (alpha*tk+beta*conj(tminusk)*gammaRatio)*H;
% lsigEqSym = (alpha*xk*tk+beta*conj(xminusk)*conj(tminusk))/(alpha*tk+beta*conj(tminusk))
% tk and tminusk are tone rotations of current subchannel and mirror subchannel respectively.
% Obtain alpha from the above equation as all other values are known.
num = (xk-lsigEqSym);
den = (lsigEqSym.*refSymRatio-xminusk);
alphaInv = 1+tkData.*num./(conj(tminuskData).*den);
alphaAllSubC = 1./alphaInv;

% Choose subcarrier indices for averaging the alpha estimates
if numSubchannels==2
    % Consider imaginary tone rotations for 40 MHz
    a = (xk.*tkData+xminusk.*conj(tminuskData))./(tkData+refSymRatio.*conj(tminuskData));
    ind2 = (a~=1 & a~=-1 & tkData~=0 & tminuskData~=0);
else
    % 20, 80, 160, 320 MHz
    ind2 = bitxor(xk.*tkData~=xminusk.*tminuskData,tkData~=refSymRatio.*tminuskData) & (tkData~=0 & tminuskData~=0);
end
alphaEst = mean(alphaAllSubC(ind2),1);

if any(lsigDemodData(activeSubChanMask(dataInd))==0)
    % When lsigDemodData of an active subchannel has zeros, alphaEst is NaN.
    % Assign it as 1 to make it finite.
    alphaEst = 1;
end

% Obtain gain and phase imbalances based on Equation-4 of [1]
gaindB = mag2db(abs(alphaEst*2-1)); 
phasedeg = 180*(angle(alphaEst*2-1))/pi;

iqImbal = [-gaindB phasedeg]; % Add -ve sign to convert asymmetric gain imbalance to symmetric.
end