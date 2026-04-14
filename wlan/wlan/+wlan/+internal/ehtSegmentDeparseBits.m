function y = ehtSegmentDeparseBits(x,NSYM,NSS,NBPSCS,ruSize,dcm)
%ehtSegmentDeparseBits EHT segment deparser of data bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtSegmentDeparseBits(X,NSYM,NSS,NBPSCS,RUSIZE,DCM) performs the
%   inverse operation of the segment parsing defined in IEEE
%   P802.11be/D1.5 Section 36.3.13.5.
%
%   Y is a matrix of size (Ncbpss*Nsym)*L-by-Nss containing the merged
%   segments after performing the inverse operation of the segment parser.
%   Ncbpss is the number of coded bits per OFDM symbol per spatial stream,
%   Nsym is the number of OFDM symbols, L is the number of frequency
%   subblocks and Nss is the number of spatial streams.
%
%   X is a cell array of size Ncbpssi-by-Nsym-by-Nss for each subblock L
%   containing deinterleaved data, where Ncbpssi is the number of coded
%   bits per OFDM symbol per spatial stream per interleaver block, and L is
%   the number of frequency subblocks as defined in IEEE P802.11be/D1.5
%   Section 36.3.13.5, where
%
%   - L is 2 for 484+996, (242+484)+996, 2x996 RU/MRU
%   - L is 3 for 484+2*996 and 3*996 RU/MRU
%   - L is 4 for 484+3*996 and 4*996 RU/MRU
%
%   NSYM is the number of OFDM symbols and NSS is the number of spatial
%   streams.
%
%   NUMBPSCS is a scalar specifying the number of coded bits per subcarrier
%   per spatial stream. It must be equal to 1, 2, 4, 6, 8, 10, or 12.
%
%   RUSIZE is the RU size.
%
%   DCM is a logical representing if dual carrier modulation is used.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

p = wlan.internal.ehtSegmentParserParameters(ruSize,NBPSCS,dcm);
L = p.L;
m = p.m;
nl = p.NL;
Ncbpssl = p.Ncbpssl; % Same as NCBPSS/L
if dcm
    N = 22; % Equation 36-70 of IEEE P802.11be/D1.5
else
    N = 44;
end

m1 = cell(1,L);
m2 = cell(1,L);
for lidx=1:L
    k = (0:(Ncbpssl(lidx)-nl(lidx)*N*NBPSCS-1))';
    m1{lidx} = sum(m).*floor(k./m(lidx)) + sum(m(1:(lidx-1))) + mod(k,m(lidx)); % Equation 36-70 of IEEE P802.11be/D1.0
    m2{lidx} = 0; % For codegen (all elements of the cell array must be initialized before the first use)
end

idxRU996 = p.RU996Index;
idxNonRU996 = p.NonRU996Index;
mRU996 = m(p.RU996Index);
if any(nl) % Only for MRU. Equation 36-71 of IEEE P802.11be/D1.5
    for l=1:numel(idxRU996) % Process RU of size 996
        k = Ncbpssl(idxRU996(l))-nl(idxRU996(l))*N*NBPSCS:Ncbpssl(idxRU996(l))-1;
        k1 = k-(Ncbpssl(idxRU996(l))-nl(idxRU996(l))*N*NBPSCS);
        m2{l} = sum(m).*floor(Ncbpssl(idxNonRU996)/m(idxNonRU996)) + sum(mRU996(1:numel(idxRU996))).*floor(k1./mRU996(l)) + sum(mRU996(1:(l-1))) + mod(k,mRU996(l));
        m1{idxRU996(l)} = [m1{idxRU996(l)};m2{l}.']; % Combine MRU indices
    end
end

% Map input to the parse sequence
y = coder.nullcopy(zeros(sum(p.Ncbpssl),NSYM,NSS,'like',(x{1})));
for i=1:L
    y(m1{i}+1,:,:) = x{i};
end

y = reshape(y,sum(p.Ncbpssl)*NSYM,NSS);

end