function [bits,failCRC] = wlanHESIGABitRecover(rx,noiseVarEst,varargin)
%wlanHESIGABitRecover Recover information bits in HE-SIG-A field
% 
%   [BITS,FAILCRC] = wlanHESIGABitRecover(RX,NOISEVAREST) recovers the
%   information bits given the HE-SIG-A field, and the noise variance
%   estimate.
%
%   BITS is an int8 column vector of length 52 containing the recovered
%   information bits in HE-SIG-A field.
% 
%   FAILCRC is true if BITS fails the CRC check. It is a logical scalar. 
%
%   RX are the single or double complex demodulated HE-SIG-A symbols of
%   size 52-by-N, where N is the number of OFDM symbols in HE-SIG-A field.
%   N is 2 for HE-SU and HE-MU packet format. N is 4 for HE-EXT-SU packet.
%
%   NOISEVAREST is the single or double noise variance estimate. It is a
%   real nonnegative scalar.
%   
%   BITS = wlanHESIGABitRecover(...,CSI) uses the channel state information
%   to enhance the demapping of OFDM subcarriers. CSI is a 52-by-1 column
%   vector of real values of type single or double.

%   Copyright 2018-2025 The MathWorks, Inc.

%#codegen

narginchk(2,3);

% Validate input
[numSubcarriers,numSym] = size(rx);

if numSubcarriers==0
    % Return empty for 0 samples
    bits = zeros(0,1,'int8');
    failCRC = false(0,1);
    return;
end

% Validate input
validateattributes(rx,{'single','double'},{'2d','finite','nrows',52},mfilename,'rx');
coder.internal.errorIf(~any(numSym==[2 4]),'wlan:wlanHESIGABitRecover:InvalidNumSymbols');

validateattributes(noiseVarEst,{'single','double'},{'real','scalar','nonnegative','finite'},'noiseVarEst','noise variance estimate'); 
if nargin>2
    dataCSI = varargin{1};
    validateattributes(dataCSI,{'single','double'},{'real','column','finite','nrows',52},mfilename,'csi');
else
    dataCSI = ones(52,1,class(rx)); % No CSI
end

numBPSCS = 1;
numCBPSSI = 52;
dcm = false;
    
if numSym==4 % Assume HE-EXT-SU packet format due to 4 OFDM symbols
    % Demap
    demapped = wlanConstellationDemap(rx,noiseVarEst,numBPSCS,[0 pi/2 0 0]);

    % Apply CSI to each OFDM symbol
    demapped = demapped .* dataCSI;

    % Deinterleave symbols 1 and 3
    deinterleaved = wlan.internal.heBCCDeinterleave(reshape(demapped(:,[1 3]),104,1),56,numBPSCS,numCBPSSI,dcm);

    % Combine symbol LLRs
    deinterleaved = deinterleaved+reshape(demapped(:,[2 4]),104,1);
else % Otherwise assume HE-SU, HE-MU or HE-TB packet format
    demapped = wlanConstellationDemap(rx,noiseVarEst,numBPSCS);

    % Apply CSI to each OFDM symbol
    demapped = demapped .* dataCSI;

    % Deinterleave
    deinterleaved = wlan.internal.heBCCDeinterleave(demapped(:),56,numBPSCS,numCBPSSI,dcm);
end

% Decode
bits = wlanBCCDecode(deinterleaved,1/2);
bits = bits(1:52,:);

% Check the CRC
crc = bits(end-9:end-6); % Extract CRC (only 6 tail bits follow CRC)
checksum = wlan.internal.crcGenerate(bits(1:end-10),8);
failCRC = any(checksum(1:4)~=crc);

end

