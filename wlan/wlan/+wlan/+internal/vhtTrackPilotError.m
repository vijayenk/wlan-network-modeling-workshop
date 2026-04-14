function [y,cpe,ae] = vhtTrackPilotError(x,chanEstPilots,chanBW,fieldName,recParams)
%vhtTrackPilotError VHT waveform pilot error tracking
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,CPE,AE] =
%   vhtTrackPilotError(X,CHANESTPILOTS,CHANBW,FIELDNAME,RECPARAMS) returns
%   VHT pilot-error-tracked OFDM symbols Y. CPE is common phase error per
%   OFDM symbol averaged over all receive antennas. AE is the amplitude
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
%   CHANBW is the channel bandwidth and must be 'CBW20', 'CBW40', 'CBW80', or
%   'CBW160'.
%
%   FIELDNAME imust be 'L-SIG', 'VHT-SIG-A', 'VHT-LTF', 'VHT-SIG-B', or 'VHT-Data'.
%
%   RECPARAMS is a structure containing algorithmic controls.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

% Get reference pilots
    numSTS = size(chanEstPilots,2);
    ofdmInfo = wlan.internal.vhtOFDMInfo(fieldName,chanBW);
    nsym = size(x,2);
    n = (0:nsym-1).';
    % While fields such as 'L-SIG' and 'VHT-SIG-B' generally have only 1
    % symbol, we generate reference pilots based on number of symbols in
    % input X rather than what is expected for a given field.
    switch fieldName
      case 'L-SIG' % IEEE Std 802.11-2020, Eqn 21-25
        z = 0; % No offset as first symbol with pilots
        refPilots = wlan.internal.nonHTPilots(nsym,z,chanBW);
      case 'VHT-SIG-A' % IEEE Std 802.11-2020, Eqn 21-28
        z = 1; % Offset by 1 to account for L-SIG pilot symbol
        refPilots = wlan.internal.nonHTPilots(nsym,z,chanBW);
      case 'VHT-LTF' % IEEE Std 802.11-2020, Eqn 21-41        
        % The first column of the P matrix is the same for any number of
        % STSs
        maxNSTS = 8;
        [seqVHTLTF,Pvhtltf] = wlan.internal.vhtltfSequence(chanBW,maxNSTS);
        refPilots = seqVHTLTF(ofdmInfo.ActiveFFTIndices(ofdmInfo.PilotIndices)).*Pvhtltf(1,1:nsym);
      case 'VHT-SIG-B' % IEEE Std 802.11-2020, Eqn 21-47
        z = 3; % Offset by 3 to allow for L-SIG and VHT-SIG-A pilot symbols
        refPilots = wlan.internal.vhtPilots(n,z,chanBW,numSTS); % Same pilots on all space-time streams so we do not care about the index
      otherwise % 'VHT-Data' % IEEE Std 802.11-2020, Eqn 21-95
        assert(strcmp(fieldName,'VHT-Data'));
        z = 4; % Offset by 4 to allow for L-SIG, VHT-SIG-A, VHT-SIG-B pilot symbols
        refPilots = wlan.internal.vhtPilots(n,z,chanBW,numSTS); % Same pilots on all space-time streams so we do not care about the index
    end

    % Track pilot error
    [y,cpe,ae] = wlan.internal.trackPilotErrorCore(x,chanEstPilots,refPilots,ofdmInfo,recParams);

end
