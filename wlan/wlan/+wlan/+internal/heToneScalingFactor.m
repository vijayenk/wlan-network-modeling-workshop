function NToneField = heToneScalingFactor(field,chanBW,varargin)
%heToneScalingFactor Tone scaling factor for pre HE and EHT fields
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   N = heToneScalingFactor(FIELD,CHANBW) returns a the tone scaling
%   factor.
%
%   FIELD must be one of:
%     L-STF, L-LTF, L-SIG, RL-SIG, HE-SIG-A, HE-SIG-B, 'U-SIG', 'EHT-SIG'
%
%   CHANBW is the channel bandwidth and must be 20, 40, 80, 160, or 320.

%   Copyright 2017-2022 The MathWorks, Inc.

%#codegen

% IEEE Std 802.11ax-2021, Table 27-16 -Number of modulated subcarriers and
% guard interval duration values for HE PPDU fields
% IEEE P802.11be/D1.5, Table 36-26 - Number of modulated subcarriers and
% guard interval duration values for EHT PPDU fields

assert(any(chanBW==[20 40 80 160 320]));
switch field
    case 'L-STF'
        switch chanBW
            case 20
                NToneField = 12;
            case 40
                NToneField = 24;
            case 80
                NToneField = 48;
            case 160
                NToneField = 96;
            otherwise % 320 MHz
                NToneField = 192;
        end
    case 'L-LTF'
        switch chanBW
            case 20
                NToneField = 52;
            case 40
                NToneField = 104;
            case 80
                NToneField = 208;
            case 160
                NToneField = 416;
            otherwise % 320 MHz
                NToneField = 832;
        end
    otherwise % {'L-SIG','RL-SIG','HE-SIG-A','HE-SIG-B','U-SIG','EHT-SIG'}
        switch chanBW
            case 20
                NToneField = 56;
            case 40
                NToneField = 112;
            case 80
                NToneField = 224;
            case 160
                NToneField = 448;
            otherwise % 320 MHz
                NToneField = 896;
        end
end