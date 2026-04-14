function y = segmentParseSymbolsCore(x)     
%segmentParseSymbolsCore Segment parser of data subcarriers.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = wlanSegmentParseSymbols(X) performs the inverse operation of the
%   segment deparsing on the input X defined in IEEE 802.11-2016 Section
%   21.3.10.9.3, and Std 802.11ax-2021, Section 27.3.12.11.
%
%   Y is an array of size (Nsd/Nseg)-by-Nsym-by-Nss-by-2 containing the 
%   the frequency segments obtained from the inverse operation of segment 
%   deparsing. Nsd is the number of data subcarriers, Nsym is the number of
%   OFDM symbols, Nss is the number of spatial streams, and Nseg is the
%   number of frequency segments.
%
%   X is an array of size Nsd-by-Nsym-by-Nss containing the equalized data
%   to be segmented.
%
%   See also segmentDeparseSymbolsCore.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

[numSD, numSym, numSS, ~] = size(x);
tempX = reshape(x, numSD/2, 2, numSym, numSS);
y = permute(tempX, [1 3 4 2]);
    
end