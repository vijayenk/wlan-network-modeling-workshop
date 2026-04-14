function [bits, crcBits, eqDataSym, varargout] = wlanVHTDataRecover( ...
    rx, chanEst, noiseVarEst, cfgVHT, varargin)
%wlanVHTDataRecover Recover bits from VHT Data field signal
%
%   [BITS, CRCBITS] = wlanVHTDataRecover(RX, CHANEST, NOISEVAREST,
%   CFGVHTSU) recovers the bits in the VHT-Data field for a VHT format
%   single-user transmission.
%
%   BITS is an int8 column vector of length 8*CFGVHT.PSDULength containing
%   the recovered information bits.
%
%   CRCBITS is an int8 column vector of length 8 containing the VHT-Data
%   field checksum bits.
%
%   RX is the received time-domain VHT Data field signal, specified as an
%   Ns-by-Nr matrix of real or complex values. Ns represents the number of
%   time-domain samples in the VHT Data field and Nr represents the number
%   of receive antennas. Ns can be greater than the VHT Data field length;
%   in this case additional samples at the end of RXVHTDATA are not used.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the VHT-LTF. It is an array of size Nst-by-Nsts-by-Nr, where Nst
%   represents the total number of occupied subcarriers, Nsts represents
%   the total number of space-time streams used for the transmission and Nr
%   is the number of receive antennas.
%
%   NOISEVAREST is the noise variance estimate. It is a nonnegative scalar.
%
%   CFGVHTSU is the format configuration object of type wlanVHTConfig, which
%   specifies the parameters for the single-user VHT format.
%
%   [BITS, CRCBITS] = wlanVHTDataRecover(RX, CHANEST, NOISEVAREST,
%   CFGVHTMU, USERNUMBER) recovers the bits in the VHT-Data field of a VHT
%   format multi-user transmission for an individual user of interest.
%
%   CFGVHTMU is the VHT format configuration for a multi-user transmission,
%   specified as a wlanVHTConfig object.
%
%   USERNUMBER is the user of interest, specified as an integer between 1
%   and NumUsers, where NumUsers is the number of users in the
%   transmission.
%
%   [BITS, CRCBITS] = wlanVHTDataRecover(RXVHTDATA, CHANEST, NOISEVAREST,
%   CFGVHTSU, USERNUMBER, NUMSTS) recovers the bits in the VHT-Data field
%   of a VHT format multi-user transmission for an individual user of
%   interest.
%
%   CFGVHTSU is the VHT format configuration for the user of interest,
%   specified as a wlanVHTConfig object.
%
%   NUMSTS is the number of space-time streams, specified as a
%   1-by-NumUsers vector. Element values specify the number of space-time
%   streams per user.
%
%   [BITS, CRCBITS] = wlanVHTDataRecover(..., NAME, VALUE) specifies
%   additional name-value pair arguments described below. When a name-value
%   pair is not specified, its default value is used.
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
%                               object of type wlanVHTConfig to 'LDPC'.
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
%                               configuration object of type wlanVHTConfig
%                               to 'LDPC'.The default is false.
%
%   [..., EQDATASYM, CPE, AE] = wlanVHTDataRecover(...) also returns the
%   equalized subcarriers, common phase error, and average amplitude error.
%
%   EQDATASYM is a complex Nsd-by-Nsym-by-Nss array containing the
%   equalized symbols at data carrying subcarriers. Nsd represents the
%   number of data subcarriers, Nsym represents the number of OFDM symbols
%   in the VHT-Data field, and Nss represents the number of spatial
%   streams assigned to the user.
%
%   CPE is a column vector of length Nsym containing the common phase error
%   between each received and expected OFDM symbol.
%
%   AE is a real Nsym-by-Nr array containing the average amplitude error
%   for all subcarriers, in dB, with respect to the estimated receiver
%   pilots per OFDM symbol for each receive antenna.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen
%#ok<*EMCA>

narginchk(4, 24);
nargoutchk(0, 5);

% Calculate CPE or AE if requested
calculateCPE = false;
calculateAE = false;
if nargout>3
    calculateCPE = true;
end
if nargout>4
    calculateAE = true;
end

% VHT configuration input self-validation
validateattributes(cfgVHT, {'wlanVHTConfig'}, {'scalar'}, mfilename, 'VHT format configuration object');

% Validate and parse optional inputs
[muSpec, userNum, numSTSVec, recParams] = wlan.internal.parseVHTOptionalInputs(mfilename, cfgVHT.NumSpaceTimeStreams, varargin{:});

% Check MU
if muSpec==2 % SU CFGVHT
    % Have a SU cfgVHT object as input
    propIdx = 1;
    numSTSu = numSTSVec(userNum);
elseif muSpec==1 % MU CFGVHT
    validateattributes(varargin{1}, {'numeric'}, {'real','integer','scalar','>=',1,'<=',cfgVHT.NumUsers}, mfilename, 'USERNUMBER');
    % Have a MU cfgVHT object as input
    propIdx = userNum;
    numSTSu = numSTSVec(propIdx);
else % not specified, set defaults
    % Single-user case
    propIdx = 1;
    numSTSu = numSTSVec(propIdx);
end

cfgInfo = validateConfig(cfgVHT, 'MCS');
chanBW = cfgVHT.ChannelBandwidth;

% NDP only for SU, so idx is (1)
if cfgVHT.APEPLength(1) == 0
    bits     = zeros(0, 1, 'int8');
    crcBits  = zeros(0, 1, 'int8');
    mcsTable = wlan.internal.getRateTable(cfgVHT);
    eqDataSym = zeros(mcsTable.NSD(1), 0, mcsTable.Nss(1), 'like', rx);
    if calculateCPE==true
        varargout{1} = zeros(0, 0, class(rx)); % CPE
    end
    if calculateAE==true
        varargout{2} = zeros(0, 0, class(rx)); % AE
    end
    return;
end

% All optional params: parsed and validated
numSTSTotal = sum(numSTSVec);

% Signal input self-validation
validateattributes(rx, {'double','single'}, {'2d','finite'}, mfilename, 'VHT-Data field signal');
validateattributes(chanEst, {'double','single'}, {'3d','finite'}, mfilename, 'channel estimation');
validateattributes(noiseVarEst, {'double','single'}, {'real','scalar','nonnegative','finite'}, mfilename, 'noise variance estimation');

[numSamples,numRx] = size(rx);

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-Data', chanBW, cfgVHT.GuardInterval);

% Set channel coding
coder.varsize('channelCoding',[1,4]);
channelCoding = getChannelCoding(cfgVHT);

% Cross-validation between inputs
if muSpec==2
    coder.internal.errorIf(cfgVHT.NumSpaceTimeStreams(1) ~= numSTSu, ...
        'wlan:wlanVHTDataRecover:InvalidNumSTS', numSTSu, cfgVHT.NumSpaceTimeStreams(1));
end
coder.internal.errorIf(cfgVHT.STBC && muSpec > 0, 'wlan:wlanVHTDataRecover:InvalidSTBCMU');

coder.internal.errorIf(size(chanEst, 1) ~= ofdmInfo.NumTones, 'wlan:wlanVHTDataRecover:InvalidChanEst1D', ofdmInfo.NumTones);
coder.internal.errorIf(size(chanEst, 2) ~= numSTSTotal, 'wlan:wlanVHTDataRecover:InvalidChanEst2D', numSTSTotal);
coder.internal.errorIf(size(chanEst, 3) ~= numRx, 'wlan:wlanVHTDataRecover:InvalidChanEst3D');

% Cross-validation between inputs
numOFDMSym = cfgInfo.NumDataSymbols;
symLen = ofdmInfo.FFTLength+ofdmInfo.CPLength;
minInputLen = numOFDMSym*(symLen);
coder.internal.errorIf(numSamples < minInputLen, 'wlan:wlanVHTDataRecover:ShortDataInput', minInputLen);

% Calculate the number of whole OFDM symbols in the input signal. This
% accounts for the MU-padding and LDPC extra symbol, if needed.
if muSpec==2 && any(strcmp(channelCoding,'LDPC'))
    numOFDMSym = floor(numSamples/symLen);
    % Recalculate the minimum input signal length required to process LDPC
    % encoded data with an extra LDPC encoded symbol.
    minInputLen = numOFDMSym*symLen;
end

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
demod = wlan.internal.legacyOFDMDemodulate(rx(1:minInputLen,:), ofdmInfo, recParams.OFDMSymbolOffset, sum(numSTSVec));

% Index into streams for the user of interest
stsIdx = sum(numSTSVec(1:(userNum-1)))+(1:numSTSu);

% Pilot phase and amplitude tracking
pilotTrackingParams = struct('CalculateCPE', calculateCPE, 'CalculateAE', calculateAE, 'TrackPhase', strcmp(recParams.PilotPhaseTracking, 'PreEQ'), 'TrackAmplitude', strcmp(recParams.PilotAmplitudeTracking, 'PreEQ'));
[demod,varargout{1:2}] = wlan.internal.vhtTrackPilotError(demod, chanEst(ofdmInfo.PilotIndices,stsIdx,:), chanBW, 'VHT-Data', pilotTrackingParams);

% Equalization
if cfgVHT.STBC  % Only SU
    mcsTable = wlan.internal.getRateTable(cfgVHT);
    numSS = mcsTable.Nss(propIdx);  % Number of spatial streams
    [eqDataSym, dataCSI] = wlan.internal.stbcCombine(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,:,:), numSS, recParams.EqualizationMethod, noiseVarEst);
else    % Both SU and MU
    [eqDataSym, dataCSI] = wlan.internal.equalize(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,stsIdx,:), recParams.EqualizationMethod, noiseVarEst);
end

% Recover PSDU
[bits,crcBits] = wlan.internal.vhtDataBitRecover(eqDataSym, noiseVarEst, dataCSI, cfgVHT, recParams, propIdx);

end
