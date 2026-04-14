function apepLength = wlanAPEPLength(cfgPHY, unit, value)
%wlanAPEPLength APEP length calculation
%   APEPLENGTH = wlanAPEPLength(CFGPHY, UNIT, VALUE) calculates the APEP
%   length in octets from the given VALUE and physical layer configuration
%   CFGPHY. The VALUE can be in terms of PPDU transmission time or number
%   of data symbols, indicated by the UNIT argument.
%
%   APEPLENGTH is the A-MPDU pre-EOF padding length in octets, returned as
%   a scalar number. This is the maximum APEP length that fits into the
%   specified PPDU transmission time or number of data symbols.
%
%   CFGPHY is an object of type wlanVHTConfig or wlanHESUConfig, or 
%   wlanEHTMUConfig.
%
%   UNIT indicates the units of the argument VALUE from which the APEP
%   length is calculated, specified as one of 'TxTime' or 'NumDataSymbols'.
%
%   VALUE is the value from which the APEP length is calculated. 
%       - If UNIT is set to 'TxTime', VALUE is a scalar number specifying
%         time in microseconds.
%       - If UNIT is set to 'NumDataSymbols', VALUE is a scalar number
%         specifying the number of data symbols.

%   Copyright 2019-2025 The MathWorks, Inc.

%#codegen

% Validate inputs
validateattributes(cfgPHY, {'wlanVHTConfig', 'wlanHESUConfig', 'wlanEHTMUConfig'},{'scalar'}, 'wlanAPEPLength', 'format configuration object');
unit = validatestring(unit, {'TxTime', 'NumDataSymbols'}, 'wlanAPEPLength', 'UNIT');

% Calculate the PSDU length
psduLength = wlanPSDULength(cfgPHY, unit, value);

% APEP length is always 4-byte aligned. Align the PSDU length to the next
% lower 4-byte boundary to get APEP length
apepLength = psduLength - rem(psduLength, 4);

% If the APEP length doesn't result in the above calculated PSDU length, do
% not align the APEP length to 4-bytes
switch class(cfgPHY)
    case 'wlanHESUConfig'
        if apepLength <= 6500631
            cfgPHY.APEPLength = apepLength;
            if cfgPHY.getPSDULength ~= psduLength
                apepLength = psduLength;
            end
        end

    case 'wlanEHTMUConfig'
        if apepLength <= 15523198
            cfgPHY.User{1}.APEPLength = apepLength;
            if cfgPHY.psduLength ~= psduLength
                apepLength = psduLength;
            end
        end

    otherwise
        if apepLength <= 1048575
            cfgPHY.APEPLength = apepLength;
            if cfgPHY.PSDULength ~= psduLength
                apepLength = psduLength;
            end
        end
end

end
