function varargout = mergeSubchannels(varargin)
%mergeSubchannels merge subchannels for equalization
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   DEMODSC = mergeSubchannels(DEMOD,NSC) returns the demodulated symbols
%   for a single subchannel in preparation for equalization. A subchannel
%   is typically 20 MHz within the entire channel bandwidth. The
%   demodulated symbols for multiple subchannels are permuted such that
%   subchannels become additional receive antennas to simplify combining
%   during equalization.
%
%   DEMODSC is a Nsd/Nsc-by-Nsym-by-Nsc*Nr matrix containing the
%   demodulated symbols for a single subchannel. Nsd is the number of
%   subcarriers in the input demodulated data for the entire channel
%   bandwidth. Nsym is the number of OFDM symbols. Nsc is the number of
%   subchannels (e.g. 20 MHz) within the entire channel bandwidth (e.g. 160
%   MHz). Nr is the number of receive antennas.
%
%   DEMOD is a Nsd-by-Nsym-by-Nr matrix containing demodulated symbols for
%   the entire channel bandwidth.
%
%   [DEMODASC,DEMODBSC,...] = mergeSubchannels(DEMODA,DEMODB,...,NSC)
%   returns a single subchannel for any number of demodulated arrays passed
%   as arguments.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

narginchk(2,inf);
Nsc = varargin{end};
numCalc = nargin-1;
out = cell(1,numCalc);

for i = 1:numCalc
  % Merge Nsc symbols together for the
  % repeated subcarriers
  demod = varargin{i};
  [Nsd,Nsym,Nr] = size(demod); % [Num subcarriers, Num symbols, Nu. receive antennas]
  Nsdpsc = Nsd/Nsc; % Number of subcarriers per subchannel (e.g. 20 MHz)
  demodSC = reshape(permute(reshape(demod,Nsdpsc,Nsc,Nsym,Nr),[1 3 4 2]),Nsdpsc,Nsym,Nsc*Nr);
  out{i} = demodSC;
end

varargout = out;
end