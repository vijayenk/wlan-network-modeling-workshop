function [info,fftLength,cpLength] = heOFDMInfo(fieldname,chanBW,guardInterval,ruSize,ruindex,osf,flagFeedbackNDP,ruToneSetIndex)
%heOFDMInfo OFDM information for HE
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [INFO,FFTLENGTH,CPLENGTH] =
%   heOFDMInfo(FIELDNAME,CBW,GUARDINTERVAL,RUSIZE,RUINDEX,OSF,...
%   FLAGFEEDBACKNDP,RUTONESETINDEX) returns a structure containing OFDM
%   information for the specified field and channel bandwidth, as well as
%   the FFT length and CP length.
%
%   See also wlanHEOFDMInfo.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

arguments
    fieldname
    chanBW
    guardInterval = 3.2
    ruSize = 242
    ruindex = 1
    osf = 1
    flagFeedbackNDP = false
    ruToneSetIndex = 1 % For FeedbackNDP
end

cbw = wlan.internal.cbwStr2Num(chanBW);
numSubchannels = cbw/20;

switch fieldname
    case {'HE-Data','HE-LTF'}
        if flagFeedbackNDP
            if strcmp(fieldname,'HE-Data')
                coder.internal.error('wlan:wlanHEOFDMInfo:InvalidFieldName');
            end
            numSubcarrierIndices = 12; % 6 active + 6 complementary tone sets
            activeFreqInd = zeros(numSubcarrierIndices,1); % Store active and complementary tone sets
            for feedBackStatus=1:2
                activeFreqInd(feedBackStatus:2:end) = wlan.internal.heTBNDPSubcarrierIndices(cbw,ruToneSetIndex,feedBackStatus==1);
            end
            dataIndices = (1:numSubcarrierIndices)';
            pilotIndices = zeros(0,1);
        else
            [occInd,activeFreqInd] = wlan.internal.heOccupiedSubcarrierIndices(cbw,ruSize,ruindex);
            dataIndices = occInd.Data;
            pilotIndices = occInd.Pilot;
        end
        fftLength = 256*numSubchannels;
        cpLength = wlan.internal.ehtCPLength(numSubchannels,guardInterval);
    case {'HE-SIG-B','HE-SIG-A','RL-SIG','L-SIG'}
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