function [y,cpe,ae] = wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,varargin)
%wlanEHTTrackPilotError EHT waveform pilot error tracking
%   [Y,CPE,AE] = wlanEHTTrackPilotError(X,CHANEST,CFG,FIELDNAME) returns
%   EHT pilot-error-tracked OFDM symbols Y. CPE is the common phase error
%   per OFDM symbol averaged over all receive antennas. AE is the amplitude
%   error per OFDM symbol and receive antenna.
%
%   Y is a complex Nst-by-Nsym-by-Nr array containing the pilot-tracked
%   OFDM symbols. Nst is the number of occupied subcarriers, Nsym is the
%   number of symbols, and Nr is the number of receive antennas.
%
%   CPE is a real 1-by-Nsym vector containing the common phase error per
%   OFDM symbol averaged over receive antennas.
%
%   AE is a real 1-by-Nsym-by-Nr array containing the average amplitude
%   error for all subcarriers, in dB, with respect to the estimated
%   received pilots per OFDM symbol for each receive antenna.
%
%   X is a complex Nst-by-Nsym-by-Nr array containing the received OFDM
%   symbols. Nst is the number of active subcarriers (data and pilots).
%
%   CHANEST is a complex Nst-by-Nsts-by-Nr array containing the channel
%   gains for all active subcarriers, or a Nsp-by-Nsts-by-Nr array
%   containing the channel gains for only pilot subcarriers. Nsts is the
%   number of space-time streams and Nsp is the number of pilot
%   subcarriers.
%
%   CFG is a format configuration object of type wlanEHTMUConfig or
%   wlanEHTRecoveryConfig.
%
%   [Y,CPE,AE] = wlanEHTTrackPilotError(X,CHANEST,CFG,FIELDNAME,RUNUMBER)
%   performs pilot tracking for the resource unit (RU) of interest of an
%   EHT MU, OFDMA PPDU type of IEEE P802.11be/D5.0. For an OFDMA PPDU type,
%   when FIELDNAME is 'EHT-LTF' or 'EHT-Data' then the additional RUNUMBER
%   argument is required. RUNUMBER is the number of the RU of interest. For
%   wlanEHTRecoveryConfig, RUNUMBER is not required.
%
%   When FIELDNAME is 'EHT-LTF' or 'EHT-Data' and PPDU type is non-OFDMA
%   then the additional RUNUMBER argument is not required and is assumed to
%   be one.
%
%   When FIELDNAME is 'L-SIG', 'RL-SIG', 'U-SIG', or 'EHT-SIG' then the
%   additional RUNUMBER argument is not required and is assumed to be one.
%
%   [Y,CPE,AE] = wlanEHTTrackPilotError(...,NAME,VALUE) specifies one or
%   both of these name-value arguments.
%
%   'TrackPhase'         Perform pilot phase tracking, specified as true or
%                        false. To estimate and correct a common phase
%                        offset across all subcarriers and receive antennas
%                        for each OFDM symbol before equalization, set this
%                        property to true. Otherwise, set this property to
%                        false. The default is true.
%
%   'TrackAmplitude'     Perform pilot amplitude tracking, specified as
%                        true or false. To estimate and correct an
%                        amplitude error across all subcarriers for each
%                        OFDM symbol and each receiver antenna before
%                        equalization, set this property to true.
%                        Otherwise, set this property to false. The default
%                        is false. Due to the limitations of the algorithm
%                        used, disable pilot amplitude tracking when
%                        filtering a waveform through a MIMO fading
%                        channel.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(4,9)
    validateattributes(x,{'single','double'},{'3d','finite'},mfilename,'received OFDM symbols');
    validateattributes(chanEst,{'single','double'},{'3d','finite'},mfilename,'channel estimation');
    validateattributes(cfg,{'wlanEHTMUConfig','wlanEHTRecoveryConfig'},{'scalar'},mfilename,'format configuration object');
    fieldName = validatestring(fieldName,{'EHT-Data','EHT-LTF','EHT-SIG','U-SIG','RL-SIG','L-SIG'},mfilename,'field');

    [Nst,Nsym,Nr] = size(x);
    [Nstce,Nsts,Nrce] = size(chanEst);

    isEHTData = strcmp(fieldName,'EHT-Data');
    isEHTLTF = strcmp(fieldName,'EHT-LTF');
    isEHTfields = isEHTLTF || isEHTData;
    isEHTMUConfig = isa(cfg,'wlanEHTMUConfig');

    % Validate the number of receive antennas in x and chanEst
    coder.internal.errorIf(Nr~=Nrce,'wlan:shared:Unequal3Dim',Nr,Nrce);

    if isEHTMUConfig
        mode = compressionMode(cfg); % Get PPDU type and compression mode
        if (any(mode==[1 2]) && cfg.UplinkIndication==0) || (any(mode==[0 1]) && cfg.UplinkIndication==1)  % Single user: DL(EHT MU) or UL(EHT TB and EHT MU)
            if nargin>4 && isnumeric(varargin{1}) % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
                numArgPreNV = 2;
                recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
            else % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,N-V)
                numArgPreNV = 1;
                recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
            end
            ruNumber = 1;
        else % OFDMA
            if (nargin==4 && isEHTfields) || (nargin>4 && isEHTfields && ~isnumeric(varargin{1})) % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName) or wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,N-V)
                coder.internal.error('wlan:shared:ExpectedRUNumberEHT');
            elseif nargin>4 && isEHTfields % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
                wlan.internal.validateRUNumber(varargin{1},numel(cfg.RU));
                ruNumber = varargin{1};
                numArgPreNV = 2;
                recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
            else % Pre EHT fields
                if nargin==4 || nargin>4 && ~isnumeric(varargin{1})
                    numArgPreNV = 1; % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,N-V)
                    recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
                else
                    numArgPreNV = 2; % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
                    recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
                end
                ruNumber = 1;
            end
        end
    else % EHT Recovery
         % Validate the channel bandwidth
        wlan.internal.mustBeDefined(cfg.ChannelBandwidth,'ChannelBandwidth');
        if isEHTfields
            % Validate the relevant properties for EHT-LTF or EHT-Data field
            wlan.internal.mustBeDefined(cfg.NumEHTSIGSymbolsSignaled,'NumEHTSIGSymbolsSignaled');
            wlan.internal.mustBeDefined(cfg.RUSize,'RUSize');
            wlan.internal.mustBeDefined(cfg.RUIndex,'RUIndex');
            wlan.internal.mustBeDefined(cfg.EHTLTFType,'EHTLTFType');
            wlan.internal.mustBeDefined(cfg.NumSpaceTimeStreams,'NumSpaceTimeStreams');
            wlan.internal.mustBeDefined(cfg.RUTotalSpaceTimeStreams,'RUTotalSpaceTimeStreams');
        end
        if nargin==4 || nargin>4 && ~isnumeric(varargin{1})
            numArgPreNV = 1; % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,N-V)
            recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
        else
            numArgPreNV = 2; % wlanEHTTrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
            recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{numArgPreNV:end});
        end
        ruNumber = 1;
    end

    if isEHTfields
        if isEHTMUConfig
            allocInfo = ruInfo(cfg);
            ehtsigInfo = wlan.internal.ehtSIGCodingInfo(cfg);
            numEHTSIG = ehtsigInfo.NumSIGSymbols;
            ruSize = allocInfo.RUSizes{ruNumber};
            ruIdx = allocInfo.RUIndices{ruNumber};
            % Get the max number of STSs for all RUs to return all of phase corrected LTF symbols
            numSTSRU = max(allocInfo.NumSpaceTimeStreamsPerRU);
            numExtraEHTLTFSymbols = cfg.NumExtraEHTLTFSymbols;
        else % wlanEHTRecoveryConfig
            numEHTSIG = cfg.NumEHTSIGSymbolsSignaled;
            ruSize = cfg.RUSize;
            ruIdx = cfg.RUIndex;
            numSTSRU = cfg.RUTotalSpaceTimeStreams;
            numExtraEHTLTFSymbols = 0;
        end

        % Indices of data and pilot subcarriers within the occupied RU
        cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
        ruMappingInd = wlan.internal.ehtOccupiedSubcarrierIndices(cbw,ruSize,ruIdx);
        ofdmInfo = struct;
        ofdmInfo.NumTones = numel(ruMappingInd.Data) + numel(ruMappingInd.Pilot);
        ofdmInfo.PilotIndices = ruMappingInd.Pilot;
        pilotInd = ofdmInfo.PilotIndices;
        numTones = ofdmInfo.NumTones;

        % Generate reference pilot for EHT-LTF and EHT-Data fields
        if isEHTLTF
            numEHTLTFOFDMSym = wlan.internal.numVHTLTFSymbols(numSTSRU)+numExtraEHTLTFSymbols;
            % Validate the second dimension of x
            coder.internal.errorIf(Nsym>numEHTLTFOFDMSym,'wlan:pilotTracking:Dim2MustBeLessThanOrEqual','X',Nsym,numEHTLTFOFDMSym);
            seqEHTLTF = wlan.internal.ehtLTFSequence(cbw,cfg.EHTLTFType);
            Pheltf = wlan.internal.mappingMatrix(8); % Get the mapping matrix for max number of space-time streams
                                                     % Derive B mapping matrix from P mapping matrix
                                                     % E.Prahia etc, Next Generation Wireless LANs 802.11n and 802.11ac, Page 198, Eq 7.26 and 7.27
            Bheltf = Pheltf(1,1:Nsym);
            refPilots = seqEHTLTF(ruMappingInd.Pilot).*Bheltf;
        else % EHT-Data
            n = (0:Nsym-1);
            numUSIG = 2;
            z = 2 + numUSIG + numEHTSIG;
            % Get the number of space-time streams
            numSpaceTimeStreams = Nsts;
            refPilots = wlan.internal.ehtPilots(ruSize,numSpaceTimeStreams,n,z);
        end
    else % Pre EHT fields
        [pilotInd,numTones,refPilots,ofdmInfo] = wlan.internal.trackingPreHEOFDMInfo(fieldName,Nsym,cfg.ChannelBandwidth);
    end

    % Validate the first dimension of x
    coder.internal.errorIf(ofdmInfo.NumTones~=Nst,'wlan:pilotTracking:InvalidNumNsc','X',ofdmInfo.NumTones,fieldName);

    % Validate the first dimension of chanEst
    coder.internal.errorIf(~(numel(pilotInd)==Nstce || numTones==Nstce),'wlan:pilotTracking:InvalidChanEst1DPilotTrack','CHANEST',Nstce,numTones,numel(pilotInd));

    % Validate the second dimension of chanEst
    if isEHTData
        coder.assumeDefined(numSTSRU);
        expectedNsts = numSTSRU;
        coder.internal.errorIf(Nsts>expectedNsts,'wlan:pilotTracking:Dim2MustBeLessThanOrEqual','CHANEST',Nsts,expectedNsts);
    else
        expectedNsts = 1;
        coder.internal.errorIf(Nsts~=expectedNsts,'wlan:shared:InvalidNumSTS','CHANEST',Nsts,expectedNsts);
    end


    if numel(pilotInd)==Nstce
        % Assume channel estimate is only for pilots
        chanEstPilots = chanEst;
    else
        % Otherwise extract pilots from channel estimate
        chanEstPilots = chanEst(pilotInd,:,:);
    end

    % Estimate CPE and AE
    estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilots,refPilots);
    cpe = wlan.internal.commonPhaseErrorEstimate(x(ofdmInfo.PilotIndices,:,:),estRxPilots);
    aeEstimate = wlan.internal.amplitudeErrorEstimate(x(ofdmInfo.PilotIndices,:,:),estRxPilots);
    ae = 20*log10(aeEstimate); % Transform AE from linear to logarithmic scale

    % Perform pilot tracking
    y = x;
    if recParams.TrackPhase
        y = wlan.internal.commonPhaseErrorCorrect(y,cpe);
    end
    if recParams.TrackAmplitude
        y = wlan.internal.amplitudeErrorCorrect(y,aeEstimate);
    end
end
