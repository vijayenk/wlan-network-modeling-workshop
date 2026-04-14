function [pilotChanEst,pilotRef,info,isPilotActive] = extractUsedPilots(pilotChanEst,pilotRef,info)
%EXTRACTUSEDPILOT extract the used pilot subcarriers
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PILOTCHANEST,PILOTREF,INFO,ISPILOTACTIVE] =
%   extractUsedPilots(PILOTCHANEST,PILOTREF,INFO) remove the NaNs within
%   the pilot channel estimate and returns the ofdmInfo, pilot channel
%   estimate and reference pilot of used pilot subcarriers.
%
%   INFO is a structure containing the field:
%     PilotIndices           - Indices of pilots within the active
%                              subcarriers in the range [1, NumTones]
%
%   PILOTCHANEST is an Nsp-by-Nsym-by-Nr array characterizing the estimated
%   channel for pilot subcarrier locations for each symbol. Nsp is the
%   number of pilot subcarriers, Nsym is the number of OFDM symbols, and Nr
%   is the number of receive antennas.
%
%   PILOTREF is an Nsp-by-Nsym-by-Nsts array characterizing the reference
%   pilots, where Nsts is the number of space time streams.
%
%   ISPILOTACTIVE is an Nsp-by-1 logical vector indicating if the
%   corresponding subcarrier is active or not.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

% NaNs may be generated for the 1xHELTF as some pilot subcarriers do
% not exist in the HE-LTF - Section 27.3.2.4, IEEE 802.11ax-2021
isPilotActive = ~any(isnan(pilotChanEst),[2 3]); % Logic flag of Nsp-by-1
info.PilotIndices = info.PilotIndices(isPilotActive);
pilotChanEst = pilotChanEst(isPilotActive,:,:);
pilotRef = pilotRef(isPilotActive,:,:);
end