function y = segmentDeparseBitsCore(x, numES, numCBPS, numBPSCS)
%segmentDeparseBitsCore Segment deparser of data bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = segmentDeparseBitsCore(X, NUMES, NUMCBPS, NUMBPSCS) performs the
%   inverse operation of the segment parsing defined in IEEE 802.11-2016
%   Section 21.3.10.7, and IEEE Std 802.11ax-2021, Section 27.3.12.7.
%
%   Y is a matrix of size (Ncbpss*Nsym)-by-Nss containing the merged 
%   segments after performing the inverse operation of the segment parser.
%   Ncbpss is the number of coded bits per OFDM symbol per spatial stream, 
%   Nsym is the number of OFDM symbols, and Nss is the number of spatial
%   streams.
%
%   X is a multidimensional array of size (Ncbpssi*Nsym)-by-Nss-by-2
%   containing deinterleaved data, where Ncbpssi is the number of coded
%   bits per OFDM symbol per spatial stream per interleaver block, and 2
%   is the number of segments.
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
%   See also segmentParseBitsCore.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

% Validate number of segments in x - last dimension of x must be 2
if size(x,3) ~= 2
    coder.internal.error('wlan:wlanSegmentParseBits:InvalidInputSegments');
end

% Validate input parameters
numSS = wlan.internal.validateSegmentParseBitsInputs(x, numES, numCBPS, numBPSCS);

% Return an empty matrix if x is empty
if isempty(x)
    y = zeros(0, numSS, 'like', x);
    return;
end

numCBPSS = numCBPS/numSS;       % Input length must be multiple of numCBPSS
blockSize = max(1, numBPSCS/2); % s in the spec
numES = blockSize*numES;        % s*numES in the spec
numTrunks = floor(numCBPSS/(2*numES));
tailLen = numCBPSS - 2*numTrunks*numES;

if tailLen > 0
    % When numCBPSS is not divisible by 2*blockSize*numES
    xIn4D = reshape(x, numES*numTrunks+tailLen/2, [], numSS, 2);
    majorIn5D = reshape(xIn4D(1:numES*numTrunks, :, :, :), numES, numTrunks, [], numSS, 2);
    tailIn5D = reshape(xIn4D(numES*numTrunks+(1:tailLen/2), :, :, :), blockSize, (tailLen/(2*blockSize)), [], numSS, 2);

    tailIn5D = permute(tailIn5D, [1 5 2 3 4]);
    majorIn5D = permute(majorIn5D, [1 5 2 3 4]); % [numES, 2, numTrunks, size(x,1)/numCBPSS, numSS]

    % When numCBPSS is not divisible by 2*blockSize*numES
    yIn3D = cat(1, reshape(majorIn5D, 2*numES*numTrunks, [], numSS), reshape(tailIn5D, tailLen, [], numSS));
else
    majorIn5D = reshape(x, numES, numTrunks, [], numSS, 2);

    majorIn5D = permute(majorIn5D, [1 5 2 3 4]); % [numES, 2, numTrunks, size(x,1)/numCBPSS, numSS]

    % No tail in IEEE Std 802.11ax-2021, Section 27.3.12.7.
    yIn3D = reshape(majorIn5D, 2*numES*numTrunks, [], numSS);
end

y = reshape(yIn3D, [], numSS);

end