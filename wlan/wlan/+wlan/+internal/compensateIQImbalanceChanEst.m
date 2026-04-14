function [chanEst,pilotEst,demodEHTLTF] = compensateIQImbalanceChanEst(chanEstIQ,pilotEstIQ,cfgUsers,userIdx,iqImbalance)
%compensateIQImbalanceChanEst Compensate IQ gain and phase imbalances in
%channel estimates
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [CHANEST,PILOTEST,DEMODEHTLTF] = compensateIQImbalanceChanEst(CHANESTIQ,PILOTESTIQ,CFGUSERS,USERIDX,IQIMBALANCE)
%
%   CHANEST are the IQ imbalance compensated channel estimates
%
%   PILOTEST are IQ imbalance compensated single-stream pilot estimates
%
%   DEMODEHTLTF are IQ imbalance compensated demodulated EHT-LTF symbols
%
%   CHANESTIQ are IQ imbalance impaired channel estimates
%
%   PILOTESTIQ are IQ imbalance impaired single-stream pilot estimates
%
%   CFGUSERS are the configuration objects of all users
%
%   USERIDX is the index of current user
%
%   IQIMBALANCE is a 1x2 array of IQ gain imbalance (dB) and phase
%   imbalance (degrees)

%   Reference:
%   [1] M. Janaswamy, N. K. Chavali and S. Batabyal, "Measurement of
%   transmitter IQ parameters in HT and VHT wireless LAN systems," 2016
%   International Conference on Signal Processing and Communications
%   (SPCOM), Bangalore.

%   Copyright 2025 The MathWorks, Inc.

[alphaEst, betaEst] = wlan.internal.getIQImbalanceParameters(iqImbalance);

currUser = cfgUsers(userIdx);
cbwNum = wlan.internal.cbwStr2Num(currUser.ChannelBandwidth);
fftLength = 256*cbwNum/20;

% Get subcarrier indices whose mirror subcarrier is a null, a pilot, and
% data respectively
[mirrNullInd,mirrPilotInd,mirrDataInd] = getMirrorSubcarrierIdx(cfgUsers);

[ruMappingInd,activeFreqInd] = wlan.internal.ehtOccupiedSubcarrierIndices(cbwNum,currUser.RUSize,currUser.RUIndex);
dataIndices = ruMappingInd.Data;
pilotIndices = ruMappingInd.Pilot;
activeFFTInd = activeFreqInd+(fftLength/2)+1;

% Check if any pilot has a mirror data subcarrier
pilotOverlapDataIdx = intersect(activeFFTInd(pilotIndices),mirrDataInd);
pilotOverlapData = ~isempty(pilotOverlapDataIdx);

% Get subcarrier indices and reference sequence
[ltf,k] = wlan.internal.ehtLTFSequence(currUser.ChannelBandwidth,currUser.EHTLTFType);
idxFull = wlan.internal.ehtRUSubcarrierIndices(cbwNum);
ltfType = cfgUsers(userIdx).EHTLTFType;
ltfFullLen = zeros(fftLength,1);
[idxIntersect,~,c] = intersect(idxFull,k);
idxIntersect = idxIntersect+fftLength/2+1;
ltfFullLen(idxIntersect) = ltf(c);
nSTS = size(chanEstIQ,2);

% Compute ratio of conjugate mirror reference symbol and current reference
% symbol as given in Equation-7 of [1]
gammaRatio = conj(ltfFullLen(end:-1:2))./ltfFullLen(2:end);
gammaRatio(mirrNullInd-1) = 0;

% Compensate IQ imbalance in channel estimates
[chanEst, Puse, Ruse] = compensateIQImbalanceCore(chanEstIQ,alphaEst,betaEst,gammaRatio(activeFFTInd-1),currUser.NumEHTLTFSymbols,nSTS);

switch ltfType
    case 1
        LTF_Mode = 4;
    case 2
        LTF_Mode = 2;
    otherwise % 4
        LTF_Mode = 1;
end
if nSTS==1 && LTF_Mode>1
    % Interpolate over compressed subcarriers
    chanEst = wlan.internal.heInterpolateChannelEstimate(chanEst,fftLength,LTF_Mode,activeFFTInd);
end

% Perform interpolation of channel estimates after IQ imbalance
% compensation
if nSTS>1
    % Undo cyclic shift for each STS before averaging and interpolation
    csh = wlan.internal.getCyclicShiftVal('VHT',nSTS,cbwNum);
    chanEst(dataIndices,:,:) = wlan.internal.cyclicShiftChannelEstimate(chanEst(dataIndices,:,:),-csh, fftLength,activeFreqInd(dataIndices));
    
    % Consider data subcarrier locations where there is no mirror pilot
    % subcarrier
    [~,onlyDataIdx] = setdiff(activeFFTInd(dataIndices),mirrPilotInd);

    % Interpolate over pilot locations and compressed subcarriers
    chanEst = wlan.internal.heInterpolateChannelEstimate(chanEst(dataIndices(onlyDataIdx),:,:),fftLength,LTF_Mode,activeFFTInd,dataIndices(onlyDataIdx));
    
    % Re-apply cyclic shift after interpolation
    chanEst = wlan.internal.cyclicShiftChannelEstimate(chanEst,csh,fftLength,activeFreqInd);
end


% Correct single stream pilot channel estimates for IQ imbalance
if nSTS==1 || ~pilotOverlapData
    pilotEst = pilotEstIQ./(alphaEst+betaEst.*gammaRatio(activeFFTInd(pilotIndices)-1));
else
    % Because pilot subcarriers overlap with data subcarriers, there is
    % interference of P matrix of data with R matrix of pilot. Hence,
    % instead use the estimated MIMO channel estimates at pilot locations
    % to compute single stream pilot channel estimates.
    Nltf = currUser.NumEHTLTFSymbols; % Including any extra EHT-LTF symbols
    pilotEstSym = sum(chanEst(pilotIndices,:,:),2);
    pilotEst = repmat(pilotEstSym,1,Nltf,1);
end

% Form demodulated EHT-LTF symbols from IQ imbalance corrected channel
% estimates to use them for data-aided equalization.
PMatLTF = permute(Puse.',[3 1 2]).*ltfFullLen(activeFFTInd(dataIndices)); % Multiply LTF sequence and P matrix [nDataInd,nLTF,nSTS]
PMatLTFP = permute(PMatLTF,[2 3 1]); % [nLTF,nSTS,nDataInd];
chanEstP = permute(chanEst(dataIndices,:,:),[2 3 1]); % [nSTS,nRx,nDataInd]
dataDemodP = pagemtimes(PMatLTFP,chanEstP); % [nLTF,nSTS,nDataInd] x [nSTS,nRx,nDataInd] = [nLTF,nRx,nDataInd]
demodEHTLTF(dataIndices,:,:) = permute(dataDemodP,[3 1 2]); % [nDataInd,nLTF,nRx]
if ltfType==1
    Ruse = Puse; % Even pilots use P matrix
end
RMatLTF = permute(Ruse.',[3 1 2]).*ltfFullLen(activeFFTInd(pilotIndices)); % Multiply LTF sequence and R matrix [nPilotInd,nLTF,nSTS]
RMatLTFP = permute(RMatLTF,[2 3 1]); % [nLTF,nSTS,nPilotInd];
chanEstP = permute(chanEst(pilotIndices,:,:),[2 3 1]); % [nSTS,nRx,nPilotInd]
pilotDemodP = pagemtimes(RMatLTFP,chanEstP); % [nLTF,nSTS,nPilotInd] x [nSTS,nRx,nPilotInd] = [nLTF,nRx,nPilotInd]
demodEHTLTF(pilotIndices,:,:) = permute(pilotDemodP,[3 1 2]); % [nPilotInd,nLTF,nRx]
end


%--------------------------------------------------------------------------
function [chanEst,Puse,Ruse] = compensateIQImbalanceCore(chanEstIQ,alphaEst,betaEst,gammaRatio,numLTFSym,numSTS)
% Compensate IQ imbalance in channel estimates

P = wlan.internal.mappingMatrix(numLTFSym);
Puse = P(1:numSTS,1:numLTFSym); % Extract the P matrix
Ruse = repmat(P(1,1:numLTFSym),numSTS,1);

if isreal(Puse)
    % Puse matrix is a real matrix. As conjugate of a real matrix is the
    % same matrix, it doesn't affect IQ imbalance compensation.
    chanEst = (chanEstIQ)./(alphaEst+betaEst.*gammaRatio); % Based on Equation-29 of [1]
else
    % Puse matrix is a complex matrix. Conjugate of Puse matrix should be
    % considered for IQ imbalance compensation. 

    % Puse is a kind of unitary matrix, so find its inverse using transpose
    % conjugate.
    invPuse = (Puse')/numLTFSym; 

    % Inverse of Puse matrix is multiplied during mimo channel estimation.
    % A residual factor of conj(Puse)*inv(Puse) is left out after mimo
    % channel estimation because of IQ imbalance.
    repeatedPMatComp = repmat(permute(conj(Puse)*invPuse,[3 1 2]),size(chanEstIQ,1),1,1); % [nSc, nSTS, nSTS]
    eyeMat = repmat(permute(eye(numSTS),[3 1 2]),size(chanEstIQ,1),1,1); % [nSc, nSTS, nSTS]

    % Based on Equation-29 of [1]
    repeatedPMatCompIQ = alphaEst.*eyeMat+betaEst.*gammaRatio.*(repeatedPMatComp); % [nSc, nSTS, nSTS]
    repeatedPMatCompIQP = permute(repeatedPMatCompIQ,[2 3 1]); % [nSTS, nSTS, nSc]
    chanEstIQP = permute(chanEstIQ,[2 3 1]); % [nSTS, nRx, nSc]

	% Apply inverse of the computed matrix to remove residual component and
	% IQ imbalance component
    chanEstP = pagemtimes(pageinv(repeatedPMatCompIQP),chanEstIQP); % [nSTS, nRx, nSc]
    chanEst = permute(chanEstP,[3 1 2]); % [nSc, nSTS, nRx]
end
end


%--------------------------------------------------------------------------
function [mirrNullInd,mirrPilotInd,mirrDataInd] = getMirrorSubcarrierIdx(cfgUsers)
% Find subcarrier indices whose mirror index has a null, a pilot, and data
% respectively.

user = cfgUsers(1);
numUsers = numel(cfgUsers);

cbwNum = wlan.internal.cbwStr2Num(user.ChannelBandwidth);
fftLength = 256*cbwNum/20;
pilotIdxAllUsers = zeros(fftLength,1);
dataIdxAllUsers = zeros(fftLength,1);
activeFFTIndAllUsers = zeros(fftLength,1);

for iu=1:numUsers
    user = cfgUsers(iu);
    [ruMappingInd,activeFreqInd] = wlan.internal.ehtOccupiedSubcarrierIndices(cbwNum,user.RUSize,user.RUIndex);
    dataIndices = ruMappingInd.Data;
    pilotIndices = ruMappingInd.Pilot;
    activeFFTInd = activeFreqInd+(fftLength/2)+1;

	% Pilot subcarrier locations
    pilotIdxAllUsers(activeFFTInd(pilotIndices)) = 1;
	
	% Data subcarrier locations
    dataIdxAllUsers(activeFFTInd(dataIndices)) = 1;
	
	% Active subcarrier locations
    activeFFTIndAllUsers(activeFFTInd) = 1;
end

% Find indices where there are mirror pilot subcarriers. Indices from 2
% to end are used because the 1st index has no mirror subcarrier.
mirrPilotInd = (find(pilotIdxAllUsers(end:-1:2)))+1;

% Find indices where there are mirror data subcarriers
mirrDataInd = (find(dataIdxAllUsers(end:-1:2)))+1;

% Find indices where the mirror subcarrier is not active
mirrNullInd = (find(activeFFTIndAllUsers(end:-1:2)==0))+1;
end