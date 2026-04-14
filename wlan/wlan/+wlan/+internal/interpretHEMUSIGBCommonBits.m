function [cfgMU,failInterpretation] = interpretHEMUSIGBCommonBits(bits,failCRC,cfgMU,varargin)
%interpretHEMUSIGBCommonBits Interpret HE-SIG-B common field bits for an HE MU packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [CFGMU,FAILINTERPRETATION] =
%   interpretHEMUSIGBCommonBits(bits,failCRC,cfgRx) parses and interprets
%   decoded HE-SIG-B common bits and returns an updated recovery object
%   with the relevant HE-SIG-B fields set. The HE-SIG-B common bit fields
%   are defined in IEEE Std 802.11ax-2021, Table 27-20 and Table 27-21. When
%   you use this syntax and the function cannot interpret the recovered
%   HE-SIG-B common field bits due to an unexpected value, an exception is
%   issued, and the function does not return an output.
%
%   BITS is an int8 matrix containing the recovered common field bits for
%   each content channel of HE-SIG-B field. The size of the BITS output
%   depends on the channel bandwidth:
%
%   * For a channel bandwidth of 20 MHz the size of BITS is 18-by-1.
%   * For a channel bandwidth of 40 MHz the size of BITS is 18-by-2.
%   * For a channel bandwidth of 80 MHz the size of BITS is 27-by-2.
%   * For a channel bandwidth of 160 MHz the size of BITS is 43-by-2.
%
%   FAILCRC is a logical vector of size 1-by-NumContentChannel.
%
%   CFGMU is the format configuration object of type <a href="matlab:help('wlanHERecoveryConfig')">wlanHERecoveryConfig</a>, which 
%   specifies the parameters for recovered HE MU packet format.
%
%   [...] = interpretHEMUSIGBCommonBits(...,SUPPRESSERROR) controls the
%   behavior of the function due to an unexpected value of the interpreted
%   HE-SIG-B common field bits. SUPPRESSERROR is logical. When
%   SUPPRESSERROR is true and the function cannot interpret the recovered
%   HE-SIG-B common field bits due to an unexpected value, the function
%   returns FAILINTERPRETATION as true and cfgMU is unchanged. When
%   SUPPRESSERROR is false and the function cannot interpret the recovered
%   HE-SIG-B common field bits due to an unexpected value, an exception is
%   issued, and the function does not return an output. The default is
%   false.

%   Copyright 2020-2025 The MathWorks, Inc.

%#codegen

nargoutchk(1,2);
suppressError = false; % Control the validation of the interpreted HE-SIG-A bits
failInterpretation = false;
if nargin>3
    suppressError = varargin{1};
end

chanBW = cfgMU.ChannelBandwidth;
cbw = wlan.internal.cbwStr2Num(chanBW);
sigbMCSTable = wlan.internal.heSIGBRateTable(cfgMU.SIGBMCS,cfgMU.SIGBDCM);
commonInfo = wlan.internal.heSIGBCommonFieldInfo(cbw,sigbMCSTable.NDBPS);
center26ToneRU = zeros(1,commonInfo.NumContentChannels);
ruAllocation = coder.nullcopy(zeros(commonInfo.NumRUAllocationSubfield*8,commonInfo.NumContentChannels));
lowerCenter26ToneRU = -1;
upperCenter26ToneRU = -1;

for icc = 1:commonInfo.NumContentChannels
    % Parse input bits
    ruAllocation(:,icc) = bits(1:commonInfo.NumRUAllocationSubfield*8,icc);
    % Extract Center26ToneRU information for CBW80 and CBW160
    if any(strcmp(chanBW,{'CBW80','CBW160'}))
        center26ToneRU(:,icc) = bits(commonInfo.NumRUAllocationSubfield*8+1,icc);
    end
end

% If any of the content channel fail the CRC
startIndex = 1; % Process all contents channels
if sum(any(failCRC,1))==1 % For codegen
    % CRC fail for any of the content channel

    % Split the allocation index per content channel. For example,
    % there are two alternate allocation indices indicated in both
    % content channel for CBW80. Similarly, there are four alternate
    % content channel indicated on both content channel for CBW160.
    allocationPerCC = interpretRUAllocationBits(ruAllocation,commonInfo.NumContentChannels);
    % Only process the content channel with valid/pass CRC. Get the column index of the content channel that passes CRC.
    startIndexTemp = find(failCRC(1,:)==0);
    startIndex = startIndexTemp(1); % For codegen
    endIndex = startIndex;
    % Define allocation index as a row vector of -1s.
    allocationIndex = ones(1,numel(allocationPerCC))*-1;
    % Get and update the allocation index indicated in the content channel with valid/pass CRC.
    allocationIndex(startIndex:2:end) = allocationPerCC(startIndex,:);

    if startIndex==1
        % Process content channel-1
        if strcmp(chanBW,'CBW80')
            % The existence of user on LowerCenter26ToneRU is indicated by content channel-1 for CBW80
            center26ToneRUUser = [center26ToneRU(1) 0];
        elseif strcmp(chanBW,'CBW160')
            % The existence of user on LowerCenter26ToneRU is indicated by content channel-1 for CBW160
            center26ToneRUUser = [center26ToneRU(1) 0];
            center26ToneRU = [center26ToneRU(1) 0];
        else % For CBW40 and CBW20, there is no center26ToneRU
            center26ToneRUUser = [0 0];
        end
    else
        % Process content channel-2
        if strcmp(chanBW,'CBW80')
            % No user exists on UpperCenter26ToneRU for CBW80
            center26ToneRUUser = [0 0];
        elseif strcmp(chanBW,'CBW160')
            % The existence of user on UpperCenter26ToneRU is indicate on content channel-2 for CBW160
            center26ToneRUUser = [0 center26ToneRU(2)];
            center26ToneRU = [0 center26ToneRU(2)];
        else % For CBW40 and CBW20, there is no center26ToneRU
            center26ToneRUUser = [0 0];
        end
    end
else
   % All content channel passes the CRC
   [allocationPerCC,allocationIndex] = interpretRUAllocationBits(ruAllocation,commonInfo.NumContentChannels);
   endIndex = commonInfo.NumContentChannels;
   if strcmp(chanBW,'CBW80')
       % The existence of user on LowerCenter26ToneRU is indicated on
       % content channel-1&2 for CBW80. The user on LowerCenter26ToneRU is
       % only transmitted on content channel-1.
       center26ToneRUUser = [center26ToneRU(1) 0];
   else
       center26ToneRUUser = center26ToneRU;
   end
end

% Get number of users per content channel
numUsersPerContentChannel = ones(1,commonInfo.NumContentChannels)*-1;
for u = startIndex:endIndex
    if all(allocationPerCC(u,:)==114) || all(allocationPerCC(u,:)==115)
        % No user exist if the complete allocation index per content channel is 114 or 115
        numUserPerCC = 0; % Indicates no user on a content channel
    else
        allocation = allocationPerCC(u,:);
        numUserPerCC = 0;
        for j = 1:numel(allocation)
            allocationstr = wlan.internal.heRUAllocationLUT(allocation(j));
            numUserPerCC = numUserPerCC+allocationstr.NumUsers;
        end
    end
    % Number of users in each content channel
    numUsersPerContentChannel(u) = sum(numUserPerCC)+center26ToneRUUser(u);
end

% Update center26ToneRU information in the recovery object
if strcmp(chanBW,'CBW80')
    % The LowerCenter26Tone RU information is sent on both content channels
    lowerCenter26ToneRU = center26ToneRU(startIndex);
    upperCenter26ToneRU = -1;
elseif strcmp(chanBW,'CBW160')
    lowerCenter26ToneRU = center26ToneRU(1);
    upperCenter26ToneRU = center26ToneRU(2);
end

% Check decoded field value for the AllocationIndex
setAllocation = allocationIndex(allocationIndex>-1); % Check allocations which are defined

% Allocation index must be valid for decoded bandwidth
if cbw<160 % All allocation indices valid for 160
    ruAllocations40 = [114 200:207];
    ruAllocations80 = [115 208:215];
    ruAllocations160 = 216:223;
    switch cbw 
        case 20
            invalidAllocations = [ruAllocations40 ruAllocations80 ruAllocations160];
        case 40
            invalidAllocations = [ruAllocations80 ruAllocations160];
        otherwise % 80
            invalidAllocations = ruAllocations160;
    end 
    if any(ismember(setAllocation,invalidAllocations),'all')
        if suppressError
            failInterpretation = true;
            return
        else
            % Throw a custom error as setting the APEPLength property will not
            % throw an error
            coder.internal.error('wlan:shared:InvalidSignaledAllocationIndex');
        end
    end
end

% Check allocation index is valid. If not suppressing error, rely on error
% thrown when setting the APEPLength property below.
if any(setAllocation>223,'all') && suppressError
    failInterpretation = true;
    return
end
cfgMU.AllocationIndex = allocationIndex;

% Calculate the number of HE-SIG-B symbols per content channel when
% NumSIGBSymbolsSignaled < 16. If expectedNumSIGBSymbols per content
% channel is greater than NumSIGBSymbolsSignaled then it is not possible to
% recover the users on that content channel.
for i = 1:commonInfo.NumContentChannels
    if numUsersPerContentChannel(i)~=-1 && cfgMU.NumSIGBSymbolsSignaled<16
        expectedNumSIGBSymbols = wlan.internal.heNumSIGBSymbolsPerContentChannel(1,numUsersPerContentChannel(i),commonInfo.NumCommonFieldBits,sigbMCSTable.NDBPS);
        if cfgMU.NumSIGBSymbolsSignaled<expectedNumSIGBSymbols
            % Unable to decode the user set numUsersPerContentChannel to -1
            numUsersPerContentChannel(i) = -1;
        end
    end
end

% Number of users per content channel must not be undefined (-1) for all
% content channels
if all(numUsersPerContentChannel==-1)
    if suppressError
        failInterpretation = true;
    else
        coder.internal.error('wlan:interpretHEMUSIGBCommonBits:InvalidSignaledHESIGBSymbols');
    end
end

cfgMU.NumUsersPerContentChannel = numUsersPerContentChannel;
cfgMU.LowerCenter26ToneRU = lowerCenter26ToneRU;
cfgMU.UpperCenter26ToneRU = upperCenter26ToneRU;

end

function [allocationPerCC,allocationIndex] = interpretRUAllocationBits(ruAllocation,numContentChannel)
%interpretRUAllocationBits Interpret RU allocation bits
    tmp = bit2int(ruAllocation(:),8,false);
    allocationPerCC = reshape(tmp,[],numContentChannel)';
    allocationIndex = allocationPerCC(:)';
end