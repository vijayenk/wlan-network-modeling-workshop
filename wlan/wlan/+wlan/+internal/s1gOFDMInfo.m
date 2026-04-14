function info = s1gOFDMInfo(fieldname,cfg,varargin)
%s1gOFDMInfo OFDM information for S1G
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   INFO = s1gOFDMInfo(FIELDNAME,CFG) returns a structure containing
%   OFDM information for the specified field and configuration.
%
%   FIELDNAME is the field of interest and must be one of: 'S1G-LTF1',
%   'S1G-SIG', 'S1G-LTF2N', 'S1G-SIG-A','S1G-DLTF', 'S1G-SIG-B',
%   'S1G-Data'.
%
%   CFG is a format configuration object of type <a href="matlab:help('wlanS1GConfig')">wlanS1GConfig</a>.
%   FIELDNAME must be relevant for the configuration specified with CFG.
%
%   See also wlanS1GOFDMInfo.

%   Copyright 2018-2021 The MathWorks, Inc.

%#codegen

% Validate the field is relevant for the format
format = packetFormat(cfg);

osf = wlan.internal.parseOSF(varargin{:});

% Get OFDM configuration for field
if strcmp(fieldname,'S1G-Data')
    guardInterval = cfg.GuardInterval;
    travelingPilots = cfg.TravelingPilots;
    if travelingPilots
        s = validateConfig(cfg,'MCS');
        numSym = s.NumDataSymbols;
        [ofdmCfg,dataInd,pilotInd] = wlan.internal.s1gOFDMConfig(cfg.ChannelBandwidth,guardInterval,fieldname(5:end),1,travelingPilots,numSym);
    else
        [ofdmCfg,dataInd,pilotInd] = wlan.internal.s1gOFDMConfig(cfg.ChannelBandwidth,guardInterval,fieldname(5:end));

    end
else
    % For all other field, guard interval is Long
    [ofdmCfg,dataInd,pilotInd] = wlan.internal.s1gOFDMConfig(cfg.ChannelBandwidth,'Long',fieldname(5:end));
end

% Index first column for traveling pilots case when a matrix is returned
activeFFTIndices = sort([ofdmCfg.DataIndices(:,1); ofdmCfg.PilotIndices(:,1)]);

% Get the cyclic prefix length
switch fieldname
  case 'S1G-LTF1'
    % Get CP per symbol for LTF-1 field depending on format
    gi = ofdmCfg.CyclicPrefixLength;
    gi2 = 2*ofdmCfg.CyclicPrefixLength;
    if strcmp(format,'S1G-1M')
        cp = [gi2 0 gi];
    else
        cp = [gi2 0];
    end
  case 'S1G-Data'
    if strcmp(cfg.GuardInterval,'Long')
        cp = ofdmCfg.CyclicPrefixLength;
    else
        % Returned CP length is short, therefore create a long for
        % first symbol
        cp = [2*ofdmCfg.CyclicPrefixLength ofdmCfg.CyclicPrefixLength];
    end
  otherwise
    cp = ofdmCfg.CyclicPrefixLength;
end

% Form structure
info = struct;
info.FFTLength = ofdmCfg.FFTLength*osf;
info.SampleRate = ofdmCfg.SampleRate*osf;
info.CPLength = cp*osf;
info.NumSubchannels = ofdmCfg.NumSubchannels;
info.NumTones = numel(activeFFTIndices);
info.ActiveFrequencyIndices = activeFFTIndices-ofdmCfg.FFTLength/2-1;
info.ActiveFFTIndices = activeFFTIndices+ofdmCfg.FFTLength*(osf-1)/2;
info.DataIndices = dataInd;
info.PilotIndices = pilotInd;

wlan.internal.validateOFDMOSF(osf,ofdmCfg.FFTLength,cp);

end
