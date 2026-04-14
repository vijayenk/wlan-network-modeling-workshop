function [y, err] = crcDetect(x,numBits)
%crcDetect Detect errors in CRC checksum
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [Y,ERR] = crcDetect(X) checks CRC checksum of an input message X with
%   CRC generated as per IEEE 802.11-2020 Section 19.3.9.4.4. X is a binary
%   column vector containing the message bits and the CRC checksum. The
%   number of elements must be at least the number of checksum bits. Y is a
%   binary column vector containing the message bits. ERR is true if there
%   is an error in the CRC checksum of the input X. It is a logical scalar.
%
%   [Y, ERR] = crcDetect(X,NUMBITS) checks CRC checksum with a specified
%   number of bits. When NUMBITS is 4, the CRC is assumed to be generated
%   as per IEEE P802.11-REVme/D6.0 Section 24.3.8.2.1.5. When NUMBITS is
%   16, the CRC is assumed to be generated as per IEEE 802.11-2020 Section
%   20.3.7. Otherwise, an 8-bit CRC is assumed to be generated as per IEEE
%   802.11-2020 Section 19.3.9.4.4.
%
%   % Example 1: Check the CRC checksum for the HT-SIG field according to
%   % IEEE Std 802.11-2020 Section 19.3.9.4.4.
%
%     m = [1 1 1 1 0 0 0 1 0 0 1 0 0 1 0 0 1 1 0 0 0 1 1 1 0 1 0 1].';
%     [y, err] = wlan.internal.crcDetect(m);
%
%   See also wlan.internal.crcGenerate.

%   Copyright 2015-2025 The MathWorks, Inc.

%#codegen

arguments
    x
    numBits = 8
end

% CRC configuration
crc = wlan.internal.getCRCConfig(numBits);

% Message and error status
[y,err] = crcDetect(x,crc);
err = logical(err); % crcDetect output err matches type of x

end