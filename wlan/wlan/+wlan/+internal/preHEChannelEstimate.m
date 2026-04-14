function est = preHEChannelEstimate(rxSym,chanEst,numSubchannels,varargin)
%preHEChannelEstimate Pre-HE channel estimate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST = preHEChannelEstimate(RXSYM,CHANEST,NUMSUBCHANNELS) returns the
%   full channel estimate in the L-SIG field.
%
%   EST is a complex Nst-by-1-by-Nr array containing the estimated channel
%   at data and pilot subcarriers, where Nst is the number of occupied
%   subcarriers and Nr is the number of receive antennas. EST includes the
%   channel estimates for the extra four subcarriers per 20 MHz subchannel
%   present in the L-SIG field.
%
%   RXSYM is the demodulated L-SIG field symbol of size Nst-by-Nsym-by-Nr.
%   Nsym represents the number of OFDM symbols in L-SIG and RL-SIG fields.
%
%   CHANEST is a complex Nst-by-1-by-Nr array containing the estimated
%   channel at data and pilot subcarriers using the L-LTF field.
%
%   NUMSUBCHANNELS is the number of 20 MHz subchannel for the given channel
%   bandwidth.
%
%   EST = preHEChannelEstimate(...,SPAN) performs frequency smoothing
%   by using a moving average filter across adjacent subcarriers to reduce
%   the noise on the channel estimate. The span of the filter in
%   subcarriers, SPAN, must be odd. If adjacent subcarriers are highly
%   correlated frequency smoothing will result in significant noise
%   reduction, however in a highly frequency-selective channel smoothing
%   may degrade the quality of the channel estimate.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

[numSCLSIG,numSymLSIG,numRx] = size(rxSym);
% Extract the first 2 OFDM symbols from rxSym
numSymLSIG = min(numSymLSIG,2);
est = coder.nullcopy(zeros(numSCLSIG,1,numRx,'like',rxSym));
% IEEE Std 802.11ax-2021, Sections 27.3.6.4 and 27.3.6.5
idxSCExtra = [1 2 55 56].'; % Indicates the extra four subcarriers' locations of -28, -27, 27 and 28
scExtra = [-1 -1 -1 1].';

for i = 1:numSubchannels
    idxExtraChanEst = groupSCIdx(idxSCExtra,56,i);
    idxLLTFChanEst = groupSCIdx((1:52),52,i);
    idxLSIGChanEst = groupSCIdx((1:56),56,i);
    % Average over the number of L-SIG and RL-SIG OFDM symbols and insert four extra subcarriers in channel estimation
    chanEstExtra = mean(rxSym(idxExtraChanEst,1:numSymLSIG,:),2).*scExtra;
    est(idxExtraChanEst,:,:) = chanEstExtra;
    est(idxLSIGChanEst(3:end-2),:,:) = chanEst(idxLLTFChanEst,:,:);
    % Perform frequency smoothing if requested
    if nargin > 3
        span = varargin{1};
        est(idxLSIGChanEst,:,:) = wlan.internal.frequencySmoothing(est(idxLSIGChanEst,:,:),span);
    end
end

end

function groupIdx = groupSCIdx(idxSC,spacing,idxSubchannel)
%groupSCIdx Group subcarrier indices for different subchannels

    groupIdx = idxSC+(idxSubchannel-1)*spacing;
end