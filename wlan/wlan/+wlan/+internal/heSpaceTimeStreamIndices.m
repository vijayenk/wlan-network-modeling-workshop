function [idx,varargout] = heSpaceTimeStreamIndices(cfgMU)   
%heSpaceTimeStreamIndices space time stream indices for each user
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   IDX = heSpaceTimeStreamIndices(CFGMU) returns a 2-by-NumUsers vector.
%   The first row of the contains the starting space-time stream index for
%   each user. The second row contains the last space-time stream index for
%   each user.
% 
%   [IDX,STS] = heSpaceTimeStreamIndices(CFGMU) returns a cell array STS
%   containing the space-time stream indices for each user.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

allocation = ruInfo(cfgMU);

nsts = zeros(1,allocation.NumUsers);
startIdx = zeros(1,allocation.NumUsers);
endIdx = zeros(1,allocation.NumUsers);
userNum = 1;
for ur = 1:numel(cfgMU.RU)
    startingIdx = 0;
    numUsers = allocation.NumUsersPerRU(ur);
    userNumbers = cfgMU.RU{ur}.UserNumbers;
    for ui = 1:numUsers
		startIdx(userNum) = startingIdx+1;
        nsts(userNum) = cfgMU.User{userNumbers(ui)}.NumSpaceTimeStreams;
        startingIdx = startingIdx+nsts(userNum);
        endIdx(userNum) = startingIdx;
        userNum = userNum+1;
    end
end
idx = [startIdx; endIdx];

if nargout>1
    n = allocation.NumUsers;
	sts = cell(1,n);
	for i = 1:n
		sts{i} = startIdx(i)-1+(1:nsts(i));
	end
	varargout{1} = sts;
end

end