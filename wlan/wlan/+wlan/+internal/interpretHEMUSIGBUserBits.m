function [user,failInterpretation] = interpretHEMUSIGBUserBits(bits,invalidContentCh,failCRC,cfg,varargin)
%interpretHEMUSIGBUserBits Interpret HE-SIG-B user field bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [USER,FAILINTERPRETATION] = interpretHEMUSIGBUserBits(USERBITS,INVALIDCONTENTCH,FAILCRC,CFG)
%   interpret HE-SIG-B user field bits. The returned USER is a cell array
%   of size 1-by-NumUsers. USER is the updated format configuration object
%   after HE-SIG-B user field decoding, of type <a href="matlab:help('wlanHERecoveryConfig')">wlanHERecoveryConfig</a>.
%   When you use this syntax and the function cannot interpret the
%   recovered HE-SIG-B user field bits, due to an unexpected value, an
%   exception is issued and the function does not return.
%
%   BITS is an int8 matrix of size 21-by-NumUsers, where NumUsers is the
%   number of users in the transmission, containing the recovered user
%   field bits for all users.
%
%   INVALIDCONTENTCH represents the status of SIGB content channel and is a
%   logical row vector of length 1-by-NumContentCh.
%
%   FAILCRC is a logical row vector of length NumUsers representing the
%   CRC result for each user. It is true if the user fails the CRC. It
%   is a logical row vector of size 1-by-NumUsers.
%
%   [...] = interpretHEMUSIGBUserBits(...,SUPPRESSERROR) controls the
%   behavior of the function due to an unexpected value of the interpreted
%   HE-SIG-B user field bits. SUPPRESSERROR is logical. When SUPPRESSERROR
%   is true and the function cannot interpret the recovered HE-SIG-B user
%   field bits due to an unexpected value, the function returns
%   FAILINTERPRETATION as true and the returned object is unchanged for the
%   user. When SUPPRESSERROR is false and the function cannot interpret the
%   recovered HE-SIG-B user field bits due to an unexpected value, an
%   exception is issued and the function does not return. The default is
%   false.

%   Copyright 2020-2023 The MathWorks, Inc.

%#codegen

nargoutchk(1,2);
suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
if nargin>4
    suppressError = varargin{1};
end

numUsers = size(bits,2); % Number of users
ruAllocation = cfg.AllocationIndex;
sigbCompression = cfg.SIGBCompression;

% The length of AllocationIndex must be 1, 2, 4, or 8, defining the
% assignment for each 20 MHz subchannel in a 20 MHz, 40 MHz, 80 MHz or 160
% MHz channel bandwidth.
chbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
numAllocations = chbw/20; % Length of allocation index
userValid = true(size(failCRC));

if sigbCompression
    % No common field is present
    if numUsers>1
        mumimoAllocation = true(1,numUsers); % All users in MU-MIMO
    else
        mumimoAllocation = false; % One user so not MU-MIMO
    end
    % Number of users this current user shared with
    totalNumUsers = numUsers*ones(1,numUsers);
    userNumWithinRU = 1:numUsers;
    allocInfo = wlan.internal.heAllocationInfo(cfg.AllocationIndex);
    ruSize = allocInfo.RUSizes;
    ruIndex = allocInfo.RUIndices;
    ruNumber = ones(1,numUsers); % For codegen
    if any(failCRC)
       % If any user fail the CRC than it is not possible to recover the
       % spatial mapping information of other users
       userValid = false(size(failCRC));
    end
    % Get mapping of the users within each content channel. This
    % information is required to map the users in the same sequence as used
    % in HE-SIG-B user field encoding as per IEEE Std 802.11ax-2021,
    % Section 27.3.11.8.
    contentChUsers = usersPerContentChannel(ruAllocation,invalidContentCh,sigbCompression,cfg);
else
    if all(invalidContentCh==0)
        % All content channels are valid. Process user bits on all content channels
        allocationPerContentCh = 0;
        if chbw==160
           wlan.internal.mustBeDefined(cfg.LowerCenter26ToneRU,'LowerCenter26ToneRU');
           wlan.internal.mustBeDefined(cfg.UpperCenter26ToneRU,'UpperCenter26ToneRU');
           center26ToneRU = [cfg.LowerCenter26ToneRU cfg.UpperCenter26ToneRU]; 
        elseif chbw==80
           % Both content channels carry the Center26ToneRU information.
           % Since both content channels are valid, any content channel can
           % be used to extract Center26ToneRU information.
           wlan.internal.mustBeDefined(cfg.LowerCenter26ToneRU,'LowerCenter26ToneRU');
           center26ToneRU = cfg.LowerCenter26ToneRU;
        else % CBW20 and CBW40
           center26ToneRU = 0; % No Center26ToneRU in CBW20 and CBW40
        end
    elseif invalidContentCh(1)==0
        % Content channel-1 is valid for CBW 40/80/160. Process user bits
        % on content channel-1.
        if chbw==40 && (size(ruAllocation,2)==2)
            center26ToneRU = 0; % No Center26ToneRU in CBW40
            % Get the allocation index indicated by content channel-1
            allocationPerContentCh = ruAllocation(1);
        elseif chbw==80 && (size(ruAllocation,2)==4)
            wlan.internal.mustBeDefined(cfg.LowerCenter26ToneRU,'LowerCenter26ToneRU');
            center26ToneRU = cfg.LowerCenter26ToneRU;
            % Get the allocation index indicated by content channel-1
            allocationPerContentCh = [ruAllocation(1) ruAllocation(3)];
            % Replace allocation index 114 with 113
            [~,emptyRULocation] = find(allocationPerContentCh==114);
            allocationPerContentCh(emptyRULocation) = 113;
        else % chbw==160 && (size(ruAllocation,2)==8)
            % No UpperCenter26ToneRU user information due to invalid content channel-2
            wlan.internal.mustBeDefined(cfg.LowerCenter26ToneRU,'LowerCenter26ToneRU');
            center26ToneRU = [cfg.LowerCenter26ToneRU 0];
            % Get the allocation index indicated by content channel-1
            allocationPerContentCh = [ruAllocation(1) ruAllocation(3) ruAllocation(5) ruAllocation(7)];
        end
    else
        % Content channel-2 is valid for CBW 40/80/160. Process user bits
        % on content channel-2.
        if chbw==40 && (size(ruAllocation,2)==2)
            center26ToneRU = 0; % No Center26ToneRU in CBW40
            % Get the allocation index indicated by content channel-2
            allocationPerContentCh = ruAllocation(2); %cfg.AllocationIndex(2);
        elseif chbw==80 && (size(ruAllocation,2)==4)
            center26ToneRU = 0; % No user in content channel-2 for CBW80
            % Get the allocation index indicated by content channel-2
            allocationPerContentCh = [ruAllocation(2) ruAllocation(4)];
            % Replace allocation index 114 with 113
            [~,emptyRULocation] = find(allocationPerContentCh==114);
            allocationPerContentCh(emptyRULocation) = 113;
        else % chbw==160 && (size(ruAllocation,2)==8)
            % No LowerCenter26ToneRU user information due to invalid content channel-1
            wlan.internal.mustBeDefined(cfg.UpperCenter26ToneRU,'UpperCenter26ToneRU');
            center26ToneRU = [0 cfg.UpperCenter26ToneRU]; % No user in content channel-1
            % Get the allocation index indicated by content channel-2
            allocationPerContentCh = [ruAllocation(2) ruAllocation(4) ruAllocation(6) ruAllocation(8)];
        end
    end

    % Replace the invalid allocation index with 113, 114 and 115. This is
    % to replace the invalid value(-1) in the recovered allocation index.
    if any(invalidContentCh)
        ruAllocationForInvalidValue = ones(1,numAllocations/2);
        for i=1:numAllocations/2
            if allocationPerContentCh(i)>=200 && allocationPerContentCh(i)<=207
                ruAllocationForInvalidValue(i) = 114;
            elseif allocationPerContentCh(i)>=208 && allocationPerContentCh(i)<=215
                ruAllocationForInvalidValue(i) = 115;
            elseif allocationPerContentCh(i)>=216 && allocationPerContentCh(i)<=223
                ruAllocationForInvalidValue(i) = 115;
            elseif allocationPerContentCh(i) == 114
                ruAllocationForInvalidValue(i) = 114;
            elseif allocationPerContentCh(i) == 115
                ruAllocationForInvalidValue(i) = 115;
            else
                ruAllocationForInvalidValue(i) = 113;
            end
        end
 
        % Create the complete allocation for the given bandwidth
        ruAllocation(1:numAllocations) = ones(1,numAllocations)*113;
        if invalidContentCh(1)==0
            ruAllocation(1:2:end) = allocationPerContentCh;
            ruAllocation(2:2:end) = ruAllocationForInvalidValue;
        elseif invalidContentCh(1)==1
            ruAllocation(2:2:end) = allocationPerContentCh;
            ruAllocation(1:2:end) = ruAllocationForInvalidValue;
        end
    end

    % HE RU allocation info
    allocInfo = wlan.internal.heAllocationInfo(ruAllocation,logical(center26ToneRU),false);

    % Get the allocation information for all RU
    numUsersPerRU = allocInfo.NumUsersPerRU;
    ruSize = allocInfo.RUSizes;
    ruIndex = allocInfo.RUIndices;
    numRUs = allocInfo.NumRUs;

    % Get the start index of the user within an RU
    startUserIndex = cumsum([0 numUsersPerRU(1:end-1)])+1;
    ruNumber = zeros(1,numUsers);
    for i=1:numUsers
        ruNumber(i) = sum(i>=startUserIndex,2);
    end
    totalNumUsers = numUsersPerRU(ruNumber); % Number of users this current user shared with

    % For each user, get the number of the user within the RU. The
    % failCRC stores the information if any user within a MU-MIMO RU
    % fails the CRC check
    userNumWithinRU = zeros(1,numUsers);
    userNum = 1;
    % Get mapping of the users within each content channel. This
    % information is required to map the users in the same sequence as used
    % in HE-SIG-B user field encoding as per IEEE Std 802.11ax-2021,
    % Section 27.3.11.8
    [contentChUsers,cc1Users,cc2Users] = usersPerContentChannel(ruAllocation,invalidContentCh,sigbCompression,cfg);
    for iru=1:numRUs
        % Determine which content channel users within this RU are signaled
        % in, and therefore if all of the users in an RU are signaled in a
        % single content channel.
        usersInRU = find(ruNumber==iru); % User numbers within this RU
        allRUUsersInCC2 = all(ismember(usersInRU,cc2Users));
        allRUUsersInCC1 = all(ismember(usersInRU,cc1Users));
        allUsersInCC = any([allRUUsersInCC1 allRUUsersInCC2]);

        % If a content channel is invalid and the number of users in a
        % MU-MIMO allocation is <8 (all signaled on one content channel) no
        % user within this RU can be recovered for an RU size greater than
        % 242.
        if any(invalidContentCh) && (ruSize(iru)>242) && (~allUsersInCC || numel(usersInRU)<8)
            userValid((userNum-1)+(1:numUsersPerRU(iru))) = false;
        end

        for iuser = 1:numUsersPerRU(iru)
            userNumWithinRU(userNum) = iuser;
            userNum = userNum+1;
        end
    end

    userValid = userValid(contentChUsers); % Mapping to the recovered CRC user per content channels
    userValid = userValid & ~failCRC; % Do not process CRC failures

    mumimoRU = numUsersPerRU>1; % RU is used for a MU-MIMO allocation
    mumimoAllocation = mumimoRU(ruNumber); % User is part of a MU-MIMO allocation
end

% Only process valid users
processUser = 1:numUsers;
processUser = processUser(userValid);

% Create a cell array of recovery objects for all users
if ~isempty(processUser)

    totalNumUsers = totalNumUsers(contentChUsers);
    userNumWithinRU = userNumWithinRU(contentChUsers);
    mumimoAllocation = mumimoAllocation(contentChUsers);

    % Get user parameters from the recovered user bits
    userParams = parseUserBits(bits,numUsers,totalNumUsers,userNumWithinRU,mumimoAllocation);

    user = repmat({cfg},[1 numel(processUser)]);
    failInterpretation = false(1,numel(processUser));

    for i = 1:numel(processUser)
        % Only update the properties of the users with valid CRC. An
        % un-updated recovery object is returned for the user with fail
        % CRC.
        iuser = processUser(i);
        if suppressError
            if userParams.MCS(iuser)>11
                failInterpretation(i) = true;
                continue
            end
        end
        cfg.MCS = userParams.MCS(iuser);
        cfg.STAID = userParams.STAID(iuser);
        cfg.DCM = userParams.DCM(:,iuser);
        if userParams.Coding(:,iuser)==1
            cfg.ChannelCoding = 'LDPC';
        else
            cfg.ChannelCoding = 'BCC';
        end
        cfg.NumSpaceTimeStreams = userParams.NSTS(iuser);
        cfg.SpaceTimeStreamStartingIndex = userParams.STSIdx(iuser);
        cfg.RUTotalSpaceTimeStreams = userParams.NSTSRU(iuser);
        cfg.Beamforming = userParams.TxBeamforming(iuser);

        cfg.RUSize = ruSize(ruNumber(contentChUsers(iuser)));
        cfg.RUIndex = ruIndex(ruNumber(contentChUsers(iuser)));

        user{i} = cfg;
    end
else
    user = {};
    failInterpretation = false(0,1);
end

end

function s = parseUserBits(userBits,numUsers,totalNumUsers,userNumWithinRU,mumimoAllocation)
%parseUserBits Parse user bits

    % Parse user field bits
    staid = userBits(1:11,:).';
    mcs = userBits(15+(1:4),:).';
    dcm = userBits(19+1,:);
    coding = userBits(20+1,:);

    txbeamforming = true(1,numUsers);
    nsts = zeros(1,numUsers);   % NumSTS number
    nstsRU = zeros(1,numUsers); % NumSTS number
    stsIdx = ones(1,numUsers);  % STS starting index

    if any(mumimoAllocation)
        % MU-MIMO allocation
        spatialConfig = userBits(11+(1:4),mumimoAllocation);
        mimoUsers = find(mumimoAllocation);

        for iu=1:numel(mimoUsers)
            numUsersInRU = totalNumUsers(mimoUsers(iu));
            spatialConfigNum = double(bit2int(spatialConfig(:,iu),4,false));
            userNum = userNumWithinRU(mimoUsers(iu));
            switch numUsersInRU
                case 2
                    if spatialConfigNum>=0 && spatialConfigNum<=3
                        nstsUsers = [spatialConfigNum+1 1];
                    elseif spatialConfigNum>=4 && spatialConfigNum<=6
                        nstsUsers = [spatialConfigNum-4+2 2];
                    elseif spatialConfigNum>=7 && spatialConfigNum<=8
                        nstsUsers = [spatialConfigNum-7+3 3];
                    else % spatialConfigNum==9
                        nstsUsers = [4 4];
                    end
                case 3
                    if spatialConfigNum>=0 && spatialConfigNum<=3
                        nstsUsers = [spatialConfigNum+1 1 1];
                    elseif spatialConfigNum>=4 && spatialConfigNum<=6
                        nstsUsers = [spatialConfigNum-4+2 2 1];
                    elseif spatialConfigNum>=7 && spatialConfigNum<=8
                        nstsUsers = [spatialConfigNum-7+3 3 1];
                    elseif spatialConfigNum>=9 && spatialConfigNum<=11
                        nstsUsers = [spatialConfigNum-9+2 2 2];
                    else % spatialConfigNum==12
                        nstsUsers = [3 3 2];
                    end
                case 4
                    if spatialConfigNum>=0 && spatialConfigNum<=3
                        nstsUsers = [spatialConfigNum+1 1 1 1];
                    elseif spatialConfigNum>=4 && spatialConfigNum<=6
                        nstsUsers = [spatialConfigNum-4+2 2 1 1];
                    elseif spatialConfigNum==7
                        nstsUsers = [3 3 1 1];
                    elseif spatialConfigNum>=8 && spatialConfigNum<=9
                        nstsUsers = [spatialConfigNum-8+2 2 2 1];
                    else % spatialConfigNum==10
                        nstsUsers = [2 2 2 2];
                    end
                case 5
                    if spatialConfigNum>=0 && spatialConfigNum<=3
                        nstsUsers = [spatialConfigNum+1 1 1 1 1];
                    elseif spatialConfigNum>=4 && spatialConfigNum<=5
                        nstsUsers = [spatialConfigNum-4+2 2 1 1 1];
                    else % spatialConfigNum==6
                        nstsUsers = [2 2 2 1 1];
                    end
                case 6
                    if spatialConfigNum>=0 && spatialConfigNum<=2
                        nstsUsers = [spatialConfigNum+1 1 1 1 1 1];
                    else % spatialConfigNum==3
                        nstsUsers = [2 2 1 1 1 1];
                    end
                case 7
                    % spatialConfigNum>=0 && spatialConfigNum<=1
                    nstsUsers = [spatialConfigNum+1 1 1 1 1 1 1];

                otherwise % 8
                    nstsUsers = [1 1 1 1 1 1 1 1]; % spatialConfigNum==0
            end
            stsIdx(mimoUsers(iu)) = sum(nstsUsers(1:userNum-1))+1;
            nsts(mimoUsers(iu)) = nstsUsers(userNum);
            nstsRU(mimoUsers(iu)) = sum(nstsUsers);
        end
    end

    if any(~mumimoAllocation)
        % Non-MU-MIMO allocation
        nstsBits = userBits(11+(1:3),~mumimoAllocation);
        stsIdx(~mumimoAllocation) = 1;
        nsts(~mumimoAllocation) = double(bit2int(nstsBits(:),3,false).')+1;
        nstsRU(~mumimoAllocation) = nsts(~mumimoAllocation);
        txbeamforming(~mumimoAllocation) = userBits(14+1,~mumimoAllocation);
    end

    mcsTmp = mcs.';
    staidTmp = staid.';
    s = struct(...
            'STAID', double(bit2int(staidTmp(:),11,false)), ...
            'MCS', double(bit2int(mcsTmp(:),4,false)), ...
            'DCM', logical(dcm), ...
            'Coding', coding, ...
            'STSIdx', stsIdx, ...
            'NSTS',  nsts, ...
            'NSTSRU', nstsRU, ...
            'TxBeamforming', txbeamforming);
end

function [usersContentChannels,contentCh1Users,contentCh2Users] = usersPerContentChannel(ruAllocation,invalidContentChannel,sigbCompression,cfg)
%usersPerContentChannel Users on SIGB content channels

    allocationIndex = ruAllocation;
    chanBW = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);

    % Determine if center 26-tone RU is signaled on which content channel
    center26ToneRU = [false false];
    if chanBW==80
        if ~sigbCompression && (cfg.LowerCenter26ToneRU && invalidContentChannel(1)==0)
            % The center 26-tone user info is carried in both content channel 1 and 2
            center26ToneRU = [true true];
        end
    elseif chanBW==160
        if ~sigbCompression
            % Can use either center 26-tone. Content channel 1 carries the
            % lower, and content channel 2 carries the upper center 26-tone
            if invalidContentChannel(2)==1
                center26ToneRU = logical([cfg.LowerCenter26ToneRU 0]);
            elseif invalidContentChannel(1)==1
                center26ToneRU = logical([0 cfg.UpperCenter26ToneRU]);
            else
                center26ToneRU = logical([cfg.LowerCenter26ToneRU cfg.UpperCenter26ToneRU]);
            end
        end
    else
        % No center 26 tone RU on either content channel
        center26ToneRU = [false false];
    end

    [contentCh1Users,contentCh2Users] = wlan.internal.heSIGBUsersPerChannel(chanBW,sigbCompression,allocationIndex,center26ToneRU);
    usersContentChannels = [contentCh1Users,contentCh2Users];
end