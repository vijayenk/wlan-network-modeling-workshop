function [snreff,scrbir,avrbir] = calculateEffectiveSINR(sinr,format,mcs)
%CalculateEffectiveSINR calculate effective SINR
%
%   Note: This is an internal undocumented function and its API
%   and/or functionality may change in subsequent releases.
%
%   [SNREFF,SCRBIR,AVRBIR] = calculateEffectiveSINR(SINR,FORMAT,MCS)
%   returns the effective SNR, the RBIR per SINR (SCRBIR) and the average
%   RBIR before reverse mapping (AVRBIR).
%
%   SINR is the SINR per subcarrier, symbol and spatial stream.
%
%   FORMAT is one of 'NonHT','HTMixed','VHT','HE_SU','HE_EXT_SU', 'EHT_SU'.
%
%   MCS is the modulation and coding scheme index for the specified format.
%

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

alpha = 1;
beta = 1;
modscheme = wlan.internal.phy.l2sm.mcs2rate(format,mcs);
[snreff,scrbir,avrbir] = wireless.internal.L2SM.calculateEffectiveSINR(sinr,modscheme,alpha,beta);
end
