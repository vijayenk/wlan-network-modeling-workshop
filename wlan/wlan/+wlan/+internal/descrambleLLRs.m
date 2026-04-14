function y = descrambleLLRs(x)
%descrambleLLRs Descramble LLR symbols
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases

%   Copyright 2017 The MathWorks, Inc.

%#codegen

buffer = ones(size(x));
% Convert LLR into 0 and 1, before descrambling
buffer(x<0) = 0; % Negative LLRs are converted to zeros
descrambleBits = wlanScramble(buffer,ones(7,1));
% Compare and set the sign of the second sequence against the descrambled output
y = x.*(-2*(buffer~=descrambleBits)+1);

end