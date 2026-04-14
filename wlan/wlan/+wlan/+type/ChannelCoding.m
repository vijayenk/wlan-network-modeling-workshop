classdef ChannelCoding < uint8
%ChannelCoding Enumeration for ChannelCoding types
%
%   Use the ChannelCoding enumeration to set the ChannelCoding property of
%   a <a href="matlab:help('wlanEHTUser')">wlanEHTUser</a> object used within a <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> object.
%
%   ChannelCoding enumeration:
%
%   bcc  - Binary convolution coding
%   ldpc - Low-density-parity-check
%
%   % Example:
%   %  Create an MU-MIMO object for a 20 MHz channel bandwidth and set the
%   %  channel coding to BCC.
%
%   cfgEHT = wlanEHTMUConfig('CBW20');
%   cfgEHT.User{1}.ChannelCoding = wlan.type.ChannelCoding.bcc;
%   disp(cfgEHT.User{1})
%
%   See also wlan.type.SpatialMapping, wlan.type.PostFECPaddingSource

%   Copyright 2022 The MathWorks, Inc.

%#codegen

enumeration
    bcc (0)
    ldpc (1)
end

methods
    function e = wlan.type.RecoveredChannelCoding(e)
        % Conversion function to convert enums for RecoveredChannelCoding
        e = wlan.type.RecoveredChannelCoding(uint8(e));
    end
end

end