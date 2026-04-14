function y = s1gDSTF(cfgS1G,varargin)
%s1gDSTF S1G Beam-changeable Short Training Field (S1G-DSTF)
% 
%   Y = s1gDSTF(CFGS1G) generates the S1G Beam changeable Short Training
%   Field (S1G-DSTF) time-domain signal for the S1G transmission format.
%
%   Y is the time-domain DSTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gDSTF(cfgS1G,OSF) generates the S1G-DSTF for the given
%   oversampling factor OSF. When not specified 1 is assumed.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% Generate D-STF as per IEEE P802.11ah/D5.0 Section 24.3.8.2.2.2.3

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(~strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GShort1M');
validateConfig(cfgS1G,'SMapping');

% Get OFDM parameters
numSTSTotal = sum(cfgS1G.NumSpaceTimeStreams);    
cfgOFDM = wlan.internal.s1gOFDMInfo('S1G-DLTF',cfgS1G);

% Get cyclic shift per space-time stream
csh = wlan.internal.getCyclicShiftVal('S1G',numSTSTotal, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));

% Generate time-domain STF
gamma = wlan.internal.s1gCarrierRotations(cfgS1G.ChannelBandwidth);
y = wlan.internal.vhtSTF(cfgOFDM,gamma,csh,cfgS1G.NumTransmitAntennas, ...
    cfgS1G.SpatialMapping,cfgS1G.SpatialMappingMatrix,varargin{:});

end