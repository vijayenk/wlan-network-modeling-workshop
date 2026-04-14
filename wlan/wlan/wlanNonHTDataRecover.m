function [bits, eqDataSym, varargout] = wlanNonHTDataRecover( ...
    rx, chanEst, noiseVarEst, cfgNonHT, varargin)
%wlanNonHTDataRecover Recover information bits from non-HT Data field signal
%
%   BITS = wlanNonHTDataRecover(RX, CHANEST, NOISEVAREST, CFGNONHT)
%   recovers the information bits in the non-HT Data field for a non-HT
%   OFDM format transmission.
%
%   BITS is an int8 column vector of length 8*CFGNONHT.PSDULength
%   containing the recovered information bits.
%
%   RX is the received time-domain non-HT Data field signal. It is a
%   Ns-by-Nr matrix of real or complex values, where Ns represents the
%   number of time-domain samples in the non-HT Data field and Nr
%   represents the number of receive antennas. Ns can be greater than the
%   non-HT Data field length; in this case redundant samples at the end of
%   RX are not used.
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
%   CFGNONHT is the format configuration object of type wlanNonHTConfig
%   that specifies the non-HT format parameters. Only OFDM modulation is
%   supported.
%
%   BITS = wlanNonHTDataRecover(..., NAME, VALUE) specifies additional
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
%   [..., EQDATASYM, CPE, SCRAMINIT, AE] = wlanNonHTDataRecover(...) also
%   returns the equalized subcarriers, common phase error, recovered
%   scrambler initial state, and average amplitude error.
%
%   EQDATASYM is a complex 48-by-Nsym matrix containing the equalized
%   symbols at data carrying subcarriers. There are 48 data carrying
%   subcarriers in the non-HT Data field. Nsym represents the number of
%   OFDM symbols in the non-HT Data field.
%
%   CPE is a column vector of length Nsym containing the common phase error
%   between each received and expected OFDM symbol.
%
%   SCRAMINIT is an int8 scalar containing the recovered initial scrambler
%   state. The function maps the initial state bits X1 to X7, as specified
%   in IEEE 802.11-2016, Section 17.3.5.5 to SCRAMINIT, treating the
%   rightmost bit as most significant.
%
%   AE is a real Nsym-by-Nr array containing the average amplitude error
%   for all subcarriers, in dB, with respect to the estimated receiver
%   pilots per OFDM symbol for each receive antenna.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(4, 12);
nargoutchk(0, 5);

% Calculate CPE or AE if requested
calculateCPE = false;
calculateAE = false;
if nargout>2
    calculateCPE = true;
end
if nargout>4
    calculateAE = true;
end

% Non-HT configuration input self-validation
validateattributes(cfgNonHT, {'wlanNonHTConfig'}, {'scalar'}, mfilename, 'format configuration object');
% Only applicable for OFDM and DUP-OFDM modulations
coder.internal.errorIf(~strcmp(cfgNonHT.Modulation, 'OFDM'), 'wlan:shared:InvalidModulation');
s = validateConfig(cfgNonHT);

% Validate rxNonHTData
validateattributes(rx, {'single', 'double'}, {'2d', 'finite'},  mfilename, 'rx');
% Validate chanEst
validateattributes(chanEst, {'single', 'double'}, {'3d', 'finite'},  mfilename, 'chanEst');
% Validate noiseVarEst
validateattributes(noiseVarEst, {'single', 'double'}, {'real', 'scalar', 'nonnegative', 'finite'},  mfilename, 'noiseVarEst');

% Validate and parse optional inputs
recParams = wlan.internal.parseOptionalInputs(mfilename, varargin{:});

numRx = size(rx, 2);

numOFDMSym = s.NumDataSymbols;

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('NonHT-Data', cfgNonHT.ChannelBandwidth);

% Cross validate inputs
[Nst, Nsym, Nr] = size(chanEst);
coder.internal.errorIf(Nst ~= ofdmInfo.NumTones, 'wlan:wlanNonHTDataRecover:InvalidNHTChanEst1D', ofdmInfo.NumTones);
coder.internal.errorIf(Nsym ~= 1, 'wlan:wlanNonHTDataRecover:InvalidNHTChanEst2D');
coder.internal.errorIf(Nr ~= numRx, 'wlan:wlanNonHTDataRecover:InvalidNHTChanEst3D');

% Cross-validation between inputs
minInputLen = numOFDMSym*(ofdmInfo.FFTLength+ofdmInfo.CPLength);
coder.internal.errorIf(size(rx, 1) < minInputLen, 'wlan:wlanNonHTDataRecover:ShortNHTDataInput', minInputLen);

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
demod = wlan.internal.legacyOFDMDemodulate(rx(1:minInputLen,:), ofdmInfo, recParams.OFDMSymbolOffset, 1);

% Track pilot error
% Reference pilots - IEEE Std 802.11-2020, Eqn 17-22
z = 1; % Offset by 1 to account for L-SIG pilot symbol
refPilots = wlan.internal.nonHTPilots(numOFDMSym, z, cfgNonHT.ChannelBandwidth);
pilotTrackingParams = struct('CalculateCPE', calculateCPE, 'CalculateAE', calculateAE, 'TrackPhase', strcmp(recParams.PilotPhaseTracking, 'PreEQ'), 'TrackAmplitude', strcmp(recParams.PilotAmplitudeTracking, 'PreEQ'));
[demod,varargout{1},varargout{3}] = wlan.internal.trackPilotErrorCore(demod, chanEst(ofdmInfo.PilotIndices,:,:), refPilots, ofdmInfo, pilotTrackingParams);

% Merge subchannel channel estimates and demodulated symbols together for
% the repeated subcarriers for data carrying subcarriers
NsdSeg = 48; % Number of subcarriers in 20 MHz segment
ofdmDataOutOne20MHz = coder.nullcopy(complex(zeros(NsdSeg, numOFDMSym, numRx*ofdmInfo.NumSubchannels, 'like', rx))); % Preallocate for codegen
chanEstDataOne20MHz = coder.nullcopy(complex(zeros(NsdSeg, 1, numRx*ofdmInfo.NumSubchannels, 'like', rx))); % Preallocate for codegen
[ofdmDataOutOne20MHz(:), chanEstDataOne20MHz(:)] = wlan.internal.mergeSubchannels(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,:,:), ofdmInfo.NumSubchannels);

% Equalization
[eqDataSym, csiData] = wlan.internal.equalize(ofdmDataOutOne20MHz, chanEstDataOne20MHz, recParams.EqualizationMethod, noiseVarEst);

% Demap and decode
[bits, varargout{2}] = wlanNonHTDataBitRecover(eqDataSym, noiseVarEst, csiData, cfgNonHT);

end

