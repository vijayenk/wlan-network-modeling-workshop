classdef WaveformAnalyzer < wirelessWaveformAnalyzer.internal.WaveformAnalysisEngine
    %WaveformAnalyzer Detect, decode and analyze WLAN packets within a waveform
    %
    %   Note: This is an internal undocumented function and its API and/or
    %   functionality may change in subsequent releases.
    %
    %   ANALYZER = WaveformAnalyzer creates a WLAN waveform analyzer. The
    %   waveform analyzer detects and analyze multiple WLAN packets within a
    %   waveform.
    %
    %   ANALYZER = WaveformAnalyzer(Name,Value) creates a WLAN waveform
    %   analyzer with the specified property Name set to the specified Value.
    %   You can specify additional name-value pair arguments in any order as
    %   (Name1,Value1, ...,NameN,ValueN).
    %
    %   WaveformAnalyzer properties:
    %
    %   DCBlocking                    - Enable DC blocking
    %   PilotTimeTracking             - Data field pilot time (sample rate offset) tracking
    %   PilotPhaseTracking            - Data field pilot phase (carrier frequency offset) tracking
    %   PilotGainTracking             - Data field pilot gain tracking
    %   DataAidedEqualization         - Equalization using data-aided channel estimates
    %   IQImbalanceCorrection         - Data field IQ imbalance correction
    %   EqualizationMethod            - Data field symbols equalization method
    %
    %   WaveformAnalyzer methods:
    %
    %   process              - Detect, decode and analyze WLAN packets within a waveform
    %   detectionSummary     - Display the summary of detected packets
    %   plotWaveform         - Plot time domain samples and signal spectrum of the selected packet
    %   fieldSummary         - Display field summary of the selected packet
    %   signalingSummary     - Display signaling field summary of the selected packet
    %   ruSummary            - Display resource unit summary of the selected packet
    %   userSummary          - Display user summary of the selected packet
    %   userEVM              - Display EVM per spatial stream for all users of the selected packet
    %   plotConstellation    - Plot equalized data field symbols for each user of the selected packet
    %   plotSubcarrierEVM    - Plot EVM per subcarrier and data field symbols of the selected packet
    %   plotSymbolEVM        - Plot EVM per data field symbols of the selected packet
    %   plotSpectralFlatness - Plot spectral flatness of the selected packet
    %   getResults           - Returns analysis results

    %   Copyright 2023-2025 The MathWorks, Inc.

    properties (Access=private)
        Results;
    end

    properties (Hidden)
        DisablePlots (1,1) logical = false;
    end

    methods
        function obj = WaveformAnalyzer(varargin)
            obj = obj@wirelessWaveformAnalyzer.internal.WaveformAnalysisEngine(varargin{:});
        end

        function [T, detectionInfo, x] = detectionSummary(obj)
            %detectionSummary Display the summary of detected packets
            %
            %   detectionSummary(ANALYZER) displays the summary of detected
            %   packets.
            %
            %   The table contains the following columns:
            %
            %   Format          Specifies the detected format of the packet
            %                   as one of: Non-HT, HT-MF, HT-GF, VHT, HE-SU,
            %                   HE-EXT-SU, HE-MU, and HE-TB.
            %
            %   PHY Status      Specifies the PHY recovery status of the
            %                   packet. If a PSDU is recovered the status
            %                   is Success. Otherwise, status is one of:
            %                   * Incomplete packet
            %                   * Unsupported format - Format other than HE,
            %                     VHT, HT-MF, HT-GF or Non-HT detected
            %                   * HE midamble not supported
            %                   * L-SIG check fail
            %                   * HT-SIG CRC fail
            %                   * Invalid HT-SIG contents - CRC passed but
            %                     contents invalid
            %                   * VHT-SIG-A CRC fail
            %                   * Invalid VHT-SIG-A contents - CRC passed but
            %                     contents invalid
            %                   * HE-SIG-A FailCRC
            %                   * Invalid HE-SIG-A contents - CRC passed but
            %                     contents invalid
            %                   * HE-SIG-B Common Fail
            %                   * HE-SIG-B User Fail
            %                   * Unexpected channel bandwidth decoded - The
            %                     decoded channel bandwidth does not match the
            %                     channel bandwidth provided by the user
            %                     therefore the packet cannot be recovered
            %
            %   Power           Power of the detected packet in dBm.
            %
            %   CFO             Carrier frequency offset in hertz.
            %
            %   RMS EVM         RMS EVM in dBs of the data field average over
            %                   all space-time streams and users.
            %
            %   Max EVM         Max EVM in dBs of the data field across all
            %                   space-time streams and users.
            %
            %   T = detectionSummary(ANALYZER) returns the summary of the
            %   detected packet in a table.

            checkWaveformProcessed(obj);
            x = obj.Results;

            if (~isempty(x))
                numPkt = numel(x);
                if(numPkt > 1)  % Single packet for v1
                    numPkt = 1;
                end
                pktFormat = strings(numPkt,1);
                pktStatus = strings(numPkt,1);
                pktPower = zeros(numPkt,1);
                cfo = zeros(numPkt,1);
                pktOffset = zeros(numPkt,1);
                mpduType = strings(numPkt,1);
                iqGainImbalance = zeros(numPkt,1);
                iqPhaseImbalance = zeros(numPkt,1);
                combineEVMRMS = [];
                combineEVMMax = [];
                for nPkt = 1:numPkt
                    pktFormat(nPkt) = x{nPkt}.Format;
                    pktStatus(nPkt) = x{nPkt}.Status;
                    pktPower(nPkt) = powerdBm(x{nPkt}.PacketPower);
                    cfo(nPkt) = x{nPkt}.Preamble.CFOEstimate;
                    pktOffset(nPkt) = x{nPkt}.PacketOffset;
                    mpduType(nPkt) = x{nPkt}.PacketContents;
                    % Extract EVM of the data field
                    evmRMS = nan; % For NDP packets
                    evmMax = nan;
                    if any(strcmp(pktFormat(nPkt),{'EHT-MU'})) && x{nPkt}.EHTData.Processed
                        [evmRMS,evmMax] = getPacketEVM(x{nPkt}.EHTData.User);
                    elseif any(strcmp(pktFormat(nPkt),{'HE-SU','HE-MU','HE-EXT-SU'})) && x{nPkt}.HEData.Processed
                        [evmRMS,evmMax] = getPacketEVM(x{nPkt}.HEData.User);
                    elseif strcmp(pktFormat(nPkt),'VHT') && x{nPkt}.VHTData.Processed
                        [evmRMS,evmMax] = getPacketEVM(x{nPkt}.VHTData.User);
                    elseif strcmp(pktFormat(nPkt),'HT-MF') && x{nPkt}.HTData.Processed
                        [evmRMS,evmMax] = getPacketEVM(x{nPkt}.HTData);
                    elseif strcmp(pktFormat(nPkt),'Non-HT') && x{nPkt}.NonHTData.Processed
                        [evmRMS,evmMax] = getPacketEVM(x{nPkt}.NonHTData);
                    end
                    if strcmp(pktFormat(nPkt),{'EHT-MU'}) && obj.IQImbalanceCorrection
						% Display IQ imbalance estimates only for EHT-MU
						% format, and only when IQ imbalance
						% correction is enabled.
                        iqGainImbalance(nPkt) = round(x{nPkt}.IQImbalance(1),4);
                        iqPhaseImbalance(nPkt) = round(x{nPkt}.IQImbalance(2),4);
                    else
                        iqGainImbalance(nPkt) = NaN;
                        iqPhaseImbalance(nPkt) = NaN;
                    end
                    combineEVMRMS = [combineEVMRMS; evmRMS]; % Average over all users
                    combineEVMMax = [combineEVMMax; evmMax]; % Max EVM between space-time streams of all users
                end

                if isempty(pktFormat)
                    T = [];
                    detectionInfo = [];
                    return;
                end
                detSummary = table(pktFormat,pktStatus,pktPower,cfo,iqGainImbalance,iqPhaseImbalance,combineEVMRMS,combineEVMMax);
                detSummary.Properties.VariableNames{1} = 'Format';
                detSummary.Properties.VariableNames{2} = 'PHY Status';
                detSummary.Properties.VariableNames{3} = 'Power (dBm)';
                detSummary.Properties.VariableNames{4} = 'CFO (Hz)';
                detSummary.Properties.VariableNames{5} = 'IQ Gain Imbalance (dB)';
                detSummary.Properties.VariableNames{6} = 'IQ Phase Imbalance (deg)';
                detSummary.Properties.VariableNames{7} = 'RMS EVM (dB)';
                detSummary.Properties.VariableNames{8} = 'Max EVM (dB)';

                detectionInfo = struct;
                detectionInfo.Format = char(pktFormat);
                detectionInfo.PHYStatus = char(pktStatus);
                if(~isnan(pktPower))
                    detectionInfo.Power_dBm = pktPower;
                end
                detectionInfo.CFO_Hz = cfo;
                if strcmp(pktFormat(nPkt),{'EHT-MU'}) && obj.IQImbalanceCorrection
                    detectionInfo.IQGainImbalance_dB = iqGainImbalance;
                    detectionInfo.IQPhaseImbalance_deg = iqPhaseImbalance;
                end
                if(~isnan(combineEVMRMS))
                    detectionInfo.RMSEVM_dB = combineEVMRMS;
                end
                if(~isnan(combineEVMMax))
                    detectionInfo.MAXEVM_dB = combineEVMMax;
                end
            else
                pktStatus = "No packet(s) detected";
                detSummary = table(pktStatus);
                detSummary.Properties.VariableNames{1} = 'PHY Status';
                detectionInfo = struct;
                detectionInfo.PHYStatus = char(pktStatus);
            end

            if nargout
                T = detSummary;
            end
        end

        function [T,fieldInfo] = fieldSummary(obj,pktNum)
            %fieldSummary Display field summary of the selected packet
            %
            %   fieldSummary(ANALYZER,PKTNUM) displays the field summary of the
            %   selected packet, PKTNUM.
            %
            %   The table contains the following columns:
            %
            %   Field Name            Field names for an HE-MU packet as
            %                         one of L-STF, L-LTF, L-SIG, RL-SIG,
            %                         HE-SIG-A, HE-SIG-B, HE-STF, HE-LTF and
            %                         Data. The HE-SIG-B field is hidden for
            %                         HE-SU and HE-EXT-SU packet formats. Field
            %                         names for an VHT packet as one of L-STF,
            %                         L-LTF, L-SIG, VHT-SIG-A, VHT-STF,
            %                         VHT-LTF, VHT-SIG-B and Data. Field names
            %                         for an HT-MF packet as one of L-STF,
            %                         L-LTF, L-SIG, HT-SIG, HT-STF, HT-LTF and
            %                         Data. For Non-HT packet format only
            %                         L-STF, L-LTF, L-SIG and Data fields are
            %                         displayed.
            %
            %   Modulation            The modulation type of all fields for the
            %                         selected packet.
            %
            %   MCS                   Modulation and coding scheme. This column
            %                         is only displayed for Non-HT packet
            %                         format.
            %
            %   Num Symbols           The number of OFDM symbols within each
            %                         packet field.
            %
            %   Parity Check/CRC      Parity/CRC information.
            %
            %   Power                 Power of each field in dBm.
            %
            %   RMS EVM               RMS EVM in dBs of the signaling and the
            %                         data field. The RMS EVM for the data
            %                         field is averaged over the space-time
            %                         streams for all users.
            %
            %   Max EVM               Max EVM in dBs of the signaling and the
            %                         data field. The Max EVM for the data
            %                         field is maximum across all space-time
            %                         streams between all users.
            %
            %   T = fieldSummary(ANALYZER,PKTNUM) returns the field
            %   summary of the selected packet in a table.

            if isempty(obj.Results)
                T = [];
                fieldInfo = [];
                return;
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};

            if x.LSIG.FailCheck || any(strcmp(x.Status,{'Unsupported format','Incomplete packet','Non-HT duplicate not supported'}))
                T = [];
                fieldInfo = [];
                return;
            end
            if strcmp(x.Format,'Non-HT')
                fieldName =  {'L-STF'; 'L-LTF'; 'L-SIG'; 'Data'};
                mod = getNonHTRateDependentParameters(x.PHYConfig.MCS);
                modType = {'BPSK'; 'BPSK'; 'BPSK'; mod};

                % Power
                power = n2str(powerdBm([x.Preamble.LSTFPower; x.Preamble.LLTFPower; x.LSIG.Power; x.NonHTData.Power]));
                lsigParity = [repmat('    ',2,1); 'Pass'; '    '];
                mcs = [repmat(' ',3,1); num2str(x.PHYConfig.MCS,1)];

                rmsEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMRMS; x.NonHTData.EVMRMS])];
                maxEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMMax; x.NonHTData.EVMMax])];

                cfg = x.PHYConfig;
                s = cfg.validateConfig;
                numDataSymbols = s.NumDataSymbols;
                numSymbols = num2str([2; 2; 1; numDataSymbols]);
            elseif strcmp(x.Format,'HT-MF')
                % CRC HT-SIG field
                if x.HTSIG.FailCRC
                    return; % Do not process any further
                end
                fieldName = {'L-STF'; 'L-LTF'; 'L-SIG'; 'HT-SIG'; 'HT-STF'; 'HT-LTF'; 'Data'};
                modType = {'BPSK'; 'BPSK'; 'BPSK'; 'QBPSK'; 'BPSK'; 'BPSK'; '          '};
                cfgRx = x.PHYConfig(1);
                if x.HTData.Processed % Update only for non NDP
                    % Modulation type is same for MCS 0:7, 8:15, 16:23, and
                    % 17:31. Limit MCS to 0:7 for MCS greater than 8.
                    mcs = rem(cfgRx.MCS,8);
                    mod = getHERateDependentParameters(mcs);
                    modType = {'BPSK'; 'BPSK'; 'BPSK'; 'QBPSK'; 'BPSK'; 'BPSK';mod};
                end

                s = validateConfig(cfgRx,'MCS');
                numSymbols = num2str([2; 2; 1; 2; 1; wlan.internal.numVHTLTFSymbols(sum(cfgRx.NumSpaceTimeStreams)); s.NumDataSymbols]);

                % CRC HT-SIG fields
                crcSIG = [repmat('    ',2,1); 'Pass'; 'Pass'; repmat('    ',3,1)];

                power = [n2str(powerdBm([x.Preamble.LSTFPower; x.Preamble.LLTFPower; x.LSIG.Power; x.HTSIG.Power])); repmat('       ',3,1)];

                if x.HTPreamble.Processed
                    power(5:6,:) = n2str(powerdBm([x.HTPreamble.HTSTFPower x.HTPreamble.HTLTFPower]));
                end

                % EVM
                rmsEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMRMS; x.HTSIG.EVMRMS]); repmat('       ',3,1)];
                maxEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMMax; x.HTSIG.EVMMax]); repmat('       ',3,1)];

                if x.HTData.Processed
                    power(7,:) = n2str(powerdBm(x.HTData.Power));
                    [dataRMSEVM,dataMAXEVM] = getPacketEVM(x.HTData);
                    rmsEVM(7,:) = n2str(dataRMSEVM);
                    maxEVM(7,:) = n2str(dataMAXEVM);
                end
            elseif strcmp(x.Format,'VHT')
                % CRC VHT-SIG-A
                if x.VHTSIGA.FailCRC
                    return; % Do not process any further
                end
                % fieldName = ['L-STF    '; 'L-LTF    '; 'L-SIG    '; 'VHT-SIG-A'; 'VHT-STF  '; 'VHT-LTF  '; 'VHT-SIG-B'; 'Data     '];
                % modType = ['BPSK      '; 'BPSK      '; 'BPSK      '; 'BPSK/QBPSK'; 'BPSK      '; 'BPSK      '; 'BPSK      '; '          '];

                fieldName = {'L-STF'; 'L-LTF'; 'L-SIG'; 'VHT-SIG-A'; 'VHT-STF'; 'VHT-LTF'; 'VHT-SIG-B'; 'Data'};
                modType = {'BPSK'; 'BPSK'; 'BPSK'; 'BPSK/QBPSK'; 'BPSK'; 'BPSK'; 'BPSK'; '          '};

                cfgRx = x.VHTSIGA.PHYConfig;
                numUsers = cfgRx.NumUsers;
                if numUsers==1 && x.VHTData.Processed
                    % Update only for non NDP
                    mod = getHERateDependentParameters(cfgRx.MCS);
                    modType = {'BPSK'; 'BPSK'; 'BPSK'; 'BPSK/QBPSK'; 'BPSK'; 'BPSK'; 'BPSK'; mod};
                end
                numSymbols = num2str([2; 2; 1; 2; 1; wlan.internal.numVHTLTFSymbols(sum(cfgRx.NumSpaceTimeStreams)); 1; x.VHTSIGA.NumDataSym]);

                % CRC VHT-SIG fields
                crcSIG = [repmat('    ',2,1); 'Pass'; 'Pass'; repmat('    ',2,1); repmat('    ',2,1);];

                power = [n2str(powerdBm([x.Preamble.LSTFPower; x.Preamble.LLTFPower; x.LSIG.Power; x.VHTSIGA.Power])); repmat('       ',4,1)];

                % EVM for LSIG and VHT-SIG-A field
                rmsEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMRMS; x.VHTSIGA.EVMRMS]); repmat('       ',4,1)];
                maxEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMMax; x.VHTSIGA.EVMMax]); repmat('       ',4,1)];

                if x.VHTPreamble.Processed && x.VHTSIGB.Processed
                    power(5:7,:) = n2str(powerdBm([x.VHTPreamble.VHTSTFPower x.VHTPreamble.VHTLTFPower x.VHTSIGB.Power]));
                    % EVM for the data and SIGB field, averaged over all space-time streams and users
                    [sigbRMSEVM,sigbMAXEVM] = getPacketEVM(x.VHTSIGB.User); % VHT SIG-B field
                    rmsEVM(7,:) = n2str(sigbRMSEVM);
                    maxEVM(7,:) = n2str(sigbMAXEVM);
                elseif x.VHTPreamble.Processed
                    power(5:6,:) = n2str(powerdBm([x.VHTPreamble.VHTSTFPower x.VHTPreamble.VHTLTFPower]));
                end

                if x.VHTData.Processed
                    crcSIG(7,:) = 'Pass'; % Set CRC for SIGB field
                    if x.VHTData.User(1).FailSIGBCRC % CRC is same for all users
                        crcSIG(7,:) = 'Fail';
                    end
                    power(8,:) = n2str(powerdBm(x.VHTData.Power));

                    [dataRMSEVM,dataMAXEVM] = getPacketEVM(x.VHTData.User); % VHT data field
                    rmsEVM(8,:) = n2str(dataRMSEVM);
                    maxEVM(8,:) = n2str(dataMAXEVM);
                end
            elseif strcmp(x.Format,'EHT-MU')
                if x.USIG.FailCRC
                    return; % Do not process any further
                end
                fieldName = {'L-STF'; 'L-LTF'; 'L-SIG'; 'RL-SIG'; 'U-SIG'; 'EHT-SIG'; 'EHT-STF'; 'EHT-LTF'; 'Data'};
                modType = {'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; '          '};

                % Get number of data symbols from the recover object
                cfgRx = x.PHYConfig(1);
                if cfgRx.PPDUType==wlan.type.EHTPPDUType.ndp
                    if x.EHTSIG.Processed % If EHT-SIG field is successfully processed only then display the relevant information
                        numSymbols = [num2str([2; 2; 1; 1; 2; cfgRx.NumEHTSIGSymbolsSignaled; 1; cfgRx.NumEHTLTFSymbols]); ' '];
                    else
                        numSymbols = [num2str([2; 2; 1; 1; 2]); ' '; ' '; ' '; ' '];
                    end
                else
                    if cfgRx.PPDUType==wlan.type.EHTPPDUType.su
                        modType = [modType(1:8,:); '          '];
                        if x.EHTSIG.User.Processed
                            modType = [modType(1:8,:); getHERateDependentParameters(x.PHYConfig.MCS)];
                        end
                    end

                    s = validateConfig(cfgRx,'DataLocationLength'); % Same for all users
                    if x.EHTSIG.User.Processed % If user field is successfully processed only then display the relevant information
                        numSymbols = num2str([2; 2; 1; 1; 2; cfgRx.NumEHTSIGSymbolsSignaled; 1; cfgRx.NumEHTLTFSymbols; s.NumDataSymbols]);
                    else
                        numSymbols = [num2str([2; 2; 1; 1; 2]); ' '; ' '; ' '; ' '];
                    end
                end

                power = [n2str(powerdBm([x.Preamble.LSTFPower; x.Preamble.LLTFPower; x.LSIG.Power; x.RLSIG.Power; x.USIG.Power])); repmat('       ',4,1)];
                crcSIG = [repmat('    ',2,1); 'Pass'; 'Pass'; 'Pass'; 'Fail'; repmat('    ',3,1)];

                % EVM
                rmsEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMRMS; x.RLSIG.EVMRMS; x.USIG.EVMRMS]); repmat('       ',4,1)];
                maxEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMMax; x.RLSIG.EVMMax; x.USIG.EVMMax]); repmat('       ',4,1)];

                if x.EHTSIG.User.Processed
                    % Show power and EVMs if the EHT-SIG user field has been processed
                    power(6,:) = n2str(powerdBm(x.EHTSIG.Power));
                    rmsEVM(6,:) = n2str(x.EHTSIG.EVMRMS);
                    maxEVM(6,:) = n2str(x.EHTSIG.EVMMax);
                end

                if x.EHTSIG.Processed
                    crcSIG(6,:) = 'Pass';
                end

                if x.EHTPreamble.Processed
                    power(7:8,:) = n2str(powerdBm([x.EHTPreamble.EHTSTFPower; x.EHTPreamble.EHTLTFPower]));
                end

                if x.EHTData.Processed
                    [dataRMSEVM,dataMAXEVM] = getPacketEVM(x.EHTData.User); % EHT data field
                    power(9,:) = n2str(powerdBm(x.EHTData.Power));
                    rmsEVM(9,:) = n2str(dataRMSEVM);
                    maxEVM(9,:) = n2str(dataMAXEVM);
                end
            else % HE SU, HE MU
                % CRC HE-SIG-A
                if x.HESIGA.FailCRC
                    return; % Do not process any further
                end
                % fieldName = ['L-STF   '; 'L-LTF   '; 'L-SIG   '; 'RL-SIG  '; 'HE-SIG-A'; 'HE-SIG-B'; 'HE-STF  '; 'HE-LTF  '; 'Data    '];
                % modType = ['BPSK      '; 'BPSK      '; 'BPSK      '; 'BPSK      '; 'BPSK      '; 'BPSK      '; 'BPSK      '; 'BPSK      '; '          '];

                fieldName = {'L-STF'; 'L-LTF'; 'L-SIG'; 'RL-SIG'; 'HE-SIG-A'; 'HE-SIG-B'; 'HE-STF'; 'HE-LTF'; 'Data'};
                modType = {'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; 'BPSK'; ''};

                % Get number of data symbols from the recover object
                cfgRx = x.PHYConfig(1);
                s = validateConfig(cfgRx,'DataLocationLength'); % Same for all users
                if strcmp(x.Format,'HE-MU')
                    if x.HESIGB.User.Processed % If user field is successfully processed only then display the relavent information
                        infoSIGB = cfgRx.getSIGBLength;
                        numLTFSym = cfgRx.NumHELTFSymbols;
                        numSymbols = num2str([2; 2; 1; 1; 2; infoSIGB.NumSIGBSymbols; 1; numLTFSym; s.NumDataSymbols]);
                    else
                        numSymbols = [num2str([2; 2; 1; 1; 2]); ' '; ' '; ' '; ' '];
                    end

                    % CRC HE-SIG-A
                    if x.HESIGA.FailCRC
                        return; % Do not process any further
                    end

                    power = [n2str(powerdBm([x.Preamble.LSTFPower; x.Preamble.LLTFPower; ...
                        x.LSIG.Power; x.RLSIG.Power; ...
                        x.HESIGA.Power])); repmat('       ',4,1)];

                    crcSIG = [repmat('    ',2,1); 'Pass'; 'Pass'; 'Pass'; 'Fail'; repmat('    ',3,1)];

                    % EVM
                    rmsEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMRMS; x.RLSIG.EVMRMS; ...
                        x.HESIGA.EVMRMS]); repmat('       ',4,1)];

                    maxEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMMax; x.RLSIG.EVMMax; ...
                        x.HESIGA.EVMMax]); repmat('       ',4,1)];

                    if x.HESIGB.User.Processed
                        % Show power and EVMs if the HE-SIG-B user field has been processed
                        power(6,:) = n2str(powerdBm(x.HESIGB.Power));
                        rmsEVM(6,:) = n2str(x.HESIGB.EVMRMS);
                        maxEVM(6,:) = n2str(x.HESIGB.EVMMax);
                    end

                    if cfgRx.SIGBCompression
                        if (x.HESIGB.User.Processed && strcmp(x.HESIGB.User.Status,'Success'))
                            crcSIG(6,:) = 'Pass';
                        end
                    else
                        if (x.HESIGB.Common.Processed && strcmp(x.HESIGB.Common.Status,'Success')) && ...
                                (x.HESIGB.User.Processed && strcmp(x.HESIGB.User.Status,'Success'))
                            crcSIG(6,:) = 'Pass';
                        end
                    end

                    if x.HEPreamble.Processed
                        power(7:8,:) = n2str(powerdBm([x.HEPreamble.HESTFPower; x.HEPreamble.HELTFPower]));
                    end

                    if x.HEData.Processed
                        [dataRMSEVM,dataMAXEVM] = getPacketEVM(x.HEData.User); % HE data field
                        power(9,:) = n2str(powerdBm(x.HEData.Power));
                        rmsEVM(9,:) = n2str(dataRMSEVM);
                        maxEVM(9,:) = n2str(dataMAXEVM);
                    end
                else % HE-SU, HE-EXT-SU
                    numLTFSym = cfgRx.NumHELTFSymbols;
                    fieldName = fieldName([1:5,7:9]',:);
                    if strcmp(x.Format,'HE-SU')
                        modType = [modType(1:7,:); '          '];
                        if x.HEData.Processed % Update for non NDP
                            modType = [modType(1:7,:); getHERateDependentParameters(x.PHYConfig.MCS)];
                        end
                        numSymbols = num2str([2; 2; 1; 1; 2; 1; numLTFSym; s.NumDataSymbols]);
                    else % 'HE-EXT-SU'
                        modType = [modType(1:4,:); 'BPSK/QBPSK'; 'BPSK'; 'BPSK'; getHERateDependentParameters(x.PHYConfig.MCS)];
                        numSymbols = num2str([2 ; 2; 1; 1; 4; 1; numLTFSym; s.NumDataSymbols]);
                    end

                    % CRC HE-SIG-A
                    crcSIG = [repmat('    ',2,1); 'Pass'; 'Pass'; 'Pass'; repmat('    ',3,1)];
                    power = [n2str(powerdBm([x.Preamble.LSTFPower; x.Preamble.LLTFPower; ...
                        x.LSIG.Power; x.RLSIG.Power; x.HESIGA.Power])); repmat('       ',3,1)];

                    if x.HEPreamble.Processed % For HighDoppler case
                        power(6:7,:) = n2str(powerdBm([x.HEPreamble.HESTFPower; x.HEPreamble.HELTFPower]));
                    end

                    % EVM
                    rmsEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMRMS; x.RLSIG.EVMRMS; ...
                        x.HESIGA.EVMRMS]); repmat('       ',3,1)];
                    maxEVM = [repmat('       ',2,1); n2str([x.LSIG.EVMMax; x.RLSIG.EVMMax; ...
                        x.HESIGA.EVMMax]); repmat('       ',3,1)];

                    if x.HEData.Processed
                        power(8,:) = n2str(powerdBm(x.HEData.Power));
                        [dataRMSEVM,dataMAXEVM] = getPacketEVM(x.HEData.User); % HE data field
                        rmsEVM(8,:) = n2str(dataRMSEVM);
                        maxEVM(8,:) = n2str(dataMAXEVM);
                    end
                end
            end

            if strcmp(x.Format,'Non-HT')
                pktFieldSummary = table(fieldName,modType,mcs,numSymbols,lsigParity,power,rmsEVM,maxEVM);
                pktFieldSummary.Properties.VariableNames{1} = ['Field' 10 'Name'];
                pktFieldSummary.Properties.VariableNames{2} = 'Modulation';
                pktFieldSummary.Properties.VariableNames{3} = 'MCS';
                pktFieldSummary.Properties.VariableNames{4} = ['Num' 10 'Symbols'];
                pktFieldSummary.Properties.VariableNames{5} = ['Parity' 10 'Check'];
                pktFieldSummary.Properties.VariableNames{6} = ['Power' 10 '(dBm)'];
                pktFieldSummary.Properties.VariableNames{7} = ['RMS' 10 'EVM (dB)'];
                pktFieldSummary.Properties.VariableNames{8} = ['Max' 10 'EVM (dB)'];

                fieldInfo = struct;
                fieldName = regexprep(fieldName,'-','');
                fieldInfo.FieldName = fieldName;
                for fIdx = 1:length(fieldName)
                    fieldInfo.(fieldName{fIdx}).Modulation = char(modType(fIdx));
                    fieldInfo.(fieldName{fIdx}).MCS = str2num(mcs(fIdx,:));
                    fieldInfo.(fieldName{fIdx}).NumSymbols = str2num(numSymbols(fIdx,:));
                    if(isspace(lsigParity(fIdx,1)))
                        fieldInfo.(fieldName{fIdx}).ParityCheck = [];
                    else
                        fieldInfo.(fieldName{fIdx}).ParityCheck = lsigParity(fIdx,:);
                    end
                    fieldInfo.(fieldName{fIdx}).Power_dBm = str2num(power(fIdx,:));
                    fieldInfo.(fieldName{fIdx}).RMSEVM_dB = str2num(rmsEVM(fIdx,:));
                    fieldInfo.(fieldName{fIdx}).MaxEVM_dB = str2num(maxEVM(fIdx,:));
                end

            else % HT, VHT, HE, EHT
                pktFieldSummary = table(fieldName,modType,numSymbols,crcSIG,power,rmsEVM,maxEVM);
                pktFieldSummary.Properties.VariableNames{1} = ['Field' 10 'Name'];
                pktFieldSummary.Properties.VariableNames{2} = 'Modulation';
                pktFieldSummary.Properties.VariableNames{3} = ['Num' 10 'Symbols'];
                pktFieldSummary.Properties.VariableNames{4} = ['Parity' 10 'Check'];
                pktFieldSummary.Properties.VariableNames{5} = ['Power' 10 '(dBm)'];
                pktFieldSummary.Properties.VariableNames{6} = ['RMS' 10 'EVM (dB)'];
                pktFieldSummary.Properties.VariableNames{7} = ['Max' 10 'EVM (dB)'];

                fieldInfo = struct;
                fieldName = regexprep(fieldName,'-','');
                fieldInfo.FieldName = fieldName;
                for fIdx = 1:length(fieldName)
                    fieldInfo.(fieldName{fIdx}).Modulation = char(modType(fIdx));
                    fieldInfo.(fieldName{fIdx}).NumSymbols = str2num(numSymbols(fIdx,:));
                    if(isspace(crcSIG(fIdx,1)))
                        fieldInfo.(fieldName{fIdx}).ParityCheck = [];
                    else
                        fieldInfo.(fieldName{fIdx}).ParityCheck = crcSIG(fIdx,:);
                    end
                    fieldInfo.(fieldName{fIdx}).Power_dBm = str2num(power(fIdx,:));
                    fieldInfo.(fieldName{fIdx}).RMSEVM_dB = str2num(rmsEVM(fIdx,:));
                    fieldInfo.(fieldName{fIdx}).MaxEVM_dB = str2num(maxEVM(fIdx,:));
                end
            end
            if nargout
                T = pktFieldSummary;
            end
        end

        function T = signalingSummary(obj,pktNum)
            %signalingSummary Display signaling field summary of the selected
            %packet
            %
            %   signalingSummary(ANALYZER,PKTNUM) displays the signaling field
            %   summary of the selected packet.
            %
            %   The table contains the following columns:
            %
            %   Property   List the L-SIG (Figure 17-5 of IEEE Std 802.11-2016)
            %              field names, including:
            %              - HT:  HT-SIG field names (Table 19-11 of IEEE
            %                     Std 802.11-2016)
            %              - VHT: VHT-SIG field names (Table 21-12 of IEEE
            %                     Std 802.11-2016)
            %              - HE:  HE-SIG-A field name (Table 27-18/19 of
            %                     IEEE P802.11ax/D4.1, April 2019)
            %              - EHT: U-SIG and EHT-SIG field name (Table 36-28,
            %                     36-33, 36-36, 36-37 of IEEE P802.11be/D4.0,
            %                     July 2023)
            %
            %   Value      List the decoded, L-SIG, HT-SIG, VHT-SIG-A and
            %              HE-SIG-A, U-SIG, and EHT-SIG field values of the
            %              selected packet.
            %
            %   T = signalingSummary(ANALYZER,PKTNUM) returns the signaling
            %   field summary of the selected packet in a table.

            if isempty(obj.Results)
                T = [];
                return;
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};

            % Nothing to display
            if any(strcmp(x.Status,{'L-SIG check fail','Unsupported format','Incomplete packet'}))
                T = [];
                return;
            end

            if strcmp(x.Format,'HT-MF')
                cfgRx = x.PHYConfig(1); % HT-SIG field properties are same for all users
                if strcmp(x.Status,'HT-SIG CRC fail')
                    displayLSIGContents(x)
                    return;
                end

                lsigInfo = x.LSIG.Info;
                rate = lsigRate(lsigInfo.MCS);

                Nss = floor(cfgRx.MCS/8)+1;
                stbc = cfgRx.NumSpaceTimeStreams - Nss;

                ndpPkt = 'False';
                if cfgRx.PSDULength==0
                    ndpPkt = 'True';
                end

                smoothVal = 'False';
                if (cfgRx.RecommendSmoothing)
                    smoothVal = 'True';
                end

                aggMPDU = 'False';
                if (cfgRx.AggregatedMPDU)
                    aggMPDU = 'True';
                end

                column = ["L-SIG Length", "L-SIG Rate", "MCS", "Bandwidth", "PSDU Length", "Smoothing", "Sounding Packet", ...
                    "Aggregation", "STBC", "Channel Coding", "Guard Interval", "Num Extension Spatial Streams"]; % Table 21-12, IEEE Std 802.11-2016

                value = [string(lsigInfo.Length), string(rate), string(cfgRx.MCS), string(cfgRx.ChannelBandwidth), string(cfgRx.PSDULength), string(smoothVal), string(ndpPkt), ...
                    string(aggMPDU), string(stbc), string(cfgRx.ChannelCoding),string(cfgRx.GuardInterval), string(cfgRx.NumExtensionStreams)];

                numVal = 1:numel(column);
                delIndex = [ ];

            elseif strcmp(x.Format,'VHT')
                if ~displayVHTPacket(x) % Do not process further for VHT MU packet if SIGB fails
                    T = [];
                    return
                end
                cfgRx = x.PHYConfig(1); % VHT-SIG-A field properties are same for all users
                if strcmp(x.Status,'VHT-SIG-A CRC fail')
                    displayLSIGContents(x)
                    return;
                end
                lsigInfo = x.LSIG.Info;
                rate = lsigRate(lsigInfo.MCS);

                stbc = 'False';
                if cfgRx.STBC
                    stbc = 'True';
                end

                % TXOP PS Not Allowed
                txopPSNotAllowed = 'False';
                if x.VHTSIGA.Bits(23)==1
                    txopPSNotAllowed = 'True';
                end

                % NumSpaceTimeStreams and Channel Coding
                numUsers = numel(x.PHYConfig);
                userSTS = zeros(1,numUsers);
                userMCS = zeros(1,numUsers);
                userCoding = [];
                tableTitleDisplayoffset = 21;
                for u=1:numUsers
                    cfgRx = x.PHYConfig(u);
                    userSTS(u) = cfgRx.NumSpaceTimeStreams;
                    userMCS(u) = cfgRx.MCS;
                    userCoding = [userCoding [char(cfgRx.ChannelCoding) pad('',1)]];
                    tableTitleDisplayoffset = tableTitleDisplayoffset+(u-1)*2;
                end

                if numUsers>1
                    userSTS = strcat(strcat('[',num2str(userSTS)),']');
                    userMCS = strcat(strcat('[',num2str(userMCS)),']');
                    userCoding = strcat(strcat('[',userCoding),']');
                end

                % Short GI NSYM Disambiquity On
                shortGISymDisambiquityOn = 'False';
                if x.VHTSIGA.Bits(26)==1
                    shortGISymDisambiquityOn = 'True';
                end

                % LDPC Extra Symbol
                ldpcExtraSymbol = 'False';
                if x.VHTSIGA.Bits(27)==1
                    ldpcExtraSymbol = 'True';
                end
                column = ["L-SIG Length", "L-SIG Rate", "Bandwidth", "STBC", "Group ID", "Num Space Time Streams", "Partial AID", "TXOP PS Not Allowed", ...% Table 21-11, IEEE Std 802.11-2016
                    "Guard Interval", "Short GI NSYM Disambiquity On", "Channel Coding", "LDPC Extra Symbol", "MCS", "Beamformed"]; % Table 21-12, IEEE Std 802.11-2016

                value = [string(lsigInfo.Length), string(rate), string(cfgRx.ChannelBandwidth), string(stbc), string(cfgRx.GroupID),string(userSTS), string(cfgRx.PartialAID),string(txopPSNotAllowed), ...
                    string(cfgRx.GuardInterval), string(shortGISymDisambiquityOn), string(userCoding), string(ldpcExtraSymbol), string(userMCS), string(ldpcExtraSymbol)];

                numVal = 1:numel(column);
                delIndex = [ ];
            elseif strcmp(x.Format,'EHT-MU')
                cfgRx = x.PHYConfig(1); % Common for all users
                if strcmp(x.Status,"U-SIG FailCRC")
                    displayLSIGContents(x)
                    return;
                end

                channelBandwidth = string(cfgRx.ChannelBandwidth);
                if strcmp(cfgRx.ChannelBandwidth,'CBW320')
                    if cfgRx.Channelization==1
                        channelBandwidth = '320 MHz-1';
                    else
                        channelBandwidth = '320 MHz-2';
                    end
                end

                title = ["Property","Value","Property","Value","Property","Value"];
                uplinkIndication = 'DL';
                if cfgRx.UplinkIndication
                    uplinkIndication = 'UL';
                end

                txopDuration = cfgRx.TXOPDuration;
                if txopDuration==-1
                    txopDuration = 'Unspecified';
                end

                if cfgRx.LDPCExtraSymbol
                    ldpcExtraSymbol = 'True';
                else
                    ldpcExtraSymbol = 'False';
                end

                PEDisambiguity = 'False';
                if cfgRx.PEDisambiguity
                    PEDisambiguity = 'True';
                end

                ehtDUPMode = 'False';
                if cfgRx.EHTDUPMode
                    ehtDUPMode = 'True';
                end

                puncturedPattern = ones(4,4);
                for i=1:height(cfgRx.PuncturedPattern)
                    puncturedPattern(i,:) = cfgRx.PuncturedPattern(i,:);
                end

                lsigInfo = x.LSIG.Info;
                rate = lsigRate(lsigInfo.MCS);
                if cfgRx.PPDUType==wlan.type.EHTPPDUType.ndp
                    column = ["L-SIG Length","L-SIG Rate","Bandwidth","UL/DL Indication","BSS Color","TXOP", ...
                        "Compression Mode","EHT-SIG MCS","Num EHT-SIG Symbols","Spatial Reuse","Guard Interval","EHT-LTF Type", ...
                        "Num EHT-LTF Symbols","PPDU Type","EHT DUP Mode","Punctured Channel Field Value","",""];

                    value = [string(lsigInfo.Length),string(rate),channelBandwidth,uplinkIndication,string(cfgRx.BSSColor),string(txopDuration),string(cfgRx.CompressionMode) ...
                        string(cfgRx.EHTSIGMCS),string(cfgRx.NumEHTSIGSymbolsSignaled),string(cfgRx.SpatialReuse),string(cfgRx.GuardInterval),string(cfgRx.EHTLTFType), ...
                        string(cfgRx.NumEHTLTFSymbols),"NDP",ehtDUPMode, ...
                        string(cfgRx.PuncturedChannelFieldValue),string(1),string(1)];
                    numVal = 1:numel(column);
                    offset = 35;
                    delIndex = [17 18];
                else
                    column = ["L-SIG Length","L-SIG Rate","Bandwidth","UL/DL Indication","BSS Color","TXOP", ...
                        "Compression Mode","EHT-SIG MCS","Num EHT-SIG Symbols","Spatial Reuse","Guard Interval","EHT-LTF Type", ...
                        "Num EHT-LTF Symbols","LDPC Extra Symbol","Pre-FEC Padding Factor","PE Disambiguity","Number of Non-OFDMA Users","PPDU Type","EHT DUP Mode", ...
                        "Punctured Channel Field Value","Punctured Channel 1st 80 MHz Subblock","Punctured Channel 2nd 80 MHz Subblock", ...
                        "Punctured Channel 3rd 80 MHz Subblock","Punctured Channel 4th 80 MHz Subblock"];

                    value = [string(lsigInfo.Length),string(rate),channelBandwidth,uplinkIndication,string(cfgRx.BSSColor),string(txopDuration),string(cfgRx.CompressionMode) ...
                        string(cfgRx.EHTSIGMCS),string(cfgRx.NumEHTSIGSymbolsSignaled),string(cfgRx.SpatialReuse),string(cfgRx.GuardInterval),string(cfgRx.EHTLTFType), ...
                        string(cfgRx.NumEHTLTFSymbols),ldpcExtraSymbol,string(cfgRx.PreFECPaddingFactor),PEDisambiguity,cfgRx.NumNonOFDMAUsers,"DL OFDMA",ehtDUPMode, ...
                        string(cfgRx.PuncturedChannelFieldValue),['[' num2str(puncturedPattern(1,:)) ']'],['[' num2str(puncturedPattern(2,:)) ']'],['[' num2str(puncturedPattern(3,:)) ']'], ...
                        ['[' num2str(puncturedPattern(4,:)) ']']];

                    numVal = 1:numel(column);
                    if cfgRx.PPDUType==wlan.type.EHTPPDUType.dl_ofdma
                        if any(strcmp(cfgRx.ChannelBandwidth,{'CBW20','CBW40'}))
                            delIndex = [17 20 21 22 23 24];
                            offset = 31;
                        elseif (strcmp(cfgRx.ChannelBandwidth,'CBW80'))
                            delIndex = [17 20 22 23 24];
                            offset = 46;
                        elseif strcmp(cfgRx.ChannelBandwidth,'CBW160')
                            delIndex = [17 20 23 24];
                            offset = 46;
                        else % CBW320
                            delIndex = [17 20];
                            offset = 46;
                        end
                    else % Non-OFDMA
                        offset = 36;
                        delIndex = [21 22 23 24];
                        if cfgRx.CompressionMode==1
                            value(18) = "EHT SU";
                            delIndex = [17 delIndex];
                            if cfgRx.EHTDUPMode
                                delIndex = [20 delIndex];
                            end
                        else % DL MUMO
                            value(18) = "DL MU-MIMO";
                        end
                    end
                end
            elseif any(strcmp(x.Format,{'HE-MU','HE-SU','HE-EXT-SU'}))
                cfgRx = x.PHYConfig(1); % Common for all users
                if strcmp(x.Status,"HE-SIG-A FailCRC")
                    displayLSIGContents(x)
                    return;
                end
                uplinkIndication = 'DL';
                if cfgRx.UplinkIndication
                    uplinkIndication = 'UL';
                end

                stbc = 'False';
                if cfgRx.STBC
                    stbc = 'True';
                end

                doppler = 'False';
                midamblePre = '';
                if cfgRx.HighDoppler
                    doppler = 'True';
                    midamblePre = num2str(cfgRx.MidamblePeriodicity);
                end

                if cfgRx.LDPCExtraSymbol
                    ldpcExtraSymbol = 'True';
                else
                    ldpcExtraSymbol = 'False';
                end

                PEDisambiguity = 'False';
                if cfgRx.PEDisambiguity
                    PEDisambiguity = 'True';
                end

                lsigInfo = x.LSIG.Info;
                rate = lsigRate(lsigInfo.MCS);
                if strcmp(x.Format,'HE-MU')
                    sigbDCM = 'False';
                    if cfgRx.SIGBDCM
                        sigbDCM = 'True';
                    end
                    sigBCompression = 'False';
                    varField = "Num HE-SIGB Symbols";
                    combinedSIGBUser = string(cfgRx.NumSIGBSymbolsSignaled);
                    if cfgRx.SIGBCompression
                        sigBCompression = 'True';
                        varField = "Num MU-MIMO Users";
                        combinedSIGBUser = sum(cfgRx.NumUsersPerContentChannel);
                    end

                    column = ["L-SIG Length", "L-SIG Rate", "UL/DL Indication", "SIGB MCS", "SIGB DCM", "BSS Color", "Spatial Reuse", ... % 1:7
                        "Bandwidth", "PreamblePuncturing", varField, "SIGB Compression", "Guard Interval", "HE-LTF Type", "Doppler", ...% 8:14
                        "TXOP", "Num HE-LTF Symbols", "Midamble Perodicity", "LDPC Extra Symbol", "STBC", "Pre-FEC Padding Factor", "PE Disambiguity"]; % 15:21

                    value = [string(lsigInfo.Length), string(rate), string(uplinkIndication), string(cfgRx.SIGBMCS), string(sigbDCM), string(cfgRx.BSSColor), string(cfgRx.SpatialReuse), ...
                        string(cfgRx.ChannelBandwidth), string(cfgRx.PreamblePuncturing), combinedSIGBUser, string(sigBCompression) ...
                        string(cfgRx.GuardInterval), string(cfgRx.HELTFType), string(doppler), string(cfgRx.TXOPDuration), string(cfgRx.NumHELTFSymbols), ...
                        string(cfgRx.MidamblePeriodicity), string(ldpcExtraSymbol), string(stbc), string(cfgRx.PreFECPaddingFactor), string(PEDisambiguity)];

                    numVal = 1:numel(column);
                    delIndex = [];
                    if any(strcmp(cfgRx.ChannelBandwidth,{'CBW20','CBW40'}))
                        delIndex = 9;
                    end

                    if strcmp(doppler,'False') % Hide MidamblePeriodicity
                        delIndex = [delIndex 17];
                    end
                else % HE-SU, HE-EXT-SU
                    dcm = 'False';
                    if cfgRx.DCM
                        dcm = 'True';
                    end

                    upper106ToneRU = 'False';
                    if cfgRx.RUSize==106 && cfgRx.RUIndex==2
                        upper106ToneRU = 'True';
                    end

                    beamforming = 'False';
                    if cfgRx.Beamforming
                        beamforming = 'True';
                    end

                    beamChange = 'True';
                    if cfgRx.PreHESpatialMapping
                        beamChange = 'False';
                    end

                    column = ["L-SIG Length", "L-SIG Rate", "Format", "Upper 106Tone RU", "Beam Change", "UL/DL Indication", "MCS", ...% 1:7
                        "DCM", "BSS Color", "Spatial Reuse", "Bandwidth", "Guard Interval", "HE-LTF Type", "Num Space Time Streams", ...% 8:15
                        "Num HE-LTF Symbols", "Midamble Perodicity", "TXOP", "Channel Coding", "LDPC Extra Symbol", "STBC", "Beamformed", ...% 16:22
                        "Pre-FEC Padding Factor", "PE Disambiguity", "Doppler"]; % 23:27

                    value = [string(lsigInfo.Length), string(rate), string(cfgRx.PacketFormat), string(upper106ToneRU), string(beamChange), string(uplinkIndication), string(cfgRx.MCS), ... %1:7
                        string(dcm), string(cfgRx.BSSColor), string(cfgRx.SpatialReuse), string(cfgRx.ChannelBandwidth), string(cfgRx.GuardInterval), string(cfgRx.HELTFType), string(cfgRx.NumSpaceTimeStreams), ... 8:15
                        string(cfgRx.NumHELTFSymbols), string(midamblePre), string(cfgRx.TXOPDuration), string(cfgRx.ChannelCoding), string(ldpcExtraSymbol), string(stbc), string(beamforming), ...% 16:22
                        string(cfgRx.PreFECPaddingFactor), string(PEDisambiguity), string(doppler)]; % 23:27

                    numVal = 1:numel(column);
                    delIndex = [];
                    if strcmp(doppler,'False') % Hide MidamblePeriodicity
                        delIndex = 16;
                    end

                    if ~strcmp(cfgRx.PacketFormat,'HE-EXT-SU')
                        delIndex = [4 delIndex];
                    end
                end
            else % Non-HT
                T = displayLSIGContents(x);
                return
            end
            visibleIndex = setxor(numVal,delIndex);
            column = column(visibleIndex);
            value = value(visibleIndex);

            if nargout
                Tvalue = rows2vars(table(value.'));
                Tcolumn = rows2vars(table(column.'));
                Tcolumn(:,1) = [];
                Tvalue(:,1) = [];
                Tparam = table2array(Tcolumn);
                Tvalue.Properties.VariableNames = Tparam;
                T = Tvalue;
            end
        end

        function [T, ruInfo] = ruSummary(obj,pktNum)
            %ruSummary Display resource unit (RU) summary of the selected packet
            %   ruSummary(ANALYZER,PKTNUM) displays the RU summary of the
            %   selected packet, PKTNUM. The RU information is only displayed
            %   for EHT and HE packets.
            %
            %   The table contains the following columns:
            %
            %   RU Index                 Resource unit index. This column
            %                            is only displayed for an EHT and
            %                            HE MU packet formats.
            %
            %   RU Size                  Resource unit size. This column is
            %                            only displayed for an EHT and HE
            %                            MU packet formats.
            %
            %   Subcarrier Index (Start) The starting subcarrier index of
            %                            an RU. This column is only
            %                            displayed for EHT and HE packet
            %                            formats.
            %
            %   Subcarrier Index (End)   The last subcarrier index of an
            %                            RU. This column is only displayed
            %                            for EHT and HE packet formats.
            %
            %   Num Users                Number of users in an RU. This
            %                            column is only displayed for EHT,
            %                            HE MU and VHT MU packet formats.
            %
            %   Num Space Time Streams   Number of space-time streams in an
            %   RU.
            %                            This column is only displayed for
            %                            EHT and HE MU packet formats.
            %
            %   Power                    RU power in dBm.
            %
            %   T = ruSummary(ANALYZER,PKTNUM) returns the RU summary of
            %   the selected packet in a table.

            if isempty(obj.Results)
                T = [];
                ruInfo = [];
                return;
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};

            if any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU'}))
                dataProcessed = x.HEData.Processed;
            elseif strcmp(x.Format,'EHT-MU')
                dataProcessed = x.EHTData.Processed;
            else % Non-HT, HT-MF and VHT
                dataProcessed = false;
            end

            if ~strcmp(x.Status,"Success") || ~any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU','EHT-MU'})) || ~dataProcessed
                T = [];
                ruInfo = [];
                return;
            end

            if strcmp(x.Format,'EHT-MU')
                cfgRx = x.PHYConfig(1); % RU information is common for all users
                cbw = wlan.internal.cbwStr2Num(cfgRx.ChannelBandwidth);
                numRUs = numel(x.EHTPreamble.RU);
                ruName = strings(numRUs,1);
                ruSize = cell(numRUs,1);
                ruStartInd = zeros(numRUs,1);
                ruEndInd = zeros(numRUs,1);
                numUserPerRU = zeros(numRUs,1);
                numSTSPerRU = zeros(numRUs,1);
                ruPower = zeros(numRUs,1);

                for ru=1:numRUs
                    ruName(ru) = string([num2str(x.EHTPreamble.RU(ru).RUIndex)]);
                    ruSize{ru} = num2str(x.EHTPreamble.RU(ru).RUSize);
                    if ~isscalar(x.EHTPreamble.RU(ru).RUSize)
                        ruSize{ru} = mruString(sort(x.EHTPreamble.RU(ru).RUSize,'descend'));
                    end
                    [~,activeIndices] = wlan.internal.ehtOccupiedSubcarrierIndices(cbw,x.EHTPreamble.RU(ru).RUSize,x.EHTPreamble.RU(ru).RUIndex);
                    ruIndex = activeIndices;
                    ruStartInd(ru) = min(ruIndex);
                    ruEndInd(ru) = max(ruIndex);
                    userNum = x.EHTPreamble.RU(ru).UserNumbers;
                    if ~isempty(userNum) % If the user fails CRC check
                        numUserPerRU(ru) = numel(x.EHTPreamble.RU(ru).UserNumbers);
                        userNumber = x.EHTPreamble.RU(ru).UserNumbers;
                        numSTSPerRU(ru) = x.PHYConfig(userNumber).RUTotalSpaceTimeStreams;
                        ruPower(ru) = powerdBm(x.EHTData.RU(ru).Power);
                    end
                end

                if numRUs==1 % EHT SU
                    if isscalar(x.EHTPreamble.RU(ru).RUSize)
                        ruTable = table(ruName,str2double(ruSize{1}),ruStartInd,ruEndInd,numUserPerRU,numSTSPerRU,ruPower);
                    else % Punctured channel
                        % If ruSize is not scalar then display as string
                        ruTable = table(ruName,string(strtrim(ruSize{1})),ruStartInd,ruEndInd,numUserPerRU,numSTSPerRU,ruPower);
                    end
                else % OFDMA
                    lenVec = cellfun('size',ruSize,2);
                    L = max(lenVec);

                    ruSizeTemp = cell(numRUs,1);
                    for ru=1:numRUs
                        S = strlength(ruSize{ru});
                        ruSizeTemp{ru} = ([ruSize{ru} repmat(' ',1,L-S)]);
                    end
                    ruSizeStr = string(strtrim(cell2mat(ruSizeTemp)));
                    ruTable = table(ruName,ruSizeStr,ruStartInd,ruEndInd,numUserPerRU,numSTSPerRU,ruPower);
                end
                ruTable.Properties.VariableNames{1} = 'RU Index';
                ruTable.Properties.VariableNames{2} = 'RU/MRU Size';
                ruTable.Properties.VariableNames{3} = 'Subcarrier Index (Start)';
                ruTable.Properties.VariableNames{4} = 'Subcarrier Index (End)';
                ruTable.Properties.VariableNames{5} = 'Num Users';
                ruTable.Properties.VariableNames{6} = 'Num Space Time Streams';
                ruTable.Properties.VariableNames{7} = 'Power (dBm)';
                ruInfo = struct;
                ruInfo.RUIndex = char(ruName);
                if numRUs == 1
                    ruInfo.RUSize = ruSize{1};
                else %OFDMA
                    ruInfo.RUSize = ruSize;
                end
                ruInfo.SubcarrierIndexStart = ruStartInd;
                ruInfo.SubcarrierIndexEnd = ruEndInd;
                ruInfo.NumUsers = numUserPerRU;
                ruInfo.NumSTS = numSTSPerRU;
                ruInfo.Power_dBm = ruPower;
            elseif strcmp(x.Format,'HE-MU')
                cfgRx = x.PHYConfig(1); % RU information is common for all users
                cbw = wlan.internal.cbwStr2Num(cfgRx.ChannelBandwidth);
                numRUs = numel(x.HEPreamble.RU);
                ruName = strings(numRUs,1);
                ruSize = zeros(numRUs,1);
                ruStartInd = zeros(numRUs,1);
                ruEndInd = zeros(numRUs,1);
                numUserPerRU = zeros(numRUs,1);
                numSTSPerRU = zeros(numRUs,1);
                ruPower = zeros(numRUs,1);

                for ru=1:numRUs
                    ruName(ru) = string([num2str(x.HEPreamble.RU(ru).RUIndex)]);
                    ruSize(ru) = x.HEPreamble.RU(ru).RUSize;
                    [dataInd,pilotInd] = wlan.internal.heSubcarrierIndices(cbw,ruSize(ru),x.HEPreamble.RU(ru).RUIndex);
                    ruIndex = sort([dataInd;pilotInd]);
                    ruStartInd(ru) = min(ruIndex);
                    ruEndInd(ru) = max(ruIndex);
                    userNum = x.HEPreamble.RU(ru).UserNumbers;
                    if ~isempty(userNum) % If the user fails CRC check
                        numUserPerRU(ru) = numel(x.HEPreamble.RU(ru).UserNumbers);
                        userNumber = x.HEPreamble.RU(ru).UserNumbers;
                        numSTSPerRU(ru) = x.PHYConfig(userNumber).RUTotalSpaceTimeStreams;
                        ruPower(ru) = powerdBm(x.HEData.RU(ru).Power);
                    end
                end

                ruTable = table(ruName,ruSize,ruStartInd,ruEndInd,numUserPerRU,numSTSPerRU,ruPower);
                ruTable.Properties.VariableNames{1} = 'RU Index';
                ruTable.Properties.VariableNames{2} = 'RU Size';
                ruTable.Properties.VariableNames{3} = 'Subcarrier Index (Start)';
                ruTable.Properties.VariableNames{4} = 'Subcarrier Index (End)';
                ruTable.Properties.VariableNames{5} = 'Num Users';
                ruTable.Properties.VariableNames{6} = 'Num Space Time Streams';
                ruTable.Properties.VariableNames{7} = 'Power (dBm)';

                ruInfo = struct;
                ruInfo.RUIndex = char(ruName);
                ruInfo.RUSize = ruSize;
                ruInfo.SubcarrierIndexStart = ruStartInd;
                ruInfo.SubcarrierIndexEnd = ruEndInd;
                ruInfo.NumUsers = numUserPerRU;
                ruInfo.NumSTS = numSTSPerRU;
                ruInfo.Power_dBm = ruPower;

            else
                recConfig = x.PHYConfig;
                cbw = wlan.internal.cbwStr2Num(recConfig.ChannelBandwidth);
                [dataInd,pilotInd] = wlan.internal.heSubcarrierIndices(cbw,recConfig.RUSize,1);
                ruIndex = sort([dataInd;pilotInd]);
                ruName = string([num2str(1)]);
                ruPower = powerdBm(x.HEData.RU.Power);

                ruTable = table(ruName,recConfig.RUSize,min(ruIndex),max(ruIndex),ruPower);
                ruTable.Properties.VariableNames{1} = 'RU Index';
                ruTable.Properties.VariableNames{2} = 'RU Size';
                ruTable.Properties.VariableNames{3} = 'Subcarrier Index (Start)';
                ruTable.Properties.VariableNames{4} = 'Subcarrier Index (End)';
                ruTable.Properties.VariableNames{5} = 'Power (dBm)';

                ruInfo = struct;
                ruInfo.RUIndex = char(ruName);
                ruInfo.RUSize = recConfig.RUSize;
                ruInfo.SubcarrierIndexStart = min(ruIndex);
                ruInfo.SubcarrierIndexEnd = max(ruIndex);
                ruInfo.Power_dBm = ruPower;
            end

            if nargout
                T = ruTable;
            end
        end

        function [T, psduBits] = userSummary(obj,pktNum)
            %userSummary Display the user summary
            %
            %   userSummary(ANALYZER,PKTNUM) displays the user properties of
            %   the selected packet, PKTNUM.
            %
            %   The table contains the following columns:
            %
            %   Station ID/User Number  Station identification is only
            %                           displaced for an EHT and HE MU
            %                           packet format. User Number is only
            %                           displayed for an VHT multiuser
            %                           packet format.
            %
            %   RU Number               Resource unit number. This column
            %                           is only displayed for EHT and HE MU
            %                           packet format.
            %
            %   MCS                     Modulation and coding scheme.
            %
            %   Modulation              Modulation information.
            %
            %   Code Rate               Code rate information for the MCS.
            %
            %   DCM                     Dual carrier modulation. This column is
            %                           only displayed for HE MU packet format.
            %
            %   Channel Coding          Channel coding information.
            %
            %   Num Space-Time Streams  Number of space-time streams per user.
            %
            %   Beamformed              Beamforming steering matrix. This
            %                           column is only displayed for EHT
            %                           and HE MU packet format.
            %
            %   T = userSummary(ANALYZER,PKTNUM) returns the user summary
            %   of the selected packet in a table.

            if isempty(obj.Results)
                T = [];
                psduBits = [];
                return;
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};

            if ~strcmp(x.Status,"Success")
                T = [];
                psduBits = [];
                return;
            end

            if any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU'}))
                dataProcessed = x.HEData.Processed;
            elseif strcmp(x.Format,'EHT-MU')
                dataProcessed = x.EHTData.Processed;
            elseif strcmp(x.Format,'VHT')
                dataProcessed = displayVHTPacket(x);
            elseif strcmp(x.Format,'HT-MF')
                dataProcessed = x.HTData.Processed;
            elseif strcmp(x.Format,'Non-HT')
                dataProcessed = x.NonHTData.Processed;
            else % Invalid/unsupported packet type
                dataProcessed = false;
            end

            if ~dataProcessed
                T = [];
                psduBits = [];
                return;
            end

            if strcmp(x.Format,'EHT-MU')
                cfgUsers = x.PHYConfig;
                numUsers = numel(cfgUsers);
                stdID = zeros(numUsers,1);
                nsts = zeros(numUsers,1);
                mcs = zeros(numUsers,1);
                chCoding = strings(numUsers,1);
                BF = strings(numUsers,1);
                modType = strings(numUsers,1);
                rate = strings(numUsers,1);
                numRUs = numel(x.EHTPreamble.RU);
                offset = 0;
                ruName = [];
                for ru=1:numRUs
                    numUserPerRU = numel(x.EHTPreamble.RU(ru).UserNumbers);
                    for u=1:numUserPerRU
                        BF(u+offset) = "False";
                        cfgRx = cfgUsers(x.EHTPreamble.RU(ru).UserNumbers(u));
                        stdID(u+offset) = cfgRx.STAID;
                        nsts(u+offset) = cfgRx.NumSpaceTimeStreams;
                        mcs(u+offset) = cfgRx.MCS;
                        chCoding(u+offset) = upper(string(cfgRx.ChannelCoding));
                        if cfgRx.Beamforming
                            BF(u+offset) = "True";
                        end
                        [modType(u+offset),rate(u+offset)] = getHERateDependentParameters(cfgRx.MCS,'string');
                    end

                    offset = offset+numUserPerRU;
                    if numUserPerRU~=0
                        ruName = [ruName; repmat(string(['RU' num2str(ru)]),u,1)];
                    end
                end

                userTable = table(stdID,ruName,mcs,modType,rate,chCoding,nsts,BF);
                userTable.Properties.VariableNames{1} = 'Station ID';
                userTable.Properties.VariableNames{2} = 'RU Number';
                userTable.Properties.VariableNames{3} = 'MCS';
                userTable.Properties.VariableNames{4} = 'Modulation';
                userTable.Properties.VariableNames{5} = 'Code Rate';
                userTable.Properties.VariableNames{6} = 'Channel Coding';
                userTable.Properties.VariableNames{7} = 'Num Space Time Streams';
                userTable.Properties.VariableNames{8} = 'Beamformed';
            elseif strcmp(x.Format,'HE-MU')
                cfgUsers = x.PHYConfig;
                numUsers = numel(cfgUsers);
                stdID = zeros(numUsers,1);
                nsts = zeros(numUsers,1);
                mcs = zeros(numUsers,1);
                dcm = strings(numUsers,1);
                chCoding = strings(numUsers,1);
                BF = strings(numUsers,1);
                modType = strings(numUsers,1);
                rate = strings(numUsers,1);
                numRUs = numel(x.HEPreamble.RU);
                ruName = [];
                offset = 0;
                for ru=1:numRUs
                    numUserPerRU = numel(x.HEPreamble.RU(ru).UserNumbers);
                    for u=1:numUserPerRU
                        dcm(u+offset) = "False";
                        BF(u+offset) = "False";
                        cfgRx = cfgUsers(x.HEPreamble.RU(ru).UserNumbers(u));
                        stdID(u+offset) = cfgRx.STAID;
                        nsts(u+offset) = cfgRx.NumSpaceTimeStreams;
                        mcs(u+offset) = cfgRx.MCS;
                        if cfgRx.DCM
                            dcm(u+offset) = "True";
                        end
                        chCoding(u+offset) = string(cfgRx.ChannelCoding);
                        if cfgRx.Beamforming
                            BF(u+offset) = "True";
                        end
                        [modType(u+offset),rate(u+offset)] = getHERateDependentParameters(cfgRx.MCS,'string');
                    end

                    offset = offset+numUserPerRU;
                    if numUserPerRU~=0
                        ruName = [ruName; repmat(string(['RU' num2str(ru)]),u,1)];
                    end
                end

                userTable = table(stdID,ruName,mcs,modType,rate,dcm,chCoding,nsts,BF);
                userTable.Properties.VariableNames{1} = 'Station ID';
                userTable.Properties.VariableNames{2} = 'RU Number';
                userTable.Properties.VariableNames{3} = 'MCS';
                userTable.Properties.VariableNames{4} = 'Modulation';
                userTable.Properties.VariableNames{5} = 'Code Rate';
                userTable.Properties.VariableNames{6} = 'DCM';
                userTable.Properties.VariableNames{7} = 'Channel Coding';
                userTable.Properties.VariableNames{8} = 'Num Space Time Streams';
                userTable.Properties.VariableNames{9} = 'Beamformed';
            elseif strcmp(x.Format,'HE-SU') || strcmp(x.Format,'HE-EXT-SU')
                cfgRx = x.PHYConfig;
                ruName(1) = string([num2str(1)]);
                nsts = cfgRx.NumSpaceTimeStreams;
                mcs = cfgRx.MCS;
                [modType,rate] = getHERateDependentParameters(cfgRx.MCS,'string');
                
                dcm = "False";
                if cfgRx.DCM
                    dcm = "True";
                end

                chCoding(1) = string(cfgRx.ChannelCoding);

                BF = "False";
                if cfgRx.Beamforming
                    BF = "True";
                end

                userTable = table(ruName,mcs,modType,rate,dcm,chCoding,nsts,BF);
                userTable.Properties.VariableNames{1} = 'RU Number';
                userTable.Properties.VariableNames{2} = 'MCS';
                userTable.Properties.VariableNames{3} = 'Modulation';
                userTable.Properties.VariableNames{4} = 'Code Rate';
                userTable.Properties.VariableNames{5} = 'DCM';
                userTable.Properties.VariableNames{6} = 'Channel Coding';
                userTable.Properties.VariableNames{7} = 'Num Space Time Streams';
                userTable.Properties.VariableNames{8} = 'Beamformed';
            elseif strcmp(x.Format,'VHT')
                numUser = numel(x.PHYConfig);
                userMCS = zeros(numUser,1);
                userMod = strings(numUser,1);
                userRate = strings(numUser,1);
                userChCoding = strings(numUser,1);
                userSTS = zeros(numUser,1);
                offset = 0;
                for u=1:numUser
                    userMCS(u) = x.PHYConfig(u).MCS;
                    [userMod(u),userRate(u)] = getHERateDependentParameters(x.PHYConfig(u).MCS,'string');
                    userSTS(u) = x.PHYConfig(u).NumSpaceTimeStreams;
                    userChCoding(u) = x.PHYConfig(u).ChannelCoding;
                    offset = offset+1;
                end
                userTable = table((1:numUser).',userMCS,userMod,userRate,userChCoding,userSTS);
                userTable.Properties.VariableNames{1} = 'User Number';
                userTable.Properties.VariableNames{2} = 'MCS';
                userTable.Properties.VariableNames{3} = 'Modulation';
                userTable.Properties.VariableNames{4} = 'Code Rate';
                userTable.Properties.VariableNames{5} = 'Channel Coding';
                userTable.Properties.VariableNames{6} = 'Num Space Time Streams';
            elseif strcmp(x.Format,'HT-MF')% HT-MF
                userMCS = x.PHYConfig.MCS;
                % Modulation type is same for MCS 0:7, 8:15, 16:23, and
                % 17:31. Limit MCS to 0:7 for MCS greater than 8.
                mcs = rem(userMCS,8);
                [userMod,userRate] = getHERateDependentParameters(mcs,'string');
                userSTS = numel(x.HTData.EVMRMS); % Number of space-time streams
                userChCoding = string(x.PHYConfig.ChannelCoding);
                userTable = table((userMCS),userMod,userRate,userChCoding,userSTS);
                userTable.Properties.VariableNames{1} = 'MCS';
                userTable.Properties.VariableNames{2} = 'Modulation';
                userTable.Properties.VariableNames{3} = 'Code Rate';
                userTable.Properties.VariableNames{4} = 'Channel Coding';
                userTable.Properties.VariableNames{5} = 'Num Space Time Streams';
            else % Non-HT
                userMCS = x.PHYConfig.MCS;
                [userMod,userRate] = getNonHTRateDependentParameters(x.PHYConfig.MCS,'string');
                userTable = table(userMCS,userMod,userRate,"BCC");
                userTable.Properties.VariableNames{1} = 'MCS';
                userTable.Properties.VariableNames{2} = 'Modulation';
                userTable.Properties.VariableNames{3} = 'Code Rate';
                userTable.Properties.VariableNames{4} = 'Channel Coding';
            end

            % Can we do here in common for all formats

            if nargout
                T = userTable;
                psduBits = x.PSDU;
            end
        end

        function T = userEVM(obj,pktNum)
            %userEVM Display EVM per spatial stream
            %
            %   userEVM(ANALYZER,PKTNUM) displays the EVM per spatial stream
            %   for the selected packet, PKTNUM.
            %
            %   The table contains the following columns:
            %
            %   Station ID/User Number      Station identification is only
            %                          displaced for an EHT and HE MU
            %                          packet format. User Number is only
            %                          displayed for an VHT multiuser
            %                          packet format.
            %
            %   Spatial Stream Index   Staring space-time stream index within
            %                          an RU. This column is not displayed for
            %                          Non-HT packet format.
            %
            %   RMS EVM                RMS EVM in dBs of the data field.
            %
            %   Max EVM                Max EVM in dBs of the data field.
            %
            %   T = userEVM(ANALYZER,PKTNUM) returns the EVM of all
            %   spatial streams of the selected packet in a table.

            if isempty(obj.Results)
                T = [];
                return;
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};

            if isDataProcessed(x) % isDataProcessed
                T = [];
                return;
            end

            if strcmp(x.Format,"EHT-MU")
                cfgPkt = x;
                cfgUsers = cfgPkt.PHYConfig;
                stdID = [];
                evmRMS = [];
                evmMax =[];
                numSTS = [];
                numRUs = numel(x.EHTPreamble.RU);
                for ru=1:numRUs
                    numUserPerRU = numel(x.EHTPreamble.RU(ru).UserNumbers);
                    for u=1:numUserPerRU
                        userNumber = x.EHTPreamble.RU(ru).UserNumbers(u);
                        cfgRx = cfgUsers(userNumber);
                        nsts = cfgRx.NumSpaceTimeStreams;
                        stdID = [stdID; repmat(cfgRx.STAID,nsts,1)]; %#ok<*AGROW>
                        evmRMS = [evmRMS; cfgPkt.EHTData.User(userNumber).EVMRMS];
                        evmMax = [evmMax; cfgPkt.EHTData.User(userNumber).EVMMax];
                        numSTS =  [numSTS; (1:nsts).'];
                    end
                end

                evmTable = table(stdID,numSTS,evmRMS,evmMax);
                evmTable.Properties.VariableNames{1} = 'Station ID';
                evmTable.Properties.VariableNames{2} = 'Spatial Stream Index';
                evmTable.Properties.VariableNames{3} = 'RMS EVM (dB)';
                evmTable.Properties.VariableNames{4} = 'Max EVM (dB)';
            elseif strcmp(x.Format,"HE-MU")
                cfgPkt = x;
                cfgUsers = cfgPkt.PHYConfig;
                stdID = [];
                evmRMS = [];
                evmMax =[];
                numSTS = [];
                numRUs = numel(x.HEPreamble.RU);
                for ru=1:numRUs
                    for u=1:numel(cfgUsers)
                        % userNumber = x.HEPreamble.RU(ru).UserNumbers(u);
                        cfgRx = cfgUsers(u);
                        if cfgRx.STBC
                            nsts = cfgRx.NumSpaceTimeStreams/2;
                        else
                            nsts = cfgRx.NumSpaceTimeStreams;
                        end
                        stdID = [stdID; repmat(cfgRx.STAID,nsts,1)]; %#ok<*AGROW>
                        evmRMS = [evmRMS; cfgPkt.HEData.User(u).EVMRMS];
                        evmMax = [evmMax; cfgPkt.HEData.User(u).EVMMax];
                        numSTS =  [numSTS; (1:nsts).'];
                    end
                end

                evmTable = table(stdID,numSTS,evmRMS,evmMax);
                evmTable.Properties.VariableNames{1} = 'Station ID';
                evmTable.Properties.VariableNames{2} = 'Spatial Stream Index';
                evmTable.Properties.VariableNames{3} = 'RMS EVM (dB)';
                evmTable.Properties.VariableNames{4} = 'Max EVM (dB)';
            elseif strcmp(x.Format,'HE-SU') || strcmp(x.Format,'HE-EXT-SU')
                cfgRx = x.PHYConfig(1);
                cfgPkt =  x;
                if cfgRx.STBC
                    numSTS = 1:cfgRx.NumSpaceTimeStreams/2;
                else
                    numSTS = (1:cfgRx.NumSpaceTimeStreams).';
                end
                userEVM = cfgPkt.HEData.User.EVMRMS;
                userRMS = cfgPkt.HEData.User.EVMMax;
                evmTable = table(numSTS,userEVM,userRMS);
                evmTable.Properties.VariableNames{1} = 'Spatial Stream Index';
                evmTable.Properties.VariableNames{2} = 'RMS EVM (dB)';
                evmTable.Properties.VariableNames{3} = 'Max EVM (dB)';
            elseif strcmp(x.Format,'VHT')
                if ~displayVHTPacket(x) % Do not process further for VHT MU packet if SIGB fails
                    T = [];
                    return
                end
                numUser = numel(x.PHYConfig);
                evmRMS = [];
                evmMax =[];
                numSTS = [];
                userIdx = [];
                for u=1:numUser
                    cfgRx = x.PHYConfig(u);
                    if cfgRx.STBC
                        nsts = cfgRx.NumSpaceTimeStreams/2;
                    else
                        nsts = cfgRx.NumSpaceTimeStreams;
                    end
                    evmRMS = [evmRMS; x.VHTData.User(u).EVMRMS];
                    evmMax = [evmMax; x.VHTData.User(u).EVMMax];
                    numSTS =  [numSTS; (1:nsts).'];
                    userIdx = [userIdx; ones(nsts,1)*u];
                end

                evmTable = table(userIdx,numSTS,evmRMS,evmMax);
                evmTable.Properties.VariableNames{1} = 'User Number';
                evmTable.Properties.VariableNames{2} = 'Spatial Stream Index';
                evmTable.Properties.VariableNames{3} = 'RMS EVM (dB)';
                evmTable.Properties.VariableNames{4} = 'Max EVM (dB)';
            elseif strcmp(x.Format,'HT-MF')
                numSTS = numel(x.HTData.EVMRMS); % Number of space-time streams
                evmTable = table((1:numSTS).',x.HTData.EVMRMS,x.HTData.EVMMax);
                evmTable.Properties.VariableNames{1} = 'Spatial Stream Index';
                evmTable.Properties.VariableNames{2} = 'RMS EVM (dB)';
                evmTable.Properties.VariableNames{3} = 'Max EVM (dB)';
            end

            if nargout
                T = evmTable;
            end
        end

        function T = macSummary(obj,pktNum)
            %macSummary Display MAC summary of the selected packet
            %
            %   macSummary(ANALYZER,PKTNUM) displays the MAC contents of the
            %   selected packet, PKTNUM.
            %
            %   The table contains the following columns:
            %
            %   FCS Status         Indicates whether the Frame Check Sequence (FCS),
            %                      a cyclic redundancy check (CRC) used for error
            %                      detection in WLAN frames, has passed or failed.
            %                      The FCS is computed at the transmitter and
            %                      appended to the frame before transmission. Upon
            %                      reception, the receiver recomputes the FCS and
            %                      compares it with the transmitted value.
            %
            %                      Pass: Indicates that the frame was received
            %                            without detected errors.
            %
            %                      Fail: FCS Status is fail for a MAC frame
            %                      if any MPDU within an A-MPDU fails the
            %                      FCS.
            %
            %                      Not Verified: Indicates that the FCS check was
            %                                    not performed due to insufficient
            %                                    MAC frame data, making it impossible
            %                                    to determine the frame's sub-type.
            %
            %   MAC Frame Sub-type         Specifies the MAC contents of the detected packet.
            %                              The sub-type is determined based on the decoded
            %                              MAC frame and is displayed as one of the following:
            %
            %                              **RTS, CTS, ACK, BlockAck, CF-End, Trigger, Data, Null, QoS Data, QoS Null, Beacon**
            %
            %                              - **Unknown** : Displayed when:
            %                                  â€¢ An unsupported MAC frame type or subtype is detected.
            %                                  â€¢ All users A-MPDUs fail deaggregation.
            %                              - **Not enough data** : Displayed if MAC frame data is insufficient.
            %                              - **Unsupported protocol version** : Displayed for invalid versions.
            %                              - **-(Not displayed)** : If frame check fails (FCS Fail).
            %
            %
            %   T = macSummary(ANALYZER,PKTNUM) returns the summary of the
            %   selected packet in a table.

            checkWaveformProcessed(obj);
            if isempty(obj.Results)
                T = [];
                return;
            end
            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};

            if ~x.MAC(1).Processed
                % MAC information is not displayed for an unsupported
                % packet format or unsuccessful(PHY) status. No MAC is
                % displayed for an NDP packet.
                T = [];
                return;
            end
            mpduBits = [];
            if any(strcmp(x.Format,{'EHT-MU','HE-SU','HE-MU','HE-EXT-SU','VHT','HT-MF'})) && ~strcmp(x.MAC(1).DeagStatus,'N/A') % If deaggregation is N/A for the first users only possible in HT-MF
                numUsers = numel(x.PHYConfig);
                count = 0;
                ampduIndex = [];
                for u=1:numUsers
                    macInfo = x.MAC(u); % MAC info per user
                    deagStatus = macInfo.DeagStatus;
                    if strcmp(deagStatus,"Success")
                        numMPDU = numel(macInfo.MPDU);
                        for m=1:numMPDU
                            if strcmp(macInfo.MPDU(m).DecodeStatus, "FCSFailed")
                                % FCS Status = Fail;
                                macFrameType(count+m,1) = "-";
                                mpduDecodeStatus(count+m,1) = "Fail";
                            else
                                mpduContents1 = x.MAC(u).MPDUList;
                                decOctets = hex2dec(mpduContents1{1});
                                if ~isempty(decOctets)
                                    mpduBits(count+m,:) = int2bit(decOctets,8,false);
                                end
                                if (numel(mpduBits)/8 < 6) % FCS Status: Not Verified when MAC frame lacks enough data to determine its sub-type
                                    mpduDecodeStatus(count+m,1) = "Not Verified";
                                    macFrameType(count+m,1) = "Not enough data";
                                else
                                    % FCS Status = Pass;
                                    mpduDecodeStatus(count+m,1) = "Pass";
                                    if strcmp(macInfo.MPDU(m).DecodeStatus, "InvalidProtocolVersion")
                                        macFrameType(count+m,1) = "Unsupported protocol version";
                                    elseif any(strcmp(macInfo.MPDU(m).DecodeStatus, ["UnsupportedFrameType" "UnsupportedFrameSubtype"]))
                                        macFrameType(count+m,1) = "Unsupported type";
                                    else
                                        % Frame sub-type known
                                        macFrameType(count+m,1) = string(x.MAC(u).MPDU(m).Config.FrameType);
                                    end
                                end
                            end
                            ampduIndex = [ampduIndex; string(sprintf('AMPDU%d_MPDU%d',u,m))];
                        end
                        count = count+numMPDU;
                    else
                        macFrameType(count+1,1) = "-";
                        mpduDecodeStatus(count+1,1) = macInfo.DeagStatus;
                        ampduIndex = [ampduIndex; string(sprintf('AMPDU%d_MPDU%d',u,1))];
                        count = count+1;
                    end
                end
            else % NonHT or HT-MF format with no AMPDU
                macInfo = x.MAC; % MAC info per user
                if strcmp(macInfo.MPDU.DecodeStatus, "FCSFailed") % FCS Status = Fail;
                    macFrameType = "-";
                    mpduStatus = "Fail";
                else
                    psduBits = x.PSDU;
                    if (numel(psduBits)/8 < 6)
                        mpduStatus = "Not enough data";
                        macFrameType = "Not enough data";
                    else % FCS Status = Pass;
                        mpduStatus = "Pass";
                        if strcmp(macInfo.MPDU.DecodeStatus, "InvalidProtocolVersion")
                            macFrameType = "Unsupported protocol version";
                        elseif any(strcmp(macInfo.MPDU.DecodeStatus, ["UnsupportedFrameType" "UnsupportedFrameSubtype"]))
                            macFrameType = "Unsupported type";
                        else
                            % Frame sub-type known
                            macFrameType = string(x.MAC.MPDU.Config.FrameType);
                        end
                    end
                end
            end

            useMpduStatus = strcmp(x.Format, 'Non-HT') || (strcmp(x.Format, 'HT-MF') && strcmp(x.MAC(1).DeagStatus, 'N/A'));
            if useMpduStatus
                statusVar = mpduStatus;
            else
                statusVar = mpduDecodeStatus;
            end
            macSummary = table(string(statusVar), macFrameType);
            macSummary.Properties.VariableNames = {'FCS Status', 'MAC Frame Sub-type'};

            if nargout
                T = macSummary;
            end
        end

        function plotSubcarrierEVM(obj, hFig, pktNum)
            %plotSubcarrierEVM Plot EVM per subcarrier and data field symbols of a
            %selected packet. The plotted EVM is additionally averaged over
            %spatial streams.

            ax = axes(hFig); %#ok<LAXES>
            set(hFig, 'NumberTitle', 'off', 'Name', 'Subcarrier EVM',...
                 'Color',[1 1 1]*0.13);
            axis(ax, 'xy');
            hold(ax, 'on');
            set(ax,'Color',[0 0 0],'XColor',[1 1 1]*0.8,'YColor',...
                [1 1 1]*0.8,'ZColor',[1 1 1]*0.8,'FontSize',9);
            xlabel(ax,'Subcarrier Index','Color',[1 1 1]*0.8,'FontSize',9);
            ylabel(ax,'EVM (dB)','Color',[1 1 1]*0.8,'FontSize',9);
            grid(ax,'on');
            ax.GridColor = [1 1 1]*0.8;
            box(ax,'on');

            if isempty(obj.Results) || obj.DisablePlots
                return
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);

            x = obj.Results{pktNum};
            if ~strcmp(x.Status,"Success")
                return;
            end
            numUsers = numel(x.PHYConfig);
            if strcmp(x.Format,'Non-HT')
                cfgUser = x.PHYConfig;
                eqSym = x.NonHTData.EQDataSym;
                [evmRMS,~,carrierIndex] = getEVMPerSubcarrier(eqSym,cfgUser,'Non-HT');
                plot(ax,carrierIndex,evmRMS,'.-');
                legendStr = 'Symbols';
            elseif strcmp(x.Format,'EHT-MU')
                if ~x.EHTData.Processed
                    return; % For NDP
                end
                staID = zeros(1,numUsers);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.EHTData.User(u).EQDataSym;
                    [evmRMS,~,carrierIndex] = getEVMPerSubcarrier(eqSymUser,cfgUser,'EHT');
                    plot(ax,carrierIndex,evmRMS,'.-');
                    staID(u) = cfgUser.STAID;
                end
                legendStr = arrayfun(@(x)sprintf('STAID %d',x),staID,'UniformOutput',false);
            elseif any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU'}))
                if ~x.HEData.Processed
                    return; % For NDP
                end
                staID = zeros(1,numUsers);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.HEData.User(u).EQDataSym;
                    [evmRMS,~,carrierIndex] = getEVMPerSubcarrier(eqSymUser,cfgUser,'HE');
                    plot(ax,carrierIndex,evmRMS,'.-');
                    staID(u) = cfgUser.STAID;
                end
                legendStr = arrayfun(@(x)sprintf('STAID %d',x),staID,'UniformOutput',false);
            elseif strcmp(x.Format,'VHT')
                if ~x.VHTData.Processed
                    return; % For NDP
                end
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.VHTData.User(u).EQDataSym;
                    [evmRMS,~,carrierIndex] = getEVMPerSubcarrier(eqSymUser,cfgUser,'VHT');
                    plot(ax,carrierIndex,evmRMS,'.-');
                end
                legendStr = arrayfun(@(x)sprintf('User %d',x),(1:numUsers).','UniformOutput',false);
            elseif strcmp(x.Format,'HT-MF')
                if ~x.HTData.Processed
                    return; % For NDP
                end
                cfgUser = x.PHYConfig;
                eqSymUser = x.HTData.EQDataSym;
                [evmRMS,~,carrierIndex] = getEVMPerSubcarrier(eqSymUser,cfgUser,'HT-MF');
                plot(ax,carrierIndex,evmRMS,'.-');
                legendStr = 'Symbols';
            end
            xlim(ax,[carrierIndex(1) carrierIndex(end)]);
            legendFlag = ~any(strcmp(x.Format,{'Non-HT','HT-MF','HE-SU'})) && ~(any(strcmp(x.Format,{'VHT','EHT-MU'})) && numUsers==1) && numUsers <5;
            if legendFlag
                legend(ax,legendStr,'Location','NorthEast','Color',[1 1 1]*0.10,'EdgeColor',[1 1 1],'TextColor',[1 1 1]*0.85);
            end
        end

        function plotSymbolEVM(obj, hFig, pktNum)
            ax = axes(hFig); %#ok<LAXES>
            set(hFig, 'NumberTitle', 'off', 'Name', 'Symbol EVM',...
                'Color',[1 1 1]*0.13);
            axis(ax, 'xy');
            hold(ax, 'on');
            set(ax,'Color',[0 0 0],'XColor',[1 1 1]*0.8,'YColor',...
                [1 1 1]*0.8,'ZColor',[1 1 1]*0.8,'FontSize',9);
            xlabel(ax,'Symbol Number','Color',[1 1 1]*0.8,'FontSize',9);
            ylabel(ax,'EVM (dB)','Color',[1 1 1]*0.8,'FontSize',9);
            grid(ax,'on');
            ax.GridColor = [1 1 1]*0.8;
            box(ax,'on');

            if isempty(obj.Results) || obj.DisablePlots
                return
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);

            x = obj.Results{pktNum};
            if ~strcmp(x.Status,"Success")
                return;
            end
            numUsers = numel(x.PHYConfig);
            % Plot EVM per symbol
            if strcmp(x.Format,'Non-HT')
                cfgUser = x.PHYConfig;
                eqSym = x.NonHTData.EQDataSym;
                [evmRMS,~] = getEVMPerSymbol(eqSym,cfgUser);
                plot(ax,1:numel(evmRMS),evmRMS,'.-');
                legendStr = 'Symbols';
            elseif any(strcmp(x.Format,'EHT-MU'))
                if ~x.EHTData.Processed
                    return; % For NDP
                end
                staID = zeros(1,numUsers);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.EHTData.User(u).EQDataSym;
                    [evmRMS,~] = getEVMPerSymbol(eqSymUser,cfgUser);
                    plot(ax,1:numel(evmRMS),evmRMS,'.-');
                    staID(u) = cfgUser.STAID;
                end
                legendStr = arrayfun(@(x)sprintf('STAID %d',x),staID,'UniformOutput',false);
            elseif any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU'}))
                if ~x.HEData.Processed
                    return; % For NDP
                end
                staID = zeros(1,numUsers);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.HEData.User(u).EQDataSym;
                    [evmRMS,~] = getEVMPerSymbol(eqSymUser,cfgUser);
                    plot(ax,1:numel(evmRMS),evmRMS,'.-');
                    staID(u) = cfgUser.STAID;
                end
                legendStr = arrayfun(@(x)sprintf('STAID %d',x),staID,'UniformOutput',false);
            elseif strcmp(x.Format,'VHT')
                if ~x.VHTData.Processed
                    return; % For NDP
                end
                numUsers = numel(x.PHYConfig);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.VHTData.User(u).EQDataSym;
                    [evmRMS,~] = getEVMPerSymbol(eqSymUser,cfgUser);
                    plot(ax,1:numel(evmRMS),evmRMS,'.-');
                end
                legendStr = arrayfun(@(x)sprintf('User %d',x),(1:numUsers).','UniformOutput',false);
            else % HT-MF
                if ~x.HTData.Processed
                    return; % For NDP
                end
                numUsers = 1;
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.HTData.EQDataSym;
                    [evmRMS,~] = getEVMPerSymbol(eqSymUser,cfgUser);
                    plot(ax,1:numel(evmRMS),evmRMS,'.-');
                end
                legendStr = 'Symbols';
            end
            legendFlag = ~any(strcmp(x.Format,{'Non-HT','HT-MF','HE-SU'})) && ~(any(strcmp(x.Format,{'VHT','EHT-MU'})) && numUsers==1) && numUsers<5;
            if legendFlag
                legend(ax,legendStr,'Location','NorthEast','Color',[1 1 1]*0.10,'EdgeColor',[1 1 1],'TextColor',[1 1 1]*0.85);
            end
        end

        function plotSpectralFlatness(obj,hFig,chanbw,pktNum)
            %plotSpectralFlatness Plot spectral flatness of a selected
            %packet.
            ax = axes(hFig);
            set(hFig, 'NumberTitle', 'off', 'Name', 'Spectral Flatness',...
                'Color',[1 1 1]*0.13);
            axis(ax, 'xy');
            hold(ax, 'on');
            set(ax,'Color',[0 0 0],'XColor',[1 1 1]*0.8,'YColor',...
                [1 1 1]*0.8,'ZColor',[1 1 1]*0.8,'FontSize',9);
            ylabel(ax,'Deviation (dB)','Color',[1 1 1]*0.8,'FontSize',9);
            xlabel(ax,'Subcarrier Index','Color',[1 1 1]*0.8,'FontSize',9);
            grid(ax,'on');
            ax.GridColor = [1 1 1]*0.8;
            hold(ax,'on');
            box(ax,'on');

            if isempty(obj.Results)
                return;
            end
            checkWaveformProcessed(obj);
            validatePktNum(obj.Results,pktNum);

            x = obj.Results{pktNum};
            if ~strcmp(x.Status,"Success")
                return;
            end

            % Set this flag to false by default for any WLAN packet format
            isPreamblePunc = false;
            isOFDMA = false;
            switch x.Format
                case "Non-HT"
                    pktFormat = "Non-HT";
                    chanEst = x.Preamble.ChanEstNonHT;
                case "VHT"
                    pktFormat = "VHT";
                    chanEst = x.VHTPreamble.ChanEst;
                case "HT-MF"
                    pktFormat = "HT";
                    chanEst = x.HTPreamble.ChanEst;
                case "EHT-MU"
                    pktFormat = "EHT";
                    firstRUSize = x.EHTPreamble.RU(1).RUSize;
                    fullBWRUSize = wlan.internal.heFullBandRUSize(x.PHYConfig(1).ChannelBandwidth);
                    % If 1st RU size is equal to the size of full bandwidth RU,
                    % then it is a full BW waveform (non-punctured)
                    fullBW = sum(firstRUSize)==fullBWRUSize;
                    if fullBW || x.PHYConfig(1).EHTDUPMode
                        % Full-bandwidth (non-punctured)
                        chanEst = x.EHTPreamble.RU(1).ChanEst;
                        ruIndices = {x.EHTPreamble.RU(1).RUIndex};
                        ruSizes = {x.EHTPreamble.RU(1).RUSize};
                    else
                        % EHT OFDMA waveform or non-OFDMA preamble-punctured
                        % waveform
                        numRUs = numel(x.EHTPreamble.RU);
                        for i = 1:numRUs
                            ruIndices{i,1} = x.EHTPreamble.RU(i).RUIndex;
                            ruSizes{i,1} = x.EHTPreamble.RU(i).RUSize;
                            chanEst{i,1} = x.EHTPreamble.RU(i).ChanEst;
                        end
                        if (any(x.PHYConfig(1).PuncturedPattern == 0,'all'))...
                                || (x.PHYConfig(1).PuncturedChannelFieldValue > 0)
                            isPreamblePunc = true;
                        end
                    end
                otherwise % "HE-SU","HE-MU", or "HE-EXT-SU"
                    pktFormat = "HE";
                    firstRUSize = x.HEPreamble.RU(1).RUSize;
                    fullBWRUSize = wlan.internal.heFullBandRUSize(x.PHYConfig(1).ChannelBandwidth);
                    % If 1st RU size is equal to the size of full bandwidth RU,
                    % then it is a full BW (non-OFDMA) waveform
                    fullBW = firstRUSize==fullBWRUSize;
                    if fullBW
                        % Full-bandwidth waveform
                        chanEst = x.HEPreamble.RU(1).ChanEst;
                    else
                        % HE OFDMA waveform
                        isOFDMA = true;
                        numRUs = numel(x.HEPreamble.RU);
                        for i = 1:numRUs
                            ruIndices(i) = x.HEPreamble.RU(i).RUIndex;
                            chanEst{i,1} = x.HEPreamble.RU(i).ChanEst;
                        end
                    end
            end

            if iscell(chanEst)
				% Remove RU specific scaling for HE/EHT OFDMA waveforms
				% that was applied by wlan.internal.ehtLTFDemodulate
				% function
                for ruNum = 1:length(chanEst)
                    currRUSize = size(chanEst{ruNum},1);
                    chanEst{ruNum} = chanEst{ruNum}/sqrt(currRUSize);
                end
            end

            if strcmp(pktFormat,'EHT') % EHT all configurations
                [~,deviation,testSC] = wlanSpectralFlatness(chanEst,pktFormat,chanbw,ruIndices,ruSizes,isPreamblePunc);
            elseif strcmp(pktFormat,'HE') & isOFDMA % HE OFDMA
                [~,deviation,testSC] = wlanSpectralFlatness(chanEst,pktFormat,chanbw,ruIndices);
            else % HE non-OFDMA and VHT/HT/Non-HT
                [~,deviation,testSC] = wlanSpectralFlatness(chanEst,pktFormat,chanbw);
            end
            
            if obj.DisablePlots
                return;
            end
            % Plot spectral flatness
            alldev = vertcat(deviation{:});
            if iscolumn(testSC{1})
                allSC = vertcat(testSC{:});
            else % testSC are row vectors
                allSC = horzcat(testSC{:}).';
            end

            plot(ax,allSC,alldev,'.');
            ylim(ax,[min(-6.5,min(alldev(:))), max(4.5,max(alldev(:)))]);

            % Overlay lower limits
            indRange = (min(allSC):max(allSC)).';
            if isPreamblePunc
                dBr = [-6 -6]; % Lower limit for two sets of test subcarriers
            else
                dBr = [-4 -6];
            end
            limitPlot(ax, dBr,indRange,testSC);
            % Overlay upper limits
            dBr = [+4 +4]; % Upper limit for two sets of test subcarriers
            limitPlot(ax, dBr,indRange,testSC);

            hold(ax,'off');

            % Create legend
            numAnts = size(alldev,2);
            legendEntries = cell(numAnts+1,1);
            legendEntries(1:numAnts) = arrayfun(@(x)sprintf('Antenna %d',x), ...
                1:numAnts,'UniformOutput',false);
            legendEntries{numAnts+1} = 'Deviation limit';
            legend(ax,legendEntries,'location','NorthEast','Color',[1 1 1]*0.10,'EdgeColor',[1 1 1],'TextColor',[1 1 1]*0.85);
        end

        function [eqSym, referenceConstellation, legendStr] = plotConstellation(obj, pktNum)
            eqSym = [];
            legendStr = [];
            referenceConstellation = [];
            if isempty(obj.Results) || obj.DisablePlots
                return;
            end

            if ~obj.isProcessed || isempty(obj.Results)
                error('No waveform to anaylze')
            end

            validatePktNum(obj.Results,pktNum);
            x = obj.Results{pktNum};
            if ~strcmp(x.Status,"Success")
                return;
            end

            if strcmp(x.Format,'Non-HT')
                numUsers = 1;
                eqSymTemp = x.NonHTData.EQDataSym;
                eqSym{1} = eqSymTemp(:);
                legendStr = 'Symbols';
            elseif strcmp(x.Format,'EHT-MU')
                if ~x.EHTData.Processed
                    return; % For NDP
                end
                numUsers = numel(x.PHYConfig);
                staID = zeros(1,numUsers);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.EHTData.User(u).EQDataSym;
                    [Nsd,Nsym,Nss] = size(eqSymUser);
                    eqDataSymTemp = reshape(eqSymUser,Nsd*Nsym,Nss);
                    eqSym{u} = eqDataSymTemp(:);
                    staID(u) = cfgUser.STAID;
                end
                if numUsers == 1
                    legendStr = 'Symbols';
                else
                    legendStr = arrayfun(@(x)sprintf('STAID %d',x),staID,'UniformOutput',false);
                end
            elseif any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU'}))
                if ~x.HEData.Processed
                    return; % For NDP
                end
                numUsers = numel(x.PHYConfig);
                staID = zeros(1,numUsers);
                for u=1:numUsers
                    cfgUser = x.PHYConfig(u);
                    eqSymUser = x.HEData.User(u).EQDataSym;
                    [Nsd,Nsym,Nss] = size(eqSymUser);
                    eqSymTemp = reshape(eqSymUser,Nsd*Nsym,Nss);
                    eqSym{u} = eqSymTemp(:);
                    staID(u) = cfgUser.STAID;
                end
                if strcmp(x.Format,'HE-SU')
                    legendStr = 'Symbols';
                else
                    legendStr = arrayfun(@(x)sprintf('STAID %d',x),staID,'UniformOutput',false);
                end
            elseif strcmp(x.Format,'VHT')
                if ~x.VHTData.Processed
                    return; % For NDP
                end
                numUsers = numel(x.PHYConfig);
                for u=1:numUsers
                    eqSymUser = x.VHTData.User(u).EQDataSym;
                    [Nsd,Nsym,Nss] = size(eqSymUser);
                    eqSymTemp = reshape(eqSymUser,Nsd*Nsym,Nss);
                    eqSym{u} = eqSymTemp(:);
                end
                if numUsers==1
                    legendStr = 'Symbols';
                else
                    legendStr = arrayfun(@(x)sprintf('User %d',x),1:numUsers,'UniformOutput',false);
                end
            elseif strcmp(x.Format,'HT-MF')
                if ~x.HTData.Processed
                    return; % For NDP
                end
                numUsers = numel(x.PHYConfig);
                eqSymUser = x.HTData.EQDataSym;
                [Nsd,Nsym,Nss] = size(eqSymUser);
                eqSym = reshape(eqSymUser,Nsd*Nsym,Nss);
                eqSym = eqSym(:);
                legendStr = 'Symbols';
            end

            % Plot reference constellation for all users
            for u=1:numUsers
                cfgUser = x.PHYConfig(u);
                referenceConstellation{u} = complex(wlanReferenceSymbols(cfgUser));
            end
        end

        function process(obj,rxWaveform,chanbw,varargin)
            %process Detect, decode and analyze WLAN packets within a waveform
            %   process(ANALYZER,WAVEFORM,CHANBW) performs analysis of packets
            %   within a waveform.
            %
            %   WAVEFORM is a Ns-by-Nr complex array containing the waveform to
            %   process. Ns is the number of samples and Nr is the number of
            %   receive antennas.
            %
            %   CHANBW is the channel bandwidth of packets within WAVEFORM.
            %   It must be 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
            %   'CBW320'.
            %
            %   process(ANALYZER,WAVEFORM,CHANBW,SR) additionally allows the
            %   sample rate of WAVEFORM to be specified in Hertz. If not
            %   provided the nominal sample rate of CHANBW is assumed. If SR is
            %   greater than the nominal sample rate, the waveform is
            %   resampled.

            rxWaveform = cast(rxWaveform,'double'); % Force the data type of rxWaveform to be double
            obj.Results = process@wirelessWaveformAnalyzer.internal.WaveformAnalysisEngine(obj,rxWaveform,chanbw,varargin{:});
        end

        function results = getResults(obj)
            %getResults Returns analysis results
            %   RESULTS is a cell array of structures, RESULTS, containing the
            %   analysis result for each detected packet. The structure
            %   contents depends on the detected packet format and contents.

            checkWaveformProcessed(obj);
            results = obj.Results;
        end
    end
end

function [evmRMS,evmMAX,carrierIndex] = getEVMPerSubcarrier(eqDataSym,cfgRx,field)
% getEVMPerSubcarrier Get EVM per subcarrier
EVM = comm.EVM;
EVM.AveragingDimensions = [2 3];
EVM.MaximumEVMOutputPort = true;
EVM.ReferenceSignalSource = 'Estimated from reference constellation';
if cfgRx.MCS==0
    EVM.ReferenceConstellation = complex(wlanReferenceSymbols(cfgRx));
else
    EVM.ReferenceConstellation = wlanReferenceSymbols(cfgRx);
end
[rmsEVM,maxEVM] = EVM(eqDataSym);

switch field
    case 'EHT'
        ofdmInfo = wlan.internal.ehtOFDMInfo('EHT-Data',cfgRx.ChannelBandwidth,cfgRx.GuardInterval,cfgRx.RUSize,cfgRx.RUIndex);
    case 'HE'
        ofdmInfo = wlan.internal.heOFDMInfo('HE-Data',cfgRx.ChannelBandwidth,cfgRx.GuardInterval,cfgRx.RUSize,cfgRx.RUIndex);
    case 'VHT'
        ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-Data',cfgRx.ChannelBandwidth,cfgRx.GuardInterval);
    case 'HT-MF'
        ofdmInfo = wlan.internal.vhtOFDMInfo('HT-Data',cfgRx.ChannelBandwidth,cfgRx.GuardInterval);
    otherwise % Non-HT
        ofdmInfo = wlan.internal.vhtOFDMInfo('NonHT-Data',cfgRx.ChannelBandwidth);
end
dataInd = ofdmInfo.ActiveFFTIndices(ofdmInfo.DataIndices);
Nfft = ofdmInfo.FFTLength;

evmRMS = nan(Nfft,1);
evmMAX = nan(Nfft,1);
evmRMS(dataInd,1) = 20*log10(rmsEVM/100);
evmMAX(dataInd,1) = 20*log10(maxEVM/100);
carrierIndex = -Nfft/2:Nfft/2-1;
end

function [rmsEVMSym,maxEVMSym] = getEVMPerSymbol(eqSymUser,cfgRx)
%getEVMPerSymbol EVM per symbols
EVM = comm.EVM;
EVM.AveragingDimensions = [1 3];
EVM.MaximumEVMOutputPort = true;
EVM.ReferenceSignalSource = 'Estimated from reference constellation';

if cfgRx.MCS==0
    EVM.ReferenceConstellation = complex(wlanReferenceSymbols(cfgRx));
else
    EVM.ReferenceConstellation = wlanReferenceSymbols(cfgRx);
end
[rmsEVM,maxEVM] = EVM(eqSymUser); % Follow same averaging as above i.e. use EVM to average = [1 3];

rmsEVMSym = 20*log10(rmsEVM/100);
maxEVMSym = 20*log10(maxEVM/100);
end

function T = displayLSIGContents(processPkt)
%displayLSIGContents Display LSIG field contents and dynamic bandwidth
%channel information for a non-HT duplicate packet.
lsigInfo = processPkt.LSIG.Info;
column = ["L-SIG Length","L-SIG Rate","Signaled Channel Bandwidth","Dynamic Bandwidth Operation"];
if ischar(processPkt.NonHTData.DynamicBandwidthOperation)
    dynBW = processPkt.NonHTData.DynamicBandwidthOperation;
else
    dynBW = 'False';
    if processPkt.NonHTData.DynamicBandwidthOperation
        dynBW = 'True';
    end
end
value = [string(lsigInfo.Length),string(lsigRate(lsigInfo.MCS)),string(processPkt.NonHTData.ChannelBandwidth),string(dynBW)];
Tvalue = rows2vars(table(value.'));
Tcolumn = rows2vars(table(column.'));
Tcolumn(:,1) = [];
Tvalue(:,1) = [];
Tparam = table2array(Tcolumn);
Tvalue.Properties.VariableNames = Tparam;
T = Tvalue;
end

function out = lsigRate(mcs)
%lsigRate LSIG field rate table
switch mcs
    case 0
        rate = [1 1 0 1];
    case 1
        rate = [1 1 1 1];
    case 2
        rate = [0 1 0 1];
    case 3
        rate = [0 1 1 1];
    case 4
        rate = [1 0 0 1];
    case 5
        rate = [1 0 1 1];
    case 6
        rate = [0 0 0 1];
    otherwise
        rate = [0 0 1 1];
end
out = ['0x' dec2hex(bit2int(rate',4,false))];
end

function out = n2str(in)
%n2str Number to string conversion
inLen = numel(in);
for i=1:inLen
    if sign(in(i))==-1
        out(i,1:7) = pad(num2str(in(i),'%10.2f'),7); %#ok<*AGROW>
    else
        out(i,1:7) = pad([' ' num2str(in(i),'%10.2f')],7);
    end
end
end

function [mod,rate] = getHERateDependentParameters(mcs,varargin)
%getHERateDependentParameters Get modulation and rate information
dataType = 'char';
if nargin>1
    dataType = varargin{1};
end
if mcs==0
    mod = "BPSK";
    rate = "1/2";
elseif mcs==1
    mod = "QPSK";
    rate = "1/2";
elseif mcs==2
    mod = "QPSK";
    rate = "3/4";
elseif mcs==3
    mod = "16QAM";
    rate = "1/2";
elseif mcs==4
    mod = "16QAM";
    rate = "3/4";
elseif mcs==5
    mod = "64QAM";
    rate = "2/3";
elseif mcs==6
    mod = "64QAM";
    rate = "3/4";
elseif mcs==7
    mod ="64QAM";
    rate = "5/6";
elseif mcs==8
    mod ="256QAM";
    rate = "3/4";
elseif mcs==9
    mod ="256QAM";
    rate = "5/6";
elseif mcs==10
    mod ="1024QAM";
    rate = "3/4";
elseif mcs==11
    mod ="1024QAM";
    rate = "5/6";
elseif mcs==12
    mod ="4096QAM";
    rate = "3/4";
elseif mcs==13
    mod ="4096QAM";
    rate = "5/6";
else % MCS 15
    mod ="BPSK-DCM";
    rate = "1/2";
end

if strcmp(dataType,'char')
    % mod = [char(mod) pad('',10-numel(char(mod)))];
    mod = [char(mod)];
end
end

function [mod,rate] = getNonHTRateDependentParameters(mcs,varargin)
%getNonHTRateDependentParameters Get modulation and rate information
dataType = 'char';
if nargin>1
    dataType = varargin{1};
end
if mcs==0
    mod = "BPSK";
    rate = "1/2";
elseif mcs==1
    mod = "BPSK";
    rate = "3/4";
elseif mcs==2
    mod = "QPSK";
    rate = "1/2";
elseif mcs==3
    mod = "QPSK";
    rate = "3/4";
elseif mcs==4
    mod = "16QAM";
    rate = "1/2";
elseif mcs==5
    mod = "16QAM";
    rate = "3/4";
elseif mcs==6
    mod = "64QAM";
    rate = "2/3";
else %mcs==7 & 8
    mod ="64QAM";
    rate = "3/4";
end

if strcmp(dataType,'char')
    mod = [char(mod) pad('',5-numel(char(mod)))];
end
end

function out = powerdBm(in)
%powerdBm Power in dBm
out = round(10*log10(in)+30,2);
end

function checkWaveformProcessed(obj)
%checkWaveformProcessed Check processed waveform
if ~obj.isProcessed
    error('No waveform processed.');
end
end

function validatePktNum(in,pktNum)
%validatePktNum Validate packet number
if pktNum>numel(in)
    error('Invalid packet selection. The selected packet should be between 1 and %d',numel(in));
end
end

function flag = isDataProcessed(x)
%isDataProcessed Table display check flag
if any(strcmp(x.Format,{'HE-SU','HE-MU','HE-EXT-SU'}))
    dataProcessed = x.HEData.Processed;
elseif strcmp(x.Format,'EHT-MU')
    dataProcessed = x.EHTData.Processed;
elseif strcmp(x.Format,'VHT')
    dataProcessed = x.VHTData.Processed;
elseif strcmp(x.Format,'HT-MF')
    dataProcessed = x.HTData.Processed;
end

flag = ~strcmp(x.Status,"Success") || ~any(strcmp(x.Format,{'EHT-MU','HE-SU','HE-MU','HE-EXT-SU','VHT','HT-MF'})) || ~dataProcessed;
end

function [evmRMS,evmMax] = getPacketEVM(pktField)
%getPacketEVM Returns RMS EVM in dBs of the data field average over all
%space-time streams and users. Also returns Max EVM in dBs of the data
%field across all space-time streams and users.

numUsers = numel(pktField);
userEVMRMS = [];
userEVMMax = [];
for u=1:numUsers
    if pktField(u).Processed
        userEVMRMS = [userEVMRMS pktField(u).EVMRMS.'];
        userEVMMax = [userEVMMax pktField(u).EVMMax.'];
    end
end
evmRMS = mag2db(mean(db2mag(userEVMRMS))); % Average over all space-time streams for each user
evmMax = max(userEVMMax); % The value is the max of the EVM across all space-time streams between all users
end

function processPkt = displayVHTPacket(x)
%displayVHTPacket Indicate whether to display the contents of a VHT packet

if ~strcmp(x.Status,'Success') || (x.VHTData.Processed==1 && strcmp(x.VHTData.Status,'VHT-SIG-B CRC fail for at least one user'))
    processPkt = false; % Do not display the contents of a VHT packet if any user fails, VHT-SIG-B CRC
    return
end

cfgRx = x.VHTSIGA.PHYConfig;
numUsers = cfgRx.NumUsers;

if numUsers==1
    processPkt = true;
else
    flag = [];
    for u=1:numUsers
        flag = [flag (x.VHTSIGB.User(u).Processed && ~x.VHTSIGB.User(u).FailInterp)];
    end
    processPkt = ~any(flag==false); % Do not process if any user fails check on VHT-SIG-B field
end
end

function limitPlot(ax, dBr,indRange,testSC)
lim = nan(numel(indRange),1);
[~,ia] = intersect(indRange,testSC{1});
lim(ia) = dBr(1)*ones(size(testSC{1}));
[~,ia] = intersect(indRange,testSC{2});
lim(ia) = dBr(2)*ones(size(testSC{2}));
plot(ax,indRange,lim,'y-');
end

function y = mruString(x)
mru = strrep(num2str(x),'  ',' '); % Remove extra space between characters
switch mru
    case '484 242'
        y = '484+242    ';
    case '996 484'
        y = '996+484    ';
    case '996 484 242'
        y = '996+484+242';
    case '996 996 484'
        y = '2x996+484  ';
    case '996 996 996 484'
        y = '3x996+484  ';
    case '996 996 996'
        y = '3x996      ';
    case '52 26'
        y = '52+26      ';
    case '106  26'
        y = '106+26     ';
end
end
