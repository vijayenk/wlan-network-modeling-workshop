function y = vhtSTF(cfgOFDM,gamma,csh,numTx,spatialMapping,Q,varargin)
%vhtSTF Generate a time domain VHT STF field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = vhtSTF(CFGOFDM,GAMMA,CSH,NUMTX,SPATIALMAPPING,Q) generates the time
%   domain VHT-STF field.
%
%   Y is an Ns-by-Nt matrix containing the modulated VHT-STF field. Ns is
%   the number of samples and Nt is the number of transmit antennas.
%
%   CFGOFDM is the OFDM configuration structure.
%
%   GAMMA is the tone rotation to apply to each subcarrier.
%
%   CSH is the cyclic shift to apply per space-time stream.
%
%   NUMTX is the number of transmit antennas.
%
%   SPATIALMAPPING is a character vector specifying the type of spatial
%   mapping.
%
%   Q is a custom spatial mapping matrix.
%
%   Y = vhtSTF(...,OSF) returns the modulated symbols given the
%   oversampling factor OSF. When not specified OSF is 1.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

numSTSTotal = size(csh,1); % CSD is per space-time stream

% Non-HT L-STF (IEEE Std:802.11-2012, pg 1695)
VHTSTF = wlan.internal.lstfSequence();

numVHTFtones = 12*cfgOFDM.NumSubchannels; % Defined as per Table 22-8 (page 252)
vhtf = [zeros(6,1);  VHTSTF; zeros(5,1)];

% Replicate over CBW and apply phase rotation
vhtfToneRotated = repmat(vhtf, cfgOFDM.NumSubchannels, 1).*gamma;

% Replicate over multiple antennas
vhtfMIMO = repmat(vhtfToneRotated, 1, 1, numSTSTotal);

% Cyclic shift addition per space-time stream
vhtfCycShift = wlan.internal.cyclicShift(vhtfMIMO, csh, cfgOFDM.FFTLength);

% Spatial mapping
vhtfSpatialMapped = wlan.internal.spatialMap(vhtfCycShift, spatialMapping, numTx, Q);

% OFDM modulation
y = wlan.internal.ofdmModulate(vhtfSpatialMapped, cfgOFDM.CPLength, varargin{:})*cfgOFDM.FFTLength/sqrt(numVHTFtones*numSTSTotal);

end
