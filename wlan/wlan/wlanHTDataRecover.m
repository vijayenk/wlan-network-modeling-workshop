function [bits, eqDataSym, varargout] = wlanHTDataRecover( ...
    rx, chanEst, noiseVarEst, cfgHT, varargin)
%wlanHTDataRecover Recover information bits from HT-Data field signal
%
%   BITS = wlanHTDataRecover(RX, CHANEST, NOISEVAREST, CFGHT) recovers the
%   information bits in the HT-Data field for a HT-Mixed format
%   transmission.
%
%   BITS is an int8 column vector of length 8*CFGHT.PSDULength containing
%   the recovered information bits.
%
%   RX is the received time-domain HT-Data field signal. It is a Ns-by-Nr
%   matrix of real or complex values, where Ns represents the number of
%   time-domain samples in the HT-Data field and Nr represents the number
%   of receive antennas. Ns can be greater than the HT-Data field length;
%   in this case additional samples at the end of RX are not used.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the HT-LTF. It is a real or complex array of size Nst-by-Nsts-by-Nr,
%   where Nst represents the total number of occupied subcarriers.
%
%   NOISEVAREST is the noise variance estimate. It is a real, nonnegative
%   scalar.
%
%   CFGHT is the format configuration object of type wlanHTConfig, which
%   specifies the parameters for the HT-Mixed format.
%
%   BITS = wlanHTDataRecover(..., NAME, VALUE) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
%
%   'OFDMSymbolOffset'          OFDM symbol sampling offset. Specify the
%                               OFDMSymbolOffset as a fraction of the
%                               cyclic prefix (CP) length for every OFDM
%                               symbol, as a double precision, real scalar
%                               between 0 and 1, inclusive. The OFDM
%                               demodulation is performed based on Nfft
%                               samples following the offset position,
%                               where Nfft denotes the FFT length. The
%                               default value of this property is 0.75,
%                               which means the offset is three quarters of
%                               the CP length.
%
%   'EqualizationMethod'        Specify the equalization method as one of
%                               'MMSE' | 'ZF'. 'MMSE' indicates that the
%                               receiver uses a minimum mean square error
%                               equalizer. 'ZF' indicates that the receiver
%                               uses a zero-forcing equalizer. The default
%                               value of this property is 'MMSE'.
%
%   'PilotPhaseTracking'        Specify the pilot phase tracking performed
%                               as one of 'PreEQ' | 'None'. 'PreEQ' pilot
%                               phase tracking estimates and corrects a
%                               common phase offset across all subcarriers
%                               and receive antennas for each received OFDM
%                               symbol before equalization. 'None'
%                               indicates that pilot phase tracking does
%                               not occur. The default is 'PreEQ'.
%
%   'PilotAmplitudeTracking'    Specify the pilot amplitude tracking
%                               performed as one of 'PreEQ' | 'None'.
%                               'PreEQ' pilot amplitude tracking estimates
%                               and corrects an average amplitude error
%                               across all subcarriers for each OFDM symbol
%                               and each receiver antenna before
%                               equalization. 'None' indicates that pilot
%                               amplitude tracking does not occur. The
%                               default is 'None'. Due to the limitations
%                               of the algorithm used, disable pilot
%                               amplitude tracking when filtering a
%                               waveform through a MIMO fading channel.
%
%   'LDPCDecodingMethod'        Specify the LDPC decoding algorithm as one
%                               of these values:
%                               - 'bp'            : Belief propagation (BP)
%                               - 'layered-bp'    : Layered BP
%                               - 'norm-min-sum'  : Normalized min-sum
%                               - 'offset-min-sum': Offset min-sum
%                               The default is 'bp'.
%
%   'MinSumScalingFactor'       Specify the scaling factor for normalized
%                               min-sum LDPC decoding algorithm as a scalar
%                               in the interval (0,1]. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'norm-min-sum'. The
%                               default is 0.75.
%
%   'MinSumOffset'              Specify the offset for offset min-sum LDPC
%                               decoding algorithm as a finite real scalar
%                               greater than or equal to 0. This argument
%                               applies only when you set
%                               LDPCDecodingMethod to 'offset-min-sum'. The
%                               default is 0.5.
%
%   'MaximumLDPCIterationCount' Specify the maximum number of iterations in
%                               LDPC decoding as a positive scalar integer.
%                               This applies when you set the channel
%                               coding property of format configuration
%                               object of type wlanHTConfig to 'LDPC'.
%                               The default is 12.
%
%   'EarlyTermination'          To enable early termination of LDPC
%                               decoding, set this property to true. Early
%                               termination applies if all parity-checks
%                               are satisfied before reaching the number of
%                               iterations specified in the
%                               'MaximumLDPCIterationCount' input. To let
%                               the decoding process iterate for the number
%                               of iterations specified in the
%                               'MaximumLDPCIterationCount' input, set this
%                               argument to false. This applies when you
%                               set the channel coding property of format
%                               configuration object of type wlanHTConfig
%                               to 'LDPC'.The default is true.
%
%   [..., EQDATASYM, CPE, AE] = wlanHTDataRecover(...) also returns the
%   equalized subcarriers, common phase error, and average amplitude error.
%
%   EQDATASYM is a complex Nsd-by-Nsym-by-Nss array containing the
%   equalized symbols at data carrying subcarriers. Nsd represents the
%   number of data subcarriers, Nsym represents the number of OFDM symbols
%   in the HT-Data field, and Nss represents the number of spatial streams.
%
%   CPE is a column vector of length Nsym containing the common phase error
%   between each received and expected OFDM symbol.
%
%   AE is a real Nsym-by-Nr array containing the average amplitude error
%   for all subcarriers, in dB, with respect to the estimated receiver
%   pilots per OFDM symbol for each receive antenna.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(4, 22);
nargoutchk(0, 4);

% Calculate CPE or AE if requested
calculateCPE = false;
calculateAE = false;
if nargout>2
    calculateCPE = true;
end
if nargout>3
    calculateAE = true;
end

% HT configuration input self-validation
validateattributes(cfgHT, {'wlanHTConfig'}, {'scalar'}, mfilename, 'HT-Mixed format configuration object');
s = validateConfig(cfgHT, 'MCS');

% Validate rxHTData
validateattributes(rx, {'double','single'}, {'2d','finite'}, mfilename, 'HT-Data field signal');
% Validate chanEst
validateattributes(chanEst, {'double','single'}, {'3d','finite'}, mfilename, 'channel estimates');
% Validate noiseVarEst
validateattributes(noiseVarEst, {'double','single'}, {'real','scalar','nonnegative','finite'}, mfilename, 'noise variance estimate');

numSTS     = cfgHT.NumSpaceTimeStreams;
numRx      = size(rx, 2);
mcsTable   = wlan.internal.getRateTable(cfgHT);
numSS      = mcsTable.Nss;
numOFDMSym = s.NumDataSymbols;

% If PSDU is empty there is no data to return
if cfgHT.PSDULength == 0
    bits     = zeros(0, 1, 'int8');
    eqDataSym  = zeros(mcsTable.NSD, 0, numSS, 'like', rx);
    if calculateCPE==true
        varargout{1} = zeros(0, 0, class(rx)); % CPE
    end
    if calculateAE==true
        varargout{2} = zeros(0, 0, class(rx)); % AE
    end
    return;
end

% Validate and parse optional inputs
recParams = wlan.internal.parseOptionalInputs(mfilename, varargin{:});

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('HT-Data', cfgHT.ChannelBandwidth, cfgHT.GuardInterval);

% Cross validate input
coder.internal.errorIf(size(chanEst, 1) ~= ofdmInfo.NumTones, 'wlan:wlanHTDataRecover:InvalidHTChanEst1D', ofdmInfo.NumTones);
coder.internal.errorIf(size(chanEst, 2) ~= numSTS, 'wlan:wlanHTDataRecover:InvalidHTChanEst2D', numSTS);
coder.internal.errorIf(size(chanEst, 3) ~= numRx, 'wlan:wlanHTDataRecover:InvalidHTChanEst3D');

% Cross-validation between inputs
minInputLen = numOFDMSym*(ofdmInfo.FFTLength+ofdmInfo.CPLength);
coder.internal.errorIf(size(rx, 1) < minInputLen, 'wlan:wlanHTDataRecover:ShortHTDataInput', minInputLen);

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
demod = wlan.internal.legacyOFDMDemodulate(rx(1:minInputLen,:), ofdmInfo, recParams.OFDMSymbolOffset, numSTS);

% Pilot phase and amplitude tracking
pilotTrackingParams = struct('CalculateCPE', calculateCPE, 'CalculateAE', calculateAE, 'TrackPhase', strcmp(recParams.PilotPhaseTracking, 'PreEQ'), 'TrackAmplitude', strcmp(recParams.PilotAmplitudeTracking, 'PreEQ'));
[demod,varargout{1:2}] = wlan.internal.htTrackPilotError(demod, chanEst(ofdmInfo.PilotIndices,:,:), cfgHT.ChannelBandwidth, 'HT-Data', pilotTrackingParams);

% Equalization
if numSS < numSTS
    [eqDataSym, csiData] = wlan.internal.stbcCombine(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,:,:), numSS, recParams.EqualizationMethod, noiseVarEst);
else
    [eqDataSym, csiData] = wlan.internal.equalize(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,:,:), recParams.EqualizationMethod, noiseVarEst);
end

% Recover PSDU
bits = wlan.internal.htDataBitRecover(eqDataSym, noiseVarEst, csiData, cfgHT, recParams);

end

