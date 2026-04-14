function [symMerge,chanMerge] = ehtMergeUSIGSubchannels(x,chanEst,chanBW)
%ehtMergeUSIGSubchannels Merge demodulated U-SIG symbols and channel estimates
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [SYMMERGE,CHANMERGE] = ehtMergeUSIGSubchannels(X,CHANEST,CHANBW) merge
%   demodulated symbols and channel estimates for each subchannel within an
%   80 MHz segment. SYMMERGE is of size 52*L-by-Nsym-by-Nr*L, where L is
%   the number of 80 MHz segments in the given channel bandwidth and Nsym
%   is the number of symbols (time domain). CHANMERGE is of size
%   52*L-by-1-by-Nr*L.
%
%   - L is 1 for 20 MHz, 40 MHz, and 80 MHz
%   - L is 2 for 160 MHz
%   - L is 4 for 320 MHz
%
%   X is a real or complex array containing the frequency domain symbols.
%   It is of size Nst-by-Nsym-by-Nr, where Nr represents the number of
%   receive antennas.
%
%   CHANEST is a real or complex array containing the channel estimates for
%   each carrier. It is of size Nst-by-1-by-Nr.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

[Ns,Nsym,Nr] = size(x);
[~,numSubchannels] = wlan.internal.cbw2nfft(chanBW);
L = ceil(numSubchannels/4); % Number of 80 MHz segments

% Merge demodulated symbols and channel estimates for each subchannel
% within an 80 MHz segment
Nscs = Ns/L; % Number of subcarrier per 80 MHz segment
Nsc = Ns/numSubchannels; % Number of subcarriers per 20 MHz subchannel
Nrx = Nr*min(numSubchannels,4);
symMerge = coder.nullcopy(zeros(Nsc*L,Nsym,Nrx,'like',x));
chanMerge = coder.nullcopy(zeros(Nsc*L,1,Nrx,'like',x));
for l=1:L
    [symMerge(Nsc*(l-1)+(1:Nsc),:,:),chanMerge(Nsc*(l-1)+(1:Nsc),:,:)] =  ...
        wlan.internal.mergeSubchannels(x(Nscs*(l-1)+(1:Nscs),:,:),chanEst(Nscs*(l-1)+(1:Nscs),:,:),min(numSubchannels,4));
end

end