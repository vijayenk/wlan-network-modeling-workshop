function pilots = htPilots(Nsym,z,chanBW,Nsts)
%htPilots HT pilot sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PILOTS = htPilots(NSYM,Z,CHANBW,NSTS) returns HT pilots.
%
%   PILOTS is Nsp-by-NSym-by-NSTS, where Nsp is the number of pilot
%   subcarriers, NSym is the number of OFDM symbols, and NSTS is the number
%   of space time streams.
%
%   NSYM is a scalar specifying the number of symbols within the HT field.
%
%   Z is a scalar specifying the number of symbols preceding the current
%   field, and is given in the standard as an addition in the pilot
%   polarity sequence subscript, e.g. the 1 in p_{n+1} in IEEE Std
%   802.11-2016, Equation 19-17.
%
%   CHANBW is the channel bandwidth character vector.
%
%   NSTS is the number of space-time streams.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

n = (0:Nsym-1).'; % Indices of symbols within the field
pilotSeq = wlan.internal.htPilotSequence(chanBW,Nsts,n);  % IEEE Std 802.11-2016, Section 19.3.11.10
polaritySeq = wlan.internal.pilotPolaritySequence(n+z).'; % IEEE Std 802.11-2016, Equation 17-25 
pilots = polaritySeq .* pilotSeq;
end
