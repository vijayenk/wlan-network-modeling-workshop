function PSDUMU = validateVHTPSDUInput(PSDU,PSDULength,numUsers,filename)
%validateVHTPSDUInput Validate and pre-process PSDU input
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   PSDUMU = validateVHTPSDUInput(PSDU,PSDULENGTH,NUMUSERS,FILENAME)
%   returns a cell array containing the PSDU per user to encode and
%   modulate. The PSDU input is also validated.
%
%   PSDU is a binary vector or cell array or binary vectors containing the
%   bits to encode per user.
%
%   PSDULength is a vector containing the required PSDU length in bytes per
%   user.
%
%   NUMUSERS is a scalar integer specifying the number of users.
%
%   FILENAME is the name of the function performing the validation.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

coder.internal.errorIf((numUsers > 1) && ~iscell(PSDU), ...
    'wlan:shared:InvalidPSDUForMU');
if iscell(PSDU) % SU and MU
    validateattributes(PSDU, {'cell'}, {'row','numel',numUsers}, ...
        filename, 'PSDU input');
    
    for u = 1:numUsers
        validateattributes(PSDU{u}, {'double','int8'}, {'real', ...
            'integer','column','binary','numel',8*PSDULength(u)}, ...
            filename, feval('sprintf','PSDU input for user %d', int16(u)));
    end
    PSDUMU = PSDU;
else % SU
    validateattributes(PSDU, {'double','int8'}, {'real','integer', ...
        'column','binary','numel',8*PSDULength(1)}, ...
        filename, 'PSDU input');
    PSDUMU = {PSDU};
end
end