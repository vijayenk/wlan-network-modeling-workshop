function s = heAllocationInfo(index,varargin)
%heAllocationInfo HE RU allocation info
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   S = heAllocationInfo(INDEX) returns a structure containing information
%   given the allocation assignment INDEX.
%
%   S is a structure with the following fields:
%     NumUsers       - the number of users in the allocation
%     NumRUs         - the number of RUs in the allocation
%     RUIndices      - a vector containing the index of each RU
%     RUSizes        - a vector containing the size of each RU
%     NumUsersPerRU  - a vector containing the number of users in each RU
%
%   INDEX is a scalar or vector containing the 8-bit allocation per 20 MHz
%   segment. Each element is the allocation for a 20 MHz segment in order
%   of absolute frequency.
%
%   S = heAllocationInfo(INDEX,CENTER26TONE) allows center 26 tone RUs to
%   be included for 80 MHz or 160 MHz bandwidths.
%
%   CENTER26TONE is a scalar or vector with two elements. Each element is a
%   logical which determines whether the center tone is present in the
%   upper of lower half.
%
%   S = heAllocationInfo(...,USERPERRUCHECK) allows an allocation to be
%   created with no users by disabling validation.
%
%   USERPERRUCHECK is a logical scalar and enables to bypass the check on
%   number of users per RU. Setting this property to false enables the user
%   to create an empty RU with no user.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

numAssignments = numel(index);

% We need 20, 40, 80, or 160 MHz assignment
coder.internal.errorIf(~any(numAssignments==[1 2 4 8]),'wlan:he:InvalidNumAssignments');

centerRUOccupiedLeft = false;  % Lower 80 MHz
centerRUOccupiedRight = false; % Upper 80 MHz
userPerRUCheck = true; % Switch to bypass the check on number of users per RU
if nargin>1
    % Center 26-tone RU specified
    if ~isempty(varargin{1})
        centerRUOccupied = varargin{1};
        centerRUOccupiedLeft = varargin{1}(1);
        if numel(centerRUOccupied)>1 
            centerRUOccupiedRight = varargin{1}(2);
        end
    end
    if nargin>2
        % Allow validation to be disabled for number of user per RU
        userPerRUCheck = varargin{2};
    end
end

% Construct allocation table for selected allocations
RUsSingle = struct('NumRUs',0,'NumUsers',0,'RUSizes',0,'RUIndices',0,'NumUsersPerRU',0);
allocation = repmat(RUsSingle,numAssignments,1);
coder.varsize('allocation(:).RUSizes');
coder.varsize('allocation(:).RUIndices');
coder.varsize('allocation(:).NumUsersPerRU');
for j = 1:numAssignments
    allocation(j) = wlan.internal.heRUAllocationLUT(index(j));
end

if any(numAssignments==[4 8]) % Only valid for 80/160 MHz
    % Allowing puncturing of a 40 MHz subchannel using adjacent 114 indices
    adjacentAllocationIndexPairs = reshape(index,2,numel(index)/2).';
    adjacent114Index = repelem(sum(adjacentAllocationIndexPairs==114,2)==2,2,1);
    if any(adjacent114Index)
        for j = 1:numel(adjacent114Index)
            if adjacent114Index(j)
                allocation(j).NumRUs = 0;
            end
        end
    end
end

if coder.target('MATLAB')
    allRUSizes = [allocation.RUSizes];
    allNumUsersPerRU = [allocation.NumUsersPerRU];
else
    allRUSizes = [];
    allNumUsersPerRU = [];
    for ia = 1:numel(allocation)
        allRUSizes = [allRUSizes allocation(ia).RUSizes(1,:)]; %#ok<AGROW>
        allNumUsersPerRU = [allNumUsersPerRU allocation(ia).NumUsersPerRU(1,:)]; %#ok<AGROW>
    end
end

% Ensure enough allocation indices are provided if an RU > 20 MHz is
% specified. This will be the case if more than one assignment is provided,
% or the number of users per RU is 0 (this will be 114 or 115).
if numAssignments>1 || allNumUsersPerRU(1)==0
    if any(allRUSizes>=(996*2)) && numAssignments<8
        coder.internal.error('wlan:he:InvalidNumAssignmentsForRUSize',2*996,8);
    end
    if any(allRUSizes>=996) && numAssignments<4
        coder.internal.error('wlan:he:InvalidNumAssignmentsForRUSize',996,4);
    end
    if any(allRUSizes>=484) && numAssignments<2
        coder.internal.error('wlan:he:InvalidNumAssignmentsForRUSize',484,2);
    end
end

if numAssignments>=2
    % If >=40 MHz then test any 484 RU assignment is valid
    coder.internal.errorIf(~(mod(sum(allRUSizes==484),2)==0),'wlan:he:InvalidAssignmentsForRUSize',484,2);

    % Test that RU are in valid locations
    F484 = 2^(numAssignments/2);

    test484IdxVal = reshape(repmat(int2bit(0:(F484-1),numAssignments/2,false).',2,1),F484,[]);
    removeIdx484Val = repmat([false true],1,numAssignments/2);
    test484Idx = test484IdxVal;
    remove484Idx = removeIdx484Val;
    is484RU = false(1,numAssignments);
    for k = 1:numAssignments
        is484RU(k) = isequal(allocation(k).RUSizes(1),484);
    end
    valid484 = any(all(is484RU==test484Idx,2));
    if ~valid484
        coder.internal.error('wlan:he:InvalidAssignmentOrderForRUSize',484,2,40);
    end

    % 484 RU to remove as they are duplicates across bandwidth
    removeDuplicate484Idx = valid484&is484RU&remove484Idx;
else
    removeDuplicate484Idx = false(1,numAssignments);
end
% Find the indices of the allocation which we will add users to
% as the other allocations are removed.
addTo484Ind = strfind(removeDuplicate484Idx,[0 1]);

if numAssignments==8 && any(allRUSizes==2*996)
    % As 996 RU with no user can be used for load balancing of 2x996 RU
    % then look for the case of 2x996 RU first before checking other
    % 996 RUs
    isEmpty996 = allRUSizes==996 & allNumUsersPerRU==0;
    if ~all(~(allRUSizes==2*996) == isEmpty996)
        coder.internal.error('wlan:he:InvalidAssignmentsFor2x996RUSize');
    end
    removeDuplicate996Idx = false(1,numAssignments);
elseif numAssignments>=4
    % If >=80 MHz then test any 996 RU assignment is valid
    if ~(mod(sum(allRUSizes==996),4)==0)
        coder.internal.error('wlan:he:InvalidAssignmentsForRUSize',996,4);
    end

    % Test that RU are in valid locations
    F996 = 2^(numAssignments/4);
    test996Idx = reshape(repmat(int2bit(0:(F996-1),numAssignments/4,false).',4,1),F996,[]);
    is996RU = false(1,numAssignments);
    for k = 1:numAssignments
        is996RU(k) = isequal(allocation(k,:).RUSizes(1),996);
    end
    valid996 = any(all(is996RU==test996Idx,2));
    if ~valid996
        coder.internal.error('wlan:he:InvalidAssignmentOrderForRUSize',996,4,80);
    end

    % 996 RU to remove as they are duplicates across bandwidth
    removeDuplicate996Idx = valid996&is996RU&repmat([false true true true],1,numAssignments/4);
else
    removeDuplicate996Idx = false(1,numAssignments);
end
% Find the indices of the allocation which we will add users to
% as the other allocations are removed.
addTo996Ind = strfind(removeDuplicate996Idx,[0 1 1 1]);

if numAssignments==8
    % Find which allocations are 2*996
    is1992RU = false(1,numAssignments);
    for k = 1:numAssignments
        is1992RU(k) = isequal(allocation(k).RUSizes(1),1992);
    end

    if any(is1992RU)
        % Find which allocations are a 996 with 0 users, assuming a 1992 RU
        % is present
        isEmpty996 = false(1,numAssignments);
        for k = 1:numAssignments
            isEmpty996(k) = isequal(allocation(k).RUSizes(1),996) && isequal(allocation(k).NumUsersPerRU(1),0);
        end

        % Treat empty 996 as 1992 RU for combining
        for i = 1:numel(isEmpty996)
            if isEmpty996(i)==true
                allocation(i).RUSizes = 2*996;
            end
        end
        is1992RU = is1992RU|isEmpty996;
        
        % 996 RU to remove as they are duplicates across bandwidth
        removeDuplicate1992Idx = is1992RU&repmat([false true true true true true true true],1,numAssignments/8);
    else
        removeDuplicate1992Idx = false(1,numAssignments);
    end
else
    removeDuplicate1992Idx = false(1,numAssignments);
end
% Find the indices of the allocation which we will add users to
% as the other allocations are removed.
addTo1992Ind = strfind(removeDuplicate1992Idx,[0 1 1 1 1 1 1 1]);

for j = 1:numel(index)
    % Increment RU index for each 20 MHz subchannel
    for i = 1:allocation(j,:).NumRUs
        switch allocation(j,:).RUSizes(i)
            case 26
                scalingFactor = 9;
            case 52
                scalingFactor = 4;
            case 106
                scalingFactor = 2;
            case 242
                scalingFactor = 1;
            case 484
                scalingFactor = 1/2;
            case 996
                scalingFactor = 1/4;
            case 2*996
                scalingFactor = 1/8;
            otherwise
                error('Unexpected RU size');
        end
        if allocation(j,:).RUSizes(i)==26 %&& any(centerRUOccupied)
            numberOfCentral26RUs = ceil((j-2)/4); % Extra RU at each 40 MHz boundary in 80 MHz
            allocation(j,:).RUIndices(i) = allocation(j,:).RUIndices(i)+(j-1)*scalingFactor+numberOfCentral26RUs;
        else
            allocation(j,:).RUIndices(i) = allocation(j,:).RUIndices(i)+(j-1)*scalingFactor;
        end
    end
end


% Add users when duplicated RU which span more than 20 MHz are
% removed
for ia = 1:numel(addTo484Ind)
    allocation(addTo484Ind(ia)).NumUsers = allocation(addTo484Ind(ia)).NumUsers+allocation(addTo484Ind(ia)+1).NumUsers;
    allocation(addTo484Ind(ia)).NumUsersPerRU = allocation(addTo484Ind(ia)).NumUsersPerRU + allocation(addTo484Ind(ia)+1).NumUsersPerRU;
end
for ia = 1:numel(addTo996Ind)
    addFromInd = (addTo996Ind(ia)+(1:3));
    numUserSum = 0;
    numUserPerRUSum = 0;
    for j = addFromInd
        numUserSum = numUserSum+allocation(j).NumUsers;
        numUserPerRUSum = numUserPerRUSum+allocation(j).NumUsersPerRU(1);
    end
    assert(isequal(numUserSum,numUserPerRUSum));
    allocation(addTo996Ind(ia)).NumUsers = allocation(addTo996Ind(ia)).NumUsers+numUserSum;
    allocation(addTo996Ind(ia)).NumUsersPerRU = allocation(addTo996Ind(ia)).NumUsersPerRU+numUserPerRUSum;
end
for ia = 1:numel(addTo1992Ind)
    addFromInd = (addTo1992Ind(ia)+(1:7));
    numUserSum = 0;
    numUserPerRUSum = 0;
    for j = addFromInd
        numUserSum = numUserSum+allocation(j).NumUsers;
        numUserPerRUSum = numUserPerRUSum+allocation(j).NumUsersPerRU(1);
    end
    allocation(addTo1992Ind(ia)).NumUsers = allocation(addTo1992Ind(ia)).NumUsers+numUserSum;
    allocation(addTo1992Ind(ia)).NumUsersPerRU = allocation(addTo1992Ind(ia)).NumUsersPerRU+numUserPerRUSum;
end

% Remove any duplicate RU which span multiple 20 MHz
removeDupIdx = (removeDuplicate484Idx|removeDuplicate996Idx|removeDuplicate1992Idx);
allocationDupRemoved = allocation(~removeDupIdx);

RUSizes = zeros(1,0);
for ia = 1:numel(allocationDupRemoved)
    for ib = 1:numel(allocationDupRemoved(ia).RUSizes)
        RUSizes = [RUSizes allocationDupRemoved(ia).RUSizes(ib)]; %#ok<AGROW>
    end
end

if numAssignments==1 && numel(RUSizes)==1
    % Single allocation index, full-band allocation
    switch allocationDupRemoved(1).RUSizes(1)
        case 242
            channelBandwidth = 20;
        case 484
            channelBandwidth = 40;
        case 996
            channelBandwidth = 80;
        otherwise % 2*996
            channelBandwidth = 160;
    end
else
    switch numAssignments
        case 1
            channelBandwidth = 20;
        case 2
            channelBandwidth = 40;
        case 4
            channelBandwidth = 80;
        otherwise % 8
            channelBandwidth = 160;
    end
end

if centerRUOccupiedLeft==true
   % Left center RU cannot be used when a 996 or 2*996 tone RU is present
   % in this half. As the stages before make sure the locations of
   % allocations are correct, if the first allocation is less than 996 then
   % assume the lower half does not contain a full-band 996 or 2*996
   % allocation.

   if channelBandwidth<80
       coder.internal.error('wlan:he:InvalidCenter26RUAllocationChanBW');
   end
   if numel(RUSizes)==1 && RUSizes(1)==996
       coder.internal.error('wlan:he:Invalid80MHzCenter26RUAllocation'); % Full-band 80 MHz
   end
   if RUSizes(1)>=996
       coder.internal.error('wlan:he:InvalidLowerCenter26RUAllocation');
   end

   centerRUOccupiedLeftStruct = struct('NumRUs',1,'NumUsers',1,'RUSizes',26,'RUIndices',19,'NumUsersPerRU',1);
   allocationDupRemovedWithCenterLeft = [allocationDupRemoved; centerRUOccupiedLeftStruct];
else
   allocationDupRemovedWithCenterLeft = allocationDupRemoved;
end
if centerRUOccupiedRight==true
   % Right center RU cannot be used when a 996 or 2*996 tone RU is present
   % in this half. As the stages before make sure the locations of
   % allocations are correct, if the first allocation is less than 2*996
   % then assume the upper half does not contain a full-band 2*996
   % allocation. If the last RU is not 996 then assume there is no full
   % band 996 allocation in the upper half.

   if channelBandwidth<160
       coder.internal.error('wlan:he:InvalidUpperCenter26RUAllocationChanBW');
   end
   if ~(RUSizes(1)<2*996 && size(RUSizes,2)>1 && RUSizes(end)<996)
       coder.internal.error('wlan:he:InvalidUpperCenter26RUAllocation');
   end
   
   centerRUOccupiedRightStruct = struct('NumRUs',1,'NumUsers',1,'RUSizes',26,'RUIndices',19+37,'NumUsersPerRU',1);
   allocationDupRemovedWithCenterLeftRight = [allocationDupRemovedWithCenterLeft; centerRUOccupiedRightStruct];

else
   allocationDupRemovedWithCenterLeftRight = allocationDupRemovedWithCenterLeft;
end

numRUs = 0;
numUsers = 0;
for i=1:numel(allocationDupRemovedWithCenterLeftRight)
    numRUs = numRUs+allocationDupRemovedWithCenterLeftRight(i).NumRUs;
    numUsers = numUsers+allocationDupRemovedWithCenterLeftRight(i).NumUsers;
end

ruIndices = zeros(1,numRUs);
ruSizes = zeros(1,numRUs);
numUsersPerRU = zeros(1,numRUs);
k = 1;
for i = 1:numel(allocationDupRemovedWithCenterLeftRight)
    for j = 1:allocationDupRemovedWithCenterLeftRight(i).NumRUs
        ruIndices(k) = allocationDupRemovedWithCenterLeftRight(i).RUIndices(j);
        ruSizes(k) = allocationDupRemovedWithCenterLeftRight(i).RUSizes(j);
        numUsersPerRU(k) = allocationDupRemovedWithCenterLeftRight(i).NumUsersPerRU(j);
        k = k+1;
    end
end

if any(numUsersPerRU>8)
    % Error if the total number of users in an RU is greater than 8
    tmp = find(numUsersPerRU>8,1);
    firstIdx = tmp(1); % For codegen
    coder.internal.error('wlan:he:InvalidNumUserPerRU',ruSizes(firstIdx),ruIndices(firstIdx),numUsersPerRU(firstIdx));
end

% The number of users should not be zero
if userPerRUCheck % Switch to bypass the check on number of users per RU
    if numUsers==0
        coder.internal.error('wlan:he:NoUser');
    end

    % The number of users per RU should not be zero
    if any(numUsersPerRU==0)
        firstIdx = find(numUsersPerRU==0,1);
        coder.internal.error('wlan:he:NoUserPerRU',ruIndices(firstIdx(1)));
    end
end

s = struct;
s.NumUsers = numUsers;
s.NumRUs = numRUs;
s.RUIndices = ruIndices;
s.RUSizes = ruSizes;
s.NumUsersPerRU = numUsersPerRU;

end

% Returns the indices of y which match the pattern x. An empty is returned
% for no matches
function matchInd = strfind(y,x)
    Nx = numel(x);
    Ny = numel(y);
    if ((Ny-Nx)+1) > 0
        match = false((Ny-Nx)+1);
        for i = 0:(Ny-Nx)
            match(i+1) = all(y(i+(1:Nx))==x);
        end
        matchInd = find(match);
    else
        matchInd = [];
    end
end

