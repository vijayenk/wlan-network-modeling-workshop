function sym = vhtSIGAEncodeInterleaveMap(bits,phRot)
%vhtSIGAEncodeInterleaveMap Encode, interleave and map VHT SIG-A bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SYM = vhtSIGAEncodeInterleaveMap(BITS,PHROT) performs BCC encoding,
%   interleaving and constellation mapping according to Sections 18.3.5.6,
%   18.3.5.7 and 18.3.5.8.
%
%   SYM is a Nsd-by-Nsym matrix of complex numbers representing the
%   encoded, interleaved and mapped bits.
%
%   BITS is a column vector of bits to encode.
%
%   PHROT is a scalar or row vector with Nsym elements of the phase
%   rotation to apply to each symbol during constellation mapping. If only
%   one phase rotation is provided all symbols are rotated by the same
%   amount.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

% Encode according to Section 18.3.5.6
encodedSIG = wlanBCCEncode(bits,'1/2');

% Interleaving according to Section 18.3.5.7
numBPSCS = 1;
numCBPS = 48;
interleaveFormat = 'Non-HT';
interleavedData = wlanBCCInterleave(encodedSIG,interleaveFormat,numCBPS); % [Ncbps*2,1]

% BPSK constellation mapping according to Section 18.3.5.8 with phase
% rotation and extract OFDM symbols
sym = wlanConstellationMap(reshape(interleavedData,numCBPS,2),numBPSCS,phRot);

end