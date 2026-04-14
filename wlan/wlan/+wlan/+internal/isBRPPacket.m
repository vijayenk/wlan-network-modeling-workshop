function flag = isBRPPacket(cfgDMG)
%isBRPPacket Determine if the packet is a BRP packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FLAG = isBRPPacket(CFGDMG) returns true if the configuration is for a
%   BRP packet.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen
flag = ~(cfgDMG.TrainingLength==0 || ...
    (any(strcmp(phyType(cfgDMG),{'SC','OFDM'})) && ...
    strcmp(cfgDMG.PacketType,'TRN-R') && cfgDMG.BeamTrackingRequest==true));

end