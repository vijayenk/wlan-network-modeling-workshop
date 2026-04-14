function [isvalid,msg] = testErrorCondition(condition,mode,errormsg,varargin)
%testErrorCondition Test an error condition
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   [ISVALID,MSG] = testErrorCondition(CONDITION,MODE,ERRORMSG,ARGS) tests
%   the given error condition, and performs an action.
%
%   ISVALID is a logical true when the condition results in no error.
%
%   MSG is a character vector containing the message catalog entry for any
%   error triggered when CONDITION is true. This is an empty character
%   vector if CONDITION is false. No warning message is returned in target
%   is codegen.
%
%   CONDITION is the logical condition for the error, true implies an
%   error.
%
%   MODE is a character vector specifying the action to take when the error
%   condition is true. It can be 'error', 'warn' or 'no action' to throw an
%   error, a warning or take no action. Unless 'no action' is specified the
%   code will return and no ISVALID or MSG will be returned.
%
%   ERRORMSG is the message catalog ID for the error/warning to throw.
%
%   ARGS are optional argument for the message catalog entry.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

if condition==true
    isvalid = false;
    if isempty(coder.target)
        msg = message(warningMessageID(errormsg),varargin{:}).getString();
    else
        % Return an empty character vector for codegen as message is
        % not supported
        msg = '';
    end
    switch lower(mode)
        case 'error'
            coder.internal.error(errormsg,varargin{:});
        case 'warn'
            coder.internal.warning(warningMessageID(errormsg),varargin{:});
        otherwise % Return warning character vector
    end   
else
    isvalid = true;
    msg = '';
end

end

% Returns the equivalent warning message ID given an error message ID
% assuming 'PSDULength' is appended to the start of the ID
function msg = warningMessageID(errormsg)
    lastSep = find(errormsg==':',1,'last');
    msg = [errormsg(1:lastSep(1)) 'PSDULength' errormsg(lastSep(1)+1:end)];
end