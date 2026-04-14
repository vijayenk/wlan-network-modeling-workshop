function demodSymAllUsersOut = compensateIQImbalanceData(eqSymAllUsers,chanEstAllUsers,cfgUsers,iqImbalance)
%compensateIQImbalanceData Compensate IQ gain and phase imbalances in
%equalized data symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEMODSYMALLUSERSOUT = compensateIQImbalanceData(EQSYMALLUSERS,CHANESTALLUSERS,CFGUSERS,IQIMBALANCE)
%
%   DEMODSYMALLUSERSOUT is a cell array of the IQ imbalance compensated
%   demodulated data symbols of all users
%
%   EQSYMALLUSERS is a cell array of the IQ imbalance impaired equalized
%   symbols of all users
%
%   CHANESTALLUSERS is a cell array of the IQ imbalance compensated channel
%   estimates of RUs of all users
%
%   CFGUSERS are the configuration objects of all users
%
%   IQIMBALANCE is a 1x2 array of IQ gain imbalance (dB) and phase
%   imbalance (degrees)

%   Reference:
%   [1] M. Janaswamy, N. K. Chavali and S. Batabyal, "Measurement of
%   transmitter IQ parameters in HT and VHT wireless LAN systems," 2016
%   International Conference on Signal Processing and Communications
%   (SPCOM), Bangalore.

%   Copyright 2025 The MathWorks, Inc.

% Note: The IQ imbalance compensation algorithm works for Direct
% spatial mapping

% Compute alphaEst from IQ gain and phase imbalance estimates
numUsers = numel(cfgUsers);
[alphaEst, betaEst] = wlan.internal.getIQImbalanceParameters(iqImbalance);

% Compute maximum space time streams of all RUs (users)
maxSTS = 0;
for iu = 1:numUsers
     maxSTS = max(maxSTS,cfgUsers(iu).RUTotalSpaceTimeStreams);
end
nRx = size(chanEstAllUsers{1},3);

% Convert individual user cells to concatenated matrix of all users
user = cfgUsers(1);
cbwNum = wlan.internal.cbwStr2Num(user.ChannelBandwidth);
fftLength = 256*cbwNum/20;
numSym = size(eqSymAllUsers{1},2);
eqSymAllUsersMat = zeros(fftLength,numSym,maxSTS);
chanEstAllUsersMat = zeros(fftLength,maxSTS,nRx);
activeFFTIndCell = cell(numUsers,1);
for iu = 1:numUsers
    user = cfgUsers(iu);
    [~,activeFreqInd] = wlan.internal.ehtOccupiedSubcarrierIndices(cbwNum,user.RUSize,user.RUIndex);
    activeFFTInd = activeFreqInd+(fftLength/2)+1;
    activeFFTIndCell{iu} = activeFFTInd;
    stsIdx = user.SpaceTimeStreamStartingIndex+(0:user.NumSpaceTimeStreams-1);
    eqSymAllUsersMat(activeFFTInd,:,stsIdx) = eqSymAllUsers{iu};
    nSTS = size(chanEstAllUsers{iu},2);
    chanEstAllUsersMat(activeFFTInd,1:nSTS,1:nRx) = chanEstAllUsers{iu};
end

% Correct IQ imbalance in equalized symbols
% For FFT length of nFFT, frequency indices run from -(nFFT/2):(nFFT/2 -1).
% Consider only mirror indices, -(nFFT/2 -1):(nFFT/2 -1), and ignore the
% 1st index
eqSymAllUsersMat(2:end,:,:) = correctIQImbal(eqSymAllUsersMat(2:end,:,:),alphaEst,betaEst);

% Form demodulated symbols by re-applying channel estimates to the
% IQ imbalance corrected equalized symbols
demodSymVecMat = applyChannel(eqSymAllUsersMat,chanEstAllUsersMat);

% Convert matrix of IQ imbalance demodulated symbols to individual user cells
demodSymAllUsersOut = cell(numUsers,1);
for iu = 1:numUsers
    demodSymAllUsersOut{iu} = demodSymVecMat(activeFFTIndCell{iu},:,:);
end
end


function out =  correctIQImbal(in, alphaEst, betaEst)
% Correct IQ gain and phase imbalance in data symbols

YL = in;
YminusL = YL(end:-1:1,:,:);

% To handle unassigned or punctured subchannels
idx = find(YL(:,1,1)==0);
YL(idx,:,:) = betaEst*conj(YminusL(idx,:,:)/alphaEst);
YminusL = YL(end:-1:1,:,:);

% Compensate IQ imbalance
out = ((YL*conj(alphaEst))-(conj(YminusL)*betaEst))./((abs(alphaEst)^2)-(abs(betaEst)^2));  % As specified in Equation-30 of [1]
end


function demodSymVec = applyChannel(eqSym,chanEst)
% Apply channel to equalized symbols to form demodulated symbols

% Obtain MIMO channel estimate per subcarrier 
% Dimensions after permutation [maxSTS,nRx,nSc]
chanEstP = permute(chanEst,[2 3 1]);

% Permute eqSym for easy channel multiplication 
% Dimensions after permutation [nOFDMSym,maxSTS,nSc]
eqSymP = permute(eqSym,[2 3 1]);

% Matrix multiply all STS of eqSym with channel estimate
demodSymVecP = pagemtimes(eqSymP,chanEstP);

% Permute back to proper dimensions
demodSymVec = permute(demodSymVecP,[3 1 2]);
end