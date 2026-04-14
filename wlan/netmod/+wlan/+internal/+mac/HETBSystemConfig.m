classdef HETBSystemConfig
%HETBSystemConfig Create a high efficiency trigger-based(TB) system format configuration object
%
%   Note: This is an internal undocumented class and its API and/or
%   functionality may change in subsequent releases.
%
%   HETBSystemConfig methods:
%
%   getPSDULength       - Number of bytes to be coded in the packet
%   ruInfo              - Resource unit allocation information
%   getTRSConfiguration - Create a valid TRS configuration object
%   getUserConfig       - Generate configuration objects of type
%                         wlanHETBConfig for all uplink HE TB users
%
%   HETBSystemConfig properties:
%
%   AllocationIndex         - RU allocation index for each 20 MHz subchannel
%   LowerCenter26ToneRU     - Lower center 26-tone RU allocation signaling
%   UpperCenter26ToneRU     - Upper center 26-tone RU allocation signaling
%   RU                      - RU properties of each assignment index
%   User                    - User properties of each assignment index
%   TriggerMethod           - Method used to trigger an HE TB PPDU
%   PreHEPowerScalingFactor - Power scaling factor for pre-HE TB field
%   STBC                    - Enable space-time block coding
%   GuardInterval           - Guard interval type
%   HELTFType               - HE-LTF compression type
%   SingleStreamPilots      - Indicate HE-LTF single-stream pilots
%   PreFECPaddingFactor     - The pre-FEC padding factor for an HE TB PPDU
%   DefaultPEDuration       - Packet extension duration in microseconds
%   BSSColor                - Basic service set (BSS) color identifier
%   SpatialReuse            - Spatial reuse indication
%   TXOPDuration            - Duration information for TXOP protection
%   HighDoppler             - High Doppler mode indication
%   MidamblePeriodicity     - Midamble periodicity in number of OFDM symbols
%   HESIGAReservedBits      - Reserved bits in HE-SIG-A field
%   ChannelBandwidth        - Channel bandwidth (MHz) of HE TB PPDU
%
%   See also wlanHETBConfig, wlanHEMUConfig.

%   Copyright 2017-2025 The MathWorks, Inc.

properties
    RU;
    User;
    TriggerMethod = 'TriggerFrame';
    PreHEPowerScalingFactor = 1;
    STBC = false;
    GuardInterval = 3.2;
    HELTFType = 4;
    SingleStreamPilots = true;
    PreFECPaddingFactor = 4;
    DefaultPEDuration = 0;
    BSSColor = 0;
    SpatialReuse = [15 15 15 15];
    TXOPDuration = 127;
    HighDoppler = false;
    MidamblePeriodicity = 10;
    HESIGAReservedBits = ones(9,1);
end

properties(SetAccess = 'private')
    ChannelBandwidth = 'CBW20';
    AllocationIndex = 192;
    LowerCenter26ToneRU = false;
    UpperCenter26ToneRU = false;

end

properties(Access=private)
  PrivateUserRUNumber = 1;
end

methods
    function obj = HETBSystemConfig(allocationIndex,varargin)
    %HETBSystemConfig Create HE TB system configuration

        % Process name-value pairs
        if nargin>1
            for i = 1:2:nargin-1
                obj.(char(varargin{i})) = varargin{i+1};
            end
        end
        obj.AllocationIndex = allocationIndex;
        center26 = [obj.LowerCenter26ToneRU obj.UpperCenter26ToneRU];
        [obj.RU,obj.User,obj.PrivateUserRUNumber] = heRUAllocation(obj.AllocationIndex,center26);

        % Set channel bandwidth based on allocation index
        allocInfo = obj.ruInfo();
        if isscalar(allocationIndex) && allocInfo.NumRUs==1
            % Allow for a single number, full-band allocation
            switch allocInfo.RUSizes(1)
                case 242
                    obj.ChannelBandwidth = 'CBW20';
                case 484
                    obj.ChannelBandwidth = 'CBW40';
                case 996
                    obj.ChannelBandwidth = 'CBW80';
                case 2*996
                    obj.ChannelBandwidth = 'CBW160';
            end
        else
            switch numel(allocationIndex)
                case 1
                    obj.ChannelBandwidth = 'CBW20';
                case 2
                    obj.ChannelBandwidth = 'CBW40';
                case 4
                    obj.ChannelBandwidth = 'CBW80';
                case 8
                    obj.ChannelBandwidth = 'CBW160';
            end
        end
    end

    function s = validateConfig(obj)
        
        % Validate MCS and length
        s = validateMCSLength(obj);

    end

    function s = ruInfo(obj)
    %ruInfo Returns information relevant to the resource unit
    %   S = ruInfo(cfgHE) returns a structure, S, containing the resource
    %   unit (RU) allocation information for the HETBSystemConfig object,
    %   cfgHE. The output structure S has the following fields:
    %
    %   NumUsers                 - Total number of users
    %   NumRUs                   - Total number of RUs
    %   RUIndices                - Vector containing the index of each RU
    %   RUSizes                  - Vector containing the size of each RU
    %   NumUsersPerRU            - Vector containing the number of users
    %                              per RU
    %   NumSpaceTimeStreamsPerRU - Vector containing the total number of
    %                              space-time streams per RU
    %   PowerBoostFactorPerRU    - Vector containing the power boost factor
    %                              per RU
    %   RUNumbers                - Vector containing the index of the
    %                              corresponding cfgHE.RU object for
    %                              each active RU.
    %   RUAssigned               - Indicate assigned RUs

        numRUs = numel(obj.RU);
        numUsers = numel(obj.User);
        ruActive = true(1,numRUs);
        for j = 1:numUsers
           if (obj.User{j}.APEPLength==0 || obj.User{j}.AID12==2046)
               ruNum = obj.User{j}.RUNumber;
               if ruNum<=numRUs
                   ruActive(ruNum) = false;
               end
           end
        end
        ruIndices = zeros(1,numRUs);
        ruSizes = zeros(1,numRUs);
        ruNumbers = zeros(1,numRUs);
        numSTS = zeros(1,numRUs);
        numUsersPerRU = zeros(1,numRUs);

        k = 1;
        for i = 1:numRUs
            for j = 1:numUsers
                ruShared = i==obj.PrivateUserRUNumber(j);
                if ruShared
                    numUsersPerRU(k) = numUsersPerRU(k)+1;
                    numSTS(k) = numSTS(k)+obj.User{j}.NumSpaceTimeStreams;
                end
            end
            ruIndices(k) = obj.RU{i}.Index;
            ruSizes(k) = obj.RU{i}.Size;
            ruNumbers(k) = i;
            k = k+1;
        end

       s = struct;
       s.NumUsers = numUsers;
       s.NumRUs = numRUs;
       s.RUIndices = ruIndices;
       s.RUSizes = ruSizes;
       s.NumUsersPerRU = numUsersPerRU;
       s.NumSpaceTimeStreamsPerRU = numSTS;
       s.PowerBoostFactorPerRU = ones(1,numRUs);
       s.RUNumbers = ruNumbers;
       s.RUAssigned = ruActive;
    end

    function psduLength = getPSDULength(obj)
    %getPSDULength Returns PSDU length for the configuration
    %   Returns a row vector with the required PSDU length for each user.
    %   For more information, see IEEE Std 802.11ax-2021, Section 27.4.3.

        if strcmp(obj.TriggerMethod,'TRS')
            psduLength = heTRSPLMETxTimePrimative(obj);
        else
            psduLength = wlan.internal.hePLMETxTimePrimative(obj);
        end
    end

    function format = packetFormat(obj) %#ok<MANU>
    %packetFormat Returns the packet format
    %   Returns the packet format as a character vector.

        format = 'HE-TB System';
        
    end

    function y = getUserConfig(obj)
    %getUserConfig Generate an HE TB configuration objects for all users
    %   Y = getUserConfig(obj) returns a cell array Y, containing a
    %   wlanHETBConfig object for all user in the HE TB transmission.

        infoRU = obj.ruInfo; % Get RU information
        if strcmp(obj.TriggerMethod,'TriggerFrame')
            infoSTS = obj.stsInfo; % Get space time streams information
        end
        y = cell(1,infoRU.NumUsers);

        for nRU = 1:infoRU.NumRUs
            for nUsers = 1:infoRU.NumUsersPerRU(nRU)
                userNum = obj.RU{nRU}.UserNumbers(nUsers);
                % Create an HE TB config object for each user and
                % update it with common and user specific properties
                cfg = wlanHETBConfig;
                cfg.TriggerMethod = obj.TriggerMethod;
                cfg.ChannelBandwidth = obj.ChannelBandwidth;
                cfg.GuardInterval = obj.GuardInterval;
                cfg.STBC = obj.STBC;
                cfg.HELTFType = obj.HELTFType;
                if strcmp(cfg.TriggerMethod,'TRS')
                    cfg.StartingSpaceTimeStream = 1;
                    commonParams = heTRSCodingParameters(obj);
                    cfg.NumDataSymbols = commonParams.NSYM;
                    cfg.DefaultPEDuration = obj.DefaultPEDuration;
                else % TriggerFrame
                    cfg.StartingSpaceTimeStream = infoSTS.StartingSpaceTimeStreamNumber(userNum);
                    commonParams = wlan.internal.heCodingParameters(obj);
                    SignalExtension = 0;
                    npp = wlan.internal.heNominalPacketPadding(obj);
                    trc = wlan.internal.heTimingRelatedConstants(obj.GuardInterval,obj.HELTFType,commonParams.PreFECPaddingFactor,npp,commonParams.NSYM);
                    TPE = trc.TPE;
                    TSYM = trc.TSYM;
                    s = obj.validateConfig;
                    % Calculation in nanoseconds. PEDisambiguity is only needed for TriggerFrame
                    cfg.PEDisambiguity = (TPE+4*(ceil((s.TxTime-SignalExtension-20)/4)-(s.TxTime-SignalExtension-20)/4))>=TSYM; % IEEE Std 802.11ax-2021, Equation 27-118
                    % Set L-SIG length
                    cfg.LSIGLength = s.LSIGLength;
                end
                cfg.PreHEPowerScalingFactor = obj.PreHEPowerScalingFactor;
                user = obj.User{userNum};
                cfg.DCM = user.DCM;
                cfg.MCS = user.MCS;
                cfg.NumSpaceTimeStreams = user.NumSpaceTimeStreams;
                cfg.ChannelCoding = user.ChannelCoding;
                cfg.NumTransmitAntennas = user.NumTransmitAntennas;
                cfg.RUSize = infoRU.RUSizes(user.RUNumber);
                cfg.RUIndex = infoRU.RUIndices(user.RUNumber);
                cfg.SpatialMapping = user.SpatialMapping;
                cfg.SpatialMappingMatrix = user.SpatialMappingMatrix;
                cfg.NumHELTFSymbols = wlan.internal.numVHTLTFSymbols(max(infoRU.NumSpaceTimeStreamsPerRU));

                cfg.PreFECPaddingFactor = commonParams.PreFECPaddingFactor;
                cfg.LDPCExtraSymbol = commonParams.LDPCExtraSymbol;
                cfg.SingleStreamPilots = obj.SingleStreamPilots;
                cfg.HighDoppler = obj.HighDoppler;
                if cfg.HighDoppler
                    cfg.MidamblePeriodicity = obj.MidamblePeriodicity;
                end
                cfg.BSSColor = obj.BSSColor;
                % Set spatial reuse
                cfg.SpatialReuse1 = obj.SpatialReuse(1);
                cfg.SpatialReuse2 = obj.SpatialReuse(2);
                cfg.SpatialReuse3 = obj.SpatialReuse(3);
                cfg.SpatialReuse4 = obj.SpatialReuse(4);
                y{1,userNum} = cfg;
            end
        end
    end

    function s = stsInfo(obj)
    %stsInfo Returns information relevant to the space time streams for HE TB users

        numUsers = numel(obj.User);
        numSTSPerUser = zeros(1,numUsers);
        user = cell(1,numUsers);
        for i = 1:numUsers
            user{i} = obj.User{i};
            numSTSPerUser(i) = user{i}.NumSpaceTimeStreams;
        end
        s = ruInfo(obj);
        % Calculate start space time stream index per user
        startSTSIdxAll = zeros(1,numUsers);
        for j=1:s.NumRUs
            startSTSIdxAll(obj.RU{j}.UserNumbers(1)) = 1;
            for i = 2:s.NumUsersPerRU(j)
                user = obj.User{obj.RU{j}.UserNumbers(i-1)};
                startSTSIdxAll(obj.RU{j}.UserNumbers(i)) = startSTSIdxAll(obj.RU{j}.UserNumbers(i)-1)+user.NumSpaceTimeStreams;
            end
        end

        SpaceTimeStreamIndices = cell(1,numUsers);
        for i = 1:numUsers
            SpaceTimeStreamIndices{i} = startSTSIdxAll(i)-1+(1:numSTSPerUser(i)).';
        end

        s = struct;
        s.NumUsers = numUsers;
        s.StartingSpaceTimeStreamNumber = startSTSIdxAll;
        s.SpaceTimeStreamIndices = SpaceTimeStreamIndices;
    end

    function obj = getTRSConfiguration(obj)
    %getTRSConfiguration Return a valid TRS configuration object
    %   This method takes the current configuration and returns an object
    %   with properties set to those required for an HE TB response to TRS.
    %   The other properties are unchanged.

        allocationInfo = obj.ruInfo;
        obj.TriggerMethod = 'TRS';
        if strcmp(obj.ChannelBandwidth,'CBW20')
            for u=1:allocationInfo.NumUsers
                obj.User{u}.ChannelCoding = 'BCC';
            end
        else
            for u=1:allocationInfo.NumUsers
                if strcmp(obj.User{u}.ChannelCoding,'LDPC')
                    obj.User{u}.LDPCExtraSymbol = 1;
                end
            end
        end

        obj.HighDoppler = false;
        obj.SingleStreamPilots = true;
        obj.STBC = false;
        for u=1:allocationInfo.NumUsers
            obj.User{u}.NumSpaceTimeStreams = 1;
        end
        obj.PreFECPaddingFactor = 4;
        obj.SpatialReuse = [15 15 15 15];
    end
end

methods (Access = private)

    function s = validateMCSLength(obj)

        % Calculate PSDU length, TX time, and number of data symbols
        if strcmp(obj.TriggerMethod,'TRS')
            [psduLength,txTime,numDataSym] = heTRSPLMETxTimePrimative(obj); % Includes packet extension
        else
            [psduLength,txTime,commonCodingParams] = wlan.internal.hePLMETxTimePrimative(obj);
            numDataSym = commonCodingParams.NSYM;
        end
        % Calculate LSIGLength. IEEE Std 802.11ax-2021, Equation 27-11
        SiganlExtension = 0;
        m = 2; % For HE TB m=2. IEEE Std 802.11ax-2021, Section 27.3.11.5
        lsigLength = ceil((txTime-SiganlExtension-20e3)/4e3)*3-3-m;
 
        % Set output structure
        s = struct(...
            'TxTime', txTime/1000, ...
            'PSDULength', psduLength, ...
            'LSIGLength', lsigLength, ...
            'NumDataSymbols', numDataSym);

    end

end

end

function [ru,user,userRUNumber] = heRUAllocation(allocationIndex,varargin)
    s = wlan.internal.heAllocationInfo(allocationIndex,varargin{:});
    numRUs = s.NumRUs;
    numUsers = s.NumUsers;

    Usertmp = cell(1,numUsers);
    RUtmp = cell(1,numRUs);
    u = 1;
    userRUNumber = zeros(1,numUsers);
    for i = 1:numRUs
        ruUserNumber = zeros(1,s.NumUsersPerRU(i));
        for j = 1:s.NumUsersPerRU(i)
            userRUNumber(u) = i;
            ruUserNumber(j) = u;
            u = u+1;
        end

        % Use round to deal with invalid combos which can give a
        % non-integer RUindices.
        RUtmp{i} = heTBRU(s.RUSizes(i),round(s.RUIndices(i)),ruUserNumber);
    end

    for u = 1:numUsers
        Usertmp{u} = heTBUser(userRUNumber(u));
    end

    user = Usertmp;
    ru = RUtmp;
end

function [commonParams,userParams] = heTRSCodingParameters(cfg)
%heTRSCodingParameters Coding parameters for trigger frame of type TRS

% Form a vector of parameters, were each element is the parameter for a user
numUsers = numel(cfg.User);

% Determine which user objects are active - the AID12 is not 2046
userActive = true(1,numUsers); % Vector indicating if a user object is active
for i = 1:numUsers
    if cfg.User{i}.AID12==2046
        % If AID12 is 2046, then RU carries no data, and user is not
        % active. Therefore do not take user into account when
        % calculating coding parameters.
        userActive(i) = false;
    end
end

% Get a vector of the user object numbers which are active (AID12 is not 2046)
numActiveUsers = sum(userActive==true);
activeUserNumbers = zeros(1,numActiveUsers);
userIdx = 1;
for i = 1:numel(userActive)
    if userActive(i)
        % If user active then store active user number
        activeUserNumbers(userIdx) = i;
        userIdx = userIdx+1;
    end
end

ruSize = zeros(numUsers,1);
mcs = zeros(numUsers,1);
numSTS = zeros(numUsers,1);
apepLength = zeros(numUsers,1);
channelCoding = repmat({'LDPC'},numUsers,1);
dcm = false(numUsers,1);

for userIdx = 1:numUsers
    ruSize(userIdx) = cfg.RU{cfg.User{userIdx}.RUNumber}.Size;
    mcs(userIdx) = cfg.User{userIdx}.MCS;
    numSTS(userIdx) = cfg.User{userIdx}.NumSpaceTimeStreams;
    AID12 = cfg.User{userIdx}.AID12;
    if AID12==2046
        % If AID12 is 2046, then RU carries no data, therefore do not
        % include user in coding calculations by setting the APEPLength
        % to 0
        apepLength(userIdx) = 0;
    else
        apepLength(userIdx) = cfg.User{userIdx}.APEPLength;
    end
    channelCoding{userIdx} = cfg.User{userIdx}.ChannelCoding;
    dcm(userIdx) = cfg.User{userIdx}.DCM;
end

stbc = cfg.STBC;
if stbc % IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137
    nss = numSTS/2;
    mSTBC = 2;
else
    nss = numSTS;
    mSTBC = 1;
end

Nservice = 16; % IEEE Std 802.11ax-2021, Table 27-12

% First calculation: the initial common number of symbols and pre-FEC
% padding factor. Calculate values for all users and take the maximum. Also
% calculate NCBPSSHORT, NDPBSSHORT, and the rate dependent parameters per
% user as part of this.

NSYMinit = zeros(numUsers,1);   % Number of symbols (initial)
ainit = zeros(numUsers,1);      % Pre-FEC padding factor (initial)
NCBPSSHORT = zeros(numUsers,1); % Number of coded bits per symbol (short)
NDBPSSHORT = zeros(numUsers,1); % Number of data bits per symbol (short)
Ntail = zeros(numUsers,1);      % Number of tail bits
R = zeros(numUsers,1);          % Rate
NSS = zeros(numUsers,1);        % Number of spatial streams
NBPSCS = zeros(numUsers,1);     % Number of bits per subcarrier
NDBPS = zeros(numUsers,1);      % Number of data bits per symbol
NCBPS = zeros(numUsers,1);      % Number of coded bits per symbols
NSD = zeros(numUsers,1);        % Number of data carrying subcarriers

for u = 1:numUsers
    if channelCoding{u} == "BCC"
        Ntail(u) = 6;
    end % For LDPC, Ntail(u) is 0

    % Get rate dependent parameters for all users
    params = wlan.internal.heRateDependentParameters(ruSize(u),mcs(u),nss(u),dcm(u));
    R(u) = params.Rate;
    NSS(u) = params.NSS;
    NBPSCS(u) = params.NBPSCS;
    NDBPS(u) = params.NDBPS;
    NCBPS(u) = params.NCBPS;
    NSD(u) = params.NSD;

    % NSD,SHORT values. IEEE Std 802.11ax-2021, Table 27-33
    NSDSHORT = wlan.internal.heNSDShort(ruSize(u),dcm(u));

    % Initial number of symbol segments in the last OFDM symbol(s). IEEE
    % Std 802.11ax-2021, Equation 27-61
    NCBPSSHORT(u) = NSDSHORT*NSS(u)*NBPSCS(u);
    NDBPSSHORT(u) = NCBPSSHORT(u)*R(u);
    if strcmp(channelCoding{u},'BCC')
        % The ainit=a for TriggerMethod, TRS and ChannelCoding, BCC. The
        % PreFECPaddingFactor(a) is fixed to 4 for TRS. IEEE Std
        % 802.11ax-2021, Section 27.3.12.5.5
        ainit(u) = 4;
    else
        % The ainit=a-1 for TriggerMethod, TRS and ChannelCoding, LDPC.
        % The PreFECPaddingFactor(a) is fixed to 4 for TRS. IEEE Std
        % 802.11ax-2021, Section 27.3.12.5.5
        ainit(u) = 3; % ainit = a-1, where a=4
    end
    % BCC
    NSYMinit(u) = mSTBC*ceil((8*apepLength(u)+Ntail(u)+Nservice)/(mSTBC*NDBPS(u))); % IEEE P802.11ax/D4.1, Equation 27-65
end

% Derive user index with longest encoded packet duration, IEEE Std 802.11ax-2021, Equation 27-75
% Only user active users
[~,umax] = max(NSYMinit(userActive)-mSTBC+mSTBC.*ainit(userActive)/4);

% Use values from max for all users, % IEEE Std 802.11ax-2021, Equation 27-76
NSYMinitCommon = NSYMinit(activeUserNumbers(umax));
ainitCommon = ainit(activeUserNumbers(umax));

% Now we know the common pre-FEC padding factor and number of symbols,
% update each users number of coded bits in the last symbol

NDBPSLASTinit = zeros(numUsers,1);
NCBPSLASTinit = zeros(numUsers,1);
for u = 1:numUsers
    % Update each user's initial number of coded bits in its last
    % symbol, IEEE Std 802.11ax-2021, Equation 27-77
    if ainitCommon<4
        NDBPSLASTinit(u) = ainitCommon*NDBPSSHORT(u);
        NCBPSLASTinit(u) = ainitCommon*NCBPSSHORT(u);
    else
        NDBPSLASTinit(u) = NDBPS(u);
        NCBPSLASTinit(u) = NCBPS(u);
    end
end

% For each user which uses LDPC calculate the number of pre FEC padding
% bits and if an LDPC extra symbol is required.

NPADPreFEC = zeros(numUsers,1);
ldpcExtraSymbol = false(numUsers,1);
for u = 1:numUsers
    if strcmp(channelCoding{u},'LDPC')
        % IEEE Std 802.11ax-2021, Equation 27-78
        NPADPreFEC(u) = (NSYMinitCommon-mSTBC)*NDBPS(u)+mSTBC*NDBPSLASTinit(u)-8*apepLength(u)-Nservice; 
        % The LDPCExtraSymbol is always true for TriggerMethod, TRS. IEEE
        % Std 802.11ax-2021, Section 27.3.12.5.5. Over writing the
        % LDPCExtraSymbol to true.
        ldpcExtraSymbol(u) = true;
    end
end

% Update NSYM, the pre-FEC padding factor, NDBPSLast, and NCBPSLast for all
% users now we know if an LDPC extra symbol is required. We can also
% calculate the Pre FEC padding factor for BCC users.

commonLDPCExtraSymbol = any(ldpcExtraSymbol(userActive));
if commonLDPCExtraSymbol
    % IEEE Std 802.11ax-2021, Equation 27-83
    if ainitCommon==4
        NSYM = NSYMinitCommon+mSTBC;
        a = 1;
    else
        NSYM = NSYMinitCommon;
        a = ainitCommon+1;
    end
else
    % IEEE Std 802.11ax-2021, Equation 27-84
    NSYM = NSYMinitCommon;
    a = ainitCommon;
end

NDBPSLAST = zeros(numUsers,1);
NCBPSLAST = zeros(numUsers,1);
NPADPreFECMAC = zeros(numUsers,1);
NPADPreFECPHY = zeros(numUsers,1);
NPADPostFEC = zeros(numUsers,1);
for u = 1:numUsers
    % Part of IEEE Std 802.11ax-2021, Equation 27-85
    if a<4
        NCBPSLAST(u) = a*NCBPSSHORT(u);
    else
        NCBPSLAST(u) = NCBPS(u);
    end

    switch channelCoding{u}
        case 'LDPC'
            % Part of IEEE Std 802.11ax-2021, Equation 27-85
            NDBPSLAST(u) = NDBPSLASTinit(u);
        case 'BCC'
            % Part of IEEE Std 802.11ax-2021, Equation 27-85
            if a<4
                NDBPSLAST(u) = a*NDBPSSHORT(u);
            else
                NDBPSLAST(u) = NDBPS(u);
            end

            % IEEE P802.11ax/D4.1, Equation 27-86
            NPADPreFEC(u) = (NSYM-mSTBC)*NDBPS(u)+mSTBC*NDBPSLAST(u)-8*apepLength(u)-Ntail(u)-Nservice;
    end

    NPADPostFEC(u) = NCBPS(u)-NCBPSLAST(u); % IEEE Std 802.11ax-2021, Equation 27-87
    
    NPADPreFECMAC(u) = floor(NPADPreFEC(u)/8)*8; % IEEE Std 802.11ax-2021, Equation 27-88
    NPADPreFECPHY(u) = mod(NPADPreFEC(u),8); % IEEE Std 802.11ax-2021, Equation 27-89
end

if all(apepLength==0)
    % For NDP set all parameters to 0 so no data symbols transmitted
    NSYM = 0;
    NSYMinitCommon = 0;
    mSTBC = 0;
    NCBPSSHORT = zeros(numUsers,1);
    NDBPSSHORT = zeros(numUsers,1);
    NCBPSLAST = zeros(numUsers,1);
    NCBPSLASTinit = zeros(numUsers,1);
    NDBPSLAST = zeros(numUsers,1);
    NDBPSLASTinit = zeros(numUsers,1);
    NPADPreFECMAC = zeros(numUsers,1);
    NPADPreFECPHY = zeros(numUsers,1);
    NPADPostFEC = zeros(numUsers,1);
    a = 4;
    ainitCommon = 4;
    commonLDPCExtraSymbol = false;
end

% Parameters common to all users
commonParams = struct;
commonParams.NSYM = NSYM;
commonParams.NSYMInit = NSYMinitCommon;
commonParams.mSTBC = mSTBC;
commonParams.PreFECPaddingFactor = a;
commonParams.PreFECPaddingFactorInit = ainitCommon;
commonParams.LDPCExtraSymbol = commonLDPCExtraSymbol;

% Initialize structure
p = struct;
p.NSYM = 0;
p.NSYMInit = 0;
p.mSTBC = 0;
p.Rate = 0;
p.NBPSCS = 0;
p.NSD = 0;
p.NCBPS = 0;
p.NDBPS = 0;
p.NSS = 0;
p.DCM = false;
p.ChannelCoding = 'LDPC';
p.NCBPSSHORT = 0;
p.NDBPSSHORT = 0;
p.NCBPSLAST = 0;
p.NCBPSLASTInit = 0;
p.NDBPSLAST = 0;
p.NDBPSLASTInit = 0;
p.NPADPreFECMAC = 0;
p.NPADPreFECPHY = 0;
p.NPADPostFEC = 0;
p.PreFECPaddingFactor = 0;
p.PreFECPaddingFactorInit = 0;
p.LDPCExtraSymbol = false;       

% Replicate for all users and populate
if coder.target('MATLAB')
    if numUsers==1
        userParams = struct;
    else
        userParams = repmat(p,numUsers,1);
    end
else
    userParams = repmat(p,numUsers,1);
    coder.varsize('userParams(:).ChannelCoding');
end

for u = 1:numUsers
    userParams(u).NSYM = NSYM;
    userParams(u).NSYMInit = NSYMinitCommon;
    userParams(u).mSTBC = mSTBC;
    userParams(u).Rate = R(u);
    userParams(u).NBPSCS = NBPSCS(u);
    userParams(u).NSD = NSD(u);
    userParams(u).NCBPS = NCBPS(u);
    userParams(u).NDBPS = NDBPS(u);
    userParams(u).NSS = NSS(u);
    userParams(u).DCM = dcm(u);
    userParams(u).ChannelCoding = channelCoding{u};
    userParams(u).NCBPSSHORT = NCBPSSHORT(u);
    userParams(u).NDBPSSHORT = NDBPSSHORT(u);
    userParams(u).NCBPSLAST = NCBPSLAST(u);
    userParams(u).NCBPSLASTInit = NCBPSLASTinit(u);
    userParams(u).NDBPSLAST = NDBPSLAST(u);
    userParams(u).NDBPSLASTInit = NDBPSLASTinit(u);
    userParams(u).NPADPreFECMAC = NPADPreFECMAC(u);
    userParams(u).NPADPreFECPHY = NPADPreFECPHY(u);
    userParams(u).NPADPostFEC = NPADPostFEC(u);
    userParams(u).PreFECPaddingFactor = a;
    userParams(u).PreFECPaddingFactorInit = ainitCommon;
    userParams(u).LDPCExtraSymbol = commonLDPCExtraSymbol;
end

end

function [PSDU_LENGTH,TXTIME,NSYM] = heTRSPLMETxTimePrimative(cfg)
%heTRSPLMETxTimePrimative PSDULength, TXTIME and NSYM from PLME TXTIME
%primitive for the trigger method of type TRS

allocationInfo = ruInfo(cfg);
numUsers = allocationInfo.NumUsers;
% Get the APEPLength and channel coding per user
apepLength = zeros(numUsers,1);
channelCoding = cell(numUsers,1);

% Get AID12 for all users
for userIdx = 1:numUsers
    if cfg.User{userIdx}.AID12==2046
        % If AID12 is 2046, then RU carries no data, therefore do not
        % include user in coding calculations by setting the APEPLength
        % to 0
        apepLength(userIdx) = 0;
    else
        apepLength(userIdx) = cfg.User{userIdx}.APEPLength;
    end
    channelCoding{userIdx} = cfg.User{userIdx}.ChannelCoding;
end

NHELTF = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU));

% Calculate TXTIME
SignalExtension = 0; % in ns, 0 for 5 GHz or 6000 for 2.4 GHz

[commonCodingParams,userCodingParams] = heTRSCodingParameters(cfg);

NSYM = commonCodingParams.NSYM;
Nma = 0; % No midamble periodicity for TriggerMethod of type TRS

% Update trc.TPE for HE TB format
sf = 1e3; % Scaling factor to convert time in us into ns
trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,0);
trc.TPE = cfg.DefaultPEDuration*sf; % Update PE duration for TRS

% Part of IEEE Std 802.11ax-2021, Equation 27-121
THE_PREAMBLE = trc.TRLSIG+trc.THESIGA+trc.THESTFT+NHELTF*trc.THELTFSYM;

% IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137
TXTIME = 20*sf+THE_PREAMBLE+NSYM*trc.TSYM+Nma*NHELTF*trc.THELTFSYM+trc.TPE+SignalExtension; % TXTIME in ns

% Calculate PSDU_LENGTH per user
Nservice = 16; % Number of service bits
PSDU_LENGTH = zeros(1,numUsers);

for u = 1:numUsers
    % IEEE Std 802.11ax-2021, Section 27.4.3
    if strcmp(channelCoding{u},'BCC') % IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137, Equation 27-138
        Ntail = 6; % IEEE Std 802.11ax-2021, Table 27-12
        PSDU_LENGTH(u) = floor(((commonCodingParams.NSYM-commonCodingParams.mSTBC)*userCodingParams(u).NDBPS+commonCodingParams.mSTBC*userCodingParams(u).NDBPSLAST-Nservice-Ntail)/8);
    else % IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137, Equation 27-139
        Ntail = 0; % LDPC
        PSDU_LENGTH(u) = floor(((commonCodingParams.NSYMInit-commonCodingParams.mSTBC)*userCodingParams(u).NDBPS+commonCodingParams.mSTBC*userCodingParams(u).NDBPSLASTInit-Nservice-Ntail)/8);
    end
end
end

function s = heTBRU(size,index,userNumbers)

    s = struct();
    s.Size = size;
    s.Index = index;
    s.UserNumbers = userNumbers;

end

function s = heTBUser(ruNumber)

    s = struct();
    s.NumTransmitAntennas = 1;
    s.PreHECyclicShifts = -75;
    s.NumSpaceTimeStreams = 1;
    s.SpatialMapping = 'Direct';
    s.SpatialMappingMatrix = complex(1);
    s.MCS = 0;
    s.DCM = 0;
    s.ChannelCoding = 'LDPC';
    s.LDPCExtraSymbol = 1;
    s.APEPLength = 100;
    s.AID12 = 0;
    s.NominalPacketPadding = 0;
    s.RUNumber = ruNumber;

end
