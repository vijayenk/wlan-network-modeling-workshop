function bits = validateVHTScramblerInit(scramInit,numUsers,fileName)
%validateVHTScramblerInit Validate and pre-process scrambler initialization
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   BITS = validateVHTScramblerInit(SCRAMINIT,NUMUSERS,FILENAME)
%   returns a vector or matrix containing the scrambler initialization bits
%   for all users. The scrambler initialization is also validated.
%
%   SCRAMINIT is the scrambler initialization per user specified as vector
%   of integers or a binary matrix.
%
%   NUMUSERS is a scalar integer specifying the number of users.
%
%   FILENAME is the name of the function performing the validation.

%   Copyright 2016-2021 The MathWorks, Inc.

%#codegen

% Validate scrambler initialization input
% The argument scramInit must be one of the following:
% * An int scalar between 1 and 127
% * A 1-by-numUsers vector of ints between 1 and 127
% * A binary 7-by-1 vector
% * A binary 7-by-numUsers matrix
validateattributes(scramInit, {'double','int8'}, {'real','integer','nonempty'}, ...
    fileName, 'Scrambler initialization');
if isscalar(scramInit)      % [1 1]
    coder.internal.errorIf( ...
         any((scramInit<1) | (scramInit>127)), ...
        'wlan:shared:InvalidScramInit');
    bits = uint8(repmat(int2bit(scramInit, 7), 1, numUsers));
elseif isrow(scramInit)     % [1 Nu]
    coder.internal.errorIf( ...
         any((scramInit<1) | (scramInit>127)) ...
         || any(size(scramInit)~=[1 numUsers]), 'wlan:shared:InvalidScramInit');
    bits = uint8(int2bit(scramInit, 7));
elseif iscolumn(scramInit)  % [7, 1]
    coder.internal.errorIf( ...
        any((scramInit~=0) & (scramInit~=1)) || (size(scramInit,1)~=7), ...
        'wlan:shared:InvalidScramInit');
    % Check for non-zero init
    coder.internal.errorIf(all(scramInit == 0), ...
        'wlan:shared:ZeroScramInit');
    bits = uint8(repmat(scramInit, 1, numUsers));
else                        % [7 Nu]
    coder.internal.errorIf( ...
        any((scramInit(:)~=0) & (scramInit(:)~=1)) || any(size(scramInit)~=[7 numUsers]), ...
        'wlan:shared:InvalidScramInit');
    % Check for non-zero init
    coder.internal.errorIf(any(sum(scramInit) == 0), ...
        'wlan:shared:ZeroScramInit');
    bits = uint8(scramInit);
end