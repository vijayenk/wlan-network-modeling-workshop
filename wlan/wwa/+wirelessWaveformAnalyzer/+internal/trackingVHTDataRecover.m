function [bits, crcBits, eqDataSym, varargout] = trackingVHTDataRecover( ...
    rxVHTData, chanEst, chanEstSSPilots, cfgVHT, cfgRec, userNum, numSTSVec, numOFDMSym, demodVHTLTF)
%trackingVHTDataRecover Recover bits from VHT Data field signal with pilot tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS, CRCBITS] = trackingVHTDataRecover(RXVHTDATA, CHANEST,
%   CHANESTSSPILOTS, CFGVHT, CFGREC, USERNUM, NUMSTS, NUMOFDMSYM, DEMODVHTLTF) 
%   recovers the bits in the VHT-Data field of a single user with joint
%   sample rate offset and residual carrier frequency offset tracking. LDPC
%   coding is not supported.
%
%   BITS is an int8 column vector of length 8*CFGVHT.PSDULength containing
%   the recovered information bits.
%
%   CRCBITS is an int8 column vector of length 8 containing the VHT-Data
%   field checksum bits.
%
%   RXVHTDATA is the received time-domain VHT Data field signal, specified
%   as an Ns-by-Nr matrix of real or complex values. Ns represents the
%   number of time-domain samples in the VHT Data field and Nr represents
%   the number of receive antennas. Ns can be greater than the VHT Data
%   field length; in this case additional samples at the end of RXVHTDATA,
%   if not required, are not used. When sample rate offset tracking is
%   enabled using the optional CFGREC argument, additional samples may be
%   required in RXVHTDATA. This is to allow for the receiver running at a
%   higher sample rate than the transmitter and therefore more samples
%   being required.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the VHT-LTF. It is an array of size Nst-by-Nsts-by-Nr, where Nst
%   represents the total number of occupied subcarriers, Nsts represents
%   the total number of space-time streams used for the transmission and Nr
%   is the number of receive antennas.
%
%   CHANESTSSPILOTS is a complex Nsp-by-Nltf-by-Nr array containing the
%   channel gains at pilot subcarrier locations for each symbol, assuming
%   one space-time stream at the transmitter. Nsp is the number of pilots
%   subcarriers and Nltf is the number of VHT-LTF symbols.
%
%   CFGVHT is the format configuration object of type <a
%   href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>. If it is a
%   single-user configuration, the USERNUM input should be 1. If it is a
%   multi-user configuration, the USERNUM input specifies the user of
%   interest.
%
%   CFGREC is a
%   <a href="matlab:help('trackingRecoveryConfig')">trackingRecoveryConfig</a>
%   configuration object that configures different algorithm options for
%   data recovery.
%
%   USERNUM is the user of interest, specified as an integer between 1
%   and NumUsers, where NumUsers is the number of users in the
%   transmission.
%
%   NUMSTS is the number of space-time streams, specified as a
%   1-by-NumUsers vector. Element values specify the number of space-time
%   streams per user.
%
%   NUMOFDMSYM specifies the number of OFDM symbols to demodulate. You
%   should specify the number of symbols when recovering a multi-user
%   transmission for an individual user of interest.
%
%   DEMODVHTLTF are the demodulated VHT-LTF symbols
%
%   [..., EQDATASYM, CPE, PEG, NOISEVAREST, EQPILOTSYM] =
%   trackingVHTDataRecover(...) also returns the equalized data and pilot
%   subcarriers, common phase error, phase error gradient, and noise
%   estimate.
%
%   EQDATASYM is a complex Nsd-by-Nsym-by-Nss array containing the
%   equalized symbols at data carrying subcarriers. Nsd represents the
%   number of data subcarriers, Nsym represents the number of OFDM symbols
%   in the VHT-Data field, and Nss represents the number of spatial streams
%   assigned to the user.
%
%   CPE is a column vector of length Nsym containing the common phase error
%   between each received and expected OFDM symbol.
%
%   PEG is a column vector of length Nsym containing the phase error
%   gradient per OFDM symbol in degrees per subcarrier. This error is
%   caused by a sample rate offset between transmitter and receiver.
%
%   NOISEVAREST is the noise variance estimated using pilots in the data
%   portion of the waveform.
%
%   EQPILOTSYM is a complex Nsp-by-Nsym-by-Nss array containing the
%   equalized symbols at pilot carrying subcarriers. Nsp represents the
%   number of pilot subcarriers.
%
%   Example:
%   %  Recover bits in VHT Data field via channel estimation on VHT-LTF
%   %  over a 2 x 2 quasi-static fading channel
%
%     % Configure a VHT configuration object
%     chanBW = 'CBW160';
%     cfgVHT = wlanVHTConfig('ChannelBandwidth',    chanBW, ...
%         'NumTransmitAntennas', 2, 'NumSpaceTimeStreams', 2, ...
%         'APEPLength',          512);
%
%     % Generate VHT-LTF and VHT Data field signals
%     txDataBits = randi([0 1], 8*cfgVHT.PSDULength, 1);
%     txVHTLTF  = wlanVHTLTF(cfgVHT);
%     txVHTData = wlanVHTData(txDataBits, cfgVHT);
%
%     % Pass through a 2 x 2 quasi-static fading channel with AWGN
%     H = 1/sqrt(2)*complex(randn(2, 2), randn(2, 2));
%     rxVHTLTF  = awgn(txVHTLTF  * H, 10);
%     rxVHTData = awgn(txVHTData * H, 10);
%
%     % Perform channel estimation based on VHT-LTF
%     demodVHTLTF = wlanVHTLTFDemodulate(rxVHTLTF, cfgVHT, 1);
%     [chanEst, chanEstSSPilots] = wlanVHTLTFChannelEstimate(... ,
%         demodVHTLTF, cfgVHT);
%
%     % Configure a recovery object using ZF equalization
%     cfgRec = trackingRecoveryConfig('EqualizationMethod', 'ZF');
%
%     % Recover information bits in VHT Data
%     numSTS = cfgVHT.NumSpaceTimeStreams;
%     cfgInfo = validateConfig(cfgVHT, 'MCS');
%     numOFDMSym = cfgInfo.NumDataSymbols;
%     rxDataBits = trackingVHTDataRecover(rxVHTData, chanEst, ...
%         chanEstSSPilots, cfgVHT, cfgRec, 1, numSTS, numOFDMSym, demodVHTLTF);
%
%     % Compare against original information bits
%     disp(isequal(txDataBits, rxDataBits));
%
%   See also trackingRecoveryConfig.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

    nargoutchk(0,8);
    numSTSu = numSTSVec(userNum);

    mcsTable = wlan.internal.getRateTable(cfgVHT);
    chanBW = cfgVHT.ChannelBandwidth;

    % Get OFDM configuration
    cfgOFDM = wlan.internal.vhtOFDMInfo('VHT-Data', chanBW, cfgVHT.GuardInterval);
    dataInd = cfgOFDM.DataIndices;
    pilotInd = cfgOFDM.PilotIndices;

    % NDP only for SU, so idx is (1)
    if cfgVHT.APEPLength(1) == 0
        bits     = zeros(0, 1, 'int8');
        crcBits  = zeros(0, 1, 'int8');
        eqDataSym = zeros(numel(dataInd), 0, mcsTable.Nss(1));
        varargout{1} = []; % CPE
        varargout{2} = []; % PEG
        varargout{3} = []; % AE
        % [psdu{u},rxSIGBCRC,eqDataSym,cpe,peg,pilotGain,nVarEst,eqPilotSym] =
        % trackingVHTDataRecover(rxData, .......)
        if nargout>6
            varargout{4} = nan; % Noise estimate
        end
        if nargout>7
            varargout{5} = zeros(numel(pilotInd), 0, mcsTable.Nss(1)); % Equalized pilots
        end
        return;
    end

    % Set up some implicit configuration parameters
    numSS = mcsTable.Nss(1);       % Number of spatial streams

    % Index into streams for the user of interest
    stsIdx = sum(numSTSVec(1:(userNum-1)))+(1:numSTSu);

    % Offset by 4 to allow for L-SIG, VHT-SIG-A, VHT-SIG-B pilot symbols
    n = (0:numOFDMSym-1).';
    z = 4;
    nsts = 1; % Using single stream pilot so set Nsts=1
    fnRefPilots = @()wlan.internal.vhtPilots(n, z, chanBW, nsts);

    % OFDM demodulation and optional pilot tracking
    fnOFDMDemod = @(x)wlan.internal.legacyOFDMDemodulate(x, cfgOFDM, cfgRec.OFDMSymbolOffset, sum(numSTSVec));
    chanEstPilotsUse = mean(chanEstSSPilots,2); % Average over OFDM symbols
    [ofdmDemod, cpe, peg, pilotGain] = wirelessWaveformAnalyzer.internal.trackingOFDMDemodulate(rxVHTData, chanEstPilotsUse, fnRefPilots, fnOFDMDemod, numOFDMSym, cfgOFDM, cfgRec);

    varargout{1} = cpe;
    varargout{2} = peg;
    varargout{3} = pilotGain;

    % Estimate noise power
    demodPilotSym = ofdmDemod(pilotInd,:,:);
    noiseVarEst = vhtNoiseEstimate(demodPilotSym,chanEstSSPilots,cfgVHT.ChannelBandwidth);
    varargout{4} = noiseVarEst;

    if cfgRec.DataAidedEqualization
        % Data-aided channel estimation using demodulated VHT-LTF and VHT-Data symbols
        tempNumSTS = cfgVHT.NumSpaceTimeStreams;
        % For equalization we need to provide the number of STSs per user
        cfgVHT.NumSpaceTimeStreams = numSTSVec;
        chanEst(dataInd,:,:) = wlan.internal.vhtDataAidedChannelEstimate(demodVHTLTF(dataInd,:,:),ofdmDemod(dataInd,:,:),chanEst(dataInd,:,:),noiseVarEst,cfgVHT,userNum);
        cfgVHT.NumSpaceTimeStreams = tempNumSTS;
    end

    % Equalization
    if cfgVHT.STBC  % Only SU
        [eqDataSym, csiData] = wlan.internal.stbcCombine(ofdmDemod(dataInd,:,:), chanEst(dataInd,:,:), numSS, cfgRec.EqualizationMethod, noiseVarEst);
        if nargout>6
            varargout{5} = wlan.internal.equalize(ofdmDemod(pilotInd,:,:), chanEst(pilotInd,:,:), cfgRec.EqualizationMethod, noiseVarEst); % Equalized pilots
        end
    else % Both SU and MU
        [eqSym, csi] = wlan.internal.equalize(ofdmDemod, chanEst, cfgRec.EqualizationMethod, noiseVarEst);
        eqDataSym = eqSym(dataInd,:,stsIdx);
        csiData = csi(dataInd,stsIdx);
        if nargout>6
            varargout{5} = eqSym(pilotInd,:,:); % Equalized pilots
        end
    end

    % Recover PSDU
    ldpcParams.LDPCDecodingMethod = 'norm-min-sum';
    ldpcParams.alphaBeta = cfgRec.MinSumScalingFactor;
    ldpcParams.MaximumLDPCIterationCount = cfgRec.MaximumLDPCIterationCount;
    ldpcParams.Termination = cfgRec.Termination;
    [bits,crcBits] = wlan.internal.vhtDataBitRecover(eqDataSym, noiseVarEst, csiData, cfgVHT, ldpcParams, 1);

end

function nest = vhtNoiseEstimate(ofdmDemodPilots,chanEstSSPilots,channelBandwidth)
% Get reference pilots, from Eqn 22-95, IEEE Std 802.11ac-2013
% Offset by 4 to allow for L-SIG, VHT-SIG-A, VHT-SIG-B pilot symbols
numOFDMSym = size(ofdmDemodPilots,2);
n = (0:numOFDMSym-1).';
z = 4;
% Set the number of space time streams to 1 since the pilots are same
% across all spatial streams
refPilots = wlan.internal.vhtPilots(n,z,channelBandwidth,1);

% Average single-stream pilot estimates over symbols (2nd dimension)
chanEstSSPilotsAvg = mean(chanEstSSPilots,2);
estRxPilots = wlan.internal.rxPilotsEstimate(chanEstSSPilotsAvg,refPilots);

% Estimate noise
pilotError = estRxPilots-ofdmDemodPilots;
nest = mean(real(pilotError(:).*conj(pilotError(:))));
end
