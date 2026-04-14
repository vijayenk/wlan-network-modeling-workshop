function refSym = wlanReferenceSymbols(varargin)
%wlanReferenceSymbols Find the reference symbols of constellation diagram
%   REFSYM = wlanReferenceSymbols(MODSCHEME) returns the constellation used
%   for a specified modulation scheme as a column vector of complex
%   symbols.
%
%   MODSCHEME is the modulation scheme and must be one of 'BPSK', 'QBPSK',
%   'pi/2-BPSK', 'QPSK', 'pi/2-QPSK', '16QAM', 'pi/2-16QAM', '64QAM',
%   'pi/2-64QAM', '256QAM', '1024QAM', or '4096QAM'.
%
%   REFSYM = wlanReferenceSymbols(MODSCHEME,PHASE) returns the
%   constellation used for the specified modulation scheme with an
%   additional rotation counter-clockwise.
%
%   PHASE is counter-clockwise rotation to apply in radians. It must be a
%   scalar or row vector, specifying rotation for same modulation scheme.
%
%   REFSYM = wlanReferenceSymbols(CFGSU) returns the constellation used in
%   the data field of a single-user transmission as a column vector of
%   complex symbols.
%
%   CFGSU is the format configuration object of type wlanEHTTBConfig,
%   wlanHESUConfig, wlanHETBConfig, wlanDMGConfig, wlanS1GConfig,
%   wlanVHTConfig, wlanHTConfig, or wlanNonHTConfig, which specifies
%   the properties for the EHT, HE, DMG, S1G, VHT, HT-Mixed or non-HT
%   formats. DSSS format of NonHT format is not supported.
%
%   REFSYM = wlanReferenceSymbols(CFGMU,USERNUMBER) returns the
%   constellation used in the data field of a transmission for an
%   individual user of interest in a multi-user configuration.
%
%   CFGMU is a multi-user configuration object of type wlanHEMUConfig,
%   wlanEHTMUConfig, wlanS1GConfig, or wlanVHTConfig. For S1G and VHT
%   objects, NumUsers property should be greater than one for multi-user
%   configurations.
%
%   USERNUMBER is the user of interest, specified as an integer from 1 to
%   NumUsers, where NumUsers is the number of users in the transmission.
%   For wlanHEMUConfig, USERNUMBER is the user of interest specified from 1
%   to length of User property of wlanHEMUConfig, where User variable gives
%   properties of an individual user of interest. USERNUMBER is not
%   required for wlanHESUConfig and wlanHETBConfig configuration object
%   and is assumed to be one.
%
%   For wlanEHTMUConfig object when EHT MU PPDU type is OFDMA or MU-MIMO
%   non-OFDMA, the additional USERNUMBER argument is required. When EHT MU
%   PPDU type is single user non-OFDMA then the additional RUNUMBER
%   argument is not required and is assumed to be one. USERNUMBER is not 
%   required for wlanEHTTBConfig configuration object and is assumed to be
%   one.
%
%   REFSYM = wlanReferenceSymbols(CFGRX) returns the constellation used in
%   the data field as specified by the HE recovery configuration object.
%
%   CFGRX is format configuration object of type wlanHERecoveryConfig or
%   wlanEHTRecoveryConfig.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,2);

rotation = 0; % Assume no phase rotation
specifiedModScheme = true;
% Validate first input argument
validateattributes(varargin{1},...
    {'char','string','wlanDMGConfig','wlanS1GConfig','wlanVHTConfig','wlanHTConfig','wlanNonHTConfig','wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig','wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{},mfilename,'first argument');

if ischar(varargin{1}) || isstring(varargin{1})
    % REFSYM = wlanReferenceSymbols(MODSCHEME,....)
    modScheme = varargin{1};
    if nargin>1
        % REFSYM = wlanReferenceSymbols(MODSCHEME,PHASE)
        validateattributes(varargin{2},{'double'},{'real','row'},mfilename,'phase rotation'); % validate input
        rotation = varargin{2};
    end

    % Validate modulation scheme
    modScheme = validatestring(modScheme,{'BPSK','QBPSK','pi/2-BPSK','QPSK','pi/2-QPSK','16QAM','pi/2-16QAM','64QAM','pi/2-64QAM','256QAM','1024QAM','4096QAM'},mfilename,'modulation scheme');
else
    % REFSYM = wlanReferenceSymbols(CFGFORMAT,...)
    cfgFormat = varargin{1};

    % DSSS modulation scheme for NonHT format is not supported
    coder.internal.errorIf(isa(cfgFormat,'wlanNonHTConfig') && ~strcmp(cfgFormat.Modulation,'OFDM'),'wlan:wlanReferenceSymbols:InvalidNonHTModulation');

    isHERecoveryConfig = isa(cfgFormat,'wlanHERecoveryConfig');
    isEHTRecoveryConfig = isa(cfgFormat,'wlanEHTRecoveryConfig');
    isRecoveryConfig = isHERecoveryConfig || isEHTRecoveryConfig;
    
    % Validate the properties of wlanHERecoveryConfig and isEHTRecoveryConfig
    if isHERecoveryConfig
        wlan.internal.mustBeDefined(cfgFormat.STBC,'STBC');
        wlan.internal.mustBeDefined(cfgFormat.RUSize,'RUSize');
        wlan.internal.mustBeDefined(cfgFormat.MCS,'MCS');
        wlan.internal.mustBeDefined(cfgFormat.DCM,'DCM');
        wlan.internal.mustBeDefined(cfgFormat.NumSpaceTimeStreams,'NumSpaceTimeStreams');
    elseif isEHTRecoveryConfig
        wlan.internal.mustBeDefined(cfgFormat.RUSize,'RUSize');
        wlan.internal.mustBeDefined(cfgFormat.MCS,'MCS');
        wlan.internal.mustBeDefined(cfgFormat.NumSpaceTimeStreams,'NumSpaceTimeStreams');
    end

    % REFSYM = wlanReferenceSymbols(CFGMU,USERNUMBER)
    if isa(cfgFormat,'wlanHEMUConfig')
        if nargin>1
            userNum = varargin{2};
        else
            coder.internal.error('wlan:shared:ExpectedUserNumber');
        end
        
        % Validate the user number for wlanHEMUConfig
        validateattributes(userNum,{'numeric'},{'integer','scalar','>=',1,'<=',length(cfgFormat.User)},mfilename,'user number');
    elseif isa(cfgFormat,'wlanEHTMUConfig')
        mode = compressionMode(cfgFormat);
        if any(mode==[0 2]) && cfgFormat.UplinkIndication==0
            if nargin<2 % For codegen
                coder.internal.error('wlan:shared:ExpectedUserNumber');
            else
                userNum = varargin{2};
                validateattributes(userNum,{'numeric'},{'integer','scalar','>=',1,'<=',length(cfgFormat.User)},mfilename,'user number');
            end
        else
            userNum = 1;
        end
    elseif (isa(cfgFormat,'wlanVHTConfig')|| isa(cfgFormat,'wlanS1GConfig')) % for wlanVHTConfig or wlanS1GConfig
        if nargin == 2  % MU
            userNum = varargin{2};
            if (cfgFormat.NumUsers == 1)
                coder.internal.error('wlan:wlanReferenceSymbols:SingleUserConfig');
            end
            validateattributes(userNum,{'numeric'},{'integer','scalar','>=',1,'<=',cfgFormat.NumUsers},mfilename,'user number'); % validate user number
        else % SU
            if (cfgFormat.NumUsers>1)
                coder.internal.error('wlan:shared:ExpectedUserNumber'); % for multi-user configuration user number should be provided
            end
            userNum = 1; % single-user configuration 
        end
        
        % Validate the properties of wlanVHTConfig or wlanS1GConfig
        validateConfig(cfgFormat,'MCS');
    else
        % REFSYM = wlanReferenceSymbols(CFGSU) or wlanReferenceSymbols(CFGRX)
        userNum = 1;
    end
    specifiedModScheme = false;
end

% Get the constellation used for the transmission
% Generate bit input for all symbols and constellation map
if specifiedModScheme==false
    if isa(cfgFormat,'wlanHESUConfig') || isa(cfgFormat,'wlanHEMUConfig') || isa(cfgFormat,'wlanHETBConfig') || isa(cfgFormat,'wlanEHTMUConfig') || isa(cfgFormat,'wlanEHTTBConfig') || isRecoveryConfig
        if isRecoveryConfig
           ruSize = cfgFormat.RUSize;
        else
           allocInfo = ruInfo(cfgFormat);
           ruSize = allocInfo.RUSizes;
        end
        if isa(cfgFormat,'wlanHESUConfig') || isa(cfgFormat,'wlanHETBConfig') || isHERecoveryConfig 
            if cfgFormat.STBC
                nss = cfgFormat.NumSpaceTimeStreams/2;
            else
                nss = cfgFormat.NumSpaceTimeStreams;
            end
            mcsTable = wlan.internal.heRateDependentParameters(ruSize,cfgFormat.MCS,nss,cfgFormat.DCM);
        elseif isEHTRecoveryConfig
            nss = cfgFormat.NumSpaceTimeStreams;
            DCM = any(cfgFormat.MCS == [14 15]);
            mcsTable = wlan.internal.heRateDependentParameters(sum(ruSize),cfgFormat.MCS,nss,DCM);
        elseif isa(cfgFormat,'wlanEHTTBConfig')
            nss = cfgFormat.NumSpaceTimeStreams;
            DCM = cfgFormat.MCS == 15;
            mcsTable = wlan.internal.heRateDependentParameters(cfgFormat.RUSize,cfgFormat.MCS,nss,DCM);
        else % MU
            if isa(cfgFormat,'wlanEHTMUConfig')
                nss = cfgFormat.User{userNum}.NumSpaceTimeStreams;
                DCM = any(cfgFormat.User{userNum}.MCS==[14 15]);
            else
                if cfgFormat.STBC
                    nss = cfgFormat.User{userNum}.NumSpaceTimeStreams/2;
                else
                    nss = cfgFormat.User{userNum}.NumSpaceTimeStreams;
                end
                DCM = cfgFormat.User{userNum}.DCM;
            end
            mcsTable = wlan.internal.heRateDependentParameters(cfgFormat.RU{cfgFormat.User{userNum}.RUNumber}.Size,cfgFormat.User{userNum}.MCS,nss,DCM);
        end
        NBPSCS = mcsTable.NBPSCS;
    else
        mcsTable = wlan.internal.getRateTable(cfgFormat);
        if isa(cfgFormat,'wlanDMGConfig')
            switch phyType(cfgFormat)
                case 'Control'
                    % DBPSK
                    NBPSCS = 1;
                case 'OFDM'
                    % As DCM is used for SQPSK and QPSK, the number of bits
                    % per subcarrier is double the value used for coding
                    switch mcsTable.NBPSCS
                        case 1
                            NBPSCS = 2; % SQPSK
                        case 2
                            NBPSCS = 4; % QPSK (DCM)
                        otherwise
                            NBPSCS = mcsTable.NBPSCS;
                    end
                otherwise % SC
                    NBPSCS = mcsTable.NCBPS;
            end
        else
            NBPSCS = mcsTable.NBPSCS(userNum);
        end
    end
else
    switch modScheme
        case {'BPSK','QBPSK','pi/2-BPSK'}
            NBPSCS = 1;
        case {'QPSK','pi/2-QPSK'}
            NBPSCS = 2;
        case {'16QAM','pi/2-16QAM'}
            NBPSCS = 4;
        case {'64QAM','pi/2-64QAM'}
            NBPSCS = 6;
        case {'256QAM'}
            NBPSCS = 8;
        case {'1024QAM'}
            NBPSCS = 10;
        otherwise % 4096QAM
            NBPSCS = 12;
    end
end
x = reshape(int2bit((0:((2^NBPSCS)-1)),NBPSCS),NBPSCS*2^NBPSCS,1);

if (specifiedModScheme==true) && (strcmp(modScheme,'QBPSK')) % QBPSK
    const = wlanConstellationMap(x,NBPSCS,pi/2+rotation);
elseif ((specifiedModScheme==true) && (strcmp(modScheme,'pi/2-BPSK')))||...
        (specifiedModScheme==false && isa(cfgFormat,'wlanDMGConfig') && strcmp(phyType(cfgFormat),'SC') && NBPSCS==1)
    pnts = wlanConstellationMap(x,NBPSCS,[0 pi/2]); % pi/2-BPSK has four reference points in constellation
    const = pnts(:) .* exp(1i*rotation);
elseif (specifiedModScheme==true) && (strcmp(modScheme,'pi/2-QPSK')) % pi/2-QPSK
    const = wlanConstellationMap(x,NBPSCS,-pi/4+rotation);
elseif specifiedModScheme==false && isa(cfgFormat,'wlanDMGConfig') && strcmp(phyType(cfgFormat),'SC') && NBPSCS==2
    % DMG SC pi/2-QPSK
    const = wlanConstellationMap(x,NBPSCS,-pi/4);
else
    const = wlanConstellationMap(x,NBPSCS,rotation);
end
% Return reference constellation
refSym = const;

end

