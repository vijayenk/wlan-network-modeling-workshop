function [bits,sigbInfo] = heSIGBBits(cfgHE)
%heSIGBBits HE Signal B Field Bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,SIGBINFO] = heSIGBBits(CFGHE) returns the HE Signal B Field
%   (HE-SIG-B) bits and a structure containing SIG-B info.
%
%   BITS are the HE-SIG-B signaling bits. It is of type double, binary
%   column vector. The length of HE-SIG-B depends on the number of RUs and
%   the users within each RU.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>.
%
%   See also wlan.internal.heSIGB.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

sigbInfo = wlan.internal.heSIGBCodingInfo(cfgHE);
chanBW = cfgHE.ChannelBandwidth;
numContentChs = sigbInfo.NumContentChannels; % Number of content channels
center26ToneRU = sigbInfo.Center26ToneRU; % Center 26 tone RU information
numSym = sigbInfo.NumSymbols;
numUsers = numel(cfgHE.User);
numRUs = numel(cfgHE.RU);

% Pre-allocation of variables
spatialConfigBitsAllUsers = zeros(4,numUsers);

% Get the spatial-configuration bits per RU
ruSpatialConfigBits = coder.nullcopy(zeros(4,numRUs));
for i = 1:numRUs
    % Get the number of space-time streams per user in an RU
    userNumbers = cfgHE.RU{i}.UserNumbers;
    numSTSPerUser = zeros(numel(userNumbers),1);
    for j = 1:numel(userNumbers)
        numSTSPerUser(j) = cfgHE.User{userNumbers(j)}.NumSpaceTimeStreams;
    end
    % The spatial configuration subfield for each user is based on all
    % users in an RU, therefore determine the bits for the RU
    ruSpatialConfigBits(:,i) = wlan.internal.heSpatialConfigurationBits(numSTSPerUser);
end

% Get the spatial-configuration bits and MU indication per user
muRU = coder.nullcopy(false(1,numUsers));
for j = 1:numUsers
    ruIdx = cfgHE.User{j}.RUNumber;
    % For each user determine whether it is part of a MU-MIMO allocation,
    % by determining the number of users per RU
    muRU(j) = numel(cfgHE.RU{ruIdx}.UserNumbers)>1;
    % Store the spatial configuration bits for the user
    spatialConfigBitsAllUsers(:,j) = ruSpatialConfigBits(:,ruIdx);
end

STAID = coder.nullcopy(zeros(1,numUsers));
MCS = coder.nullcopy(zeros(1,numUsers));
DCM = coder.nullcopy(zeros(1,numUsers));
userBeamforming = coder.nullcopy(false(1,numUsers));
isChannelCodingLDPC = coder.nullcopy(false(1,numUsers));
customSpatialMappingPerUser = coder.nullcopy(false(1,numUsers));
for userIdx = 1:numUsers
    STAID(userIdx) = cfgHE.User{userIdx}.STAID;
    MCS(userIdx) = cfgHE.User{userIdx}.MCS;
    DCM(userIdx) = cfgHE.User{userIdx}.DCM;
    userBeamforming(userIdx) = cfgHE.RU{cfgHE.User{userIdx}.RUNumber}.Beamforming;
    isChannelCodingLDPC(userIdx) = strcmp(cfgHE.User{userIdx}.ChannelCoding,'LDPC');
    customSpatialMappingPerUser(userIdx) = strcmp(cfgHE.RU{cfgHE.User{userIdx}.RUNumber}.SpatialMapping,'Custom');
end

% Pre-allocation of variables
cbw = wlan.internal.cbwStr2Num(chanBW);
% The coder.ignoreConst is required to ensure commonBits is variable-size.
% There are reads of commonBits before writes to commonBits.  If commonBits
% is fixed-size at a read, it must remain fixed-size.  Later writes to
% commonBits require variable-sizing.
commonBits = zeros(coder.ignoreConst(ceil(cbw/40)*8+(cbw>=80)+4+6),numContentChs);
maxUserContentCh = max(sigbInfo.NumUsersPerContentChannel);
if mod(maxUserContentCh,2) == 0
    % Number of user bits for each user is 21+10
    lenUserField = max(sigbInfo.NumUsersPerContentChannel)*21+ max(sigbInfo.NumUsersPerContentChannel)*10;
else
    lenUserField = max(sigbInfo.NumUsersPerContentChannel)*21+(max(sigbInfo.NumUsersPerContentChannel)-(1-all(sigbInfo.NumUsersPerContentChannel)))*10;
end
lenCommonField = numel(commonBits(:,1));
lenFields = lenUserField+lenCommonField;
lenSIGBbits = numSym*sigbInfo.NDBPS-(lenFields)+lenUserField + lenCommonField;

bits = zeros(lenSIGBbits,numContentChs,'int8');

for i = 1:numContentChs
    numUsersInContentChannel = sigbInfo.NumUsersPerContentChannel(i);
    if i == 1
        contentCh = sigbInfo.ContentChannel1Users;
    else
        contentCh = sigbInfo.ContentChannel2Users;
    end
    % Get user specific field bits for each single allocation
    userBlockBits = zeros(21,numUsersInContentChannel,'int8');
    numUserIdx = 1;
    spatialConfigBitsContentChannel = spatialConfigBitsAllUsers(:,contentCh);
    isMUContentChannel = muRU(contentCh);
    for k = 1:sigbInfo.NumUsersPerContentChannel(i)
        userIdx = contentCh(k);
        staid = STAID(userIdx);
        % Set the beamforming bit if spatial mapping is not direct
        if customSpatialMappingPerUser(userIdx)
            txBeamforming = userBeamforming(userIdx);
        else
            txBeamforming = false;
        end
        mcs = MCS(userIdx);
        dcm = DCM(userIdx);
        spatialConfigBitsUser = spatialConfigBitsContentChannel(:,k);
        isMU = isMUContentChannel(k);

        % Get the bits for a user
        userBlockBits(:,numUserIdx) = wlan.internal.heSIGBUserFieldBits(staid,spatialConfigBitsUser,txBeamforming,mcs,dcm,isChannelCodingLDPC(userIdx),isMU);
        numUserIdx = numUserIdx+1;
    end

    if sigbInfo.Compression
        % When the HE-SIG-B Compression field in the HE-SIG-A field of
        % an HE-MU PPDU is set to 1, the common block field is not
        % present.
        commonBits = zeros(0,numContentChs);
    else
        % Common Block Field The allocation for one content channel is
        % every second 20 MHz channel allocation, and potentially a
        % center 26 tone RU
        RUAllocationBits = wlan.internal.heSIGBCommonBlockBits(cfgHE.AllocationIndex((i-1)+1:2:end),center26ToneRU(i),cbw);

        % Calculate CRC and tail bits for Common Block Field
        allCRCBits = wlan.internal.crcGenerate(RUAllocationBits);
        CRCBits = allCRCBits(1:4);
        tailBits = zeros(6,1,'int8');
        commonBits(:,i) = [RUAllocationBits; CRCBits; tailBits];
    end

    userBits = userBlockBits(:,1:numUsersInContentChannel);
    % Reshape user block bits into pairs of users, excluding the last,
    % odd numbered user if necessary
    if numUsersInContentChannel == 1
        numPairs = 1;
        pairs = userBits;
        leftover = zeros(0,1,'int8');
    elseif numUsersInContentChannel == 0
        numPairs = 0;
        pairs = zeros(21*2,0,'int8');
        leftover = zeros(size(userBlockBits,1),0,'int8');
    else
        numPairs = floor(numUsersInContentChannel/2);
        pairs = reshape(userBits(:,1:numPairs*2),21*2,[]);
        leftover = userBits(:,numPairs*2+1:end);
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
    NDATA = numSym*sigbInfo.NDBPS;
    NPAD = NDATA-LENGTH;
    allUserBitsPadded = [allUserBits; zeros(NPAD,1,'int8')];

    bits(:,i) = [commonBits(:,i); allUserBitsPadded];
end
end