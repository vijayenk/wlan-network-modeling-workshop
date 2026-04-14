function bandwidth = heSIGAChannelBWValue(cfg)
%heSIGAChannelBWValue Generate the channel bandwidth value for an HE-SIG-A
%field of an HE MU format as defined in IEEE Std 802.11ax-2021, Table 27-20
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   BANDWIDTH = heSIGAChannelBWValue(CFG) returns the channel bandwidth
%   value as an integer scalar for 80/160MHz channel bandwidth for an HE MU
%   packet as defined in IEEE Std 802.11ax-2021, Table 27-20.
%
%   CFG is the format configuration object of type <a href="matlab:help('wlanHEMUConfig')">wlanHEMUConfig</a>.

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

cbw = wlan.internal.cbwStr2Num(cfg.ChannelBandwidth);
punctureMask = wlan.internal.subchannelPuncturingPattern(cfg);
primaryChIndex = cfg.PrimarySubchannel;
switch cbw
    case 20
        bandwidth = 0;
    case 40
        bandwidth = 1;
    case 80
        if ~any(punctureMask) % No puncturing
            bandwidth = 2;
        else
            if any(primaryChIndex==[1 2 3 4] & punctureMask([2 1 4 3]))
                bandwidth = 4;
            else
                bandwidth = 5;
            end
        end
    otherwise % 160MHz
        if ~any(punctureMask) % No puncturing
            bandwidth = 3;
        elseif any((primaryChIndex==[1 2 3 4 5 6 7 8] & punctureMask([2 1 4 3 6 5 8 7])))
            bandwidth = 6;
        else
            bandwidth = 7;
        end
end

end