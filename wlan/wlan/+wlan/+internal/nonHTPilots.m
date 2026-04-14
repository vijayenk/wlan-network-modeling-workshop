function pilots = nonHTPilots(Nsym,z,varargin)
%nonHTPilots Non-HT pilot sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PILOTS = nonHTPilots(NSYM,Z) returns non-HT pilots. Null subcarriers
%   are not included therefore PILOTS is sized 4-by-Nsym, where Nsym is the
%   number of symbols within the field.
%
%   NSYM is a scalar specifying the number of symbols within the VHT field.
%
%   Z is a scalar specifying the number of symbols preceding the current
%   field, and is given in the standard as an addition in the pilot
%   polarity sequence subscript, e.g. the 1 in p_{n+1} in IEEE 802.11-2012
%   Eqn 18-22.
%
%   PILOTS = nonHTPilots(NSYM,Z,CHANBW) returns the non-HT pilots
%   replicated for 4/8/16/40/80/160 MHz bandwidths. PILOTS is sized
%   Np-by-Nsym, where Np is the number of occupied pilot subcarriers over
%   the whole channel bandwidth. CHANBW is a character vector specifying 
%   the channel bandwidth.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

if nargin > 2
    chanBW = varargin{1};
else
    chanBW = 'CBW20'; % Default
end

n = (0:Nsym-1).'; % Indices of symbols within the field
pilotSeq = nonHTPilotSequence(chanBW);
polaritySeq = wlan.internal.pilotPolaritySequence(n+z).';
pilots = polaritySeq .* pilotSeq;

end

function pilotSeq = nonHTPilotSequence(chanBW)

pilotsSeg = [1 1 1 -1].'; % IEEE Std 802.11-2016 Eqn 17-24.

if (strcmp(chanBW,'CBW2') || strcmp(chanBW,'CBW5') || strcmp(chanBW,'CBW10') || strcmp(chanBW,'CBW20')) 
    % One frequency segment for 2/5/10/20 MHz
    numSeg = 1;
else
    % More than one frequency segment
    cbwMHz = wlan.internal.cbwStr2Num(chanBW);
    if cbwMHz<20 % < 20 MHz, 2 MHz segment (S1G)
        numSeg = cbwMHz/2;
    else         % >= 20 MHz, 20 MHz segment (HT,VHT)
        numSeg = cbwMHz/20;
    end
end

% Replicate pilots over number of frequency segments
pilotSeq = repmat(pilotsSeg,numSeg,1);

end
