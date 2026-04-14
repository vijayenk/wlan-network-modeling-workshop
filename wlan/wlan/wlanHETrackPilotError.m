function [y,cpe,ae] = wlanHETrackPilotError(x,chanEst,varargin)
%wlanHETrackPilotError HE waveform pilot error tracking
%
%   [Y,CPE,AE] = wlanHETrackPilotError(X,CHANEST,CFG,FIELDNAME) returns HE
%   pilot-error-tracked OFDM symbols Y. CPE is common phase error per OFDM
%   symbol averaged over all receive antennas. AE is the amplitude error
%   per OFDM symbol and receive antenna.
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
%   receiver pilots per OFDM symbol for each receive antenna.
%
%   X is a complex Nst-by-Nsym-by-Nr array containing the received OFDM
%   symbols. Nst is the number of active subcarriers (data and pilots) for
%   the specified field.
%
%   CHANEST is a complex Nst-by-Nsts-by-Nr array containing the channel
%   estimates, or a complex Nsp-by-Nsts-by-Nr array containing the channel
%   estimates at pilot subcarriers. Nsp is the number of pilot subcarriers,
%   and Nsts is the number of space-time streams. For 'L-SIG' or 'RL-SIG',
%   Nst is equal to the number of subcarriers from L-LTF channel
%   estimation.
%
%   CFG is a format configuration object of type wlanHESUConfig or
%   wlanHERecoveryConfig.
%
%   FIELDNAME is a character vector or string scalar specifying the field
%   of interest. The allowed field names are 'L-SIG', 'RL-SIG', 'HE-SIG-A',
%   'HE-SIG-B', 'HE-LTF', and 'HE-Data'.
%
%   [Y,CPE,AE] = wlanHETrackPilotError(X,CHANEST,CFGMU,FIELDNAME,RUNUMBER)
%   performs pilot tracking for the resource unit (RU) of interest of a
%   multi-user HE format. When FIELDNAME is 'HE-LTF' or 'HE-Data' then the
%   additional RUNUMBER argument is required. RUNUMBER is the number of the
%   RU of interest. For wlanHERecoveryConfig, RUNUMBER is not required.
%
%   CFGMU is a format configuration object of type wlanHEMUConfig.
%
%   [Y,CPE,AE] = wlanHETrackPilotError(X,CHANEST,CHANBW,PREHEFIELD)
%   returns HE pilot-error-tracked OFDM symbols for pre-HE fields.
%
%   CHANBW must be 'CBW20', 'CBW40', 'CBW80', or 'CBW160'.
%
%   PREHEFIELD is one of 'L-SIG','RL-SIG','HE-SIG-A', or 'HE-SIG-B'.
%
%   [Y,CPE,AE] = wlanHETrackPilotError(...,NAME,VALUE) specifies one or
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

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

% Input self-validation
    validateattributes(x,{'single','double'},{'3d','finite'},mfilename,'received OFDM symbols');
    validateattributes(chanEst,{'single','double'},{'3d'},mfilename,'channel estimation');

    [Nst,Nsym,Nr] = size(x);
    [Nstce,Nsts,Nrce] = size(chanEst);

    % Validate the number of receive antennas in x and chanEst
    coder.internal.errorIf(Nr~=Nrce,'wlan:shared:Unequal3Dim',Nr,Nrce);

    if isstring(varargin{1}) || ischar(varargin{1}) % wlanHETrackPilotError(X,CHANEST,CHANBW,FIELDNAME,...)
        narginchk(4,8)
        chanBW = validatestring(varargin{1},{'CBW20','CBW40','CBW80','CBW160'},mfilename,'channel bandwidth');
        fieldName = validatestring(varargin{2},{'L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B'},mfilename,'field name');
        isHEData = false;

        % Validate and parse optional inputs
        recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{3:end});
        [pilotInd,numTones,refPilots,ofdmInfo] = wlan.internal.trackingPreHEOFDMInfo(fieldName,Nsym,chanBW);

    else % wlanHETrackPilotError(X,CHANEST,CFG,FIELDNAME,...)
        narginchk(4,9)
        cfg = varargin{1};
        validateattributes(cfg,{'wlanHESUConfig','wlanHEMUConfig','wlanHERecoveryConfig'},{'scalar'},mfilename,'format configuration object');
        chanBW = cfg.ChannelBandwidth;
        fieldName = validatestring(varargin{2},{'L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B','HE-LTF','HE-Data'},mfilename,'field name');

        % Validate and parse optional inputs
        ruNumber = 1; % Default to 1
        isHEData = strcmp(fieldName,'HE-Data');
        isHELTF = strcmp(fieldName,'HE-LTF');
        isHEfields = isHELTF || isHEData;
        isHEMUConfig = isa(cfg,'wlanHEMUConfig');
        if isHEMUConfig
            if nargin==4 && isHEfields % wlanHETrackPilotError(x,chanEst,cfg,fieldName)
                coder.internal.error('wlan:shared:ExpectedRUNumberHE');
            elseif nargin>4 && isHEfields % wlanHETrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
                validateattributes(varargin{3},{'double'},{'positive','integer','scalar'},mfilename,'RU number');
                ruNumber = varargin{3};
                recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{4:end});
            else % Pre HE fields
                if nargin==4 || nargin>4 && ~isnumeric(varargin{3}) % wlanHETrackPilotError(x,chanEst,cfg,fieldName,N-V)
                    recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{3:end});
                else % wlanHETrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
                    recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{4:end});
                end
            end
        else
            if nargin==4 || nargin>4 && ~isnumeric(varargin{3}) % wlanHETrackPilotError(x,chanEst,cfg,fieldName,N-V)
                recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{3:end});
            else % wlanHETrackPilotError(x,chanEst,cfg,fieldName,ruNumber,N-V)
                recParams = wlan.internal.parseOptionalInputsTrackPilotError(varargin{4:end});
            end
        end

        % Get the packet format
        isHERecoveryConfig = isa(cfg,'wlanHERecoveryConfig');
        if isHERecoveryConfig && any(strcmp(fieldName,{'HE-SIG-B','HE-Data'}))
            % Validate the packetformat for 'HE-SIG-B' and 'HE-Data' fields
            wlan.internal.mustBeDefined(cfg.PacketFormat,'PacketFormat');
            pktFormat = cfg.PacketFormat;
        else % wlanHESUConfig, wlanHEMUConfig, or wlanHERecoveryConfig for 'L-SIG','RL-SIG','HE-SIG-A' and 'HE-LTF' fields
            pktFormat = packetFormat(cfg);
        end

        if isHEfields
            if isHERecoveryConfig
                % Validate channel bandwidth
                wlan.internal.mustBeDefined(cfg.ChannelBandwidth,'CHANBW');
                % Validate RU size and index
                wlan.internal.mustBeDefined(cfg.RUSize,'RUSize');
                wlan.internal.mustBeDefined(cfg.RUIndex,'RUIndex');
                ru = [cfg.RUSize cfg.RUIndex];
                [ruSize,ruIdx] = wlan.internal.validateRUArgument(ru,wlan.internal.cbwStr2Num(chanBW));
                if strcmp(pktFormat,'HE-MU')
                    % HE-SIG-B validation for HE MU
                    validateConfig(cfg,'HESIGB');
                    s = getSIGBLength(cfg);
                    numHESIGB = s.NumSIGBSymbols;
                    wlan.internal.mustBeDefined(cfg.RUTotalSpaceTimeStreams,'RUTotalSpaceTimeStreams');
                    if isHELTF
                        % Validate HELTFType and RUTotalSpaceTimeStreams
                        wlan.internal.mustBeDefined(cfg.HELTFType,'HELTFType');
                    end
                    numSTSRU = cfg.RUTotalSpaceTimeStreams;
                else % SU or EXT SU
                    numHESIGB = 0;
                    wlan.internal.mustBeDefined(cfg.NumSpaceTimeStreams,'NumSpaceTimeStreams');
                    if isHELTF
                        % Validate HELTFType and NumSpaceTimeStreams
                        wlan.internal.mustBeDefined(cfg.HELTFType,'HELTFType');
                    end
                    numSTSRU = cfg.NumSpaceTimeStreams;
                end
            elseif isHEMUConfig
                allocInfo = ruInfo(cfg);
                sigbInfo = wlan.internal.heSIGBCodingInfo(cfg);
                numHESIGB = sigbInfo.NumSymbols;
                % Validate RU number
                wlan.internal.validateRUNumber(ruNumber,allocInfo.NumRUs);
                ruSize = allocInfo.RUSizes(ruNumber);
                ruIdx = allocInfo.RUIndices(ruNumber);
                % Get the max number of STSs for all RUs to return all of phase corrected LTF symbols
                numSTSRU = max(allocInfo.NumSpaceTimeStreamsPerRU);
            else % wlanHESUConfig
                 % SU, EXT SU
                allocInfo = ruInfo(cfg);
                numHESIGB = 0;
                ruIdx = allocInfo.RUIndices;
                ruSize = allocInfo.RUSizes;
                numSTSRU = allocInfo.NumSpaceTimeStreamsPerRU(ruNumber);
            end

            % Indices of data and pilot subcarriers within the occupied RU
            cbw = wlan.internal.cbwStr2Num(chanBW);
            [ruMappingInd,kRUFull] = wlan.internal.heOccupiedSubcarrierIndices(cbw,ruSize,ruIdx);
            ofdmInfo = struct;
            ofdmInfo.NumTones = numel(ruMappingInd.Data) + numel(ruMappingInd.Pilot);
            ofdmInfo.PilotIndices = ruMappingInd.Pilot;
            pilotInd = ofdmInfo.PilotIndices;
            numTones = ofdmInfo.NumTones;

            % Generate reference pilot for HE-LTF and HE-Data fields
            if isHELTF
                numHELTFOFDMSym = wlan.internal.numVHTLTFSymbols(numSTSRU);
                % Validate the second dimension of x
                coder.internal.errorIf(Nsym>numHELTFOFDMSym,'wlan:pilotTracking:Dim2MustBeLessThanOrEqual','X',Nsym,numHELTFOFDMSym);
                [seqHELTF,kHELTF] = wlan.internal.heLTFSequence(cbw,cfg.HELTFType);
                if isHERecoveryConfig
                    kRU = kRUFull;
                else % Discard punctured subcarriers for non-HERecovery configurations
                    kRUPuncture = wlan.internal.hePuncturedRUSubcarrierIndices(cfg);
                    kRU = setdiff(kRUFull,kRUPuncture);
                end
                seqIdx = wlan.internal.intersectRUIndices(kHELTF,kRU);
                seqHELTFRU = seqHELTF(seqIdx);
                Pheltf = wlan.internal.mappingMatrix(numSTSRU);
                % Derive B mapping matrix from P mapping matrix
                % E.Prahia etc, Next Generation Wireless LANs 802.11n and 802.11ac, Page 198, Eq 7.26 and 7.27
                Bheltf = Pheltf(1,1:Nsym);
                refPilots = seqHELTFRU(ruMappingInd.Pilot).*Bheltf;
            else % HE-Data
                n = (0:Nsym-1);
                if strcmp(pktFormat,'HE-EXT-SU')
                    numHESIGA = 4;
                else % SU
                    numHESIGA = 2;
                end
                z = 2 + numHESIGA + numHESIGB;
                % Get the number of space-time streams
                numSpaceTimeStreams = Nsts;
                refPilots = wlan.internal.hePilots(ruSize,numSpaceTimeStreams,n,z);
            end
        else % Pre-HE fields
            if strcmp(fieldName,'HE-SIG-B') && ~strcmp(pktFormat,'HE-MU')
                % HE-SIG-B is only valid for wlanHEMUConfig and wlanHERecoveryConfig (HE MU format)
                coder.internal.error('wlan:wlanHETrackPilotError:InvalidFieldHESIGB');
            end
            [pilotInd,numTones,refPilots,ofdmInfo] = wlan.internal.trackingPreHEOFDMInfo(fieldName,Nsym,chanBW);
        end
    end

    % Validate the first dimension of x
    coder.internal.errorIf(ofdmInfo.NumTones~=Nst,'wlan:pilotTracking:InvalidNumNsc','X',ofdmInfo.NumTones,fieldName);

    % Validate the first dimension of chanEst
    coder.internal.errorIf(~(numel(pilotInd)==Nstce || numTones==Nstce),'wlan:pilotTracking:InvalidChanEst1DPilotTrack','CHANEST',Nstce,numTones,numel(pilotInd));

    % Validate the second dimension of chanEst
    if isHEData
        coder.assumeDefined(numSTSRU)
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

    % Extract the used pilot subcarriers if NaN exist in chanEst 
    [chanEstPilots,refPilots,ofdmInfo] = wlan.internal.extractUsedPilots(chanEstPilots,refPilots,ofdmInfo);
    estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilots,refPilots);

    % Estimate CPE and AE
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
