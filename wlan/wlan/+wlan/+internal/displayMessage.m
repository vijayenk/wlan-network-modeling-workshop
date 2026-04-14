function displayMessage(messageID, varargin)
%displayMessage Display the message
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = displayMessage(MESSAGEID) displays the message for a given valid
%   message identifier.
%
%   Y = displayMessage(MESSAGEID, PARAM1, PARAM2, ...., PARAMN) displays
%   the message for a given valid message identifier and message
%   parameters.

%   Copyright 2021 The MathWorks, Inc.

    disp(message(messageID, varargin{:}).getString);
end