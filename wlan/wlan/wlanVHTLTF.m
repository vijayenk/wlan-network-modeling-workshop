function y = wlanVHTLTF(cfgVHT,varargin)
%wlanVHTLTF VHT Long Training Field (VHT-LTF)
% 
%   Y = wlanVHTLTF(CFGVHT) generates the VHT Long Training Field (VHT-LTF)
%   time-domain signal for the VHT transmission format.
%
%   Y is the time-domain VHT-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGVHT is the format configuration object of type wlanVHTConfig which
%   specifies the parameters for the VHT format.
%
%   Y = wlanVHTLTF(CFGVHT,'OversamplingFactor',OSF) generates the VHT-LTF
%   oversampled by a factor OSF. OSF must be >=1. The resultant cyclic
%   prefix length in samples must be integer-valued for all symbols. The
%   default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);
validateattributes(cfgVHT, {'wlanVHTConfig'}, {'scalar'}, mfilename, ...
                   'VHT format configuration object');
validateConfig(cfgVHT, 'SMapping');

osf = wlan.internal.parseOSF(varargin{:});

chanBW = cfgVHT.ChannelBandwidth;
numSTSTotal = sum(cfgVHT.NumSpaceTimeStreams); 
   
% Get OFDM parameters, user VHT-LTF and ignore CP length
cfgOFDM = wlan.internal.vhtOFDMInfo('VHT-LTF', chanBW, 1);

% Get VHT-LTF sequences
[VLTF, Pvhtltf, Nltf] = wlan.internal.vhtltfSequence(chanBW, numSTSTotal);

% P and R matrices as per IEEE Std 802.11ac-2013 Sec. 22.3.8.3.5
P = Pvhtltf(1:numSTSTotal,1:Nltf);
R = repmat(Pvhtltf(1,1:Nltf),numSTSTotal,1); % Same row used for all STSs

% Perform tone rotation, CSD, spatial mapping and OFDM modulation
gamma = wlan.internal.vhtCarrierRotations(cfgOFDM.NumSubchannels);
csh = wlan.internal.getCyclicShiftVal('VHT', numSTSTotal, cfgOFDM.NumSubchannels*20);
y = wlan.internal.vhtLTFModulate(VLTF, gamma, P, R, Nltf, cfgOFDM, csh, ...
    cfgVHT.NumTransmitAntennas, cfgVHT.SpatialMapping, cfgVHT.SpatialMappingMatrix,osf);

end
