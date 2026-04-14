function y = segmentDeparseSymbolsCore(x)
%segmentDeparseSymbolsCore Segment deparser of data subcarriers
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = segmentDeparseSymbolsCore(X) performs segment deparsing on the
%   input X as per IEEE 802.11-2016 Section 21.3.10.9.3, and IEEE
%   Std 802.11ax-2021, Section 27.3.12.11.
%
%   Y is an array of size Nsd-by-Nsym-by-Nss containing the deparsed
%   frequency segments. Nsd is the number of data subcarriers, Nsym is the
%   number of OFDM symbols, and Nss is the number of spatial streams. 
%
%   X is an array of size (Nsd/Nseg)-by-Nsym-by-Nss-by-2 containing the
%   frequency segments to deparse.
%
%   See also segmentParseSymbolsCore.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

[numSDPerSeg, numSym, numSS, numSeg] = size(x);
assert(numSeg==2);
tempX = permute(x, [1 4 2 3]);
y = reshape(tempX, 2*numSDPerSeg, numSym, numSS);

end