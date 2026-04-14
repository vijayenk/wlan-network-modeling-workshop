function y = ldpcEncodeCore(infoBits,rate)
%ldpcEncodeCore Generate LDPC parity matrices
%
%   Y = ldpcEncodeCore(INFOBITS,RATE) calculates the parity check bits for
%   the binary input data (infoBits) using a WLAN LDPC code at the
%   specified rate (RATE).
% 
%   The input INFOBITS is of size Ns-by-NCW where NS is the number of
%   information bit of a codeword and NCW is number of LDPC codewords.
%
%   RATE must be equal to '1/2', '2/3', '3/4', '5/6', '5/8' and '13/16'.
%   RATE and the number of rows in INFOBITS should correspond to one of the
%   four valid block lengths: 648, 672, 1296, 1944, or 3888.
%   
%   To obtain the codewords, concatenate infoBits and y vertically, i.e.
%   [infoBits;y].
%
%   See also ldpcDecode.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

% Persistent variables for pre-computed data structures for LDPC codes
persistent PT_1_2_648     % coding rate = 1/2, block length = 648
persistent PT_1_2_1296    % coding rate = 1/2, block length = 1296
persistent PT_1_2_1944    % coding rate = 1/2, block length = 1944
persistent PT_1_2_3888    % coding rate = 1/2, block length = 3888
persistent PT_1_2_672     % coding rate = 1/2, block length = 672(802.11ad)
persistent PT_2_3_648     % coding rate = 2/3, block length = 648
persistent PT_2_3_1296    % coding rate = 2/3, block length = 1296
persistent PT_2_3_1944    % coding rate = 2/3, block length = 1944
persistent PT_2_3_3888    % coding rate = 2/3, block length = 3888
persistent PT_3_4_648     % coding rate = 3/4, block length = 648
persistent PT_3_4_672     % coding rate = 3/4, block length = 672(802.11ad)
persistent PT_3_4_1296    % coding rate = 3/4, block length = 1296
persistent PT_3_4_1944    % coding rate = 3/4, block length = 1944
persistent PT_3_4_3888    % coding rate = 3/4, block length = 3888
persistent PT_5_6_648     % coding rate = 5/6, block length = 648
persistent PT_5_6_1296    % coding rate = 5/6, block length = 1296
persistent PT_5_6_1944    % coding rate = 5/6, block length = 1944
persistent PT_5_6_3888    % coding rate = 5/6, block length = 3888
persistent PT_5_8_672     % coding rate = 5/8, block length = 672(802.11ad)
persistent PT_13_16_672   % coding rate = 13/16, block length = 672(802.11ad)    

infoLen = size(infoBits,1);

% When an LDPC code is used for the first time, load the corresponding
% pre-computed data structure and save it in a persistent variable.

% Compute parity check bits by direct modulo-2 matrix product
switch rate
    case 1/2
        blockLength = infoLen/(1/2);
        switch blockLength
            case 648
                if isempty(PT_1_2_648)
                    PT_1_2_648 = createConfig(wlan.internal.ldpcMatrix(1/2,648));
                end
                y = ldpcEncode(infoBits,PT_1_2_648,'OutputFormat','parity');
            case 1296
                if isempty(PT_1_2_1296)
                    PT_1_2_1296 = createConfig(wlan.internal.ldpcMatrix(1/2,1296));
                end
                y = ldpcEncode(infoBits,PT_1_2_1296,'OutputFormat','parity');
            case 1944
                if isempty(PT_1_2_1944)
                    PT_1_2_1944 = createConfig(wlan.internal.ldpcMatrix(1/2,1944));
                end
                y = ldpcEncode(infoBits,PT_1_2_1944,'OutputFormat','parity');
            case 672
                if isempty(PT_1_2_672)
                    PT_1_2_672 = createConfig(wlan.internal.ldpcMatrix(1/2,672));
                end
                y = ldpcEncode(infoBits,PT_1_2_672,'OutputFormat','parity');
            otherwise % 3888
                if isempty(PT_1_2_3888)
                    PT_1_2_3888 = createConfig(wlan.internal.ldpcMatrix(1/2,3888));
                end
                y = ldpcEncode(infoBits,PT_1_2_3888,'OutputFormat','parity');
        end
    case 2/3
        blockLength = infoLen/(2/3);
        switch blockLength
            case 648
                if isempty(PT_2_3_648)
                    PT_2_3_648 = createConfig(wlan.internal.ldpcMatrix(2/3,648));
                end
                y = ldpcEncode(infoBits,PT_2_3_648,'OutputFormat','parity');
            case 1296
                if isempty(PT_2_3_1296)
                    PT_2_3_1296 = createConfig(wlan.internal.ldpcMatrix(2/3,1296));
                end
                y = ldpcEncode(infoBits,PT_2_3_1296,'OutputFormat','parity');
            case 1944
                if isempty(PT_2_3_1944)
                    PT_2_3_1944 = createConfig(wlan.internal.ldpcMatrix(2/3,1944));
                end
                y = ldpcEncode(infoBits,PT_2_3_1944,'OutputFormat','parity');
            otherwise % 3888
                if isempty(PT_2_3_3888)
                    PT_2_3_3888 = createConfig(wlan.internal.ldpcMatrix(2/3,3888));
                end
                y = ldpcEncode(infoBits,PT_2_3_3888,'OutputFormat','parity');  
        end
    case 3/4
        blockLength = infoLen/(3/4);
        switch blockLength
            case 648
                if isempty(PT_3_4_648)
                    PT_3_4_648 = createConfig(wlan.internal.ldpcMatrix(3/4,648));
                end
                y = ldpcEncode(infoBits,PT_3_4_648,'OutputFormat','parity');
            case 1296
                if isempty(PT_3_4_1296)
                    PT_3_4_1296 = createConfig(wlan.internal.ldpcMatrix(3/4,1296));
                end
                y = ldpcEncode(infoBits,PT_3_4_1296,'OutputFormat','parity');
            case 1944
                if isempty(PT_3_4_1944)
                    PT_3_4_1944 = createConfig(wlan.internal.ldpcMatrix(3/4,1944));
                end
                y = ldpcEncode(infoBits,PT_3_4_1944,'OutputFormat','parity');
            case 672
                if isempty(PT_3_4_672)
                    PT_3_4_672 = createConfig(wlan.internal.ldpcMatrix(3/4,672));
                end
                y = ldpcEncode(infoBits,PT_3_4_672,'OutputFormat','parity');
            otherwise % 3888
                if isempty(PT_3_4_3888)
                    PT_3_4_3888 = createConfig(wlan.internal.ldpcMatrix(3/4,3888));
                end
                y = ldpcEncode(infoBits,PT_3_4_3888,'OutputFormat','parity');
        end
    case 5/6
        blockLength = infoLen/(5/6);
        switch blockLength
            case 648
                if isempty(PT_5_6_648)
                    PT_5_6_648 = createConfig(wlan.internal.ldpcMatrix(5/6,648));
                end
                y = ldpcEncode(infoBits,PT_5_6_648,'OutputFormat','parity');
            case 1296
                if isempty(PT_5_6_1296)
                    PT_5_6_1296 = createConfig(wlan.internal.ldpcMatrix(5/6,1296));
                end
                y = ldpcEncode(infoBits,PT_5_6_1296,'OutputFormat','parity');
            case 1944
                if isempty(PT_5_6_1944)
                    PT_5_6_1944 = createConfig(wlan.internal.ldpcMatrix(5/6,1944));
                end
                y = ldpcEncode(infoBits,PT_5_6_1944,'OutputFormat','parity');
            otherwise % 3888
                if isempty(PT_5_6_3888)
                    PT_5_6_3888 = createConfig(wlan.internal.ldpcMatrix(5/6,3888));
                end
                y = ldpcEncode(infoBits,PT_5_6_3888,'OutputFormat','parity');
        end 
    case 5/8
        if isempty(PT_5_8_672)
            PT_5_8_672 = createConfig(wlan.internal.ldpcMatrix(5/8,672));
        end
        y = ldpcEncode(infoBits,PT_5_8_672,'OutputFormat','parity');
    otherwise
        if isempty(PT_13_16_672)
            PT_13_16_672 = createConfig(wlan.internal.ldpcMatrix(13/16,672));
        end
        y = ldpcEncode(infoBits,PT_13_16_672,'OutputFormat','parity');
end
end

function out = createConfig(ldpcMatrix)
    % We use coder.ignoreSize to avoid specializing ldpcEncoderConfig
    % (and other functions) for each different ldpc matrix sizes
    out = ldpcEncoderConfig(coder.ignoreSize(ldpcMatrix));
end