function y = wlanSegmentDeparseBits(x, chanBW, numES, numCBPS, numBPSCS)
%wlanSegmentDeparseBits Segment deparser of data bits
%
%   Y = wlanSegmentDeparseBits(X, CHANBW, NUMES, NUMCBPS, NUMBPSCS)
%   performs the inverse operation of the segment parsing defined in 
%   IEEE 802.11ac-2013 Section 22.3.10.7 when CHANBW is 'CBW16' or
%   'CBW160'.
%
%   Y is a matrix of size (Ncbpss*Nsym)-by-Nss containing the merged 
%   segments after performing the inverse operation of the segment parser.
%   Ncbpss is the number of coded bits per OFDM symbol per spatial stream, 
%   Nsym is the number of OFDM symbols, and Nss is the number of spatial
%   streams.
%
%   X is a multidimensional array of size (Ncbpssi*Nsym)-by-Nss-by-Nseg
%   containing deinterleaved data, where Ncbpssi is the number of coded
%   bits per OFDM symbol per spatial stream per interleaver block, and Nseg
%   is the number of segments. When CHANBW is 'CBW16' or 'CBW160', Nseg is
%   2, otherwise it is 1.
%
%   CHANBW is a character vector or string scalar specifying the channel
%   bandwidth. It must be equal to 'CBW1', 'CBW2', 'CBW4', 'CBW8', 'CBW16',
%   'CBW20', 'CBW40', 'CBW80', or 'CBW160'.
%
%   NUMES is a scalar specifying the number of encoded streams. Valid
%   values are 1 to 9, and 12.
%
%   NUMCBPS is a nonnegative scalar specifying the number of coded bits per
%   OFDM symbol. When 'CBW16' or 'CBW160', NUMCBPS must be equal to
%   (468*NUMBPSCS*Nss).
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1, 2, 4, 6, or 8.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Validate chanBW
chanBW = wlan.internal.validateParam('S1GVHTCHANBW', chanBW, mfilename);

% Validate input
validateattributes(x, {'double','single'}, {'3d'}, mfilename, 'Input');

% Inverse operation of IEEE Std 802.11ac-2013 Section 22.3.10.7
if any(strcmp(chanBW, {'CBW16', 'CBW160'}))
    y = wlan.internal.segmentDeparseBitsCore(x, numES, numCBPS, numBPSCS);
else
    y = x;
end

end
