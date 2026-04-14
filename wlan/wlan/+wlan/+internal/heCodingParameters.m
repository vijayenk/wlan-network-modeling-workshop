function [commonParams,varargout] = heCodingParameters(cfg,varargin)
%heCodingParameters HE coding parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [COMMONPARAMS,USERPARAMS] = heCodingParameters(CFG) returns a structure
%   COMMONPARAMS, containing the coding parameters common to all users, and
%   an array of structures, USERPARAMS, containing the coding parameters
%   for each user, and an array
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   [COMMONPARAMS,USERPARAMS] = heCodingParameters(CFG,RUIDX,USERIDX)
%   returns the user parameters given the specific RU (resource unit)
%   index, RUIDX, and user index, USERIDX.

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

% Form a vector of parameters, were each element is the parameter for a
% user
allocationInfo = ruInfo(cfg);

if isa(cfg,'wlanHESUConfig') || strcmp(packetFormat(cfg),'HE-SU') % Also for HEz support
    numUsers = 1;
    userActive = true;     % Single user always active
    activeUserNumbers = 1; % Single user always active
    ruSize = allocationInfo.RUSizes(1); % To allow for 2 RUs (right 106)
    mcs = cfg.MCS;
    numSTS = cfg.NumSpaceTimeStreams;
    apepLength = cfg.APEPLength;
    channelCoding = {cfg.ChannelCoding};
    dcm = cfg.DCM;
elseif isa(cfg,'wlanHETBConfig')
    if nargout>1
        [commonParams,userParams] = triggerBasedCoding(cfg);
        varargout{1} = userParams;
    else
        commonParams = triggerBasedCoding(cfg);
    end
    return;
else % HE-MU
    numUsers = numel(cfg.User);

    % Get STAID(HE MU) and AID12(HE TB) for all users
    STAID = coder.nullcopy(zeros(1,numUsers));
    if isa(cfg,'wlanHEMUConfig')
        for u = 1:numUsers
            STAID(u) = cfg.User{u}.STAID;
        end
    else
        for u = 1:numUsers
            STAID(u) = cfg.User{u}.AID12; % Mapping AID12 to STAID
        end
    end
    % Determine which user objects are active - the STAID is not 2046
    userActive = true(1,numUsers); % Vector indicating if a user object is active
    for i = 1:numUsers
        if STAID(i)==2046
            % If STAID is 2046, then RU carries no data, and user is not
            % active. Therefore do not take user into account when
            % calculating coding parameters.
            userActive(i) = false;
        end
    end

    % Get a vector of the user object numbers which are active (STAID is
    % not 2046)
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
    channelCoding = repmat({'LDPC'},numUsers,1); % Initialize for codegen
    dcm = false(numUsers,1);

    for userIdx = 1:numUsers
        ruSize(userIdx) = cfg.RU{cfg.User{userIdx}.RUNumber}.Size;
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
        channelCoding{userIdx} = cfg.User{userIdx}.ChannelCoding;
        dcm(userIdx) = cfg.User{userIdx}.DCM;
    end
end

stbc = cfg.STBC;

if stbc % Std 802.11ax-2021, Section 27.4.3, Equation 27-137
    nss = numSTS/2;
    mSTBC = 2;
else
    nss = numSTS;
    mSTBC = 1;
end

Nservice = 16; % Std 802.11ax-2021, Table 27-12

%%
% First calculation: the initial common number of symbols and pre-FEC
% padding factor. Calculate values for all users and take the maximum. Also
% calculate NCBPSSHORT, NDPBSSHORT, and the rate dependent parameters per
% user as part of this.

NSYMinit = zeros(numUsers,1);   % Number of symbols (initial)
ainit = zeros(numUsers,1);      % Pre-FEC padding factor (initial)
NCBPSSHORT = zeros(numUsers,1); % Number of coded bits per symbol (short)
NDBPSSHORT = zeros(numUsers,1); % Number of data bits per symbol (short)
Ntail = zeros(numUsers,1);  % Number of tail bits
R = zeros(numUsers,1);      % Rate
NSS = zeros(numUsers,1);    % Number of spatial streams
NBPSCS = zeros(numUsers,1); % Number of bits per subcarrier
NDBPS = zeros(numUsers,1);  % Number of data bits per symbol
NCBPS = zeros(numUsers,1);  % Number of coded bits per symbols
NSD = zeros(numUsers,1);    % Number of data carrying subcarriers

for u = 1:numUsers
    switch channelCoding{u}
        case 'BCC'
            Ntail(u) = 6;
        case 'LDPC'
            Ntail(u) = 0;
    end

    % Get rate dependent parameters for all users
    params = wlan.internal.heRateDependentParameters(ruSize(u),mcs(u),nss(u),dcm(u));
    R(u) = params.Rate;
    NSS(u) = params.NSS;
    NBPSCS(u) = params.NBPSCS;
    NDBPS(u) = params.NDBPS;
    NCBPS(u) = params.NCBPS;
    NSD(u) = params.NSD;

    % Number of excess bits in last OFDM symbol
    NEXCESS = mod(8*apepLength(u)+Ntail(u)+Nservice,mSTBC*NDBPS(u)); % IEEE Std 802.11ax-2021, Equation 27-61

    % NSD,SHORT values. IEEE Std 802.11ax-2021, Table 27-33
    NSDSHORT = wlan.internal.heNSDShort(ruSize(u),dcm(u));

    % Initial number of symbol segments in the last OFDM symbol(s). IEEE
    % Std 802.11ax-2021, Equation 27-61
    NCBPSSHORT(u) = NSDSHORT*NSS(u)*NBPSCS(u);
    NDBPSSHORT(u) = NCBPSSHORT(u)*R(u);
    if NEXCESS==0
        ainit(u) = 4;
    else
        ainit(u) = min(ceil(NEXCESS/(mSTBC*NDBPSSHORT(u))),4);
    end

    % BCC
    NSYMinit(u) = mSTBC*ceil((8*apepLength(u)+Ntail(u)+Nservice)/(mSTBC*NDBPS(u))); % IEEE Std 802.11ax-2021, Equation 27-66
end

% Derive user index with longest encoded packet duration, IEEE Std 802.11ax-2021, Equation 27-75
% Only user active users
[~,umax] = max(NSYMinit(userActive)-mSTBC+mSTBC.*ainit(userActive)/4);

% Use values from max for all users, % IEEE Std 802.11ax-2021, Equation 27-76
NSYMinitCommon = NSYMinit(activeUserNumbers(umax));
ainitCommon = ainit(activeUserNumbers(umax));

%%
% Now we know the common pre-FEC padding factor and number of symbols,
% update each users number of coded bits in the last symbol

NDBPSLASTinit = zeros(numUsers,1);
NCBPSLASTinit = zeros(numUsers,1);
for u = 1:numUsers
    % Update each user's initial number of coded bits in its last
    % symbol, IEEE P802.11ax/D4.1, Equation 27-77
    if ainitCommon<4
        NDBPSLASTinit(u) = ainitCommon*NDBPSSHORT(u);
        NCBPSLASTinit(u) = ainitCommon*NCBPSSHORT(u);
    else
        NDBPSLASTinit(u) = NDBPS(u);
        NCBPSLASTinit(u) = NCBPS(u);
    end
end

%%
% For each user which uses LDPC calculate the number of pre FEC padding
% bits and if an LDPC extra symbol is required.

NPADPreFEC = zeros(numUsers,1);
ldpcExtraSymbol = false(numUsers,1);
for u = 1:numUsers
    if strcmp(channelCoding{u},'LDPC')
        % IEEE Std 802.11ax-2021, Equation 27-78
        NPADPreFEC(u) = (NSYMinitCommon-mSTBC)*NDBPS(u)+mSTBC*NDBPSLASTinit(u)-8*apepLength(u)-Nservice; 

        % IEEE Std 802.11ax-2021, Equation 27-79, 27-80, 27-81, 27-82
        ldpcParms = wlan.internal.heCommonLDPCParameters(NSYMinitCommon,mSTBC,NDBPS(u),NCBPS(u),NDBPSLASTinit(u),NCBPSLASTinit(u),R(u));
        ldpcExtraSymbol(u) = ldpcParms.LDPCExtraSymbol;
    end
end

%% 
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
            % Part of Std 802.11ax-2021, Equation 27-85
            NDBPSLAST(u) = NDBPSLASTinit(u);
        case 'BCC'
            % Part of Std 802.11ax-2021, Equation 27-85
            if a<4
                NDBPSLAST(u) = a*NDBPSSHORT(u);
            else
                NDBPSLAST(u) = NDBPS(u);
            end

            % IEEE Std 802.11ax-2021, Equation 27-86
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
    mSTBC = 1;
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

if nargout>1
    if nargin>1
        u = varargin{1}; % User of interest

        % Return structure for user of interest
        userParams = struct;
        userParams.NSYM = NSYM;
        userParams.NSYMInit = NSYMinitCommon; % Use the common MU one as per 27-76
        userParams.mSTBC = mSTBC;

        userParams.Rate = R(u);
        userParams.NBPSCS = NBPSCS(u);
        userParams.NSD = NSD(u);
        userParams.NCBPS = NCBPS(u);
        userParams.NDBPS = NDBPS(u);
        userParams.NSS = NSS(u);
        userParams.ChannelCoding = channelCoding{u};

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
        userParams.PSDULength = 0; % For codegen
        userParams.PSDULength = getPSDUlength(userParams);
    else
        % Initialize structure
        p = struct;
        p.NSYM = 0;
        p.NSYMInit = 0; % Use the common MU one as per 27-76
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
        p.PSDULength = 0;
        
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
            userParams(u).NSYMInit = NSYMinitCommon; % Use the common MU one as per 27-76
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
            userParams(u).PSDULength = 0; % For codegen
            userParams(u).PSDULength = getPSDUlength(userParams(u));
        end
    end
    varargout{1} = userParams;
end

end

function [commonParams,varargout] = triggerBasedCoding(cfg)
    % Determine the coding parameters for the trigger-based format as per
    % IEEE Std 802.11ax-2021, Section 27.3.12.5.5.

    dcm = cfg.DCM && any(cfg.MCS==[0 1 3 4]); % DCM only valid with MCS 0, 1, 3 or 4
    if cfg.STBC
        nss = cfg.NumSpaceTimeStreams/2;
    else
        nss = cfg.NumSpaceTimeStreams;
    end
    mcs = cfg.MCS;
    ruSize = cfg.RUSize;
    ainit = cfg.PreFECPaddingFactor;
    channelCoding = cfg.ChannelCoding;

    if strcmp(cfg.TriggerMethod,'TriggerFrame')
        [~,NSYMinit] = wlan.internal.heTBTimingRelatedConstants(cfg);
    else % TRS
        NSYMinit = cfg.NumDataSymbols;
        if strcmp(cfg.ChannelCoding,'BCC')
            % The ainit==a for TriggerMethod, TRS and ChannelCoding BCC.
            % The PreFECPaddingFactor(a) is fixed to 4 for TRS. IEEE
            % Std 802.11ax-2021, Section 27.3.11.5.5.
            ainit = 4;
        else
            % The ainit==a-1 for TriggerMethod, TRS and ChannelCoding LDPC.
            % The PreFECPaddingFactor(a) is fixed to 4 for TRS. IEEE
            % Std 802.11ax-2021, Section 27.3.12.5.5.
            ainit = 3;
        end
    end

    % IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137
    if cfg.STBC
        mSTBC = 2; 
    else
        mSTBC = 1;
    end

    Nservice = 16; % Number of service bits

    if strcmp(channelCoding,'BCC')
        Ntail = 6;
    else % 'LDPC'
        Ntail = 0;
    end

    % Rate dependent parameters
    params = wlan.internal.heRateDependentParameters(ruSize,mcs,nss,dcm);
    R = params.Rate;
    NSS = params.NSS;
    NBPSCS = params.NBPSCS;
    NDBPS = params.NDBPS;
    NCBPS = params.NCBPS;
    NSD = params.NSD;

    % IEEE P802.11ax/D4.1, Table 27-31 - NSD,SHORT values
    NSDSHORT = wlan.internal.heNSDShort(ruSize,dcm);

    % Initial number of symbol segments in the last OFDM symbol(s)
    % Std 802.11ax-2021, Equation 27-60
    NCBPSSHORT = NSDSHORT*NSS*NBPSCS;
    NDBPSSHORT = NCBPSSHORT*R;

    % If LDPC coding is used and an LDPC extra symbol is used to calculate
    % the initial Pre-FEC padding factor and NSYMinit, which are in turn
    % used to calculate NDBPSLASTinit and NCBPSLASTinit. This is the
    % initial parameters described in IEEE Std 802.11ax-2021, Section
    % 27.3.12.5.5. The ainit is fixed for TRS (HE TB), there is no need to
    % wind back, thus, bypassing the following code for TriggerMethod of
    % type TRS.
    if strcmp(channelCoding,'LDPC') && strcmp(cfg.TriggerMethod,'TriggerFrame')
        % IEEE P802.11ax/D4.1, Equation 27-90
        if cfg.LDPCExtraSymbol
            % Wind back one step in the Pre-FEC padding factor
            if ainit==1
                ainit = 4;
                NSYMinit = NSYMinit-mSTBC;
            else
                ainit = ainit-1;
                % No change:
                % NSYMinit = NSYMinit;
            end
        else
            % No change:
            % NSYMinit = NSYMinit;
            % ainit = ainit;
        end
    end

    % IEEE Std 802.11ax-2021, Equation 27-62
    if ainit<4
        NDBPSLASTinit = ainit*NDBPSSHORT;
        NCBPSLASTinit = ainit*NCBPSSHORT;
    else
        NDBPSLASTinit = NDBPS;
        NCBPSLASTinit = NCBPS;
    end

    % Now these we can increment the Pre-FEC padding factor again if
    % required and calculate the remaining parameters
    if strcmp(channelCoding,'BCC')
        % BCC - IEEE Std 802.11ax-2021, Section 27.3.12.5.1
        NSYM = NSYMinit; % HE-SU, IEEE Std 802.11ax-2021, Equation 27-65
        a = ainit; % HE-SU, IEEE Std 802.11ax-2021, Equation 27-67
        NDBPSLAST = NDBPSLASTinit; % Number of data bits per symbol in last OFDM symbol in HE-SU
        % IEEE Std 802.11ax-2021, Section 27.3.12.5.1 - number of coded bits per symbol in last OFDM symbol in HE-SU
        if a<4
            NCBPSLAST = a*NCBPSSHORT;
        else
            NCBPSLAST = NCBPS;
        end
    else % LDPC
        % The equations in this should work out the same
        if cfg.LDPCExtraSymbol
            % IEEE Std 802.11ax-2021, Equation 27-71
            if ainit==4
                NSYM = NSYMinit+mSTBC;
                a = 1;
            else
                NSYM = NSYMinit;
                a = ainit+1;
            end
        else
            % IEEE Std 802.11ax-2021, Equation 27-72
            NSYM = NSYMinit;
            a = ainit;
        end

        % IEEE P802.11ax/D4.1, Equation 27-73
        if a<4
            NCBPSLAST = a*NCBPSSHORT;
        else
            NCBPSLAST = NCBPS;
        end

        NDBPSLAST = NDBPSLASTinit;
    end

    if strcmp(channelCoding,'BCC')
        % For BCC use NSYM for data size (same as DL)
        psduLengthBits = ((NSYM-mSTBC)*NDBPS+mSTBC*NDBPSLAST-Nservice-Ntail);
    else % 'LDPC'
        % For LDPC use NSYMinit for data size required (same as DL)
        psduLengthBits = ((NSYMinit-mSTBC)*NDBPS+mSTBC*NDBPSLASTinit-Nservice-Ntail);
    end

    NPADPreFECPHY = mod(psduLengthBits,8); % Assume we need to pad
    NPADPreFECMAC = 0; % Assume PSDULength will include padded

    % Post FEC Padding
    NPADPostFEC = NCBPS-NCBPSLAST; % IEEE Std 802.11ax-2021, Equation 27-74

    % Parameters common to all users
    commonParams = struct;
    commonParams.NSYM = NSYM;
    commonParams.NSYMInit = NSYMinit;
    commonParams.mSTBC = mSTBC;
    commonParams.PreFECPaddingFactor = a;
    commonParams.PreFECPaddingFactorInit = ainit;
    commonParams.LDPCExtraSymbol = cfg.LDPCExtraSymbol;
    
    if nargout>1
        % Parameters for the user
        userParams = struct;
        userParams.NSYM = NSYM;
        userParams.NSYMInit = NSYMinit; % Use the common MU one as per 27-76
        userParams.mSTBC = mSTBC;

        userParams.Rate = R;
        userParams.NBPSCS = NBPSCS;
        userParams.NSD = NSD;
        userParams.NCBPS = NCBPS;
        userParams.NDBPS = NDBPS;
        userParams.NSS = NSS;
        userParams.DCM = dcm;
        userParams.ChannelCoding = channelCoding;

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
        varargout{1} = userParams;
    end
end

function psduLength = getPSDUlength(in)
    Nservice = 16;
    % IEEE Std 802.11ax-2021, Section 27.4.3
    if strcmp(in.ChannelCoding,'BCC') % IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137, Equation 27-138
        Ntail = 6;
        psduLength = floor(((in.NSYM-in.mSTBC)*in.NDBPS+in.mSTBC*in.NDBPSLAST-Nservice-Ntail)/8);
    else % IEEE Std 802.11ax-2021, Section 27.4.3, Equation 27-137, Equation 27-139
        Ntail = 0;
        psduLength = floor(((in.NSYMInit-in.mSTBC)*in.NDBPS+in.mSTBC*in.NDBPSLASTInit-Nservice-Ntail)/8);
    end
end