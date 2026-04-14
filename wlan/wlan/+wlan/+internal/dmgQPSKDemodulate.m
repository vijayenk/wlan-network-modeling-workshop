function y = dmgQPSKDemodulate(x,noiseVarEst,k,pk,varargin)
%dmgQPSKDemodulate Demodulates the QPSK modulated signal
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dmgQPSKDemodulate(SYM,NOISEVAREST,K,PK) performs QPSK demodulation
%   of the input symbol X given the tone pair indices K and PK.
%
%   K and PK are indices used to map tone pairs. They are of size 168-by-1,
%   where 168 is the number of data tones in each half of the OFDM symbol.
%
%   Y = dmgQPSKDemodulate(...,CSI) performs QPSK demodulation of the input
%   symbol X given the additional CSI information. The CSI can only be used
%   for the OFDM PHY.

%   Copyright 2017-2021 The MathWorks, Inc.

%#codegen

narginchk(4,5);
if nargin == 5
    csi = varargin{1};
end

% Use real/imag(k) vs real/imag(pk) and demap as QPSK (rotated)
% Process b0 and b1 from groups of 4 bits
tmpReal = complex(real(x(k+1,:)),real(x(pk+1,:))); % Take real part of pair of subcarriers
tmpRealRot = tmpReal*exp(-1i*(atan(3)-3*pi/4));    % Rotate to form QPSK constellation
b0b1 = wlanConstellationDemap(tmpRealRot,noiseVarEst,2); % QPSK demap to get b0 and b1

% Process b2 and b3 from groups of 4 bits
tmpImag = complex(imag(x(k+1,:)),imag(x(pk+1,:))); % Take quadrature part of pair of subcarriers
tmpImagRot = tmpImag*exp(-1i*(atan(3)-3*pi/4));    % Rotate to form QPSK constellation
b2b3 = wlanConstellationDemap(tmpImagRot,noiseVarEst,2); % QPSK demap to get b2 and b3

% Combine the demapped bits to get b0b1b2b3
numOFDMSym = size(x,2);
b0b1r = reshape(permute(b0b1,[1 3 2]),2,[],numOFDMSym);
b2b3r = reshape(permute(b2b3,[1 3 2]),2,[],numOFDMSym);

if nargin == 5 % Apply CSI 
    % Use k for b0 and b2 scaling and pk for b1 and b3 scaling as these are the dominant components
    b0b1rScale = coder.nullcopy(zeros(2,size(b0b1r,2),numOFDMSym));
    b0b1rScale(1,:,:) = b0b1r(1,:,:) .* csi(pk+1,1).';
    b0b1rScale(2,:,:) = b0b1r(2,:,:) .* csi(k+1,1).';
    b2b3rScale = coder.nullcopy(zeros(2,size(b2b3r,2),numOFDMSym));
    b2b3rScale(1,:,:) = b2b3r(1,:,:) .* csi(pk+1,1).';
    b2b3rScale(2,:,:) = b2b3r(2,:,:) .* csi(k+1,1).';
    comb1scale = [b0b1rScale; b2b3rScale];
else % No CSI
    comb1scale = [b0b1r; b2b3r];
end

y = squeeze(reshape(comb1scale,[],1,numOFDMSym));
end
