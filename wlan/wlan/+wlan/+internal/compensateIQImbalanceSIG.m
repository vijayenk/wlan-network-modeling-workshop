function out = compensateIQImbalanceSIG(in,iqImbal,ofdmInfo,fieldName,varargin)
%compensateIQImbalanceSIG Compensate IQ gain and phase imbalances in
%signal fields
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OUT = COMPENSATEIQIMBALANCESIG(IN,IQIMBAL,OFDMINFO,FIELDNAME)
%
%   OUT are IQ imbalance compensated channel estimates when FIELDNAME is
%   L-LTF, else they are IQ imbalance compensated SIG field equalized
%   symbols
%   
%   IN are IQ imbalance impaired channel estimates when FIELDNAME is L-LTF,
%   else they are IQ imbalance impaired SIG field equalized symbols
%
%   IQIMBAL is a 1x2 vector of IQ gain imbalance (dB) and IQ phase
%   imbalance (deg)
%
%   OFDMINFO is the ofdm info configuration object
%
%   FIELDNAME is the current field name
%
%   OUT = COMPENSATEIQIMBALANCESIG(..., ACTIVESUBCHAN)
%   considers active subchannels in IQ imbalance compensation
% 
%   ACTIVESUBCHAN is a column vector of active 20 MHz subchannels in the
%   given bandwidth

%   Reference:
%   [1] M. Janaswamy, N. K. Chavali and S. Batabyal, "Measurement of
%   transmitter IQ parameters in HT and VHT wireless LAN systems," 2016
%   International Conference on Signal Processing and Communications
%   (SPCOM), Bangalore.

%   Copyright 2025 The MathWorks, Inc.

narginchk(4,5); 

if nargin>4
    % Active (non-punctured) 20 MHz subchannels for HE, EHT
    activeSubchan = varargin{1};
else
    % All 20 MHz subchannels are active for VHT, HT, and Non-HT
    activeSubchan = ones(ofdmInfo.NumSubchannels,1);
end

nSym = size(in,1);

[alphaEst, betaEst] = wlan.internal.getIQImbalanceParameters(iqImbal);
if nSym==ofdmInfo.NumTones
    if isfield(ofdmInfo,'ActiveFFTIndices')
        ind = ofdmInfo.ActiveFFTIndices;
    else
        ind = sort([ofdmInfo.DataIndices; ofdmInfo.PilotIndices]);
    end
else
    if isfield(ofdmInfo,'ActiveFFTIndices')
        ind = ofdmInfo.ActiveFFTIndices(ofdmInfo.DataIndices);
    else
        ind = ofdmInfo.DataIndices;
    end
end

toneRot = wlan.internal.vhtCarrierRotations(ofdmInfo.NumSubchannels);

if strcmpi(fieldName,'L-LTF')
    activeSubchanMask = repelem(activeSubchan,64,1); % Active subcarriers of FFT length
    toneRotActSubCh = toneRot.*activeSubchanMask; % Tone rotations including active subchannels
    % Correct IQ imbalance in channel estimates
    out = compensateIQImbalanceChannel(in,alphaEst,betaEst,toneRotActSubCh(ind),ofdmInfo.NumSubchannels,ind);
else
    % Correct IQ imbalance in equalized symbols
    in = in*exp(1i*angle(alphaEst)); % Account for deviation caused by CPE correction
    out = compensateIQImbalSIGField(in,alphaEst,betaEst,toneRot(ind));
end

end


function lltfChanEst = compensateIQImbalanceChannel(lltfChanEst,alphaEst,betaEst,toneRotActSubCh,numSubchannels,ind)
% Correct IQ imbalance in channel estimates

% Generate reference LLTF symbols
[lltfLower,lltfUpper] = wlan.internal.lltfSequence();
if rem(size(lltfChanEst,1),56)==0
    lltfSeqFull = [zeros(4,1); -1; -1; lltfLower; 0; lltfUpper; -1; 1; zeros(3,1)];
else
    lltfSeqFull = [zeros(6,1); lltfLower; 0; lltfUpper; zeros(5,1)];
end
lltfSeqFull = repmat(lltfSeqFull,numSubchannels,1);
lltfSeqActive = lltfSeqFull(ind);

% Compute ratio of conjugate mirror reference symbol and current reference
% symbol as given in eq (7) of [1]
refSymRatio = conj(lltfSeqActive(end:-1:1))./lltfSeqActive;

toneRotInv = toneRotActSubCh(end:-1:1);
lltfChanEst = (lltfChanEst.*toneRotActSubCh)./(alphaEst.*toneRotActSubCh+betaEst.*refSymRatio.*(conj(toneRotInv)));
end


function eqSymOut =  compensateIQImbalSIGField(eqSymIn,alphaEst,betaEst,toneRot)
% Correct IQ imbalance in equalized symbols of SIG fields

t1 = toneRot;
t2 = t1(end:-1:1);

YL = eqSymIn;
YminusL = YL(end:-1:1,:,:);

% To handle punctured subchannel
idx = find(YL(:,1,1)==0);
YL(idx,:,:) = betaEst*conj(YminusL(idx,:,:)/alphaEst).*(conj(t2(idx))./t1(idx));
YminusL = YL(end:-1:1,:,:);

% Compensate IQ imbalance
eqSymOut = ((YL*conj(alphaEst))-(conj(YminusL)*betaEst).*(conj(t2)./t1))./((abs(alphaEst)^2)-(abs(betaEst)^2));  % Based on Equation-30 of [1]
end