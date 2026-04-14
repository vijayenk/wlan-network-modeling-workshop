function [cfg,failInterpretation] = interpretEHTSIGCommonBits(bits,failCRC,cfg,suppressError)
%interpretEHTSIGCommonBits Interpret EHT-SIG common field bits for an EHT MU packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [CFG,FAILINTERPRETATION] = interpretEHTSIGCommonBits(bits,failCRC,cfg)
%   parses and interpret decoded EHT-SIG common bits and returns an updated
%   recovery object with the relevant EHT-SIG fields set. When you use this
%   syntax and the function cannot interpret the recovered EHT-SIG common
%   field bits due to an unexpected value, an exception is issued, and the
%   function does not return an output.
%
%   BITS is an int8 matrix containing the recovered common field bits for
%   each content channel of the EHT-SIG field.
%
%   # For non-OFDMA
%       The EHT-SIG common bit fields are defined in Table 36-36 of IEEE
%       P802.11be/D4.0 for EHT SU and MU-MIMO, and Table 36-37 for NDP.
%       The size of the BITS input depends on the PPDU type:
%
%       * For EHT SU the size is 20-by-1
%       * For NDP the size is 16-by-1
%       * For MU-MIMO the size is 20-by-C
%
%   # For OFDMA
%       The EHT-SIG common bit fields are defined in Table 36-33 of IEEE
%       P802.11be/D4.0. The size of the BITS input depends on the channel
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
%   See Figure 36-31 and Figure 36-32 of IEEE P802.11be/D4.0.
%
%   [...] = interpretEHTSIGCommonBits(...,SUPPRESSERROR) controls the
%   behavior of the function due to an unexpected value of the interpreted
%   EHT-SIG common field bits. SUPPRESSERROR is logical. When SUPPRESSERROR
%   is true and the function cannot interpret the recovered EHT-SIG common
%   field bits due to an unexpected value, the function returns
%   FAILINTERPRETATION as true and cfg is unchanged. When SUPPRESSERROR is
%   false and the function cannot interpret the recovered EHT-SIG common
%   field bits due to an unexpected value, an exception is issued, and the
%   function does not return an output. The default is false.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    arguments
        bits;
        failCRC;
        cfg;
        suppressError = false; % Control the validation of the interpreted EHT-SIG bits
    end
    isOFDMA = cfg.PPDUType==wlan.type.EHTPPDUType.dl_ofdma;
    if isOFDMA
        L = size(failCRC,3); % Number of 80 MHz subblocks
        tempIdx = 1:L;
        validIdx = tempIdx(sum(failCRC,[1 2])==0); % Get the index of all 80 MHz subblocks which pass the CRC
    else
        % All content channels within an 80 MHz subblock contains the same common
        % field information for EHT SU, MU-MIMO and NDP, PPDU type.
        L = numel(failCRC); % Number of 80 MHz subblocks
        tempIdx = 1:L;
        validIdx = tempIdx(failCRC==0); % Get the index of an 80 MHz subblock which pass the CRC
    end

    % OFDMA: If any content channel fails then do not process further
    % non-OFDMA: If all content channel fails then do not process further
    if (isOFDMA && any(failCRC,'all')) || (~isOFDMA && all(failCRC,'all'))
        failInterpretation = true;
        return
    end
    cfgInput = cfg; % Return the input object with no change

    % Common field bits are same across all content channels and subblocks
    commonFieldBits = bits(:,validIdx(1));

    % SpatialReuse
    cfg.SpatialReuse = bit2int(double(commonFieldBits(1:4)),4,false);

    % GI+LTF Size
    GI = bit2int(double(commonFieldBits(5:6)),2,false);
    switch GI
      case 0
        cfg.GuardInterval = 0.8;
        cfg.EHTLTFType = 2;
      case 1
        cfg.GuardInterval = 1.6;
        cfg.EHTLTFType = 2;
      case 2
        cfg.GuardInterval = 0.8;
        cfg.EHTLTFType = 4;
      otherwise % 3
        cfg.GuardInterval = 3.2;
        cfg.EHTLTFType = 4;
    end

    [~,failInterpretation] = validateConfig(cfg,'EHTLTFGI',suppressError);
    if failInterpretation
        failInterpretation = true;
        cfg = cfgInput; % Return the input object with no change
        return
    end

    % Number of EHT-LTF symbols
    numEHTLTFSyms = bit2int(double(commonFieldBits(7:9)),3,false);
    switch numEHTLTFSyms
      case 0
        cfg.NumEHTLTFSymbols = 1;
      case 1
        cfg.NumEHTLTFSymbols = 2;
      case 2
        cfg.NumEHTLTFSymbols = 4;
      case 3
        cfg.NumEHTLTFSymbols = 6;
      case 4
        cfg.NumEHTLTFSymbols = 8;
      otherwise
        % Validate invalid interpretation
        failInterpretation = wlan.internal.failInterpretationIf(numEHTLTFSyms>4,'wlan:interpretEHTSIGCommonBits:InvalidNumEHTLTF',suppressError,numEHTLTFSyms);
        if failInterpretation
            cfg = cfgInput; % Return the input object with no change
            return
        end
    end

    if cfg.PPDUType==wlan.type.EHTPPDUType.ndp
        cfg.NumUsersPerContentChannel = 1; % Set to one user
                                           % NSS
        numSpaceTimeStreams = bit2int(double(commonFieldBits(10:13)),4,false)+1;
        failInterpretation = wlan.internal.failInterpretationIf(numSpaceTimeStreams>8,'wlan:interpretEHTSIGCommonBits:InvalidNumNss',suppressError,numSpaceTimeStreams);
        if failInterpretation
            cfg = cfgInput; % Return the input object with no change
            return
        end
        cfg.NumSpaceTimeStreams = numSpaceTimeStreams;
        cfg.RUTotalSpaceTimeStreams = cfg.NumSpaceTimeStreams; % Equal to NumSpaceTimeStreams due to single RU
        cfg.SpaceTimeStreamStartingIndex = 1; % 1 for NDP
                                              % Beamformed
        cfg.Beamforming = commonFieldBits(14);

        % Set RUSize and RUIndex
        allocInfo = ruInfo(cfg);
        cfg.RUSize = allocInfo.RUSizes{1};
        cfg.RUIndex = allocInfo.RUIndices{1};
        return
    else
        % LDPC Extra Symbols Segment
        cfg.LDPCExtraSymbol = commonFieldBits(10);

        % Pre-FEC Padding Factor
        preFECPaddingFactor = bit2int(double(commonFieldBits(11:12)),2,false);
        switch preFECPaddingFactor
          case 0
            cfg.PreFECPaddingFactor = 4;
          case 1
            cfg.PreFECPaddingFactor = 1;
          case 2
            cfg.PreFECPaddingFactor = 2;
          otherwise % 3
            cfg.PreFECPaddingFactor = 3;
        end

        % PE Disambiguity
        cfg.PEDisambiguity = commonFieldBits(13);
    end

    if cfg.PPDUType==wlan.type.EHTPPDUType.dl_ofdma
        cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
        [N,M,~,numContentChannels] = wlan.internal.ehtSIGNumAllocationSubfields(cbw);
        % Allocation index
        ruAllocation = coder.nullcopy(zeros(round(cbw/40)*9,L,numContentChannels)); % NumAllocationBits-by-NumContentChannels-by-L
        for l=1:L
            ruAllocation(1:9*N,l,:) = bits(17 + (1:9*N),:,l); % Process first encoding block
            ruAllocation(9*N + (1:9*M),l,:) = bits(45 + (1:9*M),:,l); % Process second encoding block
        end

        [~,allocationIndex] = interpretRUAllocationBits(ruAllocation,L,numContentChannels);
        % AllocationIndex must not be disregard or validate
        if any(allocationIndex>303,'all') ... % disregard
                || any(allocationIndex(:)==[31 56:63],'all') % validate
            if suppressError
                failInterpretation = true;
                cfg = cfgInput; % Return the object without any updates
                return
            end
        end

        % Allocation index must be valid for decoded bandwidth
        if cbw<320 % All allocation indices valid for 320
            ruAllocations40 = [29 72:79];
            ruAllocations80 = [30 80:87 96:127];
            ruAllocations160 = [88:95 128:159];
            ruAllocations320 = 160:303;
            switch cbw 
                case 20
                    invalidAllocations = [ruAllocations40 ruAllocations80 ruAllocations160 ruAllocations320];
                case 40
                    invalidAllocations = [ruAllocations80 ruAllocations160 ruAllocations320];
                case 80
                    invalidAllocations = [ruAllocations160 ruAllocations320];
                otherwise % 160
                    invalidAllocations = ruAllocations320;
            end 
            if any(ismember(allocationIndex(:),invalidAllocations)) % Invalid allocation for channel bandwidth
                if suppressError
                    failInterpretation = true;
                    cfg = cfgInput; % Return the object without any updates
                    return
                else
                    % Use custom error as setting cfg.AllocationIndex property
                    % will not throw an error
                    coder.internal.error('wlan:shared:InvalidSignaledAllocationIndex');
                end
            end
        end
        cfg.AllocationIndex = allocationIndex;
        ehtSIGInfo = wlan.internal.ehtSIGCodingInfo(cfg);
        cfg.UsersSignaledInSingleSubblock = ehtSIGInfo.UsersSignaledInSingleSubblock;
        cfg.NumUsersPerContentChannel = ehtSIGInfo.NumUsersPerSegmentPerContentChannel;
    else
        % Number Of Non-OFDMA Users
        cfg.NumNonOFDMAUsers = bit2int(double(commonFieldBits(18:20)),3,false)+1;
        if cfg.PPDUType==wlan.type.EHTPPDUType.su && cfg.NumNonOFDMAUsers>1
            failInterpretation = true;
            cfg = cfgInput; % Return the input object with no change
            return
        end

        s = wlan.internal.ehtSIGCodingInfo(cfg);
        numUsersPerCC = ones(1,numel(s.NumUsersPerSegmentPerContentChannel))*-1;
        numUsersPerCC(validIdx) = s.NumUsersPerSegmentPerContentChannel(validIdx);
        cfg.NumUsersPerContentChannel = numUsersPerCC;
    end

end

function [allocationPerCC,allocationIndex] = interpretRUAllocationBits(ruAllocation,L,numContentChannel)
%interpretRUAllocationBits Interpret RU allocation bits

    tmp = bit2int(ruAllocation(:),9,false);
    allocationPerCC = reshape(tmp,[],numContentChannel).';
    allocationIndex = reshape(allocationPerCC(:),[],L).';
end
