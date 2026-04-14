function osf = validateOFDMOSF(osf,fftLen,cplen)
%validateOFDMOSF Validate OFDM oversampling parameters
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   validateOFDMOSF(OSF,FFTLEN,CPLEN) returns the oversampling factor given
%   name-value pairs in VARARGIN.

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

    if osf==1
        return
    end

    % Validate a larger FFT can be used to oversample
    nonIntegerCP = fix(cplen*osf)~=cplen*osf;
    if any(nonIntegerCP)
        coder.internal.error('wlan:shared:InvalidOSFCPLen',sprintf('%f',osf),findFailingCPLength(cplen,nonIntegerCP));
    elseif rem(fftLen*osf,2)~=0
        coder.internal.error('wlan:shared:InvalidOSFFFTLen',sprintf('%f',osf),fftLen);
    end
end

function fcp = findFailingCPLength(cplen,nonIntegerCP)
    % Equivalent of fcp = cplen(find(nonIntegerCP,1)).
    % This is to avoid the codegen issue of the output of find being
    % potentially empty, and is a simpler implementation.
    t = 1:numel(nonIntegerCP);
    failing = t(nonIntegerCP);
    fcp = cplen(failing(1));
end