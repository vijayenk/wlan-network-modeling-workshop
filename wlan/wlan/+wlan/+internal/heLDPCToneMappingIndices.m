function ind = heLDPCToneMappingIndices(ruSize,DCM)
%heLDPCToneMappingIndices HE LDPC tone mapping indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   IND = heLDPCToneMappingIndices(RUSIZE,DCM) returns LDPC tone mapping
%   indices.
%
%   IND is a column containing the tone mapping indices.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 1992.
%
%   DCM is a logical representing if dual carrier modulation is used.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

% IEEE P802.11ax/D7.0, Table 27-36
L = 1; % Number of frequency segments
switch ruSize
    case 26
        mappingDistance = 1; % DCM true or false
    case 52
        if ~DCM
            mappingDistance = 3;
        else
            mappingDistance = 1;
        end
    case 106
        if ~DCM
            mappingDistance = 6;
        else
            mappingDistance = 3;
        end
    case 242
        mappingDistance = 9; % DCM true or false
    case 484
        if ~DCM
            mappingDistance = 12;
        else
            mappingDistance = 9;
        end
    case 996
        if ~DCM
            mappingDistance = 20;
        else
            mappingDistance = 14;
        end
    otherwise % 2*996
        assert(ruSize==1992);
        if ~DCM
            mappingDistance = 20;
        else
            mappingDistance = 14;
        end
        L = 2; % 2 frequency segments
end

tac = wlan.internal.heRUToneAllocationConstants(ruSize);
if ~DCM
    numSD = tac.NSD/L; % Mapping per frequency segment
    % IEEE P802.11ax/D7.0, Equation 27-95
    k = (0:numSD-1).';
    ind = mappingDistance.*mod(k,(numSD/mappingDistance)) + floor(k.*mappingDistance/numSD)+1;   
else % DCM
    % IEEE P802.11ax/D7.0, Equation 27-96
    numSD = tac.NSD/(L*2); % DCM has essentially half the number of data carrying subcarriers. Mapping per frequency segment.
    k = [(0:numSD-1).'; (0:numSD-1).'];
    ind = mappingDistance.*mod(k,(numSD/mappingDistance)) + floor(k.*mappingDistance/numSD)+1+[zeros(numSD,1); numSD*ones(numSD,1)];   
end

end