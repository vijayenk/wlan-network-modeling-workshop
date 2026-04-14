function [lut,L0] = selectAWGNLUT(format,mcs,coding,dataLength)
%selectAWGNLUT select AWGN lookup table
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [LUT,L0] = selectAWGNLUT(FORMAT,MCS,CODING,DATALENGTH) returns the
%   appropriate AWGN lookup table, LUT, and reference data length L0.
%
%   LUT is a matrix containing the lookup table. Each row is of the form
%   [SNR PER].
%
%   FORMAT is one of 'NonHT', 'HTMixed', 'VHT', 'HE_SU', 'HE_EXT_SU',
%   'HE_MU', 'HE_TB', 'EHT_SU'.
%
%   MCS is the modulation and coding scheme index for the specified format.
%
%   CODING is either 'BCC' or 'LDPC'.
%
%   DATALENGTH is the PSDU length in bytes.
%

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

persistent awgnLUT

if isempty(awgnLUT)
    awgnLUT = coder.load('wlan/internal/phy/l2sm/awgn.mat');
end

[modulation, rate] = wlan.internal.phy.l2sm.mcs2rate(format,mcs);
switch coding
    case 'BCC'
        % As per TGax evaluation methodology, if the number of bytes is
        % <400 then use 32 byte BCC LUT, otherwise use 1458 byte LUT.
        idx = all(awgnLUT.perTable_BCC_MCS==[modulation rate],2);
        assert(any(idx),'Format and MCS is not valid with BCC coding')
        if dataLength < 400
            lut = awgnLUT.perTable_BCC_32(:,:,idx);
            L0 = awgnLUT.L0_BCC_32(idx);
        else
            lut = awgnLUT.perTable_BCC_1458(:,:,idx);
            L0 = awgnLUT.L0_BCC_1458(idx);
        end
    otherwise
        assert(strcmpi(coding,'LDPC'))
        idx = all(awgnLUT.perTable_LDPC_MCS==[modulation rate],2);
        assert(any(idx),'Format and MCS is not valid with LDPC coding')
        lut = awgnLUT.perTable_LDPC(:,:,idx);
        L0 = awgnLUT.L0_LDPC(idx);
end
L0 = L0(1); % For codegen
end
