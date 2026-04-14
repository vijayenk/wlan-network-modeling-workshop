function demod = legacyOFDMDemodulate(rx,cfgOFDM,symOffset,numTxSTS)
%legacyOFDMDemodulate OFDM demodulate - removing gamma rotation and normalization
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEMOD = legacyOFDMDemodulate(RX,CFGOFDM,SYMOFFSET,NUMTXSTS) OFDM
%   demodulates the time domain input RX given the OFDM configuration
%   structure CFGOFDM, OFDM symbol offset SYMOFFSET, and number of transmit
%   antennas or space-time streams for normalization NUMSTS.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

demod = wlan.internal.ofdmDemodulate(rx,cfgOFDM,symOffset);

% Denormalization
demod = demod*sqrt(numTxSTS);

% Remove phase rotation on subcarriers
gamma = wlan.internal.vhtCarrierRotations(cfgOFDM.NumSubchannels);
demod = demod ./ gamma(cfgOFDM.ActiveFFTIndices);
end
