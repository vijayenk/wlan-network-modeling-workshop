function [numCol,numRow,numRot] = heBCCInterleaveParameters(ruSize,numBPSCS,DCM)
%heBCCInterleaveParameters HE BCC interleaving parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [NUMCOL,NUMROW,NUMROT] = heBCCInterleaveParameters(RUSIZE,NBPSCS,DCM)
%   returns the interleaving parameters defined in IEEE Std 802.11ax-2021,
%   Table 27-35 and P802.11be/D2.0, Section 36.3.12.6, Table 36-50.
%
%   NUMCOL, NUMROW and NUMROT are the number of columns, rows and
%   rotations.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 78,
%   106, 132, or 242.
%
%   NUMBPSCS is the number of coded bits per single carrier per spatial
%   stream.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

switch ruSize
    case 26
        if ~DCM
            numCol = 8;
            numRow = 3*numBPSCS;
            numRot = 2; % (<=2Nss<=4)
        else
            numCol = 4;
            numRow = 3*numBPSCS;
            numRot = 2; % (Nss=2)
        end
    case 52
        if ~DCM
            numCol = 16;
            numRow = 3*numBPSCS;
            numRot = 11; % (<=2Nss<=4)
        else
            numCol = 8;
            numRow = 3*numBPSCS;
            numRot = 2; % (Nss=2)
        end
     case 56
        if ~DCM
            numCol = 13;
            numRow = 4*numBPSCS;
            numRot = NaN; % Not applicable
        else
            numCol = 13;
            numRow = 2*numBPSCS;
            numRot = NaN; % Not applicable
        end
     case 78
        if ~DCM
            numCol = 18;
            numRow = 4*numBPSCS;
            numRot = 18; % (Nss<=4)
        else
            numCol = 12;
            numRow = 3;
            numRot = NaN; % Not applicable (Nss==1)
        end
    case 106
        if ~DCM
            numCol = 17;
            numRow = 6*numBPSCS;
            numRot = 29; % (<=2Nss<=4)
        else
            numCol = 17;
            numRow = 3*numBPSCS;
            numRot = 11; % (Nss=2)
        end
    case 132
        if ~DCM
            numCol = 21;
            numRow = 6*numBPSCS;
            numRot = 31; % (Nss<=4)
        else
            numCol = 21;
            numRow = 3;
            numRot = NaN; % (Nss=1)
        end
    otherwise % 242
        assert(ruSize(1)==242); % Codegen
        if ~DCM
            numCol = 26;
            numRow = 9*numBPSCS;
            numRot = 58; % (<=2Nss<=4)
        else
            numCol = 13;
            numRow = 9*numBPSCS;
            numRot = 29; % (Nss=2)
        end
end

end