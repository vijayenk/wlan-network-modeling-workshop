function out = cyclicShift(in, cSh, Nfft, varargin)
%cyclicShift Cyclic shift delay insertion in frequency domain
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OUT = cyclicShift(IN, CSH, NFFT) performs cyclic shift delay insertion
%   to all subcarriers in the frequency domain signal IN.
%
%   OUT is an Nst-by-Nsym-by-Nsts array containing the cyclic shifted
%   input. Nst is the number of subcarriers, Nsym is the number of OFDM
%   symbols, and Nsts is the number of space-time streams.
%
%   IN is an Nst-by-Nsym-by-Nsts array to cyclic shift.
%
%   CSH is a column vector of length Nsts containing the cyclic shift in
%   samples to apply to each space-time stream. Note to remove the cyclic
%   shift, negate the cyclic shift.
%
%   NFFT is the length of the FFT.
%
%   OUT = cyclicShift(..., INDICES) performs cyclic shift delay
%   insertion in the subcarrier locations specified in INDICES.
%
%   INDICES is a column vector of length Nst containing the subcarrier
%   index for each element of IN. The range of indices is -Nsr/2:Nsr/2-1,
%   where Nsr is the maximum subcarrier index.
%
%   See also getCyclicShiftVal.

%   Copyright 2015-2021 The MathWorks, Inc.

%#codegen

assert(ndims(in)<4)
[numST,numSym,numSTS] = size(in);

if nargin>3
    k = varargin{1};
else
    k = (1:Nfft).'-Nfft/2-1;
end
assert(iscolumn(k));
assert(size(k,1)==numST);
assert(iscolumn(cSh));
assert(size(cSh,1)==numSTS);

% Apply cyclic shift to each space-time stream
if coder.target('MATLAB')
    % MATLAB path
    phaseShift = exp(-1i*2*pi*permute(cSh,[2 3 1]).*k/Nfft);
    out = in .* phaseShift;
else
    % Codegen path
    out = coder.nullcopy(complex(zeros(size(in))));
    for i = 1:numSTS
        phaseShift = exp(-1i*2*pi*cSh(i).*k/Nfft);
        for j = 1:numSym
            out(:,j,i) = in(:,j,i).*phaseShift;
        end
    end
end

end
