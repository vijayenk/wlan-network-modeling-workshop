function [bits, eqDataSym, cpe] = wlanVHTSIGBRecover(rx, ...
                                                           chanEst, noiseVarEst, chanBW, varargin)
%WLANVHTSIGBRECOVER Recover information bits in VHT-SIG-B field
%
%   BITS = wlanVHTSIGBRecover(RX, CHANEST, NOISEVAREST, CHANBW) recovers
%   the information bits in the VHT-SIG-B field for a single-user
%   transmission.
%
%   BITS is an int8 column vector containing the recovered information
%   bits.
%
%   RX is the received time-domain VHT-SIG-B field signal specified as an
%   Ns-by-Nr matrix of real or complex values. Ns represents the number of
%   time-domain samples in the VHT-SIG-B field and Nr represents the number
%   of receive antennas. Ns can be greater than the VHT-SIG-B field length;
%   in this case, additional samples at the end of RX are not used.
%
%   CHANEST is the estimated channel at data and pilot subcarriers based on
%   the VHT-LTF. It is a real or complex array of size Nst-by-Nsts-by-Nr,
%   where Nst represents the total number of occupied subcarriers and Nsts
%   is the total number of space-time streams used for the transmission.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CHANBW is the channel bandwidth, It is a character vector or string and
%   must be one of 'CBW20', 'CBW40', 'CBW80', 'CBW160'.
%
%   BITS = wlanVHTSIGBRecover(RXVHTSIGB, CHANEST, NOISEVAREST, CHANBW, ...
%   USERNUMBER, NUMSTS) recovers the information bits in the VHT-SIG-B
%   field of a VHT format multiuser transmission for an individual user of
%   interest.
%
%   USERNUMBER is the user of interest, specified as an integer between 1
%   and NumUsers, where NumUsers is the number of users in the
%   transmission.
%
%   NUMSTS is the number of space-time streams, specified as a
%   1-by-NumUsers vector. Element values specify the number of space-time
%   streams per user.
%
%   BITS = wlanVHTSIGBRecover(..., NAME, VALUE) specifies additional
%   name-value pair arguments described below. When a name-value pair is
%   not specified, its default value is used.
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
%   [..., EQDATASYM, CPE] = wlanVHTSIGBRecover(...) also returns the
%   equalized subcarriers and common phase error.
%
%   EQDATASYM is a complex column vector of length Nsd containing the
%   equalized symbols at data subcarriers. Nsd represents the number of
%   data subcarriers.
%
%   CPE is a scalar containing the common phase error between the received
%   and expected OFDM symbol.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

narginchk(4, 12);
nargoutchk(0, 3);

% Calculate CPE if requested
if nargout>2
    calculateCPE = true;
else
    calculateCPE = false;
end

% Validate and parse optional inputs
[muSpec, userNum, numSTSVec, recParams] = wlan.internal.parseVHTOptionalInputs(mfilename, size(chanEst, 2), varargin{:});

% Total NumSpaceTimeStreams
numSTSTotal = sum(numSTSVec);

% Validate channel bandwidth input
chanBW = wlan.internal.validateParam('CHANBW', chanBW, mfilename);

% Get OFDM configuration
ofdmInfo = wlan.internal.vhtOFDMInfo('VHT-SIG-B', chanBW);

% Validate VHT-SIG-B field signal input
validateattributes(rx, {'double','single'}, {'2d','finite','nrows', ofdmInfo.FFTLength*5/4}, mfilename, 'VHT-SIG-B field signal');
numRx = size(rx, 2);

% Validate channel estimates
validateattributes(chanEst, {'double','single'}, {'3d','finite','nonempty'}, mfilename, 'channel estimates');

% Cross validate inputs
if muSpec
    coder.internal.errorIf(size(chanEst, 2) ~= numSTSTotal, 'wlan:wlanVHTSIGBRecover:InvalidChanEst2D', numSTSTotal);
end
coder.internal.errorIf(size(chanEst, 1) ~= ofdmInfo.NumTones || (size(chanEst, 2) > 8) || (size(chanEst, 3) ~= numRx), 'wlan:wlanVHTSIGBRecover:InvalidChanEst', ofdmInfo.NumTones, numRx);

% Validate noise variance estimate input
validateattributes(noiseVarEst, {'double','single'}, {'real','scalar','nonnegative','finite'}, mfilename, 'noise variance estimate');

% OFDM demodulation with de-normalization and removing phase rotation per subcarrier
demod = wlan.internal.legacyOFDMDemodulate(rx, ofdmInfo, recParams.OFDMSymbolOffset, numSTSTotal);

% Pull out the space-time streams per user
stsU = numSTSVec(userNum);
stsIdx = sum(numSTSVec(1:(userNum-1)))+(1:stsU);

% Pilot phase tracking
pilotTrackingParams = struct('CalculateCPE', calculateCPE, 'CalculateAE', false, 'TrackPhase', strcmp(recParams.PilotPhaseTracking, 'PreEQ'), 'TrackAmplitude', false);
[demod,cpe] = wlan.internal.vhtTrackPilotError(demod, chanEst(ofdmInfo.PilotIndices,stsIdx,:), chanBW, 'VHT-SIG-B', pilotTrackingParams);

% Perform equalization
% Flip the 4th and 8th STS, i.e., P matrix multiplication
if any(numSTSTotal == [4 7 8])
    chanEst(ofdmInfo.DataIndices,4:4:end,:) = -chanEst(ofdmInfo.DataIndices,4:4:end,:);
end
% Pull out the streams per user and combine
[eqDataSym, csiData] = wlan.internal.equalize(demod(ofdmInfo.DataIndices,:,:), sum(chanEst(ofdmInfo.DataIndices,stsIdx,:),2), recParams.EqualizationMethod, noiseVarEst); % [numSD, 1]

% Recover bits
bits = wlan.internal.vhtSIGBBitRecover(eqDataSym, noiseVarEst, csiData, chanBW, ofdmInfo);

end

