function sym = wlanDMGOFDMDemodulate(rx,varargin)
%wlanDMGOFDMDemodulate OFDM demodulate DMG fields
%   SYM = wlanDMGOFDMDemodulate(RX) OFDM demodulates the time-domain
%   received signal RX.
%
%   SYM is the demodulated frequency-domain signal, returned as a complex
%   matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst is the number of
%   active (occupied) subcarriers in the field. Nsym is the number of OFDM
%   symbols. Nr is the number of receive antennas.
%
%   RX is the received time-domain signal, specified as a complex matrix of
%   size Ns-by-Nr, where Ns represents the number of time-domain samples.
%   If Ns is not an integer multiple of the OFDM symbol length for the
%   specified field, then mod(Ns,symbol length) trailing samples are
%   ignored.
%
%   SYM = wlanDMGOFDMDemodulate(RX,'OFDMSymbolOffset',SYMOFFSET) specifies
%   the optional OFDM symbol sampling offset as a fraction of the cyclic
%   prefix length between 0 and 1, inclusive. When unspecified, a value of
%   0.75 is used.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

% Validate inputs
validateattributes(rx,{'double'},{'2d','finite','nonempty'},mfilename,'rx');
numSamples = size(rx,1);

% Get OFDM info
cfgOFDM = wlanDMGOFDMInfo();

% Get OFDM symbol offset
nvp = wlan.internal.demodNVPairParse(varargin{:});

% Validate input length
wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

% Demodulate
sym = wlan.internal.ofdmDemodulate(rx,cfgOFDM,nvp.SymOffset);

end

