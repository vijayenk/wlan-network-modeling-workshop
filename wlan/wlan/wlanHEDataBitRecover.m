function dataBits = wlanHEDataBitRecover(rx,noiseVarEst,varargin)
%wlanHEDataBitRecover Recover data bits from HE Data field
%   DATABITS = wlanHEDataBitRecover(RX,NOISEVAREST,CFGSU) recovers the data
%   bits given the Data field from a HE single user transmission, the noise
%   variance estimate, and the single user HE configuration object.
%
%   DATABITS is an int8 column vector of length 8*getPSDULength(CFGSU)
%   containing the recovered information bits.
%
%   RX is the demodulated HE-Data field OFDM symbols for a user, specified
%   as a Nsd-by-Nsym-by-Nss matrix of real or complex values, where Nsd is
%   the number of data subcarriers in the HE-Data field, Nsym is the number
%   of OFDM symbols, and Nss is the number of spatial streams.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CFGSU is the format configuration object of type wlanHESUConfig, or
%   wlanHETBConfig, which specifies the parameters for the single user and
%   trigger-based HE formats respectively.
%
%   DATABITS = wlanHEDataBitRecover(RX,NOISEVAREST,CFGMU,USERIDX)
%   recovers the data bits given the Data field from a HE multi user
%   transmission, the noise variance estimate, the multi-user HE
%   configuration object, and user index.
%
%   CFGMU is the format configuration object of type wlanHEMUConfig, which
%   specifies the parameters for the multi user HE format.
%
%   USERIDX is the 1-based index of the user to decode within the
%   transmission. USERIDX is used to index the appropriate user
%   configuration object in CFGMU.
%
%   DATABITS = wlanHEDataBitRecover(RX,NOISEVAREST,CFGRX) recovers the data
%   bits given the Data field from an HE-SU, HE-EXT-SU and HE-MU
%   transmission, the noise variance estimate, and the recovery
%   configuration object.
%
%   CFGRX is the format configuration object of type wlanHERecoveryConfig,
%   which specifies the parameters for HE-SU, HE-EXT-SU and HE-MU
%   transmission.
%
%   DATABITS = wlanHEDataBitRecover(...,CSI,CFG,...) uses the channel state
%   information to enhance the demapping of OFDM subcarriers.
%
%   CSI is a Nsd-by-Nss array of real values.
%
%   CFG is the format configuration object of type wlanHESUConfig,
%   wlanHEMUConfig, wlanHETBConfig, or wlanHERecoveryConfig which specifies
%   the transmission parameters. When CFG is a wlanHEMUConfig object the
%   user index must be provided as the argument after CFG.
%
%   DATABITS = wlanHEDataBitRecover(...,Name,Value) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'LDPCDecodingMethod'        Specify the LDPC decoding algorithm as one
%                               of these values:
%                               - 'bp'            : Belief propagation (BP)
%                               - 'layered-bp'    : Layered BP
%                               - 'norm-min-sum'  : Normalized min-sum
%                               - 'offset-min-sum': Offset min-sum
%                               The default is 'bp'.
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

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

    narginchk(3,15);
    [nsd,nsym,nss] = size(rx);

    % Default
    userIdx = 1;
    if isa(varargin{1},'wlanHESUConfig') || isa(varargin{1},'wlanHETBConfig')
        % wlanHEDataBitRecover(RX,NOISEVAREST,CFGSU)
        narginchk(3,13);
        % If no CSI input is present then assume 1 for processing
        csi = ones(nsd,nss);
        cfg = varargin{1};
        numArgPreNV = 1;
    elseif isa(varargin{1},'wlanHEMUConfig')
        % wlanHEDataBitRecover(RX,NOISEVAREST,CFGMU,USERIDX)
        narginchk(4,14);
        cfg = varargin{1};
        % If no CSI input is present then assume 1 for processing
        csi = ones(nsd,nss);
        userIdx = varargin{2};
        numArgPreNV = 2;
    elseif isa(varargin{1},'wlanHERecoveryConfig')
        % wlanHEDataBitRecover(RX,NOISEVAREST,CFGRX)
        narginchk(3,13);
        % If no CSI input is present then assume 1 for processing
        csi = ones(nsd,nss);
        cfg = varargin{1};
        numArgPreNV = 1;
    elseif nargin>3 && (isa(varargin{2},'wlanHEMUConfig') || isa(varargin{2},'wlanHESUConfig') || isa(varargin{2},'wlanHETBConfig') || isa(varargin{2},'wlanHERecoveryConfig'))
        % wlanHEDataBitRecover(RX,NOISEVAREST,CSI,CFG,...)
        csi = varargin{1};
        cfg = varargin{2};
        if isa(cfg,'wlanHESUConfig') || isa(cfg,'wlanHETBConfig') || isa(cfg,'wlanHERecoveryConfig')
            narginchk(4,14);
            numArgPreNV = 2;
        else
            narginchk(5,15);
            userIdx = varargin{3};
            numArgPreNV = 3;
        end
    else
        coder.internal.error('wlan:wlanHEDataBitRecover:IncorrectDataBitRecoverSyntax');
    end

    % Validate the format configuration object is a valid type
    validateattributes(cfg,{'wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig'},{'scalar'},mfilename,'format configuration object');

    % Validate symbols
    validateattributes(rx,{'single','double'},{'3d'},mfilename,'HE-Data equalized symbol(s)');

    % Validate and parse N-V pair optional inputs
    coder.internal.errorIf((length(varargin)-numArgPreNV)==1,'wlan:shared:InvalidNumOptionalInputs');
    ldpcParams = wlan.internal.parseOptionalInputs(mfilename,varargin{numArgPreNV+1:end});

    % Validate coding parameters in configuration object
    validateConfig(cfg,'Coding');

    % Get the appropriate RU and user info
    stbc = cfg.STBC;
    if isa(cfg,'wlanHERecoveryConfig')
        % Validate HighDoppler and NumSpaceTimeStreams
        validateConfig(cfg,'HighDoppler');
        if ~strcmp(cfg.PacketFormat,'HE-MU')
            % Validate DCM, STBC, GuardInterval and HELTFType for HE-SU and HE-EXT-SU
            validateConfig(cfg,'HELTFGIHESU');
        end
        ruSize = cfg.RUSize;
        dcm = cfg.DCM;
        channelCoding = cfg.ChannelCoding;
        numSTS = cfg.NumSpaceTimeStreams;

        s = validateConfig(cfg);
        nsymCalc = s.NumDataSymbols;
        userParams = wlan.internal.heRecoverCodingParameters( ...
            nsymCalc,cfg.PreFECPaddingFactor,ruSize,cfg.MCS,nss,cfg.ChannelCoding,cfg.STBC,cfg.DCM,cfg.LDPCExtraSymbol);
    else
        if isa(cfg,'wlanHESUConfig') || isa(cfg,'wlanHETBConfig')
            % SU
            % Get allocation information
            allocInfo = ruInfo(cfg);
            ruIdx = 1; % Only one RU for single user
            dcm = cfg.DCM;
            channelCoding = cfg.ChannelCoding;
            numSTS = cfg.NumSpaceTimeStreams;
            ruSize = allocInfo.RUSizes(ruIdx);
        else % MU
             % Get allocation information
            allocInfo = ruInfo(cfg);

            % Validate user index
            coder.internal.errorIf(userIdx>allocInfo.NumUsers,'wlan:shared:InvalidUserIdx',userIdx,allocInfo.NumUsers);
            ruIdx = cfg.User{userIdx}.RUNumber;

            dcm = cfg.User{userIdx}.DCM;
            channelCoding = cfg.User{userIdx}.ChannelCoding;
            numSTS = cfg.User{userIdx}.NumSpaceTimeStreams;
            ruSize = allocInfo.RUSizes(ruIdx);
        end
        % Get coding parameters for the user of interest
        [commonParams,userParams] = wlan.internal.heCodingParameters(cfg,userIdx);
        nsymCalc = commonParams.NSYM;
    end

    expectedNss = numSTS/(2*stbc+1*~stbc);
    % Test we have a correct number of data subcarriers, corresponding to
    % an RU size, OFDM symbols, and spatial streams
    tac = wlan.internal.heRUToneAllocationConstants(ruSize);
    if any(nsd ~= tac.NSD)
        coder.internal.error('wlan:shared:IncorrectSC',tac.NSD,nsd);
    end
    if any(nsym < nsymCalc)
        coder.internal.error('wlan:shared:IncorrectNumOFDMSym',nsymCalc,nsym);
    end
    nsym = nsymCalc; % Use the required number of symbols
    rx = rx(:,1:nsym,:); % Extract the minimum input signal length required
    if any(nss ~= expectedNss)
        coder.internal.error('wlan:shared:IncorrectNumSS',expectedNss,nss);
    end

    % Validate size of CSI
    validateattributes(csi,{'single','double'},{'real','3d','finite'},mfilename,'CSI');
    if any(size(csi) ~= [tac.NSD nss])
        coder.internal.error('wlan:he:InvalidCSISize',tac.NSD,nss);
    end

    % Inverse frequency segment deparsing
    if ruSize==2*996 % NOT 80+80
        mappedData = wlan.internal.segmentParseSymbolsCore(rx); % [Nsd,Nsym,Nss,Nseg]
        csiParserOut = wlan.internal.segmentParseSymbolsCore(reshape(csi,[],1,nss)); % [Nsd/Nseg 1 Nss Nseg]
        nseg = 2;
    else
        mappedData = rx;
        csiParserOut = csi;
        nseg = 1; % EXCEPT for 80+80
    end

    % Inverse LDPC tone mapping (if applicable)
    if strcmp(channelCoding,'BCC')
        dataSym = mappedData; % [Nsd,Nsym,Nss,Nseg]
        csiToneMapperOut = csiParserOut;
    else % LDPC
         % LDPC tone mapping
        mappingInd = wlan.internal.heLDPCToneMappingIndices(ruSize,dcm);
        dataSym = mappedData(mappingInd,:,:,:);
        csiToneMapperOut = csiParserOut(mappingInd,:,:,:);
    end

    % Constellation demapping
    interleavedSym = wlan.internal.heConstellationDemap(dataSym,noiseVarEst,userParams.NBPSCS,dcm);

    if dcm
        % If DCM used then we need to demap (combine) the CSI

        % For all DCM modes we combine (average) the upper and lower halves
        % of the CSI.
        % For NBPSCS = 4 Upper half bits are a permuted version of lower
        % half. Given we only have CSI per symbol then just combine the CSI
        % from upper and lower half on each symbol
        csiToneMapperOut = (csiToneMapperOut(1:end/2,:,:,:)+csiToneMapperOut(end/2+1:end,:,:,:))/2;
    end

    % Apply bit-wise CSI
    interleavedBitsScaled = reshape(interleavedSym, userParams.NBPSCS,[],nsym,nss,nseg) .* ...
        reshape(csiToneMapperOut,1,[],1,nss,nseg); % [(Ncbpssi*Nsym),Nss,Nseg]

    % Reshape to streams
    interleavedBits = reshape(interleavedBitsScaled,[],nss,nseg); % [(Ncbpssi*Nsym),Nss,Nseg]

    % BCC deinterleaving (if applicable)
    if strcmp(channelCoding,'BCC')
        % BCC interleaving
        numSeg = 1; % BCC only valid for RU<=242 therefore 1 segment (IEEE Std 802.11ax-2021, Section 27.1.1)
        NCBPSSI = userParams.NCBPS/userParams.NSS/numSeg;
        parsedData = wlan.internal.heBCCDeinterleave(interleavedBits,ruSize,userParams.NBPSCS,NCBPSSI,dcm,userParams.NCBPSLAST);
    else % LDPC
        parsedData = interleavedBits;
    end

    % Inverse segment parsing
    if ruSize==2*996
        new = 1; % Only 1 encoder stream in 11ax
        streamParsedData = wlan.internal.segmentDeparseBitsCore(parsedData,new,userParams.NCBPS,userParams.NBPSCS);
    else
        streamParsedData = parsedData(:,:,1); % Index for codegen
    end

    % Stream deparse
    Nes = 1; % Only one encoder for 11ax
    postFECpaddedData = wlanStreamDeparse(streamParsedData,Nes,userParams.NCBPS,userParams.NBPSCS);

    % Remove post-EC padding
    encodedData = wlan.internal.heRemovePostFECPadding(postFECpaddedData,channelCoding,userParams);

    % Decode
    if strcmp(channelCoding,'BCC')
        numTailBits = 6;
        scrambData = wlanBCCDecode(encodedData,userParams.Rate);
    else % LDPC
        numTailBits = 0;
        cfgLDPC = wlan.internal.heLDPCParameters(userParams);
        scrambData = wlan.internal.ldpcDecode(encodedData,cfgLDPC, ...
                                                  ldpcParams.LDPCDecodingMethod,ldpcParams.alphaBeta,ldpcParams.MaximumLDPCIterationCount,ldpcParams.Termination);
    end
    scrambData = scrambData(:); % Force column for codegen

    % Derive initial state of the scrambler
    scramInitBits = wlan.internal.scramblerInitialState(scrambData(1:7));

    % Remove pad and tail bits, and descramble
    if all(scramInitBits==0)
        % Scrambler initialization invalid (0), therefore do not descramble
        preFECPaddedData = scrambData;
    else
        % Descramble
        preFECPaddedData = wlanScramble(scrambData,scramInitBits);
    end

    % Remote service, padding and tail bits
    dataBits = preFECPaddedData((7+9+1):(end-userParams.NPADPreFECPHY-numTailBits));

end
