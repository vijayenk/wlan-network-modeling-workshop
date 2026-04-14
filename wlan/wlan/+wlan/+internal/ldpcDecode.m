function [y,numIterations] = ldpcDecode(x,cfg,algChoice,alphaBeta,maxNumIter,earlyTermination)
%ldpcDecode Low-Density-Parity-Check (LDPC) decoder
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ldpcDecode(X,CFG,ALGCHOICE,ALPHABETA,MAXNUMITER,EARLYTERMINATION)
%   decodes the input X for the specified rate, LDPC algorithm, and
%   options. Output Y is a hard decision decoded output of the information
%   bits.
%
%   Each column of X specifies the log-likelihood ratios of a codeword. The
%   number of rows in X should be equal to one of the four valid block
%   lengths: 648, 672, 1296, and 1944.
%
%   CFG should be a structure including the fields:
%   VecPayloadBits  - Number of payload bits within a codeword
%   Rate            - Coding rate
%   NumCW           - Number of LDPC codewords
%   LengthLDPC      - LDPC codeword length
%   VecShortenBits  - Vector of shortening bits in each codeword
%   VecPunctureBits - Vector of puncture bits in each codeword
%   VecRepeatBits   - Number of coded bits to be repeated
%
%   ALGCHOICE specifies the LDPC decoding algorithm as one of these
%   - 'bp'            : Belief propagation (BP)
%   - 'layered-bp'    : Layered BP
%   - 'norm-min-sum'  : Normalized min-sum
%   - 'offset-min-sum': Offset min-sum:
%
%   ALPHABETA specifies the scaling factor for Normalized Min-Sum
%   approximation or the offset factor for Offset Min-Sum approximation.
%   Its value is irrelevant for the other two LDPC algorithms but still
%   needed.
%
%   MAXNUMITER specifies the number of decoding iterations required to
%   decode the input X.
%
%   EARLYTERMINATION specifies the decoding termination criteria as one of
%   'early' or 'max'. For 'early', decoding is terminated when all
%   parity-checks are satisfied, up to a maximum number of iterations given
%   by MAXNUMITER. For 'max', decoding continues till MAXNUMITER iterations
%   are completed.
%
%   [Y, NUMITERATIONS] = ldpcDecode(...) decodes the LDPC encoded data.
%   The function returns the actual number of LDPC decoding iterations, one
%   per codeword. The NUMITERATIONS is NUMCW-by-1 vector, where NUMCW is
%   the number of codewords.
%
%   See also ldpcEncode, getLDPCparameters. 

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

    numCW           = cfg.NumCW;
    lengthLDPC      = cfg.LengthLDPC;
    vecShortenBits  = cfg.VecShortenBits;
    vecPunctureBits = cfg.VecPunctureBits;
    vecRepeatBits   = cfg.VecRepeatBits;
    vecPayloadBits  = cfg.VecPayloadBits;
    rate            = cfg.Rate;

    % Initialize output
    y = coder.nullcopy(zeros(sum(vecPayloadBits),1,'int8'));
    offset = 0;
    depuncturedCW = coder.nullcopy(zeros(lengthLDPC,numCW, "like", x));

    for idxCW = 1:numCW
        % Retrieve information bits
        inpBits = x(offset + (1:vecPayloadBits(idxCW)),1);
        % Size of the parity bits after puncturing
        pBlkSize = round(lengthLDPC*(1-rate)) - vecPunctureBits(idxCW);
        % Get parity bits
        parityBits = x(offset + vecPayloadBits(idxCW) + (1:pBlkSize),1);
        % Convert into LLRs
        shortenBits =  (2^100) * ones(vecShortenBits(idxCW),1,"like",x);
        % Extra bits to compensate for puncturing
        extraBits = zeros(vecPunctureBits(idxCW),1, "like", x);
        % Depunctured codeword
        depuncturedCW(:,idxCW) = [inpBits;shortenBits;parityBits;extraBits];
        offset = offset + vecPayloadBits(idxCW) + pBlkSize + vecRepeatBits(idxCW);
    end

    decoderCfg = wlan.internal.ldpcDecoderConfiguation(rate,lengthLDPC,algChoice);
    [out,numIterations] = ldpcDecode(depuncturedCW,decoderCfg,maxNumIter,'DecisionType','hard','Termination',earlyTermination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);

    idx = 0;
    for idxCW = 1:numCW
        y(idx + (1:vecPayloadBits(idxCW))) = out(1:vecPayloadBits(idxCW),idxCW);
        idx = vecPayloadBits(idxCW) + idx;
    end

end