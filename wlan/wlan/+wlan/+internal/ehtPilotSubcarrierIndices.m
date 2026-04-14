function ind = ehtPilotSubcarrierIndices(chanBW,varargin)
%ehtPilotSubcarrierIndices EHT pilot subcarrier indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   IND = ehtPilotSubcarrierIndices(CHANBW,RUSIZE) returns a column vector
%   containing the pilot indices over all RUs.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, 160, or 320.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, 2*996, or 4*996.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% IEEE P802.11be/D1.5, Section 36.3.13.11
if nargin>1
    ruSize = varargin{1}(1); % For codegen
else
    ruSize = wlan.internal.heFullBandRUSize(chanBW);
end

switch chanBW
    case 20
        switch ruSize
            case {26,52}
                posInd = [10; 22; 36; 48; 62; 76; 90; 102; 116];
            otherwise % {106, 242}
                assert(any(ruSize==[106,242]));
                posInd = [22; 48; 90; 116];
        end
        ind = [-flipud(posInd); posInd];
    case 40
        switch ruSize
            case {26,52}
                posInd = [10; 24; 36; 50; 64; 78; 90; 104; 116; 130; 144; 158; 170; 184; 198; 212; 224; 238];
            otherwise % {106, 242, 484}
                assert(any(ruSize==[106,242,484]));
                posInd = [10; 36; 78; 104; 144; 170; 212; 238];
        end
        ind = [-flipud(posInd); posInd];
    case 80
        % IEEE P802.11be/D1.5, Table 36-58
        posInd = cbw80Indices(ruSize);
        ind = [-flipud(posInd); posInd];
    case 160
        % IEEE P802.11be/D1.5, Table 36-59
        assert(chanBW==160);
        switch ruSize
            case {26,52,106,242,484,996}
                posInd = [cbw80Indices(ruSize)-512; cbw80Indices(ruSize)+512];
            otherwise % {2*996}
                assert(ruSize==2*996);
                posInd = cbw160Indices(ruSize);
        end
        ind = [-flipud(posInd); posInd];
    otherwise
        assert(chanBW==320);
        % IEEE P802.11be/D1.5, Table 36-60
        switch ruSize
            case {26,52,996}
                ind = [-flipud(cbw80Indices(ruSize))-1536; cbw80Indices(ruSize)-1536; -flipud(cbw80Indices(ruSize))-512; cbw80Indices(ruSize)-512; ...
                    -flipud(cbw80Indices(ruSize))+512; cbw80Indices(ruSize)+512; -flipud(cbw80Indices(ruSize))+1536; cbw80Indices(ruSize)+1536];
            case {106,242,484,2*996}
                ind = [-flipud(cbw160Indices(ruSize))-1024; cbw160Indices(ruSize)-1024; -flipud(cbw160Indices(ruSize))+1024; cbw160Indices(ruSize)+1024];
            otherwise % 4*996
                assert(ruSize==4*996);
                posInd = cbw320Indices;
                ind = [-flipud(posInd); posInd];
        end
end

end

function posInd = cbw80Indices(ruSize)
    switch ruSize
        case {26,52} % IEEE P802.11be/D1.5, Table 36-53, Table 36-54
            posInd = [18; 32; 44; 58; 72; 86; ...
                98; 112; 126; 140; 152; 166; 178; 192; 206; 220; ...
                232; 246; 266; 280; 292;306; 320; 334; 346; 360; ...
                372; 386; 400; 414; 426; 440; 454; 468; 480; 494];
        case {106,242,484,968} % IEEE P802.11be/D1.5, Table 36-55, 36-56, 36-57
            posInd = [18; 44; 86; 112; 152; 178; 220; 246; 266; 292; ...
                334; 360; 400; 426; 468; 494];
        otherwise % IEEE P802.11be/D1.5, Table 36-58 
            assert(ruSize==996)
            posInd = [18; 86; 152; 220; 266; 334; 400; 468];
    end
end

function posInd = cbw160Indices(ruSize)
   switch ruSize
       case {26,52,106,242,484,996}
           posInd = [-flipud(cbw80Indices(ruSize))+512; cbw80Indices(ruSize)+512];
       otherwise
           assert(ruSize==2*996)
           % IEEE P802.11be/D1.5, Table 36-59
           posInd = [44; 112; 178; 246; 292; 360; 426; 494; 530; 598; 664; 732; 778; 846; 912; 980];
   end
end

function posInd = cbw320Indices % IEEE P802.11be/D1.5, Table 36-60
   posInd = [44; 112; 178; 246; 292; 360; 426; ...
       494; 530; 598; 664; 732; 778; 846; 912; 980; 1068; 1136; 1202; ...
       1270; 1316; 1384; 1450; 1518; 1554; 1622; 1688; 1756; 1802; ...
       1870; 1936; 2004];
end