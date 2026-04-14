function y = scramblerInitialState(x)
%scramblerInitialState calculates the initial state of the scrambler
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = scramblerInitialState(X) calculates the initial state of the
%   scrambler depicted in IEEE Std 802.11-2012 Section 18.3.5.5. Y is a
%   binary column vector of size 7-by-1.
%
%   X is sequence of scrambled bits used to extract the initial state of
%   the scrambler.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

y = mod([sum(x([1 3 4 7]));x(2:4)+x(1:3)+x(5:7);x(1:3)+x(5:7)],2);

end

