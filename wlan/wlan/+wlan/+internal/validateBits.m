function validateBits(bits,propertyName)
%validateBits Validate post-FEC padding bits
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS must be a binary column vector for the given property
%   PROPERTYNAME.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

mustBeNumeric(bits);
mustBeNonempty(bits);
mustBeMember(bits,[0 1]);
if ~(coder.target('MATLAB') || coder.internal.isAmbiguousTypes())
    % Must be int8 type for C code generation, ignoring ambiguous types
    coder.internal.errorIf(~isa(bits,'int8'),'wlan:shared:InvalidBitsCodegen',propertyName);
end

end