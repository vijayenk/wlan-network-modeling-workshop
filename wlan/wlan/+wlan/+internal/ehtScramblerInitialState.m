function y = ehtScramblerInitialState(x)
%ehtScramblerInitialState Calculates the initial state of the scrambler
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = ehtScramblerInitialState(X) calculates the initial state of the
%   scrambler depicted in IEEE P802.11be/D1.5, Section 36.3.13.2. Y is a
%   binary column vector of size 11-by-1.
%
%   X is sequence of scrambled bits used to extract the initial state of
%   the scrambler.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

y = mod([sum(x([1 2 3 5 7 9 11])) sum(x([1 2 4 6 8 10])) sum(x([2 3 5 7 9 11])), ...
     sum(x([1 4 6 8 10])) sum(x([2 5 7 9 11])) sum(x([1 6 8 10])), ...
     sum(x([2 7 9 11])) sum(x([1 8 10])) sum(x([2 9 11])) sum(x([1 10])), ...
     sum(x([2 11]))],2).';

end