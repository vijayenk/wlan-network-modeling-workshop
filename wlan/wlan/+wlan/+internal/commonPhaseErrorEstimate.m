function [cpe,estRxPilots] = commonPhaseErrorEstimate(rxPilots,varargin)
%commonPhaseErrorEstimate common phase error estimate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CPE = commonPhaseErrorEstimate(RXPILOTS,ESTRXPILOTS) returns the common
%   phase error per OFDM symbol, CPE. CPE is sized 1-by-Nsym, where Nsym is
%   the number of OFDM symbols.
%
%   ESTRXPILOTS is a complex Nsp-by-Nsym-by-Nr array containing the
%   estimated received pilots given reference pilots and channel estimates.
%   Nsp is the number of pilot subcarriers and Nr is the number of receive
%   antennas.
%
%   CPE = commonPhaseErrorEstimate(RXPILOTS,CHANESTPILOTS,REFPILOTS)
%   returns the common phase error per OFDM symbol, CPE.
%
%   RXPILOTS is a complex Nsp-by-Nsym-by-Nr array containing the received
%   OFDM symbols at pilot subcarriers.
%
%   CHANESTPILOTS is a complex Nsp-by-Nsts-by-Nr array containing the
%   channel gains at pilot subcarriers. Nsts is the number of space-time
%   streams.
%
%   REFPILOTS is a complex Nsp-by-Nsym-by-Nsts array containing the
%   reference pilot values.
%
%   [CPE,ESTRXPILOTS] = commonPhaseErrorEstimate(...) additionally returns
%   a complex Nsp-by-Nsym-by-Nr containing the estimated received pilots
%   given reference pilots and channel estimates.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

narginchk(2,3)

if nargin == 2 % commonPhaseErrorEstimate(rxPilots,estRxPilots)
    estRxPilots = varargin{1};
else % commonPhaseErrorEstimate(rxPilots,chanEstPilots,refPilots)
    chanEstPilots = varargin{1};
    refPilots = varargin{2};
    estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilots,refPilots);
end

% Phase correction based on Allert val Zelst and Tim C. W. Schenk,
% Implementation of a MIMO OFDM-Based Wireless LAN System, IEEE
% Transactions on Signal Processing, Vol. 52, No. 2, February 2004. The
% result is averaged over the number of receive antennas (summed over the
% 3rd dimension).
cpe = angle(sum(sum(rxPilots.*conj(estRxPilots),1),3));
end