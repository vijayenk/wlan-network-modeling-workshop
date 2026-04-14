function chanEst = mimoChannelEstimate(x,seq,numSTS)
%mimoChannelEstimate MIMO channel estimation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   EST = mimoChannelEstimate(X,SEQ,NUMSTS) returns channel estimate for
%   each subcarrier given received symbols X, reference sequence SEQ, and
%   number of space-time streams NUMSTS.
%
%   X is the received symbols X and is sizes Nst-by-Nltf-by-Nrx where NST
%   is the number of subcarriers, Nltf is the number of LTF symbols and Nrx
%   is the number of receive antennas. Note all subcarriers in X must have
%   been modulated with the orthogonal mapping matrix P.
%
%   SEQ is the reference sequence and is sizes Nst-by-1.
%
%   NUMSTS is the number of space-time streams.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

% MIMO channel estimation as per Perahia, Eldad, and Robert Stacey.
% Next Generation Wireless LANs: 802.11 n and 802.11 ac. Cambridge
% university press, 2013, page 100, Eq 4.39.
[Nst,Nltf,Nrx] = size(x);
P = wlan.internal.mappingMatrix(Nltf);
Puse = P(1:numSTS,1:Nltf)'; % Extract and conjugate the P matrix 
denom = Nltf.*seq;
chanEst = coder.nullcopy(zeros(Nst,numSTS,Nrx,'like',x));
for k = 1:Nrx
    rxsym = squeeze(x(:,(1:Nltf),k)); % Symbols on 1 receive antenna
    for l = 1:numSTS
        chanEst(:,l,k) = rxsym*Puse(:,l)./denom;
    end
end

end