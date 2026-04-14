function Y = dmgSCEncodingInfo(cfgDMG) 
%dmgSCEncodingInfo generate LDPC encode and decode parameters.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgSCEncodingInfo(CFGDMG) return the LDPC encoding and decoding
%   parameters for Single Carrier PHY.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%   Reference: IEEE Std 802.11ad-2012, Section 21.6.3.2.3
%              IEEE Std 802.11-2016, Section 20.6.3.2.3

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

mcsTable = wlan.internal.getRateTable(cfgDMG);

if isequal(mcsTable.Rate,7/8)
	% IEEE Std 802.11-2016, Section 20.6.3.2.3
    LCW = 624; % LDPC codeword length for extend MCS
else
    LCW = 672; % LDPC codeword length
end

% IEEE 802.11ad-2012 Section 21.6.3.2.3.3 LDPC Encoding Process
Length = cfgDMG.PSDULength;
% Calculate number of LDPC codewords
NCW = ceil((Length*8)/((LCW/mcsTable.Repetition)*mcsTable.Rate));
% Calculate number of OFDM symbols
if wlan.internal.isBRPPacket(cfgDMG) && NCW<mcsTable.NCWMIN
    NCW = mcsTable.NCWMIN; % Table 21-23
end
% Calculate number of pad bits required
NDATA_PAD = NCW*(LCW/mcsTable.Repetition)*mcsTable.Rate-Length*8;
% Number of coded bits per block
NCBPB = 448*mcsTable.NCBPS; % Table 21-20
% Calculate number of symbol blocks
NBLKS = ceil((NCW*LCW)/NCBPB);
% Calculate number of symbol block padding bits
NBLK_PAD = NBLKS*NCBPB-NCW*LCW;
Y = struct( ...
    'NCW',NCW, ...
    'NBLKS',NBLKS, ...
    'NDATA_PAD',NDATA_PAD, ...
    'NBLK_PAD',NBLK_PAD, ...
    'LCW',LCW);

end