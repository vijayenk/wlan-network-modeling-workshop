function [bits,failCRC] = ehtUSIGBitRecover(rx,noiseVarEst,csi)
%ehtUSIGBitRecover Recover information bits from EHT U-SIG field
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [BITS,FAILCRC] = ehtUSIGBitRecover(RX,NOISEVAREST,CSI) recovers the
%   information bits given the EHT U-SIG field, the noise variance
%   estimate, and channel state information.
%
%   BITS is an int8 column vector of length 52-by-L containing the
%   recovered information bits in U-SIG field, where L:
%   - L is 1 for 20 MHz, 40 MHz and 80 MHz
%   - L is 2 for 160 MHz
%   - L is 4 for 320 MHz
%
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar of
%   size 1-by-L.
%
%   RX is the single or double complex demodulated U-SIG symbols of size
%   52*L-by-2.
%
%   NOISEVAREST is the noise variance estimate. It is a real nonnegative
%   scalar.
%
%   CSI is a 52*L-by-1 column vector of real values, used to to enhance the
%   demapping of OFDM subcarriers.

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

numSubcarriers = size(rx,1);
L = numSubcarriers/52; % Number of 80 MHz segments
validateattributes(csi,{'single','double'},{'real','column','finite','nrows',52*L},mfilename,'csi');

numBPSCS = 1;
numCBPSSI = 52;
dcm = false;
bits = zeros(52,L,'int8');
failCRC = false(1,L);
for l=1:L % Process 80 MHz segment
    demapped = wlanConstellationDemap(rx((1:52)+(l-1)*52,:),noiseVarEst,numBPSCS);

    % Apply CSI to each OFDM symbol
    demapped = demapped.*csi((1:52)+(l-1)*52,:);

    % Deinterleave
    deinterleaved = wlan.internal.heBCCDeinterleave(demapped(:),56,numBPSCS,numCBPSSI,dcm);

    % Decode
    bits(:,l) = wlanBCCDecode(deinterleaved,1/2);

    % Check the CRC
    crc = bits(end-9:end-6,l); % Extract CRC (only 6 tail bits follow CRC)
    checksum = wlan.internal.crcGenerate(bits(1:end-10,l),8);
    failCRC(l) = any(checksum(1:4)~=crc);
end
