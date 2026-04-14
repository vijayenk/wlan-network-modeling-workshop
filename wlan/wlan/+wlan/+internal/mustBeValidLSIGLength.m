function mustBeValidLSIGLength(lsigLength,format)
%mustBeValidLSIGLength Validate the L-SIG length for an HE TB and EHT TB PPDU
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   mustBeValidLSIGLength(LSIGLENGTH,FORMAT) validates if the L-SIG length
%   is a scalar integer satisfying the constraints for a given packet
%   FORMAT. The FORMAT is a character vector or string describing the
%   packet format and must be 'HE-TB' or 'EHT-TB'.

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

mustBeNumeric(lsigLength);
mustBeInteger(lsigLength);
mustBeGreaterThanOrEqual(lsigLength,1);
if strcmp(format,'HE TB')
    mustBeLessThanOrEqual(lsigLength,4093);
    coder.internal.errorIf(mod(lsigLength,3)~=1,'wlan:shared:InvalidLSIGLengthVal');
else % EHT TB
    mustBeLessThanOrEqual(lsigLength,4093);
    coder.internal.errorIf(mod(lsigLength+2,3)~=0,'wlan:wlanEHTTBConfig:InvalidEHTTBLSIGLengthVal');
end

end
