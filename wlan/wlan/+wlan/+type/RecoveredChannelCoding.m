classdef RecoveredChannelCoding < uint8
%RecoveredChannelCoding Enumeration for recovered ChannelCoding types
%
%   Use the RecoveredChannelCoding enumeration to set the ChannelCoding property of <a href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a> object.
%
%   RecoveredChannelCoding enumeration:
%
%   bcc     - Binary convolution coding
%   ldpc    - Low-density-parity-check
%   unknown - Indicates an unknown or undefined channel coding
%
%   % Example:
%   %  Create an EHT recovery object for a 20 MHz channel bandwidth and set
%   %  the channel coding to BCC.
%
%   cfgRec = wlanEHTRecoveryConfig('ChannelBandwidth','CBW20');
%   cfgRec.ChannelCoding = wlan.type.RecoveredChannelCoding.bcc;
%   disp(cfgRec)
%
%   See also wlan.type.ChannelCoding

%   Copyright 2023 The MathWorks, Inc.

%#codegen

enumeration
    bcc (0)
    ldpc (1)
    unknown (2)
end

methods
    function e = wlan.type.ChannelCoding(e)
        % Conversion function to convert enums for ChannelCoding
        e = wlan.type.ChannelCoding(uint8(e));
    end
end

end