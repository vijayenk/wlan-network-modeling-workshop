function [pilots, pilotSeq] = hePilots(ruSize,numSTS,n,z)
%hePilots HE pilot sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   PILOTS = hePilots(RUSIZE,NUMSTS,N,Z) returns the pilot sequence as per
%   IEEE P802.11ax/D4.1, Section 27.3.11.13.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 1992.
%
%   NUMSTS is the number of space-time streams.
%
%   N is the OFDM symbol index.
%
%   Z is the OFDM symbol offset index.

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

% Pilot sequence - IEEE P802.11ax/D4.1, Section 27.3.11.13
assert(isrow(n));
switch ruSize
    case 26
        Psi = [1 -1]; % IEEE P802.11ax/D4.1, Table 27-36
        pilotSeq = [Psi(mod(n,2)+1); Psi(mod(n+1,2)+1)]; % IEEE P802.11ax/D4.1, Equation 27-101
    case {52 106}
        Psi = [1 1 1 -1]; % IEEE P802.11ax/D4.1, Table 27-38
        pilotSeq = [Psi(mod(n,4)+1); Psi(mod(n+1,4)+1); Psi(mod(n+2,4)+1); Psi(mod(n+3,4)+1)]; % IEEE P802.11ax/D4.1, Equation 27-102 and 27-103
    case 242
        Psi = [1 1 1 -1 -1 1 1 1]; % IEEE P802.11ax/D4.1, Table 27-41
        pilotSeq = [Psi(mod(n,8)+1); Psi(mod(n+1,8)+1); Psi(mod(n+2,8)+1); Psi(mod(n+3,8)+1); ...
            Psi(mod(n+4,8)+1); Psi(mod(n+5,8)+1); Psi(mod(n+6,8)+1); Psi(mod(n+7,8)+1)]; % IEEE P802.11ax/D4.1, Equation 27-104
    case {484 996}
        Psi = [1 1 1 -1 -1 1 1 1]; % IEEE P802.11ax/D4.1, Table 27-41
        pilotSeq = ru484Seq(Psi,n);
    otherwise % 2*996
        assert(ruSize==2*996)
        Psi = [1 1 1 -1 -1 1 1 1]; % IEEE P802.11ax/D4.1, Table 27-41
        pilotSeq = [ru484Seq(Psi,n); ru484Seq(Psi,n)]; % IEEE P802.11ax/D4.1, Equation 27-107
end

polaritySeq = wlan.internal.pilotPolaritySequence(n+z).';
pilots = repmat(polaritySeq.*pilotSeq,1,1,numSTS); % Same pilots for each STS

end

function pilotSeq = ru484Seq(Psi,n)
    pilotSeq = [Psi(mod(n,8)+1); Psi(mod(n+1,8)+1); Psi(mod(n+2,8)+1); Psi(mod(n+3,8)+1); ...
        Psi(mod(n+4,8)+1); Psi(mod(n+5,8)+1); Psi(mod(n+6,8)+1); Psi(mod(n+7,8)+1); ...
        Psi(mod(n+8,8)+1); Psi(mod(n+9,8)+1); Psi(mod(n+10,8)+1); Psi(mod(n+11,8)+1); ...
        Psi(mod(n+12,8)+1); Psi(mod(n+13,8)+1); Psi(mod(n+14,8)+1); Psi(mod(n+15,8)+1)]; % IEEE P802.11ax/D4.1, Equation 27-105 and 27-106
end
