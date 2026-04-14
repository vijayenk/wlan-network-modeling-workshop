function y = wlanLSTF(cfgFormat,varargin)
%wlanLSTF Non-HT Short Training Field (L-STF)
%
%   Y = wlanLSTF(CFGFORMAT) generates the non-HT Short Training Field
%   (L-STF) time-domain signal for the VHT, HT-Mixed, and non-HT OFDM
%   transmission formats.
%
%   Y is the time-domain L-STF signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   CFGFORMAT is the format configuration object of type wlanVHTConfig, 
%   wlanHTConfig, or wlanNonHTConfig, which specifies the parameters for
%   the VHT, HT-Mixed, and non-HT OFDM formats, respectively. Only OFDM 
%   modulation is supported for a wlanNonHTConfig object input.
%
%   Y = wlanLSTF(CFGFORMAT,'OversamplingFactor',OSF) generates the L-STF
%   oversampled by a factor OSF. OSF must be >=1. The resultant IFFT length
%   must be even. The default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);

% Validate the format configuration object
validateattributes(cfgFormat, {'wlanVHTConfig','wlanHTConfig','wlanNonHTConfig'}, ...
    {'scalar'}, mfilename, 'format configuration object');

% Only applicable for OFDM and DUP-OFDM modulations
coder.internal.errorIf( isa(cfgFormat, 'wlanNonHTConfig') && ...
                        ~strcmp(cfgFormat.Modulation, 'OFDM'),...
                        'wlan:wlanLSTF:InvalidNonHTLSTF');

osf = wlan.internal.parseOSF(varargin{:});

% Validate the pre-HT or pre-VHT, fields cyclic shifts against the number
% of transmit antennas chains
validateConfig(cfgFormat,'CyclicShift');

% Generate L-STF
y = wlan.internal.lstf(cfgFormat,osf);

end
