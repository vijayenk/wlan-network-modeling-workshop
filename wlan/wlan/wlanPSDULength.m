function psduLength = wlanPSDULength(cfgPHY, unit, value, varargin)
%wlanPSDULength PSDU length calculation
%   PSDULENGTH = wlanPSDULength(CFGPHY, UNIT, VALUE) calculates the PSDU
%   length in octets from the given VALUE and physical layer configuration
%   CFGPHY. The VALUE can be in terms of PPDU transmission time or number
%   of data symbols, indicated by the UNIT argument.
%
%   PSDULENGTH is the length of the PSDU in octets, returned as a scalar
%   number. This is the maximum PSDU length that fits into the specified
%   value of PPDU transmission time or number of data symbols.
%
%   CFGPHY is an object of type wlanNonHTConfig, wlanHTConfig, 
%   wlanVHTConfig, wlanHESUConfig, or wlanEHTMUConfig. When CFGPHY 
%   is an object of type wlanEHTMUConfig, the object must specify the 
%   configuration for a single user transmission.
%
%   UNIT indicates the units of the argument VALUE from which the PSDU
%   length is calculated, specified as one of 'TxTime' or 'NumDataSymbols'.
%
%   VALUE is the value from which the PSDU length is calculated. 
%       - If UNIT is set to 'TxTime', VALUE is a scalar number specifying
%         PPDU transmission time in microseconds.
%       - If UNIT is set to 'NumDataSymbols', VALUE is a scalar number
%         specifying the number of data symbols (i.e. the number of symbols
%         in the 'Data' field of the PPDU).

%   Copyright 2019-2024 The MathWorks, Inc.

%#codegen

suppressWarns = false;
disableValidation = false;
if ~isempty(varargin) && strcmp(varargin{1}, 'SuppressWarnings')
    % Options to suppress warnings and disable validation only for network simulation
    suppressWarns = varargin{2};
    disableValidation = varargin{4};
else
    narginchk(3, 3);
end

if ~disableValidation
    % Validate inputs
    validateattributes(cfgPHY, {'wlanNonHTConfig', 'wlanHTConfig', 'wlanVHTConfig', 'wlanHESUConfig', 'wlanEHTMUConfig'}, {'scalar'}, mfilename, 'format configuration object')
    unit = validatestring(unit, {'TxTime', 'NumDataSymbols'}, mfilename, 'UNIT');
    if (isa(cfgPHY, 'wlanHESUConfig') || isa(cfgPHY, 'wlanEHTMUConfig')) && (cfgPHY.GuardInterval ~= 3.2)
        % Accept floating point numbers also
        validateattributes(value, {'numeric'}, {'scalar', 'real', 'nonnegative'}, '', 'argument-3');
        value = double(round2FiveDecimals(value));
    else
        validateattributes(value, {'numeric'}, {'scalar', 'integer', 'nonnegative'}, '', 'argument-3');
        value = double(value);
    end
else
    value = double(round2FiveDecimals(value));
end

% Minimum data length for validating non-NDP configuration
dataLengthForValidation = 1;
% Maximum TxTime limit check
if strcmp(unit, 'TxTime')
    txTimeLimit = 5484; % in microseconds
    txTime = value;
    coder.internal.errorIf((txTime > txTimeLimit), 'wlan:wlanPSDULength:ExceedsMaxTxTime');
else % NumDataSymbols
    if (value == 0)
        % If number of data symbols is zero, set data length to zero for NDP
        % validation
        dataLengthForValidation = 0;
    end
end

switch class(cfgPHY)
    case 'wlanNonHTConfig'
        if strcmp(cfgPHY.Modulation, 'DSSS')
            if strcmp(unit, 'TxTime')
                % PPDU TxTime
                txTime = value;
            else
                % Number of data symbols is not applicable for DSSS
                % modulation
                coder.internal.error('wlan:wlanPSDULength:DSSSNumDataSymNotSupported');
            end
            
            psduLength = dsssPSDULength(cfgPHY, txTime, suppressWarns);
            
        else % OFDM
            % Get rate table
            mcsTable = wlan.internal.getRateTable(cfgPHY);
            
            % Preamble overhead (16 us) + SIGNAL field overhead (4 us).
            % Refer section 17.3.3, figure 17.4 in IEEE Std 802.11-2016
            phyOverhead = 20*bwScalar(cfgPHY.ChannelBandwidth);
            
            % Calculate PSDU length
            psduLength = calculatePSDULength(cfgPHY, mcsTable, unit, value, phyOverhead, suppressWarns);
        end
        
    case 'wlanHTConfig'
        % Validate the PHY config object
        cfgPHY.PSDULength = dataLengthForValidation; % Ignore length for validation by setting minimum length (0 or 1)
        if ~disableValidation
            validateConfig(cfgPHY, 'MCS');
        end

        % Get MCS table
        mcsTable = wlan.internal.getRateTable(cfgPHY);
        
        % PHY overhead for zero data
        cfgPHY.PSDULength = 0;
        phyOverhead = cfgPHY.transmitTime("microseconds");
        
        % Calculate PSDU length in octets
        psduLength = calculatePSDULength(cfgPHY, mcsTable, unit, value, phyOverhead, suppressWarns);
        
        % Warn for output length exceeding standard limit. Refer Table 9-19
        % of IEEE Std 802.11-2016.
        maxLimit = 65535;
        if psduLength > maxLimit
            optionalWarn(suppressWarns, 'wlan:wlanPSDULength:HTMaxLimitExceeded');
        end
        
    case 'wlanVHTConfig'
        % VHT MU configuration is not supported
        coder.internal.errorIf((cfgPHY.NumUsers > 1), 'wlan:wlanPSDULength:VHTMUNotSupported');
        
        % Validate the PHY config object
        cfgPHY.APEPLength = dataLengthForValidation; % Ignore length for validation by setting minimum length (0 or 1)
        if ~disableValidation
            validateConfig(cfgPHY, 'MCS');
        end
        
        % Get MCS table
        mcsTable = wlan.internal.getRateTable(cfgPHY);
        
        % PHY overhead for zero data
        cfgPHY.APEPLength = 0;
        phyOverhead = cfgPHY.transmitTime("microseconds");

        % Calculate PSDU length in octets
        psduLength = calculatePSDULength(cfgPHY, mcsTable, unit, value, phyOverhead, suppressWarns);
        
        % Warn for output length exceeding standard limit. Refer Table 9-19
        % of IEEE Std 802.11-2016.
        maxLimit = 1048575;
        if psduLength > maxLimit
            optionalWarn(suppressWarns, 'wlan:wlanPSDULength:VHTMaxLimitExceeded');
        end
        
    case 'wlanHESUConfig' % wlanHESUConfig
        % Midambles are not supported
        coder.internal.errorIf(cfgPHY.HighDoppler, 'wlan:wlanPSDULength:MidamblesNotSupported');
        
        % Validate the PHY config object
        cfgPHY.APEPLength = dataLengthForValidation; % Ignore length for validation by setting minimum length (0 or 1)
        if ~disableValidation
            validateConfig(cfgPHY, 'DataLocationLength');
        end
        
        % Get coding parameters
        [~, userCodingParams] = wlan.internal.heCodingParameters(cfgPHY);

        % PHY overhead in microseconds
        cfgPHY.APEPLength = 0;
        phyOverhead = cfgPHY.transmitTime("microseconds");
        ndpOverhead = ndpOverheadTime(cfgPHY); % check any NDP overhead
        phyOverhead = phyOverhead - ndpOverhead; % PHY overhead in microseconds (for non-zero PSDU)
                
        % Calculate PSDU length in octets
        psduLength = calculatePSDULength(cfgPHY, userCodingParams, unit, value, phyOverhead, suppressWarns);

    otherwise % wlanEHTMUConfig
        % EHT MU configuration is not supported
        coder.internal.errorIf((numel(cfgPHY.User) > 1), 'wlan:wlanPSDULength:EHTMUNotSupported');

        % Validate the PHY config object
        cfgPHY.User{1}.APEPLength = dataLengthForValidation; % Ignore length for validation by setting minimum length (0 or 1)
        if ~disableValidation
            validateConfig(cfgPHY, 'DataLocationLength');
        end

        % Get coding parameters
        [~, userCodingParams] = wlan.internal.ehtCodingParameters(cfgPHY);
        userCodingParams = userCodingParams(1); % Extract single user configuration - for codegen

        % PHY overhead in microseconds
        cfgPHY.User{1}.APEPLength = 0;
        phyOverhead = cfgPHY.transmitTime("microseconds");
        ndpOverhead = ndpOverheadTime(cfgPHY); % check any NDP overhead
        ehtSIGOverheadNonNDP = 4; % EHT SIG overhead for non-NDP
        
        % PHY overhead for Non-NDP
        phyOverhead = phyOverhead - ndpOverhead + ehtSIGOverheadNonNDP;

        % Calculate PSDU length in octets
        psduLength = calculatePSDULength(cfgPHY, userCodingParams, unit, value, phyOverhead, suppressWarns);
end

end

% Common PSDU length calculation for all PHY formats
function psduLength = calculatePSDULength(cfgPHY, mcsTable, unit, value, phyOverhead, suppressWarns)
    txTimeLimit = 5484; % PPDU transmission time-limit. IEEE Std 802.11-2016, Table 9-19.
    serviceBits = 16;  % IEEE Std 802.11-2016 Sections 17.3.5.2, 19.3.11.2, and Table 21.5. IEEE Std 802.11ax-2021, Table 27-12.
    tailBits = 6;
    numDBPS = mcsTable.NDBPS(1); % for codegen
    [symbolTime, longSymbolTime, symbolBoundaryMultiple] = getSymbolTime(cfgPHY);
    if isLDPCCoded(cfgPHY)
        % No tail bits for LDPC coding
        % IEEE Std 802.11-2016, Sections 19.3.11.1 and 21.3.10.1.
        % IEEE Std 802.11ax-2021, Section 27.3.12.1.
        % IEEE Std 802.11be Draft 4.0, Table 36-18.
        tailBits = 0;
    end
    % Number of encoding streams
    if isa(cfgPHY, 'wlanHESUConfig') || isa(cfgPHY, 'wlanEHTMUConfig')
        numES = 1;
    else
        numES = mcsTable.NES;
    end
    isNonHT = isa(cfgPHY, 'wlanNonHTConfig');
    
    % STBC
    mSTBC = mcsTable.mSTBC;
    mSTBC = mSTBC(1); % for codegen
    dataTxTime = 0; % init for codegen

    % Calculate number of data symbols
    if strcmp(unit, 'TxTime')
        % PPDU TxTime
        txTime = value;

        % NDP overhead
        ndpOverhead = ndpOverheadTime(cfgPHY);
        if ~isNonHT
            % Check if overhead is equal to given transmission time
            if (txTime == (phyOverhead + ndpOverhead))
                psduLength = 0;
                return;
            end
        end
        
        % Calculate data transmission time
        dataTxTime = txTime - phyOverhead;

        % Calculate number of data symbols
        if ((isa(cfgPHY, 'wlanHESUConfig') || isa(cfgPHY, 'wlanEHTMUConfig')) && (cfgPHY.GuardInterval ~= 3.2)) || ...
                ((isa(cfgPHY, 'wlanHTConfig') || isa(cfgPHY, 'wlanVHTConfig')) && strcmp(cfgPHY.GuardInterval, 'Short'))
            
            if isa(cfgPHY, 'wlanHESUConfig') || isa(cfgPHY, 'wlanEHTMUConfig') % HE/EHT short guard-intervals
                numDataSymbols = ceil(round2FiveDecimals(dataTxTime/symbolTime));
            else % HT | VHT with 'short' guard-interval
                % From Eq 19-90 and Eq 21-109, data field TxTime is always
                % a multiple of long symbol time (4 us). So first calculate
                % the number of long data symbols that fit into the data
                % field TxTime and then find the number of short data
                % symbols that fit into the time taken by long symbols.
                numLongDataSymbols = ceil(dataTxTime/longSymbolTime);
                numDataSymbols = floor(numLongDataSymbols*longSymbolTime/symbolTime);
            end
            
        else % Long guard intervals
            numDataSymbols = ceil(round2FiveDecimals(dataTxTime/symbolTime));
        end

        % For STBC an even number of data symbols must be used
        numDataSymbols = mSTBC*ceil(numDataSymbols/mSTBC);
        
        % Check for minimum TxTime (preamble, header, 1 byte PSDU, service and tail bits)
        minPSDUBits = 8;
        minTxTime = phyOverhead + (ceil((serviceBits + tailBits + minPSDUBits)/numDBPS)*symbolBoundaryMultiple);
        if isNonHT
            % Non-HT format requires at least 1 data symbol. NDP is not defined for Non-HT format.
            coder.internal.errorIf((txTime < minTxTime), 'wlan:wlanPSDULength:NonHTLessThanMinTxTime', sprintf('%g', minTxTime));
        else % HT/VHT/HE formats
            if (txTime == (phyOverhead+ndpOverhead)) % No 'Data' field, i.e. NDP
                % When there is no data field, service bits and tail bits
                % are not present.
                serviceBits = 0;
                tailBits = 0;
            else % Non-zero data field
                % Check for minimum required TxTime with service bits and tail
                % bits included
                coder.internal.errorIf((txTime < minTxTime), 'wlan:wlanPSDULength:LessThanMinTxTime', sprintf('%g', phyOverhead+ndpOverhead), sprintf('%g', minTxTime));
            end
        end
        
    else % NumDataSymbols
        numDataSymbols = value;

        % For STBC an even number of data symbols must be used
        numDataSymbols = mSTBC*ceil(numDataSymbols/mSTBC);

        % Check for minimum number of data symbols
        minPSDUBits = 8;
        if (isNonHT || (numDataSymbols > 0)) && (numDBPS*numDataSymbols < (serviceBits + tailBits + minPSDUBits))
            coder.internal.error('wlan:wlanPSDULength:LessThanMinNumDataSymbol', ceil((serviceBits + tailBits + minPSDUBits)/numDBPS));
        end
        
        if (numDataSymbols == 0)  % No 'Data' field, i.e. NDP
            % When there is no data field, service bits and tail bits
            % are not present
            serviceBits = 0;
            tailBits = 0;
        end
        
        % Calculate total PPDU transmission time
        switch class(cfgPHY)
            case 'wlanNonHTConfig'
                signalExtension = 0; % Not supported
                packetExtension = 0; % Not supported
                midambleOverhead = 0; % Not supported
                txTime = phyOverhead + numDataSymbols*symbolTime + midambleOverhead + packetExtension + signalExtension; 
            case 'wlanHTConfig'
                txTime = htTxTime(cfgPHY, 'NumDataSymbols', numDataSymbols);    
            case 'wlanVHTConfig'
                txTime = vhtTxTime(cfgPHY, 'NumDataSymbols', numDataSymbols);
            case {'wlanHESUConfig', 'wlanEHTMUConfig'}
		        txTime = phyOverhead + numDataSymbols*longSymbolTime;
        end
    end
        
    if strcmp(unit, 'TxTime') && hasNominalPacketPadding(cfgPHY)
        % Handle packet extension for HE format
        [psduLength, corrTxTime] = handlePacketExtension(cfgPHY, mcsTable, txTime, numDataSymbols);

    elseif  ~isNonHT && ((mSTBC == 2) || isLDPCCoded(cfgPHY))
        [psduLength, corrTxTime, numDataSymbols] = handleExtraSymbols(cfgPHY, unit, txTime, numDataSymbols, mcsTable, tailBits, numES);

    else % No extra symbols are expected
        % Calculate number of data bits
        numDataBits = numDataSymbols*numDBPS;
        
        % Calculate PSDU length in octets
        psduLength = floor((numDataBits - serviceBits - tailBits*numES)/8);
        
        if strcmp(unit, 'TxTime')
            corrTxTime = txTime + (abs(mod(dataTxTime, -symbolBoundaryMultiple)));
            if corrTxTime > 5484
                % If the next possible higher value exceeds max TxTime limit, choose the
                % next lower value that does not exceed the TxTime limit.
                numDataBits = (numDataSymbols-1)*numDBPS;
                psduLength = floor((numDataBits - serviceBits - tailBits*numES)/8);
                corrTxTime = txTime - (abs(mod(dataTxTime, symbolBoundaryMultiple)));
            end
        else
            corrTxTime = txTime;
        end
        corrTxTime = round2FiveDecimals(corrTxTime); % Round to five digits after decimal point
    end
    
    % Warn if given value is not achievable
    if strcmp(unit, 'TxTime')
        % Symbol boundary warning for TxTime to PSDU length calculation
        if (corrTxTime ~= txTime)
            optionalWarn(suppressWarns, 'wlan:wlanPSDULength:TxTimeRoundedToNextBoundary', sprintf('%g', corrTxTime));
        end
        
    else % NumDataSymbols
        % Maximum TxTime limit check
        coder.internal.errorIf((corrTxTime > txTimeLimit), 'wlan:wlanPSDULength:NumSymExceedsTxTimeLimit', sprintf('%g', corrTxTime));
        
        if numDataSymbols ~= value
            optionalWarn(suppressWarns, 'wlan:wlanPSDULength:NSYMRoundedToNextSymbol', numDataSymbols);
        end
    end
end

% Calculate PSDU length for Non-HT DSSS modulation
function psduLength = dsssPSDULength(cfgPHY, txTime, suppressWarns)
    txTimeLimit = 5484;

    % Short preamble is not applicable for '1 Mbps' datarate. Refer section
    % 16.2.2.3 of IEEE Std 802.11-2016
    if ~strcmp(cfgPHY.DataRate, '1Mbps') && strcmp(cfgPHY.Preamble, 'Short')
        % Preamble overhead (72 us) + PHY header overhead (24 us). Refer
        % section 16.3.4 of IEEE Std 802.11-2016
        phyOverhead = 96;

    else % Long preamble
        % Preamble overhead (144 us) + PHY header overhead (48 us). Refer
        % section 16.3.4 of IEEE Std 802.11-2016
        phyOverhead = 192;
    end

    % Minimum TxTime check (preamble, header, service and tail bits)
    minTxTime = phyOverhead;
    coder.internal.errorIf((txTime <= minTxTime), 'wlan:wlanPSDULength:NonHTLessThanMinTxTime', sprintf('%g', minTxTime+1));

    % Calculate transmission time for 'Data' field
    dataTxTime = txTime - phyOverhead;

    switch(cfgPHY.DataRate)
        case '1Mbps'
            datarate = 1;
        case '2Mbps'
            datarate = 2;
        case '5.5Mbps'
            datarate = 5.5;
        otherwise % 11Mbps
            datarate = 11;
    end

    % Inverse of IEEE Eq in 802.11-2016 16.3.4. To remove ceil
    % when inverting substitute ceil(LENGTH*8/RATE) for ALPHA+BETA,
    % where ALPHA is an integer and BETA is [0 1). Therefore:
    % LENGTH+THETA = (TXTIME-OVERHEAD)*RATE/8, where THETA is [0
    % RATE/8)
    lengthPlusTheta = dataTxTime*datarate/8;
    lengthPlusThetaFloor = floor(lengthPlusTheta);
    psduLength = lengthPlusThetaFloor;
    
    % If theta is out of the required range then increment the psduLen
    theta = lengthPlusTheta - lengthPlusThetaFloor;
    if theta >= (datarate/8)
        psduLength = psduLength+1;
    end
    % The corresponding time should not be shorter than requested
    corrTxTime = dsssTxTime(cfgPHY, psduLength);
    assert(corrTxTime>=txTime);
    if (txTime ~= corrTxTime)
        if corrTxTime <= txTimeLimit
            optionalWarn(suppressWarns, 'wlan:wlanPSDULength:TxTimeRoundedToNextBoundary', sprintf('%g', corrTxTime));
        else
            % Find the nearest PSDU length that doesn't exceed maximum transmission time
            while corrTxTime > txTimeLimit
                psduLength = psduLength-1;
                corrTxTime = dsssTxTime(cfgPHY, psduLength);
            end
            if corrTxTime ~= txTime
                optionalWarn(suppressWarns, 'wlan:wlanPSDULength:TxTimeRoundedToNextBoundary', sprintf('%g', corrTxTime));
            end
        end
    end
end

% Calculate TxTime for Non-HT DSSS modulation
function txTime = dsssTxTime(cfgPHY, length)
    % Short preamble is not applicable for '1 Mbps' datarate. Refer section
    % 16.2.2.3 of IEEE Std 802.11-2016
    if ~strcmp(cfgPHY.DataRate, '1Mbps') && strcmp(cfgPHY.Preamble, 'Short')
        % Preamble overhead (72 us) + PHY header overhead (24 us). Refer
        % section 16.3.4 of IEEE Std 802.11-2016
        phyOverhead = 96;
        
    else % Long Preamble
        % Preamble overhead (144 us) + PHY header overhead (48 us). Refer
        % section 16.3.4 of IEEE Std 802.11-2016
        phyOverhead = 192;
    end

    switch(cfgPHY.DataRate)
        case '1Mbps'
            datarate = 1;
        case '2Mbps'
            datarate = 2;
        case '5.5Mbps'
            datarate = 5.5;
        otherwise % 11Mbps
            datarate = 11;
    end

    % Refer section 16.3.4 of IEEE Std 802.11-2016
    txTime = phyOverhead + ceil(length*8/datarate);
end

% Calculate HT format parameters
function [txTime, numDataSym] = htTxTime(obj, param, value)
    numSTS = obj.NumSpaceTimeStreams;

    if strcmp(param, 'PSDULength') % PSDU length is provided
        psduLength = value;
        
        % Compute the number of OFDM symbols in Data field
        mcsTable  = wlan.internal.getRateTable(obj);
        numDBPS   = mcsTable.NDBPS;
        numES     = mcsTable.NES;
        numSS     = mcsTable.Nss;
        rate      = mcsTable.Rate;

        STBC = numSTS - numSS;
        mSTBC = 1 + (STBC~=0);

        if psduLength > 0
            if strcmp(obj.ChannelCoding,'BCC')
                Ntail = 6;
                numDataSym = mSTBC * ceil((8*psduLength + 16 + ...
                    Ntail*numES)/(mSTBC*numDBPS));

            else % LDPC
                numPLD = psduLength*8 + 16;
                cfg = wlan.internal.getLDPCparameters(numDBPS,rate,mSTBC,numPLD);
                numDataSym = cfg.NumSymbol;

            end
        else % NDP or sounding packet
            numDataSym = 0;
        end
    else % Number of data symbols is provided
        numDataSym = value;
    end

    if wlan.internal.inESSMode(obj)
        numESS = obj.NumExtensionStreams;
    else
        numESS = 0;
    end
    numPreambSym = 2 + 2 + 1 + 2 + 1 + wlan.internal.numVHTLTFSymbols(numSTS) + ...
        wlan.internal.numHTELTFSymbols(numESS);

    if strcmp(obj.GuardInterval, 'Short')
        txTime = numPreambSym*4 + 4*ceil(numDataSym*3.6/4);
    else % 'Long' guard-interval
        txTime = (numPreambSym+numDataSym)*4;
    end
end

% Calculate VHT format parameters
function [txTime, numDataSymbols] = vhtTxTime(obj, param, value)
    if strcmp(param, 'APEPLength') % APEP length is provided
        apepLength = value;
        numUsers = obj.NumUsers;
        APEPLen  = repmat(apepLength, 1, numUsers/length(apepLength));
        mcsTable = wlan.internal.getRateTable(obj);
        numDBPS  = mcsTable.NDBPS;
        numES    = mcsTable.NES;
        rate     = mcsTable.Rate;
        mSTBC = (numUsers == 1)*(obj.STBC ~= 0) + 1;

        % Calculate number of OFDM symbols
        if isscalar(apepLength) && (apepLength(1) == 0) % indicates NDP
            numDataSymbols = 0;
        else
            % Get ChannelCoding property to a cell
            channelCoding = getChannelCoding(obj);

            userCodingIndex = zeros(1,numUsers);
            for u=1:numUsers
                userCodingIndex(u) = strcmp(channelCoding{u}, 'BCC');
            end
            userCodingVector = 1:numUsers;
            indBCC  = userCodingVector(userCodingIndex == 1);
            indLDPC = userCodingVector(userCodingIndex == 0);

            numSymbolsLDPC = zeros(1,numUsers);
            numDataSymbols = 0;
            numTailBits    = 6; % For BCC encoding

            if ~isempty(indBCC)
                numDataSymbols = max(mSTBC*ceil((8*APEPLen(indBCC) + 16 + numTailBits*numES(indBCC))./(mSTBC.*numDBPS(indBCC))));
            end

            if ~isempty(indLDPC)
                % LDPC encoding parameters as defined in IEEE Std 802.11-2012,
                % IEEE Std 802.11ac-2013
                numSymbolsLDPC(indLDPC) = mSTBC * ceil((8*APEPLen(indLDPC) + 16)./(mSTBC * numDBPS(indLDPC))); % Eq 22-64
                numSymMaxInit = max([numDataSymbols,numSymbolsLDPC(indLDPC)]);                                 % Eq 22-65-MU, Eq 22-62-SU
                numSymbol = zeros(1, size(indLDPC,2));

                for u = 1:size(indLDPC,2)
                    numPLD = numSymMaxInit*numDBPS(indLDPC(u));
                    cfg = wlan.internal.getLDPCparameters(numDBPS(indLDPC(u)), rate(indLDPC(u)), mSTBC, numPLD);
                    numSymbol(u) = cfg.NumSymbol; % Eq 22-67
                end

                if max(numSymbol)>numSymMaxInit
                    numDataSymbols = max(numSymbol);
                else
                    numDataSymbols = max(numSymMaxInit);
                end
            end
        end
    else % Number of data symbols is provided
        numDataSymbols = value;
    end

    % Calculate burst time
    numPreambSym = 4 + 1 + 2 + 1 + wlan.internal.numVHTLTFSymbols(sum(obj.NumSpaceTimeStreams)) + 1;
    if strcmp(obj.GuardInterval, 'Short')
        txTime = 4*numPreambSym + 4*ceil(numDataSymbols*3.6/4);
    else
        txTime = 4*numPreambSym + 4*numDataSymbols;
    end
end

% Handle extra symbols for HT/VHT/HE/EHT format
function [actualPSDULength, actualTxTime, actualNumSym] = handleExtraSymbols(cfgPHY, unit, txTime, numDataSymbols, mcsTable, tailBits, nES)

    if isa(cfgPHY, 'wlanHESUConfig') || isa(cfgPHY, 'wlanEHTMUConfig')
        if isa(cfgPHY, "wlanEHTMUConfig")
            mSTBC = 1;
        else % wlanHESUConfig
            mSTBC = mcsTable.mSTBC;
        end

        if (numDataSymbols == 0) % Handling NSYM=0 case
            numDataBits = numDataSymbols*mcsTable.NDBPS;
        else % Handling NSYM > 0
            % Calculate the number of data bits: Try different pre-FEC padding factors
            % as these are the boundaries. Refer IEEE Std 802.11ax-2021, Section 27.4.3
            % eq (27-137), and IEEE Std 802.11be Draft 3.0, Section 36.4.3 eq (36-112)
            % and (36-113)
            numDataBits = [numDataSymbols*mcsTable.NDBPS ...                        % aInit=4 (no extra LDPC symbol segment)
            (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*3*mcsTable.NDBPSSHORT ...   % aInit=3 (extra LDPC symbol segment)
            (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*2*mcsTable.NDBPSSHORT ...   % aInit=2 (extra LDPC symbol segment)
            (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*1*mcsTable.NDBPSSHORT ...   % aInit=1 (extra LDPC symbol segment)
            (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*0*mcsTable.NDBPSSHORT];     % aInit=0 (extra LDPC symbol segment)
        end

        serviceBits = 16*(numDataBits~=0);
        tailBits = tailBits*(numDataBits~=0);

    elseif isa(cfgPHY,'wlanHTConfig')
        serviceBits = 16.*(numDataSymbols>0);
        tailBits = tailBits.*(numDataSymbols>0);
        % Set a minimum number of PSDUBytes the algorithm will try. If the
        % requested number of bytes cannot be met we will stop seaching.
        % For example, if the user requests 2 OFDM symbols but the minimum
        % for a configuration is 4, and we shouldn't have a PSDULength
        % which results in a number of nominal OFDM symobls which is less
        % than the target.
        minNumSymCalc = max(numDataSymbols-mcsTable.mSTBC,1);
        minNumBytes = floor((minNumSymCalc*mcsTable.NDBPS-serviceBits-tailBits)/8);
    
        % Begin by calculating how many bytes are required to generate a
        % nominal number of OFDM symbols more than the target. We allow for
        % more when STBC is used.
        numExtraSymbols = mcsTable.mSTBC;
        minNumSym = mcsTable.mSTBC*2;
        initialNumSymbols = max(numDataSymbols+numExtraSymbols,minNumSym);
        initialNumBytes = floor((initialNumSymbols*mcsTable.NDBPS-serviceBits-tailBits)/8);
    
        % Try different PSDULengths until the calculated number of OFDM
        % symbols is the same or less than the target.
        numDataBits = (initialNumBytes:-1:minNumBytes)*8 + serviceBits; 
    else % wlanVHTConfig
        mSTBC = mcsTable.mSTBC;
        nSYM = (numDataSymbols+mSTBC):-1:(numDataSymbols-mSTBC);

        serviceBits = 16.*(nSYM>0);
        tailBits = tailBits.*(nSYM>0);

        % Calculate the number of data bits
        numDataBits = nSYM*mcsTable.NDBPS;
    end

    % Calculate PSDU length in octets
    psduLength = floor((numDataBits - serviceBits - tailBits*nES)/8);
    psduLength = psduLength(psduLength >= 0);

    txtimes = zeros(1, numel(psduLength));
    numDataSyms = zeros(1, numel(psduLength));
    switch class(cfgPHY)
        case 'wlanHTConfig'
            for i = 1:numel(psduLength)
                [txtimes(i), numDataSyms(i)] = htTxTime(cfgPHY, 'PSDULength', psduLength(i));
            end

        case 'wlanVHTConfig'
            for i = 1:numel(psduLength)
                [txtimes(i), numDataSyms(i)] = vhtTxTime(cfgPHY, 'APEPLength', psduLength(i));
            end

        case 'wlanHESUConfig'
            maxHELength = 6500631; % Max PSDU length for HE format
            
            % PSDU length must not exceed 6500631. Assignment to
            % configuration will fail if it exceeds.
            if strcmp(unit, 'TxTime')
                coder.internal.errorIf(any(psduLength > maxHELength), 'wlan:wlanPSDULength:TxTimeExceedsSymbolBoundary');
            else % NumDataSymbols
                coder.internal.errorIf(any(psduLength > maxHELength), 'wlan:wlanPSDULength:NumSymExceedsPPDUTxTime');
            end

            sf = 1e3; % Scaling factor to convert time in us into ns   
            for i = 1:numel(psduLength)
                cfgPHY.APEPLength = psduLength(i);
                [~, timeTx, commonCodingParams] = wlan.internal.hePLMETxTimePrimative(cfgPHY);
                txtimes(i) = timeTx/sf; % txtimes in us
                numDataSyms(i) = commonCodingParams.NSYM;
            end
        
        otherwise % wlanEHTMUConfig
            maxEHTLength = 15523198; % Max PSDU length for EHT format
            
            % PSDU length must not exceed 15523198. Assignment to
            % configuration will fail if it exceeds.
            if strcmp(unit, 'TxTime')
                coder.internal.errorIf(any(psduLength > maxEHTLength), 'wlan:wlanPSDULength:TxTimeExceedsSymbolBoundary');
            else % NumDataSymbols
                coder.internal.errorIf(any(psduLength > maxEHTLength), 'wlan:wlanPSDULength:NumSymExceedsPPDUTxTime');
            end

            sf = 1e3; % Scaling factor to convert time in us into ns   
            for i = 1:numel(psduLength)
                cfgPHY.User{1}.APEPLength = psduLength(i);
                [~, timeTx, commonCodingParams] = wlan.internal.ehtPLMETxTimePrimative(cfgPHY);
                txtimes(i) = timeTx/sf; % txtimes in us
                numDataSyms(i) = commonCodingParams.NSYM;
            end
    end

    if strcmp(unit, 'TxTime') 
        % Get NumDataSymbols for the closest TxTime
        [actualNumSym,actualTxTime,lenIdx] = getLengthForClosestTxTime(txTime,txtimes,numDataSyms);
    else % NumDataSymbols
        % Pick the min value which is greater than or equal to 'value'
        idx = find(numDataSyms >= numDataSymbols);
        [actualNumSym,minidx] = min(numDataSyms(idx));
        lenIdx = idx(minidx);
        actualTxTime = txtimes(lenIdx);
    end
    actualTxTime = round2FiveDecimals(actualTxTime); % Round to five digits after decimal point
    assert(~isempty(actualTxTime) && ~isempty(actualNumSym));
    actualPSDULength = psduLength(lenIdx);
end

% Handle packet extension for HE format
function [psduLength, corrTxTime] = handlePacketExtension(cfgPHY, mcsTable, txTime, nSym)
    if isa(cfgPHY, "wlanEHTMUConfig")
        mSTBC = 1;
        maxPSDULength = 15523198;
    else % wlanHESUConfig
        mSTBC = mcsTable.mSTBC;
        maxPSDULength = 6500631;
    end

    % Try different numbers of data symbols as packet extension may require
    % fewer actual data symbols
    numDataSymbols = [nSym, nSym-1, nSym-2, nSym-3];

    % Calculate the number of data bits: Try different pre-FEC padding
    % factors as these are the boundaries.
    numDataBits = [numDataSymbols*mcsTable.NDBPS ...                            % aInit=4
        (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*3*mcsTable.NDBPSSHORT ...   % aInit=3
        (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*2*mcsTable.NDBPSSHORT ...   % aInit=2
        (numDataSymbols-mSTBC)*mcsTable.NDBPS+mSTBC*1*mcsTable.NDBPSSHORT];     % aInit=1

    serviceBits = 16*(numDataBits ~= 0);
    
    if isLDPCCoded(cfgPHY)
        tailBits = 0;
    else
        tailBits = 6*(numDataBits ~= 0);
    end
    
    % Calculate PSDU length in octets
    factoredLengths = floor((numDataBits - serviceBits - tailBits)/8);
    % Check with maximum allowed PSDU length as per the standard. Assignment to
    % configuration will fail if it exceeds.
    coder.internal.errorIf(any(factoredLengths > maxPSDULength) && isempty(factoredLengths((factoredLengths >= 0) & (factoredLengths <= maxPSDULength))), ...
        'wlan:wlanPSDULength:TxTimeExceedsSymbolBoundary');
	% Test only valid lengths
    testLengths = factoredLengths((factoredLengths >= 0) & (factoredLengths <= maxPSDULength));
    
    % Calculate the TxTimes for the above PSDU lengths
    sf = 1e3; % Scaling factor to convert time in us into ns
    txtimes = zeros(1, numel(testLengths));
    if isa(cfgPHY, "wlanEHTMUConfig")
        for i = 1:numel(testLengths)
            cfgPHY.User{1}.APEPLength = testLengths(i);
            [~, timeTx] = wlan.internal.ehtPLMETxTimePrimative(cfgPHY);
            txtimes(i) = timeTx/sf; % txtimes in us
        end
    else
        for i = 1:numel(testLengths)
            cfgPHY.APEPLength = testLengths(i);
            [~, timeTx] = wlan.internal.hePLMETxTimePrimative(cfgPHY);
            txtimes(i) = timeTx/sf; % txtimes in us
        end
    end

    % Choose the PSDU length with the next nearest TxTime value
    [psduLength,corrTxTime] = getLengthForClosestTxTime(txTime,txtimes,testLengths);
end

% Returns the length that results in time closest to given TxTime, its
% corresponding TxTime and the index used to extract the length and time.
function [outputLength, closestTxTime, idxToExtract] = getLengthForClosestTxTime(txTime, testTxTimes, testLengths)
    % Choose the PSDU length with the next nearest TxTime value
    idx = find(testTxTimes >= txTime);
    % Get the lowest transmit time which is greater than or equal to the
    % target
    closestTxTime = min(testTxTimes(idx));

    if closestTxTime > 5484
        % Pick the max value which is less than or equal to 'value'
        idx = find(testTxTimes <= txTime);

        % Get the highest transmit time which is less than or equal to the
        % target
        closestTxTime = max(testTxTimes(idx));
    end
    
    % Get the largest PSDULength which gives this transmit time
    candidateTestLengths = testLengths(idx);
    matchTxTime = find(closestTxTime==testTxTimes(idx));
    [outputLength,maxIdx] = max(candidateTestLengths(matchTxTime));

    % Index used to extract from testTxTimes and testLengths
    idxToExtract = idx(matchTxTime(maxIdx));
end

% Get the symbol time for the specific format configuration
function [symbolTime, longSymbolTime, symbolBoundaryMultiple] = getSymbolTime(cfgPHY)
    switch class(cfgPHY)
        case 'wlanNonHTConfig'
            scalar = bwScalar(cfgPHY.ChannelBandwidth);
            symbolTime = 4*scalar; % Symbol duration including guard interval
            longSymbolTime = 4*scalar; % Long symbol duration
            symbolBoundaryMultiple = longSymbolTime; % Symbol boundary multiple

        case {'wlanHTConfig', 'wlanVHTConfig'}
            % Symbol duration including guard interval
            if strcmp(cfgPHY.GuardInterval, 'Long')
                symbolTime = 4;
            else
                symbolTime = 3.6;
            end
            longSymbolTime = 4; % Long symbol duration
            symbolBoundaryMultiple = longSymbolTime; % Symbol boundary multiple

        otherwise % wlanHESUConfig and wlanEHTMUConfig
            % Symbol duration including guard interval
            switch cfgPHY.GuardInterval
                case 0.8
                    symbolTime = 13.6;
                case 1.6
                    symbolTime = 14.4;
                otherwise % 3.2
                    symbolTime = 16;
            end
            longSymbolTime = 16; % Long symbol duration
            symbolBoundaryMultiple = symbolTime; % Symbol boundary multiple
    end
end

% Rounds the given number to 5 digits after the decimal point
function y = round2FiveDecimals(x)
% For codegen
    y = floor(x*100000)/100000;
end

% Returns a duration scalar based on the channel bandwidth
function scalar = bwScalar(chanBW)
    switch chanBW
      case 'CBW5'
        scalar = 4;
      case 'CBW10'
        scalar = 2;
      otherwise % 'CBW20','CBW40','CBW80','CBW160'
        scalar = 1;
    end
end

% Returns NDP overhead based on the PHY configuration
function ndpOverhead = ndpOverheadTime(cfgPHY)
    if isa(cfgPHY, 'wlanHESUConfig') || isa(cfgPHY, 'wlanEHTMUConfig')
        if strcmp(cfgPHY.ChannelBandwidth,'CBW320')
            ndpOverhead = 8; % IEEE Std 802.11be Draft 3.0, Section 36.3.14
        else
            ndpOverhead = 4; % IEEE Std 802.11ax-2021, Section 27.3.13, & IEEE Std 802.11be Draft 3.0, Section 36.3.14
        end
    else % No NDP overhead for other formats
        ndpOverhead = 0;
    end
end

% Check LDPC Channel coding
function ldpcCoding = isLDPCCoded(cfgPHY)
    switch class(cfgPHY)
        case 'wlanNonHTConfig'
            ldpcCoding = false;
        case 'wlanEHTMUConfig'
            if cfgPHY.User{1}.ChannelCoding==wlan.type.ChannelCoding.ldpc
                ldpcCoding = true;
            else
                ldpcCoding = false;
            end
        otherwise % {'wlanHTConfig', 'wlanVHTConfig', 'wlanHESUConfig'}
            if strcmp(cfgPHY.ChannelCoding, 'LDPC')
                ldpcCoding = true;
            else
                ldpcCoding = false;
            end
    end
end

function flag = hasNominalPacketPadding(cfgPHY)
    switch class(cfgPHY)
        case 'wlanHESUConfig'
            if cfgPHY.NominalPacketPadding
                flag = true;
            else
                flag = false;
            end
        case 'wlanEHTMUConfig'
            if cfgPHY.User{1}.NominalPacketPadding
                flag = true;
            else
                flag = false;
            end
        otherwise
            flag = false;
    end
end

function optionalWarn(suppressWarns, warnID, varargin)
    if ~suppressWarns
        coder.internal.warning(warnID, varargin{:});
    end
end