function [bits,codingInfo] = ehtSIGBits(cfgEHT)
%ehtSIGBits EHT-SIG Field Bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,CODINGINFO] = ehtSIGBits(CFGEHT) generates the EHT-SIG field bits
%   and a structure containing EHT-SIG info.
%
%   BITS are the EHT-SIG signaling bits. For OFDMA it is of type int8,
%   binary matrix of size NDBPS*NumSym-by-C-by-L, where NDBPS is the number
%   of data bits per symbols, NumSym is the number of EHT-SIG symbols. C is
%   the number of content channel. C is one for 20 MHz and two for 40 MHz,
%   80 MHz, 160 MHz, and 320 MHz channel bandwidth. L is the number of 80
%   MHz segments and is one for 20 MHz, 40 MHz, and 80 MHz. L is two and
%   four for 160 MHz and 320 MHz respectively.
%
%   For multi-user non-OFDMA the number of BITS is a binary matrix of size
%   NDBPS*NumSym-by-C. For single-user non-OFDMA and NDP the binary matrix
%   is of size NDBPS*NumSym-by-1.
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a>.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

numUsers = numel(cfgEHT.User);
numRUs = numel(cfgEHT.RU);
[codingInfo,usersInSegments] = wlan.internal.ehtSIGCodingInfo(cfgEHT);
commonFieldBits = ehtSIGCommonFieldBits(cfgEHT,codingInfo);

Nsym = codingInfo.NumSIGSymbols; % Number of EHT-SIG symbols
L = codingInfo.NumSegments; % Number of segments
C = codingInfo.NumContentChannels; % Number of content channels

% Pre-allocation of variables
spatialConfigBitsAllUsers = coder.nullcopy(zeros(6,numUsers));
ruSpatialConfigBits = coder.nullcopy(zeros(6,numRUs));
% Get the spatial-configuration bits per RU
for i=1:numRUs
    % Get the number of space-time streams per user in an RU
    userNumbers = cfgEHT.RU{i}.UserNumbers;
    numSTSPerUser = zeros(numel(userNumbers),1);
    for j=1:numel(userNumbers)
        numSTSPerUser(j) = cfgEHT.User{userNumbers(j)}.NumSpaceTimeStreams;
    end
    % The spatial configuration subfield for each user is based on all
    % users in an RU, therefore determine the bits for the RU
    ruSpatialConfigBits(:,i) = wlan.internal.ehtSpatialConfigurationBits(numSTSPerUser);
end

% Get the spatial-configuration bits and multi-user (MU) indication per user
muRU = false(1,numUsers);
for j=1:numUsers
    ruIdx = cfgEHT.User{j}.RUNumber;
    % For each user determine whether it is part of a MU-MIMO
    % allocation, by determining the number of users per RU
    muRU(j) = numel(cfgEHT.RU{ruIdx}.UserNumbers)>1;
    % Store the spatial configuration bits for the user
    spatialConfigBitsAllUsers(:,j) = ruSpatialConfigBits(:,ruIdx);
end

% Pre-allocation of variables
STAID = coder.nullcopy(zeros(1,numUsers));
MCS = coder.nullcopy(zeros(1,numUsers));
isChannelCodingLDPC = coder.nullcopy(false(1,numUsers));
userBeamforming = coder.nullcopy(false(1,numUsers));
customSpatialMappingPerUser = coder.nullcopy(false(1,numUsers));
for userIdx=1:numUsers
    STAID(userIdx) = cfgEHT.User{userIdx}.STAID;
    MCS(userIdx) = cfgEHT.User{userIdx}.MCS;
    userBeamforming(userIdx) = cfgEHT.RU{cfgEHT.User{userIdx}.RUNumber}.Beamforming;
    isChannelCodingLDPC(userIdx) = cfgEHT.User{userIdx}.ChannelCoding==wlan.type.ChannelCoding.ldpc;
    customSpatialMappingPerUser(userIdx) = cfgEHT.RU{cfgEHT.User{userIdx}.RUNumber}.SpatialMapping==wlan.type.SpatialMapping.custom;
end

% Pre-allocation of variables for EHT-SIG bits
bits = zeros(codingInfo.NumSIGSymbols*codingInfo.NDBPS,C,L,'int8');

if codingInfo.IsNDP % NDP
    bits = commonFieldBits;
else % non-OFDMA, OFDMA
    for l=1:L % Number of segments
        for c=1:C % Number of content channels
            contentCh = usersInSegments{l,c}; % Users per segment per content channel
            % Get user specific field bits for each single allocation
            numUsersInContentChannel = codingInfo.NumUsersPerSegmentPerContentChannel(l,c);
            userBlockBits = zeros(22,numUsersInContentChannel,'int8');
            numUserIdx = 1;
            spatialConfigBitsContentChannel = spatialConfigBitsAllUsers(:,contentCh);
            isMUContentChannel = muRU(contentCh);
            for k = 1:numUsersInContentChannel
                userIdx = contentCh(k);
                % Set the beamforming bit if spatial mapping is not direct
                if customSpatialMappingPerUser(userIdx)
                    txBeamforming = userBeamforming(userIdx);
                else
                    txBeamforming = false;
                end
                spatialConfigBitsUser = spatialConfigBitsContentChannel(:,k);
                isMU = isMUContentChannel(k);

                % Get the bits for a user
                userBlockBits(:,numUserIdx) = ehtSIGUserFieldBits(STAID(userIdx),MCS(userIdx),spatialConfigBitsUser,txBeamforming,isChannelCodingLDPC(userIdx),isMU);
                numUserIdx = numUserIdx+1;
            end
            % Reshape user block bits into pairs of users, excluding the last, odd numbered user if necessary
            userBits = userBlockBits(:,1:numUsersInContentChannel);
            if codingInfo.CompressionMode==0 % OFDMA
                if numUsersInContentChannel == 1
                    numPairs = 1;
                    pairs = userBits;
                    leftover = zeros(0,1,'int8');
                elseif numUsersInContentChannel == 0
                    numPairs = 0;
                    pairs = zeros(22*2,0,'int8');
                    leftover = zeros(size(userBits,1),0,'int8');
                else
                    numPairs = floor(numUsersInContentChannel/2);
                    pairs = reshape(userBits(:,1:numPairs*2),22*2,[]);
                    leftover = userBits(:,numPairs*2+1:end);
                end
                commonBits = commonFieldBits(:,c,l);
            else % SU or MU-MIMO
                if numUsersInContentChannel==1
                    firstUserBits = userBits;
                    crc = wlan.internal.crcGenerate([commonFieldBits(:,c,l); firstUserBits]);
                    commonBits = [commonFieldBits(:,c,l); firstUserBits; crc(1:4,:); zeros(6,1,'int8')];
                    numPairs = 0;
                    pairs = zeros(0,1,'int8');
                    leftover = zeros(0,1,'int8');
                else
                    firstUserBits = userBits(:,1);
                    crc = wlan.internal.crcGenerate([commonFieldBits(:,c,l); firstUserBits]);
                    commonBits = [commonFieldBits(:,c,l); firstUserBits; crc(1:4,:); zeros(6,1,'int8')];
                    numPairs = floor((numUsersInContentChannel-1)/2);
                    if coder.target('MATLAB') % Code for MATLAB evaluation
                        pairs = reshape(userBits(:,(1:numPairs*2)+1),22*2,[]);
                    else
                        if numPairs==0 % For codegen
                            pairs = zeros(1,0,'int8');
                        else
                            pairs = reshape(userBits(:,(1:numPairs*2)+1),22*2,[]);
                        end
                    end
                    leftover = userBits(:,numPairs*2+2:end);
                end
            end

            userCRCBitsAll = zeros(8,numPairs,'int8');
            for k = 1:numPairs
                userCRCBitsAll(:,k) = wlan.internal.crcGenerate(pairs(:,k));
            end
            tailBits = zeros(6,numPairs,'int8'); % Calculate Tail bits per pair
            pairsCRCTail = [pairs; userCRCBitsAll(1:4,:); tailBits];

            if ~isempty(leftover)
                % Add CRC and tail bits to leftover user
                crcBits = wlan.internal.crcGenerate(leftover);
                tailBits = zeros(6,1,'int8');
                leftoverCRCTail = [leftover; crcBits(1:4,:); tailBits];
                allUserBits = [pairsCRCTail(:); leftoverCRCTail];
            else
                allUserBits = pairsCRCTail(:);
            end

            % Pad to a whole number of OFDM symbols
            LENGTH = numel(allUserBits) + length(commonBits);
            NDATA = Nsym*codingInfo.NDBPS;
            NPAD = NDATA-LENGTH;
            allUserBitsPadded = [allUserBits; zeros(NPAD,1,'int8')];

            bits(:,c,l) = [commonBits; allUserBitsPadded];
        end
    end
end

end

function bits = ehtSIGCommonFieldBits(cfgEHT,sigCodingInfo)
%ehtSIGCommonFieldBits EHT-SIG common field bits
%
%   BITS = ehtSIGCommonFieldBits(CFGEHT,SIGCODINGINFO) generates the
%   EHT-SIG field bits for the EHT MU transmission format.
%
%   Common field bits for OFDMA, non-OFDMA, and NDP transmission are
%   defined in Table 36-33, Table 36-36, and 36-37 of IEEE P802.11be/D1.5
%   respectively.
%
%   For OFDMA BITS is a binary matrix of size N-by-C-by-L. For non-OFDMA
%   BITS is a binary matrix of size N-by-C. For NDP or non-OFDMA single
%   user transmission BITS is a binary matrix of size N-by-1. Where N is
%   the number of common field bits, C is the number of content channels
%   and L is the number of 80 MHz segments.

cbw = wlan.internal.cbwStr2Num(cfgEHT.ChannelBandwidth);

% For OFDMA, get number of RU allocation subfields N and M
[N,M] = wlan.internal.ehtSIGNumAllocationSubfields(cbw);
C = sigCodingInfo.NumContentChannels;

% Spatial Reuse
B00_03 = int2bit(cfgEHT.SpatialReuse,4,false);

% G1 + LTF mode
if cfgEHT.EHTLTFType==2 && cfgEHT.GuardInterval==0.8
    val = 0;
elseif cfgEHT.EHTLTFType==2 && cfgEHT.GuardInterval==1.6
    val = 1;
elseif cfgEHT.EHTLTFType==4 && cfgEHT.GuardInterval==0.8
    val = 2;
else
    assert(cfgEHT.EHTLTFType==4 && cfgEHT.GuardInterval==3.2)
    val = 3;
end
B04_05 = int2bit(val,2,false);

% Number of EHT-LTF symbols
allocInfo = ruInfo(cfgEHT);
maxNumSTSPerRU = max(allocInfo.NumSpaceTimeStreamsPerRU);
NumHELTFSymbol = wlan.internal.numVHTLTFSymbols(maxNumSTSPerRU)+cfgEHT.NumExtraEHTLTFSymbols;
switch NumHELTFSymbol
    case 1
        numEHTLTFSignal = 0;
    case 2
        numEHTLTFSignal = 1;
    case 4
        numEHTLTFSignal = 2;
    case 6
        numEHTLTFSignal = 3;
    otherwise % 8
        assert(NumHELTFSymbol==8)
        numEHTLTFSignal = 4;
end
B06_08 = int2bit(numEHTLTFSignal,3,false);
tailBits = zeros(6,1,'int8');

if sigCodingInfo.IsNDP
    % NSS
    B09_12 = int2bit(cfgEHT.User{1}.NumSpaceTimeStreams-1,4,false);

    % Beamformed
    if cfgEHT.RU{1}.SpatialMapping==wlan.type.SpatialMapping.custom
        B13_13 = double(cfgEHT.RU{1}.Beamforming);
    else
        B13_13 = 0;
    end

    % Disregard
    B14_15 = [1; 1];

    B00_15 = [B00_03; B04_05; B06_08; B09_12; B13_13; B14_15];

    allCRCBits = wlan.internal.crcGenerate(B00_15);
    bits = [B00_15; allCRCBits(1:4); tailBits]; % B16-B25
else
    % LDPC Extra symbol segment
    [peDisambiguity,codingInfo] = ehtPEDisambiguityCalculation(cfgEHT);
    B09_09 = codingInfo.LDPCExtraSymbol;

    % Pre-FEC Padding Segment
    B10_B11 = preFECPaddingFactorEncoding(codingInfo.PreFECPaddingFactor);

    % PE Disambiguity
    B12_12 = peDisambiguity;

    % Disregard
    B13_16 = [1; 1; 1; 1];

    B00_16 = [B00_03; B04_05; B06_08; B09_09; B10_B11; B12_12; B13_16];

    if sigCodingInfo.CompressionMode==0 % OFDMA
        numBitsWithoutRUAllocBits = 17;
        numCRCTailBits = 10;
        numBitsWithRUAlloc1Bits = numBitsWithoutRUAllocBits+9*N+numCRCTailBits;
        L = sigCodingInfo.NumSegments; % Number of 80 MHz segments
        % Pre-allocation of variables
        bits = coder.nullcopy(zeros(numBitsWithoutRUAllocBits+9*N+numCRCTailBits+9*M+numCRCTailBits*(M~=0),sigCodingInfo.NumContentChannels,L,'int8')); % NumBits-by-C-by-L
        numAllocationIndexPerSegment = min(4,size(cfgEHT.AllocationIndex,2)); % Number of allocations in an 80 MHz segment
        for l=1:L
            % RU Allocation-1
            allocIndex = cfgEHT.AllocationIndex(l,:);
            for cc=1:C
                % Get allocation index of content channel 1 and 2 of first segment
                allocBits = int2bit(allocIndex(cc:2:numAllocationIndexPerSegment),9,false);
                allCRCBits = wlan.internal.crcGenerate([B00_16; allocBits(:)]); % Calculate CRC
                CRCBits = allCRCBits(1:4);
                bits(1:numBitsWithRUAlloc1Bits,cc,l) = [B00_16; allocBits(:); CRCBits; tailBits];
            end

            % RU Allocation-2
            if sigCodingInfo.NumSegments>1 % Only process for 160 MHz and 320 MHz
                for cc=1:C
                    % Get allocation index of content channel 1 and 2 of
                    % all segments after the first segment
                    allocBits = int2bit(allocIndex(1,numAllocationIndexPerSegment+cc:2:end),9,false);
                    allCRCBits = wlan.internal.crcGenerate(allocBits(:)); % Calculate CRC
                    CRCBits = allCRCBits(1:4);
                    bits(numBitsWithRUAlloc1Bits+1:end,cc,l) = [allocBits(:); CRCBits; tailBits];
                end
            end
        end
    else % Non-OFDMA (SU or Multiple users)
        B17_19 = int2bit(allocInfo.NumUsers-1,3,false);
        % Common field bits are same in all EHT-SIG content channels
        bits = repmat(int8([B00_16; B17_19]),1,C); % For codegen
    end
end
end

function [peDisambiguity,codingInfo] = ehtPEDisambiguityCalculation(cfg)
%ehtPEDisambiguityCalculation PE Disambiguity calculation as defined in Section 36.3.14 of IEEE P802.11be/D1.5

[~,TXTIME,codingInfo] = wlan.internal.ehtPLMETxTimePrimative(cfg);
npp = wlan.internal.heNominalPacketPadding(cfg);
trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,codingInfo.PreFECPaddingFactor,npp,codingInfo.NSYM);
TSYM = trc.TSYM;
% Signal extension is in microseconds and should be 0 if in 5 GHz band
% or 6us in the 2.4 GHz band if required (Section 36.3.12.5 of IEEE P802.11be/1.4)
SignalExtension = 0; % Assume 5 GHz band
TPE = trc.TPE;
sf = 1e-3; % TXTIME in ns so convert to us for equation before comparison
peDisambiguity = (TPE+round(4/sf*(ceil((TXTIME*sf-SignalExtension-20)/4)-(TXTIME*sf-SignalExtension-20)/4)))>=TSYM; % Equation 36-94
end

function bits = preFECPaddingFactorEncoding(preFECPaddingFactor)
%preFECPaddingFactorEncoding Pre-FEC Padding Factor subfield encoding as
%defined in Table 36-33(OFDMA), 36-36(non-OFDMA) of IEEE P802.11be/D1.5.

switch preFECPaddingFactor
    case 1
        bits = [1; 0];
    case 2
        bits = [0; 1];
    case 3
        bits = [1; 1];
    otherwise % 4
        assert(isequal(preFECPaddingFactor,4))
        bits = [0; 0];
end
end

function y = ehtSIGUserFieldBits(staid,mcs,spatialConfig,txBeamforming,codingBits,isMU)
%ehtSIGUserFieldBits Generate EHT-SIG User Field bits as defined in Table 36-40 and 36-41 of IEEE P802.11be/D1.5

staIDBits = int2bit(staid,11,false);
mcsBits = int2bit(mcs,4,false);
if isMU % MU-MIMO
    spatialConfigUse = spatialConfig;
    y = [staIDBits; mcsBits; codingBits; spatialConfigUse];
else % non MU-MIMO
    reservedBit = 1;
    txBeamformingBits = double(txBeamforming);
    y = [staIDBits; mcsBits; reservedBit; spatialConfig(1:4); txBeamformingBits; codingBits];
end
end