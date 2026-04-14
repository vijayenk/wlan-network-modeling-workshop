function [codingInfo,userInSegment] = ehtSIGCodingInfo(cfg)
%ehtSIGCodingInfo EHT-SIG coding information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [codingInfo,userInSegment] = ehtSIGCodingInfo(CFG) returns a structure
%   containing EHT-SIG coding information and the users within an 80 MHz
%   subblock for each content channel.
%
%   codingInfo contains the following fields:
%
%   Rate                                      - Coding rate.
%   NBPSCS                                    - Number of coded bits per
%                                               subcarrier per spatial
%                                               streams.
%   NCBPS                                     - Number of coded bits per
%                                               symbols.
%   NSD                                       - Number of data tones in
%                                               EHT-SIG field.
%   NDBPS                                     - Number of data bits per
%                                               symbols.
%   NSS                                       - Number of spatial streams
%   DCM                                       - DCM for EHT MCS 15.
%   MCS                                       - EHT-SIG field MCS
%   CompressionMode                           - Compression mode as defined
%                                               in Table 36-29 of IEEE
%                                               P802.11be/D4.0.
%   IsNDP                                     - Indicate NDP
%   NumContentChannels                        - Number of content channels.
%                                               Number of content channels
%                                               is one for 20 MHz and two
%                                               for all other bandwidths.
%   NumSIGSymbols                             - Number of OFDM symbols.
%   NumCommonFieldBits                        - Number of common field bits
%   NumSIGBits                                - Number of EHT-SIG bits.
%   NumDataBitsPerSegmentPerContentChannel    - Number of data bits per
%                                               subblock for all content
%                                               channels of size
%                                               L-by-NumContentChannels.
%   NumPaddingBitsPerSegmentPerContentChannel - Number of padded bits per
%                                               subblock for all content
%                                               channels of size
%                                               L-by-NumContentChannels.
%   NumUsersPerSegmentPerContentChannel       - Number of users per subblock
%                                               for all content channels of
%                                               size
%                                               L-by-NumContentChannels.
%   RUSubchannelAllocation                    - Per-subchannel RU
%                                               allocation index for
%                                               EHT-SIG signaling. Same as
%                                               standard allocation indices
%                                               except indicates an empty
%                                               RU of the appropriate size
%                                               in subchannels containing
%                                               an RU>=242-tones.
%   NumSegments                               - Number of 80 MHz segments
%                                               in the channel bandwidth.
%   UsersSignaledInSingleSubblock             - Indicates if the users are
%                                               signaled in a single 80 MHz
%                                               subblock in a 160/320 MHz
%                                               bandwidth (OFDMA), and when
%                                               the RU size of the resource
%                                               unit is less than 242-tone
%                                               RU.
%
%   userInSegment is a cell array of size L-by-2, where each cell
%   contains the distribution of users in a 80 MHz subblock for each content
%   channel. L represents the number of 80 MHz segments and is 1 for 20
%   MHz, 40 MHz, and 80 MHz. L is 2 and 4 for 160 MHz and 320 MHz
%   respectively.

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

    [codingInfo,userInSegment] = ehtSIGCodingInfoLocal(cfg);
    % Recalculate coding info as needed
    usersSignaledInSingleSubblock = codingInfo.UsersSignaledInSingleSubblock;
    if usersSignaledInSingleSubblock && isa(cfg,'wlanEHTRecoveryConfig') % Only applicable for OFDMA, 160/320 MHz, RU size<242-tone RU

        % Create an M-by-N allocation with allocation index 28, which
        % contributes zero user fields to the user specific field in the
        % same EHT-SIG content channel. The allocation index other than
        % the one in the relevant 80 MHz subblocks are replaced with
        % allocation index 28. With this allocation the users are signaled
        % in a single 80 MHz subblock, hence there is no repetition of
        % users across other 80 MHz subblocks.
        allocIdx = ones(size(cfg.AllocationIndex))*28;
        for s=1:size(cfg.AllocationIndex,1) % Loop through 80 MHz subblocks
            allocIdx(s,(1:4)+(s-1)*4) = cfg.AllocationIndex(s,(1:4)+(s-1)*4);
        end
        % Recalculate EHT-SIG coding information with the updated allocation index
        cfg.AllocationIndex = allocIdx;
        [codingInfo,userInSegment] = ehtSIGCodingInfoLocal(cfg);
        codingInfo.UsersSignaledInSingleSubblock = usersSignaledInSingleSubblock;
    end
end

function [codingInfo,userInSegment] = ehtSIGCodingInfoLocal(cfg)

    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
    isEHTRecovery = isa(cfg,'wlanEHTRecoveryConfig');
    ehtSIGTable = wlan.internal.ehtSIGRateTable(cfg.EHTSIGMCS); % Rate table for EHT-SIG field

    % Get Compression mode
    [mode,isNDP] = compressionMode(cfg);
    
    if isEHTRecovery
        if mode==0 % OFDMA
            allocInfo = wlan.internal.ehtAllocationParams(cfg.AllocationIndex);
            isSameEHTSignalling = allocInfo.IsSameEHTSignalling;
        else
            isEHTDUPMode = cfg.EHTDUPMode==1;
            allocInfo = wlan.internal.ehtAllocationInfo(cfg.ChannelBandwidth,cfg.NumNonOFDMAUsers,cfg.PuncturedChannelFieldValue,isEHTDUPMode);
        end
        ruSubchannelAllocation = allocInfo.RUSubchannelAllocation;
        numUsersPerSubchannel = allocInfo.NumUsersPerSubchannel;
        usersSignaledPerSubchannel = allocInfo.UsersSignaledPerSubchannel;
    else % wlanEHTMUConfig and uhrMUConfig
        ruSubchannelAllocation = cfg.pAllocInfo.RUSubchannelAllocation;
        numUsersPerSubchannel = cfg.pAllocInfo.NumUsersPerSubchannel;
        usersSignaledPerSubchannel = cfg.pAllocInfo.UsersSignaledPerSubchannel;
        isSameEHTSignalling = cfg.pAllocInfo.IsSameEHTSignalling;
    end
    sigInfo = wlan.internal.ehtSIGCommonFieldInfo(cbw,mode,ehtSIGTable.NDBPS,isNDP);

    numSym = 0;
    coder.varsize('numSym',[1 4],[0 1]); % For codegen
    numUsersPerSegmentPerContentChannel = 0;
    coder.varsize('numUsersPerSegmentPerContentChannel',[4 2],[1 1]); % For codegen
    numDataBitsPerSegmentPerContentChannel = 0;
    coder.varsize('numDataBitsPerSegmentPerContentChannel',[4 2],[1 1]); % For codegen
    numPaddingBitsPerSegmentPerContentChannel = 0;
    coder.varsize('numPaddingBitsPerSegmentPerContentChannel',[4 2],[1 1]); % For codegen
    if mode==0 % OFDMA
        L = ceil(size(cfg.AllocationIndex,2)/4); % Number of 80 MHz segments
    else % SU. NDP or MU-MIMO
        L = 1; % Same users across all subband, assume L=1
    end
    userInSegment = coder.nullcopy(cell(L,sigInfo.NumContentChannels));

    if isNDP
        % Only common field, no user fields.
        numDataBitsPerSegmentPerContentChannel(1) = sigInfo.NumCommonFieldBits;
        userInSegment = {0};
        numSym(1) = ceil(numDataBitsPerSegmentPerContentChannel/ehtSIGTable.NDBPS);
        numPaddingBitsPerSegmentPerContentChannel(1) = numSym*ehtSIGTable.NDBPS-numDataBitsPerSegmentPerContentChannel;
        ruSubchannelAllocation = nan;
    else
        % Get the users signaled in each content channel and 80 MHz subblock
        numSym = zeros(1,L);
        numUsersPerSegmentPerContentChannel = zeros(L,sigInfo.NumContentChannels);
        numDataBitsPerSegmentPerContentChannel = zeros(L,sigInfo.NumContentChannels);
        numPaddingBitsPerSegmentPerContentChannel = zeros(L,sigInfo.NumContentChannels);

        if mode==0 % OFDMA
            NSC = min(4,size(numUsersPerSubchannel,2)); % Number of subchannels in an 80 MHz subblock
            coder.assumeDefined(isSameEHTSignalling)
            for l=1:L
                if sigInfo.NumContentChannels>1
                    if isSameEHTSignalling
                        numUserInSegment = numUsersPerSubchannel;
                    else
                        numUserInSegment = numUsersPerSubchannel((l-1)*NSC+(1:NSC));
                    end
                    numUsersPerSegmentPerContentChannel(l,1) = sum(numUserInSegment(1:2:end)); % subblock L, content channel-1
                    numUsersPerSegmentPerContentChannel(l,2) = sum(numUserInSegment(2:2:end)); % subblock L, content channel-2
                    userContentCh1 = zeros(1,0);
                    coder.varsize('userContentCh1',[1 18],[0 1]); % For codegen
                    userContentCh2 = zeros(1,0);
                    coder.varsize('userContentCh2',[1 18],[0 1]); % For codegen

                    % Get users in both content channels in each subblock. For 40 MHz there are two content channels in a subblock
                    for i=1:sigInfo.NumContentChannels - (cbw==40)
                        if isSameEHTSignalling
                            % Signal same users per content channel across all segments
                            userContentCh1 = [usersSignaledPerSubchannel{1:2:end}];
                            userContentCh2 = [usersSignaledPerSubchannel{2:2:end}];
                        else
                            userContentCh1 = [userContentCh1 usersSignaledPerSubchannel{1+NSC*(l-1)+(i-1)*2}]; %#ok<*AGROW>
                            userContentCh2 = [userContentCh2 usersSignaledPerSubchannel{2+NSC*(l-1)+(i-1)*2}];
                        end
                    end
                    userInSegment{l,1} = userContentCh1;
                    userInSegment{l,2} = userContentCh2;
                else
                    numUsersPerSegmentPerContentChannel(l,1) = numUsersPerSubchannel;
                    userInSegment{l,1} = usersSignaledPerSubchannel{1};
                end
                [numSym(l),numDataBitsPerSegmentPerContentChannel(l,:),numPaddingBitsPerSegmentPerContentChannel(l,:)] = ...
                    ehtNumSIGSymbolsPerContentChannel(sigInfo.NumContentChannels,numUsersPerSegmentPerContentChannel(l,:),sigInfo.NumCommonFieldBits,ehtSIGTable.NDBPS,mode);
            end
        else % non-OFDMA

            % Get the number of users on each signaled 20 MHz subchannel
            numUsersPer20 = zeros(1,sigInfo.NumContentChannels);
            if sigInfo.NumContentChannels==1
                numUsersPer20 = numUsersPerSubchannel;
            else
                % Split user fields between two content channels
                numUsersPer20(1) = ceil(numUsersPerSubchannel/2);
                numUsersPer20(2) = numUsersPerSubchannel-ceil(numUsersPerSubchannel/2);
            end

            % Get the start and end indices for the users
            startUserIndexPer20 = cumsum([0 numUsersPer20(1:end-1)])+1;
            endUserIndexPer20 = startUserIndexPer20+numUsersPer20-1;

            % Content channel 1 contains users for odd subchannels, channel 2 for even
            contentChannel1Users = zeros(1,0);
            for i=1:2:numel(startUserIndexPer20)
                contentChannel1Users = [contentChannel1Users startUserIndexPer20(i):endUserIndexPer20(i)];
            end
            userInSegment{1} = contentChannel1Users;
            numUsersPerSegmentPerContentChannel(1,1) = numel(contentChannel1Users); % For codegen
            if sigInfo.NumContentChannels==2
                contentChannel2Users = zeros(1,0);
                for i=2:2:numel(startUserIndexPer20)
                    contentChannel2Users = [contentChannel2Users startUserIndexPer20(i):endUserIndexPer20(i)];
                end
                userInSegment{2} = contentChannel2Users;
                numUsersPerSegmentPerContentChannel(1,2) = numel(contentChannel2Users); % For codegen
            end
            [numSym,numDataBitsPerSegmentPerContentChannel,numPaddingBitsPerSegmentPerContentChannel] = ...
                ehtNumSIGSymbolsPerContentChannel(sigInfo.NumContentChannels,numUsersPerSegmentPerContentChannel,sigInfo.NumCommonFieldBits,ehtSIGTable.NDBPS,mode);
        end
    end

    numSIGSymbols = max(numSym); % Max number of symbols across two subfields (RU Allocation-1 and RU Allocation-2)
    numEHTSIGBits = ehtSIGTable.NDBPS*numSIGSymbols*sigInfo.NumContentChannels*L;

    % The variable usersSignaledInSingleSubblock indicates if the users are
    % signaled in a single 80 MHz subblock in a 160/320 MHz bandwidth, and when
    % the RU size of the resource unit is less than 242-tone RU. True means
    % that the users are signaled in a single 80 MHz subblock, hence there is
    % no repetition of users information across other 80 MHz subblocks. This
    % variable is only applicable for OFDMA configuration.
    if isEHTRecovery
        usersSignaledInSingleSubblock = mode==0 && any(strcmp(cfg.ChannelBandwidth,{'CBW160','CBW320'})) && all(cfg.AllocationIndex<=55,'all') ...
            && cfg.NumEHTSIGSymbolsSignaled<numSIGSymbols;
    else % wlanEHTMUConfig, UHR MU config
        usersSignaledInSingleSubblock = ~isSameEHTSignalling;
    end

    codingInfo = struct( ...
        'Rate',                                      ehtSIGTable.Rate, ...
        'NBPSCS',                                    ehtSIGTable.NBPSCS, ...
        'NCBPS',                                     ehtSIGTable.NCBPS, ...
        'NSD',                                       ehtSIGTable.NSD, ...
        'NDBPS',                                     ehtSIGTable.NDBPS, ...
        'NSS',                                       ehtSIGTable.NSS, ...
        'DCM',                                       cfg.EHTSIGMCS==15, ...
        'MCS',                                       cfg.EHTSIGMCS, ...
        'CompressionMode',                           mode, ...
        'IsNDP',                                     isNDP, ...
        'NumContentChannels',                        sigInfo.NumContentChannels, ...
        'NumSIGSymbols',                             numSIGSymbols, ...
        'NumCommonFieldBits',                        sigInfo.NumCommonFieldBits, ...
        'NumSIGBits',                                numEHTSIGBits, ...
        'NumDataBitsPerSegmentPerContentChannel',    numDataBitsPerSegmentPerContentChannel, ...
        'NumPaddingBitsPerSegmentPerContentChannel', numPaddingBitsPerSegmentPerContentChannel, ...
        'NumUsersPerSegmentPerContentChannel',       numUsersPerSegmentPerContentChannel, ...
        'RUSubchannelAllocation',                    ruSubchannelAllocation, ...
        'NumSegments',                               L, ...
        'UsersSignaledInSingleSubblock',             usersSignaledInSingleSubblock);
end

function [numSym,numDataBitsPerCC,numPaddingBitsPerCC] = ehtNumSIGSymbolsPerContentChannel(numCC,numUsersPerCC,numCommonFieldBits,NDBPS,mode)
%ehtNumSIGSymbolsPerContentChannel Number of symbols in EHT-SIG content channels

    numSymPerCC = zeros(1,numCC);
    numDataBitsPerCC = zeros(1,numCC);
    numPaddingBitsPerCC = zeros(1,numCC);
    for i = 1:numCC
        % The allocation for one content channel is every second 20 MHz channel allocation
        % Get the number of pairs and any leftover users
        if mode==0 % OFDMA
            numFirstEncodingBlock = 0;
        else % SU, MU-MIMO

            % First user is encoded with the common field so does not count towards pairs or leftover
            numFirstEncodingBlock = 1;
        end
        numPairs = floor((numUsersPerCC(i)-numFirstEncodingBlock)/2);
        numLeftover = mod(numUsersPerCC(i)-numFirstEncodingBlock,2);

        % Non-OFDMA first encoding block has 22 bits plus tail and CRC (IEEE P802.11be/D1.5 Table 36-36)
        % A standard user block has 22 bits plus tail and CRC (IEEE P802.11be/D1.5 Table 36-38)
        % Each pair and any left-over user have 6 tail bits and 4 crc bits appended
        numUserFieldBits = 22*numUsersPerCC(i)+(6+4)*(numFirstEncodingBlock+numPairs+numLeftover);
        % Determine the number of symbols required to transmit all the content channel bits
        numDataBitsPerCC(i) = numUserFieldBits+numCommonFieldBits;
        numSymPerCC(i) = ceil(numDataBitsPerCC(i)/NDBPS);
        numPaddingBitsPerCC(i) = numSymPerCC(i)*NDBPS- numDataBitsPerCC(i);
    end

    % Transmit the greater number of required symbols
    numSym = max(numSymPerCC);

end
