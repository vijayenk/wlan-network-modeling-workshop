function [rot,punctureMask] = hePreHECarrierRotations(cfg)
%hePreHECarrierRotations Preamble field subcarrier rotations
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   ROT = hePreHECarrierRotations(CFG) returns a column array containing
%   the per-subcarrier gamma rotation. If a subcarrier is within a 20 MHz
%   subchannel which is to be punctured, the returned rotation is 0.
%
%   [ROT,PUCTUREMASK] = hePreHECarrierRotations(CFG) additionally returns
%   a logical column vector indicating if a 20 MHz subchannel is punctured
%   (true) or not (false).
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,  
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, <a href="matlab:help('wlanVHTConfig')">wlanVHTConfig</a>, <a href="matlab:help('wlanHTConfig')">wlanHTConfig</a>, or <a href="matlab:help('wlanNonHTConfig')">wlanNonHTConfig</a>.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

if isa(cfg,'wlanNonHTConfig') && strcmp(cfg.ChannelBandwidth,'CBW320') % NonHT Duplicate mode for 320 MHz
    % User-defined phase rotation as defined in Equation 36-13 and Equation 36-14 of IEEE P802.11be/D5.0
    carrierRotations = reshape(repmat(cfg.PhaseRotation,64,1),[],1);
    numSubchannels = 16;
else
    [carrierRotations,numSubchannels] = wlan.internal.vhtCarrierRotations(cfg.ChannelBandwidth);
end
Nfft = 64*numSubchannels;

% Handle punctured subchannels
punctureMask = wlan.internal.subchannelPuncturingPattern(cfg);
if any(punctureMask)
    % Null out punctured 20 MHz segments
    carrierRotations20 = reshape(carrierRotations, Nfft/numSubchannels, numSubchannels);
    carrierRotations20(:,punctureMask) = zeros(Nfft/numSubchannels, sum(punctureMask));
    rot = carrierRotations20(:);
else
    rot = carrierRotations; % No puncturing
end

end