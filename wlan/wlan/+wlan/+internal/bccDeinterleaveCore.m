function y = bccDeinterleaveCore(x,numBPSCS,numCBPSSI,Ncol,Nrow,Nrot)
%bccDeinterleaveCore BCC Deinterleaver
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = bccDeinterleaveCore(X, NUMBPSCS, NUMCBPSSI, NCOL, NROW, NROT)
%   outputs the binary convolutionally deinterleaved input X, as defined in
%   IEEE 802.11-2012 Section 18.3.5.7, IEEE 802.11ac-2013 Section
%   22.3.10.8, and IEEE 802.11ah Section 24.3.9.8.
%
%   Y is an array of size (Ncbpssi*Nsym)-by-Nss-by-Nseg containing binary 
%   convolutionally deinterleaved data. Ncbpssi is the number of coded bits
%   per OFDM symbol per spatial stream per interleaver block, Nsym is the
%   number of OFDM symbols, Nss is the number of spatial streams, and Nseg
%   is the number of segments.
%
%   X is an a single or double precision array of size
%   (Ncbpssi*Nsym)-by-Nss-by-Nseg containing binary convolutionally
%   interleaved data.
%
%   NUMBPSCS is the number of coded bits per subcarrier per spatial stream.
%
%   NUMCBPSSI is the number of coded bits per OFDM symbol per spatial
%   stream per interleaver block. It is a positive integer scalar equal to
%   Nsd*Nbpscs for 'Non-HT' interleaving, and equal to Nsd*NUMBPSCS/Nseg
%   for 'VHT' interleaving, where Nsd is the number of data subcarriers.
%
%   NCOL, NROW, and NROT are the interleaver parameters.
%
%   See also bccInterleaveCore.

%   Copyright 2015-2022 The MathWorks, Inc.

%#codegen

% Number of spatial streams
numSS = size(x,2);
s = max(numBPSCS/2, 1);   % Eq. 22-68, IEEE Std 802.11ac-2013

% Indices for first permutation if numSS > 1
pRMat = coder.nullcopy(zeros(numCBPSSI, numSS, 'like',x));
pRMat(:,1) = (1:numCBPSSI).';
if numSS >= 2 && numSS <=4
    % Eq. 22-80, pg 282
    for iss = 2:numSS
        pRMat(:, iss) = mod((0:numCBPSSI-1).' + ( mod(2*(iss-1),3) + ...
            3*floor((iss-1)/3)) * Nrot * numBPSCS, numCBPSSI) + 1;
    end
else
    jTab = [0 5 2 7 3 6 1 4];   % Table 22-18
    % Eq 22-81, pg 282
    for iss = 2:numSS
        pRMat(:, iss) = mod((0:numCBPSSI-1).' + jTab(iss) * ...
            Nrot * numBPSCS, numCBPSSI) + 1;
    end
end

% Indices for first permutation of 'Non-HT' deinterleaving or second 
% permutation of 'VHT' deinterleaving - Eq. 22-82
secondPIdx = ( s*floor( (0:numCBPSSI-1)/s ) + ...
    mod( ((0:numCBPSSI-1) + floor( Ncol*(0:numCBPSSI-1)/numCBPSSI ) ), s ) ...
    + 1).';   % 1-based indexing for interleaving

% Indices for second permutation of 'Non-HT' deinterleaver, or third 
% permutation of 'VHT' deinterleaver - Eq. 22-83
tmp = reshape(1:numCBPSSI,Ncol,Nrow).';
thirdPIdx = tmp(:);

% Reshape into Ncbpssi-Nsym-Nss-Nseg 
numSeg = size(x,3); % Number of segments
numSym = size(x,1)/numCBPSSI; % Number of OFDM symbols
data = reshape(x,numCBPSSI,numSym,numSS,numSeg);

yIn4D = coder.nullcopy(zeros(size(data),'like',x));
% Deinterleave data
for nssIdx = 1:size(data,3)
    yIn4D(thirdPIdx(secondPIdx(pRMat(:,nssIdx))),:,nssIdx,:) = data(:,:,nssIdx,:);
end

% Deinterleaver output
% Reshape to 3D [Ncbpssi*Nsym,Nss,Nseg]
y = reshape(yIn4D,numCBPSSI*numSym,numSS,numSeg);

end