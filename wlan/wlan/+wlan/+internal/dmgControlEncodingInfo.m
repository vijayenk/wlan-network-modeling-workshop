function y = dmgControlEncodingInfo(cfgDMG) 
%dmgControlEncodingInfo generate LDPC encode and decode parameters.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgControlEncodingInfo(CFGDMG) return the LDPC encoding and
%   decoding parameters for Control PHY.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.
%
%  Reference: IEEE Std 802.11ad-2012, Section 21.4.3.3.3

%   Copyright 2016 The MathWorks, Inc.

%#codegen

% IEEE 802.11ad-2012 Section 21.4.3.3.3 Encoder
LCWD = 168;  % Maximum number of data bits in each LDPC codeword
LDPFCW = 88; % Number of header and data bits in first LDPC codeword
LFDCW = 6;   % Length of additional data in the header
Length = cfgDMG.PSDULength;
% Number of LDPC codewords
NCW = 1+ceil(((Length-6)*8)/LCWD);
% Number of header and data bits in the first LDPC codeword
LDPCW = ceil(((Length-6)*8)/(NCW-1));
% Number of bits in last codeword
LDPLCW = (Length-6)*8-(NCW-2)*LDPCW;

y = struct( ...
 'NCW',NCW, ...
 'LDPCW',LDPCW, ...
 'LDPLCW',LDPLCW, ...
 'LDPFCW',LDPFCW, ...
 'LFDCW',LFDCW);

end