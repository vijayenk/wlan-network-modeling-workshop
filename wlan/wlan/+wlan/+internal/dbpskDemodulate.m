function y = dbpskDemodulate(x,noiseVarEst)
% dbpskDemodulate Soft demodulates the DBPSK modulated signal
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = dbpskDemodulate(X,NOISEVAREST) performs DBPSK soft demodulation of
%   the symbols given the noise variance NOISEVAREST. The soft demodulation
%   uses the Gaussian Metric algorithm [1].
%
%   [1] H. Tatsunami, K. Ishibashi, and H. Ochiai, “On the Performance of
%   LDPC Codes with Differential Detection over Rayleigh Fading Channels”,
%   Vehicular Tech. Conf., 2006, IEEE 63rd Volume 5, 2006 Page(s):2388 -
%   2392.

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen

% Clip noiseVar to allowable value to avoid divide by zero warnings
minNoiseVar = 1e-10;
if noiseVarEst < minNoiseVar
    noiseVarEst = minNoiseVar;
end
E = var(x)-noiseVarEst;
x = [0;x]; % Append zero due for differential demodulation
N = E*noiseVarEst + (noiseVarEst/2)^2;
y = zeros(length(x)-1,1);

for i=1:length(x)-1
    y(i) = 2*E*(real(x(i)'.* x(i+1)))/N;
end

% For differential encoding proposes d(-1) is defined to be 1, as
% per IEEE Std 802.11ad 2012 Sections 21.4.3.3.4. The output of the
% soft demapper is multiplied by -1.
y = y*-1;

end