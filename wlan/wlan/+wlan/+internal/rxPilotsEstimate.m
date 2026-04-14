function estRxPilots = rxPilotsEstimate(chanEstPilots,refPilots)
%rxPilotsEstimate Estimate received pilots
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   ESTRXPILOTS = rxPilotsEstimate(CHANESTPILOTS,REFPILOTS) returns a
%   complex Nsp-by-Nsym-by-Nr array containing the estimated received
%   pilots given reference pilots and channel estimates. Nsp is the number
%   of pilot subcarriers, Nsym is the number of OFDM symbols, and Nr is the
%   number of receive antennas.
%
%   CHANESTPILOTS is a complex Nsp-by-Nsts-by-Nr array containing the
%   channel gains at pilot subcarriers. Nsts is the number of space-time
%   streams.
%
%   REFPILOTS is a complex Nsp-by-Nsym-by-Nsts array containing the
%   reference pilot values.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

Nsts = size(chanEstPilots,2);

% Calculate an estimate of the received pilots using the channel estimate
chanEstPilotsR = permute(chanEstPilots,[1 4 2 3]);
% Extract Nsts stream from refPilots if the number of STS is not matching with that in channel estimates
refPilotsR = refPilots(:,:,1:Nsts);

% Sum over space-time streams and remove that dimension by permuting
estRxPilots = permute(sum(chanEstPilotsR.*refPilotsR,3),[1 2 4 3]);
end

