function [headerBits,dataBits,numIterations] = ...
    dmgHeaderDecode(x,cfgDMG,algChoice,alphaBeta,maxNumIter,termination)
%dmgHeaderDecode Decode DMG header field for Control, SC and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   HEADERBITS = dmgHeaderDecode(X,CFGDMG) decodes the input X using a DMG
%   LDPC code at the specified rate. HEADERBITS is the soft decision
%   decoded bits. For OFDM and SC PHY, HEADERBITS is of length 64
%   containing the recovered header bits. For Control PHY the recovered
%   HEADERBITS is of length 40.
%
%   CFGDMG is the format configuration object of type <a 
%   href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a>, which
%   specifies the parameters for the DMG format.
%
%   ALGCHOICE specifies the LDPC decoding algorithm as one of these
%   - 'bp'            : Belief propagation (BP)
%   - 'layered-bp'    : Layered BP
%   - 'norm-min-sum'  : Normalized min-sum
%   - 'offset-min-sum': Offset min-sum:
%
%   ALPHABETA specifies the scaling factor (if the Normalized Min-Sum
%   approximation is used) or the offset factor (if the Offset Min-Sum
%   approximation is used). Its value is irrelevant for the other two LDPC
%   algorithms but still needed.
%
%   MAXNUMITER specifies the number of decoding iterations required to
%   decode the input X.
%
%   TERMINATION specifies the decoding termination criteria as one of
%   'early' or 'max'. For 'early', decoding is terminated when all
%   parity-checks are satisfied, up to a maximum number of iterations given
%   by MAXNUMITER. For 'max', decoding continues till MAXNUMITER iterations
%   are completed.
%
%   [...,DATABITS] = dmgHeaderDecode(...) additionally returns the soft
%   decision decoded data bits, DATABITS, which are encoded along with the
%   header bit in the first LDPC block of the Control PHY. DATABITS is of
%   length 48 for Control PHY and is empty for SC and OFDM PHY.
%
%   [...,NUMITERATIONS] = dmgHeaderDecode(...) returns the actual number of
%   LDPC decoding iterations.
%
%   See also wlanDMGHeaderBitRecover, wlanDMGDataBitRecover

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

% If input X is empty then do not attempt to decode it; return empty
dataBits = zeros(0,1,'int8'); % Assign empty due to codeGen
if isempty(x)
    headerBits = zeros(0,1,'int8');
    numIterations = [];
    return;
end

LCW = 672;  % Codeword length
rate = 3/4; % Header is always encoded with rate 3/4

switch phyType(cfgDMG)
    case 'Control'
        % IEEE 802.11ad-2012, Section 21.4.3.3
        HL = 40; % Header length for Control PHY
        x = x(1:256,1);
        parms = wlan.internal.dmgControlEncodingInfo(cfgDMG);
        input = [x(1:parms.LDPFCW,1); realmax*ones(LCW-length(x),1); x(parms.LDPFCW+1:end,1)];

        cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(rate,LCW),algChoice);
        [decodedBits,numIterations] = ldpcDecode(input,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);

        % De-scramble header field
        scramInit = [1; 1; 1; decodedBits(5:-1:2,1)]; % Scrambler initialization is bits 2:5 of the header
        if all(scramInit(4:end,1)==0)
            % Scrambler initialization invalid (0), therefore do not descramble
            descrambledBits = decodedBits(6:parms.LDPFCW,1);
        else
            descrambledBits = wlanScramble(decodedBits(6:parms.LDPFCW,1),scramInit);
        end
        scrambledBits = [decodedBits(1:5); descrambledBits];
        headerBits = scrambledBits(1:HL,1); % Header bits length is 40
        dataBits = scrambledBits(HL+1:end,1); % First 48 data bits are appended with the header

    case 'SC'
        % IEEE Std 802.11ad-2012, Section 21.6.3.1.4
        HL = 64; % Header length for SC and OFDM PHY
        c1 = x(1:length(x)/2,1); % Extract first sequence
        c2 = x(length(c1)+1:end,1); % Extract second sequence
        c2 = wlan.internal.descrambleLLRs(c2);
        % Sum first and second sequence for additional processing gain.
        % Only first 216 LLRs are summed. This includes 64 header bits and
        % 152 parity bits which are common in both c1 and c2.
        L = HL+152; % Header(64) + Common parity bits(152)
        c = c1(1:L,1)+c2(1:L,1);
        usefulBits = [c; c1(L+1:end,1); c2(L+1:end,1)]; % Header + Parity
        headerBits = usefulBits(1:HL,1);
        parityBits = usefulBits(HL+1:end,1);
        extraBits = realmax*ones(LCW-length(headerBits)-length(parityBits),1);
        input = [headerBits; extraBits; parityBits];

        cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(rate,LCW),algChoice);
        [decodedBits,numIterations] = ldpcDecode(input,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);

        % De-scramble header field
        scramInit = decodedBits(7:-1:1); % Scrambler initialization is first 7 bits of the header
        if all(scramInit==0)
            % Scrambler initialization invalid (0), therefore do not descramble
            descrambledBits = decodedBits(8:HL,1);
        else
            descrambledBits = wlanScramble(decodedBits(8:HL,1),scramInit);
        end
        headerBits = [decodedBits(1:7); descrambledBits];

    otherwise % OFDM
        % IEEE Std 802.11ad-2012, Section 21.5.3.1.4
        HL = 64; % Header length for SC and OFDM PHY
        % Append missing parity bits to the first sequence
        usefulBits = combineDescrambleLLRs(x);
        headerBits = usefulBits(1:HL,1);
        parityBits = usefulBits(HL+1:end,1);
        extraBits = realmax*ones(LCW-length(headerBits)-length(parityBits),1);
        input = [headerBits; extraBits; parityBits];
        cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(rate,LCW),algChoice);
        [decodedBits,numIterations] = ldpcDecode(input,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);

        % De-scramble header field
        scramInit = decodedBits(7:-1:1,1); % Scrambler initialization is first 7 bits of the header
        if all(scramInit==0)
            % Scrambler initialization invalid (0), therefore do not descramble
            descrambledBits = decodedBits(8:HL,1);
        else
            descrambledBits = wlanScramble(decodedBits(8:HL,1),scramInit);
        end
        headerBits = [decodedBits(1:7); descrambledBits];
end

end

function y = combineDescrambleLLRs(x)
    HL = 64; % Header length for OFDM PHY
    seqLen = 224; % Length of each sequence in the header field (672/3)
    c1 = x(1:seqLen,1); % Extract first sequence
    c2c3 = x(seqLen+1:end,1); % Extract second and third sequence
    out = wlan.internal.descrambleLLRs(c2c3);
    c2 = out(1:seqLen,1);
    c3 = out(seqLen+1:end,1);
    index1 = 1:148;   % Index of the first common elements between sequence c2 and c3
    index2 = 149:156; % Index of the second elements only present in sequence c3
    index3 = 149:216; % Index of the first elements present in sequence c2
    index4 = 157;     % Start index of the elements in sequence c3
    index5 = 217;     % Start index of the elements only present in sequence c2

    % Build sequence C2 and C3
    c2c3 = [c2(index1)+c3(index1); c3(index2); c2(index3)+c3(index4:index4+size(index3,2)-1); c2(index5:end)];

    % Sum common elements between first, second and third sequence for additional processing gain.
    c1c2c3 = c1+[c2c3(1:HL,1); c2c3(HL+8+1:end,1)];
    y = [c1c2c3(1:HL,1); c2c3(HL+1:HL+8,1); c1c2c3(HL+1:end,1)];
end
