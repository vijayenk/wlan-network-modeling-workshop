function [trackedSym,cpe,ae] = wlanVHTTrackPilotError(sym,chEst,cfg,field,varargin)
%wlanVHTTrackPilotError VHT waveform pilot error tracking

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    arguments
        sym (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        chEst (:,:,:) {mustBeFloat,mustBeFinite,mustBeNonempty}
        cfg (1,1) {mustBeA(cfg,{'wlanVHTConfig'})}
        field {mustBeTextScalar}
    end
    arguments (Repeating)
        varargin
    end

    fieldVal = validatestring(field,{'L-SIG','VHT-SIG-A','VHT-LTF','VHT-SIG-B','VHT-Data'},mfilename,'FIELD');
    nvpairs = wlan.internal.parseOptionalInputsTrackPilotError(varargin{:});

    % Get sizes of inputs
    [nscSym,nsym,nrxSym] = size(sym);
    [nscChe,nsts,nrxChe] = size(chEst);

    % Validate number of receive antennas of sym and chEst
    coder.internal.errorIf(nrxSym~=nrxChe,'wlan:shared:Unequal3Dim',nrxSym,nrxChe);

    ofdmInfo = wlan.internal.vhtOFDMInfo(fieldVal,cfg.ChannelBandwidth);

    % Check for expected number of tones in sym
    coder.internal.errorIf(ofdmInfo.NumTones~=nscSym,'wlan:pilotTracking:InvalidNumNsc','SYM',ofdmInfo.NumTones,fieldVal);

    % Check for pilot or pilots+data subcarriers in chEst. We don't need to
    % recall ofdmInfo for L-LTF when fieldVal is L-SIG or VHT-SIG-A because
    % numTone and pilotIdxs are the same for these fields
    numPilots = length(ofdmInfo.PilotIndices);
    onlyPilots = numPilots==nscChe;
    coder.internal.errorIf(~(onlyPilots || ofdmInfo.NumTones==nscChe),'wlan:pilotTracking:InvalidChanEst1DPilotTrack','CHANEST',nscChe,ofdmInfo.NumTones,numPilots);

    % Extract only pilot subcarriers if necessary
    if onlyPilots
        chEstPilots = chEst;
    else
        chEstPilots = chEst(ofdmInfo.PilotIndices,:,:);
    end

    % Channel estimate sts validation
    if matches(fieldVal,{'VHT-SIG-B','VHT-Data'})
        expectedNsts = sum(cfg.NumSpaceTimeStreams);
        coder.internal.errorIf(nsts>expectedNsts,'wlan:pilotTracking:Dim2MustBeLessThanOrEqual','CHEST',nsts,expectedNsts);
    else % L-SIG, VHT-SIG-A, VHT-LTF
        expectedNsts = 1;
        if matches(fieldVal,'VHT-LTF')
            maxNSTS = 8;
            maxNumVHTLTFSym = wlan.internal.numVHTLTFSymbols(maxNSTS);
            % Validate 2nd dim of SYM
            coder.internal.errorIf(nsym>maxNumVHTLTFSym,'wlan:pilotTracking:Dim2MustBeLessThanOrEqual','SYM',nsym,maxNumVHTLTFSym);
        end
        coder.internal.errorIf(nsts~=expectedNsts,'wlan:shared:InvalidNumSTS','CHEST',nsts,expectedNsts);
    end

    % Only calculate cpe/ae if requested by the user or if respective
    % NV-pair is true
    sArgs = namedargs2cell(nvpairs); % For codegen
    trackingParams = struct('CalculateCPE',nargout > 1 | nvpairs.TrackPhase, ...
                            'CalculateAE',nargout > 2 | nvpairs.TrackAmplitude,sArgs{:});
    [trackedSym,cpe,ae] = wlan.internal.vhtTrackPilotError(sym,chEstPilots,cfg.ChannelBandwidth,fieldVal,trackingParams);

    % Force cpe to be a row vector
    cpe = cpe(:).';

end
