function [rot,Nsc,Nfft] = s1gCarrierRotations(chanBW)
%s1gCarrierRotations S1G carrier rotation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [ROT,NCS,NFFT] = s1gCarrierRotations(CHANBW) returns the carrier
%   rotation per subcarrier, number of subchannelsm and FFT length per
%   subchannel given the channel bandwidth. CHANBW is the channel bandwidth
%   and must be 'CBW1', 'CBW2', 'CBW4', 'CBW8', or, 'CBW16'.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen
% S1G; different gamma for every 32/64 subcarrier group, IEEE
% P802.11ah/D5.0 Section 24.3.7
GammaPhase = wlan.internal.s1gGammaPhase(chanBW);
Nsc = numel(GammaPhase); % Number of 2MHz subchannels

if strcmp(chanBW,'CBW1')
    Nfft = 32; % FFT length for a sub channel
else
    Nfft = 64;
end

% Tone rotation: Section 24.3.7. (gamma)
rot = reshape(repmat(GammaPhase,[Nfft,1]),[],1);

end