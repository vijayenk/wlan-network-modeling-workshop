function [y, CSI] = equalize(x, chanEst, eqMethod, varargin)
%equalize Perform MIMO channel equalization.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y, CSI] = equalize(X, CHANEST, 'ZF') performs equalization using the
%   signal input X and the channel estimation input CHANEST, and returns
%   the estimation of transmitted signal in Y and the soft channel state
%   information in CSI. The zero-forcing (ZF) method is used. The inputs X
%   and CHANEST can be single or double precision 2-D matrices or 3-D
%   arrays with real or complex values. X is of size Nsd x Nsym x Nr, where
%   Nsd represents the number of data subcarriers (frequency domain), Nsym
%   represents the number of OFDM symbols (time domain), and Nr represents
%   the number of receive antennas (spatial domain). CHANEST is of size Nsd
%   x Nsts x Nr, where Nsts represents the number of space-time streams.
%   The single or double precision output Y is of size Nsd x Nsym x Nsts. Y
%   is complex when either X or CHANEST is complex and is real otherwise.
%   The single or double precision, real output CSI is of size Nsd x Nsts.
%
%   [Y, CSI] = equalize(X, CHANEST, 'MMSE', NOISEVAR) performs the
%   equalization using the minimum-mean-square-error (MMSE) method. The
%   noise variance input NOISEVAR is a single or double precision, real,
%   nonnegative scalar.
%
%   See also stbcCombine.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen
narginchk(3,4)
if strcmpi(eqMethod, 'MMSE')
    narginchk(4,4);
    noiseVarEst = varargin{1};
    algorithm = 0;
else % ZF
    assert(strcmpi(eqMethod,'ZF'))
    noiseVarEst = cast(0,class(x)); % For codegen
    algorithm = 1;
end
[y, CSI] = comm.internal.ofdm.equalizeCore3D(x, chanEst, noiseVarEst, algorithm);

end