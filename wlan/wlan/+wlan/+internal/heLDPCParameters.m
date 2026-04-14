function Y = heLDPCParameters(codingParams)
%heLDPCParameters LDPC encode and decode parameters.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases. 
%
%   Y = heLDPCParameters(CODINGPARAMS) returns a structure containing LDPC
%   parameters for coding and decoding.
%
%   See also ldpcEncode, ldpcCDecode.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

NSYMinit = codingParams.NSYMInit;
numDBPS = codingParams.NDBPS;
numCBPS = codingParams.NCBPS;
rate = codingParams.Rate;
mSTBC = codingParams.mSTBC;
aInitCommon = codingParams.PreFECPaddingFactorInit;
NCBPSSHORT = codingParams.NCBPSSHORT;
NCBPSLASTinit = codingParams.NCBPSLASTInit;
NDBPSLASTinit = codingParams.NDBPSLASTInit;

% A: Compute the number of available bits, IEEE Std 802.11ax-2021, Equation
% 27-69

% Initial LDPC parameters calculation - before update if LDPC extra symbol
% required
if isfield(codingParams,'LDPC2x')
    ldpcParms = wlan.internal.heCommonLDPCParameters(NSYMinit,mSTBC,numDBPS,numCBPS,NDBPSLASTinit,NCBPSLASTinit,rate,codingParams.LDPC2x);
else
    ldpcParms = wlan.internal.heCommonLDPCParameters(NSYMinit,mSTBC,numDBPS,numCBPS,NDBPSLASTinit,NCBPSLASTinit,rate);
end

% Update NumAvBits and numPuncture bits if LDPC extra symbol is required
if codingParams.LDPCExtraSymbol
    % IEEE Std 802.11ax-2021, Equation 27-81
    if aInitCommon==3
        ldpcParms.NumAvBits = ldpcParms.NumAvBits+mSTBC*(numCBPS-3*NCBPSSHORT);
    else
        ldpcParms.NumAvBits = ldpcParms.NumAvBits+mSTBC*NCBPSSHORT;
    end

    % IEEE Std 802.11ax-2021, Equation 27-82
    ldpcParms.NumPuncture = max(0, (ldpcParms.NumCW*ldpcParms.LengthLDPC)-ldpcParms.NumAvBits-ldpcParms.NumShort);
end

% C: Compute the number of shortening and punctured bits, IEEE Std 802.11-2016, Equation 19-37, 19-38
numSPCW = floor(ldpcParms.NumShort/ldpcParms.NumCW);
shortBoundary = rem(ldpcParms.NumShort, ldpcParms.NumCW);
vecShortenBits = zeros(1,ldpcParms.NumCW);
vecShortenBits(1:shortBoundary)= numSPCW+1;
vecShortenBits(shortBoundary+1:end)= numSPCW;

vecPunctureBits = zeros(1,ldpcParms.NumCW);
numPPCW = floor(ldpcParms.NumPuncture/ldpcParms.NumCW); 
punctureBoundary = rem(ldpcParms.NumPuncture, ldpcParms.NumCW); 

if (ldpcParms.NumPuncture > 0)
   vecPunctureBits(1:punctureBoundary) = numPPCW+1;
   vecPunctureBits(punctureBoundary+1:ldpcParms.NumCW) = numPPCW;
   vecRepeatBits = zeros(1,ldpcParms.NumCW);
else  
   % E: Compute the number of coded bits to be repeated. IEEE Std 802.11-2016, Equation 19-42
   numRep = max(0, round(ldpcParms.NumAvBits-ldpcParms.NumCW*ldpcParms.LengthLDPC*(1-rate))-ldpcParms.NumPLD);
   repeatBits = floor(numRep/ldpcParms.NumCW);
   extraBitLoc = rem(numRep,ldpcParms.NumCW);                          
   vecRepeatBits = repmat(repeatBits,1,ldpcParms.NumCW);
   vecRepeatBits(1:extraBitLoc) = repeatBits+1; 
end

% Number of payload bits within a codeword
vecPayloadBits = ldpcParms.LengthLDPC*rate-vecShortenBits;

% Set output
Y = struct( ...
    'VecPayloadBits',   vecPayloadBits, ...
    'Rate',             rate, ...
    'NumCBPS',          numCBPS, ...
    'NumCW',            ldpcParms.NumCW, ...
    'LengthLDPC',       ldpcParms.LengthLDPC, ...
    'VecShortenBits',   vecShortenBits, ...
    'VecPunctureBits',  vecPunctureBits, ...
    'VecRepeatBits',    vecRepeatBits, ...
    'NumAvailableBits', ldpcParms.NumAvBits, ...
    'ShortBoundary',    shortBoundary);
end