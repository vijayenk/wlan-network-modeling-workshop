function y = crcGenerate(x,numBits)  
%crcGenerate Generate CRC checksum
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = crcGenerate(X) generates CRC checksum for an input message X as per
%   IEEE Std 802.11-2020 Section 19.3.9.4.4. X is an binary column vector
%   containing the message bits. Y is an int8 column vector of length 8
%   containing the checksum.
%
%   Y = crcGenerate(X,NUMBITS) generates CRC checksum with a specified
%   number of bits. When NUMBITS is 4, the CRC is generated as described in
%   IEEE P802.11-REVme/D6.0 Section 24.3.8.2.1.5. When NUMBITS is 16, the
%   CRC is generated as described in IEEE 802.11-2020 Section 20.3.7.
%   Otherwise, the CRC is generated as described in IEEE 802.11-2020
%   Section 19.3.9.4.4. Y is an int8 column vector of length NUMBITS
%   containing the checksum.
%
%   % Example 1: Generate the CRC for the HT-SIG field according to IEEE
%   % Std 802.11-2020 Section 19.3.9.4.4.
%
%     m = [1 1 1 1 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 0 0 0 0 0].';
%     y = wlan.internal.crcGenerate(m);
%
%   % Example 2: Generate the CRC for the S1G-SIG field according to IEEE
%   % IEEE P802.11-REVme/D6.0 Section 24.3.8.2.1.5.
%
%     m = [1 1 1 1 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 0 0 0 0 0].';
%     numBits = 4;
%     y = wlan.internal.crcGenerate(m,numBits);
%
%   See also wlan.internal.crcDetect.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

arguments
    x (:,1)
    numBits = 8
end

% CRC configuration
crc = wlan.internal.getCRCConfig(numBits);

% Codeword
cw = crcGenerate(x,crc);

% Checksum
y = cw(end-numBits+1:end);

end