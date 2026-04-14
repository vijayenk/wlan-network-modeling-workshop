function [bits,failCRC] = wlanUSIGBitRecover(x,nVar,csi)
%wlanUSIGBitRecover Recover information bits in EHT U-SIG field
%
%   [BITS,FAILCRC] = wlanUSIGBitRecover(X,NVAR) recovers the information
%   bits given the demodulated EHT U-SIG field and the noise variance
%   estimate.
%
%   BITS is an int8 matrix of size 52-by-L containing the recovered
%   information bits in the U-SIG field, where L is the number of 80 MHz
%   subblocks:
%   - L is 1 for 20 MHz, 40 MHz and 80 MHz
%   - L is 2 for 160 MHz
%   - L is 4 for 320 MHz
%
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar of
%   size 1-by-L.
%
%   X is a 52*L-by-2 array containing the demodulated U-SIG symbols.
%
%   NVAR is the noise variance estimate. It is a real nonnegative scalar.
%
%   BITS = wlanUSIGBitRecover(...,CSI) uses the channel state information
%   to enhance the demapping of OFDM subcarriers. CSI is a 52*L-by-1 column
%   vector of real values.

%   Copyright 2023-2025 The MathWorks, Inc.

%#codegen

    arguments
        x {mustBeFloat,mustBeFinite}
        nVar {mustBeFloat,mustBeFinite,mustBeNonnegative,mustBeNonempty}
        csi {mustBeFloat,mustBeFinite} = ones(size(x,1),1);
    end

    % Validate input
    [nsd,nSym] = size(x);
    coder.internal.errorIf(~any(nsd==[52 104 208]),'wlan:wlanUSIGBitRecover:IncorrectSC');
    coder.internal.errorIf(nSym~=2,'wlan:wlanUSIGBitRecover:InvalidNumSymbols');
    coder.internal.errorIf(any(size(csi)~=[nsd 1]),'wlan:he:InvalidCSISize',nsd,1);

    numBPSCS = 1; % Number of coded bits per subcarrier per spatial stream, 1 for BPSK
    numCBPSSI = 52; % Number of coded bits per OFDM symbol per spatial stream per interleaver block
    dcm = false; % No DCM in U-SIG field
    L = max(1,nsd/52); % Number of 80 MHz subblocks
    bits = coder.nullcopy(zeros(52,L,'int8'));
    failCRC = coder.nullcopy(false(1,L));
    for l=1:L % Process 80 MHz subblock
        demapped = wlanConstellationDemap(x((1:52)+(l-1)*52,:),nVar,numBPSCS);

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
end
