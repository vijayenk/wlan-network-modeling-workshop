function y = dmgHeaderEncode(headerBits,varargin)
%dmgHeaderEncode Encode header bits for Control, Single Carrier and OFDM PHY
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgHeaderEncode(HEADERBITS,CFGDMG) generates the DMG LDPC header
%   encoded bits for Single Carrier and OFDM PHYs.
%
%   Y = dmgHeaderEncode(...,PSDU,CFGDMG) generates DMG LDPC header encoded
%   bits for Control PHY. PSDU is the PLCP service data unit input to the
%   PHY. It is a double or int8 typed column vector of length
%   cfgDMG.PSDULength*8. The PSDU is the required input for DMG Control
%   PHY.
%
%   Y is the encoded header bits. It is of size N-by-1 of type uint8, where
%   N is the number of LDPC encoded header bits in the header field of
%   Control, Single Carrier and OFDM PHY.
%
%   CFGDMG is the format configuration object of type <a href="matlab:help('wlanDMGConfig')">wlanDMGConfig</a> which
%   specifies the parameters for the DMG format.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

narginchk(2,3); % Expect at least 2 inputs; headerBits, cfgDMG and optionally psdu

if isa(varargin{1},'wlanDMGConfig')
    cfgDMG = varargin{1};
    coder.internal.errorIf(strcmp(phyType(cfgDMG),'Control'),'wlan:dmgHeader:NoPSDUControl');
else
    narginchk(3,3);
    psdu = varargin{1};
    cfgDMG = varargin{2};
end

% If PSDU is empty then do not attempt to encode it; return empty
if isempty(headerBits)
    y = zeros(0,1,'int8');
    return;
end

LCW = 672; % Codeword length
scramInit = wlan.internal.dmgScramblerInitializationBits(cfgDMG);

switch phyType(cfgDMG)
    case 'Control'
        % Scramble header and data field: IEEE 802.11ad-2012, Section 21.4.3.2.3
        scramBits = [headerBits(1:5); wlanScramble([headerBits(6:end); psdu],scramInit)];

        % LDPC Encoding of header bits
        parms = wlan.internal.dmgControlEncodingInfo(cfgDMG);
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*LCW; 
        blkFirstCW = [scramBits(1:parms.LDPFCW); zeros(LCWD-parms.LDPFCW,1)];
        parityBits = wlan.internal.ldpcEncodeCore(blkFirstCW,rate);
        y = [scramBits(1:parms.LDPFCW); parityBits];

    case 'SC' 
        % Scramble header field: IEEE Std 802.11ad-2012, Section 21.6.3.1.4  
        scramBits = [headerBits(1:7); wlanScramble(headerBits(8:end),scramInit)];
        rate = 3/4; % Header is always encoded with rate 3/4
        LCWD = rate*LCW;
        blkCW = [scramBits; zeros(LCWD-size(scramBits,1),1)];
        parityBits = wlan.internal.ldpcEncodeCore(blkCW,rate);
        c1 = [scramBits; parityBits(1:160)];
        c2 = [scramBits; parityBits(1:152); parityBits(161:end)];
        % Scramble (XOR) c2
        y = [c1; wlanScramble(c2,ones(7,1))];
       
    otherwise % OFDM
        % Scramble header field: IEEE Std 802.11ad-2012, Section 21.5.3.1.4  
        scramBits = [headerBits(1:7); wlanScramble(headerBits(8:end),scramInit)];
        rate = 3/4;      % Header is always encoded with rate 3/4
        LCWD = rate*LCW; % Block length of LDPC data
        blkCW = [scramBits; zeros(LCWD-length(scramBits),1)]; % Pad with zeros
        parityBits = wlan.internal.ldpcEncodeCore(blkCW,rate);
        c1 = [scramBits; parityBits(9:end)];
        c2 = [scramBits; parityBits(1:84); parityBits(93:end)];
        c3 = [scramBits; parityBits(1:160)];
        % Scramble(XOR) c2 and c3
        y = [c1; wlanScramble([c2; c3],ones(7,1))];
        
end

