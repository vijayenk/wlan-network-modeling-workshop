function failInterpretation = failInterpretationIf(condition,errormsg,suppressError,varargin)
%failInterpretationIf Check error condition
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FAILINTERPRETATION =
%   failInterpretationIf(CONDITION,ERRORMSG,SUPPRESSERROR,varargin) checks
%   the given error condition. When you use this syntax with CONDITION true
%   an exception is issued, and the function does not return an output.
%
%   CONDITION is the logical condition for the error, true implies an
%   error.
%
%   ERRORMSG is the message catalog ID for the error to throw.
%
%   SUPPRESSERROR controls the behavior of the function. SUPPRESSERROR is
%   logical. When both, CONDITION and SUPPRESSERROR are true, the function
%   does not error and return FAILINTERPRETATION as true. When
%   SUPPRESSERROR is false and CONDITION is true an exception is issued,
%   and the function does not return an output.
%
%   FAILINTERPRETATION = failInterpretationIf(...,INTERPRETEDVALUE) display
%   the interpreted value when the exception is issued.
%
%   ERRORMSG is the message catalog ID for the error/warning to throw.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

failInterpretation = false;
if condition
    if suppressError
        failInterpretation = true;
    else
        coder.internal.errorIf(condition,errormsg,varargin{:});
    end
end

end