function [bits, eqDataSym, varargout] = trackingHTDataRecover(rxHTData, chanEst, cfgHT, cfgRec, demodHTLTF)
%trackingHTDataRecover Recover information bits from HT-Data field signal with pilot tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS = trackingHTDataRecover(RXHTDATA, CHANEST, CFGHT, CFGREC, DEMODHTLTF) recovers the
%   information bits in the HT-Data field using pilot subcarriers to
%   estimate noise variance.
%
%   BITS is an int8 column vector of length 8*CFGHT.PSDULength containing
%   the recovered information bits.
%
%   RXHTDATA is the received time-domain HT-Data field signal. It is a
%   Ns-by-Nr matrix of real or complex values, where Ns represents the
%   number of time-domain samples in the HT-Data field and Nr represents
%   the number of receive antennas. Ns can be greater than the HT Data
%   field length; in this case additional samples at the end of RXHTDATA,
%   if not required, are not used. When sample rate offset tracking is
%   enabled using the optional CFGREC argument, additional samples may be
%   required in RXHTDATA. This is to allow for the receiver running at a
%   higher sample rate than the transmitter and therefore more samples
%   being required.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the HT-LTF. It is a real or complex array of size Nst-by-Nsts-by-Nr,
%   where Nst represents the total number of occupied subcarriers.
%
%   CFGHT is the format configuration object of type <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, which
%   specifies the parameters for the HT-Mixed format.
%
%   CFGREC is a <a
%   href="matlab:help('trackingRecoveryConfig')">trackingRecoveryConfig</a>
%   configuration object that configures different algorithm options for
%   data recovery.
%
%   DEMODHTLTF are the demodulated HT-LTF symbols
%
%   [..., EQSYM, CPE, PEG, NOISEVAREST, EQPILOTSYM] = trackingHTDataRecover(...)
%   also returns the equalized data and pilot subcarriers, common phase
%   error, phase error gradient, and pilot noise estimate.
%
%   EQDATASYM is a complex Nsd-by-Nsym-by-Nss array containing the
%   equalized symbols at data carrying subcarriers. Nsd represents the
%   number of data subcarriers, Nsym represents the number of OFDM symbols
%   in the HT-Data field, and Nss represents the number of spatial streams.
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
%   % Recover a HT-Data field signal through a SISO AWGN channel using
%   % ZF equalization.
% 
%     cfgHT = wlanHTConfig('PSDULength', 1024);     % HT format configuration
%     txBits = randi([0 1], 8*cfgHT.PSDULength, 1); % Payload bits
%     txHSig = wlanHTData(txBits, cfgHT);           % Generate HT-Data signal
% 
%     % Pass through an AWGN channel with noise variance of 1
%     rxHTSig = awgn(txHSig, 1, 1);
% 
%     % Extract HT-LTF demodulated symbols 
%     index = wlanFieldIndices(cfgHT);
%     rxHTLTF = rxHTSig(index.HTLTF(1):index.HTLTF(2),:);
%     demodHTLTF = wlanHTLTFDemodulate(rxHTLTF,cfgHT);
% 
%     % Configure recovery object
%     cfgRec = trackingRecoveryConfig('EqualizationMethod', 'ZF');
%     % Recover payload bits
%     rxBits = trackingHTDataRecover(rxHTSig, ones(56,1), cfgHT, cfgRec, demodHTLTF);
% 
%     [numerr, ber] = biterr(rxBits, txBits);       % Compare bits
%     disp(ber)
%
%   See also trackingRecoveryConfig.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    nargoutchk(0,7);
    cfgInfo = validateConfig(cfgHT, 'MCS');
    numOFDMSym = cfgInfo.NumDataSymbols;

    numSTS     = cfgHT.NumSpaceTimeStreams;
    mcsTable   = wlan.internal.getRateTable(cfgHT);
    numSS      = mcsTable.Nss;

    % Get OFDM configuration
    cfgOFDM = wlan.internal.vhtOFDMInfo('HT-Data', cfgHT.ChannelBandwidth, cfgHT.GuardInterval);
    dataInd = cfgOFDM.DataIndices;
    pilotInd = cfgOFDM.PilotIndices;

    % If PSDU is empty there is no data to return
    if cfgHT.PSDULength == 0
        bits = zeros(0, 1, 'int8');
        eqDataSym = zeros(cfgOFDM.NumTones, 0, numSS);
        varargout{1} = []; % CPE
        varargout{2} = []; % PEG
        varargout{3} = []; % AE
                           % [psdu,eqDataSym,cpe,peg,pilotGain,nVarEst,eqPilotSym] =
                           % trackingHTDataRecover(rxData,....)
        if nargout>5
            varargout{4} = nan; % Noise variance estimate
        end
        if nargout>6
            varargout{5} = zeros(numel(pilotInd), 0, mcsTable.Nss(1)); % Equalized pilots
        end
        return;
    end

    % Extract pilot subcarriers from channel estimate
    chanEstPilots = chanEst(pilotInd,:,:);

    % Get reference pilots, from IEEE Std 802.11-2012, Eqn 20-58/59
    % For HT-MF, offset by 3 to allow for L-SIG and HT-SIG pilot symbols
    z = 3;
    fnRefPilots = @()wlan.internal.htPilots(numOFDMSym, z, cfgHT.ChannelBandwidth, numSTS);

    % OFDM demodulation and optional pilot tracking
    fnOFDMDemod = @(x)wlan.internal.legacyOFDMDemodulate(x, cfgOFDM, cfgRec.OFDMSymbolOffset, numSTS);
    [ofdmDemod, cpe, peg, pilotGain] = wirelessWaveformAnalyzer.internal.trackingOFDMDemodulate(rxHTData, chanEstPilots, fnRefPilots, fnOFDMDemod, numOFDMSym, cfgOFDM, cfgRec);

    varargout{1} = cpe;
    varargout{2} = peg;
    varargout{3} = pilotGain;

    % Estimate receive pilot values
    [~,estRxPilots] = wlan.internal.commonPhaseErrorEstimate(ofdmDemod(pilotInd,:,:), chanEstPilots, fnRefPilots());

    % Estimate noise
    pilotError = estRxPilots-ofdmDemod(pilotInd,:,:);
    noiseVarEst = mean(real(pilotError(:).*conj(pilotError(:))));
    varargout{4} = noiseVarEst;

    if cfgRec.DataAidedEqualization
        % Data-aided channel estimation using demodulated HT-LTF and HT-Data symbols
        chanEst(dataInd,:,:) = wlan.internal.htDataAidedChannelEstimate(demodHTLTF(dataInd,:,:),ofdmDemod(dataInd,:,:),chanEst(dataInd,:,:),noiseVarEst,cfgHT);
    end

    % Equalization
    if numSS < numSTS
        [eqDataSym, csiData] = wlan.internal.stbcCombine(ofdmDemod(dataInd,:,:), chanEst(dataInd,:,:), numSS, cfgRec.EqualizationMethod, noiseVarEst);
        if nargout>5
            varargout{5} = wlan.internal.equalize(ofdmDemod(pilotInd,:,:), chanEst(pilotInd,:,:), cfgRec.EqualizationMethod, noiseVarEst); % Equalized pilots
        end
    else
        [eqSym, csi] = wlan.internal.equalize(ofdmDemod, chanEst, cfgRec.EqualizationMethod, noiseVarEst);
        eqDataSym = eqSym(dataInd,:,:);
        csiData = csi(dataInd,:);
        if nargout>4
            varargout{5} = eqSym(pilotInd,:,:); % Equalized pilots
        end
    end

    % Recover PSDU
    ldpcParams.LDPCDecodingMethod = cfgRec.LDPCDecodingMethod;
    ldpcParams.alphaBeta = cfgRec.MinSumScalingFactor;
    ldpcParams.MaximumLDPCIterationCount = cfgRec.MaximumLDPCIterationCount;
    ldpcParams.Termination = cfgRec.Termination;
    bits = wlan.internal.htDataBitRecover(eqDataSym, noiseVarEst, csiData, cfgHT, ldpcParams);

end
