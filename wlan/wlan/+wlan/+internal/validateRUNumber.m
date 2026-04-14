function validateRUNumber(ruNumber,numRUs)
%validateRUNumber Validate RU number
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   validateRUNumber(RUNUMBER,NUMRUS) validates that RU number does not
%   exceed the number of RUs.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

    validateattributes(ruNumber,{'numeric'},{'scalar','integer','>',0,'<=',numRUs},mfilename,'RU Number');

end