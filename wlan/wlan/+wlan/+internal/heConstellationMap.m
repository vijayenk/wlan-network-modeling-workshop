function y = heConstellationMap(x,NBPSCS,DCM)
%heConstellationMap HE constellation mapping
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
% 
%   Y = heConstellationMap(X,NBPSCS,DCM) performs constellation mapping of
%   X, and optionally dual carrier modulation.
%
%   Y is an Nsd-by-Nsym-by-Nss-by-Nseg array containing the mapped symbols.
%   Nsd is the number of data carrying subcarriers, Nsym is the number of
%   OFDM symbols, Nss is the number of spatial streams, and Nseg is the
%   number of segments.
%
%   X is an Nsd*NBPSCS/(Nss*Nseg)-by-Nsym-by-Nss-by-Nseg array containing
%   the bits to map.
%
%   NBPSCS is the number of coded bits per subcarrier per spatial stream.
%
%   DCM is a logical representing if dual carrier modulation is used.
%
%   See also heConstellationDemap

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

if DCM
    % DCM - IEEE P802.11ax/D4.1, Section 27.3.11.9
    switch NBPSCS
        case 1 % BPSK
            % Frequency dependent phase shift on upper half
            [NSD,NSYM,~,~] = size(x);
            lowerMappedData = wlanConstellationMap(x,NBPSCS);
            k = repmat((0:NSD-1).',1,NBPSCS*NSYM);
            upperMappedData = lowerMappedData.*exp(1i*pi*(k+NSD));
        case 2 % QPSK
            % Conjugate upper half
            lowerMappedData = wlanConstellationMap(x,NBPSCS);
            upperMappedData = conj(lowerMappedData);
        otherwise % NBPSCS = 4, 16-QAM
            assert(NBPSCS==4)
            NBPSS = size(x,1);
            % Permute bits before mapping on upper half
            lowerMappedData = wlanConstellationMap(x,NBPSCS);
            permInd = reshape(repmat([2 1 4 3].',1,NBPSS/4)+(0:4:NBPSS-1),NBPSS,1);
            upperMappedData = wlanConstellationMap(x(permInd,:,:,:),NBPSCS);
    end
    y = [lowerMappedData; upperMappedData];
else
    % Constellation mapping
    y = wlanConstellationMap(x,NBPSCS);
end

end