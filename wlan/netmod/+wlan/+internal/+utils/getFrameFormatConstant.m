function formatConstant = getFrameFormatConstant(formatString)
%getFrameFormatConstant Return frame format as a constant from the given
%frame format string
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

% Check for more frequently used formats first
if strcmp(formatString, "Non-HT") || strcmp(formatString, "NonHT")
    formatConstant = wlan.internal.FrameFormats.NonHT;
elseif strcmp(formatString, "HE-SU") || strcmp(formatString, "HE_SU")
    formatConstant = wlan.internal.FrameFormats.HE_SU;
elseif strcmp(formatString, "EHT-MU") % EHT-MU is returned by wlanFormatDetect
    formatConstant = wlan.internal.FrameFormats.EHT_MU;
elseif strcmp(formatString, "EHT-SU") || strcmp(formatString, "EHT_SU") % EHT-SU is set at the MAC layer and mapped to EHT_SU
    formatConstant = wlan.internal.FrameFormats.EHT_SU;
elseif any(strcmp(formatString, ["HE-MU-OFDMA", "HE-MU", "HE_MU"]))
    formatConstant = wlan.internal.FrameFormats.HE_MU;
elseif strcmp(formatString, "HE-TB") || strcmp(formatString, "HE_TB")
    formatConstant = wlan.internal.FrameFormats.HE_TB;
elseif strcmp(formatString, "HE-EXT-SU") || strcmp(formatString, "HE_EXT_SU")
    formatConstant = wlan.internal.FrameFormats.HE_EXT_SU;
elseif strcmp(formatString, "VHT")
    formatConstant = wlan.internal.FrameFormats.VHT;
elseif any(strcmp(formatString, ["HT-MF", "HT-Mixed", "HTMixed"]))
    formatConstant = wlan.internal.FrameFormats.HTMixed;
elseif strcmp(formatString, "EHT-TB") || strcmp(formatString, "EHT_TB")
    formatConstant = wlan.internal.FrameFormats.EHT_TB;
else % Unsupported frame formats like HT_GF
    formatConstant = -1;
end
end