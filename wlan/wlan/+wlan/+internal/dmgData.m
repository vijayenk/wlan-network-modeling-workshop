function y = dmgData(psdu,cfgDMG)
%dmgData DMG Data field processing of the PSDU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgData(PSDU,CFGDMG) generates the DMG format Data field
%   time-domain waveform for the input PLCP Service Data Unit (PSDU).
%
%   Y is the time-domain DMG Data field signal. It is a complex column
%   vector of length Ns, where Ns represents the number of time-domain
%   samples.
%
%   PSDU is the PHY service data unit input to the PHY. It is a double
%   or int8 typed column vector of length CFGDMG.PSDULength*8, with each
%   element representing a bit.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

if strcmp(phyType(cfgDMG),'Control')
    % Encode header and data together due to differential encoding
    headerBits = wlan.internal.dmgHeaderBits(cfgDMG);
    encHeaderBits = wlan.internal.dmgHeaderEncode(headerBits,psdu,cfgDMG);
    encDataBits = wlan.internal.dmgDataEncode(psdu,cfgDMG);
    
    % Modulate
    yT = wlan.internal.dmgDataModulate([encHeaderBits; encDataBits],cfgDMG);
    
    % Strip out the encoded data from differential modulation
    y = yT((8192+1):end);
else % SC/OFDM PHY
    % Encode data
    encodedBits = wlan.internal.dmgDataEncode(psdu,cfgDMG);
    
    % Modulate
    y = wlan.internal.dmgDataModulate(encodedBits,cfgDMG);
end

end
