function ind = ehtLDPCToneMappingIndices(ruSize,DCM)
%ehtLDPCToneMappingIndices EHT LDPC tone mapping indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   IND = ehtLDPCToneMappingIndices(RUSIZE,DCM) returns LDPC tone mapping
%   indices.
%
%   IND is a column containing the tone mapping indices.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 78,
%   106, 132, 242, 484, 726, 968, 996, 1992, and 3984.
%
%   DCM is a logical representing if dual carrier modulation is used.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% IEEE P802.11be/D3.0, Table 36-52
switch ruSize
    case 26
        mappingDistance = 1;
    case 52
        if DCM
            mappingDistance = 1;
        else
            mappingDistance = 3;
        end
    case 78 % 52+26
        if DCM
            mappingDistance = 3;
        else
            mappingDistance = 4;
        end
    case {106 132} % 132 = 106+32
        if DCM
            mappingDistance = 3;
        else
            mappingDistance = 6;
        end
    case 242
        mappingDistance = 9;
    case {484 968} % Treat as 484-tone RU for MCS-14 (RU size 968-tone RU)
        if DCM
            mappingDistance = 9;
        else
            mappingDistance = 12;
        end
    case 726 % 242+484
        if DCM
            mappingDistance = 9;
        else
            mappingDistance = 18;
        end
    otherwise % 996, 2x996, 4*996
        if DCM
            mappingDistance = 14;
        else
            mappingDistance = 20;
        end
end

tac = wlan.internal.heRUToneAllocationConstants(ruSize);

if ~DCM
    numSD = tac.NSD;
    % IEEE P802.11be/1.5, Equation 36-72
    k = (0:numSD-1).';
    ind = mappingDistance.*mod(k,((numSD)/mappingDistance)) + floor(k.*mappingDistance/(numSD))+1;
else % DCM
    % IEEE P802.11be/D1.5, Equation 36-73
    numSD = tac.NSD/2; % DCM has essentially half the number of data carrying subcarriers
    k = [(0:numSD-1).'; (0:numSD-1).'];
    ind = mappingDistance.*mod(k,((numSD)/mappingDistance)) + floor(k.*mappingDistance/(numSD))+1+[zeros(numSD,1); (numSD)*ones(numSD,1)];
end

end