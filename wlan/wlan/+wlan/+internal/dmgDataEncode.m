function y = dmgDataEncode(psdu,cfgDMG)
%dmgDataEncode Encode data bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgDataEncode(PSDU,CFGDMG) generates the DMG LDPC encoded bits for
%   the data field for Control, Single Carrier and OFDM PHYs.
%
%   Y is of size N-by-1 of type uint8, where N is the number of LDPC
%   encoded pay load bits.
%
%   PSDU is the PLCP service data unit input to the PHY. It is a double or
%   int8 typed column vector of length cfgDMG.PSDULength*8.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% If PSDU is empty then do not attempt to encode it; return empty
if isempty(psdu)
    y = zeros(0,1,'int8');
    return;
end

mcsTable = wlan.internal.getRateTable(cfgDMG);
scramInit = wlan.internal.dmgScramblerInitializationBits(cfgDMG);

switch phyType(cfgDMG)
    case 'Control'
        % Scramble dummy header and PSDU bits together to
        % ensure scrambler is in correct state for each section
        dummyHeaderBits = zeros(40,1,'int8'); % Dummy header bits
        scramAllBits = [dummyHeaderBits(1:5,:); wlanScramble([dummyHeaderBits(6:end,:); psdu],scramInit)];

        % LDPC Encoding of header bits
        parms = wlan.internal.dmgControlEncodingInfo(cfgDMG);
        rate = 3/4; % Rate 3/4 parity check matrix
        LCW = 672;  % Codeword length
        LCWD = rate*LCW; 

        % LDPC encoding of middle CWs
        % Extract bits for middle codewords
        bitsMiddleCW = scramAllBits(parms.LDPFCW+1:end-parms.LDPLCW);
        % Create a block of data words of length 502 by padding zeros
        middleCW = reshape(bitsMiddleCW,parms.LDPCW,parms.NCW-2);
        blkMiddleCW = [middleCW; zeros(LCWD-size(middleCW,1),parms.NCW-2)];
        parityBits = wlan.internal.ldpcEncodeCore(blkMiddleCW,rate);
        ldpcMiddleCW = [middleCW; parityBits];

        % LDPC encoding of last CW
        lastCW = scramAllBits(end-parms.LDPLCW+1:end);
        % Generate parity matrix for each data word
        blkLastCW = [lastCW; zeros(LCWD-parms.LDPLCW,1)];
        parityBits = wlan.internal.ldpcEncodeCore(blkLastCW,rate);
        % Create LDPC encoded data by removing zeros
        ldpcLastCW = [lastCW; parityBits];
        y = [ldpcMiddleCW(:); ldpcLastCW(:)];
        
    case 'SC' 
        % LDPC Encoding of data bits
        parms = wlan.internal.dmgSCEncodingInfo(cfgDMG);
        
        % Scramble dummy header, PSDU and padding bits
        % together to ensure scrambler is in correct state for each section
        dummyHeaderBits = zeros(64-7,1,'int8'); % Dummy header bits
        allBits = [dummyHeaderBits; psdu; zeros(parms.NDATA_PAD,1); zeros(parms.NBLK_PAD,1)];
        scramAllBits = wlanScramble(allBits,scramInit);
        
        % Extract data bits and block padding bits from scrambled stream
        scramDataBits = scramAllBits(numel(dummyHeaderBits)+(1:(numel(psdu)+parms.NDATA_PAD)));
        scramBlkPadBits = scramAllBits(end-parms.NBLK_PAD+1:end);

        % Generate parity bits and create LDPC codewords, IEEE Std 802.11-2020
        % Section 20.5.3.2.3.3
        if mcsTable.Repetition==1
            blkCW = reshape(scramDataBits,parms.LCW*mcsTable.Rate,parms.NCW); % Reshape into blocks 
            if isequal(mcsTable.Rate,7/8)
                % Generate parity bits with 13/16 rate
                parityBits = wlan.internal.ldpcEncodeCore(blkCW,13/16);
                ldpcEncodedBits = [blkCW; parityBits(49:end,:)]; % Remove first 48 parity bits
            else
                parityBits = wlan.internal.ldpcEncodeCore(blkCW,mcsTable.Rate);
                ldpcEncodedBits = [blkCW; parityBits];
            end
        else
           LZ = parms.LCW/(2*mcsTable.Repetition);
           blkCW = [reshape(scramDataBits,LZ,parms.NCW); zeros(LZ,parms.NCW)];
           % Generate parity bits with block concatenated with zeros
           parityBits = wlan.internal.ldpcEncodeCore(blkCW,mcsTable.Rate);
           % Scramble the data portion of the code word
           scramBlkCW = coder.nullcopy(zeros(LZ,parms.NCW)); % Preinitialize
           for n = 1:parms.NCW
                scramBlkCW(:,n) = wlanScramble(blkCW(1:LZ,n),ones(7,1));
           end
           ldpcEncodedBits = [blkCW(1:LZ,:); scramBlkCW; parityBits];
        end
        
        % Add padded bits
        y = [ldpcEncodedBits(:); scramBlkPadBits];
      
    otherwise % OFDM
        parms = wlan.internal.dmgOFDMEncodingInfo(cfgDMG);
        
        % Scramble dummy header and PSDU bits together to ensure scrambler is in
        % correct state for PSDU scrambling
        dummyHeaderBits = zeros(64-7,1,'int8'); % Dummy header bits
        allBits = [dummyHeaderBits; psdu; zeros(parms.NPAD,1)];

        % Scramble data portion (with header continuation)
        scramAllBits = wlanScramble(allBits,scramInit);

        % Data Encode
        mcsTable = wlan.internal.getRateTable(cfgDMG);
        LCWD = mcsTable.Rate*parms.LCW; % Block length of LDPC data
        scramDataBits = scramAllBits(numel(dummyHeaderBits)+1:end); % Extract scrambled data bits
        blkCW = reshape(scramDataBits,LCWD,parms.NCW);               % Reshape into blocks 
        parityBits = wlan.internal.ldpcEncodeCore(blkCW,mcsTable.Rate);
        ldpcEncodedBits = [blkCW; parityBits];
        y = ldpcEncodedBits(:);
end
