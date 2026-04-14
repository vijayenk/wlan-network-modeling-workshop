function y = vhtSIGBModulate(data,pilots,gamma,cfgOFDM,csh,numTx,spatialMapping,Q,varargin)
%vhtSIGBModulate Tone rotation, CSD, spatial mapping and OFDM modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = vhtSIGBModulate(DATA,PILOTS,GAMMA,CFGOFDM,CSH,NUMTX,SPATIALMAPPING,Q)
%   performs tone rotation, CSD, spatial mapping and OFDM modulation.
%
%   Y is an Ns-by-Nt matrix containing the modulated VHT-SIG-B field. Ns is
%   the number of samples and Nt is the number of transmit antennas.
%
%   DATA is an Nsd-by-1-Nsts matrix containing data symbols, where Nsd is
%   the number of data carrying subcarriers and Nsts is the number of
%   space-time streams.
%
%   PILOTS is a Nsp-by-1-by-Nsts matrix containing pilot symbols, where Nsp
%   is the number of pilot carrying subcarriers.
%
%   GAMMA is the tone rotation to apply to each subcarrier.
%
%   CFGOFDM is the OFDM configuration structure.
%
%   CSH is the cyclic shift to apply per space-time stream.
%
%   NUMTX is the number of transmit antennas.
%
%   MAPPINGTYPE is a character vector specifying the type of spatial
%   mapping.
%
%   Q is a custom spatial mapping matrix.
%
%   Y = vhtSIGBModulate(...,OSF) returns the modulated symbols given the
%   oversampling factor OSF. When not specified OSF is 1.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

numSTSTotal = numel(csh); % shift per space-time stream

% Tone packing for different CBW for a single stream, single symbol
symbol = complex(zeros(cfgOFDM.FFTLength,1,numSTSTotal));
symbol(cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices),:,:) = data;
symbol(cfgOFDM.ActiveFFTIndices(cfgOFDM.PilotIndices),:,:) = pilots(:,1,:); % Index for codegen

% Tone rotation (gamma) - based on legacy Nfft
symbol = symbol .* gamma;

% Cyclic shift addition
vhtsigCycShift = wlan.internal.cyclicShift(symbol,csh,cfgOFDM.FFTLength);

% Spatial mapping
vhtsigSpatialMapped = wlan.internal.spatialMap(vhtsigCycShift,spatialMapping,numTx,Q);

% OFDM modulation
y = wlan.internal.ofdmModulate(vhtsigSpatialMapped,cfgOFDM.CPLength,varargin{:})*cfgOFDM.FFTLength/sqrt(cfgOFDM.NumTones*numSTSTotal);

end
