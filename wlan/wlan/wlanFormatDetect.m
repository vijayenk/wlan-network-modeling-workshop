function format = wlanFormatDetect(rx,chanEst,noiseVarEst,chanBW,varargin)
%wlanFormatDetect Packet format detection
%   FORMAT = wlanFormatDetect(RX,CHANEST,NOISEVAREST,CHANBW) detects the
%   format of a packet, returning one of these values: Non-HT, HT-MF,
%   HT-GF, VHT, HE-SU, HE-EXT-SU, HE-MU, HE-TB, EHT-MU, EHT-TB, or
%   EHTValidate.
%
%   FORMAT is a character vector specifying the detected format of the
%   packet and is one of: 'Non-HT', 'HT-MF', 'HT-GF', 'VHT', 'HE-SU',
%   'HE-EXT-SU', 'HE-MU', 'HE-TB', 'EHT MU', 'EHT TB', or 'EHTValidate'.
%   See the wlanFormatDetect documentation.
%
%   RX is a time-domain signal containing the OFDM symbols immediately
%   following the L-LTF. It is a single or double complex matrix of size
%   Ns-by-Nr, where Ns represents the number of time-domain samples and Nr
%   represents the number of receive antennas. To successfully detect any
%   packet format, Ns must be greater than or equal to four times the OFDM
%   symbol duration in samples.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the L-LTF. It is a single or double complex array of size
%   Nst-by-1-by-Nr, where Nst is the total number of occupied subcarriers.
%   The singleton dimension corresponds to the single transmitted stream in
%   the L-LTF which includes the combined cyclic shifts if multiple
%   transmit antennas are used. The channel estimates must not include tone
%   rotation for each 20 MHz subchannel as described in IEEE Std
%   802.11-2016, section 21.3.7.5.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CHANBW is a character vector specifying the channel bandwidth and must
%   be one of these values: 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80',
%   'CBW160', or 'CBW320'.
%
%   FORMAT = wlanFormatDetect(..., NAME, VALUE) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'OFDMSymbolOffset'      OFDM symbol sampling offset. Specify the
%                           OFDMSymbolOffset as a fraction of the cyclic
%                           prefix (CP) length for every OFDM symbol,
%                           double precision, real scalar between 0 and 1,
%                           inclusive. The OFDM demodulation is performed
%                           based on Nfft samples following the offset
%                           position, where Nfft denotes the FFT length.
%                           The default value of this property is 0.75,
%                           which means the offset is three quarters of the
%                           CP length.
%
%   'EqualizationMethod'    Specify the equalization method as one of
%                           'MMSE' | 'ZF'. 'MMSE' indicates that the
%                           receiver uses a minimum mean square error
%                           equalizer. 'ZF' indicates that the receiver
%                           uses a zero-forcing equalizer. The default
%                           value of this property is 'MMSE'.
%
%   'PilotPhaseTracking'    Specify the pilot phase tracking performed as
%                           one of 'PreEQ' | 'None'. 'PreEQ' pilot phase
%                           tracking estimates and corrects a common phase
%                           offset across all subcarriers and receive
%                           antennas for each received OFDM symbol before
%                           equalization. 'None' indicates that pilot phase
%                           tracking does not occur. The default is 'PreEQ'.
%
%   'SuppressWarnings'     Suppress warnings, specified as true or
%                          false. Set to true to suppress warning messages.
%                          The default is false.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

narginchk(4,12)

% Validate Channel Bandwidth
chanBW = wlan.internal.validateParam('NONHTEHTCHANBW',chanBW,mfilename);

% Validate and parse optional inputs
recParams = wlan.internal.parseOptionalInputs(mfilename,varargin{:});

% Get OFDM configuration
cfgOFDM = wlan.internal.vhtOFDMInfo('VHT-SIG-A',chanBW);

% Validate signal input
validateattributes(rx,{'double','single'},{'2d','finite'},mfilename,'signal');
% Validate length of signal input
minInputLength = 3*5/4*cfgOFDM.FFTLength; % 4 standard OFDM symbols
coder.internal.errorIf(size(rx,1)<minInputLength,'wlan:wlanFormatDetect:ShortDataInput',minInputLength);

% Validate channel estimates
numRx = size(rx,2);
validateattributes(chanEst,{'double','single'},{'3d','finite'},mfilename,'chanEst');

% Cross validate inputs:chanEst
coder.internal.errorIf(size(chanEst,1)~=cfgOFDM.NumTones,'wlan:shared:InvalidChanEst1D',cfgOFDM.NumTones);
coder.internal.errorIf(size(chanEst,2)~=1,'wlan:shared:InvalidChanEst2D');
coder.internal.errorIf(size(chanEst,3)~=numRx,'wlan:shared:InvalidChanEst3D');

% Validate noise variance estimate input
validateattributes(noiseVarEst,{'double','single'},{'real','scalar','nonnegative','finite'},mfilename,'noiseVarEst');

format = 'Non-HT'; % For codegen
% Format is always non-HT for 5 and 10 MHz
if any(strcmp(chanBW,{'CBW5','CBW10'}))
    return;
end

Ns = cfgOFDM.NumSubchannels*80; % OFDM symbol duration in samples (80 samples @ 20 MHz)

if size(rx,1)>=Ns*4 % Check for HE and EHT packet
    % Detect repetition, correlate L-SIG with L-SIG and RL-SIG field
    corrFields = xcorr(sum(rx(1:Ns,:),2),sum(rx(1:2*Ns,:),2));
    normCorr = abs(corrFields)./max(abs(corrFields));
    % Find the index of first peak
    indexFirstPeak = find(normCorr==1);
    % Remove the first peak
    normCorr(indexFirstPeak(1)) = 0;
    % Find the index of second peak
    indexSecondPeak = find(normCorr==max(normCorr));
    % Calculate the separation between the two peaks in samples
    peakSeparation = indexSecondPeak(1)-indexFirstPeak(1);

    if mod(peakSeparation,Ns)==0 % Repetition detected
        preEHTInfo = preEHTOFDMInfo(cfgOFDM.NumSubchannels);

        % Demodulate L-SIG field, the demodulated symbols include gamma rotation
        lsigDemod = wlan.internal.ofdmDemodulate(rx(1:2*Ns,:),preEHTInfo,recParams.OFDMSymbolOffset);

        % Add gamma rotation to L-LTF channel estimates
        gamma = wlan.internal.vhtCarrierRotations(cfgOFDM.NumSubchannels);
        chanEstEHT = chanEst .* gamma(cfgOFDM.ActiveFFTIndices,:);

        % Scale up the channel estimates from legacy L-LTF field since the
        % HE, L-LTF field is scaled down as compared to other fields in HE
        epsilon = sqrt(size(chanEstEHT,1)/size(lsigDemod,1));
        chanEstEHT = chanEstEHT./epsilon;

        % Estimate CPE and phase correct symbols
        if strcmp(recParams.PilotPhaseTracking,'PreEQ')
            z = 0; % if z is 0 then there is no offset
            cpe = commonPhaseErrorEstimate(lsigDemod(preEHTInfo.PilotIndices,:,:),chanEstEHT(cfgOFDM.PilotIndices,:,:),chanBW,z);
            lsigDemod = wlan.internal.commonPhaseErrorCorrect(lsigDemod,cpe);
        end

        % Estimate channel on extra 4 subcarriers per subchannel and create full channel estimate
        preEHTChEst = wlan.internal.preHEChannelEstimate(lsigDemod,chanEstEHT,cfgOFDM.NumSubchannels);

        % Average L-SIG and RL-SIG before equalization
        lsigDemod = mean(lsigDemod,2);

        % Merge subchannels; channel estimates and demodulated symbols together for the repeated subcarriers
        [ofdmData20MHz,chanEstData20MHz] = wlan.internal.mergeSubchannels(lsigDemod(preEHTInfo.DataIndices,:,:), ...
                                                                          preEHTChEst(preEHTInfo.DataIndices,:,:),cfgOFDM.NumSubchannels);

        % Perform equalization
        [eqLSIGSym,csi] = wlan.internal.equalize(ofdmData20MHz,chanEstData20MHz,recParams.EqualizationMethod,noiseVarEst);

        % Decode L-SIG field
        [~,lsigFail,lsigInfo] = wlanLSIGBitRecover(eqLSIGSym,noiseVarEst,csi);

        % Ref: Figure 36-80 of IEEE P802.11be/D5.0
        m = 3-mod(lsigInfo.Length,3);

        if ~lsigFail(1) && lsigInfo.MCS==0
            rxSamples = rx(2*Ns+(1:2*Ns),:); % HE-SIG-A and U-SIG field samples for HE and EHT packet format respectively
            demodSym = wlan.internal.ofdmDemodulate(rxSamples,preEHTInfo,recParams.OFDMSymbolOffset);
            if strcmp(recParams.PilotPhaseTracking,'PreEQ')
                z = 2; % Offset to account for L-SIG and RL-SIG pilot symbol
                cpe = commonPhaseErrorEstimate(demodSym(preEHTInfo.PilotIndices,:,:),preEHTChEst(preEHTInfo.PilotIndices,:,:),chanBW,z);
                demodSym = wlan.internal.commonPhaseErrorCorrect(demodSym,cpe);
            end

            if any(m==[1 2]) % Content check for HE packet e.g. Parity check, MCS=0(rate=6Mbps) and m is 1 or 2
                % HE format detected, determine the HE packet type    
                % Merge subchannels; channel estimates and demodulated symbols together for the repeated subcarriers
                [ofdmData20MHz,chanEstData20MHz] = wlan.internal.mergeSubchannels(demodSym(preEHTInfo.DataIndices,:,:), ...
                                                                                  preEHTChEst(preEHTInfo.DataIndices,:,:),cfgOFDM.NumSubchannels);

                % Perform equalization
                [eqHESIGASym,csi] = wlan.internal.equalize(ofdmData20MHz,chanEstData20MHz,recParams.EqualizationMethod,noiseVarEst);

                if m==1
                    % HE-MU or HE-EXT-SU. If the second symbol is QBPSK, then HE-EXT-SU
                    if isqbpsk(eqHESIGASym(:,2,:))
                        % Packet is HE-EXT-SU
                        format = 'HE-EXT-SU';
                    else
                        % Packet is HE-MU
                        format = 'HE-MU';
                    end
                else % m==2
                     % Packet is HE-SU or HE-TB
                    [bits,failCRC] = wlanHESIGABitRecover(eqHESIGASym,noiseVarEst,csi);
                    if ~failCRC
                        if bits(1)==0
                            format = 'HE-TB';
                        else
                            format = 'HE-SU';
                        end
                    end
                end
                return
            else % Determine the EHT packet type as per Fig 36-80 of IEEE P802.11be/D5.0
                % Merge subchannels; channel estimates and demodulated symbols together for the repeated subcarriers
                [symMerge,chanMerge] = wlan.internal.ehtMergeUSIGSubchannels(demodSym(preEHTInfo.DataIndices,:,:),preEHTChEst(preEHTInfo.DataIndices,:,:),chanBW);
                % Equalize
                [sym,csi] = wlan.internal.equalize(symMerge,chanMerge,recParams.EqualizationMethod,noiseVarEst);

                % Recover U-SIG bits and CRC per 80 MHz subblock
                [bits,failCRC] = wlan.internal.ehtUSIGBitRecover(sym,noiseVarEst,csi);

                % EHT MU packet is detected if any 80 MHz subblock has a
                % valid CRC and the first symbols after RL-SIG field is not
                % QBPSK. Fig 36-80 of IEEE P802.11be/D5.0
                if any(failCRC==0) && ~isqbpsk(sym(:,1))
                    [uplinkIndication,compressionMode] = interpretUSIGBits(bits,failCRC);
                    if uplinkIndication==0 && any(compressionMode==[0 1 2])
                        format = 'EHT-MU';
                    elseif uplinkIndication==1 && compressionMode==0
                        format = 'EHT-TB';
                    elseif uplinkIndication==1 && compressionMode==1
                        format = 'EHT-MU';
                    else % uplinkIndication==0 && compressionMode==3 || uplinkIndication==1 && any(compressionMode==3)
                        format = 'EHTValidate'; % Table 36-29 of IEEE P802.11be/D5.0
                    end
                    return
                end
            end
        end
    end
end

% Demodulate L-SIG plus two additional symbols following L-SIG
[eqDataSym,csiData] = demodulateSymbols(rx(1:3*Ns,:),chanEst(cfgOFDM.DataIndices,:,:),chanEst(cfgOFDM.PilotIndices,:,:), ...
                                        chanBW,noiseVarEst,recParams.OFDMSymbolOffset,recParams.EqualizationMethod,recParams.PilotPhaseTracking,cfgOFDM);

% Demap and decode L-SIG symbols
[~,lsigFail,lsigInfo] = wlanLSIGBitRecover(eqDataSym(:,1),noiseVarEst,csiData);

% HT-GF detection
if any(strcmp(chanBW,{'CBW20','CBW40'})) && isqbpsk(eqDataSym(:,1))
    format = 'HT-GF';
    return;
end

% Warn if L-SIG check fails and SuppressWarning flag is false
% any is for codegen
if any(lsigFail) && ~recParams.SuppressWarnings
    coder.internal.warning('wlan:wlanFormatDetect:LSIGCheckFail');
end

% Determine format from MCS and QBPSK detection
if lsigInfo.MCS==0
    if any(strcmp(chanBW,{'CBW20','CBW40'})) && isqbpsk(eqDataSym(:,2))
        format = 'HT-MF';
    elseif isqbpsk(eqDataSym(:,3))
        format = 'VHT';
    else
        format = 'Non-HT';
    end
else
    format = 'Non-HT';
end

end


function result = isqbpsk(sym)
%isqbpsk Return true if the symbol is QBPSK and false if BPSK

    threshold = 0.5;
    Ns = size(sym,1); % Number of subcarriers
    metric = nnz(imag(sym(:)).^2>real(sym(:)).^2);
    result = metric>=(Ns*threshold);
end

function [eqDataSym,csiData] = demodulateSymbols(rx,chanEstData,chanEstPilots,chanBW,noiseVarEst,symOffset,eqMethod,pilotPhaseTracking,ofdmInfo)
%demodulateSymbols Demodulate and equalize symbols

    % OFDM demodulation with de-normalization and removing phase rotation per subcarrier
    demod = wlan.internal.legacyOFDMDemodulate(rx,ofdmInfo,symOffset,1);

    % Pilot phase tracking
    if strcmp(pilotPhaseTracking,'PreEQ')
        z = 0; % No account of L-SIG symbol
        cpe = commonPhaseErrorEstimate(demod(ofdmInfo.PilotIndices,:,:),chanEstPilots,chanBW,z);
        demod(ofdmInfo.DataIndices,:,:) = wlan.internal.commonPhaseErrorCorrect(demod(ofdmInfo.DataIndices,:,:),cpe);
    end

    % Merge subchannels; channel estimates and demodulated symbols together for the repeated subcarriers
    [ofdmData20MHz,chanEstData20MHz] = wlan.internal.mergeSubchannels(demod(ofdmInfo.DataIndices,:,:),chanEstData,ofdmInfo.NumSubchannels);

    % Perform equalization
    [eqDataSym,csiData] = wlan.internal.equalize(ofdmData20MHz,chanEstData20MHz,eqMethod,noiseVarEst);
end

function cpe = commonPhaseErrorEstimate(rxPilots,chanEstPilots,chanBW,z)
%commonPhaseErrorEstimate Common phase error estimate

    numPilotSym = size(rxPilots,2);
    % Get reference pilots. Input z is the Offset to account for symbols
    % preceding the ones used for phase tracking
    refPilots = wlan.internal.nonHTPilots(numPilotSym,z,chanBW);
    cpe = wlan.internal.commonPhaseErrorEstimate(rxPilots,chanEstPilots,refPilots);
end

function info = preEHTOFDMInfo(numSubchannels)
%preEHTOFDMInfo Pre-EHT tone indices

    [activeFrequencyIndex,activePilotIndex] = wlan.internal.preEHTToneIndices(numSubchannels);
    [dataIndices,pilotIndices] = wlan.internal.preEHTOccupiedIndices(activeFrequencyIndex,activePilotIndex);
    fftLength = 64*numSubchannels;
    cpLength = 16*numSubchannels;
    info = struct;
    info.FFTLength = fftLength;
    info.CPLength = cpLength;
    info.NumSubchannels = numSubchannels;
    info.NumTones = numel(activeFrequencyIndex);
    info.ActiveFrequencyIndices = activeFrequencyIndex;
    info.ActiveFFTIndices = activeFrequencyIndex+fftLength*1/2+1;
    info.DataIndices = dataIndices;
    info.PilotIndices = pilotIndices;
end

function [uplinkIndication,compressionMode] = interpretUSIGBits(usigbits,failCRC)
% InterpretUSIGBits Interpret decoded U-SIG field bits for UL/DL indication
% and compress mode indication

    % Process bits on a valid 80 MHz subblock. Extract bits on relevant 80
    % MHz subblocks. If there are more than one valid subblocks process the
    % bits on the first 80 MHz subblocks.
    index = 1:numel(failCRC); % Number of subblocks
    idx = index(failCRC==0); % Get index of a valid subblock
    bits = usigbits(:,idx(1)); % Process bits on first valid subblock

    % UL/DL Indication
    B106_06 = bits(7); % U-SIG-1 as per Table 36-28 of IEEE P802.11be/D5.0
    if B106_06
        uplinkIndication = 1; % 1 for Uplink
    else
        uplinkIndication = 0; % 0 for Downlink
    end

    % PPDU type and compression mode indication
    usig2Bits = bits(27:end); % U-SIG-2 as per Table 36-28 of IEEE P802.11be/D5.0
    compressionMode = bit2int(usig2Bits(1:2),2,false);
end

