function subChanelIndex = heTBNDPSubchannelIndex(cbw,ruToneSetIndex)
%heTBNDPSubchannelIndex Returns the subchannel index of an HE TB feedback NDP
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SUBCHANNELINDEX = heTBNDPSubchannelIndex(CBW,RUTONESETINDEX) returns
%   the subchannel index of an HE TB feedback NDP for the corresponding
%   RUToneSetIndex and CBW as defined in IEEE Std 802.11ax-2021, Table
%   27-32.
%
%   CBW is the channel bandwidth and must be 20, 40, 80 and 160.
%
%   RUTONESETINDEX is a positive integer between 1 and 144, inclusive as
%   defined in IEEE Std 802.11ax-2021, Tables 27-30. RUToneSetIndex is
%   bandwidth dependent and must be:
%       - 1:18  (inclusive) for 20 MHz
%       - 1:36  (inclusive) for 40 MHz
%       - 1:72  (inclusive) for 80 MHz
%       - 1:144 (inclusive) for 160 MHz

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

switch cbw
    case 20
        subChanelIndex = 1;
    case 40
        if ruToneSetIndex <=18
            subChanelIndex = 1;
        else
            subChanelIndex = 2;
        end
    case 80
        subChanelIndex = getRUIndex80MHz(ruToneSetIndex);
    otherwise
        if ruToneSetIndex<=72
            subChanelIndex = getRUIndex80MHz(ruToneSetIndex); % Lower 80 MHz
        else
            offsetIndex = rem(ruToneSetIndex-1,72)+1;
            subChanelIndex = getRUIndex80MHz(offsetIndex)+4; % Upper 80 MHz
        end
end
end

function subChanelIndex = getRUIndex80MHz(ruToneSetIndex)
    if ruToneSetIndex<=18
        subChanelIndex = 1;
    elseif ruToneSetIndex<=36
        subChanelIndex = 2;
    elseif ruToneSetIndex<=54
        subChanelIndex = 3;
    else % ruToneSetIndex<=72
        subChanelIndex = 4;
    end
end