function Npe = heNumPacketExtensionSamples(varargin)
%numPacketExtensionSamples Number of samples in packet extension field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NPE = numPacketExtensionSamples(CFG) returns the number of samples in
%   Packet Extension.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>, or 
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>.
%
%   NPE = numPacketExtensionSamples(TPE,CBW) returns the number of samples
%   in Packet Extension. TPE is the packet extension duration, and CBW is
%   the channel bandwidth in MHz.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

if nargin==1
    cfg = varargin{1};
    commonCodingParams = wlan.internal.heCodingParameters(cfg);
    npp = wlan.internal.heNominalPacketPadding(cfg);
    trc = wlan.internal.heTimingRelatedConstants(cfg.GuardInterval,cfg.HELTFType,commonCodingParams.PreFECPaddingFactor,npp,commonCodingParams.NSYM);
    TPE = trc.TPE;
    cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
else
    TPE = varargin{1};
    cbw = varargin{2};
end
sf = cbw*1e-3; % Scaling factor to convert bandwidth and time in ns to samples
Npe = TPE*sf;