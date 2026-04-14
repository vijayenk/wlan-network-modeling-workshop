function y = bccInterleaveCore(x,numBPSCS,numCBPSSI,Ncol,Nrow,Nrot)
%bccInterleaveCore BCC Interleaver
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = bccInterleaveCore(X, NUMBPSCS, NUMCBPSSI, NCOL, NROW, NROT) outputs
%   the interleaved binary convolutionally encoded data input X, as defined
%   in IEEE 802.11-2012 Section 18.3.5.7, IEEE 802.11ac-2013 Section
%   22.3.10.8, and IEEE 802.11ah Section 24.3.9.8.
%
%   Y is an (Ncbpssi*Nsym)-by-Nss-by-Nseg array of the same class of input 
%   X containing binary convolutionally interleaved data. Ncbpssi is the 
%   number of coded bits per OFDM symbol per spatial stream per interleaver
%   block, Nsym is the number of OFDM symbols, Nss is the number of spatial
%   streams, and Nseg is the number of segments.
%
%   X is an 'int8' or 'double' (Ncbpssi*Nsym)-by-Nss-by-Nseg array 
%   containing binary convolutionally encoded data.
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
%   See also bccDeinterleaveCore.

%   Copyright 2015-2017 The MathWorks, Inc.

%#codegen

% Number of spatial streams
[numSamples,numSS,numSeg] = size(x);
numSym = numSamples/numCBPSSI; % Number of OFDM symbols

s = max(numBPSCS/2, 1);   % Eq. 22-68, IEEE Std 802.11ac-2013

% Indices for first permutation of 'Non-HT' and 'VHT' interleavers - Eq. 22-76
tmp = reshape(1:numCBPSSI,Ncol,Nrow).';
firstPIdx = tmp(:);

% Indices for second permutation of 'Non-HT' and 'VHT' interleavers - Eq. 22-77
secondPIdx = ( s*floor( (0:numCBPSSI-1)/s ) + ...
    mod( ((0:numCBPSSI-1) + numCBPSSI - ...
    floor( Ncol*(0:numCBPSSI-1)/numCBPSSI ) ), s ) ...
    + 1).';   % 1-based indexing for interleaving

% Indices for third permutation if numSS > 1
pRMat = coder.nullcopy(zeros(numCBPSSI,numSS));
pRMat(:,1) = (1:numCBPSSI).';
if numSS >= 2 && numSS <=4
    % Eq. 22-78, pg 281
    for iss = 2:numSS
        pRMat(:, iss) = mod((0:numCBPSSI-1).' - ( mod(2*(iss-1),3) + ...
            3*floor((iss-1)/3)) * Nrot * numBPSCS, numCBPSSI) + 1;
        % 1-based indexing for interleaving
    end
else % Applies for numSS > 4
    jTab = [0 5 2 7 3 6 1 4];   % Table 22-18
    % Eq. 22-79
    for iss = 2:numSS
        pRMat(:, iss) = mod((0:numCBPSSI-1).' - jTab(iss) * ...
            Nrot * numBPSCS, numCBPSSI) + 1; % 1-based indexing for interleaving
    end
end

% Reshape into Ncbpssi-Nsym-Nss-Nseg    
data = reshape(x,numCBPSSI,numSym,numSS,numSeg);

yIn4D = coder.nullcopy(zeros(size(data),'like',x));
% Interleave data
for nssIdx = 1:size(data,3)
    yIn4D(pRMat(secondPIdx,nssIdx),:,nssIdx,:) = data(firstPIdx,:,nssIdx,:);
end

% Interleaver output
% Reshape to 3D [Ncbpssi*Nsym,Nss,Nseg]
y = reshape(yIn4D,numCBPSSI*numSym,numSS,numSeg);

end