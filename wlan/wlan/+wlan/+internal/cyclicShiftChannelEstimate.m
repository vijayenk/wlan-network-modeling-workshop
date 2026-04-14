function out = cyclicShiftChannelEstimate(in,cSh,Nfft,varargin)
%cyclicShiftChannelEstimate Channel estimate cyclic shift delay insertion in frequency domain
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   OUT = cyclicShiftChannelEstimate(IN,CSH,NFFT) performs cyclic shift
%   delay insertion to all subcarriers in the frequency domain signal IN.
%
%   OUT is an Nst-by-by-Nsts-by-Nr array containing the cyclic shifted
%   channel estimate. Nst is the number of subcarriers, Nsts is the number
%   of space-time streams, and Nr is the number of receive antennas.
%
%   IN is an Nst-by-Nsts-by-Nr array to cyclic shift.
%
%   CSH is a column vector of length Nsts containing the cyclic shift in
%   samples to apply to each space-time stream. Note to remove the cyclic
%   shift, negate the cyclic shift.
%
%   NFFT is the length of the FFT.
%
%   OUT = cyclicShiftChannelEstimate(...,INDICES) performs cyclic shift delay
%   insertion in the subcarrier locations specified in INDICES.
%
%   INDICES is a column vector of length Nst containing the subcarrier
%   index for each element of IN. The range of indices is -Nsr/2:Nsr/2-1,
%   where Nsr is the maximum subcarrier index.
%
%   See also getCyclicShiftVal.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

assert(ndims(in)<4)
[numST,numSTS,numRx] = size(in);

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
    phaseShift = exp(-1i*2*pi*cSh.'.*k/Nfft);
    out = in .* phaseShift;
else
    % Codegen path
    out = coder.nullcopy(zeros(size(in),'like',in));
    for i = 1:numSTS
        phaseShift = exp(-1i*2*pi*cSh(i).*k/Nfft);
        for j = 1:numRx
            out(:,i,j) = in(:,i,j).*phaseShift;
        end
    end
end

end
