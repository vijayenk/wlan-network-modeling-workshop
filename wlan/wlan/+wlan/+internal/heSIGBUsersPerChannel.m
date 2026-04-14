function [contentChannel1Users,contentChannel2Users,numContentChannels] = heSIGBUsersPerChannel(chanBW,sigBCompression,allocationIndex,center26ToneRU)
%heSIGBUsersPerChannel HE SIGB users per content channel
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [CONTENTCHANNEL1USERS,CONTENTCHANNEL2USERS,NUMCONTENTCHANNEL] =
%   heSIGBUsersPerChannel(CHANBW,SIGBCOMPRESSION,ALLOCATIONINDEX,CENTER26TONERU)
%   returns the number of user per content channel and the distribution of
%   users per SIGB content channel.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

switch chanBW
   case 20
       numContentChannels = 1;
   otherwise % 40/80/160MHz
       numContentChannels = 2;
end

% The number of content channels and common field bits depends on the
% bandwidth
if sigBCompression
    % Get the number of users on each signaled 20 MHz subchannel
    numUsersPer20 = zeros(1,numContentChannels);
    allocInfo = wlan.internal.heAllocationInfo(allocationIndex);
    if numContentChannels==1
        numUsersPer20 = allocInfo.NumUsers;
    else
        % Split user fields between two content channels 
        numUsersPer20(1) = ceil(allocInfo.NumUsers/2);
        numUsersPer20(2) = allocInfo.NumUsers-ceil(allocInfo.NumUsers/2);
    end
else
    % Get the number of users on each signaled 20 MHz subchannel
    num20 = numel(allocationIndex);
    numUsersPer20 = zeros(1,num20);
    for i = 1:num20
        allocInfo20 = wlan.internal.heRUAllocationLUT(allocationIndex(i));
        numUsersPer20(i) = allocInfo20.NumUsers;
    end
end

% Get the start and end indices for the users
startUserIndexPer20 = cumsum([0 numUsersPer20(1:end-1)])+1;
endUserIndexPer20 = startUserIndexPer20+numUsersPer20-1;

% Content channel 1 contains users for odd subchannels, channel 2 for even
contentChannel1Users = zeros(1,0);
for i=1:2:numel(startUserIndexPer20)
   contentChannel1Users = [contentChannel1Users startUserIndexPer20(i):endUserIndexPer20(i)]; %#ok<AGROW>
end
contentChannel2Users = zeros(1,0);
for i=2:2:numel(startUserIndexPer20)
   contentChannel2Users = [contentChannel2Users startUserIndexPer20(i):endUserIndexPer20(i)]; %#ok<AGROW>
end

% Add central 26 tone users
if center26ToneRU(1)==true
   lowerCentral26User = endUserIndexPer20(end)+1;
   contentChannel1Users = [contentChannel1Users lowerCentral26User];
end

if center26ToneRU(2)==true
    if center26ToneRU(1)==false
        % If only upper central 26-tone RU user is present
        upperCentral26User = endUserIndexPer20(end)+1;
    elseif chanBW==80
        % If 80 MHz and lower central 26-tone RU user present, do not
        % repeat user carried on content channel 1
        upperCentral26User = zeros(1,0);
    else
        % If 160 MHz, carry upper central 26-tone RU user (lower carried on
        % content channel 1)
        upperCentral26User = endUserIndexPer20(end)+2;
    end
    contentChannel2Users = [contentChannel2Users upperCentral26User];
end

end