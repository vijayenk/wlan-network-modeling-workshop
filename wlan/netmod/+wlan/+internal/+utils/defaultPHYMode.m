function s = defaultPHYMode()
%   PHYRxOn           - Logical value, that defines whether the PHY Rx
%                       is on or not
%   EnableSROperation - Logical value, that defines whether the SR
%                       operation is enabled or not.
%   BSSColor          - Basic service set color (Used to differentiate
%                       signals as Intra-BSS/Intra-BSS). Type double
%   OBSSPDThreshold   - Overlapping BSS packet detect threshold. Type
%                       double

%   Copyright 2022-2025 The MathWorks, Inc.

    s = struct(...
        'PHYRxOn', true, ...
        'EnableSROperation', false, ...
        'BSSColor', 0, ...
        'OBSSPDThreshold', -82);
end
