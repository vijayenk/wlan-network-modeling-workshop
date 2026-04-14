function [nSCUniqueDefault,nSubblock80] = validateEqualizerInputs(sym,chEst,cfg,field,userIdx,filename,nsc20MHz)
%validateEqualizerInputs VHT, HE, and EHT equalizer input validation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [NSCUNIQUEDEFAULT,NSUBBLOCK80] =
%   validateEqualizerInputs(SYM,CHEST,CFG,FIELD,USERIDX,FILENAME) validates
%   the SYM, CHEST, CFG, and USERIDX inputs and returns the number of
%   unique subcarriers that exist in a subchannel and the total number of
%   80 MHz subblocks. FILENAME is the mfilename that called this
%   function.
%
%   [NSCUNIQUEDEFAULT,NSUBBLOCK80] = validateEqualizeInputs(...,nsc20MHz)
%   also specifies a 1x3 vector that indicates the number of pilot, data,
%   and pilots+data subcarriers in pre- fields.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

% Generate conditional flags
    arguments
        sym
        chEst
        cfg
        field
        userIdx
        filename
        nsc20MHz = [4 52 56] % Default is for HE/EHT
    end
    isRecoveryObject = isa(cfg,"wlanHERecoveryConfig") || isa(cfg,"wlanEHTRecoveryConfig");
    isVHT = isa(cfg,"wlanVHTConfig");
    isMUObject = isa(cfg,"wlanHEMUConfig") || isa(cfg,"wlanEHTMUConfig") || (isVHT && ~isscalar(cfg.NumSpaceTimeStreams));
    isDataField = contains(field,"Data");
    isVHTSIGB = matches(field,"VHT-SIG-B");
    hasSTBCProp = isprop(cfg,"STBC");

    % Check that recovery config object has required properties defined
    if isRecoveryObject
        wlan.internal.mustBeDefined(cfg.ChannelBandwidth,"ChannelBandwidth");
        if isDataField
            wlan.internal.mustBeDefined(cfg.NumSpaceTimeStreams,"NumSpaceTimeStreams");
            if hasSTBCProp % HE-Data Only
                wlan.internal.mustBeDefined(cfg.STBC,"STBC");
            end
        end
    end

    % Get sizes of inputs
    [nSCSym,~,nRxSym] = size(sym);
    [nSCChEst,nSTS,nRxChEst] = size(chEst);

    % Validate first and third dimensions of sym and chEst against each other
    coder.internal.errorIf(nSCSym ~= nSCChEst,"wlan:shared:Unequal1Dim",nSCSym,nSCChEst);
    coder.internal.errorIf(nRxSym ~= nRxChEst,"wlan:shared:Unequal3Dim",nRxSym,nRxChEst);

    % Number of 20 MHz subchannels
    cbw = cfg.ChannelBandwidth;
    [~,numSubchannels] = wlan.internal.cbw2nfft(cbw);

    % Number of unique subcarriers per 20 MHz subchannel and number of 80
    % MHz subblocks
    nSCUniqueDefault = nSCSym/numSubchannels;
    nSubblock80 = ceil(numSubchannels/4);

    % Determine expected number of space time streams
    if ~isDataField && ~isVHTSIGB % Pre- field validation

        % Number of pilots, data, or pilots+data in cbw
        nSCValidation = nsc20MHz.*numSubchannels;

        % Validate sym and chEst dimensions further
        coder.internal.errorIf(~any(nSCSym==nSCValidation),"wlan:shared:InvalidNumSC", ...
                               nSCSym,nSCValidation(1),nSCValidation(2),nSCValidation(3),wlan.internal.cbwStr2Num(cbw));
        stsVal = 1;
    elseif hasSTBCProp && cfg.STBC && ~isVHTSIGB % Data field STS

        % STBC applies only to VHT/HE config objects
        % For STBC combining number of space time streams
        % must be 2 for HE and even for VHT
        if isVHT
            coder.internal.errorIf(~isscalar(cfg.NumSpaceTimeStreams),"wlan:shared:VectorSTSWithSTBC");
            stsVal = cfg.NumSpaceTimeStreams(1); % For codegen
            coder.internal.errorIf(logical(mod(stsVal,2)),"wlan:shared:OddNumSTSWithSTBC");
        else % HE
            stsVal = 2;
        end
    elseif isMUObject % Data field STS

        % Validate userIdx only for MU/VHT config objects
        validateattributes(userIdx,"numeric",{"integer","scalar", ...
                                              "positive"},filename,"USERIDX");
        if isVHT
            stsVecLen = length(cfg.NumSpaceTimeStreams);
            coder.internal.errorIf(userIdx>stsVecLen,"wlan:shared:InvalidUserIdxWithSTS",userIdx,stsVecLen);
            stsVal = sum(cfg.NumSpaceTimeStreams);
        else
            RUInfo = ruInfo(cfg);
            coder.internal.errorIf(userIdx>RUInfo.NumUsers,"wlan:shared:InvalidUserIdx",userIdx,RUInfo.NumUsers);
            stsVal = RUInfo.NumSpaceTimeStreamsPerRU(cfg.User{userIdx}.RUNumber);
        end
    elseif isRecoveryObject && contains(packetFormat(cfg),"MU") % Data field STS
        stsVal = cfg.RUTotalSpaceTimeStreams;
        stsStartIdx = cfg.SpaceTimeStreamStartingIndex;

        % Check MU recovery object values are defined
        wlan.internal.mustBeDefined(stsVal,"RUTotalSpaceTimeStreams");
        wlan.internal.mustBeDefined(stsStartIdx,"SpaceTimeStreamStartingIndex");

        % Cross validate RU STS against number of STS and STS starting index
        numSTS = cfg.NumSpaceTimeStreams;
        minNumSTS = stsStartIdx + numSTS - 1;
        coder.internal.errorIf(minNumSTS>stsVal, ...
                               "wlan:shared:InvalidRecoverySTS",stsStartIdx,numSTS,minNumSTS,stsVal);
    else % Data field STS VHT/HE/EHT SU
        stsVal = cfg.NumSpaceTimeStreams(1); % Indexing for codegen
    end

    % Validate number of space time streams
    coder.internal.errorIf(stsVal~=nSTS,"wlan:shared:InvalidNumSTS","CHEST",nSTS,stsVal);
end
