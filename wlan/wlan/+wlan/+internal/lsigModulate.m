function y = lsigModulate(data,pilots,cfgFormat,varargin)
%lsigModulate Tone rotation, CSD, and OFDM modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = lsigModulate(DATA,PILOTS,CFGFORMAT) performs tone rotation, CSD,
%   spatial mapping and OFDM modulation.
%
%   Y is an Ns-by-Nt matrix containing the modulated L-SIG field. Ns is the
%   number of samples and Nt is the number of transmit antennas.
%
%   DATA is a Nsd-by-1 matrix containing data symbols, where Nsd is the
%   number of data carrying subcarriers.
%
%   PILOTS is a Nsp-by-1 matrix containing pilot symbols, where Nsp is the
%   number of pilot carrying subcarriers.
%
%   CFGFORMAT is the format configuration object of type <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>,
%   <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, <a
%   href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>, or <a href="matlab:help('wlanWURConfig')">wlanWURConfig</a>, which specifies the
%   parameters for the VHT, HT-Mixed, non-HT OFDM, and WUR formats,
%   respectively. Only OFDM modulation is supported for a wlanNonHTConfig
%   object input.
%
%   Y = lsigModulate(DATA,PILOTS,CFGFORMAT,OSF)  performs modulation with
%   the oversampling factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

% Map subcarriers and replicate over bandwidth
ofdm = wlan.internal.vhtOFDMInfo('L-SIG',cfgFormat.ChannelBandwidth,1);
sym = complex(zeros(ofdm.FFTLength,1));
sym(ofdm.ActiveFFTIndices(ofdm.DataIndices)) = repmat(data,ofdm.NumSubchannels,1);
sym(ofdm.ActiveFFTIndices(ofdm.PilotIndices)) = repmat(pilots,ofdm.NumSubchannels,1);

% Apply gamma rotation, replicate over antennas and apply cyclic shifts
[lsig,scalingFactor] = wlan.internal.legacyFieldMap(sym,ofdm.NumTones,cfgFormat);

% OFDM modulate
y = wlan.internal.ofdmModulate(lsig,ofdm.CPLength,varargin{:})*scalingFactor;

end

