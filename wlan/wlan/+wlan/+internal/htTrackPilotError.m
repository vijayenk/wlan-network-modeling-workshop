function [y,cpe,ae] = htTrackPilotError(x,chanEstPilots,chanBW,fieldName,recParams)
%htTrackPilotError HT waveform pilot error tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,CPE,AE] = htTrackPilotError(X,CHANESTPILOTS,CHANBW,RECPARAMS)
%   returns HT pilot-error-tracked OFDM symbols Y. CPE is common phase
%   error per OFDM symbol averaged over all receive antennas. AE is the
%   amplitude error per OFDM symbol and receive antenna.
%
%   Y is a complex Nst-by-Nsym-by-Nr array containing the pilot-tracked
%   OFDM symbols. Nst is the number of occupied subcarriers, Nsym is the
%   number of symbols, and Nr is the number of receive antennas.
%
%   CPE is a real 1-by-Nsym vector containing the common phase error per
%   OFDM symbol averaged over receive antennas.
%
%   AE is a real 1-by-Nsym-by-Nr array containing the average amplitude
%   error for all subcarriers, in dB, with respect to the estimated
%   receiver pilots per OFDM symbol for each receive antenna.
%
%   X is a complex Nst-by-Nsym-by-Nr array containing the received OFDM
%   symbols. Nst is the number of active subcarriers (data and pilots) for
%   the specified field.
%
%   CHANESTPILOTS is a complex Nsp-by-Nsts-by-Nr array containing the
%   channel estimates at pilot subcarriers. Nsp is the number of pilot
%   subcarriers, and Nsts is the number of space-time streams.
%
%   CHANBW is the channel bandwidth and must be 'CBW20' or 'CBW40'.
%
%   FIELDNAME is a character vector or string scalar specifying the field
%   of interest. The allowed field names are 'HT-SIG' and 'HT-Data'.
%
%   RECPARAMS is a structure containing algorithmic controls.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

% Get reference pilots
switch fieldName
    case 'HT-SIG' % IEEE Std 802.11-2020 Eqn 19-16/17
        z = 1; % offset to allow for L-SIG pilot symbols
        refPilots = wlan.internal.nonHTPilots(2,z,chanBW);
    otherwise % 'HT-Data' % IEEE Std 802.11-2020 Eqn 19-58/59
        assert(strcmp(fieldName,'HT-Data'));
        z = 3; % offset to allow for L-SIG and HT-SIG pilot symbols
        numOFDMSym = size(x,2);
        numSTS = size(chanEstPilots,2);
        refPilots = wlan.internal.htPilots(numOFDMSym,z,chanBW,numSTS);
end

% Track pilot error
ofdmInfo = wlan.internal.vhtOFDMInfo(fieldName,chanBW);
[y,cpe,ae] = wlan.internal.trackPilotErrorCore(x,chanEstPilots,refPilots,ofdmInfo,recParams);

end