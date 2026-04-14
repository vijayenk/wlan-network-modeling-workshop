function y = segmentParseBitsCore(x,numES,numCBPS,numBPSCS)
%segmentParseBitsCore Segment parser of data bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = segmentParseBitsCore(X, NUMES, NUMCBPS, NUMBPSCS) performs segment
%   parsing on the input X as per IEEE 802.11-2016 Section 21.3.10.7, and
%   IEEE Std 802.11ax-2021, Section 27.3.12.7.

%   Y is a multidimensional array of size (Ncbpssi*Nsym)-by-Nss
%   containing the segmented bits. Ncbpssi is the number of coded bits per
%   OFDM symbol per spatial stream per interleaver block, Nsym is the
%   number of OFDM symbols, Nss is the number of spatial streams.
%
%   X is a 'double' or 'int8' matrix of size (Ncbpss*Nsym)-by-Nss 
%   containing stream parsed bits, where Ncbpss is the number of coded bits
%   per OFDM symbol per spatial stream.
%
%   NUMES is a scalar specifying the number of encoded streams. Valid
%   values are 1 to 9, and 12.
%
%   NUMCBPS is a nonnegative scalar specifying the number of coded bits per
%   OFDM symbol. NUMCBPS must be equal to (Nsd*NUMBPSCS*Nss), where Nsd
%   must be 468 or 1960.
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1, 2, 4, 6, 8, or 10.
%       
%   See also segmentDeparseBitsCore.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

% Validate input parameters
numSS = wlan.internal.validateSegmentParseBitsInputs(x, numES, numCBPS, numBPSCS);

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(0, numSS, 2, 'like', x);
    return;
end

numCBPSS = numCBPS/numSS;       % Input length must be multiple of numCBPSS
blockSize = max(1, numBPSCS/2); % s in the spec
numES = blockSize*numES;        % s*numES in the spec
numTrunks = floor(numCBPSS/(2*numES));
tailLen = numCBPSS - 2*numTrunks*numES;

% Eq. 22-73
xIn3D = reshape(x, numCBPSS, [], numSS);  % [numCBPSs, size(x, 1)/numCBPSS, numSS]
majorIn4D = reshape(xIn3D(1:2*numES*numTrunks, :, :), numES, 2, [], numSS); % [numES, 2, numTrunks*size(x,1)/numCBPSS, numSS]
majorIn4D = permute(majorIn4D, [1 3 4 2]); % [numES, numTrunks * size(x,1)/numCBPSS, numSS, 2]

if tailLen > 0
    % Eq. 22-74 when numCBPSS is not divisible by 2*blockSize*numES
    tailIn4D = reshape(xIn3D(end-tailLen+(1:tailLen), :, :), blockSize, 2, [], numSS);
    tailIn4D = permute(tailIn4D, [1 3 4 2]);
    yIn4D = cat(1, reshape(majorIn4D, numES*numTrunks, [], numSS, 2), ...
        reshape(tailIn4D, tailLen/2, [], numSS, 2)); % [numCBPSS/2, [], numSS, 2]
    y = reshape(yIn4D, [], numSS, 2);
else
    % No tail in Std 802.11ax-2021, Section 27.3.12.7.
    y = reshape(majorIn4D, [], numSS, 2);
end
    
end