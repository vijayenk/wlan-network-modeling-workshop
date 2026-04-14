function [bits,failCRC,cfg] = wlanEHTSIGCommonBitRecover(x,nVar,varargin)
%wlanEHTSIGCommonBitRecover Recover information bits from EHT SIG field
%
%   [BITS,FAILCRC,CFG] = wlanEHTSIGCommonBitRecover(X,NVAR,CFG) recovers
%   the EHT-SIG common field bits given the demodulated EHT-SIG field from
%   an EHT MU transmission, a noise variance estimate, and an EHT
%   configuration object of type wlanEHTRecoveryConfig. When you use this
%   syntax and the function cannot interpret the recovered EHT-SIG common
%   field bits due to an unexpected value, an exception is issued, and the
%   function does not return an output.
%
%   BITS is a binary, int8 matrix containing the recovered common field
%   bits for each content channel of the EHT-SIG field.
%
%   # For non-OFDMA
%       The EHT-SIG common bit fields are defined in Table 36-36 of IEEE
%       P802.11be/D5.0 for EHT SU and MU-MIMO, and Table 36-37 for NDP.
%       The size of the BITS input depends on the PPDU type:
%
%       * For EHT SU the size is 20-by-1
%       * For NDP the size is 16-by-1
%       * For MU-MIMO the size is 20-by-C
%
%   # For OFDMA
%       The EHT-SIG common bit fields are defined in Table 36-33 of IEEE
%       P802.11be/D5.0. The size of the BITS input depends on the channel
%       bandwidth:
%
%       * For CBW20 and CBW40 the size is 36-by-C
%       * For CBW80 the size is 45-by-C
%       * For CBW160 the size is 73-by-C-by-L
%       * For CBW320 the size is 109-by-C-by-L
%
%   Where C is the number of content channels. It is 1 for 20 MHz and 2 for
%   all other bandwidths. L is the number of 80 MHz subblocks:
%       * L is 1 for 20 MHz, 40 MHz and 80 MHz
%       * L is 2 for 160 MHz
%       * L is 4 for 320 MHz
%
%   FAILCRC represents the result of the CRC for each common encoding block
%   and content channel. True represents a CRC failure. FAILCRC is an array
%   of size X-by-C-by-L. Where X is the number of EHT-SIG common encoding
%   blocks. X is 1 for non-OFDMA configurations. For OFDMA configurations X
%   is 1 for 20 MHz, 40 MHz, and 80 MHz, and 2 for all other bandwidths.
%   See Figure 36-31 and Figure 36-32 of IEEE P802.11be/D5.0.
%
%   CFG is an updated format configuration object of type wlanEHTRecoveryConfig
%   after EHT-SIG common field decoding.
%
%   [BITS,FAILCRC] = wlanEHTSIGCommonBitRecover(...), when you use this
%   syntax and the function cannot interpret the recovered EHT-SIG common
%   field bits due to an unexpected value, no exception is issued.
%
%   X is a vector containing the complex demodulated and equalized EHT-SIG
%   common field symbols. It is of size Nsd-by-Nsym, where Nsd is the
%   number of data subcarriers in EHT-SIG field. Nsym is the number of
%   EHT-SIG field symbols. The size of X depends on the PPDU type and
%   channel bandwidth:
%
%   # For non-OFDMA
%       For bandwidth greater than 40 MHz, X contains the combined 20-MHz
%       subchannel repetitions.
%
%       * For CBW20 Nsd is 52
%       * For CBW40, CBW80, CBW160, and CBW320. Nsd is 104
%
%   # For OFDMA
%       For bandwidths greater than 80 MHz, X contains the combined contents
%       channels within each 80 MHz subblock
%       * For CBW20 Nsd is 52
%       * For CBW40 and CBW80 Nsd is 104
%       * For CBW160 Nsd is 208
%       * For CBW320 Nsd is 416
%
%   NVAR is the noise variance estimate, specified as a real nonnegative
%   scalar.
%
%   CFG is a format configuration object of type wlanEHTRecoveryConfig
%   that specifies the parameters for the EHT MU format.
%
%   [...] = wlanEHTSIGCommonBitRecover(...,CSI,CFG) uses the channel state
%   information to enhance the demapping of OFDM subcarriers. The CSI input
%   is an Nsd-by-1 column vector of real values, where Nsd is the number of
%   data subcarriers in the EHT-SIG field.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    narginchk(3,4);
    updateConfig = nargout==3; % Validate the interpreted bit values
    validateattributes(x,{'single','double'},{'2d','finite'},mfilename,'x');
    [nsd,nSym] = size(x);

    if isa(varargin{1},'wlanEHTRecoveryConfig')
        % wlanEHTSIGCommonBitRecover(RX,NVAR,CFG)
        csi = ones(nsd,1);
        cfg = varargin{1};
    elseif nargin>3 && isa(varargin{2},'wlanEHTRecoveryConfig')
        % wlanEHTSIGCommonBitRecover(RX,NVAR,CSI,CFG)
        csi = varargin{1};
        cfg = varargin{2};
    else
        coder.internal.error('wlan:eht:InvalidConfigType');
    end

    % Validate channel bandwidth
    chanBW = wlan.internal.validateParam('EHTCHANBW',cfg.ChannelBandwidth,mfilename);
    cbw = wlan.internal.cbwStr2Num(chanBW);
    validateConfig(cfg,'EHTSIG');
    coder.internal.errorIf(nSym~=cfg.NumEHTSIGSymbolsSignaled,'wlan:eht:InvalidNumEHTSIGSyms',nSym,cfg.NumEHTSIGSymbolsSignaled);

    L = wlan.internal.ehtNumSubblocks(cfg.PPDUType,cbw); % Number of 80 MHz subblocks
    coder.internal.errorIf(any(size(csi)~=[nsd 1]),'wlan:he:InvalidCSISize',nsd,1);
    params = wlan.internal.ehtSIGRateTable(cfg.EHTSIGMCS);
    mode = cfg.compressionMode;
    isNDP = cfg.PPDUType==wlan.type.EHTPPDUType.ndp;
    c = wlan.internal.ehtSIGCommonFieldInfo(cbw,mode,params.NDBPS,isNDP);
    [N,M,NumEncBlks] = wlan.internal.ehtSIGNumAllocationSubfields(cbw);
    Nsc = 52; % Number of subcarrier in a single content channel
    Nsb = nsd/L; % Number of subcarriers per 80 MHz subblocks
    expectedNumSC = Nsc*c.NumContentChannels*L;
    coder.internal.errorIf(nsd~=expectedNumSC,'wlan:he:InvalidRowLength',expectedNumSC);
    u = wlan.internal.ehtSIGUserFieldInfo;
    if isNDP
        bits = coder.nullcopy(zeros(c.NumCommonFieldBits-u.NumCRCBits-u.NumTailBits,c.NumContentChannels,L,'int8')); % NumBits-by-NumContentChannels-by-1
    else
        bits = coder.nullcopy(zeros(c.NumCommonFieldBits,c.NumContentChannels,L,'int8')); % NumBits-by-NumContentChannels-by-L
    end

    isOFDMA = cfg.PPDUType==wlan.type.EHTPPDUType.dl_ofdma;

    if isOFDMA
        failCRC = coder.nullcopy(false(NumEncBlks,c.NumContentChannels,L)); % NumEncBlks-by-NumContentChannels-by-L
    else
        failCRC = coder.nullcopy(false(1,c.NumContentChannels)); % 1-by-NumContentChannels
    end

    % Decode common encoding block per content channel per 80 MHz subblock
    for l=1:L % Process each 80 MHz subblock
        for cch = 1:c.NumContentChannels % Process each content channel
            subBlkIndex = (1:Nsc) + Nsc*(cch-1) + Nsb*(l-1); % Index of an 80 MHz subblock
            decodeBits = wlan.internal.heSIGBDecode(x(subBlkIndex,:),csi(subBlkIndex,1),nVar,params,cfg.EHTSIGMCS);

            commonBits = decodeBits(1:c.NumCommonFieldBits); % Common field bits
            if isNDP
                ndpBits = c.NumCommonFieldBits-u.NumCRCBits-u.NumTailBits; % Common field bits less CRC and Tail
                checksum = wlan.internal.crcGenerate(commonBits(1:ndpBits));
                failCRC(1,cch) = any(checksum(1:4)~=commonBits(ndpBits + (1:u.NumCRCBits),:));
                commonBits = commonBits(1:ndpBits);
            elseif isOFDMA
                % First common encoding block
                firstCommonEncodingBlkBits = commonBits(1:17 + 9*N); % First common encoding block bits
                checksum = wlan.internal.crcGenerate(firstCommonEncodingBlkBits);
                failCRC(1,cch,l) = any(checksum(1:4)~=commonBits(17 + 9*N + (1:4))); % First common encoding block CRC bits
                if any(cbw==[160 320])
                    % Second common encoding block
                    secondCommonEncodingBlkBits = commonBits(17 + 9*N + 10 + (1:M*9)); % Second common encoding block bits
                    checksum = wlan.internal.crcGenerate(secondCommonEncodingBlkBits);
                    failCRC(2,cch,l) = any(checksum(1:4)~=commonBits(17 + 9*N + 10 + M*9 + (1:4))); % Second common encoding block CRC bits
                end
            else % EHT SU, DL-MUMIMO
                firstUserBits = decodeBits(c.NumCommonFieldBits+(1:u.NumUserFieldBits + u.NumCRCBits + u.NumTailBits)); % First user bits
                                                                                                                        % Check CRC over common encoding block (U-SIG overflow + first user field)
                checksum = wlan.internal.crcGenerate([commonBits; firstUserBits(1:u.NumUserFieldBits,:)]);
                failCRC(l,cch) = any(checksum(1:4)~=firstUserBits(u.NumUserFieldBits + (1:u.NumCRCBits),:));
            end
            bits(:,cch,l) = commonBits;
        end
    end

    % OFDMA: If any content channel fails then do not process further
    % non-OFDMA: If all content channel fails then do not process further
    if (isOFDMA && any(failCRC,'all')) || (~isOFDMA && all(failCRC,'all'))
        return
    end

    % Process all users
    if updateConfig
        cfg = wlan.internal.interpretEHTSIGCommonBits(bits,failCRC,cfg);
    end

end
