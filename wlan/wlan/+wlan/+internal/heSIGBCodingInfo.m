function codingInfo = heSIGBCodingInfo(cfg)
% heSIGBCodingInfo HE SIG-B coding information
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CODINGINFO = heSIGBCodingInfo(CFGMU) returns a structure containing
%   SIG-B coding information including the number of HE-SIG-B symbols for
%   the given multi-user format configuration object CFG.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

% Multi-user configuration
allocationIndex = cfg.AllocationIndex;
chanBW = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
sigbMCS = cfg.SIGBMCS;
sigbDCM = cfg.SIGBDCM;

% Rate table for SIG-B
sigbMCSTable = wlan.internal.heSIGBRateTable(sigbMCS,sigbDCM);

% Determine if center 26-tone RU is signaled on which content channel
if cfg.LowerCenter26ToneRU || cfg.UpperCenter26ToneRU
    if chanBW==80
        % The center 26-tone user info is carried in both content channel 1
        % and 2
        center26ToneRU = [true true];
    elseif chanBW==160
        % Can use either center 26-tone. content channel 1 carries the
        % lower, and content channel 2 carries the upper
        center26ToneRU = [cfg.LowerCenter26ToneRU cfg.UpperCenter26ToneRU];
    else
        % No center 26 tone RU on either content channel
        center26ToneRU = [false false];
    end
else
    % No center 26 tone RU on either content channel
    center26ToneRU = [false false];
end

% SIG-B compression is only used for full bandwidth MU-MIMO allocation
sigBCompression = false; % SIGB compression is not valid for OFDMA
allocationInfo = cfg.ruInfo;
if allocationInfo.NumRUs==1 % For full bandwidth allocation
    switch cfg.ChannelBandwidth
        case 'CBW20'
            sigBCompression = cfg.SIGBCompression;
        otherwise % CBW40, CBW80, CBW160
            sigBCompression = numel(allocationIndex)==1;
    end
end

[contentChannel1Users,contentChannel2Users,numContentChannels] = wlan.internal.heSIGBUsersPerChannel(chanBW,sigBCompression,allocationIndex,center26ToneRU);

numUsersPerChannel = zeros(1,numContentChannels);
numUsersPerChannel(1) = numel(contentChannel1Users);
if numContentChannels>1
    numUsersPerChannel(2) = numel(contentChannel2Users);
end

if sigBCompression
    numCommonFieldBits = 0;
else
    s = wlan.internal.heSIGBCommonFieldInfo(chanBW,sigbMCSTable.NDBPS);
    numCommonFieldBits = s.NumCommonFieldBits;
end

numSym = wlan.internal.heNumSIGBSymbolsPerContentChannel(numContentChannels, ...
    numUsersPerChannel,numCommonFieldBits,sigbMCSTable.NDBPS);

codingInfo = struct( ...
    'Rate',                      sigbMCSTable.Rate, ...
    'NBPSCS',                    sigbMCSTable.NBPSCS, ...
    'NCBPS',                     sigbMCSTable.NCBPS, ...
    'NSD',                       sigbMCSTable.NSD, ...
    'NDBPS',                     sigbMCSTable.NDBPS, ...
    'NSS',                       sigbMCSTable.NSS, ...
    'DCM',                       sigbDCM, ...
    'Compression',               sigBCompression, ...
    'NumContentChannels',        numContentChannels, ...
    'NumSymbols',                numSym, ...
    'NumUsersPerContentChannel', numUsersPerChannel, ...
    'ContentChannel1Users',      contentChannel1Users, ...
    'ContentChannel2Users',      contentChannel2Users, ...
    'Center26ToneRU',            center26ToneRU);
end