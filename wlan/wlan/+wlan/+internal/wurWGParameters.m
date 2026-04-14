function [k, Nfft, Ncp, useIdx] = wurWGParameters(dataRate,chanBW,osf)
%wurWGParameters WUR waveform generation parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [K, NFFT, NCP, USEIDX] = wurWGParameters(DATARATE,CHANBW,OSF) returns
%   the subcarrier index, the length of FFT, the length of cyclic prefix,
%   and the corresponding use index for the WUR waveform generations.
%
%   K is a vector represents the subcarrier indices after applying the 
%   frequency offsets.
%
%   NFFT is a scalar, which represents the length of FFT.
%
%   NCP is a scalar, which represents the length of cyclic prefix.
%
%   USEIDX is a vector of indices to extract when performing OFDM
%   modulation.
%
%   DATARATE specifies the transmission rate as character vector or string 
%   and must be 'LDR', or 'HDR'.
%
%   CHANBW is a character specifies the bandwidth of WUR PPDUs and must be
%   'CBW20', 'CBW40', or 'CBW80'.
%
%   OSF is the oversampling factor.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

coder.varsize('k',[4 12],[1 1]); % For codegen

switch chanBW
    case 'CBW20' 
        Nfft = 64;
        if strcmp(dataRate,'HDR')
            % IEEE P802.11ba/D8.0, December 2020, Section 30.3.4.1.
            k = [-6 -4 -2 2 4 6];
            Ncp = 8;
            useIdx = 1:32*osf;
        else
            % IEEE P802.11ba/D8.0, December 2020, Section 30.3.4.2.
            k = [-6:-1 1:6];
            Ncp = 16;
            useIdx = 1:64*osf;
        end
    case 'CBW40'
        Nfft = 128;
        if strcmp(dataRate,'HDR')
            k = [-6 -4 -2 2 4 6];
            Ncp = 16;
            useIdx = 1:64*osf;
        else
            k = [-6:-1 1:6];
            Ncp = 32;
            useIdx = 1:128*osf;
        end
        k = k + [0 64].' - 32; % Frequency offsets. See wlan.internal.nonHTToneIndices.
    otherwise % case 'CBW80'
        Nfft = 256;
        if strcmp(dataRate,'HDR')
            k = [-6 -4 -2 2 4 6];
            Ncp = 32;
            useIdx = 1:128*osf;
        else
            k = [-6:-1 1:6];
            Ncp = 64;
            useIdx = 1:256*osf;
        end
        k = k + (0:64:192).' - (64+32); % Frequency offsets. See wlan.internal.nonHTToneIndices.
end

if osf>1
    wlan.internal.validateOFDMOSF(osf,Nfft,Ncp);
end
Nfft = Nfft*osf;
Ncp = Ncp*osf;

end
