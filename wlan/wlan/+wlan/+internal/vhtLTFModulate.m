function y = vhtLTFModulate(LTF,gamma,P,R,Nltf,cfgOFDM,csh,numTx,spatialMapping,Q,varargin)
%vhtLTFModulate VHT-LTF tone rotation, CSD, spatial mapping and modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = vhtLTFModulate(LTF,GAMMA,P,R,NLTF,CFGOFDM,CSH,NUMTX,SPATIALMAPPING,Q)
%   returns modulated VHT-LTF samples. This process includes tone rotation,
%   CSD, spatial mapping and OFDM modulation.
%
%   LTF is the frequency domain VHT-LTF sequence.
%
%   GAMMA is the tone rotation to apply to each subcarrier.
%
%   P and R are the orthogonal mapping matrices for data and pilots.
%
%   NLTF is the number of LTFs
%
%   CFGOFDM is the OFDM configuration structure.
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
%   Y = vhtLTFModulate(...,OSF) returns the modulated symbols given the
%   oversampling factor OSF. When not specified OSF is 1.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Tone rotation
vhtltfToneRotated = LTF.*gamma;

% Define VHTLTF and output variable sizes
numSTS = numel(csh); % CSH is 1 element per STS
vhtltfSTS = complex(zeros(cfgOFDM.FFTLength,numSTS,Nltf));

% Generate and modulate each VHT-LTF symbol
% Map data and pilot subcarriers and apply P and R mapping matrices
for i = 1:Nltf
    vhtltfSTS(cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices),:,i) = vhtltfToneRotated(cfgOFDM.ActiveFFTIndices(cfgOFDM.DataIndices)) .* P(:, i).';
    vhtltfSTS(cfgOFDM.ActiveFFTIndices(cfgOFDM.PilotIndices),:,i) = vhtltfToneRotated(cfgOFDM.ActiveFFTIndices(cfgOFDM.PilotIndices)) .* R(:, i).';
end

% Cyclic shift addition
% The cyclic shift is applied per user per stream
vltfCSD =  wlan.internal.cyclicShift(permute(vhtltfSTS,[1 3 2]),csh,cfgOFDM.FFTLength);

% Spatial mapping
vltfSpatialMapped = wlan.internal.spatialMap(vltfCSD,spatialMapping,numTx,Q);

% OFDM modulation
y = wlan.internal.ofdmModulate(vltfSpatialMapped,cfgOFDM.CPLength,varargin{:})*cfgOFDM.FFTLength/sqrt(cfgOFDM.NumTones*numSTS);

end
