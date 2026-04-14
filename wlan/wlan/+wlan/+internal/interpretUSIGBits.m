function [cfg,failInterpretation] = interpretUSIGBits(usigBits,failCRC,cfg,suppressError)
%interpretUSIGBits Interpret U-SIG bits for EHT MU packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [CFG,FAILINTERPRETATION] = interpretUSIGBits(USIGBITS,FAILCRC,CFG)
%   interpret U-SIG bits into U-SIG fields defined in IEEE P802.11be/D3.0,
%   Table 36-28. When you use this syntax and the function cannot interpret
%   the recovered U-SIG bits due to an unexpected value an exception is
%   issued, and the function does not return an output.
%
%   CFG is the format configuration object of type <a
%   href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>,
%   which specifies the parameters for the recovered EHT MU packet. The
%   function returns the updated CFG after the interpretation of U-SIG
%   bits.
%
%   FAILINTERPRETATION is a logical scalar and represent the result of
%   interpreting the recovered U-SIG field bits. The function return this
%   as true when it cannot interpret the received U-SIG bits.
%
%   USIGBITS are the int8 column vector of size 52-by-L containing the
%   recovered information bits in U-SIG field, where L is the number of 80
%   MHz subblocks:
%   - L is 1 for 20 MHz, 40 MHz and 80 MHz
%   - L is 2 for 160 MHz
%   - L is 4 for 320 MHz
%
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar of
%   size 1-by-L.
%
%   [...,FAILINTERPRETATION] = interpretHEMUSIGABits(...,SUPPRESSERROR)
%   controls the behavior of the function due to an unexpected value of the
%   interpreted U-SIG bits. SUPPRESSERROR is logical. When SUPPRESSERROR
%   is true and the function cannot interpret the recovered U-SIG bits
%   due to an unexpected value, the function returns FAILINTERPRETATION as
%   true and cfg is unchanged. When SUPPRESSERROR is false and the
%   function cannot interpret the recovered U-SIG bits due to an
%   unexpected value, an exception is issued, and the function does not
%   return an output. The default is false.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen
    arguments
        usigBits;
        failCRC;
        cfg;
        suppressError = false; % Control the validation of the interpreted U-SIG bits
    end

    % If all content channel fails then do not process further
    if all(failCRC,2) % For codegen
        failInterpretation = true;
        return;
    end
    cfgInput = cfg;

    % Determine the compression mode as defined in Table 36-29 of IEEE
    % P802.11be/D3.0 Compression mode is determined by processing the U-SIG
    % bits in the first 80 MHz subblock from the subblocks which pass the CRC.
    L = numel(failCRC); % Number of 80 MHz subblocks
    tempIdx = 1:L;
    validIdx = tempIdx(failCRC==0); % Get the index of an 80 MHz subblock which pass the CRC
    subBlkBits = usigBits(:,validIdx(1)); % Get the bits for the first 80 MHz subblock which pass CRC

    % Process bit in the first symbol of U-SIG field for UL/DL indication
    uplinkIndication = subBlkBits(7); % UL/DL indication bit

    % Process bits in the second symbol of U-SIG field for PPDU Type and compression mode indication
    bitsSym2 = subBlkBits(27:end); % Second U-SIG symbol bits
                                   % PPDU Type And Compression Mode
    compressionMode = double(bit2int(bitsSym2(1:2),2,false));
    if suppressError
        if uplinkIndication && any(compressionMode==[0 2 3]) % EHT TB and Validate
            cfg = cfgInput; % Return the input object with no change
            failInterpretation = true;
            return
        else % DL
            if compressionMode==3 % Validate
                cfg = cfgInput; % Return the input object with no change
                failInterpretation = true;
                return
            end
        end
    else
        if uplinkIndication
            failInterpretation = wlan.internal.failInterpretationIf(any(compressionMode==[2 3]),'wlan:interpretUSIGBits:ValidateULPPDUType',suppressError);
            if failInterpretation
                cfg = cfgInput; % Return the input object with no change
                return
            end
            failInterpretation = wlan.internal.failInterpretationIf(compressionMode==0,'wlan:interpretUSIGBits:InvalidFomat',suppressError); % EHT TB
            if failInterpretation
                cfg = cfgInput; % Return the input object with no change
                return
            end
        else % DL
            failInterpretation = wlan.internal.failInterpretationIf(compressionMode==3,'wlan:interpretUSIGBits:ValidateDLPPDUType',suppressError);
            if failInterpretation
                cfg = cfgInput; % Return the input object with no change
                return
            end
        end
    end

    % Process bits in an 80 MHz subblock which has a valid CRC.
    %% U-SIG-1 symbol
    bitsSym1 = subBlkBits(1:26,1); % First symbol bits in U-SIG field

    % PHY Version Identifier
    phyVer = double(bit2int(bitsSym1(1:3),3,false));
    if phyVer~=0
        failInterpretation = wlan.internal.failInterpretationIf(true,'wlan:interpretUSIGBits:ValidatePHYVersionIdentifier',suppressError);
        if failInterpretation
            cfg = cfgInput; % Return the input object with no change
            return
        end
    end

    % Bandwidth
    chanbwNum = double(bit2int(bitsSym1(4:6),3,false));
    switch chanbwNum
      case 0
        chanBW = 'CBW20';
      case 1
        chanBW = 'CBW40';
      case 2
        chanBW = 'CBW80';
      case 3
        chanBW = 'CBW160';
      case 4
        chanBW = 'CBW320';
        cfg.Channelization = 1;
      case 5
        chanBW = 'CBW320';
        cfg.Channelization = 2;
      otherwise % Validate
        failInterpretation = wlan.internal.failInterpretationIf(true,'wlan:interpretUSIGBits:ValidateBandwidth',suppressError);
        if failInterpretation
            cfg = cfgInput; % Return the input object with no change
            return
        end
    end

    % U-SIG field is corrupted, if the interpreted channel bandwidth
    % mismatches with the simulated channel bandwidth set in the recovery
    % object
    failInterpretation = wlan.internal.failInterpretationIf(~strcmp(chanBW,cfgInput.ChannelBandwidth),...
        'wlan:interpretUSIGBits:MisinterpretedBandwidth',suppressError,...
        wlan.internal.cbwStr2Num(chanBW),wlan.internal.cbwStr2Num(cfgInput.ChannelBandwidth));
    if failInterpretation
        cfg = cfgInput; % Return the input object with no change
        return
    end

    cfg.ChannelBandwidth = chanBW;

    % UL/DL
    cfg.UplinkIndication = uplinkIndication;

    % BSS Color
    cfg.BSSColor = double(bit2int(bitsSym1(8:13),6,false));

    % TXOP duration
    txopDuration = double(bit2int(bitsSym1(14:20),7,false));
    % RXVECTOR parameter TXOP_DURATION is computed from the value of the TXOP
    % subfield in U-SIG as defined in Table 36-1 of IEEE P802.11be/D3.0.
    if txopDuration==127
        cfg.TXOPDuration = -1; % Set to unspecified
    elseif rem(txopDuration,2)==0 % Is even
        cfg.TXOPDuration = 8*txopDuration/2;
    else % Is odd
        cfg.TXOPDuration = 512+128*(txopDuration-1)/2;
    end

    % Validate
    failInterpretation = wlan.internal.failInterpretationIf(bitsSym1(26)==0,'wlan:interpretUSIGBits:ValidateBitUSIGSym1',suppressError);
    if failInterpretation
        cfg = cfgInput; % Return the input object with no change
        return
    end

    %% U-SIG-2 symbol
    bitsSym2 = subBlkBits(27:end,1);

    % PPDU Type And Compression Mode
    cfg.CompressionMode = compressionMode;

    % Validate
    failInterpretation = wlan.internal.failInterpretationIf(bitsSym2(3)==0,'wlan:interpretUSIGBits:ValidateBitUSIGSym2',suppressError);
    if failInterpretation
        cfg = cfgInput; % Return the input object with no change
        return
    end

    if compressionMode==0 % Punctured Channel Information (OFDMA)
                          % Only the punctured channel information field has different values
                          % between 80 MHz frequency subblocks in an EHT MU PPDU with
                          % compressionMode equal to 0.
        puncturingPattern = coder.nullcopy(ones(L,4)*-1);
        failInterpretationPerblk = zeros(1,numel(validIdx));
        for l=1:numel(validIdx) % Process valid 80 MHz subblocks
                                % Store failInterpretation for each 80 MHz subblock
            puncturingPattern(validIdx(l),:) = double(usigBits(26+(4:7),validIdx(l))); % Offset by 1st U-SIG symbol bits
            failInterpretationPerblk(l) = wlan.internal.isValidPucturingPattern(puncturingPattern(validIdx(l),:),suppressError,l);
        end
        failInterpretation = all(failInterpretationPerblk);
        if failInterpretation % If all 80 MHz subblock fails interpretation
            cfg = cfgInput; % Return the input object with no change
            return
        end
        % Replace puncturingPattern with -1 for the subblock that has failInterpretation
        if any(failInterpretationPerblk)
            puncturingPattern(validIdx(failInterpretationPerblk==1),:) = repmat(ones(1,4)*-1,numel(tempIdx(failInterpretationPerblk==1)),1);
        end
        cfg.PuncturedPattern = puncturingPattern;
    else % Punctured Channel Information (non-OFDMA)
        puncturedChannelInformation = double(bit2int(bitsSym2(4:8),5,false));
        switch wlan.internal.cbwStr2Num(chanBW)
          case {20 40}
            invalidFieldValue = puncturedChannelInformation~=0; % Field value must be zero for 20/40 MHz
          case 80
            invalidFieldValue = puncturedChannelInformation>4 && puncturedChannelInformation<25; % Field value must be between 0 and 4 (inclusive) for 80 MHz
          case 160
            invalidFieldValue = puncturedChannelInformation>12 && puncturedChannelInformation<25; % Field value must be between 0 and 12 (inclusive) for 160 MHz
          otherwise % 320
            invalidFieldValue = puncturedChannelInformation>24; % Field value must be between 0 and 24 (inclusive) for 320 MHz
        end
        failInterpretation = wlan.internal.failInterpretationIf(invalidFieldValue,'wlan:interpretUSIGBits:InvalidPuncturingFieldVal',suppressError,puncturedChannelInformation);
        if failInterpretation
            cfg = cfgInput; % Return the input object with no change
            return
        end
        cfg.PuncturedChannelFieldValue = puncturedChannelInformation;
    end

    % EHT-SIG MCS
    ehtSIGMCS = double(bit2int(bitsSym2(10:11),2,false));
    switch ehtSIGMCS
      case 0
        cfg.EHTSIGMCS = 0;
      case 1
        cfg.EHTSIGMCS = 1;
      case 2
        cfg.EHTSIGMCS = 3;
      otherwise % MCS 15
        cfg.EHTSIGMCS = 15;
    end

    % Number of EHT-SIG symbols
    cfg.NumEHTSIGSymbolsSignaled = double(bit2int(double(bitsSym2(12:16)),5,false))+1;
end
