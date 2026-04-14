function info = vhtOFDMInfo(fieldname,chanBW,varargin)
%vhtOFDMInfo OFDM information for VHT and HT
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   INFO = vhtOFDMInfo(FIELDNAME,CHANBW) returns a structure containing
%   OFDM information for the specified field and channel bandwidth.
%
%   INFO is a structure with these fields:
%     FFTLength               - FFT length
%     SampleRate              - Sample rate of waveform
%     CPLength                - Cyclic prefix length
%     NumTones                - Number of active tones
%     NumSubchannels          - Number of 20 MHz subchannel
%     ActiveFrequencyIndices  - Indices of active subcarriers relative to
%                               DC (within -NFFT/2 to NFFT/2-1)
%     ActiveFFTIndices        - Indices of active subcarriers within the
%                               FFT (within 1 to NFFT)
%     NominalActiveFFTIndices - Indices of active subcarriers within the
%                               nominal FFT (within 1 to NFFT/OSF)
%     DataIndices             - Indices of data carrying subcarrier within
%                               active subcarriers (within the range 1 to
%                               NumTones)
%     PilotIndices            - Indices of pilot carrying subcarrier within
%                               active subcarriers (within the range 1 to
%                               NumTones)
%
%   FIELDNAME is the field to demodulate and must be 'L-LTF', 'L-SIG',
%   'VHT-SIG-A', 'HT-SIG', 'VHT-SIG-B', 'VHT-LTF', 'HT-LTF', 'VHT-Data',
%   'HT-Data', or 'NonHT-Data'.
%
%   CHANBW must be 'CBW5', 'CBW10', 'CBW20', 'CBW40', 'CBW80', 'CBW160', or
%   'CBW320'.
%
%   INFO = vhtOFDMInfo(...,GI) returns OFDM info for the VHT-Data or
%   HT-Data fields.
%
%   GI the guard interval and must be 'Short' or 'Long'. The default is
%   'Long'.
%
%   INFO = vhtOFDMInfo(...,OSF) returns OFDM info for the oversampling
%   factor OSF.
%
%   OSF must be >=1 and the product of OSF and nominal cyclic prefix length
%   must be integer-valued. The default is 1.
%
%   See also wlanVHTOFDMInfo, wlanHTOFDMInfo, wlanNonHTOFDMInfo.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

% Optional OSF and guard interval
    if nargin>2
        if isnumeric(varargin{1})
            osf = varargin{1};
            if nargin>3
                guardInterval = varargin{2};
            else
                guardInterval = 'Long';
            end
        else
            guardInterval = varargin{1};
            if nargin>3
                osf = varargin{2};
            else
                osf = 1;
            end
        end
    else
        osf = 1;
        guardInterval = 'Long';
    end

    [fftLength,numSubchannels] = wlan.internal.cbw2nfft(chanBW);

    switch fieldname
      case {'VHT-Data','HT-Data'}
        switch guardInterval
          case 'Long'
            cpLength = 16*numSubchannels;
          otherwise % 'Short'
            cpLength = 8*numSubchannels;
        end
        [freqInd,pilotIdx] = wlan.internal.vhtToneIndices(numSubchannels);
      case {'VHT-SIG-B','VHT-LTF','HT-LTF'}
        [freqInd,pilotIdx] = wlan.internal.vhtToneIndices(numSubchannels);
        cpLength = 16*numSubchannels;
      case {'VHT-SIG-A','L-SIG','HT-SIG','NonHT-Data'}
        [freqInd,pilotIdx] = wlan.internal.nonHTToneIndices(numSubchannels);
        cpLength = 16*numSubchannels;
      otherwise % 'L-LTF'
        [freqInd,pilotIdx] = wlan.internal.nonHTToneIndices(numSubchannels);
        cpLength = [32*numSubchannels 0];
    end

    % Get the indices of data and pilots within active subcarriers
    numST = numel(freqInd);
    idx = ismember(freqInd,pilotIdx);
    seq = (1:numST)';
    pilotIndices = seq(idx);
    dataIndices = seq(~idx);

    % Form structure
    info = struct;
    info.FFTLength = fftLength*osf;
    info.SampleRate = 20e6*numSubchannels*osf;
    info.CPLength = cpLength*osf;
    info.NumSubchannels = numSubchannels;
    info.NumTones = numST;
    info.ActiveFrequencyIndices = freqInd;
    info.ActiveFFTIndices = freqInd+fftLength*osf/2+1;
    info.NominalActiveFFTIndices = freqInd+fftLength/2+1;
    info.DataIndices = dataIndices;
    info.PilotIndices = pilotIndices;

    wlan.internal.validateOFDMOSF(osf,fftLength,cpLength);

end
