function y = heConstellationDemap(x,nVar,NBPSCS,DCM)
%heConstellationDemap HE constellation de-mapping
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = heConstellationDemap(X,NVAR,NBPSCS,DCM) demaps the received input
%   symbols (X) using the soft-decision approximate LLR method. The
%   combining of dual carrier modulated symbols is optionally performed.
%
%   Y is an Nsd*NBPSCS/(Nss*Nseg)-by-Nsym-by-Nss-by-Nseg array containing
%   the demapped soft bits.
%
%   X is a single or double precision array of size
%   Nsd-by-Nsym-by-Nss-by-Nseg array containing the symbols to demap. Nsd
%   is the number of data carrying subcarriers, Nsym is the number of OFDM
%   symbols, Nss is the number of spatial streams, and Nseg is the number
%   of segments.
%
%   NVAR is single or double precision nonnegative scalar representing the
%   noise variance estimate.
%
%   NBPSCS is the number of coded bits per subcarrier per spatial stream.
%
%   DCM is a logical representing if dual carrier modulation is used.
%
%   See also heConstellationMap

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

if DCM
    % DCM - IEEE Std 802.11ax-2021, Section 27.3.12.9
    switch NBPSCS
        case 1
            % Upper half is phase rotated version of lower half;
            % combine and average
            Nsd = size(x,1);
            Nsd = Nsd/2;
            k = (0:Nsd-1).';
            xComb = (x(1:end/2,:,:,:)+(x(end/2+1:end,:,:,:).*exp(-1i*pi*(k+Nsd))))/2;
            y = wlanConstellationDemap(xComb,nVar/2,NBPSCS);
        case 2
            % Upper half is conjugate of lower half; combine and
            % average
            xComb = (x(1:end/2,:,:,:)+conj(x(end/2+1:end,:,:,:)))/2;
            y = wlanConstellationDemap(xComb,nVar/2,NBPSCS);
        otherwise % 4
            assert(NBPSCS==4)
            % Upper half bits are a permuted version of lower half.
            % Permute, combine and average.
            lower = wlanConstellationDemap(x(1:end/2,:,:,:),nVar,NBPSCS);
            upper = wlanConstellationDemap(x(end/2+1:end,:,:,:),nVar,NBPSCS);
            permuteIdx = reshape([2 1 4 3].'+(0:4:(size(upper,1)-1)),size(upper,1),1);
            y = lower+upper(permuteIdx,:,:,:); % sum LLRs
    end
else
    y = wlanConstellationDemap(x,nVar,NBPSCS);
end

end
