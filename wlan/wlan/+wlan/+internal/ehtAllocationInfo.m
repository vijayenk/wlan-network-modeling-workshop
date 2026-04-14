function y = ehtAllocationInfo(varargin)
%ehtAllocationInfo EHT RU allocation info
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtAllocationInfo(INDEX) returns a structure for an OFDMA format
%   containing information given the allocation assignment INDEX.
%
%   Y is a structure with the following fields:
%
%   NumUsers                   - Total number of users in an allocation
%   NumRUs                     - Number of RUs in an allocation
%   RUIndices                  - A vector containing the index of each RU
%   RUSizes                    - A vector containing the size of each RU
%   NumUsersPerRU              - A vector containing the number of users
%                                in each RU
%   PuncturingPattern          - Indicates the puncturing pattern for an
%                                non-OFDMA transmission as defined in
%                                Table 36-30 of IEEE P802.11be/D1.5. For
%                                OFDMA, the punctured subchannel is
%                                indicated by allocation index 26 in a 20
%                                MHz subchannel.
%   NumUsersPerSubchannel      - Indicates the number of users in a 20 MHz
%                                subchannel for an OFDMA transmission. For
%                                an non-OFDMA the field represents
%                                NumUsersPerRU.
%   RUSubchannelAllocation     - Per-subchannel RU allocation index for
%                                EHT-SIG signaling. Same as standard
%                                allocation indices except indicates an
%                                empty RU of the appropriate size in
%                                subchannels containing an RU>=242-tones.
%   UsersSignaledPerSubchannel - Indicates the user numbers signaled in a
%                                20 MHz subchannel. This assumes user
%                                numbers are assigned per RU in increasing
%                                order of frequency.
%   AllocationIndexPerSegment  - Per-segment and per-subchannel RU
%                                allocation index for EHT-SIG signaling.
%                                For 20/40/80 MHz the size is 1-by-N. For
%                                160/320 MHz the size is M-by-N. Where M is
%                                the number of segments, M is 2 for 160 MHz
%                                and 4 for 320 MHz. N is the 1, 2, 4, 8, or
%                                16 for 20, 40, 80, 160, and 320 MHz.
%   ChannelBandwidth           - Channel bandwidth as one of 'CBW20',
%                                'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%   IsSameEHTSignalling        - Returns true when M-by-N allocation index
%                                has identical row elements.
%
%   INDEX is a scalar or vector containing the 9-bit allocation per 20 MHz
%   segment. Each element is the allocation for a 20 MHz segment in order
%   of absolute frequency.
%
%   Y = ehtAllocationInfo(CHANBW,NUMUSER,PUNCTUREDCHANNELFIELDVALUE,EHTDUPMODE)
%   returns a same structure containing information given the channel
%   bandwidth, number of users, punctured channel field value, and EHT DUP
%   mode indication as defined in Table 36-28 of IEEE P802.11be/D1.5
%   standard for non-OFDMA format.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'. NUMUSER
%   is a scalar between 1 and 8 (inclusive). PUNCTUREDCHANNELFIELDVALUE is
%   a scalar between 0 and 24 (inclusive). EHTDUPMode is a logical scalar
%   and indicates EHT DUP mode for non-OFDMA transmission as defined in
%   IEEE P802.11be/D1.5.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(1,4);
    % Set defaults
    first80MHzSubblock = false;
    numUsers = 1;
    puncturedChannelFieldValue = 0;
    isOFDMA = true;
    ehtDUPMode = false;

    if isnumeric(varargin{1}) % OFDMA
                              % ehtAllocationInfo(allocIndex,numUsers,puncturedChannelFieldValue,ehtDUPMode)
        allocationIndex = varargin{1};
        validateattributes(allocationIndex,{'numeric'},{'>=',0,'<=',303},mfilename,'AllocationIndex');
        [M,N] = size(allocationIndex); % M-by-N
        numAssignments = N;
        % Get allocation index in use per segment if the allocation index is a
        % matrix. Only validate the allocation index in use.
        if M==1 % Allocation index is 1-by-N
            coder.internal.errorIf(~(any(numAssignments==[1 2 4 8 16])),'wlan:wlanEHTMUConfig:InvalidNumAssignments');
            allocationIndexUse = allocationIndex(M,:);
        else % Allocation index is M-by-N (numAssignments)
            coder.internal.errorIf(~(any(numAssignments==[8 16]) && any(M==[2 4])),'wlan:wlanEHTMUConfig:InvalidNumAssignments');
            % When AllocationIndex is an M-by-N matrix, the per segment (M) AllocationIndex must be equal for all segments
            coder.internal.errorIf(~all(allocationIndex(2:end,:)==allocationIndex(1,:),'all'),'wlan:eht:InvalidMbyNAllocation');
            allocationIndexUse = coder.nullcopy(zeros(1,numAssignments));
            for m=1:M
                allocationIndexUse((1:4)+(m-1)*4) = allocationIndex(m,(1:4)+(m-1)*4);
            end
        end

        % Allocation index 31 and 56 to 63 (inclusive) as specified in Table 36-34 of IEEE P802.11be/D1.5 are not supported
        coder.internal.errorIf(inAllocation(allocationIndexUse,[31 56:63]),'wlan:wlanEHTMUConfig:InvalidAllocation');

        % Validate the twelve allowed 2x996-484-tone MRUs in a non-OFDMA 320 MHz EHT PPDU as defined in Figure 36-14 of IEEE P802.11be/D1.5.
        % The allocation index range for 2x996-484-tone. MRUs is defined in Table 36-34 of IEEE P802.11be/D1.5.
        if numel(allocationIndexUse)==16 && inAllocation(allocationIndexUse,256:303)
            % Check for the transmission in either first, second, and third or second, third, and fourth 80 MHz subchannel for allocation index range 256:303
            if inAllocation(allocationIndexUse(1:4),256:303) || all(allocationIndexUse(1:4)==30)
                coder.internal.errorIf(inAllocation(allocationIndexUse(13:16),256:303) || all(allocationIndexUse(13:16)==30),'wlan:wlanEHTMUConfig:InvalidLMRUAllocation');
                % Indicate that []-484-996-996 (MRU1) to 996-996-484 (MRU12) are transmitted in the first 80 MHz segment of a 320 MHz channel bandwidth
                first80MHzSubblock = true;
            else
                % Indicate that []-484-996-996 (MRU1) to 996-996-484 (MRU12) are transmitted in the second 80 MHz subblock of a 320 MHz channel bandwidth
                first80MHzSubblock = false;
            end
        end
        zeroUserAllocation = false(size(allocationIndexUse));
        zeroUserAllocationRUSize = zeros(size(allocationIndexUse));
        cbw = numel(allocationIndexUse)*20; % ChannelBandwidth in MHz
                                            % Set channel bandwidth
        switch cbw
          case 20
            channelBandwidth = 'CBW20';
          case 40
            channelBandwidth = 'CBW40';
          case 80
            channelBandwidth = 'CBW80';
          case 160
            channelBandwidth = 'CBW160';
          otherwise
            channelBandwidth = 'CBW320';
        end
    else % Non-OFDMA
        if nargin>1
            channelBandwidth = varargin{1};
            cbw = wlan.internal.cbwStr2Num(channelBandwidth); % Channelbandwidth in MHz
            if isnumeric(varargin{2})
                validateattributes(varargin{2},{'numeric'},{'scalar','>=',1,'<=',8},mfilename,'NumUsers');
                numUsers = varargin{2};
            end
            if nargin>3
                validateattributes(varargin{3},{'numeric'},{'scalar','>=',0,'<=',24},mfilename,'PuncturedChannelFieldValue');
                puncturedChannelFieldValue = varargin{3};
                if nargin==4
                    validateattributes(varargin{4},{'logical'},{'scalar'},mfilename,'EHTDUPMode');
                    ehtDUPMode = varargin{4};
                    coder.internal.errorIf(ehtDUPMode && ((any(cbw==[20 40]) || numUsers>1) || puncturedChannelFieldValue~=0),'wlan:eht:InvalidDUPMode');
                end
            end
            coder.internal.errorIf((any(cbw==[20 40]) && puncturedChannelFieldValue~=0) || (cbw==80 && puncturedChannelFieldValue>4) || ...
                                   (cbw==160 && puncturedChannelFieldValue>12),'wlan:eht:InvalidPuncturedFieldValue');
        end
        numAssignments = 1;
        zeroUserAllocation = false;
        zeroUserAllocationRUSize = 0;
        isOFDMA = false;
    end

    ruSizesVec = zeros(1,0);
    ruIndicesVec = zeros(1,0);
    coder.varsize('ruSizesVec',[1 144],[0 1]); % For codegen
    coder.varsize('ruIndicesVec',[1 144],[0 1]); % For codegen
    numUsersVec = zeros(1,0);
    ruNumVec = zeros(1,0);
    coder.varsize('ruNumVec',[1 144],[0 1]); % For codegen
    coder.varsize('numUsersVec',[1 144],[0 1]); % For codegen
    mruIndexVec = zeros(1,0);
    coder.varsize('mruIndexVec',[1 144],[0 1]); % For codegen
    ruSubchannelAllocation = zeros(1,0);
    numUsersSubchannel = zeros(1,numAssignments);
    coder.varsize('numUsersSubchannel',[1 16],[0 1]); % For codegen
    ruNumPerSubchannel = cell(1,numAssignments);
    numIndPerSubchannelRU = [26 52 106 242 484 968 996 242+484 484+996 1992 484+(996*2) 484+(996*3) 3*996 3984];
    numIndPerSubchannelVal = [9 4 2 1 0.5 0.25 0.25 0.25 0.125 0.125 0.0625 0.0625 0.0625 0.0625];

    numRUs = 0; % Total number of RUs (an MRU is an RU)
    for i=1:numAssignments
        ruNumPerSubchannel{i} = zeros(1,0); % Initialize to zero for codegen
        if isOFDMA % OFDMA
            s = ehtRUAllocationLUT(allocationIndexUse(i),first80MHzSubblock);
        else
            s = ehtRUAllocationLUT(channelBandwidth,numUsers,puncturedChannelFieldValue,ehtDUPMode);
        end
        numUsersSubchannel(i) = ceil(sum(s.NumUsersPerRU));
        if s.NumUsers==0
            % Skip allocations with 0 users when creating RUs
            if ~(isOFDMA && any(allocationIndexUse(i)==[26 27]))
                % If not punctured RU then record it is an active RU but zero-users for validation
                zeroUserAllocation(i) = true;
                zeroUserAllocationRUSize(i) = s.RUSizes;
            end
            continue
        end

        ruNumPerSCVec = zeros(1,0); % Vector of RU numbers created/used on each subchannel. Initialize to zero for each iteration of numAssignments
        coder.varsize('ruNumPerSCVec',[1 144],[0 1]); % For codegen

        for j = 1:numel(s.RUIndices)
            % Offset RU index by appropriate relative to the allocation index
            ia = i;
            if any(s.IsMRU) && sum(s.RUSizes(s.IsMRU))>242
                % s.RUIndices for an L-MRU are relative to the bandwidth
                % spanned by the L-MRU - e.g. a 242+484-tone MRU is within 80
                % MHz, and a 484+996-tone MRU is within 160 MHz. Therefore,
                % adjust indices relative to the whole channel bandwidth.
                n = numIndPerSubchannelVal(numIndPerSubchannelRU==sum(s.RUSizes));
                ia = (ceil(i*n)-1)/n+1;
            end
            if s.RUSizes(j)==26
                % The center 26-tone RUs in each 80 MHz segment are undefined
                % but have an index. Therefore, account for these when
                % calculating the index offset
                numCentral26RUs = ceil((i-2)/4);
                offset = floor((ia-1)*numIndPerSubchannelVal(numIndPerSubchannelRU==s.RUSizes(j)))+numCentral26RUs;
            else
                offset = floor((ia-1)*numIndPerSubchannelVal(numIndPerSubchannelRU==s.RUSizes(j)));
            end
            ruIndex = s.RUIndices(j)+offset;

            ruMatch = s.RUSizes(j)==ruSizesVec & ruIndex==ruIndicesVec;
            if any(ruMatch)
                % If RU already created add required number of users to it and
                % do not create a new RU. Check for overlapping L-MRU with different MRU indices
                coder.internal.errorIf(s.MRUIndex(j)~=mruIndexVec(ruMatch),'wlan:eht:InvalidRUAllocation');
                numUsersVec(ruMatch) = numUsersVec(ruMatch)+s.NumUsersPerRU(j);
                ruNumPerSCVec = [ruNumPerSCVec ruNumVec(ruMatch)]; %#ok<AGROW>
            else
                % Otherwise create new RU
                ruIndicesVec(end+1) = ruIndex;
                ruSizesVec(end+1) = s.RUSizes(j);
                numUsersVec(end+1) = s.NumUsersPerRU(j);
                mruIndexVec(end+1) = s.MRUIndex(j);

                % Vector containing the RU number corresponding to this sub-RU.
                % s.RUNumber is the number of each RU within the subchannel.
                % Therefore, offset these numbers by the total number of RUs
                % so far. Note a sub-RU is not counted as an RU but and MRU
                % is.
                ruNumVec(end+1) = numRUs+s.RUNumber(j);
                % Store for just this subchannel
                ruNumPerSCVec(end+1) = numRUs+s.RUNumber(j);
            end
        end
        numRUs = ruNumVec(end);
        % Remove duplicate entries if ruNumPerSCVec contain repetitions of the same RU number due to an MRU
        ruNumPerSubchannel{i} = unique(ruNumPerSCVec);
    end

    % Group sub-RUs together
    ruIndices = cell(1,numRUs);
    ruSizes = cell(1,numRUs);
    numUsersPerRU = zeros(1,numRUs);
    for n = 1:numRUs
        isSubRU = ruNumVec==n; % Logical index of sub-RUs which make up an RU
        ruIndices{n} = ruIndicesVec(isSubRU);
        ruSizes{n} = ruSizesVec(isSubRU);
        numUsersPerRU(n) = ceil(sum(numUsersVec(isSubRU)));
    end

    % Get puncturing pattern for non-OFDMA
    if isOFDMA
        % Preamble puncturing is only applicable to 80 MHz, 160 MHz, and 320 MHz
        puncturingPattern = allocationIndexUse==26;
        coder.varsize('puncturingPattern');
        if numel(allocationIndexUse)>=4
            % Validate puncturing patterns as defined in Table 36-28 of IEEE P802.11be/D1.5
            punc80MHz = reshape(puncturingPattern,4,[]).'; % There are four 20 MHz subblocks in a 80 MHz channel
            for i=1:size(punc80MHz,1)
                wlan.internal.isValidPucturingPattern(~punc80MHz(i,:),false,i);
            end
        else
            coder.internal.errorIf(any(puncturingPattern),'wlan:eht:InvalidPuncturingPattern');
            puncturingPattern = false(1,numel(allocationIndexUse));
        end
    else
        puncturingPattern = s.PuncturingPattern;
        coder.varsize('puncturingPattern');
    end

    if any(numUsersPerRU>8)
        % Error if the total number of users in an RU is greater than 8
        for u = 1:numel(numUsersPerRU)
            coder.internal.errorIf(numUsersPerRU(u)>8,'wlan:eht:InvalidNumUsersPerRU',u,numUsersPerRU(u)); % For codegen
        end
    end

    if isOFDMA
        overlapWithRU = false(size(zeroUserAllocation));
        % Validate that allocation indices with zero users signaled overlap
        % with an RU of the correct size, i.e. 29 (empty 484) must overlap with
        % a 484-tone RU.
        allRUSizes = [ruSizes{:}];
        allRUIndices = [ruIndices{:}];
        switch cbw
          case 20
            coder.internal.errorIf(allocationIndexUse>55,'wlan:eht:InvalidAllocation20MHz');
          case 40
            coder.internal.errorIf(any(ruSizesVec>484) || any(allocationIndexUse>79),'wlan:eht:InvalidAllocation40MHz');
          case 80
            coder.internal.errorIf(any(ruSizesVec>996) || any(allocationIndexUse>127),'wlan:eht:InvalidAllocation80MHz');
          case 160
            coder.internal.errorIf(any(allocationIndexUse>159),'wlan:eht:InvalidAllocation160MHz');
        end

        ruInd = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSizesVec,ruIndicesVec);
        coder.internal.errorIf(numel(ruInd(:))~=numel(unique(ruInd(:))),'wlan:eht:InvalidRUAllocation'); % For codegen

        % An allocation is in error if the punctured (26) and unassigned (27)
        % allocation indices overlap with any other RU or MRU.
        puncRUIndex = find(any(allocationIndexUse==([26 27])'));
        if ~isempty(puncRUIndex)
            punRUSize = ones(1,numel(puncRUIndex))*242;
            punRUInd = wlan.internal.ehtRUSubcarrierIndices(cbw,punRUSize,puncRUIndex);
            coder.internal.errorIf(any(ruInd==punRUInd.','all'),'wlan:eht:InvalidRUAllocation');
        end

        largeRUSizes = [242 484 996 2*996 4*996];
        largeRUEmptyAlloc = [28 29 30 30 30]; % Empty allocation index for each large size RU
        ruSubchannelAllocation = allocationIndexUse; % Per-subchannel allocation indices for EHT-SIG

        for r = 1:numel(allRUSizes)
            % The RU-size may have zero-users, therefore test if an empty
            % allocation has been provided. Also set the per-subchannel
            % allocation indices for EHT-SIG
            if any(allRUSizes(r) == largeRUSizes)
                % Get logical index of segments which contain an RU
                segmentOccupiedByRU = wlan.internal.ehtRUSegmentOccupied(cbw,allRUSizes(r),allRUIndices(r));
                % An allocation index is in error if the segment containing
                % this RU has an allocation index which indicates it has zero
                % users, but the RU size from the allocation index does not
                % match the actual RU size.
                zeroUserAllocationOverlapsWithRU = zeroUserAllocation & segmentOccupiedByRU;
                % Zero-user 996 allocations can be used with 2*996 and 4*996 RUs
                zeroUserRUSizeMatch996 = zeroUserAllocationRUSize==996 & any(allRUSizes(r)==[2*996 4*996]);
                zeroUserRUSizeMatch = zeroUserAllocationRUSize==allRUSizes(r) | zeroUserRUSizeMatch996;
                unexpectedAllocation = zeroUserAllocationOverlapsWithRU & ~zeroUserRUSizeMatch;
                if any(unexpectedAllocation)
                    allocIdx = find(unexpectedAllocation,1); % For codegen
                    coder.internal.error('wlan:eht:InvalidRUSizeAllocation',allocIdx(1),allRUSizes(r),allRUSizes(r))
                end
                % Mark the allocation index as overlapped with an RU
                overlapWithRU(zeroUserAllocationOverlapsWithRU & zeroUserRUSizeMatch) = true;

                % Set the corresponding subchannel allocation to an empty RU of the appropriate size
                if coder.target('MATLAB') % Code for MATLAB evaluation
                    ruSubchannelAllocation(segmentOccupiedByRU) = largeRUEmptyAlloc(allRUSizes(r)==largeRUSizes);
                else % Code for code generation
                    ruEmptyAlloc = largeRUEmptyAlloc(allRUSizes(r)==largeRUSizes);
                    if isscalar(ruEmptyAlloc) % For codegen
                        ruSubchannelAllocation(segmentOccupiedByRU) = ruEmptyAlloc(1); % Scalar expansion
                    else
                        ruSubchannelAllocation(segmentOccupiedByRU) = ruEmptyAlloc; % For codegen the ruEmptyAlloc size must match segmentOccupiedByRU
                    end
                end
            end
        end
        % Validate that all zero-user allocations overlap with an RU
        diffAlloc = (overlapWithRU~=zeroUserAllocation);
        if any(diffAlloc)
            allocIdx = find(diffAlloc,1);
            coder.internal.error('wlan:eht:InvalidEmptyAllocation',allocIdx(1),zeroUserAllocationRUSize(allocIdx(1)),zeroUserAllocationRUSize(allocIdx(1)));
        end

        % The number of users per RU should not be zero
        if isempty(numUsersPerRU)
            coder.internal.error('wlan:he:NoUserPerRU',1);
        end
    end

    % Order the RU and users in increasing order of subcarrier frequency
    firstInd = zeros(1,numRUs);
    for i = 1:numRUs
        allInd = wlan.internal.ehtRUSubcarrierIndices(cbw,ruSizes{i},ruIndices{i});
        firstInd(i) = allInd(1);
    end
    [~,sortIdx] = sort(firstInd);

    % Get the user number for each RU (assuming ordered by RU absolute frequency)
    usersPerRU = cell(1,numRUs);
    numUsersPerRU = numUsersPerRU(sortIdx);
    sortedRUIndices = cell(1,numRUs);
    sortedRUSizes = cell(1,numRUs);
    for i = 1:numRUs
        usersPerRU{i} = sum(numUsersPerRU(1:(i-1)))+(1:numUsersPerRU(i));
        sortedRUIndices{i} = ruIndices{sortIdx(i)};
        sortedRUSizes{i} = ruSizes{sortIdx(i)};
    end

    % Get the user number signaled on each subchannel
    usersSignaledPerSubchannel = coder.nullcopy(cell(1,numAssignments));
    coder.varsize('usersSignaledPerSubchannel',[1 16],[0 1]);
    numUsersSignaledPerRU = zeros(1,numRUs);

    for i = 1:numAssignments
        usersSignaledPerSubchannel{i} = zeros(1,0);
        ru = ruNumPerSubchannel{i};
        if isempty(ru)
            continue % No user signaled, skip
        end
        % The RUs are sorted but usersPerRU is based on the pre-sorted
        % value. Therefore index into the sorted list.
        [~,~,ru] = intersect(ru,sortIdx);
        if numel(ru)>1
            % Replace: usersSignaledPerSubchannel{i} = cat(2,usersPerRU{ru}) for codegen below
            temp = zeros(1,0);
            coder.varsize('temp',[1 16],[0 1]);
            for u=1:numel(ru)
                temp = [temp usersPerRU{ru(u)}]; %#ok<AGROW>
            end
            usersSignaledPerSubchannel{i} = temp;
            numUsersSignaledPerRU(ru) = 1; % Multiple RU per subchannel, ASSUME only 1 user per RU (cant be multi-user)
        else
            % Assume users signaled in order, so offset user by number already
            % signaled on RU. Assume if only one RU on a subchannel then all
            % users singaled on this subchannel are in this one RU.
            userIdx = numUsersSignaledPerRU(ru)+(1:numUsersSubchannel(i));
            usersSignaledPerSubchannel{i} = usersPerRU{ru}(userIdx);
            % Count user signaled for this RU
            numUsersSignaledPerRU(ru) = numUsersSignaledPerRU(ru)+numUsersSubchannel(i);
        end
    end

    % Create allocation per 80 MHz segments for 160 MHz and 320 MHz of size
    % M-by-N. For 80 MHz, M=2 and N=8 and for 160 MHz. M=4 and N=16.
    allocationIndexPerSegment = zeros(0,0); % For codegen
    coder.varsize('allocationIndexPerSegment',[4 16],[1 1]);
    isSameEHTSignalling = false; % For codegen
    if isOFDMA
        if any(cbw==[160 320])
            if M==1
                % For N-by-1 or M-by-N with different EHT-SIG content channels per 80 MHz frequency subblock
                numSegments = cbw/80;
                allocationIndexPerSegment = repmat(ruSubchannelAllocation,numSegments,1); % Same EHT SIG contents channels per 80 MHz segment
                                                                                          % Different EHT-SIG content channels per 80 MHz frequency subblock, when input allocationIndex is 1-by-M.
                for s=1:numSegments % Return an M-by-N matrix
                    allocationIndexPerSegment(s,(1:4)+(s-1)*4) = allocationIndexUse((1:4)+(s-1)*4);
                end
            else % Same EHT-SIG content channels per 80 MHz frequency subblock, when input allocationIndex is M-by-N.
                allocationIndexPerSegment = allocationIndex;
                isSameEHTSignalling = true;
            end
        else
            allocationIndexPerSegment = allocationIndex;
        end
    end

    y = struct;
    y.NumUsers = sum(numUsersPerRU);
    y.NumRUs = numRUs;
    y.RUIndices = sortedRUIndices;
    y.RUSizes = sortedRUSizes;
    y.NumUsersPerRU = numUsersPerRU;
    y.PuncturingPattern = puncturingPattern;
    y.NumUsersPerSubchannel = numUsersSubchannel;
    y.RUSubchannelAllocation = ruSubchannelAllocation;
    y.UsersSignaledPerSubchannel = usersSignaledPerSubchannel;
    y.AllocationIndexPerSegment = allocationIndexPerSegment;
    y.ChannelBandwidth = channelBandwidth;
    y.IsSameEHTSignalling = isSameEHTSignalling;

end

function allocStruct = ehtRUAllocationLUT(varargin)
%ehtRUAllocationLUT EHT RU allocation details
%
%   ALLOCSTRUCT = ehtRUAllocationLUT(ASSIGNMENT) returns a structure
%   containing the RU allocation given the assignment index as per IEEE
%   P802.11be/D1.5, Table 36-34

    isOFDMA = true;
    if nargin==2
        assignment = varargin{1};
        first80MHzSubblock = varargin{2};
    else
        isOFDMA = false;
        channelBandwidth = varargin{1};
        numUsers = varargin{2};
        puncturedChannelFieldValue = varargin{3};
        ehtDUPMode = varargin{4};
    end

    allocStruct = struct('NumRUs',0,'NumUsers',0,'RUIndices',0,'RUSizes',0,'IsMRU',false,'NumUsersPerRU',0,'NumUsersPerMRU',0,'PuncturingPattern',false,'RUNumber',0,'MRUIndex',0);
    coder.varsize('allocStruct.PuncturingPattern');

    if isOFDMA % OFDMA
        switch assignment
          case 0
            allocStruct.NumRUs = 9;
            allocStruct.NumUsers = 9;
            allocStruct.RUIndices = [1 2 3 4 5 6 7 8 9];
            allocStruct.RUSizes = [26 26 26 26 26 26 26 26 26];
            allocStruct.IsMRU = [false false false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:9;
            allocStruct.MRUIndex = zeros(1,9);
          case 1
            allocStruct.NumRUs = 8;
            allocStruct.NumUsers = 8;
            allocStruct.RUIndices = [1 2 3 4 5 6 7 4];
            allocStruct.RUSizes = [26 26 26 26 26 26 26 52];
            allocStruct.IsMRU = [false false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:8;
            allocStruct.MRUIndex = zeros(1,8);
          case 2
            allocStruct.NumRUs = 8;
            allocStruct.NumUsers = 8;
            allocStruct.RUIndices = [1 2 3 4 5 3 8 9];
            allocStruct.RUSizes = [26 26 26 26 26 52 26 26];
            allocStruct.IsMRU = [false false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1 ];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:8;
            allocStruct.MRUIndex = zeros(1,8);
          case 3
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 2 3 4 5 3 4];
            allocStruct.RUSizes = [26 26 26 26 26 52 52];
            allocStruct.IsMRU = [false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:7;
            allocStruct.MRUIndex = zeros(1,7);
          case 4
            allocStruct.NumRUs = 8;
            allocStruct.NumUsers = 8;
            allocStruct.RUIndices = [1 2 2 5 6 7 8 9];
            allocStruct.RUSizes = [26 26 52 26 26 26 26 26];
            allocStruct.IsMRU = [false false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:8;
            allocStruct.MRUIndex = zeros(1,8);
          case 5
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 2 2 5 6 7 4];
            allocStruct.RUSizes = [26 26 52 26 26 26 52];
            allocStruct.IsMRU = [false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:7;
            allocStruct.MRUIndex = zeros(1,7);
          case 6
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 2 2 5 3 8 9];
            allocStruct.RUSizes = [26 26 52 26 52 26 26];
            allocStruct.IsMRU = [false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:7;
            allocStruct.MRUIndex = zeros(1,7);
          case 7
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 2 5 3 4];
            allocStruct.RUSizes = [26 26 52 26 52 52];
            allocStruct.IsMRU = [false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:6;
            allocStruct.MRUIndex = zeros(1,6);
          case 8
            allocStruct.NumRUs = 8;
            allocStruct.NumUsers = 8;
            allocStruct.RUIndices = [1 3 4 5 6 7 8 9];
            allocStruct.RUSizes = [52 26 26 26 26 26 26 26];
            allocStruct.IsMRU = [false false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:8;
            allocStruct.MRUIndex = zeros(1,8);
          case 9
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 3 4 5 6 7 4];
            allocStruct.RUSizes = [52 26 26 26 26 26 52];
            allocStruct.IsMRU = [false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:7;
            allocStruct.MRUIndex = zeros(1,7);
          case 10
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 3 4 5 3 8 9];
            allocStruct.RUSizes = [52 26 26 26 52 26 26];
            allocStruct.IsMRU = [false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:7;
            allocStruct.MRUIndex = zeros(1,7);
          case 11
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 3 4 5 3 4];
            allocStruct.RUSizes = [52 26 26 26 52 52];
            allocStruct.IsMRU = [false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:6;
            allocStruct.MRUIndex = zeros(1,6);
          case 12
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 2 5 6 7 8 9];
            allocStruct.RUSizes = [52 52 26 26 26 26 26];
            allocStruct.IsMRU = [false false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:7;
            allocStruct.MRUIndex = zeros(1,7);
          case 13
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 5 6 7 4];
            allocStruct.RUSizes = [52 52 26 26 26 52];
            allocStruct.IsMRU = [false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:6;
            allocStruct.MRUIndex = zeros(1,6);
          case 14
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 5 3 8 9];
            allocStruct.RUSizes = [52 52 26 52 26 26];
            allocStruct.IsMRU = [false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:6;
            allocStruct.MRUIndex = zeros(1,6);
          case 15
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 2 5 3 4];
            allocStruct.RUSizes = [52 52 26 52 52];
            allocStruct.IsMRU = [false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:5;
            allocStruct.MRUIndex = zeros(1,5);
          case 16
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 3 4 5 2];
            allocStruct.RUSizes = [26 26 26 26 26 106];
            allocStruct.IsMRU = [false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:6;
            allocStruct.MRUIndex = zeros(1,6);
          case 17
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 2 2 5 2];
            allocStruct.RUSizes = [26 26 52 26 106];
            allocStruct.IsMRU = [false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:5;
            allocStruct.MRUIndex = zeros(1,5);
          case 18
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 3 4 5 2];
            allocStruct.RUSizes = [52 26 26 26 106];
            allocStruct.IsMRU = [false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:5;
            allocStruct.MRUIndex = zeros(1,5);
          case 19
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 2 5 2];
            allocStruct.RUSizes = [52 52 26 106];
            allocStruct.IsMRU = [false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:4;
            allocStruct.MRUIndex = zeros(1,4);
          case 20
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 5 6 7 8 9];
            allocStruct.RUSizes = [106 26 26 26 26 26];
            allocStruct.IsMRU = [false false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:6;
            allocStruct.MRUIndex = zeros(1,6);
          case 21
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 5 6 7 4];
            allocStruct.RUSizes = [106 26 26 26 52];
            allocStruct.IsMRU = [false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:5;
            allocStruct.MRUIndex = zeros(1,5);
          case 22
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 5 3 8 9];
            allocStruct.RUSizes = [106 26 52 26 26];
            allocStruct.IsMRU = [false false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:5;
            allocStruct.MRUIndex = zeros(1,5);
          case 23
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 5 3 4];
            allocStruct.RUSizes = [106 26 52 52];
            allocStruct.IsMRU = [false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:4;
            allocStruct.MRUIndex = zeros(1,4);
          case 24
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 2 3 4];
            allocStruct.RUSizes = [52 52 52 52];
            allocStruct.IsMRU = [false false false false];
            allocStruct.NumUsersPerRU = [1 1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:4;
            allocStruct.MRUIndex = zeros(1,4);
          case 25
            allocStruct.NumRUs = 3;
            allocStruct.NumUsers = 3;
            allocStruct.RUIndices = [1 5 2];
            allocStruct.RUSizes = [106 26 106];
            allocStruct.IsMRU = [false false false];
            allocStruct.NumUsersPerRU = [1 1 1];
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1:3;
            allocStruct.MRUIndex = zeros(1,3);
          case 26
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 242;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
          case 27
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 242;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
          case 28
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 242;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
          case 29
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 484;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
          case 30
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 996;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
          case 31 % Validation
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 242;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
          case 32 % MRU 3
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 2 3 4 5 3 8 9];
            allocStruct.RUSizes = [26 26 26 26 26 52 26 26];
            allocStruct.IsMRU = [false false false false false true true false];
            allocStruct.NumUsersPerRU = [1 1 1 1 1 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:5 6 6 7];
            allocStruct.MRUIndex = [0 0 0 0 0 3 3 0];
          case 33 % MRU 3
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 2 5 3 8 9];
            allocStruct.RUSizes = [26 26 52 26 52 26 26];
            allocStruct.IsMRU = [false false false false true true false];
            allocStruct.NumUsersPerRU = [1 1 1 1 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:4 5 5 6];
            allocStruct.MRUIndex = [0 0 0 0 3 3 0];
          case 34 % MRU 3
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 3 4 5 3 8 9];
            allocStruct.RUSizes = [52 26 26 26 52 26 26];
            allocStruct.IsMRU = [false false false false true true false];
            allocStruct.NumUsersPerRU = [1 1 1 1 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:4 5 5 6];
            allocStruct.MRUIndex = [0 0 0 0 3 3 0];
          case 35 % MRU 3
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 2 5 3 8 9];
            allocStruct.RUSizes = [52 52 26 52 26 26];
            allocStruct.IsMRU = [false false false true true false];
            allocStruct.NumUsersPerRU = [1 1 1 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:3 4 4 5];
            allocStruct.MRUIndex = [0 0 0 3 3 0];
          case 36 % MRU 1
            allocStruct.NumRUs = 7;
            allocStruct.NumUsers = 7;
            allocStruct.RUIndices = [1 2 2 5 6 7 8 9];
            allocStruct.RUSizes = [26 26 52 26 26 26 26 26];
            allocStruct.IsMRU = [false true true false false false false false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 1 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3:7];
            allocStruct.MRUIndex = [0 1 1 0 0 0 0 0];
          case 37 % MRU 1
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 2 5 6 7 4];
            allocStruct.RUSizes = [26 26 52 26 26 26 52];
            allocStruct.IsMRU = [false true true false false false false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3:6];
            allocStruct.MRUIndex = [0 1 1 0 0 0 0];
          case 38 % MRU 1
            allocStruct.NumRUs = 6;
            allocStruct.NumUsers = 6;
            allocStruct.RUIndices = [1 2 2 5 3 8 9];
            allocStruct.RUSizes = [26 26 52 26 52 26 26];
            allocStruct.IsMRU = [false true true false false false false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3:6];
            allocStruct.MRUIndex = [0 1 1 0 0 0 0];
          case 39 % MRU 1
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 2 2 5 3 4];
            allocStruct.RUSizes = [26 26 52 26 52 52];
            allocStruct.IsMRU = [false true true false false false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3:5];
            allocStruct.MRUIndex = [0 1 1 0 0 0];
          case 40 % MRU 2
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1  2  3  4  5  2];
            allocStruct.RUSizes = [26 26 26 26 26 106];
            allocStruct.IsMRU = [false false false false  true true];
            allocStruct.NumUsersPerRU = [1 1 1 1 0.5 0.5];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:4 5 5];
            allocStruct.MRUIndex = [0 0 0 0 2 2];
          case 41 % MRU 2
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 2 2 5 2];
            allocStruct.RUSizes = [26 26 52 26 106];
            allocStruct.IsMRU = [false false false true true];
            allocStruct.NumUsersPerRU = [1 1 1 0.5 0.5];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:3 4 4];
            allocStruct.MRUIndex = [0 0 0 2 2];
          case 42 % MRU 2
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 3 4 5 2];
            allocStruct.RUSizes = [52 26 26 26 106];
            allocStruct.IsMRU = [false false false true true];
            allocStruct.NumUsersPerRU = [1 1 1 0.5 0.5];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1:3 4 4];
            allocStruct.MRUIndex = [0 0 0 2 2];
          case 43 % MRU 2
            allocStruct.NumRUs = 3;
            allocStruct.NumUsers = 3;
            allocStruct.RUIndices = [1 2 5 2];
            allocStruct.RUSizes = [52 52 26 106];
            allocStruct.IsMRU = [false false true true];
            allocStruct.NumUsersPerRU = [1 1 0.5 0.5];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 3 3];
            allocStruct.MRUIndex = [0 0 2 2];
          case 44 % MRU 1
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 5 6 7 8 9];
            allocStruct.RUSizes = [106 26 26 26 26 26];
            allocStruct.IsMRU = [true true false false false false];
            allocStruct.NumUsersPerRU = [0.5 0.5 1 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 1 2:5];
            allocStruct.MRUIndex = [1 1 0 0 0 0];
          case 45 % MRU 1
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 5 6 7 4];
            allocStruct.RUSizes = [106 26 26 26 52];
            allocStruct.IsMRU = [true true false false false];
            allocStruct.NumUsersPerRU = [0.5 0.5 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 1 2:4];
            allocStruct.MRUIndex = [1 1 0 0 0];
          case 46 % MRU 1
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 5 3 8 9];
            allocStruct.RUSizes = [106 26 52 26 26];
            allocStruct.IsMRU = [true true false false false];
            allocStruct.NumUsersPerRU = [0.5 0.5 1 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 1 2:4];
            allocStruct.MRUIndex = [1 1 0 0 0];
          case 47 % MRU 1
            allocStruct.NumRUs = 3;
            allocStruct.NumUsers = 3;
            allocStruct.RUIndices = [1 5 3 4];
            allocStruct.RUSizes = [106 26 52 52];
            allocStruct.IsMRU = [true true false false];
            allocStruct.NumUsersPerRU = [0.5 0.5 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 1 2 3];
            allocStruct.MRUIndex = [1 1 0 0];
          case 48 % MRU 1
            allocStruct.NumRUs = 2;
            allocStruct.NumUsers = 2;
            allocStruct.RUIndices = [1 5 2];
            allocStruct.RUSizes = [106 26 106];
            allocStruct.IsMRU = [true true false];
            allocStruct.NumUsersPerRU = [0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 1 2];
            allocStruct.MRUIndex = [1 1 0];
          case 49 % MRU 1
            allocStruct.NumRUs = 3;
            allocStruct.NumUsers = 3;
            allocStruct.RUIndices = [1 5 3 8 9];
            allocStruct.RUSizes = [106 26 52 26 26];
            allocStruct.IsMRU = [true true true true false];
            allocStruct.NumUsersPerRU = [0.5 0.5 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 1 2 2 3];
            allocStruct.MRUIndex = [1 1 3 3 0];
          case 50 % MRU 2
            allocStruct.NumRUs = 2;
            allocStruct.NumUsers = 2;
            allocStruct.RUIndices = [1 5 2];
            allocStruct.RUSizes = [106 26 106];
            allocStruct.IsMRU = [false true true];
            allocStruct.NumUsersPerRU = [1 0.5 0.5];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2];
            allocStruct.MRUIndex = [0 2 2];
          case 51 % MRU 2
            allocStruct.NumRUs = 3;
            allocStruct.NumUsers = 3;
            allocStruct.RUIndices = [1 2 2 5 2];
            allocStruct.RUSizes = [26 26 52 26 106];
            allocStruct.IsMRU = [false true true true true];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 0.5 0.5];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3 3];
            allocStruct.MRUIndex = [0 1 1 2 2];
          case 52 % MRU 3
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 5 3 8 9];
            allocStruct.RUSizes = [106 26 52 26 26];
            allocStruct.IsMRU = [false false true true false];
            allocStruct.NumUsersPerRU = [1 1 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 3 3 4];
            allocStruct.MRUIndex = [0 0 3 3 0];
          case 53 % MRU 1
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 2 2 5 2];
            allocStruct.RUSizes = [26 26 52 26 106];
            allocStruct.IsMRU = [false true true false false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3 4];
            allocStruct.MRUIndex = [0 1 1 0 0];
          case 54 % MRU 1 & MRU 3
            allocStruct.NumRUs = 5;
            allocStruct.NumUsers = 5;
            allocStruct.RUIndices = [1 2 2 5 3 8 9];
            allocStruct.RUSizes = [26 26 52 26 52 26 26];
            allocStruct.IsMRU = [false true true false true true false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 0.5 0.5 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3 4 4 5];
            allocStruct.MRUIndex = [0 1 1 0 3 3 0];
          case 55 % MRU 2
            allocStruct.NumRUs = 4;
            allocStruct.NumUsers = 4;
            allocStruct.RUIndices = [1 2 5 3 4];
            allocStruct.RUSizes = [52 52 26 52 52];
            allocStruct.IsMRU = [false true true false false];
            allocStruct.NumUsersPerRU = [1 0.5 0.5 1 1];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.RUNumber = [1 2 2 3 4];
            allocStruct.MRUIndex = [0 2 2 0 0];
          case 56 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 57 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 58 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 59 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 60 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 61 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 62 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case 63 % Validation
            allocStruct.NumRUs = 0;
            allocStruct.NumUsers = 0;
            allocStruct.RUIndices = 0;
            allocStruct.RUSizes = 0;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = 0;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.RUNumber = 0;
            allocStruct.MRUIndex = 0;
          case {64 65 66 67 68 69 70 71} % Full allocation for CBW20
            allocStruct = ehtRUAllocationNonOFDMA('CBW20',(assignment-64)+1,0);
          case {72 73 74 75 76 77 78 79} % Full allocation for CBW40
            allocStruct = ehtRUAllocationNonOFDMA('CBW40',(assignment-72)+1,0);
          case {80 81 82 83 84 85 86 87} % Full allocation for CBW80
            allocStruct = ehtRUAllocationNonOFDMA('CBW80',(assignment-80)+1,0);
          case {88 89 90 91 92 93 94 95} % Full allocation for CBW160
            allocStruct = ehtRUAllocationNonOFDMA('CBW160',(assignment-88)+1,0);
          case {96 97 98 99 100 101 102 103} % []-242-484 (MRU1)
            allocStruct = ehtRUAllocationNonOFDMA('CBW80',(assignment-96)+1,1);
          case {104 105 106 107 108 109 110 111} % 242-[]-484 (MRU2)
            allocStruct = ehtRUAllocationNonOFDMA('CBW80',(assignment-104)+1,2);
          case {112 113 114 115 116 117 118 119} % 484-[]-242 (MRU3)
            allocStruct = ehtRUAllocationNonOFDMA('CBW80',(assignment-112)+1,3);
          case {120 121 122 123 124 125 126 127} % 484-242-[] (MRU4)
            allocStruct = ehtRUAllocationNonOFDMA('CBW80',(assignment-120)+1,4);
          case {128 129 130 131 132 133 134 135} % []-484-996 (MRU1)
            allocStruct = ehtRUAllocationNonOFDMA('CBW160',(assignment-128)+1,9);
          case {136 137 138 139 140 141 142 143} % 484-[]-996 (MRU2)
            allocStruct = ehtRUAllocationNonOFDMA('CBW160',(assignment-136)+1,10);
          case {144 145 146 147 148 149 150 151} % 996-[]-484 (MRU3)
            allocStruct = ehtRUAllocationNonOFDMA('CBW160',(assignment-144)+1,11);
          case {152 153 154 155 156 157 158 159} % 996-[]-484 (MRU4)
            allocStruct = ehtRUAllocationNonOFDMA('CBW160',(assignment-152)+1,12);
          case {160 161 162 163 164 165 166 167} % []-996-996-996 (MRU1)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-160)+1,9);
          case {168 169 170 171 172 173 174 175} % 996-[]-996-996 (MRU2)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-168)+1,10);
          case {176 177 178 179 180 181 182 183} % 996-996-[]-996 (MRU3)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-176)+1,11);
          case {184 185 186 187 188 189 190 191} % 996-996-996-[] (MRU4)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-184)+1,12);
          case {192 193 194 195 196 197 198 199} % []-484-996-996-996 (MRU1)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-192)+1,1);
          case {200 201 202 203 204 205 206 207} % 484-[]-996-996-996 (MRU2)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-200)+1,2);
          case {208 209 210 211 212 213 214 215} % 996-[]-484-996-996 (MRU3)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-208)+1,3);
          case {216 217 218 219 220 221 222 223} % 996-484-[]-996-996 (MRU4)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-216)+1,4);
          case {224 225 226 227 228 229 230 231} % 996-996-[]-484-996 (MRU5)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-224)+1,5);
          case {232 233 234 235 236 237 238 239} % 996-996-484-[]-996 (MRU6)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-232)+1,6);
          case {240 241 242 243 244 245 246 247} % 996-996-996-[]-484 (MRU7)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-240)+1,7);
          case {248 249 250 251 252 253 254 255} % 996-996-996-484-[] (MRU8)
            allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-248)+1,8);
          case {256 257 258 259 260 261 262 263} % []-484-996-996 (MRU1, MRU7) corresponding puncturedChannelFieldValue 19, 13.
            if first80MHzSubblock % puncturedChannelFieldValue 19
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-256)+1,19);
            else % puncturedChannelFieldValue 13
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-256)+1,13);
            end
          case {264 265 266 267 268 269 270 271} % 484-[]-996-996 (MRU2, MRU8) corresponding puncturedChannelFieldValue 20, 14.
            if first80MHzSubblock  % puncturedChannelFieldValue 20
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-264)+1,20);
            else % puncturedChannelFieldValue 14
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-264)+1,14);
            end
          case {272 273 274 275 276 277 278 279} % 996-[]-484-996 (MRU3, MRU9) corresponding puncturedChannelFieldValue 21, 15.
            if first80MHzSubblock % puncturedChannelFieldValue 21
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-272)+1,21);
            else % puncturedChannelFieldValue 15
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-272)+1,15);
            end
          case {280 281 282 283 284 285 286 287} % 996-484-[]-996 (MRU4, MRU10)
            if first80MHzSubblock % puncturedChannelFieldValue 22
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-280)+1,22);
            else % puncturedChannelFieldValue 16
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-280)+1,16);
            end
            allocStruct.PuncturingPattern = false(0,1); % Puncturing pattern is not defined for OFDMA
          case {288 289 290 291 292 293 294 295} % 996-996-[]-484 (MRU5, MRU11)
            if first80MHzSubblock % puncturedChannelFieldValue 23
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-288)+1,23);
            else % puncturedChannelFieldValue 17
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-288)+1,17);
            end
            allocStruct.PuncturingPattern = false(0,1); % Puncturing pattern is not defined for OFDMA
          case {296 297 298 299 300 301 302 303} % 996-996-484-[] (MRU6, MRU12)
            if first80MHzSubblock % puncturedChannelFieldValue 24
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-296)+1,24);
            else % puncturedChannelFieldValue 18
                allocStruct = ehtRUAllocationNonOFDMA('CBW320',(assignment-296)+1,18);
            end
        end
    else % non-OFDMA
        allocStruct = ehtRUAllocationNonOFDMA(channelBandwidth,numUsers,puncturedChannelFieldValue);
        if ehtDUPMode && strcmp(channelBandwidth,'CBW80')
            allocStruct.RUSizes = 968; % Treat as single 2x484-tone RU
        end
    end
    % Basic test
    assert(allocStruct.RUNumber(end)==allocStruct.NumRUs);
    assert(numel(allocStruct.RUNumber)==numel(allocStruct.RUSizes));
end

function allocStruct = ehtRUAllocationNonOFDMA(channelBandwidth,numUsers,puncturedChannelFieldValue)
%ehtRUAllocationNonOFDMA Get allocation index and puncturing pattern for a
%given bandwidth as specified in Table 36-30 and Table 36-34 of IEEE
%P802.11be/D1.5.

    switch channelBandwidth
      case 'CBW20'
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = numUsers;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 242;
        allocStruct.IsMRU = false;
        allocStruct.NumUsersPerRU = numUsers;
        allocStruct.NumUsersPerMRU = 0;
        allocStruct.PuncturingPattern = false;
        allocStruct.RUNumber = 1;
        allocStruct.MRUIndex = 0;
      case 'CBW40'
        allocStruct.NumRUs = 1;
        allocStruct.NumUsers = numUsers;
        allocStruct.RUIndices = 1;
        allocStruct.RUSizes = 484;
        allocStruct.IsMRU = false;
        allocStruct.NumUsersPerRU = numUsers;
        allocStruct.NumUsersPerMRU = 0;
        allocStruct.PuncturingPattern = false;
        allocStruct.RUNumber = 1;
        allocStruct.MRUIndex = 0;
      case 'CBW80'
        if puncturedChannelFieldValue==0 % No puncturing
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 996;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = numUsers;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.PuncturingPattern = false(1,4);
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
        elseif puncturedChannelFieldValue==1 % []-242-484 (MRU1)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [2 2];
            allocStruct.RUSizes = [242 484];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [true false false false];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [1 1];
        elseif puncturedChannelFieldValue==2 % 242-[]-484 (MRU2)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2];
            allocStruct.RUSizes = [242 484];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false true false false];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [2 2];
        elseif puncturedChannelFieldValue==3 % 484-[]-242 (MRU3)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 4];
            allocStruct.RUSizes = [484 242];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false true false];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [3 3];
        else % puncturedChannelFieldValue==4 % 484-242-[] (MRU4)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3];
            allocStruct.RUSizes = [484 242];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false true];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [4 4];
        end
      case 'CBW160'
        if puncturedChannelFieldValue==0
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 1992;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = numUsers;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.PuncturingPattern = [false false false false false false false false];
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
        elseif puncturedChannelFieldValue==1 % []-242-484-996 (MRU1)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [2 2 2];
            allocStruct.RUSizes = [242 484 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [true false false false false false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [1 1 1];
        elseif puncturedChannelFieldValue==2 % 242-[]-484-996 (MRU2)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 2];
            allocStruct.RUSizes = [242 484 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false true false false false false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [2 2 2];
        elseif puncturedChannelFieldValue==3 % 484-[]-242-996 (MRU3)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 4 2];
            allocStruct.RUSizes = [484 242 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false true false false false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [3 3 3];
        elseif puncturedChannelFieldValue==4 % 484-242-[]-996 (MRU4)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3 2];
            allocStruct.RUSizes = [484 242 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false true false false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [4 4 4];
        elseif puncturedChannelFieldValue==5 % 996-[]-242-484 (MRU5)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 6 4];
            allocStruct.RUSizes = [996 242 484];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false true false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [5 5 5];
        elseif puncturedChannelFieldValue==6 % 996-242-[]-484 (MRU6)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 5 4];
            allocStruct.RUSizes = [996 242 484];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false true false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [6 6 6];
        elseif puncturedChannelFieldValue==7 % 996-484-[]-242 (MRU7)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3 8];
            allocStruct.RUSizes = [996 484 242];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false false true false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [7 7 7];
        elseif puncturedChannelFieldValue==8 % 996-484-242-[] (MRU8)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3 7];
            allocStruct.RUSizes = [996 484 242];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false false false true];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [8 8 8];
        elseif puncturedChannelFieldValue==9 % []-484-996 (MRU1), Figure 36-12
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [2 2];
            allocStruct.RUSizes = [484 996];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = 1;
            allocStruct.PuncturingPattern = [true true false false false false false false];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [1 1];
        elseif puncturedChannelFieldValue==10 % 484-[]-996 (MRU2)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2];
            allocStruct.RUSizes = [484 996];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false true true false false false false];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [2 2];
        elseif puncturedChannelFieldValue==11 % 996-[]-484 (MRU3)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 4];
            allocStruct.RUSizes = [996 484];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false true true false false];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [3 3];
        else % puncturedChannelFieldValue==12 % 996-484-[] (MRU4)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3];
            allocStruct.RUSizes = [996 484];
            allocStruct.IsMRU = [true true];
            allocStruct.NumUsersPerRU = [numUsers/2 numUsers/2];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false false true true];
            allocStruct.RUNumber = [1 1];
            allocStruct.MRUIndex = [4 4];
        end
      otherwise % CBW320
        if puncturedChannelFieldValue==0
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = 1;
            allocStruct.RUSizes = 3984;
            allocStruct.IsMRU = false;
            allocStruct.NumUsersPerRU = numUsers;
            allocStruct.NumUsersPerMRU = 0;
            allocStruct.PuncturingPattern = false(1,8);
            allocStruct.RUNumber = 1;
            allocStruct.MRUIndex = 0;
        elseif puncturedChannelFieldValue==1 % []-484-996-996-996 (MRU1)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [2 2 3 4];
            allocStruct.RUSizes = [484 996 996 996];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [true false false false false false false false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [1 1 1 1];
        elseif puncturedChannelFieldValue==2 % 484-[]-996-996-996 (MRU2)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 3 4];
            allocStruct.RUSizes = [484 996 996 996];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false true false false false false false false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [2 2 2 2];
        elseif puncturedChannelFieldValue==3 % 996-[]-484-996-996 (MRU3)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 4 3 4];
            allocStruct.RUSizes = [996 484 996 996];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false true false false false false false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [3 3 3 3];
        elseif puncturedChannelFieldValue==4 % 996-484-[]-996-996 (MRU4)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3 3 4];
            allocStruct.RUSizes = [996 484 996 996];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false true false false false false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [4 4 4 4];
        elseif puncturedChannelFieldValue==5 % 996-996-[]-484-996 (MRU5)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 6 4];
            allocStruct.RUSizes = [996 996 484 996];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false true false false false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [5 5 5 5];
        elseif puncturedChannelFieldValue==6 % 996-996-484-[]-996 (MRU6)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 5 4];
            allocStruct.RUSizes = [996 996 484 996];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false true false false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [6 6 6 6];
        elseif puncturedChannelFieldValue==7 % 996-996-996-[]-484 (MRU7)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 3 8];
            allocStruct.RUSizes = [996 996 996 484];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false false true false];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [7 7 7 7];
        elseif puncturedChannelFieldValue==8 % 996-996-996-484-[] (MRU8)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 3 7];
            allocStruct.RUSizes = [996 996 996 484];
            allocStruct.IsMRU = [true true true true];
            allocStruct.NumUsersPerRU = [numUsers/4 numUsers/4 numUsers/4 numUsers/4];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false false false true];
            allocStruct.RUNumber = [1 1 1 1];
            allocStruct.MRUIndex = [8 8 8 8];
        elseif puncturedChannelFieldValue==9 % []-996-996-996 (MRU1)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [2 3 4];
            allocStruct.RUSizes = [996 996 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [true true false false false false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [1 1 1];
        elseif puncturedChannelFieldValue==10 % 996-[]-996-996 (MRU2)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 3 4];
            allocStruct.RUSizes = [996 996 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false true true false false false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [2 2 2];
        elseif puncturedChannelFieldValue==11 % 996-996-[]-996 (MRU3)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 4];
            allocStruct.RUSizes = [996 996 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false true true false false];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [3 3 3];
        elseif puncturedChannelFieldValue==12 % 996-996-996-[] (MRU4)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            allocStruct.RUIndices = [1 2 3];
            allocStruct.RUSizes = [996 996 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = [false false false false false false true true];
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = [4 4 4];
        elseif any(puncturedChannelFieldValue==[13 19]) % []-484-996-996 (MRU1, MRU7)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            if puncturedChannelFieldValue==13 % ~first80MHzSubblock. MRU7: 80 MHz Subblock 2, 3 and 4
                ruIndices = [4 3 4];
                puncturingPattern = [true true true false false false false false];
                mruIndex = [7 7 7]; % MRU 7
            else % puncturedChannelFieldValue 19. % MRU1: 80 MHz Subblock 1, 2 and 3
                ruIndices = [2 2 3];
                puncturingPattern = [true false false false false false true true];
                mruIndex = [1 1 1]; % MRU 1
            end
            allocStruct.RUIndices = ruIndices;
            allocStruct.RUSizes = [484 996 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = puncturingPattern;
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = mruIndex;
        elseif any(puncturedChannelFieldValue==[14 20]) % 484-[]-996-996 (MRU2, MRU8)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            if puncturedChannelFieldValue==14 % ~first80MHzSubblock. MRU8: 80 MHz Subblock 2, 3 and 4
                ruIndices = [3 3 4];
                puncturingPattern = [true true false true false false false false];
                mruIndex = [8 8 8]; % MRU 8
            else % puncturedChannelFieldValue 20. MRU2: 80 MHz Subblock 1, 2 and 3
                ruIndices = [1 2 3];
                puncturingPattern = [false true false false false false true true];
                mruIndex = [2 2 2]; % MRU 2
            end
            allocStruct.RUIndices = ruIndices;
            allocStruct.RUSizes = [484 996 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = puncturingPattern;
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = mruIndex;
        elseif any(puncturedChannelFieldValue==[15 21]) % 996-[]-484-996 (MRU3, MRU9)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            if puncturedChannelFieldValue==15 % ~first80MHzSubblock. MRU9: 80 MHz Subblock 2, 3 and 4
                ruIndices = [2 6 4];
                puncturingPattern = [true true false false true false false false];
                mruIndex = [9 9 9]; % MRU 9
            else % MRU3: 80 MHz Subblock 1, 2 and 3
                ruIndices = [1 4 3];
                puncturingPattern = [false false true false false false true true];
                mruIndex = [3 3 3]; % MRU 3
            end
            allocStruct.RUIndices = ruIndices;
            allocStruct.RUSizes = [996 484 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = puncturingPattern;
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = mruIndex;
        elseif any(puncturedChannelFieldValue==[16 22]) % 996-484-[]-996 (MRU4, MRU10)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            if puncturedChannelFieldValue==16 % ~first80MHzSubblock. MRU10: 80 MHz Subblock 2, 3 and 4
                ruIndices = [2 5 4];
                puncturingPattern = [true true false false false true false false];
                mruIndex = [10 10 10]; % MRU 10
            else % MRU4: 80 MHz Subblock 1, 2 and 3
                ruIndices = [1 3 3];
                puncturingPattern = [false false false true false false true true];
                mruIndex = [4 4 4]; % MRU 4
            end
            allocStruct.RUIndices = ruIndices;
            allocStruct.RUSizes = [996 484 996];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = puncturingPattern;
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = mruIndex;
        elseif any(puncturedChannelFieldValue==[17 23]) % 996-996-[]-484 (MRU5, MRU11)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            if puncturedChannelFieldValue==17 % ~first80MHzSubblock. MRU11: 80 MHz Subblock 2, 3 and 4
                ruIndices = [2 3 8];
                puncturingPattern = [true true false false false false true false];
                mruIndex = [11 11 11]; % MRU 11
            else % MRU5: 80 MHz Subblock 1, 2 and 3
                ruIndices = [1 2 6];
                puncturingPattern = [false false false false true false true true];
                mruIndex = [5 5 5]; % MRU 5
            end
            allocStruct.RUIndices = ruIndices;
            allocStruct.RUSizes = [996 996 484];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = puncturingPattern;
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = mruIndex;
        else % any(puncturedChannelFieldValue==[18 24]) % 996-996-[]-484 (MRU6, MRU12)
            allocStruct.NumRUs = 1;
            allocStruct.NumUsers = numUsers;
            if puncturedChannelFieldValue==18 % ~first80MHzSubblock. MRU12: 80 MHz Subblock 2, 3 and 4
                ruIndices = [2 3 7];
                puncturingPattern = [true true false false false false false true];
                mruIndex = [12 12 12]; % MRU 12
            else % puncturedChannelFieldValue 24. % MRU6: 80 MHz Subblock 1, 2 and 3
                ruIndices = [1 2 5];
                puncturingPattern = [false false false false false true true true];
                mruIndex = [6 6 6]; % MRU 6
            end
            allocStruct.RUIndices = ruIndices;
            allocStruct.RUSizes = [996 996 484];
            allocStruct.IsMRU = [true true true];
            allocStruct.NumUsersPerRU = [numUsers/3 numUsers/3 numUsers/3];
            allocStruct.NumUsersPerMRU = numUsers;
            allocStruct.PuncturingPattern = puncturingPattern;
            allocStruct.RUNumber = [1 1 1];
            allocStruct.MRUIndex = mruIndex;
        end
    end
end

function f = inAllocation(allocationIndex,indices)
%inAllocation returns true if any element of indices is present in the vector allocationIndex
    f = any(allocationIndex==indices','all');
end
