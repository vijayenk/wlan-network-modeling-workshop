function ehtValidateTXOPDuration(x)
%ehtValidateTXOPDuration Validate TXOPDuration
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   X must be an integer scalar between 0 and 8448 or an empty

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.errorIf(~isempty(x) && (~isnumeric(x) || ~isscalar(x) || x<0 || x>8448 || ~isreal(x) || (mod(x,1)~=0)),'wlan:eht:InvalidTXOPDuration');

end