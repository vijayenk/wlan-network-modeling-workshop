function y = spatialMap(x, mappingType, numTx, mappingMatrix, varargin)
%spatialMap Spatial mapping
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = spatialMap(X, MAPPINGTYPE, NUMTX, MAPPINGMATRIX) performs spatial
%   mapping from space-time streams to transmit antennas.
%
%   Y is a FFTLen-by-numSym-by-NUMTX or numST-by-numSym-by-NUMTX matrix,
%   where FFTLen represents the FFT length, numST represents the number of
%   data plus pilot subcarriers, numSym represents the number of OFDM
%   symbols, and NUMTX represents the number of transmit antennas.
%
%   X is a FFTLen-by-numSym-by-numSTS or numST-by-numSym-by-numSTS matrix,
%   where numSTS represents the number of space-time streams. When FFTLen
%   is 32, 64, 128, 256, or 512, the null subcarrier locations in
%   VHT/HT/S1G portion of a waveform are assumed and enforced.
%
%   MAPPINGTYPE can be one of 'Direct', 'Hadamard', 'Fourier' and 'Custom'.
%
%   NUMTX is the number of transmit antennas.
%
%   MAPPINGMATRIX is a numSTS-by-NUMTX, FFTLen-by-numSTS-by-NUMTX or
%   numST-by-numSTS-by-NUMTX spatial mapping matrix(ces) that apply only
%   when the MAPPINGTYPE input is 'Custom'. The output Y is a
%   FFTLen-by-NUMTX or numST-by-NUMTX matrix.
%
%   Y = spatialMap(..., MAPPINGIND) performs spatial mapping using the
%   mapping indices MAPPINGIND to extract subcarriers from MAPPINGMATRIX.
%   MAPPINGIND is a vector with FFTLen or numST elements. When not provided
%   all rows of MAPPINGMATRIX are assumed to be used.

%   Copyright 2015-2024 The MathWorks, Inc.

%#codegen

% Section 21.3.10.11.1 in IEEE Std 802.11-2020.
if isenum(mappingType)
    switch mappingType
        case wlan.type.SpatialMapping.direct
            y = x;
        case wlan.type.SpatialMapping.hadamard
            y = spatialMappingHadamard(x,numTx);
        case wlan.type.SpatialMapping.fourier
            y = spatialMappingFourier(x,numTx);
        otherwise  % 'Custom'
            y = spatialMappingCustom(x,mappingMatrix,numTx,varargin{:});
    end
else
    switch mappingType
        case 'Direct'
            y = x;
        case 'Hadamard'
            y = spatialMappingHadamard(x,numTx);
        case 'Fourier'
            y = spatialMappingFourier(x,numTx);
        otherwise  % 'Custom'
            y = spatialMappingCustom(x,mappingMatrix,numTx,varargin{:});
    end
end

end

function y = spatialMappingHadamard(x,numTx)
%spatialMappingHadamard Spatial mapping for Hadamard

    N = 2^ceil(log2(numTx)); % N must be power of 2
    Q = hadamard(N);
    numSTS = size(x,3);
    normQ = Q(1:numSTS, 1:numTx)/sqrt(numTx);
    y = precode(x, normQ, numTx);
end

function y = spatialMappingFourier(x,numTx)
%spatialMappingFourier Spatial mapping for Fourier

    % The following can be obtained from dftmtx(numTx) which however does not generate code
    numSTS = size(x,3);
    [g1, g2] = meshgrid(0:numTx-1, 0:numSTS-1);
    normQ = exp(-1i*2*pi.*g1.*g2/numTx)/sqrt(numTx);
    y = precode(x, normQ, numTx);
end

function y = spatialMappingCustom(x,mappingMatrix,numTx,varargin)
%spatialMappingCustom Spatial mapping for Custom

    [numCarriers,numSym,numSTS] = size(x);
    if size(mappingMatrix, 1) <= 8 % 8 is maximum Nsts expected
        % MappingMatrix is Nsts-by-Ntx
        Q = mappingMatrix(1:numSTS, :);
        normQ = Q * sqrt(numSTS)/norm(Q, 'fro'); % Normalization
        y = precode(x, normQ, numTx);
    else
        % MappingMatrix is Nst-by-Nsts-by-Ntx
        if nargin>3
            % Indices provided to extract active subcarrier from mapping matrix
            ind = varargin{1};
            assert(numCarriers==numel(ind));
            mappingMatrixP = permute(mappingMatrix(ind, 1:numSTS, :), [2 3 1]);
        else
            mappingMatrixP = permute(mappingMatrix(:, 1:numSTS, :), [2 3 1]); % Nsts-by-Ntx-by-Nst
        end
        if isempty(coder.target)
            normQ = mappingMatrixP .* sqrt(numSTS) ./ pagenorm(mappingMatrixP, 'fro'); % Normalization
        else
            % pagenorm is not supported for code generation
            Nst = size(mappingMatrix,1);
            n = coder.nullcopy(zeros(1,1,Nst)); % 1-by-1-by-Nst
            for i = 1:Nst
                n(i) = norm(mappingMatrixP(:, :, i), 'fro');
            end
            normQ = mappingMatrixP .* sqrt(numSTS) ./ n;
        end
        xP = permute(x, [2 3 1]); % Permute to Nsym-by-Nsts-by-Nst
        if fullFFT(numCarriers)
            % X is full FFT, so extract active subcarriers for spatial mapping
            dataAndPilotIdx = getDataAndPilotIndices(numCarriers);
            yP = complex(zeros(numSym, numTx, numCarriers));
            yP(:, :, dataAndPilotIdx) = pagemtimes(xP(:, :, dataAndPilotIdx), normQ);
        else
            yP = pagemtimes(xP, normQ);
        end
        y = permute(yP, [3 1 2]);
    end
end

function y = precode(x,normQ,numTx)
%precode Apply precoding

    [numCarriers, numSym, ~] = size(x);
    xP = permute(x, [1 3 2]); % Permute to Nst-by-Nsts-by-Nsym
    y = complex(zeros(numCarriers, numSym, numTx)); % Initialize output
    if fullFFT(numCarriers)
        % X is full FFT, so extract active subcarriers for spatial mapping
        dataAndPilotIdx = getDataAndPilotIndices(numCarriers);
        for isym = 1:numSym
            y(dataAndPilotIdx, isym, :) = xP(dataAndPilotIdx, :, isym) * normQ;
        end
    else
        for isym = 1:numSym
            y(:, isym, :) = xP(:, :, isym) * normQ;
        end
    end
end

function f = fullFFT(numCarriers)
%fullFFT returns true X is a full FFT grid
    f = any(numCarriers == [32 64 128 256 512]);
end

function dataAndPilotIdx = getDataAndPilotIndices(numCarriers)
%getDataAndPilotIndices Get data and pilot indices

    % numCarriers is the full FFT size
    FFTLen = numCarriers;
    DCOffset = FFTLen/2 + 1;
    switch FFTLen
      case 32
        nullIndices = [1:3 DCOffset FFTLen-1:FFTLen]; % S1G 1 MHz mode
      case 64
        nullIndices = [1:4 DCOffset FFTLen-2:FFTLen];
      case 512
        nullIndices = [1:6 DCOffset + [-129:-127 -5:5 127:129] FFTLen-4:FFTLen];
      otherwise % 128, 256
        nullIndices = [1:6 DCOffset + (-1:1) FFTLen-4:FFTLen];
    end
    dataAndPilotIdx = setdiff(1:FFTLen, nullIndices);
end