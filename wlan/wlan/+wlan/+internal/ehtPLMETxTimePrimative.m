function [PSDU_LENGTH,TXTIME,commonCodingParams,userCodingParams,trc] = ehtPLMETxTimePrimative(cfg)
%ehtPLMETxTimePrimative EHT PSDULength and TXTIME from PLME TXTIME
%primitive
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PSDU_LENGTH,TXTIME,COMMONCODINGPARAMS,,USERCODINGPARAMS,TRC] =
%   ehtPLMETxTimePrimative(CFG) returns the PSDU length per user, TXTIME,
%   common coding parameter, user coding parameters, and time related
%   constants as per IEEE P802.11be/D2.0 Section 36.4.3.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlaEHTMUConfig')">wlanEHTMUConfig</a>, or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

allocationInfo = ruInfo(cfg);
numUsers = allocationInfo.NumUsers;
isEHTTB = isequal(packetFormat(cfg),'EHT-TB');

if isEHTTB
    NEHTLTF = cfg.NumEHTLTFSymbols;
    NEHTSIG = 0;
else
    % Get the APEPLength per user
    apepLength = zeros(numUsers,1);

    % Get STAID(EHT MU) and AID12(EHT TB) for all users
    STAID = coder.nullcopy(zeros(1,numUsers));

    for u = 1:numUsers
        if isequal(packetFormat(cfg),'EHT-MU')
            STAID(u) = cfg.User{u}.STAID;
        else
            % EHT-TB System
            STAID(u) = cfg.User{u}.AID12; % Mapping AID12 to STAID
        end
        if STAID(u)==2046
            % If STAID is 2046, then RU carries no data, therefore do not
            % include user in coding calculations by setting the APEPLength
            % to 0
            apepLength(u) = 0;
        else
            apepLength(u) = cfg.User{u}.APEPLength;
        end
    end

    % Number of EHT-LTF and EHT-SIG symbols
    NEHTLTF = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU))+cfg.NumExtraEHTLTFSymbols;
    if isEHTTB || isequal(packetFormat(cfg),'EHT-TB System')
        NEHTSIG = 0;
    else
        ehtSIGInfo = wlan.internal.ehtSIGCodingInfo(cfg);
        NEHTSIG = ehtSIGInfo.NumSIGSymbols;
    end
end

% Calculate TXTIME
SignalExtension = 0; % in ns, 0 for 5 GHz or 6000 for 2.4 GHz
[commonCodingParams,userCodingParams] = wlan.internal.ehtCodingParameters(cfg);
NSYM = commonCodingParams.NSYM;

if isEHTTB
    trc = wlan.internal.ehtTBTimingRelatedConstants(cfg);
else % EHT-MU and EHT-TB system
    npp = wlan.internal.heNominalPacketPadding(cfg);
    trc = wlan.internal.ehtTimingRelatedConstants(cfg.ChannelBandwidth,cfg.GuardInterval,cfg.EHTLTFType,commonCodingParams.PreFECPaddingFactor,npp,commonCodingParams.NSYM);
end

switch packetFormat(cfg)
    case 'EHT-MU'
        TEHT_PREAMBLE = trc.TRLSIG+trc.TUSIG+NEHTSIG*trc.TEHTSIG+trc.TEHTSTFNT+NEHTLTF*trc.TEHTLTFSYM; % Equation 36-97
    otherwise % EHT-TB || EHT-TB System
        TEHT_PREAMBLE = trc.TRLSIG+trc.TUSIG+trc.TEHTSTFT+NEHTLTF*trc.TEHTLTFSYM; % Equation 36-97
end
sf = 1e3; % Scaling factor to convert bandwidth and time in ns to samples.
TXTIME = 20*sf+TEHT_PREAMBLE+NSYM*trc.TSYM+trc.TPE+SignalExtension; % TXTIME in ns. Equation 36-110

% Calculate PSDU_LENGTH per user
PSDU_LENGTH = coder.nullcopy(zeros(1,numUsers));
for u = 1:numUsers
    PSDU_LENGTH(u) = userCodingParams(u).PSDULength; 
end

% Force PSDULength to 0 when APEPLength is 0 for EHT MU
if isequal(packetFormat(cfg),'EHT-MU')
    PSDU_LENGTH(apepLength==0) = 0;
end

end