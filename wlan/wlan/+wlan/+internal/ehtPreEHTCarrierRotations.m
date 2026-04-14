function [rot,punctureMask] = ehtPreEHTCarrierRotations(cfg)
%ehtPreHECarrierRotations Preamble field subcarrier rotations
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   ROT = ehtPreHECarrierRotations(CFG) returns a column array containing
%   the per-subcarrier gamma rotation. If a subcarrier is within a 20 MHz
%   subchannel which is to be punctured, the returned rotation is 0.
%
%   [ROT,PUNCTUREMASK] = ehtPreHECarrierRotations(CFG) additionally returns
%   a logical column vector indicating if a 20 MHz subchannel is punctured
%   (true) or not (false).
%
%   CFGEHT is the format configuration object of type <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> or
%   <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a> 

%   Copyright 2022 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
if cbw==320
    % User-defined phase rotation as defined in Equation 36-13 and Equation 36-14 of IEEE P802.11be/D1.5
    carrierRotations = reshape(repmat(cfg.PreEHTPhaseRotation,64,1),[],1);
    numSubchannels = 16;
else
    [carrierRotations,numSubchannels] = wlan.internal.vhtCarrierRotations(cfg.ChannelBandwidth);
end
Nfft = 64*numSubchannels;

% Handle punctured subchannels
punctureMask = wlan.internal.subchannelPuncturingPattern(cfg);

if any(punctureMask)
    % Null out punctured 20 MHz segments
    carrierRotations20 = reshape(carrierRotations,Nfft/numSubchannels,numSubchannels);
    numPunctureMask = sum(punctureMask,2); % For codegen
    carrierRotations20(:,punctureMask) = zeros(Nfft/numSubchannels,numPunctureMask(1));
    rot = carrierRotations20(:);
else
    rot = carrierRotations; % No puncturing
end

end