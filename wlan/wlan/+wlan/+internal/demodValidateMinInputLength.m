function demodValidateMinInputLength(numSamples,varargin)
%demodValidateMinInputLength Validate input length for OFDM demodulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   demodValidateMinInputLength(NUMSAMPLES,OFDMSYMLEN) verifies the number
%   of input samples, NUMSAMPLES, is greater than or equal to at least one
%   OFDM symbol length (OFDMSYMLEN) or 0.
%
%   demodValidateMinInputLength(NUMSAMPLES,CFGOFDM) verifies the number
%   of input samples, given the ofdm configuration structure CFGOFDM.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

narginchk(2,2);

if isnumeric(varargin{1})
    Ns = varargin{1}; % Number of samples in an OFDM symbol
else
    cfgOFDM = varargin{1};
    Ns = cfgOFDM.FFTLength+cfgOFDM.CPLength(1); % Number of samples in an OFDM symbol
end
minInputLength = sum(Ns);
coder.internal.errorIf(numSamples>0 && numSamples<minInputLength,'wlan:shared:ShortDataInput',minInputLength);
end