function [HESSequence,HESIndex] = heTBSTFSequence(cbw)
%heTBSTFSequence HE-STF sequence and subcarrier indices of HE TB packet
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [HESSEQUENCE,HESINDEX] = heTBSTFSequence(CBW) returns HE-STF sequence
%   and subcarrier indices of HE TB packet for the given channel bandwidth
%   as defined in IEEE Std 802.11ax-2021, Section 27.3.11.9.
%
%   CBW is the channel bandwidth in MHz and must be 20, 40, 80, 160, or
%   320.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

M = wlan.internal.heSTFMSequence; % M sequence of HE-STF field
switch cbw
    case 20
        HESSequence = [M; 0; -M]*(1+1i)/sqrt(2); % Equation 27-28
        HESIndex = (-120:8:120).'; % Equation 27-29
    case 40
        HESSequence = [M; -1; -M; 0; M; -1; M]*(1+1i)/sqrt(2); % Equation 27-30
        HESSequence(1) = 0; % Set HES -248 = 0;
        HESSequence(end) = 0; % Set HES +248 = 0;
        HESIndex = (-248:8:248).';
    case 80
        HESSequence = [M; -1; M; -1; -M; -1; M; 0; -M; 1; M; 1; -M; 1; -M]*(1+1i)/sqrt(2); % Equation 27-32
        HESSequence(1) = 0; % Set HES -504 = 0;
        HESSequence(end) = 0; % Set HES +504 = 0;
        HESIndex = (-504:8:504).';
    case 160
        HESSequence = [M; -1; M; -1; -M; -1; M; 0; -M; 1; M; 1; -M; 1; -M; 0; ... % Equation 27-34
            -M; 1; -M; 1; M; 1; -M; 0; -M; 1; M; 1; -M; 1; -M]*(1+1i)/sqrt(2);
        HESSequence(127) = 0; % Set HES -8 = 0;
        HESSequence(129) = 0; % Set HES +8 = 0;
        HESSequence(1) = 0;   % Set HES -1016 = 0;
        HESSequence(end) = 0; % Set HES +1016 = 0;
        HESIndex = (-1016:8:1016).';
    otherwise % 320 MHz
        HESSequence = [M; -1; M; -1; -M; -1; M; 0; -M; 1; M; 1; -M; 1; -M; 0; M; -1; M; -1; -M; -1; ... % IEEE P802.11be/D2.0, May 2022, Equation 36-34
            M; 0; -M; 1; M; 1; -M; 1; -M; 0; -M; 1; -M; 1; M; 1; -M; 0; M; -1; -M; -1; ...
            M; -1; M; 0; -M; 1; -M; 1; M; 1; -M; 0; M; -1; -M; -1; M; -1; M]*(1+1i)/sqrt(2);
        HESSequence(255) = 0; % Set HES -8 = 0;
        HESSequence(257) = 0; % Set HES +8 = 0;
        HESSequence(129) = 0; % Set HES -1016 = 0;
        HESSequence(383) = 0; % Set HES +1016 = 0;
        HESSequence(127) = 0; % Set HES -1032 = 0;
        HESSequence(385) = 0; % Set HES +1032 = 0;
        HESSequence(1) = 0;   % Set HES -2040 = 0;
        HESSequence(end) = 0; % Set HES +2040 = 0;
        HESIndex = (-2040:8:2040).';
end