function ind = heRUSubcarrierIndices(chanBW,varargin)
%heRUSubcarrierIndices RU subcarrier indices as per IEEE Std 802.11ax-2021, Tables 27-7 to 27-9
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   IND = heRUSubcarrierIndices(CHANBW,RUSIZE) returns a matrix containing
%   the indices for all RUs. Each column contains the indices for an RU.
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, or 160.
%
%   RUSIZE is the RU size in subcarriers and must be one of 26, 52, 106,
%   242, 484, 996, or 2*996.
%
%   IND = heRUSubcarrierIndices(CHANBW) returns a matrix containing the
%   indices for all RUs assuming a full bandwidth allocation.
%
%   IND = heRUSubcarrierIndices(CHANBW,RUSIZE,RUINDEX) optionally returns
%   the indices for only the RU specified by RUINDEX.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

if nargin>1
    ruSize = varargin{1};
else
    ruSize = wlan.internal.heFullBandRUSize(chanBW);
end

% IEEE Std 802.11ax-2021, Table 27-7/8/9 - Subcarrier indices for RUs in a 20/40/80 MHz HE PPDU
switch chanBW
    case 20
        switch ruSize
            case 26
                ruSizeInd = [(-121:-96).' (-95:-70).' (-68:-43).' (-42:-17).' ([-16:-4 4:16]).' (17:42).' (43:68).' (70:95).' (96:121).'];
            case 52
                ruSizeInd = [(-121:-70).' (-68:-17).' (17:68).' (70:121).'];
            case 106
                ruSizeInd = [(-122:-17).' (17:122).'];
            otherwise % 242
                assert(ruSize==242)
                ruSizeInd = [-122:-2 2:122].';
        end
    case 40
        switch ruSize
            case 26
                ruSizeInd = [(-243:-218).' (-217:-192).' (-189:-164).' (-163:-138).' (-136:-111).' (-109:-84).' (-83:-58).' (-55:-30).' (-29:-4).' ...
                    (4:29).' (30:55).' (58:83).' (84:109).' (111:136).' (138:163).' (164:189).' (192:217).' (218:243).'];
            case 52
                ruSizeInd = [(-243:-192).' (-189:-138).' (-109:-58).' (-55:-4).' ...
                    (4:55).' (58:109).' (138:189).' (192:243).'];
            case 106
                ruSizeInd = [(-243:-138).' (-109:-4).' (4:109).' (138:243).'];
            case 242
                ruSizeInd = [(-244:-3).' (3:244).'];
            otherwise % 484
                assert(ruSize==484)
                ruSizeInd = [-244:-3 3:244].';
        end
    case 80
        ruSizeInd = cbw80Size(ruSize);
    otherwise % 160
        assert(chanBW==160)
        switch ruSize
            case 2*996
                % Not in a table; based on Nst in Table 28-14
                ruSizeInd = [cbw80Size(996)-512; cbw80Size(996)+512];
            otherwise
                ruSizeInd = [cbw80Size(ruSize)-512 cbw80Size(ruSize)+512];
        end
end

if nargin>2
    % Return indices for RU index of interest
    ruIndex = varargin{2};
    ind = ruSizeInd(:,ruIndex);
else
    % Return indices for all RU indices
    ind = ruSizeInd;
end

end

function ruSizeInd = cbw80Size(ruSize)
    switch ruSize
        case 26
            ruSizeInd = [(-499:-474).' (-473:-448).' (-445:-420).' (-419:-394).' (-392:-367).' (-365:-340).' (-339:-314).' (-311:-286).' (-285:-260).' ...
                (-257:-232).' (-231:-206).' (-203:-178).' (-177:-152).' (-150:-125).' (-123:-98).' (-97:-72).' (-69:-44).' (-43:-18).' ...
                [(-16:-4) (4:16)].' ...
                (18:43).' (44:69).' (72:97).' (98:123).' (125:150).' (152:177).' (178:203).' (206:231).' (232:257).' ...
                (260:285).' (286:311).' (314:339).' (340:365).' (367:392).' (394:419).' (420:445).' (448:473).' (474:499).'];
        case 52
            ruSizeInd = [(-499:-448).' (-445:-394).' (-365:-314).' (-311:-260).' (-257:-206).' (-203:-152).' (-123:-72).' (-69:-18).' ...
                (18:69).' (72:123).' (152:203).' (206:257).' (260:311).' (314:365).' (394:445).' (448:499).'];
        case 106
            ruSizeInd = [(-499:-394).' (-365:-260).' (-257:-152).' (-123:-18).' ...
                (18:123).' (152:257).' (260:365).' (394:499).'];
        case 242
            ruSizeInd = [(-500:-259).' (-258:-17).' (17:258).' (259:500).'];
        case 484
            ruSizeInd = [(-500:-17).' (17:500).'];
        otherwise % 996
            assert(ruSize==996);
            ruSizeInd = [-500:-3 3:500].';
    end
end