function params = heCommonLDPCParameters(NSYMinitCommon,mSTBC,NDBPS,NCBPS,NDBPSLASTinit,NCBPSLASTinit,R,varargin)
%heCommonLDPCParameters HE LDPC common coding parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PARAMS = heCommonLDPCParameters(NSYMINITCOMMON,MSTBC,NDBPS,NCBPS,
%   NDBPSLASTINIT,NCBPSLASTINIT,R,ISLDPC2x) returns a structure containing
%   LDPC parameters required for calculating per-user coding information.

%   Copyright 2017-2025 The MathWorks, Inc.

%#codegen

isLDPC2x = false;
if nargin>7
    isLDPC2x = varargin{1};
end

% IEEE Std 802.11ax-2021, Section 27.3.12.5.4
Npld = (NSYMinitCommon-mSTBC)*NDBPS+mSTBC*NDBPSLASTinit; % IEEE Std 802.11ax-2021, Equation 27-79
Navbits = (NSYMinitCommon-mSTBC)*NCBPS+mSTBC*NCBPSLASTinit; % IEEE Std 802.11ax-2021, Equation 27-80

% B: Compute integer number of LDPC codewords. IEEE Std 802.11-2016, Section 19.3.11.7.5, Table 19-16
if (Navbits<= 648)
    numCW = 1; % Number of LDPC code words
    if (Navbits >= (Npld + 912*(1 - R)))
        lengthLDPC = 1296;
    else
        lengthLDPC = 648;
    end
elseif(Navbits <= 1296)
    numCW = 1;
    if(Navbits >= (Npld + 1464*(1 - R)))
        lengthLDPC = 1944;
    else
        lengthLDPC = 1296;
    end
elseif(Navbits <= 1944)
    numCW = 1;
    lengthLDPC = 1944;
elseif(Navbits <= 2592)
    numCW = 2; 
    if(Navbits >= (Npld + 2916*(1 - R)))
        lengthLDPC = 1944;
    else
        lengthLDPC = 1296;
    end
elseif(Navbits <= 3888) % Section 38.3.6, Table 38-11. IEEE P802.11bn/D0.1
    numCW = 2; 
    lengthLDPC = 1944;
else % LDPC codeword length = 3888. Section 38.3.6, Table 38-11. IEEE P802.11bn/D0.1
    if isLDPC2x
        lengthLDPC = 3888;
    else
        lengthLDPC = 1944;
    end
    numCW = ceil(Npld/(lengthLDPC*R));
end

% C: Compute the number of shortening bits for HT and VHT. IEEE Std
% 802.11-2016, Section 19.3.11.7.5, Equation 19-37
numSHRT = max(0, numCW*lengthLDPC*R-Npld);                 

% D: Compute the number of bits to be punctured for HT and VHT. IEEE Std
% 802.11-2016, Section 19.3.11.7.5, Equation 19-38
numPunctureBits = max(0,(numCW*lengthLDPC)-Navbits-numSHRT);

% Determine if an LDPC extra symbol is required, IEEE Std 802.11ax-2021,
% Section 27.3.12.5.4
if (((numPunctureBits > 0.1*numCW*lengthLDPC*(1-R)) && ...
   (numSHRT < 1.2*numPunctureBits*(R/(1-R))))|| ...
   (numPunctureBits > 0.3*numCW*lengthLDPC*(1-R)))
    ldpcExtraSymbol = true;
else
    ldpcExtraSymbol = false;
end

params = struct;
params.NumPLD = Npld;
params.NumAvBits = Navbits;
params.LengthLDPC = lengthLDPC;
params.NumCW = numCW;
params.NumShort = numSHRT;
params.NumPuncture = numPunctureBits;
params.LDPCExtraSymbol = ldpcExtraSymbol;

end