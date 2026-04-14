function demod = wlanNonHTOFDMDemodulate(rx,fieldname,parms,varargin)
%wlanNonHTOFDMDemodulate Demodulate non-HT fields
%   SYM = wlanNonHTOFDMDemodulate(RX,FIELDNAME,CFG) demodulates the
%   time-domain received signal RX using OFDM demodulation parameters
%   appropriate for the specified FIELDNAME.
%
%   SYM is the demodulated frequency-domain signal, returned as a complex
%   matrix or 3-D array of size Nst-by-Nsym-by-Nr. Nst is the number of
%   active (occupied) subcarriers in the field. Nsym is the number of OFDM
%   symbols. Nr is the number of receive antennas.
%
%   RX is the received time-domain signal, specified as a complex matrix of
%   size Ns-by-Nr, where Ns represents the number of time-domain samples.
%   If Ns is not an integer multiple of the OFDM symbol length for the
%   specified field, then the function ignores the mod(Ns,Ls) trailing
%   samples, where Ls is the symbol length.
%
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG', or
%   'NonHT-Data'.
%
%   CFG is a format configuration object of type wlanNonHTConfig.
%
%   SYM = wlanNonHTOFDMDemodulate(RX,FIELDNAME,CHANBW) returns the
%   demodulated symbols for the specified channel bandwidth.
%
%   CHANBW must be 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
%   'CBW320'.
%
%   SYM = wlanNonHTOFDMDemodulate(...,'OversamplingFactor',OSF) specifies
%   the optional oversampling factor of the waveform to demodulate. The
%   oversampling factor must be greater than or equal to 1. The default
%   value is 1. When you specify an oversampling factor greater than 1, the
%   function uses a larger FFT size to demodulate the oversampled waveform.
%   The oversampling factor must result in an integer number of samples in
%   the cyclic prefix.
%
%   SYM = wlanNonHTOFDMDemodulate (...,'OFDMSymbolOffset',SYMOFFSET)
%   specifies the optional OFDM symbol sampling offset as a fraction of the
%   cyclic prefix length between 0 and 1, inclusive. The default value is
%   0.75.

%   Copyright 2020-2024 The MathWorks, Inc.

%#codegen

narginchk(3,7);

% Validate inputs and get OFDM configuration
validateattributes(rx,{'single','double'},{'2d','finite','nonempty'},mfilename,'rx');
numSamples = size(rx,1);
fieldname = validatestring(fieldname,{'NonHT-Data','L-SIG','L-LTF'},mfilename,'field name');
nvp = wlan.internal.demodNVPairParse(varargin{:});
cfgOFDM = wlanNonHTOFDMInfo(fieldname,parms,'OversamplingFactor',nvp.OversamplingFactor);
wlan.internal.demodValidateMinInputLength(numSamples,cfgOFDM);

if strcmp(fieldname,'L-LTF')
    demod = wlan.internal.demodulateLLTF(rx,cfgOFDM,nvp.SymOffset);
else
    % General case used for L-SIG and Non-HT Data
    demod = wlan.internal.ofdmDemodulate(rx,cfgOFDM,nvp.SymOffset);
end

end
