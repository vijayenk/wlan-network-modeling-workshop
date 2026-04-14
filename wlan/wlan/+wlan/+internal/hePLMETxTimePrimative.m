function [PSDU_LENGTH,TXTIME,varargout] = hePLMETxTimePrimative(cfg)
%hePLMETxTimePrimative HE PSDULength and TXTIME from PLME TXTIME primitive
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   [PSDU_LENGTH,TXTIME] = hePLMETxTimePrimative(CFG) returns the PSDU
%   length per user, and TX time as per as per IEEE P802.11ax/D4.1 Section
%   27.4.3.
%
%   [...,COMMONCODINGPARAMS] = hePLMETxTimePrimative(CFG) additionally
%   returns the common coding parameters.
%
%   [...,COMMONCODINGPARAMS,USERCODINGPARAMS] = hePLMETxTimePrimative(CFG)
%   additionally returns the user coding parameters.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

allocationInfo = ruInfo(cfg);
numUsers = allocationInfo.NumUsers;

isTBPPDU = isa(cfg,'wlanHETBConfig');
isTBSystem = isequal(packetFormat(cfg),'HE-TB System');
isTB = isTBPPDU  || isTBSystem;

% Force PSDULength to 0 and TXTIME to 72000 nsec for HE TB feedback NDP
if isTBPPDU && cfg.FeedbackNDP
    PSDU_LENGTH = 0;
    TXTIME = 72000;
    return;
end

% For all formats get the APEPLength and channel coding per user, and
% the number of HE-LTF and HE-SIG-B symbols
if isTBPPDU
    % Get current RU assignment details
    NHELTF = cfg.NumHELTFSymbols;
    NHESIGB = 0;
elseif isa(cfg,'wlanHESUConfig')
    apepLength = cfg.APEPLength;
    NHESIGB = 0;
    NHELTF = wlan.internal.numVHTLTFSymbols(cfg.NumSpaceTimeStreams);
elseif strcmp(packetFormat(cfg),'HE-SU') % For HEz
    apepLength = cfg.APEPLength;
    NHESIGB = 0;
    NHELTF = numHELTFSymbols(cfg);
else % HE-MU
    % Get the APEPLength and channel coding per user
    apepLength = zeros(numUsers,1);

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
    for userIdx = 1:numUsers
        if STAID(userIdx)==2046
            % If STAID is 2046, then RU carries no data, therefore do not
            % include user in coding calculations by setting the APEPLength
            % to 0
            apepLength(userIdx) = 0;
        else
            apepLength(userIdx) = cfg.User{userIdx}.APEPLength;
        end
    end

    if isTB 
        NHESIGB = 0; % No HE-SIG-B field in HE TB
    else
        sigbInfo = wlan.internal.heSIGBCodingInfo(cfg);
        NHESIGB = sigbInfo.NumSymbols;
    end
    NHELTF = wlan.internal.numVHTLTFSymbols(max(allocationInfo.NumSpaceTimeStreamsPerRU));
end

% Calculate TXTIME
SignalExtension = 0; % in ns, 0 for 5 GHz or 6000 for 2.4 GHz
[commonCodingParams,userCodingParams] = wlan.internal.heCodingParameters(cfg);

NSYM = commonCodingParams.NSYM;

if isTBPPDU
    [trc,~,Nma] = wlan.internal.heTBTimingRelatedConstants(cfg);
else % wlanHESUConfig, wlanHEMUConfig
    npp = wlan.internal.heNominalPacketPadding(cfg);
    Nma = wlan.internal.numMidamblePeriods(cfg,commonCodingParams.NSYM);
    trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,commonCodingParams.PreFECPaddingFactor,npp,commonCodingParams.NSYM);
end

% Part of IEEE P802.11ax/D4.1, Equation 27-121
switch packetFormat(cfg)
    case 'HE-MU'
        THE_PREAMBLE = trc.TRLSIG+trc.THESIGA+NHESIGB*trc.THESIGB+trc.THESTFNT+NHELTF*trc.THELTFSYM;
    case 'HE-SU'
        THE_PREAMBLE = trc.TRLSIG+trc.THESIGA+trc.THESTFNT+NHELTF*trc.THELTFSYM;
    case {'HE-TB' 'HE-TB System'}
        THE_PREAMBLE = trc.TRLSIG+trc.THESIGA+trc.THESTFT+NHELTF*trc.THELTFSYM;
    otherwise % 'HE-EXT-SU'
        THE_PREAMBLE = trc.TRLSIG+trc.THESIGAR+trc.THESTFNT+NHELTF*trc.THELTFSYM;
end
sf = 1e3; % Scaling factor to convert bandwidth and time in ns to samples
% IEEE P802.11ax/D4.1, Section 27.4.3, Equation 27-135
TXTIME = 20*sf+THE_PREAMBLE+NSYM*trc.TSYM+Nma*NHELTF*trc.THELTFSYM+trc.TPE+SignalExtension; % TXTIME in ns

% Get PSDULength for all users
PSDU_LENGTH = coder.nullcopy(zeros(1,numUsers));
for u = 1:numUsers
    PSDU_LENGTH(u) = userCodingParams(u).PSDULength; 
end
% Force PSDULength to 0 when APEPLength is 0 for SU and MU
if ~isTB
    PSDU_LENGTH(apepLength==0) = 0;
end

varargout{1} = commonCodingParams;
varargout{2} = userCodingParams;
end
