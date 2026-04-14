function y = wlanLLTF(cfgFormat,varargin)
%wlanLLTF Non-HT Long Training Field (L-LTF)
%
%   Y = wlanLLTF(CFGFORMAT) generates the non-HT Long Training Field
%   (L-LTF) time-domain signal for the VHT, HT-Mixed, and non-HT OFDM
%   transmission formats.
%
%   Y is the time-domain L-LTF signal. It is a complex matrix of size
%   Ns-by-Nt, where Ns represents the number of time-domain samples and
%   Nt represents the number of transmit antennas.
%
%   CFGFORMAT is the format configuration object of type wlanVHTConfig, 
%   wlanHTConfig, or wlanNonHTConfig, which specifies the parameters for
%   the VHT, HT-Mixed, and non-HT OFDM formats, respectively. Only OFDM 
%   modulation is supported for a wlanNonHTConfig object input.
%
%   Y = wlanLLTF(CFGFORMAT,'OversamplingFactor',OSF) generates the L-LTF
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);

% Validate the format configuration object
validateattributes(cfgFormat,{'wlanVHTConfig','wlanHTConfig','wlanNonHTConfig'}, ...
                   {'scalar'},mfilename,'format configuration object');

% Only applicable for OFDM and DUP-OFDM modulations
coder.internal.errorIf(isa(cfgFormat,'wlanNonHTConfig')  && ...
                       ~strcmp(cfgFormat.Modulation,'OFDM'), ...
                       'wlan:wlanLLTF:InvalidNonHTLLTF');

osf = wlan.internal.parseOSF(varargin{:});

% Validate the pre-HT or pre-VHT, fields cyclic shifts against the number
% of transmit antennas chains
validateConfig(cfgFormat, 'CyclicShift');

% Generate L-LTF
y = wlan.internal.lltf(cfgFormat,osf);

end
