function crc = getCRCConfig(numBits)
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   CRC = getCRCConfig(NUMBITS) creates a cyclic redundancy check (CRC)
%   coding configuration using a specified number of bits, NUMBITS, which
%   can be either 4, 8, or 16.
%
%   When NUMBITS is 4, CRC is defined as per IEEE P802.11-REVme/D6.0
%   Section 24.3.8.2.1.5. When NUMBITS is 8, CRC is defined as per IEEE
%   IEEE Std 802.11-2020 Section 19.3.9.4.4. When NUMBITS is 16, CRC is
%   defined as per IEEE Std 802.11-2020 Section 20.3.7.
%

%   Copyright 2025 The MathWorks, Inc.

%#codegen

persistent crc4 crc8 crc16

if isempty(crc4) % Assume other configs are empty if any one is
    crc4 = crcConfig(Polynomial=[4 1 0],InitialConditions=1,DirectMethod=true,FinalXOR=1);      % Section 24.3.8.2.1.5 IEEE P802.11-REVme/D6.0
    crc8 = crcConfig(Polynomial=[8 2 1 0],InitialConditions=1,DirectMethod=true,FinalXOR=1);    % Section 19.3.9.4.4 IEEE Std 802.11-2020
    crc16 = crcConfig(Polynomial=[16 12 5 0],InitialConditions=1,DirectMethod=true,FinalXOR=1); % Section 20.3.7 IEEE Std 802.11-2020
end

switch numBits
    case 4
        crc = crc4;
    case 8
        crc = crc8;
    otherwise % 16
        assert(numBits==16, 'numBits must be either 4, 8, or 16')
        crc = crc16;
end

end
