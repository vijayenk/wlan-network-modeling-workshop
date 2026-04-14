function y = s1gDLTF(cfgS1G,varargin)
%s1gDLTF S1G Beam Changeable Long Training Fields (S1G-DLTF)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = s1gDLTF(cfgS1G) generates the beam changeable long training field
%   (DLTF) for the S1G Long preamble.
%
%   Y is the time-domain D-LTF signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gDLTF(cfgS1G,OSF) generates the S1G-DLTF for the given
%   oversampling factor OSF. When not specified 1 is assumed.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% Generate D-LTF as per IEEE P802.11ah/D5.0 Section 24.3.8.2.2.2.4

nargoutchk(0,2);

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(~strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GShort1M');
validateConfig(cfgS1G,'SMapping');

% Get VHT-LTF sequence
numSTSTotal = sum(cfgS1G.NumSpaceTimeStreams); 
[LTF,Pvhtltf,Nltf] = wlan.internal.vhtltfSequence(cfgS1G.ChannelBandwidth,numSTSTotal);

% Get OFDM parameters
cfgOFDM = wlan.internal.s1gOFDMInfo('S1G-DLTF',cfgS1G);

% Define LTF and output variable sizes
% ltfSTS = complex(zeros(FFTLen, numSTSTotal));
% A matrix for data subcarriers 
Adata = Pvhtltf(1:numSTSTotal,1:Nltf); 
% A matrix for pilot subcarriers (first column of P matrix)
Apilots = repmat(Pvhtltf(1:numSTSTotal,1),1,Nltf); % Same column for all LTFs

% Perform tone rotation, CSD, spatial mapping and OFDM modulation
gamma = wlan.internal.s1gCarrierRotations(cfgS1G.ChannelBandwidth);
csh = wlan.internal.getCyclicShiftVal('S1G',numSTSTotal, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));
y = wlan.internal.vhtLTFModulate(LTF,gamma,Adata,Apilots,Nltf,cfgOFDM,csh, ...
    cfgS1G.NumTransmitAntennas,cfgS1G.SpatialMapping,cfgS1G.SpatialMappingMatrix,varargin{:});
end
