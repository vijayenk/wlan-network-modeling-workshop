classdef PostFECPaddingSource < uint8
%PostFECPaddingSource Enumeration for PostFECPaddingSource types
%
%   Use the PostFECPaddingSource enumeration to set the
%   PostFECPaddingSource property of a <a href="matlab:help('wlanEHTUser')">wlanEHTUser</a> object used within
%   a <a href="matlab:help('wlanEHTMUConfig')">wlanEHTMUConfig</a> object.
%
%   PostFECPaddingSource enumeration:
%
%   mt19937arwithseed - Use mt19937ar random number generator with seed to
%                       generate normally distributed random bits.
%   globalstream      - Use current global random number stream to generate
%                       normally distributed random bits.
%   userdefined       - Use bits specified in PostFECPaddingBits property
%                       of <a href="matlab:help('wlanEHTUser')">wlanEHTUser</a> object
%
%   % Example:
%   %  Create an MU-MIMO object for a 20 MHz channel bandwidth and use the
%   %  bits specified in the PostFECPaddingBits property.
%
%   cfgEHT = wlanEHTMUConfig('CBW20');
%   cfgEHT.User{1}.PostFECPaddingSource = wlan.type.PostFECPaddingSource.userdefined;
%   cfgEHT.User{1}.PostFECPaddingBits = [1; 0; 0; 1];
%   disp(cfgEHT.User{1})
%
%   See also wlan.type.SpatialMapping, wlan.type.ChannelCoding

%   Copyright 2022 The MathWorks, Inc.

%#codegen

enumeration
    mt19937arwithseed (0)
    globalstream (1)
    userdefined (2)
end

end