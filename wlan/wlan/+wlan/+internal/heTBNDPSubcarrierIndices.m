function ind = heTBNDPSubcarrierIndices(cbw,ruToneSetIndex,feedbackStatus)
%heTBNDPSubcarrierIndices HE TB feedback NDP subcarrier indices
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   IND = heTBNDPSubcarrierIndices(CBW,RUTONESETINDEX,FEEDBACKSTATUS)
%   returns a vector containing the HE-LTF mapping subcarrier indices as
%   defined in IEEE Std 802.11ax-2021, Table 27-32.
%
%   CBW is the channel bandwidth and must be 20, 40, 80, or 160.
%
%   RUTONESETINDEX is a positive integer between 1 and 144, inclusive as
%   defined in IEEE Std 802.11ax-2021, Tables 27-32. RUToneSetIndex is
%   bandwidth dependent and must be:
%       - 1:18  (inclusive) for 20 MHz
%       - 1:36  (inclusive) for 40 MHz
%       - 1:72  (inclusive) for 80 MHz
%       - 1:144 (inclusive) for 160 MHz
%
%   FeedbackStatus is logical scalar and specify the modulated tones
%   within an RU tone set indicated by RUToneSetIndex.

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

% Get subcarrier indices for 20 MHz. The subcarrier indices for 40/80/160
% MHz follow a similar pattern with an offset as defined in IEEE
% Std 802.11ax-2021, Table 27-32.
indexCBW20 = subcarrierIndex20Mhz(rem(ruToneSetIndex-1,18)+1,feedbackStatus);
switch cbw
    case 20
        ind = indexCBW20;
    case 40
        if ruToneSetIndex<=18
            ind = indexCBW20-128;
        else
            ind = indexCBW20+128;
        end
    case 80
        ind = subcarrierIndex80Mhz(indexCBW20,ruToneSetIndex);
    otherwise % 160 MHz
        if ruToneSetIndex<=72 % Lower 160 MHz
            ind = subcarrierIndex80Mhz(indexCBW20,ruToneSetIndex);
            ind = ind-512;
        else
            if ruToneSetIndex==144
                ruToneSetIndex = ruToneSetIndex/2;
            else
                ruToneSetIndex = rem(ruToneSetIndex,72);
            end
            ind = subcarrierIndex80Mhz(indexCBW20,ruToneSetIndex);
            ind = ind+512;
        end
end
end

function ind = subcarrierIndex20Mhz(ruToneSetIndex,feedbackStatus)
    if feedbackStatus==1
        mappingInd = [-113; -77; -41; 6; 42; 78];
    else
        mappingInd = [-112; -76; -40; 7; 43; 79];
    end
    ind = mappingInd+(ruToneSetIndex-1)*2;
end

function index = subcarrierIndex80Mhz(indexCBW20,ruToneSetIndex)
    if ruToneSetIndex<=18
        index = indexCBW20-384;
    elseif ruToneSetIndex<=36
        index = indexCBW20-128;
    elseif ruToneSetIndex<=54
        index = indexCBW20+128;
    else % ruToneSetIndex<=72
        index = indexCBW20+384;
    end
end