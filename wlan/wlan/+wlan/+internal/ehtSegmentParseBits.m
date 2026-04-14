function [y,p] = ehtSegmentParseBits(x,NCBPS,NBPSCS,ruSize,dcm)
%ehtSegmentParseBits Segment parser of data bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtSegmentParseBits(X,NCBPS,NBPSCS,RUSIZE,DCM) performs segment
%   parsing on the input X as per IEEE P802.11be/D1.5 Section 36.3.13.5.
%
%   Y is a cell array of size (Ncbpssi*Nsym)-by-Nss for each frequency
%   subblock L, containing the segmented bits. Ncbpssi is the number of
%   coded bits per OFDM symbol per spatial stream per interleaver block,
%   Nsym is the number of OFDM symbols, Nss is the number of spatial
%   streams, and L is the number of frequency subblocks as defined in
%   IEEE P802.11be/D1.5, Section 36.3.13.5, where
%
%   - L is 2 for 484+996, (242+484)+996, 2x996 RU/MRU
%   - L is 3 for 484+2*996 and 3*996 RU/MRU
%   - L is 4 for 484+3*996 and 4*996 RU/MRU
%
%   X is a 'double' or 'int8' matrix of size (Ncbpss*Nsym)-by-Nss 
%   containing stream parsed bits, where Ncbpss is the number of coded bits
%   per OFDM symbol per spatial stream.
%
%   NCBPS is a nonnegative scalar specifying the number of coded bits per
%   OFDM symbol. NCBPS must be equal to (Nsd*NBPSCS*Nss).
%
%   NBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream.
%
%   RUSIZE is the RU size.
%
%   DCM is a logical representing if dual carrier modulation is used.
%
%   [...,P] = ehtSegmentParseBits(...) returns a structure of segment parse
%   parameters for a given RUSize, NBPSCS, and DCM.
%
%   P contains the following fields:
%
%   RUSizePer80MHz     - RU Size within a 80 MHz frequency segment
%   m                  - Proportional ratio defined in Table 36-48 of IEEE
%                        P802.11be/D1.5
%   L                  - Number of frequency subblocks
%   NL                 - Indicates the location of 996 RU in an MRU
%   RU996Index         - Indicates the RU index of a 996 RU within an MRU
%   NonRU996Index      - Indicates the non 996 RU index within an MRU
%   Ncbpssl            - Number of coded bits per spatial streams per
%                        frequency segments
%   NumAllocationRU996 - Indicates the RU index as a vector within a 996
%                        RU frequency segment
%       
%   See also ehtSegmentDeparseBits

%   Copyright 2022 The MathWorks, Inc.

%#codegen

NSS = size(x,2);
NCBPSS = NCBPS/NSS;
NSYM = numel(x)/(NSS*NCBPSS);
p = wlan.internal.ehtSegmentParserParameters(ruSize,NBPSCS,dcm);
if dcm
     NBPSCS= NBPSCS/2; 
end
L = p.L;
m = p.m;
nl = p.NL;
Ncbpssl = p.Ncbpssl; % Same as  NCBPSS/L
% Generate bit mapping for single NSS

if ~isempty(coder.target) % For codegen
    m1 = cell(1,max(L,numel(p.RU996Index)));
    m2 = cell(1,L);
    for l=1:size(m1,2) % For codegen assigns values to the cell array elements
         m1{l} = zeros(1,0);
    end

    for l=1:L % For codegen assigns values to the cell array elements
         m2{l} = zeros(1,0);
    end
end

for l=0:(L-1)
    lidx = l+1;
    k = (0:(Ncbpssl(lidx)-nl(lidx)*44*NBPSCS-1))';
    m1{lidx} = sum(m).*floor(k./m(lidx)) + sum(m(1:(lidx-1))) + mod(k,m(lidx)); % Equation 36-70 of IEEE P802.11be/D1.5
end

% Equation 36-62
idxRU996 = p.RU996Index;
idxNonRU996 = p.NonRU996Index;
mRU996 = m(p.RU996Index);

if any(nl) % Leftoverbits
    for l=1:numel(idxRU996) % Process RU of size 996. Equation 36-71 of IEEE P802.11be/D1.5
        k = Ncbpssl(idxRU996(l))-nl(idxRU996(l))*44*NBPSCS:Ncbpssl(idxRU996(l))-1;
        k1 = k-(Ncbpssl(idxRU996(l))-nl(idxRU996(l))*44*NBPSCS);
        m2{l} = sum(m).*floor(Ncbpssl(idxNonRU996)/m(idxNonRU996)) + sum(mRU996(1:numel(idxRU996))).*floor(k1./mRU996(l)) + sum(mRU996(1:(l-1))) + mod(k,mRU996(l));
        m1{idxRU996(l)} = [m1{idxRU996(l)};m2{l}.']; % Combine MRU indices
    end
end

% Map input to the parse sequence
inp = reshape(x,NCBPSS,NSYM,NSS); % NCBPSS-NSYM-NSS
y = cell(1,L);
for j=1:L
    subBlk = inp(m1{j}+1,:,:); % Add 1 for 1-based indexing
    y{j} = reshape(subBlk(:),p.Ncbpssl(j)*NSYM,NSS);
end

end