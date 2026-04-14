function info = wlanHTOFDMInfo(fieldname,varargin)
%wlanHTOFDMInfo OFDM information for HT
%   INFO = wlanHTOFDMInfo(FIELDNAME,CFG) returns a structure containing
%   OFDM information for the specified field and configuration.
% 
%   INFO is a structure with the these fields:
%     FFTLength              - FFT length
%     SampleRate             - Sample rate of waveform
%     CPLength               - Cyclic prefix length
%     NumTones               - Number of active subcarriers
%     NumSubchannels         - Number of 20 MHz subchannels
%     ActiveFrequencyIndices - Indices of active subcarriers relative to DC
%                              in the range [-NFFT/2, NFFT/2-1]
%     ActiveFFTIndices       - Indices of active subcarriers within the FFT
%                              in the range [1, NFFT]
%     DataIndices            - Indices of data within the active 
%                              subcarriers in the range [1, NumTones]
%     PilotIndices           - Indices of pilots within the active
%                              subcarriers in the range [1, NumTones]
% 
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG',
%   'HT-SIG', 'HT-LTF', or 'HT-Data'
%
%   CFG is a format configuration object of type wlanHTConfig.
%
%   When a format configuration object is not available, individual fields
%   can be demodulated using the below syntaxes:
%
%   INFO = wlanHTOFDMInfo('HT-Data',CHANBW,GI) returns OFDM info for
%   the HT-Data field.
%
%   CHANBW must be 'CBW20' or 'CBW40'.
%   GI the guard interval and must be 'Short' or 'Long'.
%
%   INFO = wlanHTOFDMInfo(FIELDNAME,CHANBW) returns the OFDM information
%   for all fields apart from 'HT-Data'.
%
%   INFO = wlanHTOFDMInfo(...,'OversamplingFactor',OSF) returns OFDM
%   information to oversample by a factor OSF. OSF must be >=1. The
%   oversampled cyclic prefix length in samples must be integer-valued. The
%   default is 1.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

narginchk(2,5);

fieldname = validatestring(fieldname,{'HT-Data','HT-LTF','HT-SIG','L-SIG','L-LTF'},mfilename,'file name');

guardInterval = 'Long'; % For codegen

if isa(varargin{1},'wlanHTConfig')
    % wlanHTOFDMInfo(FIELDNAME,CFG) 
    cfg = varargin{1};
    chanBW = cfg.ChannelBandwidth;
    guardInterval = cfg.GuardInterval;
    osf = wlan.internal.parseOSF(varargin{2:end});
elseif ischar(varargin{1}) || isstring(varargin{1})
    % wlanHTOFDMInfo(FIELDNAME,CHANBW,...)
    [chanBW,guardInterval,osf] = wlan.internal.vhtOFDMInfoParseFlatInput(fieldname,'HT-Data',mfilename,varargin{:});
else
    coder.internal.errorIf(true,'wlan:wlanHTOFDMInfo:UnexpectedArgument');
end

allInfo = wlan.internal.vhtOFDMInfo(fieldname,chanBW,osf,guardInterval);

% Take only required fields
info = struct;
info.FFTLength = allInfo.FFTLength;
info.SampleRate = allInfo.SampleRate;
info.CPLength = allInfo.CPLength;
info.NumSubchannels = allInfo.NumSubchannels;
info.NumTones = allInfo.NumTones;
info.ActiveFrequencyIndices = allInfo.ActiveFrequencyIndices;
info.ActiveFFTIndices = allInfo.ActiveFFTIndices;
info.DataIndices = allInfo.DataIndices;
info.PilotIndices = allInfo.PilotIndices;

end
