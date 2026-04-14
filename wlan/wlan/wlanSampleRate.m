function sr = wlanSampleRate(x,varargin)
%wlanSampleRate Return the nominal sample rate
%
%   SR = wlanSampleRate(CFGFORMAT) returns the nominal sample rate for the
%   specified format configuration object, CFGFORMAT.
%
%   SR is the sample rate in samples per second.
%
%   CFGFORMAT is the format configuration object of type wlanVHTConfig,
%   wlanHTConfig, wlanNonHTConfig, wlanS1GConfig, wlanDMGConfig,
%   wlanHESUConfig, wlanHEMUConfig, wlanHETBConfig, wlanHERecoveryConfig,
%   wlanEHTMUConfig, wlanEHTTBConfig, wlanEHTRecoveryConfig, wlanWURConfig,
%   or which specifies the parameters for the VHT, HT-Mixed, Non-HT, S1G,
%   DMG, HE, EHT, and WUR formats.
%
%   SR = wlanSampleRate(CHANBW) returns the nominal sample rate for the
%   specified channel bandwidth as a string scalar or character vector.
%   CHANBW must be one of 'CBW1', 'CBW2', 'CBW4', 'CBW5', 'CBW8', 'CBW10',
%   'CBW16', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'.
%
%   SR = wlanSampleRate(...,'OversamplingFactor',OSF) returns the sample
%   rate for the specified format configuration object or channel bandwidth
%   oversampled by a factor OSF. OSF must be >=1. The default is 1.

%   Copyright 2017-2024 The MathWorks, Inc.

%#codegen

narginchk(1,3);

if isstring(x) || ischar(x) % String scalar or character vector as an input
    chanBW = validatestring(x,{'CBW1','CBW2','CBW4','CBW5','CBW8','CBW10','CBW16','CBW20','CBW40','CBW80','CBW160','CBW320'},mfilename,'channel bandwidth');
    sr = wlan.internal.cbwStr2Num(chanBW)*1e6;
else
    validateattributes(x,{'wlanVHTConfig','wlanHTConfig','wlanNonHTConfig','wlanS1GConfig','wlanDMGConfig','wlanHESUConfig','wlanHEMUConfig','wlanHETBConfig','wlanHERecoveryConfig','wlanWURConfig','wlanEHTMUConfig','wlanEHTTBConfig','wlanEHTRecoveryConfig'},{'scalar'},mfilename,'format configuration object');

    if (isa(x,'wlanNonHTConfig')&&strcmp(x.Modulation,'DSSS')) % non-HT DSSS
        sr = 11e6;
    elseif isa(x,'wlanDMGConfig')
        if strcmp(phyType(x),'OFDM')
            sr = 2640e6;
        else
            sr = 1760e6;
        end
    else % EHT, HE, S1G, VHT, HT, Non-HT OFDM, WUR
        chanBW = x.ChannelBandwidth;
        if isa(x,'wlanHERecoveryConfig') || isa(x,'wlanEHTRecoveryConfig')
            wlan.internal.mustBeDefined(chanBW,'ChannelBandwidth');
        end
        sr = wlan.internal.cbwStr2Num(chanBW)*1e6;
    end
end

if nargin>1
    osf = wlan.internal.parseOSF(varargin{:});
    sr = sr*osf;
end

end

