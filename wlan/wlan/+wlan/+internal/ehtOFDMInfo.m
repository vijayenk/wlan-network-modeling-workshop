function [info,fftLength,cpLength] = ehtOFDMInfo(fieldname,chanBW,guardInterval,ruSize,ruindex,osf)
%ehtOFDMInfo OFDM information for EHT
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [INFO,FFTLENGTH,CPLENGTH] =
%   ehtOFDMInfo(FIELDNAME,CBW,GUARDINTERVAL,RUSIZE,RUINDEX,OSF) returns a
%   structure containing OFDM information for the specified field and
%   channel bandwidth, as well as the FFT length and CP length.
%
%   See also wlanEHTOFDMInfo.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

arguments
    fieldname
    chanBW
    guardInterval = 3.2
    ruSize = 242
    ruindex = 1
    osf = 1
end

cbw = wlan.internal.cbwStr2Num(chanBW);
numSubchannels = cbw/20;

switch fieldname
    case {'EHT-Data','EHT-LTF'}
        [ruMappingInd,activeFreqInd] = wlan.internal.ehtOccupiedSubcarrierIndices(cbw,ruSize,ruindex);
        dataIndices = ruMappingInd.Data;
        pilotIndices = ruMappingInd.Pilot;
        fftLength = 256*numSubchannels;
        cpLength = wlan.internal.ehtCPLength(numSubchannels,guardInterval);
    case {'U-SIG','EHT-SIG','RL-SIG','L-SIG'}
        [activeFreqInd,activePilotIdx] = wlan.internal.preEHTToneIndices(numSubchannels);
        [dataIndices,pilotIndices] = wlan.internal.preEHTOccupiedIndices(activeFreqInd,activePilotIdx);
        fftLength = 64*numSubchannels;
        cpLength = 16*numSubchannels;
    otherwise % 'L-LTF'
        [activeFreqInd,activePilotIdx] = wlan.internal.nonHTToneIndices(numSubchannels);
        [dataIndices,pilotIndices] = wlan.internal.preEHTOccupiedIndices(activeFreqInd,activePilotIdx);
        fftLength = 64*numSubchannels;
        cpLength = [32*numSubchannels 0];
end

% Form structure
info = struct;
info.FFTLength = fftLength*osf;
info.SampleRate = 20e6*numSubchannels*osf;
info.CPLength = cpLength*osf;
info.NumSubchannels = numSubchannels;
info.NumTones = numel(activeFreqInd);
info.ActiveFrequencyIndices = activeFreqInd;
info.ActiveFFTIndices = activeFreqInd+fftLength*osf/2+1;
info.DataIndices = dataIndices;
info.PilotIndices = pilotIndices;
end