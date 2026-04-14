function [dataBits,numIterations] = dmgDataDecode(x,cfgDMG,algChoice,alphaBeta,maxNumIter,termination)
%dmgDataDecode Decode data bits for Control, SC and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DATABITS = dmgDataDecode(X,CFGDMG) decodes the input X using a DMG LDPC
%   code at the specified rate. DATABITS is the soft decision decoded
%   information bits.
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
%   [...,NUMITERATIONS] = dmgDataDecode(...) returns the actual number of
%   LDPC decoding iterations, one per codeword. NUMITERATIONS is NumCW-by-1
%   vector, where NumCW is the number of codewords.
%
%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

% If input X is empty then do not attempt to decode; return empty
if isempty(x)
    dataBits = zeros(0,1,'int8');
    numIterations = [];
    return;
end

scramInit = wlan.internal.dmgScramblerInitializationBits(cfgDMG);
mcsTable = wlan.internal.getRateTable(cfgDMG);

switch phyType(cfgDMG)
    case 'Control'
        % Decode first codeword from header field
        [~,dataDecode] = wlan.internal.dmgHeaderDecode(x,cfgDMG,algChoice,alphaBeta,maxNumIter,termination);

        x = x(257:end,1); % Get data field
        parms = wlan.internal.dmgControlEncodingInfo(cfgDMG);
        LCW = 672; % Codeword length
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*LCW;
        blkLength = LCW-LCWD+parms.LDPCW;
        % Extract bits for middle codewords
        bitsMiddleCW = x(1:blkLength*(parms.NCW-2),1);
        cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(rate,LCW),algChoice);
        if isempty(bitsMiddleCW)
            middleCWdecoded = zeros(0,0,'int8');
        else
            middleCW = reshape(bitsMiddleCW,blkLength,parms.NCW-2);
            % Append extra LLR bits to extend the size of each block to 672
            extraBits = realmax*ones(LCW-size(middleCW,1),parms.NCW-2);
            blkMiddleCW = [middleCW(1:parms.LDPCW,:); extraBits; middleCW(parms.LDPCW+1:end,:)];
            decodedMiddleCW = ldpcDecode(blkMiddleCW,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);
            middleCWdecoded = decodedMiddleCW(1:parms.LDPCW,:);
        end

        % Extract bits for the last codeword
        blkLength = LCW-LCWD+parms.LDPLCW;
        lastCW = x(end-(blkLength-1):end,1);
        % Append extra LLR bits to extend the size of each block to 672
        extraBits = realmax*ones(LCW-size(lastCW,1),1);
        blkEndCW = [lastCW(1:parms.LDPLCW,1); extraBits; lastCW(parms.LDPLCW+1:end,1)];
        [decodedLastCW,numIterations] = ldpcDecode(blkEndCW,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);
        endCWdecoded = decodedLastCW(1:parms.LDPLCW,1);

        % De-scramble header and PSDU bits together to ensure the scrambler
        % is in correct state for each section. Dummy header bits are added
        % to advance the scrambler.
        headerBits = zeros(88-5,1,'int8'); % Dummy header bits
        descrambledBits = wlanScramble([headerBits; middleCWdecoded(:); endCWdecoded],scramInit); % Extract data bits
        dataBits = [dataDecode;descrambledBits(parms.LDPFCW-6+2:end,1)];

    case 'OFDM'
        parms = wlan.internal.dmgOFDMEncodingInfo(cfgDMG);
        % Only process the valid input length size
        blk = reshape(x,parms.LCW,parms.NCW); % Reshape into blocks
        cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(mcsTable.Rate,parms.LCW),algChoice);
        [decodedBits,numIterations] = ldpcDecode(blk,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);

        % De-scramble header and PSDU bits together to ensure the scrambler
        % is in correct state for each section. Dummy header bits are added
        % to advance the scrambler.
        scramHeaderBits = zeros(64-7,1,'int8');
        decodedBits = decodedBits(:);
        descrambledBits = wlanScramble([scramHeaderBits; decodedBits(1:end-parms.NPAD,1)],scramInit);
        dataBits = descrambledBits(numel(scramHeaderBits)+1:end);

    otherwise % SC PHY
        parms = wlan.internal.dmgSCEncodingInfo(cfgDMG);
        LZ = parms.LCW/(2*mcsTable.Repetition);
        blkBits = x(:);
        blk = reshape(blkBits(1:end-parms.NBLK_PAD,1),parms.LCW,parms.NCW); % Reshape into blocks of size 672

        if mcsTable.Repetition==1
            if isequal(mcsTable.Rate,7/8)
                % Add punctured 48 parity bits and decode with 13/16 rate
                reconBlk = [blk(1:546,:); zeros(48,parms.NCW); blk(546+1:end,:)];
                cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(13/16,672),algChoice);
                [decodedCW,numIterations] = ldpcDecode(reconBlk,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);
            else
                reconBlk = blk;
                cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(mcsTable.Rate,parms.LCW),algChoice);
                [decodedCW,numIterations] = ldpcDecode(reconBlk,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);
            end
        else
            % Append extra LLR bits to extend the size to 672
            extraBits = realmax*ones(LZ,parms.NCW);
            repetitionBlk = wlan.internal.descrambleLLRs(blk(LZ+(1:LZ),:));
            blkCW = [blk(1:LZ,:) + repetitionBlk; extraBits; blk(2*LZ+1:end,:)];
            cfg = ldpcDecoderConfig(wlan.internal.ldpcMatrix(mcsTable.Rate,parms.LCW),algChoice);
            [decodedCW,numIterations] = ldpcDecode(blkCW,cfg,maxNumIter,'DecisionType','hard','Termination',termination,'MinSumScalingFactor',alphaBeta,'MinSumOffset',alphaBeta);
            decodedCW = decodedCW(1:LZ,:);
        end

        % De-scramble header and PSDU bits together to ensure the scrambler
        % is in correct state for each section. Dummy header bits are added
        % to advance the scrambler.
        scramHeaderBits = zeros(64-7,1,'int8');
        allBits = [scramHeaderBits; decodedCW(:)];
        descrambledBits = wlanScramble(allBits,scramInit);
        dataBits = descrambledBits(numel(scramHeaderBits)+1:end-parms.NDATA_PAD);

end
end
