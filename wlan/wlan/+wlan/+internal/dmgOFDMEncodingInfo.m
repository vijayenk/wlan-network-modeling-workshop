function Y = dmgOFDMEncodingInfo(cfgDMG) 
%dmgOFDMEncodingInfo generate LDPC encode and decode parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgOFDMEncodingInfo(CFGDMG) return the LDPC encoding and decoding
%   parameters for OFDM PHY.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   Reference: IEEE Std 802.11ad-2012, Section 21.5.3.2.3

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

mcsTable = wlan.internal.getRateTable(cfgDMG);

% IEEE 802.11ad-2012 Section 21.5.3.2.3.3
LCW = 672; % LDPC codeword length
Length = cfgDMG.PSDULength;
% Calculate number of LDPC codewords
NCW = ceil((Length*8)/(LCW*mcsTable.Rate));
% Calculate number of OFDM symbols
NSYM = ceil((NCW*LCW)/mcsTable.NCBPS);
aBRPminOFDMblocks = 20; % Table 21-31
if wlan.internal.isBRPPacket(cfgDMG) && NSYM<aBRPminOFDMblocks
 NSYM = aBRPminOFDMblocks;
end
% Calculate number of pad bits required
NPAD = mcsTable.Rate*NSYM*mcsTable.NCBPS-Length*8;
% Recalculate number of LDPC codewords given NSYM
NCW = NSYM*mcsTable.NCBPS/LCW;
Y = struct('NCW',NCW,'NSYM',NSYM,'NPAD',NPAD,'LCW',LCW);

end