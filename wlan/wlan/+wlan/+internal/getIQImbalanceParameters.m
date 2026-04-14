function [alpha, beta] = getIQImbalanceParameters(iqImbalance)
%getIQImbalanceParameters Compute alpha and beta values from IQ gain and
%phase imbalance values.
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.

%   Reference:
%   [1] M. Janaswamy, N. K. Chavali and S. Batabyal, "Measurement of
%   transmitter IQ parameters in HT and VHT wireless LAN systems," 2016
%   International Conference on Signal Processing and Communications
%   (SPCOM), Bangalore.

%   Copyright 2025 The MathWorks, Inc.

iqGaindB = iqImbalance(1);
iqPhaseDeg = iqImbalance(2);
alpha = (1+db2mag(-iqGaindB)*exp(1i*iqPhaseDeg*pi/180))/2; % As specified in Equation-4 of [1]
beta = 1-alpha;

end