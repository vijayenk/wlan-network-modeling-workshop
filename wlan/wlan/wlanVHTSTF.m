function y = wlanVHTSTF(cfgVHT,varargin)
%wlanVHTSTF VHT Short Training Field (VHT-STF)
% 
%   Y = wlanVHTSTF(CFGVHT) generates the VHT Short Training Field (VHT-STF)
%   time-domain signal for the VHT transmission format.
%
%   Y is the time-domain VHT-STF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGVHT is the format configuration object of type wlanVHTConfig which
%   specifies the parameters for the VHT format.
%
%   Y = wlanVHTSTF(CFGVHT,'OversamplingFactor',OSF) generates the VHT-STF
%   oversampled by a factor OSF. OSF must be >=1. The resultant IFFT length
%   must be even. The default is 1.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);
validateattributes(cfgVHT, {'wlanVHTConfig'},{'scalar'},mfilename, ...
    'VHT format configuration object');
validateConfig(cfgVHT,'SMapping');
       
osf = wlan.internal.parseOSF(varargin{:});

% Get OFDM parameters  
cfgOFDM = wlan.internal.vhtOFDMInfo('VHT-LTF',cfgVHT.ChannelBandwidth,1);

% Get cyclic shift per space-time stream
numSTSTotal = sum(cfgVHT.NumSpaceTimeStreams);
csh = wlan.internal.getCyclicShiftVal('VHT',numSTSTotal, ...
    wlan.internal.cbwStr2Num(cfgVHT.ChannelBandwidth));

% Generate time-domain STF
gamma = wlan.internal.vhtCarrierRotations(cfgOFDM.NumSubchannels);
y = wlan.internal.vhtSTF(cfgOFDM,gamma,csh,cfgVHT.NumTransmitAntennas, ...
    cfgVHT.SpatialMapping,cfgVHT.SpatialMappingMatrix,osf);

end

