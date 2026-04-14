function dataPerUser = vhtSIGBEncodeInterleaveMap(bitsPerUser,chanBW)
%vhtSIGBEncodeInterleaveMap Encode, interleave and map VHT SIG-B bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   SYM = vhtSIGBEncodeInterleaveMap(BITS,CHANBW) performs BCC encoding,
%   segment parsing, interleaving and constellation mapping according to
%   Sections 18.3.5.6, 22.3.10.7, 22.3.10.8 and 18.3.5.8.
%
%   SYM is a Nsd-by-Nsym matrix of complex numbers representing the
%   encoded, interleaved and mapped bits.
%
%   BITS is a column vector of bits to encode for a user.
%
%   CHANBW is a character vector specifying the channel bandwidth.

%   Copyright 2016-2017 The MathWorks, Inc.

%#codegen

% Repeat bits, with padding, for different CBW
switch chanBW
  case {'CBW20','CBW2'}
    repVHTSIGBBits = bitsPerUser; % 26
    numCBPSSI   = 52;     % Table 22-6, coded bits per interleaver block
  case {'CBW40','CBW4'}
    repVHTSIGBBits = [bitsPerUser; bitsPerUser]; % 54
    numCBPSSI   = 108;
  case {'CBW80','CBW8'}
    repVHTSIGBBits = [repmat(bitsPerUser, 4, 1); 0]; % 117
    numCBPSSI   = 234;
  otherwise   % {'CBW80+80', 'CBW160', 'CBW16'}
    repVHTSIGBBits = repmat([repmat(bitsPerUser, 4, 1); 0], 2, 1); % 234
    numCBPSSI   = 234;
end
numBPSCS = 1;
numSeg = 1 + any(strcmp(chanBW, {'CBW16', 'CBW160'}));
numCBPS = numCBPSSI*numSeg;
numES = 1;

% BCC encoding
encOut = wlanBCCEncode(repVHTSIGBBits,'1/2');
% [Ncbps,1]

% Segment Parser
parsedData = wlanSegmentParseBits(encOut,chanBW,numES,numCBPS,numBPSCS);
% [Ncbpssi,1,2] for 'CBW160' or 'CBW16', [Ncbps,1] otherwise

% BCC Interleaving
interleaveOut = wlanBCCInterleave(parsedData,'VHT',numCBPSSI,chanBW);
% [Ncbpssi,1,2] for 'CBW160' or 'CBW16', [Ncbps,1] otherwise

% Reshape to form OFDM symbols
interleaveOut = reshape(interleaveOut,numCBPSSI,1,1,numSeg);
% [Ncbpssi,1,1,2] for 'CBW160' or 'CBW16', [Ncbps,1] otherwise

% Constellation mapping
mappedData = wlanConstellationMap(interleaveOut,numBPSCS);
% [Nsd/2,1,1,2] for 'CBW160' or 'CBW16', [Nsd,1] otherwise

% Segment Deparser
deparsedData = wlanSegmentDeparseSymbols(mappedData,chanBW);
% [Nsd,1]
dataPerUser = deparsedData(:); % (:) for codegen

end