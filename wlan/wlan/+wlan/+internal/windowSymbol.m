function y = windowSymbol(symbol,windowlength)
%windowSymbol Window the consecutive OFDM symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = windowSymbol(SYMBOL,WINDOWLENGTH) applies windowing across
%   consecutive OFDM symbols.
%
%   SYMBOL is of size Ns-by-N, where Ns is the length of the extended OFDM
%   symbols and N is the number of OFDM symbols.
%
%   WINDOWLENGTH is the length of the windowing portion in samples.
%
%   See also windowingEquation

%   Copyright 2016 The MathWorks, Inc.

%#codegen

% Overlap and add the extended window potion.
% Set the windowing length equal to the pre-index window length.
W = windowlength-(windowlength>0);
firstRegion = symbol(1:end-W,1,:);
overlapRegion = symbol(end-W+1:end,1:end-1,:)+symbol(1:W,2:end,:);
middleRegion = [overlapRegion; symbol(W+1:end-W,2:end,:)];
lastRegion = symbol(end-W+1:end,end,:);
y = [firstRegion;reshape(middleRegion,[],1,size(symbol,3));lastRegion];

end