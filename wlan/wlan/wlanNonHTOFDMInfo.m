function info = wlanNonHTOFDMInfo(fieldname,varargin)
%wlanNonHTOFDMInfo OFDM information for Non-HT
%   INFO = wlanNonHTOFDMInfo(FIELDNAME) returns a structure containing OFDM
%   information for the specified field.
% 
%   INFO is a structure with these fields:
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
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG', or
%   'NonHT-Data'.
%
%   INFO = wlanNonHTOFDMInfo(FIELDNAME,CHANBW) returns OFDM information for
%   the specified field and channel bandwidth. CHANBW must be one of
%   'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or 'CBW320'. When
%   not specified 'CBW20' is assumed.
%
%   INFO = wlanNonHTOFDMInfo(FIELDNAME,CFG) returns OFDM information for
%   the specified field and format configuration object. CFG is the format
%   configuration object of type wlanNonHTConfig that specifies the non-HT
%   format parameters. Only OFDM modulation is supported.
%
%   INFO = wlanNonHTOFDMInfo(...,'OversamplingFactor',OSF) returns OFDM
%   information to oversample by a factor OSF. OSF must be >=1. The
%   oversampled cyclic prefix length in samples must be integer-valued. The
%   default is 1.

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

fieldname = validatestring(fieldname,{'NonHT-Data','L-SIG','L-LTF'},mfilename,'field name');

if nargin>1
    if ischar(varargin{1}) || isstring(varargin{1})
        if nargin==3
            % wlanNonHTOFDMInfo(FIELD,OversamplingFactor,OSF)
            osf = wlan.internal.parseOSF(varargin{1:end});
            chanBW = 'CBW20'; % Default
        else
            % wlanNonHTOFDMInfo(FIELD,CHANBW, ...)
            chanBW = wlan.internal.validateParam('NONHTCHANBW',varargin{1},mfilename);
            osf = wlan.internal.parseOSF(varargin{2:end});
        end
    else
        % wlanNonHTOFDMInfo(FIELD,CFG,...)
        % Validate the format configuration object
        validateattributes(varargin{1},{'wlanNonHTConfig'},{'scalar'},mfilename,'format configuration object');
        % Only applicable for OFDM and DUP-OFDM modulations
        coder.internal.errorIf(~strcmp(varargin{1}.Modulation,'OFDM'),'wlan:shared:InvalidModulation');
        chanBW = varargin{1}.ChannelBandwidth;
        osf = wlan.internal.parseOSF(varargin{2:end});
    end
    [fftLength,numSubchannels] = wlan.internal.cbw2nfft(chanBW);
else
    % Defaults
    fftLength = 64;
    numSubchannels = 1;
    osf = 1;
    chanBW = 'CBW20'; % Default for returning the sample rate
end
switch fieldname
    case {'NonHT-Data','L-SIG'}
        cpLength = 16*numSubchannels;
    otherwise % 'L-LTF'
        cpLength = [32 0]*numSubchannels;
end

% Get the indices of data and pilots within active subcarriers
[freqInd,pilotIdx] = wlan.internal.nonHTToneIndices(numSubchannels);
numST = numel(freqInd);
idx = ismember(freqInd,pilotIdx);
seq = (1:numST)';
pilotIndices = seq(idx);
dataIndices = seq(~idx);

% Form structure
info = struct;
info.FFTLength = fftLength*osf;
info.SampleRate = wlan.internal.cbwStr2Num(chanBW)*1e6*osf;
info.CPLength = cpLength*osf;
info.NumSubchannels = numSubchannels;
info.NumTones = numST;
info.ActiveFrequencyIndices = freqInd;
info.ActiveFFTIndices = freqInd+fftLength*osf/2+1;
info.DataIndices = dataIndices;
info.PilotIndices = pilotIndices;

wlan.internal.validateOFDMOSF(osf,fftLength,cpLength);

end
