function s = defaultIndicationToMAC(vector)
%

%   Copyright 2022-2025 The MathWorks, Inc.

arguments
    vector = wlan.internal.utils.defaultTxVector;
end
    s = struct( ...
        'MessageType', wlan.internal.PHYPrimitives.UnknownIndication, ...
        'Vector', vector, ...
        'PPDUInfo', struct('StartTime', 0, 'CenterFrequency', 0), ... % Passed from PHY to MAC in RxError and RxEnd indications
        'Per20Bitmap', false); % 27.3.20.6.5 Per 20 MHz CCA sensitivity - false (CCA idle)/true (CCA busy)
end
