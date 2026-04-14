function decConfig = ldpcDecoderConfiguation(rate,blockLength,algChoice)
%ldpcDecoderConfiguation LDPC decoder configuration
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DECCONFIG = ldpcDecoderConfiguation(rate,blockLength,algChoice) returns
%   the LDPC decoder configuration object for a given code RATE, LDPC
%   BLOCKLENGTH, and the decoding algorithm.
%
%   Input RATE must be equal to '1/2', '2/3', '3/4','5/6', '5/8', or 13/16,
%   BLOCKLENGTH must be equal to 648, 672, 1296, 1944, or 3888. ALGCHOICE
%   specifies the LDPC decoding algorithm as one of these:
%
%   - 'bp'            : Belief propagation (BP)
%   - 'layered-bp'    : Layered BP
%   - 'norm-min-sum'  : Normalized min-sum
%   - 'offset-min-sum': Offset min-sum:

%   Copyright 2024-2025 The MathWorks, Inc.

%#codegen

persistent decoderCfg
if isempty(decoderCfg)
    % Create a 20 elemenet cell array to store the LDPC decoder
    % configuration of all possible rate and blocklengths.
    decoderCfg = coder.nullcopy(cell(20,1));
end

persistent newLDPCConfiguration
if isempty(newLDPCConfiguration)
    % Indicates if the new LDPC decoder configuration is required
    newLDPCConfiguration = true(20,1);
end

switch rate
    case 1/2
        switch blockLength
            case 648
                blkRateIndex = 1;
            case 1296
                blkRateIndex = 2;
            case 1944
                blkRateIndex = 3;
            case 3888
                blkRateIndex = 4;
            otherwise % 672
                blkRateIndex = 5;
        end
    case 2/3
        switch blockLength
            case 648
                blkRateIndex = 6;
            case 1296
                blkRateIndex = 7;
            case 3888
                blkRateIndex = 8;
            otherwise % 1944
                blkRateIndex = 9;
        end
    case 3/4
        switch blockLength
            case 648
                blkRateIndex = 10;
            case 1296
                blkRateIndex = 11;
            case 1944
                blkRateIndex = 12;
            case 3888
                blkRateIndex = 13;
            otherwise % 672
                blkRateIndex = 14;
        end
    case 5/6
        switch blockLength
            case 648
                blkRateIndex = 15;
            case 1296
                blkRateIndex = 16;
            case 3888
                blkRateIndex = 17;
            otherwise % 1944
                blkRateIndex = 18;
        end
    case 5/8
        blkRateIndex = 19; % 672
    otherwise
        blkRateIndex = 20; % 672
end

if newLDPCConfiguration(blkRateIndex)
    newLDPCConfiguration(blkRateIndex) = false;
    decoderCfg{blkRateIndex} = ldpcDecoderConfig(wlan.internal.ldpcMatrix(rate,blockLength));
end
decConfig = decoderCfg{blkRateIndex};
decConfig.Algorithm = algChoice;