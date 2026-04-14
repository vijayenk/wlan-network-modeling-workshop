function pilots = vhtPilots(n,z,chanBW,numSTS)
%vhtPilots VHT pilot sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PILOTS = vhtPilots(N,Z,CHANBW,NUMSTS) returns VHT pilots.
%
%   PILOTS is Nsp-by-Nsym-by-Nsts, where Nsp is the number of pilot
%   subcarriers, Nsym is the number of OFDM symbols, and Nsts is the number
%   of space time streams.
%
%   N is a column vector specifying the symbol number (0-based indexing).
%
%   Z is a scalar specifying the number of symbols preceding the current
%   field, and is given in the standard as an addition in the pilot
%   polarity sequence subscript, e.g. the 4 in p_{n+4} in IEEE
%   802.11ac-2013 Eqn 22-95.
%
%   CHANBW is the channel bandwidth character vector.
%
%   NUMSTS is the number of space-time streams.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

validateattributes(n,{'numeric'},{'column'},mfilename,'Symbol number');

pilotSeq = vhtPilotSequence(chanBW,numSTS,n); % IEEE Std 802.11ac-2013 Section 22.3.10.10
polaritySeq = wlan.internal.pilotPolaritySequence(n+z).'; % IEEE Std 802.11-2012 Eqn 18-25 
pilots = polaritySeq .* pilotSeq;
end

% VHT Pilot sequence defined in IEEE Std 802.11ac-2013 Section 22.3.10.10.
% Returns a matrix sized Nsp-by-NSym-by-Nsts, where Nsp is the number of
% pilot subcarriers, NSym is the number of OFDM symbols, and NSTS is the
% number of space time streams.
function pilotSeq = vhtPilotSequence(chanBW,numSTS,n)
% IEEE Std 802.11ac-2013 Table 22-21; note 0-based index in the standard
Psi80MHz = [1; 1; 1; -1; -1; 1; 1; 1];
switch chanBW
    case {'CBW1'} % Eqn 24-46, IEEE P802.11ah/D5.0
        % +1 for 0-based indexing
        singleSTSPilots = [Psi80MHz(mod(n,2)+2+1).'; Psi80MHz(mod((n+1),2)+2+1).']; 
    case {'CBW2','CBW4','CBW20','CBW40'}
        % Uses HT pilot sequence with a single space-time stream
        singleSTSPilots = wlan.internal.htPilotSequence(chanBW,1,n);
    case {'CBW8','CBW80','CBW80+80'}
        P = numel(Psi80MHz);
        idx = mod(n(:,1)+(0:P-1),P)+1; % +1 for 0-based indexing
        singleSTSPilots = Psi80MHz(idx.');
    otherwise % {'CBW16','CBW160'}
        Psi160MHz = [Psi80MHz; Psi80MHz];
        P = numel(Psi160MHz);
        idx = mod(n(:,1)+(0:P-1),P)+1; % +1 for 0-based indexing
        singleSTSPilots = Psi160MHz(idx.');
end
pilotSeq = repmat(singleSTSPilots,1,1,numSTS); % Same pilots per STS
end
