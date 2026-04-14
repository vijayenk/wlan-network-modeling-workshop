function [activeSubCarriers,testSC,fftLength] = spectralFlatnessTestParams(format,cbw)
%spectralFlatnessTestParams Parameters for estimating spectral flatness
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%  [ACTIVESUBCARRIERS,TESTSC,FFTLENGTH] =
%  spectralFlatnessTestParams(FORMAT,CBW) outputs the parameters required for
%  estimating the spectral flatness for a given format, FORMAT, and channel
%  bandwidth, CBW.
%
%  ACTIVESUBCARRIERS specifies the active subcarrier indices. TESTSC
%  specifies the lower and upper subcarrier indices used for spectral
%  flatness test. FFTLENGTH specifies the FFT length.

%   Copyright 2025 The MathWorks, Inc.

%#codegen

testSC = cell(1,2);

switch format
    case 'Non-HT'
        % Error on partial matches
        cbw = wlan.internal.validateParam('NONHTEHTCHANBW', cbw);
        [fftLength,numSubchannels] = wlan.internal.cbw2nfft(cbw);
        activeSubCarriers = wlan.internal.nonHTToneIndices(numSubchannels);
        switch cbw
            case {'CBW5','CBW10','CBW20'}
                % Section 20.3.20.2 of IEEE Std 802.11-2012.
                lowTestSC = [-16:-1 1:16];
                uppTestSC = [-26:-17 17:26];
            case 'CBW40'
                lowTestSC = [-42:-33 -31:-6 6:31 33:42];
                uppTestSC = [-58:-43 43:58];
            case 'CBW80'
                % Table 22-23 of IEEE Std 802.11ac-2013.
                lowTestSC = [-84:-70 -58:-33 -31:-6 6:31 33:58 70:84];
                uppTestSC = [-122:-97 -95:-85 85:95 97:122];
            case 'CBW160'
                lowTestSC = [-172:-161 -159:-134 -122:-97 -95:-70 -58:-44 44:58 70:95 97:122 134:159 161:172];
                uppTestSC = [-250:-225 -223:-198 -186:-173 -43:-33 -31:-6 6:31 33:43 173:186 198:223 225:250];
            otherwise % 'CBW320'
                lowTestSC = [-348:-326 -314:-300 -212:-198 -186:-161 -159:-134 -122:-97 -95:-84 84:95 97:122 134:159 161:186 198:212 300:314 326:348];
                uppTestSC = [-506:-481 -479:-454 -442:-417 -415:-390 -378:-353 -351:-349 -299:-289 -287:-262 -250:-225 -223:-213 -83:-70 -58:-33 -31:-6 ...
                    6:31 33:58 70:83 213:223 225:250 262:287 289:299 349:351 353:378 390:415 417:442 454:479 481:506];
        end
    case 'HT'
        cbw = wlan.internal.validateParam('HTCHANBW', cbw);
        switch cbw
            case 'CBW20'
                % Section 20.3.20.2 of IEEE Std 802.11-2012.
                fftLength = 64;
                activeSubCarriers = [-28:-1 1:28];
                lowTestSC = [-16:-1 1:16];
                uppTestSC = [-28:-17 17:28];
            otherwise % 'CBW40'
                fftLength = 128;
                activeSubCarriers = [-58:-2 2:58];
                lowTestSC = [-42:-2 2:42];
                uppTestSC = [-58:-43 43:58];
        end
    case 'VHT'
        cbw = wlan.internal.validateParam('CHANBW', cbw);
        switch cbw
            case 'CBW20'
                % Table 22-23 of IEEE Std 802.11ac-2013.
                fftLength = 64;
                activeSubCarriers = [-28:-1 1:28];
                lowTestSC = [-16:-1 1:16];
                uppTestSC = [-28:-17 17:28];
            case 'CBW40'
                fftLength = 128;
                activeSubCarriers = [-58:-2 2:58];
                lowTestSC = [-42:-2 2:42];
                uppTestSC = [-58:-43 43:58];
            case 'CBW80'
                fftLength = 256;
                activeSubCarriers = [-122:-2 2:122];
                lowTestSC = [-84:-2 2:84];
                uppTestSC = [-122:-85 85:122];
            otherwise % 'CBW160'
                fftLength = 512;
                activeSubCarriers = [-250:-130 -126:-6 6:126 130:250];
                lowTestSC = [-172:-130 -126:-44 44:126 130:172];
                uppTestSC = [-250:-173 -43:-6 6:43 173:250];
        end
    case 'S1G'
        cbw = wlan.internal.validateParam('S1GCHANBW', cbw);
        switch cbw
            case 'CBW1'
                % Table 23-29 of IEEE Std 802.11ah-2016.
                fftLength = 32;
                activeSubCarriers = [-13:-1 1:13];
                lowTestSC = [-8:-1 1:8];
                uppTestSC = [-13:-9 9:13];
            case 'CBW2'
                fftLength = 64;
                activeSubCarriers = [-28:-1 1:28];
                lowTestSC = [-16:-1 1:16];
                uppTestSC = [-28:-17 17:28];
            case 'CBW4'
                fftLength = 128;
                activeSubCarriers = [-58:-2 2:58];
                lowTestSC = [-42:-2 2:42];
                uppTestSC = [-58:-43 43:58];
            case 'CBW8'
                fftLength = 256;
                activeSubCarriers = [-122:-2 2:122];
                lowTestSC = [-84:-2 2:84];
                uppTestSC = [-122:-85 85:122];
            otherwise % 'CBW16'
                fftLength = 512;
                activeSubCarriers = [-250:-130 -126:-6 6:126 130:250];
                lowTestSC = [-172:-130 -126:-44 44:126 130:172];
                uppTestSC = [-250:-173 -43:-6 6:43 173:250];
        end
    case 'HE'
        cbw = wlan.internal.validateParam('CHANBW', cbw);
        switch cbw
            case 'CBW20'
                % Table 27-9 of IEEE Std 802.11ax-2021.
                activeSubCarriers = [-122:-2 2:122];
                fftLength = 256;
                % Table 27-48 of IEEE Std 802.11ax-2021.
                lowTestSC = [-84:-2 2:84];
                uppTestSC = [-122:-85 85:122];
            case 'CBW40'
                activeSubCarriers = [-244:-3 3:244];
                fftLength = 512;
                lowTestSC = [-168:-3 3:168];
                uppTestSC = [-244:-169 169:244];
            case 'CBW80'
                activeSubCarriers = [-500:-3 3:500];
                fftLength = 1024;
                lowTestSC = [-344:-3 3:344];
                uppTestSC = [-500:-345 345:500];
            otherwise % 'CBW160'
                activeSubCarriers = [-1012:-515 -509:-12 12:509 515:1012];
                fftLength = 2048;
                lowTestSC = [-696:-515 -509:-166 166:509 515:696];
                uppTestSC = [-1012:-697 -165:-12 12:165 697:1012];
        end
    otherwise % EHT
        cbw = wlan.internal.validateParam('EHTCHANBW', cbw);
        switch cbw
            case 'CBW20'
                % Table 27-7 of IEEE Std 802.11ax-2021.
                activeSubCarriers = [-122:-2 2:122];
                fftLength = 256;
                lowTestSC = [-84:-2 2:84];
                uppTestSC = [-122:-85 85:122];
            case 'CBW40'
                activeSubCarriers = [-244:-3 3:244];
                fftLength = 512;
                lowTestSC = [-168:-3 3:168];
                uppTestSC = [-244:-169 169:244];
            case 'CBW80'
                activeSubCarriers = [-500:-3 3:500];
                fftLength = 1024;
                lowTestSC = [-344:-3 3:344];
                uppTestSC = [-500:-345 345:500];
            case 'CBW160'
                activeSubCarriers = [-1012:-515 -509:-12 12:509 515:1012];
                fftLength = 2048;
                lowTestSC = [-696:-515 -509:-12 12:509 515:696];
                uppTestSC = [-1012:-697 697:1012];
            otherwise % 'CBW320'
                activeSubCarriers = [-2036:-1539 -1533:-1036 -1012:-515 -509:-12 12:509 515:1012 1036:1533 1539:2036];
                fftLength = 4096;
                lowTestSC =  [-1400:-1036 -1012:-515 -509:-12 12:509 515:1012 1036:1400];
                uppTestSC = [-2036:-1539 -1533:-1401 1401:1533 1539:2036];
        end
end
testSC{1} = lowTestSC.';
testSC{2} = uppTestSC.';
activeSubCarriers = activeSubCarriers.';

end