function [commonParams,varargout] = ehtCodingParameters(cfg,varargin)
%ehtCodingParameters EHT coding parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [COMMONPARAMS,USERPARAMS] = ehtCodingParameters(CFG) returns a
%   structure COMMONPARAMS, containing the coding parameters common to all
%   users, and an array of structures, USERPARAMS, containing the coding
%   parameters for each user, and an array as define in IEEE
%   P802.11be/D2.0.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlaEHTMUConfig')">wlanEHTMUConfig</a>, or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.
%
%   [COMMONPARAMS,USERPARAMS] = ehtCodingParameters(CFG,RUIDX,USERIDX)
%   returns the user parameters given the specific RU (resource unit)
%   index, RUIDX, and user index, USERIDX

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

if isequal(packetFormat(cfg),'EHT-TB')
    [commonParams,varargout{1:nargout-1}] = triggerBasedCoding(cfg);
    return;
end

% Form a vector of parameters, each element is the parameter for a user
numUsers = numel(cfg.User);

% Get STAID(EHT MU) and AID12(EHT TB) for all users
STAID = coder.nullcopy(zeros(1,numUsers));
userActive = true(1,numUsers); % Vector indicating if a user object is active
for u = 1:numUsers
    if isequal(packetFormat(cfg),'EHT-MU')
        STAID(u) = cfg.User{u}.STAID;
    else % EHT-TB System
        STAID(u) = cfg.User{u}.AID12; % Mapping AID12 to STAID
    end
    % Determine which user objects are active - the STAID is not 2046
    if STAID(u)==2046
        % If STAID is 2046, then RU carries no data, and user is not
        % active. Therefore do not take user into account when
        % calculating coding parameters.
        userActive(u) = false;
    end
end

% Get a vector of the user object numbers which are active (STAID is not 2046)
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

ruSize = cell(numUsers,1);
mcs = zeros(numUsers,1);
numSTS = zeros(numUsers,1);
apepLength = zeros(numUsers,1);
channelCoding = repmat(wlan.type.ChannelCoding.ldpc,numUsers,1); % Initialize
dcm = false(numUsers,1); % DCM is only applicable for MCS 14, 15

for userIdx = 1:numUsers
    ruSize{userIdx} = cfg.RU{cfg.User{userIdx}.RUNumber}.Size;
    mcs(userIdx) = cfg.User{userIdx}.MCS;
    numSTS(userIdx) = cfg.User{userIdx}.NumSpaceTimeStreams;
    if STAID(userIdx)==2046
        % If STAID is 2046, then RU carries no data, therefore do not
        % include user in coding calculations by setting the APEPLength
        % to 0
        apepLength(userIdx) = 0;
    else
        apepLength(userIdx) = cfg.User{userIdx}.APEPLength;
    end
    channelCoding(userIdx) = cfg.User{userIdx}.ChannelCoding;
    if any(mcs(userIdx)==[14 15])
        dcm(userIdx) = true;
    end
end

nss = numSTS;
Nservice = 16; % Table 36-18

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
    switch channelCoding(u)
        case wlan.type.ChannelCoding.bcc
            Ntail(u) = 6;
        case wlan.type.ChannelCoding.ldpc
            Ntail(u) = 0;
    end

    % Get rate dependent parameters for all users
    params = wlan.internal.heRateDependentParameters(sum(ruSize{u}),mcs(u),nss(u),dcm(u));
    R(u) = params.Rate;
    NSS(u) = params.NSS;
    NBPSCS(u) = params.NBPSCS;
    NDBPS(u) = params.NDBPS;
    NCBPS(u) = params.NCBPS;
    NSD(u) = params.NSD;

    % Number of excess bits in last OFDM symbol
    NEXCESS = mod(8*apepLength(u)+Ntail(u)+Nservice,NDBPS(u)); % Equation 36-47

    % NSD, SHORT values. Table 36-46
    NSDSHORT = wlan.internal.heNSDShort(sum(ruSize{u}),dcm(u),cfg.EHTDUPMode);

    % Initial number of symbol segments in the last OFDM symbol(s), Equation 36-48
    NCBPSSHORT(u) = NSDSHORT*NSS(u)*NBPSCS(u);
    NDBPSSHORT(u) = NCBPSSHORT(u)*R(u);
    if NEXCESS==0 % Equation 36-48
        ainit(u) = 4;
    else
        ainit(u) = min(ceil(NEXCESS/(NDBPSSHORT(u))),4);
    end

    NSYMinit(u) = ceil((8*apepLength(u)+Ntail(u)+Nservice)/(NDBPS(u))); % Equation 36-49
end

% Derive user index for active users with longest encoded packet duration, Equation 36-48
[~,umax] = max(NSYMinit(userActive)-1+ainit(userActive)/4);

% Use values from max for all users. Equation 36-50
NSYMinitCommon = NSYMinit(activeUserNumbers(umax));
ainitCommon = ainit(activeUserNumbers(umax));

% Now we know the common pre-FEC padding factor and number of symbols,
% update each users number of coded bits in the last symbol

NDBPSLASTinit = zeros(numUsers,1);
NCBPSLASTinit = zeros(numUsers,1);
for u = 1:numUsers
    % Update each user's initial number of coded bits in its last
    % symbol, Equation 36-52, 36-53
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
    if channelCoding(u)==wlan.type.ChannelCoding.ldpc
        % Equation 36-63
        NPADPreFEC(u) = (NSYMinitCommon-1)*NDBPS(u)+NDBPSLASTinit(u)-8*apepLength(u)-Nservice; 

        mSTBC = 1; % No STBC in EHT
        ldpcParms = wlan.internal.heCommonLDPCParameters(NSYMinitCommon,mSTBC,NDBPS(u),NCBPS(u),NDBPSLASTinit(u),NCBPSLASTinit(u),R(u));
        ldpcExtraSymbol(u) = ldpcParms.LDPCExtraSymbol;
    end
end

% Update NSYM, the pre-FEC padding factor, NDBPSLast, and NCBPSLast for all
% users now we know if an LDPC extra symbol is required. We can also
% calculate the Pre FEC padding factor for BCC users.

commonLDPCExtraSymbol = any(ldpcExtraSymbol(userActive));
if commonLDPCExtraSymbol
    % Equation 36-58
    if ainitCommon==4
        NSYM = NSYMinitCommon+1;
        a = 1;
    else
        NSYM = NSYMinitCommon;
        a = ainitCommon+1;
    end
else
    % Equation 36-59
    NSYM = NSYMinitCommon;
    a = ainitCommon;
end

NDBPSLAST = zeros(numUsers,1);
NCBPSLAST = zeros(numUsers,1);
NPADPreFECMAC = zeros(numUsers,1);
NPADPreFECPHY = zeros(numUsers,1);
NPADPostFEC = zeros(numUsers,1);
for u = 1:numUsers
    % Equation 36-62
    if a<4
        NCBPSLAST(u) = a*NCBPSSHORT(u);
    else
        NCBPSLAST(u) = NCBPS(u);
    end

    switch channelCoding(u)
        case wlan.type.ChannelCoding.ldpc
            % Equation 36-60
            NDBPSLAST(u) = NDBPSLASTinit(u);
        case wlan.type.ChannelCoding.bcc
            % Equation 36-61
            if a<4
                NDBPSLAST(u) = a*NDBPSSHORT(u);
            else
                NDBPSLAST(u) = NDBPS(u);
            end

            % Equation 36-64
            NPADPreFEC(u) = (NSYM-1)*NDBPS(u)+NDBPSLAST(u)-8*apepLength(u)-Ntail(u)-Nservice;
    end

    NPADPostFEC(u) = NCBPS(u)-NCBPSLAST(u); % Equation 36-65
    NPADPreFECMAC(u) = floor(NPADPreFEC(u)/8)*8; % Equation 36-66
    NPADPreFECPHY(u) = mod(NPADPreFEC(u),8); % Equation 36-67
end

if all(apepLength==0)
    % For NDP set all parameters to 0 so no data symbols transmitted
    NSYM = 0;
    NSYMinitCommon = 0;
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
commonParams.PreFECPaddingFactor = a;
commonParams.PreFECPaddingFactorInit = ainitCommon;
commonParams.LDPCExtraSymbol = commonLDPCExtraSymbol;
commonParams.EHTDUPMode = cfg.EHTDUPMode;

if nargout>1
    if nargin>1
        u = varargin{1}; % User of interest

        % Return structure for user of interest
        userParams = struct;
        userParams.NSYM = NSYM;
        userParams.NSYMInit = NSYMinitCommon; % Use the common MU one as per 36-49
        userParams.mSTBC = 1; % No STBC in EHT (leaving this field, needed by wlan.internal.heCommonLDPCParameters)
        userParams.Rate = R(u);
        userParams.NBPSCS = NBPSCS(u);
        userParams.NSD = NSD(u);
        userParams.NCBPS = NCBPS(u);
        userParams.NDBPS = NDBPS(u);
        userParams.DCM = dcm(u);
        userParams.NSS = NSS(u);
        userParams.ChannelCoding = channelCoding(u);

        userParams.NCBPSSHORT = NCBPSSHORT(u);
        userParams.NDBPSSHORT = NDBPSSHORT(u);
        userParams.NCBPSLAST = NCBPSLAST(u);
        userParams.NCBPSLASTInit = NCBPSLASTinit(u);
        userParams.NDBPSLAST = NDBPSLAST(u);
        userParams.NDBPSLASTInit = NDBPSLASTinit(u);
        userParams.NPADPreFECMAC = NPADPreFECMAC(u);
        userParams.NPADPreFECPHY = NPADPreFECPHY(u);
        userParams.NPADPostFEC = NPADPostFEC(u);
        userParams.PreFECPaddingFactor = a;
        userParams.PreFECPaddingFactorInit = ainitCommon;
        userParams.LDPCExtraSymbol = commonLDPCExtraSymbol;
        userParams.EHTDUPMode = cfg.EHTDUPMode;
        userParams.PSDULength = 0; % For codegen. Added a dummy value as new fields cannot be added when structure has been read or used (see the line below)
        userParams.PSDULength = getPSDUlength(userParams);
    else
        % Initialize structure
        p = struct;
        p.NSYM = 0;
        p.NSYMInit = 0; % Use the common MU one as per 36-49
        p.mSTBC = 0; % No STBC in EHT (leaving this field, needed by wlan.internal.heCommonLDPCParameters)
        p.Rate = 0;
        p.NBPSCS = 0;
        p.NSD = 0;
        p.NCBPS = 0;
        p.NDBPS = 0;
        p.NSS = 0;
        p.DCM = false;
        p.ChannelCoding = wlan.type.ChannelCoding.ldpc;
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
        p.PSDULength = 0;
        p.EHTDUPMode = false;
        
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
            userParams(u).NSYMInit = NSYMinitCommon; % Use the common MU one as per 36-51
            userParams(u).mSTBC = 1; % No STBC in EHT (leaving this field, needed by wlan.internal.heCommonLDPCParameters)

            userParams(u).Rate = R(u);
            userParams(u).NBPSCS = NBPSCS(u);
            userParams(u).NSD = NSD(u);
            userParams(u).NCBPS = NCBPS(u);
            userParams(u).NDBPS = NDBPS(u);
            userParams(u).NSS = NSS(u);
            userParams(u).DCM = dcm(u);
            userParams(u).ChannelCoding = channelCoding(u);

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
            userParams(u).EHTDUPMode = cfg.EHTDUPMode;
            userParams(u).PSDULength = 0; % For codegen. Added a dummy value as new fields cannot be added when structure has been read or used (see the line below)
            userParams(u).PSDULength = getPSDUlength(userParams(u)); 
        end
    end
    varargout{1} = userParams;
end
end

function [commonParams,varargout] = triggerBasedCoding(cfg)
    % Determine the coding parameters for the trigger-based format as per
    % IEEE P802.11be/D2.0, Section 36.3.13.3.6.

    dcm = false;
    ehtDUPMode = false;
    if cfg.MCS==15
        dcm = true;
    end
    nss = cfg.NumSpaceTimeStreams;
    mcs = cfg.MCS;
    ruSize = cfg.RUSize;
    ainit = cfg.PreFECPaddingFactor;

    [~,NSYMinit] = wlan.internal.ehtTBTimingRelatedConstants(cfg);
    Nservice = 16; % Number of service bits

    if cfg.ChannelCoding==wlan.type.ChannelCoding.bcc
        Ntail = 6;
    else % 'LDPC'
        Ntail = 0;
    end

    % Rate dependent parameters
    params = wlan.internal.heRateDependentParameters(sum(ruSize),mcs,nss,dcm);
    R = params.Rate;
    NSS = params.NSS;
    NBPSCS = params.NBPSCS;
    NDBPS = params.NDBPS;
    NCBPS = params.NCBPS;
    NSD = params.NSD;

    % Table 36-46 - NSD,SHORT values
    NSDSHORT = wlan.internal.heNSDShort(sum(ruSize),dcm,ehtDUPMode);

    % Initial number of symbol segments in the last OFDM symbol(s)
    % IEEE P802.11be/D2.0, Equation 36-48
    NCBPSSHORT = NSDSHORT*NSS*NBPSCS;
    NDBPSSHORT = NCBPSSHORT*R;

    % If LDPC coding is used and an LDPC extra symbol is used to calculate
    % the initial Pre-FEC padding factor and NSYMinit, which are in turn
    % used to calculate NDBPSLASTinit and NCBPSLASTinit. This is the
    % initial parameters described in Section 36.3.13.3.6.
    if cfg.ChannelCoding == wlan.type.ChannelCoding.ldpc
        % IEEE P802.11be/D2.0, Equation 36-68
        if cfg.LDPCExtraSymbol
            % Wind back one step in the Pre-FEC padding factor
            if ainit==1
                ainit = 4;
                NSYMinit = NSYMinit-1;
            else
                ainit = ainit-1;
                % NSYMinit = NSYMinit; % No change
            end
        else
            % No change:
            % NSYMinit = NSYMinit;
            % ainit = ainit;
        end
    end

    if ainit<4
        NDBPSLASTinit = ainit*NDBPSSHORT; % Equation 36-52
        NCBPSLASTinit = ainit*NCBPSSHORT; % Equation 36-53
    else
        NDBPSLASTinit = NDBPS; % Equation 36-52
        NCBPSLASTinit = NCBPS; % Equation 36-53
    end

    % Now these we can increment the Pre-FEC padding factor again if
    % required and calculate the remaining parameters
    if cfg.ChannelCoding==wlan.type.ChannelCoding.bcc % Section 36.3.13.3.6
        NSYM = NSYMinit;
        a = ainit;
        NDBPSLAST = NDBPSLASTinit; % Number of data bits per symbol in last OFDM symbol. % Equation 36-61
    else % LDPC
        % The equations in this should work out the same
        if cfg.LDPCExtraSymbol
            % Equation 36-58
            if ainit==4
                NSYM = NSYMinit+1;
                a = 1;
            else
                NSYM = NSYMinit;
                a = ainit+1;
            end
        else
            % Equation 36-59
            NSYM = NSYMinit;
            a = ainit;
        end
        NDBPSLAST = NDBPSLASTinit; % Equation 36-61
    end

    % Equation 36-62
    if a<4
        NCBPSLAST = a*NCBPSSHORT;
    else
        NCBPSLAST = NCBPS;
    end

    if cfg.ChannelCoding==wlan.type.ChannelCoding.bcc
        % For BCC use NSYM for data size (same as DL)
        psduLengthBits = ((NSYM-1)*NDBPS+NDBPSLAST-Nservice-Ntail);
    else % 'LDPC'
        % For LDPC use NSYMinit for data size required (same as DL)
        psduLengthBits = ((NSYMinit-1)*NDBPS+NDBPSLASTinit-Nservice-Ntail);
    end

    NPADPreFECPHY = mod(psduLengthBits,8); % Assume we need to pad
    NPADPreFECMAC = 0; % Assume PSDULength will include padded

    % Post FEC Padding
    NPADPostFEC = NCBPS-NCBPSLAST; % Equation 36-65

    % Parameters common to all users
    commonParams = struct;
    commonParams.NSYM = NSYM;
    commonParams.NSYMInit = NSYMinit;
    commonParams.mSTBC = 1; % No STBC in EHT
    commonParams.PreFECPaddingFactor = a;
    commonParams.PreFECPaddingFactorInit = ainit;
    commonParams.LDPCExtraSymbol = cfg.LDPCExtraSymbol;

    if nargout>1
        % Parameters for the user
        userParams = struct;
        userParams.NSYM = NSYM;
        userParams.NSYMInit = NSYMinit; % Use the common MU one as per Equaltion 36-59
        userParams.mSTBC = 1; % No STBC in EHT

        userParams.Rate = R;
        userParams.NBPSCS = NBPSCS;
        userParams.NSD = NSD;
        userParams.NCBPS = NCBPS;
        userParams.NDBPS = NDBPS;
        userParams.NSS = NSS;
        userParams.DCM = dcm;
        userParams.ChannelCoding = cfg.ChannelCoding;

        userParams.NCBPSSHORT = NCBPSSHORT;
        userParams.NDBPSSHORT = NDBPSSHORT;
        userParams.NCBPSLAST = NCBPSLAST;
        userParams.NCBPSLASTInit = NCBPSLASTinit;
        userParams.NDBPSLAST = NDBPSLAST;
        userParams.NDBPSLASTInit = NDBPSLASTinit;
        userParams.NPADPreFECMAC = NPADPreFECMAC;
        userParams.NPADPreFECPHY = NPADPreFECPHY;
        userParams.NPADPostFEC = NPADPostFEC;
        userParams.PreFECPaddingFactor = a;
        userParams.PreFECPaddingFactorInit = ainit;
        userParams.LDPCExtraSymbol = cfg.LDPCExtraSymbol;
        userParams.PSDULength = floor(psduLengthBits/8);
        userParams.EHTDUPMode = ehtDUPMode;
        varargout{1} = userParams;
    end
end

function psduLength = getPSDUlength(in)
    Nservice = 16;
    if in.ChannelCoding==wlan.type.ChannelCoding.bcc % IEEE P802.11be/D1.5, Section 36.4.3, Equation 36-112
        Ntail = 6;
        psduLength = floor(((in.NSYM-1)*in.NDBPS+in.NDBPSLAST-Nservice-Ntail)/8);
    else % Section 36.4.3, Equation 36-113
        psduLength = floor(((in.NSYMInit-1)*in.NDBPS+in.NDBPSLASTInit-Nservice)/8);
    end
end