function out = parseInputBits(in,numReqBits,offset)
%parseInputBits Repeat and extract input bits for processing
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OUT = parseInputBits(IN,NUMREQBITS) cyclically repeats a column of
%   input bits IN to the required output length, NUMREQBITS.
%
%   OUT = parseInputBits(IN,NUMREQBITS,OFFSET) offsets the start of
%   selected output bits from IN by OFFSET.

%   Copyright 2020-2025 The MathWorks, Inc.

%#codegen

assert(isvector(in))
if isempty(in)
    out = in; % Return empty
    return
elseif numReqBits == 0
    out = zeros(0,1,'like',in); % Return empty
    return
end
if nargin>2
    bitoffset = uint32(offset);
else
    bitoffset = uint32(0);
end
numBits = uint32(numel(in));
numReqBits = uint32(numReqBits);
out = in(mod(bitoffset+(0:numReqBits-1)',numBits)+1);

end
