function [bits, eqSym, varargout] = trackingNonHTDataRecover( ...
    rxNonHTData, chanEst, noiseVarEst, cfgNonHT, cfgRec, demodLLTF)
%trackingNonHTDataRecover Recover information bits from non-HT Data field signal with pilot tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS = trackingNonHTDataRecover(RXNONHTDATA, CHANEST, NOISEVAREST,
%   CFGNONHT, CFGREC, DEMODLLTF) recovers the information bits in the non-HT Data
%   field for a non-HT OFDM format transmission with joint sample rate
%   offset and residual carrier frequency offset tracking.
%
%   BITS is an int8 column vector of length 8*CFGNONHT.PSDULength
%   containing the recovered information bits.
%
%   RXNONHTDATA is the received time-domain non-HT Data field signal. It is
%   a Ns-by-Nr matrix of real or complex values, where Ns represents the
%   number of time-domain samples in the non-HT Data field and Nr
%   represents the number of receive antennas. Ns can be greater than the
%   non-HT Data field length; in this case additional samples at the end of
%   RXNONHTDATA, if not required, are not used. When sample rate offset
%   tracking is enabled using the optional CFGREC argument, additional
%   samples may be required in RXNONHTDATA. This is to allow for the
%   receiver running at a higher sample rate than the transmitter and
%   therefore more samples being required.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the L-LTF. It is a real or complex array of size Nst-by-1-by-Nr, where
%   Nst represents the total number of occupied subcarriers. The singleton
%   dimension corresponds to the single transmitted stream in the L-LTF
%   which includes the combined cyclic shifts if multiple transmit antennas
%   are used.
%
%   NOISEVAREST is the noise variance estimate. It is a real, nonnegative
%   scalar.
%
%   CFGNONHT is the format configuration object of type <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>
%   that specifies the non-HT format parameters. Only OFDM modulation is
%   supported.
%
%   CFGREC is a <a
%   href="matlab:help('trackingRecoveryConfig')">trackingRecoveryConfig</a>
%   configuration object that configures different algorithm options for
%   data recovery.
%
%   DEMODLLTF are the demodulated L-LTF symbols
%
%   [..., EQSYM, CPE, PEG, PILOTGAIN, SCRAMINIT, EQSYMUNCOMBINED] =
%   trackingNonHTDataRecover(...) also returns the equalized subcarriers,
%   common phase error, phase error gradient, pilot gain, recovered
%   scrambler initial value, and equalized subcarriers without combining
%   duplicate subchannels.
%
%   EQSYM is a complex 52-by-Nsym matrix containing the equalized symbols
%   at active subcarriers after combining duplicate subchannels. There are
%   52 active subcarriers in the non-HT Data field after duplicate
%   subchannel combining. Nsym represents the number of OFDM symbols in the
%   non-HT Data field.
%
%   CPE is a column vector of length Nsym containing the common phase error
%   between each received and expected OFDM symbol.
%
%   PEG is a column vector of length Nsym containing the phase error
%   gradient per OFDM symbol in degrees per subcarrier. This error is
%   caused by a sample rate offset between transmitter and receiver.
%
%   PILOTGAIN is a Nsym-by-Nsp array containing the pilot gains. Nsp is the
%   number of pilot subcarriers.
%
%   SCRAMINIT is an int8 scalar containing the recovered initial scrambler
%   state. The function maps the initial state bits X1 to X7, as specified
%   in IEEE 802.11-2016, Section 17.3.5.5 to SCRAMINIT, treating the
%   rightmost bit as most significant.
%
%   EQSYMUNCOMBINED is a complex Nst-by-Nsym matrix containing the
%   equalized symbols at data carrying subcarriers. Nst is the number of
%   active subcarriers in the non-HT Data field.
%
%   Example:
%   %  Recover a non-HT Data field signal through a SISO AWGN channel
%   %  using ZF equalization.
%
%     cfgNonHT = wlanNonHTConfig('PSDULength', 1024);  % non-HT OFDM
%     txBits = randi([0 1], 8*cfgNonHT.PSDULength, 1); % PSDU bits
%     tx = wlanNonHTData(txBits, cfgNonHT);      % non-HT Data field signal
%
%     % Add AWGN, with noise variance of 1
%     rx = awgn(tx, 1, 1);
%
%     % Extract L-LTF demodulated symbols 
%     index = wlanFieldIndices(cfgNonHT);
%     lltf = rx(index.LLTF(1):index.LLTF(2),:);
%     demodLLTF = wlanLLTFDemodulate(lltf,cfgNonHT.ChannelBandwidth);

%     % Configure recovery object
%     cfgRec = trackingRecoveryConfig('EqualizationMethod', 'ZF');
%     % Recover PSDU bits
%     rxBits = trackingNonHTDataRecover(rx, ones(52,1), 1, cfgNonHT, cfgRec, demodLLTF);
%
%     [numerr, ber] = biterr(rxBits, txBits); % Compare bits
%     disp(ber)
%
%   See also trackingRecoveryConfig.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    nargoutchk(0,7);
    cfgInfo = validateConfig(cfgNonHT);
    numOFDMSym = cfgInfo.NumDataSymbols;
    numRx = size(rxNonHTData, 2);

    % Get OFDM configuration
    cfgOFDM = wlan.internal.vhtOFDMInfo('NonHT-Data', cfgNonHT.ChannelBandwidth);
    dataInd = cfgOFDM.DataIndices;
    pilotInd = cfgOFDM.PilotIndices;

    % Extract pilot subcarriers from channel estimate
    chanEstPilots = chanEst(pilotInd,:,:);

    % Get reference pilots, from IEEE Std 802.11-2012, Eqn 18-22
    z = 1; % Offset by 1 to account for L-SIG pilot symbol
    fnRefPilots = @()wlan.internal.nonHTPilots(numOFDMSym, z, cfgNonHT.ChannelBandwidth);

    fnOFDMDemod = @(x)wlan.internal.legacyOFDMDemodulate(x, cfgOFDM, cfgRec.OFDMSymbolOffset, 1);

    % OFDM demodulation and optional pilot tracking
    [ofdmDemod, cpe, peg, pilotgain] = wirelessWaveformAnalyzer.internal.trackingOFDMDemodulate(rxNonHTData, chanEstPilots, fnRefPilots, fnOFDMDemod, numOFDMSym, cfgOFDM, cfgRec);

    if cfgRec.DataAidedEqualization
        % Data-aided channel estimation using demodulated L-LTF and NonHT-Data symbols
        chanEst(dataInd,:,:) = wlan.internal.nonHTDataAidedChannelEstimate(demodLLTF(dataInd,:,:),ofdmDemod(dataInd,:,:),chanEst(dataInd,:,:),noiseVarEst,cfgNonHT);
    end

    varargout{1} = cpe;
    varargout{2} = peg;
    varargout{3} = pilotgain;

    % Merge num20 channel estimates and demodulated symbols together for the repeated subcarriers
    NstSeg = 52; % Number of subcarriers in 20 MHz segment
    num20MHz = size(ofdmDemod,1)/NstSeg; % Number of 20 MHz subchannels
    ofdmOutOne20MHz = coder.nullcopy(complex(zeros(NstSeg, numOFDMSym, numRx*num20MHz))); % Preallocate for codegen
    chanEstOne20MHz = coder.nullcopy(complex(zeros(NstSeg, 1, numRx*num20MHz))); % Preallocate for codegen
    [ofdmOutOne20MHz(:), chanEstOne20MHz(:)] = wlan.internal.mergeSubchannels(ofdmDemod, chanEst, num20MHz);

    % Equalization
    [eqSym, csi] = wlan.internal.equalize(ofdmOutOne20MHz, chanEstOne20MHz, cfgRec.EqualizationMethod, noiseVarEst);

    % Extract data and pilot subcarriers
    [~, dataInd20] = wlan.internal.getOFDMConfig('CBW20', 'Long', 'Legacy');
    eqDataSym = eqSym(dataInd20,:,:);
    csiData = csi(dataInd20,:);

    [bits,scraminit] = wlanNonHTDataBitRecover(eqDataSym, noiseVarEst, csiData, cfgNonHT);
    if nargout>5
        varargout{4} = scraminit;
    end

    if nargout>6
        % Equalize without combining
        varargout{5} =  wlan.internal.equalize(ofdmDemod, chanEst, cfgRec.EqualizationMethod, noiseVarEst);
    end
end
