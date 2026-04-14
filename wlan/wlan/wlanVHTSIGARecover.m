function [bits, failCRC, eqDataSym, cpe] = wlanVHTSIGARecover( ...
    rx, chanEst, noiseVarEst, chanBW, varargin)
%WLANVHTSIGARECOVER Recover information bits in VHT-SIG-A field
%
%   [BITS, FAILCRC] = wlanVHTSIGARecover(RX, CHANEST, NOISEVAREST, CHANBW)
%   recovers the information bits in the VHT-SIG-A field and performs CRC
%   check.
%
%   BITS is an int8 column vector of length 48 containing the recovered
%   information bits.
%
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar.
%
%   RX is the received time-domain VHT-SIG-A field signal. It is a Ns-by-Nr
%   matrix of real or complex values, where Ns represents the number of
%   time-domain samples in the VHT-SIG-A field and Nr represents the number
%   of receive antennas. Ns can be greater than the VHT-SIG-A field length;
%   in this case additional samples at the end of RX are not used.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the L-LTF . It is a real or complex array of size Nst-by-1-by-Nr, where
%   Nst represents the total number of occupied subcarriers. The singleton
%   dimension corresponds to the single transmitted stream in the L-LTF
%   which includes the combined cyclic shifts if multiple transmit antennas
%   are used.
%
%   NOISEVAREST is the noise variance estimate. It is a double precision,
%   real, nonnegative scalar.
%
%   CHANBW is a character vector or string describing the channel bandwidth
%   and must be one of the following: 'CBW20','CBW40','CBW80','CBW160'.
%
%   [BITS, FAILCRC] = wlanVHTSIGARecover(..., NAME, VALUE) specifies
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
%   [..., EQDATASYM, CPE] = wlanVHTSIGARecover(...) also returns the
%   equalized subcarriers and common phase error.
%
%   EQDATASYM is a 48-by-2 complex matrix containing the equalized symbols
%   at data subcarriers. There are 48 data subcarriers in each of the 2
%   OFDM symbols which constitute the VHT-SIG-A field.
%
%   CPE is a column vector of length 2 containing the common phase error
%   between each of the 2 received and expected OFDM symbols.

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
chanBW = wlan.internal.validateParam('CHANBW', chanBW, mfilename);

% Validate and parse optional inputs
recParams = wlan.internal.parseOptionalInputs(mfilename, varargin{:});

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-SIG-A', chanBW);

% Validate VHT-SIG-A field signal input
validateattributes(rx, {'double','single'}, {'2d','finite', 'nrows',ofdmInfo.FFTLength*5/2}, mfilename, 'VHT-SIG-A field signal');
numRx = size(rx, 2);

% Validate channel estimates
validateattributes(chanEst, {'double','single'}, {'3d','finite'}, mfilename, 'channel estimates');

% Cross validate inputs
coder.internal.errorIf(size(chanEst, 1) ~= ofdmInfo.NumTones, 'wlan:wlanVHTSIGARecover:InvalidChanEst1D', ofdmInfo.NumTones);
coder.internal.errorIf(size(chanEst, 2) ~= 1, 'wlan:wlanVHTSIGARecover:InvalidChanEst2D');
coder.internal.errorIf(size(chanEst, 3) ~= numRx, 'wlan:wlanVHTSIGARecover:InvalidChanEst3D');

% Validate noise variance estimate input
validateattributes(noiseVarEst, {'double','single'}, {'real','scalar','nonnegative','finite'}, mfilename, 'noise variance estimate');

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
demod = wlan.internal.legacyOFDMDemodulate(rx, ofdmInfo, recParams.OFDMSymbolOffset, 1);

% Pilot phase tracking
pilotTrackingParams = struct('CalculateCPE', calculateCPE, 'CalculateAE', false, 'TrackPhase', strcmp(recParams.PilotPhaseTracking, 'PreEQ'), 'TrackAmplitude', false);
[demod,cpe] = wlan.internal.vhtTrackPilotError(demod, chanEst(ofdmInfo.PilotIndices,:,:), chanBW, 'VHT-SIG-A', pilotTrackingParams);

% Merge subchannel channel estimates and demodulated symbols together for the repeated subcarriers
[ofdmOutDataOne20MHz, chanEstDataOne20MHz] = wlan.internal.mergeSubchannels(demod(ofdmInfo.DataIndices,:,:), chanEst(ofdmInfo.DataIndices,:,:), ofdmInfo.NumSubchannels);

% Perform equalization
[eqDataSym, csiData] = wlan.internal.equalize(ofdmOutDataOne20MHz, chanEstDataOne20MHz, recParams.EqualizationMethod, noiseVarEst); % [48, 2]

% Recover bits
[bits, failCRC] = wlan.internal.vhtSIGABitRecover(eqDataSym, noiseVarEst, csiData);

end

