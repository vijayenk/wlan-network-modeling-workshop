function [per,snreff] = estimateLinkPerformance(sinr,len,format,mcs,coding)
%estimateLinkPerformance link performance model
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [PER,SNREFF] = estimateLinkPerformance(SINR,LEN,FORMAT,MCS,CODING)
%   returns the estimated packet error rate and effective SINR.
%
%   SINR is an array containing the SINR for each subcarrier, symbol and
%   spatial stream.
%
%   LEN is the payload length in bytes.
%
%   FORMAT is one of 'NonHT', 'HTMixed', 'VHT', 'HE_SU', 'HE_EXT_SU',
%   'HE_MU', 'HE_TB', 'EHT_SU'.
%
%   MCS is the modulation and coding scheme index and must be 0-11,
%   depending on the format.
%
%   CODING is the channel coding used and must be 'BCC' or 'LDPC'.
%

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

% Calculate the effective SNR
snreff = wlan.internal.phy.l2sm.calculateEffectiveSINR(sinr,format,mcs);

% Estimate the packet error rate for the given SNR and configuration
per = wlan.internal.phy.l2sm.estimatePER(snreff,format,mcs,coding,len);
end
