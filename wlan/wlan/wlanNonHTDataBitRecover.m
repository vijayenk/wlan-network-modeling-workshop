function [psdu, scramInit, serviceBits] = wlanNonHTDataBitRecover(sym, noiseVarEst, varargin)
%wlanNonHTDataBitRecover Recover data bits from non-HT Data field
%   PSDU = wlanNonHTDataBitRecover(RX,NOISEVAREST,CFG) recovers the data
%   bits given the equalized Data field from a non-HT transmission, the
%   noise variance estimate, and the non-HT configuration object.
%
%   PSDU is an int8 column vector of length 8*CFG.PSDULength containing the
%   recovered information bits.
%
%   RX contains the demodulated and equalized Data field OFDM symbols,
%   specified as a 48-by-Nsym complex-valued matrix, where 48 is the number
%   of data subcarriers in the Data field and Nsym is the number of OFDM
%   symbols.
%
%   NOISEVAREST is the noise variance estimate, specified as a nonnegative
%   scalar.
%
%   CFG is the format configuration object of type wlanNonHTConfig which
%   specifies the parameters for the non-HT format. Only OFDM modulation
%   type is supported.
%
%   DATABITS = wlanNonHTDataBitRecover(...,CSI,CFG) uses the channel state
%   information to enhance the demapping of OFDM subcarriers. CSI is a
%   48-by-1 column vector of real values.
%
%   [...,SCRAMINIT] = wlanNonHTDataBitRecover(...) additionally returns the
%   recovered initial scrambler state as an int8 scalar. The function maps
%   the initial state bits X1 to X7 as specified in IEEE Std 802.11-2016,
%   Section 17.3.5.5 to SCRAMINIT, treating the leftmost bit as most
%   significant.
%
%   [...,SERVICEBITS] = wlanNonHTDataBitRecover(...) additionally returns
%   the binary SERVICE field bits as a 16-by-1 column vector. The bit 8 of
%   the SERVICE field bit indicates a 320 MHz transmission.
%
%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

narginchk(3,4);

[nsd,nsym,nss] = size(sym);
validateattributes(sym, {'single','double'}, {'finite','2d','nrows',48}, mfilename, 'SYM');

if isa(varargin{1},'wlanNonHTConfig')
    % wlanNonHTDataBitRecover(RX,NOISEVAREST,CFG)
    % If no CSI input is present then assume 1 for processing
    csi = ones(nsd,nss);
    cfg = varargin{1};
elseif nargin>3 && isa(varargin{2}, 'wlanNonHTConfig')
    % wlanNonHTDataBitRecover(RX,NOISEVAREST,CSI,CFG)
    csi = varargin{1};
    cfg = varargin{2};
    validateattributes(csi, {'single','double'}, {'real','finite','size',[48,1]}, mfilename, 'CSI');
else
    coder.internal.error('wlan:wlanNonHTDataBitRecover:InvalidSyntax');
end

% Non-HT configuration input self-validation
validateattributes(cfg, {'wlanNonHTConfig'}, {'scalar'}, mfilename, 'format configuration object');
% Only applicable for OFDM and DUP-OFDM modulations
coder.internal.errorIf(~strcmp(cfg.Modulation, 'OFDM'), 'wlan:shared:InvalidModulation');
s = validateConfig(cfg);
coder.internal.errorIf(nsym<s.NumDataSymbols, 'wlan:shared:IncorrectNumOFDMSym', s.NumDataSymbols, nsym);

% Validate noiseVarEst
validateattributes(noiseVarEst, {'single','double'}, {'real','scalar','nonnegative','finite'}, mfilename, 'noiseVarEst');

mcsTable = wlan.internal.getRateTable(cfg);

% Constellation demapping
qamDemodOut = wlanConstellationDemap(sym, noiseVarEst, mcsTable.NBPSCS);

% Apply bit-wise CSI and concatenate OFDM symbols in the first dimension
qamDemodOut = reshape(qamDemodOut, mcsTable.NBPSCS, [], nsym) .* ...
                reshape(csi, 1, []); % [Nbpscs Nsd Nsym]
qamDemodOut = reshape(qamDemodOut, [], 1);

% Deinterleave
deintlvrOut = wlanBCCDeinterleave(qamDemodOut, 'Non-HT', mcsTable.NCBPS);

% Channel decoding
decBits = wlanBCCDecode(deintlvrOut, mcsTable.Rate);

% Derive initial state of the scrambler
scramSeqInit = decBits(1:7);
scramInitBits = wlan.internal.scramblerInitialState(scramSeqInit);

% Remove pad and tail bits, and descramble
if all(scramInitBits==0)
    % Scrambler initialization invalid (0), therefore do not descramble
    descramDataOut = decBits(1:(16+8*cfg.PSDULength));
else
    descramDataOut = wlanScramble(decBits(1:(16+8*cfg.PSDULength)), scramInitBits);
end

% Remove the 16 service bits
psdu = descramDataOut(17:end);

% Convert scrambler initialization bits to number
scramInit = bit2int(scramInitBits,length(scramInitBits));

% SERVICE field bits
serviceBits = descramDataOut(1:16);
end
