function npp = heNominalPacketPadding(cfg)
%heNominalPacketPadding Nominal Packet Padding for packet extension field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   NPP = heNominalPacketPadding(CFG) returns the Nominal Packet Padding
%   per user, based on the packet format.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHESUConfig')">wlanHESUConfig</a>,
%   <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>, <a href="matlab:help('wlanHETBConfig')">wlanHETBConfig</a>, or <a href="matlab:help('wlanEHTTBConfig')">wlanEHTTBConfig</a>.

%   Copyright 2019-2025 The MathWorks, Inc.

%#codegen

if isa(cfg,'wlanHESUConfig') || strcmp(packetFormat(cfg),'HE-SU') % Also for HEz
    npp = cfg.NominalPacketPadding;
elseif isa(cfg,'wlanHETBConfig') || isa(cfg,'wlanEHTTBConfig') || strcmp(cfg.packetFormat,'UHR-TB')
    npp = 0; % For HE TB and EHT TB
else % HE/EHT/UHR MU
    numUsers = numel(cfg.User);
    npp = coder.nullcopy(zeros(numUsers,1));
    for userIdx=1:numUsers
        npp(userIdx) = cfg.User{userIdx}.NominalPacketPadding;
    end
end