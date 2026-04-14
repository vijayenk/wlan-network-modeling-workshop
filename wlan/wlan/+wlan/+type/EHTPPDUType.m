classdef EHTPPDUType< uint8
%EHTPPDUType Enumeration for EHT PPDU type
%
%   The EHTPPDUType enumeration sets the PPDUType property of a <a
%   href="matlab:help('wlanEHTRecoveryConfig')">wlanEHTRecoveryConfig</a>
%   object
%
%   EHTPPDUType enumeration:
%
%   su        - EHT SU transmission
%   ndp       - EHT Sounding NDP
%   dl_ofdma  - DL OFDMA (including non-MU-MIMO and MU-MIMO) transmission
%   dl_mumimo - DL MU-MIMO transmission
%   unknown   - Unknown or undefined transmission
%
%   % Example:
%   %  Indicate a DL MU-MIMO object for a 320 MHz channel bandwidth
%
%   cfg = wlanEHTRecoveryConfig;
%   cfg.ChannelBandwidth = 'CBW320';
%   cfg.CompressionMode = 2;
%   cfg.EHTSIGMCS = 0;
%   cfg.NumEHTSIGSymbolsSignaled = 1
%
%   See also wlan.type.RecoveredChannelCoding, wlan.type.ChannelCoding

%   Copyright 2023 The MathWorks, Inc.

%#codegen

enumeration
    su (0)
    ndp (1)
    dl_ofdma (2)
    dl_mumimo (3)
    unknown (4)
end

end