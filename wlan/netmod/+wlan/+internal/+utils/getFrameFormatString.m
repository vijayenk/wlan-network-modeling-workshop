function formatString = getFrameFormatString(formatConstant, layer)
%getFrameFormatString Return frame format as a string format used by the
%specified layer from the given frame format constant
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.

%   Copyright 2025 The MathWorks, Inc.

if strcmp(layer, 'PHY')
    switch formatConstant % Check for more frequently used formats first
        case wlan.internal.FrameFormats.NonHT
            formatString = 'NonHT';
        case wlan.internal.FrameFormats.HE_SU
            formatString = 'HE_SU';
        case wlan.internal.FrameFormats.EHT_SU
            formatString = 'EHT_SU';
        case wlan.internal.FrameFormats.HE_MU
            formatString = 'HE_MU';
        case wlan.internal.FrameFormats.HE_TB
            formatString = 'HE_TB';
        case wlan.internal.FrameFormats.VHT
            formatString = 'VHT';
        case wlan.internal.FrameFormats.HTMixed
            formatString = 'HTMixed';
        case wlan.internal.FrameFormats.HE_EXT_SU
            formatString = 'HE_EXT_SU';
    end
elseif strcmp(layer, 'MAC')
    switch formatConstant % Check for more frequently used formats first
        case wlan.internal.FrameFormats.NonHT
            formatString = 'Non-HT';
        case wlan.internal.FrameFormats.HE_SU
            formatString = 'HE-SU';
        case wlan.internal.FrameFormats.EHT_SU
            formatString = 'EHT-SU';
        case wlan.internal.FrameFormats.HE_MU
            formatString = 'HE-MU';
        case wlan.internal.FrameFormats.HE_TB
            formatString = 'HE-TB';
        case wlan.internal.FrameFormats.VHT
            formatString = 'VHT';
        case wlan.internal.FrameFormats.HTMixed
            formatString = 'HT-Mixed';
        case wlan.internal.FrameFormats.HE_EXT_SU
            formatString = 'HE-EXT-SU';
    end
end
end