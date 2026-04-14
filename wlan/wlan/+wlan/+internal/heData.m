function y = heData(txPSDU,cfg,varargin)
%heData HE Data field carrying the PSDU(s)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heData(PSDU,CFGHE) generates the HE Data field carrying the PSDU(s)
%   time-domain signal for the HE transmission format.
%
%   Y is the time-domain HE Data field signal. It is a complex matrix of
%   size Ns-by-Nt, where Ns represents the number of time-domain samples
%   and Nt represents the number of transmit antennas.
%
%   PSDU is the PHY service data unit input to the PHY. For single-user,
%   PSDU can be a double or int8 typed binary column vector of length
%   cfgHE.getPSDULength*8. Alternatively, PSDU can be a row cell array with
%   length equal to number of users. The ith element in the cell array must
%   be a double or int8 typed binary column vector of length
%   cfgHE.getPSDULength(i)*8.
%
%   CFGHE is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, or <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>.
%
%   Y = heData(...,SCRAMINIT) optionally allows specification of the
%   scrambler initialization. When not specified, it defaults to a value of
%   93. When specified, it can be a double or int8-typed integer scalar or
%   1-by-Nu row vector between 1 and 127, inclusive, where Nu represents
%   the number of users. Alternatively, SCRAMINIT can be a double or
%   int8-typed binary 7-by-1 column vector or 7-by-Nu matrix, without any
%   all-zero column. If it is a scalar or column vector, it applies to all
%   users. Otherwise, each user can have its own scrambler initialization
%   as indicated by the corresponding column.
%
%   Y = heData(CFGHE,SCRAMINIT,OSF) generates the HE-Data for the given
%   oversampling factor OSF. When not specified 1 is assumed.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
osf = 1;
allocationInfo = ruInfo(cfg);

if isa(cfg,'wlanHEMUConfig')
    numUsers = allocationInfo.NumUsers;
else
    numUsers = 1; % For single user/trigger force codegen to 1 user
end
numRUs = allocationInfo.NumRUs;
ruIndices = allocationInfo.RUIndices;
ruSizes = allocationInfo.RUSizes;
alpha = allocationInfo.PowerBoostFactorPerRU;
numSTSTotalRU = allocationInfo.NumSpaceTimeStreamsPerRU;

if nargin == 2
    % As per IEEE Std 802.11-2012, Section L.1.5.2.
    scramInitBits = uint8(repmat([1; 0; 1; 1; 1; 0; 1], 1, numUsers)); % Default is 93
else
    scramInit = varargin{1};
    % Validate scrambler initialization input
    scramInitBits = wlan.internal.validateVHTScramblerInit(scramInit,numUsers,mfilename);
    
    if nargin == 4
       osf = varargin{2}; 
    end
end
[commonCodingParams,userCodingParams] = wlan.internal.heCodingParameters(cfg);

numTx = cfg.NumTransmitAntennas;

tac = wlan.internal.heRUToneAllocationConstants(ruSizes);
cardKr = tac.NST;

Nfft = 256*cbw/20;
ofdmGrid = complex(zeros(Nfft,commonCodingParams.NSYM,numTx));

if isa(cfg,'wlanHEMUConfig')
    % HE MU PPDU
    numHESIGA = 2;
    sigbInfo = wlan.internal.heSIGBCodingInfo(cfg);
    z = 2+numHESIGA+sigbInfo.NumSymbols; % Pilot symbol offset

    if ~iscell(txPSDU)
        txPSDUCell = {txPSDU};
    else
        txPSDUCell = txPSDU;
    end

    % Frequency and spatial mapping
    for j = 1:numRUs
        if ~allocationInfo.RUAssigned(j)
            continue
        end
        % Get the index of the RU object containing the active RU properties
        iru = allocationInfo.RUNumbers(j);

        % Get current RU assignment details
        ru = cfg.RU{iru};
        numSTSTotal = allocationInfo.NumSpaceTimeStreamsPerRU(j);
        numUsers = allocationInfo.NumUsersPerRU(j);

        ruGrid = coder.nullcopy(complex(zeros(tac.NST(j),commonCodingParams.NSYM,numSTSTotal)));

        % Get indices of data and pilots within RU (without Nulls) and active frequency indices.
        [ruMappingInd,k] = wlan.internal.heOccupiedSubcarrierIndices(cbw,ru.Size,ru.Index);

        % Encode, modulate, and map each user within the RU to space-time streams
        startSpaceTimeStream = 1;
        for i = 1:numUsers
            u = ru.UserNumbers(i);
            user = cfg.User{u};

            if user.APEPLength~=0
                if ~strcmp(user.PostFECPaddingSource,'User-defined')
                    % Generate post-FEC padding bits
                    postFECPaddingBits = randomPostFECPadding(userCodingParams(u).NPADPostFEC,userCodingParams(u).mSTBC,user.PostFECPaddingSource,user.PostFECPaddingSeed);
                else
                    % Repeat/cut/reshape user input bits
                    postFECPaddingBits = reshape(...
                      wlan.internal.parseInputBits(int8(user.PostFECPaddingBits),userCodingParams(u).NPADPostFEC*userCodingParams(u).mSTBC), ...
                      userCodingParams(u).NPADPostFEC,userCodingParams(u).mSTBC);
                end
                
                % Generate STS for the user
                stsPerUser = wlan.internal.heSTSPerUser(txPSDUCell{u},scramInitBits(:,u),postFECPaddingBits,ru.Size,userCodingParams(u));

                % Determine the indices of space-time streams to map
                stsIdx = startSpaceTimeStream-1+(1:user.NumSpaceTimeStreams);
                % Map user data and pilots
                ruGrid(ruMappingInd.Data,:,stsIdx) = stsPerUser;
                n = 0:commonCodingParams.NSYM-1;
                ruGrid(ruMappingInd.Pilot,:,stsIdx) = wlan.internal.hePilots(ru.Size,user.NumSpaceTimeStreams,n,z);
            end
            startSpaceTimeStream = startSpaceTimeStream+user.NumSpaceTimeStreams;
        end

        % Cyclic shift
        ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,k);

        % Spatial mapping
        txRUGrid = wlan.internal.spatialMap(ruGrid,ru.SpatialMapping,numTx,ru.SpatialMappingMatrix);
       
        % Calculate per RU scaling
        ruScalingFactor = alpha(j)/sqrt(numSTSTotalRU(j));

        % Map subcarriers to full FFT grid and scale
        ofdmGrid(k+Nfft/2+1,:,:) = txRUGrid*ruScalingFactor;
    end

    % Overall scaling factor
    allScalingFactor = Nfft/sqrt(sum(alpha(allocationInfo.RUAssigned).^2.*cardKr(allocationInfo.RUAssigned)));
else
    % HE SU, HE EXT SU, or HE TB PPDU
    if isa(cfg,'wlanHESUConfig')
        startSpaceTimeStream = 1;
    else % 'wlanHETBConfig'
        startSpaceTimeStream = cfg.StartingSpaceTimeStream;
    end

    if strcmp(packetFormat(cfg),'HE-EXT-SU')
        numHESIGA = 4;
    else % 'HE-SU', 'HE-TB'
        numHESIGA = 2;
    end
    numHESIGB = 0;
    z = 2+numHESIGA+numHESIGB; % Pilot symbol offset

    if iscell(txPSDU)
        txPSDUMat = txPSDU{1};
    else
        txPSDUMat = txPSDU;
    end
    
    if ~strcmp(cfg.PostFECPaddingSource,'User-defined')
        % Generate post-FEC padding bits
        postFECPaddingBits = randomPostFECPadding(userCodingParams.NPADPostFEC,userCodingParams.mSTBC,cfg.PostFECPaddingSource,cfg.PostFECPaddingSeed);
    else
        % Repeat/cut/reshape user input bits
        postFECPaddingBits = reshape(...
          wlan.internal.parseInputBits(int8(cfg.PostFECPaddingBits),userCodingParams.NPADPostFEC*userCodingParams.mSTBC), ...
          userCodingParams.NPADPostFEC,userCodingParams.mSTBC);
    end

    % Generate per-space-time stream symbols for user
    stsPerUser = wlan.internal.heSTSPerUser(txPSDUMat,scramInitBits,postFECPaddingBits,ruSizes,userCodingParams);

    % Map user data and pilots
    % Get indices of data and pilots within RU (without Nulls) and active frequency indices
    [ruMappingInd,k] = wlan.internal.heOccupiedSubcarrierIndices(cbw,ruSizes,ruIndices);
    ruGrid = coder.nullcopy(complex(zeros(cardKr,commonCodingParams.NSYM,cfg.NumSpaceTimeStreams)));
    ruGrid(ruMappingInd.Data,:,:) = stsPerUser(:,:,1:cfg.NumSpaceTimeStreams);
    n = 0:commonCodingParams.NSYM-1;
    ruGrid(ruMappingInd.Pilot,:,:) = wlan.internal.hePilots(ruSizes,cfg.NumSpaceTimeStreams,n,z);

    % Cyclic shift
    stsIdx = startSpaceTimeStream-1+(1:cfg.NumSpaceTimeStreams).'; 
    ruGrid = wlan.internal.heCyclicShift(ruGrid,cbw,k,stsIdx);

    % Spatial mapping
    Q = wlan.internal.heExtractRUFromSpatialMappingMatrix(cfg);
    txGrid = wlan.internal.spatialMap(ruGrid,cfg.SpatialMapping,numTx,Q);

    % Calculate per RU scaling
    ruScalingFactor = 1/sqrt(numSTSTotalRU);

    % Map subcarriers to full FFT grid and scale
    ofdmGrid(k+Nfft/2+1,:,:) = txGrid*ruScalingFactor;

    % Overall scaling factor
    allScalingFactor = Nfft/sqrt(cardKr);
end

% OFDM modulate and scale
switch cfg.GuardInterval
    case 0.8
        cpLen = 0.8*cbw;
    case 1.6
        cpLen = 1.6*cbw;
    otherwise % 3.2
        cpLen = 3.2*cbw;
end
y = wlan.internal.ofdmModulate(ofdmGrid,cpLen,osf)*allScalingFactor;
end

function postFECPPadBits = randomPostFECPadding(NPADPostFEC,mSTBC,randomStream,seed)
    persistent stream

    if strcmp(randomStream,'mt19937ar with seed')
        if isempty(stream)
            if coder.target('MATLAB')
                stream = RandStream('mt19937ar');
            else
                stream = coder.internal.RandStream('mt19937ar');
            end
        end
        % Use same seed when generating each packet
        reset(stream,seed);
        postFECPPadBits = randi(stream,[0 1],NPADPostFEC,mSTBC,'int8');
    else
        % Use global stream
        postFECPPadBits = randi([0 1],NPADPostFEC,mSTBC,'int8');
    end
end
