function dataBits = wlanEHTDataBitRecover(rx,noiseVarEst,varargin)
%wlanEHTDataBitRecover Recover data bits from EHT MU Data field
%   DATABITS = wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,USERIDX)
%   recovers the data bits given the equalized data field OFDM symbols,
%   noise variance and user index for a user in a EHT MU transmission.
%
%   DATABITS is an int8 column vector of length 8*psduLength(CFG)
%   containing the recovered information bits.
%
%   RX is the demodulated EHT-Data field OFDM symbols for a user, specified
%   as a Nsd-by-Nsym-by-Nss matrix of real or complex values, where Nsd is
%   the number of data subcarriers in the EHT-Data field, Nsym is the
%   number of OFDM symbols, and Nss is the number of spatial streams.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CFG is a format configuration object of type wlanEHTMUConfig,
%   wlanEHTTBConfig, or wlanEHTRecoveryConfig.
%
%   USERIDX indicates the user of interest.
%
%   #  For an EHT MU OFDMA and multi-user non-OFDMA PPDU type, USERIDX is
%      the 1-based index of the user to decode within the EHT MU
%      transmission.
%   #  For an EHT MU, single user, non-OFDMA PPDU type, USERIDX is not
%      required.
%   #  For an EHT TB PPDU type USERIDX is not required.
%   #  For wlanEHTRecoveryConfig, USERIDX is not required.
%
%   DATABITS = wlanEHTDataBitRecover(...,CSI,CFG,...) uses the channel
%   state information to enhance the demapping of OFDM subcarriers.
%
%   CSI is a Nsd-by-Nss array of real values.
%
%   DATABITS = wlanEHTDataBitRecover(...,Name,Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'LDPCDecodingMethod'        Specify the LDPC decoding algorithm as one
%                               of these values:
%                               - 'bp'            : Belief propagation (BP)
%                               - 'layered-bp'    : Layered BP
%                               - 'norm-min-sum'  : Normalized min-sum
%                               - 'offset-min-sum': Offset min-sum
%                               The default is 'norm-min-sum'.
%
%   'MinSumScalingFactor'       Specify the scaling factor for normalized
%                               min-sum LDPC decoding algorithm as a scalar
%                               in the interval (0,1]. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'norm-min-sum'. The
%                               default is 0.75.
%
%   'MinSumOffset'              Specify the offset for offset min-sum LDPC
%                               decoding algorithm as a finite real scalar
%                               greater than or equal to 0. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'offset-min-sum'. The
%                               default is 0.5.
%
%   'MaximumLDPCIterationCount' Specify the maximum number of iterations in
%                               LDPC decoding as a positive scalar integer.
%                               The default is 12.
%
%   'EarlyTermination'          To enable early termination of LDPC
%                               decoding, set this property to true. Early
%                               termination applies if all parity-checks
%                               are satisfied before reaching the number of
%                               iterations specified in the
%                               'MaximumLDPCIterationCount' input. To let
%                               the decoding process iterate for the number
%                               of iterations specified in the
%                               'MaximumLDPCIterationCount' input, set this
%                               argument to false. The default is true.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

    narginchk(3,15);
    [nsd,nsym,nss] = size(rx);
    [userIdx,numUsers,ldpcParams,csi,cfg,isEHTMU] = parseInput(nargin,nsd,nss,varargin{:});
    validateattributes(userIdx,{'numeric'},{'integer','scalar','>=',1,'<=',numUsers},mfilename,'user number');

    % Validate input symbols and noise variance estimates
    validateattributes(rx,{'single','double'},{'3d','finite'},mfilename,'EHT-Data equalized symbol(s)');
    validateattributes(noiseVarEst,{'single','double'},{'finite'},mfilename,'noise variance estimate');

    % Validate coding parameters
    validateConfig(cfg,'Coding');

    % Validate MCS-15
    validateConfig(cfg,'EHTMCS15');

    % Get the appropriate RU and user properties
    if isa(cfg,'wlanEHTRecoveryConfig')
        wlan.internal.mustBeDefined(char(cfg.PPDUType),'PPDUType');
        ruSize = cfg.RUSize;
        isEHTDUPMode = cfg.EHTDUPMode;
        % For code generation, to convert wlan.type.RecoveredChannelCoding
        % to a wlan.type.ChannelCoding type, first cast to uint8 then
        % wlan.type.ChannelCoding
        channelCoding = wlan.type.ChannelCoding(uint8(cfg.ChannelCoding));
        numSTS = cfg.NumSpaceTimeStreams;
        if any(cfg.MCS==[14 15])
            DCM = true;
        else
            DCM = false;
        end
        ldpcExtraSymbol = cfg.LDPCExtraSymbol;
        s = validateConfig(cfg);
        nsymCalc = s.NumDataSymbols;
        stbc = false; % No STBC in EHT
        userParams = wlan.internal.heRecoverCodingParameters(nsymCalc,cfg.PreFECPaddingFactor,sum(ruSize),cfg.MCS,numSTS,channelCoding,stbc,DCM,ldpcExtraSymbol,isEHTDUPMode);
    else
        if isEHTMU
            % Validate EHT DUP mode
            validateConfig(cfg,'EHTDUPMode');
            ruIdx = cfg.User{userIdx}.RUNumber;
            channelCoding = cfg.User{userIdx}.ChannelCoding;
            numSTS = cfg.User{userIdx}.NumSpaceTimeStreams;
            ruSize = cfg.RU{ruIdx}.Size;
        else % EHT TB
            allocInfo = ruInfo(cfg);
            ruIdx = 1; % Only one RU/MRU in EHT TB
            channelCoding = cfg.ChannelCoding;
            numSTS = cfg.NumSpaceTimeStreams;
            ruSize = allocInfo.RUSizes{ruIdx};
        end
        % Get coding parameters for the user of interest
        [commonParams,userParams] = wlan.internal.ehtCodingParameters(cfg,userIdx);
        nsymCalc = commonParams.NSYM;
        isEHTDUPMode = cfg.EHTDUPMode;
    end

    if isEHTDUPMode
        % Halve the RU size defined for CBW80, CBW160, and CBW320 for EHT DUP
        % mode (MCS-14). Segment parsing and constellation mapping is performed
        % on bits required for half the RU size for the given channel
        % bandwidth. The remaining half of the RU has symbols generated from
        % frequency domain duplication as defined in Section 36.3.13.10 of IEEE
        % P802.11be/D5.0.
        ruSize = ruSize/2;

        % Average lower and upper subcarriers due to frequency domain
        % duplication in EHT DUP mode.
        halfNumSubcarriers = size(rx,1)/2;
        % Remove scaling by multiplying the upper subcarriers by -1
        upperDataSubcarriers = [rx(1+halfNumSubcarriers:1.5*halfNumSubcarriers,:,:)*-1; rx(1+1.5*halfNumSubcarriers:end,:,:)];
        rxSym = (rx(1:halfNumSubcarriers,:,:)+upperDataSubcarriers)/2; % Average lower and upper subcarriers
                                                                       % Average CSI for lower and upper subcarriers
        csiSym = (csi(1:halfNumSubcarriers,:,:)+csi(halfNumSubcarriers+1:end,:,:))/2;
        % The information is carried in half the data subcarriers for MCS 14
        nsd = nsd/2;
    else % For codegen
        rxSym = rx;
        csiSym = csi;
    end

    expectedNss = numSTS;
    % Test we have a correct number of data subcarriers, corresponding to
    % an RU size, OFDM symbols, and spatial streams
    tac = wlan.internal.heRUToneAllocationConstants(sum(ruSize));
    if any(nsd ~= tac.NSD)
        coder.internal.error('wlan:shared:IncorrectSC',tac.NSD,nsd);
    end
    if any(nsym < nsymCalc)
        coder.internal.error('wlan:shared:IncorrectNumOFDMSym',nsymCalc,nsym);
    end
    nsym = nsymCalc; % Use the required number of symbols
    rxSym = rxSym(:,1:nsym,:); % Extract the minimum input signal length required
    if any(nss ~= expectedNss)
        coder.internal.error('wlan:shared:IncorrectNumSS',expectedNss,nss);
    end

    % Validate size of CSI
    validateattributes(csiSym,{'single','double'},{'real','3d','finite'},mfilename,'CSI');
    if any(size(csiSym) ~= [tac.NSD nss])
        coder.internal.error('wlan:he:InvalidCSISize',tac.NSD,nss);
    end

    % Inverse frequency segment deparsing
    if sum(ruSize)>=1480 % Deparsing is applicable for MRU/RU size >= 996+484
        p = wlan.internal.ehtSegmentParserParameters(ruSize,userParams.NBPSCS,userParams.DCM);
        L = p.L; % Number of 80 MHz frequency segments
        if userParams.DCM
            % Double the number of coded bits per OFDM symbol per spatial stream per segment for DCM
            Ncbpssl = p.Ncbpssl*2;
        else
            Ncbpssl = p.Ncbpssl;
        end
        mappedData = ehtSegmentParseSymbols(rxSym,Ncbpssl/userParams.NBPSCS); % (Nsd/L)-by-Nsym-by-Nss for each 80 MHz frequency segment
        csiParserOut = ehtSegmentParseSymbols(reshape(csiSym,[],1,nss),Ncbpssl/userParams.NBPSCS); % (Nsd/L)-by-1-by-Nss for each 80 MHz frequency segment
        ruSize80MHzSubblock = p.RUSizePer80MHz; % RU/MRU size per 80 MHz segment
    else
        L = 1; % Number of 80 MHz frequency segments
        mappedData = {rxSym};
        csiParserOut = {csiSym};
        ruSize80MHzSubblock = sum(ruSize); % Sum RUs if it is an MRU
    end

    % Inverse LDPC tone mapping (if applicable)
    isBCC = channelCoding==wlan.type.ChannelCoding.bcc;
    if isBCC
        dataSym = mappedData; % [Nsd,Nsym,Nss,L]
        csiToneMapperOut = csiParserOut;
    else % LDPC tone mapping
        dataSym = cell(1,L);
        csiToneMapperOut = cell(1,L);
        for l=1:L
            mappingInd = wlan.internal.ehtLDPCToneMappingIndices(ruSize80MHzSubblock(l),userParams.DCM); % Get LDPC mapping index for an 80 MHz subblock
            dataSym{l} = mappedData{l}(mappingInd,:,:);
            csiToneMapperOut{l} = csiParserOut{l}(mappingInd,:,:);
        end
    end

    if userParams.DCM
        for l=1:L
            % If DCM used then we need to demap (combine) the CSI

            % For all DCM modes we combine (average) the upper and lower halves
            % of the CSI. For NBPSCS = 4 Upper half bits are a permuted version
            % of lower half. Given we only have CSI per symbol then just
            % combine the CSI from upper and lower half on each symbol
            csiToneMapperOut{l} = (csiToneMapperOut{l}(1:end/2,:,:,:)+csiToneMapperOut{l}(end/2+1:end,:,:,:))/2;
        end
    end

    % Apply bit-wise CSI
    interleavedBits = cell(1,L);
    parsedData = cell(1,L);
    for l=1:L
        % Constellation demapping
        interleavedSym = wlan.internal.heConstellationDemap(dataSym{l},noiseVarEst,userParams.NBPSCS,userParams.DCM);
        interleavedBitsScaled = reshape(interleavedSym,userParams.NBPSCS,[],nsym,nss) .* ... % NBPSCS-by-Nsd-by-Nsym-by-Nss
            reshape(csiToneMapperOut{l},1,[],1,nss); % 1-by-Nsd-by-1-by-Nss
        % Reshape to streams
        interleavedBits{l} = reshape(interleavedBitsScaled,[],nsym,nss); % NBPSCS-by-Nsym-by-Nss
        parsedData{l} = cast(0,class(rx)); % For codegen (all elements of the cell array must be initialized before the first use)
    end

    % BCC deinterleaving (if applicable)
    if isBCC
        interleavedBitsBCC = reshape(interleavedBits{1},[],nss,L); % Ncbpssi*Nsym-by-Nss-by-L
                                                                   % BCC interleaving
        assert(L==1); % BCC only valid for RU<=242
        NCBPSSI = userParams.NCBPS/userParams.NSS;
        parsedData{1} = wlan.internal.heBCCDeinterleave(interleavedBitsBCC,ruSize80MHzSubblock,userParams.NBPSCS,NCBPSSI,userParams.DCM,userParams.NCBPSLAST);
    else % LDPC
        parsedData = interleavedBits;
    end

    % Inverse segment parsing
    if sum(ruSize)>=1480 % Parsing is applicable for MRU/RU size >= 996+484
        streamParsedData = wlan.internal.ehtSegmentDeparseBits(parsedData,nsym,nss,userParams.NBPSCS,ruSize,userParams.DCM);
    elseif isBCC && userParams.DCM && any(sum(ruSize)==[106 132 242])
        % On reception, the padded 1 bit per symbol to "make up for NCBPS
        % coded bits" as defined in section 36.3.13.3.5 IEEE
        % P802.11be/D7.0, is removed in heBCCDeinterleave for the special
        % case (MCS 15 with RU size 106, 132, and 242). No reshape is
        % required as this makes the length of parseData a non-integer
        % multiple of NSD-by-NSYM-by-NBPSCS.
        streamParsedData = parsedData{1}(:);
    else
        streamParsedData = reshape(parsedData{1},userParams.NSD*nsym*userParams.NBPSCS,nss);
    end

    % Stream deparse
    Nes = 1; % Only one encoder for 11be
    postFECpaddedData = wlanStreamDeparse(streamParsedData,Nes,userParams.NCBPS,userParams.NBPSCS);

    % Remove post-FEC padding
    encodedData = wlan.internal.heRemovePostFECPadding(postFECpaddedData,channelCoding,userParams);

    % Decode
    if channelCoding==wlan.type.ChannelCoding.bcc
        numTailBits = 6;
        scrambData = wlanBCCDecode(encodedData,userParams.Rate);
    else % LDPC
        numTailBits = 0;
        cfgLDPC = wlan.internal.heLDPCParameters(userParams);
        scrambData = wlan.internal.ldpcDecode(encodedData,cfgLDPC,ldpcParams.LDPCDecodingMethod,ldpcParams.alphaBeta,ldpcParams.MaximumLDPCIterationCount,ldpcParams.Termination);
    end
    scrambData = scrambData(:); % Force column for codegen

    % Derive initial state of the scrambler
    scramInitBits = wlan.internal.ehtScramblerInitialState(scrambData(1:11));

    % Remove pad and tail bits, and descramble
    if all(scramInitBits==0)
        % Scrambler initialization invalid (0), therefore do not descramble
        preFECPaddedData = scrambData;
    else
        % Descramble
        preFECPaddedData = wlan.internal.ehtScramble(scrambData,scramInitBits);
    end

    % Remote service, padding and tail bits
    dataBits = preFECPaddedData((7+9+1):(end-userParams.NPADPreFECPHY-numTailBits));

end

function y = ehtSegmentParseSymbols(x,Ncbpss)
%ehtSegmentParseSymbols Segment parser of data subcarriers.
%
%   Y = ehtSegmentParseSymbols(X) performs the inverse operation of the
%   segment deparsing on the input X defined in IEEE P802.11be/D5.0 Section
%   36.3.13.9.
%
%   Y is an array of size (Nsd/L)-by-Nsym-by-Nss containing the the
%   frequency segments obtained from the inverse operation of segment
%   deparsing of frequency subblocks, L. Nsd is the number of data
%   subcarriers, Nsym is the number of OFDM symbols, Nss is the number of
%   spatial streams, and L is the number of frequency subblocks as defined
%   in IEEE P802.11be/D5.0, Section 36.3.13.4, where
%
%   - L is 2 for 484+996, (242+484)+996, 2x996 RU/MRU
%   - L is 3 for 484+2*996 and 3*996 RU/MRU
%   - L is 4 for 484+3*996 and 4*996 RU/MRU
%
%   X is an array of size Nsd-by-Nsym-by-Nss containing the equalized data
%   to be segmented.

    offfsetNcbpss = cumsum([0 Ncbpss]);
    L = numel(Ncbpss); % Number of frequency subblocks
    y = cell(1,L);
    for i=1:L
        y{i} = x(offfsetNcbpss(i)+(1:Ncbpss(i)),:,:);
    end

end

function [userIdx,numUsers,ldpcParams,csi,cfg,isEHTMU] = parseInput(numInputArg,nsd,nss,varargin)
%parseInput Parse inputs

    csiInputFlag = false; % If no CSI input is present

    if isa(varargin{1},'wlanEHTMUConfig') || isa(varargin{1},'wlanEHTTBConfig') || isa(varargin{1},'wlanEHTRecoveryConfig') % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,...)
        cfg = varargin{1};
        csi = ones(nsd,nss); % If no CSI input is present then assume 1 for processing
    elseif numInputArg>3 && (isa(varargin{2},'wlanEHTMUConfig') || isa(varargin{2},'wlanEHTTBConfig') || isa(varargin{2},'wlanEHTRecoveryConfig')) % wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG,...)
        csi = varargin{1};
        cfg = varargin{2};
        csiInputFlag = true; % CSI input is present
    else
        coder.internal.error('wlan:wlanEHTDataBitRecover:IncorrectDataBitRecoverSyntax');
    end

    isEHTMU = isa(cfg,'wlanEHTMUConfig');

    mode = compressionMode(cfg);
    if any(mode==[0 2]) && isEHTMU % OFDMA or MU-MIMO
        if nargin==3 || (numInputArg==4 && csiInputFlag) % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG)
            coder.internal.error('wlan:shared:ExpectedUserNumber');
        elseif numInputArg>3 && isnumeric(varargin{2}) % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,USERIDX,NV)
            userIdx = varargin{2};
            numArgPreNV = 4;
            ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV-1:end});
        elseif numInputArg>3 && isnumeric(varargin{3}) && csiInputFlag
            userIdx = varargin{3}; % wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG,USERIDX,NV)
            numArgPreNV = 5;
            ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV-1:end});
        else % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,NV), wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG,NV)
            coder.internal.error('wlan:shared:ExpectedUserNumber');
        end
        numUsers = length(cfg.User);
    else % Single user EHT MU packet or EHT Recovery config
        numUsers = 1;
        userIdx = 1;
        if csiInputFlag % wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG,...)
            if numInputArg>4
                if isnumeric(varargin{3}) % wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG,USERIDX,NV)
                    numArgPreNV = 5;
                    ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV-1:end});
                else % wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG,NV)
                    numArgPreNV = 4;
                    ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV-1:end});
                end
            else % wlanEHTDataBitRecover(RX,NOISEVAREST,CSI,CFG)
                ldpcParams = wlan.internal.parseOptionalInputs(mfilename);
            end
        else % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,...)
            if numInputArg>3
                if isnumeric(varargin{2}) % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,USERIDX,NV)
                    numArgPreNV = 4;
                    ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV-1:end});
                else % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG,NV)
                    numArgPreNV = 3;
                    ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV-1:end});
                end
            else % wlanEHTDataBitRecover(RX,NOISEVAREST,CFG)
                ldpcParams = wlan.internal.parseOptionalInputs(mfilename);
            end
        end
    end
end
