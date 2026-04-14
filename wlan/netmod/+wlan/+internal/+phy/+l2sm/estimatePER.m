function [per,perPL0,L0,lut] = estimatePER(snreff,format,mcs,coding,len)
%estimatePER Estimate PER
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PER,PERPL0,L0,LUT] = estimatePER(SNREFF,FORMAT,MCS,CODING,LEN)
%   estimates the packet error rate given effecive SINR and parameters. PER
%   is the packet error rate. PERPL0 is the packet error rate for the
%   reference data length. L0 is the reference data length in bytes. LUT is
%   the selected AWGN lookup table.
%
%   SNREFF is the effective SNR.
%
%   FORMAT is one of 'NonHT','HTMixed','VHT','HE_SU','HE_EXT_SU','EHT_SU'.
%
%   MCS is the modulation and coding scheme index for the specified format.
%
%   CODING is either 'BCC' or 'LDPC'.
%
%   LEN is the PSDU length in bytes.
%

%   Copyright 2022-2025 The MathWorks, Inc.

%#codegen

% Select AWGN lookup table
[lut,L0] = wlan.internal.phy.l2sm.selectAWGNLUT(format,mcs,coding,len);

% Given the LUT and effective SNR, interpolate and extrapolate
% to get the SNR
perPL0 = wireless.internal.L2SM.interpolatePER(snreff,lut(:,:,1));

% Calculate final PER, adjusting for packet size as per IEEE
% 11-14-05171-12r0 11ax Evaluation Methodology, Annex 1.
per = 1-(1-perPL0)^(len/L0);
end


