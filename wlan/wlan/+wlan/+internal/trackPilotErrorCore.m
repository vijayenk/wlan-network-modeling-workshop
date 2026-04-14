function [y,cpe,ae] = trackPilotErrorCore(x,chanEstPilots,refPilots,ofdmInfo,recParams)
%trackPilotErrorCore Pilot error tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,CPE,AE] =
%   trackPilotErrorCore(X,CHANESTPILOTS,REFPILOTS,OFDMINFO,RECPARAMS)
%   returns pilot-error-tracked OFDM symbols Y. CPE is common phase error
%   per OFDM symbol averaged over all receive antennas. AE is the amplitude
%   error per OFDM symbol and receive antenna.
%
%   Y is a complex Nst-by-Nsym-by-Nr array containing the pilot-tracked
%   OFDM symbols. Nst is the number of occupied subcarriers, Nsym is the
%   number of symbols, and Nr is the number of receive antennas.
%
%   CPE is a real Nsym-by-1 vector containing the common phase error per
%   OFDM symbol averaged over receive antennas.
%
%   AE is a real Nsym-by-Nr array containing the average amplitude error
%   for all subcarriers, in dB, with respect to the estimated receiver
%   pilots per OFDM symbol for each receive antenna.
%
%   X is a complex Nst-by-Nsym-by-Nr array containing the received OFDM
%   symbols. Nst is the number of active subcarriers (data and pilots) for
%   the specified field.
%
%   CHANESTPILOTS is a complex Nsp-by-Nsts-by-Nr array containing the
%   channel estimates at pilot subcarriers. Nsp is the number of pilot
%   subcarriers, and Nsts is the number of space-time streams for the user
%   of interest.
%
%   REFPILOTS is a complex Nsp-by-Nsym-by-Nsts array containing the
%   reference pilot values.
%
%   OFDMINFO is a structure containing OFDM parameters.
%
%   RECPARAMS is a structure containing algorithmic controls.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

[~,Nsym,Nr] = size(x);
realx = real(x(1)); % CPE and AE must be real
cpeEstimate = zeros(Nsym,1,'like',realx);
aeEstimate = ones(1,Nsym,Nr,'like',realx);

estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilots,refPilots);

% Estimate CPE and AE
if recParams.CalculateCPE || recParams.TrackPhase
    cpeEstimate = wlan.internal.commonPhaseErrorEstimate(x(ofdmInfo.PilotIndices,:,:),estRxPilots);
end
if recParams.CalculateAE || recParams.TrackAmplitude
    aeEstimate = wlan.internal.amplitudeErrorEstimate(x(ofdmInfo.PilotIndices,:,:),estRxPilots);
    aeEstimate = max(aeEstimate,eps); % Set AE to the smallest double/single-precision number when AE is small
end

% Perform pilot tracking
y = x;
if recParams.TrackPhase
    y = wlan.internal.commonPhaseErrorCorrect(y,cpeEstimate);
end
if recParams.TrackAmplitude
    y = wlan.internal.amplitudeErrorCorrect(y,aeEstimate);
end

cpe = cpeEstimate.'; % Permute to Nsym-by-1
ae = permute(mag2db(aeEstimate),[2 3 1]); % Convert AE from magnitude to decibels and permute to Nsym-by-Nr

end