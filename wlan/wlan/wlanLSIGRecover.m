function [bits, failCheck, eqDataSym, varargout] = wlanLSIGRecover( ...
    rx, chanEst, noiseVarEst, chanBW, varargin)
%wlanLSIGRecover Recover information bits in L-SIG field
%
%   [BITS, FAILCHECK] = wlanLSIGRecover(RX, CHANEST, NOISEVAREST, CHANBW)
%   recovers the information bits in the L-SIG field and performs parity
%   and rate checks.
%
%   BITS is an int8 column vector of length 24 containing the recovered
%   information bits.
%
%   FAILCHECK is a logical scalar which is true if BITS fails the parity
%   check or its first 4 bits is not one of the eight legitimate rates.
%
%   RX is the received time-domain L-SIG field signal. It is a Ns-by-Nr
%   matrix of real or complex values, where Ns represents the number of
%   time-domain samples in the L-SIG field and Nr represents the number of
%   receive antennas. Ns can be greater than the L-SIG field length; in
%   this case additional samples at the end of RX are not used.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the L-LTF. It is a real or complex array of size Nst-by-1-by-Nr, where
%   Nst represents the total number of occupied subcarriers.  The singleton
%   dimension corresponds to the single transmitted stream in the L-LTF
%   which includes the combined cyclic shifts if multiple transmit antennas
%   are used.
%
%   NOISEVAREST is the noise variance estimate. It is a real nonnegative
%   scalar.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must one of: 'CBW5','CBW10','CBW20','CBW40','CBW80', or 'CBW160'.
%
%   [BITS, FAILCHECK] = wlanLSIGRecover(..., NAME, VALUE) specifies
%   additional name-value pair arguments described below. When a name-value
%   pair is not specified, its default value is used.
%
%   'OFDMSymbolOffset'      OFDM symbol sampling offset. Specify the
%                           OFDMSymbolOffset as a fraction of the cyclic
%                           prefix (CP) length for every OFDM symbol, as a
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
%   [..., EQDATASYM, CPE] = wlanLSIGRecover(...) also returns the equalized
%   subcarriers and common phase error.
%
%   EQDATASYM is a complex column vector of length 48 containing the
%   equalized symbols at data carrying subcarriers. There are 48 data
%   carrying subcarriers in the L-SIG field.
%
%   CPE is an scalar containing the common phase error between the received
%   and expected OFDM symbol.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(4, 10);
nargoutchk(0, 4);

% Calculate CPE if requested
if nargout>3
    calculateCPE = true;
else
    calculateCPE = false;
end

% Validate channel bandwidth input
CBW = validatestring(chanBW, {'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160' }, mfilename, 'channel bandwidth');
% Error on partial matches with validatestring
coder.internal.errorIf(any(strcmpi(chanBW,{'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16'})), 'wlan:shared:InvalidNonHTChanBW');

% Validate and parse optional inputs
recParams = wlan.internal.parseOptionalInputs(mfilename, varargin{:});

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('L-SIG', CBW);

% Validate L-SIG field signal input
validateattributes(rx, {'single','double'}, {'2d','finite','nrows',ofdmInfo.FFTLength*5/4}, mfilename, 'L-SIG field signal');
numRx = size(rx, 2);

% Validate channel estimates
validateattributes(chanEst, {'single','double'}, {'3d','finite'}, mfilename, 'channel estimates');

% Cross validate inputs
[Nst, Nsym, Nr] = size(chanEst);
coder.internal.errorIf(Nst ~= ofdmInfo.NumTones, 'wlan:shared:InvalidChanEst1D', ofdmInfo.NumTones);
coder.internal.errorIf(Nsym ~= 1, 'wlan:shared:InvalidChanEst2D');
coder.internal.errorIf(Nr ~= numRx, 'wlan:shared:InvalidChanEst3D');

% Validate noise variance estimate input
validateattributes(noiseVarEst, {'single','double'}, {'real','scalar','nonnegative','finite'}, mfilename, 'noise variance estimate');

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
demod = wlan.internal.legacyOFDMDemodulate(rx, ofdmInfo, recParams.OFDMSymbolOffset, 1);

% Pilot phase tracking
pilotTrackingParams = struct('CalculateCPE', calculateCPE, 'CalculateAE', false, 'TrackPhase', strcmp(recParams.PilotPhaseTracking, 'PreEQ'), 'TrackAmplitude', false);
[demod, varargout{1}] = wlan.internal.vhtTrackPilotError(demod, chanEst(ofdmInfo.PilotIndices,:,:), CBW, 'L-SIG', pilotTrackingParams);

% Merge subchannel channel estimates and demodulated symbols together for
% the repeated subcarriers for data carrying subcarriers
NsdSeg = 48; % Number of subcarriers in 20 MHz segment
ofdmDataOutOne20MHz = coder.nullcopy(complex(zeros(NsdSeg, 1, numRx*ofdmInfo.NumSubchannels, 'like', rx))); % Preallocate for codegen
chanEstDataOne20MHz = ofdmDataOutOne20MHz; % Preallocate for codegen
[ofdmDataOutOne20MHz(:), chanEstDataOne20MHz(:)] = wlan.internal.mergeSubchannels(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,:,:), ofdmInfo.NumSubchannels);

% Perform equalization
[eqDataSym, csiData] = wlan.internal.equalize(ofdmDataOutOne20MHz, chanEstDataOne20MHz, recParams.EqualizationMethod, noiseVarEst);

% Demap and decode L-SIG symbols
[bits, failCheck] = wlanLSIGBitRecover(eqDataSym, noiseVarEst, csiData);

end

