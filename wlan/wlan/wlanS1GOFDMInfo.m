function info = wlanS1GOFDMInfo(fieldname,cfg,varargin)
%wlanS1GOFDMInfo OFDM information for S1G
%   INFO = wlanS1GOFDMInfo(FIELDNAME,CFG) returns a structure containing
%   OFDM information for the specified field and configuration.
% 
%   INFO is a structure with these fields:
%     FFTLength              - FFT length
%     SampleRate             - Sample rate of waveform
%     CPLength               - Cyclic prefix length
%     NumTones               - Number of active subcarriers
%     NumSubchannels         - Number of 2 MHz subchannels for all packet
%                              formats except S1G-1M. The function returns
%                              this field as 1 for S1G-1M packets.
%     ActiveFrequencyIndices - Indices of active subcarriers relative to DC
%                              in the range [-NFFT/2, NFFT/2-1]
%     ActiveFFTIndices       - Indices of active subcarriers within the FFT
%                              in the range [1, NFFT]
%     DataIndices            - Indices of data within the active 
%                              subcarriers in the range [1, NumTones]
%     PilotIndices           - Indices of pilots within the active
%                              subcarriers in the range [1, NumTones]
% 
%   FIELDNAME is the field of interest and must be one of: 'S1G-LTF1',
%   'S1G-SIG', 'S1G-LTF2N', 'S1G-SIG-A','S1G-DLTF', 'S1G-SIG-B',
%   'S1G-Data'.
%
%   CFG is a format configuration object of type wlanS1GConfig. 
%   FIELDNAME must be relevant for the configuration specified with CFG.
%
%   INFO = wlanS1GOFDMInfo(...,'OversamplingFactor',OSF) returns OFDM
%   information to oversample by a factor OSF. OSF must be >=1. The
%   oversampled cyclic prefix length in samples must be integer-valued. The
%   default is 1.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

% Validate inputs
fieldname = validatestring(fieldname,{'S1G-Data','S1G-DLTF','S1G-SIG-B','S1G-SIG-A','S1G-SIG','S1G-LTF1','S1G-LTF2N'},mfilename,'field');
validateattributes(cfg,{'wlanS1GConfig'},{'scalar'},mfilename,'CFG');

% Validate the field is relevant for the format
format = packetFormat(cfg);
if strcmp(format,'S1G-Long')
    if any(strcmp(fieldname,{'S1G-SIG','S1G-LTF2N'}))
        coder.internal.error('wlan:wlanS1GOFDMInfo:InvalidField',fieldname,format);
    end
else
    if any(strcmp(fieldname,{'S1G-DLTF','S1G-SIG-A','S1G-SIG-B'}))
        coder.internal.error('wlan:wlanS1GOFDMInfo:InvalidField',fieldname,format);
    end
end

info = wlan.internal.s1gOFDMInfo(fieldname,cfg,varargin{:});

end

