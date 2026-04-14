function pilots = ehtPilots(ruSize,numSTS,n,z)
%ehtPilots EHT pilot sequence
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PILOTS = ehtPilots(RUSIZE,NUMSTS,N,Z) returns the pilot sequence as per
%   IEEE P802.11be/D4.0, Section 36.3.13.11.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 968, 996, 1992, or 3984.
%
%   NUMSTS is the number of space-time streams.
%
%   N is the OFDM symbol index.
%
%   Z is the OFDM symbol offset index.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Pilot sequence
assert(isrow(n));
temp = [];
if any(sum(ruSize)==[78 132]) % MRU [52+26] and [106+26]
    Psi = [1 1 1 -1 -1 1]; % IEEE P802.11be/D4.0, Equation 36-86
    pilotSeq = [Psi(mod(n,6)+1); Psi(mod(n+1,6)+1); Psi(mod(n+2,6)+1); Psi(mod(n+3,6)+1); Psi(mod(n+4,6)+1); Psi(mod(n+5,6)+1)]; % IEEE P802.11be/D4.0, Equation 36-82, 36-84
else
    for i=1:numel(ruSize)
        switch ruSize(i)
            case 968 % 2x484-tone RU for EHT DUP Mode
                Psi = [1 1 1 -1 -1 1 1 1]; % IEEE Std 802.11ax-2021, Table 27-43
                pilotSeq = [ru484Seq(Psi,n); ru484Seq(Psi,n)];
            case 4*996
                assert(ruSize(i)==4*996)
                Psi = [1 1 1 -1 -1 1 1 1]; % IEEE Std 802.11ax-2021, Table 27-43
                pilotSeq = [ru484Seq(Psi,n); ru484Seq(Psi,n); ru484Seq(Psi,n); ru484Seq(Psi,n)]; % IEEE P802.11be/D4.0, Equation 36-81
            otherwise
                [~, pilotSeq] = wlan.internal.hePilots(ruSize(i),numSTS,n,z);
        end
        temp = [temp; pilotSeq]; %#ok<AGROW>
    end
    pilotSeq = temp;
end

polaritySeq = wlan.internal.pilotPolaritySequence(n+z).';
pilots = repmat(polaritySeq.*pilotSeq,1,1,numSTS); % Same pilots for each STS

end

function pilotSeq = ru484Seq(Psi,n)
    pilotSeq = [Psi(mod(n,8)+1); Psi(mod(n+1,8)+1); Psi(mod(n+2,8)+1); Psi(mod(n+3,8)+1); ...
        Psi(mod(n+4,8)+1); Psi(mod(n+5,8)+1); Psi(mod(n+6,8)+1); Psi(mod(n+7,8)+1); ...
        Psi(mod(n+8,8)+1); Psi(mod(n+9,8)+1); Psi(mod(n+10,8)+1); Psi(mod(n+11,8)+1); ...
        Psi(mod(n+12,8)+1); Psi(mod(n+13,8)+1); Psi(mod(n+14,8)+1); Psi(mod(n+15,8)+1)]; % IEEE P802.11be/D4.0, Equation 36-80
end