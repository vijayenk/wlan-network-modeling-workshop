function chanEst = dataAidedChannelEstimate(chanEstData,demodLTFData,mappedSym,stsIdx)
%dataAidedChannelEstimate data-aided MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Copyright 2025 The MathWorks, Inc.

% Initial the channel estimation to be x-LTF ones
chanEst = chanEstData; % Nst-by-Nsts-by-Nrx

% LS channel estimation using EHT-LTF and EHT-Data field
% Equation 4 in "Training-based MIMO channel estimation: A study of
% estimator tradeoffs and optimal training signals." Biguesh M, and Alex B.
% G. IEEE transactions on signal processing 54.3 (2006): 884-893.
PI = pagepinv(permute(mappedSym,[3 2 1])); % Nsts-by-Nsym-by-Nsc
symTemp = permute(demodLTFData,[3 2 1]); % Nrx-by-Nsym-by-Nsc
% Only update the channel estimation with STS indices belonging to the user
chanEst(:,stsIdx,:) = permute(pagemtimes(symTemp,PI),[3 2 1]); % Nrx-by-Nsts-by-Nsc = Nrx-by-Nsym-by-Nsc * Nsym-by-Nsts-by-Nsc
end