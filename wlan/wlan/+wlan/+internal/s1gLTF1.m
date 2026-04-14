function y = s1gLTF1(cfgS1G,varargin)
%s1gLTF1 S1G Omni-directional Long Training Field (S1G-LTF1)
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = s1gLTF1(cfgS1G) generates the omni directional long training field
%   (LTF1) for the S1G Long preamble.
%
%   Y is the time-domain LTF1 signal. It is a complex matrix of size
%   Ns-by-Nt where Ns represents the number of time-domain samples and Nt
%   represents the number of transmit antennas.
%
%   CFGS1G is the format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a> which
%   specifies the parameters for the S1G format.
%
%   Y = s1gLTF1(cfgS1G,OSF) generates the S1G-LTF1 for the given
%   oversampling factor OSF. When not specified 1 is assumed.

%   Copyright 2016-2025 The MathWorks, Inc.

%#codegen

% Validate S1G configuration object
validateattributes(cfgS1G,{'wlanS1GConfig'},{'scalar'},mfilename,'S1G format configuration object');
coder.internal.errorIf(~strcmp(packetFormat(cfgS1G),'S1G-Long'),'wlan:shared:UndefinedFieldForS1GShort1M');

% OFDM params
cfgOFDM = wlan.internal.s1gOFDMConfig(cfgS1G.ChannelBandwidth, ...
    'Long','LTF1',cfgS1G.NumTransmitAntennas);

% Get sequence
S = wlan.internal.vhtltfSequence(cfgS1G.ChannelBandwidth,1);

% Tone rotation
ltfToneRotated = S.*cfgOFDM.CarrierRotations;

% Repeat over transmit antennas
ltfToneRotatedMIMO = repmat(ltfToneRotated,1,1,cfgS1G.NumTransmitAntennas);

% Apply cyclic shift per space-time stream
csh = wlan.internal.getCyclicShiftVal('S1G',cfgS1G.NumTransmitAntennas, ...
    wlan.internal.cbwStr2Num(cfgS1G.ChannelBandwidth));
ltfCycShift = wlan.internal.cyclicShift(ltfToneRotatedMIMO,csh,cfgOFDM.FFTLength);

% OFDM modulation
% CP length = TGI2  (IEEE P802.11ah/D5.0, Eqn 24-24)
modOut = wlan.internal.ofdmModulate(ltfCycShift,0,varargin{:});
y = [modOut(end/2+1:end,:); modOut; modOut]*cfgOFDM.NormalizationFactor;
end
