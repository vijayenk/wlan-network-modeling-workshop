function [ae,varargout] = amplitudeErrorEstimate(rxPilots,varargin)
%amplitudeErrorEstimate amplitude error estimate
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   AE = amplitudeErrorEstimate(RXPILOTS,ESTRXPILOTS) returns the average
%   amplitude error with respective to the estimated RX pilots per OFDM
%   symbol and receive antenna, AE. AE is sized 1-by-Nsym-by-Nr, where Nsym
%   is the number of OFDM symbols and Nr is the number of receive antennas.
%
%   ESTRXPILOTS is a complex Nsp-by-Nsym-by-Nr array containing the
%   estimated received pilots given reference pilots and channel estimates.
%   Nsp is the number of pilot subcarriers.
%
%   AE = amplitudeErrorEstimate(RXPILOTS,CHANESTPILOTS,REFPILOTS) returns
%   the average amplitude error with respective to the estimated RX pilots
%   per OFDM symbol and receive antenna, AE.
%
%   RXPILOTS is a complex Nsp-by-Nsym-by-Nr array containing the received
%   OFDM symbols at pilot subcarriers. Nsp is the number of pilot
%   subcarriers.
%
%   CHANESTPILOTS is a complex Nsp-by-Nsts-by-Nr array containing the
%   channel gains at pilot subcarriers. Nsts is the number of space-time
%   streams.
%
%   REFPILOTS is a complex Nsp-by-Nsym-by-Nsts array containing the
%   reference pilot values.
%
%   [AE,ESTRXPILOTS] = amplitudeErrorEstimate(...) additionally returns
%   a complex Nsp-by-Nsym-by-Nr containing the estimated received pilots
%   given reference pilots and channel estimates.

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen

narginchk(2,3)

if nargin == 2 % amplitudeErrorEstimate(rxPilots,estRxPilots)
    estRxPilots = varargin{1};
else % amplitudeErrorEstimate(rxPilots,chanEstPilots,refPilots)
    chanEstPilots = varargin{1};
    refPilots = varargin{2};
    estRxPilots = wlan.internal.rxPilotsEstimate(chanEstPilots,refPilots);
    varargout{1} = estRxPilots;
end

% Estimate the pilot amplitude error
ampPilotError = abs(rxPilots)./abs(estRxPilots);

% Average over all subcarriers to estimate the amplitude error
ae = mean(ampPilotError);

end

