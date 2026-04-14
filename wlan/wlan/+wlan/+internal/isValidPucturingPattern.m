function failInterpretation = isValidPucturingPattern(x,suppressError,varargin)
%isValidPucturingPattern Validated puncturing patterns
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   FAILINTERPRETATION = isValidPucturingPattern(X,SUPPRESSERROR) checks
%   the puncturing pattern X, against the allowed punturing pattern as
%   defined in Table 36-28 of IEEE P802.11be/D3.0.
%
%   SUPPRESSERROR controls the behavior of the function. SUPPRESSERROR is
%   logical. If puncturing pattern is invalid and SUPPRESSERROR are true,
%   the function does not error and return FAILINTERPRETATION as true. When
%   SUPPRESSERROR is false and puncturing pattern is invalid an exception
%   is issued, and the function does not return an output.
%
%   FAILINTERPRETATION = isValidPucturingPattern(...,SUBBLOCKNUMBER)
%   display the 80 MHz subblock number when the exception is issued.

%   Copyright 2023 The MathWorks, Inc.

%#codegen

failInterpretation = false;
condition = any(~ismember(x,wlan.internal.ehtAllowedOFDMAPuncturingPatterns,'row'));
if condition
    if suppressError
        failInterpretation = true;
    else
        coder.internal.errorIf(condition,'wlan:eht:InvalidPuncturingPatternPerSegment',varargin{:});
    end
end

end