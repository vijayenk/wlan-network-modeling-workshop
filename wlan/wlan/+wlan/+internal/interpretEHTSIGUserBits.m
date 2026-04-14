function [user,failInterpretation] = interpretEHTSIGUserBits(bits,failCRC,cfg,suppressError)
%interpretEHTSIGUserBits Interpret EHT-SIG user field bits for an EHT MU packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [USER,FAILINTERPRETATION] = interpretEHTSIGUserBits(bits,failCRC,cfg)
%   parses and interpret decode EHT-SIG user field bits. The returned USER
%   is a cell array of size 1-by-NumUsers. USER is the updated format
%   configuration object after EHT-SIG user field decoding, of type
%   <a href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>. When you use this syntax and the function
%   cannot interpret the recovered EHT-SIG user field bits due to an
%   unexpected value, an exception is issued and the function does not
%   return.
%
%   BITS is an int8 matrix of size 22-by-NumUsers, where NumUsers is the
%   number of users in the transmission, containing the recovered user
%   field bits for all users.
%
%   FAILCRC is a logical row vector of length NumUsers representing the CRC
%   result for each user. It is true if the user fails the CRC. It is a
%   logical row vector of size 1-by-NumUsers.
%
%   [...] = interpretEHTSIGUserBits(...,SUPPRESSERROR) controls the
%   behavior of the function due to an unexpected value of the interpreted
%   EHT-SIG user field bits. SUPPRESSERROR is logical. When SUPPRESSERROR
%   is true and the function cannot interpret the recovered EHT-SIG user
%   field bits due to an unexpected value, the function returns
%   FAILINTERPRETATION as true and the returned object is unchanged for the
%   user. When SUPPRESSERROR is false and the function cannot interpret the
%   recovered EHT-SIG user field bits due to an unexpected value, an
%   exception is issued and the function does not return. The default is
%   false

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen
    arguments
        bits;
        failCRC;
        cfg;
        suppressError = false; % Control the validation of the interpreted EHT-SIG bits
    end

    % If all content channel or users fails then do not process further
    if cfg.PPDUType==wlan.type.EHTPPDUType.dl_ofdma
        isInvalid = any(cfg.NumUsersPerContentChannel==-1,'all') || all(failCRC,'all');
    else % non-OFDMA
        coder.internal.assert(isvector(cfg.NumUsersPerContentChannel),'wlan:codegen:NotAVector','NumUsersPerContentChannel')
        isInvalid = all(cfg.NumUsersPerContentChannel(1,:)==-1) || all(failCRC,'all');
    end

    if isInvalid
        failInterpretation = true;
        user = {}; % If all content channel fail then do not process further
        return
    end

    numUsers = size(bits,2); % Number of users
    isEHTDUPMode = false; % EHT-DUP mode is unknown
    isEHTSU = false;

    if cfg.PPDUType==wlan.type.EHTPPDUType.dl_ofdma
        allocInfo = wlan.internal.ehtAllocationParams(cfg.AllocationIndex);
        [~,userInSegment] = wlan.internal.ehtSIGCodingInfo(cfg);
        temp = userInSegment';
        contentChUsers = unique([temp{:}],'stable'); % This is to handle M-by-N, with same users across all 80 MHz subblocks

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
        userNumWithinRU = zeros(1,numUsers);
        userNum = 1;
        for iru=1:numRUs
            for iuser = 1:numUsersPerRU(iru)
                userNumWithinRU(userNum) = iuser;
                userNum = userNum+1;
            end
        end
        mumimoRU = numUsersPerRU>1; % RU is used for a MU-MIMO allocation
        mumimoAllocation = mumimoRU(ruNumber); % User is part of a MU-MIMO allocation
    else % non-OFDMA
         % No common field is present
        if numUsers>1
            mumimoAllocation = true(1,numUsers); % All users in MU-MIMO
        else
            mumimoAllocation = false; % One user so not MU-MIMO
        end
        if cfg.PPDUType==wlan.type.EHTPPDUType.su
            % Determine EHT DUP mode by recoverying the MCS value for the first user
            % bits. EHT DUP mode is always single user.
            mcs = double(bit2int(bits(12:15,1),4,false));
            isEHTDUPMode = mcs==14;
            isEHTSU = true;
        end
        % Number of users this current user shared with
        totalNumUsers = numUsers*ones(1,numUsers);
        userNumWithinRU = 1:numUsers;
        allocInfo = wlan.internal.ehtAllocationInfo(cfg.ChannelBandwidth,cfg.NumNonOFDMAUsers,cfg.PuncturedChannelFieldValue,isEHTDUPMode);
        ruSize = allocInfo.RUSizes;
        ruIndex = allocInfo.RUIndices;
        ruNumber = ones(1,numUsers);
        contentChUsers = 1:numUsers;
    end

    % Only process valid users
    processUser = 1:numUsers;
    processUser = processUser(~failCRC);

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
            cfg.STAID = userParams.STAID(iuser);
            if cfg.PPDUType==wlan.type.EHTPPDUType.dl_mumimo
                if wlan.internal.failInterpretationIf(userParams.MCS(iuser)>13,'wlan:interpretEHTSIGUserBits:InvalidMCSMUMIMO',suppressError,userParams.MCS(iuser))
                    failInterpretation(i) = true;
                    continue
                end
            end
            cfg.MCS = userParams.MCS(iuser);
            if userParams.Coding(:,iuser)==1
                cfg.ChannelCoding = wlan.type.RecoveredChannelCoding.ldpc;
            else
                cfg.ChannelCoding = wlan.type.RecoveredChannelCoding.bcc;
            end
            if isEHTSU || isEHTDUPMode
                if wlan.internal.failInterpretationIf(userParams.NSTS(iuser)>8,'wlan:interpretEHTSIGUserBits:InvalidNSSNonMUMIMO',suppressError,userParams.NSTS(iuser))
                    failInterpretation(i) = true;
                    continue
                end
            end
            cfg.NumSpaceTimeStreams = userParams.NSTS(iuser);
            cfg.SpaceTimeStreamStartingIndex = userParams.STSIdx(iuser);
            cfg.RUTotalSpaceTimeStreams = userParams.NSTSRU(iuser);
            cfg.Beamforming = userParams.Beamformed(iuser);

            cfg.RUSize = ruSize{ruNumber(contentChUsers(iuser))};
            cfg.RUIndex = ruIndex{ruNumber(contentChUsers(iuser))};

            user{i} = cfg;
        end
    else
        user = {};
        failInterpretation = false(1,0);
    end
end


function s = parseUserBits(userBits,numUsers,totalNumUsers,userNumWithinRU,mumimoAllocation)
%parseUserBits Parse user bits

% Parse user field bits
    staid = userBits(1:11,:);
    mcs = userBits(11+(1:4),:);

    nsts = zeros(1,numUsers);   % NumSTS number
    nstsRU = zeros(1,numUsers); % NumSTS number
    stsIdx = ones(1,numUsers);  % STS starting index
    coding = true(1,numUsers);  % Channel coding
    beamformed = false(1,numUsers); % Beamfomed

    if any(mumimoAllocation) % OFDMA with a mix of RUs with MU-MIMO and non-MU-MIMO
                             % MU-MIMO allocation
        spatialConfig = userBits(16+(1:6),mumimoAllocation);
        mimoUsers = find(mumimoAllocation);
        coding(mumimoAllocation) = userBits(16,mumimoAllocation);

        for iu=1:numel(mimoUsers)
            numUsersInRU = totalNumUsers(mimoUsers(iu));
            spatialConfigNum = double(bit2int(spatialConfig(:,iu),6,false));
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
                elseif spatialConfigNum>=10 && spatialConfigNum<=12
                    nstsUsers = [spatialConfigNum-10+2 2 2];
                else % spatialConfigNum==13
                    nstsUsers = [3 3 2];
                end
              case 4
                if spatialConfigNum>=0 && spatialConfigNum<=3
                    nstsUsers = [spatialConfigNum+1 1 1 1];
                elseif spatialConfigNum>=4 && spatialConfigNum<=6
                    nstsUsers = [spatialConfigNum-4+2 2 1 1];
                elseif spatialConfigNum==7
                    nstsUsers = [3 3 1 1];
                else %spatialConfigNum>=10 && spatialConfigNum<=12
                    nstsUsers = [spatialConfigNum-10+2 2 2 1];
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
        % Non-MU-MIMO allocation (RUs)
        nstsBits = userBits(16+(1:4),~mumimoAllocation);
        stsIdx(~mumimoAllocation) = 1;
        nsts(~mumimoAllocation) = double(bit2int(nstsBits(:),4,false).')+1;
        nstsRU(~mumimoAllocation) = nsts(~mumimoAllocation);
        coding(~mumimoAllocation) = userBits(22,~mumimoAllocation);
        beamformed(~mumimoAllocation) = userBits(21,~mumimoAllocation);
    end

    % This if statement is required to work around the runtime check in the
    % generated code of bit2int
    if iscolumn(staid)
        staidInt = double(bit2int(staid(:,1),11,false));
        mcsInt = double(bit2int(mcs(:,1),4,false));
    else
        staidInt = double(bit2int(staid,11,false));
        mcsInt = double(bit2int(mcs,4,false));
    end

    s = struct(...
        'STAID', staidInt, ...
        'MCS', mcsInt, ...
        'Coding', coding, ...
        'STSIdx', stsIdx, ...
        'NSTS',  nsts, ...
        'NSTSRU', nstsRU, ...
        'Beamformed',beamformed);
end
