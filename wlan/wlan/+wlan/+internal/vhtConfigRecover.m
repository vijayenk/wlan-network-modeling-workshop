function [cfgVHTRx, numDataSym, crcBits, apepLen, failInterpretation] = ...
    vhtConfigRecover(LSIGBits, VHTSIGABits, varargin)
%vhtConfigRecover Recover VHT transmission configuration
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CFGVHT = vhtConfigRecover(LSIGBITS,VHTSIGABITS) returns a VHT
%   configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a> given recovered
%   bits from L-SIG and VHT-SIG-A fields for a single-user or multi-user
%   transmission.
%
%   CFGVHT = vhtConfigRecover(LSIGBITS,VHTSIGABITS,VHTSIGBBITS)
%   returns a VHT configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a> given recovered
%   bits from L-SIG, VHT-SIG-A, and VHT-SIG-B fields for a single-user
%   transmission only.
%
%   CFGVHT = vhtConfigRecover(LSIGBITS,VHTSIGABITS,VHTSIGBBITS, ...
%   USERNUMBER) returns a VHT configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>
%   given recovered bits from L-SIG, VHT-SIG-A, and VHT-SIG-B fields for a
%   user specified by USERNUMBER for a multi-user transmission.
%
%   [CFGVHT,NUMDATASYM,CRCBITS,APEPLENGTH,FAILINTERPRETATION] =
%   vhtConfigRecover(...) returns additional decoding information.
%
%   NUMDATASYM is the decoded number of VHT data symbols.
%
%   CRCBITS is a an 8-by-1 binary vector containing the reference VHT-SIG-B
%   CRC bits. It is an array of zeros if you do not provide VHT-SIG-B bits.
%
%   APEPLENGTH is the decoded APEPLENGTH.
%
%   FAILINTERPRETATION is a logical scalar and represent the result of
%   interpreting the received signaling bits. The function return this as
%   true when it cannot interpret the received bits.
%
%   [...] = vhtConfigRecover(...,'SuppressError',VAL) controls the behavior
%   of the function due to an unexpected value of the interpreted bits. VAL
%   is logical. When VAL is true and the function cannot interpret the
%   recovered bits due to an unexpected value, the function returns VAL as
%   true. When VAL is false and the function cannot interpret the recovered
%   its due to an unexpected value, an exception is issued, and the
%   function does not return an output. The default is false.
%
%   Note: Best effort processing implies offering as much configuration
%   detail as possible based on inputs:
%       LSIG + VHTSIGA                     : for Single-user Tx
%       LSIG + VHTSIGA + VHTSIGB           : for Single-user Tx
%       LSIG + VHTSIGA + VHTSIGB + UserNum : for Multi-user Tx
%
%   See also wlanVHTDataRecover, wlanVHTConfig.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

narginchk(2,6);

suppressError = false;
if nargin>3 && strcmp(varargin{end-1},'SuppressError')
    suppressError = varargin{end};
    validateattributes(suppressError,{'logical'},{'scalar'},mfilename,'Suppress error');
    nprevarg = nargin-2;
else
    nprevarg = nargin;
end

if nprevarg==2 % two inputs
    VHTSIGBBits = []; % For single-user transmission
    userNum = 1;
elseif nprevarg==3
    VHTSIGBBits = varargin{1}; % For single-user transmission
    userNum = 1;
elseif nprevarg==4
    VHTSIGBBits = varargin{1}; % For multi-user transmission
    userNum = varargin{2};
else
    error('Unexpected syntax');
end

% Retrieve information from VHT-SIG-A bits
VHTSIGABits = double(reshape(VHTSIGABits, 24, 2)');
if all(VHTSIGABits(1,1:2) == [0 0])
    chanBW = 'CBW20';
    numSD = 52;
elseif  all(VHTSIGABits(1,1:2) == [1 0])
    chanBW = 'CBW40';
    numSD = 108;
elseif  all(VHTSIGABits(1,1:2) == [0 1])
    chanBW = 'CBW80';
    numSD = 234;
else
    chanBW = 'CBW160';
    numSD = 468;
end

stbc = logical(VHTSIGABits(1, 4));
groupID = bit2int(VHTSIGABits(1, 5:10)', 6, false);
if groupID == 0 || groupID == 63
    isSUTx = true;
else
    isSUTx = false; % is MU transmission
end

% Get extra OFDM symbol information from VHTSIG-A bits
if VHTSIGABits(2,4)==1
    LDPCextraOFDMsymbol = 1;
else
    LDPCextraOFDMsymbol = 0;
end

% Retrieve rxTime from L-SIG bits
rxTime = getRxTime(LSIGBits);

% default assignments
crcBits = zeros(8, 1, 'int8');
apepLen = 0;

if isSUTx
    % SINGLE-USER Transmission

    numSpaceTimeStreams = bit2int(VHTSIGABits(1, 11:13)', 3, false) + 1;
    % Make sure numSpaceTimeStreams is a even scalar when using STBC
    failInterpretation = wlan.internal.failInterpretationIf(stbc && (mod(numSpaceTimeStreams, 2) == 1),...
        'wlan:shared:OddNumSTSWithSTBC',suppressError);
    if failInterpretation
        % Invalid value
        numDataSym = 0;
        cfgVHTRx = wlanVHTConfig;
        return
    end

    partialAID = bit2int(VHTSIGABits(1, 14:22)', 9, false);
    mcs = bit2int(VHTSIGABits(2, 5:8)', 4, false);
    beamforming = logical(VHTSIGABits(2, 9));
    numSS  = numSpaceTimeStreams / (stbc + 1);
    thisComb = [wlan.internal.cbwStr2Num(chanBW), mcs, numSS];

    if suppressError && (mcs>9 || isInvalidCombination(thisComb))
        % Invalid value
        failInterpretation = true;
        numDataSym = 0;
        cfgVHTRx = wlanVHTConfig;
        return
    end

    channelCodingBit = VHTSIGABits(2, 3);
    if channelCodingBit==1
        % Channel coding is LDPC
        channelCoding = {'LDPC'};
    else
        % Channel coding is BCC
        channelCoding = {'BCC'};
    end

    % Get number of OFDM Data symbols
    [numDataSym, guardInterval] = getDataSym(VHTSIGABits, ...
        numSpaceTimeStreams, rxTime);

    % Calculate received PSDULength and set it to be the APEPLength
    [numDBPS, numES] = getMCSTable(mcs, numSD, numSS, channelCoding{1});
    if strcmp(channelCoding{1}, 'BCC')
        numTailBits = 6;
        psduLength = floor((numDataSym*numDBPS - numTailBits*numES - 16)/8);
    else % LDPC
        psduLength = floor(((numDataSym-LDPCextraOFDMsymbol*(1+stbc))*numDBPS - 16)/8);
    end
    psduLength = max(psduLength,0); % Deal with NDP which psduLength calculation

    % Create the returned object from individual parameters
    cfgVHTRx = wlanVHTConfig('ChannelBandwidth', chanBW, ...
        'NumSpaceTimeStreams', numSpaceTimeStreams, ...
        'GroupID', groupID, ...
        'STBC', stbc, ...
        'Beamforming', beamforming, ...
        'PartialAID', partialAID, ...
        'MCS', mcs, ...
        'ChannelCoding', channelCoding, ...
        'GuardInterval', guardInterval, ...
        'APEPLength', psduLength);

    % Don't necessarily need the SIGB bits for SU recovery.
    % If passed in, confirm the actual lengths are appropriate
    if ~isempty(VHTSIGBBits)
        [crcBits, apepLen] = wlan.internal.vhtInterpretSIGB(VHTSIGBBits, chanBW, true);

        % Confirm APEP lengths and PSDU length are commensurate. APEP
        % length recovered is in units of 4 octets so account for this in
        % comparison.
        failInterpretation = wlan.internal.failInterpretationIf(ceil(psduLength/4) < apepLen/4,...
            'wlan:vhtConfigRecover:InvalidLengths',suppressError);
        if failInterpretation
            numDataSym = 0;
            cfgVHTRx = wlanVHTConfig;
            return
        end
    end
else
    % MULTI-USER Transmission

    % Get coded NSTS per user
    numSTS = [bit2int(VHTSIGABits(1, 11:13)', 3, false) ...
        bit2int(VHTSIGABits(1, 14:16)', 3, false) bit2int(VHTSIGABits(1, 17:19)', 3, false) ...
        bit2int(VHTSIGABits(1, 20:22)', 3, false)];

    % Derive other properties from numSTS: numUsers, UserPositions,
    % NumSpaceTimeStreams, channelCodingBits

    maxUsers = 4;                           % Maximum allowed
    uPositions = 0:3;                       % correspond to max. users
    channelCodingBits = ones(1, maxUsers);  % corresponding to max. users
    for userIdx = 1:maxUsers
        % Read off the received channelCoding bits
        if userIdx == 1
            % Read B2 for 1 user
            channelCodingBits(1) = VHTSIGABits(2, 3);
        else
            % Read B4:B6 for 2:4 users
            channelCodingBits(userIdx) = VHTSIGABits(2, 3+userIdx);
        end
    end

    % Check numSTS values and revise properties
    uPositions = uPositions(numSTS~=0);
    channelCodingBits = channelCodingBits(numSTS~=0);
    numUsers = length(uPositions);
    if numUsers == 1
        % NumUser is 1 for MU case, treat it as failed interpretation
        failInterpretation = true;
        numDataSym = 0;
        cfgVHTRx = wlanVHTConfig;
        return
    end

    numSpaceTimeStreams = numSTS(numSTS~=0);
    % Invalid number of STSs
    failInterpretation = wlan.internal.failInterpretationIf(any(numSpaceTimeStreams>4) || sum(numSpaceTimeStreams)>8,...
        'wlan:vhtConfigRecover:InvalidTotalNumSTS',suppressError);
    if failInterpretation
        % Invalid value
        numDataSym = 0;
        cfgVHTRx = wlanVHTConfig;
        return
    end

    % Per-user coding information
    %   0 indicates BCC, 1 indicates LDPC for present users.
    channelCoding = cell(1, numUsers);
    for userIdx = 1:numUsers
        if channelCodingBits(userIdx) == 1
            % Channel coding is LDPC
            channelCoding{userIdx} = 'LDPC';
        else
            % Channel coding is BCC
            channelCoding{userIdx} = 'BCC';
        end
    end

    % Get number of OFDM Data symbols
    [numDataSym, guardInterval] = getDataSym(VHTSIGABits, ...
        sum(numSpaceTimeStreams), rxTime);

    if ~isempty(VHTSIGBBits)
        % Individual user processing (based on userNum)
        %   apepLen Rounded to 4-byte multiple
        [crcBits, apepLen, mcs] = wlan.internal.vhtInterpretSIGB(VHTSIGBBits, chanBW, false);
        numSS = numSpaceTimeStreams(userNum) / (stbc + 1);
        thisComb = [wlan.internal.cbwStr2Num(chanBW), mcs, numSS];

        if suppressError && (mcs>9 || apepLen>1048575 || isInvalidCombination(thisComb))
            % Invalid value
            failInterpretation = true;
            cfgVHTRx = wlanVHTConfig;
            return
        end

        % Calculate received PSDULength and set it to be the APEPLength
        [numDBPS, numES] = getMCSTable(mcs, numSD, numSS, channelCoding{userNum});
        if strcmp(channelCoding{userNum}, 'BCC')
            numTailBits = 6;
            psduLength = floor((numDataSym*numDBPS - numTailBits*numES - 16)/8);
        else % LDPC
            psduLength = floor(((numDataSym-LDPCextraOFDMsymbol*(1+stbc))*numDBPS - 16)/8);
        end

        % Confirm APEP lengths and PSDU length are commensurate. APEP
        % length recovered is in units of 4 octets so account for this in
        % comparison.
        failInterpretation = wlan.internal.failInterpretationIf(ceil(psduLength/4) < apepLen/4,...
            'wlan:vhtConfigRecover:InvalidLengths',suppressError);
        if failInterpretation
            numDataSym = 0;
            cfgVHTRx = wlanVHTConfig;
            return
        end

        % Create the returned object from individual parameters
        % Set this to be a single-user config.
        cfgVHTRx = wlanVHTConfig('ChannelBandwidth', chanBW, ...
            'NumUsers', 1, ...
            'NumSpaceTimeStreams', numSpaceTimeStreams(userNum), ...
            'GroupID', groupID, ...
            'STBC', stbc, ...
            'MCS', mcs, ...
            'ChannelCoding', {channelCoding{userNum}}, ...
            'GuardInterval', guardInterval, ...
            'APEPLength', psduLength ); % Required for codegen
    else
        % Create the returned object from individual parameters
        % Set this to be a MULTI-USER configuration
        %   But with no length information (only the default)
        cfgVHTRx = wlanVHTConfig('ChannelBandwidth', chanBW, ...
            'NumUsers', numUsers, ...
            'UserPositions', uPositions, ...
            'NumSpaceTimeStreams', numSpaceTimeStreams, ...
            'GroupID', groupID, ...
            'STBC', stbc, ...
            'ChannelCoding', channelCoding, ...
            'GuardInterval', guardInterval);
    end

end

end

%--------------------------------------------------------------------------
function rxTime = getRxTime(LSIGBits)
% Retrieve RXTime from L-SIG for VHT transmission

% 4 symbol range, [RXTime - 3: RXTime]
rxTime = (bit2int(double(LSIGBits(6:17)), 12, false) + 3)/3*4 + 20;

end

%--------------------------------------------------------------------------
function [numDataSym, giType] = getDataSym(VHTSIGABits, numSTSTotal, rxTime)
% Recover number of OFDM symbols and guard interval type

numPreambSym = 9 + wlan.internal.numVHTLTFSymbols(numSTSTotal);
if VHTSIGABits(2, 1)
    giType = 'Short';
    numDataSym = floor((rxTime/4 - numPreambSym)*10.0/9.0) - VHTSIGABits(2, 2);
else
    giType = 'Long';
    numDataSym = rxTime/4 - numPreambSym;  % Precise
end

end

%--------------------------------------------------------------------------
function [Ndbps, Nes] = getMCSTable(MCS, Nsd, Nss, channelCoding)
% Similar to wlan.internal.getRateTable, but with modified inputs

[Nbpscs,rate] = wlan.internal.getMCSTable(MCS);

Ndbps = Nsd * Nbpscs * Nss * rate;

if strcmp(channelCoding, 'LDPC')
    Nes = 1; % always the case
else % BCC
    % Handle exceptions to Nes generic rule - Table 7.13 [2].
    %   For each case listed, work off the Ndbps value and create a look-up
    %   table for the Nes value.
    %   Only 9360 has a valid value from the generic rule also,
    %   all others are exceptions
    NdbpsVec = [2457 8190 9828 9360 14040 9828 16380 19656 21840 14976 22464];
    expNes =   [   3    6    6    6     8    6     9    12    12     8    12];

    exceptIdx = find(Ndbps == NdbpsVec);
    if ~isempty(exceptIdx)
        if (Ndbps == 9360) && (Nss == 5) % One valid case for 160, 80+80
            Nes = 5;
        else  % Two exception cases
            Nes = expNes(exceptIdx(1));
        end
    else  % Generic rule: 3.6*600 - for a net 600Mbps per encoder
        Nes = ceil(Ndbps/2160);
    end
end

end

%--------------------------------------------------------------------------
function flag = isInvalidCombination(currentComb)
% isInValidCombination returns true if the provided combination of cbw,
% mcs, and nss is not allowed, otherwise returns false

    % Bandwidth/MCS/Nss valid combinations
    % Reference: Tables 21-29 to 21-60, IEEE Std 802.11-2020
    InvalidComb_BW_MCS_Nss = [20,  9, 1; ... % [chanBW, MCS, numSS]
                              20,  9, 2; ...
                              20,  9, 4; ...
                              20,  9, 5; ...
                              20,  9, 7; ...
                              20,  9, 8; ...
                              80,  6, 3; ...
                              80,  6, 7; ...
                              80,  9, 6; ...
                              160, 9, 3];
    flag = any(all(currentComb == InvalidComb_BW_MCS_Nss, 2));
end
% [EOF]