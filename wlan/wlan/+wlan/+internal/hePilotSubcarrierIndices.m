function ind = hePilotSubcarrierIndices(chanBW,varargin)
%hePilotSubcarrierIndices HE pilot subcarrier indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   IND = hePilotSubcarrierIndices(CHANBW,RUSIZE) returns a column vector
%   containing the pilot indices over all RUs.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, or 160.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 2*996.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

% IEEE P802.11ax/D4.1, Section 27.3.11.13.
if nargin>1
    ruSize = varargin{1};
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
    case 40
        switch ruSize
            case {26,52}
                posInd = [10; 24; 36; 50; 64; 78; 90; 104; 116; 130; 144; 158; 170; 184; 198; 212; 224; 238];
            otherwise % {106, 242, 484}
                assert(any(ruSize==[106,242,484]));
                posInd = [10; 36; 78; 104; 144; 170; 212; 238];
        end
    case 80
        posInd = cbw80Indices(ruSize);
    otherwise % 160
        assert(chanBW==160);
        switch ruSize
            case {26,52,106,242,484,996}
                posInd = [cbw80Indices(ruSize)-512; cbw80Indices(ruSize)+512];
            otherwise % {2*996}
                assert(ruSize==1992);
                posInd = [cbw80Indices(996)-512; cbw80Indices(996)+512];
        end
end
ind = [-flipud(posInd); posInd];

end

function posInd = cbw80Indices(ruSize)
    switch ruSize
        case {26,52}
            posInd = [10; 24; 38; 50; 64; 78; 92; 104; 118; 130; 144; ...
                158; 172; 184; 198; 212; 226; 238; 252; 266; 280; ...
                292; 306; 320; 334; 346; 360; 372; 386; 400; 414; ...
                426; 440; 454; 468; 480; 494];
        case {106, 242, 484}
            posInd = [24; 50; 92; 118; 158; 184; 226; 252; 266; 292; ...
                334; 360; 400; 426; 468; 494];
        otherwise % 996
            assert(ruSize==996)
            posInd = [24; 92; 158; 226; 266; 334; 400; 468];
    end
end