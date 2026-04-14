function [bits,failCRC,varargout] = wlanHESIGBUserBitRecover(rx,noiseVarEst,varargin)
%wlanHESIGBUserBitRecover Recover user field bits from HE-SIG-B field
%   [BITS,FAILCRC,CFGRX] = wlanHESIGBUserBitRecover(RX,NOISEVAREST,CFGRX)
%   recovers the HE-SIG-B user field bits given the HE-SIG-B field from an
%   HE multi-user transmission, the noise variance estimate, and the
%   HE configuration object of type wlanHERecoveryConfig.
%   When you use this syntax and the function cannot interpret the
%   recovered HE-SIG-B user field bits due to an unexpected value, an
%   exception is issued, and the function does not return an output.
%
%   BITS is an int8 matrix of size 21-by-NumUsers, where NumUsers is the
%   number of users in the transmission, containing the recovered user
%   field bits for all users. The function only returns BITS if it can
%   decode the corresponding content channel.
%
%   FAILCRC represents the result of the CRC for each user. It is true if
%   the user fails the CRC. It is a logical row vector of size
%   1-by-NumUsers.
%
%   Returned CFGRX is a cell array of size 1-by-NumUsers. CFGRX is the
%   updated format configuration object after HE-SIG-B user field decoding,
%   of type wlanHERecoveryConfig. The updated format configuration object
%   CFGRX is only returned for the users who pass the CRC.
%
%   [BITS,FAILCRC] = wlanHESIGBUserBitRecover(...), when you use this
%   syntax and the function cannot interpret the recovered HE-SIG-B user
%   field bits due to an unexpected value, no exception is issued.
%
%   RX are the complex demodulated HE-SIG-B field symbols of size N-by-1,
%   where N is the number of active sub-carriers in HE-SIG-B field. N is 52
%   for CBW20, and 104 for CBW40, CBW80 and CBW160. For bandwidths greater
%   than 40 MHz, RX contains the combined 20 MHz subchannel repetitions.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   The input CFGRX is the format configuration object of type wlanHERecoveryConfig,  
%   which specifies the parameters for the HE MU format.
%
%   [...] = wlanHESIGBUserBitRecover(...,CSI,CFGRX) uses the channel state
%   information to enhance the demapping of OFDM subcarriers. CSI is an
%   M-by-1 column vector of real values, where M is the number of data
%   subcarriers in HE-SIG-B field.

%   Copyright 2019-2025 The MathWorks, Inc.

%#codegen

narginchk(3,4);
nargoutchk(0,3);
returnObjects = nargout==3; % Validate the interpreted bit values

validateattributes(rx,{'single','double'},{'2d','finite'},mfilename,'rx');
[numSubcarriers,numSIGBSymbols] = size(rx);

if isa(varargin{1},'wlanHERecoveryConfig')
    % wlanHESIGBUserBitRecover(RX,NOISEVAREST,CFGRX)
    csi = ones(numSubcarriers,1);
    cfg = varargin{1};
elseif nargin>3 && isa(varargin{2},'wlanHERecoveryConfig')
    % wlanHESIGBUserBitRecover(RX,NOISEVAREST,CSI,CFGRX)
    csi = varargin{1};
    cfg = varargin{2};
else
    coder.internal.error('wlan:he:InvalidConfigType');
end

numUsersPerContentChannel = cfg.NumUsersPerContentChannel;
sigbCompression = cfg.SIGBCompression;

if numSubcarriers==0
    % Return empty for 0 samples
    bits = zeros(0,1,'int8');
    failCRC = false(0,1);
    if returnObjects
        varargout{1} = {};
    end
    return;
end

% Validate CSI input
if nargin>3
    validateattributes(csi,{'single','double'},{'real','3d','finite'},mfilename,'CSI');
    if any(size(csi)~=[numSubcarriers 1])
        coder.internal.error('wlan:he:InvalidCSISize',numSubcarriers,1);
    end
end

% Only valid for HE MU packet
coder.internal.errorIf(~strcmp(cfg.PacketFormat,'HE-MU'),'wlan:he:InvalidPacketFormat');

% Validate ChannelBandwidth, NumUserPerContentChannel and AllocationIndex
wlan.internal.mustBeDefined(cfg.NumUsersPerContentChannel,'NumUsersPerContentChannel');
wlan.internal.mustBeDefined(cfg.AllocationIndex,'AllocationIndex');
validateConfig(cfg,'RUAllocation');

% Validate input size subcarriers(rows)
chanBW = cfg.ChannelBandwidth;
switch chanBW
    case 'CBW20'
        expectedNumSubCarriers = 52;
        numContentChannels = 1;
    otherwise
        expectedNumSubCarriers = 104;
        numContentChannels = 2;
end
coder.internal.errorIf(numSubcarriers~=expectedNumSubCarriers,'wlan:he:InvalidRowLength',expectedNumSubCarriers);

% Validate noise variance
validateattributes(noiseVarEst,{'single','double'},{'real','scalar','nonnegative','finite'},mfilename,'noiseVarEst');

% Validate MCS, DCM and SIGBCompression properties
MCS = cfg.SIGBMCS;
DCM = cfg.SIGBDCM;
cfg.validateConfig('HESIGB');

% Validate the number of HE-SIG-B symbols required
if ~sigbCompression
    wlan.internal.mustBeDefined(cfg.NumSIGBSymbolsSignaled,'NumHESIGBSymbolsSignaled');
end

% The location of invalid content channel indicated by the AllocationIndex
% should match with NumUsersPerContentChannel
invalidContentChannel = false(1,numContentChannels);
allocationIndex = cfg.AllocationIndex;
mcsTable = wlan.internal.heSIGBRateTable(MCS,DCM);
chbw = wlan.internal.cbwStr2Num(chanBW);
commonInfo = wlan.internal.heSIGBCommonFieldInfo(chbw,mcsTable.NDBPS);
% Get the allocation index per content channel
if sigbCompression
    numCommonFieldBits = 0;
else
    % Get number of HE-SIG-B common field bit
    numCommonFieldBits = commonInfo.NumCommonFieldBits;
    for i=1:numContentChannels
        % Check if there is an invalid user in NumUsersPerContentChannel
        invalidContentChannel(i) = numUsersPerContentChannel(i)==-1;
        allocationPerContentChannel = reshape(allocationIndex,numContentChannels,ceil(numel(allocationIndex)/2));
        invalidAllocationIndex = any(allocationPerContentChannel(i,:)==-1);
        coder.internal.errorIf(invalidAllocationIndex~=invalidContentChannel(i),'wlan:wlanHESIGBUserBitRecover:InvalidContentChannelLocation');
    end
end
% Calculate the number of HE-SIG-B symbols
expectedNumSIGBSymbols = wlan.internal.heNumSIGBSymbolsPerContentChannel(commonInfo.NumContentChannels,cfg.NumUsersPerContentChannel,numCommonFieldBits,mcsTable.NDBPS);
coder.internal.errorIf(numSIGBSymbols<expectedNumSIGBSymbols,'wlan:wlanHESIGBUserBitRecover:InvalidHESIGBSymbols',expectedNumSIGBSymbols);
[numUserFieldPairBits,numUserFieldBits,numCRCBits,numTailBits] = getNumUserFieldBits();

% Only process users on valid HE-SIG-B content channel. The AllocationIndex
% and NumUsersPerContentChannel properties of the configuration object are
% used to infer the valid HE-SIG-B content channel required to be
% processed.
if any(invalidContentChannel) && invalidContentChannel(1)==0
    % Process the first content channel
    startIndex = 1;
    endIndex = 1;
elseif any(invalidContentChannel) && invalidContentChannel(1)==1
    % Process the second content channel
    startIndex = 2;
    endIndex = 2;
else % Process all content channels
    startIndex = 1;
    endIndex = 2;
    if strcmp(cfg.ChannelBandwidth,'CBW20')
        endIndex = 1; % Only one content channel in CBW20
    end
end

% Initialization
userBitsContentCh1 = zeros(21,0,'int8');
userBitsContentCh2 = zeros(21,0,'int8');
failCRC1 = false(1,0);
failCRC2 = false(1,0);

% Process valid content channel
for icc=startIndex:endIndex
    failCRCPerUser = false(1,0); % Initialize for each content channel

    % Decode HE-SIG-B common field
    nsdIndex = 52*(icc-1)+(1:52); % Subcarrier indices for a content channel
    decoded = wlan.internal.heSIGBDecode(rx(nsdIndex,:),csi(nsdIndex,:),noiseVarEst,mcsTable,MCS,DCM);

    % Decode user fields
    numUsersPerCC = numUsersPerContentChannel(icc);
    oddNumberOfUsers = mod(numUsersPerCC,2);
    if oddNumberOfUsers
        % Extra user (not all pairs)
        numPairs = (numUsersPerCC-1)/2;
        oddUserBits = decoded(numCommonFieldBits+numPairs*numUserFieldPairBits+(1:(numUserFieldBits+numTailBits+numCRCBits)));
    else
        numPairs = numUsersPerCC/2;
        oddUserBits = zeros(0,1,'int8'); % For codegen
    end

    % Extract all user field (without padding) from content channel
    decodedUserPairs = decoded(numCommonFieldBits+(1:numUserFieldPairBits*numPairs));

    % Pre-allocation bit storage
    userBits = coder.nullcopy(zeros(numUserFieldBits,numUsersPerCC,'int8'));
    crcBits = coder.nullcopy(zeros(4,numPairs+oddNumberOfUsers,'int8'));

    % Reshape so each column is a pair of user fields (excluding any odd number)
    if numPairs~=0
        decodedUserBlock = reshape(decodedUserPairs,numUserFieldPairBits,numPairs); % 52-by-numPairs
        userBits(:,1:numPairs*2) = reshape(decodedUserBlock(1:numUserFieldBits*2,:),numUserFieldBits,[]);
        crcBits(:,1:numPairs) = decodedUserBlock(numUserFieldBits*2+(1:numCRCBits),:);
        % Test checksums for pairs
        for ip=1:numPairs
            checksum = wlan.internal.crcGenerate(decodedUserBlock(1:numUserFieldBits*2,ip),8);
            commonUserBlockError = any(checksum(1:4)~=crcBits(:,ip));
            % Same CRC for both users in a pair
            failCRCPerUser = [failCRCPerUser repmat(commonUserBlockError,1,2)]; %#ok<AGROW>
        end
    end

    if oddNumberOfUsers
        % If odd number of users, add the final user
        userBits(:,numUsersPerCC) = oddUserBits(1:numUserFieldBits);
        crcBits(:,numPairs+1) = oddUserBits(numUserFieldBits+(1:numCRCBits));

        % Test checksum for final user
        checksum = wlan.internal.crcGenerate(userBits(:,numUsersPerCC),8);
        commonUserBlockError = any(checksum(1:4)~=crcBits(:,numPairs+1));
        % Append CRC for the last user
        failCRCPerUser = [failCRCPerUser commonUserBlockError]; %#ok<AGROW>
    end

    if icc==1
        userBitsContentCh1 = userBits;
        failCRC1 = failCRCPerUser;
    else
        userBitsContentCh2 = userBits;
        failCRC2 = failCRCPerUser;
    end
end

bits = [userBitsContentCh1 userBitsContentCh2]; % HE-SIG-B user field bits
failCRC = [failCRC1 failCRC2]; % CRC for all user
if returnObjects
    if all(failCRC,1) % For codegen
        % If CRC fails for all users or if there are no users within an RU
        varargout{1} = {};
    else
        varargout{1} = wlan.internal.interpretHEMUSIGBUserBits(bits,invalidContentChannel,failCRC,cfg);
    end
end

end

function [numUserFieldPairBits,numUserFieldBits,numCRCBits,numTailBits] = getNumUserFieldBits
%getNumUserFieldBits User field info

    numCRCBits = 4;
    numTailBits = 6;
    numUserFieldBits = 21;
    numUserFieldPairBits = numUserFieldBits*2+numTailBits+numCRCBits;
end

