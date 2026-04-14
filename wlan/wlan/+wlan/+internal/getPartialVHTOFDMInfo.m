function info = getPartialVHTOFDMInfo(cbw,preVHT)
%getVHTDataIndices Returns a struct with basic OFDM info for VHT such as
% data indices, pilot indices, number of tones, and number of subchannels.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%

%   Copyright 2025 The MathWorks, Inc.

%#codegen

    [~,numSubchannels] = wlan.internal.cbw2nfft(cbw);

    % Get the frequency indices for data+pilots and pilots
    if preVHT
        % Covers fields VHT-SIG-A and prior
        [freqIdxs,pilotFreqIdxs] = wlan.internal.nonHTToneIndices(numSubchannels);
    else
        [freqIdxs,pilotFreqIdxs] = wlan.internal.vhtToneIndices(numSubchannels);
    end

    numTones = numel(freqIdxs);

    % Calculate the indicies for MATLAB indexing
    [dataIdxs,pilotIdxs] = wlan.internal.preEHTOccupiedIndices(freqIdxs, pilotFreqIdxs);

    info.NumSubchannels = numSubchannels;
    info.NumTones = numTones;
    info.DataIndices = dataIdxs;
    info.PilotIndices = pilotIdxs;
end
