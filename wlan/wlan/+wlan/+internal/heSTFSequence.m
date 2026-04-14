function [HESSequence,HESIndex] = heSTFSequence(cbw)
%heSTFSequence HE-STF sequence and subcarrier indices of HE MU and HE SU
%packet format
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [HESSEQUENCE,HESINDEX] = heSTFSequence(CBW) returns HE-STF sequence and
%   subcarrier indices of HE MU and HE SU packet for the given channel
%   bandwidth as defined in IEEE Std 802.11ax-2021, Section 27.3.11.9.
%
%   CBW is the channel bandwidth in MHz and must be 20, 40, 80, 160, or
%   320.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

M = wlan.internal.heSTFMSequence; % M sequence of HE-STF field
switch cbw
    case 20
        HESSequence = M*(1+1i)/sqrt(2); % IEEE Std 802.11ax-2021, Equation 27-23
        HESSequence(8) = 0; % Set HES 0 = 0;
        HESIndex = (-112:16:112).';
    case 40
        HESSequence = [M; 0; -M]*(1+1i)/sqrt(2); % IEEE Std 802.11ax-2021, Equation 27-24
        HESIndex = (-240:16:240).';
    case 80
        HESSequence = [M; 1; -M; 0; -M; 1; -M]*(1+1i)/sqrt(2); % IEEE Std 802.11ax-2021, Equation 27-25
        HESIndex = (-496:16:496).';
    case 160
        HESSequence = [M; 1; -M; 0; -M; 1; -M; 0; -M; -1; M; 0; -M; 1; -M]*(1+1i)/sqrt(2); % IEEE Std 802.11ax-2021, Equation 27-26
        HESIndex = (-1008:16:1008).';
    otherwise % 320 MHz
        HESSequence = [M; 1; -M; 0; -M; 1; -M; 0; M; 1; -M; 0; -M; 1; -M; 0; ...
                      -M; -1; M; 0; M; -1; M; 0; -M; -1; M; 0; M; -1; M]*(1+1i)/sqrt(2);
        HESIndex = (-2032:16:2032).'; % IEEE P802.11be/D2.0, Equation 36-29
end