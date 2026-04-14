function p = ehtSegmentParserParameters(ruSize,NBPSCS,dcm)
%ehtSegementParserParameters EHT segment parse parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   P = ehtSegementParserParameters(RUSIZE,NBPSCS,DCM) returns a structure
%   of segment parse parameters for a given RUSize, NBPSCS, and DCM.
%
%   P contains the following fields:
%
%   RUSizePer80MHz     - RU Size within a 80 MHz frequency segment
%   m                  - Proportional ratio defined in Table 36-48 of IEEE
%                        P802.11be/D1.5
%   L                  - Number of frequency subblocks
%   NL                 - Indicates the location of 996 RU in an MRU
%   RU996Index         - Indicates the RU index of a 996 RU within an MRU
%   NonRU996Index      - Indicates the non 996 RU index within an MRU
%   Ncbpssl            - Number of coded bits per spatial streams per
%                        frequency segments
%
%   Copyright 2022 The MathWorks, Inc.

%#codegen

s = max(1,NBPSCS/2);
if dcm
    NBPSCS = NBPSCS/2;
end
p = struct('RUSizePer80MHz',0,'m',0,'L',0,'NL',0,'RU996Index',1,'NonRU996Index',1,'Ncbpssl',1);
coder.varsize('p.RUSizePer80MHz',[1 4],[0 1]);
coder.varsize('p.m',[1 4],[0 1]);
coder.varsize('p.NL',[1 4],[0 1]);
coder.varsize('p.RU996Index',[1 4],[0 1]);
coder.varsize('p.NonRU996Index',[1 4],[0 1]);
coder.varsize('p.Ncbpssl',[1 4],[0 1]);

if numel(ruSize)==2
    lut = [484 996; 996 484];
    if all(lut(1,:)==ruSize) % [484 996]
        p.RUSizePer80MHz = [484 996];
        p.m = [s 2*s];
        p.L = 2;
        p.NL = [0 1];
        p.RU996Index = 2;
        p.NonRU996Index = 1;
        p.Ncbpssl = ([468 980])*NBPSCS;
    else % [996 484]
        p.RUSizePer80MHz = [996 484];
        p.m = [2*s s];
        p.L = 2;
        p.NL = [1 0];
        p.RU996Index = 1;
        p.NonRU996Index = 2;
        p.Ncbpssl = ([980 468])*NBPSCS;
    end
elseif numel(ruSize)==3
    lut = [242 484 996; 484 242 996; 996 242 484; 996 484 242; 484 996 996; 996 484 996; 996 996 484; 996 996 996];
    if all(lut(1,:)==ruSize) || all(lut(2,:)==ruSize) % [242 484 996] or [484 242 996]
        p.RUSizePer80MHz = [726 996];
        p.m = [3*s 4*s];
        p.L = 2;
        p.NL = [0 1];
        p.RU996Index = 2;
        p.NonRU996Index = 1;
        p.Ncbpssl = ([702 980])*NBPSCS;
    elseif all(lut(3,:)==ruSize) || all(lut(4,:)==ruSize) % [996 242 484] or [996 484 242]
        p.RUSizePer80MHz = [996 726];
        p.m = [4*s 3*s];
        p.L = 2; 
        p.NL = [1 0];
        p.RU996Index = 1;
        p.NonRU996Index = 2;
        p.Ncbpssl = ([980 702])*NBPSCS;
    elseif all(lut(5,:)==ruSize) % [484 996 996]
        p.RUSizePer80MHz = [484 996 996];
        p.m = [s 2*s 2*s];
        p.L = 3;
        p.NL = [0 1 1];
        p.RU996Index = [2 3];
        p.NonRU996Index = 1;
        p.Ncbpssl = ([468 980 980])*NBPSCS;
    elseif all(lut(6,:)==ruSize) % [996 484 996]
        p.RUSizePer80MHz = [996 484 996];
        p.m = [2*s s 2*s];
        p.L = 3;
        p.NL = [1 0 1];
        p.RU996Index = [1 3];
        p.NonRU996Index = 2;
        p.Ncbpssl = ([980 468 980])*NBPSCS;
    elseif all(lut(7,:)==ruSize) % [996 996 484]
        p.RUSizePer80MHz = [996 996 484];
        p.m = [2*s 2*s s];
        p.L = 3;
        p.NL = [1 1 0];
        p.RU996Index = [1 2];
        p.NonRU996Index = 3;
        p.Ncbpssl = ([980 980 468])*NBPSCS;
    else % [996 996 996]
        p.RUSizePer80MHz = [996 996 996];
        p.m = [s s s];
        p.L = 3;
        p.NL = [0 0 0];
        p.RU996Index = [1 2 3];
        p.NonRU996Index = 0;
        p.Ncbpssl = ([980 980 980])*NBPSCS;
    end
elseif numel(ruSize)==4
    lut = [484 996 996 996; 996 484 996 996; 996 996 484 996; 996 996 996 484];
    if all(lut(1,:)==ruSize) % [484 996 996 996]
        p.RUSizePer80MHz = [484 996 996 996];
        p.m = [s 2*s 2*s 2*s];
        p.L = 4;
        p.NL = [0 1 1 1];
        p.RU996Index = [2 3 4];
        p.NonRU996Index = 1;
        p.Ncbpssl = ([468 980 980 980])*NBPSCS;
    elseif all(lut(2,:)==ruSize) % [996 484 996 996]
        p.RUSizePer80MHz = [996 484 996 996];
        p.m = [2*s s 2*s 2*s];
        p.L = 4;
        p.NL = [1 0 1 1];
        p.RU996Index = [1 3 4];
        p.NonRU996Index = 2;
        p.Ncbpssl = ([980 468 980 980])*NBPSCS;
    elseif all(lut(3,:)==ruSize) % [996 996 484 996]
        p.RUSizePer80MHz = [996 996 484 996];
        p.m = [2*s 2*s s 2*s];
        p.L = 4;
        p.NL = [1 1 0 1];
        p.RU996Index = [1 1 0 1];
        p.RU996Index = [1 2 4];
        p.NonRU996Index = 3;
        p.Ncbpssl = ([980 980 468 980])*NBPSCS;
    elseif all(lut(4,:)==ruSize) % [996 996 996 484]
        p.RUSizePer80MHz = [996 996 996 484];
        p.m = [2*s 2*s 2*s s];
        p.L = 4;
        p.NL = [1 1 1 0];
        p.RU996Index = [1 2 3];
        p.NonRU996Index = 4;
        p.Ncbpssl = ([980 980 980 468])*NBPSCS;
    end
else
    if ruSize==1992
        p.RUSizePer80MHz = [996 996];
        p.m = [s s];
        p.L = 2;
        p.NL = [0 0];
        p.RU996Index = [1 2];
        p.NonRU996Index = 0;
        p.Ncbpssl = ([980 980])*NBPSCS;
    else % 4x996
        p.RUSizePer80MHz = [996 996 996 996];
        p.m = [s s s s];
        p.L = 4;
        p.NL = [0 0 0 0];
        p.RU996Index = [1 2 3 4];
        p.NonRU996Index = 0;
        p.Ncbpssl = ([980 980 980 980])*NBPSCS;
    end
end